# ART_DIRECTION — how the game looks

Based on the team's asset list (22 Oct 2026). All 3D packs are CC0. Low-poly, flat colours, one palette. The base should read clearly on a phone screen held sideways.

## 1. Palette

Six colours carry meaning everywhere: in 3D, in the UI and in the icons. Never use them for anything else.

| Name | Hex | Means |
| --- | --- | --- |
| Regolith grey | `#8B8D90` | Moon ground (rocks a darker `#5E6166`) |
| Module white | `#E9E7E2` | Habitat and modules |
| Power yellow | `#F2C14E` | Power, batteries, solar |
| Water blue | `#3D8BD9` | Water |
| Oxygen green | `#44B35A` | Oxygen, plants, "OK" status |
| Alert red | `#E04848` | Danger, alarms, broken things |

Neutrals: sky `#05060A`, UI panel `#141821` at 88 % opacity, UI text `#F3F4F6`, muted text `#9AA3B2`.

Crew suit colours (never blue, green or yellow, because those mean water, oxygen and power): orange `#F28C28`, purple `#8B5CF6`, pink `#EC6FA8`, brown `#A0673A`.

## 2. Rules

- KayKit colours every model from one atlas, `spacebits_texture.png`. Keep it as is; tint with materials only where this file says so.
- KayKit ground and rocks are Mars orange. Override them in code with a plain grey `StandardMaterial3D` (Regolith grey / rock grey). No realistic textures in the base scene.
- Use the **glTF** files only.
- All 3D under **5 MB** in `game/assets/models/`. The 28 KayKit models are about 0.78 MB.
- **No wind turbines** (no air on the Moon). Skip Quaternius enemies, mechs, alien trees, pickups.
- **No NASA logos** on any model or texture. If a NASA 3D model shows one, hide that part.

## 3. Cargo item → model on the base

Every packed item appears on the base. Six solar panels packed = six panels outside. No greenhouse packed = its spot stays empty.

| Game item | Model (file) | What changes on screen |
| --- | --- | --- |
| Habitat (always) | KayKit `basemodule_A` | Status light on the roof: green / yellow / red for life support |
| Life support + water recycler (always) | KayKit `basemodule_C` | Sparks and steam when the recycler breaks |
| Solar panel ×N | KayKit `solarpanel` | Turns with the Sun, stops at sunset, goes dark when broken |
| Battery ×N | KayKit `containers_B` (yellow cluster), one per battery, max 12 shown, then a "×N" label | Emissive strip shows charge; drains at night |
| Small reactor ×N | Code-built: short cylinder + 4 thin radiator panels, on KayKit `lander_base` as the stand | Steady soft glow, day and night |
| Greenhouse | KayKit `basemodule_E`, dome tinted pale green | Code-built cones as plants: grow each healthy day, turn brown when wilting |
| Water containers | KayKit `containers_C` (blue) | One tank disappears per 20 % of water used |
| Oxygen tanks | KayKit `containers_A` (green) | Same as water |
| Shield water | Code-built thin grey boxes around the shelter | Shown only if packed; thicker look for more units |
| Storm shelter (always) | KayKit `tunnel_straight_B`, half-buried | Regolith mound (code) on top grows with each REGOLITH job |
| Food | KayKit `cargo_A_stacked` → `cargo_A_packed` → `cargo_A` | Stack shrinks as food runs low |
| Science drill (always) | KayKit `drill_structure` + `drill_module` | Drill part spins on SCIENCE days |
| Lamp posts (always) | KayKit `lights` | On at night, off when power fails |
| Tunnels | KayKit `tunnel_straight_A`, `tunnel_diagonal_short_A` | — |
| Rover (always) | KayKit `spacetruck` + `spacetruck_trailer` | Drives dig site → shelter on REGOLITH days |
| Dig site | KayKit `terrain_mining` | Where the rover loads |
| Radar dish | Quaternius Roof Radar on the habitat roof | Turns slowly |

### Base layout (top view, tune in the editor)

```
                N (shelter + mound)
                     [Shelter]
   [Dig site]  [Greenhouse]═[Habitat]═[Life support]   [Drill]
   [Rover]          [O2][H2O]   [Batteries]    [Lamp posts around]
                 ┌───────────────────────────┐
                 │  Solar field (rows)       │      [Landing pad]
                 └───────────────────────────┘           [Crates]
   [Reactor(s)] ~25 m away, cable to habitat (NASA plans reactors far from crews)
```

Put each spot as a `Marker3D` in `Base.tscn` (`Slot_Solar`, `Slot_Battery`, ...). Spawning code places N copies in a grid from the marker.

## 4. Crew

