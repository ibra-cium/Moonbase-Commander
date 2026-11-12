# M-09 — Moon Science Cards: learn while you play

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| PM | M-08 | M | Agent | i18n-bangla, web-export-mobile, nasa-data |

## Paste-ready prompt

```text
Run ticket M-09 (Moon Science Cards: learn while you play). Ticket file: agent-kit/tickets/M-09-science-cards.md
Goal: 29 real NASA-sourced facts become collectible Science Cards. Each unlocks at the moment it matters in play (landing, sunset, storm, drilling science, a breakdown...), pops up as a small "New Science Card!" toast, and is kept in an album on the map with its source. Quiet days get a "Did you know?" from Mission Control.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Why

Right now a kid sees one fact per mission, at the very end. The team has 29 sourced facts (`facts.json`), and kids learn best when a fact arrives at the moment it means something. The sunset card arrives as the sun sets; the moonquake card arrives after enough drilling. Collecting cards (like a card album, or upgrades in Clash of Clans) gives kids a reason to replay and try new things.

The card list, triggers, titles and hints are already in `game/data/learning.json` → `cards`, `science_thresholds` and `quiet_day_pool`. **Do not rewrite the text.**

## Read first

- `game/data/learning.json`, `game/data/facts.json`
- The M-08 handoff (`LearningData`, `Settings.collect_card`)
- The M-02 and M-04 handoffs (speech bubbles, alert-card queue)
- `.agent/skills/web-export-mobile/SKILL.md`

## Trigger rules

`ui/card_triggers.gd` (`class_name CardTriggers`, `RefCounted`, pure) takes the previous and current day reports, today's jobs and a context dictionary, and returns the trigger IDs that fired today. Use the real `SimDayReport` field names.

| Trigger | When |
| --- | --- |
| `landed` | first report of a mission |
| `first_outside_job` | any job today is outside (REGOLITH, SCIENCE, CLEAN, or REPAIR of a panel) |
| `first_regolith` | `shelter_g_cm2` went up |
| `science_N` | the **session** science total (all missions added together) crossed N, using `science_thresholds` |
| `dusty` | `dust` > 0.2 |
| `first_clean` | a CLEAN job today |
| `meteoroid` | a `METEOROID` event today |
| `recycler_broke` | a `RECYCLER_BROKE` event today |
| `storm_warning` | the storm day starts, after the M-04 countdown card closes |
| `storm_survived` | the storm day resolves without evacuation |
| `sunset` | `day == SUNSET_DAY`, after the M-04 night card closes |
| `night_reactor` | night (`sun_factor == 0`) and `reactor_kwh > 0` |
| `night_battery_low` | night and `battery_percent` < 30 |
| `first_farm` | a FARM job today with a living greenhouse |
| `crew_tired` | any crew member reached 0 energy, or got sick from overwork (M-06) |
| `quiet_day` | nothing else fired today and no alert showed; every second quiet day; gives the next uncollected fact from `quiet_day_pool` |

`briefing_M*` and `debrief_M*` cards are collected by the M-08 screens, not here. A trigger whose card is already collected does nothing.

## Tasks

1. **Triggers.** Build `ui/card_triggers.gd` per the table, plus a small controller in `scenes/main.gd` (or `ui/card_controller.gd`) that runs after each `day_resolved` and calls `Settings.collect_card()`.
2. **Toast.** A "New Science Card!" toast at the top centre, one line: a card icon, `CARD_NEW` and the card title. It stays 4 s; tapping it opens the card. At most 2 per day; extra ones wait for the next day (they are already collected, so nothing is lost). It queues behind M-04 alert cards, the tutorial and speech bubbles, and never covers End Day. Sound: soft `ui_confirm`.
3. **Quiet-day cards** appear as a Mission Control "Did you know?" chip (headset icon + `CARD_DID_YOU_KNOW` + title) instead of the toast. Tapping it opens the card.
4. **Card view.** `ui/CardView.tscn`: a coloured top band by category (moon = Regolith grey, survival = Oxygen blue, nasa = gold, as in ART_DIRECTION §1 or the closest existing colours), the title, the fact text (`LearningData.text()`), and a `SourceTag` with the source name; tapping it opens the link like the Sources screen does. Close button. This is a reading view the player opens, not an interrupting popup, so 3 lines of text are fine.
5. **Album.** `ui/CardAlbum.tscn`, opened from a new map button `CARD_ALBUM_COUNT`.
   - A grid: 3 columns on a phone in portrait, 5 in landscape; scrolls.
   - Collected cards show colour, icon and title; tapping opens the card view.
   - Locked cards are dark with "?", `CARD_LOCKED` and `CARD_HOW_TO_FIND` with the hint.
   - Tabs: `CARD_TAB_ALL`, `CARD_TAB_MOON`, `CARD_TAB_SURVIVAL`, `CARD_TAB_NASA`.
6. **Debrief.** Add a line `DEBRIEF_NEW_CARDS` with small card icons for the cards collected during this mission (including the M-08 briefing and NASA cards). Tapping it opens the album. The existing "Did you know?" debrief fact also gets collected.
7. **Certificate.** The `CERT_CARDS` line from M-08 now shows.
8. **Sources for judges.** Add a `## Facts and Science Cards` table to `Moonbase-Commander/data/sources.md`: ID, card title, fact (EN), source, link. Generate it from `facts.json` + `learning.json` so it matches exactly. If quick, add a "Facts" tab to the in-game Sources screen with the same list.
9. **Tests.** Add `tests/test_card_triggers.gd` covering:
   - each trigger fires once, from the right report change
   - science thresholds count across missions
   - quiet-day pool order, and every second quiet day only
   - at most 2 toasts a day
   - collected cards never fire again
   - every card in `learning.json` has a fact and every fact has exactly one card (29 = 29)

