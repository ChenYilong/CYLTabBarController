//
//  CYLBaseNavigationController.swift
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 [EN] A navigation controller that hides the tab bar for a pushed page and shows it again at the root
      (`UINavigationController+CYLBaseNavigation.swift`). An `open` Swift class since docs/Swift-Migration.md step 113 (phase ②;
      an Objective-C shell from step 102 until then).
 [CN] 推入页面时隐藏 TabBar、回到根页面时重新显示的导航控制器（`UINavigationController+CYLBaseNavigation.swift`）。自第 113 步（第 ② 阶段）起为
      `open` 的 Swift 类（此前为第 102 步的 Objective-C 外壳）。
 */
@objc(CYLBaseNavigationController)
open class CYLBaseNavigationController: UINavigationController {

    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        cyl_baseNavigationWillPush(viewController)
        super.pushViewController(viewController, animated: animated)
    }

    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        super.setViewControllers(viewControllers, animated: animated)
        cyl_baseNavigationToggleTabBarHidden()
    }

    open override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        let viewControllers = super.popToRootViewController(animated: animated)
        cyl_baseNavigationToggleTabBarHidden()
        return viewControllers
    }

    open override func popViewController(animated: Bool) -> UIViewController? {
        let viewController = super.popViewController(animated: animated)
        cyl_baseNavigationToggleTabBarHidden()
        return viewController
    }

    open override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let viewControllers = super.popToViewController(viewController, animated: animated)
        cyl_baseNavigationToggleTabBarHidden()
        return viewControllers
    }
}
