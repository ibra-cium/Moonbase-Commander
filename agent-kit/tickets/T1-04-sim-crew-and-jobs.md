# T1-04 — Crew, jobs, dust, radiation and sickness

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P1 | T1-03 | M | Agent | sim-testing |

## Paste-ready prompt

```text
Run ticket T1-04 (Crew, jobs, dust, radiation and sickness). Ticket file: agent-kit/tickets/T1-04-sim-crew-and-jobs.md
Goal: Four crew members, their daily jobs and what the jobs change, as GAME_RULES §6.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Four crew members, their daily jobs and what the jobs change, as GAME_RULES §6.

## Read first

- `agent-kit/GAME_RULES.md`
- agent-kit/ARCHITECTURE.md (Simulation classes)
- `agent-kit/CONVENTIONS.md`
- `.agent/skills/sim-testing/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`

## Tasks

1. `sim/sim_plan.gd` (`SimPlan`): `jobs: Array[String]` (one per crew), `greenhouse_lights_on`, `science_gear_on`. Job codes: `REST, REPAIR, CLEAN, FARM, REGOLITH, SCIENCE`.
2. `sim/sim_crew.gd` (`SimCrew`): per member `job`, `sick_days`, `dose_msv`; `ever_sick`.
3. Functions: `normalize_jobs(plan, storm_today)` (sick → REST, storm → REST), `outside_flags(state)` (REPAIR is inside when the recycler is broken, else outside), `apply_daily_dose(worked_outside)`, `apply_sickness(co2_high)`, `apply_job_effects(...)` returning changes for dust, repairs, shelter, science, farming (§6.1–6.2).
4. `tests/test_crew.gd`: sick crew forced to REST; outside job with EVA shed does nothing; doses inside 0.95 vs outside 1.369; dust adds 0.02 per outside job and CLEAN resets to 0; REPAIR fixes the recycler first; CO2 above 3.0 makes every healthy crew member sick for 2 days; resting recovers.

## Done when

- [x] All tests pass.

## Verify

- `tools\test.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add crew, jobs and radiation dose (T1-04)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `Moonbase-Commander/game/sim/sim_plan.gd` (`SimPlan`) with `jobs: Array[String]`, `greenhouse_lights_on`, `science_gear_on`, job constants, and outside job detection.
2. Create `Moonbase-Commander/game/sim/sim_crew.gd` (`SimCrew` and `CrewMember`) tracking per-member `job`, `sick_days`, `dose_msv`, and `ever_sick`.
3. Implement `normalize_jobs`, `outside_flags`, `apply_daily_dose`, `apply_sickness`, and `apply_job_effects` following GAME_RULES §6.1–6.4 strictly using `_c.v(...)`.
4. Create `Moonbase-Commander/game/tests/test_crew.gd` with comprehensive unit tests for job normalization, outside flags, EVA shedding, radiation doses, dust accumulation and cleaning, REPAIR priority, CO2 headache sickness, and recovery.
5. Run `tools\test.ps1` to verify all test suites pass.

## Handoff

### What works
- `SimPlan` (`game/sim/sim_plan.gd`):
  - Job constants: `REST`, `REPAIR`, `CLEAN`, `FARM`, `REGOLITH`, `SCIENCE`.
  - Properties `jobs: Array[String]`, `greenhouse_lights_on: bool`, `science_gear_on: bool`.
  - Outside job detection method `has_outside_jobs(recycler_broken: bool = false)` correctly treating `REPAIR` as inside when recycler is broken and outside when working.
  - Plan cloning and getter/setter helpers.
- `SimCrew` (`game/sim/sim_crew.gd`):
  - Member tracking with inner `CrewMember` (`job`, `sick_days`, `dose_msv`, `is_sick()`).
  - `normalize_jobs(plan, storm_today)`: forces sick crew to `REST`, and on solar storm day forces all crew to `REST`.
  - `outside_flags(state)`: reports boolean array of outside jobs; handles `REPAIR` as inside when recycler is broken and outside otherwise.
  - `apply_daily_dose(worked_outside, eva_served)`: accumulates `RAD_SURFACE_MSV_DAY` (1.369 mSv) for active outside jobs with EVA power, else `RAD_HABITAT_MSV_DAY` (0.95 mSv).
  - `apply_sickness(co2_high, jobs)`: sets `sick_days = SICK_REST_DAYS` (2) and `ever_sick = true` on `CO2_HEADACHE_MMHG`; decrements sick days on `REST` until full recovery.
  - `apply_job_effects(jobs, power_served, state)`: resolves all end-of-day job effects per GAME_RULES §6.1–6.2 (EVA power shed cancellation, REPAIR priority on recycler before solar panels, CLEAN resetting dust to 0, REGOLITH adding shelter shielding, SCIENCE requiring both EVA and ops power, and dust accumulation capped at `DUST_MAX_LOSS`).
- Unit tests (`game/tests/test_crew.gd`): 11 unit tests covering all tasks and edge cases (45 total tests passing across project).

### What to test by hand
- Run `powershell -File tools\test.ps1` to verify all 45 unit tests pass.

### Known issues / notes
- None.

### Ideas for later
- When building `SimMission` in T1-07, `crew.normalize_jobs` and `crew.apply_job_effects` integrate directly into the daily mission loop steps 2, 6, 7, and 9.


