# COMMIT_LOG

The agent adds one block per finished ticket. When the game is finished, the developer commits from this list (one commit per ticket, or per phase). This file stays in the kit and is never committed.

<!-- blocks below -->

## T0-01 — Workspace check and repo housekeeping (2026-11-09)
Message: docs: update status, tech and sources for the build (T0-01)
Files:
- .gitignore
- CONTRIBUTING.md
- README.md
- data/sources.md
- data/Moonbase_Commander_Final_Data.xlsx
- docs/ai-prompts/README.md
- docs/ai-prompts/T0-01.md
- docs/ai-usage.md
- docs/concept.md
- game/README.md
Checks: tools verified · git diff clean · links and tables render PASS

## T0-02 — Godot project skeleton (2026-11-09)
Message: game: create Godot 4.6.3 project skeleton (T0-02)
Files:
- docs/ai-prompts/T0-02.md
- docs/ai-usage.md
- game/project.godot
- game/icon.svg
- game/icon.svg.import
- game/autoload/constants.gd
- game/autoload/settings.gd
- game/autoload/game_state.gd
- game/i18n/strings.csv
- game/i18n/strings.csv.import
- game/i18n/strings.en.translation
- game/i18n/strings.bn.translation
- game/scenes/Main.tscn
- game/scenes/main.gd
- game/assets/audio/.gitkeep
- game/assets/fonts/.gitkeep
- game/assets/icons/.gitkeep
- game/assets/models/.gitkeep
- game/assets/particles/.gitkeep
- game/assets/textures/.gitkeep
- game/data/.gitkeep
- game/sim/.gitkeep
- game/tests/.gitkeep
- game/ui/.gitkeep
- game/world/.gitkeep
Checks: import PASS · headless run PASS · rendering run PASS · Godot MCP debug output PASS

## T0-03 — Test harness and helper scripts (2026-11-09)
Message: tools: add headless test runner and helper scripts (T0-03)
Files:
- docs/ai-prompts/T0-03.md
- docs/ai-usage.md
- game/tests/run_tests.gd
- game/tests/test_case.gd
- game/tests/test_smoke.gd
- game/tests/run_scenarios.gd
- game/tests/scenarios/.gitkeep
- tools/test.ps1
- tools/scenarios.ps1
Checks: tests PASS · failure detection PASS · scenarios stub PASS

## T0-04 — Constants loader and game data (2026-11-09)
Message: data: add game constants, facts and the Constants loader (T0-04)
Files:
- docs/ai-prompts/T0-04.md
- docs/ai-usage.md
- game/autoload/constants.gd
- game/data/constants.json
- game/data/facts.json
- game/scenes/Main.tscn
- game/scenes/main.gd
- game/sim/sim_constants.gd
- game/tests/test_case.gd
- game/tests/test_constants.gd
Checks: tests PASS · invalid constant detection PASS · MCP debug output PASS ("30 days")

## T0-05 — Web export and first phone check over Wi-Fi (2026-11-09)
Message: build: add web export preset and web scripts (T0-05)
Files:
- docs/ai-prompts/T0-05.md
- docs/ai-usage.md
- game/export_presets.cfg
- tools/export_web.ps1
- tools/serve.py
- tools/serve_web.ps1
- tools/deploy_web.ps1
Checks: export PASS · tests PASS · scenarios PASS · phone OK

## PA-02 — Organize and import the assets (2026-11-10)
Message: assets: add KayKit, Quaternius, Kenney, NASA maps, fonts and icons (PA-02)
Files:
- docs/ai-prompts/PA-02.md
- docs/ai-usage.md
- tools/resize_image.gd
- game/assets/audio/
- game/assets/fonts/
- game/assets/icons/
- game/assets/models/
- game/assets/nasa3d/
- game/assets/particles/
- game/assets/textures/
- game/assets/ui/
Checks: import PASS · tests PASS · scenarios PASS · models budget PASS (0.87 MB < 5 MB) · smoke test scene PASS

## T1-01 — Cargo catalog and pack maths (2026-11-10)
Message: game: add cargo catalog and pack maths (T1-01)
Files:
- docs/ai-prompts/T1-01.md
- docs/ai-usage.md
- game/sim/sim_cargo.gd
- game/tests/test_cargo.gd
Checks: import PASS · tests PASS (13/13) · scenarios PASS

