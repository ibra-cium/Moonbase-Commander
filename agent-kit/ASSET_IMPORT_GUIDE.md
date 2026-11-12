# ASSET_IMPORT_GUIDE

Two parts:

- **Part A — the developer downloads** (PA-01). The agent cannot download from these sites, so Siam downloads each pack into `Moonbase/asset-packs/`. The agent guides him one pack at a time and checks the folder after each download.
- **Part B — the agent organizes and imports** (PA-02). The agent copies only the files the game uses into `game/assets/`, renames, resizes, sets import options, fixes import problems, checks sizes and licenses, and writes the COMMIT_LOG block. No git.

AI log: the download is logged as done by hand; PA-02 is logged like any other agent ticket.

---

## Part A — downloads (developer)

Put every download in `Moonbase/asset-packs/<folder>/` (outside the repo) and unzip it there.

| # | Pack | Where | What to click / take | Folder in `asset-packs/` |
| --- | --- | --- | --- | --- |
| 1 | KayKit Space Base Bits (CC0) | https://kaylousberg.itch.io/space-base-bits | "Download Now" → "No thanks, just take me to the downloads" → the free pack | `kaykit-space-base-bits/` |
| 2 | Quaternius Ultimate Space Kit (CC0) | https://quaternius.com/packs/ultimatespacekit.html | Download the pack (glTF is inside) | `quaternius-ultimate-space-kit/` |
| 3 | Kenney Particle Pack (CC0, 80 files) | https://kenney.nl/assets/particle-pack | "Download" (a donation is optional; "Continue without donating") | `kenney-particle-pack/` |
| 4 | Kenney Sci-fi Sounds (CC0, 70 files) | https://kenney.nl/assets/sci-fi-sounds | same | `kenney-sci-fi-sounds/` |
| 5 | Kenney Interface Sounds (CC0, 100 files) | https://kenney.nl/assets/interface-sounds | same | `kenney-interface-sounds/` |
| 6 | Kenney UI Pack (Sci-Fi) (CC0, optional) | https://kenney.nl/assets/ui-pack-sci-fi | same | `kenney-ui-pack-sci-fi/` |
| 7 | NASA CGI Moon Kit | https://svs.gsfc.nasa.gov/4720 | Download `lroc_color_2k.jpg` and `ldem_3_8bit.jpg` only (the big TIFs are not needed) | `nasa-moon-kit/` |
| 8 | NASA Blue Marble Next Generation | https://science.nasa.gov/earth/earth-observatory/blue-marble-next-generation/ (also https://svs.gsfc.nasa.gov/3539) | The January 2004 map at 5400 × 2700, plain (no topography): `world.200401.3x5400x2700.jpg`. If January is hard to find, any 2004 month at 5400 × 2700 works. | `nasa-blue-marble/` |
| 9 | Noto Sans | https://fonts.google.com/noto/specimen/Noto+Sans | "Get font" → download | `fonts/` |
| 10 | Noto Sans Bengali | https://fonts.google.com/noto/specimen/Noto+Sans+Bengali | same | `fonts/` |
| 11 | Material Icons | https://fonts.google.com/icons | Download each icon in the list below as **SVG** | `material-icons/` |
| 12 | NASA 3D Resources (optional, debrief cards) | https://github.com/nasa/NASA-3D-Resources | The **PNG pictures** of: Apollo Lunar Module, Habitat Demonstration Unit, RASSOR, Lunar Reconnaissance Orbiter (A), Astronaut. No big model files. | `nasa-3d/` |

Material Icons to download (SVG): `bolt water_drop air co2 restaurant eco shield construction science cleaning_services landscape bedtime info play_arrow refresh translate volume_up volume_off star warning rocket_launch wb_sunny nightlight add remove`

Links can change. If a page has moved, search the pack name on the same site and tell the agent the new link.

---

## Part B — organize and import (agent, ticket PA-02)

Rules for the agent:

- Copy, never move: `asset-packs/` stays as it is.
- Only the files below go into the repo. Each pack's license file goes with it.
- Godot must be closed during copying; afterwards run `& $GODOT --headless --path game --import`.

### B1. Target folders and files

