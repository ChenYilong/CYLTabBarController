#!/bin/sh
# Usage: STYLE=FlatDesign scripts/theme-screenshots.sh [simulator name]
#
# [EN] Screenshots of the skins (issue #216) on an iOS simulator, on a Mac with Xcode and CocoaPods: builds the
#      Objective-C demo, installs it, then launches it once per theme with -CYLDemoThemeIdentifier <theme> (read from
#      NSUserDefaults by +[UIViewController cyl_setUpThemeSettings]) and saves a screenshot of each launch in
#      build/theme-screenshots/. STYLE=FlatDesign starts the FlatDesign tab bar (-CYLScrollHideSelfTestFlatDesign YES);
#      otherwise the default style (Liquid Glass on iOS 26). THEMES overrides the list (comma separated identifiers).
# [CN] 在 iOS 模拟器上为换肤（issue #216）截图，需要装有 Xcode 与 CocoaPods 的 Mac：编译 Objective-C Demo 并安装，然后每个主题启动一次
#      （-CYLDemoThemeIdentifier <主题>，由 +[UIViewController cyl_setUpThemeSettings] 从 NSUserDefaults 读取），每次启动保存一张截图到
#      build/theme-screenshots/。STYLE=FlatDesign 以扁平样式 TabBar 启动（-CYLScrollHideSelfTestFlatDesign YES）；否则为默认样式
#      （iOS 26 上为液态玻璃）。THEMES 可替换主题列表（以逗号分隔的 identifier）。
set -eu
cd "$(dirname "$0")/.."
DEVICE_NAME="${1:-}"
STYLE="${STYLE:-Default}"
THEMES="${THEMES:-Default,Christmas,Spring Festival,Halloween,Dark,Network}"
DERIVED=build/theme-screenshots-build
OUT=build/theme-screenshots
mkdir -p "$DERIVED" "$OUT"

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

# [EN] As scripts/scroll-hide-self-test.sh: the demo's pods, then the app for the simulator.
# [CN] 与 scripts/scroll-hide-self-test.sh 相同：先安装 Demo 的 pods，再为模拟器编译 App。
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

xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE_ID" -b
# [EN] A clean status bar, as in App Store screenshots. [CN] 干净的状态栏，与 App Store 截图一致。
xcrun simctl status_bar "$DEVICE_ID" override --time 9:41 --batteryState charged --batteryLevel 100 --wifiBars 3 || true
xcrun simctl install "$DEVICE_ID" "$APP"

STYLE_ARGUMENTS=""
STYLE_SLUG="liquid-glass"
if [ "$STYLE" = "FlatDesign" ]; then
  STYLE_ARGUMENTS="-CYLScrollHideSelfTestFlatDesign YES"
  STYLE_SLUG="flat-design"
fi

OLD_IFS=$IFS
IFS=','
for THEME in $THEMES; do
  IFS=$OLD_IFS
  SLUG=$(printf '%s' "$THEME" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9' '-' | sed -e 's/--*/-/g' -e 's/-$//')
  # [EN] Network icons are downloaded: give them longer. [CN] 网络图标需要下载：多等一会。
  WAIT=8
  [ "$THEME" = "Network" ] && WAIT=20
  FILE="$OUT/theme-switching-$STYLE_SLUG-$SLUG.png"
  for ATTEMPT in 1 2; do
    # shellcheck disable=SC2086
    xcrun simctl launch --terminate-running-process "$DEVICE_ID" "$BUNDLE_ID" -CYLDemoThemeIdentifier "$THEME" $STYLE_ARGUMENTS
    sleep "$WAIT"
    # [EN] Still running? A crash leaves a black screen behind: report it and launch once more.
    # [CN] 仍在运行？崩溃后屏幕为黑色：报告并重新启动一次。
    if xcrun simctl spawn "$DEVICE_ID" launchctl list | grep -q "UIKitApplication:$BUNDLE_ID"; then
      # [EN] A little longer for the first frame, then the screenshot. [CN] 再多等一会，确保首帧已绘制，然后截图。
      sleep 2
      xcrun simctl io "$DEVICE_ID" screenshot "$FILE"
      echo "Saved $FILE"
      break
    fi
    echo "The app is not running after launching it with theme $THEME (attempt $ATTEMPT): crashed?"
    find "$HOME/Library/Logs/DiagnosticReports" -name 'CYLTabBarController*' -newer "$DERIVED/build.log" -print \
      -exec head -n 60 {} \; 2>/dev/null || true
  done
  xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" || true
  IFS=','
done
IFS=$OLD_IFS
ls -la "$OUT"
