//
//  CYLAnimatedItemSubclassChannelTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import XCTest
@testable import CYLAnimatedItem

/**
 [EN] The subclass-explicit channel of `CYLAnimatedItemView` (`setSubclassTitleColor(_:for:)`, `setSubclassIconColor(_:for:)`), `applyTitleTintColor(_:)`,
      `adaptedOnGlass(_:kind:)`, the default glass tint and the options a tag turns on. A tag button is such a subclass.
 [CN] `CYLAnimatedItemView` 的子类显式通道（`setSubclassTitleColor(_:for:)`、`setSubclassIconColor(_:for:)`）、`applyTitleTintColor(_:)`、
      `adaptedOnGlass(_:kind:)`、默认玻璃着色以及标签打开的选项。标签按钮就是这样的子类。
 */
final class CYLAnimatedItemSubclassChannelTests: XCTestCase {

    /// A subclass as a tag button is: it only talks to the item through the public channels. 只通过公开通道与条目交互的子类。
    private final class ChannelTag: CYLAnimatedItemView {}

    private var windows: [UIWindow] = []

    override func tearDown() {
        CYLAnimatedItemView.liquidGlassActiveOverride = nil
        windows.forEach { $0.isHidden = true }
        windows = []
        super.tearDown()
    }

    private func window(dark: Bool) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.overrideUserInterfaceStyle = dark ? .dark : .light
        window.isHidden = false
        windows.append(window)
        return window
    }

    private func place(_ item: CYLAnimatedItemView, dark: Bool = false) {
        item.frame = CGRect(x: 0, y: 0, width: 200, height: 56)
        item.title = "Home"
        window(dark: dark).addSubview(item)
        item.layoutIfNeeded()
    }

    private func rgba(_ color: UIColor?, dark: Bool = false) -> [CGFloat] {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color?.resolvedColor(with: UITraitCollection(userInterfaceStyle: dark ? .dark : .light)).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a]
    }

    private func assertSame(_ actual: UIColor?, _ expected: UIColor, _ message: String, dark: Bool = false, line: UInt = #line) {
        for (x, y) in zip(rgba(actual, dark: dark), rgba(expected, dark: dark)) { XCTAssertEqual(x, y, accuracy: 0.01, message, line: line) }
    }

    private func luminance(_ color: UIColor?) -> CGFloat {
        let c = rgba(color, dark: true)
        return CYLAnimatedItemContrast.relativeLuminance(red: c[0], green: c[1], blue: c[2])
    }

    private func appearance(title: UIColor? = nil, icon: UIColor? = nil, font: UIFont? = nil) -> UITabBarItemAppearance {
        let appearance = UITabBarItemAppearance()
        var attributes: [NSAttributedString.Key: Any] = [:]
        if let title { attributes[.foregroundColor] = title }
        if let font { attributes[.font] = font }
        appearance.normal.titleTextAttributes = attributes
        appearance.normal.iconColor = icon
        return appearance
    }

    // MARK: - Precedence 优先级

    func testTheFiveLevelsOfTheTitleColorInOrder() {
        let item = ChannelTag(frame: .zero)
        place(item)
        // 5: the component's built-in.
        assertSame(item.titleLabel.textColor, UIColor.label.resolvedColor(with: item.traitCollection), "component built-in")
        // 4: the subclass built-in beats the component's built-in.
        item.applyTitleTintColor(.orange)
        assertSame(item.titleLabel.textColor, .orange, "subclass built-in")
        // 3: the stack's inherited appearance beats the subclass built-in.
        item.applyInheritedItemAppearance(appearance(title: .green))
        XCTAssertTrue(item.isItemAppearanceInherited)
        assertSame(item.titleLabel.textColor, .green, "stack-inherited")
        // 2: the subclass-explicit color beats the inherited appearance.
        item.setSubclassTitleColor(.purple, for: .normal)
        assertSame(item.titleLabel.textColor, .purple, "subclass-explicit")
        XCTAssertTrue(item.isItemAppearanceInherited, "the channel never changes the inheritance")
        // 1: the item's own appearance beats the subclass-explicit color.
        item.itemAppearance = appearance(title: .red)
        XCTAssertFalse(item.isItemAppearanceInherited)
        assertSame(item.titleLabel.textColor, .red, "own appearance")
        // Back down: dropping each level shows the next one.
        item.itemAppearance = nil
        assertSame(item.titleLabel.textColor, .purple, "own removed: subclass-explicit")
        item.setSubclassTitleColor(nil, for: .normal)
        assertSame(item.titleLabel.textColor, .orange, "explicit cleared: subclass built-in")
        item.applyTitleTintColor(nil)
        assertSame(item.titleLabel.textColor, UIColor.label.resolvedColor(with: item.traitCollection), "all cleared: component built-in")
    }

    func testTheFiveLevelsOfTheIconColorInOrder() {
        let item = ChannelTag(frame: .zero)
        place(item)
        item.applyIconTintColor(.orange)
        assertSame(item.imageView.tintColor, .orange, "subclass built-in")
        item.applyInheritedItemAppearance(appearance(icon: .green))
        assertSame(item.imageView.tintColor, .green, "stack-inherited beats the subclass built-in")
        item.setSubclassIconColor(.purple, for: .normal)
        assertSame(item.imageView.tintColor, .purple, "subclass-explicit beats the inherited appearance")
        item.itemAppearance = appearance(icon: .red)
        assertSame(item.imageView.tintColor, .red, "own appearance wins")
        item.itemAppearance = nil
        assertSame(item.imageView.tintColor, .purple, "own removed")
        item.setSubclassIconColor(nil, for: .normal)
        assertSame(item.imageView.tintColor, .orange, "explicit cleared: subclass built-in")
    }

    func testTheChannelIsPerState() {
        let item = ChannelTag(frame: .zero)
        place(item)
        item.setSubclassTitleColor(.red, for: .selected)
        item.setSubclassIconColor(.blue, for: .disabled)
        assertSame(item.titleLabel.textColor, UIColor.label.resolvedColor(with: item.traitCollection), "normal: untouched")
        item.isSelected = true
        assertSame(item.titleLabel.textColor, .red, "selected")
        item.isSelected = false
        item.isEnabled = false
        assertSame(item.imageView.tintColor, .blue, "disabled icon")
    }

    func testASubclassInsideAStackKeepsTheInheritanceAndTheStacksFontsAndIconColors() {
        let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        window(dark: false).addSubview(stack)
        let font = UIFont.italicSystemFont(ofSize: 21)
        stack.itemAppearance = appearance(title: nil, icon: .green, font: font)
        let item = ChannelTag(frame: .zero)
        stack.dispatchesItemTaps = false
        stack.append(item, action: nil, spacingBefore: 0)
        XCTAssertTrue(item.isItemAppearanceInherited)
        item.setSubclassTitleColor(.purple, for: .normal)
        item.setSubclassTitleColor(.purple, for: .selected)
        item.applyTitleTintColor(.orange)
        item.applyIconTintColor(.orange)
        XCTAssertTrue(item.isItemAppearanceInherited, "still inherited")
        XCTAssertEqual(item.titleLabel.font, font, "the stack's font survives")
        assertSame(item.imageView.tintColor, .green, "the stack's icon color survives (it beats the subclass built-in)")
        assertSame(item.titleLabel.textColor, .purple, "the subclass-explicit title color shows")
        stack.itemAppearance = appearance(title: nil, icon: .blue, font: font)
        XCTAssertTrue(item.isItemAppearanceInherited)
        assertSame(item.imageView.tintColor, .blue, "a new stack appearance still reaches the item")
    }

    // MARK: - Dark glass 深色玻璃

    func testSubclassExplicitColorsAreAdaptedOnDrawnDarkGlass() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let dark = UIColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x43 / 255, alpha: 1)
        let item = ChannelTag(frame: .zero)
        item.itemBackgroundStyle = .liquidGlass
        place(item, dark: true)
        item.setSubclassTitleColor(dark, for: .normal)
        item.setSubclassIconColor(dark, for: .normal)
        XCTAssertGreaterThan(luminance(item.titleLabel.textColor), luminance(dark), "the title is lifted (4.5:1)")
        XCTAssertGreaterThan(luminance(item.imageView.tintColor), luminance(dark), "the icon is lifted (3:1)")
        let reference = CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: nil, tintAlpha: nil)
        XCTAssertGreaterThanOrEqual(CYLAnimatedItemContrast.contrastRatio(luminance(item.titleLabel.textColor), reference),
                                    CYLAnimatedItemContrast.titleMinimumContrast - 0.05)
        XCTAssertGreaterThanOrEqual(CYLAnimatedItemContrast.contrastRatio(luminance(item.imageView.tintColor), reference),
                                    CYLAnimatedItemContrast.iconMinimumContrast - 0.05)
    }

    func testTheSubclassBuiltInTitleAndIconColorsGoThroughTheSameResolutionAndAdaptation() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let dark = UIColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x43 / 255, alpha: 1)
        let item = ChannelTag(frame: .zero)
        item.itemBackgroundStyle = .liquidGlass
        place(item, dark: true)
        item.applyTitleTintColor(dark)
        item.applyIconTintColor(dark)
        XCTAssertGreaterThan(luminance(item.titleLabel.textColor), luminance(dark), "a static built-in title is adapted on drawn dark glass")
        XCTAssertGreaterThan(luminance(item.imageView.tintColor), luminance(dark), "a static built-in icon is adapted too")
        XCTAssertGreaterThan(CYLAnimatedItemContrast.contrastRatio(luminance(item.titleLabel.textColor),
            CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: nil, tintAlpha: nil)), CYLAnimatedItemContrast.titleMinimumContrast - 0.01)
    }

    func testTheComponentBuiltInNormalAndSelectedTitlesShareOnePath() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let item = CYLAnimatedItemView(frame: .zero)
        item.itemBackgroundStyle = .liquidGlass
        place(item, dark: true)
        assertSame(item.titleLabel.textColor, .white, "normal: the dark label color, unchanged by the rule", dark: true)
        item.isSelected = true
        item.layoutIfNeeded()
        assertSame(item.titleLabel.textColor, item.tintColor.resolvedColor(with: item.traitCollection), "selected: the inherited tint resolved like normal", dark: true)
        // Both are plain colors resolved with the item's traits (the same function), not dynamic ones.
        XCTAssertFalse(item.titleLabel.textColor.isEqual(UIColor.label), "a resolved color, not the dynamic label")
    }

    func testTheExplicitColorsAreNotAdaptedInLightModeOrOnFlat() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let dark = UIColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x43 / 255, alpha: 1)
        let light = ChannelTag(frame: .zero)
        light.itemBackgroundStyle = .liquidGlass
        place(light, dark: false)
        light.setSubclassTitleColor(dark, for: .normal)
        assertSame(light.titleLabel.textColor, dark, "light mode: as set")
        let flat = ChannelTag(frame: .zero)
        flat.itemBackgroundColor = .black
        place(flat, dark: true)
        flat.setSubclassTitleColor(dark, for: .normal)
        assertSame(flat.titleLabel.textColor, dark, "flat: as set")
    }

    func testAdaptedOnGlassIsThePublicRuleOfTheItem() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let dark = UIColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x43 / 255, alpha: 1)
        let item = ChannelTag(frame: .zero)
        item.itemBackgroundStyle = .liquidGlass
        place(item, dark: true)
        let title = item.adaptedOnGlass(dark, kind: .title)
        let icon = item.adaptedOnGlass(dark, kind: .icon)
        XCTAssertGreaterThan(luminance(title), luminance(dark))
        XCTAssertGreaterThanOrEqual(luminance(title), luminance(icon), "4.5:1 lifts at least as much as 3:1")
        assertSame(item.adaptedOnGlass(.label, kind: .title), .label, "a dynamic color is returned as it is", dark: true)
        let plain = ChannelTag(frame: .zero)
        place(plain, dark: true)
        assertSame(plain.adaptedOnGlass(dark, kind: .title), dark, "no item background in use: as it is")
        let lightItem = ChannelTag(frame: .zero)
        lightItem.itemBackgroundStyle = .liquidGlass
        place(lightItem, dark: false)
        assertSame(lightItem.adaptedOnGlass(dark, kind: .title), dark, "light mode: as it is")
    }

    // MARK: - Default tint 默认着色

    func testTheNilTintDefaultIsZeroPointOneLightAndZeroPointZeroFourDark() throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("UIGlassEffect needs iOS 26") }
        XCTAssertEqual(CYLAnimatedItemView.defaultGlassTintAlphaLight, 0.10)
        XCTAssertEqual(CYLAnimatedItemView.defaultGlassTintAlphaDark, 0.04)
        for dark in [false, true] {
            CYLAnimatedItemView.liquidGlassActiveOverride = true
            let item = ChannelTag(frame: .zero)
            item.itemBackgroundStyle = .liquidGlass
            place(item, dark: dark)
            item.itemGlassTintAlpha = 1
            let glass = try XCTUnwrap(item.itemLiquidGlassView as? UIVisualEffectView)
            let tint = (glass.effect as? UIGlassEffect)?.tintColor
            XCTAssertEqual(rgba(tint, dark: dark)[3], dark ? 0.04 : 0.10, accuracy: 0.005, dark ? "dark" : "light")
            item.itemGlassTintAlpha = nil
            let again = (try XCTUnwrap(item.itemLiquidGlassView as? UIVisualEffectView).effect as? UIGlassEffect)?.tintColor
            XCTAssertEqual(rgba(again, dark: dark)[3], dark ? 0.04 : 0.10, accuracy: 0.005, "the share does not touch the default")
        }
    }

    // MARK: - Options 选项

    func testTheNewOptionsAreOffOrNilByDefault() {
        let item = ChannelTag(frame: .zero)
        XCTAssertNil(item.itemHighlightedBackgroundColor)
        XCTAssertNil(item.itemDisabledAnimationAlpha)
        XCTAssertFalse(item.showsLastFrameWhenSelected)
        XCTAssertFalse(item.showsOutlineWhenIncreaseContrast)
        XCTAssertFalse(item.respectsReduceMotion)
        XCTAssertFalse(item.disabledWinsImage)
        XCTAssertFalse(item.isItemAppearanceInherited)
    }

    func testTheHighlightedBackgroundShowsWhileHighlightedAndEnabledOnly() {
        let item = ChannelTag(frame: .zero)
        place(item)
        item.itemBackgroundColor = .white
        item.itemHighlightedBackgroundColor = .red
        item.layoutIfNeeded()
        assertSame(item.backgroundColor, .white, "idle")
        item.isHighlighted = true
        assertSame(item.backgroundColor, .red, "pressed")
        item.isEnabled = false
        assertSame(item.backgroundColor, .white, "disabled: not pressed")
        item.isEnabled = true
        item.isHighlighted = false
        assertSame(item.backgroundColor, .white, "released")
    }

    func testDisabledWinsKeepsTheNormalImageForADisabledSelectedItem() {
        let normal = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { _ in }
        let selected = UIGraphicsImageRenderer(size: CGSize(width: 5, height: 5)).image { _ in }
        let item = ChannelTag(frame: .zero)
        place(item)
        item.image = normal
        item.selectedImage = selected
        item.isSelected = true
        item.isEnabled = false
        XCTAssertTrue(item.imageView.image === selected, "default: the selected image wins")
        item.disabledWinsImage = true
        XCTAssertTrue(item.imageView.image === normal, "disabled wins: the normal image")
        item.isEnabled = true
        XCTAssertTrue(item.imageView.image === selected, "enabled again")
    }

    func testTheResolvedInsetAndEngineForwarders() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        XCTAssertEqual(CYLAnimatedItemView.resolvedContentHorizontalInset(nil, style: .liquidGlass), cylAnimatedItemLiquidGlassContentInset)
        XCTAssertEqual(CYLAnimatedItemView.resolvedContentHorizontalInset(nil, style: .flat), 0)
        XCTAssertEqual(CYLAnimatedItemView.resolvedContentHorizontalInset(3, style: .liquidGlass), 3)
        XCTAssertEqual(CYLAnimatedItemView.isAnimationEngineAvailable, NSClassFromString("CYLTabBarItemAnimationFactory") != nil)
    }

    // MARK: - Guards: glass drawn, flat, glass asked for but not drawn 玻璃已绘制、扁平、请求了玻璃但未绘制

    func testDrawsLiquidGlassAndDrawsFlatBackgroundFollowTheResolvedStyle() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let glass = ChannelTag(frame: .zero)
        glass.itemBackgroundStyle = .liquidGlass
        XCTAssertTrue(glass.drawsLiquidGlass)
        XCTAssertFalse(glass.drawsFlatBackground)
        let flat = ChannelTag(frame: .zero)
        XCTAssertFalse(flat.drawsLiquidGlass)
        XCTAssertTrue(flat.drawsFlatBackground)
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        XCTAssertFalse(glass.drawsLiquidGlass, "glass asked for, system draws none")
        XCTAssertTrue(glass.drawsFlatBackground)
        XCTAssertEqual(glass.resolvedItemBackgroundStyle, .flat)
    }

    func testGlassAskedForButNotDrawnAdaptsNothingAndKeepsTheFlatColor() {
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        let dark = UIColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x43 / 255, alpha: 1)
        let item = ChannelTag(frame: .zero)
        item.itemBackgroundStyle = .liquidGlass
        item.itemBackgroundColor = .systemTeal
        place(item, dark: true)
        item.setSubclassTitleColor(dark, for: .normal)
        item.setSubclassIconColor(dark, for: .normal)
        assertSame(item.titleLabel.textColor, dark, "not drawn: the title is as set", dark: true)
        assertSame(item.imageView.tintColor, dark, "not drawn: the icon is as set", dark: true)
        assertSame(item.adaptedOnGlass(dark, kind: .title), dark, "not drawn: adaptedOnGlass returns it", dark: true)
        XCTAssertNil(item.itemLiquidGlassView)
        XCTAssertNotNil(item.backgroundColor, "the flat color is drawn")
        // The system starts to draw glass: the same colors are adapted without being set again.
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        item.itemBackgroundColor = .systemIndigo
        XCTAssertTrue(item.drawsLiquidGlass)
        XCTAssertGreaterThan(luminance(item.titleLabel.textColor), luminance(dark), "drawn: adapted")
    }

    func testTheIncreaseContrastOutlineIsOnlyDrawnWhenTheOptionIsOn() {
        let item = ChannelTag(frame: .zero)
        place(item)
        item.itemBackgroundColor = .white
        item.itemBorderWidth = 0
        item.setSubclassTitleColor(.red, for: .normal)
        XCTAssertEqual(item.layer.borderWidth, 0, "option off: no outline")
        item.showsOutlineWhenIncreaseContrast = true
        if UIAccessibility.isDarkerSystemColorsEnabled || item.traitCollection.accessibilityContrast == .high {
            XCTAssertEqual(item.layer.borderWidth, 1)
        } else {
            XCTAssertEqual(item.layer.borderWidth, 0, "Increase Contrast is off: no outline")
        }
    }
}
