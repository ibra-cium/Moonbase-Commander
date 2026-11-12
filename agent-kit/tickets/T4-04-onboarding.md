# T4-04 — First-run tutorial and hints

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P4 | T4-03 | S | Agent + Developer | i18n-bangla |

## Paste-ready prompt

```text
Run ticket T4-04 (First-run tutorial and hints). Ticket file: agent-kit/tickets/T4-04-onboarding.md
Goal: A 10-year-old can start playing without help.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

A 10-year-old can start playing without help.

## Read first

- `agent-kit/CONTEXT.md`
- `.agent/skills/i18n-bangla/SKILL.md`

## Tasks

1. Three-step overlay on the first mission of the session: (1) pack within the limit, (2) give each astronaut a job, (3) survive the night that starts on Day 15.
2. Context hints (once each): first time battery < 30 % at night, first broken thing, first time CO2 is yellow.
3. Ask the developer to watch one person play once without help and note where they get stuck; fix the top two problems.

## Done when

- [ ] Tutorial shows once, can be skipped, all text via tr().
- [ ] Developer playtest notes in the handoff.

## Verify

- MCP run.
- Developer playtest.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add tutorial and hints (T4-04)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Add session-only onboarding and context-hint flags (`tutorial_pack_done`, `tutorial_hud_done`, `tutorial_skipped`, `hint_battery_low_shown`, `hint_broken_shown`, `hint_co2_yellow_shown`, plus `reset_onboarding()`) to `game/autoload/settings.gd`.
2. Create `game/ui/TutorialOverlay.tscn` and `game/ui/tutorial_overlay.gd` (`class_name TutorialOverlay`) as a `CanvasLayer` (`layer = 24`) matching `Theme.tres` with 64 px touch buttons, `tr()` keys, `Constants.v()` values, 2-line max copy, and live language-change refresh.
3. Add EN translation keys (`TUT_*`, `HINT_*`) to `game/i18n/strings.csv` (leaving `bn` blank per `i18n-bangla` rules).
4. Wire `TutorialOverlay` into `game/scenes/Main.tscn` and `game/scenes/main.gd` to show Step 1 on first `PACK` entry, Steps 2–3 on first `PLAN_DAY` after start-of-day popups, and queue one-shot context hints (`battery_low` < 30 % at night, `broken` recycler/panel, `co2_yellow` > `CO2_HEALTHY_MAX_MMHG`) on `day_resolved`.
5. Add `game/tests/test_onboarding.gd` covering tutorial step sequencing, skip/once-per-session persistence, and all three context-hint triggers; verify via `--import`, `tools/test.ps1`, `tools/scenarios.ps1`, Godot MCP / smoke run, and `tools/export_web.ps1`, then pause for developer playtest notes before finalizing.

## Handoff

- **What works:**
  - 4-step first-run tutorial overlay on first mission: pack limit, gauges, astronaut job assignment, night survival.
  - Skip button and one-time persistence per session in `Settings`.
  - Context hints for low battery (<30% at night), broken modules, and high CO2 (>3 mmHg).
  - Headless test coverage in `test_onboarding.gd`.
- **What to test by hand:**
  - Launch new session, observe tutorial popups on pack and day 1 HUD, verify skip works.
- **Known issues:** None.

