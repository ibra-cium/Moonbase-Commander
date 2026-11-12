# T1-07 — Mission loop, end checks, stars and debrief + GameState

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P1 | T1-06 | L | Agent | sim-testing, nasa-data |

## Paste-ready prompt

```text
Run ticket T1-07 (Mission loop, end checks, stars and debrief + GameState). Ticket file: agent-kit/tickets/T1-07-sim-mission-and-debrief.md
Goal: Tie all systems into `SimMission.step_day(plan)` in the exact order of GAME_RULES §4, add end checks, stars, cause chain, root cause and fact, and connect it to the `GameState` autoload.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Tie all systems into `SimMission.step_day(plan)` in the exact order of GAME_RULES §4, add end checks, stars, cause chain, root cause and fact, and connect it to the `GameState` autoload.

## Read first

- `agent-kit/GAME_RULES.md`
- agent-kit/ARCHITECTURE.md (Simulation classes)
- `agent-kit/CONVENTIONS.md`
- `.agent/skills/sim-testing/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`
- `game/data/facts.json`

## Tasks

1. `sim/sim_mission.gd` (`SimMission`): `setup(constants, cargo, seed, force := {})`, `step_day(plan) -> SimDayReport`, `day`, `ended`, `result`, `cargo`.
2. `sim/sim_day_report.gd`: day, sun factor, generation, battery, served/shed, stocks, CO2, crew (job, sick, dose), greenhouse, shelter g/cm², dust, broken things, events of the day, new log ids, `hours_on_battery`.
3. `sim/sim_result.gd` + `sim/sim_debrief.gd`: outcome code, end day, stars (§9.2), cause chain text items (§9.3), root cause code + values (§9.4), fact id (§9.5).
4. `autoload/game_state.gd`: `new_mission(cargo, seed)` emits `mission_started`, then `day_started(day, popups)`; `submit_day(plan)` steps the mission and emits `event_triggered` for each event, `day_resolved`, then `mission_ended` or the next `day_started`.
5. `tests/test_mission.gd`: the S02 setup (base cargo, rule REST, forced storm 10, no recycler break, no meteoroid) survives 30 days with 2 stars; the end checks run in the §9.1 order; the root cause rules pick the right code for night energy, shield, repair and supply cases; same seed + plans → same result.

## Done when

- [x] All tests pass.
- [x] `GameState` emits the signals in the documented order (test with a small listener object).

## Verify

- `tools\test.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add mission loop, debrief and GameState (T1-07)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `sim/sim_day_report.gd`: state snapshot container capturing power, stocks, life support, crew health, greenhouse, shelter, events, and log ids.
2. Create `sim/sim_result.gd` and `sim/sim_debrief.gd`: outcome, stars evaluation (§9.2), cause chain construction (§9.3), root cause identification (§9.4), and fact selection (§9.5) from `facts.json`.
3. Create `sim/sim_mission.gd`: orchestrate daily cycle in exact order of GAME_RULES §4 (start-of-day events, jobs, power, greenhouse, life support, radiation/storm, sickness, end checks §9.1, job effects, end-of-day events, day increment / survival).
4. Update `autoload/game_state.gd`: wire `new_mission` and `submit_day` to emit `mission_started`, `day_started`, `event_triggered`, `day_resolved`, and `mission_ended` in documented sequence.
5. Create `tests/test_mission.gd`: test S02 30-day survival (2 stars), §9.1 end check priority order, all §9.4 root cause branches, deterministic reproducibility, and GameState signal emissions. Verify with `tools\test.ps1`.

## Handoff

- **What works:**
  - `SimDayReport` (`game/sim/sim_day_report.gd`) captures state snapshots for UI gauges, HUD, 3D world visuals, and event logs.
  - `SimResult` (`game/sim/sim_result.gd`) and `SimDebrief` (`game/sim/sim_debrief.gd`) handle star calculations (§9.2), reverse cause chain traversal (§9.3), root cause diagnosis for night energy, shield deficit, un-repaired recycler, supply shortages, and mission success (§9.4), and seeded matching of NASA educational facts from `game/data/facts.json` (§9.5).
  - `SimMission` (`game/sim/sim_mission.gd`) coordinates the full 30-day turn cycle in the exact order of GAME_RULES §4 with strict §9.1 end checks.
  - `GameState` (`game/autoload/game_state.gd`) manages missions and emits `mission_started`, `day_started`, `event_triggered`, `day_resolved`, and `mission_ended` in the documented order.
  - Unit tests in `game/tests/test_mission.gd` verify S02 30-day survival (2 stars), §9.1 end check ordering, all §9.4 root cause branches, deterministic reproduction, and GameState signal sequence.
- **What to test by hand:**
  - Run `tools\test.ps1` to confirm all 66 headless unit tests pass.
- **Known issues:**
  - None.
- **Next ticket:**
  - `T1-08` — Balance scenarios S01–S09.