## T1-02 — Power system (2026-11-10)
Message: game: add power simulation (T1-02)
Files:
- docs/ai-prompts/T1-02.md
- docs/ai-usage.md
- game/sim/sim_power.gd
- game/tests/test_case.gd
- game/tests/test_power.gd
Checks: import PASS · tests PASS (22/22) · scenarios PASS

## T1-03 — Life support: oxygen, CO2, water, food (2026-11-10)
Message: game: add life support simulation (T1-03)
Files:
- docs/ai-prompts/T1-03.md
- docs/ai-usage.md
- game/sim/sim_life.gd
- game/tests/test_life.gd
Checks: import PASS · tests PASS (34/34)

## T1-04 — Crew, jobs, dust, radiation and sickness (2026-11-10)
Message: game: add crew, jobs and radiation dose (T1-04)
Files:
- docs/ai-prompts/T1-04.md
- docs/ai-usage.md
- game/sim/sim_plan.gd
- game/sim/sim_crew.gd
- game/tests/test_crew.gd
Checks: import PASS · tests PASS (45/45)

## T1-05 — Greenhouse (2026-11-10)
Message: game: add greenhouse simulation (T1-05)
Files:
- docs/ai-prompts/T1-05.md
- docs/ai-usage.md
- game/sim/sim_greenhouse.gd
- game/tests/test_greenhouse.gd
Checks: import PASS · tests PASS (52/52)

## T1-06 — Events schedule and mission log (2026-11-10)
Message: game: add event schedule and mission log (T1-06)
Files:
- docs/ai-prompts/T1-06.md
- docs/ai-usage.md
- game/sim/sim_event.gd
- game/sim/sim_events.gd
- game/sim/sim_log.gd
- game/tests/test_events.gd
Checks: tests PASS (61/61)

## T1-07 — Mission loop, end checks, stars and debrief + GameState (2026-11-10)
Message: game: add mission loop, debrief and GameState (T1-07)
Files:
- docs/ai-prompts/T1-07.md
- docs/ai-usage.md
- game/sim/sim_day_report.gd
- game/sim/sim_result.gd
- game/sim/sim_debrief.gd
- game/sim/sim_mission.gd
- game/autoload/game_state.gd
- game/tests/test_mission.gd
Checks: tests PASS (66/66) · scenarios PASS

## T1-08 — Balance scenarios S01–S09 (2026-11-10)
Message: game: add balance scenarios S01-S09 (T1-08)
Files:
- docs/ai-prompts/T1-08.md
- docs/ai-usage.md
- game/tests/run_scenarios.gd
- game/tests/scenarios/S01_solar_only.json
- game/tests/scenarios/S02_two_reactors.json
- game/tests/scenarios/S03_one_reactor.json
- game/tests/scenarios/S04_max_batteries.json
- game/tests/scenarios/S05_no_shield.json
- game/tests/scenarios/S06_recycler_not_fixed.json
- game/tests/scenarios/S07_three_stars.json
- game/tests/scenarios/S08_overweight.json
- game/tests/scenarios/S09_recycler_fixed.json
Checks: tests PASS (66/66) · scenarios PASS (9/9)

## T2-01 — Asset check, Moon ground, sky and camera (2026-11-10)
Message: game: add Moon ground, sky and orbit camera (T2-01)
Files:
- docs/ai-prompts/T2-01.md
- docs/ai-usage.md
- game/autoload/constants.gd
- game/scenes/Main.tscn
- game/world/world.gd
- game/world/World.tscn
- game/world/sky_rig.gd
- game/world/SkyRig.tscn
- game/world/camera_rig.gd
- game/world/CameraRig.tscn
- game/world/ground.gd
- game/world/rocks.gd
- game/tests/test_world.gd
Checks: tests PASS (71/71) · scenarios PASS (9/9) · MCP run PASS · export PASS · phone check ready

