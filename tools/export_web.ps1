param()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) {
    $ScriptDir = (Get-Location).Path
}

$RepoRoot = Split-Path -Parent $ScriptDir
$GameDir = Join-Path $RepoRoot "game"
$BuildWebDir = Join-Path $RepoRoot "build\web"

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

# Ensure build/web directory exists (Godot does not create target directories)
New-Item -ItemType Directory -Force $BuildWebDir | Out-Null

$IndexHtml = Join-Path $BuildWebDir "index.html"
Write-Host "Exporting Web build to $IndexHtml..."
& $Godot --headless --path $GameDir --export-release "Web" $IndexHtml

if ($LASTEXITCODE -ne 0) {
    Write-Error "Export failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

if (-not (Test-Path $IndexHtml)) {
    Write-Error "Export finished but $IndexHtml was not found."
    exit 1
}

# Patch index.html for LAN testing: single-threaded export does not require HTTPS,
# but Godot's web shell checks window.isSecureContext unconditionally.
$htmlContent = Get-Content $IndexHtml -Raw
if ($htmlContent -match "const missing = Engine\.getMissingFeatures\(\{") {
    $patched = $htmlContent -replace "const missing = Engine\.getMissingFeatures\(\{[\s\S]*?\}\);", "const missing = Engine.getMissingFeatures({`n`t`tthreads: GODOT_THREADS_ENABLED,`n`t}).filter(function (x) { return !x.includes('Secure Context'); });"
    $patched = $patched.Replace('<script src="index.js"></script>', '<script src="index.js?v=2"></script>')
    Set-Content -Path $IndexHtml -Value $patched -NoNewline
}

# Patch index.js: guard against missing audioWorklet in insecure contexts (LAN HTTP testing on mobile)
$IndexJs = Join-Path $BuildWebDir "index.js"
if (Test-Path $IndexJs) {
    $jsContent = Get-Content $IndexJs -Raw
    $jsContent = $jsContent.Replace('GodotAudio.audioPositionWorkletPromise=ctx.audioWorklet.addModule(path);', 'GodotAudio.audioPositionWorkletPromise=(ctx.audioWorklet?ctx.audioWorklet.addModule(path):Promise.resolve());')
    $jsContent = $jsContent.Replace('GodotAudioWorklet.promise=GodotAudio.ctx.audioWorklet.addModule(path).then(function(){GodotAudioWorklet.worklet=new AudioWorkletNode(GodotAudio.ctx,"godot-processor",{outputChannelCount:[channels]});return Promise.resolve()});', 'GodotAudioWorklet.promise=(GodotAudio.ctx.audioWorklet?GodotAudio.ctx.audioWorklet.addModule(path).then(function(){GodotAudioWorklet.worklet=new AudioWorkletNode(GodotAudio.ctx,"godot-processor",{outputChannelCount:[channels]});return Promise.resolve()}):Promise.resolve());')
    $jsContent = $jsContent.Replace('async connectPositionWorklet(start){await GodotAudio.audioPositionWorkletPromise;if(this.isCanceled){return}this._source.connect(this.getPositionWorklet());if(start){this.start()}}', 'async connectPositionWorklet(start){await GodotAudio.audioPositionWorkletPromise;if(this.isCanceled){return}if(GodotAudio.ctx&&GodotAudio.ctx.audioWorklet){this._source.connect(this.getPositionWorklet())}if(start){this.start()}}')
    $jsContent = $jsContent.Replace('getPlaybackPosition(){return this._playbackPosition}', 'getPlaybackPosition(){if(this._positionWorklet==null&&this.isStarted&&!this.isPaused&&GodotAudio.ctx){return this.offset+Math.max(0,(GodotAudio.ctx.currentTime-this._sourceStartTime)*this.getPlaybackRate()*this.getPitchScale())}return this._playbackPosition}')
    $jsContent = $jsContent.Replace('GodotAudio.ctx=ctx;', 'GodotAudio.ctx=ctx;if(!GodotAudio._gestureResumeBound){GodotAudio._gestureResumeBound=true;["touchend","pointerup","mouseup","click","keydown"].forEach(function(ev){window.addEventListener(ev,function(){if(GodotAudio.ctx&&GodotAudio.ctx.state!=="running"){GodotAudio.ctx.resume()}},{capture:true,passive:true})})}')
    Set-Content -Path $IndexJs -Value $jsContent -NoNewline
}

Write-Host "Web export succeeded: $IndexHtml"
exit 0

