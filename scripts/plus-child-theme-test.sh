#!/bin/sh
# Usage: STYLE=FlatDesign scripts/plus-child-theme-test.sh [simulator name]
#
# [EN] The plus child theme test. Method, scenarios, expected results, known glitches and their causes:
#      docs/Plus-Child-Theme-Switching-Test.md
#      (https://github.com/ChenYilong/CYLTabBarController/blob/master/docs/Plus-Child-Theme-Switching-Test.md).
#      On a Mac with Xcode and CocoaPods: builds the Objective-C demo and launches it once per scenario "A>B" with
#      -CYLDemoThemeIdentifier A -CYLDemoSelectIndex $SELECT_INDEX (default 2, the plus child view controller, selected
#      2 s after launch) -CYLDemoThemeSwitchTo B (the steps run as a chain, each timed from the previous one). The demo checks the plus button's stand-in
#      in the Liquid Glass selected layer 3 s after the selection ("before") and 3 s after the switch ("after") and logs
#      "plus child theme test: PASS|FAIL|SKIP ..."; the script also saves a screenshot right after each check (before,
#      after) in build/plus-child-theme-test/. Exits 1 on any FAIL, on a run that never logged "done", and, with
#      REQUIRE_PASS=1 (the Liquid Glass job), when nothing passed. STYLE=FlatDesign uses the FlatDesign tab bar, where
#      there is no stand-in (SKIP); the screenshots still show the plus button.
# [CN] PlusButton 子控制器换肤测试。测试方法、测试场景、预期效果、可能的错乱及推测原因见
#      docs/Plus-Child-Theme-Switching-Test.md
#      （https://github.com/ChenYilong/CYLTabBarController/blob/master/docs/Plus-Child-Theme-Switching-Test.md）。
#      需要装有 Xcode 与 CocoaPods 的 Mac：编译 Objective-C Demo，每个场景 “A>B” 启动一次，参数为 -CYLDemoThemeIdentifier A
#      -CYLDemoSelectIndex $SELECT_INDEX（默认 2，即 PlusButton 子控制器，启动 2 秒后选中）-CYLDemoThemeSwitchTo B
#      （各步骤按链式执行，每一步从上一步开始计时）。Demo 在选中 3 秒后（“before”）与切换 3 秒后（“after”）检查液态玻璃选中图层中的 PlusButton 替身，
#      输出 "plus child theme test: PASS|FAIL|SKIP ..."；脚本还会在每次检查之后立即截图（切换前、切换后），保存在
#      build/plus-child-theme-test/。出现 FAIL、某次运行没有输出 "done"，或设置 REQUIRE_PASS=1（液态玻璃 job）而没有任何 PASS 时，
#      退出码为 1。STYLE=FlatDesign 使用扁平样式 TabBar，没有替身（SKIP），截图仍会显示 PlusButton。
set -eu
cd "$(dirname "$0")/.."
DEVICE_NAME="${1:-}"
STYLE="${STYLE:-Default}"
SCENARIOS="${SCENARIOS:-Default>Christmas,Christmas>Pink Rose,Spring Festival>Network}"
SELECT_INDEX="${SELECT_INDEX:-2}"
DERIVED=build/plus-child-theme-test-build
OUT=build/plus-child-theme-test
LOG="$OUT/app.log"
mkdir -p "$DERIVED" "$OUT"
: > "$LOG"

DEVICE_ID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
name = sys.argv[1]
devices = json.load(sys.stdin)["devices"]
for runtime in sorted(devices, reverse=True):
    if "iOS" not in runtime:
        continue
    for device in devices[runtime]:
        if (name and device["name"] == name) or (not name and device["name"].startswith("iPhone")):
            print(device["udid"]); sys.exit(0)
sys.exit(1)' "$DEVICE_NAME") || { echo "No iPhone simulator"; xcrun simctl list devices available; exit 1; }
echo "Simulator: $DEVICE_ID"
xcodebuild -version

# [EN] As scripts/theme-screenshots.sh: the demo's pods, then the app for the simulator.
# [CN] 与 scripts/theme-screenshots.sh 相同：先安装 Demo 的 pods，再为模拟器编译 App。
pod install
find Pods -name 'CYLTabBarController.xcscheme' -print -delete
if ! xcodebuild -workspace CYLTabBarController.xcworkspace -scheme CYLTabBarController -configuration Debug \
  -sdk iphonesimulator -destination "id=$DEVICE_ID" -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=16.0 build > "$DERIVED/build.log" 2>&1; then
  echo "Build failed. Errors:"
  grep -nE "(error|fatal error):|^ld: |Undefined symbols" "$DERIVED/build.log" | sort -u | head -n 60 || true
  tail -n 30 "$DERIVED/build.log"
  exit 1
fi
APP=$(find "$DERIVED/Build/Products" -maxdepth 4 -name '*.app' -not -path '*/PlugIns/*' | head -n 1)
if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "No .app was built"; exit 1
fi
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")
echo "App: $BUNDLE_ID ($APP)"

# [EN] CLAUDE.md: free RAM before the simulator (does nothing outside macOS). [CN] CLAUDE.md：启动模拟器前释放内存（macOS 以外不做任何事）。
scripts/free-ram.sh || true
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE_ID" -b
xcrun simctl status_bar "$DEVICE_ID" override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 || true
xcrun simctl install "$DEVICE_ID" "$APP"

