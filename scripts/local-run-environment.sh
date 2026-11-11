#!/bin/sh
# Keeps the local run environment comment at the top of .github/workflows/ios.yml (AGENTS.md, "CI/CD and where tests run").
#
#   scripts/local-run-environment.sh            # check and, when needed, write the comment
#   scripts/local-run-environment.sh --check    # exit 1 when the comment is missing or out of date, change nothing
#   scripts/local-run-environment.sh FILE       # another workflow file
#
# Run it before every local build (directly on this Mac, not GitHub CI/CD). The local environment is agreed to stay the
# same, so the comment changes only when a version changes: it is added when missing, left alone when macOS and Xcode are
# the same, and rewritten when either differs. It is the first line of the file, so it is the first thing read before a
# local run:
#   # local-run-environment: macOS 27.3 (26C5035r), Xcode 27.2 (27B5028f)
set -eu
cd "$(dirname "$0")/.."

CHECK=0
FILE=.github/workflows/ios.yml
for arg in "$@"; do
    case "$arg" in
        --check) CHECK=1 ;;
        *) FILE="$arg" ;;
    esac
done
[ -f "$FILE" ] || { echo "no such file: $FILE" >&2; exit 2; }

DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export DEVELOPER_DIR
MACOS="$(sw_vers -productVersion) ($(sw_vers -buildVersion))"
XCODE="$(xcodebuild -version | awk 'NR==1{v=$2} NR==2{b=$3} END{print v " (" b ")"}')"
LINE="# local-run-environment: macOS ${MACOS}, Xcode ${XCODE}"
FIRST="$(head -n 1 "$FILE")"

case "$FIRST" in
    "$LINE")
        echo "unchanged: $LINE" ;;
    "# local-run-environment:"*)
        [ "$CHECK" = 1 ] && { echo "out of date: $FIRST (now: ${LINE#\# })"; exit 1; }
        TMP="$(mktemp)"; { echo "$LINE"; tail -n +2 "$FILE"; } > "$TMP" && cat "$TMP" > "$FILE" && rm -f "$TMP"
        echo "updated: $LINE" ;;
    *)
        [ "$CHECK" = 1 ] && { echo "missing: $LINE"; exit 1; }
        TMP="$(mktemp)"; { echo "$LINE"; cat "$FILE"; } > "$TMP" && cat "$TMP" > "$FILE" && rm -f "$TMP"
        echo "added: $LINE" ;;
esac
