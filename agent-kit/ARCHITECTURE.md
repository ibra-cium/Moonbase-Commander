# ARCHITECTURE — Godot 4.6.3 project

## Big picture

Think of the game as three layers, like a theatre:

- **Simulation (`game/sim/`)** is the script of the play. Pure logic. It takes the player's plan for one day and returns what happened. No graphics, no nodes, fully testable headless.
- **World (`game/world/`)** is the stage. It shows the 3D base and plays effects. It only listens.
- **UI (`game/ui/`)** is the program and the buttons. It shows numbers, collects the player's choices, and listens.

`GameState` (autoload) sits in the middle and passes messages.

```
 Player taps  ──►  UI  ──plan──►  GameState  ──►  SimMission.step_day(plan)
                                     │                    │
                                     ◄──── SimDayReport ──┘
                                     │
                    signals: day_resolved(report), event_triggered(evt), mission_ended(result)
                         │                          │
                         ▼                          ▼
                    UI updates gauges        World plays sunset, storm, sparks...
```

## Project settings (set in T0-02)

| Setting | Value | Why |
| --- | --- | --- |
| Renderer | `gl_compatibility` (Compatibility) | Required for web export and phones |
| `rendering/textures/vram_compression/import_etc2_astc` | `true` | Textures work on mobile browsers |
| Window size | 1280 × 720, landscape | 3D base + side panels fit; phones play in landscape |
| Stretch mode / aspect | `canvas_items` / `expand` | UI scales on any screen |
| Main scene | `res://scenes/Main.tscn` | Flow controller |
| Physics | none needed | No physics bodies in this game |
| Default locale | `en`; translations from `res://i18n/strings.csv` | Bangla in P5 |

## Autoloads (in this order)

| Name | Script | Job |
| --- | --- | --- |
| `Constants` | `autoload/constants.gd` | Loads `res://data/constants.json` once. `Constants.v("ID")` returns the value, `Constants.meta("ID")` returns unit, type, source, link. Unknown ID → `push_error` and assert in debug. Holds a `SimConstants` object (`Constants.sim`) to pass into the simulation. |
| `Settings` | `autoload/settings.gd` | Language, sound on/off, camera sensitivity. Session only, no saving needed. |
| `GameState` | `autoload/game_state.gd` | Owns the current `SimMission`. Methods: `new_mission(cargo, seed)`, `submit_day(plan)`. Signals listed below. |
| `Audio` | `autoload/audio.gd` | Plays loops and one-shots by name (added in P4). |

### GameState signals

| Signal | Payload | Listeners |
| --- | --- | --- |
| `mission_started(mission)` | `SimMission` | World spawns the base, UI shows HUD |
| `day_started(day, warnings)` | `int`, `Array[SimEvent]` (e.g. storm warning that needs a choice) | UI shows popups |
| `day_resolved(report)` | `SimDayReport` | UI gauges, world visuals |
| `event_triggered(evt)` | `SimEvent` | World effects, audio |
| `mission_ended(result)` | `SimResult` | Main switches to debrief |

## Simulation classes (`game/sim/`, all `extends RefCounted`)

| File | Class | Job |
| --- | --- | --- |
| `sim_constants.gd` | `SimConstants` | Wraps the values dictionary. `v(id)`; errors on unknown ID. Built from JSON text so tests can load it without autoloads. |
| `sim_cargo.gd` | `SimCargo` | Item counts, mass per item, total mass, `is_valid()`, the item catalog (GAME_RULES §2). |
| `sim_plan.gd` | `SimPlan` | One day's choices: job per crew member, greenhouse lights on/off, science gear on/off, storm choice. |
| `sim_power.gd` | `SimPower` | Generation, battery, priority shedding (GAME_RULES §4). |
| `sim_life.gd` | `SimLife` | Oxygen, CO2, water, food (§5). |
| `sim_crew.gd` | `SimCrew` | Four crew: job, health, dose, sick days (§6). |
| `sim_greenhouse.gd` | `SimGreenhouse` | Growth, wilting, oxygen, science (§7). |
| `sim_events.gd` | `SimEvents` | Seeded schedule and event resolution (§8). |
| `sim_event.gd` | `SimEvent` | One event: `code`, `day`, `needs_choice`, data. |
| `sim_log.gd` | `SimLog` | Log entries with `id`, `day`, `code`, `values`, `caused_by` (entry id). Used for the debrief chain. |
| `sim_day_report.gd` | `SimDayReport` | Everything the UI and world need after a day: stocks, gauges, power served per system, events, log ids. |
| `sim_mission.gd` | `SimMission` | Owns all of the above. `step_day(plan) -> SimDayReport`. Holds `day`, `ended`, `result`. |
| `sim_result.gd` | `SimResult` | Outcome, stars, end day, cause chain, root cause, fact id. |
| `sim_debrief.gd` | `SimDebrief` | Builds the cause chain and picks the fact (§9). |

