# T0-03 — Test harness and helper scripts

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P0 | T0-02 | S | Agent | sim-testing |

## Paste-ready prompt

```text
Run ticket T0-03 (Test harness and helper scripts). Ticket file: agent-kit/tickets/T0-03-test-harness-and-tools.md
Goal: Set up headless testing and the PowerShell helper scripts every later ticket uses for verification.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Set up headless testing and the PowerShell helper scripts every later ticket uses for verification.

## Read first

- `.agent/skills/sim-testing/SKILL.md`
- agent-kit/ARCHITECTURE.md (Tests, Tools)
- `agent-kit/ENV.md`

## Tasks

1. Create `game/tests/run_tests.gd` and `game/tests/test_case.gd` as in the sim-testing skill (`load_constants()` may stay unused until T0-04).
2. Create `game/tests/test_smoke.gd` with one passing test and, temporarily, one failing test. Run it: the runner must print the failure and exit with code 1. Then delete the failing test.
3. Create `game/tests/run_scenarios.gd` stub: prints "no scenarios yet" and exits 0 (filled in T1-08). Create `game/tests/scenarios/` with `.gitkeep`.
4. Create `tools/test.ps1`, `tools/scenarios.ps1`: find Godot from `$env:GODOT`, else from `tools/godot_path.txt` (one line, git-ignored), else stop with a clear message. Run `--import` if `game/.godot` does not exist. Return Godot's exit code.
5. Write the developer's Godot path into `tools/godot_path.txt` (not committed).

## Done when

- [x] `tools\test.ps1` prints PASSED 1 FAILED 0 and exits 0.
- [x] A failing test makes the script exit non-zero (checked once, then removed).

## Verify

- Run `tools\test.ps1` twice from a fresh PowerShell window.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`tools: add headless test runner and helper scripts (T0-03)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `game/tests/run_tests.gd` and `game/tests/test_case.gd` matching the specification in `sim-testing` skill.
2. Create `game/tests/run_scenarios.gd` stub and `game/tests/scenarios/.gitkeep`.
3. Create `tools/godot_path.txt` with `C:\Godot\Godot_v4.6.3-stable_win64_console.exe`.
4. Create `tools/test.ps1` and `tools/scenarios.ps1` to resolve Godot path, run `--import` if `game/.godot` is missing, and execute scripts returning Godot's exit code.
5. Create `game/tests/test_smoke.gd` with a passing test and a temporary failing test; verify failure exit code, then remove the failing test and verify `tools\test.ps1` passes with code 0 twice.

## Handoff

- **What works:** Headless test runner (`game/tests/run_tests.gd`), test base class (`game/tests/test_case.gd`), smoke test suite (`game/tests/test_smoke.gd`), scenario runner stub (`game/tests/run_scenarios.gd`), and PowerShell scripts (`tools/test.ps1`, `tools/scenarios.ps1`). Verified failure detection (exits code 1 on failed assertion) and passing execution (`PASSED 1  FAILED 0` with exit code 0).
- **What to test by hand:** Run `tools\test.ps1` and `tools\scenarios.ps1` in PowerShell.
- **Known issues:** None.
- **Ideas for later:** Ready for T0-04 (Constants loader and game data).


