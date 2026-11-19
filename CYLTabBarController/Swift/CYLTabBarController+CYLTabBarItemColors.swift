//
//  CYLTabBarController+CYLTabBarItemColors.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The associated object keys of the per-tab colors and of the selected tab's badge.
 * [CN] 单个 Tab 颜色与选中 Tab 角标所用的关联对象 key。
 */
private enum CYLTabBarItemColorsKeys {
    /// [EN] Marks the tab buttons (and the controller) the library filled with a background color.
    /// [CN] 标记本库填充过背景色的 Tab 按钮（以及控制器）。
    static let coloredTabButtons = CYLUtilsKeys.key("cyl_coloredTabButtons")
    static let hidesBadgeOfSelectedTab = CYLUtilsKeys.key("cyl_hidesBadgeOfSelectedTab")
    /// [EN] The badge value hidden on a tab item. [CN] Tab item 上被隐藏的角标值。
    static let hiddenBadgeValue = CYLUtilsKeys.key("cyl_hiddenBadgeValue")
    /// [EN] Marks a view controller whose CYLBadge was cleared by the library. [CN] 标记本库清除过 CYLBadge 的控制器。
    static let hiddenCYLBadge = CYLUtilsKeys.key("cyl_hiddenCYLBadge")
}

// MARK: - CYLTabBarController (CYLSelectedTabBadge)

/**
 * [EN] `CYLTabBarController (CYLSelectedTabBadge)`, declared in CYLTabBarController.h. Translated from Objective-C
 *      (docs/Swift-Migration.md, step 56).
 * [CN] `CYLTabBarController (CYLSelectedTabBadge)`，声明在 CYLTabBarController.h 中。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md，第 56 步）。
 */
extension CYLTabBarController {

    @objc(cyl_hidesBadgeOfSelectedTab)
    func cylHidesBadgeOfSelectedTab() -> Bool {
        (objc_getAssociatedObject(self, CYLTabBarItemColorsKeys.hidesBadgeOfSelectedTab) as? NSNumber)?.boolValue ?? false
    }

