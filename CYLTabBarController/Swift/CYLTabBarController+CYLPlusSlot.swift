//
//  CYLTabBarController+CYLPlusSlot.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/// [EN] Marks the tab item attributes inserted for the slot (Liquid Glass, FlatDesign), so a re-assignment can remove them.
/// [CN] 标记为 slot 插入的 TabBarItem 属性（液态玻璃、扁平样式），重新赋值时据此移除。
private let cylTabBarItemPlusSlotPlaceholderKey = "CYLTabBarItemPlusSlotPlaceholder"

/**
 [EN] The plus slot: the plus button's tab in `viewControllers`, the plus child view controller, or a placeholder for a plus
      button without one (Liquid Glass, FlatDesign). It is derived state: `-setViewControllers:` removes any slot the array
      carries and inserts exactly one, at `-cyl_plusSlotIndexForTabCount:`; everything else reads the slot's index from
      `viewControllers`. Translated from Objective-C (docs/Swift-Migration.md, step 124); the tab setup
      (CYLTabBarController+CYLTabSetup.swift, step 126) stores the result in `_viewControllers`.
      Internal members with the Objective-C selectors, declared in CYLTabBarController+CYLPrivate.h.

      FIX: placeholder count mismatch. The slot used to be inserted by three methods with different conditions and indexes,
      and not removed first, so re-assigning `viewControllers` dropped the plus child view controller or added a second slot,
      FlatDesign indexed its buttons out of bounds, `cyl_tabbarItemsCount` counted a carried slot, and Liquid Glass placed the
      slot in the middle while `-[UIView cyl_plusButtonIndex]` returned the custom index.
 [CN] 加号 slot：PlusButton 在 `viewControllers` 中对应的 Tab，即 PlusButton 子控制器，或没有子控制器时的占位控制器（液态玻璃、扁平样式）。
      它是派生状态：`-setViewControllers:` 先移除数组中已有的 slot，再在 `-cyl_plusSlotIndexForTabCount:` 处插入且只插入一个；其他地方都从
      `viewControllers` 读取 slot 的下标。已从 Objective-C 翻译（第 124 步）；Tab 设置（第 126 步）把结果存入 `_viewControllers`。以 Objective-C selector 实现的内部
      成员，声明于 CYLTabBarController+CYLPrivate.h。

      FIX：占位导致的数量不匹配。以前 slot 由三个方法以不同的条件与下标插入，且不先移除，因此重新赋值 `viewControllers` 时会丢失 PlusButton 子控制器
      或多出第二个 slot，扁平样式按越界的下标访问按钮，`cyl_tabbarItemsCount` 计入数组自带的 slot，液态玻璃把 slot 放在中间而
      `-[UIView cyl_plusButtonIndex]` 返回自定义下标。
 */
extension CYLTabBarController {

    @objc(cyl_isPlusSlotViewController:)
    func cylIsPlusSlotViewController(_ viewController: UIViewController?) -> Bool {
        guard let viewController else { return false }
        let content = viewController.cyl_getViewControllerInsteadOfNavigation()
        if viewController.cyl_isPlaceholder || content.cyl_isPlaceholder {
            return true
        }
        // [EN] Also the plus child view controller seen through a navigation controller. [CN] 也包括被导航控制器包裹的 PlusButton 子控制器。
        guard let plusChild = cylPrivate.cylContextPlusChildViewController() else { return false }
        return viewController === plusChild || content === plusChild
    }

    /// [EN] The app's own tabs: `viewControllers` without any slot. [CN] App 自己的 Tab：去掉所有 slot 的 `viewControllers`。
    @objc(cyl_viewControllersByRemovingPlusSlot:)
    func cylViewControllersByRemovingPlusSlot(_ viewControllers: [UIViewController]?) -> [UIViewController] {
        (viewControllers ?? []).filter { !cylIsPlusSlotViewController($0) }
    }

    /// [EN] The slot's index in `viewControllers`, or NSNotFound. [CN] slot 在 `viewControllers` 中的下标，没有时返回 NSNotFound。
    @objc(cyl_plusSlotIndexInViewControllers)
    func cylPlusSlotIndexInViewControllers() -> Int {
        (viewControllers ?? []).firstIndex { cylIsPlusSlotViewController($0) } ?? NSNotFound
    }