## New UI text keys (EN; Samia fills `bn`)

| Key | EN |
| --- | --- |
| `CARD_NEW` | New Science Card! |
| `CARD_DID_YOU_KNOW` | Did you know? |
| `CARD_ALBUM` | Science Cards |
| `CARD_ALBUM_COUNT` | Science Cards {n}/{total} |
| `CARD_LOCKED` | Not found yet |
| `CARD_HOW_TO_FIND` | How to find it: {hint} |
| `CARD_TAB_ALL` | All |
| `CARD_TAB_MOON` | Moon |
| `CARD_TAB_SURVIVAL` | Astronaut life |
| `CARD_TAB_NASA` | NASA now |
| `CARD_CLOSE` | Close |
| `DEBRIEF_NEW_CARDS` | New Science Cards this mission: {n} |

## Done when

- [ ] Playing M1 → M4 unlocks cards at the right moments, with a toast or a Did-you-know chip; nothing covers alerts or End Day.
- [ ] The album shows 29 cards: collected ones open with text and source, locked ones show a hint.
- [ ] The debrief lists the new cards; the certificate shows the count.
- [ ] `sources.md` lists all 29 facts with sources.
- [ ] All tests and scenarios pass (no simulation change).

## Verify

- `tools\test.ps1`, `tools\scenarios.ps1`
- MCP run: M4 with a reactor and science jobs → at least landing, science 1/3/6, sunset, night reactor and storm cards.
- `tools\export_web.ps1`, then `/phone-test`: toast readable and not blocking taps; album scrolls; works in Bangla.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add Moon Science Cards with triggers, album and sources (M-09)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan
1. Add `LearningData` card/threshold/pool helpers, session card tracking in `Settings` (`mission_collected_cards`, `session_science_total`, `quiet_day_counter`), and a pure `CardTriggers` evaluator (`game/ui/card_triggers.gd`).
2. Build `CardView` (category header band, fact text, `SourceTag`, Close button) and `CardAlbum` (4 tabs, 3-col portrait / 5-col landscape grid, collected & locked tiles), and add the `CARD_ALBUM_COUNT` button to `MissionMap`.
3. Wire `CardController` in `main.gd` + `DayHud` toast (4 s, max 2/day, queued behind alerts/tutorials/hints/bubbles) and Mission Control quiet-day chip (`CARD_DID_YOU_KNOW`).
4. Update `DebriefScreen` (`DEBRIEF_NEW_CARDS` row + collect debrief fact), `CertificateScreen` (`show_cards_count = true`), `SourcesScreen` Facts tab, `data/sources.md` (`## Facts and Science Cards`), and `game/i18n/strings.csv` (12 EN keys).
5. Add `game/tests/test_card_triggers.gd`, update `test_learning.gd` for certificate cards label, import assets, and run `test.ps1`, `scenarios.ps1`, MCP M4 playtest, and `export_web.ps1`.

## Handoff
- What works:
  - `LearningData` card/trigger/threshold/pool lookup + `Settings` session card tracking (`mission_collected_cards`, `session_science_total()`, `quiet_day_counter`) + pure `CardTriggers` & `CardController` (all 16 gameplay/science triggers fire once per session, quiet-day chip every 2nd quiet planning day from `quiet_day_pool`, max 2 toasts per day with next-day rollover).
  - `DayHud` top-centre toast (`CARD_NEW`) and Mission Control quiet-day chip (`CARD_DID_YOU_KNOW`) queued cleanly behind M-04 `EventPopup`, tutorials, context hints, and crew `SpeechBubble`, never blocking `End Day`.
  - `CardView` (category colour top band, fact body, `SourceTag` link info) and `CardAlbum` (4 tabs `All` / `Moon` / `Survival` / `NASA`, 3 columns in portrait / 5 columns in landscape, locked `?` tiles with unlock hints), opened from `MissionMap` (`CARD_ALBUM_COUNT`) and `DebriefScreen` (`DEBRIEF_NEW_CARDS` row), plus `CertificateScreen` card count and `SourcesScreen` Facts filter + `data/sources.md` 29-card table.
- Verified checks: `tools\test.ps1` (`PASSED 183  FAILED 0`), `tools\scenarios.ps1` (`16 / 16`), Godot MCP `run_project` + `get_debug_output` (`0` errors, `0` warnings in M-09 scripts), and `tools\export_web.ps1` (`build\web\index.html`).
- What to test by hand: Run `/phone-test` (`tools\serve_web.ps1`) on phone over Wi-Fi: play Mission 4 with reactor + science/regolith jobs through Day 15 sunset/lunar night to observe toast/chip timing behind alerts and speech bubbles, open `CardAlbum` in portrait and landscape, check `DebriefScreen` ("New cards this mission") and `SourcesScreen` ("Facts" filter).
- Known issues / ideas for later: `bn` translations for the 12 new `M-09` CSV keys (`CARD_NEW`..`DEBRIEF_NEW_CARDS`) are left empty (cleanly falling back to English) until Samia translates `strings.csv`. `game/sim/*.gd` untouched. Next ticket is `M-07` (`M-07-kid-gauges.md`).
