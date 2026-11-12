# PA-01 — Download the asset packs (developer, agent guides)

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| PA | T0-02 | S | Developer + Agent | — |

## Paste-ready prompt

```text
Run ticket PA-01 (Download the asset packs). Ticket file: agent-kit/tickets/PA-01-download-asset-packs.md
You cannot download from these sites, so guide me: follow agent-kit/ASSET_IMPORT_GUIDE.md Part A one row at a time. Give me the link, what to click and the folder to unzip into, then wait for me to say done and check the folder. Do not download anything and do not touch Moonbase-Commander/. At the end, list what is in asset-packs/ and set PA-01 to Done in STATUS.md.
```

## Goal

Siam downloads every pack into `Moonbase/asset-packs/`. The agent cannot download from these sites, so it guides him one pack at a time and checks each folder after the download.

## Read first

- agent-kit/ASSET_IMPORT_GUIDE.md (Part A)

## Tasks

1. Create the empty folders from the Part A table inside `asset-packs/`.
2. Guide the developer through Part A one row at a time: give the link, what to click, which folder to save and unzip into. Wait for "done" after each row.
3. After each row: list the folder and confirm the expected files are there (e.g. the KayKit glTF folder with `basemodule_A.gltf`, the Kenney PNGs, `lroc_color_2k.jpg`). If something is missing or a link has moved, tell him exactly what to look for.
4. Do not download anything yourself and do not touch `Moonbase-Commander/` in this ticket.

## Done when

- [x] Every row of the Part A table (optional rows only if he chose them) has its files in `asset-packs/`.

## Verify

- Folder listing per pack in the handoff.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

— (no commit; the download is logged as "by hand" in PA-02)

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create target directories in `asset-packs/` for all packs listed in ASSET_IMPORT_GUIDE Part A.
2. Guide developer row-by-row (1 through 12): present link, click instructions, and target destination folder.
3. After developer confirms completion of each row, inspect the folder to verify expected files.
4. Once all rows are complete, summarize the folder contents of `asset-packs/`, update STATUS.md to Done, and write handoff.

## Handoff

### Asset Pack Inventory in `asset-packs/`
- `kaykit-space-base-bits/`: 384 files (9.63 MB) — KayKit glTF, bin, textures (`spacebits_texture.png`), and `License.txt`.
- `quaternius-ultimate-space-kit/`: 467 files (142.41 MB) — includes `Roof_Radar.gltf`, FBX/OBJ models, textures, and `License.txt`.
- `kenney-particle-pack/`: 195 files (14.52 MB) — transparent PNG particle textures and `License.txt`.
- `kenney-sci-fi-sounds/`: 76 files (5.73 MB) — 70+ `.ogg` sound effects and `License.txt`.
- `kenney-interface-sounds/`: 103 files (0.92 MB) — 100 `.ogg` UI click/switch/confirmation sounds and `License.txt`.
- `kenney-ui-pack-sci-fi/`: 1,117 files (0.83 MB) — UI frames, bars, icons, fonts, and `License.txt`.
- `nasa-moon-kit/`: 2 files (0.2 MB) — `lroc_color_2k.jpg` and `ldem_3_8bit.jpg`.
- `nasa-blue-marble/`: 1 file (0.08 MB) — `world.200401.3x5400x2700.jpg`.
- `fonts/`: 191 files (101.07 MB) — Noto Sans and Noto Sans Bengali static TTF font families + `OFL.txt` licenses.
- `material-icons/`: 26 files (0.02 MB) — 25 white-ready SVG symbols + `LICENSE-material-icons.txt` (Apache 2.0).
- `nasa-3d/`: 6 files (4.99 MB) — PNG pictures of Apollo Lunar Module, Habitat Demonstration Unit (parts 1 & 2), RASSOR, LRO (A), and Astronaut.

### Notes
- `Moonbase-Commander/` was completely untouched during this ticket.
- Ready for `PA-02` (Organize and import the assets into `game/assets/`).

