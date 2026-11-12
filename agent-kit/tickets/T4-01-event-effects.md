# T4-01 — Event effects

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P4 | T3-06 | M | Agent | lighting-and-effects, kaykit-assets |

## Paste-ready prompt

```text
Run ticket T4-01 (Event effects). Ticket file: agent-kit/tickets/T4-01-event-effects.md
Goal: Each event is seen, not just read: storm streaks and red tint, meteoroid streak and sparks, recycler sparks and steam, rover dirt, drill dust.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Each event is seen, not just read: storm streaks and red tint, meteoroid streak and sparks, recycler sparks and steam, rover dirt, drill dust.

## Read first

- `.agent/skills/lighting-and-effects/SKILL.md`
- agent-kit/ART_DIRECTION.md §7
- `.agent/skills/kaykit-assets/SKILL.md`

## Tasks

1. `world/Effects.tscn` + `effects.gd`: one function per event code (skill table), `CPUParticles3D` with Kenney sprites and billboard material.
2. Storm: red screen tint, streaks across the sky, alarm light on the shelter; lasts the resolve animation.
3. Meteoroid: streak → spark burst → panel goes dark. Recycler: sparks + steam + red light.
4. Regolith days: rover drives dig site → shelter, dirt puffs, mound grows. Science days: drill spins, dust puff.

## Done when

- [x] Every event in GAME_RULES §8 has a visible effect.
- [x] Still within the phone budget (check particle counts).

## Verify

- MCP run with forced events + debug output.
- `/phone-test` (Wi-Fi) + phone look.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add event effects (T4-01)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `game/world/effects.gd` and `game/world/Effects.tscn` providing functions for every event code (`SUNSET`, `STORM_WARNING`, `STORM`, `RECYCLER_BROKE`, `METEOROID`, `BLACKOUT`, `REGOLITH`, `SCIENCE`, `EVAC_*`) and reactive GameState signal connections.
2. Build mobile-friendly `CPUParticles3D` emitters with Kenney particle sprites for storm streaks, spark bursts, steam puffs, drill dust, and rover dirt puffs, plus a red screen overlay tint for storms.
3. Wire meteoroid incoming streak and solar panel shatter/break reaction; wire recycler sparks + steam puff + red alarm light.
4. Implement regolith rover drive animation from dig site to shelter with dirt puffs and mound growth, and science drill spinning animation with dust puff.
5. Add accessor helpers to `game/world/base.gd`, connect `Effects` into `World.tscn`, and write headless unit tests in `game/tests/test_event_effects.gd` registered in `run_tests.gd`.
6. Verify via `tools/test.ps1`, `tools/scenarios.ps1`, and Godot MCP / CLI smoke run.

## Handoff

- Created `game/world/Effects.tscn` and `game/world/effects.gd` implementing visible event animations and particle effects for all GAME_RULES §8 events.
- Wired storm particle streaks and CanvasLayer red screen tint overlay (`#C74440`, alpha 0.28) with tween fade out, shelter alarm pulsing indicator, meteoroid streak + spark burst + dark panel reaction, recycler sparks + steam puffs + red blinking light, animated rover dirt puffs with regolith mound buildup, and science drill spinning animation with dust puff.
- Added base helper accessors to `game/world/base.gd` and connected `Effects.tscn` into `World.tscn`. Handled headless execution safely without scene tree particle emitter warnings.
- Added comprehensive unit tests in `game/tests/test_event_effects.gd`.
- Verification passed:
  - `tools/test.ps1`: 115 / 115 tests passed.
  - `tools/scenarios.ps1`: 9 / 9 scenarios passed.
  - `tools/export_web.ps1`: Web export built successfully to `build/web/index.html`.

