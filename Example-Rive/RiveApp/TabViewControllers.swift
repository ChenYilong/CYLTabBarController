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
            // [EN] The shared test list, with a Rive animation in plain UIKit above it. [CN] 共用的测试列表，上方是纯 UIKit 中的 Rive 动画。
            return settingsViewController(headerView: RiveMenuButtonDemoView())
        case .user:
            rootViewController = UIHostingController(rootView: SignInView(show: .constant(true)))
        }
        rootViewController.title = rawValue.capitalized
        return UINavigationController(rootViewController: rootViewController)
    }
}
