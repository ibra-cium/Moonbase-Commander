# GAME_RULES — the simulation spec

Every name in `CAPS` is an ID in `game/data/constants.json`. Never use the number directly.
A Python reference of these exact rules is in `agent-kit/reference/sim_prototype.py`. The GDScript simulation must give the same results for the scenarios in §10.

## 1. Overview

- `MISSION_CREW` astronauts, `MISSION_DAYS` turns, one turn = one Earth day.
- Landing at sunrise on Day 1. Sun factor per day:
  - `day < SUNSET_DAY` → 1.0
  - `day == SUNSET_DAY` → `SUN_FACTOR_SUNSET_DAY`
  - `day > SUNSET_DAY` → 0.0 (night until the end of the mission)
- The player wins by keeping the crew on the Moon until the end of Day `MISSION_DAYS`. Failure = evacuation, never death.

## 2. Cargo catalog (pack screen)

| Item key | Name on screen | Mass per unit | Max units | What one unit gives |
| --- | --- | --- | --- | --- |
| `solar` | Solar panel | `SOLAR_UNIT_MASS_KG` | `SOLAR_MAX_UNITS` | `SOLAR_UNIT_KW` peak power |
| `battery` | Battery | `BATTERY_UNIT_MASS_KG` | `BATTERY_MAX_UNITS` | `BATTERY_UNIT_KWH` storage |
| `reactor` | Small reactor | `REACTOR_S_MASS_KG` | `REACTOR_MAX_UNITS` | `REACTOR_S_KWE` day and night |
| `greenhouse` | Greenhouse | `area × GREENHOUSE_KG_PER_M2` | one size from `GREENHOUSE_SIZE_OPTIONS_M2` | growing area in m² |
| `o2` | Oxygen tanks | `O2_UNIT_MASS_KG` | `SUPPLY_MAX_UNITS` | `O2_UNIT_KG` oxygen |
| `water` | Water container | `WATER_UNIT_MASS_KG` | `SUPPLY_MAX_UNITS` | `WATER_UNIT_KG` water |
| `food` | Food crate | `FOOD_CRATE_MASS_KG` | `SUPPLY_MAX_UNITS` | `FOOD_CRATE_MASS_KG` kg packed food (= `FOOD_CRATE_DAYS` days for the crew) |
| `shield` | Shield water | `SHIELD_UNIT_KG` | `SUPPLY_MAX_UNITS` | `SHIELD_UNIT_G_CM2` on the storm shelter |

- Always on the base, not counted in cargo (arrived on an earlier lander — a simplification, say so on the Sources screen): habitat, life-support module, storm shelter, rover, drill, lamp posts.
- `total_mass ≤ CARGO_LIMIT_KG` or Launch is disabled.
- The pack screen shows warnings, not blocks, when a supply covers fewer than `MISSION_DAYS` (see §11).

## 3. Starting state (after landing)

| Variable | Start value |
| --- | --- |
| `battery_kwh` | full: `battery × BATTERY_UNIT_KWH` (= capacity) |
| `o2_kg` | `o2 × O2_UNIT_KG` |
| `water_kg` | `water × WATER_UNIT_KG` |
| `food_kg` | `food × FOOD_CRATE_MASS_KG` |
| `co2_mmhg` | `CO2_START_MMHG` |
| `dust` | `DUST_LANDING` |
| `shelter_g_cm2` | `shield × SHIELD_UNIT_G_CM2` |
| `recycler_broken`, `broken_panels` | false, 0 |
| crew ×4 | health OK, `sick_days` 0, `dose_msv` 0, `energy` `CREW_ENERGY_MAX` |
| greenhouse | alive if area > 0, `days_since_farm` 0, `wilt_days` 0, `healthy_days` 0 |
| `science_points`, `ever_sick`, `ever_tired` | 0, false, false |

## 4. Order of one day (`SimMission.step_day(plan)`)

All steps use the state at the **start** of the day. Job effects apply at the **end** of the day, so a repair done today works tomorrow.

