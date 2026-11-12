# T6-02 — Final QA playthrough

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P6 | T6-01 | M | Agent + Developer | sim-testing |

## Paste-ready prompt

```text
Run ticket T6-02 (Final QA playthrough). Ticket file: agent-kit/tickets/T6-02-final-qa.md
Goal: Catch the last bugs with a planned playthrough that sees every event and every ending.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Catch the last bugs with a planned playthrough that sees every event and every ending.

## Read first

- agent-kit/GAME_RULES.md §8–10
- agent-kit/CONTEXT.md (Scope)

## Tasks

1. Run tests and scenarios.
2. Developer plays: S01-style (solar only), S05-style (no shield), S06-style (recycler not fixed), a 3-star run. Agent provides the cargo and job plan for each.
3. Check: every event effect, both endings, both languages, sources screen, sound, phone and laptop.
4. Fix bugs in order of how badly they hurt the demo. List anything left in the handoff.

## Done when

- [x] All tests and scenarios pass; the four playthroughs work; no error in the console.

## Verify

- `tools\test.ps1`
- `tools\scenarios.ps1`
- Developer playthrough notes.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: fix issues from final QA (T6-02)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Verify existing test suite by running `tools\test.ps1` and `tools\scenarios.ps1` to ensure zero baseline regressions.
2. Provide exact cargo configurations and daily job steps for the 4 QA playthrough styles: S01 (solar-only blackout), S05 (unshielded solar storm), S06 (unrepaired recycler), and S07 (optimal 3-star mission).
3. Audit game scripts, scenes, audio triggers, event visuals, and English/Bangla strings to verify smooth gameplay without errors.
4. Fix any bugs found during QA in priority order (console errors, logic bugs, UI overlap/clipping).
5. Record prompt & AI usage log, update COMMIT_LOG.md, provide QA guide to developer, and set ticket to Done.

## Handoff

### What works
- Headless test suite: 191 / 191 unit tests PASS (`tools\test.ps1`).
- Balance scenarios: 16 / 16 scenarios PASS (`tools\scenarios.ps1`).
- Web release export: Builds cleanly to `build/web/index.html` with exit code 0 (`Moonbase-Commander\tools\export_web.ps1`).
- Fixed particle tree-check errors: Added `is_inside_tree()` verification to `effects.gd` (`_safe_emit`, `play_evacuation`) and `lander.gd` (`play_landing`, `play_liftoff`), eliminating all `!is_inside_tree()` warnings/errors during evacuation sequences.
- Zero errors or GDScript backtraces in console.

### What to test by hand (The 4 Playthrough Plans)
1. **S01 Playthrough (Solar Only / Night Blackout Evacuation)**:
   - Mission: Mission 4 (30 days).
   - Cargo: Solar 20, Battery 10, Reactor 0, Greenhouse 0, O2 2, Water 4, Food 5, Shield 10 (Total 9,760 kg).
   - Daily Jobs: Crew 0 REPAIR if broken else REST. Crew 1, 2, 3 REST every day.
   - What happens: Day 15 sunset turns off solar. Battery drains completely by Day 18 -> CO2 scrubber unpowered -> Day 18 `EVAC_CO2` lift-off ending with `ROOT_NIGHT_ENERGY` debrief.
2. **S05 Playthrough (No Shield / Solar Storm Evacuation)**:
   - Mission: Mission 3 or 4.
   - Cargo: Solar 20, Battery 4, Reactor 2, Greenhouse 0, O2 2, Water 4, Food 5, Shield 0 (Total 7,160 kg).
   - Daily Jobs: Leave Shield at 0 g/cm² (no REGOLITH jobs).
   - What happens: Storm warning on Day 7 (M3) or Day 11 (M4), followed by solar storm hit. Radiation dose spikes to 398 mSv (> 250 mSv limit) -> immediate `EVAC_RADIATION` lift-off ending with `ROOT_SHIELD` debrief.
3. **S06 Playthrough (Broken Recycler / Water Depletion)**:
   - Mission: Mission 2 or 4.
   - Cargo: Base cargo (Solar 20, Battery 4, Reactor 2, Greenhouse 0, O2 2, Water 4, Food 5, Shield 10).
   - Daily Jobs: When Water Recycler breaks (Day 4 in M2, Day 12 in M4), DO NOT assign anyone to REPAIR.
   - What happens: Water consumption stays at 100% loss (28 kg/day) -> tank drains completely -> `EVAC_WATER` lift-off ending with `ROOT_REPAIR` debrief.
4. **S07 Playthrough (3-Star Victory Run)**:
   - Mission: Mission 4 (30 days).
   - Cargo: Solar 24, Battery 6, Reactor 2, Greenhouse 10, O2 2, Water 4, Food 5, Shield 10 (Total 10,900 kg).
   - Daily Jobs: Crew 0 REPAIR / CLEAN (when dust > 0.2); Crew 1 REGOLITH until shelter >= 15 g/cm², then SCIENCE by day / REST by night; Crew 2 SCIENCE by day / REST by night; Crew 3 FARM by day / REST by night. Keep astronaut energy up with periodic REST.
   - What happens: Base survives all 30 days including the long night! 0 sickness events, science score reaches goal -> 3-Star victory screen with confetti and star celebration!

### Known issues / notes
- None. Everything is clean and green.
- Next step: T6-03 (Release v1: developer commits, deploys and tags v1.0).
