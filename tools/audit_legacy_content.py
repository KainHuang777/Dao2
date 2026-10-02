"""Read-only Dao1 catalog comparison; writes evidence only inside Dao2."""
import argparse
import csv
import hashlib
import json
import re
import subprocess
from collections import Counter
from decimal import Decimal
from pathlib import Path


def read_csv(path):
    with path.open(encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def number(value):
    return Decimal(str(value or 0))


def building_projection(row):
    costs, effects = {}, {}
    for prefix, count in (("basicCost", 4), ("advCost", 2)):
        for index in range(1, count + 1):
            key = row.get(f"{prefix}{index}_type", "0")
            if key and key != "0":
                costs[key] = row[f"{prefix}{index}_amount"]
    for prefix, count in (("effect", 2), ("advEffect", 3)):
        for index in range(1, count + 1):
            key = row.get(f"{prefix}{index}_type", "0")
            if key and key != "0":
                effects[key] = row[f"{prefix}{index}_amount"]
    raw_prereq = row["prereqBuilding"]
    prereq = None
    if raw_prereq and raw_prereq != "0":
        parts = raw_prereq.split(":")
        prereq = {"building": parts[0], "level": int(parts[1]) if len(parts) > 1 else 1}
    return costs, effects, prereq


def numeric_map_equal(left, right):
    return set(left) == set(right) and all(number(left[k]) == number(right[k]) for k in left)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dao1", type=Path, required=True)
    args = parser.parse_args()
    dao1_path = args.dao1.resolve()
    def git_read(*command):
        result = subprocess.run(["git", "--no-optional-locks", "-c", "safe.directory=" + dao1_path.as_posix(),
                                 "-C", str(dao1_path), *command], capture_output=True, encoding="utf-8")
        return {"exit_code": result.returncode, "output": result.stdout.strip(), "error": result.stderr.strip()}
    project = Path(__file__).resolve().parents[1]
    output = project / "docs/verification/artifacts/content-progression-audit"
    output.mkdir(parents=True, exist_ok=True)
    files = ["Resources.csv", "buildings.csv", "storage.csv", "eras.csv", "skills.csv"]
    tables = {name: read_csv(args.dao1 / "src/data" / name) for name in files}
    manifest = json.loads((project / "content/manifest.json").read_text(encoding="utf-8"))
    def load_group(key):
        return [row for name in manifest[key]
                for row in json.loads((project / "content" / name).read_text(encoding="utf-8"))]
    resources, buildings, eras = [load_group(key) for key in ("resource_files", "building_files", "era_files")]
    old_resources = {row["id"]: row for row in tables["Resources.csv"]}
    old_buildings = {row["id"]: row for row in tables["buildings.csv"] + tables["storage.csv"]}
    baseline = (project / "docs/legacy-source-manifest.md").read_text(encoding="utf-8")
    hashes = []
    for name in files:
        src = args.dao1 / "src/data" / name
        digest = hashlib.sha256(src.read_bytes()).hexdigest().upper()
        match = re.search(r"`src/data/" + re.escape(name) + r"`.*?`([A-F0-9]{64})`", baseline)
        public = args.dao1 / "public/data" / name
        hashes.append({"file": name, "rows": len(tables[name]), "sha256": digest,
                       "baseline_sha256": match.group(1) if match else None,
                       "baseline_matches": bool(match and digest == match.group(1)),
                       "public_matches_src": public.exists() and public.read_bytes() == src.read_bytes()})
    resource_comparison = []
    for row in resources:
        old = old_resources.get(row["id"])
        fields = ("type", "max", "rate", "unlocked")
        equal = bool(old) and all(
            number(old[k]) == number(row[k]) if k in ("max", "rate") else
            str(old[k]).lower() == str(row[k]).lower() for k in fields)
        resource_comparison.append({"id": row["id"], "base_fields_match": equal,
                                    "dao1": old, "dao2": row})
    building_comparison = []
    for row in buildings:
        old = old_buildings.get(row["id"])
        costs, effects, prereq = building_projection(old)
        equal = all((number(old["era"]) == number(row["era"]),
                     number(old["maxLevel"]) == number(row["max_level"]),
                     number(old["costFactor"]) == number(row["cost_factor"]),
                     numeric_map_equal(costs, row["base_cost"]),
                     numeric_map_equal(effects, row["effects"]), prereq == row["prereq"],
                     number(old.get("effectWeight")) == number(row["effect_weight"])))
        building_comparison.append({"id": row["id"], "mapped_numeric_fields_match": equal})
    duplicates = {name: [key for key, count in Counter(r["id"] for r in rows).items() if count > 1]
                  for name, rows in tables.items()}
    evidence = {"dao1_path": str(dao1_path), "dao1_git_head": git_read("rev-parse", "HEAD"),
                "dao1_git_status": git_read("status", "--short"), "dao1_files": hashes,
                "counts": {"dao1_resources": len(old_resources),
                           "dao1_recipes": sum(bool(r["recipe"]) for r in old_resources.values()),
                           "dao1_buildings": len(tables["buildings.csv"]),
                           "dao1_storage": len(tables["storage.csv"]),
                           "dao2_resources": len(resources), "dao2_buildings": len(buildings)},
                "dao1_resource_types": dict(Counter(r["type"] for r in old_resources.values())),
                "dao1_buildings_by_era": dict(Counter(r["era"] for r in old_buildings.values())),
                "duplicate_ids": duplicates, "dao2_manifest": manifest,
                "resource_comparison": resource_comparison, "building_comparison": building_comparison,
                "dao1_resources": tables["Resources.csv"],
                "dao1_buildings": tables["buildings.csv"] + tables["storage.csv"],
                "dao1_eras": tables["eras.csv"], "dao2_eras": eras}
    (output / "catalogs.json").write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    lines = ["# 資源／建築／配方逐項清單（2026-10-02）", "", "由 tools/audit_legacy_content.py 產生；CSV 條件不代表 runtime 即時可用，漸進解鎖另見主報告。", "",
             "## 資源", "", "| ID | Dao1 名稱 | 類型 | CSV 境界前置 | CSV 功法前置 | Dao2 |", "| --- | --- | --- | --- | --- | --- |"]
    new_resource_ids = {row["id"] for row in resources}
    new_building_ids = {row["id"] for row in buildings}
    for row in tables["Resources.csv"]:
        lines.append("| " + " | ".join([row["id"], row["name"], row["type"], row["prereqEra"] or "—", row["prereqSkill"] or "—", "開局子集" if row["id"] in new_resource_ids else "未載入"]) + " |")
    lines += ["", "## 建築（含倉儲）", "", "| ID | Dao1 名稱 | Era | 建築前置 | 功法前置 | Dao2 |", "| --- | --- | --- | --- | --- | --- |"]
    for row in evidence["dao1_buildings"]:
        lines.append("| " + " | ".join([row["id"], row["name"], row["era"], row["prereqBuilding"], row["prereqTech"], "開局子集" if row["id"] in new_building_ids else "未載入"]) + " |")
    lines += ["", "## Dao1 合成配方", "", "| 產物 ID | 名稱 | CSV Era | 原料 → 一次合成（加成／隨機另算） | Dao2 |", "| --- | --- | --- | --- | --- |"]
    for row in tables["Resources.csv"]:
        if row["recipe"]:
            recipe = json.loads(row["recipe"])
            status = "同 ID；配方與效果改寫" if row["id"] == "foundation_pill" else "未承接通用配方"
            lines.append("| " + " | ".join([row["id"], row["name"], row["prereqEra"], "＋".join(f"{key} × {value}" for key, value in recipe.items()), status]) + " |")
    lines += ["", "Dao2 另有 cultivation_pill（聚靈丹）、lifespan_pill（延壽丹），皆不是 Dao1 同 ID 配方；來源與差異見主報告。", ""]
    (output / "inventory.md").write_text("\n".join(lines), encoding="utf-8")
    print(json.dumps({"counts": evidence["counts"], "resource_matches": sum(r["base_fields_match"] for r in resource_comparison),
                      "building_matches": sum(r["mapped_numeric_fields_match"] for r in building_comparison),
                      "hashes": hashes, "duplicates": duplicates}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
