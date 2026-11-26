# Usage (PowerShell):
#   .\release-ram.ps1 -DryRun                          # print what would be done, change nothing
#   .\release-ram.ps1 -Yes                             # do it without asking
#   .\release-ram.ps1 -Yes -KeepEmulator emulator-5556 # keep this Android emulator (repeat with a comma list)
#   .\release-ram.ps1 -Only apps,gradle                # run only these steps
#   .\release-ram.ps1 -Skip brightness                 # run all steps except these
#
# Windows section of docs/Release-RAM.md. Frees RAM on a development PC before emulator debugging: quits the heavy apps,
# stops watchman and Gradle, closes the Explorer windows, stops the emulators that are not kept, and dims the built-in
# display. Run it ONLY when nobody is debugging on an emulator. Steps: apps, watchman, gradle, explorer, emulators, brightness.
# macOS: use release-ram.sh instead.
param(
  [switch]$DryRun,
  [switch]$Yes,
  [string[]]$Only = @(),
  [string[]]$Skip = @(),
  [string[]]$KeepEmulator = @(),
  [string[]]$Extra = @(),
  [int]$Brightness = 1
)

$ErrorActionPreference = 'Continue'

function Say([string]$Text) { Write-Host "release-ram: $Text" }

function Test-Step([string]$Name) {
  if ($Only.Count -gt 0 -and $Only -notcontains $Name) { return $false }
  if ($Skip -contains $Name) { return $false }
  return $true
}

if (-not $DryRun -and -not $Yes) {
  Say 'this quits WeChat DevTools, DevEco Studio and the HarmonyOS emulator, watchman, Gradle, Obsidian, Android Studio,'
  Say 'the Android emulators, Chrome, bionic, opencode, MiniMax Code and TextExpander, closes the Explorer windows and dims the display.'
  $answer = Read-Host 'Is nobody debugging on an emulator right now? Type yes to continue'
  if ($answer -ne 'yes') { Say 'cancelled'; exit 1 }
}

# Stops every process with one of the names. The names are process names without .exe (see Get-Process) and are matched
# without regard to case, so `Emulator` (HarmonyOS, DevEco Studio) is also `emulator` (the Android SDK): `-PathPattern` keeps only the
# processes whose executable path matches the regular expression (checked on a Windows PC: both have the process name Emulator).
function Stop-Named([string]$Label, [string[]]$Names, [string]$PathPattern = '') {
  $found = @(Get-Process -Name $Names -ErrorAction SilentlyContinue)
  if ($PathPattern -ne '') { $found = @($found | Where-Object { $_.Path -and $_.Path -match $PathPattern }) }
  if ($found.Count -eq 0) { Say "apps: $Label is not running"; return }
  Say "apps: quitting $Label ($($found.Count) process(es))"
  if ($DryRun) { return }
  foreach ($process in $found) {
    # A polite close first (closes the main window), then a kill after a few seconds.
    [void]$process.CloseMainWindow()
  }
  Start-Sleep -Seconds 4
  foreach ($process in $found) { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue }
}

# The process name of WeChat DevTools is its Chinese product name; spelled with code points so that this file stays ASCII
# (Windows PowerShell 5.1 reads a UTF-8 file without BOM as ANSI and cannot parse the characters).
$WeChatName = -join ([char[]](0x5FAE,0x4FE1,0x5F00,0x53D1,0x8005,0x5DE5,0x5177))

function Step-Apps {
  Stop-Named 'WeChat DevTools' @($WeChatName, 'wechatdevtools', 'wechatwebdevtools')
  Stop-Named 'DevEco Studio' @('devecostudio64', 'devecostudio')
  Stop-Named 'HarmonyOS emulator' @('Emulator', 'emulator-crash-service', 'HarmonyOSEmulator', 'hmos_emulator') 'Huawei|DevEco'
  Stop-Named 'Obsidian' @('Obsidian')
  Stop-Named 'Android Studio' @('studio64', 'studio')
  Stop-Named 'Google Chrome' @('chrome')
  Stop-Named 'bionic' @('bionic')
  Stop-Named 'opencode' @('opencode')
  Stop-Named 'MiniMax Code' @('minimax', 'minimax-code')
  Stop-Named 'TextExpander' @('TextExpander')
  foreach ($name in $Extra) { Stop-Named $name @($name) }
}

