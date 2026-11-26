//
//  CYLAnimatedItemColorRoleTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import CYLAnimatedItem

/**
 [EN] The color roles of `CYLAnimatedItemView`: a subclass registers a custom label as a THIRD role (after the title and the icon) with `register(_:)` only,
      and gets the one precedence chain (own `itemAppearance` > subclass-explicit > the stack's inherited `itemAppearance` > subclass built-in > the role's built-in)
      and the one dark-glass adaptation (only on drawn Liquid Glass with dark traits, never in light mode or flat).
 [CN] `CYLAnimatedItemView` 的颜色角色：子类只用 `register(_:)` 把自定义标签注册为第三个角色（在标题与图标之后），即获得唯一的优先级链
      （条目自己的 `itemAppearance` > 子类显式 > 堆叠视图继承的 `itemAppearance` > 子类内置 > 角色内置值）与唯一的深色玻璃调整
      （只在绘制液态玻璃且 trait 为深色时，浅色与扁平不调整）。
 */
final class CYLAnimatedItemColorRoleTests: XCTestCase {

    /// A subclass with a label of its own, declared as a color role; nothing else is plumbed. 有自己标签的子类，标签声明为颜色角色，没有其他处理。
    private final class LabelItem: CYLAnimatedItemView {
        let extraLabel = UILabel()

        override init(frame: CGRect) {
            super.init(frame: frame)
            addSubview(extraLabel)
            // The explicit color of the role comes from the badge text attributes of an `itemAppearance` (a stand-in for an element the appearance can set).
            register(CYLAnimatedItemColorRole(
                id: "test.extraLabel", kind: .title,
                explicitColor: { $0.badgeTextAttributes[.foregroundColor] as? UIColor },
                componentBuiltIn: { _, _ in UIColor(white: 0.8, alpha: 1) },
                apply: { item, resolved in (item as? LabelItem)?.extraLabel.textColor = resolved.color }))
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }
    }

    private let role = CYLAnimatedItemColorRole(id: "test.extraLabel", kind: .title, apply: { _, _ in })
    private var windows: [UIWindow] = []

    override func tearDown() {
        CYLAnimatedItemView.liquidGlassActiveOverride = nil
        windows.forEach { $0.isHidden = true }
        windows = []
        super.tearDown()
    }

