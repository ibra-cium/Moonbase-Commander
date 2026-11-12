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

$web = Join-Path $repo "build\web"
if (-not (Test-Path (Join-Path $web "index.html"))) {
    throw "Run tools\export_web.ps1 first"
}

$ipAddressObj = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue | Where-Object {
    $_.InterfaceAlias -notmatch "Loopback|vEthernet" -and $_.IPAddress -notlike "169.*"
} | Select-Object -First 1

$ip = if ($ipAddressObj) { $ipAddressObj.IPAddress } else { "127.0.0.1" }

Write-Host "Open on the phone (same Wi-Fi): http://$($ip):8060/"
$servePy = Join-Path $ScriptDir "serve.py"
Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match "python" -and $_.CommandLine -like "*tools*serve.py*"
} | ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
}
python $servePy $web

