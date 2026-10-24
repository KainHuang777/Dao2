"""Audit the bounded SUPPLY-2 evidence; never runs Godot or reads player saves."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "docs/verification/artifacts/content-p2-supply"
SOURCES = [
    "src/content/supply_content.gd", "src/application/game_session.gd",
    "src/application/offline_coordinator.gd", "src/domain/resource_ledger.gd",
    "src/persistence/save_codec.gd", "src/persistence/save_manager.gd",
    *[f"src/simulation/{name}.gd" for name in [
        "island_economy", "island_progression", "processing_system", "command_processor",
        "time_advancer", "offline_closed_form", "offline_economy_jump",
        "reincarnation_rules", "story_progress",
    ]],
    "tests/content_p2_supply_economy_runner.gd", "tests/m1c_persistence_runner.gd",
    "tests/m1d_offline_runner.gd", "tools/run_all_runners.ps1",
    "docs/verification/content-p2-supply-2.md",
]
GROUPS = {
    "supply2-l1-logs": ["content_p2_supply_data", "res1a_processing", "res1b_economy", "res1c_progression"],
    "supply2-l2-logs": ["resource_accounts", "m1a_core", "res1c2_offline"],
    "long-final-logs": ["res1d2_integration", "offline_closed_form_parity"],
    "save-final-logs": ["m1d_offline"],
    "m1c-final-logs": ["m1c_persistence"],
    "economy-final-logs": ["content_p2_supply_economy"],
}


def main():
    failures, runners, hashes = [], {}, {}
    for folder, names in GROUPS.items():
        for name in names:
            base = ART / folder / f"tests_{name}_runner.gd.initial.log"
            try:
                stdout = base.read_text(encoding="utf-8-sig")
                stderr = Path(str(base) + ".err").read_text(encoding="utf-8-sig")
                command = (ART / (folder.removesuffix("-logs") + ".log")).read_text(encoding="utf-8-sig")
                valid = ("PASS:" in stdout or "failures=[]" in stdout) and "SCRIPT ERROR:" not in stdout + stderr and f"[PASS:initial] tests/{name}_runner.gd" in command
                if not valid:
                    failures.append(f"runner evidence: {name}")
                runners[name] = {"passed": valid, "stdout": str(base.relative_to(ROOT)),
                                 "sha256": hashlib.sha256(base.read_bytes()).hexdigest()}
            except (OSError, UnicodeError) as exc:
                failures.append(f"{name}: {exc}")
    result = json.loads((ART / "economy-contract.json").read_text(encoding="utf-8"))
    if result["checks"] != 283 or result["failures"]:
        failures.append("final economy report")
    for source in SOURCES:
        data = (ROOT / source).read_bytes()
        data.decode("utf-8-sig", errors="strict")
        hashes[source] = hashlib.sha256(data).hexdigest()
    if len(runners) != 12:
        failures.append("expected twelve unique selected runners")
    report = {"date": "2026-10-24", "level": "L1 plus bounded L2; not L3",
              "stage": "SUPPLY-2 economy/save core; player entry still D2",
              "checks": result["checks"], "unique_runners": len(runners),
              "runners": runners, "source_sha256": hashes, "failures": failures}
    (ART / "supply2-delivery-audit.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"unique_runners": len(runners), "economy_checks": result["checks"], "failures": failures}))
    return bool(failures)


if __name__ == "__main__":
    raise SystemExit(main())
