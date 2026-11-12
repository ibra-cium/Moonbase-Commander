# M-03 — Tap-to-collect bubbles and resource bar

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| PM | M-02 | M | Agent | godot-3d-scenes, web-export-mobile, i18n-bangla |

## Paste-ready prompt

```text
Run ticket M-03 (Tap-to-collect bubbles and resource bar). Ticket file: agent-kit/tickets/M-03-tap-to-collect.md
Goal: After each day, glowing bubbles pop over the buildings that made something (energy, science, shelter, plant oxygen). The player taps them and they fly into a resource bar at the top, like collecting gold in Clash of Clans.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

The base should feel like it is producing something. After each day, bubbles pop over the buildings that made something. The player taps them and they fly into a resource bar at the top. Science becomes a visible score with a goal.

**This ticket only shows numbers the simulation already reports. No sim changes, no new rules.**

## Read first

- `agent-kit/ARCHITECTURE.md` (World and UI only listen)
- `agent-kit/ART_DIRECTION.md` §1 (colours)
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/web-export-mobile/SKILL.md` (touch, phone budget)

## Tasks

1. **Screen anchors (shared helper, reused by M-05).** Create `ui/world_anchor.gd` (`class_name WorldAnchor`): a `Control` that follows a 3D point every frame with `Camera3D.unproject_position()`. It hides itself when the point is behind the camera or off screen. Bubbles are 2D `Button`s placed by this helper, **not** 3D colliders: the project has no physics, and 2D buttons are easy to tap on a phone. Since a touch that starts on a Control is ignored by `camera_rig.gd`, tapping a bubble does not rotate the camera. Check this on the phone.
2. **Base anchor points.** In `world/base.gd` add `get_collect_anchor(kind: String) -> Vector3` for `"energy"` (above the solar field, or above the reactor if there is no solar), `"science"` (above the drill, `get_drill_module()`), `"shelter"` (above the shelter mound, `get_shelter_mound()`) and `"plants"` (above the greenhouse). Return `Vector3.ZERO` when the building is missing.
3. **Bubbles.** Create `ui/CollectBubble.tscn` + `ui/collect_bubble.gd`: a round glowing button with an icon and `+N`. It bobs gently and pops when tapped, then a small copy of the icon flies to its counter in the resource bar (tween about 0.5 s) and the counter ticks up. Use the existing `ui_confirm` (or a soft `ui_switch`) sound on tap.
4. **What pops after a day** (values from the `SimDayReport`; deltas are against the previous report):

   | Bubble | Icon | Shown when | Value |
   | --- | --- | --- | --- |
   | Energy | `assets/icons/bolt.svg` | always | `generation_kwh` (rounded) |
   | Science | `assets/icons/science.svg` | science went up today | `science_points` delta |
   | Shelter | `assets/icons/shield.svg` | shelter went up today | `shelter_g_cm2` delta (1 decimal) |
   | Plants | `assets/icons/eco.svg` | greenhouse healthy today | `greenhouse_o2_kg` (1 decimal) |

   Bubbles not tapped by the time End Day is pressed are collected automatically (same fly animation, faster), so nothing is ever lost and the numbers stay right.
5. **Resource bar.** In `DayHud.tscn` top bar, next to the day label: three compact counters.
   - **Science:** `{n} / {goal}`. The goal is `SCIENCE_GOAL_POINTS`. The counter turns gold when the goal is reached.
   - **Energy today:** kWh made today.
   - **Shelter:** g/cm².

   Each counter has a `SourceTag` (`SCIENCE_GOAL_POINTS`, `SOLAR_UNIT_KW`, `SHIELD_GOAL_G_CM2`). The counters show the sim's numbers. Tapping bubbles only animates them; it never changes what the sim knows.
6. **Kid-friendly gauges (small).** The CO2 gauge also shows a word: `AIR_GOOD` when at or below `CO2_HEALTHY_MAX_MMHG`, `AIR_STUFFY` up to `CO2_LIMIT_MMHG`, `AIR_DANGER` above. Keep the mmHg number and its source tag.
7. **Phone budget.** At most 4 bubbles at a time. Free the nodes after collecting. No new particles.
8. **Tests.** Add `tests/test_collect.gd`: which bubbles appear for a given pair of reports, auto-collect on End Day, counter totals equal the report values.

## New text keys (EN; leave `bn` empty for Samia)

| Key | EN |
| --- | --- |
| `RES_SCIENCE` | Science |
| `RES_SCIENCE_VALUE` | {n} / {goal} |
| `RES_ENERGY` | Energy today |
| `RES_SHELTER` | Shelter |
| `COLLECT_HINT` | Tap the bubbles! |
| `AIR_GOOD` | Air: good |
| `AIR_STUFFY` | Air: stuffy |
| `AIR_DANGER` | Air: danger! |

