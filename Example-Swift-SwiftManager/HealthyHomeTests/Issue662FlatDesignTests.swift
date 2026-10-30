import UIKit
import XCTest
import CYLTabBarController

/// Integration coverage for #662. The host app supplies a real UIWindowScene;
/// the bottom marker makes the safe-area assertion exercise Auto Layout as well.
@MainActor
final class Issue662FlatDesignTests: XCTestCase {
    private let accuracy: CGFloat = 0.5

    func testDefaultHeightAtLaunchAndAfterPushPop() throws {
        try exerciseFlatDesign(height: nil)
    }

    func testCustomHeightAtLaunchAndAfterPushPop() throws {
        try exerciseFlatDesign(height: 60)
    }

    func testSecondTabSelectedBeforeWindowIsShown() throws {
        let fixture = try Fixture(height: nil, selectedIndexBeforeDisplay: 1)
        defer { fixture.close() }
        let secondNavigation = try XCTUnwrap(fixture.secondNavigation)
        XCTAssertTrue(fixture.selectedBeforeDisplay === secondNavigation,
                      "The second tab must be selected before the controller is attached to the window")
        settle(fixture)
        XCTAssertTrue(fixture.controller.selectedViewController === secondNavigation)
        XCTAssertEqual(fixture.controller.tabBarHeight, 49, accuracy: accuracy)
        assertVisible(fixture, page: fixture.secondPage, phase: "preselected-second-tab", height: 49)
    }

