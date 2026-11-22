//
//  CYLTabBarController+CYLFlatDesignTabBarAccessors.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] The FlatDesign parts of the `cyl_tabBar` and `tabBarHeight` accessors (docs/Swift-Migration.md, step 128), called by the
//      core through `CYLFlatDesignTabBarAccessors`. FlatDesign subspec only.
// [CN] `cyl_tabBar` 与 `tabBarHeight` 访问器的扁平样式部分（第 128 步），核心通过 `CYLFlatDesignTabBarAccessors` 调用。仅属于扁平样式子库。

extension CYLTabBarController {

    /**
     [EN] Installs the FlatDesign tab bar on first use: the system tab bar is swapped for CYLFlatDesignTabBarHideTabBar through KVC
          and hidden (KVC can fail silently: the actual system bar is hidden too), and CYLFlatDesignTabBar is added. A CYLTabBar
          left from a system style stops being observed first, else the next CYLTabBar is never observed.
     [CN] 首次使用时安装扁平样式 TabBar：通过 KVC 把系统 TabBar 换成 CYLFlatDesignTabBarHideTabBar 并隐藏（KVC 可能静默失败：同时隐藏真正的系统
          TabBar），再添加 CYLFlatDesignTabBar。系统样式留下的 CYLTabBar 先停止观察，否则之后的 CYLTabBar 永远不会被观察。
     */
    @objc(cyl_flatDesignInstallTabBarIfNeeded)
    func cylFlatDesignInstallTabBarIfNeeded() {
        let storage = cylTabSetupStorage
        let accessors = cylTabBarAccessorsStorage
        if cylPrivate.cylStoredTabBar() is CYLTabBar {
            cylStopObservingTabImageViewDefaultOffset()
            storage.cylSetStoredTabBar(nil)
        }
        guard cylPrivate.cylStoredTabBar() == nil else { return }
        cylSetValue(CYLFlatDesignTabBarHideTabBar(), forKey: "tabBar")
        if !tabBar.isHidden {
            tabBar.isHidden = true
        }
        let flatDesignTabBar = CYLFlatDesignTabBar(frame: cylLayoutHooks.cylTabBarFrame())
        flatDesignTabBar.delegate = (self as AnyObject) as? CYLFlatDesignTabBarDelegate
        // [EN] `-setContext:` usually ran before this tab bar existed (it only copies the context to an existing one).
        // [CN] `-setContext:` 通常在本 TabBar 创建之前就执行了（它只会复制给已存在的 TabBar）。
        flatDesignTabBar.context = cyl_context
        storage.cylSetStoredTabBar(flatDesignTabBar)
        storage.cylSetDidRefreshSystemTabBarVisibility(false)
        accessors.cylSetRefreshedSystemTabBarWindow(nil)
        view.addSubview(flatDesignTabBar)
        addObserver(self, forKeyPath: "cyl_tabBar", options: [.old, .new], context: CYLTabBarController.cylFlatDesignTabBarKVOContext())
        accessors.cylSetTabBarHiddenRequest(false)
        accessors.cylSetTabBarHidden(false)
        cylFlatDesignUpdateAdditionalSafeAreaInsets(animated: false)
        NotificationCenter.default.post(name: NSNotification.Name.CYLTabBarStyleTypeDidChange, object: self)
    }

    /// [EN] A new height re-lays out the FlatDesign tab bar and the safe area. [CN] 新的高度会重新布局扁平样式 TabBar 与安全区域。
    @objc(cyl_flatDesignApplyTabBarHeight:)
    func cylFlatDesignApplyTabBarHeight(_ tabBarHeight: CGFloat) {
        guard cylPrivate.cylStoredTabBar() is CYLFlatDesignTabBar else { return }
        let accessors = cylTabBarAccessorsStorage
        guard accessors.cylTabBarHeightStorage() != tabBarHeight else { return }
        accessors.cylSetTabBarHeightStorage(tabBarHeight)
        cylFlatDesignUpdateAdditionalSafeAreaInsets(animated: false)
        view.setNeedsLayout()
    }
}
