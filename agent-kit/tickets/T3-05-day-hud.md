# T3-05 — Day HUD: gauges, crew jobs, power switches

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P3 | T3-04 | L | Agent | i18n-bangla, nasa-data |

## Paste-ready prompt

```text
Run ticket T3-05 (Day HUD: gauges, crew jobs, power switches). Ticket file: agent-kit/tickets/T3-05-day-hud.md
Goal: Everything the player needs to plan a day on one screen, readable on a phone.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Everything the player needs to plan a day on one screen, readable on a phone.

## Read first

- agent-kit/ART_DIRECTION.md §8
- agent-kit/ARCHITECTURE.md (UI, Main flow)
- agent-kit/GAME_RULES.md §11
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/i18n-bangla/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`

## Tasks

1. `ui/DayHud.tscn`: top bar (Day N/30, sun/night icon, Fast toggle, menu); left column gauges (power: generation + battery %, oxygen, CO2, water, food days, radiation, shelter g/cm²) each with a source tag; bottom crew bar with 4 `CrewCard`s; right: greenhouse lights and science gear switches; big End Day button.
2. `ui/CrewCard.tscn`: suit colour, job picker (icons), greyed jobs that are not possible (sick, nothing broken, no greenhouse), sick icon, dose.
3. Short day summary after each resolve (toast, two lines max): e.g. "Battery lasted 19 h. Air system off."
4. Storm popup from `day_started` with one button (DECISIONS).
5. Remove the temporary HUD from T3-04.

## Done when

- [x] A full mission is playable on the phone with touch only.
- [x] Every gauge has a working source tag.
- [x] Jobs that cannot work are greyed with a reason.

## Verify

- MCP run + debug output.
- `/phone-test` (Wi-Fi) + phone check of the HUD.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add day HUD with gauges and crew jobs (T3-05)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `game/ui/CrewCard.tscn` & `crew_card.gd` displaying suit color, dose mSv, health/sick status, and a responsive job selector with Material Icons, greying invalid jobs (sick, nothing broken, no greenhouse, storm) with clear reasons.
2. Build full `game/ui/DayHud.tscn` & `day_hud.gd` featuring: TopBar (Day N/30, Sun/Night icon, Fast toggle, Menu button), LeftColumn (7 Gauges with SourceTags: Power, O2, CO2, Water, Food, Rad, Shelter), BottomBar (4 CrewCards), RightControls (Greenhouse lights and Science gear toggles, big End Day button), and a 2-line resolve toast.
3. Update `game/scenes/main.gd` to synchronize the plan between HUD and `GameState.submit_day()`, and ensure the start-of-day storm popup uses a single "Everyone to the shelter" button per DECISIONS.
4. Add all needed localization keys to `game/i18n/strings.csv` with English text and empty `bn` fallback.
5. Verify with `tools\test.ps1` (100% pass), `tools\scenarios.ps1`, and interactive headless scene execution.

## Handoff

- **What works:**
  - Full operational Day HUD (`DayHud.tscn` / `day_hud.gd`) featuring:
    - Top bar with Day counter (Day N/30), Sun/Night indicator with reactive icon and text, Fast (0.5s) resolution toggle, and in-game Menu/Pause button.
    - Left column with 7 gauges (Power, O2, CO2, Water, Food, Radiation, Shelter), thin progress bars, critical red pulsing alarms, and interactive `SourceTag`s (ⓘ) with popovers showing real NASA/scientific metadata.
    - Bottom bar with 4 `CrewCard`s (`CrewCard.tscn` / `crew_card.gd`) showing suit colors (orange, purple, pink, brown), accumulated radiation dose, sick warnings, 1-tap `<` / `>` job cycling, and an accessible 6-job popover grid that disables unavailable jobs with clear explanation labels (e.g. sick, nothing broken, no greenhouse, storm).
    - Right controls with Greenhouse lights and Science gear power switches, resolving indicator, and prominent 64 px tall "End Day" button.
    - Floating 2-line toast notification providing instant feedback on power generation, battery drain hours, system shedding, and event occurrences.
    - In-mission Pause dialog allowing instant language switching (English / বাংলা) and quick access to the Data Sources screen.
    - Solar storm warning popup from `GameState.day_started` uses single "Everyone to the shelter" button per DECISIONS.md.
  - All 106 headless tests in `tools\test.ps1` pass without errors or warnings.
  - All 9 balance scenarios S01–S09 in `tools\scenarios.ps1` pass with exact expected outcomes.
  - Web export (`tools\export_web.ps1`) succeeds cleanly.
- **What to test by hand:**
  - Run the game in browser via `tools\serve_web.ps1` or desktop Godot.
  - Test tapping each gauge's ⓘ source tag to inspect metadata popovers.
  - Test changing astronaut jobs via `<` / `>` and tapping the job button to open the 6-job popover grid. Verify disabled reasons appear as expected.
  - Test clicking "Menu" to toggle languages (English / বাংলা) or view the Data Sources screen, then resume the mission.
  - Step through days and verify that the 2-line day summary toast appears after each day.
- **Known issues:**
  - None.
- **Ideas for later tickets:**
  - Ticket T3-06 will build the Debrief screen with star breakdowns, cause chains, and contextual educational facts.
