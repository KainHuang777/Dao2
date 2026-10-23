"""Synthetic proposal audit, not Godot gameplay or save acceptance.

python tools/content_p1_sect_design_audit.py --capture-baseline  # once
python tools/content_p1_sect_design_audit.py
Writes only docs/verification/artifacts/content-p1-sect-design/*.json.
"""
from pathlib import Path
from decimal import Decimal as D, ROUND_CEILING, ROUND_FLOOR
import ast
import hashlib
import itertools
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/verification/artifacts/content-p1-sect-design"
PROPOSAL = ROOT / "docs/design-data/content-p1-sect-proposal.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read(path):
    return path.read_text(encoding="utf-8-sig")


def write(name, value):
    (OUT / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def protected():
    files = [p for folder in ("src", "content", "tests", "assets")
             for p in (ROOT / folder).rglob("*") if p.is_file()]
    files += [ROOT / p for p in ("project.godot", "export_presets.cfg", "build/web/index.pck") if (ROOT / p).is_file()]
    return {p.relative_to(ROOT).as_posix(): sha(p) for p in sorted(files)}


def constant(path, name):
    # These source constants are Python-literal-compatible dictionaries.
    text = read(ROOT / path)
    match = re.search(r"const " + name + r" := ([\s\S]*?)(?=\nconst |\nstatic func )", text)
    if not match:
        raise ValueError(f"Missing constant: {name}")
    return ast.literal_eval(match[1].strip())


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    base_file = OUT / "session-start.json"
    if "--capture-baseline" in sys.argv:
        if base_file.exists():
            raise RuntimeError("Baseline exists; refusing to overwrite evidence")
        write("session-start.json", {"date": "2026-10-23", "protected": protected()})
    baseline = json.loads(read(base_file))["protected"]
    current = protected()
    failures = []
    checks = 0

    def check(ok, label):
        nonlocal checks
        checks += 1
        if not ok:
            failures.append(label)

    changes = sorted(k for k in set(baseline) | set(current) if baseline.get(k) != current.get(k))
    check(not changes, "protected runtime/content/tests/assets/config/frozen Web unchanged")
    p = json.loads(read(PROPOSAL))
    check(p["status"] == "APPROVED_FOR_IMPLEMENTATION" and p.get("approval") == {"date": "2026-10-23", "user_quote": "採Q", "groups": ["Q1", "Q2", "Q3", "Q-save"]}, "explicit Q approval recorded")
    engine = subprocess.run([str(ROOT / "tools/godot/4.7.2/Godot_v4.7.2-stable_win64_console.exe"), "--version"], capture_output=True, text=True)
    check(engine.returncode == 0 and engine.stdout.strip() == "4.7.2.stable.official.ed1daf0bf", "existing engine version")
    sect_source = "src/simulation/sect_system.gd"
    techs = constant(sect_source, "TECHNIQUES")
    market = constant(sect_source, "MARKET_ITEMS")
    templates = constant(sect_source, "TASK_TEMPLATES")
    rarities = constant(sect_source, "RARITY_CONFIGS")
    pills = constant("src/simulation/alchemy_system.gd", "PILLS")
    beasts = constant("src/simulation/beast_system.gd", "BEAST_CONFIGS")
    stages = constant("src/simulation/beast_system.gd", "STAGE_CONFIGS")
    soul_talents = constant("src/simulation/beast_system.gd", "BEAST_TALENTS")
    check((len(techs), sum(map(len, templates.values())), len(market)) == (4, 15, 4), "runtime baseline counts")
    check(len(techs) + len(p["techniques"]) == 6 and sum(map(len, templates.values())) + len(p["task_templates"]) == 20 and len(market) + len(p["market_items"]) == 6, "target counts")
    ids = [x["id"] for x in p["techniques"] + p["market_items"]] + [x["template_id"] for x in p["task_templates"]]
    check(len(ids) == len(set(ids)) == 9, "nine unique proposed content IDs")
    check(not set(ids) & (set(techs) | set(market)), "no runtime ID collision")
    costs = []
    for t in p["techniques"]:
        check(t["min_era"] in (2, 3) and t["max_level"] == 5, t["id"] + " scope")
        check(D(t["effect_per_level"]) * t["max_level"] == D("0.10"), t["id"] + " capped 10%")
        rows = []
        for level in range(t["max_level"]):
            scale = D(t["cost_scale"]) ** level
            row = {"rank": level + 1, "contribution": int((D(t["base_contrib"]) * scale).to_integral_value(rounding=ROUND_CEILING)), "materials": {key: int((D(v) * scale).to_integral_value(rounding=ROUND_CEILING)) for key, v in t["resource_cost"].items()}}
            rows.append(row)
            check(row["contribution"] > 0 and all(v > 0 for v in row["materials"].values()), t["id"] + " positive cost")
        costs.append({"id": t["id"], "ranks": rows, "total_contribution": sum(x["contribution"] for x in rows), "total_materials": {key: sum(x["materials"][key] for x in rows) for key in t["resource_cost"]}})
    check([x["total_contribution"] for x in costs] == [792, 1188], "documented cumulative contributions")
    check([x["total_materials"] for x in costs] == [{"stone_low": 68}, {"wood": 1320}], "documented cumulative materials")
    allow = set(p["techniques"][0]["pill_allowlist"])
    check(len(allow) == 4 and allow <= set(pills), "four existing direct pills")
    discount_cases = 0
    examples = []
    for pill_id, definition in pills.items():
        for rank, skill, count in itertools.product(range(6), range(4), (1, 2, 10, 99)):
            paid = {}
            for resource, value in definition["cost"].items():
                base = D(str(value))
                factor = D(1) - D("0.02") * rank if resource == "spirit_grass_low" and pill_id in allow else D(1)
                skill_factor = D(1) - D("0.05") * skill if resource == "lingli" and pill_id in ["cultivation_pill", "high_cultivation_pill", "spirit_tide_pill", "wood_nurture_pill", "herb_nurture_pill", "wealth_gathering_pill", "qi_absorption_pill"] else D(1)
                actual = base * factor * skill_factor * count
                check(actual == sum([base * factor * skill_factor] * count), "batch equivalence")
                check(actual > 0 and actual <= base * count, "positive bounded proposed cost")
                if pill_id not in allow:
                    check(factor == 1, "eight excluded pills keep grass cost")
                paid[resource] = str(actual)
            discount_cases += 1
            if pill_id == "cultivation_pill" and rank == 5 and skill == 3 and count in (1, 99):
                examples.append({"pill": pill_id, "rank": rank, "skill_rank": skill, "count": count, "paid": paid})
    fox_base = D(str(beasts["jade_fox"]["feed_resource"]["spirit_grass_low"]))
    soul_discount = D(str(soul_talents["fox_t3_cheap"]["value"]))
    soul_growth = D(str(soul_talents["fox_t2_speed"]["value"]))
    threshold = stages["growing"]["max_exp"]
    fox_rows = []
    for soul_cost, soul_xp, talent, rank in itertools.product((D(0), soul_discount), (D(0), soul_growth), range(6), range(6)):
        fee = max(1, int((fox_base * (1 - soul_cost) * (1 - D("0.02") * rank)).to_integral_value(rounding=ROUND_FLOOR)))
        xp = int((D(50) * (1 + soul_xp)).to_integral_value(rounding=ROUND_FLOOR)) + 10 * talent
        feeds = int((D(threshold) / xp).to_integral_value(rounding=ROUND_CEILING))
        previous_fee = max(1, int((fox_base * (1 - soul_cost)).to_integral_value(rounding=ROUND_FLOOR)))
        check(0 < fee <= previous_fee and xp > 0, "fox fee does not alter XP")
        fox_rows.append({"soul_discount": str(soul_cost), "soul_growth": str(soul_xp), "talent_rank": talent, "technique_rank": rank, "feed_cost": fee, "xp": xp, "feeds_to_mature_from_zero": feeds, "total_grass": fee * feeds, "saved_grass": (previous_fee - fee) * feeds})
    check([max(1, int((fox_base * (1 - soul_discount) * (1 - D("0.02") * rank)).to_integral_value(rounding=ROUND_FLOOR))) for rank in range(6)] == [30, 29, 28, 28, 27, 27], "rounding plateaus explicitly shown")
    rarity_rows = []
    check(sum(c["weight"] for c in rarities.values()) == 100, "baseline rarity weights")
    check({x["rarity"] for x in p["task_templates"]} == set(rarities), "one new template per rarity")
    for t in p["task_templates"]:
        cfg = rarities[t["rarity"]]
        check(len(templates[t["rarity"]]) == 3, "three existing templates per rarity")
        check(t["min_era"] in (2, 3) and set(t["rewards"]) <= {"wood", "stone_low", "spirit_grass_low"}, t["template_id"] + " reachable reward resources")
        check(all(v > 0 for v in t["rewards"].values()), t["template_id"] + " positive rewards")
        mean = D(cfg["contrib_min"] + cfg["contrib_max"]) / 2
        rarity_rows.append({"rarity": t["rarity"], "duration": cfg["duration"], "mean_contribution": str(mean), "mean_contribution_per_second": str(mean / cfg["duration"]), "new_template_slot_probability_all_eligible": str(D(cfg["weight"]) / 400)})
    eligibility_cases = 0
    for era, wood, ore, herb, fox in itertools.product((1, 2, 3), (False, True), (False, True), (False, True), (False, True)):
        opened = {key for key, flag in (("wood", wood), ("ore", ore), ("herb", herb)) if flag}
        for t in p["task_templates"]:
            eligible = era >= t["min_era"] and set(t["requires_open_islands"]) <= opened and (not t["requires_active_beast"] or fox)
            n = 3 + int(eligible)
            check(n in (3, 4), "filter never empties a rarity pool")
            check((D(3) / n + D(int(eligible)) / n) == 1, "conditional selection probability normalized")
            eligibility_cases += 1
    expected_contribution = sum(D(c["weight"]) / 100 * D(c["contrib_min"] + c["contrib_max"]) / 2 for c in rarities.values())
    expected_duration = sum(D(c["weight"]) / 100 * D(c["duration"]) for c in rarities.values())
    check(expected_contribution == D("66.2") and expected_duration == 192, "documented random-slot averages")
    shop_rows = []
    for item in p["market_items"]:
        check(item["limit"] == 10 and item["cost"] > 0, "positive lifetime shop bound")
        if "grant_pill" in item:
            check(item["grant_pill"] in pills and pills[item["grant_pill"]]["min_era"] <= item["min_era"], "shop pill exists and respects era")
    for rate, room in itertools.product(map(D, ("0", "0.1", "0.25", "0.5", "1", "5")), map(D, ("0", "50", "75", "150", "1500"))):
        extra = min(room, 300 * rate)
        check(extra >= 0 and extra <= room and extra <= 300 * rate, "shop pill synthetic capacity clipping")
        shop_rows.append({"pre_same_resource_buff_rate": str(rate), "headroom": str(room), "max_extra_grass": str(extra), "beats_75_grass_ratio_reference": extra > 75})
    check(D(45) / 30 * 50 == 75 and D(75) / 300 == D("0.25"), "shop comparison break-even")
    source_paths = [sect_source, "src/simulation/beast_system.gd", "src/simulation/alchemy_system.gd", "src/simulation/talent_system.gd", "src/simulation/skill_system.gd", "src/simulation/reincarnation_rules.gd", "src/persistence/save_codec.gd", "src/persistence/save_manager.gd", "src/domain/game_state.gd", "src/application/game_session.gd", "src/presentation/sect_panel.gd", "src/simulation/island_progression.gd", "src/simulation/command_processor.gd"]
    for doc in (ROOT / "docs/32-content-p1-sect-design.md", ROOT / "docs/verification/content-p1-sect.md"):
        check(doc.exists(), "delivery document " + doc.name)
        if doc.exists():
            for target in re.findall(r"\]\(([^)]+)\)", read(doc)):
                if "://" not in target and not target.startswith("#"):
                    check((doc.parent / target.split("#")[0]).exists(), "local link " + target)
    report = {"kind": "synthetic design audit; NOT gameplay acceptance", "checks": checks, "failures": failures, "protected_files": len(baseline), "protected_changes": changes, "engine": {"exit_code": engine.returncode, "version": engine.stdout.strip()}, "baseline_counts": p["baseline"], "proposed_counts": p["target"], "proposal_sha256": sha(PROPOSAL), "source_hashes": {x: sha(ROOT / x) for x in source_paths}, "costs": costs, "alchemy_scenarios": discount_cases, "alchemy_examples": examples, "fox_scenarios": len(fox_rows), "fox_rows": fox_rows, "task_eligibility_scenarios": eligibility_cases, "rarity_rows": rarity_rows, "random_slot_mean_contribution": str(expected_contribution), "random_slot_mean_duration": str(expected_duration), "shop_scenarios": len(shop_rows), "shop_rows": shop_rows}
    write("analysis.json", report)
    print(json.dumps({key: report[key] for key in ("checks", "failures", "protected_files", "protected_changes", "alchemy_scenarios", "fox_scenarios", "task_eligibility_scenarios", "shop_scenarios")}, ensure_ascii=False))
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
