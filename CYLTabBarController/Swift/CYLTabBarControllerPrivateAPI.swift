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
    @objc(cyl_applyTabBarItemStyles) func cylApplyTabBarItemStyles()
    @objc(cyl_syncTabBarAppearances) func cylSyncTabBarAppearances()
    @objc(cyl_rearmViewDidLayoutSubviewsBlockInvokeOnce) func cylRearmViewDidLayoutSubviewsBlockInvokeOnce()
    @objc(cyl_tabBarItemIconViewProviders) func cylTabBarItemIconViewProviders() -> NSMapTable<UIViewController, AnyObject>
    @objc(cyl_themeRemoveTabBarItemAttributeKeys:atIndex:) func cylThemeRemoveTabBarItemAttributeKeys(_ keys: [String], atIndex index: UInt)
    @objc(cyl_isPlusSlotViewController:) func cylIsPlusSlotViewController(_ viewController: UIViewController) -> Bool
    @objc(cyl_tabButtonsOfViewController:) func cylTabButtons(of viewController: UIViewController) -> [UIControl]
}

/**
 * [EN] The methods only `CYLPlusButton.m` declares, as for the tab bar controller above. [CN] 只在 `CYLPlusButton.m` 中声明的方法，与上面的 TabBarController 相同。
 */
/**
 * [EN] The class methods of `CYLTabBarController` that only the private header declares. A class method is an instance method of the
 *      class object, so it is declared as an instance method here and called on `CYLTabBarController.self`.
 * [CN] 只在私有头文件中声明的 `CYLTabBarController` 类方法。类方法是类对象的实例方法，因此这里声明为实例方法，并在 `CYLTabBarController.self` 上调用。
 */
@objc protocol CYLTabBarControllerPrivateClassAPI {
    @objc(cyl_loadTabBarItemIcon:completion:) func cylLoadTabBarItemIcon(_ icon: Any?, completion: @escaping (UIImage?) -> Void)
}

@objc protocol CYLPlusButtonPrivateAPI {
    @objc(cyl_drawsTitleOverBackgroundImage) func cylDrawsTitleOverBackgroundImage() -> Bool
    @objc(cyl_removeImage) func cylRemoveImage()
    @objc(cyl_setBackgroundImageDidChangeHandler:) func cylSetBackgroundImageDidChangeHandler(_ handler: @escaping () -> Void)
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

extension CYLPlusButton {
    /// [EN] The private methods of this plus button. [CN] 本 PlusButton 的私有方法。
    var cylPrivate: CYLPlusButtonPrivateAPI {
        unsafeBitCast(self as AnyObject, to: CYLPlusButtonPrivateAPI.self)
    }
}