## T2-02 — Base layout and cargo spawner (2026-11-10)
Message: game: add base layout and cargo spawner (T2-02)
Files:
- docs/ai-prompts/T2-02.md
- docs/ai-usage.md
- game/world/model_catalog.gd
- game/world/base.gd
- game/world/Base.tscn
- game/world/BaseDebug.tscn
- game/world/base_debug.gd
- game/world/World.tscn
- game/tests/test_base.gd
Checks: tests PASS (76/76) · scenarios PASS (9/9) · MCP run PASS (draw calls: ~160) · export PASS

## T2-03 — Base reacts to each day (2026-11-10)
Message: game: base visuals follow the simulation (T2-03)
Files:
- docs/ai-prompts/T2-03.md
- docs/ai-usage.md
- game/world/base.gd
- game/world/base_debug.gd
- game/world/BaseDebug.tscn
- game/tests/test_base.gd
Checks: tests PASS (83/83) · scenarios PASS (9/9) · smoke run PASS · export PASS

## T2-04 — Code-built hopping astronauts (2026-11-10)
Message: game: add hopping astronauts (T2-04)
Files:
- docs/ai-prompts/T2-04.md
- docs/ai-usage.md
- game/world/astronaut.gd
- game/world/Astronaut.tscn
- game/world/crew.gd
- game/world/Crew.tscn
- game/world/base.gd
- game/world/Base.tscn
- game/world/World.tscn
- game/world/BaseDebug.tscn
- game/world/base_debug.gd
- game/tests/test_crew.gd
Checks: tests PASS (80/80) · scenarios PASS (9/9) · MCP run PASS · export PASS

## T2-05 — Sun path, Day 15 sunset and night (2026-11-10)
Message: game: add day-night cycle and sunset (T2-05)
Files:
- docs/ai-prompts/T2-05.md
- docs/ai-usage.md
- game/world/sky_rig.gd
- game/world/SkyRig.tscn
- game/world/base.gd
- game/world/BaseDebug.tscn
- game/world/base_debug.gd
- game/tests/test_world.gd
Checks: tests PASS (83/83) · scenarios PASS (9/9) · export PASS · smoke run PASS

## T2-06 — 3D performance pass on the phone (2026-11-10)
Message: game: tune 3D performance for phones (T2-06)
Files:
- docs/ai-prompts/T2-06.md
- docs/ai-usage.md
- game/project.godot
- game/autoload/settings.gd
- game/world/ground.gd
- game/world/astronaut.gd
- game/world/base.gd
- game/world/base_debug.gd
- game/world/BaseDebug.tscn
Checks: tests PASS (83/83) · scenarios PASS (9/9) · export PASS · phone check

## T3-01 — UI theme, widgets and Sources screen (2026-11-10)
Message: game: add UI theme, widgets and sources screen (T3-01)
Files:
- docs/ai-prompts/T3-01.md
- docs/ai-usage.md
- game/project.godot
- game/autoload/constants.gd
- game/i18n/strings.csv
- game/ui/Theme.tres
- game/ui/font_regular.tres
- game/ui/font_bold.tres
- game/ui/ui_colors.gd
- game/ui/SourceTag.tscn
- game/ui/source_tag.gd
- game/ui/Gauge.tscn
- game/ui/gauge.gd
- game/ui/EventPopup.tscn
- game/ui/event_popup.gd
- game/ui/SourcesScreen.tscn
- game/ui/sources_screen.gd
- game/ui/TestUI.tscn
- game/ui/test_ui.gd
- game/tests/test_ui_widgets.gd
- tools/build_theme.gd
Checks: tests PASS (87/87) · scenarios PASS (9/9) · MCP smoke run PASS · export PASS

## T3-02 — Title screen with NASA Moon globe (2026-11-10)
Message: game: add title screen with NASA Moon globe (T3-02)
Files:
- docs/ai-prompts/T3-02.md
- docs/ai-usage.md
- game/i18n/strings.csv
- game/ui/TitleScreen.tscn
- game/ui/title_screen.gd
- game/scenes/Main.tscn
- game/scenes/main.gd
- game/tests/test_title_screen.gd
Checks: tests PASS (91/91) · scenarios PASS (9/9) · MCP smoke run PASS · export PASS

