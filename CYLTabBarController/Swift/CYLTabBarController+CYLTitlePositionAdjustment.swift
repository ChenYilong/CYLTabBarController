//
//  CYLTabBarController+cylTitlePositionAdjustment.swift
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
/**
 * [EN] The associated object keys shared with CYLTabBarController.m, which reads and writes them too (selector-based
 *      keys, the same pointer on both sides).
 * [CN] 与 CYLTabBarController.m 共用的关联对象 key（它也会读写；基于 selector 的 key，两边是同一个指针）。
 */
enum CYLTitlePositionAdjustmentKeys {
    /// [EN] The offset CYL wrote on a `UITabBarItem`. [CN] CYL 写入 `UITabBarItem` 的偏移。
    static let setByCYL = CYLUtilsKeys.key("cyl_titlePositionAdjustmentSetByCYL")
}

/**
 * [EN] The keys only Swift uses: the per-item appearance states and the per-tab colors.
 * [CN] 只有 Swift 使用的 key：每个 item 的 appearance 状态与单个 Tab 的颜色。
 */
private enum CYLItemAppearanceKeys {
    static let standardAppearance = CYLUtilsKeys.key("cyl_titlePositionAdjustmentStandardAppearance")
    static let scrollEdgeAppearance = CYLUtilsKeys.key("cyl_titlePositionAdjustmentScrollEdgeAppearance")
    /// [EN] The per-tab colors and title fonts a tab asked for; nil when none. [CN] Tab 设置的颜色与标题字体；没有时为 nil。
    static let colors = CYLUtilsKeys.key("cyl_tabBarItemColors")
}

/**
 * [EN] What one installed item appearance was built from: the bar appearance itself (not a copy, so an unchanged tab
 *      bar is recognized by identity and nothing is installed again on layout), the app's own item appearance, and the
 *      offset and colors it was built with (they tell when to rebuild).
 * [CN] 一个已安装的 item appearance 的构建来源：bar appearance 本身（不是副本，TabBar 未改变时按对象身份即可识别，布局时不会重复安装）、
 *      App 自己的 item appearance，以及构建时的偏移与颜色（用于判断是否需要重建）。
 */
@available(iOS 13.0, *)
private final class CYLItemAppearanceState: NSObject {
    let installed: UITabBarAppearance
    let source: UITabBarAppearance
    let appBase: UITabBarAppearance?
    let offset: NSValue?
    let colors: NSDictionary?

    init(installed: UITabBarAppearance, source: UITabBarAppearance, appBase: UITabBarAppearance?, offset: NSValue?, colors: NSDictionary?) {
        self.installed = installed
        self.source = source
        self.appBase = appBase
        self.offset = offset
        self.colors = colors
    }
}

/**
 * FIX: issue #475 (titlePositionAdjustment has no effect on iOS 13)
 * [EN] Since iOS 13 a tab bar that uses `UITabBarAppearance` ignores `-[UITabBarItem titlePositionAdjustment]`: the title
 *      offset comes from the item appearances of the bar appearance instead. So a tab with an offset (or per-tab colors)
 *      also gets its own `standardAppearance` (and `scrollEdgeAppearance` on iOS 15+): a copy of the tab bar's, with the
 *      offset and colors written into every layout and state. The copy is rebuilt when the tab bar's appearance changes
 *      (checked on layout), and an appearance the app installed on the item itself is kept as the base and restored when
 *      the offset is reset. Translated from Objective-C (docs/Swift-Migration.md, step 57).
 * [CN] iOS 13 起，使用 `UITabBarAppearance` 的 TabBar 会忽略 `-[UITabBarItem titlePositionAdjustment]`，标题偏移改由 bar appearance
 *      中的 item appearance 决定。因此有偏移（或单个 Tab 颜色）的 Tab 还会得到自己的 `standardAppearance`（iOS 15+ 还有
 *      `scrollEdgeAppearance`）：TabBar appearance 的副本，偏移与颜色写入每种布局与状态。TabBar 的 appearance 改变时（布局时检查）
 *      会重建副本；App 自己在 item 上设置的 appearance 会作为基础保留，偏移重置时恢复。已从 Objective-C 翻译（docs/Swift-Migration.md，第 57 步）。
 */
extension CYLTabBarController {

    // MARK: - Building an item appearance

    /**
     * [EN] The per-tab colors and title fonts (`CYLTabBarItemTitleColor`, `CYLTabBarItemTitleFont`...) of `attributes`;
     *      nil when none.
     * [CN] `attributes` 中单个 Tab 的颜色与标题字体（`CYLTabBarItemTitleColor`、`CYLTabBarItemTitleFont` 等）；没有时为 nil。
     */
    private static func cylItemColors(from attributes: [String: Any]?) -> NSDictionary? {
        guard let attributes else {
            return nil
        }
        var colors: [String: Any] = [:]
        for key in [cylTabBarItemTitleColor, cylTabBarItemSelectedTitleColor, cylTabBarItemIconColor, cylTabBarItemSelectedIconColor] {
            if let color = attributes[key] as? UIColor {
                colors[key] = color
            }
        }
        for key in [cylTabBarItemTitleFont, cylTabBarItemSelectedTitleFont] {
            if let font = attributes[key] as? UIFont {
                colors[key] = font
            }
        }
        return colors.isEmpty ? nil : colors as NSDictionary
    }