    private func place(_ item: CYLAnimatedItemView, dark: Bool) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.overrideUserInterfaceStyle = dark ? .dark : .light
        window.isHidden = false
        windows.append(window)
        item.frame = CGRect(x: 0, y: 0, width: 200, height: 56)
        item.title = "Home"
        window.addSubview(item)
        item.layoutIfNeeded()
    }

    private func rgba(_ color: UIColor?, dark: Bool = false) -> [CGFloat] {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color?.resolvedColor(with: UITraitCollection(userInterfaceStyle: dark ? .dark : .light)).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a]
    }

    private func assertSame(_ actual: UIColor?, _ expected: UIColor, _ message: String, line: UInt = #line) {
        for (x, y) in zip(rgba(actual), rgba(expected)) { XCTAssertEqual(x, y, accuracy: 0.01, message, line: line) }
    }

    private func luminance(_ color: UIColor?) -> CGFloat {
        let c = rgba(color, dark: true)
        return CYLAnimatedItemContrast.relativeLuminance(red: c[0], green: c[1], blue: c[2])
    }

    private func appearance(badgeText color: UIColor) -> UITabBarItemAppearance {
        let appearance = UITabBarItemAppearance()
        appearance.normal.badgeTextAttributes = [.foregroundColor: color]
        return appearance
    }

    // MARK: - Precedence 优先级

    func testThirdRoleFollowsThePrecedenceChain() {
        let item = LabelItem(frame: .zero)
        place(item, dark: false)
        assertSame(item.extraLabel.textColor, UIColor(white: 0.8, alpha: 1), "the role's own built-in level")

        item.applyBuiltInColor(.orange, role: role)
        assertSame(item.extraLabel.textColor, .orange, "the subclass built-in beats the role's built-in")

        item.applyInheritedItemAppearance(appearance(badgeText: .green))
        assertSame(item.extraLabel.textColor, .green, "the stack's inherited appearance beats the subclass built-in")

        item.setSubclassColor(.blue, for: .normal, role: role)
        assertSame(item.extraLabel.textColor, .blue, "the subclass-explicit color beats the stack's")

        item.itemAppearance = appearance(badgeText: .yellow)
        assertSame(item.extraLabel.textColor, .yellow, "the item's own appearance beats the subclass-explicit color")

        item.itemAppearance = nil
        assertSame(item.extraLabel.textColor, .blue, "without an appearance the subclass-explicit color is back")
        item.setSubclassColor(nil, for: .normal, role: role)
        assertSame(item.extraLabel.textColor, .orange, "cleared: the subclass built-in")
        item.applyBuiltInColor(nil, role: role)
        assertSame(item.extraLabel.textColor, UIColor(white: 0.8, alpha: 1), "forgotten: the role's built-in")
    }

    func testRolesDoNotDisturbTheTitleAndTheIcon() {
        let item = LabelItem(frame: .zero)
        place(item, dark: false)
        item.setSubclassColor(.red, for: .normal, role: role)
        assertSame(item.titleLabel.textColor, .label, "the built-in title is untouched")
        assertSame(item.imageView.tintColor, .label, "the built-in icon is untouched")
        item.setSubclassTitleColor(.purple, for: .normal)
        assertSame(item.titleLabel.textColor, .purple, "the wrapper still drives the title role")
        assertSame(item.extraLabel.textColor, .red, "and not the custom role")
    }

    // MARK: - Dark glass 深色玻璃

    func testThirdRoleIsAdaptedOnDrawnDarkGlass() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let dark = UIColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x43 / 255, alpha: 1)
        let item = LabelItem(frame: .zero)
        item.itemBackgroundStyle = .liquidGlass
        place(item, dark: true)
        item.setSubclassColor(dark, for: .normal, role: role)
        XCTAssertGreaterThan(luminance(item.extraLabel.textColor), luminance(dark), "the custom label is lifted like the title")
        let reference = CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: nil, tintAlpha: nil)
        XCTAssertGreaterThanOrEqual(CYLAnimatedItemContrast.contrastRatio(luminance(item.extraLabel.textColor), reference),
                                    CYLAnimatedItemContrast.titleMinimumContrast - 0.05, "4.5:1, the kind of the role")
        XCTAssertEqual(rgba(item.extraLabel.textColor, dark: true), rgba(item.adaptedOnGlass(dark, kind: .title), dark: true),
                       "the same rule as the public function")
    }

    func testThirdRoleIsNotAdaptedInLightModeOrFlat() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let dark = UIColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x43 / 255, alpha: 1)

        let light = LabelItem(frame: .zero)
        light.itemBackgroundStyle = .liquidGlass
        place(light, dark: false)
        light.setSubclassColor(dark, for: .normal, role: role)
        assertSame(light.extraLabel.textColor, dark, "light mode: as it is")

        let flat = LabelItem(frame: .zero)
        place(flat, dark: true)
        flat.setSubclassColor(dark, for: .normal, role: role)
        assertSame(flat.extraLabel.textColor, dark, "flat: as it is")
    }

    func testRegisteringTheSameIdReplacesTheRole() {
        let item = LabelItem(frame: .zero)
        place(item, dark: false)
        item.setSubclassColor(.red, for: .normal, role: role)
        let replacement = CYLAnimatedItemColorRole(id: "test.extraLabel", kind: .title, apply: { item, resolved in
            (item as? LabelItem)?.extraLabel.textColor = resolved.color?.withAlphaComponent(0.5)
        })
        item.register(replacement)
        XCTAssertEqual(rgba(item.extraLabel.textColor)[3], 0.5, accuracy: 0.01, "the replaced apply runs; the stored colors are kept")
    }
}