1. Start-of-day events (§8): sunset message; storm day → everyone goes to the shelter (all jobs become REST).
2. Jobs: sick crew → REST. Mark which jobs are outside (§6).
3. Power (§4.1).
4. Greenhouse (§7).
5. Life support (§5).
6. Radiation dose (§6.3) and storm dose (§8).
7. Crew sickness, energy and recovery (§6.4, §6.5).
8. End checks (§9.1). If ended, stop here.
9. Job effects (§6.2), dust, `days_since_farm`.
10. End-of-day events: recycler breakdown, meteoroid (§8).
11. `day += 1`. After Day `MISSION_DAYS` → SURVIVED.

### 4.1 Power

Systems in priority order (1 = most important). kW values come from constants.

| # | System key | kW | Requested when |
| --- | --- | --- | --- |
| 1 | `core` | `LOAD_AIR_KW + LOAD_THERMAL_KW + LOAD_WASTE_KW + LOAD_COMMS_KW` | always |
| 2 | `water` | `LOAD_WATER_KW` | recycler not broken |
| 3 | `food` | `LOAD_FOOD_KW` | always |
| 4 | `eva` | `LOAD_EVA_KW` | at least one crew member has an outside job today |
| 5 | `science` | `LOAD_OPS_KW` | `plan.science_gear_on` |
| 6 | `greenhouse` | `GREENHOUSE_W_PER_M2 × area / 1000` | area > 0 and `plan.greenhouse_lights_on` |

`LOAD_GREENHOUSE_KW` is not used. The greenhouse load comes from its area instead (see DECISIONS.md).

```
working_panels = solar - broken_panels
generation_kwh = working_panels × SOLAR_UNIT_KW × 24 × sun_factor × (1 - dust)
               + reactor × REACTOR_S_KWE × 24
supply = generation_kwh + battery_kwh
for each requested system in priority order:
    need = kW × 24
    if nothing shed yet and need ≤ supply: served, supply -= need
    else: shed this and every lower system; the first shed system uses up what is left (supply = 0)
battery_kwh = min(capacity, supply)
```

- If `core` is shed → log `BLACKOUT` (this means the air system is off today). The report also gives `hours_on_battery = supply_before_core / core_kW` for the UI ("battery lasted 19 h").
- If another system is shed → log `POWER_SHED` with the list.

## 5. Life support

```
air_on = core served

CO2:   if air_on: co2 = max(CO2_START_MMHG, co2 - CO2_FALL_PER_DAY_AIR_ON)
       else:      co2 = co2 + CO2_RISE_PER_DAY_AIR_OFF            → log CO2_HIGH when co2 > CO2_HEADACHE_MMHG

Water: drink  = WATER_KG_PERSON_DAY × crew
       plants = GREENHOUSE_WATER_L_M2_DAY × area   (only if greenhouse served; 1 L = 1 kg)
       recycler_on = water served and not recycler_broken
       water_kg -= (drink + plants) × (1 - WATER_RECOVERY_FULL)  if recycler_on
       water_kg -= (drink + plants)                             otherwise

Oxygen: need = O2_KG_PERSON_DAY × crew - greenhouse_o2 (§7)
        oga  = air_on ? min(need, OGA_O2_KG_DAY, water_kg / OGA_WATER_PER_KG_O2) : 0   (never below 0)
        water_kg -= oga × OGA_WATER_PER_KG_O2       (split water is not recovered)
        o2_kg    -= need - oga                       (the rest comes from the tanks)

Food:  eat = FOOD_PACKED_KG_PERSON_DAY × crew
       food_kg -= eat
       if food shed: food_kg -= FOOD_SPOIL_DAYS_IF_OFF × eat   → log FOOD_SPOILED
```

Supply warnings (log only): when a stock will last fewer than `SUPPLY_WARNING_DAYS` days at today's use → `SUPPLY_LOW` (o2 / water / food).

## 6. Crew

### 6.1 Jobs

| Job | Where | Effect (end of day) | Needs |
| --- | --- | --- | --- |
| `REST` | inside | sick crew recover (§6.4) | — |
| `REPAIR` | inside if the recycler is broken (fixes it); else outside (fixes one broken panel) | as stated | something broken; outside → `eva` served |
| `CLEAN` | outside | `dust = 0` | `eva` served |
| `FARM` | inside | `days_since_farm = 0` | greenhouse alive |
| `REGOLITH` | outside | `shelter_g_cm2 += REGOLITH_G_CM2_PER_JOB` | `eva` served |
| `SCIENCE` | outside (drill) | `science_points += 1` | `eva` and `science` served |

