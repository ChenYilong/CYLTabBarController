//
//  CYLAnimatedItemContrast.swift
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
//  [EN] The dark-glass contrast rule of CYLAnimatedItemView, the same rule as Android (`CYLAnimatedItemContrast.kt`), HarmonyOS
//       (`CYLAnimatedItemContrast.ets`) and the mini program (`cyl_animated_item_contrast.js`).
//  [CN] CYLAnimatedItemView 的深色玻璃对比度规则，与 Android（`CYLAnimatedItemContrast.kt`）、HarmonyOS（`CYLAnimatedItemContrast.ets`）
//       和小程序（`cyl_animated_item_contrast.js`）相同。
//

import UIKit

#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
/**
 [EN] The dark-glass contrast rule of an item: an EXPLICIT, static title or icon color that is too dark for dark Liquid Glass is lifted,
      keeping hue, saturation and alpha, until it has the minimum contrast against the glass (title text `titleMinimumContrast` 4.5, icon
      and animation tint `iconMinimumContrast` 3). The glass is judged over black (ONE reference): the default frosted tint (`glassTint`
      nil or fully transparent) is white at `frostedWhiteAlpha` 0.14; an explicit tint is its color times its alpha times the tint alpha
      (`defaultTintShare` 0.75 when nil). HSL lightness rises in `lightnessStep` 0.005 steps and never goes above white. A dynamic color
      (light and dark resolutions differ) is returned as it is. Dark glass only: light glass is NOT adapted. Pure and deterministic;
      `CYLAnimatedItemView` calls it only where glass is really drawn, in Dark Mode, for a color the app set (built-in colors and flat
      items are untouched). A subclass with its own explicit colors (a ClassifyMenu tag) calls it the same way.
 [CN] 条目的深色玻璃对比度规则：显式的静态标题或图标颜色在深色液态玻璃上过暗时，保持色相、饱和度与透明度，提高亮度直到与玻璃的对比度达到最小值
      （标题文字 `titleMinimumContrast` 4.5，图标与动画着色 `iconMinimumContrast` 3）。玻璃以黑色为底判断（唯一参照）：默认磨砂着色（`glassTint`
      为 nil 或完全透明）为白色 `frostedWhiteAlpha` 0.14；显式着色为其颜色乘以透明度再乘以着色透明度（nil 时为 `defaultTintShare` 0.75）。HSL 亮度
      每步 `lightnessStep` 0.005 上升，不超过白色。动态颜色（浅色与深色解析结果不同）原样返回。只处理深色玻璃：浅色玻璃不调整。纯函数、确定性；
      `CYLAnimatedItemView` 只在玻璃确实绘制、深色模式、颜色由应用设置时调用（内置颜色与扁平条目不受影响）。有自己显式颜色的子类
      （ClassifyMenu 的标签）以同样方式调用。
 */
public enum CYLAnimatedItemContrast {

    /** [EN] The least contrast of an icon or animation tint (3:1). [CN] 图标或动画着色的最小对比度（3:1）。 */
    public static let iconMinimumContrast: CGFloat = 3

    /** [EN] The least contrast of title text (4.5:1). [CN] 标题文字的最小对比度（4.5:1）。 */
    public static let titleMinimumContrast: CGFloat = 4.5

    /** [EN] The white share of the default frosted glass in Dark Mode; over black it is about #242424. [CN] 深色模式默认磨砂玻璃的白色占比；黑底上约为 #242424。 */
    public static let frostedWhiteAlpha: CGFloat = 0.14

    /** [EN] The share of an explicit tint's alpha that tints the glass when the tint alpha is nil (`itemGlassTintAlpha`). [CN] 着色透明度为 nil 时，显式着色透明度中用于玻璃着色的占比（`itemGlassTintAlpha`）。 */
    public static let defaultTintShare: CGFloat = 0.75

