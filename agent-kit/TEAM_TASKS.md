# TEAM TASKS — for the teammates (not agent tickets)

Siam is the only one writing code, but the teammates' own commits show real teamwork to the judges. Each task is a data or text file. Each person commits from their **own GitHub account** (on github.com you can edit a file in the browser and commit it there; no setup needed).

| Who | Task | File | When |
| --- | --- | --- | --- |
| Samia Jahan | Write the Bangla column for every text key | `game/i18n/strings.csv` (column `bn`) | after T3-06 (keys are complete), before 12 Nov noon |
| Samia Jahan | Bangla for the 16 debrief facts | `game/data/facts.json` (field `bn`) | any time |
| MD Samiul Islam | Check the 16 debrief facts against their links, and fix wording if a fact is not exactly what the source says | `game/data/facts.json` | 10 Nov |
| MD Samiul Islam | Verify the AI-found rows for Segments 1–2: open each link, tick "Verified by team" | `data/sources.md` | 10–11 Nov |
| Ahsanur Rahman | Verify the AI-found rows for Segment 3; add the two links that were hidden in the PDF export; add the real "date checked" for 3.1 and 3.2 | `data/sources.md` | 10–11 Nov |
| Alfi Shahrin Talukder | Read every *Game setting* and *Game assumption* in `constants.json`; check each `note` is clear for a judge; suggest changes to Siam | `game/data/constants.json` (notes only) | 10 Nov |

## Rules for these edits

- Change only your file. Never change a `value` in `constants.json`. Values are changed by Siam in a balance ticket.
- Bangla text: short, the same meaning as the English, and keep `{placeholders}` exactly as they are (for example `{min}`, `{day}`).
- Commit message: `data: <what> (team)`, for example `data: Bangla text for pack screen (team)`.
- Pull before editing if you use a local copy.