`COLLECT_HINT` shows once, the first time bubbles appear, as a small label near the first bubble.

## Done when

- [ ] After each day the right bubbles pop over the right buildings; tapping collects them; untapped ones collect on End Day.
- [ ] Science counter with goal is always visible on the HUD and matches the sim.
- [ ] CO2 gauge shows Air good / stuffy / danger.
- [ ] Tapping a bubble on the phone does not rotate the camera.
- [ ] No change in sim results: S01–S09 and the mission scenarios pass.

## Verify

- `tools\test.ps1`, `tools\scenarios.ps1`
- MCP run of M3 with regolith jobs (shelter bubbles) and M4 with science jobs.
- `tools\export_web.ps1`, then `/phone-test`: bubble tapping, frame rate.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add tap-to-collect bubbles and resource bar (M-03)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan
1. Add the 8 English strings (`RES_SCIENCE`, `RES_SCIENCE_VALUE`, `RES_ENERGY`, `RES_SHELTER`, `COLLECT_HINT`, `AIR_GOOD`, `AIR_STUFFY`, `AIR_DANGER`) to `game/i18n/strings.csv`.
2. Add `get_collect_anchor(kind)` to `world/base.gd` for energy, science, shelter, and plants, and create `ui/world_anchor.gd` (`class_name WorldAnchor`) plus `ui/CollectBubble.tscn` / `ui/collect_bubble.gd` with tap-to-fly icon tweening and auto-cleanup.
3. Add the 3-counter `ResourceBar` (Science, Energy today, Shelter) with `SourceTag` popovers and CO2 word badge (`AIR_GOOD` / `AIR_STUFFY` / `AIR_DANGER`) to `DayHud.tscn` / `day_hud.gd` + `Gauge.tscn` / `gauge.gd`.
4. Wire daily report delta bubble spawning and `End Day` auto-collect in `scenes/main.gd` (`COLLECT_HINT` once), then write `tests/test_collect.gd` and run full `/verify` including M3/M4 checks and web export.

## Handoff
- Added [`world_anchor.gd`](file:///d:/MOONBASE/Moonbase-Commander/game/ui/world_anchor.gd) (`WorldAnchor`), [`CollectBubble.tscn`](file:///d:/MOONBASE/Moonbase-Commander/game/ui/CollectBubble.tscn) + [`collect_bubble.gd`](file:///d:/MOONBASE/Moonbase-Commander/game/ui/collect_bubble.gd), and [`base.gd`](file:///d:/MOONBASE/Moonbase-Commander/game/world/base.gd) `get_collect_anchor(kind)` (`energy`, `science`, `shelter`, `plants`).
- Added the 3-counter top `ResourceBar` (`Science`, `Energy today`, `Shelter` with `SourceTag` popovers), `BubblesLayer` / `FlyLayer`, tap/End-Day fly tweens, and CO2 status words (`AIR_GOOD`, `AIR_STUFFY`, `AIR_DANGER`) in [`DayHud.tscn`](file:///d:/MOONBASE/Moonbase-Commander/game/ui/DayHud.tscn), [`day_hud.gd`](file:///d:/MOONBASE/Moonbase-Commander/game/ui/day_hud.gd), [`Gauge.tscn`](file:///d:/MOONBASE/Moonbase-Commander/game/ui/Gauge.tscn), and [`gauge.gd`](file:///d:/MOONBASE/Moonbase-Commander/game/ui/gauge.gd).
- Wired resolved-day bubble spawning, held counter updates, one-time `COLLECT_HINT` (`settings.hint_collect_shown`), and `End Day` auto-collect in [`main.gd`](file:///d:/MOONBASE/Moonbase-Commander/game/scenes/main.gd) and [`settings.gd`](file:///d:/MOONBASE/Moonbase-Commander/game/autoload/settings.gd); added 8 English keys in [`strings.csv`](file:///d:/MOONBASE/Moonbase-Commander/game/i18n/strings.csv) and 6 tests in [`test_collect.gd`](file:///d:/MOONBASE/Moonbase-Commander/game/tests/test_collect.gd).
- Verified after final code edit: `.\tools\test.ps1` (`PASSED 146  FAILED 0`), `.\tools\scenarios.ps1` (`15 / 15`), Godot MCP `run_project` (0 runtime errors), and `.\tools\export_web.ps1` (`Web export succeeded`, `build\web\index.html` exists).
- Pending phone check (`/phone-test`): bubble tapping and frame rate on mobile.
