# T0-04 — Constants loader and game data

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P0 | T0-03 | M | Agent | nasa-data, sim-testing |

## Paste-ready prompt

```text
Run ticket T0-04 (Constants loader and game data). Ticket file: agent-kit/tickets/T0-04-constants-and-game-data.md
Goal: Bring in the game numbers and make `Constants.v("ID")` the only way code reads them.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Bring in the game numbers and make `Constants.v("ID")` the only way code reads them.

## Read first

- `.agent/skills/nasa-data/SKILL.md`
- agent-kit/ARCHITECTURE.md (Autoloads, Simulation classes)
- `agent-kit/CONVENTIONS.md`

## Tasks

1. Copy `agent-kit/repo-files/game/data/constants.json` and `facts.json` into `game/data/`.
2. `game/sim/sim_constants.gd` (`class_name SimConstants extends RefCounted`): `static func from_json(text: String) -> SimConstants`, `func v(id: String) -> Variant` (unknown ID → `push_error` + `assert(false)`), `func has(id: String) -> bool`, `func meta(id: String) -> Dictionary`, `func ids() -> PackedStringArray`.
3. `autoload/constants.gd`: reads `res://data/constants.json` with `FileAccess.get_file_as_string`, builds `sim: SimConstants`, exposes `v()` and `meta()`.
4. `game/tests/test_constants.gd`: file loads; 166 IDs; `SOLAR_UNIT_MASS_KG` ≈ 12.5; `LOAD_TOTAL_KW` ≈ 18.7; `NIGHT_BATTERY_MASS_KG` ≈ 41416.7; `has("NOT_AN_ID")` is false; every entry has value, unit, type, source.
5. Same file: a scan test that reads every `.gd` under `res://` (skip `res://tests/`), finds `v("ID")` with a regex, and fails if an ID is missing in the JSON.
6. Replace the title label text with `tr("GAME_TITLE")` + a small debug label showing `Constants.v("MISSION_DAYS")` days, to prove the autoload works in the running game. Remove the debug label in T3-02.

## Done when

- [x] All tests pass.
- [x] Running the game shows "30 days" in the debug label.

## Verify

- `tools\test.ps1`
- MCP run: debug label shows 30.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`data: add game constants, facts and the Constants loader (T0-04)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Copy `agent-kit/repo-files/game/data/constants.json` and `facts.json` into `game/data/`.
2. Create `game/sim/sim_constants.gd` (`class_name SimConstants extends RefCounted`) with `from_json`, `v`, `has`, `meta`, and `ids`.
3. Update `autoload/constants.gd` to read `res://data/constants.json`, instantiate `SimConstants`, and delegate `v()` and `meta()`.
4. Create `game/tests/test_constants.gd` extending `TestCase` with value checks, entry completeness checks, and a regex scanner for all `v("ID")` in `res://` scripts.
5. Add a debug label to `scenes/Main.tscn` and `scenes/main.gd` displaying `Constants.v("MISSION_DAYS")` days.
6. Verify with `tools\test.ps1` and Godot command line / MCP execution.

## Handoff

- **What works:** `constants.json` and `facts.json` imported; `SimConstants` class and `Constants` autoload active; 166 constants verified; tests assert all metadata fields, values, and scan all `.gd` files for constant references; running project displays "30 days" via `Constants.v("MISSION_DAYS")`.
- **What to test by hand:** Run `tools\test.ps1` or run the project in Godot to see "Moonbase Commander" and "30 days" on the title screen.
- **Known issues:** None.
- **Ideas for later:** The debug label on `Main.tscn` will be removed in T3-02 when the full title screen UI is built.

