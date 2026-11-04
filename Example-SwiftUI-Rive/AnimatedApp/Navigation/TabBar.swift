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
            if tab == .bell {
                // [EN] The test list shared by every Swift demo: every settings row of the library, grouped.
                // [CN] 所有 Swift Demo 共用的测试列表：库中所有设置行，分组显示。
                let settingsViewController = CYLSettingsDemoTableViewController()
                settingsViewController.title = tab.rawValue.capitalized
                return UINavigationController(rootViewController: settingsViewController)
            }
            return UIHostingController(rootView: tab.content)
        }
        let tabBarController = CYLTabBarController(viewControllers: viewControllers,
                                                   tabBarItemsAttributes: Tab.allCases.map(\.attributes))
        tabBarController.applyCourseTabBarAppearance()
        return tabBarController
    }

    func updateUIViewController(_: CYLTabBarController, context _: Context) {
        // [EN] Intentionally empty: the tab bar controller is created once; recreating it would drop each tab's state.
        // [CN] 有意留空：TabBarController 只创建一次；重新创建会丢失各 Tab 的状态。
    }
}

extension Tab {
    @ViewBuilder
    var content: some View {
        if self == .chat {
            HomeView()
                .safeAreaInset(edge: .top) {
                    Color.clear.frame(height: 104)
                }
        } else {
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