## T3-03 — Pack screen (2026-11-10)
Message: game: add pack screen (T3-03)
Files:
- docs/ai-prompts/T3-03.md
- docs/ai-usage.md
- game/i18n/strings.csv
- game/autoload/game_state.gd
- game/ui/PackItemCard.tscn
- game/ui/pack_item_card.gd
- game/ui/PackScreen.tscn
- game/ui/pack_screen.gd
- game/scenes/Main.tscn
- game/scenes/main.gd
- game/tests/test_pack_screen.gd
Checks: tests PASS (98/98) · scenarios PASS (9/9) · MCP smoke run PASS · export PASS

## T3-04 — Landing and the day loop (2026-11-10)
Message: game: add landing and the day loop (T3-04)
Files:
- docs/ai-prompts/T3-04.md
- docs/ai-usage.md
- game/autoload/settings.gd
- game/autoload/game_state.gd
- game/world/sky_rig.gd
- game/world/crew.gd
- game/world/base.gd
- game/world/Lander.tscn
- game/world/lander.gd
- game/world/World.tscn
- game/world/world.gd
- game/ui/DayHud.tscn
- game/ui/day_hud.gd
- game/ui/DebriefScreen.tscn
- game/ui/debrief_screen.gd
- game/ui/event_popup.gd
- game/scenes/Main.tscn
- game/scenes/main.gd
- game/i18n/strings.csv
- game/tests/test_day_loop.gd
Checks: tests PASS (104/104) · scenarios PASS (9/9)

## T3-05 — Day HUD: gauges, crew jobs, power switches (2026-11-10)
Message: game: add day HUD with gauges and crew jobs (T3-05)
Files:
- docs/ai-prompts/T3-05.md
- docs/ai-usage.md
- game/i18n/strings.csv
- game/ui/SourceTag.tscn
- game/ui/Gauge.tscn
- game/ui/gauge.gd
- game/ui/CrewCard.tscn
- game/ui/crew_card.gd
- game/ui/DayHud.tscn
- game/ui/day_hud.gd
- game/scenes/main.gd
- game/tests/test_day_loop.gd
Checks: tests PASS (106/106) · scenarios PASS (9/9) · export PASS

## T3-06 — Debrief: stars, cause chain, fact, retry (2026-11-10)
Message: game: add debrief screen (T3-06)
Files:
- docs/ai-prompts/T3-06.md
- docs/ai-usage.md
- game/i18n/strings.csv
- game/ui/DebriefScreen.tscn
- game/ui/debrief_screen.gd
- game/scenes/main.gd
- game/tests/test_day_loop.gd
Checks: tests PASS (109/109) · scenarios PASS (9/9) · export PASS

## T4-01 — Event effects (2026-11-10)
Message: game: add event effects (T4-01)
Files:
- docs/ai-prompts/T4-01.md
- docs/ai-usage.md
- game/world/effects.gd
- game/world/Effects.tscn
- game/world/World.tscn
- game/world/world.gd
- game/world/base.gd
- game/tests/test_event_effects.gd
- game/tests/run_tests.gd
Checks: tests PASS (115/115) · scenarios PASS (9/9) · export PASS

## T4-02 — Evacuation lift-off and success ending (2026-11-11)
Message: game: add mission ending sequences (T4-02)
Files:
- docs/ai-prompts/T4-02.md
- docs/ai-usage.md
- game/i18n/strings.csv
- game/world/lander.gd
- game/world/crew.gd
- game/world/sky_rig.gd
- game/world/camera_rig.gd
- game/ui/EndingOverlay.tscn
- game/ui/ending_overlay.gd
- game/scenes/Main.tscn
- game/scenes/main.gd
- game/tests/test_mission_endings.gd
- game/tests/test_day_loop.gd
Checks: tests PASS (121/121) · scenarios PASS (9/9) · export PASS

## T4-03 — Audio: life-support hum, alarms, UI sounds (2026-11-11)
Message: game: add audio (T4-03)
Files:
- docs/ai-prompts/T4-03.md
- docs/ai-usage.md
- game/autoload/audio.gd
- game/autoload/settings.gd
- game/project.godot
- game/scenes/main.gd
- game/world/effects.gd
- game/world/lander.gd
- game/ui/TitleScreen.tscn
- game/ui/title_screen.gd
- game/ui/DayHud.tscn
- game/ui/day_hud.gd
- game/ui/pack_screen.gd
- game/ui/pack_item_card.gd
- game/ui/crew_card.gd
- game/ui/sources_screen.gd
- game/ui/source_tag.gd
- game/ui/event_popup.gd
- game/ui/ending_overlay.gd
- game/ui/debrief_screen.gd
- game/i18n/strings.csv
- game/tests/test_audio.gd
Checks: tests PASS (126/126) · scenarios PASS (9/9) · export PASS

