# T1-01 — Cargo catalog and pack maths

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P1 | T0-04 | M | Agent | sim-testing, nasa-data |

## Paste-ready prompt

```text
Run ticket T1-01 (Cargo catalog and pack maths). Ticket file: agent-kit/tickets/T1-01-sim-cargo.md
Goal: The cargo model behind the pack screen: items, masses, limits and the warnings the player sees before launch.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

The cargo model behind the pack screen: items, masses, limits and the warnings the player sees before launch.

## Read first

- `agent-kit/GAME_RULES.md`
- agent-kit/ARCHITECTURE.md (Simulation classes)
- `agent-kit/CONVENTIONS.md`
- `.agent/skills/sim-testing/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`

## Tasks

1. `sim/sim_cargo.gd` (`SimCargo`): counts for `solar, battery, reactor, greenhouse (area m²), o2, water, food, shield`; catalog per GAME_RULES §2 (name key, unit mass, max units, constant IDs).
2. Methods: `unit_mass(key)`, `total_mass()`, `is_valid()` (mass ≤ `CARGO_LIMIT_KG`, counts within max, greenhouse area in `GREENHOUSE_SIZE_OPTIONS_M2`), `set_count(key, n)` that clamps.
3. Summary values: `battery_kwh_capacity()`, `solar_kw()`, `reactor_kw()`, `o2_kg()`, `water_kg()`, `food_kg()`, `shelter_g_cm2()`.
4. Warnings for the pack screen (GAME_RULES §11): food days, water days with the recycler (drink loss + oxygen-generator water), night energy have vs need (`essential_kW × NIGHT_HOURS`). Return them as small dictionaries `{code, values}`; the UI turns them into text.
5. `tests/test_cargo.gd`: base cargo (§10) mass ≈ 5343 kg; S08 cargo ≈ 15641 kg and invalid; greenhouse 7 m² invalid; night need for the base ≈ 3178 kWh (essential 8.97 kW × NIGHT_HOURS); clamping works.

## Done when

- [ ] All tests pass.
- [ ] No number typed in `sim_cargo.gd`; every value via `c.v()`.

## Verify

- `tools\test.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add cargo catalog and pack maths (T1-01)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `Moonbase-Commander/game/sim/sim_cargo.gd` (`class_name SimCargo extends RefCounted`) with counts for all 8 cargo items, catalog data, clamping in `set_count()`, mass/validity checks, summary getters, and pack warnings (`food_days`, `water_days`, `night_energy`).
2. Source all game numbers strictly from `_c.v("...")` without hardcoded constants.
3. Create `Moonbase-Commander/game/tests/test_cargo.gd` implementing tests for base cargo mass (~5343 kg), S08 overweight (~15641 kg and invalid), invalid greenhouse area (7 m²), night energy need (~3178 kWh with ~8.97 kW essential load), clamping behavior, summaries, and warning calculations.
4. Run `--import` and verify with `tools\test.ps1`.

## Handoff

- **What works**: `SimCargo` (`game/sim/sim_cargo.gd`) fully models the 8 cargo catalog items (`solar`, `battery`, `reactor`, `greenhouse`, `o2`, `water`, `food`, `shield`). All game numbers are sourced via `_c.v(...)`. Mass calculation, bounds clamping, greenhouse discrete size validation (`[0, 5, 10, 20]`), summary getters, and live pack warnings (`food_days`, `water_days`, `night_energy`) are implemented and covered by 8 new unit tests in `game/tests/test_cargo.gd`. Test suite passes with 13 tests total and 0 failures.
- **What to test by hand**: Run `tools\test.ps1` from PowerShell to verify headless test execution.
- **Known issues**: None.
- **Ideas for later**: When building the PackScreen in T3-03, `get_warnings()` returns structured `{code, values}` with formatting variables (`n`, `have`, `need`, `is_warning`, `source_id`), ready to wire directly into UI cards and source info popups.