    /**
     * [EN] Sets one title text attribute (color or font) of a state, keeping the others.
     * [CN] 设置某个状态的一个标题属性（颜色或字体），保留其他属性。
     */
    @available(iOS 13.0, *)
    private static func cylSetTitleAttribute(of state: UITabBarItemStateAppearance, _ name: NSAttributedString.Key, _ value: Any?) {
        guard let value else {
            return
        }
        var attributes = state.titleTextAttributes
        attributes[name] = value
        state.titleTextAttributes = attributes
    }

    @available(iOS 13.0, *)
    private static func cylSetColors(of itemAppearance: UITabBarItemAppearance, _ colors: NSDictionary) {
        cylSetTitleAttribute(of: itemAppearance.normal, .foregroundColor, colors[cylTabBarItemTitleColor])
        cylSetTitleAttribute(of: itemAppearance.selected, .foregroundColor, colors[cylTabBarItemSelectedTitleColor])
        // [EN] Fonts: the selected state uses the unselected font unless it has its own. [CN] 字体：选中状态没有单独设置时使用未选中的字体。
        let titleFont = colors[cylTabBarItemTitleFont]
        cylSetTitleAttribute(of: itemAppearance.normal, .font, titleFont)
        cylSetTitleAttribute(of: itemAppearance.selected, .font, colors[cylTabBarItemSelectedTitleFont] ?? titleFont)
        if let iconColor = colors[cylTabBarItemIconColor] as? UIColor {
            itemAppearance.normal.iconColor = iconColor
        }
        if let selectedIconColor = colors[cylTabBarItemSelectedIconColor] as? UIColor {
            itemAppearance.selected.iconColor = selectedIconColor
        }
    }

