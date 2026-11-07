//
//  CYLDemoTabBarStyle.swift
//  CYLTabBarController demos
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import UIKit

/*!
 * [EN] The tab bar style of a demo, chosen from the navigation bar: FlatDesign, or the system's (Liquid Glass on iOS 26 and
 *      later, the classic tab bar before), so the same animated tabs can be compared in all three. A demo gives its tab bar
 *      `styleType` when it creates it, and sets `rebuildRootViewController` to show the button. The launch argument
 *      `-CYLDemoTabBarFlatDesign YES` chooses FlatDesign too.
 * [CN] Demo 的 TabBar 样式，在导航栏中选择：扁平样式，或系统样式（iOS 26 及以后为液态玻璃，之前为经典 TabBar），以便在三种样式下对比相同的动画 Tab。Demo 在
 *      创建 TabBar 时传入 `styleType`，并设置 `rebuildRootViewController` 以显示按钮。启动参数 `-CYLDemoTabBarFlatDesign YES` 同样选择扁平样式。
 */
enum CYLDemoTabBarStyle {
    private static let defaultsKey = "CYLDemoTabBarFlatDesign"
    static var rebuildRootViewController: (() -> Void)?

    static var isFlatDesign: Bool {
        get { UserDefaults.standard.bool(forKey: defaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }

    static var styleType: CYLTabBarStyleType {
        isFlatDesign ? .flatDesign : .default
    }

    /// [EN] The title of the button: the style it switches to. [CN] 按钮标题：切换后的样式。
    static var switchTitle: String {
        if !isFlatDesign {
            return "Flat Design"
        }
        return CYLConstants.isLiquidGlassActive() ? "Liquid Glass" : "Classic"
    }

    /// [EN] Rebuilds the tab bar in the other style, staying on the tab of `viewController`: its list holds the button that
    ///      switches back.
    /// [CN] 以另一种样式重建 TabBar，并停留在 `viewController` 所在的 Tab：它的列表上有切换回去的按钮。
    static func toggle(from viewController: UIViewController) {
        let selectedIndex = viewController.tabBarController?.selectedIndex
        let window = viewController.view.window
        isFlatDesign.toggle()
        rebuildRootViewController?()
        if let selectedIndex = selectedIndex, let rebuilt = window?.rootViewController as? UITabBarController {
            rebuilt.selectedIndex = selectedIndex
        }
    }
}
