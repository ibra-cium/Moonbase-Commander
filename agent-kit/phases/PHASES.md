# PHASES

| Phase | Name | When | Exit gate |
| --- | --- | --- | --- |
| [P0](P0-setup.md) | Setup | 9 Nov evening | A 3D placeholder scene with the "30 days" label opens on the developer's phone over the home Wi-Fi. |
| [PA](PA-asset-import.md) | Asset download and import | 9–10 Nov, any time after T0-02 | `game/assets/` filled with a clean import; AI log has the "downloaded by hand" row and the PA-02 row. |
| [P1](P1-simulation.md) | Simulation | 10 Nov | All unit tests pass and scenarios S01–S09 match GAME_RULES §10 (and the Python reference). |
| [P2](P2-3d-base.md) | 3D base | 10–11 Nov | The biggest base runs smoothly on the phone; S01 shows the Day 16 blackout in 3D. |
| [P3](P3-game-loop-and-ui.md) | Game loop and UI | 11 Nov | A full 30-day mission is playable on the phone with touch only, every gauge has a source tag, and the debrief explains the result. |
| [P4](P4-events-and-feel.md) | Events and feel | 12 Nov morning | Every event is visible and audible; a first-time player starts without help. |
| [P5](P5-bangla-and-phone.md) | Bangla and phone | 12 Nov | All screens work in Bangla; a full mission plays well on the phone. |
| [P6](P6-ship.md) | Ship | 12 Nov night | Developer committed and deployed; v1.0 tag; link works in a private window; capture list ready for 13 Nov. |

PA can run any time after T0-02 (between other tickets). P2 needs PA done.