    /**
     * [EN] The appearance of one tab: a copy of `base` with its title offset (when `offset` is set) and its colors (when
     *      `colors` is set) written into every layout and state.
     * [CN] 单个 Tab 的 appearance：`base` 的副本，写入其标题偏移（`offset` 不为 nil 时）与颜色（`colors` 不为 nil 时），作用于所有布局与状态。
     */
    @available(iOS 13.0, *)
    private static func cylAppearance(forItemFrom base: UITabBarAppearance, offset: NSValue?, colors: NSDictionary?) -> UITabBarAppearance {
        let appearance = base.copy()
        for itemAppearance in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            if let offset {
                for state in [itemAppearance.normal, itemAppearance.selected, itemAppearance.disabled, itemAppearance.focused] {
                    state.titlePositionAdjustment = offset.uiOffsetValue
                }
            }
            if let colors, colors.count > 0 {
                cylSetColors(of: itemAppearance, colors)
            }
        }
        return appearance
    }

    /**
     * [EN] Keeps one appearance of `tabBarItem` (`standardAppearance` or `scrollEdgeAppearance`, through `keyPath`) in step
     *      with its offset and colors. `barAppearance` is the tab bar's appearance it is built from; `transparent` builds
     *      it with a transparent background.
     * [CN] 使 `tabBarItem` 的某个 appearance（`standardAppearance` 或 `scrollEdgeAppearance`，由 `keyPath` 指定）与其偏移和颜色保持一致。
     *      `barAppearance` 为其所基于的 TabBar appearance，`transparent` 表示以透明背景构建。
     */
    @available(iOS 13.0, *)
    private static func cylSyncItemAppearance(_ tabBarItem: UITabBarItem, stateKey: UnsafeRawPointer,
                                              keyPath: ReferenceWritableKeyPath<UITabBarItem, UITabBarAppearance?>,
                                              barAppearance: UITabBarAppearance?, transparent: Bool,
                                              offset: NSValue?, colors: NSDictionary?) {
        let state = objc_getAssociatedObject(tabBarItem, stateKey) as? CYLItemAppearanceState
        let current = tabBarItem[keyPath: keyPath]
        var appBase = state?.appBase
        let installedByCYL = state.map { current === $0.installed || current?.isEqual($0.installed) == true } ?? false
        if let current, !installedByCYL {
            // [EN] The app installed its own appearance on the item: build on it. [CN] App 在 item 上安装了自己的 appearance：在其基础上构建。
            appBase = current
        }
        let hasColors = (colors?.count ?? 0) > 0
        guard offset != nil || hasColors else {
            if state != nil {
                tabBarItem[keyPath: keyPath] = appBase
                objc_setAssociatedObject(tabBarItem, stateKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return
        }
        guard let source = appBase ?? barAppearance else {
            return
        }
        let storedColors = hasColors ? colors : nil
        if let state, installedByCYL, state.source === source || state.source.isEqual(source),
           state.offset == offset, state.colors == storedColors {
            return
        }
        var base = source
        if appBase == nil && transparent {
            base = source.copy()
            base.configureWithTransparentBackground()
        }
        tabBarItem[keyPath: keyPath] = cylAppearance(forItemFrom: base, offset: offset, colors: storedColors)
        guard let installed = tabBarItem[keyPath: keyPath] else {
            return
        }
        let newState = CYLItemAppearanceState(installed: installed, source: source, appBase: appBase, offset: offset, colors: storedColors)
        objc_setAssociatedObject(tabBarItem, stateKey, newState, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    // MARK: - Applying

    /**
     * [EN] Writes the title offset on a tab only when it has one, or to reset a value CYL set before: a value set on the
     *      item overrides the `UITabBarItem` appearance proxy, so an offset the app set through the proxy is kept. Classic
     *      and Liquid Glass tab bars only; FlatDesign items have no appearance proxy.
     * [CN] 仅在有偏移时，或为重置 CYL 之前设置的值时，才写入 Tab 的标题偏移：在 item 上设置的值会覆盖 `UITabBarItem` 的 appearance
     *      代理，因此 App 通过代理设置的偏移得以保留。仅用于经典与液态玻璃 TabBar；扁平样式 item 没有 appearance 代理。
     */
    @objc(cyl_applyTitlePositionAdjustment:toTabBarItem:)
    func cylApplyTitlePositionAdjustment(_ offset: UIOffset, to tabBarItem: UITabBarItem?) {
        guard let tabBarItem else {
            return
        }
        let isZero = offset == .zero
        let wasSetByCYL = objc_getAssociatedObject(tabBarItem, CYLTitlePositionAdjustmentKeys.setByCYL) != nil
        if isZero && !wasSetByCYL {
            return
        }
        tabBarItem.titlePositionAdjustment = offset
        objc_setAssociatedObject(tabBarItem, CYLTitlePositionAdjustmentKeys.setByCYL, isZero ? nil : NSValue(uiOffset: offset),
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        if #available(iOS 13.0, *) {
            cylSyncTitlePositionAdjustmentAppearance(of: tabBarItem)
        }
    }

    @available(iOS 13.0, *)
    private func cylSyncTitlePositionAdjustmentAppearance(of tabBarItem: UITabBarItem) {
        let offset = objc_getAssociatedObject(tabBarItem, CYLTitlePositionAdjustmentKeys.setByCYL) as? NSValue
        let colors = objc_getAssociatedObject(tabBarItem, CYLItemAppearanceKeys.colors) as? NSDictionary
        let standardAppearance = tabBar.standardAppearance
        Self.cylSyncItemAppearance(tabBarItem, stateKey: CYLItemAppearanceKeys.standardAppearance, keyPath: \.standardAppearance,
                                   barAppearance: standardAppearance, transparent: false, offset: offset, colors: colors)
        if #available(iOS 15.0, *) {
            // [EN] Without a scroll edge appearance the tab bar shows its standard one with a transparent background at the
            //      scroll edge: build the same, so the item's opaque standard copy is not used there.
            // [CN] 没有 scrollEdgeAppearance 时，TabBar 在滚动边缘显示透明背景的 standardAppearance：按相同方式构建，避免在此处使用
            //      item 的不透明副本。
            let scrollEdgeAppearance = tabBar.scrollEdgeAppearance
            Self.cylSyncItemAppearance(tabBarItem, stateKey: CYLItemAppearanceKeys.scrollEdgeAppearance, keyPath: \.scrollEdgeAppearance,
                                       barAppearance: scrollEdgeAppearance ?? standardAppearance, transparent: scrollEdgeAppearance == nil,
                                       offset: offset, colors: colors)
        }
    }

    /**
     * [EN] Picks up the per-tab colors of `tabBarItemsAttributes` (read on every layout pass, so a reload or an in-place
     *      update applies) and the changes the app made to the tab bar's appearance since the offsets were applied.
     * [CN] 读取 `tabBarItemsAttributes` 中单个 Tab 的颜色（每次布局时读取，因此重新加载或原地更新后都会生效），并同步 App 在应用偏移后
     *      对 TabBar appearance 所做的修改。
     */
    @objc(cyl_syncTitlePositionAdjustmentAppearances)
    func cylSyncTitlePositionAdjustmentAppearances() {
        guard #available(iOS 13.0, *) else {
            return
        }
        for (index, viewController) in (viewControllers ?? []).enumerated() {
            guard let item = viewController.tabBarItem else {
                continue
            }
            let colors = Self.cylItemColors(from: tabBarItemAttributes(at: UInt(index)))
            let storedColors = objc_getAssociatedObject(item, CYLItemAppearanceKeys.colors) as? NSDictionary
            if colors != storedColors {
                objc_setAssociatedObject(item, CYLItemAppearanceKeys.colors, colors, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            }
        }
        for tabBarItem in tabBar.items ?? [] {
            if objc_getAssociatedObject(tabBarItem, CYLTitlePositionAdjustmentKeys.setByCYL) != nil ||
                objc_getAssociatedObject(tabBarItem, CYLItemAppearanceKeys.colors) != nil ||
                objc_getAssociatedObject(tabBarItem, CYLItemAppearanceKeys.standardAppearance) != nil {
                cylSyncTitlePositionAdjustmentAppearance(of: tabBarItem)
            }
        }
    }
}
