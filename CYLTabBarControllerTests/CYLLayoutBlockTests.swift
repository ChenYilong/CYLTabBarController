//
//  CYLLayoutBlockTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import XCTest
import UIKit
import CYLTabBarController

/**
 [EN] The one-time layout block, now kept by CYLDeallocBlockExecutor under the key `cyl.core.layoutBlock`
      (docs/Lifecycle-Library.md): once per arm, again after the re-arm, and the re-arm leaves other blocks alone.
 [CN] 只执行一次的布局 block，现在由 CYLDeallocBlockExecutor 以 key `cyl.core.layoutBlock` 保存（docs/Lifecycle-Library.md）：
      每次启用执行一次，重新启用后再执行，重新启用不影响其他 block。
 */
final class CYLLayoutBlockTests: XCTestCase {

    private func makeTabBarController() -> CYLTabBarController {
        let pages = [UINavigationController(rootViewController: UIViewController()),
                     UINavigationController(rootViewController: UIViewController())]
        let controller = CYLTabBarController(viewControllers: pages,
                                             tabBarItemsAttributes: [[CYLTabBarItemTitle: "First"], [CYLTabBarItemTitle: "Second"]])
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        return controller
    }

    private func layOut(_ controller: CYLTabBarController) {
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
    }

    private func rearm(_ controller: CYLTabBarController) {
        controller.perform(NSSelectorFromString("cyl_rearmViewDidLayoutSubviewsBlockInvokeOnce"))
    }

    func testOnceBlockRunsOncePerArm() {
        let controller = makeTabBarController()
        var runs = 0
        controller.setViewDidLayoutSubViewsBlockInvokeOnce(true) { _ in runs += 1 }
        layOut(controller)
        XCTAssertEqual(runs, 1)
        layOut(controller)
        XCTAssertEqual(runs, 1, "a second layout must not run the block again")
        rearm(controller)
        layOut(controller)
        XCTAssertEqual(runs, 2, "the re-arm lets it run once more")
    }

    func testBlockWithoutOnceRunsEveryLayout() {
        let controller = makeTabBarController()
        var runs = 0
        controller.viewDidLayoutSubviewsBlock = { _ in runs += 1 }
        layOut(controller)
        layOut(controller)
        XCTAssertGreaterThanOrEqual(runs, 2)
    }

    func testBlockReceivesTheController() {
        let controller = makeTabBarController()
        var received: CYLTabBarController?
        controller.setViewDidLayoutSubViewsBlockInvokeOnce(true) { received = $0 }
        layOut(controller)
        XCTAssertTrue(received === controller)
    }

    // MARK: - The tab bar's and the items' layout blocks (CYLDeallocBlockExecutor, keyed `.end` blocks)

    func testTabBarDidLayoutBlockRunsAfterEachLayoutAndNilRemovesIt() {
        let controller = makeTabBarController()
        guard let tabBar = controller.cyl_tabBar as? CYLTabBar else { return XCTFail("no tab bar") }
        var runs = 0
        tabBar.didLayoutSubViewsBlock = { _ in runs += 1 }
        layOut(controller)
        tabBar.setNeedsLayout()
        tabBar.layoutIfNeeded()
        XCTAssertGreaterThanOrEqual(runs, 1)
        let before = runs
        tabBar.didLayoutSubViewsBlock = nil
        tabBar.setNeedsLayout()
        tabBar.layoutIfNeeded()
        XCTAssertEqual(runs, before, "setting nil removes the block")
    }

    func testSettingTheTabBarBlockAgainReplacesTheFirst() {
        let controller = makeTabBarController()
        guard let tabBar = controller.cyl_tabBar as? CYLTabBar else { return XCTFail("no tab bar") }
        var first = 0
        var second = 0
        tabBar.didLayoutSubViewsBlock = { _ in first += 1 }
        tabBar.didLayoutSubViewsBlock = { _ in second += 1 }
        layOut(controller)
        tabBar.setNeedsLayout()
        tabBar.layoutIfNeeded()
        XCTAssertEqual(first, 0)
        XCTAssertGreaterThanOrEqual(second, 1)
    }

    func testItemLayoutBlockReceivesItsItemAndButton() {
        let controller = makeTabBarController()
        layOut(controller)
        guard let item = (controller.cyl_tabBar as? UITabBar)?.items?.first else { return XCTFail("no item") }
        var received: (UITabBarItem, UIView)?
        item.cyl_viewDidLayoutSubviewsBlock = { item, view in received = (item, view) }
        controller.cyl_tabBar?.setNeedsLayout()
        controller.cyl_tabBar?.layoutIfNeeded()
        XCTAssertTrue(received?.0 === item)
        item.cyl_viewDidLayoutSubviewsBlock = nil
        received = nil
        controller.cyl_tabBar?.setNeedsLayout()
        controller.cyl_tabBar?.layoutIfNeeded()
        XCTAssertNil(received, "setting nil removes the block")
    }
}
