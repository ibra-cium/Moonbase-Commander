# M-06 — Crew energy: astronauts need rest

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| PM | T5-02 | M | Agent | sim-testing, nasa-data, i18n-bangla |

## Paste-ready prompt

```text
Run ticket M-06 (Crew energy: astronauts need rest). Ticket file: agent-kit/tickets/M-06-crew-energy.md
Goal: Each astronaut has 3 energy pips. Any job except Rest uses one pip a day; a Rest day refills them. Working with 0 pips makes the astronaut sick from overwork. Rest finally matters.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Why

Playtest on 11 Nov: crew can work every day for the whole mission with no downside. Rest only helps sick crew recover, and the extra radiation from working outside (`RAD_SURFACE_MSV_DAY` vs `RAD_HABITAT_MSV_DAY`, about 41 mSv over 30 days) is far below every limit. So "everyone works every day" is always best and Rest is a dead button.

NASA treats overwork as a real crew risk: the Human Research Program has an evidence report on health and performance problems from sleep loss and work overload (NTRS 20160003864). The game rule below is a simple *Game assumption* inspired by it; the numbers are ours, not NASA's.

## Read first

- `agent-kit/CONTEXT.md` (hard rules 1, 2, 3)
- `agent-kit/GAME_RULES.md` §2, §6, §6.4, §9, §10
- `.agent/skills/sim-testing/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`
- `.agent/skills/i18n-bangla/SKILL.md`

## The rule

- Each crew member has `energy`, starting at `CREW_ENERGY_MAX` (3).
- In step 7 of `step_day` (crew sickness and recovery), after jobs are done:
  - Job is **REST** (chosen, forced because sick, or the storm day) → `energy = CREW_ENERGY_MAX`.
  - Any other job, with `energy == 0` at the start of the day → the job still happens, then the astronaut becomes sick: `sick_days = SICK_REST_DAYS`, `ever_sick = true`, log `CREW_TIRED` with cause `OVERWORK`. Energy stays 0; the forced Rest days refill it.
  - Any other job, with `energy > 0` → `energy -= 1`.
- So an astronaut can work 3 days in a row safely. The 4th work day in a row makes them sick (2 lost days and a lost star).
- CO2 sickness is unchanged. A crew member already sick is not made sick again.

## Tasks

0. **Keep the data files clean.** On 11 Nov `constants.json` was repaired: an edit had added a BOM and garbled 126 text fields (`â€“` instead of `–`). Follow the new rule in `agent-kit/CONVENTIONS.md` → *Text files*: never edit data files with Windows PowerShell `Get-Content`/`Set-Content`/`Out-File`. In `tests/test_constants.gd`, add a check that `constants.json`, `facts.json`, `learning.json`, `missions.json` and `strings.csv` have no BOM and contain no `â€`, `Ã` or `Â`.
1. **Constant.** Add `CREW_ENERGY_MAX` = 3 to `game/data/constants.json`: unit `pips`, system `Crew`, type `Game assumption`, source `Game design choice inspired by NASA HRP Evidence Report: Risk of Performance Decrements and Adverse Health Outcomes Resulting from Sleep Loss, Circadian Desynchronization, and Work Overload (NTRS 20160003864)`, link `https://ntrs.nasa.gov/api/citations/20160003864/downloads/20160003864.pdf`, note `Work 3 days, then rest 1. The NASA report describes the risk; the numbers are a game choice.` Add the same source to `game/data/facts.json` only if you add a fact line (optional, one short line).
2. **Sim.** `sim/sim_crew.gd`: add `energy` to each member (`to_dict()` includes it), reset it in the crew reset, apply the rule in `apply_sickness()` (it already gets `jobs`). Return `newly_tired` (indexes) in its result. `sim/sim_mission.gd` step 7: log `CREW_TIRED` for newly tired crew, with cause `OVERWORK`. Keep the existing `CREW_SICK` log for CO2.
3. **Log and debrief.** In `sim/sim_log.gd` add the `OVERWORK` cause. In `sim/sim_debrief.gd`, when a star is missing because of sickness, say which kind: CO2 (existing text) or overwork (`ROOT_SUCCESS_2_TIRED`, and the 1-star text names both causes when both happened). Track `ever_tired` in the crew (and the report) so the debrief can tell them apart.
4. **Scenario rules.** The `SMART` rule in `tests/run_scenarios.gd` keeps crew working every day, so it now makes them sick. Add rest rotation to SMART: crew member `i` gets REST on days where `(day + i) % 4 == 0`, except crew 0 when something is broken (repairs always win). Update the SMART description in `GAME_RULES.md` §10. `REST` and `NOFIX` rules do not change.
5. **Re-run all scenarios.** Expected: every scenario keeps its outcome and end day. If any star count or end day changes, write the new value in the scenario JSON and in the `GAME_RULES.md` table, and list every change with a one-line reason in the handoff. Add `S10_overwork`: default cargo, a rule `ALLWORK` (everyone SCIENCE every day, crew 0 REPAIR when broken), storm 10 → expected `SURVIVED`, 1 or 2 stars with `ever_tired` true (write the real result).
6. **GAME_RULES.md.** Add §6.5 "Crew energy" with the rule above, add `energy` to the §2 crew state, and add `CREW_TIRED` to the log/cause tables.
7. **UI: crew card.** Under the name, show 3 small pips (filled = energy left), in the crew's suit colour, grey when empty. At 0 pips the card shows `CREW_TIRED_LABEL` in amber. In the job picker and on M-05 building markers, a job for a crew member with 0 pips is **not** greyed out (the player may choose it) but shows `CREW_TIRED_WARN` in red, and picking it plays `ui_error` once as a warning. The Habitat (Rest) marker shows `CREW_REST_REFILL`.
8. **UI: voice and hint.** Add a speech bubble line `CREW_SAY_TIRED` to the M-02 priority list, right after BROKEN, when any healthy crew member has 0 pips. When someone gets sick from overwork, the line is `CREW_SAY_OVERWORKED`. Add a one-time hint (same system as the T4-04 hints, new flag `hint_tired_shown` in `Settings`): the first time any crew member reaches 1 pip, show `HINT_TIRED_TITLE` / `HINT_TIRED_BODY`.
9. **Tests.** Add to `tests/test_crew.gd`: energy goes down on work, refills on rest and storm day, the 4th work day in a row makes the astronaut sick with cause `OVERWORK`, sick crew refill, CO2 sickness unchanged, `ever_tired` set. UI test: pips shown, the tired warning appears but the job can still be chosen.

