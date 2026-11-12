# T2-02 — Base layout and cargo spawner

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P2 | T2-01 | L | Agent | godot-3d-scenes, kaykit-assets |

## Paste-ready prompt

```text
Run ticket T2-02 (Base layout and cargo spawner). Ticket file: agent-kit/tickets/T2-02-base-layout-and-spawner.md
Goal: Every packed item appears on the base: N panels, N batteries, reactors, greenhouse, tanks, crates, shield boxes, plus the always-there buildings.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Every packed item appears on the base: N panels, N batteries, reactors, greenhouse, tanks, crates, shield boxes, plus the always-there buildings.

## Read first

- `agent-kit/ART_DIRECTION.md`
- agent-kit/ARCHITECTURE.md (World)
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/kaykit-assets/SKILL.md`

## Tasks

1. `world/model_catalog.gd`: item key → PackedScene(s) per ART_DIRECTION §3.
2. `world/Base.tscn`: `Marker3D` slots as in the layout sketch (ART_DIRECTION §3). Always-there pieces: habitat `basemodule_A`, life support `basemodule_C`, tunnels, shelter `tunnel_straight_B` half-buried, drill, lamp posts, rover + trailer at the dig site, radar on the habitat roof, landing pad.
3. `world/base.gd`: `build_from_cargo(cargo)` clears and spawns grids from each slot; battery cluster shows max 12 models then a "×N" `Label3D`; greenhouse only if area > 0 (dome tinted pale green, duplicated material); shield boxes around the shelter only if shield > 0.
4. Code-built reactor: `CylinderMesh` + 4 thin `BoxMesh` radiators on `lander_base`, placed ~25 m away with a thin cable (stretched box) to the habitat.
5. Debug: a `world/BaseDebug.tscn` that builds the base from the S07 cargo so it can be checked alone. Connect `base.gd` to `GameState.mission_started`.

## Done when

- [x] S07 cargo shows 24 panels, 6 batteries, 2 reactors, greenhouse, tanks, crates, shield boxes.
- [x] Base cargo without greenhouse shows an empty greenhouse spot.
- [x] No errors; draw calls noted in the handoff.

## Verify

- MCP run of `BaseDebug.tscn` + debug output.
- `tools\test.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add base layout and cargo spawner (T2-02)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `game/world/model_catalog.gd` mapping cargo keys and base elements to PackedScenes and mesh helpers per ART_DIRECTION §3.
2. Create `game/world/Base.tscn` and `game/world/base.gd` with Marker3D layout slots, always-there base structures (habitat, life support, tunnels, buried shelter, drill, lamps, rover/trailer, roof radar, landing pad), and dynamic cargo spawning for solar, battery (max 12 + Label3D), greenhouse (pale green tint), O2, water, food, and shield boxes.
3. Code-build reactor assembly (`CylinderMesh` + 4 thin `BoxMesh` radiators on `lander_base`) ~25 m away with stretched cable to habitat.
4. Hook `base.gd` to `GameState.mission_started` and update `game/world/World.tscn` to instantiate `Base.tscn`.
5. Create `game/world/BaseDebug.tscn` and unit tests in `game/tests/test_base.gd`.
6. Verify via headless tests (`tools\test.ps1`), scenario checks (`tools\scenarios.ps1`), and MCP/CLI debug run of `BaseDebug.tscn`.

## Handoff

### What works
- `model_catalog.gd` provides centralized preloaded scenes and shadow control helpers for all cargo and base assets.
- `Base.tscn` establishes 14 `Marker3D` layout slots and always-there static structures: Habitat with rotating roof radar, Life Support, half-buried Shelter, connecting tunnels, Science Drill, Dig Site crater, Rover with trailer, Landing Pad, and perimeter lamps.
- `base.gd` dynamically spawns cargo:
  - 24 solar panels arranged in rows.
  - 6 batteries (clusters max 12 models; shows "×N" `Label3D` in power yellow when >12).
  - 2 code-built nuclear reactors (~25 m away) with 4 radiator panels on `lander_base` and stretched cable to Habitat.
  - Greenhouse module with pale-green tinted dome (isolated via duplicated material), completely empty if greenhouse area is 0.
  - O2 and water tanks, stacked food crates, and grey shield walls around the shelter.
- `BaseDebug.tscn` standalone debug scene runs with zero warnings or errors. Draw calls: ~160, objects: ~260, running smoothly at 41-60 FPS in Compatibility renderer.
- Headless tests (`tools\test.ps1`) pass: 76 / 76.
- Scenarios (`tools\scenarios.ps1`) pass: 9 / 9.

### What to test by hand
- Open `res://world/BaseDebug.tscn` in Godot editor or run it via MCP to view the layout and test the mode buttons ("S07 (Full)", "No GH", "16 Bat").
- Check the orbit camera and visual hierarchy around the habitat and reactor cable.

### Known issues & ideas for later
- Day-to-day visual reactions (tanks disappearing as supplies decrease, status indicator lights changing colors, rover moving on regolith days, drill spinning on science days) will be implemented in the next ticket T2-03.
