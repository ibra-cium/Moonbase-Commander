# M-02 — Named crew, speech bubbles and less tapping

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| PM | M-01 | S | Agent | godot-3d-scenes, i18n-bangla |

## Paste-ready prompt

```text
Run ticket M-02 (Named crew, speech bubbles and less tapping). Ticket file: agent-kit/tickets/M-02-named-crew.md
Goal: The four astronauts have names and say one short line a day about what is happening. Jobs stay from yesterday, and science gear switches on by itself when someone does Science.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Kids care about characters, not about "Crew 2". Each astronaut gets a name and says one short line a day about what is happening, so the player hears the danger before reading a gauge. The player also stops re-tapping four jobs every day.

## Read first

- `agent-kit/CONTEXT.md` (hard rules 4, 5, 7)
- `agent-kit/ART_DIRECTION.md`
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/i18n-bangla/SKILL.md`

## Tasks

1. **Names.** Crew index → name key: 0 `CREW_NAME_0` Rafi (orange suit), 1 `CREW_NAME_1` Mira (purple), 2 `CREW_NAME_2` Leo (pink), 3 `CREW_NAME_3` Nadia (brown). They are fictional adult astronauts: no photos, no real people. `ui/crew_card.gd` shows the name instead of `CREW_MEMBER`, in the job picker title too. Add a small suit-colour dot or helmet icon next to the name, tinted with the astronaut's suit colour from `world/astronaut.gd` `SUIT_COLORS`.
2. **Name tags in 3D.** Each astronaut gets a small billboard `Label3D` with its name above the helmet (no depth test, readable on a phone, faded at long camera distance). It hides during the landing and ending cinematics.
3. **Speech bubbles.** Create `world/speech_bubble.gd`: a billboard `Label3D` with a dark rounded `Sprite3D` backing (or a 2D `PanelContainer` placed with `Camera3D.unproject_position`, whichever reads better on the phone). It pops in, stays `BUBBLE_SHOW_SEC` (3.0), and fades out. At most **one bubble per day**, shown after `day_resolved`. Pick the line by this priority (first match wins) and put it over the astronaut that fits (the sick one, the repairer, otherwise a random healthy one from the mission's seed):

   | Priority | When (from the day report / events) | Key |
   | --- | --- | --- |
   | 1 | storm day | `CREW_SAY_STORM` |
   | 2 | someone became sick today | `CREW_SAY_SICK` |
   | 3 | recycler broke or a panel broke today | `CREW_SAY_BROKEN` |
   | 4 | CO2 above `CO2_HEALTHY_MAX_MMHG` | `CREW_SAY_STUFFY` |
   | 5 | food lasts fewer than `SUPPLY_WARNING_DAYS` days | `CREW_SAY_FOOD_LOW` |
   | 6 | first day after sunset | `CREW_SAY_DARK` |
   | 7 | something was repaired today | `CREW_SAY_FIXED` |
   | 8 | science points went up today | `CREW_SAY_SCIENCE` |
   | 9 | anything else | `CREW_SAY_GOOD` |

   On Day 1, after landing, show `CREW_SAY_HELLO`. The bubble never covers the toast or a popup: if a popup or tutorial is open, wait until it closes.
4. **Jobs stay from yesterday.** In `scenes/main.gd` `_state_plan_day()`, stop calling `day_hud.reset_crew_to_rest()` every day. Keep each crew member's job from the day before. Still force REST when they are sick or on the storm day (`crew_card.update_availability` already does this), and if yesterday's job is no longer possible (nothing to repair, greenhouse dead) fall back to REST. The 3D astronauts walk back to their kept job spot at the start of the day.
5. **Science gear switches itself.** The plan's `science_gear_on` is true exactly when at least one crew member has the SCIENCE job. Hide the Science Gear button from the HUD (`DayHud.tscn` → `RightControls/VBox/ScienceSwitch`). Keep `science_gear_on` in `SimPlan` so the sim and the scenarios are unchanged. The Greenhouse switch stays.
6. **Tests.** Add to `tests/test_crew.gd` or a new `tests/test_crew_voice.gd`: the line priority, one bubble per day, jobs kept between days, sick crew forced to REST, `science_gear_on` follows the SCIENCE job.

## New text keys (EN; leave `bn` empty for Samia)

| Key | EN |
| --- | --- |
| `CREW_NAME_0` | Rafi |
| `CREW_NAME_1` | Mira |
| `CREW_NAME_2` | Leo |
| `CREW_NAME_3` | Nadia |
| `CREW_SAY_HELLO` | Ready to work, Commander! |
| `CREW_SAY_STORM` | Into the shelter, quick! |
| `CREW_SAY_SICK` | I feel dizzy. I need rest. |
| `CREW_SAY_BROKEN` | Something broke! Who can fix it? |
| `CREW_SAY_STUFFY` | The air feels stuffy... |
| `CREW_SAY_FOOD_LOW` | We are running out of food! |
| `CREW_SAY_DARK` | It's so dark. Is the battery OK? |
| `CREW_SAY_FIXED` | Fixed it! |
| `CREW_SAY_SCIENCE` | We found something cool in the rocks! |
| `CREW_SAY_GOOD` | All good out here! |

## Done when

- [x] Crew cards, picker titles and 3D name tags show the four names.
- [x] One speech bubble per day, the right line for the situation, never on top of a popup.
- [x] Jobs stay from day to day; sick and storm days still force REST.
- [x] Science gear button gone; Science job earns points with no extra tap.
- [x] S01–S09 and the M-01 mission scenarios still pass.

## Verify

- `tools\test.ps1`, `tools\scenarios.ps1`
- MCP run of M2 (recycler bubble) and M4 up to Day 16 (dark bubble).
- `tools\export_web.ps1`, then `/phone-test`: bubbles readable on the phone.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add named crew and speech bubbles (M-02)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

- **Strings (`game/i18n/strings.csv`):** Add the 14 EN keys (`CREW_NAME_0..3`, `CREW_SAY_*`) with `bn` empty and re-import.
- **Crew names & UI (`ui/crew_card.gd`, `ui/CrewCard.tscn`, `ui/DayHud.tscn`, `ui/day_hud.gd`):** Replace `CREW_MEMBER` with `CREW_NAME_%d` (tinted with `SUIT_COLORS` in both card and picker header), hide `RightControls/VBox/ScienceSwitch`, and derive `plan.science_gear_on` from whether any crew member holds `JOB_SCIENCE`.
- **3D name tags (`world/Astronaut.tscn`, `world/astronaut.gd`, `world/crew.gd`):** Add billboard `Label3D` `NameTag` (`no_depth_test = true`, camera distance fade, hidden during landing/ending cinematics) and add `apply_kept_jobs` so crew hop back to yesterday's jobs.
- **Speech bubbles (`world/speech_bubble.gd`, `world/SpeechBubble.tscn`, `scenes/main.gd`, `scenes/Main.tscn`):** Implement 2D `PanelContainer` bubble tracked via `Camera3D.unproject_position` (`BUBBLE_SHOW_SEC = 3.0`), pure priority voice/astronaut selector (`1..9` + Day 1 hello, 1/day, toast/popup/tutorial deferral), and keep jobs across days in `_state_plan_day()`.
- **Tests (`tests/test_crew_voice.gd`, `tests/test_day_loop.gd`):** Cover line priority, one bubble per day, kept jobs, sick/storm/impossible `REST` enforcement, and auto `science_gear_on`, then verify with `test.ps1`, `scenarios.ps1`, MCP M2/M4 runs, and `export_web.ps1`.

## Handoff

- **Completed:** Implemented named crew (`Rafi`, `Mira`, `Leo`, `Nadia` + `SUIT_COLORS` dots in cards, picker header `PickerSuitBadge`, and billboard 3D `NameTag` `Label3D` with camera distance fade & cinematic hiding), `SpeechBubble` 2D tracked voice bubbles (1/day, strict priority `1..9` + Day 1 `CREW_SAY_HELLO`, 3.0s hold, `ToastPanel`/popup/tutorial/picker deferral), kept jobs across days (`Crew.apply_kept_jobs` + sick/storm/impossible `REST` guard), and automatic `science_gear_on` driven by `JOB_SCIENCE` with `ScienceSwitch` hidden.
- **Test update note:** Updated existing test `test_day_loop.gd::test_day_hud_gauges_and_switches` to assert `ScienceSwitch` is hidden and `science_gear_on` follows `JOB_SCIENCE` instead of a manual switch press, and added `tests/test_crew_voice.gd`.
- **Checks after final edit:** `--headless --path game --import` PASS, `tools\test.ps1` PASS (`140 / 140`, `0` failed), `tools\scenarios.ps1` PASS (`15 / 15`), Godot visual run captures PASS (Day 1 hello + `NameTag`s, M2 Day 4 recycler bubble, M4 Day 16 dark bubble), Godot MCP `run_project` PASS (`0` errors, `0` warnings in modified files), and `tools\export_web.ps1` PASS (`build/web/index.html` generated).
- **Phone test next:** Run `/phone-test` to inspect 3D `NameTag` legibility and `SpeechBubble` placement on your phone over Wi-Fi (`CREW_SAY_*` `bn` translations remain empty for Samia in `T5-01`).