    func testLaunchAndTabSwitchWithoutNavigation() throws {
        let fixture = try Fixture(height: nil)
        defer { fixture.close() }
        // Let UIKit lay out the newly visible window naturally; do not force a
        // layout before checking the initial result.
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.4))
        assertVisible(fixture, page: fixture.firstPage, phase: "natural-launch", height: 49)
        fixture.controller.selectedIndex = 1
        settle(fixture)
        assertVisible(fixture, page: fixture.secondPage, phase: "switch-second", height: 49)
        fixture.controller.selectedIndex = 0
        settle(fixture)
        assertVisible(fixture, page: fixture.firstPage, phase: "switch-first", height: 49)
    }

    func testChangingHeightAfterLaunchRelayoutsTheSafeArea() throws {
        let fixture = try Fixture(height: nil)
        defer { fixture.close() }
        settle(fixture)
        XCTAssertEqual(fixture.controller.tabBarHeight, 49, accuracy: accuracy)
        assertVisible(fixture, page: fixture.firstPage, phase: "height-initial-49", height: 49)

        for height in [CGFloat(60), CGFloat(49)] {
            fixture.controller.tabBarHeight = height
            settle(fixture)
            XCTAssertEqual(fixture.controller.tabBarHeight, height, accuracy: accuracy)
            assertVisible(fixture, page: fixture.firstPage, phase: "height-changed-\(Int(height))", height: height)
        }
    }

    func testUnrelatedLayoutsPreserveBusinessNavigationAdditionalInset() throws {
        let fixture = try Fixture(height: nil)
        defer { fixture.close() }
        let navigation = try XCTUnwrap(fixture.firstNavigation)
        settle(fixture)
        XCTAssertTrue(fixture.window.isKeyWindow)
        XCTAssertTrue(fixture.controller.selectedViewController === navigation)
        XCTAssertTrue(navigation.view.window === fixture.window)

        var businessInsets = navigation.additionalSafeAreaInsets
        businessInsets.bottom = 20
        navigation.additionalSafeAreaInsets = businessInsets
        XCTAssertEqual(navigation.additionalSafeAreaInsets.bottom, 20, accuracy: 0.001)

        // This is an absolute business override, not a request to change the bar.
        // Repeated unrelated layout passes must not replace it with CYL's inset.
        for pass in 1...3 {
            fixture.controller.view.setNeedsLayout()
            navigation.view.setNeedsLayout()
            fixture.controller.view.layoutIfNeeded()
            navigation.view.layoutIfNeeded()
            settle(fixture)
            logLayout(fixture, page: fixture.firstPage, phase: "business-inset-layout-\(pass)")
            XCTAssertEqual(navigation.additionalSafeAreaInsets.bottom, 20, accuracy: 0.001,
                           "Layout pass \(pass) overwrote the business-set navigation inset")
        }
    }

    func testExplicitlyHidingAndRestoringTheCustomTabBar() throws {
        let fixture = try Fixture(height: nil)
        defer { fixture.close() }
        settle(fixture)
        assertVisible(fixture, page: fixture.firstPage, phase: "before-explicit-hide", height: 49)

        fixture.controller.setTabBarHidden(true, animated: false)
        settle(fixture)
        XCTAssertTrue(fixture.controller.isTabBarHidden)
        assertHidden(fixture, page: fixture.firstPage, phase: "explicitly-hidden")

        fixture.controller.setTabBarHidden(false, animated: false)
        settle(fixture)
        XCTAssertFalse(fixture.controller.isTabBarHidden)
        assertVisible(fixture, page: fixture.firstPage, phase: "explicitly-restored", height: 49)
    }

    func testInitiallyHiddenBarKeepsItsIntentAfterFirstLayout() throws {
        for animated in [false, true] {
            let fixture = try Fixture(height: nil, hideBeforeDisplayAnimated: animated)
            XCTAssertTrue(fixture.controller.isTabBarHidden)
            settle(fixture, animation: animated)
            XCTAssertTrue(fixture.controller.isTabBarHidden)
            assertHidden(fixture, page: fixture.firstPage, phase: "initially-hidden-\(animated)")
            fixture.controller.setTabBarHidden(false, animated: false)
            settle(fixture)
            assertVisible(fixture, page: fixture.firstPage, phase: "initially-hidden-restored-\(animated)", height: 49)
            fixture.close()
        }
    }

    func testHideRequestedWhileTabBarIsInAnOverlaySurvivesSelection() throws {
        let fixture = try Fixture(height: nil)
        defer { fixture.close() }
        let firstNavigation = try XCTUnwrap(fixture.firstNavigation)
        let secondNavigation = try XCTUnwrap(fixture.secondNavigation)
        settle(fixture)
        XCTAssertFalse(fixture.controller.isTabBarHidden)
        assertVisible(fixture, page: fixture.firstPage, phase: "before-overlay-hide", height: 49)

        let bar = fixture.controller.cyl_tabBar
        let originalSuperview = try XCTUnwrap(bar.superview)
        XCTAssertTrue(originalSuperview === fixture.controller.view)
        guard originalSuperview === fixture.controller.view else { return }
        let originalIndex = try XCTUnwrap(originalSuperview.subviews.firstIndex { $0 === bar })
        let originalFrame = bar.frame
        // A navigation transition temporarily reparents the bar into an overlay
        // in the selected page. Reproduce that hierarchy without timing a push.
        let overlay = UIView(frame: fixture.firstPage.view.bounds)
        fixture.firstPage.view.addSubview(overlay)
        let frameInOverlay = originalSuperview.convert(originalFrame, to: overlay)
        UIView.performWithoutAnimation {
            overlay.addSubview(bar)
            bar.frame = frameInOverlay
        }
        XCTAssertTrue(bar.superview === overlay)

        fixture.controller.setTabBarHidden(true, animated: false)
        XCTAssertTrue(bar.superview === overlay, "The request must occur while the bar is in the overlay")
        XCTAssertTrue(fixture.controller.isTabBarHidden,
                      "The getter must record the hide request even while the bar is reparented")

        UIView.performWithoutAnimation {
            originalSuperview.insertSubview(bar, at: min(originalIndex, originalSuperview.subviews.count))
            bar.frame = originalFrame
            overlay.removeFromSuperview()
        }
        XCTAssertTrue(bar.superview === fixture.controller.view)
        fixture.controller.selectedIndex = 1
        settle(fixture)
        XCTAssertTrue(fixture.controller.selectedViewController === secondNavigation)
        XCTAssertTrue(fixture.controller.isTabBarHidden)
        XCTAssertEqual(secondNavigation.additionalSafeAreaInsets.bottom, 0, accuracy: accuracy)
        assertHidden(fixture, page: fixture.secondPage, phase: "overlay-hide-second-tab")

        fixture.controller.selectedIndex = 0
        settle(fixture)
        XCTAssertTrue(fixture.controller.selectedViewController === firstNavigation)
        XCTAssertTrue(fixture.controller.isTabBarHidden)
        assertHidden(fixture, page: fixture.firstPage, phase: "overlay-hide-first-tab")
    }

    func testShowRequestDuringAnimatedHideWinsImmediatelyAndAfterCompletion() throws {
        let fixture = try Fixture(height: nil)
        defer { fixture.close() }
        let navigation = try XCTUnwrap(fixture.firstNavigation)
        settle(fixture)
        assertVisible(fixture, page: fixture.firstPage, phase: "before-interrupted-hide", height: 49)

        let animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(true)
        defer { UIView.setAnimationsEnabled(animationsWereEnabled) }
        let delegate = TabBarVisibilitySpy()
        fixture.controller.delegate = delegate
        defer { fixture.controller.delegate = nil }

        fixture.controller.setTabBarHidden(true, animated: true)
        XCTAssertTrue(fixture.controller.isTabBarHidden, "The animated hide must update the requested state immediately")
        XCTAssertEqual(delegate.willHideCount, 1)
        XCTAssertEqual(delegate.didHideCount, 0, "The second request must precede hide animation completion")
        // Do not advance the run loop between the two requests.
        fixture.controller.setTabBarHidden(false, animated: false)
        XCTAssertFalse(fixture.controller.isTabBarHidden, "The newest show request must be observable immediately")

        settle(fixture, animation: true)
        XCTAssertFalse(fixture.controller.isTabBarHidden)
        XCTAssertEqual(navigation.additionalSafeAreaInsets.bottom, fixture.controller.tabBarHeight, accuracy: accuracy)
        assertVisible(fixture, page: fixture.firstPage, phase: "show-after-interrupted-hide", height: 49)
    }

    func testQueuedRequestRetainsItsOwnAnimationChoice() throws {
        let fixture = try Fixture(height: nil, recordVisibilityRequests: true)
        defer { fixture.close() }
        let controller = try XCTUnwrap(fixture.controller as? VisibilityRecordingTabBarController)
        settle(fixture)
        controller.recordedRequests.removeAll()
        controller.setTabBarHidden(true, animated: true)
        controller.setTabBarHidden(false, animated: false)
        settle(fixture, animation: true)
        XCTAssertGreaterThanOrEqual(controller.recordedRequests.count, 3)
        XCTAssertEqual(controller.recordedRequests.last?.hidden, false)
        XCTAssertEqual(controller.recordedRequests.last?.animated, false,
                       "The queued request must keep its own animated argument")
        assertVisible(fixture, page: fixture.firstPage, phase: "queued-nonanimated-show", height: 49)
    }

    func testHidesBottomBarWhenPushedOverridesShowButPreservesExplicitHideOnPop() throws {
        let fixture = try Fixture(height: nil)
        defer { fixture.close() }
        let navigation = try XCTUnwrap(fixture.firstNavigation)
        settle(fixture)
        XCTAssertFalse(fixture.controller.isTabBarHidden)
        assertVisible(fixture, page: fixture.firstPage, phase: "before-priority-push", height: 49)

        let pushedPage = Page()
        pushedPage.hidesBottomBarWhenPushed = true
        navigation.pushViewController(pushedPage, animated: true)
        settle(fixture, animation: true)
        XCTAssertTrue(navigation.topViewController === pushedPage)
        XCTAssertFalse(fixture.controller.isTabBarHidden, "Navigation hiding must not replace the explicit intent")
        assertHidden(fixture, page: pushedPage, phase: "priority-push")

        // Change the explicit state in both directions while the page requires
        // a hidden bar: the show request must not override navigation priority.
        fixture.controller.setTabBarHidden(true, animated: false)
        XCTAssertTrue(fixture.controller.isTabBarHidden)
        fixture.controller.setTabBarHidden(false, animated: false)
        XCTAssertFalse(fixture.controller.isTabBarHidden)
        settle(fixture)
        XCTAssertEqual(navigation.additionalSafeAreaInsets.bottom, 0, accuracy: accuracy)
        assertHidden(fixture, page: pushedPage, phase: "priority-over-explicit-show")

        fixture.controller.setTabBarHidden(true, animated: false)
        XCTAssertTrue(fixture.controller.isTabBarHidden)
        navigation.popViewController(animated: true)
        settle(fixture, animation: true)
        XCTAssertTrue(navigation.topViewController === fixture.firstPage)
        XCTAssertTrue(fixture.controller.isTabBarHidden, "Popping must retain the explicit hide request")
        XCTAssertEqual(navigation.additionalSafeAreaInsets.bottom, 0, accuracy: accuracy)
        assertHidden(fixture, page: fixture.firstPage, phase: "explicit-hide-after-priority-pop")

        fixture.controller.setTabBarHidden(false, animated: false)
        settle(fixture)
        XCTAssertFalse(fixture.controller.isTabBarHidden)
        XCTAssertEqual(navigation.additionalSafeAreaInsets.bottom, fixture.controller.tabBarHeight, accuracy: accuracy)
        assertVisible(fixture, page: fixture.firstPage, phase: "show-after-priority-pop", height: 49)
    }

    func testMoreNavigationIsDetectedBeforeSelectingSixthTab() throws {
        let fixture = try Fixture(height: nil)
        defer { fixture.close() }
        let icon = try XCTUnwrap(UIImage(systemName: "circle"))
        let pages = (0..<6).map { _ in UINavigationController(rootViewController: Page()) }
        let attributes: [[String: Any]] = (0..<6).map { index in
            [CYLTabBarItemTitle: "Tab \(index)", CYLTabBarItemImage: icon, CYLTabBarItemSelectedImage: icon]
        }
        let controller = CYLTabBarController(viewControllers: pages, tabBarItemsAttributes: attributes,
                                             styleType: .flatDesign, context: "Issue662More-\(UUID().uuidString)")
        fixture.window.rootViewController = controller
        fixture.window.makeKeyAndVisible()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.4))
        fixture.window.layoutIfNeeded()
        let systemItems = try XCTUnwrap(controller.tabBar.items)
        let more = controller.moreNavigationController
        guard systemItems.contains(where: { $0 === more.tabBarItem }) else {
            throw XCTSkip("UIKit did not create a More item for this simulator configuration")
        }
        // Check the private decision before selecting index 5: on the broken
        // path it would index the five visible flat items with the value 5.
        let detected = (controller.value(forKey: "_showsMoreNavigationController") as? NSNumber)?.boolValue ?? false
        XCTAssertTrue(detected, "FlatDesign must detect UIKit's actual More item")
        guard detected else { return }
        var moreInsets = more.additionalSafeAreaInsets
        moreInsets.top = 7
        moreInsets.left = 3
        more.additionalSafeAreaInsets = moreInsets
        controller.selectedIndex = 5
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.4))
        fixture.window.layoutIfNeeded()
        XCTAssertEqual(controller.selectedIndex, 5)
        XCTAssertFalse(controller.cyl_tabBar.isHidden)
        XCTAssertEqual(more.additionalSafeAreaInsets.bottom, controller.tabBarHeight, accuracy: accuracy)
        XCTAssertEqual(more.additionalSafeAreaInsets.top, 7, accuracy: accuracy)
        XCTAssertEqual(more.additionalSafeAreaInsets.left, 3, accuracy: accuracy)
    }

    func testWillHideDelegateCanReenterWithShow() throws {
        let fixture = try Fixture(height: nil)
        defer { fixture.close() }
        let navigation = try XCTUnwrap(fixture.firstNavigation)
        settle(fixture)
        assertVisible(fixture, page: fixture.firstPage, phase: "before-reentrant-show", height: 49)

        let delegate = TabBarVisibilitySpy(requestShowOnWillHide: true)
        fixture.controller.delegate = delegate
        defer { fixture.controller.delegate = nil }
        fixture.controller.setTabBarHidden(true, animated: false)
        XCTAssertEqual(delegate.willHideCount, 1)
        XCTAssertEqual(delegate.hiddenAfterReentrantShow, false, "The reentrant request must update the getter")
        XCTAssertFalse(fixture.controller.isTabBarHidden)

        settle(fixture, animation: true)
        XCTAssertEqual(delegate.willHideCount, 1, "A reentrant show must not cause repeated hide callbacks")
        XCTAssertFalse(fixture.controller.isTabBarHidden)
        XCTAssertEqual(navigation.additionalSafeAreaInsets.bottom, fixture.controller.tabBarHeight, accuracy: accuracy)
        assertVisible(fixture, page: fixture.firstPage, phase: "after-reentrant-show", height: 49)
    }

    func testDirectViewControllerChildrenAtLaunchAndAfterSelection() throws {
        let fixture = try Fixture(height: nil, directChildren: true)
        defer { fixture.close() }
        let children = try XCTUnwrap(fixture.controller.viewControllers)
        XCTAssertEqual(children.count, 2)
        guard children.count == 2 else { return }
        XCTAssertTrue(children.allSatisfy { !($0 is UINavigationController) })
        XCTAssertTrue(children[0] === fixture.firstPage)
        XCTAssertTrue(children[1] === fixture.secondPage)
        settle(fixture)
        XCTAssertTrue(fixture.controller.selectedViewController === fixture.firstPage)
        assertVisible(fixture, page: fixture.firstPage, phase: "direct-child-launch", height: 49)

        fixture.controller.selectedIndex = 1
        settle(fixture)
        XCTAssertTrue(fixture.controller.selectedViewController === fixture.secondPage)
        assertVisible(fixture, page: fixture.secondPage, phase: "direct-child-second-tab", height: 49)
    }

    func testDirectChildKeepsItsAdditionalBottomInset() throws {
        let fixture = try Fixture(height: nil, directChildren: true, firstPageAdditionalBottom: 20)
        defer { fixture.close() }
        settle(fixture)
        XCTAssertTrue(fixture.controller.selectedViewController === fixture.firstPage)
        // Pre-existing limitation, also reproduced on iOS 27.0 before this fix:
        // the framework overwrites the selected controller's original bottom inset.
        let bar = fixture.controller.cyl_tabBar
        let barTop = bar.convert(CGPoint(x: 0, y: bar.bounds.minY), to: fixture.window).y
        let safeBottom = fixture.firstPage.view.convert(
            CGPoint(x: 0, y: fixture.firstPage.view.safeAreaLayoutGuide.layoutFrame.maxY), to: fixture.window).y
        let markerBottom = fixture.firstPage.marker.convert(
            CGPoint(x: 0, y: fixture.firstPage.marker.bounds.maxY), to: fixture.window).y
        XCTAssertFalse(bar.isHidden)
        XCTAssertEqual(markerBottom, safeBottom, accuracy: accuracy)
        XCTExpectFailure("Pre-existing selected-controller additionalSafeAreaInsets overwrite; not addressed by #662") {
            XCTAssertEqual(safeBottom, barTop - 20, accuracy: accuracy)
        }
    }

    func testLeafAdditionalBottomIsPreservedAcrossPushAndPop() throws {
        let fixture = try Fixture(height: nil, firstPageAdditionalBottom: 20)
        defer { fixture.close() }
        let navigation = try XCTUnwrap(fixture.firstNavigation)
        settle(fixture)
        XCTAssertEqual(fixture.firstPage.additionalSafeAreaInsets.bottom, 20, accuracy: accuracy)
        assertVisible(fixture, page: fixture.firstPage, phase: "leaf-additional-launch", height: 49, extraBottom: 20)

        let pushedPage = Page()
        pushedPage.additionalSafeAreaInsets.bottom = 20
        navigation.pushViewController(pushedPage, animated: true)
        settle(fixture, animation: true)
        XCTAssertTrue(navigation.topViewController === pushedPage)
        XCTAssertEqual(pushedPage.additionalSafeAreaInsets.bottom, 20, accuracy: accuracy)
        assertVisible(fixture, page: pushedPage, phase: "leaf-additional-push", height: 49, extraBottom: 20)

        navigation.popViewController(animated: true)
        settle(fixture, animation: true)
        XCTAssertTrue(navigation.topViewController === fixture.firstPage)
        XCTAssertEqual(fixture.firstPage.additionalSafeAreaInsets.bottom, 20, accuracy: accuracy)
        assertVisible(fixture, page: fixture.firstPage, phase: "leaf-additional-pop", height: 49, extraBottom: 20)
    }

    func testFailedSystemTabBarReplacementAtLaunch() throws {
        let fixture = try Fixture(height: nil, rejectSystemTabBarReplacement: true)
        defer { fixture.close() }
        let controller = try XCTUnwrap(fixture.controller as? KVCRejectingTabBarController)
        XCTAssertGreaterThan(controller.rejectedTabBarAssignments, 0,
                             "The test must actually reject a tabBar KVC replacement")
        let rejectedBar = try XCTUnwrap(controller.rejectedTabBar, "No replacement tab bar was rejected")
        XCTAssertFalse(rejectedBar === controller.tabBar,
                       "The rejected replacement must not be the actual system tab bar")
        print("[Issue662InjectedKVC] rejected=\(controller.rejectedTabBarAssignments) " +
              "replacementClass=\(type(of: rejectedBar)) actualSystemClass=\(type(of: controller.tabBar)) " +
              "replacementInstalled=\(rejectedBar === controller.tabBar)")
        settle(fixture)
        XCTAssertTrue(controller.tabBar.isHidden,
                      "FlatDesign must not leave the system tab bar visible when KVC replacement fails")
        assertVisible(fixture, page: fixture.firstPage, phase: "injected-kvc-failure", height: 49)
        let navigation = try XCTUnwrap(fixture.firstNavigation)
        let pushedPage = Page()
        pushedPage.hidesBottomBarWhenPushed = true
        navigation.pushViewController(pushedPage, animated: false)
        settle(fixture)
        assertHidden(fixture, page: pushedPage, phase: "injected-kvc-push")
        navigation.popViewController(animated: false)
        settle(fixture)
        XCTAssertTrue(controller.tabBar.isHidden, "UIKit must not leave the original system bar visible after pop")
        assertVisible(fixture, page: fixture.firstPage, phase: "injected-kvc-pop", height: 49)
    }

    private func exerciseFlatDesign(height: CGFloat?) throws {
        let fixture = try Fixture(height: height)
        defer { fixture.close() }
        let firstNavigation = try XCTUnwrap(fixture.firstNavigation)
        let secondNavigation = try XCTUnwrap(fixture.secondNavigation)

        let expectedHeight = height ?? 49
        settle(fixture)
        XCTAssertTrue(fixture.window.isKeyWindow)
        XCTAssertTrue(fixture.window.windowScene === fixture.scene)
        XCTAssertEqual(fixture.controller.viewControllers?.count, 2)
        XCTAssertEqual(fixture.controller.tabBarHeight, expectedHeight, accuracy: accuracy)
        assertVisible(fixture, page: fixture.firstPage, phase: "launch", height: expectedHeight)

        // Test a push that keeps the bar and one that hides it, followed by both pops.
        let visiblePage = Page()
        firstNavigation.pushViewController(visiblePage, animated: true)
        settle(fixture, animation: true)
        XCTAssertTrue(firstNavigation.topViewController === visiblePage)
        assertVisible(fixture, page: visiblePage, phase: "push-visible", height: expectedHeight)

        let hiddenPage = Page()
        hiddenPage.hidesBottomBarWhenPushed = true
        firstNavigation.pushViewController(hiddenPage, animated: true)
        settle(fixture, animation: true)
        XCTAssertTrue(firstNavigation.topViewController === hiddenPage)
        assertHidden(fixture, page: hiddenPage, phase: "push-hidden")

        firstNavigation.popViewController(animated: true)
        settle(fixture, animation: true)
        XCTAssertTrue(firstNavigation.topViewController === visiblePage)
        assertVisible(fixture, page: visiblePage, phase: "pop-visible", height: expectedHeight)

        firstNavigation.popViewController(animated: true)
        settle(fixture, animation: true)
        XCTAssertTrue(firstNavigation.topViewController === fixture.firstPage)
        assertVisible(fixture, page: fixture.firstPage, phase: "pop-root", height: expectedHeight)

        fixture.controller.selectedIndex = 1
        settle(fixture)
        XCTAssertTrue(fixture.controller.selectedViewController === secondNavigation)
        assertVisible(fixture, page: fixture.secondPage, phase: "second-tab", height: expectedHeight)
    }

    private func assertVisible(_ fixture: Fixture, page: Page, phase: String, height: CGFloat, extraBottom: CGFloat = 0,
                               file: StaticString = #filePath, line: UInt = #line) {
        logLayout(fixture, page: page, phase: phase)
        let bar = fixture.controller.cyl_tabBar
        let barTop = bar.convert(CGPoint(x: 0, y: bar.bounds.minY), to: fixture.window).y
        let safeBottom = page.view.convert(CGPoint(x: 0, y: page.view.safeAreaLayoutGuide.layoutFrame.maxY),
                                           to: fixture.window).y
        let markerBottom = page.marker.convert(CGPoint(x: 0, y: page.marker.bounds.maxY), to: fixture.window).y
        let expectedBottom = barTop - extraBottom
        XCTAssertTrue(page.view.window === fixture.window, "\(phase): page is not in the test window", file: file, line: line)
        XCTAssertFalse(bar.isHidden, "\(phase): custom bar should be visible", file: file, line: line)
        XCTAssertEqual(bar.bounds.height, height + fixture.controller.view.safeAreaInsets.bottom,
                       accuracy: accuracy, "\(phase): custom bar height", file: file, line: line)
        XCTAssertEqual(safeBottom, expectedBottom, accuracy: accuracy,
                       "\(phase): page safe-area bottom must be \(extraBottom)pt above the custom bar top in window coordinates", file: file, line: line)
        XCTAssertEqual(markerBottom, expectedBottom, accuracy: accuracy,
                       "\(phase): Auto Layout marker must follow the page safe-area bottom", file: file, line: line)
    }

    private func assertHidden(_ fixture: Fixture, page: Page, phase: String,
                              file: StaticString = #filePath, line: UInt = #line) {
        logLayout(fixture, page: page, phase: phase)
        let safeBottom = page.view.convert(CGPoint(x: 0, y: page.view.safeAreaLayoutGuide.layoutFrame.maxY),
                                           to: fixture.window).y
        let markerBottom = page.marker.convert(CGPoint(x: 0, y: page.marker.bounds.maxY), to: fixture.window).y
        let windowSafeBottom = fixture.window.safeAreaLayoutGuide.layoutFrame.maxY
        XCTAssertTrue(page.view.window === fixture.window, "\(phase): page is not in the test window", file: file, line: line)
        XCTAssertTrue(fixture.controller.cyl_tabBar.isHidden, "\(phase): custom bar should be hidden", file: file, line: line)
        XCTAssertEqual(safeBottom, windowSafeBottom, accuracy: accuracy,
                       "\(phase): page should extend to the window safe-area bottom", file: file, line: line)
        XCTAssertEqual(markerBottom, windowSafeBottom, accuracy: accuracy,
                       "\(phase): Auto Layout marker should reach the window safe-area bottom", file: file, line: line)
    }

    private func settle(_ fixture: Fixture, animation: Bool = false) {
        // Give the scene and, when requested, the real UIKit navigation animation
        // time to complete before sampling their final geometry.
        RunLoop.main.run(until: Date(timeIntervalSinceNow: animation ? 1.0 : 0.2))
        fixture.window.setNeedsLayout()
        fixture.window.layoutIfNeeded()
        fixture.controller.view.layoutIfNeeded()
        fixture.controller.selectedViewController?.view.layoutIfNeeded()
        (fixture.controller.selectedViewController as? UINavigationController)?.topViewController?.view.layoutIfNeeded()
        fixture.window.layoutIfNeeded()
        XCTAssertNil(fixture.firstNavigation?.transitionCoordinator, "navigation transition did not finish")
    }

    private func logLayout(_ fixture: Fixture, page: Page, phase: String) {
        let controller = fixture.controller
        let navigation = controller.selectedViewController as? UINavigationController
        let bar = controller.cyl_tabBar
        let barFrame = bar.convert(bar.bounds, to: fixture.window)
        let pageFrame = page.view.convert(page.view.bounds, to: fixture.window)
        let safeBottom = page.view.convert(CGPoint(x: 0, y: page.view.safeAreaLayoutGuide.layoutFrame.maxY),
                                           to: fixture.window).y
        let contentGuide: String
        if #available(iOS 26.0, *) {
            let frame = controller.contentLayoutGuide.layoutFrame
            contentGuide = "\(describe(frame)) window=\(describe(controller.view.convert(frame, to: fixture.window)))"
        } else {
            contentGuide = "unavailable"
        }
        let fields = [
            "[Issue662] phase=\(phase)",
            "os=\(UIDevice.current.systemVersion)",
            "height=\(controller.tabBarHeight)",
            "window=\(describe(fixture.window.bounds))",
            "windowSafe=\(describe(fixture.window.safeAreaInsets))",
            "contentLayoutGuide=\(contentGuide)",
            "controllerSafe=\(describe(controller.view.safeAreaInsets))",
            "navigationSafe=\(navigation.map { describe($0.view.safeAreaInsets) } ?? "nil")",
            "navigationAdditional=\(navigation.map { describe($0.additionalSafeAreaInsets) } ?? "nil")",
            "pageFrame=\(describe(pageFrame))",
            "pageSafe=\(describe(page.view.safeAreaInsets))",
            "pageAdditional=\(describe(page.additionalSafeAreaInsets))",
            "pageSafeBottomY=\(safeBottom)",
            "customBar=\(describe(barFrame))",
            "customHidden=\(bar.isHidden)",
            "systemBar=\(describe(controller.tabBar.frame))",
            "systemHidden=\(controller.tabBar.isHidden)",
            "controllerTabBarHidden=\(controller.isTabBarHidden)"
        ]
        print(fields.joined(separator: " "))
    }

    private func describe(_ rect: CGRect) -> String {
        "(x:\(rect.minX),y:\(rect.minY),w:\(rect.width),h:\(rect.height))"
    }

    private func describe(_ insets: UIEdgeInsets) -> String {
        "(top:\(insets.top),left:\(insets.left),bottom:\(insets.bottom),right:\(insets.right))"
    }
}

