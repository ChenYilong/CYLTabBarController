//
//  CYLAnimatedItemDefaultTintTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import ImageIO
import UniformTypeIdentifiers
import XCTest
import CYLAnimatedItem

private final class DefaultTintRecordingView: UIView {
    var calls: [UIColor?] = []

    @objc(cyl_applyAnimationViewTintColor:selected:)
    func applyTint(_ color: UIColor?, selected _: Bool) { calls.append(color) }
}

private final class DefaultTintFactory: NSObject, CYLTabBarItemAnimationViewMaking {
    let view = DefaultTintRecordingView()

    func animationView(url _: URL, size _: CGSize, contentMode _: UIView.ContentMode) -> UIView? { view }
    func player(for _: UIView?) -> CYLTabBarItemAnimationPlayer? { nil }
    func isAnimationView(_ view: UIView?) -> Bool { view === self.view }
}

/// An item whose animation view is given (as the FlatDesign tab does with the tab flow's view).
private final class GivenViewItem: CYLAnimatedItemView {
    var given: UIView?
    override var animationView: UIView? { given }
}

/// A tag-like subclass with its own icon colors by `applyIconTintColor`.
private final class DefaultTintTagItem: CYLAnimatedItemView {
    override func itemStateDidChange() {
        super.itemStateDidChange()
        applyIconTintColor(.orange)
    }
}

/**
 * [EN] Tint spec v2: built-in colors (probe values), explicit vs effective icon colors, the rendering mode with the one-color detector and its fixtures,
 *      the tab flow's alwaysOriginal, and the divider contrast.
 * [CN] 着色规格 v2：内置颜色（实测值）、显式与有效图标颜色、渲染模式与单色检测及其夹具、Tab 流程的 alwaysOriginal、分隔条对比度。
 */
final class CYLAnimatedItemDefaultTintTests: XCTestCase {

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

