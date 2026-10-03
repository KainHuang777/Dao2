import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { canCraft, computeCraftResult } from "file:///E:/Python/test1/src/balance/rules/craft.ts";
import { isRecipeGated } from "file:///E:/Python/test1/src/balance/rules/recipe.ts";

const fixture = JSON.parse(readFileSync("tests/fixtures/legacy/res1-a-source.json", "utf8"));

describe("RES1-A fixed read-only DAO1 craft reference", () => {
  it("matches the source hashes before using the reference", () => {
    for (const source of fixture.sources) {
      const bytes = readFileSync(`E:/Python/test1/${source.path}`);
      expect(createHash("sha256").update(bytes).digest("hex")).toBe(source.sha256.toLowerCase());
    }
  });

  it.each(fixture.resources.filter((row: any) => Object.keys(row.recipe).length))(
    "executes the original $id ratios with no bonus and no crit",
    (row: any) => {
      const ingredients = Object.fromEntries(Object.entries(row.recipe).map(([id, cost]) => [id, { value: Number(cost) * 2, unlocked: true }]));
      const input = { key: row.id, resource: { type: "crafted", unlocked: true, recipe: row.recipe, value: 0, max: 100 }, ingredients, count: 2, hasRecipe: () => true, craftBonusSum: 0, nextRandom: () => 0.5 };
      expect(canCraft(input)).toEqual({ canCraft: true });
      expect(computeCraftResult(input)).toEqual({ outputCount: 2, finalCount: 2, deductedIngredients: Object.fromEntries(Object.entries(row.recipe).map(([id, cost]) => [id, Number(cost) * 2])), critMultiplier: 1, skillBonusMultiplier: 1 });
    },
  );

  it("keeps legacy crit, bonus, overflow and epsilon separate from v2", () => {
    const input = { key: "bronze_essence", resource: { type: "crafted", unlocked: true, recipe: { black_copper: 10, stone_low: 5 }, value: 0, max: 100 }, ingredients: { black_copper: { value: 20, unlocked: true }, stone_low: { value: 10, unlocked: true } }, count: 2, hasRecipe: () => true, craftBonusSum: 0.5, nextRandom: () => 0.01 };
    expect(computeCraftResult(input).finalCount).toBe(9);
    expect(computeCraftResult({ ...input, resource: { ...input.resource, max: 4 } }).finalCount).toBe(4);
    expect(canCraft({ ...input, count: 1, ingredients: { ...input.ingredients, black_copper: { value: 9.995, unlocked: true } } }).canCraft).toBe(true);
    expect(isRecipeGated("foundation_pill")).toBe(false);
    expect(isRecipeGated("golden_core_pill")).toBe(false);
    expect(isRecipeGated("longevity_pill")).toBe(true);
    expect(canCraft({ ...input, key: "longevity_pill", hasRecipe: () => false })).toEqual({ canCraft: false, reason: "recipe-not-learned" });
  });
});
