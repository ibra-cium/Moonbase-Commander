# T5-02 — Phone polish and load time

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P5 | T5-01 | M | Agent + Developer | web-export-mobile |

## Paste-ready prompt

```text
Run ticket T5-02 (Phone polish and load time). Ticket file: agent-kit/tickets/T5-02-phone-polish.md
Goal: The game feels good on the developer's phone from the public link.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

The game feels good on the developer's phone from the public link.

## Read first

- `.agent/skills/web-export-mobile/SKILL.md`

## Tasks

1. Loading screen with progress and the game title (custom HTML shell or Godot boot splash with a dark background).
2. Touch: no accidental orbit when tapping buttons; safe area margins; landscape hint when the phone is held upright.
3. Phone check of a full mission; fix the top issues; re-check the budget.
4. Plan B only if the developer decides so (DECISIONS.md).

## Done when

- [x] A full mission plays smoothly on the phone; developer says OK.

## Verify

- `/phone-test` (Wi-Fi) + full phone run.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: polish phone play and loading (T5-02)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Add `game/web/shell.html` wired in `game/export_presets.cfg` (`html/custom_html_shell`): dark `#05060A` loading screen with Moonbase Commander title, progress bar + `%`, `viewport-fit=cover` safe-area CSS probe (`window.__moonbaseSafeInsets`), and an automatic upright portrait "rotate to landscape" overlay (EN + BN) on touch devices, keeping `$GODOT_URL` and `Engine.getMissingFeatures` compatible with `tools/export_web.ps1`.
2. Shrink `index.pck` in `game/export_presets.cfg` by excluding verified-unused `assets/nasa3d/*`, `assets/ui/*`, and unreferenced `assets/particles/kenney/*` files (keeping all referenced resources, `*.json`, `*.csv`).
3. Harden touch & camera orbit in `game/world/camera_rig.gd` and `game/ui/DayHud.tscn`: ignore camera input when `World` is hidden, ignore touch-emulated mouse (`DEVICE_ID_EMULATION`), set `mouse_filter = STOP` on HUD pills/status strips and close button/HUD gaps, and guard near-button edge taps from orbiting or triggering `empty_ground_tapped`.
4. Add `game/ui/safe_area.gd` to apply notch/rounded-corner safe-area padding across UI screens (`TitleScreen`, `MissionMap`, `PackScreen`, `SourcesScreen`, `DayHud`, `EndingOverlay`, `DebriefScreen`) using `DisplayServer.get_display_safe_area()` + Web CSS insets without changing 1280×720 desktop margins.
5. Add headless tests (`game/tests/test_phone_polish.gd`), run `tools/test.ps1`, Godot scene smoke check, `tools/export_web.ps1`, and launch `tools/serve_web.ps1` (`/phone-test`) for the developer's full-mission phone test (applying any fixes + Plan B only if needed).

## Handoff

- **What was built:**
  - `game/web/shell.html` + `game/export_presets.cfg` + `game/project.godot`: `#05060A` dark-space loading overlay with **MOONBASE COMMANDER** title, live progress bar and `%`, `viewport-fit=cover` + CSS safe-area probe (`window.__moonbaseSafeInsets`), and upright portrait landscape hint (`Rotate your phone to landscape` / `ফোনটি অনুভূমিকভাবে ঘোরান`), keeping LAN HTTP and Web Audio patches working in `tools/export_web.ps1`.
  - Load-time optimization: excluded unused `assets/nasa3d/*`, `assets/ui/*`, and unused `assets/particles/kenney/*` frames in `game/export_presets.cfg`, trimming `build/web/index.pck` from `10,323,916` bytes (~9.85 MB) to `4,960,764` bytes (~4.73 MB). No Plan B fallback needed.
  - Touch & safe-area polish: hardened `game/world/camera_rig.gd` (`_is_world_visible()`, `DEVICE_ID_EMULATION` + post-touch mouse suppression, `BUTTON_TOUCH_GUARD_PX = 8.0`, skip nested `SubViewport`), blocked pass-through taps on `DayHud.tscn` resource pills (`SciencePill`, `EnergyPill`, `ShelterPill`), `LeftColumn/Gauges`, and `BottomBar/HBox`, extracted `Settings.is_touch_or_mobile()`, and wired `UiSafeArea` (`game/ui/safe_area.gd`) across `DayHud`, `TitleScreen`, `MissionMap`, `PackScreen`, `SourcesScreen`, `EndingOverlay`, and `DebriefScreen`.
  - Phone server fix: hardened `tools/serve.py` (`MoonbaseHTTPServer` disabling Windows socket double-binding and guarding closed-pipe `log_message`) and updated `tools/serve_web.ps1` to stop stale `tools\serve.py` processes on port 8060 cleanly.
- **Verification:**
  - `--import`: PASS (registered `UiSafeArea`).
  - `tools\test.ps1`: PASS (`PASSED 166  FAILED 0`, including 4 new tests in `game/tests/test_phone_polish.gd`).
  - `tools\scenarios.ps1`: PASS (`Scenarios passed: 15 / 15`).
  - Godot MCP runtime smoke (`run_project` + `get_debug_output` + `stop_project`): PASS (`0` runtime errors).
  - `tools\export_web.ps1`: PASS (`build/web/index.html` exported cleanly; `index.pck` = 4,960,764 bytes).
  - `/phone-test` over Wi-Fi (`http://192.168.0.109:8060/`): HTTP `200` confirmed on all assets; developer tested on phone and reported `"looks good"`; background server stopped cleanly.
- **Files added/changed:** `docs/ai-prompts/T5-02.md`, `docs/ai-usage.md`, `game/autoload/settings.gd`, `game/export_presets.cfg`, `game/project.godot`, `game/tests/test_phone_polish.gd`, `game/tests/test_phone_polish.gd.uid`, `game/ui/DayHud.tscn`, `game/ui/day_hud.gd`, `game/ui/debrief_screen.gd`, `game/ui/ending_overlay.gd`, `game/ui/mission_map.gd`, `game/ui/pack_screen.gd`, `game/ui/safe_area.gd`, `game/ui/safe_area.gd.uid`, `game/ui/sources_screen.gd`, `game/ui/title_screen.gd`, `game/web/shell.html`, `game/world/camera_rig.gd`, `tools/serve.py`, `tools/serve_web.ps1`.
- **Next:** `T6-01` (Sources, credits and README).
