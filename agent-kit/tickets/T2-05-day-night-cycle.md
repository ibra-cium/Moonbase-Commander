# T2-05 — Sun path, Day 15 sunset and night

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P2 | T2-04 | M | Agent | lighting-and-effects |

## Paste-ready prompt

```text
Run ticket T2-05 (Sun path, Day 15 sunset and night). Ticket file: agent-kit/tickets/T2-05-day-night-cycle.md
Goal: The Sun crosses the sky over Days 1–14, sets on Day 15, and the base switches to night lighting; a blackout turns everything dark and silent.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

The Sun crosses the sky over Days 1–14, sets on Day 15, and the base switches to night lighting; a blackout turns everything dark and silent.

## Read first

- `.agent/skills/lighting-and-effects/SKILL.md`
- agent-kit/ART_DIRECTION.md §6–7
- agent-kit/GAME_RULES.md §1

## Tasks

1. `world/sky_rig.gd`: `sun_progress()` + `apply_sun()` as in the skill. During each day's resolve animation, tween the day fraction 0 → 1.
2. Sunset day: long shadows, sun sets, fade to night: lamp posts on, window emission on, faint blue ambient, panels stop turning.
3. Solar panels turn to face the Sun by day (rotate the panel part, not the base).
4. Blackout (core shed): lamps and emissive strips off, status light red. Back on when power returns.
5. Make sure the scene still reads well at night (camera view of the base not pitch black).

## Done when

- [ ] BaseDebug through S01: day lighting changes, sunset on Day 15, night lamps, blackout on Day 16.
- [ ] No errors, still smooth.

## Verify

- MCP run + debug output.
- `/phone-test` (Wi-Fi) + quick phone look at night lighting.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add day-night cycle and sunset (T2-05)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. In `world/sky_rig.gd`, add `set_day(day, frac)`, `animate_day(day, duration)` tweening `frac` 0 -> 1 during day resolution, emitting `sun_updated(t, azimuth, is_day)`.
2. In `world/base.gd`, add `OmniLight3D` nodes to lamp posts and emissive window indicators to modules; toggle on at sunset/night and off on daytime or blackout.
3. In `world/base.gd`, orient working solar panels to track the Sun's azimuth during the day, freezing at sunset/night and keeping broken panels static.
4. In `world/base.gd`, handle blackout: shut off all lamps, emissive window meshes and battery strips, setting status light to red.
5. In `world/BaseDebug.tscn` and `world/base_debug.gd`, replace standalone light with `SkyRig`, integrate day tweening and stepping through S01.
6. Verify headless test suite, scenarios S01-S09, MCP smoke run, web export, and phone test.

## Handoff

- **What works**:
  - `SkyRig`: Sun traverses east to west over Days 1–14 with realistic lunar elevation arc (4° sunrise, 64° midday, 4° sunset).
  - Sunset on Day 15: Sun reaches horizon and fades `light_energy` to 0.0 with long dramatic shadows.
  - Night readability: Faint blue Earth-light ambient (`Color(0.12, 0.16, 0.22, 1)`, energy 0.45) keeps the lunar terrain and base silhouette visible without pitch blackness.
  - Night lighting: All 5 lamp posts ignite with warm white `OmniLight3D` (range 8 m, no shadows for mobile performance), and habitat/life-support window emission strips turn on.
  - Solar tracking: Working solar panels rotate around Y to face the Sun's azimuth in real-time; broken panels stay fixed, and all panels stop turning at sunset/night.
  - Blackout handling: In blackout (Day 16 in S01), all lamp posts (mesh + omni lights), window emission, and battery glow strips shut off immediately; habitat status light turns red.
  - `BaseDebug`: Uses `SkyRig`, tweens sun on each day step, displays Sun/Night state in UI, and jumps cleanly to Day 16 blackout.
- **What to test by hand**:
  - Open `res://world/BaseDebug.tscn` in Godot or run web build over Wi-Fi (`/phone-test`).
  - Press Space to step through Days 1 to 14: observe the Sun moving across the sky and solar panels rotating to follow it.
  - Step to Day 15: see sunset on the horizon, panel rotation stop, and lamp posts / window lights turn on.
  - Step to Day 16 (in S01): witness blackout (lamps off, window emission off, battery glow off, status light red).
- **Checks passed**:
  - `tools/test.ps1`: 83 passed, 0 failed.
  - `tools/scenarios.ps1`: 9 / 9 scenarios passed.
  - `tools/export_web.ps1`: web export succeeded to `build/web/index.html`.
