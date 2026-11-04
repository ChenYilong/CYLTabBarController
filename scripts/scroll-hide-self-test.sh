#!/bin/sh
# Scroll hiding self-test (issue #13) on an iOS simulator, on a Mac with Xcode and CocoaPods.
#
#   scripts/scroll-hide-self-test.sh                          # newest iPhone simulator, default demo style
#   scripts/scroll-hide-self-test.sh "iPhone 16"              # a simulator by name
#   STYLE=FlatDesign scripts/scroll-hide-self-test.sh         # start on the FlatDesign tab bar
#   RUNTIME=iOS-18 scripts/scroll-hide-self-test.sh           # an iPhone of a runtime (classic style before iOS 26);
#                                                             # a missing runtime is downloaded and an iPhone created
#
# [EN] Builds the Objective-C demo, installs it on a booted simulator, launches it with -CYLScrollHideSelfTest YES and
#      streams the console. The demo runs every automatic simulation (-[UIViewController cyl_runScrollHideSelfTest]) and
#      prints one PASS / FAIL / SKIP line each. The script exits 0 when the run finished with no FAIL, 1 otherwise.
#      The default demo uses Liquid Glass on iOS 26, which cannot be hidden from code, so every row is SKIP there; run it
#      on an iOS 18 / 17 runtime (classic style), or open the FlatDesign page and use the "Self-test" row.
# [CN] 构建 Objective-C 演示工程，安装到已启动的模拟器，以 -CYLScrollHideSelfTest YES 启动并输出控制台日志。演示工程会运行所有可自动化的模拟
#      （-[UIViewController cyl_runScrollHideSelfTest]），每项打印一行 PASS / FAIL / SKIP。运行结束且没有 FAIL 时退出码为 0，否则为 1。
#      默认演示在 iOS 26 上使用液态玻璃，无法用代码隐藏，因此全部为 SKIP；请在 iOS 18 / 17 运行时（经典样式）上运行，或打开扁平样式页面
#      使用“Self-test”行。
set -eu
cd "$(dirname "$0")/.."
DEVICE_NAME="${1:-}"
STYLE="${STYLE:-}"
RUNTIME="${RUNTIME:-}"
DERIVED=build/scroll-hide-self-test
LOG="$DERIVED/self-test.log"
BUILD_LOG="$DERIVED/build.log"
TIMEOUT=600
mkdir -p "$DERIVED"

# [EN] Prints the UDID of the first available iPhone whose runtime identifier contains $1 (any runtime when empty).
# [CN] 输出运行时标识包含 $1（为空时为任意运行时）的第一个可用 iPhone 的 UDID。
find_iphone() {
  wanted_runtime="$1"
  xcrun simctl list devices available -j | python3 -c '
import json, sys
wanted = sys.argv[1]
devices = json.load(sys.stdin)["devices"]
for runtime in sorted(devices, reverse=True):
    if wanted and wanted not in runtime:
        continue
    for device in devices[runtime]:
        if device["name"].startswith("iPhone"):
            print(device["udid"]); sys.exit(0)
sys.exit(1)' "$wanted_runtime"
}

# [EN] Creates an iPhone on the newest installed runtime whose identifier contains $1 and prints its UDID.
# [CN] 在标识包含 $1 的最新已安装运行时上创建一台 iPhone，并输出其 UDID。
create_iphone() {
  wanted_runtime="$1"
  PAIR=$(xcrun simctl list runtimes -j | python3 -c '
import json, sys
wanted = sys.argv[1]
runtimes = [r for r in json.load(sys.stdin)["runtimes"]
            if r.get("isAvailable") and r.get("platform", "iOS") == "iOS" and wanted in r["identifier"]]
for runtime in sorted(runtimes, key=lambda r: [int(x) for x in r["version"].split(".")], reverse=True):
    phones = [t for t in runtime.get("supportedDeviceTypes", []) if t.get("productFamily") == "iPhone"]
    if phones:
        print(runtime["identifier"], phones[-1]["identifier"]); sys.exit(0)
sys.exit(1)' "$wanted_runtime") || return 1
  runtime_id=${PAIR% *}
  device_type=${PAIR#* }
  xcrun simctl create "iPhone (scroll hiding self-test)" "$device_type" "$runtime_id"
}

# [EN] The version to download for a RUNTIME such as iOS-18 or iOS-17-5: a major version alone means its last release.
# [CN] RUNTIME（如 iOS-18 或 iOS-17-5）对应的下载版本：只写主版本时取该版本的最后一个发布版。
runtime_download_version() {
  runtime_name="$1"
  VERSION=$(printf '%s' "$runtime_name" | sed -e 's/^iOS-//' -e 's/-/./g')
  case "$VERSION" in
    18) echo 18.6 ;;
    17) echo 17.5 ;;
    16) echo 16.4 ;;
    *) echo "$VERSION" ;;
  esac
}

