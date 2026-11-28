#!/usr/bin/env bash
# [EN] Builds and runs the tab bar item animation tests on macOS (Xcode command line tools), as the "Animation tests"
#      GitHub Actions workflow does: the real registry, view animator and player sources of the CYLTabBarItemAnimation
#      subspec, driven by Objective-C stand-ins of three Core helpers that are Swift now (CYLCoreStandIns.m). Only
#      Foundation is linked; stub/UIKit declares the few UIKit types those sources use.
# [CN] 在 macOS（Xcode 命令行工具）上编译并运行 Tab 图标动画的测试，与 GitHub Actions 的「Animation tests」工作流相同：使用
#      CYLTabBarItemAnimation 子库中真实的注册表、视图 animator 与播放器源码，并由三个已迁移到 Swift 的 Core 辅助函数的 Objective-C 替身驱动
#      （CYLCoreStandIns.m）。只链接 Foundation；stub/UIKit 声明这些源码用到的少量 UIKit 类型。
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
animation="$root/CYLTabBarController/CYLTabBarItemAnimation"
build="$(mktemp -d)"
trap 'rm -rf "$build"' EXIT

xcrun clang -fobjc-arc -fmodules -Wall -Wextra -Wno-unused-parameter -DDEBUG=1 \
    -include "$here/CYLCoreStandIns.h" \
    -I"$here/stub" -I"$animation" -I"$root/CYLTabBarController" -I"$root/CYLTabBarController/CYLUtils" -I"$root/CYLTabBarController/CYLBadgeView" \
    "$here/main.m" "$here/stub/UIKit.m" "$here/CYLCoreStandIns.m" "$here/CYLAnimationKeyLookupStandIns.m" \
    "$animation/CYLTabBarItemAnimatorRegistry.m" \
    "$animation/CYLTabBarItemAnimationFactory.m" \
    "$animation/CYLTabBarItemAnimationEngine.m" \
    "$animation/CYLTabBarItemAnimationTint.m" \
    "$animation/CYLTabBarItemAnimationColorCount.m" \
    "$animation/CYLTabBarItemViewAnimator.m" \
    "$animation/CYLTabBarItemAnimationPlayer.m" \
    "$root/CYLTabBarController/CYLUtils/CYLAnimationKeys.m" \
    -framework Foundation -framework CoreGraphics -framework QuartzCore -o "$build/tests"
"$build/tests"
