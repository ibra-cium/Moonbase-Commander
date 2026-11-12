# T2-01 — Asset check, Moon ground, sky and camera

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P2 | T1-08, PA-02 | M | Agent | godot-3d-scenes, kaykit-assets, lighting-and-effects, web-export-mobile |

## Paste-ready prompt

```text
Run ticket T2-01 (Asset check, Moon ground, sky and camera). Ticket file: agent-kit/tickets/T2-01-moon-ground-sky-camera.md
Goal: The empty Moon scene: grey ground and rocks, black sky with stars, the Sun, Earth in the sky, and a touch-friendly orbit camera.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

The empty Moon scene: grey ground and rocks, black sky with stars, the Sun, Earth in the sky, and a touch-friendly orbit camera.

## Read first

- `agent-kit/ART_DIRECTION.md`
- agent-kit/ARCHITECTURE.md (World)
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/kaykit-assets/SKILL.md`
- `.agent/skills/lighting-and-effects/SKILL.md`

## Tasks

1. Read-only asset check: list `game/assets/` and compare with ART_DIRECTION and ASSET_IMPORT_GUIDE §2. Report missing files to the developer. Do not add or move asset files.
2. `world/World.tscn` with the children listed in ARCHITECTURE. `Ground`: KayKit `terrain_low` tiles (about 60×60 m), `terrain_slope` edges, Regolith grey override, two `terrain_mining` craters. `Rocks`: 10–15 rocks, rock grey, no shadows.
3. `world/SkyRig.tscn`: black `WorldEnvironment`, low ambient, star `MultiMeshInstance3D` (a few hundred points on a big sphere), Sun `DirectionalLight3D` + glow sprite, Earth sphere with `earth_bluemarble_jan_1024.jpg` placed low in the sky.
4. `world/CameraRig.tscn` + `camera_rig.gd`: orbit/zoom by mouse and touch (skill), clamps, smooth damping.
5. Put `World.tscn` into `Main.tscn` in place of the placeholder world.
6. Deploy and ask for a phone check (orbit and pinch on the phone).

## Done when

- [ ] Scene runs with no errors; ground and rocks are grey, not orange.
- [ ] Orbit and pinch work on the phone at a smooth frame rate.

## Verify

- MCP run + debug output.
- `tools\test.ps1` still passes.
- `/phone-test` (Wi-Fi) + phone check.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add Moon ground, sky and orbit camera (T2-01)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Asset audit: verify all required models, textures, audio, icons, and fonts in `game/assets/` against ART_DIRECTION and ASSET_IMPORT_GUIDE §2.
2. Build `world/SkyRig.tscn` + `sky_rig.gd`: WorldEnvironment (black `#05060A`, low ambient, ACES tonemap), star MultiMesh, Sun DirectionalLight3D with flare sprite and sun_progress/apply_sun methods, Earth sphere with Blue Marble texture.
3. Build `world/CameraRig.tscn` + `camera_rig.gd`: Gimbal rig (yaw/pitch/distance) with mouse and multi-touch pinch/drag, UI hover ignoring, pitch clamping (25°–65°), distance clamping (18–60 m), and smooth damping.
4. Build `world/ground.gd`, `world/rocks.gd`, and `world/World.tscn`: MultiMesh 60×60 m regolith grey `terrain_low` tiles, perimeter `terrain_slope`, two `terrain_mining` craters, 12–15 scattered grey rocks without shadows, and placeholder slots (`Base`, `Crew`, `Effects`).
5. Replace placeholder World in `scenes/Main.tscn` with `World.tscn`, run Godot MCP / CLI smoke test, run `tools/test.ps1` and `tools/scenarios.ps1`, export web build, and prepare for phone test.

## Handoff

- **What works:**
  - `game/world/SkyRig.tscn` + `sky_rig.gd`: Deep space environment (`#05060A`, ACES tonemap, subtle Earth-light ambient), 400-star MultiMesh sphere, warm Sun DirectionalLight3D (`#FFF4E0`) with Kenney flare glow sprite, NASA Blue Marble Earth sphere placed low in the sky, and `sun_progress(day, frac)` / `apply_sun(t)` methods.
  - `game/world/CameraRig.tscn` + `camera_rig.gd`: Gimbal orbit camera responding to mouse drag and touch gestures (single-finger orbit, two-finger pinch zoom, mouse wheel zoom), pitch clamped (25°–65°), distance clamped (18–60 m), and smooth framerate-independent exponential damping. Ignores drags that start on UI elements.
  - `game/world/ground.gd` + `world/rocks.gd`: 60×60 m terrain using MultiMesh for flat `terrain_low` tiles with regolith grey override (`#8B8D90`), perimeter `terrain_slope` boundaries, 2 `terrain_mining` craters, and 14 scattered rocks (`#5E6166`) with shadows disabled.
  - `game/world/World.tscn`: Root world scene containing all ARCHITECTURE children (`Ground`, `Rocks`, `Base`, `Crew`, `SkyRig`, `CameraRig`, `Effects`) integrated cleanly into `scenes/Main.tscn`.
  - Headless test coverage in `game/tests/test_world.gd` validating all node structures, transforms, materials, and sun progression calculations (71/71 tests passing).
  - Web export build verified (`build/web/index.html`).
- **What to test by hand:**
  - Run the project or serve the web build over Wi-Fi (`tools\serve_web.ps1`). Check that the ground is regolith grey, sky is deep black with stars and low Earth, and test orbiting/pinching with touch on a phone.
- **Known issues / notes:**
  - Asset audit revealed `drill_module` was listed as a standalone gltf in ASSET_IMPORT_GUIDE table, but in KayKit pack it is integrated in `drill_structure.gltf` and OBJ format. Everything required for P2/T2-01 is present.
- **Next ticket:**
  - `T2-02`: Base layout and cargo spawner (`agent-kit/tickets/T2-02-base-layout-and-spawner.md`).
