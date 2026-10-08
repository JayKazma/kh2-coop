# KH2 Co-op launcher (Steam transport). Windows PowerShell 5.1, no installs.
# This script sits in the package root. Layout next to it: bin\kh2ctl.exe, bin\kh2coop_inject.dll,
# bin\kh2coop_runtime_scaffold.exe, KH2COOP-PACKAGE, package.json, version.txt,
# settings.json (created on first run), build\rig\... (created by the mod).
# Updates: GitHub release asset kh2coop-update.zip with bin\*, version.txt and optionally KH2Coop.ps1.
param([switch]$NoUpdate)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Root        = $PSScriptRoot
$Bin         = Join-Path $Root 'bin'
$Kh2ctl      = Join-Path $Bin 'kh2ctl.exe'
$Runtime     = Join-Path $Bin 'kh2coop_runtime_scaffold.exe'
$Dll         = Join-Path $Bin 'kh2coop_inject.dll'
$Logs        = Join-Path $Root 'build\rig\logs'
$SettingsFile= Join-Path $Root 'settings.json'
$VersionFile = Join-Path $Root 'version.txt'
$UpdateBase  = 'https://raw.githubusercontent.com/JayKazma/kh2-coop/main'   # version.txt, dist/kh2coop-update.zip, dist/notes.txt
$GameExe     = 'KINGDOM HEARTS II FINAL MIX.exe'

# ---------------------------------------------------------------- settings
$Settings = [ordered]@{ gameDir = ''; cloneMode = $true; mode = 'host'; hostId = ''; friendId = ''; name = '' }
if (Test-Path $SettingsFile) {
    try { $saved = Get-Content $SettingsFile -Raw | ConvertFrom-Json
          foreach ($k in @('gameDir','cloneMode','mode','hostId','friendId','name')) { if ($null -ne $saved.$k) { $Settings[$k] = $saved.$k } } } catch {}
}
function Save-Settings { ($Settings | ConvertTo-Json) | Set-Content -Encoding UTF8 $SettingsFile }
function Find-GameDir {
    if ($Settings.gameDir -and (Test-Path (Join-Path $Settings.gameDir $GameExe))) { return $Settings.gameDir }
    $candidates = @('C:\Program Files (x86)\Steam\steamapps\common\KINGDOM HEARTS -HD 1.5+2.5 ReMIX-')
    foreach ($drive in (Get-PSDrive -PSProvider FileSystem | ForEach-Object Root)) {
        $candidates += (Join-Path $drive 'SteamLibrary\steamapps\common\KINGDOM HEARTS -HD 1.5+2.5 ReMIX-')
        $candidates += (Join-Path $drive 'Steam\steamapps\common\KINGDOM HEARTS -HD 1.5+2.5 ReMIX-')
    }
    foreach ($c in $candidates) { if (Test-Path (Join-Path $c $GameExe)) { return $c } }
    return ''
}

# ---------------------------------------------------------------- window
$form = New-Object System.Windows.Forms.Form
$form.Text = 'KH2 Co-op'
$form.Size = New-Object System.Drawing.Size(640, 560)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false

function Add-Label($text, $x, $y, $w = 120) {
    $l = New-Object System.Windows.Forms.Label; $l.Text = $text; $l.Location = New-Object System.Drawing.Point($x, $y); $l.Size = New-Object System.Drawing.Size($w, 20); $form.Controls.Add($l); $l
}
function Add-Text($x, $y, $w, $value) {
    $t = New-Object System.Windows.Forms.TextBox; $t.Location = New-Object System.Drawing.Point($x, $y); $t.Size = New-Object System.Drawing.Size($w, 22); $t.Text = $value; $form.Controls.Add($t); $t
}
function Add-Button($text, $x, $y, $w, $h = 32) {
    $b = New-Object System.Windows.Forms.Button; $b.Text = $text; $b.Location = New-Object System.Drawing.Point($x, $y); $b.Size = New-Object System.Drawing.Size($w, $h); $form.Controls.Add($b); $b
}

$versionLabel = Add-Label ('Version ' + $(if (Test-Path $VersionFile) { (Get-Content $VersionFile -Raw).Trim() } else { 'unknown' })) 12 10 300
$updateButton = Add-Button 'Check for updates' 470 6 150 26

Add-Label 'Game folder' 12 44 | Out-Null
$gameBox = Add-Text 130 42 400 (Find-GameDir)
$browseButton = Add-Button '...' 536 41 40 24

