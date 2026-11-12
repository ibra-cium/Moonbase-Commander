# CONVENTIONS

## GDScript (Godot 4.6.3)

- Static types everywhere: `var power_kwh: float = 0.0`, `func step(plan: SimPlan) -> SimDayReport:`.
- Files `snake_case.gd`, scenes `PascalCase.tscn`, `class_name PascalCase`. Simulation classes start with `Sim` (`SimMission`, `SimPower`).
- Simulation code (`game/sim/`) extends `RefCounted`. No `Node`, no scene tree, no `get_tree()`, no `print` for logic, no randomness except the mission's seeded `RandomNumberGenerator`.
- Signals are past tense: `day_resolved`, `mission_ended`.
- Constants: `Constants.v("SOLAR_UNIT_KW")` in game code. In sim code, the constants dictionary is passed in (`SimConstants`) so tests run without autoloads.
- No magic numbers for game data. Anything the simulation uses or the player reads as a fact (masses, kW, kg, days, doses, chances) comes from `constants.json`.
- Visual and layout numbers (positions, scales, colours, animation times, font sizes) are fine as named `const` at the top of world/UI scripts: `const PANEL_SPACING_M := 2.5`. Colours come from `ART_DIRECTION.md` §1.
- Tests and scenarios load scripts with `preload("res://sim/...")`, not by `class_name`, so they work right after `--import`.
- Keep functions under ~40 lines. One script = one job.
- Comments: one short line when the "why" is not obvious. No essays.
- User-facing text: always `tr("KEY")`. Keys `UPPER_SNAKE` grouped by screen: `PACK_TITLE`, `HUD_O2`, `EVT_STORM_WARN`.

## Scenes and nodes

- Node names PascalCase. Scene root named like the file.
- UI under a `CanvasLayer`. 3D world under `World` (Node3D).
- The world and the UI never change the simulation directly. They send the player's plan to `GameState`; the simulation answers with a report; they display it.

## Files

```
game/
  autoload/   constants.gd, game_state.gd, settings.gd, audio.gd
  sim/        sim_*.gd only
  world/      3D scenes and scripts
  ui/         screens, widgets, theme
  scenes/     Main.tscn (flow controller)
  data/       constants.json, facts.json
  i18n/       strings.csv
  assets/     models/, textures/, particles/, audio/, fonts/, icons/
  tests/      run_tests.gd, run_scenarios.gd, test_*.gd, scenarios/*.json
tools/        *.ps1 helper scripts (repo root)
```

## Text files

- All text files (`.json`, `.csv`, `.md`, `.gd`, `.tscn`) are UTF-8 **without BOM**, with LF line endings.
- Never read or write data files with Windows PowerShell `Get-Content` / `Set-Content` / `Out-File` / `>`. Windows PowerShell 5.1 reads UTF-8 as ANSI and writes a BOM; on 11 Nov this garbled 126 text fields in `constants.json`. Use the file-edit tool, Python (`python -X utf8`), or PowerShell 7 with `-Encoding utf8NoBOM`.
- `tests/test_constants.gd` fails if a data file has a BOM or garbled characters (`â€`, `Ã`, `Â`).

## Git

- The agent never runs git commands that change the repo. Read-only `git status` / `git diff` only.
- The developer commits when the game is finished, using `agent-kit/COMMIT_LOG.md` (message and files per ticket).
- Never put `.godot/`, `build/`, kit files or asset packs into commits.
