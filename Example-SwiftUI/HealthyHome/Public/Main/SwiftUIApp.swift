//
//  SwiftUIApp.swift
//  HealthyHome (SwiftUI)
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import SwiftUI
import UIKit

// [EN] A SwiftUI app (SwiftUI `App` life cycle) whose root is a CYLTabBarController. The tab bar controller is UIKit,
//      embedded with `UIViewControllerRepresentable`; every tab and the plus button's page are SwiftUI views in a
//      `UIHostingController`. `TabBarBridge` lets the SwiftUI views drive the tab bar (badges, selection, push).
//      See docs/SwiftUI-Integration.md.
// [CN] 一个 SwiftUI App（SwiftUI `App` 生命周期），根视图是 CYLTabBarController。TabBarController 属于 UIKit，通过
//      `UIViewControllerRepresentable` 嵌入；每个 Tab 以及 PlusButton 的页面都是放在 `UIHostingController` 中的 SwiftUI 视图。
//      `TabBarBridge` 让 SwiftUI 视图控制 TabBar（角标、选中、push）。见 docs/SwiftUI-Integration.md。
@main
struct HealthyHomeSwiftUIApp: App {
    // [EN] The UIKit app delegate is kept for code that still needs one.
    // [CN] 保留 UIKit 的 AppDelegate，供仍需要它的代码使用。
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var bridge = TabBarBridge()

    init() {
        // [EN] Register the plus button before the tab bar controller is created.
        // [CN] 在创建 TabBarController 之前注册 PlusButton。
        CYLPlusButtonSubclass.register()
    }

    var body: some Scene {
        WindowGroup {
            CYLTabBarControllerView(bridge: bridge)
                // [EN] The tab bar controller lays out its own safe area, like a UIKit root view controller.
                // [CN] TabBarController 自己处理安全区域，与 UIKit 的根控制器一致。
                .ignoresSafeArea()
        }
    }
}

// MARK: - Bridge

/// [EN] Gives SwiftUI views access to the CYLTabBarController that hosts them: badges, tab selection by identifier, and
///      pushing a SwiftUI page onto the selected tab. Passed down as an environment object.
/// [CN] 让 SwiftUI 视图访问承载它们的 CYLTabBarController：角标、按标识选中 Tab，以及向当前 Tab push 一个 SwiftUI 页面。
///      以 environment object 的形式向下传递。
final class TabBarBridge: ObservableObject {
    weak var tabBarController: CYLTabBarController?

    /// [EN] The plus button's touchable area values, mirrored so SwiftUI controls can bind to them.
    /// [CN] PlusButton 可点击区域的设置，镜像一份供 SwiftUI 控件绑定。
    @Published var showsTouchableArea = false {
        didSet { plusButton?.showsTouchableArea = showsTouchableArea }
    }
    @Published var touchableAreaScale: Double = 1 {
        didSet { plusButton?.touchableAreaScale = CGFloat(touchableAreaScale) }
    }

    /// [EN] Guard: only when the tab bar controller has a plus button.
    /// [CN] 仅在 TabBarController 有 PlusButton 时返回。
    var plusButton: CYLPlusButton? {
        guard let tabBarController, tabBarController.hasPlusButton() else { return nil }
        // [EN] `+plusButtonForOwner:` is imported into Swift as an initializer. [CN] `+plusButtonForOwner:` 在 Swift 中导入为构造方法。
        return CYLPlusButton(forOwner: tabBarController)
    }

    func select(_ identifier: String) {
        tabBarController?.cyl_selectTabBarItem(withIdentifier: identifier)
    }

    func showBadge(_ value: String, onTab identifier: String) {
        tabBarController?.cyl_viewController(withTabBarItemIdentifier: identifier)?
            .cyl_showBadgeValue(value, animationType: .bounce)
    }

    func clearBadge(onTab identifier: String) {
        tabBarController?.cyl_viewController(withTabBarItemIdentifier: identifier)?.cyl_clearBadge()
    }

    /// [EN] Pushes a SwiftUI page onto the selected tab's navigation stack, with the tab bar hidden.
    /// [CN] 将一个 SwiftUI 页面 push 到当前 Tab 的导航栈中，并隐藏 TabBar。
    func push<Content: View>(_ content: Content, title: String) {
        guard let navigationController = tabBarController?.selectedViewController as? UINavigationController else { return }
        let hostingController = UIHostingController(rootView: content.environmentObject(self))
        hostingController.title = title
        hostingController.hidesBottomBarWhenPushed = true
        navigationController.pushViewController(hostingController, animated: true)
    }
}

// MARK: - CYLTabBarController in SwiftUI

/// [EN] CYLTabBarController as a SwiftUI view. It is created once, in `makeUIViewController`; SwiftUI state reaches it
///      through `TabBarBridge`, so `updateUIViewController` has nothing to do.
/// [CN] 以 SwiftUI 视图的形式使用 CYLTabBarController。只在 `makeUIViewController` 中创建一次；SwiftUI 的状态通过 `TabBarBridge`
///      传递给它，因此 `updateUIViewController` 无需处理。
struct CYLTabBarControllerView: UIViewControllerRepresentable {
    let bridge: TabBarBridge

    func makeUIViewController(context _: Context) -> CYLTabBarController {
        let viewControllers = SwiftUITab.allCases.map { tab -> UIViewController in
            let hostingController = UIHostingController(rootView: tab.content.environmentObject(bridge))
            hostingController.title = tab.title
            return RootNavigationController(rootViewController: hostingController)
        }
        // [EN] The same titles and icons as Example-Swift-03, plus an identifier per tab (#408).
        // [CN] 与 Example-Swift-03 相同的标题和图标，并为每个 Tab 加上标识（#408）。
        let attributes = zip(TabBarCommon.tabBarItemsAttributesForController(), SwiftUITab.allCases).map { item, tab -> [AnyHashable: Any] in
            var item = item
            item[CYLTabBarItemIdentifier] = tab.identifier
            return item
        }
        let tabBarController = RootTabBarController(viewControllers: viewControllers, tabBarItemsAttributes: attributes)
        // [EN] Before its view loads, as in UIKit.
        // [CN] 在其视图加载之前设置，与 UIKit 中一致。
        tabBarController.tabBarStyleType = .liquidGlass
        bridge.tabBarController = tabBarController
        return tabBarController
    }

    func updateUIViewController(_: CYLTabBarController, context _: Context) {
        // [EN] Intentionally empty: the tab bar controller is created once in `makeUIViewController`, and SwiftUI state
        //      reaches it through `TabBarBridge`. Recreating or reconfiguring it here would drop every tab's navigation stack.
        // [CN] 有意留空：TabBarController 只在 `makeUIViewController` 中创建一次，SwiftUI 的状态通过 `TabBarBridge` 传递给它。
        //      在这里重新创建或重新配置会丢失各 Tab 的导航栈。
    }
}
