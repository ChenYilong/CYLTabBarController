//
//  AppDelegate.swift
//  RiveApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/*!
 * [EN] A UIKit app (no SwiftUI `App`): the window's root view controller is a CYLTabBarController whose tab icons are Rive
 *      artboards. It reuses the course's screens, Rive files and assets from Example-SwiftUI-Rive (see README.md).
 * [CN] 一个 UIKit App（不使用 SwiftUI `App`）：window 的根控制器是 CYLTabBarController，其 Tab 图标是 Rive 画板。它复用
 *      Example-SwiftUI-Rive 中课程的页面、Rive 文件与资源（见 README.md）。
 */
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = Self.makeTabBarController()
        window.makeKeyAndVisible()
        self.window = window
        return true
    }

    /// [EN] The same tabs and Rive attributes as the SwiftUI app (TabItems.swift). [CN] 与 SwiftUI App 相同的 Tab 与 Rive 属性（TabItems.swift）。
    static func makeTabBarController() -> CYLTabBarController {
        let tabBarController = CYLTabBarController(viewControllers: Tab.allCases.map(\.viewController),
                                                   tabBarItemsAttributes: Tab.allCases.map(\.attributes))
        tabBarController.applyCourseTabBarAppearance()
        return tabBarController
    }
}
