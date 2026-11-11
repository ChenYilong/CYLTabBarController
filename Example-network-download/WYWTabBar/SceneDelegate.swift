//
//  SceneDelegate.swift
//  WYWTabBar
//
//  Ported from Objective-C on 2026/11/11: the examples are Swift only.
//

import UIKit
import CYLTabBarController

/// [EN] `@objc(SceneDelegate)`: Info.plist names the scene delegate class `SceneDelegate`.
/// [CN] `@objc(SceneDelegate)`：Info.plist 中场景代理的类名为 `SceneDelegate`。
@objc(SceneDelegate)
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var tabBarController: MainTabBarController?

    // [EN] Creates the window for the scene: apps built with the iOS 27 SDK must adopt the UIScene life cycle.
    // [CN] 为 scene 创建 window：使用 iOS 27 SDK 构建的 App 必须采用 UIScene 生命周期。
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .white
        self.window = window
        showTabBarController(style: .liquidGlass)
        window.makeKeyAndVisible()
    }

    /// [EN] Shows the tabs with `style` (Liquid Glass or FlatDesign), then loads their icons from the network: the in-place
    ///      updates work in every style.
    /// [CN] 以 `style`（液态玻璃或扁平样式）显示 Tab，再从网络加载图标：原地更新适用于所有样式。
    func showTabBarController(style: CYLTabBarStyleType) {
        // [CN] 2. 创建 5 个页面 + 导航栏
        // [EN] 2. Create the 5 pages and their navigation bars.
        // [CN] 3. 包装导航控制器
        // [EN] 3. Wrap them in navigation controllers.
        let homeNav = wrapInNavigation(HomeViewController(), title: cylDemoLocalizedString("首页"))
        let wealthNav = wrapInNavigation(WealthViewController(), title: cylDemoLocalizedString("理财"))
        let tradeNav = wrapInNavigation(TradeViewController(), title: cylDemoLocalizedString("交易"))
        let infoNav = wrapInNavigation(InfoViewController(), title: cylDemoLocalizedString("资讯"))
        let mineNav = wrapInNavigation(MineViewController(), title: cylDemoLocalizedString("我的"))

        // [CN] 1. 创建 TabBar 主控制器（图片使用 UIImage，非字符串）
        // [EN] 1. Create the tab bar controller (the images are UIImages, not names).
        // FIX: issue #601, #337
        // [EN] CYLTabBarItemImage is the default icon and the placeholder; CYLTabBarItemImageURL replaces it once downloaded
        //      (cached, drawn in its own colors, every style, also over a Lottie icon).
        // [CN] CYLTabBarItemImage 是默认图标及占位图；CYLTabBarItemImageURL 下载完成后覆盖它（带缓存，保持图片自身颜色，适用于所有样式，
        //      也能覆盖 Lottie 图标）。
        let iconSize = NSValue(cgSize: CGSize(width: 24, height: 24))
        let attributes: [[AnyHashable: Any]] = [
            // [CN] 首页 [EN] Home
            [CYLTabBarItemTitle: cylDemoLocalizedString("首页"),
             CYLTabBarItemImage: UIImage(systemName: "house") as Any,
             CYLTabBarItemSelectedImage: UIImage(systemName: "house.fill") as Any,
             CYLTabBarItemImageURL: "https://cdn-icons-png.flaticon.com/512/3132/3132732.png",
             CYLTabBarItemSelectedImageURL: "https://cdn-icons-png.flaticon.com/512/3132/3132779.png",
             CYLTabBarItemImageURLSize: iconSize],
            // [CN] 行情 [EN] Markets
            [CYLTabBarItemTitle: cylDemoLocalizedString("行情"),
             CYLTabBarItemImage: UIImage(systemName: "chart.line.uptrend.xyaxis") as Any,
             CYLTabBarItemSelectedImage: UIImage(systemName: "chart.line.uptrend.xyaxis") as Any,
             CYLTabBarItemImageURL: "https://cdn-icons-png.flaticon.com/512/1828/1828884.png",
             CYLTabBarItemSelectedImageURL: "https://cdn-icons-png.flaticon.com/512/1828/1828925.png",
             CYLTabBarItemImageURLSize: iconSize],
            // [CN] 交易 [EN] Trade
            [CYLTabBarItemTitle: cylDemoLocalizedString("交易"),
             CYLTabBarItemImage: UIImage(systemName: "plus.circle") as Any,
             CYLTabBarItemSelectedImage: UIImage(systemName: "plus.circle.fill") as Any,
             CYLTabBarItemImageURL: "https://cdn-icons-png.flaticon.com/512/3132/3132732.png",
             CYLTabBarItemSelectedImageURL: "https://cdn-icons-png.flaticon.com/512/3132/3132779.png",
             CYLTabBarItemImageURLSize: iconSize],
            // [CN] 资讯 [EN] News
            [CYLTabBarItemTitle: cylDemoLocalizedString("资讯"),
             CYLTabBarItemImage: UIImage(systemName: "newspaper") as Any,
             CYLTabBarItemSelectedImage: UIImage(systemName: "newspaper.fill") as Any,
             CYLTabBarItemImageURL: "https://cdn-icons-png.flaticon.com/512/1828/1828884.png",
             CYLTabBarItemSelectedImageURL: "https://cdn-icons-png.flaticon.com/512/1828/1828925.png",
             CYLTabBarItemImageURLSize: iconSize],
            // [CN] 我的 [EN] Me
            // FIX: issue #605
            // [EN] An animated GIF icon; any URL works, a file URL here.
            // [CN] GIF 动图图标；任何 URL 都可以，这里使用本地文件 URL。
            [CYLTabBarItemTitle: cylDemoLocalizedString("我的"),
             CYLTabBarItemImage: UIImage(systemName: "person") as Any,
             CYLTabBarItemSelectedImage: UIImage(systemName: "person.fill") as Any,
             CYLTabBarItemImageURL: Bundle.main.url(forResource: "tab_animated", withExtension: "gif") as Any,
             CYLTabBarItemImageURLSize: iconSize],
        ]
        let tabBarController = MainTabBarController(viewControllers: [homeNav, wealthNav, tradeNav, infoNav, mineNav],
                                                    tabBarItemsAttributes: attributes,
                                                    styleType: style,
                                                    context: nil)
        self.tabBarController = tabBarController

        // [CN] 6. 设置 Window 根控制器
        // [EN] 6. Set the window's root view controller.
        window?.rootViewController = tabBarController
        updateTitleAfterPurchase()
    }

    // [CN] 包装导航栏
    // [EN] Wraps a page in a navigation controller.
    private func wrapInNavigation(_ viewController: UIViewController, title: String) -> UINavigationController {
        viewController.title = title
        return UINavigationController(rootViewController: viewController)
    }

    private func updateTitleAfterPurchase() {
        // [EN] FIX: issue #601 — e.g. after a purchase: the title of a tab, in place.
        // [CN] 例如购买课程后：原地更新某个 Tab 的标题。
        tabBarController?.updateTabBarItem(at: 1, attributes: [CYLTabBarItemTitle: cylDemoLocalizedString("已购课程")])
    }
}
