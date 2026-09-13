import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { computeBuildingCost } from "file:///E:/Python/test1/src/balance/rules/buildingCost.ts";
import {
  applyTrainingTimeBonuses,
  checkCapacityRequirements,
  computeCumulativeTrainingTime,
  computeSingleLevelTime,
} from "file:///E:/Python/test1/src/balance/rules/eraRequirements.ts";
import { getMaxLifespanSeconds, computeReincarnationReward } from "file:///E:/Python/test1/src/balance/rules/lifespanRules.ts";
import {
  computeKarmaStorageContribution,
  computeKarmaStorageResourceGrant,
  computeReincarnationStartAmount,
  computeResourceInheritanceAmount,
} from "file:///E:/Python/test1/src/balance/rules/reincarnationInheritance.ts";
import { getOnboardingUnlockState } from "file:///E:/Python/test1/src/balance/rules/onboardingUnlocks.ts";
import { SeededRandom } from "file:///E:/Python/test1/src/balance/simulation/SeededRandom.ts";
import Decimal from "file:///E:/Python/test1/src/utils/break_eternity.js";

function decimalRecord(values: Record<string, { toString(): string }>): Record<string, string> {
  return Object.fromEntries(Object.entries(values).map(([key, value]) => [key, value.toString()]));
}

describe("M0-B legacy reference extraction", () => {
  it("matches the checked-in golden fixture against the read-only legacy implementation", () => {
    const eras = [
      { eraId: 1, lifespan: 80 },
      { eraId: 2, lifespan: 120 },
      { eraId: 3, lifespan: 540 },
    ] as any;
    const values = {
      building_cost: {
        level_0: decimalRecord(computeBuildingCost({ baseCost: { money: 100, wood: 40 }, level: 0 })),
        level_20: decimalRecord(computeBuildingCost({ baseCost: { money: 100, wood: 40 }, level: 20 })),
        level_21: decimalRecord(computeBuildingCost({ baseCost: { money: 100, wood: 40 }, level: 21 })),
        level_50: decimalRecord(computeBuildingCost({ baseCost: { money: 100, wood: 40 }, level: 50 })),
        level_51_discounted: decimalRecord(computeBuildingCost({ baseCost: { money: 100, wood: 40 }, level: 51, costFactor: 1.25, costReduction: 0.15, intuitionLevel: 4 })),
      },
      training: {
        cumulative_10_1_5_level_0: computeCumulativeTrainingTime(10, 1.5, 0),
        cumulative_10_1_5_level_3: computeCumulativeTrainingTime(10, 1.5, 3),
        single_10_1_5_level_4: computeSingleLevelTime(10, 1.5, 4),
        bonused_100: applyTrainingTimeBonuses(100, 0.25, 0.5, 0.1),
        clamped_100: applyTrainingTimeBonuses(100, 0, 0.01, 0.99),
      },
      capacity: {
        below_tolerance: checkCapacityRequirements(
          { lingli_max: 500 },
          { lingli: 499.89 },
        ).map((gap) => ({ ...gap, current: gap.current.toString() })),
        at_tolerance: checkCapacityRequirements(
          { lingli_max: 500, stone_low_max: 1000 },
          { lingli: 499.9, stone_low: 1000 },
        ).map((gap) => ({ ...gap, current: gap.current.toString() })),
      },
      amount: ["0", "123.45", "1e100", "1e1000000", "ee5"].map((input) => {
        const amount = new Decimal(input);
        return { input, string: amount.toString(), json: amount.toJSON() };
      }),
      lifespan: {
        era_1: getMaxLifespanSeconds({ eras, eraId: 1 }),
        era_2_talent_pill: getMaxLifespanSeconds({ eras, eraId: 2, talentBonus: 0.1, pillBonus: 5 }),
        era_4_fallback: getMaxLifespanSeconds({ eras, eraId: 4 }),
      },
      reincarnation: {
        normal: computeReincarnationReward(125, "normal", 1),
        advanced: computeReincarnationReward(125, "advanced", 1),
        era_floor: computeReincarnationReward(5, "normal", 4),
        start: [0, 1, 2, 20].map((count) => computeReincarnationStartAmount(999, count)),
        contribution: computeKarmaStorageContribution(199, 3),
        resource_grant: computeKarmaStorageResourceGrant(3),
        resource_inheritance: computeResourceInheritanceAmount(999, 3),
      },
      onboarding: {
        new_game: getOnboardingUnlockState({ onboardingVersion: 1, era: 1, buildings: {} }),
        hut_2: getOnboardingUnlockState({ onboardingVersion: 1, era: 1, buildings: { hut: 2 } }),
        early_chain: getOnboardingUnlockState({ onboardingVersion: 1, era: 1, buildings: { hut: 2, wooden_house: 2, forest_farm: 3, stone_mine: 3, herb_farm: 3 } }),
      },
      seeded_random: ["dao2-fixture", "修仙問道", 12345].map((seed) => {
        const rng = SeededRandom.fromSeed(seed);
        const first = [rng.next(), rng.next(), rng.next(), rng.next()];
        const state = rng.state;
        const resumed = SeededRandom.fromState(state).next();
        return { seed, first, state, resumed };
      }),
    };
    const fixture = JSON.parse(
      readFileSync(resolve(process.cwd(), "tests/fixtures/legacy/m0-b-v1.json"), "utf8"),
    );
    expect(values).toEqual(fixture.expected);
  });
});
