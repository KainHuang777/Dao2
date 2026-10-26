"""Static PILL-1 delivery audit. Does not run Godot or write player saves."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs/verification/artifacts/content-p2-pills"
checks = []


def check(ok, label):
    checks.append({"label": label, "ok": bool(ok)})


def read(path):
    return (ROOT / path).read_text(encoding="utf-8-sig", errors="strict")


def main():
    source = read("src/simulation/alchemy_system.gd")
    proposal = json.loads(read("docs/design-data/content-p2-pills-proposal.json"))
    for pill in proposal["pills"]:
        line = next(s for s in source.splitlines() if s.startswith('\t"' + pill["id"] + '": {"id":'))
        definition = json.loads("{" + line.strip().rstrip(",") + "}")[pill["id"]]
        for field, expected in [("name", pill["name"]), ("cost", pill["cost"]), ("min_era", pill["era"])]:
            check(definition[field] == expected, pill["id"] + ":" + field)
        check(pill["art_status"] == "NOT_GENERATED", pill["id"] + ":art pending")
    check('const VERSION := 2' in source, "pill_version2")
    check('const SCHEMA_VERSION := 5' in read("src/persistence/save_codec.gd"), "schema5")
    check('PILL_RULES_VERSION if state.pill_version >= 2 else TALENT_RULES_VERSION' in read("src/persistence/save_codec.gd"), "pill identity precedence")
    check(proposal["status"] == "PILL_1_DONE_PILL_2_TODO", "bounded task status")
    for name in ["core", "save"]:
        result = json.loads((OUT / (name + ".json")).read_text(encoding="utf-8"))
        check(not result["failures"] and result["checks"] >= 400, name + " final checks")
    restoration = json.loads((OUT / "restoration.json").read_text(encoding="utf-8"))
    check(not restoration["failures"], "baseline restore verification")
    for row in restoration["restored"]:
        # The separately documented earlier talent report takes precedence.
        prior = restoration["earlier_direct_run_reconciled"]
        expected = prior["sha256"] if row["path"] == prior["path"] else row["restored_sha256"]
        check(hashlib.sha256((ROOT / row["path"]).read_bytes()).hexdigest() == expected, "restored " + row["path"])
    latest = {}
    for group in json.loads((OUT / "logs-index.json").read_text(encoding="utf-8")):
        for path in (OUT / "logs" / group["id"]).glob("*.log"):
            markers = re.findall(r"RUNNER_RESULT status=(\w+) exit=(-?\d+)", path.read_text(encoding="utf-8-sig", errors="replace"))
            if markers:
                latest[path.name] = {"status": markers[-1], "group": group["id"]}
    check(len(latest) == 13, "13 unique selected runners")
    for name, row in latest.items():
        check(row["status"] == ("PASS", "0"), "latest selected result " + name)
    for name in ["tests/content_p2_pills_runner.gd", "tests/content_p2_pills_save_runner.gd"]:
        check(name in read("tools/run_all_runners.ps1"), "registered " + name)
    doc = ROOT / "docs/verification/content-p2-pills-core.md"
    for target in re.findall(r"\]\(([^)]+)\)", doc.read_text(encoding="utf-8")):
        check((doc.parent / target.split("#")[0]).exists(), "report link " + target)
    files = [
        "src/simulation/alchemy_system.gd", "src/simulation/buff_system.gd",
        "src/simulation/tribulation_rules.gd", "src/simulation/production.gd",
        "src/simulation/island_economy.gd", "src/simulation/time_advancer.gd",
        "src/simulation/offline_closed_form.gd", "src/simulation/command_processor.gd",
        "src/simulation/story_progress.gd", "src/application/game_session.gd",
        "src/domain/life_history.gd", "src/persistence/save_codec.gd", "src/persistence/save_manager.gd",
        "tests/content_p2_pills_runner.gd", "tests/content_p2_pills_save_runner.gd",
        "tests/content_p1_pills_runner.gd", "tests/content_p2_supply_economy_runner.gd",
        "tools/run_all_runners.ps1", "tools/content_p2_pills_audit.py",
        "README.md", "ROADMAP.md", "docs/ai-handoff.md", "docs/development-status.md",
        "docs/25-system-content-expansion-plan.md", "docs/37-content-p2-pill-design.md",
        "docs/design-data/content-p2-pills-proposal.json", "updata.txt",
        "docs/verification/content-p2-pills-core.md",
    ]
    hashes = {}
    for name in files:
        read(name)
        hashes[name] = hashlib.sha256((ROOT / name).read_bytes()).hexdigest()
        check(True, "UTF-8 " + name)
    failures = [row["label"] for row in checks if not row["ok"]]
    (OUT / "delivery-audit.json").write_text(json.dumps({
        "level": "L1 static / L2 selected evidence", "checks": checks,
        "failures": failures, "latest_runners": latest, "sha256": hashes,
    }, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"PILL-1 static: {len(checks)} checks, failures={failures}")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
