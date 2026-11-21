//
//  UIControl+CYLTabBarItemAnimationPlayer.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] Swift since docs/Swift-Migration.md, 2026-11-21 (was UIControl+CYLTabBarItemAnimationPlayer.{h,m}). Part of Core, compiled
//      only with an animation subspec: each one sets the Swift condition `CYL_ANIMATION_ENGINE_AVAILABLE` on the pod (the
//      Objective-C files read the C macro of the same name), the Xcode framework target and Swift Package Manager define it.
// [CN] 自 docs/Swift-Migration.md 2026-11-21 起为 Swift（原 UIControl+CYLTabBarItemAnimationPlayer.{h,m}）。属于 Core，只有引入动画子库时才编译：
//      每个动画子库在本 pod 上设置 Swift 条件 `CYL_ANIMATION_ENGINE_AVAILABLE`（Objective-C 文件读取同名 C 宏），Xcode framework target 与
//      Swift Package Manager 也定义了它。
#if CYL_ANIMATION_ENGINE_AVAILABLE
import UIKit
#if canImport(CYLAnimatedItem)
import CYLAnimatedItem
#endif

/**
 * FIX: issue #604 — public API of the tab icon animation.
 * [EN] The player of a tab button's animation, whatever its library, so that an app controls it without casting
 *      `cyl_lottieAnimationView` to `LOTAnimationView`, `PAGView`… (e.g. in `tabBarController(_:didSelectControl:)`).
 * [CN] Tab 按钮动画的播放器，与动画库无关，App 无需把 `cyl_lottieAnimationView` 强转为 `LOTAnimationView`、`PAGView` 等即可控制它
 *      （例如在 `tabBarController(_:didSelectControl:)` 中）。
 */
extension UIControl {

    /**
     * [EN] The player of this tab button's animation, nil without one. [CN] 本 Tab 按钮动画的播放器；没有动画时为 nil。
     */
    @objc(cyl_tabBarItemAnimationPlayer)
    public var cyl_tabBarItemAnimationPlayer: CYLTabBarItemAnimationPlayer? {
        CYLTabBarItemAnimationFactory.player(for: cyl_tabBarItemAnimationView())
    }
}
#endif
