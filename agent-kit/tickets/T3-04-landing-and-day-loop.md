# T3-04 — Landing and the day loop

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P3 | T3-03 | L | Agent | godot-3d-scenes |

## Paste-ready prompt

```text
Run ticket T3-04 (Landing and the day loop). Ticket file: agent-kit/tickets/T3-04-landing-and-day-loop.md
Goal: Launch → landing animation → the turn loop: plan the day, press End Day, watch it resolve, repeat until the end.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Launch → landing animation → the turn loop: plan the day, press End Day, watch it resolve, repeat until the end.

## Read first

- agent-kit/ART_DIRECTION.md §8
- agent-kit/ARCHITECTURE.md (UI, Main flow)
- agent-kit/GAME_RULES.md §11
- `.agent/skills/godot-3d-scenes/SKILL.md`
- `.agent/skills/i18n-bangla/SKILL.md`
- `.agent/skills/nasa-data/SKILL.md`
- agent-kit/ART_DIRECTION.md §5

## Tasks

1. `main.gd` states: PACK → LANDING → PLAN_DAY ⇄ RESOLVE_DAY → DEBRIEF, calling `GameState.new_mission(cargo, seed)` and `GameState.submit_day(plan)`. Seed: random per mission, shown small in the debrief.
2. `world/Lander.tscn`: lander drops onto the pad with a flame, dust cloud, scorch mark; crates roll out one by one; then the base builds (spawn with a quick pop-in).
3. RESOLVE_DAY: about 2 s; sun moves, crew hop to jobs, base updates; then the next PLAN_DAY. Popups from `day_started` appear before planning (storm).
4. A "Fast" toggle that shortens resolve to 0.5 s (for testing and for the video).

## Done when

- [x] A full 30-day mission can be played start to end with a temporary minimal HUD (End Day button).
- [x] Landing plays once per mission.

## Verify

- MCP run + debug output.
- `tools\test.ps1`

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add landing and the day loop (T3-04)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `game/world/Lander.tscn` & `lander.gd` with lander descent animation, thruster flame, touchdown dust particles (CPUParticles3D), pad scorch mark, crates rollout, and base pop-in sequence.
2. In `game/world/base.gd`, implement `animate_pop_in(duration)` for quick pop-in of static buildings and cargo spawns.
3. In `game/autoload/settings.gd`, add `fast_mode: bool = false`. Update `sky_rig.gd` and `crew.gd` to respect resolution duration.
4. Create minimal `game/ui/DayHud.tscn` / `day_hud.gd` (day counter, Fast toggle, End Day button) and `game/ui/DebriefScreen.tscn` / `debrief_screen.gd` (stars, outcome, seed, retry/pack buttons), and wire `EventPopup` for start-of-day warnings.
5. In `game/scenes/main.gd` & `Main.tscn`, wire full state flow: PACK → LANDING → PLAN_DAY ⇄ RESOLVE_DAY → DEBRIEF with random mission seed.
6. Verify with headless tests `tools\test.ps1`, full play smoke test, and check no errors or warnings.

## Handoff

- **What works:**
  - Launch from `PackScreen` transitions into `LANDING` state once per mission with random seed generation.
  - `Lander` (`Lander.tscn` / `lander.gd`) drops from y=22 onto the landing pad at (12, 0.5, 7.5), displays thruster flame flickering, kicks up regolith dust shockwave particles, fades in a pad scorch mark, rolls out crates, and triggers sequential pop-in of base buildings and astronaut crew.
  - `PLAN_DAY` presents minimal `DayHud` (Day counter, Fast toggle button, Resolving indicator, End Day button with >= 64 px touch target) and processes start-of-day warnings via `EventPopup` (e.g. solar storm warnings).
  - `RESOLVE_DAY` advances the day via `GameState.submit_day(plan)`, animating sun movement and crew hopping (1.5-2.0s in normal mode, 0.4-0.5s in fast mode).
  - Full 30-day mission can complete start to end and transitions to `DebriefScreen`, displaying outcome, 3-star rating, days survived, root cause code, seed display, Retry Mission button, and Change Cargo button.
  - All 104 unit tests in `tools\test.ps1` pass without errors.
  - All 9 balance scenarios S01-S09 in `tools\scenarios.ps1` pass.
- **What to test by hand:**
  - Run the game in browser or desktop (`tools\serve_web.ps1` or Godot).
  - Click Start -> pack cargo -> Launch Mission. Watch the lander descend with flame and dust, pad scorch appear, and base pop in.
  - Test toggling Fast mode ON/OFF on the HUD.
  - Step through days by clicking "End Day". Notice the sun moving and crew hopping.
  - Reach Day 30 debrief screen and test "Retry Mission" and "Change Cargo".
- **Known issues:**
  - None.
- **Ideas for later tickets:**
  - Ticket T3-05 will replace the minimal DayHud with the full comprehensive HUD (gauges, source tags, crew plan drawer, etc.).

