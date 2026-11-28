//
//  CYLSystemBarsTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import XCTest
import UIKit
import CYLTabBarController

/// [EN] A page with a fixed status bar style. [CN] 状态栏样式固定的页面。
private final class CYLStatusBarStylePage: UIViewController {
    private let style: UIStatusBarStyle

    init(style: UIStatusBarStyle) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { style }
}

/**
 [EN] The status bar follows the tab on screen (docs/Swift-Migration.md, step 129 and its follow-up). Before the first selection `selectedViewController`
      is nil and `selectedIndex` is -1 while the first tab is shown, so the first tab decides, not the last one.
 [CN] 状态栏跟随屏幕上显示的 Tab（docs/Swift-Migration.md 第 129 步及其后续）。首次选中之前 `selectedViewController` 为 nil、`selectedIndex` 为 -1，
      而此时显示的是第一个 Tab，因此由第一个 Tab 决定，而不是最后一个。
 */
@MainActor
final class CYLSystemBarsTests: XCTestCase {

    private func makeTabBarController() -> (CYLTabBarController, [CYLStatusBarStylePage]) {
        let pages = [CYLStatusBarStylePage(style: .darkContent), CYLStatusBarStylePage(style: .lightContent)]
        let controller = CYLTabBarController(viewControllers: pages,
                                             tabBarItemsAttributes: [[CYLTabBarItemTitle: "First"], [CYLTabBarItemTitle: "Second"]])
        // [EN] The view is not loaded: loading it selects the first tab, and the bug is the state before that.
        // [CN] 不加载视图：加载视图会选中第一个 Tab，而该缺陷出现在此之前的状态。
        return (controller, pages)
    }

    func testStatusBarChildAtLaunchIsTheFirstTab() {
        let (controller, pages) = makeTabBarController()
        XCTAssertNil(controller.selectedViewController, "no tab was selected yet")
        XCTAssertTrue(controller.childForStatusBarStyle === pages[0], "the first tab is on screen, not the last one")
        XCTAssertEqual(controller.childForStatusBarStyle?.preferredStatusBarStyle, .darkContent)
        XCTAssertTrue(controller.childForStatusBarHidden === pages[0])
        XCTAssertTrue(controller.childForHomeIndicatorAutoHidden === pages[0])
        XCTAssertTrue(controller.childForScreenEdgesDeferringSystemGestures === pages[0])
    }

    func testStatusBarChildFollowsTheSelectedTab() {
        let (controller, pages) = makeTabBarController()
        controller.selectedViewController = pages[1]
        XCTAssertTrue(controller.childForStatusBarStyle === pages[1])
        XCTAssertEqual(controller.childForStatusBarStyle?.preferredStatusBarStyle, .lightContent)
    }
}
