# PM — new text keys for Bangla (for Samia)

These keys are added to `game/i18n/strings.csv` by tickets M-01 to M-05 on 11 Nov. The English may still change slightly while the agent builds; the final text is in `strings.csv`. Keep `{placeholders}` exactly as they are. Names (Rafi, Mira, Leo, Nadia) are written in Bangla letters.

| Ticket | Key | English | Bangla |
| --- | --- | --- | --- |
| M-01 | `MAP_TITLE` | Moon Missions | |
| M-01 | `MAP_PLAY` | Play | |
| M-01 | `MAP_LOCKED` | Win the mission before to unlock | |
| M-01 | `MAP_FREE_PLAY` | Free play | |
| M-01 | `MISSION_M1_NAME` | First Landing | |
| M-01 | `MISSION_M1_GOAL` | Pack air, water and food. Stay {days} days. | |
| M-01 | `MISSION_M2_NAME` | Something Broke | |
| M-01 | `MISSION_M2_GOAL` | A machine will break. Fix it fast! | |
| M-01 | `MISSION_M3_NAME` | Solar Storm | |
| M-01 | `MISSION_M3_GOAL` | A solar storm is coming. Build a safe shelter. | |
| M-01 | `MISSION_M4_NAME` | The Long Night | |
| M-01 | `MISSION_M4_GOAL` | Survive {days} days, with 14 dark days. | |
| M-01 | `DEBRIEF_NEXT_MISSION` | Next mission | |
| M-01 | `PACK_LOCKED_ITEM` | Already packed | |
| M-01 | `TUT_STEP3_GOAL` | Your goal: {goal} | |
| M-02 | `CREW_NAME_0` | Rafi | |
| M-02 | `CREW_NAME_1` | Mira | |
| M-02 | `CREW_NAME_2` | Leo | |
| M-02 | `CREW_NAME_3` | Nadia | |
| M-02 | `CREW_SAY_HELLO` | Ready to work, Commander! | |
| M-02 | `CREW_SAY_STORM` | Into the shelter, quick! | |
| M-02 | `CREW_SAY_SICK` | I feel dizzy. I need rest. | |
| M-02 | `CREW_SAY_BROKEN` | Something broke! Who can fix it? | |
| M-02 | `CREW_SAY_STUFFY` | The air feels stuffy... | |
| M-02 | `CREW_SAY_FOOD_LOW` | We are running out of food! | |
| M-02 | `CREW_SAY_DARK` | It's so dark. Is the battery OK? | |
| M-02 | `CREW_SAY_FIXED` | Fixed it! | |
| M-02 | `CREW_SAY_SCIENCE` | We found something cool in the rocks! | |
| M-02 | `CREW_SAY_GOOD` | All good out here! | |
| M-03 | `RES_SCIENCE` | Science | |
| M-03 | `RES_SCIENCE_VALUE` | {n} / {goal} | |
| M-03 | `RES_ENERGY` | Energy today | |
| M-03 | `RES_SHELTER` | Shelter | |
| M-03 | `COLLECT_HINT` | Tap the bubbles! | |
| M-03 | `AIR_GOOD` | Air: good | |
| M-03 | `AIR_STUFFY` | Air: stuffy | |
| M-03 | `AIR_DANGER` | Air: danger! | |
| M-04 | `ALERT_STORM_TITLE` | Solar storm coming! | |
| M-04 | `ALERT_STORM_COUNT` | {min} minutes to reach the shelter | |
| M-04 | `ALERT_STORM_SAFE_TITLE` | Shelter held! | |
| M-04 | `ALERT_STORM_SAFE_BODY` | Storm dose {dose} mSv. Safe limit: {limit} mSv. | |
| M-04 | `ALERT_METEOR_TITLE` | Meteoroid strike! | |
| M-04 | `ALERT_METEOR_BODY` | A solar panel broke. Send someone to Repair. | |
| M-04 | `ALERT_RECYCLER_TITLE` | Water recycler broke! | |
| M-04 | `ALERT_RECYCLER_BODY` | Repair it, or the water will run out. | |
| M-04 | `ALERT_NIGHT_TITLE` | The long night begins | |
| M-04 | `ALERT_NIGHT_BODY` | Night energy {have} / {need} kWh. | |
| M-05 | `ASSIGN_PICK_BUILDING` | Where should {name} work? | |
| M-05 | `ASSIGN_CLEAN` | Clean | |
| M-05 | `ASSIGN_REPAIR` | Repair | |
| M-05 | `TUT_STEP2_BODY` (changed) | Tap an astronaut, then tap a building to give a job. Then press End Day. | |

Also changed in M-01: `HUD_DAY` → `Day {day} / {total}` and `DEBRIEF_DAY_REACHED` → `Completed {days} of {total} days`.