## New text keys (EN; Samia fills `bn`)

| Key | EN |
| --- | --- |
| `CREW_TIRED_LABEL` | Tired! |
| `CREW_TIRED_WARN` | Too tired! Working today will make {name} sick. |
| `CREW_REST_REFILL` | Rest: full energy |
| `CREW_SAY_TIRED` | I'm so tired... can I rest? |
| `CREW_SAY_OVERWORKED` | I worked too hard. I feel sick. |
| `HINT_TIRED_TITLE` | Astronauts need rest |
| `HINT_TIRED_BODY` | Each job uses one energy dot. One Rest day fills them all again. |
| `LOG_CREW_TIRED` | {name} got sick from working too hard. |
| `ROOT_SUCCESS_2_TIRED` | Mission survived with 2 stars. Missing star: {name} got sick from working too hard. Give everyone a Rest day. |

Also update `ROOT_SUCCESS_1` so it can name overwork as a cause. Keep `{placeholders}` exactly the same in EN and BN.

## Done when

- [ ] Energy pips visible on every crew card; they go down when working and refill after one Rest day.
- [ ] The 4th work day in a row makes that astronaut sick, with the right speech bubble, log line and debrief text.
- [ ] Storm day and sick days refill energy.
- [ ] SMART rule rotates rest; all scenarios pass, and every changed expectation is listed with a reason.
- [ ] `GAME_RULES.md` §6.5 written; the constant has its source and link and shows on the Sources screen.
- [ ] New keys in `strings.csv` (bn may be empty until Samia fills it).
- [ ] The encoding test passes; `constants.json` is still UTF-8 without BOM after your edit.

## Verify

- `tools\test.ps1`, `tools\scenarios.ps1`
- MCP run: M4, keep Leo on Science 4 days in a row → he gets sick on Day 4; rotate the others → no sickness.
- `tools\export_web.ps1`, then `/phone-test`: pips readable on the phone.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add crew energy and overwork sickness (M-06)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Verify UTF-8 without BOM and add an encoding guard in `game/tests/test_constants.gd`, then add `CREW_ENERGY_MAX` (`3`) to `game/data/constants.json` and `data/sources.md`.
2. Add `energy` (`CREW_ENERGY_MAX`), overwork sickness, `ever_tired`, and `CREW_TIRED` / `OVERWORK` logging and debrief handling across `sim_crew.gd`, `sim_mission.gd`, `sim_day_report.gd`, `sim_log.gd`, and `sim_debrief.gd`.
3. Update `SMART` rotation and add `ALLWORK` / `S10_overwork.json` in `game/tests/run_scenarios.gd`, sync scenario expectations and `agent-kit/GAME_RULES.md`.
4. Add energy pips, tired label, red overwork warnings with `ui_error` chime, `REST` refill text, `SpeechBubble` lines, one-time `"tired"` hint, `strings.csv` EN keys, and debrief formatting; expand `game/tests/test_crew.gd`.
5. Run `tools\test.ps1`, `tools\scenarios.ps1`, Godot MCP playthrough verification, and `tools\export_web.ps1` (plus `/phone-test` / AI record and handoff).

## Handoff

- **Built:** Added `CREW_ENERGY_MAX` (`3` pips) and crew energy tracking across sim (`SimCrew`, `SimMission`, `SimDayReport`, `SimLog`, `SimDebrief`), scenarios (`SMART` rotation + `ALLWORK` / `S10_overwork.json` + `agent-kit/GAME_RULES.md`), UI (`CrewCard` pips + amber `Tired!` badge + picker/marker red `CREW_TIRED_WARN` + `ui_error` chime + `REST` refill hint, `SpeechBubble` tired/overworked lines, one-time `"tired"` tutorial hint, `DebriefScreen` overwork formatting), EN strings (`bn` left empty with verified EN fallback), UTF-8/BOM guard in `test_constants.gd`, and unit/UI/voice tests in `test_crew.gd`.
- **Checks:** `import` PASS · `tools\test.ps1` PASS (`PASSED 170 FAILED 0`) · `tools\scenarios.ps1` PASS (`16/16`) · Godot MCP `run_project` PASS (`0` errors, `0` new warnings) · M4 SceneTree playthrough PASS (`leo_sick=true`, `tired=true`, `sci=4`, `hint=true`, zero overlapping `CrewCard`s) · `tools\export_web.ps1` PASS (`build/web/index.html`).
- **Note for Samia:** 10 M-06 Bangla translation keys in `game/i18n/strings.csv` (`ROOT_SUCCESS_1` and the 9 new `M-06` keys) have empty `bn` cells and fall back to English cleanly.
- **Next:** Developer can optionally run `/phone-test` to inspect the 3 pips and tired warning on a phone before committing.