- An outside job whose power is shed does nothing; the crew member stays inside (log `JOB_NO_POWER`).
- Sick crew can only `REST`. The UI greys out the other jobs.
- On the storm day all jobs are `REST` in the shelter.

### 6.2 Dust

At the end of the day: `dust += DUST_PER_OUTSIDE_JOB × (outside jobs that worked, not counting CLEAN)`, capped at `DUST_MAX_LOSS`. Then, if a `CLEAN` job worked, `dust = 0`. Log `DUST_HIGH` the first time dust reaches `DUST_MAX_LOSS` (again after each clean).

### 6.3 Daily radiation

Each crew member: `+RAD_SURFACE_MSV_DAY` if their outside job worked today, else `+RAD_HABITAT_MSV_DAY`.

### 6.4 Sickness

- If `co2 > CO2_HEADACHE_MMHG` after §5: every crew member who is not sick becomes sick: `sick_days = SICK_REST_DAYS`, `ever_sick = true`, log `CREW_SICK` (caused by `CO2_HIGH`).
- Otherwise each sick crew member on `REST`: `sick_days -= 1`; at 0 they are well again.

### 6.5 Crew energy

- Every astronaut starts with `CREW_ENERGY_MAX` (3) energy pips.
- `REST` (chosen, forced because sick, or forced on a storm day) refills `energy` to `CREW_ENERGY_MAX`.
- Any other job when `energy > 0` uses 1 pip (`energy -= 1`).
- Any other job when `energy == 0` still executes that day's job (§4 step 9), then makes that astronaut sick at §4 step 7: `sick_days = SICK_REST_DAYS`, `ever_sick = true`, `ever_tired = true`, log `CREW_TIRED` with cause `OVERWORK`.
- A crew member who is already sick at the start of the day is forced to `REST` (refilling `energy`) and is not made sick again; CO2 sickness is unchanged.

## 7. Greenhouse (only if area > 0 and plants alive)

```
healthy = greenhouse served and water_kg > 0 and days_since_farm < FARM_EVERY_DAYS     (start-of-day values)
if healthy:
    wilt_days = 0; healthy_days += 1; greenhouse_o2 = CROP_O2_G_M2_DAY × area / 1000
    if healthy_days % GREENHOUSE_DAYS_PER_POINT == 0: science_points += 1
else:
    greenhouse_o2 = 0; wilt_days += 1
    if wilt_days ≥ 2: plants die (log PLANTS_DIED); they do not come back
end of day: days_since_farm += 1, unless a FARM job worked today (then 0)
```

Harvest needs `LETTUCE_GROW_DAYS` of growth, which is longer than the mission. The game never harvests. The debrief uses this as a lesson (fact F07).

## 8. Events

Scheduled when the mission starts, from `RandomNumberGenerator` with the mission seed. Draw in this exact order so tests stay stable:

1. `storm_day = randi_range(STORM_DAY_MIN, STORM_DAY_MAX)` if `STORM_GUARANTEED == 1`
2. `recycler_day = randi_range(RECYCLER_BREAK_DAY_MIN, RECYCLER_BREAK_DAY_MAX)`
3. `meteoroid = randf() < METEOROID_CHANCE`; if true, `meteoroid_day = randi_range(METEOROID_DAY_MIN, METEOROID_DAY_MAX)`

Scenarios and tests can force days (`force: {storm_day, recycler_day, meteoroid_day}`; 0 or 99 = never).

| Event | When | Effect |
| --- | --- | --- |
| `SUNSET` | start of `SUNSET_DAY` | Message, sun factor drops (§1). World plays the sunset. |
| `STORM_WARNING` | start of `storm_day` | `day_started` sends a popup: "Solar storm in about `SPE_WARNING_TYPICAL_MIN` minutes. Everyone to the shelter!" One button. All jobs become REST. |
| `STORM` | §4 step 6 on `storm_day` | Every crew member gets `storm_dose(shelter_g_cm2)` on top of the daily dose. If `storm_dose > RAD_SPE_LIMIT_MSV` → evacuation `EVAC_RADIATION`. |
| `RECYCLER_BROKE` | end of `recycler_day` | `recycler_broken = true` until a REPAIR job |
| `METEOROID` | end of `meteoroid_day` | If a working panel exists: `broken_panels += 1` |
| `SUPPLY_LOW` | any day | Warning only |

