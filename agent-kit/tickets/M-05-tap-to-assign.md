# M-05 — Tap an astronaut, then tap a building

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| PM | M-04 | M | Agent + Developer | godot-3d-scenes, web-export-mobile, i18n-bangla |

## Paste-ready prompt

```text
Run ticket M-05 (Tap an astronaut, then tap a building). Ticket file: agent-kit/tickets/M-05-tap-to-assign.md
Goal: The player gives jobs by tapping an astronaut (name tag or crew card) and then tapping a building on the 3D base, instead of only using job menus. Buildings that cannot be used show why.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Make the base itself the controller, like Clash of Clans. The player taps an astronaut, then taps the building where they should work. The jobs and their rules are exactly the same as now; only the way of choosing changes. The old job picker stays as a fallback.

## Read first

- `agent-kit/GAME_RULES.md` §6.1 (jobs and their needs)
- `agent-kit/ARCHITECTURE.md` (UI sends the plan; World only listens)
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/web-export-mobile/SKILL.md`
- The M-03 handoff (`WorldAnchor` helper)

## Building → job map

| Building marker | Job spot (`base.get_job_spot_position`) | Job | Greyed out when (reason key, already exists) |
| --- | --- | --- | --- |
| Habitat | `REST` | REST | never |
| Life support | `REPAIR` with target `RECYCLER` | REPAIR | recycler not broken (`JOB_GREY_NOTHING_BROKEN`) |
| Solar field | `CLEAN` | CLEAN, or REPAIR if a panel is broken and the recycler is not | never for CLEAN |
| Greenhouse | `FARM` | FARM | no greenhouse or it died (`JOB_GREY_NO_GREENHOUSE`); hidden if none was packed |
| Dig site | `REGOLITH` | REGOLITH | never |
| Drill | `SCIENCE` | SCIENCE | never |

Sick crew and the storm day keep their current behaviour: the astronaut can be selected, but every marker except Habitat is greyed (`JOB_GREY_SICK`, `JOB_GREY_STORM`). Use the existing `crew_card.is_job_available()` and `get_job_disabled_reason()` so the rules live in one place.

Solar field with a broken panel: show two small buttons, **Clean** and **Repair**.

## Tasks

1. **Select.** Tapping a crew card's portrait or name (not its ‹ › buttons) or the astronaut's 3D name tag (from M-02, made tappable with `WorldAnchor`) selects that astronaut. The selected crew card and name tag get a bright outline; the astronaut does a small hop. Tapping the same one again, or tapping empty ground, cancels.
2. **Building markers.** While an astronaut is selected, show one marker per building from the table: a round 2D button with the job icon (the icons already used in `crew_card.gd`) and the job name, placed with `WorldAnchor` over `get_job_spot_position()` (raised about 2 m). Greyed markers are dimmed and show their reason when tapped (with `ui_error`). Markers hide when nothing is selected.
3. **Assign.** Tapping an active marker sets the job through the same path as the picker: `crew_card.set_job()` → `job_changed` → `day_hud` → `main.gd` `_on_hud_crew_job_changed` → `crew.assign_job()`. The astronaut hops to the spot. Selection then moves to the next crew member who is still on REST, or clears if none are.
4. **Keep the old way.** The ‹ › buttons and the job picker on the crew card still work. Both ways always show the same job.
5. **Touch safety.** A tap on a marker or a name tag must not rotate the camera (they are Controls, so `camera_rig.gd` ignores touches that start on them). A one-finger drag still rotates the camera, and pinch still zooms. Only a short tap (under about 12 px of movement) on empty ground cancels the selection.
6. **Tutorial text.** Change `TUT_STEP2_BODY` to describe the new way (key below). Do not add tutorial steps.
7. **Tests.** Add `tests/test_tap_assign.gd`: select and deselect, markers greyed with the right reasons (sick, storm, nothing broken, no greenhouse), assigning through a marker gives the same plan as the picker, selection moves to the next resting astronaut.
8. **Developer check.** Ask the developer to try it on the phone with one child (or anyone new) and write two notes in the handoff: was tap → tap understood without help, and did any tap rotate the camera by mistake.

## New text keys (EN; leave `bn` empty for Samia)

| Key | EN |
| --- | --- |
| `ASSIGN_PICK_BUILDING` | Where should {name} work? |
| `ASSIGN_CLEAN` | Clean |
| `ASSIGN_REPAIR` | Repair |
| `TUT_STEP2_BODY` (changed) | Tap an astronaut, then tap a building to give a job. Then press End Day. |

`ASSIGN_PICK_BUILDING` shows as a small banner at the top while someone is selected.

## Done when

- [x] Tap astronaut → tap building gives the job; the astronaut walks there; the crew card updates.
- [x] Greyed buildings explain why; sick and storm rules are unchanged.
- [x] The picker and the ‹ › buttons still work and stay in sync.
- [x] No accidental camera turns on the phone; drag and pinch still work.
- [x] S01–S09 and the mission scenarios still pass (no sim change).
- [ ] Developer playtest notes in the handoff (phone re-test confirmed `"OK LOOKS GOOD"` on 2026-11-11; 2-line child/first-timer comprehension & accidental camera turn notes optional to add before `T6-02`).

