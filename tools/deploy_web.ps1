# tools/deploy_web.ps1
# Deploy to GitHub Pages.
# NOTE: The agent NEVER runs this script. The developer runs it at the end (T6-03).

$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
if (-not $ScriptDir) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if (-not $ScriptDir) {
    $ScriptDir = (Get-Location).Path
}

$repo = Split-Path -Parent $ScriptDir
if (-not (Test-Path (Join-Path $repo "game"))) {
    if (Test-Path "Moonbase-Commander/game") {
        $repo = (Resolve-Path "Moonbase-Commander").Path
    } elseif (Test-Path "game") {
        $repo = (Get-Location).Path
    }
}

$wt = Join-Path (Split-Path -Parent $repo) "gh-pages-worktree"
$exportScript = Join-Path $ScriptDir "export_web.ps1"
& $exportScript

if (-not (Test-Path $wt)) {
    git -C $repo fetch origin gh-pages
    if ($LASTEXITCODE -eq 0) {
        git -C $repo worktree add $wt gh-pages
    } else {
        git -C $repo worktree add --orphan -b gh-pages $wt
    }
}

Get-ChildItem $wt -Force | Where-Object { $_.Name -ne ".git" } | Remove-Item -Recurse -Force
Copy-Item (Join-Path $repo "build\web\*") $wt -Recurse
New-Item (Join-Path $wt ".nojekyll") -ItemType File -Force | Out-Null
git -C $wt add -A
git -C $wt commit -m "deploy: web build $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
git -C $wt push -u origin gh-pages

