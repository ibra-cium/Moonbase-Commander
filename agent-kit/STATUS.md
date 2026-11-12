# STATUS — ticket board

Status: `Todo` · `Doing` · `Done` · `Blocked (reason)`. The agent updates this file; it is never committed.

| ID | Title | Phase | Depends on | Who | Status |
| --- | --- | --- | --- | --- | --- |
| [T0-01](tickets/T0-01-workspace-and-repo-housekeeping.md) | Workspace check and repo housekeeping | P0 | — | Agent | Done |
| [T0-02](tickets/T0-02-godot-project-skeleton.md) | Godot project skeleton | P0 | T0-01 | Agent | Done |
| [T0-03](tickets/T0-03-test-harness-and-tools.md) | Test harness and helper scripts | P0 | T0-02 | Agent | Done |
| [T0-04](tickets/T0-04-constants-and-game-data.md) | Constants loader and game data | P0 | T0-03 | Agent | Done |
| [T0-05](tickets/T0-05-web-export-and-phone-check.md) | Web export and first phone check over Wi-Fi | P0 | T0-04 | Agent + Developer | Done |
| [PA-01](tickets/PA-01-download-asset-packs.md) | Download the asset packs (developer, agent guides) | PA | T0-02 | Developer + Agent | Done |
| [PA-02](tickets/PA-02-organize-and-import-assets.md) | Organize and import the assets | PA | PA-01 | Agent | Done |
| [T1-01](tickets/T1-01-sim-cargo.md) | Cargo catalog and pack maths | P1 | T0-04 | Agent | Done |
| [T1-02](tickets/T1-02-sim-power.md) | Power system | P1 | T1-01 | Agent | Done |
| [T1-03](tickets/T1-03-sim-life-support.md) | Life support: oxygen, CO2, water, food | P1 | T1-02 | Agent | Done |
| [T1-04](tickets/T1-04-sim-crew-and-jobs.md) | Crew, jobs, dust, radiation and sickness | P1 | T1-03 | Agent | Done |
| [T1-05](tickets/T1-05-sim-greenhouse.md) | Greenhouse | P1 | T1-04 | Agent | Done |
| [T1-06](tickets/T1-06-sim-events-and-log.md) | Events schedule and mission log | P1 | T1-05 | Agent | Done |
| [T1-07](tickets/T1-07-sim-mission-and-debrief.md) | Mission loop, end checks, stars and debrief + GameState | P1 | T1-06 | Agent | Done |
| [T1-08](tickets/T1-08-balance-scenarios.md) | Balance scenarios S01–S09 | P1 | T1-07 | Agent | Done |
| [T2-01](tickets/T2-01-moon-ground-sky-camera.md) | Asset check, Moon ground, sky and camera | P2 | T1-08, PA-02 | Agent | Done |
| [T2-02](tickets/T2-02-base-layout-and-spawner.md) | Base layout and cargo spawner | P2 | T2-01 | Agent | Done |
| [T2-03](tickets/T2-03-base-reacts-to-reports.md) | Base reacts to each day | P2 | T2-02 | Agent | Done |
| [T2-04](tickets/T2-04-astronauts.md) | Code-built hopping astronauts | P2 | T2-03 | Agent | Done |
| [T2-05](tickets/T2-05-day-night-cycle.md) | Sun path, Day 15 sunset and night | P2 | T2-04 | Agent | Done |
| [T2-06](tickets/T2-06-3d-performance-pass.md) | 3D performance pass on the phone | P2 | T2-05 | Agent + Developer | Done |
| [T3-01](tickets/T3-01-ui-theme-and-widgets.md) | UI theme, widgets and Sources screen | P3 | T2-06 | Agent | Done |
| [T3-02](tickets/T3-02-title-screen.md) | Title screen with NASA Moon globe | P3 | T3-01 | Agent | Done |
| [T3-03](tickets/T3-03-pack-screen.md) | Pack screen | P3 | T3-02 | Agent | Done |
| [T3-04](tickets/T3-04-landing-and-day-loop.md) | Landing and the day loop | P3 | T3-03 | Agent | Done |
| [T3-05](tickets/T3-05-day-hud.md) | Day HUD: gauges, crew jobs, power switches | P3 | T3-04 | Agent | Done |
| [T3-06](tickets/T3-06-debrief-screen.md) | Debrief: stars, cause chain, fact, retry | P3 | T3-05 | Agent | Done |
| [T4-01](tickets/T4-01-event-effects.md) | Event effects | P4 | T3-06 | Agent | Done |
| [T4-02](tickets/T4-02-mission-endings.md) | Evacuation lift-off and success ending | P4 | T4-01 | Agent | Done |
| [T4-03](tickets/T4-03-audio.md) | Audio: life-support hum, alarms, UI sounds | P4 | T4-02 | Agent | Done |
| [T4-04](tickets/T4-04-onboarding.md) | First-run tutorial and hints | P4 | T4-03 | Agent + Developer | Done |
| [M-01](tickets/M-01-mission-map.md) | Mission map and four missions | PM | T4-04 | Agent | Done |
| [M-02](tickets/M-02-named-crew.md) | Named crew, speech bubbles and less tapping | PM | M-01 | Agent | Done |
| [M-03](tickets/M-03-tap-to-collect.md) | Tap-to-collect bubbles and resource bar | PM | M-02 | Agent | Done |
| [M-04](tickets/M-04-moon-alerts.md) | "The Moon attacks": event alerts with countdown and result | PM | M-03 | Agent | Done |
| [M-05](tickets/M-05-tap-to-assign.md) | Tap an astronaut, then tap a building | PM | M-04 | Agent + Developer | Done |
| [T5-01](tickets/T5-01-bangla-language.md) | English / Bangla toggle | P5 | M-05 | Agent | Done |
| [T5-02](tickets/T5-02-phone-polish.md) | Phone polish and load time | P5 | T5-01 | Agent + Developer | Done |
| [M-06](tickets/M-06-crew-energy.md) | Crew energy: astronauts need rest | PM | T5-02 | Agent | Done |
| [M-08](tickets/M-08-astronaut-training.md) | Junior astronaut training: briefing, guess first, answer after | PM | M-06 | Agent | Done |
| [M-09](tickets/M-09-science-cards.md) | Moon Science Cards: learn while you play | PM | M-08 | Agent | Done |
| [M-07](tickets/M-07-kid-gauges.md) | Gauges a kid can read and act on | PM | M-09 | Agent + Developer | Done |
| [T6-01](tickets/T6-01-sources-and-credits.md) | Sources, credits and README | P6 | M-07 | Agent | Done |
| [T6-02](tickets/T6-02-final-qa.md) | Final QA playthrough | P6 | T6-01 | Agent + Developer | Done |
| [T6-03](tickets/T6-03-release-v1.md) | Release: developer commits, deploys and tags v1.0 | P6 | T6-02 | Developer + Agent | Done |
