# M-08 — Junior astronaut training: briefing, guess first, answer after

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| PM | M-06 | L | Agent | i18n-bangla, web-export-mobile, nasa-data |

## Paste-ready prompt

```text
Run ticket M-08 (Junior astronaut training: briefing, guess first, answer after). Ticket file: agent-kit/tickets/M-08-astronaut-training.md
Goal: Each mission starts with a short Mission Control briefing and one "Guess first!" question. The debrief asks the same question again, explains the answer with real NASA numbers, shows the lesson and a "NASA is working on this right now" card, and promotes the player from Cadet to Moonbase Commander. The map shows a before/after training score, and finishing Mission 4 gives a certificate.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Why

The challenge is called **Build a Junior Astronaut Mission Trainer**. Right now kids play, but nothing shows what they learned or connects it to NASA. This ticket wraps every mission in a learning loop:

**Guess (before) → experience it (play) → answer again (after) → see the real NASA work on it.**

Comparing the two answers gives a built-in learning score that the team can show the judges (Impact criterion).

All content is already written, with sources:
- `game/data/learning.json` (new, 11 Nov): Mission Control briefings, one question per mission, lessons, ranks, card list for M-09.
- `game/data/facts.json`: now F01–F29 (F17–F29 added 11 Nov).

**Do not rewrite the text.** If something does not fit on a phone, say so in the handoff.

## Read first

- `agent-kit/CONTEXT.md` (hard rules 1–4, 7)
- `game/data/learning.json` and `game/data/facts.json`
- `docs/impact.md`
- `.agent/skills/i18n-bangla/SKILL.md`, `.agent/skills/web-export-mobile/SKILL.md`

## Tasks

1. **Loader (pure).** `ui/learning_data.gd` (`class_name LearningData`, `RefCounted`, no nodes) loads `learning.json` and `facts.json`.
   - `text(obj) -> String`: returns `bn` when the language is Bangla and `bn` is not empty; otherwise `en`. The same rule applies to facts.
   - `format(s) -> String`: replaces `{CONSTANT_ID|fmt}` with `Constants.v(ID)`. Formats: `0` = whole number, `1` = one decimal, `pct` = ×100 then `%`, `k` = rounded to the nearest 1,000 with commas. Expected: M1 → "3.2", M2 → "98%", M3 → "398" and "47", M4 → "41,000" and "15,000".
   - `briefing(mid)`, `question(mid)`, `lesson(mid)`, `nasa_now_fact(mid)`, `rank_after(mid)`, `fact(id)`.
2. **Session state** in `autoload/settings.gd` (session only, like the stars):
   - `training: Dictionary`: mission id → `{"before": -1, "after": -1}`.
   - `rank_id: String = "CADET"`.
   - `collected_cards: Array[String]` and `collect_card(fact_id) -> bool` (true when new). M-09 builds on this.
   - `training_score() -> Dictionary`: `before_right`, `after_right`, `answered`.
3. **Mission Control briefing.** Create `ui/MissionBriefing.tscn` + `ui/mission_briefing.gd`. Add a `State.BRIEFING` in `scenes/main.gd`: Map → **Briefing** → Pack.
   - The header shows a headset or `rocket_launch` icon and the name from `learning.json` → `mission_control`. No face: Mission Control is not a person.
   - Show the two briefing cards one at a time (title + one or two lines, **Next**). A card with `fact_id` shows the fact text, a small `BRIEF_FACT_BADGE` badge and a `SourceTag` using the fact's source and link, and collects that card (`Settings.collect_card`).
   - Then the **Guess first!** screen: the question and three big answer buttons (64 px), plus `GUESS_HINT` under them. Store the answer in `training[mid].before` only the first time this mission is played in the session. No right/wrong is shown here.
   - **Let's go!** → Pack. On a replay of the same mission, show a **Skip** button and do not ask the question again.
4. **Debrief: learning steps.** In `ui/debrief_screen.gd`, after the existing result (stars, cause chain, fact), add these as short steps. Use one step per screen on a phone, or sections on a wide screen; each needs a **Next** button.
   - **Now you know!** The same question again. The player taps an answer; show ✓ `DEBRIEF_RIGHT` or `DEBRIEF_WRONG`, highlight the right option, then the formatted `explain` text with a `SourceTag` for `constant_ids[0]`. If there was a guess before, show `DEBRIEF_YOU_GUESSED`. Store `training[mid].after` the first time only. This step shows **even when the mission failed**: kids learn most from failing.
   - **You learned:** the mission's `lesson` with a badge icon.
   - **NASA is working on this right now:** the text of the `nasa_now_fact`, with its source tag, and collect that card.
   - **Rank up:** if the mission was survived (at least 1 star) and its `rank_after` is higher than the current rank, set `Settings.rank_id` and show `DEBRIEF_NEW_RANK` with a small celebration (the existing `ui_confirm` sound plus the star animation, if one exists).
   - The existing "Did you know?" fact must not repeat the mission's `nasa_now_fact`.
5. **Map.**
   - A rank badge at the top: `MAP_RANK`.
   - Once at least one after-answer exists, show the `MAP_TRAINING_SCORE` line.
   - A small **Results** button opens a panel listing, per mission: before ✓/✗/–, after ✓/✗/–, and stars. Add a **Copy** button that copies a one-line summary with `DisplayServer.clipboard_set()` and shows `RESULTS_COPIED`, plus the `RESULTS_NOTE` line. No names anywhere.
6. **Certificate.** When Mission 4 is survived, the debrief shows **Get your certificate**. It opens `ui/CertificateScreen.tscn`, which shows:
   - `CERT_TITLE`, the rank, stars per mission
   - `CERT_LEARNED` with the lessons of the survived missions (✓ each)
   - `CERT_CARDS` (only if M-09 is in; otherwise hide the line)
   - today's date (`Time.get_date_string_from_system()`), and `CERT_FOOTER`

   **No NASA logo (hard rule 3), no name field (hard rule 4).** The layout must look good in a phone screenshot, portrait and landscape. **Back to map** returns to the map.
7. **Title.** Show the subtitle `TITLE_SUBTITLE_TRAINING` under the game title.
8. **Bangla fallback.** Content with an empty `bn` shows English. Check `tr()` too: a `strings.csv` key with an empty `bn` cell must show English, not the key or an empty label. If it does not, fix it in code; do not copy English into Samia's column.
9. **Tests.** Add `tests/test_learning.gd` covering:
   - the four formatted explanations (exact strings above), and the bn → en fallback
   - every `fact_id` and `nasa_now_fact` exists in `facts.json`, and every `{ID|fmt}` exists in `constants.json`
   - `before` is stored only once and `after` only once; the training score is right
   - the rank only goes up, and only on a win
   - the certificate is only offered after an M4 win
   - the debrief fact skips the `nasa_now_fact`

## New UI text keys (EN; Samia fills `bn`)

| Key | EN |
| --- | --- |
| `BRIEF_NEXT` | Next |
| `BRIEF_SKIP` | Skip |
| `BRIEF_GO` | Let's go! |
| `BRIEF_FACT_BADGE` | Real NASA fact |
| `GUESS_TITLE` | Guess first! |
| `GUESS_HINT` | It's OK not to know – you will find out by playing! |
| `DEBRIEF_NOW_YOU_KNOW` | Now you know! |
| `DEBRIEF_RIGHT` | Correct! |
| `DEBRIEF_WRONG` | Not quite – here is the answer: |
| `DEBRIEF_YOU_GUESSED` | Before the mission you guessed: {answer} |
| `DEBRIEF_LEARNED` | You learned |
| `DEBRIEF_NASA_NOW` | NASA is working on this right now |
| `DEBRIEF_NEW_RANK` | New rank: {rank}! |
| `DEBRIEF_CERTIFICATE` | Get your certificate |
| `MAP_RANK` | Rank: {rank} |
| `MAP_TRAINING_SCORE` | Training score: before {b}/{n} → after {a}/{n} |
| `MAP_RESULTS` | Results |
| `RESULTS_TITLE` | Training results |
| `RESULTS_COL_MISSION` | Mission |
| `RESULTS_COL_BEFORE` | Before |
| `RESULTS_COL_AFTER` | After |
| `RESULTS_COL_STARS` | Stars |
| `RESULTS_COPY` | Copy |
| `RESULTS_COPIED` | Copied! |
| `RESULTS_NOTE` | No names are saved. Results stay on this device. |
| `CERT_TITLE` | Junior Astronaut Training Complete |
| `CERT_LEARNED` | You learned: |
| `CERT_CARDS` | Science Cards: {n} / {total} |
| `CERT_FOOTER` | Moonbase Commander · Team Space-ArenaX · NASA Space Apps Challenge 2026 · Not an official NASA certificate. |
| `CERT_BACK` | Back to map |
| `TITLE_SUBTITLE_TRAINING` | Junior Astronaut Training |

## Done when

- [x] Map → Briefing (2 cards + Guess first!) → Pack works for all four missions; replays can skip.
- [x] The debrief asks the question again, explains it with the right numbers and sources, and shows the lesson, the NASA card and rank-ups.
- [x] The map shows the rank, the training score and the Results panel with Copy.
- [x] The certificate appears after an M4 win: no logo, no name, readable in a screenshot.
- [x] English shows when `bn` is empty (content and UI keys).
- [x] All tests and scenarios pass (this ticket does not touch the simulation).

## Verify

- `tools\test.ps1`, `tools\scenarios.ps1`
- MCP run: play M1 (guess wrong, then answer right), lose M2 on purpose (the learning steps still show), switch Free play on and win M4 (certificate).
- `tools\export_web.ps1`, then `/phone-test`: the briefing and debrief steps fit a phone in both languages.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add astronaut training briefings, guess-first questions, ranks and certificate (M-08)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Add `ui/learning_data.gd` (`LearningData` loading `learning.json` + `facts.json`, `{ID|fmt}` formatter, `bn->en` fallback) and extend `autoload/settings.gd` with session `training`, `rank_id`, `collected_cards`, and score/promotion helpers.
2. Extend `SourceTag` for fact provenance (`source` + `link`), build `ui/MissionBriefing.tscn` + `mission_briefing.gd`, and wire `Map -> Briefing -> Pack` (and Debrief `Next mission -> Briefing`) in `scenes/Main.tscn` + `main.gd`.
3. Add post-result learning steps (`Now you know!`, `You learned`, `NASA right now`, `Rank up`, M4 `Get your certificate`) to `DebriefScreen` while preserving Debrief's `Did you know?` non-duplication of `nasa_now_fact`.
4. Add rank badge, training score, and copyable Results panel (no names) to `MissionMap`; build `CertificateScreen` (no name, no NASA logo); update `TitleScreen` subtitle; add `check.svg` and the 30 CSV keys (empty `bn`); write `tests/test_learning.gd` and run full verification + web export.

## Handoff

- **What was built:**
  - `LearningData` (`ui/learning_data.gd`): loads `learning.json` and `facts.json`, applies `bn -> en` fallback, and formats `{CONSTANT_ID|fmt}` placeholders (`0`, `1`, `pct`, `k`) from `Constants.v()`.
  - `Settings` (`autoload/settings.gd`): added session-only `training`, `rank_id`, `collected_cards`, `collect_card()`, `training_score()`, `promote_after_win()`, and `reset_training()`.
  - `MissionBriefing` (`ui/MissionBriefing.tscn` + `mission_briefing.gd`) and `State.BRIEFING` in `scenes/main.gd`: `Map -> Briefing -> Pack` (and Debrief `Next mission -> Briefing`), showing `rocket_launch.svg` Mission Control header, 2 briefing cards (fact card `SourceTag.setup_fact()` + `collect_card()`), 64 px "Guess first!" buttons stored once per mission, and replay `Skip`.
  - `DebriefScreen` (`ui/DebriefScreen.tscn` + `debrief_screen.gd`): post-result learning loop (`Now you know!` -> `You learned` -> `NASA right now` -> win-only `Rank up` celebration -> M4 `Get your certificate`) shown on both wins and losses, while skipping `nasa_now_fact` in "Did you know?".
  - `MissionMap` (`ui/mission_map.gd`): rank badge, `MAP_TRAINING_SCORE` summary, and no-name `Results` modal with `DisplayServer.clipboard_set()` copy.
  - `CertificateScreen` (`ui/CertificateScreen.tscn` + `certificate_screen.gd`), `TitleScreen` (`TITLE_SUBTITLE_TRAINING`), `assets/icons/check.svg`, 31 EN CSV keys (empty `bn` left for Samia, verified EN fallback in `bn` locale), and `tests/test_learning.gd`.
- **Phone / layout notes:**
  - Because `project.godot` uses `canvas_items` stretch with `aspect="expand"`, portrait viewports (`390x844`) keep logical width `1280` (`vp_size.y > vp_size.x`); updated `MissionBriefing`, `DebriefScreen`, and `CertificateScreen` to detect portrait via `vp_size.y > vp_size.x` so cards span cleanly without narrow centering or empty height gaps.
  - On short landscape viewports (`844x390`), answering `Now you know!` now defers one frame and auto-scrolls `FeedbackPanel` into view so the NASA explanation and `SourceTag` are visible right away.
  - Ready for physical phone verification via `/phone-test` against `build/web/index.html` (`bn` cells in `strings.csv` still need Samia's Bangla translations in P5/localization pass).
- **Checks run after final edit:**
  - `.\tools\test.ps1`: `PASSED 177  FAILED 0` (includes `test_learning.gd`, updated `test_i18n.gd`, and end-to-end `test_missions.gd`)
  - `.\tools\scenarios.ps1`: `Scenarios passed: 16 / 16`
  - `fontTools` glyph check across `strings.csv`, `learning.json`, `facts.json`: `missing_count: 0`
  - OpenGL `390x844` portrait + `844x390` landscape screenshot capture across Briefing, Guess, Debrief steps, Certificate, and Map Results: visually inspected clean
  - Godot MCP `run_project` + `get_debug_output` + `stop_project`: `0` errors, `0` warnings from M-08 scripts
  - `.\tools\export_web.ps1`: succeeded (`D:\MOONBASE\Moonbase-Commander\build\web\index.html`)
  - AI log updated in `docs/ai-prompts/M-08.md`, `docs/ai-usage.md`, and `agent-kit/COMMIT_LOG.md`
- **Next:** Run `/phone-test` if you want to check the live phone build over Wi-Fi; next ticket is **M-09** (`Moon Science Cards`).

