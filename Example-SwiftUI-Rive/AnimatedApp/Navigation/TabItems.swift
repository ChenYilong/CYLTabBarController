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
        attributes.merge(animationAttributes) { _, new in new }
        return attributes
    }

    /// [EN] The tab's Rive icon only. The course's icons.riv has no view model: `.riveInput` plays its state machine input
    ///      "active" instead.
    /// [CN] 仅该 Tab 的 Rive 图标。课程的 icons.riv 没有 view model：使用 `.riveInput` 播放其状态机输入 "active"。
    fileprivate var animationAttributes: [AnyHashable: Any] {
        let iconsURL = Bundle.main.url(forResource: "icons", withExtension: "riv")
        guard let url = CYLTabBarAnimationURLWithOptions(iconsURL, [
            .riveArtboard: rive.artboard,
            .riveStateMachine: rive.stateMachine,
            .riveInput: "active",
        ]) else {
            return [:]
        }
        return [CYLTabBarRiveURL: url, CYLTabBarRiveSize: NSValue(cgSize: CGSize(width: 32, height: 32))]
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

/*!
 * [EN] #216: a skin can change a tab's animation in place. The Christmas skin swaps the icons of "Chat" and "User"; icons.riv
 *      has no view model, so a skin cannot recolor it (`CYLTabBarAnimationColors` needs one). This runs after `super`, which
 *      applies the theme and restores the app's own look; a `CYLThemeDidChangeNotification` observer would run before it.
 * [CN] #216：皮肤可以原地更换 Tab 的动画。圣诞皮肤互换 Chat 与 User 的图标；icons.riv 没有 view model，因此皮肤无法为其换色
 *      （`CYLTabBarAnimationColors` 需要 view model）。这段代码在 `super` 之后执行，`super` 负责应用主题并恢复 App 自己的外观；
 *      `CYLThemeDidChangeNotification` 的监听者则会在它之前执行。
 */
class CourseTabBarController: CYLTabBarController {

    override func cyl_themeDidChange(by manager: CYLThemeManager, identifier: (any NSCopying & NSObjectProtocol)?, theme: NSObject?) {
        super.cyl_themeDidChange(by: manager, identifier: identifier, theme: theme)
        guard let lastIndex = viewControllers?.indices.last else { return }
        let isChristmas = (identifier as? String) == "Christmas"
        // [EN] "Chat" is the first tab and "User" the last in both apps; what lies between differs (Example-Rive has a PlusButton).
        // [CN] 两个 App 中 Chat 都是第一个 Tab，User 都是最后一个；中间不同（Example-Rive 有 PlusButton）。
        setAnimation(of: isChristmas ? .user : .chat, at: 0)
        setAnimation(of: isChristmas ? .chat : .user, at: lastIndex)
    }

    private func setAnimation(of tab: Tab, at index: Int) {
        if let attributes = tab.animationAttributes as? [String: Any] {
            updateTabBarItem(at: UInt(index), attributes: attributes)
        }
    }
}
