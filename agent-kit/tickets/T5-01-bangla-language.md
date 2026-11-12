# T5-01 — English / Bangla toggle

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P5 | T4-04 | M | Agent | i18n-bangla |

## Paste-ready prompt

```text
Run ticket T5-01 (English / Bangla toggle). Ticket file: agent-kit/tickets/T5-01-bangla-language.md
Goal: Every screen works in both languages; the Bangla text comes from the team.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Every screen works in both languages; the Bangla text comes from the team.

## Read first

- `.agent/skills/i18n-bangla/SKILL.md`
- `agent-kit/TEAM_TASKS.md`

## Tasks

1. Check every visible string is a `tr()` key in `strings.csv`; add missing keys.
2. Toggle on title and in the menu; screens refresh on `Settings.language_changed`. Facts use `bn` when filled.
3. Export the list of keys with empty `bn` for the team (print it in the handoff). Do not write Bangla yourself.
4. When the team's Bangla is in: check every screen in Bangla for clipping and missing glyphs.

## Done when

- [ ] All screens switch language; no clipped text; no boxes.
- [ ] Empty `bn` falls back to English.

## Verify

- MCP run in both languages.
- `/phone-test` (Wi-Fi) + phone check in Bangla.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add English/Bangla language toggle (T5-01)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan
1. Audit all UI/world scripts and scenes against `game/i18n/strings.csv`, adding any missing UI keys (with empty `bn` for the team) and verifying Godot's `"en"` fallback for empty `"bn"` entries.
2. Wire `Settings.language_changed` and live text refresh across all remaining screens and widgets (`DayHud` gauges/pause menu/switches/toasts, `CrewCard`, `CrewTagButton`, `Astronaut` NameTag, `DebriefScreen`, `EndingOverlay`, `SourcesScreen`, `PackScreen`, `MissionMap`).
3. Ensure `NotoSansBengali` font/theme fallback covers 3D `Label3D` (`Astronaut.tscn`) and floating popups (`SpeechBubble.tscn`, `CrewTagButton.tscn`, `BuildingMarker.tscn`, `CollectBubble.tscn`), raise PauseMenu buttons to 64 px, and fix `"✕"` in `SourceTag.tscn` to `"×"`.
4. Add `game/tests/test_i18n.gd` covering EN/BN toggles across all screens, empty-`bn` English fallback, and `facts.json` `bn`/fallback selection.
5. Re-import translations, run `tools\test.ps1` and `tools\scenarios.ps1`, run MCP/Godot smoke check in `"en"` and `"bn"`, export web, and run `/phone-test` with the developer.

## Handoff

- **What works:**
  - `game/i18n/strings.csv` now has all `220 / 220` rows populated with child-friendly Bangla translations (using Western digits `0-9` and preserving all `{placeholders}`), and `game/data/facts.json` has all `16 / 16` science facts (`F01`–`F16`) filled in Bangla. `strings.csv` is re-imported into `strings.en.translation` and `strings.bn.translation`, and English fallback remains verified for missing-`bn` keys/facts.
  - All UI screens and world widgets (`TitleScreen`, `MissionMap`, `PackScreen`, `DayHud` + PauseMenu + 7 gauges + switches + toasts, `CrewCard`, `CrewTagButton`, `Astronaut` `NameTag`/`SickIcon`, `SpeechBubble`, `BuildingMarker`, `CollectBubble`, `EventPopup`, `EndingOverlay`, `DebriefScreen`, `SourcesScreen`, `SourceTag`) switch cleanly on `Settings.language_changed` (`"en"` ↔ `"bn"`) with `NotoSans` + `NotoSansBengali` fallback, 64 px PauseMenu buttons (`ResumeBtn`, `SourcesBtn`, `LangBtn`), and `×` on `SourceTag` `CloseButton`.
  - Bangla layout & glyph verification (`check_bn_screens.gd` under Compatibility OpenGL at `1280x720`) confirmed `GLYPH_CHECK OK` (every codepoint in `strings.csv` and `facts.json` supported in both `font_regular.tres` and `font_bold.tres`) and `BANGLA_AUDIT issues=0 warnings=0` (zero clipping, overflow, or missing keys across TitleScreen, MissionMap, PackScreen + popover, DayHud + PauseMenu, TutorialOverlay Steps 1–4 & hint, EventPopup event/alerts, Debrief win/evac, EndingOverlay, SourcesScreen).
- **Checks run (latest results):**
  - `--headless --path game --import --quit`: PASS (exit 0; `strings.csv` imported to `strings.bn.translation` / `strings.en.translation`).
  - Live Compatibility OpenGL Bangla audit (`check_bn_screens.gd`): **PASS (`GLYPH_CHECK OK`, `BANGLA_AUDIT issues=0 warnings=0`)**.
  - `.\tools\test.ps1`: **PASSED 162  FAILED 0** (`game/tests/test_i18n.gd` verifies 220/220 CSV `bn` rows, placeholder parity, all 16 `facts.json` `bn` entries, missing-`bn` fallback, and EN/BN live refresh).
  - `.\tools\scenarios.ps1`: **15 / 15 PASS**.
  - Godot MCP `run_project` + `get_debug_output` + `stop_project` (`M1` Pack + Launch): **PASS (0 runtime errors)**.
  - `.\tools\export_web.ps1`: **PASS** (`D:\MOONBASE\Moonbase-Commander\build\web\index.html`; total `46.15 MB`, `index.pck` `9.85 MB`).
  - `/phone-test` (`.\tools\serve_web.ps1`): Clean single instance running at `http://192.168.0.109:8060/` (`HTTP 200` on `/index.pck`; stale duplicate PID `27044` cleaned up) — **phone check PASS (`"looks goof"`)**.
- **Developer follow-up note (`samia if out of town we dont have time you fill them`):**
  - All 213 previously empty CSV `bn` keys and 16 `facts.json` `bn` entries were filled directly by the agent; team can still refine any phrasing in `strings.csv` / `facts.json` anytime.
  - Remaining empty list removed (220 / 220 CSV keys and 16 / 16 `facts.json` entries now populated).
- **Phone check result:** Verified by developer on phone over Wi-Fi (`http://192.168.0.109:8060/`) in Bangla (`"looks goof"`).
