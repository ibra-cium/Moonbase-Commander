# T6-01 — Sources, credits and README

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P6 | T5-02 | S | Agent | nasa-data |

## Paste-ready prompt

```text
Run ticket T6-01 (Sources, credits and README). Ticket file: agent-kit/tickets/T6-01-sources-and-credits.md
Goal: Judges can check every number and every asset: sources.md matches the game, credits are complete, README says how to play.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

Judges can check every number and every asset: sources.md matches the game, credits are complete, README says how to play.

## Read first

- `.agent/skills/nasa-data/SKILL.md`
- agent-kit/ART_DIRECTION.md §9

## Tasks

1. `data/sources.md`: make the "Values used in the game" table match `constants.json` exactly (same IDs, values, types). Add rows for any IDs added during the build.
2. README: play link, "How to play" (5 lines), the credits block (ART_DIRECTION §9, plus any extra asset), "Science and NASA data" paragraph pointing to data/sources.md and the in-game Sources screen, "Use of AI" pointing to docs/ai-usage.md and docs/ai-prompts/.
3. README: add a short **Impact** section (5–8 lines) based on `docs/impact.md`: who it is for, what kids learn, how it helps NASA, and the training score. Link to `docs/impact.md`. Do not invent playtest numbers; leave the blanks for the team.
4. Check that `data/sources.md` has the *Facts and Science Cards* table from M-09 and that it matches `facts.json` (29 facts).
5. Check all relative links in README and docs work.

## Done when

- [x] sources.md and constants.json agree (write a quick count check in the handoff).
- [x] README renders on GitHub; links work.

## Verify

- `tools\test.ps1`
- Open README on GitHub.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`docs: complete sources, credits and how to play (T6-01)`

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Clean up UTF-8 characters in `Moonbase-Commander/game/data/constants.json` so chemical subscripts/symbols are clean.
2. Synchronize `Moonbase-Commander/data/sources.md` table "Values used in the game" with `constants.json` (values, units, types for all 172 IDs) and confirm the 29 facts in "Facts and Science Cards" match `facts.json`.
3. Update `Moonbase-Commander/README.md` with: GitHub Pages play link, a 5-line "How to play" section, complete credits block from `ART_DIRECTION.md` §9, "Science and NASA data" references, "Use of AI" references, and a 5–8 line "Impact" section based on `docs/impact.md`.
4. Verify all internal relative links in `README.md` and `docs/`, and verify that `tools\test.ps1` runs clean with exit code 0.

## Handoff

- **What works:**
  - Count check: `data/sources.md` table "Values used in the game" has 172 entries matching `game/data/constants.json` (172 IDs in constants, 172 in sources; 0 missing, 0 extra, 0 value/type/unit mismatches).
  - Facts check: `data/sources.md` table "Facts and Science Cards" has 29 facts matching `game/data/facts.json` (29 IDs in facts, 29 in sources; 0 missing).
  - Mojibake cleanup: `game/data/constants.json` chemical subscripts and symbols cleaned up to standard UTF-8 (`O₂`, `CO₂`, `H₂O`, `−`).
  - README updated with: browser play link (`https://ibra-cium.github.io/Moonbase-Commander/`), 5-line "How to play", credits block matching `ART_DIRECTION.md` §9 + Kenney Sci-Fi UI, "Science and NASA data", "Use of AI", and a 6-bullet "Impact" section based on `docs/impact.md`.
  - Link verification: All 16 relative markdown links across `README.md` and `docs/*.md` verified valid with 0 broken links.
  - Tests: `tools\test.ps1` passes (191 tests passed, 0 failed, exit code 0).
- **What to test by hand:**
  - Check the rendered README on GitHub.
  - The team will fill in the playtest blanks in `README.md` and `docs/impact.md` when playtest numbers are finalized before submission.
- **Known issues:**
  - None.