| Target in `game/assets/` | From | Files |
| --- | --- | --- |
| `models/kaykit/` | KayKit glTF folder | `basemodule_A basemodule_C basemodule_E solarpanel containers_A containers_B containers_C lander_A lander_B lander_base landingpad_small tunnel_straight_A tunnel_straight_B tunnel_diagonal_short_A cargo_A cargo_A_packed cargo_A_stacked drill_structure drill_module lights spacetruck spacetruck_trailer terrain_low terrain_slope terrain_mining rock_A rock_B rocks_A rocks_B` (each `.gltf` + its `.bin`), `spacebits_texture.png`, license |
| `models/quaternius/` | Ultimate Space Kit glTF folder | the roof radar model (rename to `roof_radar.gltf` / `.bin`, keep its texture), license. If no roof radar is in the pack, skip it (decoration only) and tell the developer. |
| `particles/kenney/` | Particle Pack, transparent PNGs | `flame_01–06 dirt_01–03 smoke_01–10 scorch_01–03 trace_01–07 spark_01–07 scratch_01 star_01–09 flare_01 light_01`, license |
| `audio/` | Sci-fi Sounds, Interface Sounds | see B2, license |
| `textures/nasa/` | Moon Kit, Blue Marble | `lroc_color_2k.jpg`, `ldem_3_8bit.jpg`, `earth_bluemarble_jan_1024.jpg` (B3), `CREDITS.txt` |
| `fonts/` | Noto downloads | `NotoSans-Regular.ttf NotoSans-Bold.ttf NotoSansBengali-Regular.ttf NotoSansBengali-Bold.ttf` (static TTFs), `OFL.txt` |
| `icons/` | Material Icons | the SVGs from Part A, recoloured white (B4), `LICENSE-material-icons.txt` (Apache 2.0) |
| `ui/kenney/` | UI Pack Sci-Fi (if downloaded) | panel, button and bar PNGs, license |
| `nasa3d/` | NASA 3D Resources (if downloaded) | the 5 PNGs, `CREDITS.txt` ("NASA 3D Resources"). Check none shows a NASA logo. |

Never copy `windturbine_low` or `windturbine_tall`.

`textures/nasa/CREDITS.txt`:
```
Moon: NASA's Scientific Visualization Studio, CGI Moon Kit (Lunar Reconnaissance Orbiter data).
Earth: NASA Earth Observatory, Blue Marble Next Generation.
```

### B2. Sounds

The agent cannot listen. It picks candidates by file name, copies them under the new names, and lists them for the developer to play in Godot. The developer says "OK" or names a different file.

| New name | Look for (file names) | Use |
| --- | --- | --- |
| `hum_loop.ogg` | an engine or computer loop | life-support hum |
| `alarm.ogg` | alarm, siren-like | storm warning |
| `impact.ogg` | explosion, impact, thump | meteoroid |
| `spark.ogg` | zap, laser, short electric | sparks |
| `engine.ogg` | engine, thruster | landing, lift-off |
| `ui_click.ogg` | click | buttons |
| `ui_confirm.ogg` | confirmation | confirm |
| `ui_error.ogg` | error | not allowed |
| `ui_switch.ogg` | switch | toggles |

Set `hum_loop.ogg` to loop (Import options: `loop=true`).

### B3. Earth map resize

Make `tools/resize_image.gd` (`extends SceneTree`): load the 5400 × 2700 JPG from `asset-packs/`, `resize(1024, 512, Image.INTERPOLATE_LANCZOS)`, `save_jpg(target, 0.9)`. Run it headless. Keep the script in `tools/` (it is small and shows how the file was made).

### B4. Icons white

Add `fill="#FFFFFF"` to the root `<svg>` element of each icon so they can be tinted in Godot.

### B5. Import options

| File(s) | Option |
| --- | --- |
| `hum_loop.ogg` | loop on |
| `earth_bluemarble_jan_1024.jpg`, `lroc_color_2k.jpg` | mipmaps on |
| `ldem_3_8bit.jpg` | mipmaps on (used as a height hint) |
| KayKit / Quaternius glTF | defaults; root type Node3D |
| Particle PNGs | defaults (detected as 3D when used on materials) |

Edit the `.import` files or use the editor through Godot MCP, then re-import headless. Fix any import error (wrong paths inside a `.gltf` to its `.bin` or texture are the usual cause).

### B6. Checks

- `game/assets/models/` under **5 MB** (list sizes in the handoff).
- `--import` finishes with no errors.
- A tiny test scene loads `basemodule_A.gltf` and runs with no errors (Godot MCP). Delete the test scene afterwards.
- `git status` (read-only): only `game/assets/**`, their `.import` files and `tools/resize_image.gd`. Nothing from `asset-packs/`.

### B7. Log and hand over (no git)

COMMIT_LOG message:

```
assets: add KayKit, Quaternius, Kenney, NASA maps, fonts and icons (PA-02)
```

AI log rows (`docs/ai-usage.md`):

```
| <date> | — (by hand) | Siam Ibrahim | PA-01: downloaded all asset packs from their official pages | — | KayKit, Quaternius, Kenney, NASA SVS and Earth Observatory, Google Fonts, Material Icons |
| <date> | Antigravity (<model>) | Siam Ibrahim | PA-02: copied the files we use into game/assets, resized the Earth map, recoloured icons, set import options | See docs/ai-prompts/PA-02.md | The downloaded asset packs |
```
