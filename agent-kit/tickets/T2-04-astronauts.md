# T2-04 — Code-built hopping astronauts

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P2 | T2-03 | M | Agent | godot-3d-scenes |

## Paste-ready prompt

```text
Run ticket T2-04 (Code-built hopping astronauts). Ticket file: agent-kit/tickets/T2-04-astronauts.md
Goal: Four low-poly astronauts that hop to their job spots and show their state.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Four low-poly astronauts that hop to their job spots and show their state.

## Read first

- `agent-kit/ART_DIRECTION.md`
- agent-kit/ARCHITECTURE.md (World)
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/kaykit-assets/SKILL.md`

## Tasks

1. `world/Astronaut.tscn` + `astronaut.gd`: capsule body in the suit colour, white sphere helmet, dark visor, backpack box (ART_DIRECTION §4). No downloaded model.
2. Hop loop: sine bob + small squash on landing. Moving between spots: a few hops along a path with a `Tween`.
3. Job spots as `Marker3D` in `Base.tscn` (panels, life support, greenhouse, dig site, drill, habitat door, shelter door, lander).
4. States: working (small hops at the spot), sick (slower hop + red icon `Label3D` or sprite), sheltered (hidden; shelter door light on), evacuating (hop to the lander), resting (hidden inside the habitat).
5. `world/crew.gd` listens to `day_started` / `day_resolved` and moves each astronaut to their job spot during the resolve animation.

## Done when

- [x] Four astronauts in four suit colours (no blue, green or yellow).
- [x] Each job sends the astronaut to the right spot.
- [x] Storm day: all hidden in the shelter.

## Verify

- MCP run of BaseDebug + debug output.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add hopping astronauts (T2-04)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `world/Astronaut.tscn` + `astronaut.gd`: code-built ~1.8m astronaut (capsule body in suit color, white helmet, dark visor, PLSS backpack box, red sick Label3D), sine hop loop with landing squash and Tween hop movement.
2. Add job spot `Marker3D` nodes in `Base.tscn` (`Slot_Job_*`) and add shelter door light helpers in `world/base.gd`.
3. Create `world/Crew.tscn` + `world/crew.gd`: spawns 4 astronauts in palette colors (orange, purple, pink, brown), listens to `day_started`/`day_resolved`, moves astronauts to job spots, hides them in shelter on storm days or inside habitat when resting, and hops to lander on evacuation.
4. Wire `Crew` into `World.tscn` and `BaseDebug.tscn`, update `base_debug.gd` controls/display.
5. Create `tests/test_crew.gd` and verify with `tools\test.ps1`, `tools\scenarios.ps1`, and MCP run.

## Handoff

### What works
- 4 low-poly, code-built astronauts in `world/Astronaut.tscn` with suit palette colors: orange (`#F28C28`), purple (`#8B5CF6`), pink (`#EC6FA8`), brown (`#A0673A`) — no blue, green or yellow.
- Rhythmic Apollo-style lunar hop loop with squash-on-landing and airborne stretch, plus multi-arc `Tween` hop interpolation during transitions between spots.
- States fully implemented:
  - `WORKING`: small rhythmic hops at designated spot.
  - `SICK`: slower, heavy hops at habitat door with floating red `Label3D` sick badge (`+`).
  - `RESTING`: hidden inside the habitat (`visible = false`).
  - `SHELTERED`: hidden inside the shelter (`visible = false`), with shelter door alarm light illuminated.
  - `EVACUATING`: hops across the base towards the lander / landing pad.
- Dedicated `Marker3D` job slots added under `Base.tscn` (`Slot_Job_Panels`, `Slot_Job_LifeSupport`, `Slot_Job_Greenhouse`, `Slot_Job_DigSite`, `Slot_Job_Drill`, `Slot_Job_Habitat`, `Slot_Job_Shelter`, `Slot_Job_Lander`).
- `Crew.tscn` + `crew.gd` wired to `GameState` and integrated into both `World.tscn` and `BaseDebug.tscn`.
- Headless test suite `game/tests/test_crew.gd` with 8 comprehensive unit tests passing cleanly.

### What to test by hand
- Open `res://world/BaseDebug.tscn` in Godot or run via console.
- Press `Space` to step days in S07 (Smart plan): observe astronauts hopping to their spots (cleaning panels, regolith digging, science drill, farming greenhouse).
- On storm days (e.g. Day 12 in S07): observe all astronauts hopping into the storm shelter and the red shelter door light turning on.
- Press `E` (or click "Evacuate Crew [E]"): observe all 4 astronauts hopping towards the lander.

### Known issues / notes
- None. All 80 unit tests and 9 balance scenarios pass without errors or warnings.

### Ideas for later
- Event effects ticket (T4-01) can trigger dust puff particles beneath boots on landing.