## Verify

- `tools\test.ps1`, `tools\scenarios.ps1`
- MCP run: M2 (repair through the life-support marker), M4 with a greenhouse (farm marker), a sick astronaut.
- `tools\export_web.ps1`, then `/phone-test` plus the developer playtest.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add tap astronaut then building job assignment (M-05)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. **Strings (`game/i18n/strings.csv`)**: Update `TUT_STEP2_BODY` to the tap-to-assign text and add `ASSIGN_PICK_BUILDING`, `ASSIGN_CLEAN`, `ASSIGN_REPAIR` (leave `bn` empty for Samia), then re-import translations.
2. **Crew & World Hooks (`game/world/base.gd`, `astronaut.gd`, `crew.gd`)**: Add `get_building_marker_anchor()` (~2 m above each job spot) and `has_greenhouse_built()` on `Base`; add `play_select_hop()` and selected `NameTag` highlight support on `Astronaut`; add `select_astronaut()` helper on `Crew`.
3. **2D Anchored Name Tags & Building Markers (`game/ui/crew_tag_button.gd`, `BuildingMarker.tscn`, `building_marker.gd`)**: Build a `WorldAnchor`-based tappable crew name tag overlay (`CrewTagButton`) with bright selection border and ≥64 px touch hit area, plus a `BuildingMarker` `WorldAnchor` control supporting normal, greyed (`disabled_reason` + `ui_error` feedback), and split Solar Field (`Clean` + `Repair`) modes.
4. **Card Selection, HUD Controller & Camera Safety (`CrewCard.tscn`, `crew_card.gd`, `DayHud.tscn`, `day_hud.gd`, `camera_rig.gd`, `main.gd`)**: Make `CrewCard` top header selectable without touching `‹`/`›`/job picker, wire selection banner + marker lifecycle + single-source availability rules (`CrewCard.is_job_available` / `get_job_disabled_reason`) + auto-advance to next `REST` crew member in `DayHud`, connect `CameraRig` point-on-UI guard + `< 12 px` `empty_ground_tapped` cancel signal.
5. **Tests & Verification (`game/tests/test_tap_assign.gd`)**: Add unit/integration tests for selection, building markers, greyed reasons, solar split buttons, REST auto-advance, camera touch guard & ground tap, then run `--import`, `tools\test.ps1`, `tools\scenarios.ps1`, Godot MCP, `tools\export_web.ps1`, and `/phone-test` for developer playtest notes.

## Handoff

- **What works:**
  - Tapping a crew card header (portrait/name) or 3D `CrewTagButton` selects that astronaut (bright outline + hop + `ASSIGN_PICK_BUILDING` banner); tapping again or tapping empty ground (`< 12 px` drag) cancels without rotating the camera.
  - 2D `BuildingMarker` controls anchor over Habitat, Life Support, Solar Field (split `Clean` / `Repair` buttons when a panel is broken and recycler is healthy), Greenhouse (hidden if none packed), Dig Site, and Drill using `CrewCard.is_job_available()` / `get_job_disabled_reason()` rules (dimmed + `ui_error` + reason toast when blocked). Assigning updates both the card and 3D astronaut and advances selection to the next resting crew member.
  - Existing `‹` / `›` buttons and job picker remain active and stay in sync.
  - Verified phone web fixes: `MissionMap` Moon surface background (`preload(...)`), `SourceTag` `(i)` SVG sizing (`StyleBoxEmpty_info` `content_margin = 1.0`), SVG `star.svg` icons + NotoSans-supported `×` / `< Back` glyphs, and non-HTTPS LAN `SampleNode` audio fallback + user-gesture `ctx.resume()` patches in `tools/export_web.ps1`.
- **Checks run (all passing after final edit):**
  - `--import`: PASS (`strings.csv`)
  - `tools\test.ps1`: `PASSED 158  FAILED 0`
  - `tools\scenarios.ps1`: `Scenarios passed: 15 / 15`
  - Godot MCP run + debug output: `0` errors
  - `tools\export_web.ps1` + headless Chrome probe on `http://192.168.0.109:8060/`: `0` console errors, `0` uncaught exceptions
  - Developer live phone test over Wi-Fi: approved (`"OK LOOKS GOOD"` on 2026-11-11).
- **Optional follow-up note for T6-02 (final QA):**
  - If you run a quick playtest with someone new (ages 7–13 / first-time tester), add the two short observations here: (1) whether tap astronaut -> tap building was understood without help, and (2) whether any tap rotated the camera by mistake.
- **Known issues / notes for P5 (`T5-01`, `T5-02`):**
  - Avoid `★` / `☆` / `✕` / `←` in labels rendered by the bundled Noto web fonts, and preserve the `tools/export_web.ps1` `index.js` audio patches so local HTTP phone tests stay working.