$cloneCheck = New-Object System.Windows.Forms.CheckBox
$cloneCheck.Text = 'Sora clone mode (the other player appears as Sora; same setting on both PCs)'
$cloneCheck.Location = New-Object System.Drawing.Point(12, 74); $cloneCheck.Size = New-Object System.Drawing.Size(600, 22)
$cloneCheck.Checked = [bool]$Settings.cloneMode
$form.Controls.Add($cloneCheck)

$startButton = Add-Button 'Start KH2' 12 104 150 36
$myIdLabel = Add-Label 'Your SteamID: (start the game first)' 176 112 440
$copyButton = Add-Button 'Copy' 536 106 40 26; $copyButton.Enabled = $false

$hostRadio = New-Object System.Windows.Forms.RadioButton; $hostRadio.Text = 'Host (you lead, the friend follows you)'; $hostRadio.Location = New-Object System.Drawing.Point(12, 152); $hostRadio.Size = New-Object System.Drawing.Size(300, 22)
$joinRadio = New-Object System.Windows.Forms.RadioButton; $joinRadio.Text = 'Join a host'; $joinRadio.Location = New-Object System.Drawing.Point(320, 152); $joinRadio.Size = New-Object System.Drawing.Size(200, 22)
$form.Controls.Add($hostRadio); $form.Controls.Add($joinRadio)
if ($Settings.mode -eq 'join') { $joinRadio.Checked = $true } else { $hostRadio.Checked = $true }

$peerLabel = Add-Label "Friend's SteamID" 12 182
$peerBox = Add-Text 130 180 300 $(if ($Settings.mode -eq 'join') { $Settings.hostId } else { $Settings.friendId })

$connectButton = Add-Button 'Connect' 12 212 150 36
$disconnectButton = Add-Button 'Disconnect' 176 212 150 36; $disconnectButton.Enabled = $false
$exitGameButton = Add-Button 'Close game' 340 212 150 36; $exitGameButton.Enabled = $false

$status = Add-Label 'Ready.' 12 256 600
$log = New-Object System.Windows.Forms.TextBox
$log.Multiline = $true; $log.ReadOnly = $true; $log.ScrollBars = 'Vertical'; $log.Font = New-Object System.Drawing.Font('Consolas', 8.5)
$log.Location = New-Object System.Drawing.Point(12, 280); $log.Size = New-Object System.Drawing.Size(608, 236)
$form.Controls.Add($log)

function Write-Log($text) {
    $line = (Get-Date -Format 'HH:mm:ss') + '  ' + $text
    $log.AppendText($line + [Environment]::NewLine)
}
function Set-Status($text) { $status.Text = $text; Write-Log $text }

# ---------------------------------------------------------------- state
$script:GamePid = 0
$script:RuntimeProc = $null
$script:RuntimeLog = ''
$script:RuntimeErrLog = ''
$script:RuntimeLogPos = 0
$script:MyId = ''

function Read-Shared($path) {
    $s = [IO.File]::Open($path, 'Open', 'Read', 'ReadWrite')
    try { (New-Object IO.StreamReader($s)).ReadToEnd() } finally { $s.Dispose() }
}
function Game-Alive { $script:GamePid -ne 0 -and (Get-Process -Id $script:GamePid -ErrorAction SilentlyContinue) }
function Runtime-Alive { $script:RuntimeProc -and -not $script:RuntimeProc.HasExited }

function Update-Buttons {
    $game = [bool](Game-Alive); $rt = [bool](Runtime-Alive)
    $startButton.Enabled = -not $game
    $connectButton.Enabled = $game -and $script:MyId -and -not $rt
    $disconnectButton.Enabled = $rt
    $exitGameButton.Enabled = $game
    $cloneCheck.Enabled = -not $game
    $updateButton.Enabled = -not $game
}