// MARK: - One animation tint role for every engine 所有动画引擎共用一个动画着色角色

private final class EngineRecordingView: UIView {
    var calls: [UIColor?] = []

    @objc(cyl_applyAnimationViewTintColor:selected:)
    func applyTint(_ color: UIColor?, selected _: Bool) { calls.append(color) }
}

private final class EngineFactory: NSObject, CYLTabBarItemAnimationViewMaking {
    let view = EngineRecordingView()

    func animationView(url _: URL, size _: CGSize, contentMode _: UIView.ContentMode) -> UIView? { view }
    func player(for _: UIView?) -> CYLTabBarItemAnimationPlayer? { nil }
    func isAnimationView(_ view: UIView?) -> Bool { view === self.view }
}

/**
 [EN] The animation tint role does not branch on the engine: for Lottie, PAG, Rive, SVGA and GIF it resolves the same color, adapts it on drawn dark glass the same way
      and pushes the same color to the animation view. The engines differ only in the files' detectability (a one-color Lottie JSON or GIF is detected, the binary PAG,
      SVGA and Rive files are not), which the rendering mode `automatic` turns into the one policy: a one-color file is tinted like the icon, others keep their colors.
 [CN] 动画着色角色不按引擎分支：对 Lottie、PAG、Rive、SVGA 与 GIF，它解析出相同的颜色、以相同方式在深色玻璃上调整、并向动画视图推送相同的颜色。
      引擎之间只有文件可检测性的差别（单色 Lottie JSON 与 GIF 可检测，二进制的 PAG、SVGA、Rive 文件不可检测），渲染模式 `automatic` 把它变成唯一的策略：
      单色文件按图标着色，其他保持自己的颜色。
 */
final class CYLAnimatedItemAnimationTintRoleEngineTests: XCTestCase {

    private enum Engine: CaseIterable { case lottie, pag, rive, svga, gif }

    private var windows: [UIWindow] = []
    private var temporaryFiles: [URL] = []

    override func tearDown() {
        CYLAnimatedItemView.liquidGlassActiveOverride = nil
        windows.forEach { $0.isHidden = true }
        windows = []
        temporaryFiles.forEach { try? FileManager.default.removeItem(at: $0) }
        temporaryFiles = []
        super.tearDown()
    }

    private func temporaryFile(_ name: String, _ data: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("cyl-engine-tint-\(UUID().uuidString)-\(name)")
        try data.write(to: url)
        temporaryFiles.append(url)
        return url
    }