STYLE_ARGUMENTS=""
STYLE_SLUG="liquid-glass"
if [ "$STYLE" = "FlatDesign" ]; then
  STYLE_ARGUMENTS="-CYLScrollHideSelfTestFlatDesign YES"
  STYLE_SLUG="flat-design"
fi

# [EN] Waits until the app's test log has a line matching $1 (extended regex), at most $2 seconds.
# [CN] 等待 App 的测试日志出现匹配 $1（扩展正则）的行，最多 $2 秒。
wait_for_line() {
  WAITED=0
  while ! grep -qE "$1" "$RUN_LOG" 2>/dev/null; do
    if [ "$WAITED" -ge "$(($2 * 5))" ]; then
      echo "Timed out waiting for: $1"
      return 1
    fi
    sleep 0.2
    WAITED=$((WAITED + 1))
  done
  return 0
}

STATUS=0
OLD_IFS=$IFS
IFS=','
for SCENARIO in $SCENARIOS; do
  IFS=$OLD_IFS
  FROM=${SCENARIO%%>*}
  TO=${SCENARIO#*>}
  SLUG=$(printf '%s' "$FROM to $TO" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed -e 's/--*/-/g' -e 's/-$//')
  FILE="$OUT/plus-child-theme-$STYLE_SLUG-$SLUG"
  CONSOLE_LOG="$OUT/$STYLE_SLUG-$SLUG-console.log"
  # [EN] The app appends its test lines at once to tmp/plus-child-theme-test.log in its data container: the console
  #      stream of `simctl launch --console-pty` reached this script only when the app was closed.
  # [CN] App 把测试输出立即追加到其数据容器中的 tmp/plus-child-theme-test.log：`simctl launch --console-pty` 的控制台输出
  #      直到 App 关闭才传到本脚本。
  RUN_LOG="$(xcrun simctl get_app_container "$DEVICE_ID" "$BUNDLE_ID" data)/tmp/plus-child-theme-test.log"
  ACK_DIR="$(dirname "$RUN_LOG")"
  rm -f "$RUN_LOG" "$ACK_DIR"/ack-*
  mkdir -p "$ACK_DIR"
  : > "$RUN_LOG"
  echo "== $STYLE: $FROM > $TO (tab $SELECT_INDEX)"
  # shellcheck disable=SC2086
  xcrun simctl launch --console-pty --terminate-running-process "$DEVICE_ID" "$BUNDLE_ID" -CYLDemoThemeIdentifier "$FROM" \
    -CYLDemoSelectIndex "$SELECT_INDEX" -CYLDemoThemeSwitchTo "$TO" $STYLE_ARGUMENTS > "$CONSOLE_LOG" 2>&1 &
  LAUNCH_PID=$!
  # [EN] Each screenshot right after the app logged that check: a launch can take seconds, so fixed delays from here
  #      caught the home screen, or the theme before the switch. [CN] 每张截图都在 App 输出对应检查之后立即截取：启动可能需要
  #      数秒，从这里开始计算的固定延时曾截到主屏幕，或切换前的主题。
  for PHASE in before after; do
    wait_for_line "plus child theme test: (PASS|FAIL|SKIP) $PHASE" 90 || true
    xcrun simctl io "$DEVICE_ID" screenshot "$FILE-$PHASE.png" >/dev/null && echo "Saved $FILE-$PHASE.png"
    # [EN] Handshake: the app waits for this file before it changes what is on screen (a screenshot can take more than
    #      10 s on CI). [CN] 握手：App 等到这个文件出现才改变屏幕内容（CI 上一次截图可能超过 10 秒）。
    touch "$ACK_DIR/ack-$PHASE"
    # [EN] Then the stand-in alone (the app hides the real plus button for 2 s, 3 s after the check); not after a SKIP.
    # [CN] 然后只截替身（App 在检查 3 秒后隐藏真实的 PlusButton 2 秒）；SKIP 之后不截。
    if ! grep -q "plus child theme test: SKIP $PHASE" "$RUN_LOG"; then
      wait_for_line "plus child theme test: stand-in only $PHASE" 40 || true
      xcrun simctl io "$DEVICE_ID" screenshot "$FILE-$PHASE-stand-in-only.png" >/dev/null && echo "Saved $FILE-$PHASE-stand-in-only.png"
      touch "$ACK_DIR/ack-stand-in-only-$PHASE"
    fi
  done
  wait_for_line "plus child theme test: done" 40 || true
  kill "$LAUNCH_PID" 2>/dev/null || true
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
  cp "$RUN_LOG" "$OUT/$STYLE_SLUG-$SLUG.log" 2>/dev/null || true
  grep "plus child theme test" "$RUN_LOG" | tee -a "$LOG" || true
  if ! grep -q "plus child theme test: done" "$RUN_LOG"; then
    echo "plus child theme test: FAIL $FROM > $TO: the app never logged 'done' (crashed?)" | tee -a "$LOG"
    STATUS=1
  fi
  IFS=','
done
IFS=$OLD_IFS

if grep -q "plus child theme test: FAIL" "$LOG"; then
  STATUS=1
fi
# [EN] REQUIRE_PASS=1: a run that skipped everything tested nothing. [CN] REQUIRE_PASS=1：全部 SKIP 的运行什么也没有测试。
if [ "${REQUIRE_PASS:-0}" = "1" ] && ! grep -q "plus child theme test: PASS" "$LOG"; then
  echo "Nothing passed: every check was SKIP"
  STATUS=1
fi
ls -la "$OUT"
exit "$STATUS"
