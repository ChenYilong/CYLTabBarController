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

    /**
     * [EN] Issue #415: the source of the icons (SVGATabIcons.swift). ContentView recreates the tab bar when it changes.
     * [CN] Issue #415：图标来源（SVGATabIcons.swift）。来源改变时 ContentView 重新创建 TabBar。
     */
    var iconSource = CYLDemoTabIconSource.current

    func makeUIViewController(context _: Context) -> CYLTabBarController {
        if iconSource == .svgaConfigurationFile, let tabBarController = Self.makeSVGAConfigurationTabBarController() {
            return tabBarController
        }
        // [EN] Issue #415: SVGA icons given with the SVGA initialization keys, one for one with the Rive ones.
        // [CN] Issue #415：用 SVGA 初始化 key 提供的 SVGA 图标，与 Rive 图标一一对应。
        let usesSVGA = iconSource == .svgaKeys
        let tabBarController = CourseTabBarController(viewControllers: Tab.allCases.map(\.pageViewController),
                                                      tabBarItemsAttributes: Tab.allCases.map { usesSVGA ? $0.svgaAttributes : $0.attributes })
        tabBarController.applyCourseTabBarAppearance()
        return tabBarController
    }

    /**
     * [EN] The tab bar of cyl_tabbar_configuration_svga.json: tabs and SVGA icons from the file (`CYLTabBarSVGAFilePath`),
     *      pages from the page registry. nil (and the Rive tab bar) when the file cannot be read.
     * [CN] cyl_tabbar_configuration_svga.json 中的 TabBar：Tab 与 SVGA 图标来自该文件（`CYLTabBarSVGAFilePath`），页面来自页面注册表。
     *      无法读取文件时返回 nil（并使用 Rive 的 TabBar）。
     */
    private static func makeSVGAConfigurationTabBarController() -> CYLTabBarController? {
        guard let path = Bundle.main.path(forResource: "cyl_tabbar_configuration_svga", ofType: "json") else { return nil }
        CYLDemoSVGAConfigurationPages.registerIfNeeded { $0.pageViewController }
        do {
            let tabBarController = try CourseTabBarController(configurationFile: path)
            tabBarController.applyCourseTabBarAppearance()
            return tabBarController
        } catch {
            NSLog("%@", error.localizedDescription)
            return nil
        }
    }

    func updateUIViewController(_: CYLTabBarController, context _: Context) {
        // [EN] Intentionally empty: the tab bar controller is created once; recreating it would drop each tab's state.
        // [CN] 有意留空：TabBarController 只创建一次；重新创建会丢失各 Tab 的状态。
    }
}

extension Tab {
    /**
     * [EN] The page of the tab: the course's screens, and on Bell the shared test list with the SVGA demo above it (issue #415).
     * [CN] 该 Tab 的页面：课程页面；Bell 为共用的测试列表，上方是 SVGA 演示（issue #415）。
     */
    var pageViewController: UIViewController {
        self == .bell ? settingsViewController(headerView: SVGATabIconDemoView()) : UIHostingController(rootView: content)
    }

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
