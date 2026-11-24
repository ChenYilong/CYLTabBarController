//
//  CYLTabBarControllerDeallocTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import XCTest
import UIKit
import CYLTabBarController
import CYLDeallocBlockExecutor

/**
 [EN] The teardown of the library lifecycle (docs/Lifecycle-Library.md, step 21): a `CYLTabBarController` that is released runs
      the dealloc callbacks registered on it through CYLDeallocBlockExecutor, so a core that holds nothing keeps the
      controller from leaking. The example's "Release the tab bar controller" row does the same on a real window.
 [CN] 库生命周期的销毁（docs/Lifecycle-Library.md，第 21 步）：被释放的 `CYLTabBarController` 会执行通过 CYLDeallocBlockExecutor
      登记在其上的 dealloc 回调，因此核心不持有任何东西，控制器不会泄漏。示例中的「释放 TabBarController」行在真实窗口上做同样的事。
 */
@MainActor
final class CYLTabBarControllerDeallocTests: XCTestCase {

    private func makeTabBarController() -> CYLTabBarController {
        let pages = [UINavigationController(rootViewController: UIViewController()),
                     UINavigationController(rootViewController: UIViewController())]
        let controller = CYLTabBarController(viewControllers: pages,
                                             tabBarItemsAttributes: [[CYLTabBarItemTitle: "First"], [CYLTabBarItemTitle: "Second"]])
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.layoutIfNeeded()
        return controller
    }

    func testReleasingTheTabBarControllerRunsItsDeallocCallbackOnce() {
        var runs = 0
        weak var released: CYLTabBarController?
        autoreleasepool {
            let controller = makeTabBarController()
            released = controller
            _ = controller.cylWillDealloc(key: "cyl.test.teardown") { _, _, _ in runs += 1 }
            XCTAssertEqual(runs, 0, "alive: the callback has not run")
        }
        XCTAssertNil(released, "the controller is released: the core keeps no strong reference to it")
        XCTAssertEqual(runs, 1, "the dealloc callback ran once")
    }

    func testACancelledDeallocCallbackDoesNotRun() {
        var runs = 0
        autoreleasepool {
            let controller = makeTabBarController()
            _ = controller.cylWillDealloc(key: "cyl.test.teardown") { _, _, _ in runs += 1 }
            XCTAssertTrue(controller.cylCancelDeallocCallback(key: "cyl.test.teardown"))
        }
        XCTAssertEqual(runs, 0)
    }
}
