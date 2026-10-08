# Use of AI

NASA Space Apps asks every team to name each AI tool used in the project, with the prompts and reasoning behind it and the data the AI worked on. We log every use here as we go.

| Date | Tool | Who used it | What it did | Prompt or summary of prompts | Data it worked on |
| --- | --- | --- | --- | --- | --- |
| [date] | Claude (Anthropic) | Siam Ibrahim | Helped plan the game concept and draft this repository's documents | [Paste or summarise the main prompts] | Our own concept notes; the public challenge summary |
| 2026-10-08 | Antigravity (Google DeepMind) | Siam Ibrahim | Organised this repository from our prepared files | See prompt below | The files in this repository |

## What we did ourselves

[Describe which parts of the idea, design, research and writing are the team's own work.]

## Prompt used to organise this repository

```
You are setting up the public GitHub repository for our NASA Space Apps Challenge 2026 project.

## Context
- Project: Moonbase Commander, a browser game where students aged 10–14 run a Moon base for 30 days and learn real mission trade-offs.
- Team: Space-ArenaX (5 members). Challenge: Build a Junior Astronaut Mission Trainer.
- Stage: concept only. The game will be built during the hackathon on 13–14 November 2026. Do NOT write any game code, scripts or project files for an engine now.

## Input
- `moonbase-commander.zip`. It contains a folder `moonbase-commander/` with the full repository content (including the hidden file `.gitignore`).

## Tasks
1. Create a new public GitHub repository named `moonbase-commander` under `ibra-cium`, with no auto-generated files. If the GitHub CLI is available, use: `gh repo create ibra-cium/moonbase-commander --public`. If the repository already exists, clone it instead.
2. Unzip the input and copy everything inside `moonbase-commander/` into the repository root. Keep the folder structure exactly as it is, and make sure `.gitignore` is copied.
3. If the repository already contains a README.md or LICENSE, replace them with ours.
4. Check every Markdown file:
   - every relative link points to a file that exists
   - every table has the same number of columns in each row
   - nothing is broken in the formatting
   Fix only formatting problems. Do not change the wording.
5. Open `docs/ai-usage.md`. In the row for the coding agent, fill in today's date and your tool name, and write "See prompt below" in the prompt column. Then add a new section at the end called `## Prompt used to organise this repository` and paste this full prompt inside a code block. Do not touch the other rows.
6. Commit in small, logical commits with clear messages, for example:
   - `docs: add README, license and contributing guide`
   - `docs: add challenge, concept and timeline`
   - `data: add NASA sources template`
   - `docs: log AI use for repository setup`
   Then push to the `main` branch.
7. Check that the repository is public and that the README renders correctly on GitHub.

## Rules
- No game code, no assets, no images, no engine project files.
- Never invent facts, numbers, names, links or NASA sources.
- Leave every placeholder in square brackets (for example `[YouTube link]`) exactly as it is.
- No NASA logos anywhere.
- No photos, names or voices of anyone under 18.
- No secrets, tokens or `.env` files.

## When you are done, reply with
- the repository URL
- the final folder tree
- every placeholder still left to fill, with the file it is in
- anything you could not do, and why
```