## Added late on 11 Nov (M-06, M-07)

| Ticket | Key | English | Bangla |
| --- | --- | --- | --- |
| M-06 | `CREW_TIRED_LABEL` | Tired! | |
| M-06 | `CREW_TIRED_WARN` | Too tired! Working today will make {name} sick. | |
| M-06 | `CREW_REST_REFILL` | Rest: full energy | |
| M-06 | `CREW_SAY_TIRED` | I'm so tired... can I rest? | |
| M-06 | `CREW_SAY_OVERWORKED` | I worked too hard. I feel sick. | |
| M-06 | `HINT_TIRED_TITLE` | Astronauts need rest | |
| M-06 | `HINT_TIRED_BODY` | Each job uses one energy dot. One Rest day fills them all again. | |
| M-06 | `LOG_CREW_TIRED` | {name} got sick from working too hard. | |
| M-06 | `ROOT_SUCCESS_2_TIRED` | Mission survived with 2 stars. Missing star: {name} got sick from working too hard. Give everyone a Rest day. | |
| M-07 | `KID_BATTERY` | Battery | |
| M-07 | `KID_AIR` | Air | |
| M-07 | `KID_STORM_SAFETY` | Storm safety | |
| M-07 | `KID_CHARGING` | Charging | |
| M-07 | `KID_DRAINING` | Draining | |
| M-07 | `KID_DAYS_LEFT` | {n} days left | |
| M-07 | `KID_ENOUGH` | Enough! | |
| M-07 | `KID_STORM_SAFE` | Safe | |
| M-07 | `KID_STORM_NOT_SAFE` | Not safe! | |
| M-07 | `KID_AIR_MACHINE_ON` | Air machine: on | |
| M-07 | `KID_AIR_MACHINE_OFF` | Air machine: OFF! | |
| M-07 | `KID_RECYCLER_OK` | Water recycler: OK | |
| M-07 | `KID_RECYCLER_BROKEN` | Water recycler: broken! | |
| M-07 | `KID_SCIENCE_NUMBERS` | Science numbers | |
| M-07 | `KID_SHOW_ME` | Show me | |
| M-07 | `TIP_WATER_REPAIR` | The water recycler is broken. Send someone to Repair it! | |
| M-07 | `TIP_WATER_PACK` | Water is running low. Pack more water next time. | |
| M-07 | `TIP_FOOD_PACK` | Food is running low. Pack more food next time. | |
| M-07 | `TIP_AIR_POWER` | The air machine needs power. Turn off the greenhouse lights to save power. | |
| M-07 | `TIP_BATTERY_NIGHT` | The night is long! Save power for the air machine. | |
| M-07 | `TIP_STORM_DIG` | Not safe from a solar storm! Send crew to Dig moon soil over the shelter. | |
| M-07 | `TIP_ALL_GOOD` | All good! | |

Also changed in M-06: `ROOT_SUCCESS_1` gets a version that can name overwork as a cause.

## Added late on 11 Nov (M-08, M-09): learning content

Two places to fill:
- **`game/i18n/strings.csv`**: UI keys (the `bn` column), same as before.
- **`game/data/learning.json`** and **`game/data/facts.json`**: content. Fill each `"bn": ""` next to its `"en"`, the same way you filled the facts on 10 Nov. Keep `{placeholders}` such as `{WATER_KG_PERSON_DAY|1}` exactly as they are.

Empty `bn` shows English, so the game still works while this is in progress.

### Priority 1: needed for the demo video (13 Nov 15:00)

**strings.csv (M-08)**

| Key | English | Bangla |
| --- | --- | --- |
| `BRIEF_NEXT` | Next | |
| `BRIEF_SKIP` | Skip | |
| `BRIEF_GO` | Let's go! | |
| `BRIEF_FACT_BADGE` | Real NASA fact | |
| `GUESS_TITLE` | Guess first! | |
| `GUESS_HINT` | It's OK not to know – you will find out by playing! | |
| `DEBRIEF_NOW_YOU_KNOW` | Now you know! | |
| `DEBRIEF_RIGHT` | Correct! | |
| `DEBRIEF_WRONG` | Not quite – here is the answer: | |
| `DEBRIEF_YOU_GUESSED` | Before the mission you guessed: {answer} | |
| `DEBRIEF_LEARNED` | You learned | |
| `DEBRIEF_NASA_NOW` | NASA is working on this right now | |
| `DEBRIEF_NEW_RANK` | New rank: {rank}! | |
| `DEBRIEF_CERTIFICATE` | Get your certificate | |
| `MAP_RANK` | Rank: {rank} | |
| `MAP_TRAINING_SCORE` | Training score: before {b}/{n} → after {a}/{n} | |
| `MAP_RESULTS` | Results | |
| `RESULTS_TITLE` | Training results | |
| `RESULTS_COL_MISSION` | Mission | |
| `RESULTS_COL_BEFORE` | Before | |
| `RESULTS_COL_AFTER` | After | |
| `RESULTS_COL_STARS` | Stars | |
| `RESULTS_COPY` | Copy | |
| `RESULTS_COPIED` | Copied! | |
| `RESULTS_NOTE` | No names are saved. Results stay on this device. | |
| `CERT_TITLE` | Junior Astronaut Training Complete | |
| `CERT_LEARNED` | You learned: | |
| `CERT_CARDS` | Science Cards: {n} / {total} | |
| `CERT_FOOTER` | Moonbase Commander · Team Space-ArenaX · NASA Space Apps Challenge 2026 · Not an official NASA certificate. | |
| `CERT_BACK` | Back to map | |
| `TITLE_SUBTITLE_TRAINING` | Junior Astronaut Training | |

