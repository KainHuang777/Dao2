---
description: Execute M1-B (統一時間與修行／壽元) via the fusion skill.
agent: build
---

Run the **fusion** skill to execute **M1-B — 統一時間與修行／壽元** for this project.

Steps:

1. Load the `fusion` skill and read `docs/m1-b-execution-plan.md` (the frozen brief),
   plus `AGENTS.md`, `ROADMAP.md`, `docs/development-status.md`,
   `docs/rule-differences.md`, and the existing M1-A sources under `src/`.
2. Confirm the frozen interfaces and the file-ownership partition in the brief.
   Use `fusion-scout` first for any legacy value still marked TODO in the brief.
3. Fan out the implementation workers (`fusion-worker-a`..`-d`) in parallel with
   disjoint file ownership; the orchestrator alone owns shared files and
   `content/`.
4. Fuse, then run `--import` and `tests/m1b_time_runner.gd` once, serially.
   Capture output to a UTF-8 file, require exit code 0, and grep for `SCRIPT ERROR`.
5. Dispatch `fusion-auditor` to verify against the DoD; fix real gaps.
6. Update `docs/verification/m1-b.md`, `docs/development-status.md`, and
   `docs/rule-differences.md`. Do not commit unless the user asks.
7. Report deliverables, evidence (commands + exit codes + real output), and
   unverified items.
