//
//  TabPages.swift
//  TWDFGASDGDSFDFG
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

// [CN] 页面注册表的 Swift 用法（docs/Tab-Page-Registry.md）：这个文件只为了让 CI 编译 Swift 侧的 API；演示本身仍用代码创建 Tab。
// [EN] The page registry from Swift (docs/Tab-Page-Registry.md): this file exists so that CI compiles the Swift side of
//      the API; the demo itself still creates its tabs in code.

/// [CN] 遵守 `CYLTabBarPage` 的页面：按 "swift-auto" 自动注册，不需要注册代码。
/// [EN] A page that adopts `CYLTabBarPage`: registered automatically under "swift-auto", no registration code needed.
final class SwiftAutoPageViewController: UIViewController, CYLTabBarPage {
    static func cylTabBarPageIdentifier() -> String { "swift-auto" }

    static func cylTabBarPage(withAttributes tabAttributes: [String: Any]) -> UIViewController? {
        let page = SwiftAutoPageViewController()
        page.title = tabAttributes[CYLTabBarItemTitle] as? String
        return UINavigationController(rootViewController: page)
    }
}

enum TabPages {
    /// [CN] 在全局注册表中注册页面；在创建 TabBarController 之前调用一次。
    /// [EN] Registers pages in the shared registry; call it once before any tab bar controller is created.
    static func register() {
        let registry = CYLTabBarPageRegistry.shared
        // [CN] 带类型化请求的工厂（推荐）。 [EN] A factory with a typed request (preferred).
        registry.register(factory: { request in
            let page = UIViewController()
            page.title = request.title
            page.view.backgroundColor = .systemBackground
            return UINavigationController(rootViewController: page)
        }, forPageIdentifier: "swift-home")
        // [CN] 几个页面 ID 共用一个工厂，用 `parameters` 区分。 [EN] Several page IDs share one factory, told apart by `parameters`.
        registry.register(factory: { request in
            let page = UIViewController()
            page.title = request.parameters["topic"] as? String ?? request.pageIdentifier
            return page
        }, forPageIdentifiers: ["swift-web", "swift-docs"])
    }

    /// [CN] 由配置创建 TabBarController，并列出没有页面的 Tab。
    /// [EN] A tab bar controller from a configuration, listing the tabs that got no page.
    static func makeTabBarController() -> CYLTabBarController {
        let tabBarController = CYLTabBarController(configuration: [
            CYLTabBarControllerPageLookupOrder: [CYLTabBarPageSource.sharedRegistry, CYLTabBarPageSource.automaticRegistration],
            CYLTabBarControllerTabBarItemsAttributes: [
                [CYLTabBarItemTitle: "Home", CYLTabBarItemImage: "system:house", CYLTabBarItemPageIdentifier: "swift-home"],
                [CYLTabBarItemTitle: "Auto", CYLTabBarItemImage: "system:star", CYLTabBarItemPageIdentifier: "swift-auto"],
                [CYLTabBarItemTitle: "Docs", CYLTabBarItemImage: "system:book", CYLTabBarItemPageIdentifier: "swift-docs",
                 CYLTabBarItemPageParameters: ["topic": "Documentation"]],
                [CYLTabBarItemTitle: "Missing", CYLTabBarItemImage: "system:questionmark", CYLTabBarItemPageIdentifier: "no-such-page"],
            ],
        ])
        for skipped in tabBarController.cyl_skippedTabs {
            print("skipped tab \(skipped.title ?? "") (\(skipped.pageIdentifier ?? "no ID")): \(skipped.reason.rawValue)")
        }
        return tabBarController
    }
}