    /// [EN] Whether `tabBarItemsAttributes` has the slot's entry, read from the data (the marked entry), not guessed from the style.
    /// [CN] `tabBarItemsAttributes` 中是否有 slot 的一项，根据数据（带标记的一项）判断，而不是按样式猜测。
    @objc(cyl_tabBarItemsAttributesIncludePlusSlot)
    func cylTabBarItemsAttributesIncludePlusSlot() -> Bool {
        tabBarItemsAttributes.contains { CYLTabBarController.cylIsPlusSlotAttributes($0) }
    }

    private static func cylIsPlusSlotAttributes(_ attributes: Any) -> Bool {
        ((attributes as? [AnyHashable: Any])?[cylTabBarItemPlusSlotPlaceholderKey] as? NSNumber)?.boolValue == true
    }

    /// [EN] The app's own tab item attributes: without the entries inserted for the slot. [CN] 去掉为 slot 插入的属性。
    @objc(cyl_tabBarItemsAttributesByRemovingPlusSlot:)
    func cylTabBarItemsAttributesByRemovingPlusSlot(_ attributes: [[AnyHashable: Any]]?) -> [[AnyHashable: Any]]? {
        guard let attributes else { return nil }
        return attributes.filter { !CYLTabBarController.cylIsPlusSlotAttributes($0) }
    }

    /// [EN] Liquid Glass with a CYLTabBar. [CN] 液态玻璃且使用 CYLTabBar。
    private func cylIsLiquidGlassPlusSlotStyle() -> Bool {
        tabBarStyleType != .flatDesign && CYLConstants.isLiquidGlassActive() && cyl_tabBar is CYLTabBar
    }

    /// [EN] The slot's view controller, or nil when this style shows the plus button without one: the classic style only for a
    ///      plus child view controller; Liquid Glass (CYLTabBar) and FlatDesign always (a placeholder under the plus button).
    /// [CN] slot 对应的控制器；该样式不需要 slot 时为 nil：经典样式只在有 PlusButton 子控制器时需要；液态玻璃（CYLTabBar）与扁平样式始终需要。
    private func cylPlusSlotViewController() -> UIViewController? {
        guard hasPlusButton() else { return nil }
        if let plusChild = cylPrivate.cylContextPlusChildViewController() {
            return plusChild
        }
        let isFlatDesign = tabBarStyleType == .flatDesign && cylStoredTabBarIsFlatDesign()
        guard isFlatDesign || cylIsLiquidGlassPlusSlotStyle() else { return nil }
        let placeholder = UIViewController()
        placeholder.cyl_isPlaceholder = true
        return placeholder
    }

    /// [EN] Whether the stored tab bar is the FlatDesign one (by class name: the class lives in the FlatDesign subspec).
    /// [CN] 已保存的 TabBar 是否为扁平样式 TabBar（按类名判断：该类位于扁平样式子库）。
    private func cylStoredTabBarIsFlatDesign() -> Bool {
        guard let tabBarClass = NSClassFromString("CYLFlatDesignTabBar"), let stored = cylPrivate.cylStoredTabBar() else { return false }
        return stored.isKind(of: tabBarClass)
    }

    /**
     [EN] The one rule for the slot's place among `tabCount` tabs (0 ... tabCount). Liquid Glass: the middle. Classic and
          FlatDesign: the plus button's own position (`+indexForTabbarItemsCount:`, issue #515), else the middle.
     [CN] slot 在 `tabCount` 个 Tab 中位置的唯一规则（0 ... tabCount）。液态玻璃：中间。经典与扁平样式：PlusButton 自己的位置（issue #515），否则为中间。
     */
    @objc(cyl_plusSlotIndexForTabCount:)
    func cylPlusSlotIndex(forTabCount tabCount: Int) -> Int {
        let middle = tabCount / 2
        guard !cylIsLiquidGlassPlusSlotStyle(), let plusButton = cylPrivate.cylContextPlusButton() else { return middle }
        let implementsCustomIndex = (plusButton.cylRuntimeClass as AnyObject).responds(to: NSSelectorFromString("indexOfPlusButtonInTabBar"))
        // [EN] `+indexForTabbarItemsCount:` asserts for an odd count without a custom index: only ask when it can answer.
        // [CN] Tab 数为奇数且没有自定义下标时 `+indexForTabbarItemsCount:` 会断言：只在它能给出结果时调用。
        guard implementsCustomIndex || tabCount % 2 == 0 else { return middle }
        let customIndex = Int(plusButton.cylIndex(forTabbarItemsCount: UInt(tabCount)))
        return customIndex != NSNotFound && customIndex <= tabCount ? customIndex : middle
    }

