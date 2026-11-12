# T0-02 — Godot project skeleton

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P0 | T0-01 | M | Agent | godot-3d-scenes |

## Paste-ready prompt

```text
Run ticket T0-02 (Godot project skeleton). Ticket file: agent-kit/tickets/T0-02-godot-project-skeleton.md
Goal: Create the Godot 4.6.3 project in `game/` with the folder layout, project settings, autoload stubs and a placeholder main scene.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Create the Godot 4.6.3 project in `game/` with the folder layout, project settings, autoload stubs and a placeholder main scene.

## Read first

- `agent-kit/ARCHITECTURE.md`
- `agent-kit/CONVENTIONS.md`
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `agent-kit/ENV.md`

## Tasks

1. Create `game/project.godot` for 4.6.3 with the settings in ARCHITECTURE "Project settings" (Compatibility renderer for desktop and mobile, `import_etc2_astc = true`, 1280×720, stretch `canvas_items`/`expand`, main scene `res://scenes/Main.tscn`). Project name "Moonbase Commander".
2. Create the folders from CONVENTIONS (`autoload/ sim/ world/ ui/ scenes/ data/ i18n/ assets/ tests/`) with a `.gitkeep` where empty. Add a simple `icon.svg` (grey Moon circle, no logos).
3. Autoload stubs, registered in this order: `Constants` (`autoload/constants.gd`, filled in T0-04), `Settings` (`autoload/settings.gd`: `language`, `sound_on`, signal `language_changed`), `GameState` (`autoload/game_state.gd`: the five signals from ARCHITECTURE, `new_mission()` and `submit_day()` stubs that `push_warning("not yet")`).
4. `i18n/strings.csv` with header `keys,en,bn` and keys `GAME_TITLE` (Moonbase Commander) and `TITLE_START` (Start). Import it and add the generated `.translation` files under Project Settings → Localization.
5. `scenes/Main.tscn` + `scenes/main.gd`: state enum `TITLE, PACK, LANDING, PLAN_DAY, RESOLVE_DAY, DEBRIEF`, one empty function per state, starts in `TITLE`. A `CanvasLayer` with a label `tr("GAME_TITLE")`. A placeholder `World` Node3D: grey `PlaneMesh` ground, white `BoxMesh`, `Camera3D`, `DirectionalLight3D` with shadows.
6. Run `--import`, then run the project via Godot MCP (or the editor). No errors or warnings.

## Done when

- [ ] Project opens in Godot 4.6.3 with no errors; title label and a lit box visible.
- [ ] Renderer shows "Compatibility" in the editor top-right.
- [ ] Folder layout matches CONVENTIONS.

## Verify

- Godot MCP run + debug output clean (or `& $GODOT --path game`).
- `git status`: no `.godot/` folder staged.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: create Godot 4.6.3 project skeleton (T0-02)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create folder structure under `Moonbase-Commander/game/` (`autoload/`, `sim/`, `world/`, `ui/`, `scenes/`, `data/`, `i18n/`, `assets/`, `tests/`) with `.gitkeep` and `icon.svg`.
2. Author `project.godot` with Compatibility renderer, `import_etc2_astc = true`, 1280x720 viewport, `canvas_items`/`expand`, and autoload registrations.
3. Write autoload stubs (`constants.gd`, `settings.gd`, `game_state.gd`) and `i18n/strings.csv` (English and Bangla title strings).
4. Build `scenes/Main.tscn` and `scenes/main.gd` with state enum, `CanvasLayer` title label `tr("GAME_TITLE")`, and placeholder 3D world (ground PlaneMesh, BoxMesh, DirectionalLight3D, Camera3D).
5. Run Godot import and smoke-run the project, verifying zero errors or warnings, and check `git status`.

## Handoff

- **What works**: Godot 4.6.3 project created in `game/` with `project.godot` configured for Compatibility renderer, 1280×720 viewport, `canvas_items`/`expand` stretch, and ASTC/ETC2 texture compression. Folder layout matches CONVENTIONS. Autoload stubs for `Constants`, `Settings`, and `GameState` registered in order. `i18n/strings.csv` imported and verified. `scenes/Main.tscn` runs with title label `tr("GAME_TITLE")` and lit 3D box over grey plane. Zero errors/warnings in Godot console and Godot MCP.
- **What to test by hand**: Open `game/` in Godot 4.6.3 editor or run `& $GODOT --path game` to view the title label, lit 3D cube, and grey plane. Confirm "Compatibility" in top-right.
- **Known issues**: None.
- **Ideas for later**: None. Ready for T0-03 (test harness and helper scripts).
