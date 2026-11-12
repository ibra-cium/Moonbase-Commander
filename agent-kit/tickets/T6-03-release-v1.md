# T6-03 — Release: developer commits, deploys and tags v1.0

| Phase | Depends on | Size | Who | Skills |
| --- | --- | --- | --- | --- |
| P6 | T6-02 | M | Developer + Agent | web-export-mobile |

## Paste-ready prompt

```text
Run ticket T6-03 (Release: developer commits, deploys and tags v1.0). Ticket file: agent-kit/tickets/T6-03-release-v1.md
Goal: The game is finished. The agent prepares everything; the developer commits from his own account, deploys to GitHub Pages and tags v1.0.
Follow agent-kit/HARNESS.md step by step: read the ticket and its Read-first files, write your plan into the ticket, build, run /verify, run /record-ai-use with this exact prompt, add the ticket block to agent-kit/COMMIT_LOG.md. Do NOT run any git command that changes the repo (no add/commit/push). Then stop and report to me.
```

## Goal

The game is finished. The agent prepares everything; the developer commits from his own account, deploys to GitHub Pages and tags v1.0.

## Read first

- `agent-kit/COMMIT_LOG.md`
- .agent/skills/web-export-mobile/SKILL.md (Deploy)
- `agent-kit/CONTEXT.md`

## Tasks

1. Agent: final `tools\test.ps1`, `tools\scenarios.ps1`, `tools\export_web.ps1`. All must pass.
2. Agent: check that `docs/ai-usage.md` has a row for every agent ticket plus the PA-01 "by hand" row, and that every agent ticket has its file in `docs/ai-prompts/`. Fill any gap.
3. Agent: tidy `agent-kit/COMMIT_LOG.md` into a final list in ticket order, each with its message and files, and make sure every changed file in `git status` belongs to one block. Then stop and hand over. No git commands.
4. Developer: commit from `COMMIT_LOG.md` (one commit per ticket or per phase), push to `main`.
5. Developer: run `tools\deploy_web.ps1`; on GitHub set Pages to the `gh-pages` branch (first time only); open the link in a private window on phone and laptop.
6. Developer: README status "v1.0 — playable" + play link, commit; `git tag v1.0` and `git push --tags`.
7. Agent (after the developer confirms the link works): write the capture list in the handoff: cargo and job plan to record the pack screen, Day 15 sunset, storm warning + shelter, recycler sparks, a source tag tap, the debrief and the Sources screen (matches the team's video shot list).

## Done when

- [ ] All changes committed and pushed by the developer; tag v1.0 on GitHub.
- [ ] Live link works in a private window.
- [ ] AI log complete; capture list ready.

## Verify

- Developer: private-window check of the live link.

## Suggested commit message

The agent does not commit. It writes this into `agent-kit/COMMIT_LOG.md` with the changed files; the developer commits at the end.

`(developer) one commit per ticket from COMMIT_LOG.md, then `docs: release v1.0``

<!-- The agent adds ## Plan and ## Handoff below this line -->

## Plan

1. Run the test suite (`tools\test.ps1`), scenario runner (`tools\scenarios.ps1`), and web export (`tools\export_web.ps1`) to verify all automated checks pass cleanly.
2. Verify all AI documentation: confirm every ticket row exists in `docs/ai-usage.md` and has a matching prompt record in `docs/ai-prompts/` (add T6-03 record and usage row).
3. Audit and tidy `agent-kit/COMMIT_LOG.md` in ticket order, ensuring every modified and untracked file from `git status` is accounted for across ticket blocks (including `docs/impact.md` and T6-03).
4. Prepare the final release handoff with step-by-step instructions for the developer to commit, push, run `tools\deploy_web.ps1`, set up GitHub Pages, and tag `v1.0`.
5. Prepare the demo video capture plan (Pack screen, Day 15 sunset, storm warning + shelter, recycler sparks, source tag, debrief, and Sources screen).

## Handoff

- **What works:**
  - Automated tests: 191/191 tests pass (`tools\test.ps1`).
  - Scenarios: 16/16 balance scenarios pass (`tools\scenarios.ps1`).
  - Web release build: generated in `build/web/index.html` (PCK size: 4.96 MB, loads smoothly).
  - AI logs: all 45 tickets accounted for in `docs/ai-usage.md` and `docs/ai-prompts/`.
  - Commit log: `agent-kit/COMMIT_LOG.md` completely audited and tidied into ticket blocks.

- **Developer Release Steps:**
  1. Commit from `agent-kit/COMMIT_LOG.md`:
     - You can commit ticket-by-ticket using the messages and files in `COMMIT_LOG.md`, or stage all and commit by phase / single final release commit.
  2. Push `main` branch to GitHub:
     ```powershell
     cd d:\MOONBASE\Moonbase-Commander
     git push origin main
     ```
  3. Deploy to GitHub Pages:
     ```powershell
     powershell -ExecutionPolicy Bypass -File tools\deploy_web.ps1
     ```
     *(In GitHub repo settings -> Pages, ensure Source is set to "Deploy from a branch" -> `gh-pages` / root).*
  4. Tag v1.0 and push tag:
     ```powershell
     git tag v1.0
     git push origin v1.0
     ```
  5. Check live URL in private window (mobile & desktop):
     `https://ibra-cium.github.io/Moonbase-Commander/`

- **Video Capture Shot List (for Video 2 & Video 3):**
  1. **Pack Screen**:
     - Mission M4: show cargo weight ticker reaching near 15,000 kg cap with 1x FSP Reactor (1,500 kg), 2x Solar, 2x Battery, 1x Recycler, Food & Water.
     - Tap a NASA Source Tag icon on cargo to show the modal citation with link.
  2. **Landing & Daily Operation**:
     - Lander touches down with thruster dust and engine sound.
     - Astronauts hop out; show tap-astronaut -> tap-building assignment and floating collect bubbles.
  3. **Recycler Sparks (M2 or M4 Day 7)**:
     - Water recycler malfunctions: focus camera on sparks particle effect and alarm.
  4. **Solar Storm Warning & Shelter (M3 or M4 Day 9)**:
     - Siren sounds with "The Moon attacks" warning; crew enters water/regolith storm shelter; radiation gauge stays in safe zone.
  5. **Day 15 Sunset & Night (M4 Day 15)**:
     - Smooth orbit camera showing the sun dipping behind the lunar hills, long shadows stretching, directional light fading to night.
     - Base floodlights activate; starfield and Earth stand out; solar generation drops to zero while nuclear reactor sustains life support hum.
  6. **Mission Debrief & Science Cards**:
     - Day 30 victory: 3 gold stars, cause-chain explanation, and learning check ("1/4 -> 4/4").
     - Open Science Cards Album showing collected NASA cards.
     - Open Sources screen showing 172 real data points.


