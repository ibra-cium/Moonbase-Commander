# T0-05 — Web export and first phone check over Wi-Fi

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P0 | T0-04 | M | Agent + Developer | web-export-mobile |

## Paste-ready prompt

```text
Run ticket T0-05 (Web export and first phone check over Wi-Fi). Ticket file: agent-kit/tickets/T0-05-web-export-and-phone-check.md
Goal: Prove early that a 3D Godot web build runs on the developer's phone, served from the PC over the home Wi-Fi (no deploy, no git).
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Prove early that a 3D Godot web build runs on the developer's phone, served from the PC over the home Wi-Fi (no deploy, no git).

## Read first

- `.agent/skills/web-export-mobile/SKILL.md`
- `agent-kit/ENV.md`
- `.agent/workflows/phone-test.md`

## Tasks

1. Create the "Web" export preset with the settings in the skill. Include filter must contain `*.json, *.csv`; exclude filter `tests/*`.
2. Create `tools/export_web.ps1`, `tools/serve_web.ps1` and `tools/deploy_web.ps1` (skill code). Do **not** run `deploy_web.ps1`: the developer runs it himself at the end. `build/` stays git-ignored.
3. Export. If export templates are missing, stop and ask the developer to install them for 4.6.3.
4. Check Python 3 (`python --version`); note it in ENV.md. Without Python, use Godot's own web server as the skill describes.
5. Run `/phone-test` with the placeholder scene (grey plane, white box, sun with shadows, the "30 days" label).

## Done when

- [x] The build opens on a laptop browser and on the developer's phone over Wi-Fi.
- [x] The 30-days label shows, so `constants.json` is in the export.
- [x] Phone report in the handoff (model, load time, smooth?).

## Verify

- `tools\export_web.ps1`, then `/phone-test`.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`build: add web export preset and web scripts (T0-05)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Create `game/export_presets.cfg` with the "Web" preset: single-threaded (`variant/thread_support=false`), `variant/extensions_support=false`, `vram_texture_compression` enabled for desktop and mobile, `canvas_resize_policy=2` (Adaptive), `focus_canvas_on_start=true`, include filters `*.json, *.csv`, and exclude filter `tests/*`.
2. Create `tools/export_web.ps1`, `tools/serve_web.ps1`, and `tools/deploy_web.ps1` matching the skill specifications and existing tool path conventions.
3. Run `tools/export_web.ps1` to generate `build/web/index.html` and verify export files.
4. Launch `tools/serve_web.ps1` in background and prompt the developer with the Wi-Fi link for the phone check.
5. Record results, update prompt log, ai-usage, STATUS.md, COMMIT_LOG.md, and write handoff.

## Handoff

### What works
- Godot 4.6.3 web build exported cleanly via `tools\export_web.ps1`.
- Project bundles `constants.json`, `facts.json`, and translation CSVs into `index.pck`.
- Local Wi-Fi serving tested and verified on developer's phone over Wi-Fi.
- Scene loaded with Godot engine splash, 3D placeholder geometry, and debug label ("30 days").
- `tools\export_web.ps1` includes automatic post-export patches for single-threaded LAN testing on mobile browsers (bypassing the strict Secure Context check and guarding AudioWorklet before ScriptProcessor fallback).
- `tools\deploy_web.ps1` is prepared and ready for developer use at release (T6-03).

### What to test by hand
- Run `tools\export_web.ps1` and `tools\serve_web.ps1` whenever new 3D assets or scenes are added to check web performance.

### Known issues
- None.

### Ideas for later
- Explore service worker caching when PWA is enabled later in the build.
