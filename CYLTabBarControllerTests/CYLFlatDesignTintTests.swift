//
//  CYLFlatDesignTintTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import ImageIO
import UniformTypeIdentifiers
import UIKit
import XCTest
import CYLAnimatedItem
import CYLTabBarController

/**
 [EN] The one tint resolver of the FlatDesign tab (title and icon), the tab's animation tint options in both URL forms, and the priority of the
      bar-wide default rendering mode (docs/Animated-Item.md, "Tab bar tint priority"). The tint of an animation view is read from the overlay
      layer the engine draws over a GIF view.
 [CN] 扁平 Tab 唯一的着色解析器（标题与图标）、两种 URL 写法的动画着色选项，以及栏级默认渲染模式的优先级（docs/Animated-Item.md「TabBar 着色优先级」）。
      动画视图的着色从引擎画在 GIF 视图上的叠加图层读取。
 */
final class CYLFlatDesignTintTests: XCTestCase {

    private var windows: [UIWindow] = []
    private var temporaryFiles: [URL] = []

    override func tearDown() {
        windows.forEach { $0.isHidden = true }
        windows = []
        temporaryFiles.forEach { try? FileManager.default.removeItem(at: $0) }
        temporaryFiles = []
        super.tearDown()
    }

    // MARK: Helpers

    private struct Bar {
        let controller: CYLTabBarController
        let bar: UIView
        let buttons: [CYLAnimatedItemView]
    }

