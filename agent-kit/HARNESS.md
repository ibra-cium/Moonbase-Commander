# HARNESS — the loop for every ticket

Same steps every time. Do not skip any. If a step fails twice, stop and write what happened in the handoff.

## 1. Pick

- Open `agent-kit/STATUS.md`. Take the ticket the developer named, or else the first `Todo` ticket whose dependencies are `Done`.
- Set it to `Doing` in STATUS.md.
- **PA-01** is guided: the developer downloads, you guide and check folders. You never download.

## 2. Read

- Read the ticket file completely.
- Read only the files in its **Read first** list (plus `ENV.md` for commands).
- If the ticket and a spec disagree, the spec wins; note the conflict in the handoff.

## 3. Plan (write it before coding)

Add a `## Plan` section at the bottom of the ticket file, 3–7 lines:
files you will create or change, the approach, and how you will check it.

## 4. Build

- Small steps. Run the project or the tests after each step.
- Follow `CONVENTIONS.md`. Numbers only via `Constants.v("ID")`.
- Stay inside the ticket. Ideas for later go into the handoff, not the code.

## 5. Verify (all that apply to the ticket)

| Check | How | Pass |
| --- | --- | --- |
| Headless tests | `tools\test.ps1` | Exit code 0, no errors |
| Scenarios | `tools\scenarios.ps1` | Every scenario matches its expected result in `GAME_RULES.md` §10 |
| Scene smoke test | Godot MCP run + debug output, or `& $GODOT --path game` | No errors or warnings in output |
| Web export | `tools\export_web.ps1` | Export finishes, `build/web/index.html` exists |
| Phone check | `/phone-test` (game served on the home Wi-Fi), then ask the developer | Developer says OK |

Never mark a ticket done with a failing check. Never weaken a test to make it pass. If a test is wrong, explain why in the handoff and ask.

## 6. Record (files only)

1. **Prompt record** → create `Moonbase-Commander/docs/ai-prompts/<TICKET-ID>.md` from `agent-kit/templates/ai-prompt-record.md`: the exact prompt the developer pasted, the files changed, and 3–5 lines on what you did.
2. **AI log** → add one row to `Moonbase-Commander/docs/ai-usage.md`:
   `| <date> | Antigravity (<model name>) | Siam Ibrahim | <ticket ID>: <what it did> | See docs/ai-prompts/<TICKET-ID>.md | <data or files it worked on> |`
3. **Status** → set the ticket to `Done` in `agent-kit/STATUS.md` (this file is not committed).
4. **Handoff** → add a `## Handoff` section at the bottom of the ticket: what works, what to test by hand, known issues, ideas for later.
5. **Decisions** → if you made a choice the next ticket needs to know, add one line to `agent-kit/DECISIONS.md`.

## 7. Hand over (no git)

You never commit. The developer commits everything himself when the game is finished.

1. `git status` (read-only) to list what changed. Make sure nothing from `agent-kit/`, `.agent/` or `asset-packs/` is inside `Moonbase-Commander/`.
2. Add a block at the end of `agent-kit/COMMIT_LOG.md`:

```
## <TICKET-ID> — <title> (<date>)
Message: <area>: <what> (<TICKET-ID>)
Files:
- <path>
- <path>
Checks: tests PASS · scenarios PASS · export PASS · phone OK (whatever applied)
```

Commit prefixes for the message: `game:` code and scenes · `data:` constants, sources, facts · `docs:` documentation · `assets:` asset files · `tools:` scripts · `build:` export settings.

## 8. Stop

Tell the developer in 3–5 lines: done or not, what to look at, the next ticket. Wait for the go before the next ticket.
