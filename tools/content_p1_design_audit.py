"""Offline proposal analysis only. Never imports/runs/modifies the game or saves.

Run: python tools/content_p1_design_audit.py
Evidence: docs/verification/artifacts/content-p1-design/analysis.json
All scenarios below are synthetic comparisons, not gameplay acceptance.
"""
from pathlib import Path
from decimal import Decimal as D
import ast
import hashlib
import itertools
import json
import math
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/verification/artifacts/content-p1-design"
PROPOSAL = ROOT / "docs/design-data/content-p1-proposal.json"


def read(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8-sig"))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    checks = []

    def check(label, condition):
        checks.append({"check": label, "ok": bool(condition)})

    p = read(PROPOSAL.relative_to(ROOT))
    baseline = read(OUT.relative_to(ROOT) / "session-start.json")
    mismatches = [path for path, h in baseline["protected"].items()
                  if not (ROOT / path).is_file() or sha(ROOT / path) != h]
    actual = {f.relative_to(ROOT).as_posix() for folder in ("src", "content", "tests")
              for f in (ROOT / folder).rglob("*") if f.is_file()}
    added = sorted(actual - set(baseline["protected"]))
    check("all protected runtime/content/tests/frozen build bytes unchanged", not mismatches and not added)
    engine = subprocess.run([str(ROOT / "tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe"), "--version"],
                            capture_output=True, text=True, check=True).stdout.strip()
    check("existing engine exactly 4.7.2", engine == baseline["engine"])
    check("proposal remains unapproved", p["status"] == "PROPOSED_NOT_APPROVED")
    skills = read("content/skills/era2.json") + read("content/skills/era3.json")
    resources = {r["id"]: r for r in read("content/resources/era1.json")}
    buildings = {b["id"]: b for b in read("content/buildings/era1.json") + read("content/buildings/era2.json") + read("content/buildings/study.json")}
    catalog = read("content/recipes/era1_3.json")
    source_paths = ["src/simulation/" + name + ".gd" for name in [
        "skill_system", "talent_system", "alchemy_system", "buff_system", "production",
        "time_advancer", "island_economy", "island_progression", "processing_inventory",
        "reincarnation_rules", "beast_system", "sect_system", "offline_closed_form", "offline_economy_jump"]]
    source_paths += ["src/persistence/save_codec.gd", "src/application/game_session.gd",
                     "content/skills/era2.json", "content/skills/era3.json",
                     "content/buildings/study.json", "content/buildings/era1.json",
                     "content/buildings/era2.json", "content/resources/era1.json",
                     "content/eras/era2.json", "content/eras/era3.json", "content/recipes/era1_3.json"]

    def dictionary_ids(name, constant):
        text = (ROOT / f"src/simulation/{name}.gd").read_text(encoding="utf-8-sig")
        block = text.split("const " + constant + " := {", 1)[1].split("\n}", 1)[0]
        return re.findall(r'^\t"([^"\n]+)": \{', block, re.M)

    old_talents = dictionary_ids("talent_system", "TALENTS")
    old_pills = dictionary_ids("alchemy_system", "PILLS")
    old_buffs = dictionary_ids("buff_system", "DEFINITIONS")
    alchemy_text = (ROOT / "src/simulation/alchemy_system.gd").read_text(encoding="utf-8-sig")
    pills_live = ast.literal_eval("{" + alchemy_text.split("const PILLS := {", 1)[1].split("\n}", 1)[0] + "\n}")
    buff_text = (ROOT / "src/simulation/buff_system.gd").read_text(encoding="utf-8-sig")
    buffs_live = ast.literal_eval(("{" + buff_text.split("const DEFINITIONS := {", 1)[1].split("\n}", 1)[0] + "\n}")
                                  .replace("false", "False").replace("true", "True"))
    check("live baseline remains 7 skills / 3 talents / 8 pills", (len(skills), len(old_talents), len(old_pills)) == (7, 3, 8))
    check("live6 era1-3 pills plus4 proposed yield definition ceiling10", sum(d["min_era"] <= 3 for d in pills_live.values()) == 6 and all(d["era"] <= 3 for d in p["pills"]))
    all_ids = [item["id"] for group in ("skills", "talents", "pills") for item in p[group]]
    check("12 distinct proposed IDs, no existing definition collisions", len(all_ids) == len(set(all_ids)) == 12 and not set(all_ids) & ({s["id"] for s in skills} | set(old_talents) | set(old_pills)))
    check("five skills / three talents / four pills", [len(p[k]) for k in ("skills", "talents", "pills")] == [5, 3, 4])
    check("new skills era2 three / era3 two, none era1", [s["era"] for s in p["skills"]] == [2, 2, 2, 3, 3])
    check("four new buff IDs unique and not aliases", len({x["buff_id"] for x in p["pills"]}) == 4 and not {x["buff_id"] for x in p["pills"]} & set(old_buffs))
    check("all proposed pill ingredients and targets exist in current era1 resource list", all(set(x["cost"]) | {x["target"]} <= set(resources) for x in p["pills"]))
    check("all ingredients positive, non-self-consuming recipes", all(all(v > 0 for v in x["cost"].values()) and x["target"] not in x["cost"] for x in p["pills"]))
    check("every new pill fee fits unmodified base home capacity", all(all(v <= resources[k]["max"] for k, v in x["cost"].items()) for x in p["pills"]))
    skill_waits = []
    for s in p["skills"]:
        cap = 200 if s["era"] == 2 else 6200
        check(s["id"] + " each rank fits existing study capacity", s["cost"] <= cap)
        for lib_level in (1, 2, 3):
            # Current Era2 and Era3 both have multiplier2; no other modifiers.
            rate = 2 * lib_level ** 1.5
            skill_waits.append({"id": s["id"], "library_level": lib_level,
                                "seconds_from_zero": round(s["cost"] / rate, 6)})
    check("warehouse is not prerequisite for its own skill points", all(s["effect"] != "skill_point_max" for s in p["skills"]))
    check("new three resource skills all fit zero-sect base200 point cap", all(s["cost"] <= 200 for s in p["skills"][:3]))
    check("study building library fee fits existing storage upgrades without new skills", buildings["library"]["base_cost"]["wood"] <= 150 + 300 and buildings["scripture_hall"]["base_cost"]["wood"] <= 150 + 2 * 300)
    # Explicit marginal comparison at zero other bonuses; do not sum currencies.
    production_skills = []
    for s in p["skills"][:3]:
        target = s["targets"][0]
        b = next(b for b in buildings.values() if target in b["effects"] and b["id"] != "hut")
        old = b["effects"][target] * (3 + b["effect_weight"]) ** 1.5 * 2
        upgraded = b["effects"][target] * (4 + b["effect_weight"]) ** 1.5 * 2
        production_skills.append({"id": s["id"], "rate_at_facility3": old,
                                  "rate_with_skill1": old * 1.1,
                                  "rate_at_facility4": upgraded,
                                  "max_skill_multiplier": str(D(s["amount"]) ** s["max_level"]),
                                  "building_upgrade_gain_percent": (upgraded / old - 1) * 100})
        check(s["id"] + " upgrade alternative stronger first-step output; different currency", upgraded > old * 1.1 > old)
    g = lambda h: 1 + .15 * math.log10(h + 1)
    talent_costs = {}
    for t in p["talents"]:
        costs = [t["base_cost"] * t["cost_factor"] ** i for i in range(t["max_level"])]
        talent_costs[t["id"]] = {"per_rank": costs, "cumulative": list(itertools.accumulate(costs))}
        check(t["id"] + " first rank affordable within20 and finite ladder", costs[0] <= 20 and sum(costs) == 155)
    packs = []
    for levels in itertools.product(range(6), repeat=6):
        # Existing first costs 5/10/15, all x2; proposed 5/5/5, all x2.
        spend = sum(base * (2**l - 1) for base, l in zip((5, 10, 15, 5, 5, 5), levels))
        if spend <= 20:
            packs.append({"levels_old_inherit_life_innate_new_pill_artisan_beast": levels,
                          "spend": spend, "held": 20-spend,
                          "holding_multiplier": g(20-spend)})
    # At20 heart no bonuses, output dominated by a whitelisted building.
    artisan = g(15) * 1.08 / g(20)
    check("artisan first rank still positive after loss of holding bonus", artisan > 1)
    # Ordinary, base jade fox is ready at first feed; thresholds are cumulative.
    feeds = []
    for rank, old_boost in itertools.product(range(6), (0, .3)):
        gain = math.floor(50 * (1 + old_boost + .2 * rank) + 1e-10)
        count = math.ceil(1000 / gain)
        feeds.append({"rank": rank, "existing_growth_bonus": old_boost, "exp_per_feed": gain,
                      "feeds_to_mature": count, "grass_no_discount": count * 50,
                      "seconds_between_first_and_last": (count-1) * 300})
    check("fox thresholds cumulative, not100+500+1000", feeds[0]["feeds_to_mature"] == 20)
    check("fox new rank1 saves feeds and keeps300-second cooldown", next(x for x in feeds if x["rank"] == 1 and x["existing_growth_bonus"] == 0)["feeds_to_mature"] == 17)
    discounts = []
    for level, count in itertools.product(range(4), (1, 2, 99)):
        unit = D(50) * (1 - D(".05") * level)
        check(f"discount rank{level} batch{count} exactly linear", unit * count == D(50 * count) * (1 - D(".05") * level))
        discounts.append({"level": level, "count": count, "fee_lingli": str(unit * count)})
    training_cases = []
    for rank, used, count, available in itertools.product(range(6), (0, 1, 98), (1, 2, 99), (D(0), D(30), D(3000))):
        if used + count > 99:
            continue
        raw = D(300) * D(".85") ** used * (1 - D(".85") ** count) / (1 - D(".85"))
        boosted = raw * (1 + D(".10") * rank)
        applied = min(available, boosted)
        check("pill training decay then talent then ceiling bounded", 0 <= applied <= available and boosted >= raw)
        training_cases.append({"rank": rank, "used": used, "count": count, "available": str(available), "applied": str(applied)})
    # Fully consume capped stock or continuously sink it: show both extremes.
    comparisons = []
    for pill in p["pills"]:
        for rate, cap, stock in itertools.product((D("0.1"), D(1), D(5)), (D(50), D(300), D(2000)), (D(0), D(50))):
            if stock > cap:
                continue
            base = min(cap, stock + rate * pill["duration"])
            after = min(cap, stock + rate * (1 + D(pill["bonus"])) * pill["duration"])
            check("capped incremental gain nonnegative and <=uncapped", 0 <= after-base <= rate * D(pill["bonus"]) * pill["duration"])
            comparisons.append({"pill": pill["id"], "rate": str(rate), "capacity": str(cap), "stock": str(stock),
                                "increment_without_sink": str(after-base),
                                "increment_unconstrained": str(rate * D(pill["bonus"]) * pill["duration"])})
    # Compare vectors: specialist one resource vs tide all resource. Neither universally dominates.
    effect_vectors = {"specialist_target": 300, "spirit_tide_each": .5 * 300, "quick_output_each": .2 * 600}
    check("specialist target gain exceeds both all-output alternatives; those affect other resources", effect_vectors["specialist_target"] > effect_vectors["spirit_tide_each"] > effect_vectors["quick_output_each"])
    duration_cases = []
    for remaining, count in itertools.product((0, 100, 300, 500, 3599, 3600), (1, 2, 12, 13, 99)):
        requested = 300 * count
        accepted = requested <= 3600 and requested > remaining
        duration_cases.append({"remaining": remaining, "count": count, "accepted": accepted,
                               "new_remaining": requested if accepted else remaining})
        check(f"bounded new pill duration {remaining}/{count}", not accepted or 0 < requested-remaining <= 3600)
    # Text/data checks deliberately limited to this task; no unrelated dirty diff cleanup.
    docs = ["docs/31-content-p1-design.md", "docs/verification/content-p1-design.md",
            "docs/25-system-content-expansion-plan.md", "docs/21-res1-e-skills-expansion-plan.md",
            "README.md", "ROADMAP.md", "docs/ai-handoff.md", "docs/development-status.md", "updata.txt"]
    bad_links = []
    for name in docs:
        text = (ROOT / name).read_bytes().decode("utf-8-sig", errors="strict")
        check(name + " UTF-8", "\ufffd" not in text)
        if name in docs[:2]:
            for link in re.findall(r'\]\(([^)]+)\)', text):
                if "://" in link or link.startswith("#"):
                    continue
                target = link.split("#", 1)[0]
                if target and not ((ROOT / name).parent / target).exists():
                    bad_links.append([name, link])
    check("new design and verification local links resolve", not bad_links)
    result = {"task": p["task"], "date": "2026-10-23", "evidence": "synthetic static proposal arithmetic only",
              "engine": engine, "proposal_sha256": sha(PROPOSAL), "sources": {s: sha(ROOT/s) for s in source_paths},
              "protected_files": len(baseline["protected"]), "protected_mismatches": mismatches, "runtime_added": added,
              "baseline": {"skills": [s["id"] for s in skills], "talents": old_talents, "pills": old_pills},
              "proposed_total": {"skills": 12, "talents": 6, "pills": 12, "pills_era_le3_definition_ceiling": 10},
              "skill_waits_seconds": skill_waits, "skill_upgrade_comparison": production_skills,
              "talent_costs": talent_costs, "dao20_feasible_packs": packs,
              "dao20_hold_multiplier": g(20), "dao15_hold_multiplier": g(15),
              "artisan_rank1_ratio_at20": artisan, "fox_growth": feeds, "discount_batches": discounts,
              "training_decay_ceiling_scenarios": training_cases,
              "pill_stock_scenarios": comparisons, "pill_duration_scenarios": duration_cases,
              "pill_increment_per_rate_unit": effect_vectors,
              "existing_pills_expanded_cost": {"spirit_tide_pill": {"spirit_grass_low": 10, "lingli": 200},
                                               "quick_output_pill": {"wood": 10, "stone_low": 5, "spirit_grass_low": 10, "lingli": 150}},
              "checks": checks, "check_count": len(checks), "failures": [c for c in checks if not c["ok"]], "bad_links": bad_links}
    # Bind expanded old costs to current input recipes rather than trusting prose.
    check("tide raw fee matches current liquid recipe", catalog["recipes"]["liquid"]["inputs"] == {"spirit_grass_low": "5", "lingli": "50"})
    check("quick raw fee matches current talisman recipe", catalog["recipes"]["talisman"]["inputs"] == {"wood": "10", "stone_low": "5", "lingli": "50"})
    check("existing tide/quick costs bind to actual Alchemy definitions", pills_live["spirit_tide_pill"]["cost"] == {"liquid": 2, "lingli": 100} and pills_live["quick_output_pill"]["cost"] == {"talisman": 1, "liquid": 2})
    check("existing all-output duration and bonus bind to actual definitions", pills_live["spirit_tide_pill"]["effects"]["buff_duration_seconds"] == 300 and pills_live["quick_output_pill"]["effects"]["buff_duration_seconds"] == 600)
    check("existing all-output bonuses are .5 and .2", buffs_live["spirit_tide"]["effects"]["production_multiplier"] == .5 and buffs_live["quick_output"]["effects"]["production_multiplier"] == .2)
    check("permanent foundation .1 comparison binds to actual effect", pills_live["foundation_pill"]["effects"]["production_multiplier"] == .1)
    result["check_count"] = len(checks)
    result["failures"] = [c for c in checks if not c["ok"]]
    (OUT / "analysis.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"checks": len(checks), "failures": result["failures"], "protected_unchanged": len(baseline["protected"]),
                      "source_hashes": len(source_paths), "dao20_packs": len(packs), "stock_scenarios": len(comparisons)}, ensure_ascii=False))
    raise SystemExit(bool(result["failures"]))


if __name__ == "__main__":
    main()
