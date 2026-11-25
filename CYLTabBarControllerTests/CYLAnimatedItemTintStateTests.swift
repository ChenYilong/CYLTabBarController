//
//  CYLAnimatedItemTintStateTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import ObjectiveC
import XCTest
import CYLAnimatedItem

/**
 * [EN] An animation view that records the tint calls it gets. [CN] 记录所收到着色调用的动画视图。
 */
private final class CYLRecordingTintView: UIView {
    var stateCalls: [(UIColor?, Bool)] = []
    var plainCalls = 0

    @objc(cyl_applyAnimationViewTintColor:)
    func applyTint(_: UIColor?) {
        plainCalls += 1
    }

    @objc(cyl_applyAnimationViewTintColor:selected:)
    func applyTint(_ color: UIColor?, selected: Bool) {
        stateCalls.append((color, selected))
    }
}

/**
 * [EN] An item whose animation view is the recording view. [CN] 动画视图为记录视图的 item。
 */
private final class CYLRecordingItemView: CYLAnimatedItemView {
    let recordingView = CYLRecordingTintView()

    override var animationView: UIView? { recordingView }
}

/**
 * [EN] The tint hook with the item's state (2026-11-19: a fixed tint only on the unselected tab).
 * [CN] 带 item 状态的着色钩子（2026-11-19：固定着色只用于未选中的 Tab）。
 */
final class CYLAnimatedItemTintStateTests: XCTestCase {

    /// [EN] The state-aware hook wins over the plain one and gets the item's selected state.
    /// [CN] 带状态的钩子优先于普通钩子，并收到 item 的选中状态。
    func testIconTintPassesTheSelectedState() {
        let item = CYLRecordingItemView(frame: CGRect(x: 0, y: 0, width: 80, height: 49))
        item.animationTint = "title"
        item.isSelected = false
        item.applyIconTintColor(.red)
        item.isSelected = true
        item.applyIconTintColor(.blue)
        let calls = item.recordingView.stateCalls
        XCTAssertEqual(item.recordingView.plainCalls, 0, "the state-aware hook is preferred")
        XCTAssertTrue(calls.contains { $0.0 == .red && !$0.1 }, "unselected red reached the view")
        XCTAssertTrue(calls.contains { $0.0 == .blue && $0.1 }, "selected blue reached the view")
    }
}

/**
 * [EN] The item background of CYLAnimatedItemView (flat or Liquid Glass, corner radius, border): the rules of `itemCornerRadius`, the capsule
 *      constant, the border, the resolved style. [CN] CYLAnimatedItemView 的条目背景（扁平或液态玻璃、圆角、边框）：`itemCornerRadius` 的规则、胶囊常量、边框、
 *      实际样式。
 */
final class CYLAnimatedItemBackgroundTests: XCTestCase {