Rule: one day = one call to `step_day`. The same seed + same cargo + same plans always gives the same result.

## World (`game/world/`)

| Scene | Job |
| --- | --- |
| `World.tscn` | Root Node3D: `Ground`, `Rocks`, `Base`, `Crew`, `SkyRig`, `CameraRig`, `Effects` |
| `Ground` (`ground.gd`) | KayKit terrain tiles with grey material, crater tiles |
| `SkyRig.tscn` | `WorldEnvironment` (black sky), stars (MultiMesh points), Sun (`DirectionalLight3D` + glow sprite), Earth (sphere with Blue Marble texture) |
| `Base.tscn` (`base.gd`) | Fixed slots for every cargo item. `build_from_cargo(cargo)` spawns models; `apply_report(report)` updates looks (tanks vanish, crates shrink, lights, status light colours) |
| `Astronaut.tscn` (`astronaut.gd`) | Code-built astronaut, hop animation, states |
| `CameraRig.tscn` | Orbit around base: one-finger drag rotates, pinch/wheel zooms, limits so the base stays in view |
| `Effects.tscn` | Particle and light effects per event code |
| `Lander.tscn` | Lander + landing pad for landing and lift-off |

The world reads the cargo and reports only. It never calls `SimMission`.

## UI (`game/ui/`)

| Scene | Job |
| --- | --- |
| `Theme.tres` | Fonts (Noto Sans + Noto Sans Bengali fallback), colours from ART_DIRECTION |
| `TitleScreen.tscn` | Moon globe, Earth, Start, language toggle, Sources |
| `PackScreen.tscn` | Item cards, +/− buttons, cargo bar, warnings, Launch |
| `DayHud.tscn` | Day counter, sun/night icon, gauges, crew panel, power toggles, End Day |
| `CrewCard.tscn` | One crew member: job picker, health, dose |
| `Gauge.tscn` | Icon, value, unit, bar, colour state, source tag |
| `SourceTag.tscn` | Small ⓘ; tap shows label, value, unit, type, source name. Reads `Constants.meta(id)` |
| `EventPopup.tscn` | Two lines max + up to two choice buttons |
| `DebriefScreen.tscn` | Stars, cause chain timeline, one fact with source, Retry / Change cargo |
| `SourcesScreen.tscn` | List of every constant used, with type and source |

## Main flow (`scenes/Main.tscn`, `main.gd`)

```
TITLE → PACK → LANDING (animation) → PLAN_DAY ⇄ RESOLVE_DAY (≈2 s of effects) → … → DEBRIEF → PACK (retry)
```

`main.gd` is a small state machine. It shows and hides screens and calls `GameState`. Each state is one function.

## Tests (`game/tests/`)

| File | Job |
| --- | --- |
| `run_tests.gd` | `extends SceneTree`. Finds `test_*.gd`, runs every `test_*` method, prints PASS/FAIL, `quit(1)` on any failure |
| `test_helpers.gd` | `assert_eq`, `assert_near(a, b, tol)`, `assert_true`, loads `SimConstants` from the JSON file |
| `test_constants.gd` | JSON loads; every ID used in `res://` scripts exists (scans for `v("...")`) |
| `test_*.gd` | One file per sim class |
| `run_scenarios.gd` | Runs every `scenarios/*.json`, prints a table, `quit(1)` if a result differs from `expect` |
| `scenarios/*.json` | Cargo, seed, plan rules (e.g. "all rest", "science by day"), forced event days, expected outcome |

## Tools (repo root `tools/`)

`test.ps1`, `scenarios.ps1`, `export_web.ps1`, `deploy_web.ps1` — each reads `$env:GODOT` or a `tools/godot_path.txt` (git-ignored) for the Godot path.
