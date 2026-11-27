//
//  CYLBadgeAttributeKey.kt
//  cylbadge
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
//  [EN] Not compiled yet: written statically on Linux (docs/Animated-Item-Badge-CrossPlatform.md, Android phase 2).
//  [CN] 尚未编译：在 Linux 上静态编写（docs/Animated-Item-Badge-CrossPlatform.md，Android 阶段 2）。
//

package com.cyl.tabbar

import android.graphics.Color
import android.view.View

/**
 * [EN] The keys of a badge style map: the same strings as iOS' `CYLBadgeAttributeKey` and the host view's `badgeAttributes`. Values are native
 *      values or strings (`#RRGGBB` / `#RRGGBBAA` colors, `{x, y}` offsets, numeric strings); null and unknown types are ignored, never a crash.
 *      One parser, [cylApplyBadgeAttributes], serves animated items, the tab bar host view and configuration files.
 * [CN] 角标样式 Map 的键：与 iOS 的 `CYLBadgeAttributeKey` 和宿主视图的 `badgeAttributes` 相同的字符串。值为原生值或字符串（`#RRGGBB` / `#RRGGBBAA`
 *      颜色、`{x, y}` 偏移、数字字符串）；null 与未知类型被忽略，不会崩溃。一个解析函数 [cylApplyBadgeAttributes] 同时服务动效 item、TabBar 宿主视图与配置文件。
 */
object CYLBadgeAttributeKey {
    const val VALUE = "value"
    const val COLOR = "color"
    /** One of the 10 `CYLBadgeAnimationType` names (any letter case), or its number. */
    const val ANIMATION = "animation"
    const val RADIUS = "radius"
    /** From the icon's top trailing corner, `{x, y}` in dp. */
    const val CENTER_OFFSET = "centerOffset"
    const val TEXT_COLOR = "textColor"
    /** A point size (sp) as a number or a string. */
    const val FONT = "font"
    const val BORDER_COLOR = "borderColor"
    const val BORDER_WIDTH = "borderWidth"
    const val MAXIMUM_NUMBER = "maximumNumber"
    const val RESPECTS_REDUCE_MOTION = "respectsReduceMotion"

    /**
     * [EN] The animation named in [attributes] (a name in any letter case, or 0...9); [CYLEnums.CYLBadgeAnimationType.None] for anything else.
     * [CN] [attributes] 中指定的动画（任意大小写的名称，或 0...9）；其他情况为 [CYLEnums.CYLBadgeAnimationType.None]。
     */
    @JvmStatic
    fun animationType(attributes: Map<String, Any?>?): CYLEnums.CYLBadgeAnimationType {
        val value = attributes?.get(ANIMATION)
        val all = CYLEnums.CYLBadgeAnimationType.values()
        return when (value) {
            is CYLEnums.CYLBadgeAnimationType -> value
            is Number -> all.firstOrNull { it.rawValue == value.toInt() }
            is String -> all.firstOrNull { it.name.equals(value.trim(), ignoreCase = true) }
            else -> null
        } ?: CYLEnums.CYLBadgeAnimationType.None
    }

    internal fun color(value: Any?): Int? = when (value) {
        is Int -> value
        is String -> parseColor(value.trim())
        else -> null
    }

    private fun parseColor(text: String): Int? {
        if (!text.startsWith("#")) return runCatching { Color.parseColor(text) }.getOrNull()
        val hex = text.substring(1)
        return when (hex.length) {
            6 -> hex.toLongOrNull(16)?.let { (0xFF000000L or it).toInt() }
            // #RRGGBBAA, as iOS and the configuration files write it, becomes Android's #AARRGGBB.
            8 -> hex.toLongOrNull(16)?.let { (((it and 0xFF) shl 24) or (it shr 8)).toInt() }
            else -> null
        }
    }

    internal fun number(value: Any?): Double? = when (value) {
        is Number -> value.toDouble()
        is String -> value.trim().toDoubleOrNull()
        else -> null
    }

    internal fun point(value: Any?): CYLOffset? {
        if (value is CYLOffset) return value
        // [EN] `[x, y]` in dp, as the tab bar host view takes it. [CN] 以 dp 表示的 `[x, y]`，与 TabBar 宿主视图的写法相同。
        if (value is List<*> && value.size == 2) {
            val x = (value[0] as? Number)?.toFloat() ?: return null
            val y = (value[1] as? Number)?.toFloat() ?: return null
            return CYLOffset(x, y)
        }
        val text = (value as? String)?.trim() ?: return null
        val match = Regex("""^\{\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*}$""").find(text) ?: return null
        val x = match.groupValues[1].toFloatOrNull() ?: return null
        val y = match.groupValues[2].toFloatOrNull() ?: return null
        return CYLOffset(x, y)
    }
}

/**
 * [EN] Applies the style keys of [attributes] ([CYLBadgeAttributeKey]) to this view's badge settings. The value and the animation are not applied
 *      here: the caller shows the badge. The border belongs to the badge view, which exists only after the badge is shown: call again then.
 * [CN] 把 [attributes] 中的样式键（[CYLBadgeAttributeKey]）应用到本视图的角标设置。值与动画不在这里应用：由调用方显示角标。边框属于角标视图，它在显示角标之后
 *      才存在：那时再调用一次。
 */
fun View.cylApplyBadgeAttributes(attributes: Map<String, Any?>) {
    CYLBadgeAttributeKey.color(attributes[CYLBadgeAttributeKey.COLOR])?.let { cylBadgeBackgroundColor = it }
    CYLBadgeAttributeKey.color(attributes[CYLBadgeAttributeKey.TEXT_COLOR])?.let { cylBadgeTextColor = it }
    CYLBadgeAttributeKey.number(attributes[CYLBadgeAttributeKey.FONT])?.takeIf { it > 0 }?.let { cylBadgeFont = CYLFont(it.toFloat(), bold = true) }
    CYLBadgeAttributeKey.number(attributes[CYLBadgeAttributeKey.RADIUS])?.let { cylBadgeRadius = it.toFloat() }
    CYLBadgeAttributeKey.point(attributes[CYLBadgeAttributeKey.CENTER_OFFSET])?.let { cylBadgeCenterOffset = it }
    CYLBadgeAttributeKey.number(attributes[CYLBadgeAttributeKey.MAXIMUM_NUMBER])?.let { cylBadgeMaximumBadgeNumber = it.toInt() }
    (attributes[CYLBadgeAttributeKey.RESPECTS_REDUCE_MOTION] as? Boolean)?.let { cylBadgeRespectsReduceMotion = it }
    CYLBadgeAttributeKey.color(attributes[CYLBadgeAttributeKey.BORDER_COLOR])?.let { cylBadgeBorderColor = it }
    CYLBadgeAttributeKey.number(attributes[CYLBadgeAttributeKey.BORDER_WIDTH])?.let { cylBadgeBorderWidth = it.toFloat() }
}
