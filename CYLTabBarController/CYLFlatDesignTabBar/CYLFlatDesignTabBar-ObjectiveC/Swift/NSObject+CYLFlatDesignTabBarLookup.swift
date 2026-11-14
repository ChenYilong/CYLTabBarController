//
//  NSObject+CYLFlatDesignTabBarLookup.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Flat design side of the tab bar controller lookup (`NSObject+CYLTabBarControllerLookup`, docs/Swift-Migration.md, step 40):
 *      `-cylflatdesign_setTabBarController:` and `-cylflatdesign_tabBarController` (declared in `CYLTabBarController.h` under
 *      `CYL_FLATDESIGN_AVAILABLE`), and the parent search. Only a build with FlatDesign compiles this file.
 * [CN] TabBarController 查找中扁平样式的部分（`NSObject+CYLTabBarControllerLookup`，docs/Swift-Migration.md，第 40 步）：
 *      `-cylflatdesign_setTabBarController:` 与 `-cylflatdesign_tabBarController`（在 `CYLTabBarController.h` 中声明于 `CYL_FLATDESIGN_AVAILABLE` 之下），
 *      以及向上查找父控制器。只有包含扁平样式的构建才会编译本文件。
 */
extension NSObject {

    /**
     * [EN] The property is weak: store a weak box instead of retaining the tab bar controller directly. A strong reference here creates a retain
     *      cycle (tab bar controller -> child view controller -> tab bar controller) and the whole FlatDesign tab tree is never deallocated
     *      after it is popped (#661).
     * [CN] 该属性是弱引用：保存弱引用盒子，而不是直接持有 TabBarController。强引用会产生循环引用（TabBarController -> 子控制器 -> TabBarController），
     *      导致整个 FlatDesign Tab 树在 pop 之后永远不会释放（#661）。
     */
    @objc(cylflatdesign_setTabBarController:)
    func cylFlatDesignSetTabBarController(_ tabBarController: UIViewController?) {
        let key = CYLUtilsKeys.key("cylflatdesign_tabBarController")
        cyl_setWeakAssociatedObject(tabBarController, forKey: key)
        guard let viewController = self as? UIViewController else { return }
        viewController.cyl_getViewControllerInsteadOfNavigation().cyl_setWeakAssociatedObject(tabBarController, forKey: key)
    }

    /**
     * [EN] Flat design. The same lookup as `-cyl_tabBarController`, `-cyl_tabBarControllerForStyleType:` with `CYLTabBarStyleTypeFlatDesign`, with
     *      two differences kept from before: an explicit reference (`-cylflatdesign_setTabBarController:`) is returned as it is, and there is no
     *      fallback: nil when the object is not inside a flat design tab bar controller (callers use that to tell whether they are).
     * [CN] 扁平样式。与 `-cyl_tabBarController` 使用同一个查找（`-cyl_tabBarControllerForStyleType:`，传 `CYLTabBarStyleTypeFlatDesign`），保留以前的
     *      两点不同：显式设置的引用（`-cylflatdesign_setTabBarController:`）原样返回；没有回退：对象不在扁平样式的 TabBarController 内时返回 nil
     *      （调用方依此判断是否在其中）。
     */
    @objc(cylflatdesign_tabBarController)
    func cylFlatDesignTabBarController() -> UIViewController? {
        if let reference = cyl_weakAssociatedObject(forKey: CYLUtilsKeys.key("cylflatdesign_tabBarController")) as? UIViewController {
            return reference
        }
        return cylTabBarController(matching: { $0.tabBarStyleType == .flatDesign }, fallsBackToActive: false)
    }

    @objc(cyl_nearestParentViewControllerThatIsKindOf:)
    func cylNearestParentViewController(thatIsKindOf aClass: AnyClass) -> UIViewController? {
        var controller = (self as? UIViewController)?.parent
        while let current = controller, !current.isKind(of: aClass) {
            controller = current.parent
        }
        return controller
    }
}