**learning.json**

| Where | English | Bangla |
| --- | --- | --- |
| mission_control | Mission Control | |
| ranks → CADET | Cadet | |
| ranks → JUNIOR | Junior Astronaut | |
| ranks → SPECIALIST | Mission Specialist | |
| ranks → ENGINEER | Flight Engineer | |
| ranks → COMMANDER | Moonbase Commander | |
| M1 → briefing 1 title | Welcome, Cadet! | |
| M1 → briefing 1 text | Your crew of 4 needs air, water and food every day. Everything must come with you on the lander. | |
| M1 → briefing 2 title | Real NASA fact | |
| M1 → question | How much water does ONE astronaut use in a day? | |
| M1 → option 1 | About 1 glass | |
| M1 → option 2 | About 3 big bottles | |
| M1 → option 3 | About 30 big bottles | |
| M1 → explain | About {WATER_KG_PERSON_DAY|1} kg a day – that's about three 1-litre bottles for each astronaut! | |
| M1 → lesson | Astronauts need air, water and food every single day – and all of it must fit on the lander. | |
| M2 → briefing 1 title | Machines can break | |
| M2 → briefing 1 text | Even on the Moon, machines break. When one does, send an astronaut to Repair it – fast! | |
| M2 → briefing 2 title | Real NASA fact | |
| M2 → question | On the space station, how much of their water do astronauts get back by recycling? | |
| M2 → option 1 | About 10% | |
| M2 → option 2 | About half | |
| M2 → option 3 | About 98% | |
| M2 → explain | About {WATER_RECOVERY_FULL|pct}! Even sweat and urine are cleaned into drinking water. | |
| M2 → lesson | Recycling water saves a lot of weight. Fix broken machines fast! | |
| M3 → briefing 1 title | Storm warning | |
| M3 → briefing 2 title | Build a safe shelter | |
| M3 → briefing 2 text | Before the storm comes, pack shield water or send crew to Dig Moon soil over the shelter. | |
| M3 → question | What is good at blocking dangerous storm radiation? | |
| M3 → option 1 | Bright lights | |
| M3 → option 2 | Cold air | |
| M3 → option 3 | Water and Moon soil | |
| M3 → explain | Water and Moon soil! 15 g/cm² of water cuts the storm dose from {SPE_DOSE_HABITAT_NO_EXTRA_MSV|0} to about {SPE_DOSE_SHIELD_15|0} mSv. | |
| M3 → lesson | Water and Moon soil block radiation. Hide in the shelter when a solar storm comes. | |
| M4 → briefing 1 title | The big test | |
| M4 → briefing 1 text | Your base must survive the long Moon night. Solar panels make no power in the dark. | |
| M4 → briefing 2 title | Real NASA fact | |
| M4 → question | How long is one night on the Moon? | |
| M4 → option 1 | About 12 hours | |
| M4 → option 2 | About 2 weeks | |
| M4 → option 3 | About 1 year | |
| M4 → explain | About 2 weeks! For our base, batteries for the whole night would weigh about {NIGHT_BATTERY_MASS_KG|k} kg – but the lander carries only {CARGO_LIMIT_KG|k} kg. | |
| M4 → lesson | The Moon night lasts about 2 weeks. Solar panels stop and batteries are too heavy – a small reactor keeps the base alive. | |

### Priority 2: Science Cards

**strings.csv (M-09)**

| Key | English | Bangla |
| --- | --- | --- |
| `CARD_NEW` | New Science Card! | |
| `CARD_DID_YOU_KNOW` | Did you know? | |
| `CARD_ALBUM` | Science Cards | |
| `CARD_ALBUM_COUNT` | Science Cards {n}/{total} | |
| `CARD_LOCKED` | Not found yet | |
| `CARD_HOW_TO_FIND` | How to find it: {hint} | |
| `CARD_TAB_ALL` | All | |
| `CARD_TAB_MOON` | Moon | |
| `CARD_TAB_SURVIVAL` | Astronaut life | |
| `CARD_TAB_NASA` | NASA now | |
| `CARD_CLOSE` | Close | |
| `DEBRIEF_NEW_CARDS` | New Science Cards this mission: {n} | |

