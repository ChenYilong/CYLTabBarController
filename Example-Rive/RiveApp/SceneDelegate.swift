//
//  SceneDelegate.swift
//  RiveApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

// [EN] Creates the window for the scene: apps built with the iOS 27 SDK must adopt the UIScene life cycle.
// [CN] 为 scene 创建 window：使用 iOS 27 SDK 构建的 App 必须采用 UIScene 生命周期。
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = Self.makeTabBarController()
        window.makeKeyAndVisible()
        self.window = window
    }

    /// [EN] The tabs and Rive attributes of the SwiftUI app (TabItems.swift) and a plus button (RivePlusButton.swift),
    ///      registered before the tab bar controller is created. The plus button shows the Timer tab's page, so Timer is
    ///      not a tab here: an iPhone tab bar shows at most 5 items.
    /// [CN] SwiftUI App 的 Tab 与 Rive 属性（TabItems.swift），以及一个 PlusButton（RivePlusButton.swift），在创建 TabBarController 之前注册。
    ///      PlusButton 显示 Timer Tab 的页面，因此这里没有 Timer Tab：iPhone 的 TabBar 最多显示 5 项。
    private static func makeTabBarController() -> CYLTabBarController {
        RivePlusButton.register()
        let tabs = Tab.allCases.filter { $0 != .timer }
        let tabBarController = RiveTabBarController(viewControllers: tabs.map(\.viewController),
                                                    tabBarItemsAttributes: tabs.map(\.attributes))
        tabBarController.applyCourseTabBarAppearance()
        return tabBarController
    }
}
