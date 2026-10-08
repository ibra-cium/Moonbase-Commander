# Moonbase Commander

*Keep a Moon base alive for 30 days. Survive the two-week lunar night. Learn why every choice matters.*

**NASA Space Apps Challenge 2026** · Challenge: [Build a Junior Astronaut Mission Trainer](https://www.spaceappschallenge.org/2026/challenges/build-a-junior-astronaut-mission-trainer/) · Local event: Dhaka, Bangladesh · Team: **Space-ArenaX**

> **Status: concept stage.** The game will be built during the hackathon on 13–14 November 2026. All code, data and documentation from the event will be added to this repository.

**Video:** [240-second prescreening video]([YouTube link])

---

## The problem

Space lessons for kids usually go one of two ways. Either they make the engineering trade-offs too simple, or they make them too complex to hold a young learner's attention. NASA's challenge asks for a game or app where students run a lunar or Martian outpost and balance life support, radiation shielding, power and food production, so they experience the decisions that make a mission succeed or fail.

More detail: [docs/challenge.md](docs/challenge.md)

## Our idea

Moonbase Commander is a short, replayable browser game for students aged 10–14. One run takes 10–15 minutes.

1. **Pack.** Fill a lander up to a fixed cargo mass: solar panels, batteries, a small reactor, a greenhouse, water, oxygen and shielding.
2. **Survive.** Keep four astronauts alive for 30 days, one turn per day. That is one full lunar day: about 15 days of sunlight, then about 15 days of darkness.
3. **Debrief.** If the base fails, the game shows the exact chain of what went wrong, plus one real science fact.
4. **Retry.** Try again with a better plan.

The four systems pull on each other:

| System | Needs | Gives | The trade-off |
| --- | --- | --- | --- |
| Power | Cargo mass for panels, batteries or a reactor | Power for everything else | Solar is light but gives nothing at night. Batteries and a reactor are heavy. |
| Life support | Power every day | Air and water for the crew | If power fails, CO2 rises and the crew gets sick. |
| Food | Light, water and a crew member's time | Food and some oxygen | A big greenhouse costs cargo mass and night power. |
| Shielding | Cargo mass, or crew days to pile up regolith | A safe storm shelter during solar flares | Shielding from Earth is fast but heavy. Regolith is free but slow. |

Every disaster in the game can be survived with good planning. The player never loses by pure luck, only by the choices they made.

Full concept: [docs/concept.md](docs/concept.md)

## Why it matters

NASA is going back to the Moon to stay, and the people who will live and work there are in school today. Moonbase Commander lets them feel real mission trade-offs instead of memorising facts. Kids learn by failing, understanding why, and trying again.

We are designing it to run in any phone browser and to support both **English and Bangla**, so students in Bangladesh can play it in their own language.

## Science and NASA data

Our rule: **every number in the game comes from a NASA source, and the game shows that source to the player.** Where we simplify the science for gameplay, we say so.

NASA releases the full challenge statement and its datasets on 28 October 2026. Every dataset and source we use will be listed in [data/sources.md](data/sources.md), together with what we used it for and how.

## Planned tech

- Browser game that plays on phones and laptops from one link, with no install
- Engine: Godot 4 (web export) or HTML5 Canvas with JavaScript, final choice on Day 1
- Languages: English and Bangla

## Team Space-ArenaX

| Name | Role |
| --- | --- |
| Siam Ibrahim | Game designer and developer |
| Alfi Shahrin Talukder | Developer and content architect |
| MD Samiul Islam | Researcher |
| Ahsanur Rahman | Researcher |
| Samia Jahan | Presenter and researcher |

## Repository structure

```
moonbase-commander/
├── README.md          this page
├── CONTRIBUTING.md    how our team works in this repo
├── LICENSE            MIT
├── docs/              challenge, concept, timeline and AI-use log
├── data/              NASA sources for every number in the game
├── game/              game code (built during the hackathon)
└── media/             video links and screenshots
```

## Timeline

Key dates are in [docs/timeline.md](docs/timeline.md).

## Use of AI

Every AI tool we use is named in [docs/ai-usage.md](docs/ai-usage.md), with what we used it for and the prompts behind it.

## Credits

NASA images and data are credited wherever they are used. Any third-party asset, library or tool will be listed here.

## License

Code is released under the [MIT License](LICENSE).