```
storm_dose(g):   table x = SPE_SHIELD_TABLE_G_CM2            = [0, 5, 10, 15]
                 table y = [SPE_DOSE_HABITAT_NO_EXTRA_MSV, SPE_DOSE_SHIELD_5, SPE_DOSE_SHIELD_10, SPE_DOSE_SHIELD_15]
                 g ≥ last x → last y; else linear interpolation between the two nearest points
```

Simplification to show on the Sources screen: the 5/10/15 g/cm² doses come from a pressurized-rover study and the 0 g/cm² dose from a habitat study (same NASA talk, same storm).

## 9. End, stars, debrief

### 9.1 End checks (in this order)

| Check | Outcome code |
| --- | --- |
| storm dose > `RAD_SPE_LIMIT_MSV` | `EVAC_RADIATION` |
| `co2 ≥ CO2_EVAC_MMHG` | `EVAC_CO2` |
| `o2_kg < 0` | `EVAC_O2` |
| `water_kg < 0` | `EVAC_WATER` |
| `food_kg < 0` | `EVAC_FOOD` |
| end of Day `MISSION_DAYS` | `SURVIVED` |

### 9.2 Stars

```
if SURVIVED:  stars = 1
              + 1 if not ever_sick
              + 1 if not ever_sick and science_points ≥ SCIENCE_GOAL_POINTS
else: stars = 0
```

### 9.3 Cause chain

Every log entry has `id`, `day`, `code`, `values`, `caused_by` (id of an earlier entry or -1). Links:

| Entry | `caused_by` |
| --- | --- |
| `BLACKOUT` at night | the `SUNSET` entry |
| `BLACKOUT` by day | latest `METEOROID` or `DUST_HIGH` entry if any, else -1 |
| `CO2_HIGH` | latest `BLACKOUT` |
| `CREW_SICK` | latest `CO2_HIGH` |
| `CREW_TIRED` | -1 (`values.cause = "OVERWORK"`) |
| `EVAC_CO2`, `EVAC_O2` | latest `CO2_HIGH` / `BLACKOUT` |
| `EVAC_WATER` | latest `RECYCLER_BROKE` if still broken, else latest `POWER_SHED` of water, else -1 |
| `EVAC_FOOD` | latest `FOOD_SPOILED`, else -1 |
| `EVAC_RADIATION` | the `STORM_WARNING` entry |

The debrief walks back from the final entry (max 5 steps) and shows the chain oldest first:
`Day 15: sunset → Day 16: battery empty, air system off → Day 17: CO2 too high, crew sick → Day 18: crew evacuated`.

### 9.4 Root cause (first rule that matches)

| Rule | Code | Text (values filled in) |
| --- | --- | --- |
| Evacuated after a night `BLACKOUT` and `reactor × REACTOR_S_KWE < essential_kW` (core + water + food) | `ROOT_NIGHT_ENERGY` | "Your night energy: {have} kWh. The base needed {need} kWh to get through the night." `need = essential_kW × NIGHT_HOURS`, `have = capacity + reactor × REACTOR_S_KWE × NIGHT_HOURS` |
| `EVAC_RADIATION` | `ROOT_SHIELD` | "Your shelter had {g} g/cm². About {g_needed} g/cm² keeps the storm dose under {limit} mSv." `g_needed` = smallest g with `storm_dose(g) ≤ RAD_SPE_LIMIT_MSV` (invert the interpolation), 1 decimal |
| `EVAC_WATER` and recycler still broken | `ROOT_REPAIR` | "The water recycler broke on Day {d} and was never repaired." |
| Any other `EVAC_*` | `ROOT_SUPPLY` | "You packed {packed} kg of {item}. The crew used {used} kg." |
| `SURVIVED` | `ROOT_SUCCESS` | Tells which star is missing and why (CO2 sickness, overwork sickness, or science below goal) |

### 9.5 Fact

Pick one fact from `game/data/facts.json` whose `tags` match the root cause: night → `night`, radiation → `storm`, water → `water`, oxygen/CO2 → `oxygen`, success → any fact (seeded). Show the fact text in the current language and its source name.