## T4-04 — First-run tutorial and hints (2026-11-11)
Message: game: add tutorial and hints (T4-04)
Files:
- docs/ai-prompts/T4-04.md
- docs/ai-usage.md
- game/autoload/settings.gd
- game/i18n/strings.csv
- game/scenes/Main.tscn
- game/scenes/main.gd
- game/tests/test_onboarding.gd
- game/ui/TutorialOverlay.tscn
- game/ui/tutorial_overlay.gd
Checks: tests PASS (131/131) · scenarios PASS (9/9) · export PASS

## M-01 — Mission map and four missions (2026-11-11)
Message: game: add mission map and four missions (M-01)
Files:
- data/sources.md
- docs/ai-prompts/M-01.md
- docs/ai-usage.md
- game/assets/icons/lock.svg
- game/assets/icons/lock.svg.import
- game/autoload/settings.gd
- game/data/constants.json
- game/data/missions.json
- game/i18n/strings.csv
- game/i18n/strings.csv.import
- game/i18n/strings.en.translation
- game/i18n/strings.bn.translation
- game/scenes/Main.tscn
- game/scenes/main.gd
- game/sim/sim_constants.gd
- game/sim/sim_debrief.gd
- game/sim/sim_mission.gd
- game/sim/sim_missions.gd
- game/sim/sim_missions.gd.uid
- game/sim/sim_result.gd
- game/tests/run_scenarios.gd
- game/tests/scenarios/M1_basic.json
- game/tests/scenarios/M1_no_food.json
- game/tests/scenarios/M2_no_repair.json
- game/tests/scenarios/M2_repaired.json
- game/tests/scenarios/M3_no_shield.json
- game/tests/scenarios/M3_regolith.json
- game/tests/test_constants.gd
- game/tests/test_day_loop.gd
- game/tests/test_missions.gd
- game/tests/test_missions.gd.uid
- game/tests/test_onboarding.gd
- game/ui/DebriefScreen.tscn
- game/ui/MissionMap.tscn
- game/ui/day_hud.gd
- game/ui/debrief_screen.gd
- game/ui/mission_map.gd
- game/ui/mission_map.gd.uid
- game/ui/pack_item_card.gd
- game/ui/pack_screen.gd
- game/ui/tutorial_overlay.gd
Checks: tests PASS (136/136) · scenarios PASS (15/15) · MCP run PASS (0 errors) · export PASS (phone check pending /phone-test)

## M-02 — Named crew, speech bubbles and less tapping (2026-11-11)
Message: game: add named crew and speech bubbles (M-02)
Files:
- docs/ai-prompts/M-02.md
- docs/ai-usage.md
- game/i18n/strings.csv
- game/i18n/strings.csv.import
- game/i18n/strings.en.translation
- game/i18n/strings.bn.translation
- game/scenes/main.gd
- game/tests/test_crew_voice.gd
- game/tests/test_crew_voice.gd.uid
- game/tests/test_day_loop.gd
- game/ui/CrewCard.tscn
- game/ui/DayHud.tscn
- game/ui/crew_card.gd
- game/ui/day_hud.gd
- game/world/Astronaut.tscn
- game/world/SpeechBubble.tscn
- game/world/astronaut.gd
- game/world/crew.gd
- game/world/speech_bubble.gd
- game/world/speech_bubble.gd.uid
Checks: tests PASS (140/140) · scenarios PASS (15/15) · MCP run PASS (0 errors) · M2/M4 visual captures PASS · export PASS (phone check pending /phone-test)

