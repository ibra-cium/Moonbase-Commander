# CONTEXT — Moonbase Commander

## One line

The player commands a small Moon base. They pack a lander, then keep four astronauts alive for 30 days: about 14 days of sunlight, then the long lunar night. What they pack decides whether the base survives the night.

## Challenge

NASA Space Apps Challenge 2026 · **Build a Junior Astronaut Mission Trainer** · Local event: Dhaka, Bangladesh · Team **Space-ArenaX**.

NASA asks for a game or app where students run a lunar or Martian outpost and balance life support, radiation shielding, power and food, so they feel the decisions that make a mission succeed or fail. Full text: `Moonbase-Commander/docs/challenge.md`.

## Who plays

- Students aged 10–14. One run takes 10–15 minutes.
- In a phone or laptop browser from one link. English and Bangla.
- Judges watch a 240-sec video (local) and a 30-sec video (NASA). The demo in those videos must show: the pack screen, the Day 15 sunset, a solar storm, the debrief, and a NASA source tag on a number.

## Team

| Name | Role |
| --- | --- |
| Siam Ibrahim | Game designer and the only developer (works with you) |
| Alfi Shahrin Talukder | Content architect: game values, text |
| MD Samiul Islam | Researcher: power, debrief facts |
| Ahsanur Rahman | Researcher: radiation, cargo |
| Samia Jahan | Presenter and researcher: life support, Bangla text |

Only Siam writes code. The others may commit data and text files from their own accounts.

## Dates (Dhaka time)

| When | What |
| --- | --- |
| 9–12 Nov | Build the full game (mentor approved building before the event) |
| 12 Nov night | Code freeze; developer commits everything, deploys, live link works on phones |
| 13 Nov 15:00 | Demo recorded for Video 2 |
| 13 Nov 18:30 | Video 2 (240 sec) due |
| 14 Nov 12:00 | Video 3 (30 sec) due, NASA page submitted |

## Scope

**Must have:** title screen, pack screen with cargo limit, landing, 30-day turn loop, four linked systems (power, life support, food, shielding), four crew with daily jobs, events (sunset, solar storm, recycler breakdown, dust, meteoroid), debrief with cause chain and one real fact with source, 1–3 stars, retry, source tags on numbers, 3D base that shows every packed item, plays in a phone browser.

**Nice to have:** Bangla toggle (planned in P5), sound, title-screen Moon globe, NASA hardware cards in the debrief.

**Not in this version:** multiplayer, accounts, Mars, upgrades, purchases, saving between sessions.

## The lessons the game must teach (and the numbers behind them)

| Lesson | Numbers (IDs in constants.json) |
| --- | --- |
| The lunar night is long; solar alone fails | `NIGHT_DAYS` ≈ 14.8, `SUNSET_DAY` = 15 |
| Batteries alone cannot carry the night | `NIGHT_BATTERY_MASS_KG` ≈ 41,417 kg vs `CARGO_LIMIT_KG` = 15,000 |
| A small reactor can | `REACTOR_S_KWE` = 10, `REACTOR_S_MASS_KG` = 1,500 |
| Water is also a radiation shield | `SPE_DOSE_SHIELD_15` = 46.9 mSv vs `SPE_DOSE_HABITAT_NO_EXTRA_MSV` = 398 mSv |
| Recycling water saves mass | `WATER_RECOVERY_FULL` = 0.98 |
| Plants are slow for short missions | `LETTUCE_GROW_DAYS` = 33 > `MISSION_DAYS` = 30 |

## Hard rules

1. Every number from `game/data/constants.json` via `Constants.v("ID")`. Values marked *Game setting* or *Game assumption* are our choices; the sources screen must say so.
2. Never invent facts, numbers, sources or links.
3. No NASA logos. NASA images credited ("Credit: NASA's Scientific Visualization Studio" etc.).
4. No names, faces or voices of anyone under 18.
5. The game never shows anyone dying. Failure = the crew is evacuated to Earth.
6. Every failure is avoidable with good planning. No pure-luck losses.
7. Popups: two lines of text at most.
8. Kit files stay out of the repo (see `AGENTS.md`).
