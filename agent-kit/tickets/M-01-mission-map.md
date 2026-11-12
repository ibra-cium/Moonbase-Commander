# M-01 — Mission map and four missions

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| PM | T4-04 | L | Agent | sim-testing, i18n-bangla |

## Paste-ready prompt

```text
Run ticket M-01 (Mission map and four missions). Ticket file: agent-kit/tickets/M-01-mission-map.md
Goal: After the title screen the player picks a mission on a Moon map. Four missions that start short and simple and get longer; stars per mission; the next mission unlocks after a win. Mission 4 is the current 30-day game, unchanged.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

After the title screen the player picks a mission on a Moon map (like the single-player map in Clash of Clans). Each mission teaches one lesson, gives 1–3 stars, and unlocks the next one. Players aged 7–13 get a first win in about 3 minutes.

**Mission 4 is the current 30-day game with no changes.** Scenarios S01–S09 must still pass untouched.

## Read first

- `agent-kit/CONTEXT.md`
- `agent-kit/GAME_RULES.md` §1, §2, §8, §9, §10
- `agent-kit/DECISIONS.md` (rows dated 2026-11-11 about the mission map)
- `.agent/skills/sim-testing/SKILL.md`
- `.agent/skills/i18n-bangla/SKILL.md`

## The four missions

| # | ID | Name (EN) | Days | Events (forced) | Pack screen | Lesson |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `M1` | First Landing | `MISSION_1_DAYS` (5) | none | only solar, battery, o2, water, food are shown | pack air, water and food |
| 2 | `M2` | Something Broke | `MISSION_2_DAYS` (10) | recycler on `MISSION_2_RECYCLER_DAY` (4); storm and meteoroid never | as M1; **water locked at 2 units** | repair the recycler or water runs out |
| 3 | `M3` | Solar Storm | `MISSION_3_DAYS` (12) | storm on `MISSION_3_STORM_DAY` (8); recycler and meteoroid never | M1 items + shield; shield starts at 0 | shielding, or a race to pile up regolith |
| 4 | `M4` | The Long Night | `MISSION_DAYS` (30) | random, as now | all items, as now | night energy, reactor vs batteries |

Balance was checked with `agent-kit/reference/sim_prototype.py` (MISSION_DAYS changed per mission). The GDScript sim must match:

| Scenario | Mission | Cargo | Rule | Expected |
| --- | --- | --- | --- | --- |
| `M1_basic` | M1 | solar 10, battery 0, reactor 0, gh 0, o2 2, water 4, food 5, shield 0 | REST | SURVIVED, end day 5, 2 stars |
| `M1_no_food` | M1 | same, food 0 | REST | EVAC_FOOD on Day 1 |
| `M2_no_repair` | M2 | solar 20, battery 4, reactor 2, gh 0, o2 2, water 2, food 5, shield 10 | NOFIX | EVAC_WATER on Day 9, root `ROOT_REPAIR` |
| `M2_repaired` | M2 | same | REST | SURVIVED, end day 10, 2 stars |
| `M3_no_shield` | M3 | solar 20, battery 4, reactor 2, gh 0, o2 2, water 4, food 5, shield 0 | REST | EVAC_RADIATION on Day 8, root `ROOT_SHIELD` |
| `M3_regolith` | M3 | same | SMART | SURVIVED, end day 12, 3 stars |

The prototype always prints 30 as the end day for a win (it hardcodes it); the GDScript sim ends on `MISSION_DAYS`, so a win ends on the mission's last day. If the GDScript gives a different outcome, day or star count than this table, say so in the handoff. Do not change NASA values to make it match.

## Tasks

1. **Constants.** Add five entries to `game/data/constants.json` with `"type": "Game setting"`, `"system": "Missions"` and a clear `note`:
   `MISSION_1_DAYS` 5, `MISSION_2_DAYS` 10, `MISSION_2_RECYCLER_DAY` 4, `MISSION_3_DAYS` 12, `MISSION_3_STORM_DAY` 8.
   Copy the field layout of `MISSION_DAYS` (value, unit, system, label, type, note, source "Game design choice (team decides)", link "", added_by "Game design").
2. **Mission data.** Create `game/data/missions.json`: a list of the 4 missions with `id`, `name_key`, `goal_key`, `days_id` (a constant ID), `force` (event day → constant ID, or 0 for "never"), `hidden_items` (cargo keys not shown), `locked_items` (key → fixed count), `start_cargo` (counts the pack screen starts with). Mission 4 has `days_id: "MISSION_DAYS"`, no force, nothing hidden or locked. Cargo counts here are scenario-style data like `tests/scenarios/*.json`, not facts.
3. **Sim support (pure).** Add `with_overrides(overrides: Dictionary) -> SimConstants` to `sim/sim_constants.gd`. It returns a copy whose values for the given IDs are replaced. Add `sim/sim_missions.gd` (`class_name SimMissions`, `RefCounted`): it loads `missions.json` text and returns, for a mission ID, the overridden `SimConstants` (with `MISSION_DAYS` set from `days_id`) and the `force` dictionary with constant IDs turned into numbers. No new rules in `step_day`.
4. **Session progress.** In `autoload/settings.gd` add `current_mission_id` (default `"M1"`), `mission_stars: Dictionary` (best stars per mission), `free_play: bool`, `is_mission_unlocked(id)`, `record_stars(id, stars)`. A mission unlocks when the one before it got at least 1 star. Session only, no saving (same as the tutorial flags).
5. **Mission map screen.** Create `ui/MissionMap.tscn` + `ui/mission_map.gd` (`class_name MissionMap`). Four big round mission buttons along a path on a dark Moon background (reuse `assets/textures/nasa/lroc_color_2k.jpg`, darkened, credited as on the title screen). Each button: number, name, best stars (☆/★), and a lock icon when locked. There is no lock icon in `assets/icons/` yet: write `assets/icons/lock.svg` by hand as the Material Icons `lock` shape (24×24 viewBox, same style as the other icons; Material Icons are Apache 2.0, already credited). Tapping a locked button plays `ui_error`. Tapping an open one shows the mission goal (one line) and a **Play** button. A small **Free play** toggle in a corner unlocks all missions (for teachers, judges and the demo). 64 px touch targets, `Theme.tres`, all text via `tr()`.
6. **Flow.** In `scenes/main.gd` add a `State.MAP` between `TITLE` and `PACK`: Title → Map → Pack. `GameState.new_mission()` is called with the selected mission's `SimConstants` and `force`. The debrief gets a **Next mission** button when the player survived and a next mission exists. **Title Screen** in the debrief goes to the map. **Retry** keeps the same mission.
7. **Pack screen per mission.** `pack_screen.gd` `_get_sim_constants()` returns the selected mission's constants (so warnings use the mission's days). Hide `hidden_items` cards. Locked items show their count with a lock and no +/− buttons. The night-energy warning row is hidden when `MISSION_DAYS < SUNSET_DAY`. When a mission is entered from the map, the pack screen starts from `start_cargo`; Retry keeps the last cargo, as now.
8. **Remove the hardcoded 30s.**
   - `day_hud.gd`: `set_day()` uses the mission's days; the food gauge maximum uses the mission's days.
   - `debrief_screen.gd`: end day default and the "days reached" text use the mission's days.
   - Strings: change `HUD_DAY` to `Day {day} / {total}` and `DEBRIEF_DAY_REACHED` to `Completed {days} of {total} days`.
9. **Tutorial.** Step 3 ("Survive the lunar night") only shows when the mission has a night (`MISSION_DAYS >= SUNSET_DAY`). Otherwise it shows `TUT_STEP3_GOAL` with the mission's goal. The tutorial still runs once per session.
10. **Scenarios and tests.** Let `tests/run_scenarios.gd` read an optional `"mission": "M2"` key and use `SimMissions` for constants and forced days (the scenario's own `force` wins if both exist). Add the six scenario files from the table above. Add `tests/test_missions.gd`: overrides work, the original constants object is not changed, unlock rules, locked and hidden items, the M4 constants equal the base constants.

## New text keys (EN; leave `bn` empty for Samia)

| Key | EN |
| --- | --- |
| `MAP_TITLE` | Moon Missions |
| `MAP_PLAY` | Play |
| `MAP_LOCKED` | Win the mission before to unlock |
| `MAP_FREE_PLAY` | Free play |
| `MISSION_M1_NAME` | First Landing |
| `MISSION_M1_GOAL` | Pack air, water and food. Stay {days} days. |
| `MISSION_M2_NAME` | Something Broke |
| `MISSION_M2_GOAL` | A machine will break. Fix it fast! |
| `MISSION_M3_NAME` | Solar Storm |
| `MISSION_M3_GOAL` | A solar storm is coming. Build a safe shelter. |
| `MISSION_M4_NAME` | The Long Night |
| `MISSION_M4_GOAL` | Survive {days} days, with 14 dark days. |
| `DEBRIEF_NEXT_MISSION` | Next mission |
| `PACK_LOCKED_ITEM` | Already packed |
| `TUT_STEP3_GOAL` | Your goal: {goal} |

`MISSION_M4_GOAL` must not hardcode "14": fill it from `NIGHT_DAYS` the way `TUT_STEP3_BODY` already does, or drop the number.

## Done when

- [x] Title → Map → Pack → mission → Debrief → Next mission works for all 4 missions with touch only (automated flow & MCP runtime verified; phone touch check ready for `/phone-test`).
- [x] Missions 2–4 are locked until the one before is won; Free play unlocks all.
- [x] Mission 4 plays exactly like the game before this ticket.
- [x] No "30" left in the HUD, debrief or food gauge for short missions.
- [x] S01–S09 pass unchanged, and the six new mission scenarios pass (`15 / 15`).
- [x] All new text via `tr()`; new keys in `strings.csv` with `bn` empty.

## Verify

- `tools\test.ps1`, `tools\scenarios.ps1`
- MCP run: play M1 to the end, lose M2 on purpose (no repair), check the debrief, play M4 to Day 15.
- `tools\export_web.ps1`, then `/phone-test` and ask the developer.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add mission map and four missions (M-01)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

**Files to create:**
- `game/data/missions.json` — four mission definitions (cargo starts, hidden/locked items, force events)
- `game/sim/sim_missions.gd` — `SimMissions` class: loads missions.json, returns overridden SimConstants and resolved force dict
- `game/ui/mission_map.gd` + `game/ui/MissionMap.tscn` — four circular buttons on a Moon surface path
- `game/assets/icons/lock.svg` — Material Icons lock shape, hand-written SVG
- `game/tests/scenarios/M1_basic.json`, `M1_no_food.json`, `M2_no_repair.json`, `M2_repaired.json`, `M3_no_shield.json`, `M3_regolith.json`
- `game/tests/test_missions.gd`

**Files to change:**
- `game/data/constants.json` — add 5 new `Game setting` entries: `MISSION_1_DAYS`, `MISSION_2_DAYS`, `MISSION_2_RECYCLER_DAY`, `MISSION_3_DAYS`, `MISSION_3_STORM_DAY`
- `game/sim/sim_constants.gd` — add `with_overrides(overrides) -> SimConstants`
- `game/autoload/settings.gd` — add `current_mission_id`, `mission_stars`, `free_play`, `is_mission_unlocked()`, `record_stars()`
- `game/autoload/game_state.gd` — make `new_mission` pull custom_constants + force from Settings.current mission
- `game/scenes/main.gd` — add `State.MAP`; wire Title→Map→Pack; "Title Screen" in debrief→Map; "Next mission" button on success
- `game/ui/pack_screen.gd` — use mission's SimConstants; hide hidden_items; lock locked_items; hide night-energy warn when MISSION_DAYS < SUNSET_DAY; start from start_cargo; update `_get_sim_constants()`
- `game/ui/day_hud.gd` — `set_day()` takes total from mission; food gauge max uses mission's days
- `game/ui/debrief_screen.gd` — `DEBRIEF_DAY_REACHED` uses `{total}` placeholder; wire "Next mission" button
- `game/ui/tutorial_overlay.gd` — step 3 shows mission goal when MISSION_DAYS < SUNSET_DAY
- `game/i18n/strings.csv` — add 13 new keys
- `game/tests/run_scenarios.gd` — read optional `"mission"` key, use SimMissions for constants/force
- `agent-kit/STATUS.md` — set M-01 to Doing

**Approach:**
1. Constants → missions.json → sim_constants with_overrides → SimMissions (pure, testable)
2. Settings progress fields → test_missions.gd unit tests
3. MissionMap scene (code-built nodes in .gd; minimal .tscn with just the script attached)
4. Main flow wiring (MAP state, debrief buttons)
5. Pack screen & HUD & debrief hardcoded-30 fixes + tutorial step 3
6. Scenario files; update run_scenarios.gd; run tests

**Check:** `tools\test.ps1`, `tools\scenarios.ps1`, then headless import.

## Handoff

**What works:**
- `Title -> Map -> Pack -> Mission -> Debrief` works end-to-end across all four missions (`M1` 5d, `M2` 10d w/ Day 4 recycler breakdown and locked `water=2`, `M3` 12d w/ Day 8 solar storm, `M4` original 30d unchanged).
- Locked mission buttons on `MissionMap` stay clickable so tapping a locked mission plays `ui_error`, shows `MAP_LOCKED`, and hides the Play button; **Free play** unlocks all missions immediately.
- `PackScreen` hides `hidden_items`, locks `locked_items` with `assets/icons/lock.svg` + `PACK_LOCKED_ITEM` and hides `+/-` buttons, hides the night-energy warning on short missions (`MISSION_DAYS < SUNSET_DAY`), uses `start_cargo` when entering from the map / Next mission, and keeps `last_cargo` on Retry / Change Cargo.
- `DayHud`, `DebriefScreen`, `SimResult`, `SimDebrief`, and `strings.csv` now read the mission's `MISSION_DAYS` (and `NIGHT_DAYS`) instead of hardcoded `30` / `14`, and Tutorial Step 3 falls back to `TUT_STEP3_GOAL` on missions with no lunar night.
- **Checks:** `tools\scenarios.ps1` PASS (`15 / 15`, all outcomes/days/stars match the ticket table; `M1_basic`, `M2_repaired`, `M3_regolith` use `"root": "ROOT_SUCCESS"` matching `S02`/`S03`/`S07`/`S09`), `tools\test.ps1` PASS (`136 / 136`, including new `test_missions.gd` end-to-end flow), Godot MCP `run_project` (`Main.tscn` & `MissionMap.tscn`) 0 errors, `tools\export_web.ps1` PASS (`build/web/index.html` exists).

**What to test by hand:**
- Run `/phone-test` (`tools\serve_web.ps1`) on a phone: verify map button touch sizing and layout in portrait/landscape, locked sound + `MAP_LOCKED` prompt, Free play switch, M1–M3 pack screen lock/hide layout, and M4 Day 15 sunset.
- Existing tests `test_constants.gd` (`166` -> `171`), `test_day_loop.gd::test_full_30_day_mission_completion` (pinned `Settings.current_mission_id = "M4"`), and `test_onboarding.gd::test_tutorial_overlay_steps_and_skip` (pinned `M4` for Step 3 sunset check) were updated to stay compatible with default `current_mission_id = "M1"`.

**Note:** `agent-kit/DECISIONS.md` already matches these behaviors; `Plan` note about `game_state.gd` was satisfied without modifying `game/autoload/game_state.gd` (mission constants/force are passed via existing `GameState.new_mission()`).