    /// [EN] The attributes of the slot's tab item. [CN] slot 对应 TabBarItem 的属性。
    private func cylPlusSlotTabBarItemAttributes() -> [AnyHashable: Any] {
        [CYLTabBarItemTitle: "", CYLTabBarItemImage: UIImage.cyl_tabItemPlaceholder(), CYLTabBarItemSelectedImage: UIImage.cyl_tabItemPlaceholder(),
         cylTabBarItemPlusSlotPlaceholderKey: true]
    }

    /**
     [EN] `viewControllers` (any slot removed) with exactly one slot, stored in `_viewControllers` by the tab setup;
          keeps `tabBarItemsAttributes` in step (Liquid Glass and FlatDesign give the slot its own entry; the classic style
          skips it) and updates the plus button's indexes.
     [CN] 返回 `viewControllers`（先去掉 slot）加上唯一一个 slot，由 Tab 设置存入 `_viewControllers`；同步 `tabBarItemsAttributes`
          （液态玻璃与扁平样式为 slot 提供单独的一项；经典样式跳过），并更新 PlusButton 的下标。
     */
    @objc(cyl_viewControllersAligningPlusSlotWithViewControllers:)
    func cylViewControllersAligningPlusSlot(with viewControllers: [UIViewController]?) -> [UIViewController] {
        let tabs = cylViewControllersByRemovingPlusSlot(viewControllers)
        tabBarItemsAttributes = cylTabBarItemsAttributesByRemovingPlusSlot(tabBarItemsAttributes) ?? []
        let plusButton = cylPrivate.cylContextPlusButton()
        if plusButton != nil {
            // FIX: issue #481 — checked before the alignment, with the app's own tabs. [CN] 在对齐之前用 App 自己的 Tab 检查。
            cylDoubleCheckTabControlAlign(with: tabs)
        }
        guard let slot = cylPlusSlotViewController() else {
            plusButton?.cyl_tabBarChildViewControllerIndex = NSNotFound
            return tabs
        }
        let slotIndex = min(cylPlusSlotIndex(forTabCount: tabs.count), tabs.count)
        var aligned = tabs
        aligned.insert(slot, at: slotIndex)
        cyl_addChildViewController(slot)
        plusButton?.cyl_tabBarItemVisibleIndex = slotIndex
        // [EN] As the tab bars set it on layout: the slot's index, placeholder or not. [CN] 与 TabBar 布局时一致：slot 的下标，无论是否为占位。
        plusButton?.cyl_tabBarChildViewControllerIndex = slotIndex
        if !slot.cyl_isPlaceholder {
            slot.cyl_plusViewControllerEverAdded = true
        }
        if (tabBarStyleType == .flatDesign || cylIsLiquidGlassPlusSlotStyle()) && !tabBarItemsAttributes.isEmpty {
            var attributes = tabBarItemsAttributes
            attributes.insert(cylPlusSlotTabBarItemAttributes(), at: min(slotIndex, attributes.count))
            tabBarItemsAttributes = attributes
        }
        return aligned
    }

    /// [EN] `tabBarItemsAttributes` must have one entry per tab, set before `-setViewControllers:` (debug assertion).
    /// [CN] `tabBarItemsAttributes` 必须每个 Tab 一项，并在 `-setViewControllers:` 之前设置（debug 断言）。
    private func cylDoubleCheckTabControlAlign(with tabs: [UIViewController]) {
        #if DEBUG
        if tabBarItemsAttributes.count != tabs.count {
            assertionFailure(CYLLocalizedString("[DEBUG] 设置 tabBarItemsAttributes 时，请确保元素个数与控制器的个数相同，并在 `-setViewControllers:` 之前设置。"))
        }
        #endif
    }
}
