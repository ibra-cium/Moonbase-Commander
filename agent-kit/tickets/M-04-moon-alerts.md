# M-04 — "The Moon attacks": event alerts with countdown and result

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| PM | M-03 | M | Agent | lighting-and-effects, i18n-bangla |

## Paste-ready prompt

```text
Run ticket M-04 ("The Moon attacks": event alerts with countdown and result). Ticket file: agent-kit/tickets/M-04-moon-alerts.md
Goal: The solar storm, meteoroid, recycler breakdown and sunset each become a short dramatic moment: an alert, the event plays out on the base, then a result card that says whether the base held and what to do next.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

In Clash of Clans the exciting part is watching your defences hold. Here the Moon is the attacker: a solar storm, a meteoroid, a broken machine, the long night. Each one becomes a short moment: an alert, the event plays out on the base (effects already exist from T4-01), then a result card that says whether the base held and what to do next.

**No sim changes.** The storm still has one choice ("Everyone to the shelter"), as decided on 2026-11-09. The drama comes from presentation and from showing the result of what the player packed or built.

## Read first

- `agent-kit/CONTEXT.md` (hard rules 5, 6, 7)
- `agent-kit/GAME_RULES.md` §8, §9.1
- `agent-kit/DECISIONS.md` (storm popup has one button)
- `.agent/skills/lighting-and-effects/SKILL.md`

## Tasks

1. **Alert card.** Extend `ui/event_popup.gd` / `EventPopup.tscn` with `popup_alert(icon: Texture2D, title: String, body: String, tone: String, buttons: Array)`. It shows a big icon, a coloured ribbon (`danger` red `#E04848`, `warn` amber, `safe` green `#44B35A`), a title and **one** body line (two lines total, hard rule 7). It slides in with a short shake for `danger`. Existing `popup_event()` calls keep working.
2. **Storm: countdown, then the attack plays out.**
   - At the start of the storm day: an alert card `ALERT_STORM_TITLE` with a big countdown number that ticks from `SPE_WARNING_TYPICAL_MIN` to 0 over `STORM_COUNTDOWN_SEC` (3.0 s; 1.0 s in fast mode), with the alarm sound. During the countdown the astronauts hop to the shelter (`crew.recall_to_rest(true)`). The shelter door light is on.
   - The button `EVT_CHOICE_SHELTER` appears when the count reaches 0. Pressing it **ends the day automatically**: everyone rests anyway, so there is nothing to plan. The existing storm effect plays during the resolve.
   - After `day_resolved`, if the crew was not evacuated: result card, tone `safe`, `ALERT_STORM_SAFE_TITLE` + `ALERT_STORM_SAFE_BODY` with `{dose}` = `storm_dose_msv` (rounded) and `{limit}` = `RAD_SPE_LIMIT_MSV`. Add a horizontal bar under the text showing dose vs limit, with a source tag on `RAD_SPE_LIMIT_MSV`. If evacuated, skip the card: the ending (T4-02) takes over.
