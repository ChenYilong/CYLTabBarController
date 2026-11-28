//
//  CYLTabBarController+CYLFlatDesignTabSetup.swift
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
// [EN] The FlatDesign part of `-setViewControllers:` (docs/Swift-Migration.md, step 126), called by the core through
//      `CYLFlatDesignTabSetup` (Swift/CYLTabBarController+CYLTabSetup.swift). FlatDesign subspec only.
// [CN] `-setViewControllers:` 的扁平样式部分（第 126 步），核心通过 `CYLFlatDesignTabSetup` 调用。仅属于扁平样式子库。

extension CYLTabBarController {

    /**
     [EN] Sets the FlatDesign tabs: each tab gets its FlatDesign item and button, UIKit gets the tabs (`super`), the slot is
          aligned, and the tab bar shows the items. The app's own tabs and attributes first: a re-assignment may carry the slot
          (and its attributes), which shifted `idx` by one after the slot and inserted a second slot.
     [CN] 设置扁平样式的 Tab：每个 Tab 获得扁平样式 item 与按钮，Tab 交给 UIKit（`super`），对齐 slot，TabBar 显示这些 item。先去掉 slot：
          重新赋值时数组可能自带 slot（及其属性），曾使 slot 之后的 `idx` 偏移一位并插入第二个 slot。
     */
    @objc(cyl_flatDesignSetViewControllers:)
    func cylFlatDesignSetViewControllers(_ viewControllers: [UIViewController]) -> Bool {
        guard let flatTabBar = cylPrivate.cylStoredTabBar() as? CYLFlatDesignTabBar else { return false }
        let storage = cylTabSetupStorage
        storage.cylSetNeedsReloadItems(true)
        let tabs = cylViewControllersByRemovingPlusSlot(viewControllers)
        cylPrivate.cylReplaceTabBarItemsAttributesStorage(cylTabBarItemsAttributesByRemovingPlusSlot(tabBarItemsAttributes) ?? [])
        for (idx, child) in tabs.enumerated() {
            child.cylFlatDesignSetTabBarController(self)
            cylFlatDesignSetupChildViewController(child, idx: UInt(idx))
            child.cyl_tabButton = child.cyl_tabBarItem?.tabBarButton
        }
        flatTabBar.cyl_tabbarItemsCount = UInt(tabs.count)
        super.viewControllers = tabs
        if #available(iOS 27.1, *) {
            storage.cylSetDidRefreshSystemTabBarVisibility(false)
            if isViewLoaded { view.setNeedsLayout() }
        }
        storage.cylSetViewControllersStorage(cylViewControllersAligningPlusSlot(with: tabs))
        // [EN] Legacy global (what was written last); this tab bar's own index is `-[UIView cyl_plusButtonIndex]`, read after
        //      the slot is inserted. [CN] 旧的全局变量（最后写入的值）；本 TabBar 自己的下标见 `-[UIView cyl_plusButtonIndex]`，在插入 slot 之后读取。
        CYLPlusButtonIndex = flatTabBar.cylPlusButtonIndex()
        cylFlatDesignCaptureItems()
        flatTabBar.items = cylFlatDesignItemsOfController()
        storage.cylSetNeedsReloadItems(false)
        flatTabBar.selectedItem = selectedViewController?.cyl_tabBarItem
        return true
    }

    /// [EN] The items captured by `-_captureItems`. [CN] `-_captureItems` 收集的 item。
    private func cylFlatDesignItemsOfController() -> [CYLFlatDesignTabBarItem]? {
        (perform(NSSelectorFromString("items"))?.takeUnretainedValue() as? NSArray)?.compactMap { $0 as? CYLFlatDesignTabBarItem }
    }
}
