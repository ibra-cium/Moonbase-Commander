param()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) {
    $ScriptDir = (Get-Location).Path
}

$RepoRoot = Split-Path -Parent $ScriptDir
$GameDir = Join-Path $RepoRoot "game"

$Godot = $env:GODOT

$GodotPathFile = Join-Path $ScriptDir "godot_path.txt"
if ((-not $Godot) -and (Test-Path $GodotPathFile)) {
    $Godot = (Get-Content $GodotPathFile -Raw).Trim()
}

if (-not $Godot) {
    if (Test-Path "tools/godot_path.txt") {
        $Godot = (Get-Content "tools/godot_path.txt" -Raw).Trim()
    } elseif (Test-Path "Moonbase-Commander/tools/godot_path.txt") {
        $Godot = (Get-Content "Moonbase-Commander/tools/godot_path.txt" -Raw).Trim()
    }
}

if (-not $Godot -or -not (Test-Path $Godot)) {
    Write-Error "Godot executable not found. Set `$env:GODOT or create tools/godot_path.txt"
    exit 1
}

if (-not (Test-Path $GameDir)) {
    if (Test-Path "game") {
        $GameDir = (Resolve-Path "game").Path
    } elseif (Test-Path "Moonbase-Commander/game") {
        $GameDir = (Resolve-Path "Moonbase-Commander/game").Path
    } else {
        Write-Error "Game directory not found at $GameDir"
        exit 1
    }
}

$DotGodot = Join-Path $GameDir ".godot"
if (-not (Test-Path $DotGodot)) {
    Write-Host "Initial import: game/.godot not found..."
    & $Godot --headless --path $GameDir --import
}

& $Godot --headless --path $GameDir --script "res://tests/run_scenarios.gd"
exit $LASTEXITCODE

