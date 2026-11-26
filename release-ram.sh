#!/bin/bash
# Usage:
#   ./release-ram.sh --dry-run                       # print what would be done, change nothing
#   ./release-ram.sh --yes                           # do it without asking
#   ./release-ram.sh --yes --keep UDID --keep UDID   # restart and keep these simulators (at most two)
#   ./release-ram.sh --only apps,gradle              # run only these steps
#   ./release-ram.sh --skip displays,iterm           # run all steps except these
#
# macOS section of docs/Release-RAM.md. Frees RAM on a development Mac before simulator debugging: quits the heavy
# apps, stops Gradle, restarts the iOS simulators (at most two stay), restarts Finder, mirrors the displays, reduces
# transparency and hides the iTerm2 windows (iTerm2 keeps running). Run it ONLY when nobody is debugging on a simulator.
#
# Steps (names for --only and --skip): apps, gradle, simulators, finder, displays, transparency, iterm.
# Other options: --extra "App Name" (quit one more app, repeatable), --timeout SECONDS (simulator steps, default 90),
#                --shutdown-others (also shut down the simulators that are not named with --keep; see the doc),
#                --allow-service-restart (last resort for a simulator stuck in "Shutting Down").
# Windows: use release-ram.ps1 instead.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "release-ram: this is the macOS script; on Windows run release-ram.ps1 (docs/Release-RAM.md)" >&2
  exit 2
fi

DRY=0
YES=0
ONLY=""
SKIP=""
TIMEOUT=90
SHUTDOWN_OTHERS=0
SERVICE_RESTART=0
KEEP=()
EXTRA=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1; shift ;;
    --yes) YES=1; shift ;;
    --only) ONLY="${2:?--only needs a list}"; shift 2 ;;
    --skip) SKIP="${2:?--skip needs a list}"; shift 2 ;;
    --keep) KEEP+=("${2:?--keep needs a UDID}"); shift 2 ;;
    --extra) EXTRA+=("${2:?--extra needs an app name}"); shift 2 ;;
    --timeout) TIMEOUT="${2:?--timeout needs a value}"; shift 2 ;;
    --shutdown-others) SHUTDOWN_OTHERS=1; shift ;;
    --allow-service-restart) SERVICE_RESTART=1; shift ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "release-ram: unknown option $1" >&2; exit 2 ;;
  esac
done

say() { echo "release-ram: $*"; }

enabled() {
  local step="$1"
  if [ -n "$ONLY" ]; then
    case ",$ONLY," in *",$step,"*) ;; *) return 1 ;; esac
  fi
  case ",$SKIP," in *",$step,"*) return 1 ;; esac
  return 0
}

if [ "$DRY" = 0 ] && [ "$YES" = 0 ]; then
  say "this quits CleanMyMac, the WeChat and HarmonyOS tools, the HarmonyOS and Android emulators, Gradle, Obsidian,"
  say "Xcode, Android Studio and Chrome, restarts Finder and the iOS simulators, mirrors the displays and hides iTerm2."
  printf 'Is nobody debugging on a simulator right now? Type yes to continue: '
  read -r answer
  [ "$answer" = "yes" ] || { say "cancelled"; exit 1; }
fi

# Quits one app: a polite quit by name, then the processes matching the pattern are killed if they are still there.
quit_app() {
  local name="$1" pattern="$2"
  if ! pgrep -f "$pattern" >/dev/null 2>&1; then
    say "apps: $name is not running"
    return 0
  fi
  say "apps: quitting $name"
  [ "$DRY" = 1 ] && return 0
  osascript -e "tell application \"$name\" to quit" >/dev/null 2>&1
  local waited=0
  while [ "$waited" -lt 6 ] && pgrep -f "$pattern" >/dev/null 2>&1; do
    sleep 1
    waited=$((waited + 1))
  done
  if pgrep -f "$pattern" >/dev/null 2>&1; then
    say "apps: $name is still running: killing it"
    pkill -TERM -f "$pattern" 2>/dev/null
    sleep 2
    pkill -KILL -f "$pattern" 2>/dev/null
  fi
  return 0
}

