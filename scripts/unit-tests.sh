#!/bin/sh
# Usage: scripts/unit-tests.sh [simulator name]     e.g. scripts/unit-tests.sh "iPhone 17"
#
# [EN] Runs the unit tests (CYLTabBarControllerTests: CYLThemeTests, CYLTabBarToolkitTests...) of the
#      CYLTabBarController-Framework scheme on an iOS simulator, on a Mac with Xcode. Without a name, the first available
#      iPhone of the newest runtime. Exits with xcodebuild's status; the log is build/unit-tests.log.
# [CN] 在 iOS 模拟器上运行 CYLTabBarController-Framework scheme 的单元测试（CYLTabBarControllerTests：CYLThemeTests、
#      CYLTabBarToolkitTests 等），需要装有 Xcode 的 Mac。不传名字时使用最新运行时中第一个可用的 iPhone。退出码为 xcodebuild 的结果；
#      日志为 build/unit-tests.log。
set -eu
cd "$(dirname "$0")/.."
DEVICE_NAME="${1:-}"
mkdir -p build

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
sys.exit(1)' "$DEVICE_NAME") || { echo "No iPhone simulator${DEVICE_NAME:+ named $DEVICE_NAME}"; xcrun simctl list devices available; exit 1; }
echo "Simulator: $DEVICE_ID"
# [EN] CLAUDE.md: free RAM before the simulator (does nothing outside macOS). [CN] CLAUDE.md：启动模拟器前释放内存（macOS 以外不做任何事）。
scripts/free-ram.sh || true
xcodebuild -version

set +e
xcodebuild test \
  -project CYLTabBarController.xcodeproj \
  -scheme CYLTabBarController-Framework \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath build/DerivedData/unit-tests \
  CODE_SIGNING_ALLOWED=NO > build/unit-tests.log 2>&1
STATUS=$?
set -e
# [EN] The result of every test case, then the failures with their reasons. [CN] 每个测试用例的结果，然后是失败原因。
grep -E "^Test Case .*(passed|failed)|error: -\[|Executed [0-9]+ tests" build/unit-tests.log || true
if [ "$STATUS" -ne 0 ]; then
  echo "xcodebuild test failed ($STATUS). Last lines:"
  tail -n 40 build/unit-tests.log
fi
exit "$STATUS"