    /**
     [EN] How bright iOS actually renders dark Liquid Glass over a black page, as a white share (sRGB 0.28, luminance about 0.063: measured 0.26, luminance about 0.055, on iOS 27.2 as
          Y 66 on a tag over a section board, plus a margin of about 0.02 for the anti-aliased glyph edges and the spread of the glass, Y 66 to 68). The rule judges a color against `max(model, this floor)` (`renderedGlassReferenceLuminance`): the shared
          model (`glassReferenceLuminance`, frosted white 0.14) alone gave only about 2.9:1 on the real glass. The algorithm is the shared one; this
          value is per platform, each platform measures its own.
     [CN] iOS 在黑色页面上实际渲染的深色液态玻璃亮度，以白色占比表示（sRGB 0.28，亮度约 0.063：iOS 27.2 上实测 0.26、亮度约 0.055，分组底板上的标签 Y 为 66，再加约 0.02 的余量，用于字形抗锯齿边缘与玻璃的波动，Y 66 到 68）。规则以
          `max(模型值, 此下限)`（`renderedGlassReferenceLuminance`）作为对照：只用共享模型（`glassReferenceLuminance`，磨砂白 0.14）时在真实玻璃上只有约 2.9:1。
          算法是共享的；此值因平台而异，各平台自己测量。
          [EN] Limits: the floor is per platform (each platform measures its own) and glass-only: flat fills are judged against the fill itself, flat without a fill is not adapted.
          [CN] 限制：下限因平台而异（各平台自己测量），且仅用于玻璃：纯色填充对照填充本身，没有填充的纯色背景不调整。
     */
    public static let renderedDarkGlassWhiteShare: CGFloat = 0.28

    /** [EN] The lightness rise per step (HSL, 0...1). [CN] 每步亮度增量（HSL，0...1）。 */
    public static let lightnessStep: CGFloat = 0.005

    private static let luminanceOffset: CGFloat = 0.05
    private static let channelMax: CGFloat = 255
    private static let staticTolerance: CGFloat = 0.001

    /** [EN] The WCAG contrast ratio of two relative luminances, 1 to 21. [CN] 两个相对亮度的 WCAG 对比度，1 到 21。 */
    public static func contrastRatio(_ first: CGFloat, _ second: CGFloat) -> CGFloat {
        (max(first, second) + luminanceOffset) / (min(first, second) + luminanceOffset)
    }