    private func icon() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }.withRenderingMode(.alwaysTemplate)
    }

    private func gif(_ colors: [UIColor]) throws -> URL {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let image = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16), format: format).image { context in
            for (index, color) in colors.enumerated() {
                color.setFill()
                context.fill(CGRect(x: index * 16 / colors.count, y: 0, width: 16 / colors.count, height: 16))
            }
        }
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, UTType.gif.identifier as CFString, 2, nil))
        for _ in 0..<2 {
            CGImageDestinationAddImage(destination, try XCTUnwrap(image.cgImage), nil)
        }
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("cyl-tint-\(UUID().uuidString).gif")
        try (data as Data).write(to: url)
        temporaryFiles.append(url)
        return url
    }

    private func oneColorGIF() throws -> URL { try gif([.black]) }
    private func multiColorGIF() throws -> URL { try gif([.red, .blue]) }

    private func withFragment(_ url: URL, _ options: [String: String]) throws -> URL {
        try XCTUnwrap(CYLTabBarAnimationURLWithOptions(url, options))
    }

    private func withQuery(_ url: URL, _ query: String) throws -> URL {
        var components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        components.percentEncodedQuery = query
        return try XCTUnwrap(components.url)
    }

    private func settle(_ view: UIView) {
        view.setNeedsLayout()
        view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.2))
        view.layoutIfNeeded()
    }

    private func buttons(in view: UIView) -> [CYLAnimatedItemView] {
        guard let buttonClass = NSClassFromString("CYLFlatDesignTabBarButton") else { return [] }
        var found: [CYLAnimatedItemView] = []
        var queue = [view]
        while !queue.isEmpty {
            let next = queue.removeFirst()
            if next.isKind(of: buttonClass), let button = next as? CYLAnimatedItemView { found.append(button) }
            queue.append(contentsOf: next.subviews)
        }
        return found.sorted { $0.frame.minX < $1.frame.minX }
    }

    private func makeBar(animations: [URL?] = [nil, nil], dark: Bool = false) throws -> Bar {
        guard NSClassFromString("CYLFlatDesignTabBar") != nil else { throw XCTSkip("FlatDesign is not compiled into this target") }
        let attributes: [[AnyHashable: Any]] = animations.enumerated().map { index, url in
            var item: [AnyHashable: Any] = [cylTabBarItemTitle: "T\(index)", cylTabBarItemImage: icon()]
            if let url {
                item[cylTabBarAnimationURL] = url
            }
            return item
        }
        let controller = CYLTabBarController(viewControllers: animations.map { _ in UIViewController() },
                                             tabBarItemsAttributes: attributes, styleType: .flatDesign, context: UUID().uuidString)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.overrideUserInterfaceStyle = dark ? .dark : .light
        window.rootViewController = controller
        window.isHidden = false
        windows.append(window)
        settle(controller.view)
        var queue: [UIView] = [controller.view]
        var found: UIView?
        while !queue.isEmpty, found == nil {
            let next = queue.removeFirst()
            if let barClass = NSClassFromString("CYLFlatDesignTabBar"), next.isKind(of: barClass) { found = next }
            queue.append(contentsOf: next.subviews)
        }
        let bar = try XCTUnwrap(found)
        let tabButtons = buttons(in: bar)
        XCTAssertEqual(tabButtons.count, animations.count)
        XCTAssertTrue(tabButtons.first?.isSelected == true, "the first tab is selected")
        return Bar(controller: controller, bar: bar, buttons: tabButtons)
    }

    private func rgba(_ color: UIColor?, _ view: UIView) -> [CGFloat]? {
        guard let color else { return nil }
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.resolvedColor(with: view.traitCollection).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a]
    }

    private func assertColor(_ actual: UIColor?, _ expected: UIColor?, in view: UIView, _ message: String, line: UInt = #line) {
        guard let a = rgba(actual, view), let e = rgba(expected, view) else {
            XCTFail("\(message): \(String(describing: actual)) / \(String(describing: expected))", line: line)
            return
        }
        for (x, y) in zip(a, e) { XCTAssertEqual(x, y, accuracy: 0.01, "\(message): \(a) / \(e)", line: line) }
    }

    private func titleColor(_ button: CYLAnimatedItemView) -> UIColor? { button.titleLabel.textColor }
    private func iconColor(_ button: CYLAnimatedItemView) -> UIColor? { button.imageView.tintColor }

    private func tabItem(_ bar: Bar, _ index: Int) throws -> CYLFlatDesignTabBarItem {
        try XCTUnwrap((bar.buttons[index] as? CYLFlatDesignTabBarButton)?.tabBarItem)
    }

    /// [EN] The color of the engine's tint overlay on the tab's animation view; nil without a tint. [CN] 引擎在 Tab 动画视图上的着色叠加图层颜色；无着色时为 nil。
    private func animationTint(_ button: CYLAnimatedItemView, line: UInt = #line) throws -> UIColor? {
        let view = try XCTUnwrap(button.animationView, "the tab has an animation view", line: line)
        let overlay = view.layer.sublayers?.first { $0.name == "CYLTabBarItemAnimationTintOverlay" }
        return overlay?.backgroundColor.map { UIColor(cgColor: $0) }
    }

    // MARK: Title and icon 标题与图标

    func testWithNothingSetTheSelectedTitleAndIconTakeTheTint() throws {
        let bar = try makeBar()
        let selected = bar.buttons[0]
        assertColor(titleColor(selected), selected.tintColor, in: selected, "selected title == tint")
        assertColor(iconColor(selected), titleColor(selected), in: selected, "selected icon == title")
        assertColor(titleColor(bar.buttons[1]), .systemGray, in: selected, "normal title is system gray")
        assertColor(iconColor(bar.buttons[1]), .systemGray, in: selected, "normal icon is system gray")
        XCTAssertNil(try tabItem(bar, 0).titleTextAttributes(for: .selected), "the library writes no color into the item")
    }

    func testTheBarTintColorsTitleAndIcon() throws {
        let bar = try makeBar()
        bar.bar.tintColor = .red
        bar.buttons.forEach { $0.tintColorDidChange() }
        settle(bar.controller.view)
        assertColor(titleColor(bar.buttons[0]), .red, in: bar.bar, "title")
        assertColor(iconColor(bar.buttons[0]), .red, in: bar.bar, "icon")
        assertColor(titleColor(bar.buttons[1]), .systemGray, in: bar.bar, "unselected stays gray")
    }

    func testAnAppearanceTitleColorLeavesTheIconOnTheTint() throws {
        let bar = try makeBar()
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.yellow]
        bar.bar.setValue(appearance, forKey: "standardAppearance")
        settle(bar.controller.view)
        let selected = bar.buttons[0]
        assertColor(titleColor(selected), .yellow, in: selected, "title follows the appearance")
        assertColor(iconColor(selected), selected.tintColor, in: selected, "icon follows the tint")
    }

    func testAnAppearanceIconColorChangesOnlyTheIcon() throws {
        let bar = try makeBar()
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.selected.iconColor = .green
        bar.bar.setValue(appearance, forKey: "standardAppearance")
        settle(bar.controller.view)
        let selected = bar.buttons[0]
        assertColor(iconColor(selected), .green, in: selected, "icon follows the appearance")
        assertColor(titleColor(selected), selected.tintColor, in: selected, "title follows the tint")
    }

    func testAnItemTitleColorBeatsTheAppearanceAndLeavesTheIcon() throws {
        let bar = try makeBar()
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.yellow]
        bar.bar.setValue(appearance, forKey: "standardAppearance")
        try tabItem(bar, 0).setTitleTextAttributes([.foregroundColor: UIColor.magenta], for: .selected)
        settle(bar.controller.view)
        let selected = bar.buttons[0]
        assertColor(titleColor(selected), .magenta, in: selected, "the app's per-tab title color wins")
        assertColor(iconColor(selected), selected.tintColor, in: selected, "the icon does not take the item's title color")
        selected.tintColorDidChange()
        assertColor(titleColor(selected), .magenta, in: selected, "still after a tint change")
    }

    func testDynamicColorsResolveInDarkMode() throws {
        let bar = try makeBar(dark: true)
        bar.bar.tintColor = UIColor { $0.userInterfaceStyle == .dark ? .green : .red }
        bar.buttons.forEach { $0.tintColorDidChange() }
        settle(bar.controller.view)
        assertColor(titleColor(bar.buttons[0]), .green, in: bar.buttons[0], "title")
        assertColor(iconColor(bar.buttons[0]), .green, in: bar.buttons[0], "icon")
    }

    // MARK: Animation tint 动画着色

    func testWithoutOptionsATabAnimationKeepsItsOwnColors() throws {
        let bar = try makeBar(animations: [try oneColorGIF(), try multiColorGIF()])
        XCTAssertNil(try animationTint(bar.buttons[0]), "one-color: untouched without an option")
        XCTAssertNil(try animationTint(bar.buttons[1]), "multi-color: untouched")
    }

    func testTintTitleIsHonoredInBothURLForms() throws {
        let fragment = try withFragment(try multiColorGIF(), ["tint": "title"])
        let query = try withQuery(try multiColorGIF(), "tint=title")
        let bar = try makeBar(animations: [fragment, query])
        assertColor(try animationTint(bar.buttons[0]), bar.buttons[0].tintColor, in: bar.buttons[0], "fragment form, selected")
        assertColor(try animationTint(bar.buttons[1]), .systemGray, in: bar.buttons[1], "query form, unselected")
    }

    func testAFixedTintShowsUnselectedAndYieldsToTheTitleColorSelectedInBothURLForms() throws {
        let fragment = try withFragment(try multiColorGIF(), ["tint": "#00FF00"])
        let query = try withQuery(try multiColorGIF(), "tint=%2300FF00")
        for url in [fragment, query] {
            let bar = try makeBar(animations: [url, url])
            assertColor(try animationTint(bar.buttons[0]), bar.buttons[0].tintColor, in: bar.buttons[0], "selected: as Liquid Glass")
            assertColor(try animationTint(bar.buttons[1]), .green, in: bar.buttons[1], "unselected: the fixed color")
        }
    }

    func testTheURLRenderingModeIsHonored() throws {
        let template = try withFragment(try multiColorGIF(), ["renderingMode": "alwaysTemplate"])
        let templateQuery = try withQuery(try multiColorGIF(), "renderingMode=alwaysTemplate")
        let bar = try makeBar(animations: [template, templateQuery])
        assertColor(try animationTint(bar.buttons[0]), bar.buttons[0].tintColor, in: bar.buttons[0], "alwaysTemplate")
        assertColor(try animationTint(bar.buttons[1]), .systemGray, in: bar.buttons[1], "alwaysTemplate, query form")
        let original = try withFragment(try oneColorGIF(), ["renderingMode": "alwaysOriginal"])
        let originalBar = try makeBar(animations: [original, original])
        XCTAssertNil(try animationTint(originalBar.buttons[0]), "alwaysOriginal")
    }

    func testAutomaticDetectionAskedByTheURLTintsOnlyTheOneColorFile() throws {
        let one = try withFragment(try oneColorGIF(), ["renderingMode": "automatic"])
        let multi = try withFragment(try multiColorGIF(), ["renderingMode": "automatic"])
        let bar = try makeBar(animations: [multi, one])
        XCTAssertNil(try animationTint(bar.buttons[0]), "multi-color keeps its colors")
        assertColor(try animationTint(bar.buttons[1]), .systemGray, in: bar.buttons[1], "one-color takes the icon color")
    }

    // MARK: Bar-wide default 栏级默认值

    func testTheBarDefaultAppliesAtRuntimeAndAutomaticRemovesItAgain() throws {
        let bar = try makeBar(animations: [try multiColorGIF(), try multiColorGIF()])
        bar.controller.tabBarItemAnimationRenderingMode = .alwaysTemplate
        settle(bar.controller.view)
        assertColor(try animationTint(bar.buttons[0]), bar.buttons[0].tintColor, in: bar.buttons[0], "selected")
        assertColor(try animationTint(bar.buttons[1]), .systemGray, in: bar.buttons[1], "unselected")
        bar.controller.tabBarItemAnimationRenderingMode = .automatic
        settle(bar.controller.view)
        XCTAssertNil(try animationTint(bar.buttons[0]), "automatic: unset, the file's own colors")
        XCTAssertNil(try animationTint(bar.buttons[1]))
    }

    func testTheTabsOwnSettingsBeatTheBarDefault() throws {
        let original = try withFragment(try multiColorGIF(), ["renderingMode": "alwaysOriginal"])
        let fixed = try withFragment(try multiColorGIF(), ["tint": "#00FF00"])
        let bar = try makeBar(animations: [original, fixed])
        bar.controller.tabBarItemAnimationRenderingMode = .alwaysTemplate
        settle(bar.controller.view)
        XCTAssertNil(try animationTint(bar.buttons[0]), "the tab's alwaysOriginal beats the bar's alwaysTemplate")
        assertColor(try animationTint(bar.buttons[1]), .green, in: bar.buttons[1], "the tab's URL tint beats the bar default")
        bar.controller.tabBarItemAnimationRenderingMode = .alwaysOriginal
        settle(bar.controller.view)
        assertColor(try animationTint(bar.buttons[1]), .green, in: bar.buttons[1], "also beats alwaysOriginal")
    }

    func testAPerTabAnimationTintBeatsTheBarDefaultAndTheURLTint() throws {
        let bar = try makeBar(animations: [try multiColorGIF(), try withFragment(try multiColorGIF(), ["tint": "title"])])
        bar.controller.tabBarItemAnimationRenderingMode = .alwaysOriginal
        bar.buttons[1].animationTint = "#FF0000"
        settle(bar.controller.view)
        assertColor(try animationTint(bar.buttons[1]), .red, in: bar.buttons[1], "animationTint on the tab button")
        bar.buttons[0].animationTint = "#0000FF"
        settle(bar.controller.view)
        assertColor(try animationTint(bar.buttons[0]), .blue, in: bar.buttons[0], "also on a view the URL asked nothing of")
    }

    func testAPerTabRenderingModeOnTheFlatButtonBeatsTheBarDefault() throws {
        let bar = try makeBar(animations: [try multiColorGIF(), try multiColorGIF()])
        bar.buttons[1].animationRenderingMode = .alwaysTemplate
        settle(bar.controller.view)
        assertColor(try animationTint(bar.buttons[1]), .systemGray, in: bar.buttons[1], "alwaysTemplate on the button tints a URL without options")
        XCTAssertNil(try animationTint(bar.buttons[0]), "the other tab keeps the file's own colors")
        bar.controller.tabBarItemAnimationRenderingMode = .alwaysTemplate
        bar.buttons[0].animationRenderingMode = .alwaysOriginal
        settle(bar.controller.view)
        XCTAssertNil(try animationTint(bar.buttons[0]), "alwaysOriginal on the button beats the bar's alwaysTemplate")
        assertColor(try animationTint(bar.buttons[1]), .systemGray, in: bar.buttons[1], "still tinted")
    }

    func testTheTabFlowUsesTheBarDefaultOnlyWhereTheURLSetsNothing() throws {
        let plain = UIView()
        _ = CYLTabBarItemAnimationPrepareTabTint(plain, try multiColorGIF(), nil, CYLAnimatedItemRenderingMode.alwaysTemplate.rawValue)
        XCTAssertEqual(CYLTabBarItemAnimationTabFlowRenderingMode(plain), .alwaysTemplate)
        let unset = UIView()
        _ = CYLTabBarItemAnimationPrepareTabTint(unset, try oneColorGIF(), nil, CYLAnimatedItemRenderingMode.automatic.rawValue)
        XCTAssertEqual(CYLTabBarItemAnimationTabFlowRenderingMode(unset), .alwaysOriginal, "automatic default: as before")
        let own = UIView()
        _ = CYLTabBarItemAnimationPrepareTabTint(own, try withFragment(try multiColorGIF(), ["renderingMode": "alwaysOriginal"]), nil,
                                                 CYLAnimatedItemRenderingMode.alwaysTemplate.rawValue)
        XCTAssertEqual(CYLTabBarItemAnimationTabFlowRenderingMode(own), .alwaysOriginal)
    }

    /// [EN] The tint overlays in the system tab bar (Liquid Glass on iOS 26 and later, else classic). [CN] 系统 TabBar（iOS 26 及以上为液态玻璃，否则为经典样式）中的着色叠加图层。
    private func tintOverlays(in view: UIView) -> [CALayer] {
        (view.layer.sublayers?.filter { $0.name == "CYLTabBarItemAnimationTintOverlay" } ?? []) + view.subviews.flatMap { tintOverlays(in: $0) }
    }

    func testTheBarDefaultReachesTheSystemTabBar() throws {
        let urls = [try multiColorGIF(), try multiColorGIF()]
        let attributes: [[AnyHashable: Any]] = urls.enumerated().map { index, url in
            [cylTabBarItemTitle: "S\(index)", cylTabBarItemImage: icon(), cylTabBarAnimationURL: url]
        }
        let controller = CYLTabBarController(viewControllers: [UIViewController(), UIViewController()],
                                             tabBarItemsAttributes: attributes, styleType: .default, context: UUID().uuidString)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.isHidden = false
        windows.append(window)
        settle(controller.view)
        XCTAssertTrue(tintOverlays(in: controller.view).isEmpty, "nothing set: the files' own colors")
        controller.tabBarItemAnimationRenderingMode = .alwaysTemplate
        settle(controller.view)
        XCTAssertFalse(tintOverlays(in: controller.view).isEmpty, "alwaysTemplate reaches the system tab bar")
        controller.tabBarItemAnimationRenderingMode = .automatic
        settle(controller.view)
        XCTAssertTrue(tintOverlays(in: controller.view).isEmpty, "automatic removes it again")
    }

    func testARemoteURLsQueryIsNotReadAsOptions() throws {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "example.com"
        components.path = "/a.gif"
        components.percentEncodedQuery = "tint=title"
        XCTAssertEqual(CYLTabBarAnimationOptionsFromURL(try XCTUnwrap(components.url)) as? [String: String], [:])
    }
}