**facts.json: new facts F17–F29**

| ID | English | Bangla |
| --- | --- | --- |
| F17 | In 2009 NASA crashed a used rocket into a dark crater near the Moon's South Pole – and found water ice there! | |
| F18 | The Moon shakes too! Seismometers left by Apollo astronauts recorded 28 shallow moonquakes from 1969 to 1977. | |
| F19 | The Moon moves about 3.8 cm farther from Earth every year. Scientists measure it by bouncing lasers off mirrors that Apollo astronauts left there. | |
| F20 | Scientists think the Moon was born about 4.5 billion years ago, when an object maybe as big as Mars smashed into the young Earth. | |
| F21 | Apollo astronauts brought 382 kg of Moon rocks and soil back to Earth for scientists to study. | |
| F22 | On the space station, a machine makes oxygen by splitting water with electricity. This is called electrolysis! | |
| F23 | NASA research shows that Moon soil, called regolith, blocks radiation about as well as aluminum. | |
| F24 | On Artemis I in 2022, two test dummies named Helga and Zohar flew around the Moon to measure radiation. Zohar wore a special protective vest. | |
| F25 | NASA is working on a small nuclear reactor for the Moon, so a base has power even during the 14½-day lunar night. | |
| F26 | In NASA's Watts on the Moon Challenge, a team from the University of California, Santa Barbara won $1 million for a better way to move and store power on the Moon. | |
| F27 | NASA's Break the Ice Lunar Challenge (2020–2024) asked inventors to build robots that dig icy Moon soil, so future crews can get water there. | |
| F28 | NASA's LunaRecycle Challenge asks people to invent ways to recycle trash on the Moon. A student team from MIT won first prize in Phase 2. | |
| F29 | Astronauts often sleep less in space than on Earth. NASA studies this, because tired crews can make more mistakes. | |

**learning.json → cards → title**

| Fact | Card title | Bangla |
| --- | --- | --- |
| F12 | Moon Gravity | |
| F10 | Moon Radiation | |
| F23 | Moon-Soil Shield | |
| F21 | Moon Rocks | |
| F17 | Ice in the Dark | |
| F20 | How the Moon Was Born | |
| F18 | Moonquakes | |
| F19 | Drifting Away | |
| F15 | Sharp Dust | |
| F04 | Dusty Panels | |
| F16 | Space Rock Hit | |
| F06 | Recycled Water | |
| F22 | Making Oxygen | |
| F05 | Every Breath | |
| F11 | Storm Warning | |
| F09 | The 1972 Storm | |
| F01 | The Long Night | |
| F02 | Hot and Cold | |
| F25 | A Moon Reactor | |
| F26 | Watts on the Moon | |
| F07 | Space Lettuce | |
| F29 | Sleep in Space | |
| F27 | Break the Ice | |
| F28 | LunaRecycle | |
| F24 | Helga and Zohar | |
| F13 | The Far Side | |
| F03 | Peaks of Light | |
| F14 | Why Astronauts Float | |
| F08 | Space Workout | |

### Priority 3: card hints (learning.json → cards → hint)

| Fact | Hint | Bangla |
| --- | --- | --- |
| F12 | Land on the Moon | |
| F10 | Send someone to work outside | |
| F23 | Dig Moon soil over the shelter | |
| F21 | Earn 1 science point | |
| F17 | Earn 3 science points | |
| F20 | Earn 6 science points | |
| F18 | Earn 10 science points | |
| F19 | Earn 15 science points | |
| F15 | Let dust build up on the panels | |
| F04 | Clean the solar panels | |
| F16 | Survive a meteoroid strike | |
| F06 | The water recycler breaks | |
| F22 | Mission 2 briefing | |
| F05 | Mission 1 briefing | |
| F11 | A solar storm is coming | |
| F09 | Survive a solar storm | |
| F01 | See the sunset on Day 15 | |
| F02 | Mission 4 briefing | |
| F25 | Run a reactor at night | |
| F26 | Battery gets low at night | |
| F07 | Grow plants in the greenhouse | |
| F29 | An astronaut gets tired | |
| F27 | Finish Mission 1 | |
| F28 | Finish Mission 2 | |
| F24 | Finish Mission 3 | |
| F13 | Mission Control: Did you know? | |
| F03 | Mission Control: Did you know? | |
| F14 | Mission Control: Did you know? | |
| F08 | Mission Control: Did you know? | |
