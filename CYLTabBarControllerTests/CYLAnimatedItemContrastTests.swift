//
//  CYLAnimatedItemContrastTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import XCTest
@testable import CYLAnimatedItem

/**
 [EN] The dark-glass contrast rule (`CYLAnimatedItemContrast`), the pure function behind the explicit title, icon and animation tint
      colors of `CYLAnimatedItemView` on drawn dark Liquid Glass; the same cases as Android (`CYLAnimatedItemContrastTest.kt`),
      HarmonyOS (`CYLAnimatedItemContrast.test.ets`) and the mini program (`cyl_animated_item_contrast.test.js`).
 [CN] 深色玻璃对比度规则（`CYLAnimatedItemContrast`），即 `CYLAnimatedItemView` 在确实绘制的深色液态玻璃上调整显式标题、图标与动画着色的纯函数；
      用例与 Android（`CYLAnimatedItemContrastTest.kt`）、HarmonyOS（`CYLAnimatedItemContrast.test.ets`）和小程序（`cyl_animated_item_contrast.test.js`）相同。
 */
final class CYLAnimatedItemContrastTests: XCTestCase {

    private let grey = UIColor(red: 0x3C / 255, green: 0x3C / 255, blue: 0x43 / 255, alpha: 1)

    private func rgba(_ color: UIColor) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        XCTAssertTrue(color.getRed(&r, green: &g, blue: &b, alpha: &a))
        return (r, g, b, a)
    }

    private func luminance(_ color: UIColor) -> CGFloat {
        let c = rgba(color)
        return CYLAnimatedItemContrast.relativeLuminance(red: c.r, green: c.g, blue: c.b)
    }

    private func contrast(_ color: UIColor, tint: UIColor? = nil, tintAlpha: CGFloat? = nil) -> CGFloat {
        CYLAnimatedItemContrast.contrastRatio(luminance(color), CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: tint, tintAlpha: tintAlpha))
    }

    private func hue(_ color: UIColor) -> CGFloat {
        let c = rgba(color)
        return CYLAnimatedItemContrast.hslFromRGB(red: c.r, green: c.g, blue: c.b).hue
    }

    func testTheConstantsAreTheSharedOnes() {
        XCTAssertEqual(CYLAnimatedItemContrast.iconMinimumContrast, 3)
        XCTAssertEqual(CYLAnimatedItemContrast.titleMinimumContrast, 4.5)
        XCTAssertEqual(CYLAnimatedItemContrast.frostedWhiteAlpha, 0.14)
        XCTAssertEqual(CYLAnimatedItemContrast.defaultTintShare, 0.75)
        XCTAssertEqual(CYLAnimatedItemContrast.lightnessStep, 0.005)
    }

    func testDarkTextOnTheDefaultDarkGlassBecomesLighterAndPasses4Point5() {
        XCTAssertLessThan(contrast(grey), 4.5)
        let lifted = CYLAnimatedItemContrast.adjustedTitle(grey, glassTint: nil, tintAlpha: nil)
        XCTAssertGreaterThanOrEqual(contrast(lifted), 4.5 - 0.01)
        XCTAssertGreaterThan(luminance(lifted), luminance(grey))
        XCTAssertEqual(rgba(lifted).a, 1)
        XCTAssertEqual(hue(lifted), hue(grey), accuracy: 0.02)
    }

    func testIconTintPassesThreeAndTitleNeedsMore() {
        let dark = UIColor(red: 0x1B / 255, green: 0x5E / 255, blue: 0x63 / 255, alpha: 1)
        let icon = CYLAnimatedItemContrast.adjustedIcon(dark, glassTint: nil, tintAlpha: nil)
        let title = CYLAnimatedItemContrast.adjustedTitle(dark, glassTint: nil, tintAlpha: nil)
        XCTAssertGreaterThanOrEqual(contrast(icon), 3 - 0.01)
        XCTAssertGreaterThanOrEqual(contrast(title), 4.5 - 0.01)
        XCTAssertGreaterThanOrEqual(luminance(title), luminance(icon))
    }

    func testAPassingLightColorAndWhiteAreUnchanged() {
        let light = UIColor(red: 0xE0 / 255, green: 0xE0 / 255, blue: 0xE0 / 255, alpha: 1)
        XCTAssertTrue(CYLAnimatedItemContrast.adjustedTitle(light, glassTint: nil, tintAlpha: nil) === light)
        let white = UIColor.white
        XCTAssertTrue(CYLAnimatedItemContrast.adjustedTitle(white, glassTint: nil, tintAlpha: nil) === white)
        // [EN] White on white glass cannot pass: white is the cap. [CN] 白色玻璃上的白色无法达标：白色是上限。
        let capped = rgba(CYLAnimatedItemContrast.adjustedIcon(white, glassTint: .white, tintAlpha: 1))
        XCTAssertEqual(capped.r, 1)
        XCTAssertEqual(capped.g, 1)
        XCTAssertEqual(capped.b, 1)
    }

    func testAlphaAndHueAreKeptAndTheResultNeverExceedsWhite() {
        let teal = UIColor(red: 0x10 / 255, green: 0x3A / 255, blue: 0x40 / 255, alpha: 0x80 / 255)
        let lifted = CYLAnimatedItemContrast.adjustedTitle(teal, glassTint: nil, tintAlpha: nil)
        XCTAssertEqual(rgba(lifted).a, 0x80 / 255, accuracy: 0.001)
        XCTAssertEqual(hue(lifted), hue(teal), accuracy: 0.02)
        XCTAssertGreaterThanOrEqual(contrast(lifted), 4.5 - 0.01)
        let black = CYLAnimatedItemContrast.adjustedTitle(.black, glassTint: nil, tintAlpha: nil)
        XCTAssertGreaterThanOrEqual(contrast(black), 4.49)
        let c = rgba(black)
        XCTAssertLessThanOrEqual(max(c.r, c.g, c.b), 1)
    }

    func testTheRenderedGlassFloorLiftsTheConfigFileGreyToTheRealGlassContrast() {
        let model = CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: nil, tintAlpha: nil)
        let rendered = CYLAnimatedItemContrast.renderedGlassReferenceLuminance(glassTint: nil, tintAlpha: nil)
        XCTAssertGreaterThan(rendered, model, "the floor is above the 0.14 model")
        XCTAssertEqual(rendered, CYLAnimatedItemContrast.relativeLuminance(red: 0.28, green: 0.28, blue: 0.28), accuracy: 0.0001)
        let lifted = CYLAnimatedItemContrast.adjustedTitle(grey, glassTint: nil, tintAlpha: nil)
        XCTAssertGreaterThanOrEqual(CYLAnimatedItemContrast.contrastRatio(luminance(lifted), rendered), 4.5 - 0.01, "4.5:1 on the rendered glass")
        // A bright explicit tint is never judged darker than its own model.
        let bright = UIColor.white
        XCTAssertGreaterThanOrEqual(CYLAnimatedItemContrast.renderedGlassReferenceLuminance(glassTint: bright, tintAlpha: 1),
                                    CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: bright, tintAlpha: 1))
    }

    func testDeterministic() {
        let first = rgba(CYLAnimatedItemContrast.adjustedTitle(grey, glassTint: nil, tintAlpha: nil))
        let second = rgba(CYLAnimatedItemContrast.adjustedTitle(grey, glassTint: nil, tintAlpha: nil))
        XCTAssertEqual(first.r, second.r)
        XCTAssertEqual(first.g, second.g)
        XCTAssertEqual(first.b, second.b)
        XCTAssertEqual(first.a, second.a)
    }

    func testNilOrClearTintIsTheFrostedDefault() {
        let frosted = CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: nil, tintAlpha: nil)
        XCTAssertEqual(CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: .clear, tintAlpha: nil), frosted, "alpha 0 is the frosted default")
        XCTAssertEqual(CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: UIColor(red: 1, green: 0, blue: 0, alpha: 0), tintAlpha: 0.5), frosted)
        XCTAssertEqual(luminance(UIColor(red: 0x24 / 255, green: 0x24 / 255, blue: 0x24 / 255, alpha: 1)), frosted, accuracy: 0.01)
    }

    func testAnExplicitTintChangesTheReference() {
        let frosted = CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: nil, tintAlpha: nil)
        let bright = UIColor(red: 0x80 / 255, green: 0x80 / 255, blue: 0x80 / 255, alpha: 1)
        let reference = CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: bright, tintAlpha: nil)
        XCTAssertGreaterThan(reference, frosted)
        // [EN] Alpha 1 at the default share 0.75: the color x 0.75 (0x80 x 0.75 = 0x60). [CN] 透明度 1，默认占比 0.75：颜色 x 0.75。
        XCTAssertEqual(luminance(UIColor(red: 0x60 / 255, green: 0x60 / 255, blue: 0x60 / 255, alpha: 1)), reference, accuracy: 0.002)
        XCTAssertGreaterThan(CYLAnimatedItemContrast.glassReferenceLuminance(glassTint: bright, tintAlpha: 1), reference)
        // [EN] The same color needs a lighter result on the brighter glass. [CN] 同一颜色在更亮的玻璃上需要更亮的结果。
        XCTAssertGreaterThan(luminance(CYLAnimatedItemContrast.adjustedTitle(grey, glassTint: bright, tintAlpha: nil)),
                             luminance(CYLAnimatedItemContrast.adjustedTitle(grey, glassTint: nil, tintAlpha: nil)))
    }

    func testADynamicColorIsUnchanged() {
        let dynamic = UIColor { traits in traits.userInterfaceStyle == .dark ? self.grey : .black }
        XCTAssertFalse(CYLAnimatedItemContrast.isStatic(dynamic))
        XCTAssertTrue(CYLAnimatedItemContrast.adjustedTitle(dynamic, glassTint: nil, tintAlpha: nil) === dynamic)
        let label = UIColor.label
        XCTAssertTrue(CYLAnimatedItemContrast.adjustedIcon(label, glassTint: nil, tintAlpha: nil) === label)
        XCTAssertTrue(CYLAnimatedItemContrast.isStatic(grey))
    }
}
