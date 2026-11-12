# Moonbase Commander — agent kit (for Siam)

Everything your coding agent needs to build the game, ticket by ticket. **This kit is never committed, and the agent never commits.** It writes the game, the data and one prompt file per ticket into the repo folder; you commit it all yourself when the game is finished (ticket T6-03), using `COMMIT_LOG.md`.

## 1. Set up the workspace (once)

```
1. Unzip Moonbase-Agent-Kit.zip. You get a folder Moonbase\ (with AGENTS.md, .agent\, agent-kit\, asset-packs\).
   Put it where you like, e.g. D:\Projects\Moonbase\
2. Clone the repo inside it:   cd D:\Projects\Moonbase
                               git clone https://github.com/ibra-cium/Moonbase-Commander.git
3. Open the Moonbase\ folder (not the repo folder) in Antigravity. Connect Godot MCP.
4. Paste agent-kit\START_PROMPT.md.
```

Result:

```
Moonbase\
├── AGENTS.md
├── .agent\              rules, workflows (/run-ticket, /verify, /record-ai-use, /phone-test), 7 skills
├── agent-kit\           this kit
├── asset-packs\         your downloads (phase PA)
└── Moonbase-Commander\  the repo
```

The deploy script later adds `gh-pages-worktree\` here (the web build branch). It is not part of the main repo.

If your Antigravity version does not pick up `.agent\` automatically, nothing breaks: `AGENTS.md` and every ticket list the files to read by path.

## 2. Every ticket

1. Open `agent-kit\STATUS.md`, find the next `Todo`.
2. Open the ticket file, copy the **Paste-ready prompt**, paste it into Antigravity.
3. The agent plans, builds, tests, saves the prompt record to `docs\ai-prompts\`, adds a row to `docs\ai-usage.md`, writes the ticket's commit message and file list into `agent-kit\COMMIT_LOG.md`, and stops. **It never commits.**
4. You look at it (run the game, phone check when asked), then paste the next prompt.

If the agent gets something wrong, tell it what to fix in plain words in the same chat. Big change of direction → add a line to `agent-kit\DECISIONS.md` first.

## 3. Order and timing

| Phase | When | You do |
| --- | --- | --- |
| P0 Setup (T0-01…05) | 9 Nov evening | Give the Godot path, phone check over Wi-Fi |
| PA Assets (PA-01…02) | after T0-02 | PA-01: download each pack where the agent tells you. PA-02: the agent organizes, imports and fixes; you approve the sounds |
| P1 Simulation (T1-01…08) | 10 Nov | Review test results |
| P2 3D base (T2-01…06) | 10–11 Nov | Phone checks |
| P3 Game loop and UI (T3-01…06) | 11 Nov | Play it |
| P4 Events and feel (T4-01…04) | 12 Nov morning | Watch one person play |
| P5 Bangla and phone (T5-01…02) | 12 Nov | Get Samia's Bangla text in |
| P6 Ship (T6-01…03) | 12 Nov night | Final checks, **commit everything from COMMIT_LOG.md, deploy, tag v1.0**, record video shots on 13 Nov |

Teammate tasks (Bangla text, fact checks, source checks) are in `TEAM_TASKS.md`. Send it to them.

## 4. What is in here

| File | What |
| --- | --- |
| `CONTEXT.md` | Project, audience, scope, hard rules |
| `HARNESS.md` | The loop for every ticket |
| `ENV.md` | Godot path, commands, MCP |
| `ARCHITECTURE.md` | How the Godot project is built |
| `GAME_RULES.md` | The full simulation spec with every formula |
| `ART_DIRECTION.md` | Palette, item → model map, effects, UI look (from our asset list) |
| `CONVENTIONS.md` | Code and commit style |
| `ASSET_IMPORT_GUIDE.md` | Part A: where you download each pack · Part B: how the agent organizes and imports them |
| `DECISIONS.md` | Choices already made |
| `STATUS.md` | Ticket board |
| `COMMIT_LOG.md` | Commit message + files for every finished ticket, for your commits at the end |
| `phases\`, `tickets\` | The plan |
| `reference\sim_prototype.py` | Python version of the rules; proves the scenario results |
| `repo-files\` | Files the first tickets copy into the repo (constants.json, facts.json, sources.md, the data sheet) |
| `templates\` | Ticket and prompt-record templates |

## 5. The numbers

`repo-files\game\data\constants.json` holds every game number (166 values), each with its unit, type and source. *NASA value* and *Derived* come from the team's data sheet. *Game setting* and *Game assumption* are design choices (unit sizes, CO2 rise speed, regolith speed, event timing, greenhouse mass). The Sources screen shows the type of every number, so the game stays honest.
