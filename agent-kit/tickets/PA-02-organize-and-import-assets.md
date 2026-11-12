# PA-02 — Organize and import the assets

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| PA | PA-01 | M | Agent | kaykit-assets |

## Paste-ready prompt

```text
Run ticket PA-02 (Organize and import the assets). Ticket file: agent-kit/tickets/PA-02-organize-and-import-assets.md
Goal: Copy only the files the game uses from `asset-packs/` into `game/assets/`, rename, resize, set import options, fix import problems, check size and licenses, and commit.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Copy only the files the game uses from `asset-packs/` into `game/assets/`, rename, resize, set import options, fix import problems, check size and licenses, and commit.

## Read first

- agent-kit/ASSET_IMPORT_GUIDE.md (Part B)
- agent-kit/ART_DIRECTION.md §2
- `.agent/skills/kaykit-assets/SKILL.md`
- `agent-kit/ENV.md`

## Tasks

1. Ask the developer to close the Godot editor. Then follow Part B steps B1–B5 exactly.
2. B2 sounds: copy your best guesses, then list them for the developer to play in Godot; swap any he does not like.
3. Run `--import` headless; fix every import error.
4. B6 checks (size under 5 MB, import clean, test scene loads `basemodule_A.gltf`).
5. B7: add both AI-log rows (the "by hand" download row and this ticket's row), save the prompt record, add the COMMIT_LOG block. No git commands.

## Done when

- [x] All files from B1 in place with licenses; `models/` under 5 MB (892 KB).
- [x] `--import` clean; test scene runs without errors.
- [x] Candidate sounds mapped and listed for developer review.
- [x] Both AI-log rows added.

## Verify

- `--import` output.
- Godot MCP run of the test scene.
- `git status` (read-only) shows only `game/assets/**`, `.import` files and `tools/resize_image.gd`.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`assets: add KayKit, Quaternius, Kenney, NASA maps, fonts and icons (PA-02)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Verify Godot editor is closed; create target directories in `game/assets/` (`models/kaykit`, `models/quaternius`, `particles/kenney`, `audio`, `textures/nasa`, `fonts`, `icons`, `ui/kenney`, `nasa3d`).
2. Copy exact required glTF models & texture from KayKit; copy Quaternius `Roof_Radar.gltf` as `roof_radar.gltf` with licenses.
3. Copy specified Kenney transparent particle PNGs; pick candidate audio files from Kenney sound packs with loop config on `hum_loop.ogg`.
4. Copy NASA Moon textures, create `tools/resize_image.gd` and run it headless to generate `earth_bluemarble_jan_1024.jpg`, and add NASA credits file.
5. Copy required Noto font TTFs + OFL license; copy Material Icons SVG with root `fill="#FFFFFF"` injected + license; copy UI/NASA-3D packs.
6. Run headless import, fix any issues, create a smoke test scene loading `basemodule_A.gltf` to verify clean load, then delete test scene.
7. Record prompt record, update `docs/ai-usage.md` with both rows, update `agent-kit/COMMIT_LOG.md`, and report handoff.

## Handoff

### What works
- All target folders and files from `ASSET_IMPORT_GUIDE.md` Part B organized into `game/assets/`:
  - `game/assets/models/`: KayKit (28 models + atlas texture) + Quaternius (`roof_radar.gltf`). Total size: 892 KB (well within the 5 MB limit).
  - `game/assets/particles/`: 48 Kenney transparent particle PNGs + license.
  - `game/assets/audio/`: 9 mapped `.ogg` sound files with `hum_loop.ogg` set to `loop=true` + licenses.
  - `game/assets/textures/nasa/`: `lroc_color_2k.jpg`, `ldem_3_8bit.jpg`, and resized `earth_bluemarble_jan_1024.jpg` with mipmaps enabled + `CREDITS.txt`.
  - `game/assets/fonts/`: 4 Noto Sans and Noto Sans Bengali static TTFs + `OFL.txt`.
  - `game/assets/icons/`: 25 Material Icons SVGs with root `fill="#FFFFFF"` injected + Apache 2.0 license.
  - `game/assets/ui/kenney/`: Kenney UI Pack Space Expansion PNGs + license.
  - `game/assets/nasa3d/`: 5 NASA hardware PNG cards cleaned of NASA meatballs/logos to strictly adhere to Rule 3 + `CREDITS.txt`.
- `tools/resize_image.gd` created and executed headless to produce `earth_bluemarble_jan_1024.jpg`.
- Headless `--import` ran with exit code 0 and no errors.
- Smoke test scene verified clean load and instantiation of `basemodule_A.gltf` and `roof_radar.gltf` (deleted afterwards).
- Unit tests (`tools/test.ps1`) continue to pass 5/5.
- Both AI log rows added to `docs/ai-usage.md`, prompt record created at `docs/ai-prompts/PA-02.md`, and COMMIT_LOG block added.

### Audio candidates for developer review
Please play these in Godot when convenient and let me know if you want to swap any:
1. `hum_loop.ogg` <- `spaceEngineLow_000.ogg` (low continuous engine hum, loop enabled)
2. `alarm.ogg` <- `laserRetro_004.ogg` (retro siren/alarm tone)
3. `impact.ogg` <- `explosionCrunch_000.ogg` (meteoroid impact/explosion)
4. `spark.ogg` <- `laserSmall_000.ogg` (short electric spark/zap)
5. `engine.ogg` <- `thrusterFire_000.ogg` (thruster fire for landing/lift-off)
6. `ui_click.ogg` <- `click_001.ogg` (crisp UI click)
7. `ui_confirm.ogg` <- `confirmation_001.ogg` (positive confirmation chime)
8. `ui_error.ogg` <- `error_001.ogg` (error tone)
9. `ui_switch.ogg` <- `switch_001.ogg` (toggle switch)

### Next ticket
T1-01 (Cargo catalog and pack maths).
