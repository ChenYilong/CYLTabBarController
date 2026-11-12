//
//  UIViewController+CYLTheme.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Passing a theme change down the view controller tree. Translated from Objective-C (docs/Swift-Migration.md);
 *      Objective-C callers keep the declaration in `UIViewController+CYLTheme.h`. The method is `open dynamic`:
 *      `CYLTabBarController (CYLTheme)` and apps override it and call super.
 * [CN] 将主题切换沿控制器树向下传递。已从 Objective-C 翻译（docs/Swift-Migration.md）；Objective-C 调用方继续使用
 *      `UIViewController+CYLTheme.h` 中的声明。该方法为 `open dynamic`：`CYLTabBarController (CYLTheme)` 与 App 可重写并调用 super。
 */
extension UIViewController {

    /**
     * [EN] Called on a theme change for every view controller of a visible window: children, the presented view
     *      controller and the view when it is not in a window. Subclasses call super.
     * [CN] 主题切换时对可见窗口中的每个控制器调用：子控制器、被 present 的控制器，以及不在窗口中的视图。子类需调用 super。
     */
    @objc(cyl_themeDidChangeByManager:identifier:theme:)
    open dynamic func cyl_themeDidChange(by manager: CYLThemeManager,
                                         identifier: (NSCopying & NSObjectProtocol)?,
                                         theme: NSObject?) {
        for child in children {
            child.cyl_themeDidChange(by: manager, identifier: identifier, theme: theme)
        }
        if let presented = presentedViewController, presented.presentingViewController === self {
            presented.cyl_themeDidChange(by: manager, identifier: identifier, theme: theme)
        }
        guard isViewLoaded else {
            return
        }
        setNeedsStatusBarAppearanceUpdate()
        if view.window == nil, view.superview == nil {
            view.applyThemeChange(by: manager, identifier: identifier, theme: theme, enumeratesSubviews: true)
        }
    }
}