## M-03 — Tap-to-collect bubbles and resource bar (2026-11-11)
Message: game: add tap-to-collect bubbles and resource bar (M-03)
Files:
- docs/ai-prompts/M-03.md
- docs/ai-usage.md
- game/autoload/settings.gd
- game/i18n/strings.bn.translation
- game/i18n/strings.csv
- game/i18n/strings.en.translation
- game/scenes/main.gd
- game/tests/test_collect.gd
- game/tests/test_collect.gd.uid
- game/ui/CollectBubble.tscn
- game/ui/DayHud.tscn
- game/ui/Gauge.tscn
- game/ui/collect_bubble.gd
- game/ui/collect_bubble.gd.uid
- game/ui/day_hud.gd
- game/ui/gauge.gd
- game/ui/world_anchor.gd
- game/ui/world_anchor.gd.uid
- game/world/base.gd
Checks: tests PASS (146/146) · scenarios PASS (15/15) · MCP run PASS (0 errors) · export PASS (phone check pending /phone-test)

## M-04 — "The Moon attacks": event alerts with countdown and result cards (2026-11-11)
Message: game: add Moon event alerts with countdown and result cards (M-04)
Files:
- docs/ai-prompts/M-04.md
- docs/ai-usage.md
- game/i18n/strings.bn.translation
- game/i18n/strings.csv
- game/i18n/strings.csv.import
- game/i18n/strings.en.translation
- game/scenes/main.gd
- game/tests/test_alerts.gd
- game/tests/test_alerts.gd.uid
- game/tests/test_crew_voice.gd
- game/ui/EventPopup.tscn
- game/ui/day_hud.gd
- game/ui/event_popup.gd
Checks: tests PASS (151/151) · scenarios PASS (15/15) · MCP run PASS (0 errors) · export PASS (phone check pending /phone-test)

## M-05 — Tap an astronaut, then tap a building (2026-11-11)
Message: game: add tap astronaut then building job assignment (M-05)
Files:
- docs/ai-prompts/M-05.md
- docs/ai-usage.md
- game/i18n/strings.bn.translation
- game/i18n/strings.csv
- game/i18n/strings.csv.import
- game/i18n/strings.en.translation
- game/scenes/main.gd
- game/tests/test_missions.gd
- game/tests/test_tap_assign.gd
- game/tests/test_tap_assign.gd.uid
- game/tests/test_ui_widgets.gd
- game/ui/BuildingMarker.tscn
- game/ui/CrewCard.tscn
- game/ui/CrewTagButton.tscn
- game/ui/DayHud.tscn
- game/ui/DebriefScreen.tscn
- game/ui/SourceTag.tscn
- game/ui/building_marker.gd
- game/ui/building_marker.gd.uid
- game/ui/crew_card.gd
- game/ui/crew_tag_button.gd
- game/ui/crew_tag_button.gd.uid
- game/ui/day_hud.gd
- game/ui/debrief_screen.gd
- game/ui/mission_map.gd
- game/world/astronaut.gd
- game/world/base.gd
- game/world/camera_rig.gd
- game/world/crew.gd
- tools/export_web.ps1
Checks: import PASS · tests PASS (158/158) · scenarios PASS (15/15) · MCP run PASS (0 errors) · export PASS · headless Chrome probe PASS (0 console errors) · phone OK ("OK LOOKS GOOD")

## T5-01 — English / Bangla toggle (2026-11-11)
Message: game: add English/Bangla language toggle (T5-01)
Files:
- docs/ai-prompts/T5-01.md
- docs/ai-usage.md
- game/data/facts.json
- game/i18n/strings.csv
- game/i18n/strings.bn.translation
- game/i18n/strings.en.translation
- game/tests/test_i18n.gd
- game/tests/test_i18n.gd.uid
- game/ui/BuildingMarker.tscn
- game/ui/CollectBubble.tscn
- game/ui/CrewTagButton.tscn
- game/ui/DayHud.tscn
- game/ui/SourceTag.tscn
- game/ui/crew_card.gd
- game/ui/crew_tag_button.gd
- game/ui/day_hud.gd
- game/ui/debrief_screen.gd
- game/ui/ending_overlay.gd
- game/ui/event_popup.gd
- game/ui/gauge.gd
- game/ui/mission_map.gd
- game/ui/pack_screen.gd
- game/ui/sources_screen.gd
- game/world/Astronaut.tscn
- game/world/SpeechBubble.tscn
- game/world/speech_bubble.gd
Checks: import PASS · Bangla glyph & screen audit PASS (`issues=0 warnings=0`) · tests PASS (162/162) · scenarios PASS (15/15) · MCP run PASS (0 runtime errors) · export PASS (46.15 MB / pck 9.85 MB) · phone OK (`http://192.168.0.109:8060/`, "looks goof")

