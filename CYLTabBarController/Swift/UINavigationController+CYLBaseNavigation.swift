//
//  UINavigationController+CYLBaseNavigation.swift
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
 [EN] The logic of `CYLBaseNavigationController` (docs/Swift-Migration.md step 102): the tab bar hides for every pushed page but
      the root, through `cyl_hidesBottomBarWhenPushed`. The Objective-C class stays as a shell, since apps subclass it in
      Objective-C; its overrides call these methods after `super`.
 [CN] `CYLBaseNavigationController` 的逻辑（docs/Swift-Migration.md 第 102 步）：除根页面外，每个被 push 的页面都通过
      `cyl_hidesBottomBarWhenPushed` 隐藏 TabBar。Objective-C 类保留为外壳，因为 App 会在 Objective-C 中继承它；其重写在调用 `super` 后调用这些方法。
 */
extension UINavigationController {

    /**
     [EN] Before a push: the page pushed on top of the root hides the tab bar, a deeper one does not change it (it is already
          hidden). [CN] push 之前：压在根页面上的页面隐藏 TabBar，更深的页面不改变它（TabBar 已经隐藏）。
     */
    @objc(cyl_baseNavigationWillPushViewController:)
    public func cylBaseNavigationWillPush(_ viewController: UIViewController) {
        viewController.cyl_hidesBottomBarWhenPushed = viewControllers.count == 1
    }

    /**
     [EN] After the stack changed: the top page hides the tab bar unless it is the root. [CN] 栈变化之后：顶部页面不是根页面时隐藏 TabBar。
     */
    @objc(cyl_baseNavigationToggleTabBarHidden)
    public func cylBaseNavigationToggleTabBarHidden() {
        viewControllers.last?.cyl_hidesBottomBarWhenPushed = viewControllers.count > 1
    }
}
