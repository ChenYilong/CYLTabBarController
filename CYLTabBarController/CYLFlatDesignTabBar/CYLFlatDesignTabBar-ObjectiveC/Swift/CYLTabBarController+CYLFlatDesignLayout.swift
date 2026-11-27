//
//  CYLTabBarController+CYLFlatDesignLayout.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
#if canImport(CYLBadge)
import CYLBadge
#endif
// [EN] The FlatDesign part of `-viewDidLayoutSubviews` (docs/Swift-Migration.md, step 132), called by the core through
//      `CYLFlatDesignLayout`. FlatDesign subspec only.
// [CN] `-viewDidLayoutSubviews` 的扁平样式部分（第 132 步），核心通过 `CYLFlatDesignLayout` 调用。仅属于扁平样式子库。

extension CYLTabBarController {

    /**
     [EN] Keeps the FlatDesign tab bar at `-tabBarFrame` (a new `tabBarHeight` shows at once) unless it is animating, and refreshes
          the system tab bar's visibility. False when the FlatDesign tab bar is not in place.
     [CN] 让扁平样式 TabBar 保持在 `-tabBarFrame`（新的 `tabBarHeight` 立即生效），动画过程中除外，并刷新系统 TabBar 的可见性。扁平样式 TabBar
          不存在时返回 false。
     */
    @objc(cyl_flatDesignViewDidLayoutSubviews)
    func cylFlatDesignViewDidLayoutSubviews() -> Bool {
        guard let flatTabBar = cylPrivate.cylStoredTabBar() as? CYLFlatDesignTabBar else { return false }
        let frame = cylLayoutHooks.cylTabBarFrame()
        if !cylTabBarAccessorsStorage.cylTabBarIsAnimating() && flatTabBar.frame != frame && flatTabBar.superview === view {
            flatTabBar.frame = frame
        }
        cylFlatDesignRefreshSystemTabBarVisibilityIfNeeded()
        return true
    }
}
