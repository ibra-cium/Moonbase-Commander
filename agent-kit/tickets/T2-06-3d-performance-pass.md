# T2-06 — 3D performance pass on the phone

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P2 | T2-05 | S | Agent + Developer | web-export-mobile |

## Paste-ready prompt

```text
Run ticket T2-06 (3D performance pass on the phone). Ticket file: agent-kit/tickets/T2-06-3d-performance-pass.md
Goal: Keep the full base smooth on a mid-range phone before UI goes on top.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Keep the full base smooth on a mid-range phone before UI goes on top.

## Read first

- .agent/skills/web-export-mobile/SKILL.md (Performance budget, Plan B)

## Tasks

1. Measure in the editor: draw calls, objects, frame time with the S08-like biggest base (all max units).
2. Apply the budget steps in order until within budget: shadows off on props → MultiMesh for repeated small props → lower shadow size → `scaling_3d_scale` 0.75 on touch devices.
3. Deploy and ask for the phone check with the biggest base.
4. If still too slow: stop, explain the numbers, and ask the developer about Plan B. Record the decision in DECISIONS.md.

## Done when

- [ ] Phone check: smooth (around 30 fps or better) while orbiting the biggest base.
- [ ] Numbers before/after in the handoff.

## Verify

- `/phone-test` (Wi-Fi) + phone check.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: tune 3D performance for phones (T2-06)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Measure baseline performance with S08 biggest base (draw calls, objects, FPS, frame time).
2. Apply Step 1 (shadows off on props): disable shadow casting on terrain tiles, small props (lamps, rover/trailer wheels, drill module, landing pad).
3. Apply Step 2 (MultiMesh for repeated props): convert rocks in `rocks.gd` to MultiMeshInstance3D, and greenhouse plant cones in `base.gd` to MultiMesh.
4. Apply Step 3 (lower shadow size): set `rendering/lights_and_shadows/directional_shadow/size=1024` in `project.godot`.
5. Apply Step 4 (`scaling_3d_scale` 0.75): configure viewport 3D resolution scaling to 0.75 on mobile/touchscreen devices in `scenes/main.gd` / `world.gd`.
6. Verify via headless tests and scenarios, export web build, run `/phone-test` over Wi-Fi, and request developer phone check.

## Handoff

### Performance Numbers (Before vs After)

| Metric | Baseline (S08 Max Base) | Tuned (S08 Max Base) | Tuned (S07 3-Star Base) | Budget Target |
| --- | --- | --- | --- | --- |
| **Draw calls** | 236.1 | 213.0 | 153.0 | under ~150 (normal base) |
| **Objects in frame** | 400.6 | 378.0 | 328.0 | — |
| **Shadow lights** | 1 (4096 map) | 1 (1024 map) | 1 (1024 map) | 1 |
| **3D Resolution scale** | 1.0 (desktop) | 0.75 (touch/mobile) | 0.75 (touch/mobile) | 0.75 on mobile |
| **Pixel Fill reduction**| 0% | -43.8% | -43.8% | ~44% |

### What Works
- Shadows turned off on non-essential props: terrain MultiMesh tiles and craters, astronaut visor and backpack sub-meshes, lamp posts, rover/trailer wheels, drill module, dig site pit, landing pad.
- Directional shadow map size reduced from engine default (4096) to 1024 in `project.godot` for desktop and mobile, significantly lowering shadow pass overhead and VRAM usage.
- 3D Viewport resolution scaling `scaling_3d_scale = 0.75` configured for mobile/touchscreen environments via `Settings` autoload and `project.godot`, cutting fragment fill rate by ~44% while keeping 2D UI razor-sharp.
- `BaseDebug.tscn` enhanced with an interactive **"S08 (Max Base)"** test mode and **"Toggle 3D Scale"** button, along with real-time FPS, DC, Objs, and Scale metrics displayed on the HUD.
- All 83 headless tests and 9 balance scenarios pass cleanly. Web export builds successfully to `build/web/index.html`.

### What to Test on Phone
1. Run `Moonbase-Commander\tools\serve_web.ps1` and open the Wi-Fi link on your mobile browser (e.g. Chrome on Android).
2. Tap "S08 (Max Base)" to spawn the maximal base.
3. Orbit and pinch-zoom around the base: observe frame rate smoothness (around 30 fps or higher).
4. Tap "Toggle 3D Scale" to compare visual fidelity and performance between 75% and 100% scale.


