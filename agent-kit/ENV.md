# ENV — tools, paths, commands

The developer works on **Windows** with **Antigravity**, **Godot 4.6.3** and **Godot MCP**. Use PowerShell syntax.

## First run: record the Godot path

Ask the developer once for the full path to the Godot **console** executable, for example:

```
C:\Tools\Godot\Godot_v4.6.3-stable_win64_console.exe
```

Write it into the table below and use it as `$GODOT` in every command. Use the `_console` exe for command-line runs so output appears in the terminal.

| Setting | Value |
| --- | --- |
| GODOT | `C:\Godot\Godot_v4.6.3-stable_win64_console.exe` |
| Godot version check | `4.6.3.stable.official.7d41c59c4` |
| Export templates | Installed for 4.6.3 (Editor → Manage Export Templates) |
| Godot MCP connected | yes |
| Python 3 available | yes (Python 3.13.14) |
| GitHub Pages URL (end only) | `https://ibra-cium.github.io/Moonbase-Commander/` |

## Commands (run from `Moonbase/Moonbase-Commander/`)

```powershell
$GODOT = "C:\Godot\Godot_v4.6.3-stable_win64_console.exe"

# 1. Import the project (needed once after clone, and after new assets/scripts with class_name)
& $GODOT --headless --path game --import

# 2. Run all headless tests (exit code 0 = pass)
& $GODOT --headless --path game --script res://tests/run_tests.gd

# 3. Run the balance scenarios and print the results table
& $GODOT --headless --path game --script res://tests/run_scenarios.gd

# 4. Export the web build
& $GODOT --headless --path game --export-release "Web" ../build/web/index.html

# Shortcuts (created in P0): tools\test.ps1, tools\scenarios.ps1, tools\export_web.ps1, tools\serve_web.ps1
# tools\deploy_web.ps1 is for the developer only, at the very end (it commits and pushes)
```

## Godot MCP

If Godot MCP is connected, use it to:

- run the project or one scene and read the debug output after a change,
- check for errors and warnings after you add a scene.

Use the tool names your MCP server lists (for example a run-project tool and a debug-output tool). If MCP is not connected or a call fails twice, fall back to the command line above and say so in your handoff.

The MCP does not replace the headless tests. A ticket is only done when `run_tests.gd` passes.

## Phone test

During the build the developer tests on his phone over the home Wi-Fi (`/phone-test`, `tools\serve_web.ps1`, needs Python 3). Nothing is pushed. When a ticket says "phone check", serve the build, give him the link, and ask: loads? fps feel? touch works? text readable?

## Git

Read-only only (`git status`, `git diff`). The developer commits and deploys himself at the end.
