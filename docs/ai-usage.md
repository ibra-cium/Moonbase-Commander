# Use of AI

NASA Space Apps asks every team to name each AI tool used in the project, with the prompts and reasoning behind it and the data the AI worked on. We log every use here as we go.

| Date | Tool | Who used it | What it did | Prompt or summary of prompts | Data it worked on |
| --- | --- | --- | --- | --- | --- |
| [date] | Claude (Anthropic) | Siam Ibrahim | Helped plan the game concept and draft this repository's documents | [Paste or summarise the main prompts] | Our own concept notes; the public challenge summary |
| 2026-10-08 | Antigravity (Google DeepMind) | Siam Ibrahim | Organised this repository from our prepared files | See prompt below | The files in this repository |
| 2026-11-09 | Claude (Anthropic) | Siam Ibrahim | Checked our three data tables against the data plan, found values for the gaps (marked AI-found in data/sources.md), turned the data into game values (game/data/constants.json), wrote debrief facts, the game rules and the build plan for the coding agent | Check our data against the plan; fill missing values from NASA sources with links; turn the data into game values; plan the build | Team data sheets; NASA documents linked in data/sources.md |
| 2026-11-09 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T0-01: Workspace check and repo housekeeping | See docs/ai-prompts/T0-01.md | Repository docs, .gitignore, data sources |
| 2026-11-09 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T0-02: Godot project skeleton | See docs/ai-prompts/T0-02.md | Project settings, autoload stubs, scenes, i18n CSV |
| 2026-11-09 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T0-03: Test harness and helper scripts | See docs/ai-prompts/T0-03.md | Test runner, test case base class, smoke test, scenario stub, PowerShell tools |
| 2026-11-09 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T0-04: Constants loader and game data | See docs/ai-prompts/T0-04.md | Game constants, facts data, SimConstants, Constants autoload, test suite |
| 2026-11-09 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T0-05: Web export and first phone check over Wi-Fi | See docs/ai-prompts/T0-05.md | Web export presets, web tool scripts, export artifacts |
| 2026-11-09 | — (by hand) | Siam Ibrahim | PA-01: downloaded all asset packs from their official pages | — | KayKit, Quaternius, Kenney, NASA SVS and Earth Observatory, Google Fonts, Material Icons |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | PA-02: copied the files we use into game/assets, resized the Earth map, recoloured icons, set import options | See docs/ai-prompts/PA-02.md | The downloaded asset packs |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T1-01: Cargo catalog and pack maths | See docs/ai-prompts/T1-01.md | `game/sim/sim_cargo.gd`, `game/tests/test_cargo.gd`, `game/data/constants.json` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T1-02: Power system | See docs/ai-prompts/T1-02.md | `game/sim/sim_power.gd`, `game/tests/test_power.gd`, `game/tests/test_case.gd`, `game/data/constants.json` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T1-03: Life support: oxygen, CO2, water, food | See docs/ai-prompts/T1-03.md | `game/sim/sim_life.gd`, `game/tests/test_life.gd`, `game/data/constants.json` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T1-04: Crew, jobs, dust, radiation and sickness | See docs/ai-prompts/T1-04.md | `game/sim/sim_plan.gd`, `game/sim/sim_crew.gd`, `game/tests/test_crew.gd`, `game/data/constants.json` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T1-05: Greenhouse | See docs/ai-prompts/T1-05.md | `game/sim/sim_greenhouse.gd`, `game/tests/test_greenhouse.gd`, `game/data/constants.json` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T1-06: Events schedule and mission log | See docs/ai-prompts/T1-06.md | `game/sim/sim_event.gd`, `game/sim/sim_events.gd`, `game/sim/sim_log.gd`, `game/tests/test_events.gd`, `game/data/constants.json` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T1-07: Mission loop, end checks, stars and debrief + GameState | See docs/ai-prompts/T1-07.md | `game/sim/sim_mission.gd`, `game/sim/sim_day_report.gd`, `game/sim/sim_result.gd`, `game/sim/sim_debrief.gd`, `game/autoload/game_state.gd`, `game/tests/test_mission.gd` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T1-08: Balance scenarios S01–S09 | See docs/ai-prompts/T1-08.md | `game/tests/run_scenarios.gd`, `game/tests/scenarios/*.json`, `game/sim/*.gd`, `game/data/constants.json` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T2-01: Asset check, Moon ground, sky and camera | See docs/ai-prompts/T2-01.md | `game/world/*`, `game/scenes/Main.tscn`, `game/tests/test_world.gd` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T2-02: Base layout and cargo spawner | See docs/ai-prompts/T2-02.md | `game/world/model_catalog.gd`, `game/world/base.gd`, `game/world/Base.tscn`, `game/world/BaseDebug.tscn`, `game/world/base_debug.gd`, `game/world/World.tscn`, `game/tests/test_base.gd` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T2-03: Base reacts to each day | See docs/ai-prompts/T2-03.md | `game/world/base.gd`, `game/world/BaseDebug.tscn`, `game/world/base_debug.gd`, `game/tests/test_base.gd` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T2-04: Code-built hopping astronauts | See docs/ai-prompts/T2-04.md | `game/world/astronaut.gd`, `game/world/Astronaut.tscn`, `game/world/crew.gd`, `game/world/Crew.tscn`, `game/world/Base.tscn`, `game/world/base.gd`, `game/world/BaseDebug.tscn`, `game/world/base_debug.gd`, `game/tests/test_crew.gd` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T2-05: Sun path, Day 15 sunset and night | See docs/ai-prompts/T2-05.md | `game/world/sky_rig.gd`, `game/world/SkyRig.tscn`, `game/world/base.gd`, `game/world/BaseDebug.tscn`, `game/world/base_debug.gd`, `game/tests/test_world.gd` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T2-06: 3D performance pass on the phone | See docs/ai-prompts/T2-06.md | `game/project.godot`, `game/autoload/settings.gd`, `game/world/ground.gd`, `game/world/astronaut.gd`, `game/world/base.gd`, `game/world/base_debug.gd`, `game/world/BaseDebug.tscn` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T3-01: UI theme, widgets and Sources screen | See docs/ai-prompts/T3-01.md | `game/ui/*`, `game/i18n/strings.csv`, `game/autoload/constants.gd`, `game/project.godot`, `game/tests/test_ui_widgets.gd`, `tools/build_theme.gd` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T3-02: Title screen with NASA Moon globe | See docs/ai-prompts/T3-02.md | `game/ui/TitleScreen.tscn`, `game/ui/title_screen.gd`, `game/scenes/Main.tscn`, `game/scenes/main.gd`, `game/i18n/strings.csv`, `game/tests/test_title_screen.gd` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T3-03: Pack screen | See docs/ai-prompts/T3-03.md | `game/ui/PackItemCard.tscn`, `game/ui/pack_item_card.gd`, `game/ui/PackScreen.tscn`, `game/ui/pack_screen.gd`, `game/scenes/Main.tscn`, `game/scenes/main.gd`, `game/autoload/game_state.gd`, `game/i18n/strings.csv`, `game/tests/test_pack_screen.gd` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T3-04: Landing and the day loop | See docs/ai-prompts/T3-04.md | `game/autoload/settings.gd`, `game/autoload/game_state.gd`, `game/world/lander.gd`, `game/world/Lander.tscn`, `game/world/World.tscn`, `game/ui/DayHud.tscn`, `game/ui/day_hud.gd`, `game/ui/DebriefScreen.tscn`, `game/ui/debrief_screen.gd`, `game/scenes/Main.tscn`, `game/scenes/main.gd`, `game/i18n/strings.csv`, `game/tests/test_day_loop.gd` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T3-05: Day HUD: gauges, crew jobs, power switches | See docs/ai-prompts/T3-05.md | `game/ui/CrewCard.tscn`, `game/ui/crew_card.gd`, `game/ui/DayHud.tscn`, `game/ui/day_hud.gd`, `game/scenes/main.gd`, `game/i18n/strings.csv`, `game/tests/test_day_loop.gd` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T3-06: Debrief: stars, cause chain, fact, retry | See docs/ai-prompts/T3-06.md | `game/ui/DebriefScreen.tscn`, `game/ui/debrief_screen.gd`, `game/scenes/main.gd`, `game/i18n/strings.csv`, `game/tests/test_day_loop.gd` |
| 2026-11-10 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T4-01: Event effects | See docs/ai-prompts/T4-01.md | `game/world/Effects.tscn`, `game/world/effects.gd`, `game/world/World.tscn`, `game/world/world.gd`, `game/world/base.gd`, `game/tests/test_event_effects.gd`, `game/tests/run_tests.gd` |
| 2026-11-11 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T4-02: Evacuation lift-off and success ending | See docs/ai-prompts/T4-02.md | `game/world/lander.gd`, `game/world/crew.gd`, `game/world/sky_rig.gd`, `game/world/camera_rig.gd`, `game/ui/EndingOverlay.tscn`, `game/ui/ending_overlay.gd`, `game/scenes/Main.tscn`, `game/scenes/main.gd`, `game/i18n/strings.csv`, `game/tests/test_mission_endings.gd` |
| 2026-11-11 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T4-03: Audio (life-support hum, alarms, UI sounds with Kenney Sci-Fi & Interface packs) | See docs/ai-prompts/T4-03.md | `game/autoload/audio.gd`, `game/autoload/settings.gd`, `game/project.godot`, `game/scenes/main.gd`, `game/world/effects.gd`, `game/world/lander.gd`, `game/ui/TitleScreen.tscn`, `game/ui/title_screen.gd`, `game/ui/DayHud.tscn`, `game/ui/day_hud.gd`, `game/ui/pack_screen.gd`, `game/ui/pack_item_card.gd`, `game/ui/crew_card.gd`, `game/ui/sources_screen.gd`, `game/ui/source_tag.gd`, `game/ui/event_popup.gd`, `game/ui/ending_overlay.gd`, `game/ui/debrief_screen.gd`, `game/i18n/strings.csv`, `game/tests/test_audio.gd` |
| 2026-11-11 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T4-04: First-run tutorial and hints | See docs/ai-prompts/T4-04.md | `game/autoload/settings.gd`, `game/ui/TutorialOverlay.tscn`, `game/ui/tutorial_overlay.gd`, `game/i18n/strings.csv`, `game/scenes/Main.tscn`, `game/scenes/main.gd`, `game/tests/test_onboarding.gd` |
| 2026-11-11 | Antigravity (Claude Sonnet 4.6, Gemini 3.8 Flash) | Siam Ibrahim | M-01: Mission map and four missions | See docs/ai-prompts/M-01.md | `game/data/constants.json`, `game/data/missions.json`, `data/sources.md`, `game/sim/*.gd`, `game/autoload/settings.gd`, `game/scenes/main.gd`, `game/ui/*.gd`, `game/i18n/strings.csv`, `game/tests/*` |
| 2026-11-11 | Antigravity (Google DeepMind) | Siam Ibrahim | M-02: Named crew, speech bubbles and less tapping | See docs/ai-prompts/M-02.md | `game/i18n/strings.csv`, `game/world/*`, `game/ui/*`, `game/scenes/main.gd`, `game/tests/test_crew_voice.gd`, `game/tests/test_day_loop.gd` |
| 2026-11-11 | Antigravity (Google DeepMind) | Siam Ibrahim | M-03: Tap-to-collect bubbles and resource bar | See docs/ai-prompts/M-03.md | `game/i18n/strings.csv`, `game/autoload/settings.gd`, `game/world/base.gd`, `game/ui/*`, `game/scenes/main.gd`, `game/tests/test_collect.gd` |
| 2026-11-11 | Antigravity (Google DeepMind) | Siam Ibrahim | M-04: Moon event alerts with countdown and result cards | See docs/ai-prompts/M-04.md | `game/i18n/strings.csv`, `game/ui/EventPopup.tscn`, `game/ui/event_popup.gd`, `game/ui/day_hud.gd`, `game/scenes/main.gd`, `game/tests/test_alerts.gd`, `game/tests/test_crew_voice.gd` |
| 2026-11-11 | Antigravity (Google DeepMind) | Siam Ibrahim | M-05: Tap an astronaut, then tap a building (plus phone web BG, SVG/glyph, and LAN audio fixes) | See docs/ai-prompts/M-05.md | `game/i18n/strings.csv`, `game/world/*`, `game/ui/*`, `game/scenes/main.gd`, `tools/export_web.ps1`, `game/tests/test_tap_assign.gd`, `game/tests/test_missions.gd`, `game/tests/test_ui_widgets.gd` |
| 2026-11-11 | Antigravity (Google DeepMind) | Siam Ibrahim | T5-01: English / Bangla toggle across all screens, Bangla CSV + facts fill | See docs/ai-prompts/T5-01.md | `game/i18n/strings.csv`, `game/i18n/*.translation`, `game/data/facts.json`, `game/ui/*`, `game/world/Astronaut.tscn`, `game/world/SpeechBubble.tscn`, `game/world/speech_bubble.gd`, `game/tests/test_i18n.gd` |
| 2026-11-11 | Antigravity (Google DeepMind) | Siam Ibrahim | T5-02: Phone polish, custom web loading shell, landscape hint, touch/safe-area fixes, PCK size trim, LAN server fix | See docs/ai-prompts/T5-02.md | `game/web/shell.html`, `game/export_presets.cfg`, `game/project.godot`, `game/autoload/settings.gd`, `game/world/camera_rig.gd`, `game/ui/*`, `game/tests/test_phone_polish.gd`, `tools/serve.py`, `tools/serve_web.ps1` |
| 2026-11-12 | Antigravity (Google DeepMind) | Siam Ibrahim | M-06: Crew energy pips, overwork sickness, REST refill, tired warnings/hints/voice, and S10_overwork scenario | See docs/ai-prompts/M-06.md | `game/data/constants.json`, `data/sources.md`, `game/i18n/strings.csv`, `game/sim/*`, `game/ui/*`, `game/world/speech_bubble.gd`, `game/scenes/main.gd`, `game/autoload/settings.gd`, `game/tests/*` |
| 2026-11-12 | Antigravity (Google DeepMind) | Siam Ibrahim | M-08: Junior astronaut training briefings, guess-first questions, debrief learning steps, ranks, results copy, and certificate | See docs/ai-prompts/M-08.md | `game/data/learning.json`, `game/data/facts.json`, `game/data/constants.json`, `game/i18n/strings.csv`, `game/autoload/settings.gd`, `game/ui/*`, `game/scenes/*`, `game/tests/*` |
| 2026-11-12 | Antigravity (Google DeepMind) | Siam Ibrahim | M-09: Moon Science Cards triggers, toast & quiet-day chip, CardView, CardAlbum, debrief/certificate cards, Sources Facts filter, and sources.md table | See docs/ai-prompts/M-09.md | `data/sources.md`, `game/i18n/strings.csv`, `game/autoload/settings.gd`, `game/ui/*`, `game/world/speech_bubble.gd`, `game/scenes/main.gd`, `game/tests/*` |
| 2026-11-12 | Antigravity (Google DeepMind) | Siam Ibrahim | M-07: Kid gauges, advice tip bubble with Show me action, science numbers toggle, science card onboarding, and first card pickup guidance | See docs/ai-prompts/M-07.md | `game/i18n/strings.csv`, `game/autoload/settings.gd`, `game/sim/*`, `game/ui/*`, `game/scenes/main.gd`, `game/tests/*` |
| 2026-11-12 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T6-01: Sources, credits and README | See docs/ai-prompts/T6-01.md | `data/sources.md`, `README.md`, `game/data/constants.json` |
| 2026-11-12 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T6-02: Final QA playthrough, console error fixes, web build export | See docs/ai-prompts/T6-02.md | `game/world/effects.gd`, `game/world/lander.gd`, `tools/export_web.ps1` |
| 2026-11-12 | Antigravity (Gemini 3.8 Flash) | Siam Ibrahim | T6-03: Release preparation, AI documentation sync, commit log audit, web build verification | See docs/ai-prompts/T6-03.md | `agent-kit/COMMIT_LOG.md`, `agent-kit/STATUS.md`, `docs/ai-usage.md`, `docs/ai-prompts/*`, `tools/*` |



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
