package com.cyl.animateditem

/**
 * [EN] The dark-glass contrast rule of an item (the same rule as ClassifyMenu's `CYLIconContrast`): an EXPLICIT title or icon colour that is too
 *      dark for dark Liquid Glass is lifted, keeping hue, saturation and alpha, until it has the minimum contrast against the glass. The glass
 *      is judged over black: the default frosted tint (dark mode) is white at alpha 0.14, an explicit tint is its colour times its alpha times
 *      the tint alpha. HSL lightness rises in 0.005 steps and never goes above white. Dark glass only: light glass is NOT adapted (there is
 *      no symmetric darkening rule). Pure and deterministic; the item calls it only where glass is really drawn, in night mode, for a colour the
 *      app set and for the built-in colours of an enabled item (normal and selected alike; the disabled look and flat items are untouched).
 * [CN] 条目的深色玻璃对比度规则（与 ClassifyMenu 的 `CYLIconContrast` 相同）：显式的标题或图标颜色在深色液态玻璃上过暗时，保持色相、饱和度与
 *      透明度，提高亮度直到与玻璃的对比度达到最小值。玻璃以黑色为底判断：夜间默认磨砂着色为白色 0.14 透明度，显式着色为其颜色乘以透明度再乘以
 *      着色透明度。HSL 亮度每步 0.005 上升，不超过白色。只处理深色玻璃：浅色玻璃不调整（没有对称的加深规则）。纯函数、确定性；条目只在
 *      玻璃确实绘制、夜间模式，颜色由应用设置，或为可用条目的内置颜色（普通与选中相同）时调用（禁用外观与扁平条目不受影响）。
 */
internal object CYLAnimatedItemContrast {

    /** [EN] Least contrast of an icon tint. [CN] 图标着色的最小对比度。 */
    const val ICON_MINIMUM_CONTRAST = 3.0

    /** [EN] Least contrast of title text. [CN] 标题文字的最小对比度。 */
    const val TITLE_MINIMUM_CONTRAST = 4.5

    /** [EN] White share of the default frosted glass in dark mode. [CN] 夜间默认磨砂玻璃的白色占比。 */
    const val FROSTED_WHITE_ALPHA = 0.14

    /** [EN] Share of an explicit tint's alpha that tints the glass (the renderer's `GLASS_TINT_ALPHA`). [CN] 显式着色透明度中用于玻璃着色的占比。 */
    const val DEFAULT_TINT_SHARE = 0.75f

    /**
     * [EN] The white share (Y/255 of the sRGB bytes) of the glass interior the device RENDERS in dark mode, the floor of the reference luminance.
     *      The model ([FROSTED_WHITE_ALPHA]) is darker than what a real dark glass draws (blur of the page plus the sheen), so a colour lifted only to
     *      the model stays too dark. MEASURED on Android (API 37 emulator, Configuration-like dark page, glass tags, middle band, median of 5 tags: Y 90.1, share 0.353);
     *      this constant is that value plus a margin of about 0.02. The iOS value (0.26 measured, 0.28 set) is not reused.
     * [CN] 设备在深色模式下实际渲染的玻璃内部的白色占比（sRGB 字节的 Y/255），即参考亮度的下限。模型（[FROSTED_WHITE_ALPHA]）比真实深色玻璃
     *      （页面模糊加高光）更暗，只提亮到模型的颜色仍然过暗。Android 实测（API 37 模拟器，仿 Configuration 页的深色页面与玻璃标签，标签中间带，5 个标签的中位数）：Y 90.1，占比 0.353；
     *      本常量为实测值 0.353 加约 0.02 的余量（0.37）。不沿用 iOS 的值（实测 0.26，设为 0.28）。
     */
    const val renderedDarkGlassWhiteShare = 0.37

    /** [EN] Lightness rise per step (0...1). [CN] 每步亮度增量（0...1）。 */
    const val LIGHTNESS_STEP = 0.005f

    private const val CHANNEL_MAX = 255.0
    private const val LUMINANCE_OFFSET = 0.05

    /** [EN] WCAG contrast ratio of two relative luminances. [CN] 两个相对亮度的 WCAG 对比度。 */
    fun contrastRatio(first: Double, second: Double): Double =
        (maxOf(first, second) + LUMINANCE_OFFSET) / (minOf(first, second) + LUMINANCE_OFFSET)

