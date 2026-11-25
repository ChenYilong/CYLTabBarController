package com.cyl.animateditem

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.util.TypedValue
import android.view.ContextThemeWrapper
import kotlin.math.roundToInt

/**
 * [EN] The BUILT-IN colors of an item (tint spec v2, the last level of the precedence: item explicit > stack explicit > subclass default > built-in).
 *      They are FUNCTIONS evaluated when a color is resolved, with the item's OWN context and configuration (night mode), never stored.
 *      Theme attributes of the view's context where they exist, the iOS 27.2 probe values where they do not:
 *      | role      | theme attribute (view's own context)       | fallback light  | fallback dark   |
 *      | normal    | `android:textColorPrimary`                 | 0,0,0           | 255,255,255     |
 *      | selected  | `colorPrimary` (appcompat, else framework) | 0,136,255       | 0,145,255       |
 *      | disabled  | normal at 38% of its alpha                 | 134,134,134@.45 | 140,140,140@.35 |
 *      | divider   | `android:textColorSecondary`               | 60,60,67@.60    | 235,235,245@.60 |
 *      The divider default has contrast >= 3:1 on white (light) and on a dark bar (dark); the iOS `separator` (1.2:1) is not used.
 * [CN] 条目的内置颜色（着色规范 v2，优先级的最后一级：条目显式 > 堆叠显式 > 子类默认 > 内置）。它们是在解析颜色时用条目自己的 context 与配置（夜间模式）
 *      求值的函数，从不存储。有主题属性时用视图 context 的主题属性，没有时用 iOS 27.2 探测值（见上表）。
 *      分隔线默认色在白色（日间）与深色栏（夜间）上的对比度 >= 3:1；不使用 iOS 的 `separator`（1.2:1）。
 */
object CYLAnimatedItemBuiltInColors {
    /** [EN] Fallback of the normal color: iOS label. [CN] 普通颜色的回退值：iOS label。 */
    const val NORMAL_LIGHT: Int = 0xFF000000.toInt()
    const val NORMAL_DARK: Int = 0xFFFFFFFF.toInt()

    /** [EN] Fallback of the selected color: iOS systemBlue as the UITabBar tint. [CN] 选中颜色的回退值：作为 UITabBar tint 的 iOS systemBlue。 */
    const val SELECTED_LIGHT: Int = 0xFF0088FF.toInt()
    const val SELECTED_DARK: Int = 0xFF0091FF.toInt()

    /** [EN] Fallback of the disabled color: the UIButton(.system) disabled title, 134,134,134@0.45 | 140,140,140@0.35. [CN] 禁用颜色的回退值：UIButton(.system) 的禁用标题。 */
    const val DISABLED_LIGHT: Int = 0x73868686
    const val DISABLED_DARK: Int = 0x598C8C8C

    /** [EN] Fallback of the divider: iOS secondaryLabel, 60,60,67@0.60 | 235,235,245@0.60. [CN] 分隔线的回退值：iOS secondaryLabel。 */
    const val DIVIDER_LIGHT: Int = 0x993C3C43.toInt()
    const val DIVIDER_DARK: Int = 0x99EBEBF5.toInt()

    /** [EN] The disabled color is the normal color at this share of its alpha (Material's 38%). [CN] 禁用颜色是普通颜色乘以该比例的 alpha（Material 的 38%）。 */
    const val DISABLED_ALPHA = 0.38f

