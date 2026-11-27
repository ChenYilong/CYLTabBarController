#!/usr/bin/env bash
# Copy CrossPlatform/harmonyos-cyltabbar to an ASCII path without spaces (hvigor refuses others) and build the HAP.
# Usage: scripts/harmonyos-build.sh [build dir, default /c/cyl-hm on Windows, ~/cyl-hm on macOS] [--ohos-test] [--run-ohos-test]
#   --ohos-test      also builds the ohosTest HAP for the x86_64 emulator (-p buildMode=emulatorTest, cylanimateditem/README.md)
#   --run-ohos-test  also installs it on the device and runs the hypium tests (`hdc shell aa test ... OpenHarmonyTestRunner`); env HDC_TARGET picks
#                    the device (e.g. 127.0.0.1:5555), HDC the hdc binary. The exit code is 0 only when the build and, with this flag, every test pass.
# Env: DEVECO_HOME, PYTHON (the interpreter that fetches the PAG sample; default python3, python or py).
# Exit code 0 only when the build succeeds.
set -uo pipefail
SRC="$(cd "$(dirname "$0")/../CrossPlatform/harmonyos-cyltabbar" && pwd)"
# [EN] Windows (Git Bash) and macOS defaults; override with the first argument and DEVECO_HOME.
DST_ARG=""
OHOS_TEST=0
RUN_OHOS_TEST=0
for ARG in "$@"; do
  case "$ARG" in
    --ohos-test) OHOS_TEST=1 ;;
    --run-ohos-test) OHOS_TEST=1; RUN_OHOS_TEST=1 ;;
    *) DST_ARG="$ARG" ;;
  esac
done
if [[ "$(uname)" = "Darwin" ]]; then
  DST="${DST_ARG:-$HOME/cyl-hm}"
  DEVECO="${DEVECO_HOME:-/Applications/DevEco-Studio.app/Contents}"
else
  DST="${DST_ARG:-/c/cyl-hm}"
  DEVECO="${DEVECO_HOME:-/c/Program Files/Huawei/DevEco Studio}"
fi
# [EN] The "Rive and PAG" page plays a PAG sample that the repository does not keep: fetch it (pinned, SHA-256 checked) and put it in the
#      git-ignored rawfile folder. Without it the build still succeeds and the page says the file is missing.
# [CN] “Rive 与 PAG”页面播放仓库不保存的 PAG 示例文件：获取（固定版本，校验 SHA-256）并放入不入库的 rawfile 目录。没有它构建仍然成功，页面会提示缺少文件。
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PYTHON_BIN="${PYTHON:-$(command -v python3 || command -v python || command -v py || true)}"
if [[ -n "$PYTHON_BIN" ]]; then
  "$PYTHON_BIN" "$ROOT/scripts/fetch-animation-resources.py" PAGResources >/dev/null 2>&1 || echo "PAG sample not fetched (python: $PYTHON_BIN)" >&2
fi
if [[ -f "$ROOT/Example-Shared/PAGResources/pag-ios/0.pag" ]]; then
  mkdir -p "$SRC/entry/src/main/resources/rawfile/pag"
  cp "$ROOT/Example-Shared/PAGResources/pag-ios/0.pag" "$SRC/entry/src/main/resources/rawfile/pag/demo.pag"
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
if grep -q "BUILD FAILED" "$LOG" || ! grep -q "BUILD SUCCESSFUL" "$LOG"; then
  exit 1
