# M-07 — Gauges a kid can read and act on

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| PM | M-09 | M | Agent + Developer | sim-testing, web-export-mobile, i18n-bangla |

## Paste-ready prompt

```text
Run ticket M-07 (Gauges a kid can read and act on). Ticket file: agent-kit/tickets/M-07-kid-gauges.md
Goal: Replace kg, mmHg, mSv and g/cm² on the HUD with things a 7-13 year old understands: a phone-style battery, an air face, "days left" for water and food, and storm-safety shields. Tapping a gauge tells the player what to do and points at the building. A "Science numbers" switch brings back the real units for older kids and judges.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Why

The HUD shows 7 gauges in kg, mmHg, mSv and g/cm². A 7-13 year old cannot read those, so they cannot decide anything from them. Kids already understand three things: a **phone battery**, **"how many days is left"**, and **a face that looks OK or sick**. Every gauge should answer two questions: *Am I OK?* and *What do I do?*

The real numbers do not disappear. They stay one tap away (source tag ⓘ) and come back with a **Science numbers** switch, for older kids, teachers and judges.

## Read first

- `agent-kit/CONTEXT.md` (hard rules 3, 5, 7)
- `agent-kit/ART_DIRECTION.md` (colours, icons)
- `agent-kit/GAME_RULES.md` §5, §8
- `.agent/skills/web-export-mobile/SKILL.md`
- The M-05 handoff (building markers, selection)

## The five kid gauges (replace the seven)

"Days to go" = mission days left (`MISSION_DAYS − day`). Colours: **green** = enough until the mission ends, **amber** = not enough to the end but at least `SUPPLY_WARNING_DAYS`, **red** = less than `SUPPLY_WARNING_DAYS`.

| Gauge | Icon | Big text | Small word / extra | Colour rule | Source tag |
| --- | --- | --- | --- | --- | --- |
| **Battery** | `bolt.svg` drawn as a phone battery outline | `{pct}%` | arrow ▲ `KID_CHARGING` when the battery went up or is full in sunlight, ▼ `KID_DRAINING` when it went down | green ≥ 50 %, amber ≥ 30 % (same as `BATTERY_LOW_HINT_PERCENT` in `main.gd`), red below; red pulse at 0 | `BATTERY_UNIT_KWH` |
| **Air** | `air.svg` + a face (😀 / 😐 / 😵 drawn as three simple shapes, not emoji fonts) | `AIR_GOOD` / `AIR_STUFFY` / `AIR_DANGER` | CO2 band (existing M-03 rule); also danger when the air machine is off and `o2_days_left` < `SUPPLY_WARNING_DAYS` | good = green, stuffy = amber, danger = red | `CO2_LIMIT_MMHG` |
| **Water** | `water_drop.svg` | `KID_DAYS_LEFT` ("6 days left") | `KID_ENOUGH` ✓ when days left ≥ days to go; `KID_RECYCLER_BROKEN` when broken | rule above | `WATER_KG_PERSON_DAY` |
| **Food** | `restaurant.svg` | `KID_DAYS_LEFT` | `KID_ENOUGH` ✓ when enough | rule above | `FOOD_PACKED_KG_PERSON_DAY` |
| **Storm safety** | `shield.svg` ×3 (pips) | `KID_STORM_SAFE` ✓ / `KID_STORM_NOT_SAFE` ✗ | pips from the storm dose *if a storm hit today*: 0 pips above `RAD_SPE_LIMIT_MSV`, 1 pip ≤ limit, 2 pips ≤ 50 % of limit, 3 pips ≤ 25 % of limit | 0 pips red, 1 amber, 2–3 green | `RAD_SPE_LIMIT_MSV` |

With today's numbers that gives: no shield = 0 pips (398 mSv), 5 g/cm² = 1 pip, 10 g/cm² = 2 pips, 15 g/cm² = 3 pips. The daily radiation gauge moves to Science numbers view only.

## Tasks

1. **Report fields (sim, pure, no rule change).** Add to `SimDayReport` (and `to_dict()`): `o2_days_left`, `water_days_left`, `food_days_left` (use the existing `sim_life.gd` `get_o2_tank_days_left`, `get_water_days_left` with the recycler's real state, `get_food_days_left`), `days_to_go`, and `storm_dose_if_now_msv` (the same shelter → dose interpolation the storm uses in §8, for the current `shelter_g_cm2`). Fill them in `sim_mission.gd` when building the report. Scenario results must not change.
2. **Gauge widget.** Extend `ui/gauge.gd` (or add `ui/kid_gauge.gd`) with: big text, small status word, optional pips (0–3), optional face, optional arrow. Keep `set_state()`, the pulse and the source tag. One gauge must be readable at 390 px phone width; the five gauges fit in the left column without scrolling.
3. **HUD.** In `day_hud.gd` `setup_mission()` and `update_from_report()`, drive the five kid gauges from the report fields above (no game maths in the UI except comparing with the previous report for the battery arrow). Rename status labels: `HUD_OGA_ON/OFF` → `KID_AIR_MACHINE_ON/OFF`, `HUD_RECYCLER_OK/BROKEN` → `KID_RECYCLER_OK` / `KID_RECYCLER_BROKEN`. Toasts that print mmHg or kWh use kid words unless Science numbers is on.
4. **"What should I do?"** Tapping a gauge (anywhere except its ⓘ) opens a small tip bubble next to it with one line and, when there is something to do, a **Show me** button. Show me selects the matching M-05 building marker (it opens the marker view with that building pulsing), or pulses the greenhouse switch. Rules, first match wins:

   | Gauge | When | Tip | Show me |
   | --- | --- | --- | --- |
   | Water | recycler broken | `TIP_WATER_REPAIR` | Life support marker |
   | Water | amber/red, recycler OK | `TIP_WATER_PACK` | — |
   | Food | amber/red | `TIP_FOOD_PACK` | — |
   | Air | stuffy/danger | `TIP_AIR_POWER` | greenhouse switch |
   | Battery | red, or amber at night | `TIP_BATTERY_NIGHT` | greenhouse switch |
   | Storm safety | 0 pips | `TIP_STORM_DIG` | Dig site marker |
   | any | green / fine | `TIP_ALL_GOOD` | — |

5. **Science numbers switch.** Add `Settings.science_view` (default **off**) and a switch in the HUD menu, `KID_SCIENCE_NUMBERS`. On: the gauges also show the original value and unit (kg, mmHg, mSv, g/cm², kWh) in small text under the big text, and the Radiation gauge appears. Off: kid view only. Source tags (ⓘ) work in both views. The judges' demo video should show the switch once.
6. **Crew card dose.** `CREW_DOSE` ("{dose} mSv") only shows in Science numbers view.
7. **Tests.** Add `tests/test_kid_gauges.gd`: days-left colours against days to go, storm pips for 0 / 5 / 10 / 15 g/cm² (0 / 1 / 2 / 3), air face follows the CO2 band and turns danger when the air machine is off and O2 runs low, tip rules and their Show me targets, Science numbers on/off shows/hides units. Scenarios unchanged.
8. **Developer check.** Show the HUD to one child (or anyone new) for 10 seconds and ask: "Is the base OK? What would you do?" Write the answer in the handoff.

## New text keys (EN; Samia fills `bn`)

| Key | EN |
| --- | --- |
| `KID_BATTERY` | Battery |
| `KID_AIR` | Air |
| `KID_STORM_SAFETY` | Storm safety |
| `KID_CHARGING` | Charging |
| `KID_DRAINING` | Draining |
| `KID_DAYS_LEFT` | {n} days left |
| `KID_ENOUGH` | Enough! |
| `KID_STORM_SAFE` | Safe |
| `KID_STORM_NOT_SAFE` | Not safe! |
| `KID_AIR_MACHINE_ON` | Air machine: on |
| `KID_AIR_MACHINE_OFF` | Air machine: OFF! |
| `KID_RECYCLER_OK` | Water recycler: OK |
| `KID_RECYCLER_BROKEN` | Water recycler: broken! |
| `KID_SCIENCE_NUMBERS` | Science numbers |
| `KID_SHOW_ME` | Show me |
| `TIP_WATER_REPAIR` | The water recycler is broken. Send someone to Repair it! |
| `TIP_WATER_PACK` | Water is running low. Pack more water next time. |
| `TIP_FOOD_PACK` | Food is running low. Pack more food next time. |
| `TIP_AIR_POWER` | The air machine needs power. Turn off the greenhouse lights to save power. |
| `TIP_BATTERY_NIGHT` | The night is long! Save power for the air machine. |
| `TIP_STORM_DIG` | Not safe from a solar storm! Send crew to Dig moon soil over the shelter. |
| `TIP_ALL_GOOD` | All good! |

`HUD_WATER`, `HUD_FOOD`, `HUD_OXYGEN`, `HUD_CO2`, `HUD_RADIATION`, `HUD_SHELTER` stay for Science numbers view.

## Done when

- [ ] Five kid gauges with no science units in the default view; each has a colour, a word and a source tag.
- [ ] Water and food show days left and "Enough!" when they last to the end.
- [ ] Storm safety pips match the dose table (0 / 5 / 10 / 15 g/cm² → 0 / 1 / 2 / 3).
- [ ] Tapping a gauge gives one line of advice; Show me points at the right building or switch.
- [ ] Science numbers switch brings back every real unit and the radiation gauge.
- [ ] All scenarios pass unchanged.
- [ ] Developer 10-second test written in the handoff.

## Verify

- `tools\test.ps1`, `tools\scenarios.ps1`
- MCP run: M2 (water tip → Show me → life support), M3 with no shield (storm 0 pips → Show me → dig site), M4 at night (battery tip).
- `tools\export_web.ps1`, then `/phone-test`: five gauges fit and read at phone size, in English and Bangla.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add kid-friendly gauges with tips and science view (M-07)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. **Sim report (`sim_day_report.gd`, `sim_mission.gd`)**: Add `o2_days_left`, `water_days_left`, `food_days_left`, `days_to_go`, and `storm_dose_if_now_msv` to `SimDayReport` (+ `to_dict()`) and populate them in `SimMission._build_report()` using existing `SimLife` / `SimMission` / `SimEvents` methods without changing any rule or scenario outcome.
2. **Settings & i18n (`settings.gd`, `strings.csv`)**: Add `Settings.science_view` (default `false`) + `science_view_changed`, add the 22 EN keys from M-07 to `strings.csv` (empty `bn`, UTF-8 no BOM, LF), and run `--import`.
3. **Gauge visuals (`gauge.gd`, `Gauge.tscn`, custom icon/badge helper)**: Extend `Gauge` cleanly to support kid visuals (phone-battery outline + up/down arrow, custom-drawn 3-state Air face, Water/Food days-left + ok/broken sub-word, 0–3 Storm safety shield pips), small `science_view` unit sub-label, full-gauge tap detection excluding `SourceTag`, and compact sizing so 5 gauges fit at 720p and read cleanly at 390 px.
4. **HUD, Tip Bubble & Science view (`day_hud.gd`, `DayHud.tscn`, `crew_card.gd`)**: Drive the 5 kid gauges (and toggle `RadGauge` + real units + `CrewCard.dose_label` via `Settings.science_view` in pause menu); rename status keys & kid-ify `mmHg`/`kWh` toasts when `science_view` is off; add the tap tip bubble beside the tapped gauge + `Show me` action that pulses `greenhouse_switch` or opens/pulses the M-05 `life_support` / `dig_site` building marker.
5. **Tests & Verification (`test_kid_gauges.gd`, `verify`, `phone-test`)**: Add `test_kid_gauges.gd` covering thresholds, storm pips, air off+low-O2 danger, tips + Show me, and Science view; run `test.ps1`, `scenarios.ps1`, Godot MCP scenarios (M2, M3 no shield, M4 night), web export, and `/phone-test` (including the 10-second child test).

## Handoff

### Completed
- **5 Kid-Friendly Gauges**: Battery phone outline (green/amber/red) with charging/draining arrows; Air machine face (happy/neutral/unhappy) + ON/OFF pill; Storm safety 3 shield pips + Safe/Not Safe pill; Water & Food days-left supply counters with broken recycler alert.
- **Science Numbers Switch**: Pause menu switch toggles between child visual view and real science numbers (with `SourceTag`s, radiation gauge, and crew dose labels).
- **Advice Tip Bubble & Show Me**: Context-aware advice bubble pointing out the immediate bottleneck with pulsing "Show me" highlights pointing to the Life Support building, Dig site, or Greenhouse switch.
- **Science Card Onboarding**: Tutorial and onboarding now explain NASA science cards (`TUT_TASK_SCIENCE_DESC`, `HINT_CARD_TITLE`, `HINT_CARD_BODY`) unlocking real facts stored into the Card Album.
- **Interactive First-Time Card Pickup**: The first card toast appears with a pulsing `▲ Tap to pick up!` pill and holds indefinitely until tapped. Opening `CardView` displays `Saved to your Moon Science Album! Open it anytime from the Mission Map.`
- **Tests & Scenarios**: 191 unit tests passing (`tools\test.ps1`), 16/16 simulation scenarios passing (`tools\scenarios.ps1`), web exported (`tools\export_web.ps1`), and active LAN server serving `http://192.168.0.106:8060/`.

### Verified
- `tools\test.ps1`: PASSED 191, FAILED 0.
- `tools\scenarios.ps1`: 16 / 16 PASSED.
- Live SceneTree verification: M2 broken recycler advice -> Life support pulse; M3 zero-shield storm advice -> Dig site pulse; M4 night advice -> Greenhouse switch pulse; Science view toggle on/off.
- Web export: `build/web/index.html` updated.

### For Developer Review
- Test on phone browser at `http://192.168.0.106:8060/`.
- Verify the 10-second child comprehension check (Task 8).

