# T3-03 — Pack screen

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P3 | T3-02 | L | Agent | i18n-bangla, nasa-data |

## Paste-ready prompt

```text
Run ticket T3-03 (Pack screen). Ticket file: agent-kit/tickets/T3-03-pack-screen.md
Goal: The first big decision: pack the lander within the cargo limit and see the warnings before launch.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

The first big decision: pack the lander within the cargo limit and see the warnings before launch.

## Read first

- agent-kit/ART_DIRECTION.md §8
- agent-kit/ARCHITECTURE.md (UI, Main flow)
- agent-kit/GAME_RULES.md §11
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/i18n-bangla/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`
- agent-kit/GAME_RULES.md §2

## Tasks

1. `ui/PackScreen.tscn`: one card per item (icon, name, unit mass, +/− buttons, count; greenhouse uses size options); cargo bar total / limit with source tag on the limit.
2. Warnings panel from `SimCargo` warnings (food days, water days, night energy have/need). Each warning with a source tag.
3. 3D preview: the lander (`lander_B`) with crates appearing as mass goes up (simple: scale a crate stack).
4. Launch disabled when cargo is invalid; button explains why.
5. Start values: an empty lander (the player must think). Keep the last cargo when coming back from the debrief.

## Done when

- [ ] S08 cargo cannot launch; base cargo can.
- [ ] Warnings change live; numbers match `SimCargo`.

## Verify

- MCP run + debug output.
- `tools\test.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add pack screen (T3-03)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Update `game/i18n/strings.csv` with pack items, units, warnings, and launch status translation keys.
2. Build `game/ui/PackItemCard.tscn` & `pack_item_card.gd` with touch-friendly 64px +/- controls, icons, mass display, and greenhouse size cycle options.
3. Build `game/ui/PackScreen.tscn` & `pack_screen.gd` featuring 8 item cards, cargo bar with `CARGO_LIMIT_KG` SourceTag, warnings panel with 3 live `SimCargo` warnings and SourceTags, and a 3D SubViewport showing `lander_B` with crate stack scaling with mass.
4. Support last-cargo persistence across debriefs via `GameState.last_cargo` and wire `PackScreen` into `scenes/Main.tscn` and `main.gd`.
5. Write `game/tests/test_pack_screen.gd` and verify with `tools\test.ps1` (headless tests) and scenario checks.

## Handoff

### What works
- Complete `PackScreen` UI with 8 cargo item cards (`solar`, `battery`, `reactor`, `greenhouse`, `o2`, `water`, `food`, `shield`).
- Touch-friendly 64 px minimum touch targets for +/- buttons; greenhouse cycles through valid size options `[0, 5, 10, 20]` m².
- Cargo bar tracking total mass vs `CARGO_LIMIT_KG` (12,000 kg) with attached `SourceTag`.
- Live warnings panel displaying food days, water days, and night energy have/need from `SimCargo.get_warnings()` with SourceTags (`FOOD_PACKED_KG_PERSON_DAY`, `WATER_RECOVERY_FULL`, `NIGHT_HOURS`).
- 3D preview featuring KayKit `lander_B` model with crate stack (`cargo_A_packed`) that smoothly scales with cargo mass.
- Launch button disabled with overweight message when cargo exceeds limits (S08 blocked); enabled for valid configurations.
- First session starts with empty lander; restores `GameState.last_cargo` on retries from debrief.
- Headless test suite (98 tests passed) and balance scenarios (9/9 passed). Web export tested and verified.

### What to test by hand
- Start the game from `TitleScreen`, tap Start: verifies transition from Moon globe dive into `PackScreen`.
- Tap +/- buttons: verify item counts, cargo bar, live warnings, and crate stack scaling.
- Verify Launch button is disabled when mass > 12,000 kg and enabled when valid.
- Tap (i) SourceTags to inspect source popovers for Cargo Limit and warnings.

### Known issues
- None.

### Ideas for later
- Wire UI click sounds in P4 (T4-03) when audio system is implemented.
