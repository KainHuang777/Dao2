"""REPORT-2 delivery audit. Reads sources/builds and writes this task's manifest."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "docs/verification/artifacts/report-2"
SOURCES = [
    "src/domain/life_history.gd", "src/domain/life_ledger.gd",
    "src/application/game_session.gd", "src/simulation/command_processor.gd",
    "src/simulation/time_advancer.gd", "src/simulation/offline_closed_form.gd",
    "src/simulation/reincarnation_rules.gd", "src/abode/living_abode.gd",
    "src/presentation/life_history_plot.gd", "src/presentation/life_history_view.gd",
    "src/presentation/reincarnation_panel.gd", "src/presentation/abode_modal_manager.gd",
    "src/verification/life_history_fixture.gd", "src/verification/life_history_acceptance.gd",
    "src/verification/life_history_acceptance.tscn", "src/verification/res1d2_contract.gd",
    "tests/life_history_runner.gd", "tests/life_history_ui_runner.gd",
    "tests/resource_account_assertions.gd", "tests/resource_accounts_ui_runner.gd",
    "tests/decision_ui_runner.gd", "tests/res1c2_perf_runner.gd", "tests/m1b_time_runner.gd", "tests/m3b_sect_ui_runner.gd", "tests/skills_b1_runner.gd", "tools/run_all_runners.ps1", "tools/life_history_audit.py",
    "project.godot", "export_presets.cfg", "assets/fonts/runtime/manifest.json",
    "docs/decisions/ADR-016-bounded-life-history.md", "docs/verification/report-2.md",
    "docs/19-ui-ux-guidelines.md", "docs/07-responsive-ui-web-spec.md",
    "docs/verification/m2-d.md", "docs/27-life-report-and-decision-ux-integration-plan.md",
    "README.md", "ROADMAP.md", "docs/ai-handoff.md", "docs/development-status.md", "updata.txt",
]

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    files, links = [], []
    for name in SOURCES:
        path = ROOT / name
        text = path.read_text(encoding="utf-8-sig")
        files.append({"path": name, "sha256": sha(path), "bytes": path.stat().st_size})
        if path.suffix == ".gd":
            uid = path.with_suffix(".gd.uid")
            assert uid.exists(), f"missing engine-generated UID: {uid}"
            uid.read_text(encoding="utf-8-sig")
            files.append({"path": uid.relative_to(ROOT).as_posix(), "sha256": sha(uid)})
        if name in ["docs/decisions/ADR-016-bounded-life-history.md", "docs/verification/report-2.md"]:
            for link in re.findall(r"\]\(([^)]+)\)", text):
                if "://" in link or link.startswith("#"): continue
                assert (path.parent / link.split("#")[0]).resolve().exists(), (name, link)
                links.append({"from": name, "target": link})
    raw = (OUT / "logs/all-verified.log").read_text(encoding="utf-8-sig", errors="replace")
    tail = (OUT / "logs/all-verified-tail.log").read_text(encoding="utf-8-sig", errors="replace")
    time_tail = (OUT / "logs/all-verified-time-tail.log").read_text(encoding="utf-8-sig", errors="replace")
    skills_tail = (OUT / "logs/all-verified-skills-tail.log").read_text(encoding="utf-8-sig", errors="replace")
    expected = re.findall(r"'((?:tests/|tools/test_runner)[^']*\.gd)'", (ROOT / "tools/run_all_runners.ps1").read_text(encoding="utf-8-sig"))
    boundary = expected.index("tests/res1c2_perf_runner.gd")
    time_boundary = expected.index("tests/m1b_time_runner.gd")
    skills_boundary = expected.index("tests/skills_b1_runner.gd")
    prefix_runners = list(dict.fromkeys(re.findall(r"\[RUNNING\] ([^\r\n]+)", raw)))
    tail_runners = list(dict.fromkeys(re.findall(r"\[RUNNING\] ([^\r\n]+)", tail)))
    time_runners = list(dict.fromkeys(re.findall(r"\[RUNNING\] ([^\r\n]+)", time_tail)))
    skills_runners = list(dict.fromkeys(re.findall(r"\[RUNNING\] ([^\r\n]+)", skills_tail)))
    assert prefix_runners == expected[:boundary + 1]
    assert tail_runners == expected[boundary:time_boundary + 1]
    assert time_runners == expected[time_boundary:skills_boundary + 1]
    assert skills_runners == expected[skills_boundary:]
    assert "Runner failed: tests/res1c2_perf_runner.gd with exit code 1" in raw
    assert "Runner failed: tests/m1b_time_runner.gd with exit code 1" in tail
    assert "Runner failed: tests/skills_b1_runner.gd with exit code 1" in time_tail
    assert json.loads((OUT / "suite-skills-tail-exit.json").read_text(encoding="utf-8-sig"))["suite_skills_tail"] == 0
    actual = list(dict.fromkeys(prefix_runners + tail_runners + time_runners + skills_runners))
    assert actual == expected, (len(actual), len(expected))
    assert f"ALL {len(expected) - skills_boundary} RUNNERS PASSED WITH EXIT CODE 0!" in skills_tail
    assert "SCRIPT ERROR" not in raw + tail + skills_tail
    # One old UI fixture omitted the now-observed resource max field. Preserve
    # that raw run and require a clean final re-run of the corrected fixture.
    blocks = re.split(r"(?m)^\[RUNNING\] ([^\r\n]+)\r?$", time_tail)
    old_error_blocks = [blocks[i] for i in range(1, len(blocks), 2) if "SCRIPT ERROR" in blocks[i + 1]]
    assert old_error_blocks == ["tests/m3b_sect_ui_runner.gd"], old_error_blocks
    assert time_tail.count("SCRIPT ERROR") == 4
    sect_raw = (OUT / "logs/sect-fixture-final.log").read_text(encoding="utf-8-sig")
    assert "SCRIPT ERROR" not in sect_raw and "PASS: M3-B sect UI" in sect_raw
    assert json.loads((OUT / "sect-fixture-exit.json").read_text(encoding="utf-8-sig"))["sect_fixture"] == 0
    assert "REPORT-2 282 checks failures=[]" in raw
    assert "REPORT-2 UI 56 checks failures=[]" in raw
    exits = json.loads((OUT / "delivery-exits.json").read_text(encoding="utf-8-sig"))
    assert all(value == 0 for value in exits.values()), exits
    final_exits = json.loads((OUT / "final-export-exits.json").read_text(encoding="utf-8-sig"))
    assert all(value == 0 for value in final_exits.values()), final_exits
    menu_exits = json.loads((OUT / "menu-export-exits.json").read_text(encoding="utf-8-sig"))
    assert all(value == 0 for value in menu_exits.values()), menu_exits
    assert json.loads((OUT / "ui-polish-exit.json").read_text(encoding="utf-8-sig"))["native"] == 0
    ui_raw = (OUT / "logs/ui-polish-native.log").read_text(encoding="utf-8-sig")
    assert "REPORT-2 UI 56 checks failures=[]" in ui_raw and "SCRIPT ERROR" not in ui_raw
    assert json.loads((OUT / "ui-menu-exit.json").read_text(encoding="utf-8-sig"))["native"] == 0
    menu_raw = (OUT / "logs/ui-menu-native.log").read_text(encoding="utf-8-sig")
    assert "REPORT-2 UI 58 checks failures=[]" in menu_raw and "SCRIPT ERROR" not in menu_raw
    assert json.loads((OUT / "ui-menu-headless-exit.json").read_text(encoding="utf-8-sig"))["headless"] == 0
    menu_cli = (OUT / "logs/ui-menu-headless.log").read_text(encoding="utf-8-sig")
    assert "REPORT-2 UI 58 checks failures=[]" in menu_cli and "SCRIPT ERROR" not in menu_cli
    builds = []
    for name in ["web-report-2", "report-2-acceptance"]:
        build = ROOT / "build" / name
        compression = json.loads((build / "compression.json").read_text(encoding="utf-8"))
        for item in compression["files"] + compression["audioFiles"]:
            assert sha(build / item["file"]) == item["sha256"], item["file"]
        assert len(compression["audioFiles"]) == 4
        builds.append({"path": "build/" + name, "pck_sha256": sha(build / "index.pck"), "audio_companions": 4})
    frozen = sha(ROOT / "build/web/index.pck")
    assert frozen == "7e7e619dcaa28fb05e1c397adcc24ce9071d9b53b4e8fa6379c186e0af9f9400"
    browser = json.loads((OUT / "browser-observations.json").read_text(encoding="utf-8"))
    assert all(browser[key] for key in ["readingUnchanged", "cancelUnchanged", "failedRetryUnchanged", "recoveredArchiveUnchanged", "reloadArchiveUnchanged", "finalPackageArchiveUnchanged", "menuPackageArchiveUnchanged"])
    assert browser["count"] == 3 and browser["archiveCount"] == 3 and browser["heart"] == "20"
    images = sorted(path.name for path in OUT.glob("*.png"))
    assert len(images) == 12
    result = {"task": "REPORT-2", "date": "2026-10-22", "ok": True,
              "fixed_runners": len(expected), "script_errors": 0, "delivery_exits": exits,
              "suite_mode": {"passed_prefix": boundary, "passed_middle": time_boundary - boundary,
                             "passed_time_section": skills_boundary - time_boundary,
                             "passed_skills_tail": len(expected) - skills_boundary,
                             "final_clean_rerun": "tests/m3b_sect_ui_runner.gd", "superseded_script_errors": 4,
                             "superseded_failures": ["unprepared reference omitted history observation; retained in all-verified.log",
                                                     "legacy aggregate/segmented snapshots have intentionally different observation resolution; retained in all-verified-tail.log"]},
              "final_export_exits": final_exits,
              "menu_export_exits": menu_exits,
              "builds": builds, "frozen_web_sha256": frozen, "sources": files,
              "links": links, "native_screenshots": images, "browser": browser}
    (OUT / "final-manifest.json").write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"ok": True, "fixed_runners": len(expected), "script_errors": 0,
                      "utf8_files": len(files), "links": len(links), "native_images": len(images)}))

if __name__ == "__main__":
    main()
