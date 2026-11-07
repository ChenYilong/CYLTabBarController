#!/bin/bash
# Usage: scripts/ci-build-example.sh <demo folder>     e.g. scripts/ci-build-example.sh Example-Swift-03
#
# [EN] CI helper (docs/Mac-CI-CD.md): builds one demo for the iOS Simulator, without code signing.
#      - Runs `pod install` when the folder has a Podfile (the Podfile is not changed).
#      - Uses the folder's .xcworkspace when there is one, else its .xcodeproj.
#      - Picks the app scheme from `xcodebuild -list -json`: the first scheme named after an application target of the
#        demo's own .xcodeproj (not Pods, not a Swift package), so the app's own sources are compiled, not only the
#        library. Without one, the first scheme that is not a Pods, test or framework scheme. Most demos have no shared
#        scheme, so their names are only known on the Mac.
#      Prints a summary line for the job summary and exits with xcodebuild's status.
# [CN] CI 辅助脚本（docs/Mac-CI-CD.md）：为 iOS 模拟器编译一个 Demo，不签名。
#      - 目录中有 Podfile 时先执行 `pod install`（不修改 Podfile）。
#      - 有 .xcworkspace 时使用它，否则使用 .xcodeproj。
#      - 从 `xcodebuild -list -json` 中选出 App 的 scheme：第一个与 Demo 自身 .xcodeproj（不含 Pods 与 Swift Package）中某个 App target 同名的
#        scheme，这样编译的是 App 自己的源码，而不只是库。没有时取第一个不是 Pods、测试或 framework 的 scheme。大部分 Demo 没有共享
#        scheme，名称只有在 Mac 上才能得到。
#      输出一行摘要供 job summary 使用，并以 xcodebuild 的结果作为退出码。
set -euo pipefail

DEMO_DIR="${1:?usage: $0 <demo folder>}"
cd "$(dirname "$0")/.."
ROOT="$PWD"
mkdir -p "$ROOT/build"
cd "$DEMO_DIR"

if [[ -f Podfile ]]; then
    pod install --repo-update
fi

# [EN] Globs that match nothing expand to nothing. [CN] 没有匹配的通配符展开为空。
shopt -s nullglob
WORKSPACES=(./*.xcworkspace)
PROJECTS=(./*.xcodeproj)
shopt -u nullglob
if [[ ${#WORKSPACES[@]} -gt 0 ]]; then
    CONTAINER_FLAG="-workspace"
    CONTAINER="${WORKSPACES[0]}"
elif [[ ${#PROJECTS[@]} -gt 0 ]]; then
    CONTAINER_FLAG="-project"
    CONTAINER="${PROJECTS[0]}"
else
    echo "error: no .xcworkspace or .xcodeproj in $DEMO_DIR" >&2
    exit 1
fi

# [EN] All schemes, then the first app scheme. The library's own scheme ("CYLTabBarController", from Pods or a local Swift
#      package) is listed first in many demos; picking it built only the library, so app code that no longer compiled
#      went unnoticed. A scheme named after an application target of the demo's .xcodeproj is the app.
# [CN] 列出所有 scheme，取第一个 App scheme。很多 Demo 中库自己的 scheme（"CYLTabBarController"，来自 Pods 或本地 Swift Package）排在最前；
#      以前选中它时只编译了库，App 中已无法编译的代码没有被发现。与 Demo 的 .xcodeproj 中某个 App target 同名的 scheme 即为 App。
LIST_JSON=$(xcodebuild -list -json "$CONTAINER_FLAG" "$CONTAINER")
SCHEME=$(printf '%s' "$LIST_JSON" | /usr/bin/python3 -c '
import glob, json, re, sys
data = json.load(sys.stdin)
info = data.get("workspace") or data.get("project") or {}
schemes = info.get("schemes", [])
# Schemes that build an app of the demo: its application targets, and the shared schemes whose build action makes a .app.
app_schemes = set()
for project in sys.argv[1:]:
    if project.endswith("Pods.xcodeproj"):
        continue
    try:
        pbxproj = open(project + "/project.pbxproj", encoding="utf-8").read()
    except OSError:
        continue
    for target in re.findall(r"isa = PBXNativeTarget;(.*?)\n\t\t\};", pbxproj, re.S):
        name = re.search(r"\bname = \"?([^\";]+)\"?;", target)
        if name and "com.apple.product-type.application\"" in target:
            app_schemes.add(name.group(1))
    for path in glob.glob(project + "/xcshareddata/xcschemes/*.xcscheme"):
        scheme_xml = open(path, encoding="utf-8").read()
        build_action = scheme_xml.split("</BuildAction>")[0]
        if re.search(r"BuildableName\s*=\s*\"[^\"]+\.app\"", build_action):
            app_schemes.add(path.rsplit("/", 1)[1][: -len(".xcscheme")])
def is_app(scheme):
    # Duplicate names are listed as "<name> (<project> project)".
    match = re.fullmatch(r"(.+) \((.+) project\)", scheme)
    name, project = (match.group(1), match.group(2)) if match else (scheme, "")
    return name in app_schemes and project != "Pods"
apps = [s for s in schemes if is_app(s)]
skip = ("Pods", "Test", "Tests", "UITests", "Framework", "Lottie", "MJRefresh", "SDWebImage", "Masonry")
others = [s for s in schemes if not any(word in s for word in skip)]
print((apps or others or schemes or [""])[0])
' "${PROJECTS[@]}")
if [[ -z "$SCHEME" ]]; then
    echo "error: no scheme found in $DEMO_DIR/$CONTAINER" >&2
    printf '%s\n' "$LIST_JSON" >&2
    exit 1
fi

# [EN] CocoaPods adds "${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}" to an app that links a static framework with Swift
#      code. On the xcode-27 runner TOOLCHAIN_DIR resolves to an unmounted Metal toolchain, so an Objective-C app could not
#      find the Swift back-deployment library (swiftCompatibility56). Point it at Xcode's default toolchain.
# [CN] App 链接含 Swift 代码的静态 framework 时，CocoaPods 会添加 "${TOOLCHAIN_DIR}/usr/lib/swift/${PLATFORM_NAME}"。在 xcode-27 runner 上
#      TOOLCHAIN_DIR 指向一个未挂载的 Metal 工具链，Objective-C App 因此找不到 Swift 向后兼容库（swiftCompatibility56）。这里改为指向 Xcode 默认工具链。
DEFAULT_TOOLCHAIN_DIR="$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain"

echo "Building $DEMO_DIR/$CONTAINER, scheme $SCHEME"
set +e
xcodebuild build \
    "$CONTAINER_FLAG" "$CONTAINER" \
    -scheme "$SCHEME" \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$ROOT/build/DerivedData/$DEMO_DIR" \
    CODE_SIGNING_ALLOWED=NO \
    TOOLCHAIN_DIR="$DEFAULT_TOOLCHAIN_DIR" \
    COMPILER_INDEX_STORE_ENABLE=NO 2>&1 | tee "$ROOT/build/$DEMO_DIR.log"
STATUS=${PIPESTATUS[0]}
set -e

WARNINGS=$(grep -c ': warning: ' "$ROOT/build/$DEMO_DIR.log" || true)
echo "| $DEMO_DIR | \`$SCHEME\` | $([[ "$STATUS" -eq 0 ]] && echo ✅ || echo ❌) | $WARNINGS |" >> "$ROOT/build/summary.md"
exit "$STATUS"
