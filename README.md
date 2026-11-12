# Moonbase Commander

*Keep a Moon base alive for 30 days. Survive the two-week lunar night. Learn why every choice matters.*

**NASA Space Apps Challenge 2026** · Challenge: [Build a Junior Astronaut Mission Trainer](https://www.spaceappschallenge.org/2026/challenges/build-a-junior-astronaut-mission-trainer/) · Local event: Dhaka, Bangladesh · Team: **Space-ArenaX**

> **Play in your browser:** [https://ibra-cium.github.io/Moonbase-Commander/](https://ibra-cium.github.io/Moonbase-Commander/) (runs on phones and computers)

**Video:** [240-second prescreening video]([YouTube link])

---

## How to play

1. **Pick a mission:** Choose from four progressively challenging missions on the Mission Map, from a 5-day starter to the full 30-day lunar night survival.
2. **Guess first:** Answer the junior astronaut briefing question from Mission Control to test your instinct before launch.
3. **Pack your lander:** Balance limited cargo mass between solar panels, batteries, a nuclear reactor, life-support supplies, a greenhouse, and storm shielding.
4. **Command the base:** Each day, tap astronauts to assign duties (repairing modules, farming, piling lunar regolith, researching science, or resting) and toggle power switches.
5. **Debrief and master:** Overcome solar storms, equipment breakdowns, and the dark night; inspect your cause-chain debrief, earn stars, and collect Moon Science Cards!

---

## The problem

Space lessons for kids usually go one of two ways. Either they make the engineering trade-offs too simple, or they make them too complex to hold a young learner's attention. NASA's challenge asks for a game or app where students run a lunar or Martian outpost and balance life support, radiation shielding, power and food production, so they experience the decisions that make a mission succeed or fail.

More detail: [docs/challenge.md](docs/challenge.md)

## Our idea

Moonbase Commander is a short, replayable browser game for students aged 7–13. One mission takes 3–15 minutes.

1. **Pack.** Fill a lander up to a fixed cargo mass: solar panels, batteries, a small reactor, a greenhouse, water, oxygen and shielding.
2. **Survive.** Keep four astronauts alive for the mission duration. The final mission runs a full lunar day (30 Earth days): about 15 days of sunlight, then about 15 days of freezing darkness.
3. **Debrief.** If the base fails, the game shows the exact chain of what went wrong, plus real science facts.
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

It runs in any phone or desktop browser and supports both **English and Bangla**, so students in Bangladesh can play and learn space science in their own language.

## Impact

- **Who it is for:** Kids aged 7–13 at school or at home, running in any mobile or desktop browser in both **English and Bangla** with zero setup.
- **What kids learn:** Real mission trade-offs across power, life support, radiation, and crew rest—reinforced through 29 collectible Moon Science Cards unlocked at key moments.
- **How it helps NASA:** Connects students directly to active NASA initiatives (Fission Surface Power, Watts on the Moon, Break the Ice, LunaRecycle, and Artemis I MARE) and demonstrates why these challenges matter today.
- **Measurable learning score:** Built-in "Guess first!" pre-mission questions and post-mission debrief answers give teachers and parents tangible before-and-after proof of learning.
- **Playtest results:** Tested with ___ kids aged ___. Before: ___ / ___ correct; After: ___ / ___ correct; Science cards collected per kid: ___.
- Learn more in our full [docs/impact.md](docs/impact.md).

## Science and NASA data

Our hard rule: **every number in the game comes from a NASA source, and the game shows that source to the player.** Where we simplify the science for gameplay, we label it as a "Game assumption" or "Game setting".

Every single value used in the game is catalogued with its exact NASA source document, link, and notes in [data/sources.md](data/sources.md). Players can also inspect sources live in the game by tapping the ⓘ source tag beside any gauge or pack item, or by opening the in-game **Sources** screen from the title screen or pause menu.

## Tech stack

- Godot 4.6.3, 3D low-poly, web export (Compatibility renderer), plays in phone and laptop browsers
- Dual languages: English and Bangla (with dedicated Noto Sans Bengali font fallback)

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
├── docs/              challenge, concept, impact, timeline and AI-use log
│   └── ai-prompts/    prompt of every AI coding task
├── data/              NASA sources for every number in the game
├── game/              game code (Godot 4.6.3 project)
├── tools/             helper scripts
└── media/             video links and screenshots
```

## Timeline

Key dates are in [docs/timeline.md](docs/timeline.md).

## Use of AI

We follow the NASA Space Apps Challenge AI policy completely and transparently. Every AI tool used during development is documented in [docs/ai-usage.md](docs/ai-usage.md), with dates, models, developers, and exact scope. Each individual AI-assisted coding task also has its full prompt and change summary recorded in [docs/ai-prompts/](docs/ai-prompts/).

## Credits

- 3D models: KayKit Space Base Bits by Kay Lousberg (CC0)
- 3D models: Ultimate Space Kit by Quaternius (CC0)
- UI assets: Sci-Fi UI Pack by Kenney (CC0)
- Particles and sounds: Particle Pack, Sci-fi Sounds and Interface Sounds by Kenney (CC0)
- Moon maps: CGI Moon Kit, NASA's Scientific Visualization Studio (Lunar Reconnaissance Orbiter data)
- Earth map: Blue Marble Next Generation, NASA Earth Observatory
- Spacecraft models: NASA 3D Resources
- Icons: Material Icons by Google (Apache License 2.0)
- Fonts: Noto Sans and Noto Sans Bengali (SIL Open Font License 1.1)

## License

Code is released under the [MIT License](LICENSE).
