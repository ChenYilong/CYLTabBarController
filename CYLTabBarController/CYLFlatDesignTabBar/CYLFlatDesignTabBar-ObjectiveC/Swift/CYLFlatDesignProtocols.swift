//
//  CYLFlatDesignProtocols.swift
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
// [EN] Phase 3 of the class switch (docs/Swift-Migration.md): the FlatDesign protocols of CYLConstants.h and CYLFlatDesignTabBar.h in
//      Swift, with the same Objective-C names and selectors. FlatDesign subspec only. The header had no nullability for the
//      show / hide callbacks, so their parameters stay implicitly unwrapped, as apps see them today.
// [CN] 类切换第 3 阶段：CYLConstants.h 与 CYLFlatDesignTabBar.h 中的扁平样式协议改为 Swift，Objective-C 名称与 selector 不变。仅属于扁平样式子库。
//      头文件中显示 / 隐藏回调没有可空性标注，因此参数保持隐式解包，与 App 现在看到的一致。

/**
 [EN] The delegate of the tab bar controller with the FlatDesign show / hide callbacks (`tabBarController.delegate`).
 [CN] 带扁平样式显示 / 隐藏回调的 TabBarController 代理（`tabBarController.delegate`）。
 */
@objc(CYLFlatDesignUITabBarControllerDelegate)
public protocol CYLFlatDesignUITabBarControllerDelegate: UITabBarControllerDelegate {
    /**
     [EN] Flat design only. Called before the flat-design tab bar is shown.
     [CN] 仅扁平化模式。扁平化 TabBar 即将显示时回调。
     */
    @objc(tabBarController:willShowTabBar:)
    optional func tabBarController(_ tabBarController: CYLTabBarController!, willShow tabBar: CYLFlatDesignTabBar!)
    /**
     [EN] Flat design only. Called after the flat-design tab bar is shown.
     [CN] 仅扁平化模式。扁平化 TabBar 显示完成后回调。
     */
    @objc(tabBarController:didShowTabBar:)
    optional func tabBarController(_ tabBarController: CYLTabBarController!, didShow tabBar: CYLFlatDesignTabBar!)
    /**
     [EN] Flat design only. Called before the flat-design tab bar is hidden.
     [CN] 仅扁平化模式。扁平化 TabBar 即将隐藏时回调。
     */
    @objc(tabBarController:willHideTabBar:)
    optional func tabBarController(_ tabBarController: CYLTabBarController!, willHide tabBar: CYLFlatDesignTabBar!)
    /**
     [EN] Flat design only. Called after the flat-design tab bar is hidden.
     [CN] 仅扁平化模式。扁平化 TabBar 隐藏完成后回调。
     */
    @objc(tabBarController:didHideTabBar:)
    optional func tabBarController(_ tabBarController: CYLTabBarController!, didHide tabBar: CYLFlatDesignTabBar!)
}

/**
 [EN] The delegate of `CYLFlatDesignTabBar`, told about user taps.
 [CN] `CYLFlatDesignTabBar` 的代理，接收用户点击。
 */
@objc(CYLFlatDesignTabBarDelegate)
public protocol CYLFlatDesignTabBarDelegate: NSObjectProtocol {
    /**
     [EN] Called when the user taps an item (not when selection changes in code).
     [CN] 用户点击 Item 时回调（通过代码切换选中项时不会回调）。
     */
    @objc(tabBar:didSelectItem:)
    optional func tabBar(_ tabBar: CYLFlatDesignTabBar, didSelect item: CYLFlatDesignTabBarItem)
}

/**
 [EN] CYLTabBarController is the delegate of its flat-design tab bar, as `CYLTabBarController.h` declared before the class
      switch (`<CYLTabBarControllerDelegate, CYLFlatDesignTabBarDelegate>`). Without it, the controller's
      `as? CYLFlatDesignTabBarDelegate` gave nil, the bar had no delegate, counted as a standalone bar and showed no plus
      button (docs/PlusButton.md, 2026-11-21).
 [CN] CYLTabBarController 是其扁平样式 TabBar 的代理，与类切换前 `CYLTabBarController.h` 的声明相同
      （`<CYLTabBarControllerDelegate, CYLFlatDesignTabBarDelegate>`）。缺少它时控制器的 `as? CYLFlatDesignTabBarDelegate` 得到 nil，
      TabBar 没有代理，被当作独立 TabBar，不显示 PlusButton（docs/PlusButton.md，2026-11-21）。
 */
extension CYLTabBarController: CYLFlatDesignTabBarDelegate {}
