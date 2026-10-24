"""Compile approved R46 proposal-1 to runtime data; no player/build writes."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "docs/design-data/res1-e-46-proposal.json"
TARGET = ROOT / "content/supply/era4_6.json"


def compile_content():
    proposal = json.loads(SOURCE.read_text(encoding="utf-8"))
    assert proposal["approval"] == "APPROVED"
    assert all(item["approval"] == "APPROVED" for item in proposal["decisions"])
    names = dict(zip(
        [r["id"] for r in proposal["resources"]],
        ["精鐵", "秘銀", "寒鐵", "千年靈草", "上品靈石", "化神丹", "虛空精華"],
    ))
    building_names = ["三階聚靈庫", "元嬰聚靈庫", "化神聚靈庫", "元嬰修行陣",
                      "化神修行陣", "煉虛修行陣", "寒銀調度", "古藥調度", "太虛調度"]
    resources = {}
    for item in proposal["resources"]:
        resources[item["id"]] = {
            "name": names[item["id"]], "era": item["era"], "tier": 2,
            "cap": str(item["home_cap"]), "source": item["source"], "sinks": item["sinks"],
        }
    recipes = {}
    for item in proposal["recipes"]:
        recipes[item["id"]] = {
            "version": 1, "era": item["era"], "product": item["product"],
            "inputs": {key: str(value) for key, value in item["inputs"].items()},
            "output": str(item["output"]), "facility": {"stone_mine" if item["id"] != "trans_pill" else "herb_farm": 3},
            "skills": {}, "policy": item["policy"],
        }
    buildings = []
    for item, name in zip(proposal["facilities"], building_names):
        required = item["requires"]
        assert len(required) <= 1
        effects = {key + "_max": value for key, value in item.get("flat_caps", {}).items()}
        effects.update(item.get("flat_rates", {}))
        buildings.append({
            "id": item["id"], "name": name, "era": item["era"], "max_level": 1,
            "cost_factor": 1, "prereq": {"building": next(iter(required)), "level": next(iter(required.values()))} if required else None,
            "base_cost": item["cost"], "effect_weight": None, "effects": effects,
        })
    eras = []
    for item in proposal["eras"]:
        eras.append({
            "id": item["id"], "name": item["name"], "max_level": 10,
            "resource_multiplier": item["resource_multiplier"], "lifespan": item["lifespan"],
            "level_up_requirements": {"base_time": item["base_time"], "time_multiplier": item["time_multiplier"],
                                      "resources": item["cost"], "lv9_item": {"type": item["lv9"]["id"], "amount": item["lv9"]["amount"]}},
            "upgrade_requirements": {"level": 10, "capacity": item["exit_capacity"] or {}},
        })
    route_names = ["deep_iron_home", "deep_mithril_home", "deep_cold_home", "ancient_grass_home", "void_essence_home"]
    routes = {}
    for island in proposal["islands"]:
        for product in island["route_products"]:
            routes[route_names[len(routes)]] = [island["id"], "home", product]
    return {
        "version": proposal["save"]["economy_version"],
        "provenance": {"task": "CONTENT-P2-SUPPLY", "proposal": "proposal-1", "source_sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                       "approval_quote": proposal["approval_evidence"]["quote"]},
        "resources": resources, "recipes": recipes, "buildings": buildings, "eras": eras,
        "islands": {item["id"]: item for item in proposal["islands"]}, "routes": routes,
        "durations": {item["id"]: item["seconds"] for item in proposal["recipes"]},
        "dispatch": {"deep": "mineral_focus", "ancient": "ancient_focus", "void": "void_focus"},
        "route_policy": {"seconds": 10, "cargo_per_level": 10, "max_level": 3, "enabled": False, "target": "100"},
    }


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    expected = json.dumps(compile_content(), ensure_ascii=False, indent=2) + "\n"
    if args.check:
        assert TARGET.read_text(encoding="utf-8") == expected, "R46 runtime data differs from approved proposal"
        print("PASS: R46 runtime data matches approved proposal-1")
    else:
        TARGET.parent.mkdir(parents=True, exist_ok=True)
        TARGET.write_text(expected, encoding="utf-8", newline="\n")
        print("Wrote content/supply/era4_6.json")
