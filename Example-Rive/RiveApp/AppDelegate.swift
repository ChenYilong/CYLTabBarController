//
//  AppDelegate.swift
//  RiveApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/*!
 * [EN] A UIKit app (no SwiftUI `App`): the root view controller of the scene's window (SceneDelegate.swift) is a
 *      CYLTabBarController whose tab icons are Rive artboards. It reuses the course's screens, Rive files and assets from Example-SwiftUI-Rive (see README.md).
 * [CN] 一个 UIKit App（不使用 SwiftUI `App`）：scene 的 window（SceneDelegate.swift）的根控制器是 CYLTabBarController，其 Tab 图标是 Rive 画板。它复用
 *      Example-SwiftUI-Rive 中课程的页面、Rive 文件与资源（见 README.md）。
 */
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    /// [EN] The tabs and Rive attributes of the SwiftUI app (TabItems.swift) and a plus button (RivePlusButton.swift),
    ///      registered before the tab bar controller is created. The plus button shows the Timer tab's page, so Timer is
    ///      not a tab here: an iPhone tab bar shows at most 5 items.
    /// [CN] SwiftUI App 的 Tab 与 Rive 属性（TabItems.swift），以及一个 PlusButton（RivePlusButton.swift），在创建 TabBarController 之前注册。
    ///      PlusButton 显示 Timer Tab 的页面，因此这里没有 Timer Tab：iPhone 的 TabBar 最多显示 5 项。
    static func makeTabBarController() -> CYLTabBarController {
        RivePlusButton.register()
        let tabs = Tab.allCases.filter { $0 != .timer }
        let tabBarController = RiveTabBarController(viewControllers: tabs.map(\.viewController),
                                                    tabBarItemsAttributes: tabs.map(\.attributes))
        tabBarController.applyCourseTabBarAppearance()
        return tabBarController
    }
}
