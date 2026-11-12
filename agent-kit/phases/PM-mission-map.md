# PM — Mission map and game feel (redesign, 11 Nov)

Added on 11 Nov after the first full playthrough felt flat: one packing choice decided the whole mission, the 30 days needed almost no input, and nothing showed what the player learned. Ideas borrowed from Clash of Clans: a mission map with stars and unlocks, named crew, tap-to-collect, events as "attacks" on the base, tapping buildings to give jobs.

| Ticket | What | Size |
| --- | --- | --- |
| [M-01](../tickets/M-01-mission-map.md) | Mission map and four missions | L |
| [M-02](../tickets/M-02-named-crew.md) | Named crew, speech bubbles, jobs stay from yesterday | S |
| [M-03](../tickets/M-03-tap-to-collect.md) | Tap-to-collect bubbles and resource bar | M |
| [M-04](../tickets/M-04-moon-alerts.md) | Event alerts with countdown and result | M |
| [M-05](../tickets/M-05-tap-to-assign.md) | Tap an astronaut, then tap a building | M |
| [M-06](../tickets/M-06-crew-energy.md) | Crew energy: astronauts need rest (added 11 Nov late) | M |
| [M-08](../tickets/M-08-astronaut-training.md) | Junior astronaut training: briefing, guess first, answer after, ranks, certificate (added 11 Nov late) | L |
| [M-09](../tickets/M-09-science-cards.md) | Moon Science Cards: learn while you play (added 11 Nov late) | M |
| [M-07](../tickets/M-07-kid-gauges.md) | Gauges a kid can read and act on (added 11 Nov late) | M |

**Order on 12 Nov:** M-06 → M-08 → M-09 → M-07, then P6.

**Exit gate:** a new player picks Mission 1 on the map, wins it on the phone with touch only, unlocks Mission 2, and Mission 4 still plays exactly like the game before PM. S01–S09 pass unchanged.

**Rules for PM**
- Mission 4 = the original 30-day game. Never change it to balance Missions 1–3.
- Missions 1–3 only override *Game settings* (mission length, forced event days). NASA values are never overridden.
- M-03, M-04 and M-05 do not change the simulation.
- Every new text key goes into `strings.csv` with `bn` empty; send the list to Samia the same evening.
- Stop new feature work at 21:30 on 11 Nov. P5 (Bangla, phone) and P6 (ship) run on 12 Nov.

**Not in PM (after the hackathon):** science shop / upgrades (was M-06), placing buildings freely on a grid, a base that carries over between missions, Mars.