step_apps() {
  quit_app "CleanMyMac X" "CleanMyMac"
  quit_app "wechatwebdevtools" "wechatwebdevtools|微信开发者工具"
  quit_app "DevEco Studio" "DevEco-Studio|DevEco Studio"
  quit_app "Obsidian" "/Obsidian.app/"
  quit_app "Xcode" "/Xcode.app/Contents/MacOS/Xcode"
  quit_app "Android Studio" "/Android Studio.app/"
  quit_app "Google Chrome" "/Google Chrome.app/Contents/MacOS/Google Chrome"
  # Emulators: the Android emulator is asked to stop through adb, then its processes are killed. The HarmonyOS emulator
  # is matched by name on a best-effort basis (the DevEco emulator binary names change between releases).
  if command -v adb >/dev/null 2>&1; then
    local serial
    for serial in $(adb devices 2>/dev/null | awk '/^emulator-/ { print $1 }'); do
      say "apps: adb emu kill $serial"
      [ "$DRY" = 1 ] || adb -s "$serial" emu kill >/dev/null 2>&1
    done
  fi
  quit_app "Android emulator" "qemu-system-(x86_64|aarch64).*-avd|/emulator/emulator "
  quit_app "HarmonyOS emulator" "[Hh]uawei.*[Ee]mulator|[Hh]armony[Oo][Ss].*[Ee]mulator|hmos.*emulator"
  local app
  for app in "${EXTRA[@]:-}"; do
    [ -n "$app" ] && quit_app "$app" "/$app.app/"
  done
}

step_gradle() {
  if pgrep -f "GradleDaemon|gradle-launcher" >/dev/null 2>&1; then
    say "gradle: stopping the Gradle daemons"
    if [ "$DRY" = 0 ]; then
      pkill -TERM -f "GradleDaemon|gradle-launcher" 2>/dev/null
      sleep 2
      pkill -KILL -f "GradleDaemon|gradle-launcher" 2>/dev/null
    fi
  else
    say "gradle: no Gradle daemon is running"
  fi
}

step_simulators() {
  local args=(--timeout "$TIMEOUT")
  local udid
  for udid in "${KEEP[@]:-}"; do
    [ -n "$udid" ] && args+=(--udid "$udid")
  done
  [ "$SHUTDOWN_OTHERS" = 1 ] && args+=(--shutdown-others)
  [ "$SERVICE_RESTART" = 1 ] && args+=(--allow-service-restart)
  [ "$DRY" = 1 ] && args+=(--dry-run)
  "$HERE/scripts/release-ram-restart-simulators.sh" "${args[@]}"
}

step_finder() {
  say "finder: closing every Finder window, then restarting Finder"
  [ "$DRY" = 1 ] && return 0
  osascript -e 'tell application "Finder" to close every window' >/dev/null 2>&1
  killall Finder >/dev/null 2>&1
  return 0
}

step_displays() {
  if [ "$DRY" = 1 ]; then
    swift "$HERE/scripts/release-ram-mirror-displays.swift" --dry-run
  else
    swift "$HERE/scripts/release-ram-mirror-displays.swift"
  fi
}

step_transparency() {
  local current
  current="$(defaults read com.apple.universalaccess reduceTransparency 2>/dev/null || echo 0)"
  if [ "$current" = "1" ]; then
    say "transparency: already reduced"
    return 0
  fi
  say "transparency: reducing it"
  [ "$DRY" = 1 ] && return 0
  if ! defaults write com.apple.universalaccess reduceTransparency -bool true 2>/dev/null; then
    say "transparency: macOS refused the change; set System Settings > Accessibility > Display > Reduce transparency by hand"
  fi
  return 0
}

step_iterm() {
  say "iterm: hiding every iTerm2 window (iTerm2 keeps running in the background)"
  [ "$DRY" = 1 ] && return 0
  osascript -e 'tell application "System Events" to set visible of process "iTerm2" to false' >/dev/null 2>&1 \
    || say "iterm: macOS refused (System Settings > Privacy & Security > Accessibility for your terminal); press Cmd+H in iTerm2"
  return 0
}

for step in apps gradle simulators finder displays transparency iterm; do
  if enabled "$step"; then
    "step_$step"
  else
    say "$step: skipped"
  fi
done

say "done. If you run AI sessions, tell every Windows and macOS session: the simulators were restarted, restart simulator debugging if you were waiting (docs/Release-RAM.md)."