- Code-built astronaut: capsule body (suit colour), white sphere helmet, dark visor (`#1A1A1A`, slightly glossy), small backpack box. About 1.8 m tall.
- **They hop, they don't walk.** Bob up and down with a sine wave; squash a little on each landing. Apollo crews often hopped on the Moon.
- States: working (small hops at the job spot), sick (slower hop + small red icon above the helmet), in shelter (hidden, light on at the shelter door), evacuating (all four hop to the lander).
- Job spots: panels (CLEAN/REPAIR panel), life support module (REPAIR recycler), greenhouse (FARM), dig site (REGOLITH), drill (SCIENCE), habitat door (REST: hidden inside).

## 5. Landing and lift-off

| Moment | What the player sees | Files |
| --- | --- | --- |
| Pack screen | Lander filling with crates as items are added | KayKit `lander_B` (or `lander_A`), `cargo_A_packed` |
| Landing | Lander drops onto the pad: engine flame, then a dust cloud | `landingpad_small`; Kenney `flame_01–06`, `dirt_01–03`, `smoke_01–10` |
| After landing | Burn mark on the pad, crates roll out one by one | Kenney `scorch_01–03`; KayKit `cargo_A_packed` |
| Evacuation | The same lander lifts off with flame and dust | same as landing |

## 6. Moon, sky, Earth

| Thing | Source | Notes |
| --- | --- | --- |
| Ground | KayKit `terrain_low` tiles, `terrain_slope` edges | Regolith grey material |
| Craters | KayKit `terrain_mining` | Grey |
| Rocks | KayKit `rock_A`, `rock_B`, `rocks_A`, `rocks_B` | Rock grey, scatter 10–15 |
| Stars | Code: a few hundred white points (MultiMesh) | No big star-map files |
| Sun | `DirectionalLight3D` + Kenney `flare_01` / `light_01` glow sprite | Moves across the sky Days 1–14, sets on Day 15 |
| Earth | NASA Blue Marble, January map, resized to 1024×512 | Credit: NASA Earth Observatory |
| Moon globe (title) | NASA CGI Moon Kit `lroc_color_2k.jpg` + `ldem_3_8bit.jpg` height | Credit: NASA's Scientific Visualization Studio. Made from LRO data. |

Lighting: harsh sun (warm white `#FFF4E0`), almost black shadows (no air), low ambient so the base stays readable. At night: lamp posts (`OmniLight3D`), glowing module windows, faint blue Earth-light ambient. One shadow-casting light, short shadow distance, for phones.

## 7. Event effects (no new models)

| Event | What the player sees | Assets |
| --- | --- | --- |
| Sunset (Day 15) | Sun drops, shadows stretch, lamps on, panels stop, battery glow starts draining | code, KayKit `lights` |
| Solar storm warning | Red tint, fast streaks across the sky, alarm light on the shelter, crew hops inside | Kenney `trace_01–07`, code |
| Micrometeoroid | Quick streak, spark burst, the panel goes dark with a crack | Kenney `trace`, `spark_01–07`, `scratch_01` |
| Recycler breaks | Sparks, a steam puff, red status light | Kenney `spark`, `smoke_01–10` |
| Supplies low | The crate stack or tank cluster gets smaller | KayKit models |
| Power fails | Lamps and module lights go out, the hum stops | code, sound |
| Regolith job | Rover drives, dirt puffs, shelter mound grows | KayKit `spacetruck`, Kenney `dirt_01–03`, code mound |
| Science day | Drill spins, small dust puff | KayKit `drill_module`, Kenney `dirt` |
| Mission stars | 1–3 stars pop in | Kenney `star_01–09` |

## 8. UI look

- Dark translucent panels (`#141821`, 88 %), 8 px rounded corners, 12–16 px padding.
- Touch targets at least 64 px. Body text at least 22 px at 1280×720.
- Fonts: Noto Sans (Latin), Noto Sans Bengali (fallback for Bangla).
- Icons: Material Icons: `bolt` power, `water_drop` water, `air` oxygen, `co2` (or `cloud`) CO2, `restaurant` food, `eco` greenhouse, `shield` shelter, `construction` repair, `science` science, `cleaning_services` clean, `landscape` regolith, `bedtime` rest, `info` source tag.
- Optional: Kenney UI Pack (Sci-Fi), CC0, for buttons and bars.
- Gauges: icon + number + unit + thin bar in the meaning colour. Red pulse when critical.
- Popups: two lines of text at most, one or two buttons.

## 9. Credits block (README, added in T6-01)

```
- 3D models: KayKit Space Base Bits by Kay Lousberg (CC0)
- 3D models: Ultimate Space Kit by Quaternius (CC0)
- Particles and sounds: Particle Pack, Sci-fi Sounds and Interface Sounds by Kenney (CC0)
- Moon maps: CGI Moon Kit, NASA's Scientific Visualization Studio (Lunar Reconnaissance Orbiter data)
- Earth map: Blue Marble Next Generation, NASA Earth Observatory
- Spacecraft models: NASA 3D Resources
- Icons: Material Icons by Google (Apache License 2.0)
- Fonts: Noto Sans and Noto Sans Bengali (SIL Open Font License 1.1)
```
Add Kenney UI Pack (Sci-Fi) if used.