    private func makeItem(height: CGFloat = 56) -> CYLAnimatedItemView {
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 200, height: height))
        item.title = "Home"
        return item
    }

    override func tearDown() {
        CYLAnimatedItemView.liquidGlassActiveOverride = nil
        super.tearDown()
    }

    func testFlatUnsetRadiusIsSquare() {
        let item = makeItem()
        item.itemBackgroundColor = .systemBlue
        item.layoutIfNeeded()
        XCTAssertEqual(item.layer.cornerRadius, 0)
        XCTAssertNil(item.itemLiquidGlassView)
    }

    func testLiquidGlassUnsetRadiusIsACapsule() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let item = makeItem()
        item.itemBackgroundStyle = .liquidGlass
        item.layoutIfNeeded()
        XCTAssertEqual(item.resolvedItemBackgroundStyle, .liquidGlass)
        XCTAssertEqual(item.layer.cornerRadius, 28, accuracy: 0.01)
        XCTAssertNotNil(item.itemLiquidGlassView)
    }

    func testASetRadiusIsPointsAndZeroIsSquare() {
        let item = makeItem()
        item.itemBackgroundColor = .systemBlue
        item.itemCornerRadius = 12
        item.layoutIfNeeded()
        XCTAssertEqual(item.layer.cornerRadius, 12)
        item.itemCornerRadius = 0
        XCTAssertEqual(item.layer.cornerRadius, 0)
        item.itemCornerRadius = 1000.5
        item.layoutIfNeeded()
        XCTAssertEqual(item.layer.cornerRadius, 28, accuracy: 0.01, "limited to half the height")
    }

    func testTheCapsuleConstantIsHalfTheHeightAndFollowsTheSize() {
        let item = makeItem()
        item.itemBackgroundColor = .systemBlue
        item.itemCornerRadius = CYLAnimatedItemCornerRadiusCapsule
        item.layoutIfNeeded()
        XCTAssertEqual(item.layer.cornerRadius, 28, accuracy: 0.01)
        item.frame.size.height = 40
        item.layoutIfNeeded()
        XCTAssertEqual(item.layer.cornerRadius, 20, accuracy: 0.01, "follows a resize")
    }

    func testTheBorderIsDrawn() {
        let item = makeItem()
        item.itemBorderWidth = 2
        item.itemBorderColor = .red
        item.layoutIfNeeded()
        XCTAssertEqual(item.layer.borderWidth, 2)
        XCTAssertNotNil(item.layer.borderColor)
    }

    func testTheResolvedStyleIsFlatWhereTheSystemDrawsNoGlass() {
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        let item = makeItem()
        item.itemBackgroundStyle = .liquidGlass
        XCTAssertEqual(item.resolvedItemBackgroundStyle, .flat)
        XCTAssertNil(item.itemLiquidGlassView)
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        XCTAssertEqual(item.resolvedItemBackgroundStyle, .liquidGlass)
    }

    func testAGlassWithoutAColorHasTheDefaultFrostedTint() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIGlassEffect needs iOS 26")
        }
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let item = makeItem()
        item.itemBackgroundStyle = .liquidGlass
        item.layoutIfNeeded()
        let glass = try XCTUnwrap(item.itemLiquidGlassView as? UIVisualEffectView)
        var alpha: CGFloat = -1
        (glass.effect as? UIGlassEffect)?.tintColor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            .getRed(nil, green: nil, blue: nil, alpha: &alpha)
        XCTAssertEqual(alpha, 0.5, accuracy: 0.01, "no color set: the default frosted tint, so one style parameter is visible")
    }

    func testAClearColorMeansNoColorAndGetsTheDefaultFrostedTint() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIGlassEffect needs iOS 26")
        }
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let item = makeItem()
        item.itemBackgroundStyle = .liquidGlass
        item.itemBackgroundColor = .clear
        item.itemBorderWidth = 1
        item.itemCornerRadius = 12
        item.layoutIfNeeded()
        let glass = try XCTUnwrap(item.itemLiquidGlassView as? UIVisualEffectView)
        var alpha: CGFloat = -1
        (glass.effect as? UIGlassEffect)?.tintColor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            .getRed(nil, green: nil, blue: nil, alpha: &alpha)
        XCTAssertEqual(alpha, 0.5, accuracy: 0.01, "UIColor.clear is no color: the default frosted tint, like nil")
        XCTAssertEqual(item.layer.borderWidth, 1, "the border and the corner radius stay as set")
        XCTAssertEqual(item.layer.cornerRadius, 12)
        // A color with a real alpha still tints at 75% of it.
        item.itemBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.4)
        item.layoutIfNeeded()
        (glass.effect as? UIGlassEffect)?.tintColor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            .getRed(nil, green: nil, blue: nil, alpha: &alpha)
        XCTAssertEqual(alpha, 0.3, accuracy: 0.01)
    }

    func testGlassTintAlphaOneKeepsTheColorAsItIs() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIGlassEffect needs iOS 26")
        }
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let item = makeItem()
        item.itemBackgroundStyle = .liquidGlass
        item.itemBackgroundColor = UIColor.systemTeal
        item.layoutIfNeeded()
        let glass = try XCTUnwrap(item.itemLiquidGlassView as? UIVisualEffectView)
        func tintAlpha() -> CGFloat {
            var alpha: CGFloat = -1
            (glass.effect as? UIGlassEffect)?.tintColor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
                .getRed(nil, green: nil, blue: nil, alpha: &alpha)
            return alpha
        }
        XCTAssertEqual(tintAlpha(), 0.75, accuracy: 0.01, "the default share")
        item.itemGlassTintAlpha = 1
        item.layoutIfNeeded()
        XCTAssertEqual(tintAlpha(), 1, accuracy: 0.01, "1: the color as it is, still glass")
        item.itemGlassTintAlpha = nil
        item.layoutIfNeeded()
        XCTAssertEqual(tintAlpha(), 0.75, accuracy: 0.01)
    }

    func testSettingTheSameValueAgainDoesNotRequestALayout() {
        let item = makeItem()
        item.itemCornerRadius = 8
        item.layoutIfNeeded()
        item.itemCornerRadius = 8
        XCTAssertFalse(item.layer.needsLayout(), "an unchanged value does nothing (no layout loop when set inside layoutSubviews)")
    }

    func testTheStackViewHasTheSameRules() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 200, height: 80))
        stack.itemBackgroundColor = .systemBlue
        stack.layoutIfNeeded()
        XCTAssertEqual(stack.layer.cornerRadius, 0, "flat, unset: square")
        stack.itemBackgroundStyle = .liquidGlass
        stack.layoutIfNeeded()
        XCTAssertEqual(stack.layer.cornerRadius, 40, accuracy: 0.01, "glass, unset: a capsule")
        stack.itemCornerRadius = 12
        XCTAssertEqual(stack.layer.cornerRadius, 12)
        stack.itemCornerRadius = CYLAnimatedItemCornerRadiusCapsule
        XCTAssertEqual(stack.layer.cornerRadius, 40, accuracy: 0.01)
        XCTAssertNotNil(stack.itemLiquidGlassView)
    }

    // MARK: - itemContentHorizontalInset 内容左右内缩

    func testUnsetContentInsetIsZeroOnFlatAndTheConstantOnActiveGlass() {
        let flat = makeItem()
        XCTAssertNil(flat.itemContentHorizontalInset)
        XCTAssertEqual(flat.resolvedItemContentHorizontalInset, 0)
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let glass = makeItem()
        glass.itemBackgroundStyle = .liquidGlass
        XCTAssertEqual(CYLAnimatedItemLiquidGlassContentInset, 14)
        XCTAssertEqual(glass.resolvedItemContentHorizontalInset, CYLAnimatedItemLiquidGlassContentInset)
        XCTAssertNil(glass.itemContentHorizontalInsetNumber, "unset stays unset for the bridges")
    }

    func testUnsetContentInsetIsZeroWhenGlassIsRequestedButNotDrawn() {
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        let item = makeItem()
        item.itemBackgroundStyle = .liquidGlass
        XCTAssertEqual(item.resolvedItemBackgroundStyle, .flat)
        XCTAssertEqual(item.resolvedItemContentHorizontalInset, 0)
    }

    func testAnExplicitContentInsetWins() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let glass = makeItem()
        glass.itemBackgroundStyle = .liquidGlass
        glass.itemContentHorizontalInset = 0
        XCTAssertEqual(glass.resolvedItemContentHorizontalInset, 0, "0 on glass is explicit")
        XCTAssertEqual(glass.itemContentHorizontalInsetNumber, 0)
        let flat = makeItem()
        flat.itemContentHorizontalInset = 20
        XCTAssertEqual(flat.resolvedItemContentHorizontalInset, 20)
        flat.itemContentHorizontalInsetNumber = nil
        XCTAssertEqual(flat.resolvedItemContentHorizontalInset, 0)
    }

    func testWrapContentWidthGrowsByTwiceTheInsetOnGlass() {
        let flat = makeItem()
        let flatWidth = flat.intrinsicContentSize.width
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let glass = makeItem()
        glass.itemBackgroundStyle = .liquidGlass
        XCTAssertEqual(glass.intrinsicContentSize.width, flatWidth + 2 * CYLAnimatedItemLiquidGlassContentInset, accuracy: 1)
        glass.itemContentHorizontalInset = 20
        XCTAssertEqual(glass.intrinsicContentSize.width, flatWidth + 40, accuracy: 1, "the setter changes the size")
    }

    func testStackViewMarginsAddTheInsetLeftAndRightOnly() {
        func margins(_ stack: CYLAnimatedItemStackView) -> (leading: CGFloat, top: CGFloat) {
            func constant(_ attribute: NSLayoutConstraint.Attribute) -> CGFloat {
                stack.constraints.first { ($0.firstItem as? UIView) === stack.stackView && $0.firstAttribute == attribute }?.constant ?? -1
            }
            return (constant(.leading), constant(.top))
        }
        let flat = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        flat.itemBackgroundStyle = .flat
        let flatMargins = margins(flat)
        XCTAssertEqual(flatMargins.leading, flat.contentMargin)
        XCTAssertEqual(flatMargins.top, flat.contentMargin)
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let glass = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        glass.itemBackgroundStyle = .liquidGlass
        XCTAssertEqual(margins(glass).leading, flatMargins.leading + CYLAnimatedItemLiquidGlassContentInset, "the margins follow the style")
        XCTAssertEqual(margins(glass).top, flatMargins.top, "top and bottom unchanged")
        glass.itemContentHorizontalInset = 0
        XCTAssertEqual(margins(glass).leading, flatMargins.leading)
        XCTAssertEqual(glass.contentMargin, 16, "the default of contentMargin is unchanged")
    }
}


