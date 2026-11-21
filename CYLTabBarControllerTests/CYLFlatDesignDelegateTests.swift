//
//  CYLFlatDesignDelegateTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import XCTest
import CYLTabBarController

/**
 [EN] The FlatDesign plus button (docs/PlusButton.md, 2026-11-21): the controller must be its flat-design tab bar's delegate,
      or the bar counts as a standalone bar and leaves the plus slot empty.
 [CN] 扁平样式的 PlusButton（docs/PlusButton.md，2026-11-21）：控制器必须是其扁平样式 TabBar 的代理，否则 TabBar 被当作独立 TabBar，
      PlusButton 的位置留空。
 */
final class CYLFlatDesignDelegateTests: XCTestCase {
    private func icon() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 8))
        }
    }

    private func flatDesignTabBar(in view: UIView) -> UIView? {
        guard let barClass = NSClassFromString("CYLFlatDesignTabBar") else { return nil }
        var queue = [view]
        while !queue.isEmpty {
            let next = queue.removeFirst()
            if next.isKind(of: barClass) {
                return next
            }
            queue.append(contentsOf: next.subviews)
        }
        return nil
    }

    func testTheControllerIsItsFlatDesignTabBarsDelegateAndShowsThePlusButton() throws {
        guard let delegateProtocol = NSProtocolFromString("CYLFlatDesignTabBarDelegate"),
              NSClassFromString("CYLFlatDesignTabBar") != nil else {
            throw XCTSkip("FlatDesign is not compiled into this target")
        }
        XCTAssertTrue(CYLTabBarController.conforms(to: delegateProtocol), "CYLTabBarController adopts CYLFlatDesignTabBarDelegate")

        let context = UUID().uuidString
        CYLPlusButton.cyl_register(attributes: [CYLTabBarItemTitle: "Post", CYLTabBarItemImage: icon()], action: nil, context: context)
        let attributes: [[AnyHashable: Any]] = [
            [CYLTabBarItemTitle: "A", CYLTabBarItemImage: icon()],
            [CYLTabBarItemTitle: "B", CYLTabBarItemImage: icon()],
        ]
        let controller = CYLTabBarController(viewControllers: [UIViewController(), UIViewController()],
                                             tabBarItemsAttributes: attributes, styleType: .flatDesign, context: context)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.isHidden = false
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()

        let bar = try XCTUnwrap(flatDesignTabBar(in: controller.view), "the FlatDesign tab bar is installed")
        XCTAssertTrue((bar.value(forKey: "delegate") as AnyObject?) === controller, "the controller is the bar's delegate")
        XCTAssertEqual(bar.value(forKey: "cyl_isStandaloneTabBar") as? Bool, false, "the controller's own bar is not standalone")
        XCTAssertEqual(bar.value(forKey: "cyl_flatDesignHasPlusButton") as? Bool, true, "so it shows the registered plus button")
        window.isHidden = true
    }
}
