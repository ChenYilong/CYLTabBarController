package com.cyl.animateditem

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.View
import android.view.ViewGroup
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * [EN] The one implementation of the background of an animated item (the flat color or Liquid Glass, the corner radius, the border),
 *      shared by [CYLAnimatedItemView] and [CYLAnimatedItemStackView]: both only keep the `item…` properties and call [apply].
 *      [CYLAnimatedItemCornerRadiusCapsule] is the capsule (half the height, following the size); any other value is dp limited to half
 *      the height; null is a capsule for Liquid Glass and square for flat.
 * [CN] 动效条目背景（纯色或液态玻璃、圆角、边框）的唯一实现，由 [CYLAnimatedItemView] 与 [CYLAnimatedItemStackView] 共用：二者只保存 `item…` 属性并调用
 *      [apply]。[CYLAnimatedItemCornerRadiusCapsule] 为胶囊（半高，随尺寸变化）；其他值为 dp，最大取半高；null 时液态玻璃为胶囊、扁平为直角。
 */
internal class CYLAnimatedItemBackgroundRenderer(private val host: ViewGroup) {

    companion object {
        /** The share of the host color's alpha that tints the glass. */
        const val GLASS_TINT_ALPHA = 0.75f

        /**
         * [EN] The tint of a glass whose host set no color: a light frosted gray in light mode (225, 222, 220 at alpha 0.5), a faint white in dark mode
         *      (alpha 0.14), so a Liquid Glass style alone is visible on a plain page (the same values on every platform).
         * [CN] 宿主未设置颜色时玻璃的着色：浅色模式为淡灰（225, 222, 220，透明度 0.5），深色模式为淡白（透明度 0.14），因此只设置液态玻璃样式在纯色页面上也看得见（各平台数值相同）。
         */
        /**
         * The content inset: the explicit value, else [CYLAnimatedItemLiquidGlassContentInset] where the glass is drawn (the unset radius's condition), else 0.
         * Static, so a view can ask while it is still being built (its renderer does not exist yet).
         */
        fun resolvedContentInset(explicit: Float?, style: CYLAnimatedItemBackgroundStyle?): Float =
            explicit?.let { max(it, 0f) } ?: if (style == CYLAnimatedItemBackgroundStyle.LiquidGlass && CYLAnimatedItemView.isLiquidGlassActive()) CYLAnimatedItemLiquidGlassContentInset else 0f

        fun defaultGlassTint(resources: android.content.res.Resources): Int {
            val night = resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK ==
                android.content.res.Configuration.UI_MODE_NIGHT_YES
            return if (night) Color.argb(36, 255, 255, 255) else Color.argb(128, 225, 222, 220)
        }
    }

    private val box = GradientDrawable()
    private var layer: CYLLiquidGlassView? = null

    /** The Liquid Glass layer while it is drawn; null otherwise. */
    val glassView: View? get() = layer?.takeIf { it.parent != null }

    fun resolvedStyle(style: CYLAnimatedItemBackgroundStyle): CYLAnimatedItemBackgroundStyle =
        if (style == CYLAnimatedItemBackgroundStyle.LiquidGlass && CYLAnimatedItemView.isLiquidGlassActive()) {
            CYLAnimatedItemBackgroundStyle.LiquidGlass
        } else {
            CYLAnimatedItemBackgroundStyle.Flat
        }

    /**
     * [EN] The tint a glass draws with: the host's color made translucent (its alpha times [GLASS_TINT_ALPHA]), so an opaque color such as a
     *      selected tag's green tints the glass instead of covering it. One rule for every host, the same on every platform.
     * [CN] 玻璃使用的着色：宿主颜色变为半透明（其透明度乘以 [GLASS_TINT_ALPHA]），因此选中标签的绿色这样的不透明色是给玻璃着色而不是盖住它。所有宿主、所有平台同一规则。
     */
    fun glassTint(color: Int?, tintAlpha: Float? = null): Int =
        // [EN] null and a fully transparent color (Color.TRANSPARENT) both mean "no color": the default frosted tint. [CN] null 与完全透明的颜色
        //      （Color.TRANSPARENT）都表示「没有颜色」：使用默认磨砂着色。
        color?.takeIf { Color.alpha(it) != 0 }
            ?.let { Color.argb((Color.alpha(it) * (tintAlpha ?: GLASS_TINT_ALPHA)).roundToInt(), Color.red(it), Color.green(it), Color.blue(it)) }
            ?: defaultGlassTint(host.resources)

    fun apply(style: CYLAnimatedItemBackgroundStyle, color: Int?, cornerRadius: Float?, borderWidth: Float, borderColor: Int?, tintAlpha: Float? = null) {
        val density = host.resources.displayMetrics.density
        val resolved = resolvedStyle(style)
        val height = host.height
        val radius = if (cornerRadius != null) {
            if (cornerRadius == CYLAnimatedItemCornerRadiusCapsule) height / 2f else min(max(cornerRadius, 0f) * density, height / 2f)
        } else if (resolved == CYLAnimatedItemBackgroundStyle.LiquidGlass) {
            height / 2f
        } else {
            0f
        }
        box.cornerRadius = radius
        box.setStroke((borderWidth * density).roundToInt(), borderColor ?: Color.TRANSPARENT)
        var glassDrawn = false
        if (resolved == CYLAnimatedItemBackgroundStyle.LiquidGlass) {
            val glass = layer ?: CYLLiquidGlassView(host.context).also { layer = it }
            glass.glassTintColor = glassTint(color, tintAlpha)
            glass.cornerRadius = radius
            if (glass.parent == null) host.addView(glass, 0)
            glass.visibility = View.VISIBLE
            glass.layout(0, 0, host.width, host.height)
            glass.applyEffect()
            glassDrawn = glass.isGlassDrawn
        }
        if (!glassDrawn) layer?.let { if (it.parent != null) host.removeView(it) }
        box.setColor(if (glassDrawn) Color.TRANSPARENT else (color ?: Color.TRANSPARENT))
        if (host.background !== box) host.background = box
    }

    /** Keeps the glass layer the size of the host in `onLayout`. */
    fun layoutGlass(width: Int, height: Int) {
        layer?.let { if (it.parent != null) it.layout(0, 0, width, height) }
    }
}
