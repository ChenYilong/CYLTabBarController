#!/bin/bash
# Usage:
#   scripts/release-ram-restart-simulators.sh [--udid UDID]... [--keep-max N] [--timeout SECONDS] [--no-boot]
#                                             [--shutdown-others] [--allow-service-restart] [--dry-run]
#
# Restarts iOS simulators by force, even when one is occupied (a stuck boot, a running app, a test runner such as
# xcodebuild or xctest, a hung "Shutting Down"), and keeps at most N simulators booted (default 2).
#
#   --udid UDID              A simulator to restart and keep (repeat it, at most N). Without any --udid, the booted
#                            simulators are the candidates and the N most recently used ones are restarted and kept.
#   --keep-max N             How many simulators may stay booted (default 2).
#   --timeout SECONDS        How long to wait for one shutdown or boot step (default 90).
#   --no-boot                Shut the simulators down only, do not boot them again.
#   --shutdown-others        Also shut down every OTHER booted simulator (by UDID). Off by default: this Mac is shared
#                            and a script cannot tell whether another session is testing on a simulator. Use it only
#                            when the owner confirms that no session is using a simulator.
#   --allow-service-restart  Last resort when a device stays in "Shutting Down": restart CoreSimulatorService. That
#                            service is shared, so EVERY simulator of this Mac stops. Never used by default.
#   --dry-run                Print what would be done and change nothing.
#
# Rules this script keeps: it never runs `simctl shutdown all`; every simulator it stops is named by its UDID; a booted
# simulator that is not named is left alone unless --shutdown-others is given.
# Doc for developers: docs/Release-RAM.md
set -u

if [ "$(uname -s)" != "Darwin" ]; then
  echo "release-ram-restart-simulators: not macOS, nothing to do"
  exit 0
fi

KEEP_MAX=2
TIMEOUT=90
BOOT=1
OTHERS=0
SERVICE_RESTART=0
DRY=0
UDIDS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --udid) UDIDS+=("${2:?--udid needs a value}"); shift 2 ;;
    --keep-max) KEEP_MAX="${2:?--keep-max needs a value}"; shift 2 ;;
    --timeout) TIMEOUT="${2:?--timeout needs a value}"; shift 2 ;;
    --no-boot) BOOT=0; shift ;;
    --shutdown-others) OTHERS=1; shift ;;
    --allow-service-restart) SERVICE_RESTART=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) sed -n '2,28p' "$0"; exit 0 ;;
    *) echo "release-ram-restart-simulators: unknown option $1" >&2; exit 2 ;;
  esac
done

say() { echo "release-ram: simulators: $*"; }

# Runs a command and stops it after $1 seconds (macOS has no `timeout`).
with_timeout() {
  local seconds="$1"
  shift
  perl -e 'alarm shift; exec @ARGV' "$seconds" "$@"
}

# Prints the state of a device: Booted, Shutdown, Booting, "Shutting Down", or missing.
device_state() {
  xcrun simctl list devices 2>/dev/null | grep -F "$1" | head -n 1 | sed -E 's/.*\(([A-Za-z ]+)\)[[:space:]]*$/\1/'
}

# UDIDs of the booted devices, most recently used first (the newest data folder change first).
booted_udids() {
  local udid
  xcrun simctl list devices booted 2>/dev/null | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' | while read -r udid; do
    printf '%s %s\n' "$(stat -f %m "$HOME/Library/Developer/CoreSimulator/Devices/$udid/data" 2>/dev/null || echo 0)" "$udid"
  done | sort -rn | awk '{ print $2 }'
}

# This script and every process above it (the shell that started it may carry the UDID in its own command line).
own_chain() {
  local pid=$$
  while [ -n "$pid" ] && [ "$pid" -gt 1 ]; do
    echo "$pid"
    pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
  done
}

# Process ids whose command line names the UDID, without this script and its parents.
occupying_pids() {
  local pid chain
  chain="$(own_chain)"
  pgrep -f "$1" 2>/dev/null | while read -r pid; do
    echo "$chain" | grep -qx "$pid" && continue
    echo "$pid"
  done
}

