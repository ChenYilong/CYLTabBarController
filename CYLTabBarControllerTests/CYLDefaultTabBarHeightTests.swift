//
//  CYLDefaultTabBarHeightTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import XCTest
import CYLTabBarController

/**
 [EN] Default tab bar height (docs/Cross-Platform-Components.md, "default tab bar height = the system tab bar's"): with no
      `tabBarHeight` set, the tab bar of a `CYLTabBarController` is as tall as the `UITabBar` of a plain
      `UITabBarController` in a window of the same size (Liquid Glass on iOS 26+, the classic bar below). A custom height still wins.
 [CN] 默认 TabBar 高度（docs/Cross-Platform-Components.md，“默认 TabBar 高度 = 系统 TabBar 高度”）：未设置 `tabBarHeight` 时，
      `CYLTabBarController` 的 TabBar 与同尺寸窗口中普通 `UITabBarController` 的 `UITabBar` 等高（iOS 26+ 为液态玻璃，更低版本为经典样式）。
      自定义高度仍然优先。
 */
final class CYLDefaultTabBarHeightTests: XCTestCase {
    private let windowFrame = CGRect(x: 0, y: 0, width: 390, height: 844)

    private func icon() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 25, height: 25)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 25, height: 25))
        }
    }

    private func layOut(_ controller: UITabBarController) -> UIWindow {
        let window = UIWindow(frame: windowFrame)
        window.rootViewController = controller
        window.isHidden = false
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
        controller.view.layoutIfNeeded()
        return window
    }

    private func systemTabBarHeight() -> CGFloat {
        let controller = UITabBarController()
        controller.viewControllers = (0..<3).map { index in
            let page = UIViewController()
            page.tabBarItem = UITabBarItem(title: "Tab \(index)", image: icon(), tag: index)
            return page
        }
        let window = layOut(controller)
        defer { window.isHidden = true }
        return controller.tabBar.frame.height
    }

    private func cylTabBarController(tabBarHeight: CGFloat?) -> (CYLTabBarController, UIWindow) {
        let attributes: [[AnyHashable: Any]] = (0..<3).map { [cylTabBarItemTitle: "Tab \($0)", cylTabBarItemImage: icon()] }
        let controller = CYLTabBarController(viewControllers: (0..<3).map { _ in UIViewController() },
                                             tabBarItemsAttributes: attributes)
        if let tabBarHeight { controller.tabBarHeight = tabBarHeight }
        return (controller, layOut(controller))
    }

    func testTheDefaultTabBarIsAsTallAsTheSystemTabBar() {
        let system = systemTabBarHeight()
        let (controller, window) = cylTabBarController(tabBarHeight: nil)
        defer { window.isHidden = true }
        let style = CYLConstants.isLiquidGlassActive() ? "Liquid Glass" : "classic"
        print("CYLDefaultTabBarHeight [\(style), iOS \(UIDevice.current.systemVersion)]: system UITabBar \(system) pt, CYLTabBarController \(controller.tabBar.frame.height) pt")
        XCTAssertGreaterThan(system, 0)
        XCTAssertEqual(controller.tabBar.frame.height, system, accuracy: 0.5,
                       "CYLTabBarController (\(style)) is as tall as the system UITabBar")
    }

    func testACustomTabBarHeightStillWins() throws {
        let system = systemTabBarHeight()
        let (controller, window) = cylTabBarController(tabBarHeight: 80)
        defer { window.isHidden = true }
        print("CYLDefaultTabBarHeight custom 80: system \(system) pt, CYLTabBarController tabBarHeight \(controller.tabBarHeight) pt, tabBar \(controller.tabBar.frame.height) pt")
        XCTAssertEqual(controller.tabBarHeight, 80, "the property keeps the custom height")
        if CYLConstants.isLiquidGlassActive() {
            // [EN] Liquid Glass floats the system bar; the library does not resize it (CYLTabBarController+CYLLayout.swift). [CN] 液态玻璃为浮动 TabBar，库不改其高度。
            XCTAssertEqual(controller.tabBar.frame.height, system, accuracy: 0.5)
        } else {
            XCTAssertGreaterThanOrEqual(controller.tabBar.frame.height, 80)
            XCTAssertNotEqual(controller.tabBar.frame.height, system, accuracy: 0.5)
        }
    }
}
