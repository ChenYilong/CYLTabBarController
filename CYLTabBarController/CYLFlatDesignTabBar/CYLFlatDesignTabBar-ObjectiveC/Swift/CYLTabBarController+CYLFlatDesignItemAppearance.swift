//
//  CYLTabBarController+CYLFlatDesignItemAppearance.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] The FlatDesign part of block 2 (docs/Swift-Migration.md, step 125): title offsets and image insets of the FlatDesign
//      items (`CYLFlatDesignItemAppearance`, called by the core), the item colors and fonts of the tab attributes, and the
//      mirroring of `tabBar.standardAppearance` onto the FlatDesign tab bar. FlatDesign subspec only.
// [CN] 第 2 块的扁平样式部分（第 125 步）：扁平样式 item 的标题偏移与图片内边距（`CYLFlatDesignItemAppearance`，由核心调用）、Tab 属性中的 item
//      颜色与字体，以及把 `tabBar.standardAppearance` 映射到扁平样式 TabBar。仅属于扁平样式子库。

/// [EN] The FlatDesign item of a view controller, read without creating one. [CN] 视图控制器的扁平样式 item，读取时不会创建。
private let cylFlatDesignTabBarItemKey = CYLUtilsKeys.key("cyl_tabBarItem")
private var cylDefaultStandardAppearanceKey: UInt8 = 0
private var cylSyncedStandardAppearanceKey: UInt8 = 0
private var cylSyncedItemStandardAppearanceKey: UInt8 = 0

/// [EN] Whether `appearance` differs from what was mirrored last. [CN] `appearance` 是否与上次映射的不同。
private func cylAppearanceChanged(_ appearance: AnyObject?, _ synced: AnyObject?) -> Bool {
    if appearance === synced { return false }
    guard let appearance else { return true }
    return !appearance.isEqual(synced)
}

extension CYLTabBarController {

    private var cylFlatDesignTabBarIfShown: CYLFlatDesignTabBar? {
        tabBarStyleType == .flatDesign ? cylPrivate.cylStoredTabBar() as? CYLFlatDesignTabBar : nil
    }

    private func cylFlatDesignItems() -> [(UIViewController, CYLFlatDesignTabBarItem)] {
        (viewControllers ?? []).compactMap { viewController in
            (objc_getAssociatedObject(viewController, cylFlatDesignTabBarItemKey) as? CYLFlatDesignTabBarItem).map { (viewController, $0) }
        }
    }

    private func cylRelayOutFlatDesignTabBar(_ tabBar: CYLFlatDesignTabBar) {
        tabBar.subviews.forEach { $0.setNeedsLayout() }
        tabBar.setNeedsLayout()
    }

    /// [EN] `CYLFlatDesignItemAppearance`: the controller's title offset on every item without its own (issue #475).
    /// [CN] `CYLFlatDesignItemAppearance`：把控制器的标题偏移应用到没有自行设置的每个 item（issue #475）。
    @objc(cyl_flatDesignApplyTitlePositionAdjustment:)
    func cylFlatDesignApplyTitlePositionAdjustment(_ offset: UIOffset) -> Bool {
        guard let tabBar = cylFlatDesignTabBarIfShown else { return false }
        for (_, item) in cylFlatDesignItems() {
            item.titlePositionAdjustment = CYLTitlePositionAdjustment(forItem: item, controllerOffset: offset)
        }
        cylRelayOutFlatDesignTabBar(tabBar)
        return true
    }

    /// [EN] `CYLFlatDesignItemAppearance`: the controller's image insets on every item without its own (issue #95).
    /// [CN] `CYLFlatDesignItemAppearance`：把控制器的图片内边距应用到没有自行设置的每个 item（issue #95）。
    @objc(cyl_flatDesignApplyImageInsets:)
    func cylFlatDesignApplyImageInsets(_ insets: UIEdgeInsets) -> Bool {
        guard let tabBar = cylFlatDesignTabBarIfShown else { return false }
        for (_, item) in cylFlatDesignItems() {
            item.imageInsets = CYLImageInsets(forItem: item, controllerInsets: insets)
        }
        cylRelayOutFlatDesignTabBar(tabBar)
        return true
    }

