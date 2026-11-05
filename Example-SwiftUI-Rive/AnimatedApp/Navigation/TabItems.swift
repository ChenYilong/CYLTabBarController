//
//  TabItems.swift
//  AnimatedApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/*!
 * [EN] The tabs of the demo and their CYLTabBarController attributes, shared by Example-SwiftUI-Rive (SwiftUI app) and
 *      Example-Rive (UIKit app). This is all the Rive integration needs: each tab's icon is an artboard of the course's
 *      icons.riv, given as `CYLTabBarRiveURL` like a Lottie or PAG file.
 * [CN] Demo 的 Tab 及其 CYLTabBarController 属性，由 Example-SwiftUI-Rive（SwiftUI App）与 Example-Rive（UIKit App）共用。这就是 Rive 集成所需的
 *      全部内容：每个 Tab 的图标是课程 icons.riv 中的一个画板，与 Lottie、PAG 文件一样作为 `CYLTabBarRiveURL` 传入。
 */
enum Tab: String, CaseIterable {
    case chat
    case search
    case timer
    case bell
    case user

    /// [EN] The tab's artboard and state machine in the course's icons.riv. [CN] 该 Tab 在课程 icons.riv 中的画板与状态机。
    private var rive: (artboard: String, stateMachine: String) {
        switch self {
        case .chat: return ("CHAT", "CHAT_Interactivity")
        case .search: return ("SEARCH", "SEARCH_Interactivity")
        case .timer: return ("TIMER", "TIMER_Interactivity")
        case .bell: return ("BELL", "BELL_Interactivity")
        case .user: return ("USER", "USER_Interactivity")
        }
    }

    /// [EN] Shown without the Rive subspec. [CN] 未引入 Rive 子库时显示。
    private var symbolName: String {
        switch self {
        case .chat: return "message"
        case .search: return "magnifyingglass"
        case .timer: return "timer"
        case .bell: return "bell"
        case .user: return "person"
        }
    }

    var attributes: [AnyHashable: Any] {
        let image = UIImage(systemName: symbolName) ?? UIImage()
        var attributes: [AnyHashable: Any] = [
            CYLTabBarItemTitle: rawValue.capitalized,
            CYLTabBarItemImage: image,
            CYLTabBarItemSelectedImage: image,
        ]
        // [EN] The course's icons.riv has no view model: `.riveInput` plays its state machine input "active" instead.
        // [CN] 课程的 icons.riv 没有 view model：使用 `.riveInput` 播放其状态机输入 "active"。
        let iconsURL = Bundle.main.url(forResource: "icons", withExtension: "riv")
        if let url = CYLTabBarAnimationURLWithOptions(iconsURL, [
            .riveArtboard: rive.artboard,
            .riveStateMachine: rive.stateMachine,
            .riveInput: "active",
        ]) {
            attributes[CYLTabBarRiveURL] = url
            attributes[CYLTabBarRiveSize] = NSValue(cgSize: CGSize(width: 32, height: 32))
        }
        return attributes
    }
}

extension Tab {
    /// [EN] The Bell tab's page in both apps: the test list shared by every Swift demo (every settings row of the library,
    ///      grouped), in a navigation controller, with an optional view above the rows.
    /// [CN] 两个 App 中 Bell Tab 的页面：所有 Swift Demo 共用的测试列表（库中所有设置行，分组显示），放在导航控制器中，各行上方可选显示一个视图。
    func settingsViewController(headerView: UIView? = nil) -> UIViewController {
        let settingsViewController = CYLSettingsDemoTableViewController()
        settingsViewController.title = rawValue.capitalized
        settingsViewController.headerView = headerView
        return UINavigationController(rootViewController: settingsViewController)
    }
}

extension CYLTabBarController {
    /// [EN] Call before the view loads. The course's icons are white, drawn for its dark navy bar.
    /// [CN] 在视图加载之前调用。课程的图标是白色的，为深蓝色 TabBar 设计。
    func applyCourseTabBarAppearance() {
        tabBarStyleType = .liquidGlass
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(named: "Background 2")?.withAlphaComponent(0.8)
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.overrideUserInterfaceStyle = .dark
        tabBar.tintColor = .white
    }
}