3. **Meteoroid.** When a `METEOROID` event is in the day report: after the resolve effect, card tone `danger`, `ALERT_METEOR_TITLE` + `ALERT_METEOR_BODY`.
4. **Recycler.** When `RECYCLER_BROKE` is in the day report: card tone `danger`, `ALERT_RECYCLER_TITLE` + `ALERT_RECYCLER_BODY`. Set `Settings.hint_broken_shown = true` so the T4-04 hint does not repeat the same message.
5. **Sunset.** Replace the plain sunset popup with a card, tone `warn` if `night_energy_have_kwh() < night_energy_need_kwh()` (from the mission's cargo), else `safe`: `ALERT_NIGHT_TITLE` + `ALERT_NIGHT_BODY` with `{have}` / `{need}` kWh and a bar, source tag `NIGHT_HOURS`. It only happens in missions that reach `SUNSET_DAY`.
6. **No double messages.** When a result card shows for an event, the HUD toast for that same event is skipped (`day_hud.gd` `_generate_and_show_toast`). Cards queue one after another, never on top of each other, and never on top of the tutorial overlay or a speech bubble from M-02 (the bubble waits).
7. **Tests.** Extend `tests/test_event_effects.gd` or add `tests/test_alerts.gd`: the right card for each event, the storm safe card uses the report dose, no card on evacuation, the storm day auto-ends after the shelter button, the toast is skipped when a card is shown.

## New text keys (EN; leave `bn` empty for Samia)

| Key | EN |
| --- | --- |
| `ALERT_STORM_TITLE` | Solar storm coming! |
| `ALERT_STORM_COUNT` | {min} minutes to reach the shelter |
| `ALERT_STORM_SAFE_TITLE` | Shelter held! |
| `ALERT_STORM_SAFE_BODY` | Storm dose {dose} mSv. Safe limit: {limit} mSv. |
| `ALERT_METEOR_TITLE` | Meteoroid strike! |
| `ALERT_METEOR_BODY` | A solar panel broke. Send someone to Repair. |
| `ALERT_RECYCLER_TITLE` | Water recycler broke! |
| `ALERT_RECYCLER_BODY` | Repair it, or the water will run out. |
| `ALERT_NIGHT_TITLE` | The long night begins |
| `ALERT_NIGHT_BODY` | Night energy {have} / {need} kWh. |

`EVT_STORM_TITLE`, `EVT_STORM_WARN`, `EVT_SUNSET_TITLE` and `EVT_SUNSET_MSG` stay in `strings.csv` (other code or the Bangla file may use them) but are no longer shown by the main flow.

## Done when

- [ ] Storm day: countdown, crew runs to the shelter, button, the day auto-ends, the storm plays, then "Shelter held!" with the real dose and limit (or the evacuation ending).
- [ ] Meteoroid, recycler and sunset each show their card once, with the right tone.
- [ ] No card duplicates a toast or a hint; cards never stack.
- [ ] Every card has at most two lines of text.
- [ ] S01–S09 and the mission scenarios still pass (no sim change).

## Verify

- `tools\test.ps1`, `tools\scenarios.ps1`
- MCP run: M3 with shield 10 (safe card), M3 with shield 0 (evacuation, no card), M2 (recycler card), M4 to Day 15 (night card).
- `tools\export_web.ps1`, then `/phone-test`.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add Moon event alerts with countdown and result cards (M-04)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Add the 10 `ALERT_*` English keys (`bn` empty) to `game/i18n/strings.csv` and re-import.
2. Extend `game/ui/EventPopup.tscn` and `event_popup.gd` with `popup_alert(...)`: coloured top ribbon (`danger` `#E04848`, `warn` `#F2C14E`, `safe` `#44B35A`), big icon, 2-line text cap, slide-in + danger shake, optional comparison bar + `SourceTag` (overlay layer > popup), and storm countdown mode (`SPE_WARNING_TYPICAL_MIN` → 0 over `STORM_COUNTDOWN_SEC`) while preserving `popup_event(...)`.
3. Update `game/ui/day_hud.gd` `_generate_and_show_toast` so events that display a result card skip their duplicate HUD toast.
4. Update `game/scenes/main.gd` to run the storm warning countdown (recall crew + shelter light + alarm → reveal `EVT_CHOICE_SHELTER` → auto-end day), queue non-evacuation result cards (`STORM` safe dose, `METEOROID`, `RECYCLER_BROKE` setting `hint_broken_shown = true`), replace `SUNSET` popup on `SUNSET_DAY` with the warn/safe night energy card, and serialize popups/hints/speech bubbles cleanly.
5. Add automated coverage (`tests/test_alerts.gd`), update `tests/test_crew_voice.gd` Day 4 expectation, and verify via `tools\test.ps1`, `tools\scenarios.ps1`, MCP playthroughs, and `tools\export_web.ps1`.

## Handoff

- **What works:**
  - `EventPopup` (`ui/EventPopup.tscn`, `ui/event_popup.gd`) now supports `popup_alert(icon, title, body, tone, buttons, extra)`: coloured top ribbon (`danger` `#E04848`, `warn` `#F2C14E`, `safe` `#44B35A`), big tinted icon, 2-line text cap (`TitleLabel` + `MessageLabel`), slide-in animation (plus X-shake on `danger`), optional comparison bar (`ProgressBar`), and `SourceTag` (overlay layer raised above popup layer), while keeping `popup_event(...)` working cleanly.
  - Storm sequence (`STORM_WARNING`): plays `alarm`, recalls crew into shelter (`crew.recall_to_rest(true)` + shelter door light on), ticks countdown from `SPE_WARNING_TYPICAL_MIN` (`60`) down to `0` over `3.0 s` (`1.0 s` in fast mode), then reveals `EVT_CHOICE_SHELTER`, whose click ends the storm day automatically. After `day_resolved` (if crew did not evacuate), queues `safe` card `ALERT_STORM_SAFE_TITLE` / `ALERT_STORM_SAFE_BODY` with rounded report dose, comparison bar vs `RAD_SPE_LIMIT_MSV`, and `SourceTag`. Evacuation (`shield = 0`) skips the card cleanly.
  - `METEOROID` and `RECYCLER_BROKE` (when not evacuated) queue `danger` alert cards (`ALERT_METEOR_*`, `ALERT_RECYCLER_*`), set `Settings.hint_broken_shown = true` on `RECYCLER_BROKE` to prevent the old broken hint from doubling up, and suppress their duplicate HUD toasts (`day_hud.gd` `_generate_and_show_toast`).
  - `SUNSET` on `SUNSET_DAY` (Day 15, only in missions reaching `SUNSET_DAY`) opens the `warn`/`safe` night energy alert card (`ALERT_NIGHT_TITLE` / `ALERT_NIGHT_BODY`, comparison bar of `night_energy_have_kwh()` vs `night_energy_need_kwh()`, `SourceTag` `NIGHT_HOURS`).
  - Stacked cards display strictly sequentially and never overlap each other, `TutorialOverlay`, or `SpeechBubble`.
  - Verification: `tools\test.ps1` **151 / 151 PASS** (`test_alerts.gd` + updated `test_crew_voice.gd`), `tools\scenarios.ps1` **15 / 15 PASS**, Godot MCP `run_project` + `get_debug_output` **PASS (0 runtime errors)**, `tools\export_web.ps1` **PASS** (`build/web/index.html` generated).
- **What to test by hand:**
  - Run `/phone-test` and play M3 into the solar storm (verify countdown, crew shelter hop, door light, automatic day end, storm effect, and safe dose card with `(i)` source tag) and check layout readability on mobile.
- **Known issues:**
  - None (no changes touched `game/sim/`, and Bangla `bn` translations for the 10 `ALERT_*` keys remain intentionally empty for P5).
