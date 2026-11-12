# T3-02 — Title screen with NASA Moon globe

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P3 | T3-01 | M | Agent | godot-3d-scenes |

## Paste-ready prompt

```text
Run ticket T3-02 (Title screen with NASA Moon globe). Ticket file: agent-kit/tickets/T3-02-title-screen.md
Goal: A title screen that shows real NASA data from the first second: a slowly turning Moon globe made from the LRO map, Earth and stars.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

A title screen that shows real NASA data from the first second: a slowly turning Moon globe made from the LRO map, Earth and stars.

## Read first

- agent-kit/ART_DIRECTION.md §8
- agent-kit/ARCHITECTURE.md (UI, Main flow)
- agent-kit/GAME_RULES.md §11
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/i18n-bangla/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`
- agent-kit/ART_DIRECTION.md §6

## Tasks

1. `ui/TitleScreen.tscn`: Moon sphere (`lroc_color_2k.jpg` albedo, `ldem_3_8bit.jpg` as a height/normal hint), turning slowly; Earth and stars behind.
2. Buttons: Start, EN / বাংলা, Sources. Small credit line: "Moon: NASA SVS CGI Moon Kit (LRO data)".
3. On Start: short camera dive toward the Moon, then `main.gd` goes to PACK.
4. Remove the T0-04 debug label.

## Done when

- [ ] Title looks good at 1280×720 and on the phone; Start goes to PACK.

## Verify

- MCP run + debug output.
- `/phone-test` (Wi-Fi) + phone look.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add title screen with NASA Moon globe (T3-02)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Update `game/i18n/strings.csv` with title screen translation keys (`TITLE_SOURCES`, `TITLE_CREDIT_MOON`, `TITLE_SUBTITLE`).
2. Build `game/ui/TitleScreen.tscn` and `game/ui/title_screen.gd` featuring an isolated 3D viewport with rotating NASA LRO Moon globe (`lroc_color_2k.jpg`, `ldem_3_8bit.jpg`), Earth, star field, and responsive UI controls (Start, EN/বাংলা toggle, Sources, NASA credit).
3. Implement camera dive Tween on Start in `title_screen.gd`, emitting `start_completed` to proceed to PACK.
4. Update `game/scenes/Main.tscn` and `main.gd`: remove T0-04 debug labels, wire TitleScreen and SourcesScreen into the Main state machine.
5. Verify via headless tests (`test.ps1`), scenarios (`scenarios.ps1`), Godot MCP run, web export (`export_web.ps1`), and Wi-Fi phone check.

## Handoff

### What works
- `TitleScreen.tscn` renders a dedicated 3D SubViewport (`own_world_3d = true`) featuring the rotating Moon globe from NASA LRO data (`lroc_color_2k.jpg` with `ldem_3_8bit.jpg`), the Blue Marble Earth in the background, a 350-star MultiMesh field, and directional sunlight.
- UI overlay has large title, subtitle, Start button (64 px height), EN / বাংলা toggle button (64 px height), and Data Sources button (64 px height), plus the NASA credit line.
- Tapping Start initiates a camera dive Tween toward the Moon surface accompanied by UI fadeout and a fade to black, emitting `start_completed` which transitions `main.gd` to `State.PACK`.
- Tapping "Data Sources" switches to `SourcesScreen` (and back via "← Back").
- Tapping "বাংলা" switches language to Bengali, updating labels and flipping the toggle to "English".
- T0-04 debug labels removed from `Main.tscn`.
- Headless tests (`tools/test.ps1`): PASSED 91 FAILED 0.
- Balance scenarios (`tools/scenarios.ps1`): 9 / 9 PASS.
- Godot MCP run + debug check: Compatibility renderer boots with 0 errors.
- Web export (`tools/export_web.ps1`): succeeds to `build/web/index.html`.

### What to test by hand
- Run the project or test on phone via `tools/serve_web.ps1`:
  1. Inspect the rotating Moon globe and Earth lighting.
  2. Tap "বাংলা" to see the Bengali translation toggle and back.
  3. Tap "Data Sources" to verify browsing constants, then tap "← Back".
  4. Tap "Start" and observe the camera dive toward the Moon surface.

### Ideas for later
- In P4 (audio), wire sound effects (`ui_click.ogg`, `ui_confirm.ogg`, and subtle ambient deep-space hum) to the TitleScreen buttons and camera dive.