# ---------------------------------------------------------------- update
function Get-LocalVersion { if (Test-Path $VersionFile) { (Get-Content $VersionFile -Raw).Trim() } else { '0' } }
function Compare-Version($a, $b) { # 1 if a > b
    try { return [version]($a -replace '^v','') -gt [version]($b -replace '^v','') } catch { return $a -ne $b -and $a -gt $b }
}
function Check-Update([switch]$Quiet) {
    try {
        Set-Status 'Checking for updates...'
        $headers = @{ 'User-Agent' = 'KH2Coop-Launcher'; 'Cache-Control' = 'no-cache' }
        $bust = '?t=' + [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $remote = ([string](Invoke-RestMethod -Uri "$UpdateBase/version.txt$bust" -Headers $headers -TimeoutSec 15)).Trim()
        if ($remote -notmatch '^v?\d+(\.\d+)+$') { Set-Status "Update check: unexpected version '$remote'."; return }
        $local = Get-LocalVersion
        if (-not (Compare-Version $remote $local)) { Set-Status "Up to date ($local)."; return }
        $notes = ''
        try { $notes = ([string](Invoke-RestMethod -Uri "$UpdateBase/dist/notes.txt$bust" -Headers $headers -TimeoutSec 15)).Trim() } catch {}
        $answer = [System.Windows.Forms.MessageBox]::Show("Update $remote is available (you have $local).`n`n$notes`n`nDownload and install it now?", 'KH2 Co-op update', 'YesNo', 'Question')
        if ($answer -ne 'Yes') { Set-Status 'Update skipped.'; return }
        Set-Status "Downloading $remote..."
        $form.Refresh()
        $tmp = Join-Path $env:TEMP ("kh2coop-update-" + [guid]::NewGuid().ToString('N') + '.zip')
        Invoke-WebRequest -Uri "$UpdateBase/dist/kh2coop-update.zip$bust" -OutFile $tmp -Headers $headers -TimeoutSec 300
        $stage = Join-Path $env:TEMP ("kh2coop-stage-" + [guid]::NewGuid().ToString('N'))
        Expand-Archive -Path $tmp -DestinationPath $stage -Force
        # The zip holds bin\..., version.txt and optionally KH2Coop.ps1 (applied on restart).
        if (Test-Path (Join-Path $stage 'bin')) { Copy-Item (Join-Path $stage 'bin\*') $Bin -Force }
        foreach ($f in @('version.txt', 'KH2COOP-PACKAGE', 'package.json', 'KH2 Co-op.bat')) {
            if (Test-Path (Join-Path $stage $f)) { Copy-Item (Join-Path $stage $f) (Join-Path $Root $f) -Force }
        }
        $newLauncher = Join-Path $stage 'KH2Coop.ps1'
        $restart = $false
        if ((Test-Path $newLauncher) -and ((Get-FileHash $newLauncher).Hash -ne (Get-FileHash $PSCommandPath).Hash)) {
            Copy-Item $newLauncher (Join-Path $Root 'KH2Coop.ps1.new') -Force; $restart = $true
        }
        Remove-Item $tmp, $stage -Recurse -Force -ErrorAction SilentlyContinue
        $versionLabel.Text = 'Version ' + (Get-LocalVersion)
        Set-Status "Updated to $remote."
        if ($restart) {
            [System.Windows.Forms.MessageBox]::Show('The launcher itself was updated. It will now restart.', 'KH2 Co-op update', 'OK', 'Information') | Out-Null
            Move-Item (Join-Path $Root 'KH2Coop.ps1.new') (Join-Path $Root 'KH2Coop.ps1') -Force
            Start-Process powershell -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $Root 'KH2Coop.ps1'), '-NoUpdate') -WorkingDirectory $Root
            $form.Close()
        }
    } catch {
        if (-not $Quiet) { Set-Status ('Update check failed: ' + $_.Exception.Message) } else { Write-Log ('Update check failed: ' + $_.Exception.Message) }
    }
}

