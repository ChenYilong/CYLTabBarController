//
//  HealthyHomeUITests.swift
//  HealthyHomeUITests
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import XCTest

class HealthyHomeUITests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    /**
     * [EN] Liquid Glass with a plus page: select the plus button, then drag the lens from it to "Health" and hold, then
     *      lift. Recorded from outside (`simctl io recordVideo`) to check that the plus button is never cut in two
     *      (docs/SwiftUI-Integration.md, task log). Screenshots are attached at each step.
     * [CN] 液态玻璃且 PlusButton 有页面：选中 PlusButton，再把放大镜从它拖到 "Health" 并按住，然后抬起。从外部录屏
     *      （`simctl io recordVideo`），检查 PlusButton 从不被切成两半（docs/SwiftUI-Integration.md 任务记录）。每一步附加截图。
     */
    func testDraggingTheLensAwayFromTheSelectedPlusButton() {
        let app = XCUIApplication()
        app.launch()
        let plus = app.buttons.matching(identifier: "plus").firstMatch
        XCTAssertTrue(plus.waitForExistence(timeout: 10))
        plus.tap()
        sleep(2)
        attach(app, "1 plus selected")
        let tabs = app.tabBars.firstMatch
        let menuTab = tabs.buttons.matching(NSPredicate(format: "label == %@", "Menu")).firstMatch
        let healthTab = tabs.buttons.matching(NSPredicate(format: "label == %@", "Health")).firstMatch
        XCTAssertTrue(healthTab.exists)
        let start = (menuTab.exists ? menuTab : plus).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let end = healthTab.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.6, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 3)
        sleep(2)
        attach(app, "2 after the drag")
    }

    /**
     * [EN] The same drag on a plus button whose whole icon lies inside the lens (the ObjC demo's gallery 9.4, plus tab
     *      selected at launch; the demo must be installed): the whole lens area is masked there, so a lens leaving it
     *      would show the cut most clearly. Drags from the plus slot to "Find" and holds, then lifts.
     * [CN] 对图标完全位于放大镜内的 PlusButton 做同样的拖动（ObjC 示例的图库 9.4，启动时选中 PlusButton；需要先安装该示例）：
     *      这种情况会遮住整个放大镜区域，放大镜离开时切割最明显。从 PlusButton 的位置拖到 "Find" 并按住，然后抬起。
     */
    func testDraggingTheLensAwayFromAFlatSelectedPlusButton() {
        let app = XCUIApplication(bundleIdentifier: "CYL.CYLTabBarController")
        app.launchArguments = ["-CYLDemoGalleryScene", "9.4"]
        app.launch()
        let tabs = app.tabBars.firstMatch
        let find = tabs.buttons.matching(NSPredicate(format: "label == %@", "Find")).firstMatch
        let favor = tabs.buttons.matching(NSPredicate(format: "label == %@", "Favor")).firstMatch
        XCTAssertTrue(find.waitForExistence(timeout: 15))
        XCTAssertTrue(favor.exists)
        sleep(3)
        attach(app, "1 flat plus selected")
        let origin = tabs.coordinate(withNormalizedOffset: .zero)
        let slot = CGPoint(x: (find.frame.midX + favor.frame.midX) / 2, y: find.frame.midY)
        let start = origin.withOffset(CGVector(dx: slot.x - tabs.frame.minX, dy: slot.y - tabs.frame.minY))
        let end = find.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.6, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 3)
        sleep(2)
        attach(app, "2 after the drag")
    }

    /**
     * [EN] The ObjC demo's main tab bar: a raised plus button with a title and `+alignsTitleWithTabBarItemTitles`, the only
     *      case the title-only lens mask applies to. Select it, drag the lens to "Nearby" and hold, then lift.
     * [CN] ObjC 示例的主 TabBar：带标题、实现了 `+alignsTitleWithTabBarItemTitles` 的凸起 PlusButton，是只遮标题的放大镜遮罩唯一
     *      生效的情况。选中它，把放大镜拖到 "Nearby" 并按住，然后抬起。
     */
    func testDraggingTheLensAwayFromTheDemoPlusButtonWithAlignedTitle() {
        let app = XCUIApplication(bundleIdentifier: "CYL.CYLTabBarController")
        app.launch()
        let plus = app.buttons.matching(identifier: "plus").firstMatch
        XCTAssertTrue(plus.waitForExistence(timeout: 15))
        sleep(3)
        plus.tap()
        sleep(2)
        attach(app, "1 plus selected")
        let tabs = app.tabBars.firstMatch
        let nearby = tabs.buttons.matching(NSPredicate(format: "label == %@", "Nearby")).firstMatch
        XCTAssertTrue(nearby.exists)
        let start = plus.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85))
        let end = nearby.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.6, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 3)
        sleep(2)
        attach(app, "2 after the drag")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testExample() {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testLaunchPerformance() {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTOSSignpostMetric.applicationLaunch]) {
                XCUIApplication().launch()
            }
        }
    }
}