## T5-02 — Phone polish and load time (2026-11-11)
Message: game: polish phone play and loading (T5-02)
Files:
- docs/ai-prompts/T5-02.md
- docs/ai-usage.md
- game/autoload/settings.gd
- game/export_presets.cfg
- game/project.godot
- game/tests/test_phone_polish.gd
- game/tests/test_phone_polish.gd.uid
- game/ui/DayHud.tscn
- game/ui/day_hud.gd
- game/ui/debrief_screen.gd
- game/ui/ending_overlay.gd
- game/ui/mission_map.gd
- game/ui/pack_screen.gd
- game/ui/safe_area.gd
- game/ui/safe_area.gd.uid
- game/ui/sources_screen.gd
- game/ui/title_screen.gd
- game/web/shell.html
- game/world/camera_rig.gd
- tools/serve.py
- tools/serve_web.ps1
Checks: import PASS · tests PASS (166/166) · scenarios PASS (15/15) · MCP run PASS (0 errors) · export PASS (`index.pck` trimmed 10.32 MB -> 4.96 MB) · phone OK (`http://192.168.0.109:8060/`, "looks good")




## M-06 — Crew energy: astronauts need rest (2026-11-12)
Message: game: add crew energy and rest mechanic (M-06)
Files:
- data/sources.md
- docs/ai-prompts/M-06.md
- docs/ai-usage.md
- game/autoload/settings.gd
- game/data/constants.json
- game/i18n/strings.bn.translation
- game/i18n/strings.csv
- game/i18n/strings.en.translation
- game/scenes/main.gd
- game/sim/sim_crew.gd
- game/sim/sim_day_report.gd
- game/sim/sim_debrief.gd
- game/sim/sim_log.gd
- game/sim/sim_mission.gd
- game/tests/run_scenarios.gd
- game/tests/scenarios/S10_overwork.json
- game/tests/test_constants.gd
- game/tests/test_crew.gd
- game/tests/test_i18n.gd
- game/ui/BuildingMarker.tscn
- game/ui/CrewCard.tscn
- game/ui/building_marker.gd
- game/ui/crew_card.gd
- game/ui/day_hud.gd
- game/ui/debrief_screen.gd
- game/ui/tutorial_overlay.gd
- game/world/speech_bubble.gd
Checks: import PASS · tests PASS (170/170) · scenarios PASS (16/16) · MCP run PASS (0 errors, 0 new warnings) · M4 SceneTree playthrough PASS · export PASS (`build/web/index.html`)

## M-08 — Junior astronaut training: briefing, guess first, answer after (2026-11-12)
Message: game: add astronaut training briefings, guess-first questions, ranks and certificate (M-08)
Files:
- docs/ai-prompts/M-08.md
- docs/ai-usage.md
- game/assets/icons/check.svg
- game/assets/icons/check.svg.import
- game/autoload/settings.gd
- game/i18n/strings.bn.translation
- game/i18n/strings.csv
- game/i18n/strings.csv.import
- game/i18n/strings.en.translation
- game/scenes/Main.tscn
- game/scenes/main.gd
- game/tests/test_i18n.gd
- game/tests/test_learning.gd
- game/tests/test_learning.gd.uid
- game/tests/test_missions.gd
- game/ui/CertificateScreen.tscn
- game/ui/DebriefScreen.tscn
- game/ui/MissionBriefing.tscn
- game/ui/SourceTag.tscn
- game/ui/TitleScreen.tscn
- game/ui/certificate_screen.gd
- game/ui/certificate_screen.gd.uid
- game/ui/debrief_screen.gd
- game/ui/learning_data.gd
- game/ui/learning_data.gd.uid
- game/ui/mission_briefing.gd
- game/ui/mission_briefing.gd.uid
- game/ui/mission_map.gd
- game/ui/source_tag.gd
- game/ui/title_screen.gd
Checks: import + `fontTools` glyph check PASS (`missing_count: 0`) · tests PASS (`177/177`) · scenarios PASS (`16/16`) · OpenGL `390x844` + `844x390` screenshot audit PASS · MCP run PASS (`0` runtime errors, `0` warnings in M-08 scripts) · export PASS (`build/web/index.html`)