if [ -z "$DEVICE_NAME" ]; then
  if ! DEVICE_ID=$(find_iphone "$RUNTIME"); then
    if [ -z "$RUNTIME" ]; then
      echo "No iPhone simulator"; xcrun simctl list runtimes; exit 1
    fi
    # [EN] The runner (or this Mac) lacks the runtime, e.g. the xcode-27 runner only has iOS 27: create an iPhone when the
    #      runtime is installed, otherwise download it first (several GB, a few minutes).
    # [CN] runner（或本机）没有该运行时，例如 xcode-27 runner 只有 iOS 27：已安装运行时则创建 iPhone，否则先下载（数 GB，需几分钟）。
    if ! DEVICE_ID=$(create_iphone "$RUNTIME"); then
      DOWNLOAD=$(runtime_download_version "$RUNTIME")
      echo "Downloading the iOS $DOWNLOAD simulator runtime for RUNTIME=$RUNTIME"
      xcodebuild -downloadPlatform iOS -buildVersion "$DOWNLOAD" || {
        echo "Could not download the iOS $DOWNLOAD simulator runtime"; xcrun simctl list runtimes; exit 1; }
      DEVICE_ID=$(create_iphone "$RUNTIME") || {
        echo "No iPhone simulator for runtime '$RUNTIME' after the download"; xcrun simctl list runtimes; exit 1; }
    fi
  fi
else
  DEVICE_ID=$(xcrun simctl list devices available -j | python3 -c '
import json, sys
name = sys.argv[1]
for runtime, devices in json.load(sys.stdin)["devices"].items():
    for device in devices:
        if device["name"] == name:
            print(device["udid"]); sys.exit(0)
sys.exit(1)' "$DEVICE_NAME")
fi
# [EN] IPHONEOS_DEPLOYMENT_TARGET=16.0 for every target of this test build only: the demo's Podfile sets the pods to
#      iOS 15.0, where Swift code auto-links swiftCompatibility56, which Xcode 26.3 no longer ships (link error). The
#      project files are not changed.
# [CN] 仅本次测试构建的所有 target 使用 IPHONEOS_DEPLOYMENT_TARGET=16.0：演示工程的 Podfile 把 pods 设为 iOS 15.0，此时 Swift 代码会自动
#      链接 Xcode 26.3 已不再提供的 swiftCompatibility56（链接错误）。不修改工程文件。
xcodebuild -version
pod install
if ! xcodebuild -workspace CYLTabBarController.xcworkspace -scheme CYLTabBarController -configuration Debug \
  -sdk iphonesimulator -destination "id=$DEVICE_ID" -derivedDataPath "$DERIVED" \
  CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=16.0 build > "$BUILD_LOG" 2>&1; then
  echo "Build failed. Errors:"
  grep -nE "(error|fatal error):|^ld: |Undefined symbols|symbol\(s\) not found" "$BUILD_LOG" | sort -u | head -n 60 || true
  tail -n 30 "$BUILD_LOG"
  exit 1
fi
echo "Build succeeded."

echo "Simulator: $DEVICE_ID"
# [EN] Where Xcode put the app (TARGET_BUILD_DIR / WRAPPER_NAME), else any .app under the products.
# [CN] Xcode 生成 App 的位置（TARGET_BUILD_DIR / WRAPPER_NAME），没有时在产物目录中查找任意 .app。
SETTINGS=$(xcodebuild -workspace CYLTabBarController.xcworkspace -scheme CYLTabBarController -configuration Debug \
  -sdk iphonesimulator -destination "id=$DEVICE_ID" -derivedDataPath "$DERIVED" -showBuildSettings 2>/dev/null || true)
TARGET_BUILD_DIR=$(echo "$SETTINGS" | awk -F' = ' '/^ *TARGET_BUILD_DIR = /{print $2; exit}')
WRAPPER_NAME=$(echo "$SETTINGS" | awk -F' = ' '/^ *WRAPPER_NAME = /{print $2; exit}')
APP="$TARGET_BUILD_DIR/$WRAPPER_NAME"
if [ -z "$WRAPPER_NAME" ] || [ ! -d "$APP" ]; then
  APP=$(find "$DERIVED/Build/Products" -maxdepth 4 -name '*.app' -not -path '*/PlugIns/*' | head -n 1)
fi
if [ -z "$APP" ] || [ ! -d "$APP" ]; then
  echo "No .app was built"; find "$DERIVED/Build/Products" -maxdepth 3 | head -n 40; exit 1
fi
echo "App bundle: $APP"
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Info.plist")

echo "App: $BUNDLE_ID"
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE_ID" -b
xcrun simctl install "$DEVICE_ID" "$APP"

mkdir -p "$DERIVED"
: > "$LOG"
STYLE_ARGUMENTS=""
if [ "$STYLE" = "FlatDesign" ]; then
  STYLE_ARGUMENTS="-CYLScrollHideSelfTestFlatDesign YES"
fi
# shellcheck disable=SC2086
xcrun simctl launch --console-pty --terminate-running-process "$DEVICE_ID" "$BUNDLE_ID" -CYLScrollHideSelfTest YES $STYLE_ARGUMENTS > "$LOG" 2>&1 &
LAUNCH_PID=$!
ELAPSED=0
while ! grep -q "scroll hiding self-test: done" "$LOG"; do
  sleep 5
  ELAPSED=$((ELAPSED + 5))
  if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "Timed out after ${TIMEOUT}s"
    break
  fi
done
kill "$LAUNCH_PID" 2>/dev/null || true
grep "scroll hiding" "$LOG" || true

grep -q "scroll hiding self-test: done" "$LOG" || exit 1
if grep -q "scroll hiding self-test: FAIL" "$LOG"; then
  exit 1
fi
exit 0