/**
 * [EN] A factory that returns one recording view for any file, so the tint that reaches the animation view is observable without an animation
 *      engine. [CN] 对任何文件都返回同一个记录视图的工厂，使到达动画视图的着色无需动画引擎即可观察。
 */
private final class CYLRecordingViewFactory: NSObject, CYLTabBarItemAnimationViewMaking {
    let view = CYLRecordingTintView()

    func animationView(url _: URL, size _: CGSize, contentMode _: UIView.ContentMode) -> UIView? { view }
    func player(for _: UIView?) -> CYLTabBarItemAnimationPlayer? { nil }
    func isAnimationView(_ view: UIView?) -> Bool { view === self.view }
}

/**
 * [EN] THE tint truth table (identical on every platform) on iOS: the color that reaches the animation view for each row (nil = the tint is
 *      removed). Needs no animation engine: the item's animation view is a recording view.
 * [CN] 着色真值表（各平台一致）在 iOS 上的表现：每一行到达动画视图的颜色（nil 表示移除着色）。不需要动画引擎：条目的动画视图是记录视图。
 */
final class CYLAnimatedItemTintTableTests: XCTestCase {

    private struct Row {
        let name: String
        var tint: String?
        var darkTint: String?
        var selected = false
        var dark = false
        var normal: UIColor?
        var selectedColor: UIColor?
        var expected: UIColor?
        /// The expected color is a built-in of the item (v2): the label color unselected, the item's tintColor selected.
        var builtIn = false
    }