fi
find "$DST/entry/build" -name "*.hap"
if [[ "$OHOS_TEST" = 1 ]]; then
  # [EN] The ohosTest HAP for the x86_64 emulator (no arm64-v8a .so files): the recipe of cylanimateditem/README.md, "Device tests".
  # [CN] 面向 x86_64 模拟器的 ohosTest HAP（不含 arm64-v8a .so）：cylanimateditem/README.md「Device tests」中的做法。
  TEST_LOG="$DST/build-ohostest.log"
  node "$DEVECO/tools/hvigor/bin/hvigorw.js" --mode module -p module=entry@ohosTest -p isOhosTest=true -p buildMode=emulatorTest -p product=default assembleHap --no-daemon >"$TEST_LOG" 2>&1
  grep -E "ERROR|Error Message|At File|BUILD|COMPILE RESULT" "$TEST_LOG" | sed 's/\x1b\[[0-9;]*m//g' | head -40
  if grep -q "BUILD FAILED" "$TEST_LOG" || ! grep -q "BUILD SUCCESSFUL" "$TEST_LOG"; then
    exit 1
  fi
  TEST_HAP="$(find "$DST/entry/build" -name "entry-ohosTest*.hap" | head -1)"
  echo "$TEST_HAP"
  if [[ "$RUN_OHOS_TEST" = 1 ]]; then
    HDC_BIN="${HDC:-$DEVECO/sdk/default/openharmony/toolchains/hdc}"
    HDC_ARGS=()
    if [[ -n "${HDC_TARGET:-}" ]]; then
      HDC_ARGS=(-t "$HDC_TARGET")
    fi
    # [EN] MSYS_NO_PATHCONV: Git Bash must not turn /data/... into a Windows path for hdc. [CN] MSYS_NO_PATHCONV：Git Bash 不得把 /data/... 转成 Windows 路径。
    export MSYS_NO_PATHCONV=1
    # [EN] B22: install from the build folder with RELATIVE paths: with MSYS_NO_PATHCONV a /c/... path reached hdc unconverted and was read relative to the
    #      current folder (C:\w\hm\/c/w/hm/...); hdc exits 0 even when an install fails, so its output is checked, else the OLD test HAP on the device ran
    #      and the run "passed". The app HAP goes first (the test HAP needs the matching app), then the app is started before `aa test`.
    # [CN] B22：在构建目录中用「相对」路径安装：设置 MSYS_NO_PATHCONV 后 /c/... 路径未经转换传给 hdc，被当作相对当前目录的路径（C:\w\hm\/c/w/hm/...）；
    #      hdc 安装失败时退出码仍为 0，所以检查其输出，否则设备上「旧的」测试 HAP 会运行并「通过」。先装应用 HAP（测试 HAP 需要对应的应用），在 `aa test` 前启动应用。
    cyl_hdc_install() {
      local out
      out="$(cd "$DST" && "$HDC_BIN" ${HDC_ARGS[@]+"${HDC_ARGS[@]}"} install -r "$1" 2>&1)"
      echo "$out"
      echo "$out" | grep -q "install bundle successfully" || exit 1
    }
    APP_HAP="$(cd "$DST" && find entry/build -path "*outputs/emulator*" -name "entry-*.hap" | head -1)"
    if [[ -n "$APP_HAP" ]]; then
      cyl_hdc_install "$APP_HAP"
    fi
    cyl_hdc_install "${TEST_HAP#"$DST"/}"
    "$HDC_BIN" ${HDC_ARGS[@]+"${HDC_ARGS[@]}"} shell aa start -b com.cyl.tabbar.harmony -a EntryAbility
    RESULT="$("$HDC_BIN" ${HDC_ARGS[@]+"${HDC_ARGS[@]}"} shell aa test -b com.cyl.tabbar.harmony -m entry_test -s unittest OpenHarmonyTestRunner -s timeout 15000 2>&1)"
    echo "$RESULT"
    # [EN] hypium prints "Tests run: N, Failure: F, Error: E, Pass: P, Ignore: I"; the run passes with no failure and no error.
    # [CN] hypium 输出 "Tests run: N, Failure: F, Error: E, Pass: P, Ignore: I"；没有失败与错误才算通过。
    echo "$RESULT" | grep -Eq "Failure: 0, Error: 0" || exit 1
  fi
fi
