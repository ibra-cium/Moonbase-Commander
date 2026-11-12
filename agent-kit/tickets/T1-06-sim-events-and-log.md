# T1-06 — Events schedule and mission log

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P1 | T1-05 | M | Agent | sim-testing |

## Paste-ready prompt

```text
Run ticket T1-06 (Events schedule and mission log). Ticket file: agent-kit/tickets/T1-06-sim-events-and-log.md
Goal: Seeded events (storm, recycler, meteoroid, sunset) and the log with cause links used by the debrief (GAME_RULES §8, §9.3).
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Seeded events (storm, recycler, meteoroid, sunset) and the log with cause links used by the debrief (GAME_RULES §8, §9.3).

## Read first

- `agent-kit/GAME_RULES.md`
- agent-kit/ARCHITECTURE.md (Simulation classes)
- `agent-kit/CONVENTIONS.md`
- `.agent/skills/sim-testing/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`

## Tasks

1. `sim/sim_event.gd` (`SimEvent`: `code`, `day`, `needs_popup`, `data`).
2. `sim/sim_events.gd` (`SimEvents`): `schedule(rng, force: Dictionary)` drawing in the exact order of §8; `start_of_day(day)` and `end_of_day(day, state)` returning events; `storm_dose(g_cm2)` with interpolation over `SPE_SHIELD_TABLE_G_CM2`; `shield_needed_for_limit()` (inverse, 1 decimal).
3. `sim/sim_log.gd` (`SimLog`): `add(day, code, values, caused_by) -> int`, `latest(code) -> int`, `chain_from(id, max_steps) -> Array`.
4. `tests/test_events.gd`: same seed → same days; `force` overrides (99 or 0 = never); `storm_dose(0)` = 398, `(2.5)` ≈ 287.85, `(5)` = 177.7, `(20)` = 46.9; needed shield for 250 mSv ≈ 3.4; chain walks back correctly.

## Done when

- [x] All tests pass.

## Verify

- `tools\test.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add event schedule and mission log (T1-06)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Implement `game/sim/sim_event.gd` (`SimEvent`) holding `code`, `day`, `needs_popup`, `needs_choice`, and `data`.
2. Implement `game/sim/sim_events.gd` (`SimEvents`) with seeded `schedule(rng, force)` in GAME_RULES §8 order, `start_of_day`, `end_of_day`, `storm_dose` interpolation, and inverse `shield_needed_for_limit`.
3. Implement `game/sim/sim_log.gd` (`SimLog`) with `add`, `latest`, `chain_from` (max 5 steps, oldest first), and cause linking helper.
4. Add comprehensive unit tests in `game/tests/test_events.gd` covering schedule determinism, force overrides, dose interpolation points, needed shield calculation, and cause chain traversal.
5. Verify with `tools\test.ps1`.

## Handoff

- **What works**:
  - `SimEvent` (`game/sim/sim_event.gd`): represents individual events with `code`, `day`, `needs_popup`, `needs_choice`, `data`, and dictionary serialization.
  - `SimEvents` (`game/sim/sim_events.gd`): deterministic seeded schedule following §8 order (`storm_day`, `recycler_day`, `meteoroid_day`), force day overrides (`storm_day`/`storm`, `recycler_day`/`recycler`, `meteoroid_day`/`meteoroid`) with 0/99 = never, start-of-day events (`SUNSET` on Day 15, `STORM_WARNING` with `needs_popup = true` on storm day), end-of-day events (`RECYCLER_BROKE`, `METEOROID` if working solar panels exist), linear interpolation of storm radiation dose across `SPE_SHIELD_TABLE_G_CM2`, and inverse interpolation `shield_needed_for_limit()` (giving 3.4 g/cm² for 250 mSv).
  - `SimLog` (`game/sim/sim_log.gd`): sequential mission logging with parent causation links (`caused_by`), `latest()` lookup, `chain_from(id, max_steps)` walking back up to 5 steps oldest-first with cycle prevention, and `cause_for()` helper supporting debrief root-cause analysis (GAME_RULES §9.3).
  - All 61 tests in `tools\test.ps1` pass without regressions.
- **What to test by hand**:
  - Run `tools\test.ps1` from PowerShell to verify exit code 0.
- **Known issues**:
  - None.
- **Ideas for later**:
  - In T1-07 (`SimMission`), wire `events.start_of_day` and `events.end_of_day` into the daily mission loop, and use `log.cause_for()` for automatic cause attribution during blackout, illness, and evacuation.


