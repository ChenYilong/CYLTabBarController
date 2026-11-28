#!/usr/bin/env bash
# [EN] Static "ready to test" gate for the CYLBadge / CYLUtils split and the item badge API
#      (docs/Animated-Item-Badge.md). Runs anywhere (Linux too), needs no Xcode. A session runs it before the single
#      compile-check handoff; exit 1 when a hard rule fails. Written statically, not run on a Mac yet.
# [CN] CYLBadge / CYLUtils 拆分与 item 角标 API 的静态“可测试”门槛（docs/Animated-Item-Badge.md）。任何环境（含 Linux）都能运行，
#      不需要 Xcode。会话在一次性交付编译检查之前运行；硬性规则失败时退出码为 1。静态编写，尚未在 Mac 上运行。
# shellcheck disable=SC2015,SC2013,SC2086  # A && ok || bad is the report idiom here; word splitting is intended
cd "$(dirname "$0")/.." || exit 1
export LANG=C.UTF-8 LC_ALL=C.UTF-8   # CocoaPods wants UTF-8
fail=0
ok()   { echo "PASS  $1"; }
bad()  { echo "FAIL  $1"; fail=1; }
note() { echo "SKIP  $1"; }

# 1. Podspecs parse (pod ipc spec), same version in all four, no dependency cycle.
if command -v pod >/dev/null; then
  versions=""
  for spec in CYLUtils CYLBadge CYLAnimatedItem CYLTabBarController; do
    if [ -f "$spec.podspec" ]; then
      if json=$(pod ipc spec "$spec.podspec" --allow-root 2>/dev/null); then
        ok "$spec.podspec parses"
        versions="$versions $(echo "$json" | python3 -c 'import json,sys;print(json.load(sys.stdin)["version"])')"
      else bad "$spec.podspec does not parse"; fi
    else note "$spec.podspec is not written yet"; fi
  done
  [ "$(echo $versions | tr ' ' '\n' | sort -u | wc -l)" -le 1 ] && ok "one version across the podspecs" || bad "podspec versions differ:$versions"
else note "pod not installed (gem install cocoapods): podspecs unchecked"; fi

# 2. Layering greps ("Common mistakes" of the iOS document).
U=CYLTabBarController/CYLUtils; B=CYLTabBarController/CYLBadgeView
if [ -f CYLUtils.podspec ]; then
  # [EN] Only real imports count: comments, `__has_include` feature checks, the animation key files (built by CYLAnimatedItem) and the single-module fallback to
#      `CYLTabBarController-Swift.h` (Xcode framework and Carthage build the three layers into one module) do not.
  # [CN] 只有真正的导入才算：注释、`__has_include` 功能检测与动画 key 文件（由 CYLAnimatedItem 编译）不算。
  ! grep -rnE "^\s*(#\s*import|@import|import|@_exported import)\s.*(CYLAnimatedItem|CYLTabBarController)" "$U" "$B" --include=*.swift --include=*.h --include=*.m | grep -v "CYLAnimationKeys\.\|CYLTabBarController-Swift\.h" \
    && ok "CYLUtils and CYLBadge import nothing above them" || bad "CYLUtils or CYLBadge imports a higher layer"
else note "layering grep waits for CYLUtils.podspec"; fi
n=$(grep -rn "cylBadgeSnapshotImage" CYLTabBarController Example-Shared Example --include=*.swift --include=*.h --include=*.m 2>/dev/null | wc -l)
[ "$n" -eq 0 ] && ok "no cylBadgeSnapshotImage" || note "cylBadgeSnapshotImage still used ($n hits; removed after D5)"
if [ -f CYLUtils.podspec ]; then
  d=$(grep -ln "^[^#]*dependency 'CYLDeallocBlockExecutor'" CYLUtils.podspec CYLBadge.podspec CYLAnimatedItem.podspec CYLTabBarController.podspec 2>/dev/null | tr '\n' ' ')
  [ "$d" = "CYLUtils.podspec " ] && ok "only CYLUtils depends on the lifecycle library" || bad "lifecycle dependency in: $d"
fi
# every Podfile that takes CYLAnimatedItem by path also lists CYLUtils and CYLBadge (once the pods exist)
if [ -f CYLBadge.podspec ]; then
  for pf in $(grep -rl "pod 'CYLAnimatedItem'.*:path" --include=Podfile . 2>/dev/null); do
    grep -q "pod 'CYLUtils'" "$pf" && grep -q "pod 'CYLBadge'" "$pf" || bad "$pf lacks CYLUtils / CYLBadge"
  done
fi

# 3. Repo scripts.
python3 scripts/check-swift-protocol-bodies.py CYLTabBarController 2>&1 | tail -1 | grep -q "^0 hit" && ok "no protocol bodies" || bad "protocol bodies found"
python3 scripts/sync-agent-skills.py --check >/dev/null 2>&1 && ok "skills in step" || bad "sync-agent-skills --check fails"
python3 scripts/update-docs-navigation.py >/dev/null 2>&1; git diff --quiet -- docs README.md && ok "docs navigation current" || bad "docs navigation changed: commit it"
python3 scripts/check-badge-keys.py >/dev/null 2>&1 && ok "the eleven badge keys are the same on every platform" || bad "badge keys differ between platforms: python3 scripts/check-badge-keys.py"
# 4. Swift syntax, when a toolchain exists.
if command -v swiftc >/dev/null; then
  for f in $(git diff --name-only HEAD~1 -- '*.swift'); do swiftc -parse "$f" >/dev/null 2>&1 && ok "parses $f" || bad "swiftc -parse fails: $f"; done
else note "no swiftc: Swift syntax unchecked (the Mac compile check covers it)"; fi
exit $fail
