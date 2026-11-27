//
//  CYLTabBarController+CYLFlatDesignKeyValueObserving.swift
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
// [EN] The FlatDesign part of the controller's key-value observing (docs/Swift-Migration.md, step 127), called by the core through
//      `CYLFlatDesignKeyValueObserving`. FlatDesign subspec only.
// [CN] 控制器 KVO 的扁平样式部分（第 127 步），核心通过 `CYLFlatDesignKeyValueObserving` 调用。仅属于扁平样式子库。

extension CYLTabBarController {

    /**
     [EN] The app replaced the FlatDesign tab bar (`cyl_tabBar`): the new one takes the old one's items, selection, appearance and
          place. `-cyl_setTabBar:` already stored it; setting it again here re-entered this callback forever.
     [CN] App 替换了扁平样式 TabBar（`cyl_tabBar`）：新的 TabBar 接管旧 TabBar 的 item、选中状态、外观与位置。`-cyl_setTabBar:` 已保存它；
          在这里再次赋值会无限重入本回调。
     */
    @objc(cyl_flatDesignTabBarDidChange:)
    func cylFlatDesignTabBarDidChange(_ change: [NSKeyValueChangeKey: Any]) {
        guard tabBarStyleType == .flatDesign, cylPrivate.cylStoredTabBar() is CYLFlatDesignTabBar else { return }
        let oldTabBar = change[.oldKey] as? CYLFlatDesignTabBar
        let newTabBar = change[.newKey] as? CYLFlatDesignTabBar
        guard oldTabBar !== newTabBar else { return }
        oldTabBar?.removeFromSuperview()
        guard let newTabBar else { return }
        newTabBar.standardAppearance = newTabBar.standardAppearance ?? oldTabBar?.standardAppearance
        newTabBar.delegate = (self as AnyObject) as? CYLFlatDesignTabBarDelegate
        newTabBar.items = oldTabBar?.items
        newTabBar.selectedItem = oldTabBar?.selectedItem
        view.addSubview(newTabBar)
        view.setNeedsLayout()
    }
}
