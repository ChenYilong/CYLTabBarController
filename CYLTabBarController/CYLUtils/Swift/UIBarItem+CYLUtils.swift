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
    public func cylView() -> UIView? {
        guard responds(to: CYLBarItemSelectors.view) else {
            return nil
        }
        return cylValue(forKey: "view") as? UIView
    }
}

extension UITabBarItem {

    /**
     * [EN] The tab button of the item (`UITabBarButton`, or `_UITabButton` on Liquid Glass).
     * [CN] 该 item 的 Tab 按钮（`UITabBarButton`，液态玻璃下为 `_UITabButton`）。
     */
    @objc public var cyl_tabButton: UIControl? {
        cyl_replacementTabButton ?? cylView() as? UIControl
    }

    /**
     * [EN] The button drawn for this item in place of UIKit's, when a custom tab bar shows the tab (the FlatDesign tab bar
     *      hides UIKit's buttons). Held weakly; nil (default) uses UIKit's button. Set by the tab bar through
     *      `-[UIViewController cyl_setTabButton:]`, so badges set on the item (`-cyl_showBadgeValue:…`) reach the visible
     *      button instead of the hidden one.
     * [CN] 自定义 TabBar 显示该 Tab 时代替 UIKit 按钮绘制的按钮（扁平样式 TabBar 会隐藏 UIKit 的按钮）。弱引用；nil（默认）使用 UIKit 的按钮。
     *      由 TabBar 通过 `-[UIViewController cyl_setTabButton:]` 设置，使设置在 item 上的角标（`-cyl_showBadgeValue:…`）到达可见的按钮，而不是隐藏的按钮。
     */
    @objc public var cyl_replacementTabButton: UIControl? {
        get { cylWeakAssociatedObject(forKey: &CYLBarItemKeys.replacementTabButton) as? UIControl }
        set { cylSetWeakAssociatedObject(newValue, forKey: &CYLBarItemKeys.replacementTabButton) }
    }
}

private enum CYLBarItemKeys {
    static var replacementTabButton: UInt8 = 0
}

private enum CYLBarItemSelectors {
    static let view = sel_registerName("view")
}
