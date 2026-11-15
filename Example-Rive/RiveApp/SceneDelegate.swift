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
        // [EN] The navigation bar button of the settings list rebuilds the tab bar in the other style.
        // [CN] 设置列表的导航栏按钮以另一种样式重建 TabBar。
        CYLDemoTabBarStyle.rebuildRootViewController = { [weak window] in
            window?.rootViewController = Self.makeTabBarController()
        }
        // [EN] The tab icon source switch of the Bell page (SVGATabIcons.swift) rebuilds it the same way.
        // [CN] Bell 页面的 Tab 图标来源切换（SVGATabIcons.swift）以同样方式重建。
        CYLDemoTabIconSource.rebuildTabBar = CYLDemoTabBarStyle.rebuildRootViewController
        window.makeKeyAndVisible()
        self.window = window
    }

    /// [EN] The tabs and Rive attributes of the SwiftUI app (TabItems.swift) and a plus button (RivePlusButton.swift),
    ///      registered before the tab bar controller is created. The plus button shows the Timer tab's page, so Timer is
    ///      not a tab here: an iPhone tab bar shows at most 5 items.
    /// [CN] SwiftUI App 的 Tab 与 Rive 属性（TabItems.swift），以及一个 PlusButton（RivePlusButton.swift），在创建 TabBarController 之前注册。
    ///      PlusButton 显示 Timer Tab 的页面，因此这里没有 Timer Tab：iPhone 的 TabBar 最多显示 5 项。
    private static func makeTabBarController() -> CYLTabBarController {
        // [EN] Issue #415: the same tab bar with SVGA icons from a configuration file (SVGATabIcons.swift).
        // [CN] Issue #415：同一个 TabBar，SVGA 图标来自配置文件（SVGATabIcons.swift）。
        if CYLDemoTabIconSource.current == .svgaConfigurationFile, let tabBarController = makeSVGAConfigurationTabBarController() {
            return tabBarController
        }
        RivePlusButton.register()
        let tabs = Tab.allCases.filter { $0 != .timer }
        // [EN] Issue #415: SVGA icons given with the SVGA initialization keys, one for one with the Rive ones.
        // [CN] Issue #415：用 SVGA 初始化 key 提供的 SVGA 图标，与 Rive 图标一一对应。
        let usesSVGA = CYLDemoTabIconSource.current == .svgaKeys
        let tabBarController = RiveTabBarController(viewControllers: tabs.map(\.viewController),
                                                    tabBarItemsAttributes: tabs.map { usesSVGA ? $0.svgaAttributes : $0.attributes },
                                                    styleType: CYLDemoTabBarStyle.styleType,
                                                    context: nil)
        tabBarController.applyCourseTabBarAppearance()
        return tabBarController
    }

    /**
     * [EN] The tab bar of RiveApp/SVGA/cyl_tabbar_configuration_svga.json: tabs, plus button and SVGA icons from the file
     *      (`CYLTabBarSVGAFilePath`), pages from the page registry. nil (and the Rive tab bar) when the file cannot be read.
     * [CN] RiveApp/SVGA/cyl_tabbar_configuration_svga.json 中的 TabBar：Tab、PlusButton 与 SVGA 图标来自该文件（`CYLTabBarSVGAFilePath`），页面来自页面注册表。
     *      无法读取文件时返回 nil（并使用 Rive 的 TabBar）。
     */
    private static func makeSVGAConfigurationTabBarController() -> CYLTabBarController? {
        guard let path = Bundle.main.path(forResource: "cyl_tabbar_configuration_svga", ofType: "json") else { return nil }
        // [EN] The plus button "Start" shows the Timer tab's page (svga-timer), as in the Rive tab bar.
        // [CN] PlusButton「Start」显示 Timer Tab 的页面（svga-timer），与 Rive TabBar 相同。
        CYLDemoSVGAConfigurationPages.registerIfNeeded { tab in
            let viewController = tab.viewController
            if tab == .timer {
                viewController.children.first?.title = "Start"
            }
            return viewController
        }
        do {
            let tabBarController = try RiveTabBarController(configurationFile: path)
            tabBarController.applyCourseTabBarAppearance()
            return tabBarController
        } catch {
            NSLog("%@", error.localizedDescription)
            return nil
        }
    }
}