## M-09 — Moon Science Cards: learn while you play (2026-11-12)
Message: game: add Moon Science Cards with triggers, album and sources (M-09)
Files:
- data/sources.md
- docs/ai-prompts/M-09.md
- docs/ai-usage.md
- game/autoload/settings.gd
- game/i18n/strings.bn.translation
- game/i18n/strings.csv
- game/i18n/strings.csv.import
- game/i18n/strings.en.translation
- game/scenes/main.gd
- game/tests/test_card_triggers.gd
- game/tests/test_card_triggers.gd.uid
- game/tests/test_learning.gd
- game/ui/CardAlbum.tscn
- game/ui/CardView.tscn
- game/ui/card_album.gd
- game/ui/card_album.gd.uid
- game/ui/card_controller.gd
- game/ui/card_controller.gd.uid
- game/ui/card_triggers.gd
- game/ui/card_triggers.gd.uid
- game/ui/card_view.gd
- game/ui/card_view.gd.uid
- game/ui/certificate_screen.gd
- game/ui/day_hud.gd
- game/ui/debrief_screen.gd
- game/ui/learning_data.gd
- game/ui/mission_map.gd
- game/ui/sources_screen.gd
- game/world/speech_bubble.gd
Checks: import PASS · tests PASS (183/183) · scenarios PASS (16/16) · MCP run PASS (0 errors, 0 warnings in M-09 scripts) · export PASS (`build/web/index.html`) · phone check pending developer `/phone-test`

## M-07 — Gauges a kid can read and act on (2026-11-12)
Message: ui: kid gauges, advice tip bubble, science view toggle, and card onboarding (M-07)
Files:
- docs/ai-prompts/M-07.md
- docs/ai-usage.md
- game/autoload/settings.gd
- game/i18n/strings.csv
- game/i18n/strings.csv.import
- game/i18n/strings.en.translation
- game/i18n/strings.bn.translation
- game/scenes/main.gd
- game/sim/sim_day_report.gd
- game/sim/sim_mission.gd
- game/tests/test_kid_gauges.gd
- game/tests/test_card_triggers.gd
- game/ui/Gauge.tscn
- game/ui/gauge.gd
- game/ui/kid_gauge_graphic.gd
- game/ui/kid_gauge_graphic.gd.uid
- game/ui/CrewCard.tscn
- game/ui/crew_card.gd
- game/ui/DayHud.tscn
- game/ui/day_hud.gd
- game/ui/tutorial_overlay.gd
- game/ui/CardView.tscn
- game/ui/card_view.gd
Checks: import PASS · tests PASS (191/191) · scenarios PASS (16/16) · SceneTree live scenarios PASS · export PASS (`build/web/index.html`) · phone server running (`http://192.168.0.106:8060/`)

## T6-01 — Sources, credits and README (2026-11-12)
Message: docs: complete sources, credits and how to play (T6-01)
Files:
- README.md
- data/sources.md
- docs/ai-prompts/T6-01.md
- docs/ai-usage.md
- docs/impact.md
- game/data/constants.json
Checks: tests PASS (191/191) · link check PASS (16/16) · sources sync PASS (172/172)

## T6-02 — Final QA playthrough (2026-11-12)
Message: game: fix issues from final QA (T6-02)
Files:
- docs/ai-prompts/T6-02.md
- docs/ai-usage.md
- game/world/effects.gd
- game/world/lander.gd
Checks: tests PASS (191/191) · scenarios PASS (16/16) · export PASS (`build/web/index.html`) · console clean PASS

## T6-03 — Release: developer commits, deploys and tags v1.0 (2026-11-12)
Message: docs: prepare v1.0 release, audit AI logs, and finalize commit log (T6-03)
Files:
- docs/ai-prompts/T4-04.md
- docs/ai-prompts/T6-03.md
- docs/ai-usage.md
Checks: tests PASS (191/191) · scenarios PASS (16/16) · export PASS (`build/web/index.html`) · git tree audit PASS