function Step-Watchman { Stop-Named 'watchman (React Native)' @('watchman') }

function Step-Gradle {
  $daemons = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
      Where-Object { $_.CommandLine -match 'GradleDaemon|gradle-launcher' })
  if ($daemons.Count -eq 0) { Say 'gradle: no Gradle daemon is running'; return }
  Say "gradle: stopping $($daemons.Count) Gradle process(es)"
  if ($DryRun) { return }
  $daemons | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
}

function Step-Explorer {
  Say 'explorer: closing every Explorer window (the taskbar and desktop stay)'
  if ($DryRun) { return }
  $shell = New-Object -ComObject Shell.Application
  foreach ($window in @($shell.Windows())) { try { $window.Quit() } catch { } }
}

# Android emulators that are not kept: adb emu kill by serial. An emulator is "inactive" when no session debugs on it,
# which a script cannot know: name the ones to keep with -KeepEmulator.
function Step-Emulators {
  # adb: the PATH first, else platform-tools of ANDROID_HOME or ANDROID_SDK_ROOT (on the checked PC adb was not on the PATH, ANDROID_HOME was C:\Android\Sdk).
  $adb = (Get-Command adb -ErrorAction SilentlyContinue).Source
  if (-not $adb) {
    foreach ($root in @($env:ANDROID_HOME, $env:ANDROID_SDK_ROOT)) {
      if ($root -and (Test-Path (Join-Path $root 'platform-tools\adb.exe'))) { $adb = Join-Path $root 'platform-tools\adb.exe'; break }
    }
  }
  if (-not $adb) { Say 'emulators: adb is not on the PATH and ANDROID_HOME has no platform-tools, skipped'; return }
  $serials = @(& $adb devices | Select-String '^(emulator-\d+)\s+device' | ForEach-Object { $_.Matches[0].Groups[1].Value })
  foreach ($serial in $serials) {
    if ($KeepEmulator -contains $serial) { Say "emulators: keeping $serial"; continue }
    Say "emulators: adb emu kill $serial"
    if (-not $DryRun) { & $adb -s $serial emu kill | Out-Null }
  }
  if ($serials.Count -eq 0) { Say 'emulators: no running Android emulator' }
}

# Dims the built-in display through WMI (external monitors have no WMI brightness; lower them with their own buttons).
function Step-Brightness {
  $methods = @(Get-CimInstance -Namespace root/WMI -ClassName WmiMonitorBrightnessMethods -ErrorAction SilentlyContinue)
  if ($methods.Count -eq 0) { Say 'brightness: no built-in display with WMI brightness control; lower external monitors by hand'; return }
  Say "brightness: setting $($methods.Count) display(s) to $Brightness%"
  if ($DryRun) { return }
  foreach ($method in $methods) { Invoke-CimMethod -InputObject $method -MethodName WmiSetBrightness -Arguments @{ Timeout = 1; Brightness = $Brightness } | Out-Null }
}

foreach ($step in @('apps', 'watchman', 'gradle', 'explorer', 'emulators', 'brightness')) {
  if (Test-Step $step) {
    switch ($step) {
      'apps' { Step-Apps }
      'watchman' { Step-Watchman }
      'gradle' { Step-Gradle }
      'explorer' { Step-Explorer }
      'emulators' { Step-Emulators }
      'brightness' { Step-Brightness }
    }
  } else {
    Say "${step}: skipped"
  }
}

Say 'done. If you run AI sessions, tell every Windows and macOS session: the simulators and emulators were restarted, restart debugging if you were waiting (docs/Release-RAM.md).'
exit 0
