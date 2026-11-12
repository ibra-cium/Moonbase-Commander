# T4-03 — Audio: life-support hum, alarms, UI sounds

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P4 | T4-02 | S | Agent | — |

## Paste-ready prompt

```text
Run ticket T4-03 (Audio: life-support hum, alarms, UI sounds). Ticket file: agent-kit/tickets/T4-03-audio.md
Goal: Sound that carries meaning: the hum means life support is running; silence means danger.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Sound that carries meaning: the hum means life support is running; silence means danger.

## Read first

- agent-kit/ARCHITECTURE.md (Autoloads)
- `.agent/skills/kaykit-assets/SKILL.md`

## Tasks

1. `autoload/audio.gd` (`Audio`): `play(name)`, `loop(name)`, `stop(name)`, master mute from `Settings.sound_on`.
2. Hum loop while `core` is served; stops in a blackout. Alarm on storm warning. Impact on meteoroid, spark on recycler, engine on landing/lift-off. UI click/confirm/error/switch on buttons.
3. Web: start audio only after the first tap (browsers block autoplay). Mute button on the title screen and HUD.

## Done when

- [ ] Hum stops on Day 16 in S01. Sounds work in the web build after the first tap.

## Verify

- MCP run + debug output.
- `/phone-test` (Wi-Fi) + phone check with sound.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add audio (T4-03)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Update `game/autoload/settings.gd` with `sound_changed` signal and setter on `sound_on`, create `game/autoload/audio.gd` (`Audio` autoload) loading all 9 imported Kenney Sci-Fi & Interface `.ogg` sounds with `play(name)`, `loop(name)`, `stop(name)`, Master bus mute sync, Web first-tap unlock gating, and `GameState` listeners (`hum_loop` while `core` is served, stops in blackout/mission end).
2. Register `Audio` in `game/project.godot` autoloads after `GameState`.
3. Trigger SFX (`alarm` on storm warning popup, `impact` on meteoroid hit, `spark` on recycler break, `engine` on landing/lift-off) and UI sounds (`ui_click`, `ui_confirm`, `ui_error`, `ui_switch`) across `scenes/main.gd`, `world/effects.gd`, `world/lander.gd`, and `ui/*.gd`.
4. Add 64×64 Mute toggle buttons (`volume_up.svg` / `volume_off.svg`) to `TitleScreen.tscn`/`title_screen.gd` and `DayHud.tscn`/`day_hud.gd` synced with `Settings.sound_on`, plus translation keys if needed in `strings.csv`.
5. Add `game/tests/test_audio.gd` (including S01 Day 16 hum stop and web-unlock checks), run `--import`, `tools/test.ps1`, `tools/scenarios.ps1`, Godot scene smoke run, and `tools/export_web.ps1`, then serve via `tools/serve_web.ps1` for developer phone check.

## Handoff

- Created `game/autoload/audio.gd` (`Audio` autoload) preloading all 9 imported Kenney Sci-Fi & Interface `.ogg` streams (`hum_loop`, `alarm`, `impact`, `spark`, `engine`, `ui_click`, `ui_confirm`, `ui_error`, `ui_switch`) and registered it in `game/project.godot`.
- Synced Master mute and loop pause/resume with `Settings.sound_on` (`sound_changed` signal in `game/autoload/settings.gd`), gated Web audio behind the first tap/click/key (`Audio.unlock()`), and connected `hum_loop` to `GameState` so it loops while `core` power is served and stops on blackout or mission end.
- Wired gameplay SFX (`alarm` on `STORM_WARNING` popup in `scenes/main.gd`, `impact` and `spark` in `world/effects.gd`, `engine` in `world/lander.gd`) and UI sounds across UI screens/cards, plus synced 64×64 Mute buttons (`volume_up.svg` / `volume_off.svg`) on `TitleScreen` and `DayHud` with `HUD_SOUND_ON` / `HUD_SOUND_OFF` in `game/i18n/strings.csv`.
- Verified with `tools/test.ps1` (`PASSED 126  FAILED 0`, including `test_audio.gd` verifying S01 Day 16 blackout hum stop and Web first-tap gate), `tools/scenarios.ps1` (`9 / 9`), `godot --path game --quit-after 5`, and `tools/export_web.ps1` (`build/web/index.html`, 45.97 MB). Godot MCP was not connected, so CLI verification was used.
- What to test by hand: open `http://192.168.0.109:8060/` (or re-run `tools\serve_web.ps1`) on your phone on the same Wi-Fi, confirm audio stays silent before first tap, then verify UI clicks, landing engine, life-support hum, Mute buttons on Title & HUD, and Day 16 solar blackout stopping the hum.
- Known issues: None.
- Ideas for later: T5-02 can audit total web build size and audio memory if needed.