    @objc(setCyl_hidesBadgeOfSelectedTab:)
    func cylSetHidesBadgeOfSelectedTab(_ hidesBadgeOfSelectedTab: Bool) {
        objc_setAssociatedObject(self, CYLTabBarItemColorsKeys.hidesBadgeOfSelectedTab, NSNumber(value: hidesBadgeOfSelectedTab),
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        cylUpdateBadgesOfSelectedTab()
    }

    /**
     * [EN] `cyl_hidesBadgeOfSelectedTab`: hides the selected tab's badge, restores the others'; with the property off,
     *      restores everything it hid.
     * [CN] `cyl_hidesBadgeOfSelectedTab`：隐藏选中 Tab 的角标，恢复其他 Tab 的角标；属性关闭时恢复所有被隐藏的角标。
     */
    @objc(cyl_updateBadgesOfSelectedTab)
    func cylUpdateBadgesOfSelectedTab() {
        let hides = cylHidesBadgeOfSelectedTab()
        let selectedViewController = self.selectedViewController
        for viewController in viewControllers ?? [] where !viewController.cyl_isPlaceholder {
            let hideThis = hides && viewController === selectedViewController
            let item = viewController.tabBarItem
            let hiddenValue = item.flatMap { objc_getAssociatedObject($0, CYLTabBarItemColorsKeys.hiddenBadgeValue) as? String }
            if let item, hideThis, let badgeValue = item.badgeValue {
                objc_setAssociatedObject(item, CYLTabBarItemColorsKeys.hiddenBadgeValue, badgeValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
                item.badgeValue = nil
            } else if let item, !hideThis, let hiddenValue {
                item.badgeValue = hiddenValue
                objc_setAssociatedObject(item, CYLTabBarItemColorsKeys.hiddenBadgeValue, nil, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            }
            let clearedByLibrary = (objc_getAssociatedObject(viewController, CYLTabBarItemColorsKeys.hiddenCYLBadge) as? NSNumber)?.boolValue ?? false
            if hideThis && !clearedByLibrary && viewController.cyl_isShowBadge() {
                viewController.cyl_clearBadge()
                objc_setAssociatedObject(viewController, CYLTabBarItemColorsKeys.hiddenCYLBadge, NSNumber(value: true),
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if !hideThis && clearedByLibrary {
                viewController.cyl_resumeBadge()
                objc_setAssociatedObject(viewController, CYLTabBarItemColorsKeys.hiddenCYLBadge, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}

// MARK: - Per-tab colors and the appearance sync

/**
 * [EN] The per-tab background colors and the sync of everything built from the tab bar's appearances. Translated from
 *      Objective-C (docs/Swift-Migration.md, step 56); `CYLTabBarController+CYLPrivate.h` still declares the methods, as
 *      CYLTabBarController.m calls them. The Lottie loop, the title offset copies and the FlatDesign parts stay in
 *      Objective-C behind their compile switches, reached through `cylPrivate` or at run time.
 * [CN] 单个 Tab 的背景色，以及所有基于 TabBar appearance 构建的内容的同步。已从 Objective-C 翻译（docs/Swift-Migration.md，第 56 步）；
 *      `CYLTabBarController+CYLPrivate.h` 仍声明这些方法，因为 CYLTabBarController.m 会调用。Lottie 循环、标题偏移副本与扁平样式部分仍为
 *      Objective-C（位于各自的编译开关内），通过 `cylPrivate` 或运行时调用。
 */
extension CYLTabBarController {

    /**
     * [EN] Moves the selected background color once the current run loop turn ends, after UIKit changed the selection.
     *      Also selection dependent: looping Lottie icons and the selected tab's badge.
     * [CN] 在当前 runloop 结束后（UIKit 修改选中状态之后）移动选中背景色。同样取决于选中状态：循环播放的 Lottie 图标与选中 Tab 的角标。
     */
    @objc(cyl_setNeedsUpdateSelectedBackgroundColors)
    func cylSetNeedsUpdateSelectedBackgroundColors() {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            self.cylUpdateSelectedBackgroundColorsOfTabButtons()
            self.cylPrivate.cylUpdateLoopingLottieViews()
            self.cylUpdateBadgesOfSelectedTab()
        }
    }

    /**
     * [EN] The tab attributes use `CYLTabBarItemSelectedBackgroundColor` or `CYLTabBarItemBackgroundColor`.
     * [CN] Tab 的 attributes 使用了 `CYLTabBarItemSelectedBackgroundColor` 或 `CYLTabBarItemBackgroundColor`。
     */
    private var cylUsesTabBackgroundColors: Bool {
        tabBarItemsAttributes.contains { attributes in
            attributes[CYLTabBarItemSelectedBackgroundColor] != nil || attributes[CYLTabBarItemBackgroundColor] != nil
        }
    }

    /**
     * [EN] Classic tab bar: fills each tab button with its `CYLTabBarItemBackgroundColor`, and the selected one with its
     *      `CYLTabBarItemSelectedBackgroundColor` (the unselected color when it has none). Tabs without either key are
     *      left alone. Liquid Glass draws its own selection, so it is not touched.
     * [CN] 经典 TabBar：用 `CYLTabBarItemBackgroundColor` 填充每个 Tab 按钮，选中的按钮使用 `CYLTabBarItemSelectedBackgroundColor`
     *      （未设置时使用未选中背景色）。两个键都没有的 Tab 保持不变。液态玻璃自带选中效果，不做处理。
     */
    @objc(cyl_updateSelectedBackgroundColorsOfTabButtons)
    func cylUpdateSelectedBackgroundColorsOfTabButtons() {
        guard isViewLoaded, tabBarStyleType != .flatDesign, !CYLConstants.isLiquidGlassActive(),
              let tabBar = cyl_tabBar as? CYLTabBar else {
            return
        }
        // [EN] Fast path: no tab uses the keys and no button was colored before. [CN] 快速返回：没有 Tab 使用这些键，且之前没有填充过按钮。
        let usesColors = cylUsesTabBackgroundColors
        let coloredBefore = (objc_getAssociatedObject(self, CYLTabBarItemColorsKeys.coloredTabButtons) as? NSNumber)?.boolValue ?? false
        if !usesColors && !coloredBefore {
            return
        }
        // [EN] Counted as in `-cyl_bindTabControlActions`: system tab buttons only. [CN] 与 `-cyl_bindTabControlActions` 相同，只计系统 Tab 按钮。
        let tabButtons = (tabBar.cylVisibleControls() ?? []).filter { $0.cyl_isTabButton() }
        for (tabIndex, control) in tabButtons.enumerated() {
            let attributes = tabBarItemAttributes(at: UInt(tabIndex))
            let selectedColor = attributes?[CYLTabBarItemSelectedBackgroundColor] as? UIColor
            let normalColor = attributes?[CYLTabBarItemBackgroundColor] as? UIColor
            if selectedColor == nil && normalColor == nil {
                // [EN] The keys were removed (e.g. by a reload): clear the color the library set.
                // [CN] 这些键已被移除（如重新加载）：清除本库设置的颜色。
                if (objc_getAssociatedObject(control, CYLTabBarItemColorsKeys.coloredTabButtons) as? NSNumber)?.boolValue ?? false {
                    control.backgroundColor = nil
                    objc_setAssociatedObject(control, CYLTabBarItemColorsKeys.coloredTabButtons, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                }
                continue
            }
            // [EN] Selected: its own color, else the unselected one. [CN] 选中：使用选中背景色，未设置时使用未选中背景色。
            control.backgroundColor = tabIndex == selectedIndex ? (selectedColor ?? normalColor) : normalColor
            objc_setAssociatedObject(control, CYLTabBarItemColorsKeys.coloredTabButtons, NSNumber(value: true), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        objc_setAssociatedObject(self, CYLTabBarItemColorsKeys.coloredTabButtons, usesColors ? NSNumber(value: true) : nil,
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /**
     * [EN] Brings everything built from the system tab bar's appearances up to date: the accessibility of the tabs, the
     *      title offset copies of the tabs (issue #475) or, for FlatDesign (only when CYLFlatDesignTabBar is integrated),
     *      the flat design tab bar. Runs on layout and when `tabBar.standardAppearance` / `scrollEdgeAppearance` is
     *      assigned (KVO), so a new appearance applies at once.
     * [CN] 更新所有基于系统 TabBar appearance 构建的内容：Tab 的无障碍信息、Tab 的标题偏移副本（issue #475），扁平样式时（仅在集成了
     *      CYLFlatDesignTabBar 时）为扁平样式 TabBar。在布局时以及 `tabBar.standardAppearance` / `scrollEdgeAppearance` 被赋值时（KVO）
     *      执行，新的 appearance 立即生效。
     */
    @objc(cyl_syncTabBarAppearances)
    func cylSyncTabBarAppearances() {
        cylSyncTabBarItemAccessibility()
        guard tabBarStyleType == .flatDesign else {
            // FIX: issue #475
            cylSyncTitlePositionAdjustmentAppearances()
            return
        }
        // [EN] FlatDesign is an optional subspec: its methods exist only when it is integrated. `tabBar.standardAppearance`
        //      also styles the flat design tab bar.
        // [CN] 扁平样式是可选子库：只有集成时这些方法才存在。`tabBar.standardAppearance` 同样作用于扁平样式 TabBar。
        for name in ["cyl_syncFlatDesignStandardAppearance", "cyl_syncFlatDesignTabBarItemColors"] {
            let selector = NSSelectorFromString(name)
            if responds(to: selector) {
                perform(selector)
            }
        }
    }
}