    /** [EN] The WCAG relative luminance of an sRGB color (components 0...1, clamped). [CN] sRGB 颜色（分量 0...1，超出时截断）的 WCAG 相对亮度。 */
    public static func relativeLuminance(red: CGFloat, green: CGFloat, blue: CGFloat) -> CGFloat {
        func linear(_ value: CGFloat) -> CGFloat {
            let clamped = min(max(value, 0), 1)
            return clamped <= 0.03928 ? clamped / 12.92 : pow((clamped + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    /**
     [EN] The luminance a color is judged against: the glass over black. `glassTint` nil or fully transparent is the default frosted tint
          (white at `frostedWhiteAlpha`); an explicit tint, resolved with Dark Mode traits, is its color x alpha x `tintAlpha`
          (`defaultTintShare` when nil).
     [CN] 颜色所对照的亮度：黑底上的玻璃。`glassTint` 为 nil 或完全透明时为默认磨砂着色（白色 `frostedWhiteAlpha`）；显式着色用深色模式 trait 解析，
          为颜色 x 透明度 x `tintAlpha`（nil 时为 `defaultTintShare`）。
     */
    public static func glassReferenceLuminance(glassTint: UIColor?, tintAlpha: CGFloat?) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard let tint = glassTint,
              tint.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).getRed(&red, green: &green, blue: &blue, alpha: &alpha),
              alpha > 0 else {
            return relativeLuminance(red: frostedWhiteAlpha, green: frostedWhiteAlpha, blue: frostedWhiteAlpha)
        }
        let share = min(1, max(0, alpha * (tintAlpha ?? defaultTintShare)))
        return relativeLuminance(red: red * share, green: green * share, blue: blue * share)
    }

    /**
     [EN] The reference the item judges against: the shared model, never below the rendered glass of this platform (`renderedDarkGlassWhiteShare`).
     [CN] 条目所对照的亮度：共享模型值，且不低于本平台实际渲染的玻璃（`renderedDarkGlassWhiteShare`）。
          [EN] Limits: the floor is per platform (each platform measures its own) and glass-only: flat fills are judged against the fill itself, flat without a fill is not adapted.
          [CN] 限制：下限因平台而异（各平台自己测量），且仅用于玻璃：纯色填充对照填充本身，没有填充的纯色背景不调整。
     */
    public static func renderedGlassReferenceLuminance(glassTint: UIColor?, tintAlpha: CGFloat?) -> CGFloat {
        max(glassReferenceLuminance(glassTint: glassTint, tintAlpha: tintAlpha),
            relativeLuminance(red: renderedDarkGlassWhiteShare, green: renderedDarkGlassWhiteShare, blue: renderedDarkGlassWhiteShare))
    }

    /**
     [EN] The luminance a color is judged against on a FLAT background: the fill resolved with `traits`, composited over black by its alpha. nil or a clear fill gives 0
          (black), but the item does not adapt without a fill (it cannot know what is behind it). The 0.28 rendered-glass floor does not apply.
     [CN] 纯色背景上颜色所对照的亮度：填充用 `traits` 解析，再按其透明度叠在黑色上。nil 或透明填充得到 0（黑色），但没有填充时条目不做调整（无法知道其后是什么）。
          渲染玻璃的 0.28 下限不适用。
     */
    public static func flatReferenceLuminance(fill: UIColor?, traits: UITraitCollection) -> CGFloat {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard let fill, fill.resolvedColor(with: traits).getRed(&red, green: &green, blue: &blue, alpha: &alpha), alpha > 0 else { return 0 }
        return relativeLuminance(red: red * alpha, green: green * alpha, blue: blue * alpha)
    }

    /**
     [EN] Whether `color` is static: the same color resolved with the light and the dark traits.
     [CN] `color` 是否为静态颜色：用浅色与深色 trait 解析得到相同颜色。
     */
    public static func isStatic(_ color: UIColor) -> Bool {
        var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
        var dr: CGFloat = 0, dg: CGFloat = 0, db: CGFloat = 0, da: CGFloat = 0
        guard color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).getRed(&lr, green: &lg, blue: &lb, alpha: &la),
              color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)).getRed(&dr, green: &dg, blue: &db, alpha: &da) else {
            return false
        }
        return abs(lr - dr) < staticTolerance && abs(lg - dg) < staticTolerance
            && abs(lb - db) < staticTolerance && abs(la - da) < staticTolerance
    }

    /**
     [EN] `color` itself when it is dynamic or already has `minimumContrast` against the glass (`glassReferenceLuminance`), else the same hue,
          saturation and alpha with the lowest lightness (`lightnessStep` steps, at most white) that passes; channels rounded to 1/255. When even white fails (a light
          reference), the one of `color` and the lifted color with more contrast.
     [CN] 颜色为动态颜色或与玻璃（`glassReferenceLuminance`）已达到 `minimumContrast` 时返回原颜色；否则返回色相、饱和度、透明度不变且亮度最低
          （每步 `lightnessStep`，最高为白色）的通过颜色；分量取整到 1/255。白色也不通过时（浅色参考），返回原颜色与提亮颜色中对比度较高者。
     */
    public static func adjusted(_ color: UIColor, glassTint: UIColor?, tintAlpha: CGFloat?, minimumContrast: CGFloat) -> UIColor {
        adjusted(color, referenceLuminance: renderedGlassReferenceLuminance(glassTint: glassTint, tintAlpha: tintAlpha), minimumContrast: minimumContrast)
    }

    /// [EN] The same against a reference luminance given by the caller. [CN] 同上，对照由调用方给出的参考亮度。
    public static func adjusted(_ color: UIColor, referenceLuminance reference: CGFloat, minimumContrast: CGFloat) -> UIColor {
        guard isStatic(color) else { return color }
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return color }
        let hsl = hslFromRGB(red: min(max(red, 0), 1), green: min(max(green, 0), 1), blue: min(max(blue, 0), 1))
        func contrast(_ lightness: CGFloat) -> CGFloat {
            let rgb = rgbFromHSL(hue: hsl.hue, saturation: hsl.saturation, lightness: lightness)
            return contrastRatio(relativeLuminance(red: rgb.red, green: rgb.green, blue: rgb.blue), reference)
        }
        func passes(_ lightness: CGFloat) -> Bool { contrast(lightness) >= minimumContrast }
        guard !passes(hsl.lightness) else { return color }
        var lightness = hsl.lightness
        while lightness < 1, !passes(lightness) {
            lightness = min(1, lightness + lightnessStep)
        }
        // [EN] Lifting can only help on a dark reference; on a light one (a light flat fill) it lowers contrast: keep whichever is higher. [CN] 提亮只对深色参考有帮助；浅色参考（浅色扁平填充）上会降低对比度：取二者中对比度较高者。
        if !passes(lightness), contrast(hsl.lightness) >= contrast(lightness) { return color }
        let rgb = rgbFromHSL(hue: hsl.hue, saturation: hsl.saturation, lightness: lightness)
        func channel(_ value: CGFloat) -> CGFloat { min(max((value * channelMax).rounded(), 0), channelMax) / channelMax }
        return UIColor(red: channel(rgb.red), green: channel(rgb.green), blue: channel(rgb.blue), alpha: alpha)
    }

    /** [EN] Title text (`titleMinimumContrast`, 4.5) on the glass. [CN] 玻璃上的标题文字（`titleMinimumContrast`，4.5）。 */
    public static func adjustedTitle(_ color: UIColor, glassTint: UIColor?, tintAlpha: CGFloat?) -> UIColor {
        adjusted(color, glassTint: glassTint, tintAlpha: tintAlpha, minimumContrast: titleMinimumContrast)
    }

    /** [EN] An icon or animation tint (`iconMinimumContrast`, 3) on the glass. [CN] 玻璃上的图标或动画着色（`iconMinimumContrast`，3）。 */
    public static func adjustedIcon(_ color: UIColor, glassTint: UIColor?, tintAlpha: CGFloat?) -> UIColor {
        adjusted(color, glassTint: glassTint, tintAlpha: tintAlpha, minimumContrast: iconMinimumContrast)
    }

    /** [EN] HSL of an sRGB color, all 0...1. [CN] sRGB 颜色的 HSL，均为 0...1。 */
    public static func hslFromRGB(red: CGFloat, green: CGFloat, blue: CGFloat) -> (hue: CGFloat, saturation: CGFloat, lightness: CGFloat) {
        let high = max(red, green, blue), low = min(red, green, blue)
        let lightness = (high + low) / 2
        let delta = high - low
        guard delta > 0 else { return (0, 0, lightness) }
        let saturation = delta / (1 - abs(2 * lightness - 1))
        var hue: CGFloat
        if high == red {
            hue = (green - blue) / delta
            if hue < 0 { hue += 6 }
        } else if high == green {
            hue = (blue - red) / delta + 2
        } else {
            hue = (red - green) / delta + 4
        }
        return (hue / 6, saturation, lightness)
    }

    /** [EN] The sRGB components of an HSL triple (all 0...1). [CN] HSL 三元组的 sRGB 分量（均为 0...1）。 */
    public static func rgbFromHSL(hue: CGFloat, saturation: CGFloat, lightness: CGFloat) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        let chroma = (1 - abs(2 * lightness - 1)) * saturation
        let sector = hue * 6
        let second = chroma * (1 - abs(sector.truncatingRemainder(dividingBy: 2) - 1))
        let base = lightness - chroma / 2
        let parts: (CGFloat, CGFloat, CGFloat)
        switch Int(sector) % 6 {
        case 0: parts = (chroma, second, 0)
        case 1: parts = (second, chroma, 0)
        case 2: parts = (0, chroma, second)
        case 3: parts = (0, second, chroma)
        case 4: parts = (second, 0, chroma)
        default: parts = (chroma, 0, second)
        }
        return (parts.0 + base, parts.1 + base, parts.2 + base)
    }
}