@MainActor
private final class TabBarVisibilitySpy: NSObject, CYLTabBarControllerDelegate,
                                         @preconcurrency CYLFlatDesignUITabBarControllerDelegate {
    private let requestShowOnWillHide: Bool
    private(set) var willHideCount = 0
    private(set) var didHideCount = 0
    private(set) var hiddenAfterReentrantShow: Bool?

    init(requestShowOnWillHide: Bool = false) {
        self.requestShowOnWillHide = requestShowOnWillHide
        super.init()
    }

    @objc(tabBarController:willHideTabBar:)
    func tabBarController(_ controller: CYLTabBarController, willHide bar: CYLFlatDesignTabBar) {
        willHideCount += 1
        // Reenter only once, so an accidental repeated callback fails the test
        // instead of the spy itself causing unbounded recursion.
        guard requestShowOnWillHide, willHideCount == 1 else { return }
        controller.setTabBarHidden(false, animated: false)
        hiddenAfterReentrantShow = controller.isTabBarHidden
    }

    @objc(tabBarController:didHideTabBar:)
    func tabBarController(_ controller: CYLTabBarController, didHide bar: CYLFlatDesignTabBar) {
        didHideCount += 1
    }
}

@MainActor
private final class Page: UIViewController {
    let marker = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        marker.backgroundColor = .orange
        marker.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(marker)
        NSLayoutConstraint.activate([
            marker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            marker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            marker.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            marker.heightAnchor.constraint(equalToConstant: 10)
        ])
    }
}

