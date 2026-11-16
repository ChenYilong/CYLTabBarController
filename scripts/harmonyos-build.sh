#!/usr/bin/env bash
# Copy CrossPlatform/harmonyos-cyltabbar to an ASCII path without spaces (hvigor refuses others) and build the HAP.
# Usage: scripts/harmonyos-build.sh [build dir, default /c/cyl-hm on Windows, ~/cyl-hm on macOS]. Exit code 0 only when the build succeeds.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/../CrossPlatform/harmonyos-cyltabbar" && pwd)"
# [EN] Windows (Git Bash) and macOS defaults; override with the first argument and DEVECO_HOME.
if [ "$(uname)" = "Darwin" ]; then
  DST="${1:-$HOME/cyl-hm}"
  DEVECO="${DEVECO_HOME:-/Applications/DevEco-Studio.app/Contents}"
else
  DST="${1:-/c/cyl-hm}"
  DEVECO="${DEVECO_HOME:-/c/Program Files/Huawei/DevEco Studio}"
fi
mkdir -p "$DST"
for d in AppScope cyltabbar entry hvigor; do
  rm -rf "$DST/$d/src"
  (cd "$SRC" && find "$d" -path "*/oh_modules" -prune -o -path "*/build" -prune -o -path "*/.preview" -prune -o -type f -print) |
    while IFS= read -r f; do mkdir -p "$DST/$(dirname "$f")"; cp "$SRC/$f" "$DST/$f"; done
done
cp "$SRC"/*.json5 "$SRC"/hvigorfile.ts "$DST/"
export JAVA_HOME="$DEVECO/jbr" DEVECO_SDK_HOME="$DEVECO/sdk"
export PATH="$DEVECO/jbr/bin:$DEVECO/tools/node:$DEVECO/tools/ohpm/bin:$PATH"
cd "$DST" || exit 1
ohpm install --all >/dev/null 2>&1 || ohpm install --all
LOG="$DST/build.log"
node "$DEVECO/tools/hvigor/bin/hvigorw.js" --mode module -p product=default assembleHap --no-daemon >"$LOG" 2>&1
grep -E "ERROR|Error Message|At File|BUILD|COMPILE RESULT" "$LOG" | sed 's/\x1b\[[0-9;]*m//g' | head -40
grep -q "BUILD SUCCESSFUL" "$LOG" && find "$DST/entry/build" -name "*.hap"