# ---------------------------------------------------------------- game
function Start-Game {
    $dir = $gameBox.Text.Trim('"').TrimEnd('\')
    if (-not (Test-Path (Join-Path $dir $GameExe))) { Set-Status "Game folder is wrong: $GameExe not found."; return }
    foreach ($f in @($Kh2ctl, $Runtime, $Dll)) { if (-not (Test-Path $f)) { Set-Status "Missing $f. Run Check for updates."; return } }
    $Settings.gameDir = $dir; $Settings.cloneMode = $cloneCheck.Checked; Save-Settings
    # Environment for the game child (the mod reads these at start).
    Get-ChildItem Env: | Where-Object { $_.Name -like 'KH2COOP_*' } | ForEach-Object { Remove-Item ("Env:" + $_.Name) }
    $env:KH2COOP_STEAM_BROKER = '1'
    $env:KH2COOP_PUPPET_TRACE = '1'; $env:KH2COOP_AVATAR_DIAG = '1'   # diagnostics (log only)
    $env:SteamAppId = '2552430'; $env:SteamGameId = '2552430'
    if ($cloneCheck.Checked) {
        $env:KH2COOP_PARTY_NATIVE = '1'; $env:KH2COOP_NATIVE_SORA_PRIVATE_STATUS = '1'; $env:KH2COOP_CLONE_NEUTRAL_INPUT = '1'; $env:KH2COOP_ALLY_HIT = '1'
    }
    Set-Status 'Starting KH2...'
    $form.Refresh()
    Push-Location $Root
    try {
        $ErrorActionPreference = 'Continue'
        $out = @(& $Kh2ctl launch --game-dir $dir --dll $Dll 2>&1 | ForEach-Object { "$_" })
    } finally { Pop-Location; $ErrorActionPreference = 'Stop' }
    $last = ($out | Where-Object { $_ -like '{*' } | Select-Object -Last 1)
    $r = $null
    if ($last) { try { $r = $last | ConvertFrom-Json } catch { $r = $null } }
    if (-not $r -or -not $r.ok) { Set-Status ('Launch failed: ' + ($out -join ' ')); return }
    $script:GamePid = [int]$r.processId; $script:MyId = ''
    $myIdLabel.Text = 'Your SteamID: waiting for the game''s Steam session (load to the title screen)...'
    Set-Status "KH2 started (PID $($script:GamePid))."
    Update-Buttons
}
function Poll-SteamId {
    if (-not (Game-Alive) -or $script:MyId) { return }
    $bl = Join-Path $Logs ("steam-broker_" + $script:GamePid + ".log")
    if (-not (Test-Path $bl)) { return }
    $t = Read-Shared $bl
    if ($t -match 'ready appId=2552430 identity=(\d{17})') {
        $script:MyId = $Matches[1]
        $myIdLabel.Text = 'Your SteamID: ' + $script:MyId + '   (send it to the other player)'
        $copyButton.Enabled = $true
        Set-Status 'Steam session ready. You can connect now.'
        Update-Buttons
    } elseif ($t -match '\[steam-broker\] (unavailable|refused|exception)[^\r\n]*') {
        $myIdLabel.Text = 'Steam session failed: ' + $Matches[0]
    }
}
function Start-Runtime {
    if (-not (Game-Alive) -or -not $script:MyId) { Set-Status 'Start the game first and wait for your SteamID.'; return }
    $peer = $peerBox.Text.Trim()
    if ($peer -notmatch '^\d{17}$') { Set-Status 'Enter the other player''s 17-digit SteamID.'; return }
    if ($peer -eq $script:MyId) { Set-Status 'That is your own SteamID. Enter the other player''s.'; return }
    $isHost = $hostRadio.Checked
    if ($isHost) { $Settings.friendId = $peer; $Settings.mode = 'host' } else { $Settings.hostId = $peer; $Settings.mode = 'join' }
    Save-Settings
    $ini = Join-Path $Root 'build\rig\private-join\runtime.ini'
    New-Item -ItemType Directory -Force (Split-Path $ini) | Out-Null
    Set-Content -Encoding ascii $ini "game_build=1.0.0.10-steam-global`r`ncontent_hash=none`r`nmod_hash=none"
    $desync = Join-Path $Root ('build\rig\steam-desync-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    $role = $(if ($isHost) { 'player' } else { 'friend1' })
    $steamArgs = $(if ($isHost) { @('--steam-host', '--steam-allow', $peer) } else { @('--steam-join', $peer) })
    $argv = @('--config', "`"$ini`"", '--mode', 'campaign_coop', '--network') + $steamArgs +
            @('--pid', $script:GamePid, '--role', $role, '--peer-id', $role, '--no-camera', '--tick-ms', '16', '--max-ticks', '112500', '--desync-dir', "`"$desync`"")
    New-Item -ItemType Directory -Force $Logs | Out-Null
    $stamp = (Get-Date -Format 'HHmmss')
    $script:RuntimeLog = Join-Path $Logs ("runtime_" + $script:GamePid + "_" + $stamp + ".log")
    $script:RuntimeErrLog = Join-Path $Logs ("runtime_" + $script:GamePid + "_" + $stamp + ".err.log")
    $script:RuntimeLogPos = 0
    $env:KH2COOP_AVATAR_DIAG = '1'
    $p = Start-Process -FilePath $Runtime -ArgumentList $argv -WorkingDirectory $Root -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput $script:RuntimeLog -RedirectStandardError $script:RuntimeErrLog
    $script:RuntimeProc = $p
    Write-Log ('Log: ' + $script:RuntimeLog)
    Set-Status ($(if ($isHost) { 'Hosting. ' } else { 'Joining. ' }) + 'Waiting for the other player...')
    Update-Buttons
}
function Stop-Runtime {
    $was = [bool](Runtime-Alive)
    if ($was) { try { $script:RuntimeProc.Kill() } catch {} }
    $script:RuntimeProc = $null
    if ($was) { Set-Status 'Disconnected.' }
    Update-Buttons
}
function Close-Game {
    Stop-Runtime
    if (Game-Alive) { Push-Location $Root; try { & $Kh2ctl kill --all 2>&1 | Out-Null } finally { Pop-Location } }
    Start-Sleep -Milliseconds 500
    if (Game-Alive) { try { Stop-Process -Id $script:GamePid -Force } catch {} }
    $script:GamePid = 0; $script:MyId = ''; $copyButton.Enabled = $false
    $myIdLabel.Text = 'Your SteamID: (start the game first)'
    Set-Status 'Game closed.'
    Update-Buttons
}
function Poll-RuntimeLog {
    if (-not $script:RuntimeLog -or -not (Test-Path $script:RuntimeLog)) { return }
    $t = Read-Shared $script:RuntimeLog
    if ($t.Length -gt $script:RuntimeLogPos) {
        $new = $t.Substring($script:RuntimeLogPos); $script:RuntimeLogPos = $t.Length
        foreach ($line in ($new -split "`r?`n")) {
            if (-not $line) { continue }
            if ($line -match 'Verified membership') { $status.Text = 'Connected.' }
            elseif ($line -match 'Net: rtt=(\d+)ms.*?loss=([\d.]+)%') { $status.Text = "Connected. Ping $($Matches[1]) ms, loss $($Matches[2])%" }
            elseif ($line -match 'Networking stopped|Failed to create ENet|Steam host refused|refused by relay|bad-host-allowlist') { $status.Text = 'Connection problem: ' + $line }
            if ($line -match '^\[Runtime\] (Net:|Room state:|Steam identity|Verified|Networking|Rejoin|Steam)|\[NetworkClient\]|refused|Failed|error') { $log.AppendText($line + [Environment]::NewLine) }
        }
    }
    if ($script:RuntimeProc -and $script:RuntimeProc.HasExited) {
        $script:RuntimeProc = $null
        $err = ''
        if ($script:RuntimeErrLog -and (Test-Path $script:RuntimeErrLog)) { $err = (Read-Shared $script:RuntimeErrLog).Trim() }
        if ($err) { foreach ($line in ($err -split "`r?`n" | Select-Object -Last 5)) { $log.AppendText($line + [Environment]::NewLine) } }
        Set-Status 'Co-op program exited.'; Update-Buttons
    }
}

# ---------------------------------------------------------------- wiring
$browseButton.Add_Click({
    $d = New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description = "Choose the folder that contains $GameExe"
    if ($d.ShowDialog() -eq 'OK') { $gameBox.Text = $d.SelectedPath }
})
$updateButton.Add_Click({ Check-Update })
$startButton.Add_Click({ Start-Game })
$copyButton.Add_Click({ if ($script:MyId) { Set-Clipboard $script:MyId; Set-Status 'SteamID copied.' } })
$hostRadio.Add_CheckedChanged({ if ($hostRadio.Checked) { $peerLabel.Text = "Friend's SteamID"; $peerBox.Text = $Settings.friendId } })
$joinRadio.Add_CheckedChanged({ if ($joinRadio.Checked) { $peerLabel.Text = "Host's SteamID"; $peerBox.Text = $Settings.hostId } })
$connectButton.Add_Click({ Start-Runtime })
$disconnectButton.Add_Click({ Stop-Runtime })
$exitGameButton.Add_Click({ Close-Game })
$form.Add_FormClosing({ Stop-Runtime })

$timer = New-Object System.Windows.Forms.Timer; $timer.Interval = 1000
$timer.Add_Tick({
    try { Poll-SteamId; Poll-RuntimeLog
          if ($script:GamePid -ne 0 -and -not (Game-Alive)) { Write-Log 'KH2 closed.'; $script:GamePid = 0; $script:MyId = ''; $copyButton.Enabled = $false; $myIdLabel.Text = 'Your SteamID: (start the game first)'; Stop-Runtime }
    } catch { Write-Log ('Error: ' + $_.Exception.Message) }
})
$timer.Start()
if ($hostRadio.Checked) { $peerLabel.Text = "Friend's SteamID" } else { $peerLabel.Text = "Host's SteamID" }
Update-Buttons
if (-not $NoUpdate) { $form.Add_Shown({ Check-Update -Quiet }) }
[void]$form.ShowDialog()
