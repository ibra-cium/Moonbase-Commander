# Moonbase Commander: game concept

> Concept stage. This describes what we plan to build during the hackathon on 13–14 November 2026.

## In one line

You command a small base on the Moon. Keep your four astronauts alive for 30 days: about 15 days of sunlight, then about 15 days of darkness. What you pack before launch decides whether you survive the night.

## Who it is for

- Students aged 10–14, though anyone can play.
- One run takes 10–15 minutes, so a class can try two or three runs in one period.
- Plays in a phone or laptop browser from one link. English and Bangla.

## How a run works

1. **Pack.** Fill the lander up to a fixed cargo mass. Choose between solar panels, batteries, a small reactor, a greenhouse, water, oxygen tanks and shielding.
2. **Survive.** Each day is one turn. Split your power between systems and give each of your four crew members one job: farm, repair, pile up regolith or do science.
3. **Debrief.** See exactly why the mission succeeded or failed.
4. **Retry.** Try again with a better plan.

## Two budgets, plus crew time

- **Cargo mass (before launch):** everything you bring has a weight, and the lander has a limit.
- **Power (every day):** you split the power your base makes between the systems.
- **Crew time:** four crew, one job each per day.

## The four systems

| System | Needs | Gives | The trade-off |
| --- | --- | --- | --- |
| Power | Cargo mass for panels, batteries or a reactor | Power for everything else | Solar is light but gives nothing at night. Batteries and a reactor are heavy. |
| Life support | Power every day, no exceptions | Air and water for the crew | If power fails, CO2 rises and the crew gets sick. |
| Food | Light (sun by day, lamps at night), water, a farming job | Food and some oxygen | A big greenhouse costs cargo mass and night power. |
| Shielding | Cargo mass, or crew days to pile up regolith | A safe storm shelter during solar flares | Shielding from Earth is fast but heavy. Regolith is free but slow. |

## Events

Each one can be survived with good planning.

- **Day 15: sunset.** This always happens in our mission scenario and is the big test of stored energy.
- **Solar storm warning:** the crew must reach the shelter in time.
- **Broken equipment:** a solar panel or the water recycler needs a crew day to fix.
- **Supplies running low.**

## Winning

- 1 star: the crew survives all 30 days.
- 2 stars: no crew member got sick.
- 3 stars: the science goal was completed too.

If conditions become unsafe, the crew is evacuated to Earth. The game never shows anyone dying.

## The debrief

The debrief shows the chain of decisions that led to the result, for example:

> Day 19: battery empty → heaters off → life support stopped. Root cause: one battery for a 15-day night.

Then it shows one short, real science fact, with its source.

## Game feel

- Calm at the start, growing worry as the night comes, tension in the dark, and an "aha" in the debrief. Never unfair.
- Every number also shows on the base itself: batteries drain on the building, plants wilt, lights go out.
- The life support hum stops when the power fails. Silence means danger.
- Popups have two lines of text at most.

## Honest science

- Every number in the game will come from a NASA source, listed in [../data/sources.md](../data/sources.md).
- The game shows a small source tag next to key numbers.
- Where we simplify the science for gameplay, we say so.

## Hackathon scope

**Must have:** pack screen, 30-day loop, four linked systems, four crew, at least three events, debrief, stars and retry, NASA sources for every number, plays in a phone browser.

**Nice to have:** Bangla/English toggle, sound design, real solar storm events from NASA records, base layout that affects how fast the crew reaches the shelter, Mars as a second level.

**Not in this version:** multiplayer, 3D, user accounts, upgrade timers, in-app purchases.
