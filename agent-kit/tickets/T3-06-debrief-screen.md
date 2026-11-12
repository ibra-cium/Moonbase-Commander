# T3-06 — Debrief: stars, cause chain, fact, retry

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P3 | T3-05 | M | Agent | i18n-bangla, nasa-data |

## Paste-ready prompt

```text
Run ticket T3-06 (Debrief: stars, cause chain, fact, retry). Ticket file: agent-kit/tickets/T3-06-debrief-screen.md
Goal: The learning moment: why the mission ended the way it did, one real fact with its source, and a quick retry.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

The learning moment: why the mission ended the way it did, one real fact with its source, and a quick retry.

## Read first

- agent-kit/ART_DIRECTION.md §8
- agent-kit/ARCHITECTURE.md (UI, Main flow)
- agent-kit/GAME_RULES.md §11
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/i18n-bangla/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`
- agent-kit/GAME_RULES.md §9
- `game/data/facts.json`

## Tasks

1. `ui/DebriefScreen.tscn`: outcome title, 0–3 stars, cause chain as a short timeline (day + icon + one line each), root cause sentence with values, one fact with source name, the seed.
2. For a forced storm: one line "Real chance of a strong storm in 30 days: about {p} %" (`SPE_CHANCE_STRONG_MISSION`).
3. Buttons: Retry (same cargo), Change cargo (back to PACK with last cargo), Title.
4. Root cause and chain texts as `tr()` keys with `{placeholders}`.

## Done when

- [x] Playing S01, S05 and S06 by hand gives the right root cause text.
- [x] A survived run shows which star is missing and why.

## Verify

- MCP run + debug output.
- `tools\test.ps1`
- `tools\scenarios.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add debrief screen (T3-06)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Update `game/i18n/strings.csv` with debrief translation keys: root causes (`ROOT_NIGHT_ENERGY`, `ROOT_SHIELD`, `ROOT_REPAIR`, `ROOT_SUPPLY`, `ROOT_SUCCESS_*`), cause chain event texts (`CHAIN_*`), storm disclosure (`DEBRIEF_STORM_CHANCE`), and title button (`DEBRIEF_TITLE_BTN`).
2. Redesign `game/ui/DebriefScreen.tscn` to include outcome title, days label, 0-3 stars, root cause callout panel, cause chain timeline container, forced storm note with SourceTag, NASA fact card with source, seed label, and 3 buttons (Retry, Change Cargo, Title; >=64px height) inside a responsive scrollable layout.
3. Enhance `game/ui/debrief_screen.gd` to populate all fields, format cause chain timeline with icons and `tr()` keys, format root cause with values, show fact & source from `facts.json`, show forced storm chance (`SPE_CHANCE_STRONG_MISSION`), and emit `title_pressed`.
4. Connect `title_pressed` in `game/scenes/main.gd` to return to `State.TITLE`.
5. Verify via `tools\test.ps1`, `tools\scenarios.ps1`, Godot headless import/run, and manual scenario inspection (S01, S05, S06, S07).

## Handoff

- **What works**:
  - `DebriefScreen.tscn` cleanly renders outcome title, 0–3 stars, days survived/reached, root cause analysis with computed values (`ROOT_NIGHT_ENERGY`, `ROOT_SHIELD`, `ROOT_REPAIR`, `ROOT_SUPPLY`, `ROOT_SUCCESS`), cause chain timeline with icons, forced storm disclosure (`SPE_CHANCE_STRONG_MISSION` with `SourceTag`), relevant NASA educational fact from `facts.json` with source attribution, mission seed, and three 64px-tall action buttons (Retry, Change Cargo, Title Screen).
  - All button flows hooked up in `main.gd`: Retry starts a fresh mission with the same cargo, Change Cargo returns to Pack screen preserving the cargo setup, and Title Screen returns to Title.
  - Localization strings and placeholders added to `strings.csv` with `bn` column left for the team.
  - Headless unit tests (109 passed), balance scenarios (9/9 passed), and web export all pass.
- **What to test by hand**:
  - Play or trigger a mission ending (evacuation or survived) and review the debrief screen formatting on phone / desktop.
  - Test the three buttons: Retry Mission, Change Cargo, and Title Screen.
  - Tap the ⓘ SourceTag next to the storm chance line to view the popover.
- **Known issues**:
  - None.
- **Ideas for later**:
  - Add audio stinger / sound effects for 0-star evacuation vs 3-star mission victory when audio ticket (T4-03) is run.