## 10. Scenarios (the balance tests)

Base cargo for all unless changed: `solar 20, battery 4, reactor 2, greenhouse 0, o2 2, water 4, food 5, shield 10`.

Plan rules:

- `NOFIX`: everyone REST every day.
- `REST`: crew 0 REPAIR when something is broken, everyone else REST. Lights off, science gear off.
- `SMART`: crew 0 REPAIR if broken, else CLEAN if dust > 0.2, else REST · crew 1 REGOLITH until shelter ≥ 15 g/cm², then SCIENCE by day, REST at night · crew 2 SCIENCE by day, REST at night · crew 3 FARM if the greenhouse is alive, else SCIENCE by day · rotate 1 `REST` day every 4 days (`(day + i) % 4 == 0`, except crew 0 when repairing) · greenhouse lights always on · science gear on by day only. ("By day" = `day < SUNSET_DAY`.)
- `ALLWORK`: everyone `SCIENCE` every day, except crew 0 `REPAIR` when something is broken · science gear on, greenhouse lights off.

| ID | Changes from base | Rule | Forced days | Expected |
| --- | --- | --- | --- | --- |
| S01_solar_only | battery 10, reactor 0 | REST | storm 10 | `EVAC_CO2` on Day 18, root `ROOT_NIGHT_ENERGY` |
| S02_two_reactors | — | REST | storm 10 | `SURVIVED`, 2 stars |
| S03_one_reactor | reactor 1 | REST | storm 10 | `SURVIVED`, 2 stars |
| S04_max_batteries | battery 60, solar 30, reactor 0 | REST | storm 10 | `EVAC_CO2` on Day 21, root `ROOT_NIGHT_ENERGY` |
| S05_no_shield | shield 0 | REST | storm 12 | `EVAC_RADIATION` on Day 12, root `ROOT_SHIELD`, storm dose 398 |
| S06_recycler_not_fixed | — | NOFIX | storm 10, recycler 12 | `EVAC_WATER` on Day 20, root `ROOT_REPAIR` |
| S07_three_stars | solar 24, battery 6, greenhouse 10 | SMART | storm 12, recycler 14, meteoroid 20 | `SURVIVED`, 3 stars |
| S08_overweight | solar 40, battery 60, reactor 3, greenhouse 20, o2 20, water 20, food 20, shield 20 | — | — | cargo invalid (mass ≈ 15,641 kg) |
| S09_recycler_fixed | — | REST | storm 10, recycler 12 | `SURVIVED`, 2 stars |
| S10_overwork | — | ALLWORK | storm 10 | `SURVIVED`, Day 30, 1 star (`ever_tired` = true) |

These results come from `reference/sim_prototype.py` with the constants as shipped. If a balance ticket changes a *Game setting* or *Game assumption*, re-run the prototype and update this table in the same ticket. Never change a *NASA value* to fix balance.

## 11. What the UI shows (and where the number comes from)

| UI element | Value | Source tag ID |
| --- | --- | --- |
| Cargo bar | total mass / `CARGO_LIMIT_KG` | `CARGO_LIMIT_KG` |
| Pack warnings | "Food for {n} days", "Water for about {n} days with the recycler", "Night energy {have} / {need} kWh" | `FOOD_PACKED_KG_PERSON_DAY`, `WATER_RECOVERY_FULL`, `NIGHT_HOURS` |
| Power gauge | generation today (kWh), battery % | `SOLAR_UNIT_KW`, `REACTOR_S_KWE`, `BATTERY_UNIT_KWH` |
| O2 gauge | tank kg + "generator on/off" | `O2_KG_PERSON_DAY` |
| CO2 gauge | mmHg; green ≤ `CO2_HEALTHY_MAX_MMHG`, yellow ≤ `CO2_LIMIT_MMHG`, red above | `CO2_LIMIT_MMHG` |
| Water gauge | kg, recycler state | `WATER_KG_PERSON_DAY` |
| Food gauge | days left | `FOOD_PACKED_KG_PERSON_DAY` |
| Radiation | highest crew dose, mSv | `RAD_HABITAT_MSV_DAY` |
| Shelter | g/cm² | `SHIELD_GOAL_G_CM2` |
| Day/sun | day N / 30, sun or night | `LUNAR_DAY_EARTH_DAYS` |
