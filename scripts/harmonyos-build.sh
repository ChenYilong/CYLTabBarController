#!/usr/bin/env bash
# Copy CrossPlatform/harmonyos-cyltabbar to an ASCII path without spaces (hvigor refuses others) and build the HAP.
# Usage: scripts/harmonyos-build.sh [build dir, default /c/cyl-hm on Windows, ~/cyl-hm on macOS]. Exit code 0 only when the build succeeds.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/../CrossPlatform/harmonyos-cyltabbar" && pwd)"
# [EN] Windows (Git Bash) and macOS defaults; override with the first argument and DEVECO_HOME.
if [[ "$(uname)" = "Darwin" ]]; then
  DST="${1:-$HOME/cyl-hm}"
  DEVECO="${DEVECO_HOME:-/Applications/DevEco-Studio.app/Contents}"
else
  DST="${1:-/c/cyl-hm}"
  DEVECO="${DEVECO_HOME:-/c/Program Files/Huawei/DevEco Studio}"
fi
# [EN] The sectioned example lists use CollectionViewClassifyMenu's tag list, fetched at the pinned commit (classifymenu.pin).
# [CN] 带分组的示例列表使用 CollectionViewClassifyMenu 的 TagList，按 classifymenu.pin 固定的提交拉取。
"$(dirname "$0")/fetch-classifymenu.sh" || exit 1
mkdir -p "$DST"
# [EN] Every module build-profile.json5 registers (the cyl* folders, e.g. cylanimateditem_lottie and cyldeallocblockexecutor), not a fixed list.
# [CN] build-profile.json5 注册的每个模块（cyl* 目录，例如 cylanimateditem_lottie、cyldeallocblockexecutor），而不是固定列表。
MODULES=()
for dir in "$SRC"/cyl*/; do
  [[ -d "$dir" ]] && MODULES+=("$(basename "$dir")")
done
for d in AppScope entry hvigor "${MODULES[@]}"; do
  rm -rf "$DST/$d/src"
  # [EN] `._*` are macOS AppleDouble files on an external drive; ArkTS compiles `._X.ets` and fails ("Invalid character").
  # [CN] `._*` 是外置磁盘上的 macOS AppleDouble 文件；ArkTS 会编译 `._X.ets` 并报错（"Invalid character"）。
  (cd "$SRC" && find "$d" -path "*/oh_modules" -prune -o -path "*/build" -prune -o -path "*/.preview" -prune -o -name "._*" -prune -o -type f -print) |
    while IFS= read -r f; do mkdir -p "$DST/$(dirname "$f")"; cp "$SRC/$f" "$DST/$f"; done
done
cp "$SRC"/*.json5 "$SRC"/hvigorfile.ts "$DST/"
find "$DST" -name "._*" -not -path "*/oh_modules/*" -delete 2>/dev/null
export JAVA_HOME="$DEVECO/jbr" DEVECO_SDK_HOME="$DEVECO/sdk"
export PATH="$DEVECO/jbr/bin:$DEVECO/tools/node:$DEVECO/tools/ohpm/bin:$PATH"
cd "$DST" || exit 1
ohpm install --all >/dev/null 2>&1 || ohpm install --all
LOG="$DST/build.log"
node "$DEVECO/tools/hvigor/bin/hvigorw.js" --mode module -p product=default assembleHap --no-daemon >"$LOG" 2>&1
# [EN] cylanimateditem is a HAR no module depends on yet (docs/Animated-Item.md): build it too, so its errors show.
# [CN] cylanimateditem 是尚无模块依赖的 HAR（docs/Animated-Item.md）：一并编译，以便暴露其错误。
for HAR in cylanimateditem cyldeallocblockexecutor; do
  node "$DEVECO/tools/hvigor/bin/hvigorw.js" --mode module -p module=$HAR@default -p product=default assembleHar --no-daemon >>"$LOG" 2>&1
done
grep -E "ERROR|Error Message|At File|BUILD|COMPILE RESULT" "$LOG" | sed 's/\x1b\[[0-9;]*m//g' | head -40
! grep -q "BUILD FAILED" "$LOG" && grep -q "BUILD SUCCESSFUL" "$LOG" && find "$DST/entry/build" -name "*.hap"
