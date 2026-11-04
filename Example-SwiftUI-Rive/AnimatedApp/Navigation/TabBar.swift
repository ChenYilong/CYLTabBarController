//
//  TabBar.swift
//  AnimatedApp
//
//  Created by Meng To on 2022-04-07.
//  [EN] Rewritten for CYLTabBarController: the course's hand-made SwiftUI tab bar is now a CYLTabBarController.
//  [CN] 为 CYLTabBarController 重写：课程中手写的 SwiftUI TabBar 改为 CYLTabBarController。
//

import SwiftUI
import CYLTabBarController

/*!
 * [EN] The tab bar of the course, now a CYLTabBarController embedded in SwiftUI. Its Rive icons are the course's
 *      `icons.riv` artboards, given as tab attributes exactly like Lottie or PAG files: the tab bar adds them in place of
 *      the images, plays the selected one (the state machine input "active" is YES for a second, as the course did by
 *      hand) and stops the others, in every tab bar style. Without the Rive subspec the SF Symbols show.
 * [CN] 课程中的 TabBar，现在是嵌入 SwiftUI 的 CYLTabBarController。Rive 图标是课程 `icons.riv` 中的画板，与 Lottie、PAG 文件一样作为 Tab 属性
 *      传入：TabBar 用它们替换图片，播放选中的图标（状态机输入 "active" 为 YES 一秒，与课程中手写的逻辑相同），并停止其他图标，所有 TabBar
 *      样式均支持。未引入 Rive 子库时显示 SF Symbols。
 */
struct TabBar: UIViewControllerRepresentable {

    func makeUIViewController(context _: Context) -> CYLTabBarController {
        let viewControllers = Tab.allCases.map { tab -> UIViewController in
            UIHostingController(rootView: tab.content)
        }
        let tabBarController = CYLTabBarController(viewControllers: viewControllers,
                                                   tabBarItemsAttributes: Tab.allCases.map(\.attributes))
        // [EN] Before its view loads. The course's icons are white, drawn for its dark navy bar.
        // [CN] 在其视图加载之前设置。课程的图标是白色的，为深蓝色 TabBar 设计。
        tabBarController.tabBarStyleType = .liquidGlass
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(named: "Background 2")?.withAlphaComponent(0.8)
        tabBarController.tabBar.standardAppearance = appearance
        tabBarController.tabBar.scrollEdgeAppearance = appearance
        tabBarController.tabBar.overrideUserInterfaceStyle = .dark
        tabBarController.tabBar.tintColor = .white
        return tabBarController
    }

    func updateUIViewController(_: CYLTabBarController, context _: Context) {
        // [EN] Intentionally empty: the tab bar controller is created once; recreating it would drop each tab's state.
        // [CN] 有意留空：TabBarController 只创建一次；重新创建会丢失各 Tab 的状态。
    }
}

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

    @ViewBuilder
    var content: some View {
        switch self {
        case .chat:
            HomeView()
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 104)
                }
        default:
            TabPlaceholderView(title: rawValue.capitalized)
        }
    }
}

/// [EN] The other tabs of the demo. [CN] Demo 中的其他 Tab。
private struct TabPlaceholderView: View {
    let title: String

    var body: some View {
        ZStack {
            Color("Background").ignoresSafeArea()
            Text(title)
                .customFont(.largeTitle)
        }
    }
}
