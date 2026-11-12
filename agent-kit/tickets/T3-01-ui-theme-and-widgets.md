# T3-01 — UI theme, widgets and Sources screen

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P3 | T2-06 | M | Agent | i18n-bangla, nasa-data |

## Paste-ready prompt

```text
Run ticket T3-01 (UI theme, widgets and Sources screen). Ticket file: agent-kit/tickets/T3-01-ui-theme-and-widgets.md
Goal: Shared UI building blocks: theme, fonts, icons, gauge, source tag, popup and the Sources screen.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Shared UI building blocks: theme, fonts, icons, gauge, source tag, popup and the Sources screen.

## Read first

- agent-kit/ART_DIRECTION.md §8
- agent-kit/ARCHITECTURE.md (UI, Main flow)
- agent-kit/GAME_RULES.md §11
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/i18n-bangla/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`

## Tasks

1. `ui/Theme.tres`: panel style, buttons (64 px min height), labels; default font Noto Sans with Noto Sans Bengali fallback (FontVariation).
2. Icons are already white (PA-02); tint them with `modulate` in the meaning colours.
3. `ui/Gauge.tscn`: icon, value, unit, thin bar, colour state (normal/warn/critical with pulse), optional `SourceTag`.
4. `ui/SourceTag.tscn`: ⓘ button; popover with label, value + unit, type, source name; extra line "Our choice to make the game playable" for Game setting/assumption.
5. `ui/EventPopup.tscn`: title, two lines max, one or two buttons; returns the choice by signal.
6. `ui/SourcesScreen.tscn`: every ID the game uses, grouped by `system`, with value, type and source name; a short line about simplifications (free buildings, rover-study doses, game assumptions). All text via `tr()`.
7. Add all new keys to `i18n/strings.csv` (en only).

## Done when

- [x] A test scene shows each widget; source tag shows correct data for 3 IDs.
- [x] Sources screen lists all IDs that `test_constants.gd` finds in code.

## Verify

- MCP run of the widget test scene.
- `tools\test.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add UI theme, widgets and sources screen (T3-01)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Build `ui/Theme.tres` with FontVariations for Noto Sans + Noto Sans Bengali fallback, 22 px base text, 64 px buttons, and dark translucent panels (`#141821E0`).
2. Implement `ui/SourceTag.tscn` with info icon, popover display for label, value, unit, type, and source from `Constants.meta()`, plus game-choice note.
3. Implement `ui/Gauge.tscn` with icon, value, unit, bar, meaning colour tint, and warning/critical pulse states.
4. Implement `ui/EventPopup.tscn` with modal backdrop, title, max 2-line message, 1-2 touch buttons (min 64 px), and choice signal.
5. Implement `ui/SourcesScreen.tscn` displaying constants grouped by system, with simplification notes and back navigation.
6. Add translation keys to `i18n/strings.csv`, create `ui/test_ui.tscn` to demonstrate and verify all widgets, and verify with `tools\test.ps1`.

## Handoff

### What works
- `res://ui/Theme.tres` with Noto Sans + Noto Sans Bengali fallback (`res://ui/font_regular.tres`, `res://ui/font_bold.tres`), 22 px default text, dark translucent panels (`#141821E0`), and touch buttons (minimum 64 px height).
- `res://ui/ui_colors.gd`: meaning colors defined per ART_DIRECTION §1.
- `res://ui/SourceTag.tscn`: ⓘ popover displaying constant label, value, unit, type, and source, with game-choice disclaimer when applicable.
- `res://ui/Gauge.tscn`: compact gauge with icon, value, unit, thin progress bar in meaning color, warning color state, and critical red pulse animation.
- `res://ui/EventPopup.tscn`: modal dialog with title, 2-line wrapped text, 64 px touch buttons, and choice signal emission.
- `res://ui/SourcesScreen.tscn`: searchable, system-filtered browser of all 166 constants with values, sources, and simplification notes.
- `res://ui/TestUI.tscn`: gallery displaying all widgets with live states, modal triggers, and source screen navigation.
- All 87 unit tests, 9 balance scenarios, MCP smoke test, and web release export pass with 0 errors.

### What to test by hand
- Open Godot editor or run `res://ui/TestUI.tscn` to test clicking on the 3 SourceTags, opening the EventPopup, and filtering constants on the Sources Screen.

### Ideas for later
- In P3 screens (TitleScreen, PackScreen, DayHud), instantiate `Gauge` and `SourceTag` directly for all resource indicators.
