# T4-02 — Evacuation lift-off and success ending

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P4 | T4-01 | S | Agent | godot-3d-scenes, lighting-and-effects |

## Paste-ready prompt

```text
Run ticket T4-02 (Evacuation lift-off and success ending). Ticket file: agent-kit/tickets/T4-02-mission-endings.md
Goal: Endings that feel right and never show harm: the crew hops to the lander and lifts off, or celebrates surviving the night.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Endings that feel right and never show harm: the crew hops to the lander and lifts off, or celebrates surviving the night.

## Read first

- agent-kit/ART_DIRECTION.md §4–5
- agent-kit/CONTEXT.md (Hard rules)

## Tasks

1. Evacuation: all four hop to the lander, door closes, lift-off with flame and dust, camera follows up, then the debrief.
2. Success on Day 30: sunrise glow on the horizon (the night is almost over), crew gathers outside, stars pop, then the debrief.
3. Skip button for both.

## Done when

- [x] Both endings play once and lead to the debrief.

## Verify

- MCP run + debug output.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`game: add mission ending sequences (T4-02)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. In `lander.gd`, implement `play_liftoff(crew: Node3D, fast: bool)` and `liftoff_completed` signal: flame sprite flicker, launch dust particles, rocket ascending into the sky with ease-in quadratic acceleration, and crew boarding inside.
2. In `crew.gd`, implement `celebrate_success(on_complete: Callable)` (all 4 astronauts gather in front of the habitat and hop happily) and complete boarding logic in `evacuate()`.
3. In `sky_rig.gd`, add horizon sunrise dawn glow (`show_sunrise_glow()`) to celebrate the end of the long 14-day lunar night.
4. In `camera_rig.gd`, add cutscene camera pitch follow for the rising lander during evacuation, and framed shot for celebration.
5. Create `game/ui/EndingOverlay.tscn` / `ending_overlay.gd` with touch-friendly (≥64 px) Skip button (`BTN_SKIP`), banner title, and `skip_pressed` signal. Add `BTN_SKIP` and ending titles to `strings.csv`.
6. Update `scenes/main.gd` to introduce `State.ENDING`: route `resolve_completed` when `mission.ended` to either evacuation or success ending sequence with active Skip button, cleanly transitioning to `State.DEBRIEF`.
7. Write unit tests in `game/tests/test_mission_endings.gd` registered in `run_tests.gd`, verify with `tools/test.ps1` and `tools/scenarios.ps1`, and verify scene execution with Godot.

## Handoff

- Created `game/ui/EndingOverlay.tscn` and `game/ui/ending_overlay.gd` with touch-friendly (≥64 px height) Skip button (`BTN_SKIP`) and localized title banners (`ENDING_EVAC_TITLE` and `ENDING_SUCCESS_TITLE`).
- Implemented Evacuation lift-off sequence in `lander.gd` (`play_liftoff`), `crew.gd` (`board_lander`), and `camera_rig.gd` (`follow_liftoff`): crew hops to the lander and boards inside ("door closes"), engines ignite with flame flicker and dust plume, the rocket ascends into space with quadratic acceleration, and the camera tilts up to follow the ascent before entering debrief.
- Implemented Day 30 survival success ending in `sky_rig.gd` (`show_sunrise_glow`), `crew.gd` (`celebrate_success`), `effects.gd` (`play_stars`), and `camera_rig.gd` (`frame_celebration`): warm dawn sunrise glow illuminates the eastern horizon signalling the end of the lunar night, all four crew gather outside the habitat hopping joyfully, and celebratory golden star particles pop above the base before debrief.
- Wired `State.ENDING` in `scenes/main.gd` and `Main.tscn` with full Skip button support (skipping immediately cleans up camera and enters `State.DEBRIEF`), plus state and camera reset logic on retry/change cargo.
- What to test by hand:
  - Play an evacuation run (e.g. pack only solar panels, watch Day 18 evacuation lift-off and camera tilt).
  - Play a successful run to Day 30 (e.g. S07 cargo with reactors, watch Day 30 sunrise dawn glow, outdoor gathering and stars).
  - Tap the Skip button during either ending sequence to verify it smoothly transitions directly to debrief.
- Known issues: None.
- Ideas for later: Sound effects for rocket thrusters and celebratory fanfare in T4-03.
