# T0-01 — Workspace check and repo housekeeping

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P0 | — | S | Agent | — |

## Paste-ready prompt

```text
Run ticket T0-01 (Workspace check and repo housekeeping). Ticket file: agent-kit/tickets/T0-01-workspace-and-repo-housekeeping.md
Goal: Confirm the tools work, then update the public repo so it matches the new plan: building before the event (mentor approved), 3D, Godot 4.6.3, and the team data.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Confirm the tools work, then update the public repo so it matches the new plan: building before the event (mentor approved), 3D, Godot 4.6.3, and the team data.

## Read first

- `AGENTS.md`
- `agent-kit/CONTEXT.md`
- `agent-kit/ENV.md`
- `agent-kit/DECISIONS.md`

## Tasks

1. Ask the developer for the Godot 4.6.3 console exe path. Run `& $GODOT --version`; it must start with `4.6.3`. Write the path into `agent-kit/ENV.md`. Check if Godot MCP tools are available and note yes/no in ENV.md.
2. In `Moonbase-Commander/`: `git status` must be clean on `main`; run `git pull`.
3. Copy from `agent-kit/repo-files/` into the repo (same relative paths): `data/sources.md` (replaces the template), `data/Moonbase_Commander_Final_Data.xlsx`, `docs/ai-prompts/README.md`.
4. `README.md`: change the status line to "In development: we are building the full game from 9 November 2026, with our mentor's approval. Play link: [play link]". Under "Planned tech" write: Godot 4.6.3, 3D low-poly, web export (Compatibility renderer), plays in phone and laptop browsers. In "Repository structure" add `tools/` (helper scripts) and `docs/ai-prompts/` (prompt of every AI coding task). Change nothing else.
5. `CONTRIBUTING.md`: replace the "Before the hackathon" section with: "Our mentor approved building the game before the event, so game code goes in from 9 November 2026." Keep the hackathon and rules sections. Add one rule line: "Every AI coding task saves its prompt in docs/ai-prompts/."
6. `docs/concept.md`: remove "3D" from "Not in this version". Add "3D base view (low-poly), every packed item visible on the base" to "Must have".
7. `game/README.md`: Engine: Godot 4.6.3, 3D, web export. Remove the "chosen on Day 1" text.
8. `.gitignore`: add `tools/godot_path.txt`.
9. `docs/ai-usage.md`: add this row at the end of the table (do not touch other rows): `| 2026-11-09 | Claude (Anthropic) | Siam Ibrahim | Checked our three data tables against the data plan, found values for the gaps (marked AI-found in data/sources.md), turned the data into game values (game/data/constants.json), wrote debrief facts, the game rules and the build plan for the coding agent | Check our data against the plan; fill missing values from NASA sources with links; turn the data into game values; plan the build | Team data sheets; NASA documents linked in data/sources.md |`

## Done when

- [ ] Godot version and path recorded in ENV.md.
- [ ] README, CONTRIBUTING, concept, game/README updated as listed; no other wording changed.
- [ ] data/sources.md filled; xlsx and docs/ai-prompts/README.md in the repo.
- [ ] Nothing else from agent-kit/ in the repo.

## Verify

- `git diff --stat` shows only the files listed above.
- Open README.md preview: tables render, links work.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`docs: update status, tech and sources for the build (T0-01)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Record Godot console exe path (`C:\Godot\Godot_v4.6.3-stable_win64_console.exe`), Godot MCP (yes), and Python 3 (yes) in `agent-kit/ENV.md`.
2. Confirm `Moonbase-Commander/` git status is clean on `main` and run `git pull` (already completed).
3. Copy `data/sources.md`, `data/Moonbase_Commander_Final_Data.xlsx`, and `docs/ai-prompts/README.md` from `agent-kit/repo-files/` to `Moonbase-Commander/`.
4. Update `README.md`, `CONTRIBUTING.md`, `docs/concept.md`, `game/README.md`, `.gitignore`, and `docs/ai-usage.md` in `Moonbase-Commander/` with exact required text.
5. Check with `git diff --stat` and verify table renders and relative links.

## Handoff

- **What works:** Tools verified (Godot 4.6.3 console binary found and tested, export templates confirmed, Godot MCP active, Python 3 available). All repo housekeeping complete and verified with clean git diff matching only expected files.
- **What to test by hand:** Open [Moonbase-Commander/README.md](file:///d:/MOONBASE/Moonbase-Commander/README.md) preview to verify formatting and links.
- **Known issues:** None.
- **Ideas for later:** Ready for T0-02 (Godot project skeleton).