    /**
     [EN] The title colors and fonts and the background colors of the tab attributes, on the FlatDesign items (only what changed).
     [CN] 把 Tab 属性中的标题颜色、字体与背景色应用到扁平样式 item（只改变化的部分）。
     */
    @objc(cyl_syncFlatDesignTabBarItemColors)
    func cylSyncFlatDesignTabBarItemColors() {
        let viewControllers = self.viewControllers ?? []
        for (index, viewController) in viewControllers.enumerated() {
            guard let attributes = tabBarItemAttributes(at: UInt(index)),
                  let item = objc_getAssociatedObject(viewController, cylFlatDesignTabBarItemKey) as? CYLFlatDesignTabBarItem else { continue }
            let titleFont = attributes[CYLTabBarItemTitleFont] as? UIFont
            let selectedTitleFont = attributes[CYLTabBarItemSelectedTitleFont] as? UIFont ?? titleFont
            let values: [(UIControl.State, NSAttributedString.Key, Any?)] = [
                (.normal, .foregroundColor, attributes[CYLTabBarItemTitleColor] as? UIColor),
                (.selected, .foregroundColor, attributes[CYLTabBarItemSelectedTitleColor] as? UIColor),
                (.normal, .font, titleFont),
                (.selected, .font, selectedTitleFont),
            ]
            for (state, key, value) in values {
                guard let value = value as? NSObject else { continue }
                let current = item.titleTextAttributes(for: state) ?? [:]
                if (current[key] as? NSObject)?.isEqual(value) == true { continue }
                var textAttributes = current
                textAttributes[key] = value
                item.setTitleTextAttributes(textAttributes, for: state)
            }
            if let color = attributes[CYLTabBarItemBackgroundColor] as? UIColor, item.backgroundColor != color {
                item.backgroundColor = color
            }
            if let color = attributes[CYLTabBarItemSelectedBackgroundColor] as? UIColor, item.selectedBackgroundColor != color {
                item.selectedBackgroundColor = color
            }
        }
    }

    /// [EN] Records the system tab bar's default appearance, to tell a customized one later. [CN] 记录系统 TabBar 的默认外观，以便之后识别自定义外观。
    @objc(cyl_recordDefaultStandardAppearance)
    func cylRecordDefaultStandardAppearance() {
        guard objc_getAssociatedObject(self, &cylDefaultStandardAppearanceKey) == nil else { return }
        objc_setAssociatedObject(self, &cylDefaultStandardAppearanceKey, tabBar.standardAppearance, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    private func cylIsCustomizedStandardAppearance(_ appearance: UITabBarAppearance?) -> Bool {
        guard let appearance else { return false }
        let defaultAppearance = objc_getAssociatedObject(self, &cylDefaultStandardAppearanceKey) as? UITabBarAppearance ?? UITabBarAppearance()
        return appearance !== defaultAppearance && !appearance.isEqual(defaultAppearance)
    }

    /**
     [EN] Mirrors a customized `tabBar.standardAppearance` (and each tab item's) onto the FlatDesign tab bar and its items, unless
          the app set the FlatDesign one itself.
     [CN] 把自定义的 `tabBar.standardAppearance`（以及每个 TabBarItem 的）映射到扁平样式 TabBar 及其 item，App 自行设置了扁平样式外观时除外。
     */
    @objc(cyl_syncFlatDesignStandardAppearance)
    func cylSyncFlatDesignStandardAppearance() {
        guard let flatTabBar = cylFlatDesignTabBarIfShown else { return }
        let standardAppearance = tabBar.standardAppearance
        let synced = objc_getAssociatedObject(self, &cylSyncedStandardAppearanceKey) as AnyObject?
        let mirrored: UITabBarAppearance? = cylIsCustomizedStandardAppearance(standardAppearance) ? standardAppearance : nil
        if cylAppearanceChanged(mirrored, synced) {
            let flatAppearance = flatTabBar.standardAppearance
            let flatAppearanceIsMirrored = flatAppearance == nil || flatAppearance?.isEqual(synced) == true
            if mirrored != nil || flatAppearanceIsMirrored {
                flatTabBar.standardAppearance = mirrored
            }
            objc_setAssociatedObject(self, &cylSyncedStandardAppearanceKey, mirrored, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        for (viewController, item) in cylFlatDesignItems() {
            let itemAppearance = viewController.tabBarItem.standardAppearance
            let syncedItem = objc_getAssociatedObject(item, &cylSyncedItemStandardAppearanceKey) as AnyObject?
            if cylAppearanceChanged(itemAppearance, syncedItem) {
                item.standardAppearance = itemAppearance
                objc_setAssociatedObject(item, &cylSyncedItemStandardAppearanceKey, itemAppearance, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}
