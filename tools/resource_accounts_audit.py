"""LEDGER-1 evidence audit; reads source/builds and writes only this task's manifest."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs/verification/artifacts/ledger-1"
SOURCES = [
    "src/domain/resource_ledger.gd", "src/domain/life_ledger.gd",
    "src/application/game_session.gd", "src/abode/living_abode.gd",
    "src/presentation/resource_accounts_view.gd", "src/presentation/reincarnation_panel.gd",
    "src/presentation/abode_modal_manager.gd", "src/verification/res1d2_contract.gd",
    "src/verification/resource_accounts_fixture.gd", "src/verification/resource_accounts_acceptance.gd",
    "src/verification/resource_accounts_acceptance.tscn",
    "tests/resource_accounts_runner.gd", "tests/resource_accounts_ui_runner.gd", "tests/resource_account_assertions.gd",
    "tests/res1b_economy_runner.gd", "tests/res1c_progression_runner.gd", "tests/res1c2_offline_runner.gd",
    "tests/offline_closed_form_parity_runner.gd", "tests/res1c2_perf_runner.gd", "tests/skills_b1_runner.gd",
    "tools/run_all_runners.ps1", "tools/resource_accounts_audit.py", "project.godot", "export_presets.cfg",
    "docs/decisions/ADR-015-resource-life-accounts.md", "docs/verification/ledger-1.md",
    "docs/19-ui-ux-guidelines.md", "docs/27-life-report-and-decision-ux-integration-plan.md",
    "README.md", "ROADMAP.md", "docs/ai-handoff.md", "docs/development-status.md", "updata.txt",
]
SOURCES += ["src/simulation/" + name + ".gd" for name in [
    "command_processor", "time_advancer", "offline_closed_form", "offline_economy_jump", "island_economy",
    "island_progression", "processing_system", "processing_inventory", "alchemy_system", "fortune_system",
    "realm_decision_system", "realm_system", "sect_system", "skill_system", "beast_system", "achievement_system", "abode_scenery",
]]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    files = []
    links = []
    for name in SOURCES:
        path = ROOT / name
        content = path.read_text(encoding="utf-8-sig")
        files.append({"path": name, "bytes": path.stat().st_size, "sha256": sha(path)})
        if name.endswith(".gd"):
            uid = path.with_suffix(".gd.uid")
            assert uid.exists(), f"missing engine-generated UID: {uid}"
            uid.read_text(encoding="utf-8-sig")
            files.append({"path": uid.relative_to(ROOT).as_posix(), "bytes": uid.stat().st_size, "sha256": sha(uid)})
        if name in ["docs/decisions/ADR-015-resource-life-accounts.md", "docs/verification/ledger-1.md"]:
            for link in re.findall(r"\]\(([^)]+)\)", content):
                if "://" in link or link.startswith("#"): continue
                target = (path.parent / link.split("#")[0]).resolve()
                assert target.exists(), f"missing link {name}: {link}"
                links.append({"from": name, "target": link})
    raw = (ROOT / "build/ledger1-all-delivery.log").read_text(encoding="utf-8-sig", errors="replace")
    runners = re.findall(r"\[RUNNING\] ([^\r\n]+)", raw)
    expected = re.findall(r"'((?:tests/|tools/test_runner)[^']*\.gd)'", (ROOT / "tools/run_all_runners.ps1").read_text(encoding="utf-8-sig"))
    unique_runners = list(dict.fromkeys(runners))
    assert unique_runners == expected, (len(unique_runners), len(expected))
    assert f"ALL {len(expected)} RUNNERS PASSED WITH EXIT CODE 0!" in raw, "suite incomplete or failed"
    assert "SCRIPT ERROR" not in raw, "runtime script errors in final suite"
    exits = json.loads((OUT / "export-exits.json").read_text(encoding="utf-8-sig"))
    assert all(value == 0 for value in exits.values()), exits
    builds = []
    for name in ["web-ledger-1", "ledger-1-acceptance"]:
        build = ROOT / "build" / name
        manifest = json.loads((build / "compression.json").read_text(encoding="utf-8"))
        for item in manifest["files"]:
            assert sha(build / item["file"]) == item["sha256"], item["file"]
        for item in manifest["audioFiles"]:
            assert sha(build / item["file"]) == item["sha256"], item["file"]
        assert len(manifest["audioFiles"]) == 4
        builds.append({"path": "build/" + name, "pck_sha256": sha(build / "index.pck"), "audio_companions": 4})
    frozen = sha(ROOT / "build/web/index.pck")
    assert frozen == "7e7e619dcaa28fb05e1c397adcc24ce9071d9b53b4e8fa6379c186e0af9f9400"
    browser = json.loads((OUT / "browser-observations.json").read_text(encoding="utf-8"))
    assert browser["bookEqualAfterRecoveryAndReload"] and browser["bookEqualInFinalPackage"]
    assert browser["finalArchives"] == 1 and browser["finalHeart"] == "20" and not browser["finalSaveFailed"]
    screenshots = sorted(path.name for path in OUT.glob("*.png"))
    assert len(screenshots) == 9
    result = {"date": "2026-10-22", "task": "LEDGER-1/REPORT-1B", "ok": True,
              "fixed_runners": len(expected), "script_errors": 0, "export_exits": exits,
              "frozen_web_sha256": frozen, "builds": builds, "native_screenshots": screenshots,
              "parity_source_sha256": sha(OUT / "parity-source.json"), "local_links": links, "sources": files}
    (OUT / "final-manifest.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "fixed_runners": len(expected), "script_errors": 0, "utf8_files": len(files), "links": len(links), "screenshots": len(screenshots)}))

if __name__ == "__main__":
    main()