    private fun isNight(configuration: Configuration) =
        (configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    /**
     * [EN] `context` seen with `configuration`'s night mode: `context` itself when its own night mode is the same, else a theme wrapper over it
     *      with that configuration (the framework copies the theme across). [CN] 以 `configuration` 的夜间模式看到的 `context`：夜间模式相同时就是 `context`，
     *      否则是带该配置的主题包装（框架会复制主题）。
     */
    private fun contextFor(context: Context, configuration: Configuration): Context {
        if (isNight(context.resources.configuration) == isNight(configuration)) return context
        return try {
            ContextThemeWrapper(context, 0).also { it.applyOverrideConfiguration(configuration) }
        } catch (error: RuntimeException) { context }
    }

    /**
     * [EN] The color of the theme attribute `attr` of `context` (a color value, or the default color of a color state list); null when the
     *      theme has none. [CN] `context` 主题属性 `attr` 的颜色（颜色值，或颜色状态列表的默认色）；主题没有时为 null。
     */
    @JvmStatic
    fun themeColor(context: Context, attr: Int): Int? {
        return try {
            val value = TypedValue()
            if (!context.theme.resolveAttribute(attr, value, true)) return null
            when {
                value.type in TypedValue.TYPE_FIRST_COLOR_INT..TypedValue.TYPE_LAST_COLOR_INT -> value.data
                value.resourceId != 0 -> context.getColorStateList(value.resourceId).defaultColor
                else -> null
            }
        } catch (error: RuntimeException) { null }
    }

    /**
     * [EN] The built-in normal icon / title color: `textColorPrimary`, else the label fallback. [CN] 内置的普通图标 / 标题颜色：`textColorPrimary`，否则为 label 回退值。
     */
    @JvmStatic
    fun normal(context: Context, configuration: Configuration = context.resources.configuration): Int {
        val styled = contextFor(context, configuration)
        return themeColor(styled, android.R.attr.textColorPrimary) ?: if (isNight(configuration)) NORMAL_DARK else NORMAL_LIGHT
    }

    /**
     * [EN] The built-in selected icon / title color: `colorPrimary` (appcompat, else the framework's), else the tint fallback.
     *      [CN] 内置的选中图标 / 标题颜色：`colorPrimary`（appcompat，其次框架的），否则为 tint 回退值。
     */
    @JvmStatic
    fun selected(context: Context, configuration: Configuration = context.resources.configuration): Int {
        val styled = contextFor(context, configuration)
        return themeColor(styled, androidx.appcompat.R.attr.colorPrimary)
            ?: themeColor(styled, android.R.attr.colorPrimary)
            ?: if (isNight(configuration)) SELECTED_DARK else SELECTED_LIGHT
    }

    /**
     * [EN] The built-in disabled icon / title color: the normal color at 38% of its alpha when the theme gives the normal color, else the
     *      probe fallback. [CN] 内置的禁用图标 / 标题颜色：主题提供普通颜色时为其 38% alpha，否则为探测回退值。
     */
    @JvmStatic
    fun disabled(context: Context, configuration: Configuration = context.resources.configuration): Int {
        val styled = contextFor(context, configuration)
        val base = themeColor(styled, android.R.attr.textColorPrimary) ?: return if (isNight(configuration)) DISABLED_DARK else DISABLED_LIGHT
        return withAlpha(base, DISABLED_ALPHA)
    }

    /**
     * [EN] The built-in divider color: `textColorSecondary`, else the secondaryLabel fallback. [CN] 内置的分隔线颜色：`textColorSecondary`，否则为 secondaryLabel 回退值。
     */
    @JvmStatic
    fun divider(context: Context, configuration: Configuration = context.resources.configuration): Int {
        val styled = contextFor(context, configuration)
        return themeColor(styled, android.R.attr.textColorSecondary) ?: if (isNight(configuration)) DIVIDER_DARK else DIVIDER_LIGHT
    }

    /**
     * [EN] `color` with its alpha multiplied by `share` (0..1). [CN] alpha 乘以 `share`（0..1）后的 `color`。
     */
    @JvmStatic
    fun withAlpha(color: Int, share: Float): Int =
        Color.argb((Color.alpha(color) * share).roundToInt().coerceIn(0, 255), Color.red(color), Color.green(color), Color.blue(color))

    /**
     * [EN] The WCAG contrast ratio of `foreground` (any alpha) over the opaque `background`. [CN] `foreground`（任意 alpha）叠在不透明 `background` 上的 WCAG 对比度。
     */
    @JvmStatic
    fun contrast(foreground: Int, background: Int): Double {
        val a = Color.alpha(foreground) / 255.0
        fun mix(f: Int, b: Int) = (f * a + b * (1 - a)).roundToInt()
        val over = Color.rgb(mix(Color.red(foreground), Color.red(background)), mix(Color.green(foreground), Color.green(background)), mix(Color.blue(foreground), Color.blue(background)))
        val l1 = luminance(over)
        val l2 = luminance(background)
        return (maxOf(l1, l2) + 0.05) / (minOf(l1, l2) + 0.05)
    }

    private fun luminance(color: Int): Double {
        fun channel(value: Int): Double { val c = value / 255.0; return if (c <= 0.03928) c / 12.92 else Math.pow((c + 0.055) / 1.055, 2.4) }
        return 0.2126 * channel(Color.red(color)) + 0.7152 * channel(Color.green(color)) + 0.0722 * channel(Color.blue(color))
    }
}
