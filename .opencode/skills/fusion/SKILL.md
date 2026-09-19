---
name: fusion
description: Use ONLY when the user asks to run a task through model fusion — a deepseek-v4.1-flash primary orchestrating lightweight worker subagents. Triggers include "fusion", "fusion skill", "/fusion-*", "組合模型", or any request to split a task across several lighter models. Do not use for ordinary single-agent work.
---

# Fusion orchestration

Model fusion = one strong orchestrator (the primary agent, deepseek-v4.1-flash)
decomposes a task, fans work out to several lightweight worker subagents in
parallel, then fuses and verifies their output. The orchestrator owns every
integration decision; workers are interchangeable and never own shared files.

## Roster

| Subagent | Model | Role |
| --- | --- | --- |
| `fusion-worker-a` | glm-5.3-flash | implementation worker |
| `fusion-worker-b` | qwen3.8-flash | implementation worker |
| `fusion-worker-c` | deepseek-v4-flash | implementation worker |
| `fusion-worker-d` | nemotron-3.5-lightning-free | implementation worker |
| `fusion-scout` | qwen3.8-flash | read-only research (no edits) |
| `fusion-auditor` | glm-5.3-flash | independent verification (no edits) |

## Protocol (follow in order)

1. **Load truth.** Read `AGENTS.md`, the task brief (e.g.
   `docs/m1-b-execution-plan.md`), `docs/development-status.md`, and the
   existing source files the task builds on. Never plan from memory.
2. **Freeze interfaces.** Write the exact class names, method signatures,
   constants, and return shapes into the brief BEFORE dispatch. Workers must
   not invent interfaces.
3. **Partition by file ownership.** Give each worker a disjoint file set.
   Shared/integration files (state, session, existing modules) belong to the
   orchestrator, never to a worker. A file must have exactly one writer.
4. **Fan out.** Dispatch workers in parallel in a single message. Every worker
   prompt must contain: its owned file paths, the frozen signatures, the exact
   rules/formulas with fixture vectors, the constraints (Godot 4.7.2 GDScript,
   Compatibility, UTF-8, no comments, `AmountCompat` only, keep `.uid` files),
   and the required self-report (files written, signatures, how it self-checked).
   State explicitly: do NOT run the Godot engine, do NOT edit files outside
   ownership, do NOT run `--import`.
5. **Fuse.** Integrate results, resolve interface drift, keep naming
   consistent. Only the orchestrator edits shared files.
6. **Verify once.** The orchestrator serializes engine access: run `--import`
   then the headless runner exactly once, capture output to a UTF-8 file, require
   exit code 0, and grep the output for `SCRIPT ERROR` (a runner can report PASS
   while script errors occur). Eval tests must not be trusted from worker claims
   alone.
7. **Audit independently.** Dispatch `fusion-auditor` (read-only) to read the
   final diff against the DoD and list gaps; dispatch `fusion-scout` for any
   remaining legacy research. Fix real gaps, reject false ones with evidence.
8. **Record.** Update `docs/verification/<task>.md` and
   `docs/development-status.md` with commands, exit codes, real output, and
   unverified items. Update `docs/rule-differences.md` for any new parity or v2
   decision.
9. **Report.** Summarize deliverables, evidence, unverified items, and the next
   task to the user.

## Hard rules

- Headless contract tests are not browser/interaction evidence. Never claim
  touch, FPS, rendering, or persistence passes from a runner.
- Determinism is the point: same state + same command/elapsed must give
  identical results. Domain code never reads the system clock; elapsed time is
  injected by the coordinator.
- Prefer smaller, well-scoped workers over one big worker. If a worker returns
  code that does not compile or violates ownership, fix it in the orchestrator —
  do not silently accept it.
- Do not commit unless the user explicitly asks.
