# T1-02 — Power system

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P1 | T1-01 | M | Agent | sim-testing |

## Paste-ready prompt

```text
Run ticket T1-02 (Power system). Ticket file: agent-kit/tickets/T1-02-sim-power.md
Goal: Daily power: generation, battery, and shedding by priority exactly as GAME_RULES §4.1.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Daily power: generation, battery, and shedding by priority exactly as GAME_RULES §4.1.

## Read first

- `agent-kit/GAME_RULES.md`
- agent-kit/ARCHITECTURE.md (Simulation classes)
- `agent-kit/CONVENTIONS.md`
- `.agent/skills/sim-testing/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`

## Tasks

1. `sim/sim_power.gd` (`SimPower`): state `battery_kwh`, `capacity_kwh`, `dust`, `broken_panels`.
2. `resolve(day, plan, requested: Dictionary) -> Dictionary` returning `generation_kwh`, `served` per system key, `shed` list, `battery_after`, `hours_on_battery`.
3. System list and priority from GAME_RULES §4.1 in one place (array of `{key, kw}` built from constants).
4. Sun factor function per §1.
5. `tests/test_power.gd`: 20 panels, no reactor, day 1 with landing dust → 456 kWh; day 15 half; night with 2 reactors serves core+water+food; night with 10 batteries sheds core (BLACKOUT) and drains the battery to 0; battery never above capacity; shedding stops lower systems once one is shed.

## Done when

- [x] All tests pass, including every rule in §4.1.

## Verify

- `tools\test.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add power simulation (T1-02)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `Moonbase-Commander/game/sim/sim_power.gd` (`class_name SimPower extends RefCounted`) with state variables (`battery_kwh`, `capacity_kwh`, `dust`, `broken_panels`, `solar_panels`, `reactors`, `greenhouse_area`).
2. Implement `get_sun_factor(day: int) -> float` following GAME_RULES §1 (`1.0` before sunset, `SUN_FACTOR_SUNSET_DAY` on sunset, `0.0` after).
3. Implement `get_systems_priority(area: float = 0.0) -> Array[Dictionary]` defining the 6 priority systems and loads per §4.1.
4. Implement `resolve(day: int, plan = null, requested: Dictionary = {}) -> Dictionary` computing solar + reactor generation with dust/sun factor, iterating requested systems in priority order with partial use / blackout / shedding, clamping battery to capacity, and returning report dictionary.
5. Create `Moonbase-Commander/game/tests/test_power.gd` verifying all §4.1 rules and test cases.
6. Verify with `tools\test.ps1`, import, record AI use, update commit log and handoff.

## Handoff

- **What works:** `game/sim/sim_power.gd` (`SimPower`) models daily power generation (solar with dust and sun factor, small reactors), battery storage/capacity, and priority-order load shedding per GAME_RULES §4.1. `game/tests/test_power.gd` verifies all 9 power unit tests with 100% pass rate.
- **What to test by hand:** Run `tools\test.ps1` from PowerShell to verify all 22 tests pass with exit code 0.
- **Known issues:** None.
- **Ideas for later:** Ready for T1-03 (Life support), which will consume `power_result` from `SimPower.resolve()` to determine `air_on`, recycler state, and food spoilage.