@MainActor
private final class Fixture {
    let scene: UIWindowScene
    let window: UIWindow
    let previousKeyWindow: UIWindow?
    let controller: CYLTabBarController
    let firstPage: Page
    let secondPage: Page
    let firstNavigation: UINavigationController?
    let secondNavigation: UINavigationController?
    let selectedBeforeDisplay: UIViewController?

    init(height: CGFloat?, rejectSystemTabBarReplacement: Bool = false, directChildren: Bool = false,
         selectedIndexBeforeDisplay: Int? = nil, firstPageAdditionalBottom: CGFloat = 0,
         hideBeforeDisplayAnimated: Bool? = nil, recordVisibilityRequests: Bool = false) throws {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let windowScene = try XCTUnwrap(scenes.first { $0.activationState == .foregroundActive } ?? scenes.first,
                                        "The hosted test requires a real UIWindowScene")
        scene = windowScene
        previousKeyWindow = windowScene.windows.first { $0.isKeyWindow }
        let testWindow = UIWindow(windowScene: windowScene)
        testWindow.frame = windowScene.effectiveGeometry.coordinateSpace.bounds
        window = testWindow
        let firstPage = Page()
        let secondPage = Page()
        firstPage.additionalSafeAreaInsets.bottom = firstPageAdditionalBottom
        self.firstPage = firstPage
        self.secondPage = secondPage
        let children: [UIViewController]
        if directChildren {
            firstNavigation = nil
            secondNavigation = nil
            children = [firstPage, secondPage]
        } else {
            let firstNavigation = UINavigationController(rootViewController: firstPage)
            let secondNavigation = UINavigationController(rootViewController: secondPage)
            self.firstNavigation = firstNavigation
            self.secondNavigation = secondNavigation
            children = [firstNavigation, secondNavigation]
        }
        let icon = try XCTUnwrap(UIImage(systemName: "circle"))
        let attributes: [[String: Any]] = ["First", "Second"].map {
            [CYLTabBarItemTitle: $0, CYLTabBarItemImage: icon, CYLTabBarItemSelectedImage: icon]
        }
        // A separate context prevents the host app's globally registered plus button
        // from turning this two-tab fixture into a three-tab fixture.
        let context = "Issue662Tests-\(UUID().uuidString)"
        let tabController: CYLTabBarController
        if rejectSystemTabBarReplacement {
            tabController = KVCRejectingTabBarController(viewControllers: children,
                                                        tabBarItemsAttributes: attributes,
                                                        styleType: .flatDesign, context: context)
        } else if recordVisibilityRequests {
            tabController = VisibilityRecordingTabBarController(viewControllers: children,
                                                                 tabBarItemsAttributes: attributes,
                                                                 styleType: .flatDesign, context: context)
        } else {
            tabController = CYLTabBarController(viewControllers: children,
                                                 tabBarItemsAttributes: attributes,
                                                 styleType: .flatDesign, context: context)
        }
        if let height = height {
            tabController.tabBarHeight = height
        }
        if let index = selectedIndexBeforeDisplay {
            tabController.selectedIndex = index
        }
        if let animated = hideBeforeDisplayAnimated {
            tabController.setTabBarHidden(true, animated: animated)
        }
        controller = tabController
        selectedBeforeDisplay = tabController.selectedViewController
        testWindow.rootViewController = tabController
        testWindow.makeKeyAndVisible()
    }

    func close() {
        window.isHidden = true
        window.rootViewController = nil
        previousKeyWindow?.makeKeyAndVisible()
    }
}

@MainActor
private final class VisibilityRecordingTabBarController: CYLTabBarController {
    var recordedRequests: [(hidden: Bool, animated: Bool)] = []

    override func setTabBarHidden(_ hidden: Bool, animated: Bool) {
        recordedRequests.append((hidden: hidden, animated: animated))
        super.setTabBarHidden(hidden, animated: animated)
    }
}

/// A test-only fault injection: the library's Objective-C `cyl_setValue` catches
/// this exception, leaving UIKit's original tab bar instead of the replacement.
@MainActor
private final class KVCRejectingTabBarController: CYLTabBarController {
    private(set) var rejectedTabBarAssignments = 0
    private(set) var rejectedTabBar: UITabBar?

    override func setValue(_ value: Any?, forKey key: String) {
        guard key == "tabBar" else {
            super.setValue(value, forKey: key)
            return
        }
        rejectedTabBarAssignments += 1
        rejectedTabBar = value as? UITabBar
        NSException(name: NSExceptionName("Issue662InjectedKVCException"),
                    reason: "Test-only rejection of tabBar replacement", userInfo: nil).raise()
    }
}
