# T1-08 — Balance scenarios S01–S09

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P1 | T1-07 | M | Agent | sim-testing |

## Paste-ready prompt

```text
Run ticket T1-08 (Balance scenarios S01–S09). Ticket file: agent-kit/tickets/T1-08-balance-scenarios.md
Goal: Prove the simulation teaches the right lessons: the nine scenarios in GAME_RULES §10 must give exactly the expected outcomes.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Prove the simulation teaches the right lessons: the nine scenarios in GAME_RULES §10 must give exactly the expected outcomes.

## Read first

- agent-kit/GAME_RULES.md §10
- `.agent/skills/sim-testing/SKILL.md`
- `agent-kit/reference/sim_prototype.py`

## Tasks

1. Write `tests/scenarios/S01…S09.json` from the §10 table (cargo, seed 1, rule, forced days, expected outcome/day/stars/root).
2. Fill `tests/run_scenarios.gd`: plan rules `NOFIX`, `REST`, `SMART` exactly as §10; build each day's `SimPlan` from the current report; print the results table; exit 1 on any mismatch.
3. If Python is installed, run `agent-kit/reference/sim_prototype.py` with the repo's constants.json and compare. If a result differs, print the day-by-day state from both and find the first different step. Fix the GDScript to match GAME_RULES (the spec), not the other way round.
4. Write the final results table into the ticket handoff.

## Done when

- [x] `tools\scenarios.ps1` prints 9 ✓ and exits 0.
- [x] GDScript and the Python reference agree on outcome, end day and stars for all nine.

## Verify

- `tools\test.ps1`
- `tools\scenarios.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add balance scenarios S01-S09 (T1-08)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create 9 scenario JSON definition files `game/tests/scenarios/S01_solar_only.json` through `S09_recycler_fixed.json` mapping parameters and expectations from GAME_RULES §10.
2. Implement scenario runner in `game/tests/run_scenarios.gd`: load all scenario files, implement plan rules `NOFIX`, `REST`, `SMART` using day report state, run each mission through `SimMission` (or validate cargo limit for S08), and verify outcome, end day, stars, and root cause against expectations.
3. Format and print the results table matching the specification, returning exit code 1 if any scenario fails or 0 if all 9 pass.
4. Verify by running `tools\test.ps1` and `tools\scenarios.ps1`, comparing results against `sim_prototype.py`.

## Handoff

### What works
- 9 scenario definitions S01–S09 in `game/tests/scenarios/` matching GAME_RULES §10.
- Scenario runner `game/tests/run_scenarios.gd` executes all scenarios, applies plan policies (`NOFIX`, `REST`, `SMART`), checks cargo limits, and outputs the formatted balance results table.
- 100% agreement with the Python prototype reference model (`agent-kit/reference/sim_prototype.py`).
- Headless scenario runner (`tools\scenarios.ps1`) exits 0 with 9/9 passes.
- Unit test suite (`tools\test.ps1`) passes cleanly: 66 PASSED, 0 FAILED.

### Final Results Table
```text
ID                       OUTCOME           DAY  STARS  ROOT                 OK
S01_solar_only           EVAC_CO2           18      0  ROOT_NIGHT_ENERGY    ✓
S02_two_reactors         SURVIVED           30      2  ROOT_SUCCESS         ✓
S03_one_reactor          SURVIVED           30      2  ROOT_SUCCESS         ✓
S04_max_batteries        EVAC_CO2           21      0  ROOT_NIGHT_ENERGY    ✓
S05_no_shield            EVAC_RADIATION     12      0  ROOT_SHIELD          ✓
S06_recycler_not_fixed   EVAC_WATER         20      0  ROOT_REPAIR          ✓
S07_three_stars          SURVIVED           30      3  ROOT_SUCCESS         ✓
S08_overweight           INVALID             0      0  CARGO_INVALID        ✓
S09_recycler_fixed       SURVIVED           30      2  ROOT_SUCCESS         ✓

Scenarios passed: 9 / 9
```

### What to test by hand
- Run `tools\scenarios.ps1` in PowerShell.
- Run `tools\test.ps1` in PowerShell.
- Run `python agent-kit\reference\sim_prototype.py Moonbase-Commander\game\data\constants.json` to verify parity.

### Known issues / notes
- None.

### Ideas for later
- In Phase 3 UI, scenarios S01–S09 can also be used as test presets for developer debug play.