    private func window(dark: Bool = false) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.overrideUserInterfaceStyle = dark ? .dark : .light
        window.isHidden = false
        windows.append(window)
        return window
    }

    private func rgba(_ color: UIColor?, _ style: UIUserInterfaceStyle = .light) -> [CGFloat]? {
        guard let color else { return nil }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a]
    }

    private func assertColor(_ actual: UIColor?, _ expected: UIColor?, _ message: String, _ style: UIUserInterfaceStyle = .light, line: UInt = #line) {
        guard let a = rgba(actual, style), let e = rgba(expected, style) else {
            XCTAssertEqual(actual == nil, expected == nil, message, line: line)
            return
        }
        for (x, y) in zip(a, e) { XCTAssertEqual(x, y, accuracy: 0.006, message, line: line) }
    }

    private func probe(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> UIColor {
        UIColor(red: r / 255, green: g / 255, blue: b / 255, alpha: a)
    }

    private func fixture(_ name: String) throws -> URL {
        let bundle = Bundle(for: CYLAnimatedItemDefaultTintTests.self)
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "json"), "fixture \(name).json is in the test bundle")
        return url
    }

    private func makeItem(_ factory: DefaultTintFactory, url: URL?, dark: Bool = false) -> CYLAnimatedItemView {
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 80, height: 49))
        window(dark: dark).addSubview(item)
        item.iconSize = CGSize(width: 24, height: 24)
        item.animationSource = factory
        item.animationURL = url
        return item
    }

    private func composite(_ color: UIColor, over background: UIColor, _ style: UIUserInterfaceStyle) -> [CGFloat] {
        let c = rgba(color, style)!, b = rgba(background, style)!
        return (0..<3).map { c[$0] * c[3] + b[$0] * (1 - c[3]) }
    }

    private func luminance(_ rgb: [CGFloat]) -> CGFloat {
        let l = rgb.map { $0 <= 0.03928 ? $0 / 12.92 : pow(($0 + 0.055) / 1.055, 2.4) }
        return 0.2126 * l[0] + 0.7152 * l[1] + 0.0722 * l[2]
    }

    private func contrast(_ a: [CGFloat], _ b: [CGFloat]) -> CGFloat {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    private func gif(_ drawing: (CGContext) -> Void) throws -> URL {
        let size = CGSize(width: 10, height: 10)
        let image = UIGraphicsImageRenderer(size: size, format: { let f = UIGraphicsImageRendererFormat(); f.scale = 1; f.opaque = false; return f }()).image { drawing($0.cgContext) }
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, UTType.gif.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, try XCTUnwrap(image.cgImage), nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("cyl-default-tint-\(UUID().uuidString).gif")
        try (data as Data).write(to: url)
        temporaryFiles.append(url)
        return url
    }

    private func temporaryFile(_ name: String, _ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("cyl-default-tint-\(UUID().uuidString)-\(name)")
        try data.write(to: url)
        temporaryFiles.append(url)
        return url
    }

    // MARK: Probe values (iOS 27.2) 实测值

    /// Pins the system values the owner measured on the iOS 27.2 simulator (light | dark) and the built-ins that use them.
    func testProbeValuesArePinned() {
        let rows: [(String, UIColor, UIColor, UIColor)] = [
            ("label", .label, probe(0, 0, 0), probe(255, 255, 255)),
            ("secondaryLabel", .secondaryLabel, probe(60, 60, 67, 0.60), probe(235, 235, 245, 0.60)),
            ("tertiaryLabel", .tertiaryLabel, probe(60, 60, 67, 0.30), probe(235, 235, 245, 0.30)),
            ("systemBlue (default tint)", .systemBlue, probe(0, 136, 255), probe(0, 145, 255)),
            ("disabled (UIButton)", CYLAnimatedItemView.systemDisabledColor, probe(134, 134, 134, 0.45), probe(140, 140, 140, 0.35)),
        ]
        for (name, color, light, dark) in rows {
            assertColor(color, light, "\(name) light", .light)
            assertColor(color, dark, "\(name) dark", .dark)
        }
        // The item's own built-ins resolve to exactly these.
        for style in [UIUserInterfaceStyle.light, .dark] {
            let isDark = style == .dark
            let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 80, height: 49))
            window(dark: isDark).addSubview(item)
            assertColor(item.imageView.tintColor, isDark ? probe(255, 255, 255) : probe(0, 0, 0), "normal icon is label \(style.rawValue)", style)
            assertColor(item.titleLabel.textColor, isDark ? probe(255, 255, 255) : probe(0, 0, 0), "normal title is label \(style.rawValue)", style)
            item.isSelected = true
            assertColor(item.imageView.tintColor, isDark ? probe(0, 145, 255) : probe(0, 136, 255), "selected icon is the tint \(style.rawValue)", style)
            assertColor(item.titleLabel.textColor, isDark ? probe(0, 145, 255) : probe(0, 136, 255), "selected title is the tint \(style.rawValue)", style)
            item.isSelected = false
            item.isEnabled = false
            assertColor(item.imageView.tintColor, isDark ? probe(140, 140, 140, 0.35) : probe(134, 134, 134, 0.45), "disabled icon \(style.rawValue)", style)
            assertColor(item.titleLabel.textColor, isDark ? probe(140, 140, 140, 0.35) : probe(134, 134, 134, 0.45), "disabled title \(style.rawValue)", style)
        }
    }

    // MARK: Built-ins with nothing set 什么都不设置

    func testNothingSetGivesAdaptiveColorsAndASelectedStateChange() {
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 80, height: 49))
        let window = window()
        window.addSubview(item)
        let normal = item.imageView.tintColor
        item.isSelected = true
        XCTAssertNotEqual(rgba(normal), rgba(item.imageView.tintColor), "selecting changes the icon color with nothing set")
        XCTAssertNotEqual(rgba(item.titleLabel.textColor), rgba(normal), "and the title color")
        item.isSelected = false
        assertColor(item.imageView.tintColor, normal, "deselected: back")
        window.overrideUserInterfaceStyle = .dark
        item.layoutIfNeeded()
        assertColor(item.imageView.tintColor, .white, "live switch to dark: plain white label color, not stale")
        window.overrideUserInterfaceStyle = .light
        item.layoutIfNeeded()
        assertColor(item.imageView.tintColor, .black, "live switch back")
    }

    func testSelectedColorFollowsTheInheritedTint() {
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 80, height: 49))
        let window = window()
        let container = UIView(frame: window.bounds)
        window.addSubview(container)
        container.addSubview(item)
        item.isSelected = true
        window.tintColor = .red
        assertColor(item.imageView.tintColor, .red, "tintColorDidChange re-resolves the icon")
        assertColor(item.titleLabel.textColor, .red, "and the title")
        container.tintColor = .green
        assertColor(item.imageView.tintColor, .green, "the superview chain's tint")
        container.tintAdjustmentMode = .dimmed
        XCTAssertEqual(item.tintAdjustmentMode, .dimmed)
        XCTAssertNotEqual(rgba(item.tintColor), rgba(.green), "a dimmed tint chain gives a dimmed color (what tintColor reports)")
        assertColor(item.imageView.tintColor, item.tintColor, "the icon follows the dimmed tintColor")
        assertColor(item.titleLabel.textColor, item.tintColor, "and the title")
    }

    func testATitleColorSetBySomeoneElseIsKept() {
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 80, height: 49))
        window().addSubview(item)
        item.titleLabel.textColor = .purple
        item.isSelected = true
        assertColor(item.titleLabel.textColor, .purple, "a subclass / countdown title color is not overwritten by the built-in")
        let explicit = UITabBarItemAppearance()
        explicit.selected.titleTextAttributes = [.foregroundColor: UIColor.magenta]
        item.itemAppearance = explicit
        assertColor(item.titleLabel.textColor, .magenta, "an explicit title color wins")
    }

    // MARK: Precedence 优先级

    func testPrecedenceItemThenStackThenSubclassThenBuiltIn() {
        let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        window().addSubview(stack)
        let item = DefaultTintTagItem(frame: .zero)
        stack.append(item, action: nil, spacingBefore: 0)
        item.applyIconTintColor(.orange)
        assertColor(item.imageView.tintColor, .orange, "subclass beats the built-in")
        let stackAppearance = UITabBarItemAppearance()
        stackAppearance.normal.iconColor = .blue
        stack.itemAppearance = stackAppearance
        assertColor(item.imageView.tintColor, .blue, "stack explicit beats the subclass")
        let own = UITabBarItemAppearance()
        own.normal.iconColor = .red
        item.itemAppearance = own
        assertColor(item.imageView.tintColor, .red, "item explicit beats the stack")
        item.itemAppearance = nil
        assertColor(item.imageView.tintColor, .orange, "assigning nil resets to the next level (the stack's is not re-given: the subclass)")
        item.applyIconTintColor(nil)
        assertColor(item.imageView.tintColor, .black, "nil subclass color: the built-in label color")
    }

    /// EXPLICIT vs EFFECTIVE: a FIXED tint on a SELECTED item yields only to an explicit selected icon color, never to the built-in tint or a subclass color.
    func testFixedTintSelectedYieldsOnlyToAnExplicitSelectedIconColor() {
        let url = try! fixture("camera-one-color")
        let fixed = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
        func lastColor(_ factory: DefaultTintFactory) -> UIColor? { factory.view.calls.last ?? nil }

        let nothing = DefaultTintFactory()
        let a = makeItem(nothing, url: url)
        a.animationTint = "#00FF00"
        a.isSelected = true
        assertColor(lastColor(nothing), fixed, "selected, nothing explicit: the fixed tint (not blue)")

        let subclass = DefaultTintFactory()
        let b = DefaultTintTagItem(frame: CGRect(x: 0, y: 0, width: 80, height: 49))
        window().addSubview(b)
        b.animationSource = subclass
        b.animationURL = url
        b.animationTint = "#00FF00"
        b.isSelected = true
        assertColor(b.imageView.tintColor, .orange, "the icon takes the subclass color")
        assertColor(lastColor(subclass), fixed, "the fixed tint does not yield to a subclass color")

        let explicit = DefaultTintFactory()
        let c = makeItem(explicit, url: url)
        c.animationTint = "#00FF00"
        let appearance = UITabBarItemAppearance()
        appearance.selected.iconColor = .magenta
        c.itemAppearance = appearance
        c.isSelected = true
        assertColor(lastColor(explicit), .magenta, "an explicit selected icon color wins")
        c.isSelected = false
        assertColor(lastColor(explicit), fixed, "unselected: the fixed tint")
    }

    // MARK: Detector and fixtures 检测与夹具

    func testDetectorOnFixtures() throws {
        func kind(_ name: String) throws -> CYLTabBarItemAnimationColorKind {
            CYLTabBarItemAnimationColorKindOfData(try Data(contentsOf: try fixture(name)))
        }
        XCTAssertEqual(try kind("camera-one-color"), .oneColor, "camera icon: one near-black color (stroke + keyframed fill within +-2/255)")
        XCTAssertEqual(try kind("one-color-tab_home_animate"), .oneColor, "the repo's tab_home_animate.json (Example): one color 0.133")
        XCTAssertEqual(try kind("image-layers-gray_tabbar_me_animation"), .multiColor, "the repo's gray_tabbar_me_animation.json: image layers (ty 2)")
        XCTAssertEqual(try kind("multicolor-green_lottie_tab_mine"), .multiColor, "the repo's green Lottie: three colors, never flattened")
        XCTAssertEqual(try kind("gradient-multi-color"), .multiColor, "a gradient is multi-color")
        // URL entry point, cached per file.
        XCTAssertEqual(CYLTabBarItemAnimationColorKindOfURL(try fixture("camera-one-color")), .oneColor)
        XCTAssertEqual(CYLTabBarItemAnimationColorKindOfURL(try fixture("camera-one-color")), .oneColor, "cached")
        XCTAssertEqual(CYLTabBarItemAnimationColorKindOfURL(URL(string: "https://example.com/a.json")), .undetectable, "remote: nothing is downloaded")
        XCTAssertEqual(CYLTabBarItemAnimationColorKindOfURL(nil), .undetectable)
    }

    func testDetectorRules() {
        func lottie(_ shapes: String, assets: String = "[]", layerType: Int = 4) -> Data {
            Data("""
            {"v":"5.7.0","assets":\(assets),"layers":[{"ind":1,"ty":\(layerType),"ip":0,"shapes":\(shapes)}]}
            """.utf8)
        }
        func fill(_ c: String, extra: String = "") -> String { "{\"ty\":\"fl\",\"c\":{\"a\":0,\"k\":\(c)}\(extra)}" }
        func kind(_ data: Data) -> CYLTabBarItemAnimationColorKind { CYLTabBarItemAnimationColorKindOfData(data) }
        XCTAssertEqual(kind(lottie("[\(fill("[0,0,0,1]"))]")), .oneColor)
        XCTAssertEqual(kind(lottie("[\(fill("[0,0,0,1]")),\(fill("[0.007,0.007,0.007,1]"))]")), .oneColor, "within +-2/255 (1.8) is the same color")
        XCTAssertEqual(kind(lottie("[\(fill("[0,0,0,1]")),\(fill("[0.02,0,0,1]"))]")), .multiColor, "5/255 apart is another color")
        XCTAssertEqual(kind(lottie("[\(fill("[1,0,0,1]")),\(fill("[0,0,1,1]", extra: ",\"hd\":true"))]")), .oneColor, "a hidden shape is ignored")
        XCTAssertEqual(kind(lottie("[\(fill("[1,0,0,1]")),\(fill("[0,0,1,0]"))]")), .oneColor, "a fully transparent color is ignored")
        XCTAssertEqual(kind(lottie("[\(fill("[1,0,0,1]")),\(fill("[0,0,1,1]", extra: ",\"o\":{\"a\":0,\"k\":0}"))]")), .oneColor, "a fill with opacity 0 is ignored")
        XCTAssertEqual(kind(lottie("[\(fill("[1,0,0,0.5]")),\(fill("[1,0,0,1]"))]")), .oneColor, "alpha is ignored")
        XCTAssertEqual(kind(lottie("[\(fill("[{\"t\":0,\"s\":[1,0,0,1],\"e\":[0,1,0,1]},{\"t\":9,\"s\":[0,1,0,1]}]"))]")), .multiColor, "every keyframe value counts (s and e)")
        XCTAssertEqual(kind(lottie("[\(fill("[255,0,0]")),\(fill("[1,0,0,1]"))]")), .oneColor, "0...255 values are scaled")
        XCTAssertEqual(kind(lottie("[{\"ty\":\"st\",\"c\":{\"a\":0,\"k\":[0,0,0,1]}},\(fill("[0,0,0,1]"))]")), .oneColor, "stroke and fill share one color")
        XCTAssertEqual(kind(lottie("[{\"ty\":\"gs\"}]")), .multiColor, "a gradient stroke")
        XCTAssertEqual(kind(lottie("[\(fill("[0,0,0,1]"))]", layerType: 2)), .multiColor, "an image layer")
        XCTAssertEqual(kind(lottie("[\(fill("[0,0,0,1]"))]", assets: "[{\"id\":\"i\",\"p\":\"a.png\",\"u\":\"images/\",\"w\":4,\"h\":4}]")), .multiColor, "an image asset")
        XCTAssertEqual(kind(lottie("[]")), .undetectable, "no colors: nothing to say")
        XCTAssertEqual(kind(Data("not json".utf8)), .undetectable, "parse failure")
        XCTAssertEqual(kind(Data("{\"layers\": [".utf8)), .undetectable, "broken json")
        XCTAssertEqual(kind(Data([0x50, 0x41, 0x47, 0x01, 0x02, 0x03, 0x04])), .undetectable, "PAG")
        XCTAssertEqual(kind(Data([0x50, 0x4B, 0x03, 0x04, 0x00, 0x00])), .undetectable, "a zip (SVGA / dotLottie)")
        XCTAssertEqual(kind(Data("RIVE".utf8 + [0x07, 0x00])), .undetectable, "Rive")
    }

    func testDetectorOnGIFFirstFrame() throws {
        let one = try gif { c in UIColor.red.setFill(); c.fill(CGRect(x: 0, y: 0, width: 10, height: 10)) }
        XCTAssertEqual(CYLTabBarItemAnimationColorKindOfURL(one), .oneColor, "a solid frame")
        let glyph = try gif { c in UIColor.black.setFill(); c.fill(CGRect(x: 2, y: 2, width: 6, height: 6)) }
        XCTAssertEqual(CYLTabBarItemAnimationColorKindOfURL(glyph), .oneColor, "transparent pixels (alpha < 0.1) are ignored")
        let tolerated = try gif { c in
            UIColor.red.setFill(); c.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
            UIColor.blue.setFill(); c.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        XCTAssertEqual(CYLTabBarItemAnimationColorKindOfURL(tolerated), .oneColor, "99% in one bucket")
        let split = try gif { c in
            UIColor.red.setFill(); c.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
            UIColor.blue.setFill(); c.fill(CGRect(x: 0, y: 0, width: 5, height: 10))
        }
        XCTAssertEqual(CYLTabBarItemAnimationColorKindOfURL(split), .multiColor, "50% / 50%")
        let almost = try gif { c in
            UIColor.red.setFill(); c.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
            UIColor.blue.setFill(); c.fill(CGRect(x: 0, y: 0, width: 3, height: 1))
        }
        XCTAssertEqual(CYLTabBarItemAnimationColorKindOfURL(almost), .multiColor, "97% is below 98%")
    }

    // MARK: Rendering mode 渲染模式

    private enum Source { case camera, gray, green, gradient, empty, pag, gifOne, gifMulti }
    private enum Level { case item, stack, urlOption }

    private func url(_ source: Source) throws -> URL {
        switch source {
        case .camera: return try fixture("camera-one-color")
        case .gray: return try fixture("one-color-tab_home_animate")
        case .green: return try fixture("multicolor-green_lottie_tab_mine")
        case .gradient: return try fixture("gradient-multi-color")
        case .empty: return try temporaryFile("empty.json", Data("{}".utf8))
        case .pag: return try temporaryFile("icon.pag", Data([0x50, 0x41, 0x47, 0x01, 0x02, 0x03, 0x04, 0x05]))
        case .gifOne: return try gif { c in UIColor.black.setFill(); c.fill(CGRect(x: 0, y: 0, width: 10, height: 10)) }
        case .gifMulti: return try gif { c in
            UIColor.red.setFill(); c.fill(CGRect(x: 0, y: 0, width: 10, height: 10))
            UIColor.blue.setFill(); c.fill(CGRect(x: 0, y: 0, width: 5, height: 10)) }
        }
    }

    func testRenderingModeTable() throws {
        // (source, mode, expects a tint) for an unselected item with nothing set.
        let rows: [(Source, CYLAnimatedItemRenderingMode, Bool)] = [
            (.camera, .automatic, true), (.camera, .alwaysTemplate, true), (.camera, .alwaysOriginal, false),
            (.gray, .automatic, true),
            (.green, .automatic, false), (.green, .alwaysTemplate, true), (.green, .alwaysOriginal, false),
            (.gradient, .automatic, false), (.gradient, .alwaysTemplate, true),
            (.empty, .automatic, false), (.empty, .alwaysTemplate, true),
            (.pag, .automatic, false), (.pag, .alwaysTemplate, true), (.pag, .alwaysOriginal, false),
            (.gifOne, .automatic, true), (.gifMulti, .automatic, false), (.gifMulti, .alwaysTemplate, true),
        ]
        for (source, mode, tinted) in rows {
            for level in [Level.item, .stack, .urlOption] {
                let factory = DefaultTintFactory()
                var fileURL = try url(source)
                if level == .urlOption {
                    var components = URLComponents(url: fileURL, resolvingAgainstBaseURL: false)!
                    components.fragment = "renderingMode=\(mode == .automatic ? "automatic" : mode == .alwaysTemplate ? "alwaysTemplate" : "alwaysOriginal")"
                    fileURL = components.url!
                }
                let item: CYLAnimatedItemView
                switch level {
                case .item:
                    item = makeItem(factory, url: fileURL)
                    item.animationRenderingMode = mode
                case .stack:
                    let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
                    window().addSubview(stack)
                    stack.animationRenderingMode = mode
                    item = CYLAnimatedItemView(frame: .zero)
                    item.iconSize = CGSize(width: 24, height: 24)
                    item.animationSource = factory
                    stack.append(item, action: nil, spacingBefore: 0)
                    item.animationURL = fileURL
                case .urlOption:
                    item = makeItem(factory, url: fileURL)
                }
                guard let last = factory.view.calls.last else { XCTFail("\(source) \(mode) \(level): nothing reached the view"); continue }
                if tinted {
                    assertColor(last, UIColor.label.resolvedColor(with: item.traitCollection), "\(source) \(mode) \(level): the effective (label) color")
                } else {
                    XCTAssertNil(last, "\(source) \(mode) \(level): the file's own colors")
                }
            }
        }
    }

    func testAnExplicitTintBeatsTheRenderingModeAndAnItemModeBeatsTheStackMode() throws {
        let factory = DefaultTintFactory()
        let item = makeItem(factory, url: try fixture("multicolor-green_lottie_tab_mine"))
        item.animationRenderingMode = .alwaysOriginal
        item.animationTint = "#00FF00"
        assertColor(factory.view.calls.last ?? nil, UIColor(red: 0, green: 1, blue: 0, alpha: 1), "an explicit tint wins over alwaysOriginal")
        item.animationTint = "banana"
        XCTAssertNil(factory.view.calls.last ?? nil, "an invalid tint is unset: the rendering mode decides (original)")
        item.animationTint = nil
        item.animationRenderingMode = .alwaysTemplate
        assertColor(factory.view.calls.last ?? nil, UIColor.label.resolvedColor(with: item.traitCollection), "template")

        let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        window().addSubview(stack)
        stack.animationRenderingMode = .alwaysTemplate
        let f2 = DefaultTintFactory()
        let own = CYLAnimatedItemView(frame: .zero)
        own.animationSource = f2
        own.animationRenderingMode = .alwaysOriginal
        stack.append(own, action: nil, spacingBefore: 0)
        own.animationURL = try fixture("camera-one-color")
        XCTAssertNil(f2.view.calls.last ?? nil, "the item's own mode beats the stack's")
        own.animationRenderingMode = .automatic
        XCTAssertNotNil(f2.view.calls.last ?? nil, "automatic on the item inherits the stack's alwaysTemplate")
        stack.animationRenderingMode = .automatic
        assertColor(f2.view.calls.last ?? nil, UIColor.label.resolvedColor(with: own.traitCollection), "camera is one-color: automatic still tints")
        stack.remove(own)
        XCTAssertEqual(own.inheritedAnimationRenderingMode, .automatic)
    }

    func testTheEffectiveSelectedColorTintsAOneColorFileAndFollowsTheTrait() throws {
        let factory = DefaultTintFactory()
        let window = window()
        let item = makeItem(factory, url: try fixture("camera-one-color"))
        window.addSubview(item)
        assertColor(factory.view.calls.last ?? nil, .black, "light, unselected: label")
        window.overrideUserInterfaceStyle = .dark
        item.layoutIfNeeded()
        assertColor(factory.view.calls.last ?? nil, .white, "live switch: plain white pushed")
        item.isSelected = true
        assertColor(factory.view.calls.last ?? nil, probe(0, 145, 255), "selected dark: the tint", .dark)
    }

    // MARK: Tab flow 标签流程

    func testTheTabFlowKeepsTheFilesOwnColorsWithoutATintOption() throws {
        let plain = UIView()
        _ = CYLTabBarItemAnimationPrepareTint(plain, try fixture("camera-one-color"), nil)
        XCTAssertEqual(CYLTabBarItemAnimationTabFlowRenderingMode(plain), .alwaysOriginal, "a one-color tab icon is not recolored without #tint")
        XCTAssertFalse(plain.responds(to: NSSelectorFromString("cyl_applyAnimationViewTintColor:")), "no tint method: nothing recolors it")

        let template = UIView()
        var components = URLComponents(url: try fixture("camera-one-color"), resolvingAgainstBaseURL: false)!
        components.fragment = "renderingMode=alwaysTemplate"
        XCTAssertTrue(CYLTabBarItemAnimationPrepareTint(template, components.url!, nil), "an explicit alwaysTemplate tints like title")
        XCTAssertEqual(CYLTabBarItemAnimationTabFlowRenderingMode(template), .alwaysTemplate)

        let tinted = UIView()
        components.fragment = "tint=title"
        XCTAssertTrue(CYLTabBarItemAnimationPrepareTint(tinted, components.url!, nil))

        XCTAssertEqual(CYLTabBarItemAnimationTabFlowRenderingMode(UIView()), .automatic, "a view the tab flow did not prepare")

        // The item (FlatDesign tab) that shows the tab flow's view: automatic takes the tab flow's alwaysOriginal.
        let flowView = DefaultTintRecordingView()
        _ = CYLTabBarItemAnimationPrepareTint(flowView, try fixture("camera-one-color"), nil)
        let item = GivenViewItem(frame: CGRect(x: 0, y: 0, width: 80, height: 49))
        window().addSubview(item)
        item.given = flowView
        item.animationURL = try fixture("camera-one-color")
        item.applyItemAppearance()
        XCTAssertNil(flowView.calls.last ?? nil, "the tab flow's alwaysOriginal beats automatic detection")
        item.animationRenderingMode = .alwaysTemplate
        XCTAssertNotNil(flowView.calls.last ?? nil, "the item's own mode wins")
    }

    // MARK: Divider contrast 分隔条对比度

    func testTheDefaultDividerHasAtLeastThreeToOneContrastOnLightAndDarkBars() {
        for (style, bar) in [(UIUserInterfaceStyle.light, UIColor.white), (.dark, UIColor.black)] {
            let color = UIColor.secondaryLabel
            let ratio = contrast(composite(color, over: bar, style), rgba(bar, style)!.prefix(3).map { $0 })
            XCTAssertGreaterThanOrEqual(ratio, 3.0, "secondaryLabel on \(style == .light ? "white" : "black"): \(ratio)")
        }
        // The stack's own default divider is that color, resolved per appearance.
        for dark in [false, true] {
            let stack = CYLAnimatedItemStackView(frame: .zero)
            stack.contentMargin = 0
            window(dark: dark).addSubview(stack)
            let a = CYLAnimatedItemView(frame: .zero), b = CYLAnimatedItemView(frame: .zero)
            stack.append(a, action: nil, spacingBefore: 0)
            stack.append(b, action: nil, spacingBefore: 0)
            stack.showsDividers = true
            stack.frame = CGRect(origin: .zero, size: stack.intrinsicContentSize)
            stack.layoutIfNeeded()
            let divider = stack.dividerViews[0] as! CYLAnimatedItemView
            let line = divider.subviews.first { $0 !== divider.imageView && $0 !== divider.titleLabel && !$0.isHidden }
            let style: UIUserInterfaceStyle = dark ? .dark : .light
            assertColor(line?.backgroundColor, UIColor.secondaryLabel, "stack default divider (dark \(dark))", style)
        }
    }

    func testAnExplicitIconColorDividerIsAtAlpha06AndKeepsTheContrast() {
        XCTAssertEqual(CYLAnimatedItemDividerAlpha, 0.6)
        for (style, bar, icon) in [(UIUserInterfaceStyle.light, UIColor.white, UIColor.black), (.dark, UIColor.black, UIColor.white)] {
            let ratio = contrast(composite(icon.withAlphaComponent(CYLAnimatedItemDividerAlpha), over: bar, style), rgba(bar, style)!.prefix(3).map { $0 })
            XCTAssertGreaterThanOrEqual(ratio, 3.0, "explicit label-like icon color at 0.6: \(ratio)")
        }
        let dark = false
        let stack = CYLAnimatedItemStackView(frame: .zero)
        stack.contentMargin = 0
        window(dark: dark).addSubview(stack)
        let appearance = UITabBarItemAppearance()
        appearance.normal.iconColor = .red
        stack.itemAppearance = appearance
        stack.append(CYLAnimatedItemView(frame: .zero), action: nil, spacingBefore: 0)
        stack.append(CYLAnimatedItemView(frame: .zero), action: nil, spacingBefore: 0)
        stack.showsDividers = true
        stack.frame = CGRect(origin: .zero, size: stack.intrinsicContentSize)
        stack.layoutIfNeeded()
        let divider = stack.dividerViews[0] as! CYLAnimatedItemView
        let line = divider.subviews.first { $0 !== divider.imageView && $0 !== divider.titleLabel && !$0.isHidden }
        assertColor(line?.backgroundColor, UIColor.red.withAlphaComponent(0.6), "explicit icon color at 0.6")
    }
}
