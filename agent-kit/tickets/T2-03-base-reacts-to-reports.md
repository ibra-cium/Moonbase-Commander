# T2-03 — Base reacts to each day

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P2 | T2-02 | M | Agent | godot-3d-scenes, kaykit-assets |

## Paste-ready prompt

```text
Run ticket T2-03 (Base reacts to each day). Ticket file: agent-kit/tickets/T2-03-base-reacts-to-reports.md
Goal: The base shows the simulation state at a glance: tanks vanish, crates shrink, battery glow drains, status light changes, lamps go out in a blackout, the shelter mound grows, plants grow or wilt, broken panels go dark.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

The base shows the simulation state at a glance: tanks vanish, crates shrink, battery glow drains, status light changes, lamps go out in a blackout, the shelter mound grows, plants grow or wilt, broken panels go dark.

## Read first

- `agent-kit/ART_DIRECTION.md`
- agent-kit/ARCHITECTURE.md (World)
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/kaykit-assets/SKILL.md`
- agent-kit/GAME_RULES.md §11

## Tasks

1. `base.gd`: `apply_report(report)` (connected to `GameState.day_resolved`).
2. Water and oxygen clusters: one tank hidden per 20 % used. Food: `cargo_A_stacked` → `cargo_A_packed` → `cargo_A` → none as food runs down.
3. Battery glow strip emission = battery fraction. Status light on the habitat: green (all fine), yellow (any supply low or CO2 above healthy), red (blackout or CO2 above limit).
4. Broken panel: dark material + `scratch_01` decal-like quad. Recycler broken: red light on `basemodule_C`.
5. Shelter mound: a code mesh (flattened sphere) scaled by `shelter_g_cm2`. Greenhouse: plant cones scale with `growth_days`, turn brown when wilting, hidden when dead.
6. BaseDebug: buttons or keys to step days with a fixed plan, to check visuals without the UI.

## Done when

- [x] Stepping through S01 in BaseDebug shows the blackout and red status light on Day 16.
- [x] Stepping S07 shows the mound growing and plants growing.

## Verify

- MCP run of BaseDebug + debug output.
- `tools\test.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: base visuals follow the simulation (T2-03)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. In `game/world/base.gd`, implement `apply_report(report)` with full visual state reactions:
   - Progressive hiding of O2 and water tanks (1 tank hidden per 20% used, keeping >=1 while supply remains).
   - Food stack progression: `cargo_A_stacked` -> `cargo_A_packed` -> `cargo_A` -> hidden when empty.
   - Battery glow strip emission modulated by battery charge fraction; lamp posts extinguished during blackout.
   - Habitat roof status light: green (healthy), yellow (CO2 > healthy max or supply low), red (blackout or CO2 >= limit).
   - Broken solar panels: dark material override + `scratch_01` decal quad; red warning light on `basemodule_C` for broken recycler.
   - Shelter mound: code-built flattened `SphereMesh` scaling with `shelter_g_cm2`.
   - Greenhouse plants: code-built cone meshes scaling with `growth_days`, brown when wilting, hidden when dead.
2. In `game/world/base_debug.gd` and `BaseDebug.tscn`, add controls to step through S01 (blackout & red light on Day 16) and S07 (mound & plants growing) with status HUD.
3. Add comprehensive automated tests in `game/tests/test_base.gd` verifying all visual reaction states.
4. Verify with `tools\test.ps1`, `tools\scenarios.ps1`, and running `BaseDebug.tscn`.

## Handoff

### What works
- `apply_report(report)` in `base.gd` (wired to `GameState.day_resolved`) updates all visual indicators:
  - Tanks vanish progressively as supplies drop (1 tank hidden per 20% used, keeping >= 1 visible until supply hits 0).
  - Food crate models transition dynamically between `cargo_A_stacked` -> `cargo_A_packed` -> `cargo_A` -> hidden when empty.
  - Battery glow strip emission matches battery charge fraction (1.0 down to 0.0); perimeter lamps shut off during blackouts.
  - Habitat roof status light reflects life-support status: green (healthy), yellow (CO2 > 2.0 mmHg or supply low), red (blackout or CO2 >= 3.0 mmHg).
  - Broken solar panels receive dark material override and `scratch_01` quad decals; restored on repair.
  - Life Support module `basemodule_C` toggles red warning light when recycler breaks; turns off when repaired.
  - Code-built flattened `SphereMesh` regolith shelter mound scales up with `shelter_g_cm2`.
  - Greenhouse code-built cone plants scale up with `growth_days`, turn brown with wilt days, and hide if crop dies.
- `BaseDebug.tscn` interactive stepping tool supports stepping S01 and S07 scenarios with live HUD stats and hotkeys (Space to step, 1 for S01, 7 for S07, B for Day 16 blackout).
- Headless test suite expanded to 83 tests passing cleanly (`tools\test.ps1`).
- Scenarios S01–S09 all pass (`tools\scenarios.ps1`).
- Web export completes cleanly (`tools\export_web.ps1`).

### What to test by hand
- Run `res://world/BaseDebug.tscn` in Godot editor or via MCP.
- Click "Jump Day 16 (Blackout)" under S01: observe battery glow strip at 0, perimeter lamps extinguished, and habitat roof status light glowing red.
- Click "S07 (Smart)" and press Space to step days: observe regolith mound growing over the shelter tunnel and green plant cones scaling up inside the greenhouse dome.

### Known issues & ideas for later
- Astronaut characters hopping to job locations will be built in the next ticket T2-04.

