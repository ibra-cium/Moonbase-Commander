# T1-05 — Greenhouse

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P1 | T1-04 | S | Agent | sim-testing |

## Paste-ready prompt

```text
Run ticket T1-05 (Greenhouse). Ticket file: agent-kit/tickets/T1-05-sim-greenhouse.md
Goal: Plants that need light, water and care, give a little oxygen and science, and never ripen in 30 days (GAME_RULES §7).
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Plants that need light, water and care, give a little oxygen and science, and never ripen in 30 days (GAME_RULES §7).

## Read first

- `agent-kit/GAME_RULES.md`
- agent-kit/ARCHITECTURE.md (Simulation classes)
- `agent-kit/CONVENTIONS.md`
- `.agent/skills/sim-testing/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`

## Tasks

1. `sim/sim_greenhouse.gd` (`SimGreenhouse`): `area`, `alive`, `days_since_farm`, `wilt_days`, `healthy_days`, `growth_days`.
2. `resolve(served: bool, water_kg: float) -> Dictionary` with `healthy`, `o2_kg`, `water_kg` (plant water), `science_point`, `died`.
3. `end_of_day(farmed_today: bool)`.
4. `tests/test_greenhouse.gd`: 10 m² healthy → 0.398 kg O2; a science point every 3 healthy days; two unhealthy days → dead forever; no farm job for 2 days → unhealthy; area 0 does nothing.

## Done when

- [x] All tests pass.

## Verify

- `tools\test.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add greenhouse simulation (T1-05)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `Moonbase-Commander/game/sim/sim_greenhouse.gd` (`class_name SimGreenhouse extends RefCounted`) tracking `area`, `alive`, `days_since_farm`, `wilt_days`, `healthy_days`, and `growth_days`.
2. Implement `resolve(served: bool, water_kg: float) -> Dictionary` applying GAME_RULES §7 formulas: healthy condition, crop oxygen generation, science point every 3 healthy days, wilting after unhealthy days with death on 2 wilt days, and plant water consumption.
3. Implement `end_of_day(farmed_today: bool)` updating `days_since_farm`.
4. Create unit tests in `Moonbase-Commander/game/tests/test_greenhouse.gd` covering all 5 criteria: 10 m² healthy O2 production, science point every 3 healthy days, 2 unhealthy days killing plants permanently, lack of farming for 2 days triggering unhealthy state, and area 0 doing nothing.
5. Verify with `tools\test.ps1` (all tests pass) and ensure no regressions.

## Handoff

### What works
- `SimGreenhouse` fully implements GAME_RULES §7:
  - Tracks `area`, `alive`, `days_since_farm`, `wilt_days`, `healthy_days`, `growth_days`.
  - Determines healthy status from start-of-day greenhouse power served, available water > 0, and days since last farm job < `FARM_EVERY_DAYS` (2).
  - Produces crop oxygen (`CROP_O2_G_M2_DAY * area / 1000` = 0.398 kg O2 for 10 m²).
  - Produces 1 science point every 3 healthy days (`GREENHOUSE_DAYS_PER_POINT`).
  - Consumes plant water (`GREENHOUSE_WATER_L_M2_DAY * area`).
  - Two consecutive unhealthy days cause permanent crop death (`alive = false`, `died = true`).
  - `end_of_day(farmed_today)` resets `days_since_farm` to 0 when farmed, or increments by 1.
  - Zero area greenhouse (`area = 0`) safely does nothing.
- Headless test suite (`tools\test.ps1`): PASSED 52 FAILED 0 with all 7 new unit tests in `game/tests/test_greenhouse.gd`.

### What to test by hand
- Run `tools\test.ps1` in PowerShell to verify the test suite.

### Known issues
- None.

### Ideas for later
- In Phase 2 (T2-03), plant cone scale can visually bind directly to `growth_days`, foliage color can tint brown on wilt, and hide when dead.