    /// A file of the engine; Lottie and GIF are ONE-color (detectable), the others are binary files the detector cannot read. 各引擎的文件。
    private func file(_ engine: Engine) throws -> URL {
        switch engine {
        case .lottie:
            let bundle = Bundle(for: CYLAnimatedItemAnimationTintRoleEngineTests.self)
            return try XCTUnwrap(bundle.url(forResource: "camera-one-color", withExtension: "json"), "the one-color Lottie fixture is in the test bundle")
        case .pag: return try temporaryFile("icon.pag", Data([0x50, 0x41, 0x47, 0x01, 0x02, 0x03, 0x04, 0x05]))
        case .rive: return try temporaryFile("icon.riv", Data("RIVE".utf8 + [0x07, 0x00]))
        case .svga: return try temporaryFile("icon.svga", Data([0x50, 0x4B, 0x03, 0x04, 0x00, 0x00]))
        case .gif:
            let size = CGSize(width: 10, height: 10)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = false
            let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
                UIColor.black.setFill()
                context.cgContext.fill(CGRect(origin: .zero, size: size))
            }
            let data = NSMutableData()
            let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, UTType.gif.identifier as CFString, 1, nil))
            CGImageDestinationAddImage(destination, try XCTUnwrap(image.cgImage), nil)
            XCTAssertTrue(CGImageDestinationFinalize(destination))
            return try temporaryFile("icon.gif", data as Data)
        }
    }

    private func makeItem(_ engine: Engine, mode: CYLAnimatedItemRenderingMode, dark: Bool, glass: Bool) throws -> (CYLAnimatedItemView, EngineFactory) {
        let factory = EngineFactory()
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 80, height: 49))
        if glass { item.itemBackgroundStyle = .liquidGlass }
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.overrideUserInterfaceStyle = dark ? .dark : .light
        window.isHidden = false
        windows.append(window)
        window.addSubview(item)
        item.iconSize = CGSize(width: 24, height: 24)
        item.animationRenderingMode = mode
        item.animationSource = factory
        item.animationURL = try file(engine)
        return (item, factory)
    }

    private func rgba(_ color: UIColor?) -> [CGFloat]? {
        guard let color else { return nil }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a]
    }

    func testAutomaticTintsOnlyAOneColorFileTheSameForEveryEngine() throws {
        for engine in Engine.allCases {
            let (item, factory) = try makeItem(engine, mode: .automatic, dark: false, glass: false)
            let last = try XCTUnwrap(factory.view.calls.last, "\(engine): something reached the view")
            if engine == .lottie || engine == .gif {
                XCTAssertEqual(rgba(last), rgba(item.imageView.tintColor), "\(engine): a one-color file is tinted like the icon")
            } else {
                XCTAssertNil(last, "\(engine): an undetectable file keeps its own colors")
            }
        }
    }

    func testTheTintRoleResolvesAdaptsAndPushesTheSameColorForEveryEngine() throws {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let dark = UIColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x43 / 255, alpha: 1)
        var pushed: [[CGFloat]] = []
        for engine in Engine.allCases {
            let (item, factory) = try makeItem(engine, mode: .alwaysTemplate, dark: true, glass: true)
            item.setSubclassIconColor(dark, for: .normal)
            let last = try XCTUnwrap(try XCTUnwrap(factory.view.calls.last, "\(engine): the tint reached the view"), "\(engine): a color")
            let adapted = item.adaptedOnGlass(dark, kind: .icon)
            XCTAssertEqual(rgba(last), rgba(adapted), "\(engine): the pushed color is the icon color adapted at 3:1")
            XCTAssertEqual(rgba(last), rgba(item.imageView.tintColor), "\(engine): the icon and the animation take one color")
            XCTAssertNotEqual(rgba(last), rgba(dark), "\(engine): the dark color was lifted on dark glass")
            pushed.append(try XCTUnwrap(rgba(last)))
        }
        for color in pushed {
            for (x, y) in zip(color, pushed[0]) { XCTAssertEqual(x, y, accuracy: 0.006, "every engine pushes the same color") }
        }
    }

    func testTheTintRoleIsNotAdaptedInLightModeForEveryEngine() throws {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let dark = UIColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x43 / 255, alpha: 1)
        for engine in Engine.allCases {
            let (item, factory) = try makeItem(engine, mode: .alwaysTemplate, dark: false, glass: true)
            item.setSubclassIconColor(dark, for: .normal)
            let last = try XCTUnwrap(try XCTUnwrap(factory.view.calls.last))
            XCTAssertEqual(rgba(last), rgba(dark), "\(engine): light mode: as it is")
        }
    }

    func testAFixedAnimationTintIsAdaptedOnGlassOnlyNotOnADarkFlatFill() throws {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let blue = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
        let (flat, flatFactory) = try makeItem(.lottie, mode: .alwaysTemplate, dark: true, glass: false)
        flat.itemBackgroundColor = UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
        flat.animationTint = "#0000FF"
        XCTAssertEqual(rgba(try XCTUnwrap(try XCTUnwrap(flatFactory.view.calls.last))), rgba(blue), "flat fill: the fixed tint is as it is (glass-only)")
        let (glass, glassFactory) = try makeItem(.lottie, mode: .alwaysTemplate, dark: true, glass: true)
        glass.animationTint = "#0000FF"
        XCTAssertNotEqual(rgba(try XCTUnwrap(try XCTUnwrap(glassFactory.view.calls.last))), rgba(blue), "drawn glass: the fixed tint is lifted")
    }
}