wait_for_state() {
  local udid="$1" wanted="$2" waited=0
  while [ "$waited" -lt "$TIMEOUT" ]; do
    [ "$(device_state "$udid")" = "$wanted" ] && return 0
    sleep 2
    waited=$((waited + 2))
  done
  return 1
}

# Stops one device by force: a polite shutdown first, then the processes that occupy it, then a second shutdown.
force_shutdown() {
  local udid="$1" state pid pids
  state="$(device_state "$udid")"
  if [ -z "$state" ]; then
    say "$udid is not a known device"
    return 1
  fi
  if [ "$state" = "Shutdown" ]; then
    say "$udid is already shut down"
    return 0
  fi
  say "$udid is $state: shutting it down"
  [ "$DRY" = 1 ] && return 0
  with_timeout "$TIMEOUT" xcrun simctl shutdown "$udid" >/dev/null 2>&1
  wait_for_state "$udid" Shutdown && return 0

  pids="$(occupying_pids "$udid")"
  if [ -n "$pids" ]; then
    say "$udid is occupied by: $(echo "$pids" | tr '\n' ' ')(stopping them)"
    for pid in $pids; do kill -TERM "$pid" 2>/dev/null; done
    sleep 2
    for pid in $pids; do kill -KILL "$pid" 2>/dev/null; done
  fi
  with_timeout "$TIMEOUT" xcrun simctl shutdown "$udid" >/dev/null 2>&1
  wait_for_state "$udid" Shutdown && return 0

  if [ "$SERVICE_RESTART" = 1 ]; then
    say "$udid still $(device_state "$udid"): restarting CoreSimulatorService (every simulator of this Mac stops)"
    launchctl kickstart -k "gui/$(id -u)/com.apple.CoreSimulator.CoreSimulatorService" >/dev/null 2>&1 \
      || killall -9 com.apple.CoreSimulator.CoreSimulatorService >/dev/null 2>&1
    sleep 3
    with_timeout "$TIMEOUT" xcrun simctl shutdown "$udid" >/dev/null 2>&1
    wait_for_state "$udid" Shutdown && return 0
  fi
  say "$udid could not be shut down (state: $(device_state "$udid")); rerun with --allow-service-restart"
  return 1
}

boot_device() {
  local udid="$1"
  say "$udid: booting"
  [ "$DRY" = 1 ] && return 0
  with_timeout "$TIMEOUT" xcrun simctl boot "$udid" >/dev/null 2>&1
  if ! with_timeout "$((TIMEOUT * 2))" xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1; then
    say "$udid did not finish booting in $((TIMEOUT * 2)) s (state: $(device_state "$udid"))"
    return 1
  fi
  say "$udid is $(device_state "$udid")"
}

keep=()
if [ "${#UDIDS[@]}" -gt 0 ]; then
  if [ "${#UDIDS[@]}" -gt "$KEEP_MAX" ]; then
    echo "release-ram-restart-simulators: ${#UDIDS[@]} --udid values, but at most $KEEP_MAX simulators may be kept" >&2
    exit 2
  fi
  keep=("${UDIDS[@]}")
else
  while read -r udid; do
    [ -n "$udid" ] && keep+=("$udid")
  done < <(booted_udids | head -n "$KEEP_MAX")
fi

status=0

# Booted simulators that are not kept are shut down, each by its own UDID, only when --shutdown-others is given.
while read -r udid; do
  [ -z "$udid" ] && continue
  skip=0
  for kept in "${keep[@]:-}"; do
    [ "$kept" = "$udid" ] && skip=1
  done
  [ "$skip" = 1 ] && continue
  if [ "$OTHERS" != 1 ]; then
    say "$udid is booted and not named: left alone (use --shutdown-others only when no session uses it)"
    continue
  fi
  force_shutdown "$udid" || status=1
done < <(booted_udids)

for udid in "${keep[@]:-}"; do
  [ -z "$udid" ] && continue
  force_shutdown "$udid" || { status=1; continue; }
  if [ "$BOOT" = 1 ]; then
    boot_device "$udid" || status=1
  fi
done

say "booted now: $(booted_udids | tr '\n' ' ')"
exit "$status"