    private let normal = UIColor(red: 0.1, green: 0.2, blue: 0.3, alpha: 1)
    private let selectedColor = UIColor(red: 0.9, green: 0.8, blue: 0.7, alpha: 1)
    private let fixed = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    private let darkFixed = UIColor(red: 0, green: 0, blue: 1, alpha: 1)

    private var file: URL!

    override func setUpWithError() throws {
        file = FileManager.default.temporaryDirectory.appendingPathComponent("cyl-item-tint-\(UUID().uuidString).json")
        try "{}".write(to: file, atomically: true, encoding: .utf8)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: file)
        super.tearDown()
    }

    private func components(_ color: UIColor?) -> [CGFloat]? {
        guard let color else { return nil }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a]
    }

    private func assertColor(_ actual: UIColor?, _ expected: UIColor?, _ message: String, line: UInt = #line) {
        guard let a = components(actual), let e = components(expected) else {
            XCTAssertEqual(actual == nil, expected == nil, message, line: line)
            return
        }
        for (x, y) in zip(a, e) { XCTAssertEqual(x, y, accuracy: 0.01, message, line: line) }
    }

    private func appearance(normal: UIColor?, selected: UIColor?) -> UITabBarItemAppearance {
        let appearance = UITabBarItemAppearance()
        appearance.normal.iconColor = normal
        appearance.selected.iconColor = selected
        return appearance
    }

    private var windows: [UIWindow] = []

    /// The item sits in a window, whose style (light / dark) its traits follow.
    private func makeItem(_ factory: CYLRecordingViewFactory, dark: Bool = false) -> CYLAnimatedItemView {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        window.overrideUserInterfaceStyle = dark ? .dark : .light
        window.isHidden = false
        windows.append(window)
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 80, height: 49))
        window.addSubview(item)
        item.iconSize = CGSize(width: 24, height: 24)
        item.animationSource = factory
        return item
    }

    /// The built-in icon color of the item's current state, resolved with its own traits.
    private func builtInColor(_ item: CYLAnimatedItemView) -> UIColor {
        (item.isSelected ? (item.tintColor ?? .systemBlue) : UIColor.label).resolvedColor(with: item.traitCollection)
    }

    /// The color of the last call that reached the view; `.some(nil)` is a removal.
    private func last(_ factory: CYLRecordingViewFactory) -> UIColor?? {
        factory.view.stateCalls.last.map { $0.0 }
    }

    func testTheTruthTableRows() {
        let rows: [Row] = [
            Row(name: "unset, unselected", normal: normal, expected: nil),
            Row(name: "unset, selected", selected: true, normal: normal, selectedColor: selectedColor, expected: nil),
            Row(name: "invalid text is unset", tint: "banana", normal: normal, expected: nil),
            Row(name: "invalid hex (5 digits) is unset", tint: "#12345", normal: normal, expected: nil),
            Row(name: "title unselected: the normal color", tint: "title", normal: normal, expected: normal),
            Row(name: "title unselected, no normal color: the built-in label color", tint: "title", selectedColor: selectedColor, builtIn: true),
            Row(name: "title selected: the selected color", tint: "title", selected: true, normal: normal, selectedColor: selectedColor, expected: selectedColor),
            Row(name: "title selected, only the selected color", tint: "title", selected: true, selectedColor: selectedColor, expected: selectedColor),
            Row(name: "title selected, only the normal color: the built-in tint color (v2, no fallback to normal)", tint: "title", selected: true, normal: normal, builtIn: true),
            Row(name: "title selected, no icon color at all: the built-in tint color", tint: "title", selected: true, builtIn: true),
            Row(name: "title unselected, no icon color at all: the built-in label color", tint: "title", builtIn: true),
            Row(name: "title in dark mode follows the colors", tint: "title", dark: true, normal: normal, expected: normal),
            Row(name: "fixed unselected", tint: "#00FF00", normal: normal, expected: fixed),
            Row(name: "fixed unselected, no icon colors", tint: "#00FF00", expected: fixed),
            Row(name: "fixed unselected, dark, darkTint", tint: "#00FF00", darkTint: "#0000FF", dark: true, normal: normal, expected: darkFixed),
            Row(name: "fixed unselected, light, darkTint ignored", tint: "#00FF00", darkTint: "#0000FF", normal: normal, expected: fixed),
            Row(name: "fixed unselected, dark, no darkTint", tint: "#00FF00", dark: true, expected: fixed),
            Row(name: "fixed unselected, dark, invalid darkTint", tint: "#00FF00", darkTint: "blue", dark: true, expected: fixed),
            Row(name: "fixed selected: the selected color", tint: "#00FF00", selected: true, normal: normal, selectedColor: selectedColor, expected: selectedColor),
            Row(name: "fixed selected, only the normal color: the fixed color (the table)", tint: "#00FF00", selected: true, normal: normal, expected: fixed),
            Row(name: "fixed selected, no icon colors: the fixed color", tint: "#00FF00", selected: true, expected: fixed),
            Row(name: "fixed selected, no icon colors, dark: the darkTint", tint: "#00FF00", darkTint: "#0000FF", selected: true, dark: true, expected: darkFixed),
            Row(name: "fixed selected with a color, dark: the icon color", tint: "#00FF00", darkTint: "#0000FF", selected: true, dark: true, selectedColor: selectedColor, expected: selectedColor),
            Row(name: "8 digits are RRGGBBAA", tint: "#FF000080", expected: UIColor(red: 1, green: 0, blue: 0, alpha: 128 / 255)),
        ]
        for row in rows {
            // Set before the file loads, then (below) after; both must give the same color.
            let before = CYLRecordingViewFactory()
            let early = makeItem(before, dark: row.dark)
            if row.normal != nil || row.selectedColor != nil { early.itemAppearance = appearance(normal: row.normal, selected: row.selectedColor) }
            early.animationTint = row.tint
            early.animationDarkTint = row.darkTint
            early.isSelected = row.selected
            early.animationURL = file
            XCTAssertNotNil(early.animationView, row.name)
            if row.normal == nil && row.selectedColor == nil {
                // No itemAppearance at all: a host that tints by hand (applyIconTintColor) is not part of this row.
                early.itemAppearance = appearance(normal: nil, selected: nil)
            }
            guard let got = last(before) else {
                XCTFail("\(row.name): nothing reached the view")
                continue
            }
            assertColor(got, row.builtIn ? builtInColor(early) : row.expected, "\(row.name) (set before load)")

            let after = CYLRecordingViewFactory()
            let late = makeItem(after, dark: row.dark)
            late.itemAppearance = appearance(normal: row.normal, selected: row.selectedColor)
            late.isSelected = row.selected
            late.animationURL = file
            late.animationTint = row.tint
            late.animationDarkTint = row.darkTint
            guard let gotLate = last(after) else {
                XCTFail("\(row.name): nothing reached the view (set after load)")
                continue
            }
            assertColor(gotLate, row.builtIn ? builtInColor(late) : row.expected, "\(row.name) (set after load)")
        }
    }

    /// (c) Clearing animationTint removes the tint, whenever it was set.
    func testClearingRemovesTheTint() {
        let factory = CYLRecordingViewFactory()
        let item = makeItem(factory)
        item.itemAppearance = appearance(normal: normal, selected: selectedColor)
        item.animationURL = file
        item.animationTint = "title"
        assertColor(last(factory) ?? nil, normal, "title tints")
        item.animationTint = nil
        guard let cleared = last(factory) else { return XCTFail("clearing reached the view") }
        XCTAssertNil(cleared, "cleared: no stale color")
        item.animationTint = "#00FF00"
        assertColor(last(factory) ?? nil, fixed, "set again")
        item.animationTint = "not a color"
        XCTAssertNil(last(factory) ?? nil, "an invalid text is unset")
    }

    /// v2: "title" with no explicit icon color takes the built-in color (it never goes without one).
    func testTitleWithoutAnyExplicitIconColorTakesTheBuiltInColor() {
        let factory = CYLRecordingViewFactory()
        let item = makeItem(factory)
        item.animationURL = file
        item.animationTint = "title"
        item.itemAppearance = appearance(normal: normal, selected: nil)
        assertColor(last(factory) ?? nil, normal, "explicit")
        item.itemAppearance = appearance(normal: nil, selected: nil)
        assertColor(last(factory) ?? nil, builtInColor(item), "no explicit color: the built-in label color")
    }

    /// v2: selected without an explicit selected color is the inherited tint (not the normal color); explicit colors win; deselecting follows.
    func testSelectionFollowsTheTableWithTheBuiltInTintAsFallback() {
        let factory = CYLRecordingViewFactory()
        let item = makeItem(factory)
        item.itemAppearance = appearance(normal: normal, selected: nil)
        item.animationURL = file
        item.animationTint = "title"
        item.isSelected = true
        assertColor(last(factory) ?? nil, builtInColor(item), "selected, no explicit selected color: the built-in tint")
        item.itemAppearance = appearance(normal: normal, selected: selectedColor)
        assertColor(last(factory) ?? nil, selectedColor, "selected color")
        item.isSelected = false
        assertColor(last(factory) ?? nil, normal, "deselected")
    }

    /// (d) A fixed tint's dark color applies in dark mode and again on a trait change.
    func testDarkTintFollowsATraitChange() {
        let factory = CYLRecordingViewFactory()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        let item = makeItem(factory)
        window.addSubview(item)
        window.isHidden = false
        item.animationURL = file
        item.animationTint = "#00FF00"
        item.animationDarkTint = "#0000FF"
        window.overrideUserInterfaceStyle = .light
        item.itemAppearance = appearance(normal: normal, selected: nil)
        assertColor(last(factory) ?? nil, fixed, "light")
        window.overrideUserInterfaceStyle = .dark
        item.layoutIfNeeded()
        assertColor(last(factory) ?? nil, darkFixed, "dark after the trait change, without any other call")
        window.overrideUserInterfaceStyle = .light
        item.layoutIfNeeded()
        assertColor(last(factory) ?? nil, fixed, "light again")
    }

    /// The `tint` option of the URL applies when the property is unset; the property overrides it.
    func testThePropertyOverridesTheURLOption() {
        let url = URL(string: file.absoluteString + "#tint=title")!
        let factory = CYLRecordingViewFactory()
        let item = makeItem(factory)
        item.itemAppearance = appearance(normal: normal, selected: nil)
        item.animationURL = url
        assertColor(last(factory) ?? nil, normal, "the URL's title")
        item.animationTint = "#00FF00"
        assertColor(last(factory) ?? nil, fixed, "the property wins")
        item.animationTint = nil
        assertColor(last(factory) ?? nil, normal, "back to the URL's option")
    }
}
