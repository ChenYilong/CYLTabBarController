//
//  UIViewController+CYLUtils.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] FIX: issue #535 — moved from `UIViewController+CYLTabBarControllerExtention.h` (Core). Translated from
 *      Objective-C (docs/Swift-Migration.md); Objective-C callers keep the declaration in `UIViewController+CYLUtils.h`.
 * [CN] FIX: issue #535 —— 从 Core 的 `UIViewController+CYLTabBarControllerExtention.h` 移入。已从 Objective-C 翻译为 Swift
 *      （docs/Swift-Migration.md）；Objective-C 调用方继续使用 `UIViewController+CYLUtils.h` 中的声明。
 */
extension UIViewController {

    /**
     * [EN] Returns the first view controller of a navigation controller, or the receiver itself if it is not one.
     * [CN] 若自身是导航控制器则返回其第一个子控制器，否则返回自身。
     */
    @objc(cyl_getViewControllerInsteadOfNavigationController)
    public func cyl_getViewControllerInsteadOfNavigation() -> UIViewController {
        if let navigationController = self as? UINavigationController,
           let rootViewController = navigationController.viewControllers.first {
            return rootViewController
        }
        return self
    }
}
