//
//  UIBarItem+CYLUtils.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Translated from Objective-C (docs/Swift-Migration.md); Objective-C callers keep the declarations in
 *      `UIBarItem+CYLUtils.h`.
 * [CN] 已从 Objective-C 翻译为 Swift（docs/Swift-Migration.md）；Objective-C 调用方继续使用 `UIBarItem+CYLUtils.h` 中的声明。
 */
extension UIBarItem {

    /**
     * [EN] The view of a `UIBarButtonItem` or `UITabBarItem` (UIKit creates it lazily: nil until the item is shown).
     * [CN] `UIBarButtonItem` 或 `UITabBarItem` 的视图（UIKit 延迟创建：显示之前为 nil）。
     */
    @objc(cyl_view)
    public func cyl_view() -> UIView? { // NOSONAR: kept API name
        guard responds(to: CYLBarItemSelectors.view) else {
            return nil
        }
        return cyl_value(forKey: "view") as? UIView
    }
}

extension UITabBarItem {

    /**
     * [EN] The tab button of the item (`UITabBarButton`, or `_UITabButton` on Liquid Glass).
     * [CN] 该 item 的 Tab 按钮（`UITabBarButton`，液态玻璃下为 `_UITabButton`）。
     */
    @objc public var cyl_tabButton: UIControl? {
        cyl_view() as? UIControl
    }
}

private enum CYLBarItemSelectors {
    static let view = sel_registerName("view")
}