    /** [EN] WCAG relative luminance of an sRGB colour (components 0...1). [CN] sRGB 颜色（分量 0...1）的相对亮度。 */
    fun relativeLuminance(red: Double, green: Double, blue: Double): Double {
        fun linear(c: Double): Double = if (c <= 0.03928) c / 12.92 else Math.pow((c + 0.055) / 1.055, 2.4)
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    private fun alphaOf(color: Int) = (color ushr 24) and 0xFF
    private fun redOf(color: Int) = (color shr 16) and 0xFF
    private fun greenOf(color: Int) = (color shr 8) and 0xFF
    private fun blueOf(color: Int) = color and 0xFF

    /**
     * [EN] The luminance the colour is judged against: the glass over black. `glassTint` null or fully transparent is the default frosted tint
     *      (white at [FROSTED_WHITE_ALPHA]); an explicit tint is its colour x alpha x `tintAlpha` ([DEFAULT_TINT_SHARE] when null).
     * [CN] 颜色所对照的亮度：黑底上的玻璃。`glassTint` 为 null 或完全透明时是默认磨砂着色（白色 [FROSTED_WHITE_ALPHA]）；显式着色为
     *      颜色 x 透明度 x `tintAlpha`（null 时为 [DEFAULT_TINT_SHARE]）。
     */
    fun glassReferenceLuminance(glassTint: Int?, tintAlpha: Float?): Double {
        if (glassTint == null || alphaOf(glassTint) == 0) {
            return relativeLuminance(FROSTED_WHITE_ALPHA, FROSTED_WHITE_ALPHA, FROSTED_WHITE_ALPHA)
        }
        val share = alphaOf(glassTint) / CHANNEL_MAX * (tintAlpha ?: DEFAULT_TINT_SHARE).toDouble()
        return relativeLuminance(redOf(glassTint) / CHANNEL_MAX * share, greenOf(glassTint) / CHANNEL_MAX * share, blueOf(glassTint) / CHANNEL_MAX * share)
    }

    /**
     * [EN] The reference the lift judges against: the model [glassReferenceLuminance], never below the rendered dark glass ([renderedDarkGlassWhiteShare]).
     * [CN] 提亮所对照的参考亮度：模型 [glassReferenceLuminance]，但不低于实际渲染的深色玻璃（[renderedDarkGlassWhiteShare]）。
     */
    fun renderedGlassReferenceLuminance(glassTint: Int?, tintAlpha: Float?): Double =
        maxOf(glassReferenceLuminance(glassTint, tintAlpha), relativeLuminance(renderedDarkGlassWhiteShare, renderedDarkGlassWhiteShare, renderedDarkGlassWhiteShare))

    /**
     * [EN] `color` itself when it already has `minimumContrast` against a glass of `glassLuminance`, else the same hue, saturation and alpha
     *      with the lowest lightness (0.005 steps, at most white) that passes.
     * [CN] 颜色与亮度为 `glassLuminance` 的玻璃已达到 `minimumContrast` 时返回原颜色，否则返回色相、饱和度、透明度不变且亮度最低
     *      （每步 0.005，最高为白色）的通过颜色。
     */
    fun adjusted(color: Int, glassLuminance: Double, minimumContrast: Double): Int {
        val hsl = hslFromRGB(redOf(color) / CHANNEL_MAX.toFloat(), greenOf(color) / CHANNEL_MAX.toFloat(), blueOf(color) / CHANNEL_MAX.toFloat())
        fun passes(): Boolean {
            val rgb = rgbFromHSL(hsl[0], hsl[1], hsl[2])
            return contrastRatio(relativeLuminance(rgb[0].toDouble(), rgb[1].toDouble(), rgb[2].toDouble()), glassLuminance) >= minimumContrast
        }
        if (passes()) return color
        while (hsl[2] < 1f && !passes()) hsl[2] = minOf(1f, hsl[2] + LIGHTNESS_STEP)
        val rgb = rgbFromHSL(hsl[0], hsl[1], hsl[2])
        fun channel(value: Float) = Math.round(value * CHANNEL_MAX.toFloat()).coerceIn(0, 255)
        return (alphaOf(color) shl 24) or (channel(rgb[0]) shl 16) or (channel(rgb[1]) shl 8) or channel(rgb[2])
    }

    /** [EN] Title text (4.5) on the glass. [CN] 玻璃上的标题文字（4.5）。 */
    fun adjustedTitle(color: Int, glassTint: Int?, tintAlpha: Float?): Int =
        adjusted(color, renderedGlassReferenceLuminance(glassTint, tintAlpha), TITLE_MINIMUM_CONTRAST)

    /** [EN] Icon tint (3) on the glass. [CN] 玻璃上的图标着色（3）。 */
    fun adjustedIcon(color: Int, glassTint: Int?, tintAlpha: Float?): Int =
        adjusted(color, renderedGlassReferenceLuminance(glassTint, tintAlpha), ICON_MINIMUM_CONTRAST)

    /** [EN] HSL of an sRGB colour as [hue, saturation, lightness], all 0...1. [CN] sRGB 颜色的 HSL。 */
    fun hslFromRGB(red: Float, green: Float, blue: Float): FloatArray {
        val high = maxOf(red, green, blue)
        val low = minOf(red, green, blue)
        val lightness = (high + low) / 2
        val delta = high - low
        if (delta <= 0f) return floatArrayOf(0f, 0f, lightness)
        val saturation = delta / (1 - Math.abs(2 * lightness - 1))
        var hue = when (high) {
            red -> (green - blue) / delta
            green -> (blue - red) / delta + 2
            else -> (red - green) / delta + 4
        }
        if (hue < 0) hue += 6f
        return floatArrayOf(hue / 6f, saturation, lightness)
    }

    /** [EN] sRGB components of an HSL triple. [CN] HSL 三元组的 sRGB 分量。 */
    fun rgbFromHSL(hue: Float, saturation: Float, lightness: Float): FloatArray {
        val chroma = (1 - Math.abs(2 * lightness - 1)) * saturation
        val sector = hue * 6f
        val second = chroma * (1 - Math.abs(sector % 2f - 1))
        val base = lightness - chroma / 2
        val parts = when (sector.toInt() % 6) {
            0 -> floatArrayOf(chroma, second, 0f)
            1 -> floatArrayOf(second, chroma, 0f)
            2 -> floatArrayOf(0f, chroma, second)
            3 -> floatArrayOf(0f, second, chroma)
            4 -> floatArrayOf(second, 0f, chroma)
            else -> floatArrayOf(chroma, 0f, second)
        }
        return floatArrayOf(parts[0] + base, parts[1] + base, parts[2] + base)
    }
}
