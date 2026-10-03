"""Read-only DAO1 content inventory; output evidence inside the DAO2 workspace."""
from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_FILES = (
    "src/data/Resources.csv", "src/data/buildings.csv", "src/data/storage.csv",
    "src/data/eras.csv", "src/data/skills.csv", "src/utils/ResourceManager.ts",
    "src/balance/rules/craft.ts", "src/balance/rules/recipe.ts",
)


def read_text(path: Path) -> str:
    for encoding in ("utf-8-sig", "big5", "cp950"):
        try:
            return path.read_text(encoding=encoding)
        except UnicodeDecodeError:
            continue
    raise ValueError(f"Unsupported text encoding: {path}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--legacy-root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output = args.output.resolve()
    if not output.is_relative_to(ROOT):
        parser.error("Output must stay inside DAO2; the reference project is read-only")
    source = args.legacy_root.resolve()
    manifests, tables = [], {}
    for relative in SOURCE_FILES:
        path = source / relative
        data = path.read_bytes()
        entry = {"path": relative, "sha256": hashlib.sha256(data).hexdigest()}
        if path.suffix == ".csv":
            rows = [row for row in csv.DictReader(io.StringIO(read_text(path))) if row.get("id", "").strip()]
            ids = [row["id"] for row in rows]
            if len(ids) != len(set(ids)):
                raise ValueError(f"Duplicate IDs in {relative}")
            tables[path.stem.lower()] = rows
            entry["records_with_id"] = len(rows)
        manifests.append(entry)
    current_manifest = json.loads(read_text(ROOT / "content/manifest.json"))
    current = {}
    current_sources = []
    for kind in ("resource", "building", "era"):
        records = []
        for relative in current_manifest[f"{kind}_files"]:
            path = ROOT / "content" / relative
            records.extend(json.loads(read_text(path)))
            current_sources.append({"path": f"content/{relative}", "sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
        current[kind] = records
    current_ids = {r["id"] for r in current["resource"]}
    resources = []
    for row in tables["resources"]:
        recipe = json.loads(row["recipe"]) if row["recipe"].strip() else {}
        resources.append({
            "id": row["id"], "name": row["name"], "type": row["type"],
            "prereq_era": row["prereqEra"], "prereq_skill": row["prereqSkill"],
            "recipe": recipe, "in_dao2_resource_manifest": row["id"] in current_ids,
        })
    summary = {
        "legacy_resource_records": len(resources),
        "legacy_resource_types": dict(Counter(r["type"] for r in resources)),
        "legacy_recipes": sum(bool(r["recipe"]) for r in resources),
        "legacy_buildings": len(tables["buildings"]),
        "legacy_storage": len(tables["storage"]),
        "legacy_eras": len(tables["eras"]),
        "dao2_manifest_resources": len(current["resource"]),
        "dao2_manifest_buildings": len(current["building"]),
        "dao2_manifest_eras": [r["id"] for r in current["era"]],
    }
    report = {
        "audit_version": 1, "reference_root": str(source),
        "scope": "Static source inventory, not runtime parity or completion percentage. DAO2 subsystem resources are outside the content manifest.",
        "summary": summary, "legacy_sources": manifests,
        "dao2_content_sources": current_sources, "resources": resources,
        "legacy_era_requirements": tables["eras"],
        "legacy_building_ids_by_era": {era: [r["id"] for r in tables["buildings"] if r["era"] == era] for era in sorted({r["era"] for r in tables["buildings"]}, key=int)},
        "dao2_manifest_resource_ids": sorted(current_ids),
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, ensure_ascii=True))


if __name__ == "__main__":
    main()
