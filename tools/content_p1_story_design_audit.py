"""Static proposal/source inventory and pool arithmetic; never runs game rules.

Run from any working directory. --capture-baseline records protected source bytes;
subsequent normal runs compare them. Outputs are isolated design artifacts only.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/verification/artifacts/content-p1-story-design"
PROPOSAL = ROOT / "docs/design-data/content-p1-story-proposal.json"


def read(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def write(path: Path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def protected_hashes():
    paths = []
    for directory in ["src", "content", "tests", "assets", "build/web"]:
        paths.extend(p for p in (ROOT / directory).rglob("*") if p.is_file())
    paths.extend(ROOT / name for name in ["project.godot", "export_presets.cfg"])
    return {p.relative_to(ROOT).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted(set(paths)) if p.is_file()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--capture-baseline", action="store_true")
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    baseline_path = OUT / "protected-baseline.json"
    current = protected_hashes()
    if args.capture_baseline:
        if baseline_path.exists():
            parser.error("Baseline already exists; refusing to replace evidence")
        write(baseline_path, current)
    if not baseline_path.exists():
        parser.error("Run --capture-baseline once before normal audits")

    failures = []
    checks = 0

    def check(condition, name):
        nonlocal checks
        checks += 1
        if not condition:
            failures.append(name)

    baseline = read(baseline_path)
    changed = sorted(k for k in baseline.keys() | current.keys() if baseline.get(k) != current.get(k))
    check(not changed, "Protected game/source/build inventory unchanged")
    proposal = read(PROPOSAL)
    doc = (ROOT / "docs/33-content-p1-story-design.md").read_text(encoding="utf-8")
    old_events = read(ROOT / "content/encounters/encounters.json")
    source = (ROOT / "src/simulation/achievement_system.gd").read_text(encoding="utf-8")
    definitions = source.split("const DEFINITIONS := {", 1)[1].split("static func", 1)[0]
    old_achievements = re.findall(r'^\t"([a-z0-9_]+)": \{', definitions, re.M)
    check(len(old_achievements) == 18, "18 current achievement definitions")
    check(len(old_events) == 26, "26 current encounter definitions")
    check(proposal["approval"] == "APPROVED_FOR_IMPLEMENTATION"
          and proposal.get("approval_evidence", {}).get("user_quote") == "採R"
          and proposal.get("approval_evidence", {}).get("approved_groups") == ["R1", "R2", "R-save", "R-art"],
          "Explicit human approval of all R groups")
    check(proposal["target"] == {"achievements": 30, "encounters": 38}, "Target counts")
    achievements, events = proposal["achievements"], proposal["encounters"]
    check(len(achievements) == 12 and len(events) == 12, "12+12 new definitions")
    ac = Counter(a["category"] for a in achievements)
    ec = Counter(e["category"] for e in events)
    check(ac == {k: 2 for k in ["cultivation", "abode", "alchemy", "sect", "beast_fate", "reincarnation"]}, "Six achievement categories")
    check(ec == {k: 2 for k in ["resource", "industry", "sect", "alchemy", "beast", "reincarnation"]}, "Six encounter categories")
    all_ids = [v["id"] for v in achievements + events]
    check(len(set(all_ids)) == 24, "Unique proposed IDs")
    check(not set(all_ids) & (set(old_achievements) | {e["id"] for e in old_events}), "No current ID collisions")
    resources = {"wood", "stone_low", "spirit_grass_low", "money", "lingli"}
    pills = {"wood_nurture_pill", "herb_nurture_pill", "wealth_gathering_pill", "qi_absorption_pill"}
    gates = {"wood_open", "timber_completed", "positive_home_arrival", "joined_sect", "new_supply_claimed", "refined_any_p1", "two_p1_consumed", "active_fox", "mature_active_fox", "second_life", "any_new_talent"}
    rewards_total = Counter()
    for a in achievements:
        check(a["id"] in doc and a["name"] in doc, a["key"] + " human review row")
        check(a["era"] in [1, 2, 3], a["key"] + " natural-era scope")
        check(bool(a["condition"]) and bool(a["proof"]) and bool(a["art"]), a["key"] + " explicit proof/art")
        check(set(a["rewards"]) <= {"resources", "sect_contribution"}, a["key"] + " bounded reward channels")
        check(set(a["rewards"].get("resources", {})) <= resources, a["key"] + " live home reward IDs")
        for k, v in a["rewards"].get("resources", {}).items():
            check(type(v) is int and v > 0, a["key"] + " reward integer")
            rewards_total[k] += v
        if "sect_contribution" in a["rewards"]:
            rewards_total["sect_contribution"] += a["rewards"]["sect_contribution"]
    expected = {"wood": 200, "stone_low": 180, "spirit_grass_low": 90, "lingli": 340, "sect_contribution": 65}
    check(rewards_total == expected, "Achievement reward aggregate matches review table")
    signatures = []
    for e in events:
        check(e["id"] in doc and e["title"] in doc, e["key"] + " human review row")
        check(e["era"] in [1, 2, 3], e["key"] + " playable-era scope")
        check(set(e["requires"]) <= gates, e["key"] + " finite condition whitelist")
        check(e["art"] in {"spring", "traveler", "industry", "sect", "beast", "ruins"}, e["key"] + " assigned art")
        check(len(e["options"]) == 3 and bool(e["desc"]), e["key"] + " complete story/branches")
        for index, opt in enumerate(e["options"]):
            label = e["key"] + "ABC"[index]
            check(bool(opt["text"]) and bool(opt["log"]), label + " original choice/result copy")
            check(set(opt["costs"]) <= resources, label + " home-only cost")
            check(all(type(v) is int and v > 0 for v in opt["costs"].values()), label + " positive integer costs")
            check(set(opt["rewards"]) <= {"resources", "pills", "training_seconds"}, label + " supported fixed effects")
            check(set(opt["rewards"].get("resources", {})) <= resources, label + " home reward IDs")
            check(set(opt["rewards"].get("pills", {})) <= pills, label + " Era2/3 only pill IDs")
            nums = list(opt["rewards"].get("resources", {}).values()) + list(opt["rewards"].get("pills", {}).values())
            if "training_seconds" in opt["rewards"]:
                nums.append(opt["rewards"]["training_seconds"])
            check(all(type(v) is int and v > 0 for v in nums), label + " positive integer rewards")
            check((bool(opt["costs"]) and bool(opt["rewards"])) if index < 2 else (not opt["costs"] and not opt["rewards"]), label + " paid alternatives/free exit")
        a, b = e["options"][:2]
        check(a["rewards"] != b["rewards"], e["key"] + " distinct branch outcomes")
        signatures.append(json.dumps([{k: o[k] for k in ["costs", "rewards"]} for o in e["options"]], sort_keys=True))
    check(len(set(signatures)) == 12, "Not renamed copies of reward pairs")

    # Pool arithmetic only: scenarios explicitly list proposed conditions.
    # No claim of running FortuneSystem, RNG, persistence or natural progression.
    profiles = [
        ("first_life_era1", 1, set(), set()),
        ("first_life_era2_industry_sect_pills", 2, {"wood_open", "timber_completed", "positive_home_arrival", "joined_sect", "new_supply_claimed", "refined_any_p1", "two_p1_consumed"}, set()),
        ("first_life_era3_mature_fox", 3, gates - {"second_life", "any_new_talent"}, set()),
        ("second_life_era1", 1, {"second_life", "any_new_talent"}, set()),
        ("second_life_era3_all_conditions", 3, gates, set()),
    ]
    pool_rows = []
    for name, era, flags, _ in profiles:
        # Stable neutral chrono, no aspiration, current realm_human: old realm bias x3.
        old_weights = [(e["id"], float(e.get("weight", 100)) * (3 if e.get("realm_bias") == "realm_human" else 1))
                       for e in old_events if int(e.get("min_era", 1)) <= era]
        w = sum(value for _, value in old_weights)
        eligible = [e["id"] for e in events if e["era"] <= era and set(e["requires"]) <= flags]
        new_weight = 60 * len(eligible)
        check(w > 0 and new_weight > 0, name + " nonempty old/new pools")
        pool_rows.append({"scenario": name, "era": era, "new_conditions": sorted(flags), "old_count": len(old_weights),
                          "old_effective_weight": w, "new_count": len(eligible), "new_ids": eligible,
                          "new_weight": new_weight, "new_share": new_weight / (w + new_weight),
                          "single_new_share": 60 / (w + new_weight),
                          "conditional_expected_draws_per_new_id": (w + new_weight) / 60})
    check([p["new_count"] for p in pool_rows] == [1, 6, 10, 2, 12], "Review profile eligible counts")
    check(len(json.dumps(proposal, ensure_ascii=False).encode("utf-8")) > 0, "Proposal UTF-8 readable")
    analysis = {"task": proposal["task"], "evidence_kind": "STATIC_PROPOSAL_AND_ARITHMETIC_ONLY", "checks": checks,
                "failures": failures, "protected_files": len(current), "changed_protected_files": changed,
                "baseline_counts": {"achievements": len(old_achievements), "encounters": len(old_events)},
                "proposed_counts": {"achievements": len(achievements), "encounters": len(events), "options": 36},
                "achievement_rewards": dict(rewards_total), "pool_assumptions": "realm_human; neutral weather/shichen; empty aspiration; fixed qualifications",
                "pool_profiles": pool_rows, "proposal_sha256": hashlib.sha256(PROPOSAL.read_bytes()).hexdigest(),
                "not_executed": ["Godot rule/native runners", "browser", "natural flow", "save migration", "image generation", "export"]}
    write(OUT / "analysis.json", analysis)
    print(json.dumps({k: analysis[k] for k in ["checks", "failures", "protected_files", "changed_protected_files", "achievement_rewards"]}, ensure_ascii=False))
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
