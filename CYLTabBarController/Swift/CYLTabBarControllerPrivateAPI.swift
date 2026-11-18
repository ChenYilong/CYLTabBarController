//
//  CYLTabBarControllerPrivateAPI.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

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
    @objc(cyl_rearmViewDidLayoutSubviewsBlockInvokeOnce) func cylRearmViewDidLayoutSubviewsBlockInvokeOnce()
    @objc(cyl_tabBarItemIconViewProviders) func cylTabBarItemIconViewProviders() -> NSMapTable<UIViewController, AnyObject>
    @objc(cyl_themeRemoveTabBarItemAttributeKeys:atIndex:) func cylThemeRemoveTabBarItemAttributeKeys(_ keys: [String], atIndex index: UInt)
    @objc(cyl_isPlusSlotViewController:) func cylIsPlusSlotViewController(_ viewController: UIViewController) -> Bool
    @objc(cyl_tabButtonsOfViewController:) func cylTabButtons(of viewController: UIViewController) -> [UIControl]
    @objc(cyl_contextPlusButton) func cylContextPlusButton() -> CYLPlusButton?
    @objc(cyl_contextPlusChildViewController) func cylContextPlusChildViewController() -> UIViewController?
    @objc(cyl_reportedControlForControl:) func cylReportedControl(for control: UIControl?) -> UIControl?
    /// [EN] The page registry state of the class extension (docs/Swift-Migration.md, step 54). [CN] 类扩展中的页面注册表状态（第 54 步）。
    @objc(pageRegistry) func cylPageRegistryState() -> CYLTabBarPageProviding?
    @objc(pageResolver) func cylPageResolverState() -> CYLTabBarPageProvider?
    @objc(pageLookupOrder) func cylPageLookupOrderState() -> [String]?
    @objc(skippedTabs) func cylSkippedTabsState() -> [CYLTabBarSkippedTab]?
    @objc(setSkippedTabs:) func cylSetSkippedTabsState(_ skippedTabs: [CYLTabBarSkippedTab])
    @objc(pagesFromPageIdentifiers) func cylPagesFromPageIdentifiersState() -> Bool
    @objc(pagesByPageIdentifier) func cylPagesByPageIdentifierState() -> [String: NSMutableArray]?
    @objc(cyl_tabBarItemsAttributesIndexOfViewControllerAtIndex:) func cylTabBarItemsAttributesIndexOfViewController(at index: UInt) -> UInt
    /// [EN] Replaces the attributes storage without the setter's work. [CN] 替换属性存储，不执行 setter 的逻辑。
    @objc(cyl_replaceTabBarItemsAttributesStorage:) func cylReplaceTabBarItemsAttributesStorage(_ tabBarItemsAttributes: [[AnyHashable: Any]])
    /// FIX: issue #594 — implemented in CYLTabBarController.m (`CYLTabBarController (CYLPlusButtonSelection)`).
    @objc(cyl_plusButtonControlIfSelectingPlusChildViewController:) func cylPlusButtonControlIfSelectingPlusChildViewController(_ viewController: UIViewController) -> UIControl?
    /// FIX: issue #610 — implemented in CYLTabBarController.m, only with FlatDesign (`CYL_FLATDESIGN_AVAILABLE`).
    @objc(cyl_flatDesignReportDidSelectControl:) optional func cylFlatDesignReportDidSelectControl(_ control: UIControl)
}

/**
 * [EN] The class methods of `CYLTabBarController` that only the private header declares. A class method is an instance method of the
 *      class object, so it is declared as an instance method here and called on `CYLTabBarController.self`.
 * [CN] 只在私有头文件中声明的 `CYLTabBarController` 类方法。类方法是类对象的实例方法，因此这里声明为实例方法，并在 `CYLTabBarController.self` 上调用。
 */
@objc protocol CYLTabBarControllerPrivateClassAPI {
    @objc(cyl_loadTabBarItemIcon:completion:) func cylLoadTabBarItemIcon(_ icon: Any?, completion: @escaping (UIImage?) -> Void)
}

extension CYLTabBarController {
    /// [EN] The private methods of this controller. [CN] 本控制器的私有方法。
    var cylPrivate: CYLTabBarControllerPrivateAPI {
        unsafeBitCast(self as AnyObject, to: CYLTabBarControllerPrivateAPI.self)
    }
}

extension CYLTabBarController {
    /// [EN] The private class methods. [CN] 私有类方法。
    static var cylPrivateClass: CYLTabBarControllerPrivateClassAPI {
        unsafeBitCast(CYLTabBarController.self as AnyObject, to: CYLTabBarControllerPrivateClassAPI.self)
    }
}
