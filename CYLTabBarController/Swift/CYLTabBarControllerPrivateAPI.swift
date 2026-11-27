//
//  CYLTabBarControllerPrivateAPI.swift
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
 * [EN] The methods that only `CYLTabBarController+CYLPrivate.h` declares (it is not part of the module, so Swift cannot see it),
 *      listed once with their Objective-C selectors. Swift code of the library reaches them through `cylPrivate`. An entry goes
 *      away when its owner is translated and the method becomes a Swift member. Docs: docs/Swift-Migration.md, step 39.
 * [CN] 只在 `CYLTabBarController+CYLPrivate.h` 中声明的方法（该头文件不属于 module，Swift 看不到），连同其 Objective-C selector 集中列在这里。
 *      库内的 Swift 代码通过 `cylPrivate` 调用它们。其所属代码翻译为 Swift 后，对应条目即可删除。文档：docs/Swift-Migration.md，第 39 步。
 */
@objc protocol CYLTabBarControllerPrivateAPI {
    @objc(cyl_updateLoopingLottieViews) func cylUpdateLoopingLottieViews()
    /// [EN] The image-only tabs state (docs/Swift-Migration.md, step 58). [CN] 纯图标 Tab 的状态（第 58 步）。
    @objc(cyl_imageOnlyTabsAdjustmentDisabled) func cylImageOnlyTabsAdjustmentDisabled() -> Bool
    @objc(setCyl_imageOnlyTabsAdjustmentDisabled:) func cylSetImageOnlyTabsAdjustmentDisabled(_ disabled: Bool)
    @objc(cyl_storedTabBar) func cylStoredTabBar() -> UIView?
    @objc(setTabBarItemAnimationViewAdded:) func cylSetTabBarItemAnimationViewAdded(_ added: Bool)
    @objc(setInvokeOnceViewDidLayoutSubViewsBlock:) func cylSetInvokeOnceViewDidLayoutSubViewsBlock(_ invokeOnce: Bool)
    /// [EN] Class-extension state of the classic hide / show animation (step 75). [CN] 经典隐藏 / 显示动画的类扩展状态（第 75 步）。
    @objc(cylClassicTabBarIsAnimating) func cylClassicTabBarIsAnimating() -> Bool
    @objc(setCylClassicTabBarIsAnimating:) func cylSetClassicTabBarIsAnimating(_ value: Bool)
    @objc(cylClassicTabBarHiddenRequest) func cylClassicTabBarHiddenRequest() -> Bool
    @objc(setCylClassicTabBarHiddenRequest:) func cylSetClassicTabBarHiddenRequest(_ value: Bool)
    @objc(cylClassicTabBarAnimationGeneration) func cylClassicTabBarAnimationGeneration() -> UInt
    @objc(setCylClassicTabBarAnimationGeneration:) func cylSetClassicTabBarAnimationGeneration(_ value: UInt)
    /// [EN] Still Objective-C ("Plus slot"), used by the tab item setup (step 76). [CN] 仍为 Objective-C，供 Tab item 设置使用（第 76 步）。
    @objc(cyl_tabBarItemsAttributesIncludePlusSlot) func cylTabBarItemsAttributesIncludePlusSlot() -> Bool
    /// [EN] Setters of the re-synthesized selection storage, Objective-C until the class switch (step 77). [CN] 重新合成的选中存储的 setter，类迁移前仍为 Objective-C（第 77 步）。
    @objc(cyl_setSelectedViewControllerStorage:) func cylSetSelectedViewControllerStorage(_ viewController: UIViewController?)
    @objc(cyl_setSelectedIndexStorage:) func cylSetSelectedIndexStorage(_ selectedIndex: UInt)
    /// [EN] Class-extension state and a loader still in Objective-C, used by the in-place update (step 73). [CN] 仍为 Objective-C 的类扩展状态与加载方法，供原地更新使用（第 73 步）。
    @objc(tabBarItemAnimationURLs) func cylTabBarItemAnimationURLs() -> NSMutableArray
    @objc(tabBarItemAnimationSizes) func cylTabBarItemAnimationSizes() -> NSMutableArray
    @objc(cyl_isPlusSlotViewController:) func cylIsPlusSlotViewController(_ viewController: UIViewController) -> Bool
    @objc(cyl_contextPlusButton) func cylContextPlusButton() -> CYLPlusButton?
    @objc(cyl_contextPlusChildViewController) func cylContextPlusChildViewController() -> UIViewController?
    /// [EN] The control reported in the current run loop turn (step 59). [CN] 当前 runloop 中已上报的控件（第 59 步）。
    @objc(setCyl_controlReportedInCurrentRunLoop:) func cylSetControlReportedInCurrentRunLoop(_ control: UIControl?)
    /// [EN] Used by `-didSelectControl:` (step 64). [CN] 供 `-didSelectControl:` 使用（第 64 步）。
    @objc(cyl_controlReportedInCurrentRunLoop) func cylControlReportedInCurrentRunLoop() -> UIControl?
    @objc(cyl_setNeedsUpdateTabBarItemIconViews) func cylSetNeedsUpdateTabBarItemIconViews()
    /// [EN] The page registry state of the class extension (docs/Swift-Migration.md, step 54). [CN] 类扩展中的页面注册表状态（第 54 步）。
    @objc(pageRegistry) func cylPageRegistryState() -> CYLTabBarPageProviding?
    @objc(pageResolver) func cylPageResolverState() -> CYLTabBarPageProvider?
    @objc(pageLookupOrder) func cylPageLookupOrderState() -> [String]?
    @objc(skippedTabs) func cylSkippedTabsState() -> [CYLTabBarSkippedTab]?
    @objc(setSkippedTabs:) func cylSetSkippedTabsState(_ skippedTabs: [CYLTabBarSkippedTab])
    @objc(pagesFromPageIdentifiers) func cylPagesFromPageIdentifiersState() -> Bool
    @objc(pagesByPageIdentifier) func cylPagesByPageIdentifierState() -> [String: NSMutableArray]?
    /// [EN] Replaces the attributes storage without the setter's work. [CN] 替换属性存储，不执行 setter 的逻辑。
    @objc(cyl_replaceTabBarItemsAttributesStorage:) func cylReplaceTabBarItemsAttributesStorage(_ tabBarItemsAttributes: [[AnyHashable: Any]])
    /// FIX: issue #610 — implemented in CYLTabBarController.m, only with FlatDesign (`CYL_FLATDESIGN_AVAILABLE`).
    @objc(cyl_flatDesignReportDidSelectControl:) optional func cylFlatDesignReportDidSelectControl(_ control: UIControl)
}

extension CYLTabBarController {
    /// [EN] The private methods of this controller. [CN] 本控制器的私有方法。
    var cylPrivate: CYLTabBarControllerPrivateAPI {
        unsafeBitCast(self as AnyObject, to: CYLTabBarControllerPrivateAPI.self)
    }
}
