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
        assertSame(item.titleLabel.textColor, item.adaptedOnGlass(item.tintColor.resolvedColor(with: item.traitCollection), kind: .title), "selected: the inherited tint resolved like normal, then adapted on drawn dark glass like every built-in", dark: true)
        // Both are plain colors resolved with the item's traits (the same function), not dynamic ones.
        XCTAssertFalse(item.titleLabel.textColor.isEqual(UIColor.label), "a resolved color, not the dynamic label")
    }

    func testTheExplicitColorsAreNotAdaptedInLightModeOrOnFlatWithoutAFill() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let dark = UIColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x43 / 255, alpha: 1)
        let light = ChannelTag(frame: .zero)
        light.itemBackgroundStyle = .liquidGlass
        place(light, dark: false)
        light.setSubclassTitleColor(dark, for: .normal)
        assertSame(light.titleLabel.textColor, dark, "light mode: as set")
        // Step 2 (flat extension): a flat item WITHOUT a fill is still as set; one with a fill is adapted (see the flat tests below).
        let flat = ChannelTag(frame: .zero)
        place(flat, dark: true)
        flat.setSubclassTitleColor(dark, for: .normal)
        assertSame(flat.titleLabel.textColor, dark, "flat without a fill: as set", dark: true)
    }

    // MARK: - Dark flat 深色扁平

    private func flatItem(fill: UIColor?, dark: Bool = true) -> ChannelTag {
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        let item = ChannelTag(frame: .zero)
        item.itemBackgroundColor = fill
        place(item, dark: dark)
        return item
    }

    private func ratio(_ color: UIColor?, against reference: CGFloat) -> CGFloat {
        CYLAnimatedItemContrast.contrastRatio(luminance(color), reference)
    }

    private let flatDarkText = UIColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x43 / 255, alpha: 1)

    func testDarkFlatWithAnOpaqueFillIsAdaptedAgainstTheFill() {
        let fill = UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
        let item = flatItem(fill: fill)
        item.setSubclassTitleColor(flatDarkText, for: .normal)
        item.setSubclassIconColor(flatDarkText, for: .normal)
        let reference = CYLAnimatedItemContrast.flatReferenceLuminance(fill: fill, traits: item.traitCollection)
        XCTAssertLessThan(ratio(flatDarkText, against: reference), 1.6, "before: about 1.5:1")
        XCTAssertGreaterThanOrEqual(ratio(item.titleLabel.textColor, against: reference), CYLAnimatedItemContrast.titleMinimumContrast - 0.05)
        XCTAssertGreaterThanOrEqual(ratio(item.imageView.tintColor, against: reference), CYLAnimatedItemContrast.iconMinimumContrast - 0.05)
        assertSame(item.adaptedForContrast(flatDarkText, kind: .title), item.titleLabel.textColor.resolvedColor(with: item.traitCollection), "the public rule is the same", dark: true)
        assertSame(item.adaptedOnGlass(flatDarkText, kind: .title), item.adaptedForContrast(flatDarkText, kind: .title), "the old name forwards", dark: true)
        XCTAssertFalse(item.drawsLiquidGlass)
    }

    func testDarkFlatDefaultLabelPassesUnchanged() {
        let item = flatItem(fill: UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1))
        assertSame(item.titleLabel.textColor, .white, "the default dark label is as it is", dark: true)
    }

    func testDarkFlatWithAHalfAlphaWhiteFillIsJudgedAgainstTheFillOverBlackAndLiftsAsFarAsWhiteGoes() {
        let fill = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        let item = flatItem(fill: fill)
        item.setSubclassTitleColor(flatDarkText, for: .normal)
        let reference = CYLAnimatedItemContrast.flatReferenceLuminance(fill: fill, traits: item.traitCollection)
        XCTAssertEqual(reference, CYLAnimatedItemContrast.relativeLuminance(red: 0.5, green: 0.5, blue: 0.5), accuracy: 0.001, "white at 0.5 over black is 0.5 grey")
        // The limit: a lift-only rule (it only makes a color lighter here) cannot exceed white's contrast on a 0.5 grey: 1.05 / (0.214 + 0.05) = about 3.98:1, so 4.5:1 is NOT reachable.
        // The title is therefore lifted as far as it can go (white-ish), not to 4.5:1.
        // 仅提亮的规则不可能超过白色在 0.5 灰上的对比度（约 3.98:1），因此 4.5:1 无法达到；标题被提亮到上限（接近白色）。
        let before = ratio(flatDarkText, against: reference)
        let after = ratio(item.titleLabel.textColor, against: reference)
        XCTAssertGreaterThanOrEqual(after, 3.9, "lifted to the maximum possible")
        XCTAssertLessThanOrEqual(after, 4.0, "white is the cap")
        XCTAssertGreaterThanOrEqual(after, before, "never worse than the unlifted color")
        XCTAssertGreaterThan(luminance(item.titleLabel.textColor), luminance(flatDarkText))
    }

    func testDarkFlatWithAHalfAlphaDarkFillReachesTheTitleMinimum() {
        // White at 0.15 alpha over black is a dark grey (0.15): 4.5:1 IS reachable there.
        let fill = UIColor(red: 1, green: 1, blue: 1, alpha: 0.15)
        let item = flatItem(fill: fill)
        item.setSubclassTitleColor(flatDarkText, for: .normal)
        item.setSubclassIconColor(flatDarkText, for: .normal)
        let reference = CYLAnimatedItemContrast.flatReferenceLuminance(fill: fill, traits: item.traitCollection)
        XCTAssertEqual(reference, CYLAnimatedItemContrast.relativeLuminance(red: 0.15, green: 0.15, blue: 0.15), accuracy: 0.001, "white at 0.15 over black")
        XCTAssertLessThan(ratio(flatDarkText, against: reference), CYLAnimatedItemContrast.titleMinimumContrast, "before: below 4.5:1")
        XCTAssertGreaterThanOrEqual(ratio(item.titleLabel.textColor, against: reference), CYLAnimatedItemContrast.titleMinimumContrast - 0.05)
        XCTAssertGreaterThanOrEqual(ratio(item.imageView.tintColor, against: reference), CYLAnimatedItemContrast.iconMinimumContrast - 0.05)
    }

    func testDarkFlatWithNoFillOrAClearFillIsNotAdapted() {
        let none = flatItem(fill: nil)
        none.setSubclassTitleColor(flatDarkText, for: .normal)
        none.setSubclassIconColor(flatDarkText, for: .normal)
        assertSame(none.titleLabel.textColor, flatDarkText, "no fill: as set (the item cannot know what is behind it)", dark: true)
        assertSame(none.imageView.tintColor, flatDarkText, "no fill: the icon as set", dark: true)
        assertSame(none.adaptedForContrast(flatDarkText, kind: .title), flatDarkText, "no fill: the public rule returns it", dark: true)
        let clear = flatItem(fill: .clear)
        clear.setSubclassTitleColor(flatDarkText, for: .normal)
        assertSame(clear.titleLabel.textColor, flatDarkText, "a clear fill is no fill", dark: true)
    }

    func testDarkFlatTakesTheViewsOwnBackgroundColorAsTheFill() {
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        let item = ChannelTag(frame: .zero)
        item.backgroundColor = UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
        place(item, dark: true)
        item.setSubclassTitleColor(flatDarkText, for: .normal)
        XCTAssertGreaterThan(luminance(item.titleLabel.textColor), luminance(flatDarkText), "the fill the item draws (no item background in use)")
    }

    func testLightFlatIsNotAdapted() {
        let item = flatItem(fill: .black, dark: false)
        item.setSubclassTitleColor(flatDarkText, for: .normal)
        assertSame(item.titleLabel.textColor, flatDarkText, "light mode: as set")
    }

    func testDarkFlatDisabledAndDynamicColorsAreNotAdapted() {
        let item = flatItem(fill: UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1))
        assertSame(item.adaptedForContrast(.label, kind: .title), .label, "dynamic: as it is", dark: true)
        item.applyTitleTintColor(flatDarkText)
        item.isEnabled = false
        item.layoutIfNeeded()
        assertSame(item.titleLabel.textColor, flatDarkText, "the disabled look is never adapted", dark: true)
    }

    func testGlassIsUnchangedAndTheFloorStaysGlassOnly() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let item = ChannelTag(frame: .zero)
        item.itemBackgroundStyle = .liquidGlass
        item.itemBackgroundColor = UIColor(white: 0.1, alpha: 1)
        place(item, dark: true)
        item.setSubclassTitleColor(flatDarkText, for: .normal)
        let glass = CYLAnimatedItemContrast.renderedGlassReferenceLuminance(glassTint: item.itemBackgroundColor, tintAlpha: nil)
        let model = CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: item.itemBackgroundColor, tintAlpha: nil)
        XCTAssertGreaterThan(glass, model, "the 0.28 floor applies on glass")
        XCTAssertGreaterThanOrEqual(ratio(item.titleLabel.textColor, against: glass), CYLAnimatedItemContrast.titleMinimumContrast - 0.05)
        let flatReference = CYLAnimatedItemContrast.flatReferenceLuminance(fill: item.itemBackgroundColor, traits: item.traitCollection)
        XCTAssertLessThan(flatReference, glass, "the flat reference has no floor")
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
        // Step 2: not drawn = flat WITH a fill, so the rule judges against the teal fill (no glass floor); this color already passes there, so it stays as set.
        assertSame(item.titleLabel.textColor, dark, "not drawn: the title already passes against the flat teal fill", dark: true)
        assertSame(item.imageView.tintColor, dark, "not drawn: the icon already passes against the flat teal fill", dark: true)
        assertSame(item.adaptedOnGlass(dark, kind: .title), dark, "not drawn: adaptedOnGlass returns it", dark: true)
        item.itemBackgroundColor = .black
        XCTAssertGreaterThan(luminance(item.titleLabel.textColor), luminance(dark), "not drawn, a black flat fill: adapted against the fill, not the glass")
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

    // MARK: - Real SF Symbols 真实的 SF Symbol

    private func symbolItem(dark: Bool = true, glass: Bool = false, fill: UIColor? = nil, image: UIImage? = UIImage(systemName: "star")) -> ChannelTag {
        CYLAnimatedItemView.liquidGlassActiveOverride = glass
        let item = ChannelTag(frame: .zero)
        item.imageView.image = image
        if glass { item.itemBackgroundStyle = .liquidGlass }
        item.itemBackgroundColor = fill
        place(item, dark: dark)
        return item
    }

    func testASystemSymbolWithABuiltInDarkIconColorIsLiftedOnDrawnDarkGlass() {
        let item = symbolItem(glass: true)
        XCTAssertEqual(item.imageView.image?.renderingMode, .automatic, "a system symbol is a template by default")
        item.applyIconTintColor(flatDarkText)
        XCTAssertTrue(item.drawsLiquidGlass)
        let reference = CYLAnimatedItemContrast.renderedGlassReferenceLuminance(glassTint: nil, tintAlpha: nil)
        XCTAssertGreaterThan(luminance(item.imageView.tintColor), luminance(flatDarkText), "the star's tint is lifted")
        XCTAssertGreaterThanOrEqual(ratio(item.imageView.tintColor, against: reference), CYLAnimatedItemContrast.iconMinimumContrast - 0.05)
    }

    func testASystemSymbolOnADarkFlatFillIsLifted() {
        let fill = UIColor(red: 28 / 255, green: 28 / 255, blue: 30 / 255, alpha: 1)
        let item = symbolItem(fill: fill)
        item.applyIconTintColor(flatDarkText)
        let reference = CYLAnimatedItemContrast.flatReferenceLuminance(fill: fill, traits: item.traitCollection)
        XCTAssertGreaterThan(luminance(item.imageView.tintColor), luminance(flatDarkText))
        XCTAssertGreaterThanOrEqual(ratio(item.imageView.tintColor, against: reference), CYLAnimatedItemContrast.iconMinimumContrast - 0.05)
    }

    func testASystemSymbolOnFlatWithNoFillIsUnchanged() {
        let item = symbolItem()
        item.applyIconTintColor(flatDarkText)
        assertSame(item.imageView.tintColor, flatDarkText, "no fill: as set", dark: true)
    }

    func testASystemSymbolInLightModeIsUnchanged() {
        let glass = symbolItem(dark: false, glass: true)
        glass.applyIconTintColor(flatDarkText)
        assertSame(glass.imageView.tintColor, flatDarkText, "light glass: as set")
        let flat = symbolItem(dark: false, fill: .black)
        flat.applyIconTintColor(flatDarkText)
        assertSame(flat.imageView.tintColor, flatDarkText, "light flat: as set")
    }

    func testASystemSymbolWithAnExplicitIconColorIsAdaptedAndAnExplicitDynamicColorIsNot() {
        let item = symbolItem(glass: true)
        item.setSubclassIconColor(flatDarkText, for: .normal)
        XCTAssertGreaterThan(luminance(item.imageView.tintColor), luminance(flatDarkText), "an explicit static color is adapted on drawn dark glass")
        item.setSubclassIconColor(.label, for: .normal)
        assertSame(item.imageView.tintColor, .label, "an explicit dynamic color is never adapted", dark: true)
    }

    func testAPaletteSymbolAndAnOriginalImageStillGetTheRoleColorInTintColor() {
        // UIKit ignores `tintColor` for a palette/multicolor symbol and for an `.alwaysOriginal` image: the item still writes the role color to `imageView.tintColor`
        // (that is all it controls), but the rendered pixels are not affected. Only the tintColor value is asserted here.
        // UIKit 对调色板/多色符号与 `.alwaysOriginal` 图片忽略 tintColor：条目仍把角色颜色写入 `imageView.tintColor`（条目能控制的仅此），但渲染像素不受影响；这里只断言 tintColor 的值。
        let palette = UIImage(systemName: "star.fill")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(paletteColors: [.red, .blue]))
        let original = UIImage(systemName: "star")?.withRenderingMode(.alwaysOriginal)
        for (name, image) in [("palette", palette), ("alwaysOriginal", original)] {
            let item = symbolItem(glass: true, image: image)
            item.applyIconTintColor(flatDarkText)
            XCTAssertGreaterThan(luminance(item.imageView.tintColor), luminance(flatDarkText), "\(name): the role color is written (lifted)")
        }
    }
}
