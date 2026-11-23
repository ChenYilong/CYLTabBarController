//
//  TabViewControllers.swift
//  RiveApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import SwiftUI
import UIKit

extension Tab {
    /// [EN] The page of each tab: the course's SwiftUI screens in a UIHostingController, and the UIKit test list.
    /// [CN] 每个 Tab 的页面：放在 UIHostingController 中的课程 SwiftUI 页面，以及 UIKit 测试列表。
    var viewController: UIViewController {
        let rootViewController: UIViewController
        switch self {
        case .chat:
            rootViewController = UIHostingController(rootView: HomeView())
        case .search:
            // [EN] The course's side menu, with its Rive icons, on the course's dark background.
            // [CN] 课程的侧边菜单及其 Rive 图标，使用课程的深色背景。
            rootViewController = UIHostingController(rootView: SideMenu()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .background(Color(hex: "17203A").ignoresSafeArea()))
        case .timer:
            rootViewController = UIHostingController(rootView: OnboardingView(show: .constant(true)))
        case .bell:
            // [EN] The shared test list, with a Rive animation in plain UIKit above it, then the SVGA demo (issue #415).
            // [CN] 共用的测试列表，上方是纯 UIKit 中的 Rive 动画，其后是 SVGA 演示（issue #415）。
            let demos = UIStackView(arrangedSubviews: [RiveMenuButtonDemoView(), SVGATabIconDemoView()])
            demos.axis = .vertical
            return settingsViewController(headerView: demos)
        case .user:
            rootViewController = UIHostingController(rootView: SignInView(show: .constant(true)))
            // [EN] The next tab in turn after the Bell tab's demos (AGENTS.md, "Demo table rows"): the engine API of
            //      `CYLAnimatedItemView`, a page pushed from the navigation bar. [CN] 轮到 Bell Tab 的演示之后的下一个 Tab
            //      （AGENTS.md「Demo table rows」）：`CYLAnimatedItemView` 的引擎 API，从导航栏推入的页面。
            let engineAPIItem = UIBarButtonItem(title: cylDemoLocalizedString("Engine API"), primaryAction: UIAction { [weak rootViewController] _ in
                rootViewController?.navigationController?.pushViewController(AnimatedItemEngineAPIViewController(), animated: true)
            })
            engineAPIItem.accessibilityIdentifier = "AnimatedItemEngineAPIButton"
            rootViewController.navigationItem.rightBarButtonItem = engineAPIItem
        }
        rootViewController.title = rawValue.capitalized
        return UINavigationController(rootViewController: rootViewController)
    }
}
