# T1-03 — Life support: oxygen, CO2, water, food

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P1 | T1-02 | M | Agent | sim-testing |

## Paste-ready prompt

```text
Run ticket T1-03 (Life support: oxygen, CO2, water, food). Ticket file: agent-kit/tickets/T1-03-sim-life-support.md
Goal: Daily air, water and food as GAME_RULES §5.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Daily air, water and food as GAME_RULES §5.

## Read first

- `agent-kit/GAME_RULES.md`
- agent-kit/ARCHITECTURE.md (Simulation classes)
- `agent-kit/CONVENTIONS.md`
- `.agent/skills/sim-testing/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`

## Tasks

1. `sim/sim_life.gd` (`SimLife`): `o2_kg`, `co2_mmhg`, `water_kg`, `food_kg`, `recycler_broken`.
2. `resolve(power_result, greenhouse_o2, greenhouse_water_kg, crew_count) -> Dictionary` with amounts used, `oga_kg`, flags (`air_on`, `co2_high`, `food_spoiled`, `supply_low` list).
3. Follow §5 order exactly: CO2, water loss, oxygen (generator limited by water and `OGA_O2_KG_DAY`), food and spoil.
4. `tests/test_life.gd`: recycler on → water loss ≈ 0.257 kg + generator water ≈ 4.03 kg per day for 4 crew; recycler broken → ≈ 12.87 + 4.03; air off → CO2 +1.5 and 3.58 kg from tanks; CO2 never below start when air on; food spoils one extra day when food power is shed.

## Done when

- [x] All tests pass.

## Verify

- `tools\test.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add life support simulation (T1-03)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `Moonbase-Commander/game/sim/sim_life.gd` extending `RefCounted` with state (`o2_kg`, `co2_mmhg`, `water_kg`, `food_kg`, `recycler_broken`) and setup methods from constants/cargo.
2. Implement `resolve(power_result, greenhouse_o2, greenhouse_water_kg, crew_count) -> Dictionary` following GAME_RULES §5 order (CO2, water loss, oxygen via OGA/tanks, food & spoil, supply_low warnings) using `_c.v(...)`.
3. Create `Moonbase-Commander/game/tests/test_life.gd` with unit tests for recycler on/off, OGA water splitting, air off CO2 rise and tank draw, CO2 lower bound, food spoiling on power shed, and supply warnings.
4. Run headless unit tests via `tools\test.ps1` to ensure all tests pass.

## Handoff

### What works
- `SimLife` (`game/sim/sim_life.gd`):
  - Initial setup via `setup(o2_units, water_units, food_units)` or `setup_from_cargo(cargo)` tracking `o2_kg`, `co2_mmhg`, `water_kg`, `food_kg`, and `recycler_broken`.
  - `resolve(power_result, greenhouse_o2, greenhouse_water_kg, crew_count) -> Dictionary` executing GAME_RULES §5 in exact sequence:
    1. CO2: falls by `CO2_FALL_PER_DAY_AIR_ON` (clamped to `CO2_START_MMHG`) when air is on; rises by `CO2_RISE_PER_DAY_AIR_OFF` when air is off; flags `co2_high` if > `CO2_HEADACHE_MMHG`.
    2. Water loss: drinks `WATER_KG_PERSON_DAY * crew` + `greenhouse_water_kg`. Recovers 98% (`WATER_RECOVERY_FULL`) if recycler is powered and not broken; 0% recovery otherwise.
    3. Oxygen: crew need offset by `greenhouse_o2`. OGA splits water (at `OGA_WATER_PER_KG_O2`) up to `OGA_O2_KG_DAY` and available water. Unmet need is drawn from O2 tanks.
    4. Food: crew eats `FOOD_PACKED_KG_PERSON_DAY * crew`. If food power is shed, an extra `FOOD_SPOIL_DAYS_IF_OFF * eat` spoils.
    5. Supply warnings: flags `o2`, `water`, `food` in `supply_low` when remaining stock covers fewer than `SUPPLY_WARNING_DAYS` days.
- Comprehensive unit test suite in `game/tests/test_life.gd` covering all rules and edge cases (34 total tests passing across project).

### What to test by hand
- Run `powershell -File tools\test.ps1` to verify test suite passes.

### Known issues / notes
- None.

### Ideas for later
- Day HUD in P3 can directly query `life.get_food_days_left()`, `life.get_water_days_left()`, and `life.get_o2_tank_days_left()` for quick gauge readouts.
