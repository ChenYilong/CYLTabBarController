package com.cyl.animateditem

import android.content.res.Configuration
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.view.TextureView
import android.view.View

/**
 * [EN] `CYLTabBarItemAnimationTint`: the `tint` / `darkTint` options of a tab's animation URL, for every engine (GIF,
 *      Lottie, PAG, SVGA, Rive), as on iOS. A one-color icon is drawn like a template image: the view's layer goes
 *      through a SRC_IN color filter (a `TextureView`, as PAG's and Rive's views, takes it as its layer paint), so no
 *      engine needs a color API of its own. "title" follows the tab's title color (the player's `tintColor`); a fixed
 *      color ("#RRGGBB" / "#RRGGBBAA") uses `darkTint` in night mode when it is set.
 * [CN] Tab 动画 URL 中的 `tint` / `darkTint` 选项，适用于所有引擎（GIF、Lottie、PAG、SVGA、Rive），与 iOS 相同。单色图标像模板图片一样绘制：
 *      视图的图层经过 SRC_IN 颜色滤镜（PAG 与 Rive 的视图是 `TextureView`，作为其 layer paint），因此任何引擎都不需要自己的颜色 API。
 *      "title" 跟随 Tab 的标题颜色（播放器的 `tintColor`）；固定颜色（"#RRGGBB" / "#RRGGBBAA"）在夜间模式且设置了 `darkTint` 时使用它。
 */
object CYLTabBarItemAnimationTint {
    /**
     * [EN] The `tint` option value that follows the tab's title color. [CN] 跟随 Tab 标题颜色的 `tint` 选项值。
     */
    const val TINT_TITLE = "title"

    private const val TINT_TAG = "cyl_tab_bar_item_animation_tint"

    // [EN] The `tint` / `darkTint` an item's `animationTint` / `animationDarkTint` set on an animation view; weak, main thread only.
    // [CN] 条目的 `animationTint` / `animationDarkTint` 设置在动画视图上的 `tint` / `darkTint`；弱引用，仅主线程使用。
    private val overrides = java.util.WeakHashMap<View, Map<String, String>>()

    /**
     * [EN] Makes `tint` / `darkTint` (the item's `animationTint` / `animationDarkTint`) replace the same options of `view`'s
     *      source; a null or blank value replaces nothing, both null removes the override. The players and the Rive view read
     *      `effectiveOptions`, so a later `setTintColor` / night-mode change keeps the override.
     * [CN] 让 `tint` / `darkTint`（条目的 `animationTint` / `animationDarkTint`）替换 `view` 来源中的同名选项；null 或空白不替换任何选项，
     *      两者都为 null 时移除覆盖。播放器与 Rive 视图读取 `effectiveOptions`，因此之后的 `setTintColor` / 夜间模式变化仍保留该覆盖。
     */
    fun setOverride(view: View, tint: String?, darkTint: String?) {
        val values = LinkedHashMap<String, String>()
        tint?.trim()?.takeIf { it.isNotEmpty() }?.let { values[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionTint] = it }
        darkTint?.trim()?.takeIf { it.isNotEmpty() }?.let { values[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionDarkTint] = it }
        if (values.isEmpty()) overrides.remove(view) else overrides[view] = values
    }

    /**
     * [EN] `options` of the source with the override of `view` on top; `options` itself when there is none.
     * [CN] 来源的 `options`，加上 `view` 的覆盖；没有覆盖时就是 `options`。
     */
    fun effectiveOptions(view: View?, options: Map<String, String>): Map<String, String> {
        val override = view?.let { overrides[it] } ?: return options
        return options + override
    }

    /**
     * [EN] Draws `color` on an animation view: on the layer of `view`, or on the inner view of a Rive view (which draws its own tint).
     * [CN] 在动画视图上绘制 `color`：绘制在 `view` 的图层上，Rive 视图则绘制在其内部视图上（它自己绘制着色）。
     */
    fun applyToAnimationView(view: View, color: Int?) {
        if (view is CYLRiveTabBarItemAnimationView) { if (view.appliedTintColor != color) view.drawTint(color) } else apply(view, color)
    }

    // [EN] The views whose tint an item resolves (it knows both icon colors); their player and Rive view leave the tint to it. Weak, main thread only.
    // [CN] 由条目解析着色的视图（条目知道两种图标颜色）；其播放器与 Rive 视图不再自己处理着色。弱引用，仅主线程使用。
    private val managed = java.util.Collections.newSetFromMap(java.util.WeakHashMap<View, Boolean>())

    /**
     * [EN] Marks `view`'s tint as resolved by the item that shows it (`CYLAnimatedItemView.refreshAnimationTint`).
     * [CN] 标记 `view` 的着色由显示它的条目解析（`CYLAnimatedItemView.refreshAnimationTint`）。
     */
    fun setManaged(view: View) { managed.add(view) }

    /**
     * [EN] Whether an item resolves the tint of `view`. [CN] `view` 的着色是否由条目解析。
     */
    fun isManaged(view: View?): Boolean = view != null && managed.contains(view)

    /**
     * [EN] The `tint` option, trimmed; null when it is missing or empty. [CN] 去除空白后的 `tint` 选项；缺失或为空时为 null。
     */
    fun tintOption(options: Map<String, String>): String? =
        options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionTint]?.trim()?.takeIf { it.isNotEmpty() }

    /**
     * [EN] Whether `options` ask for any tint. [CN] `options` 是否要求着色。
     */
    fun hasTint(options: Map<String, String>): Boolean = tintOption(options) != null

    /**
     * [EN] The tint truth table (the same on iOS, Android, HarmonyOS and the mini program), the only place that resolves a tint.
     *      `tint` / `darkTint` are the already merged texts (the item's property over the source's option). Unset or invalid `tint`
     *      (neither "title" nor "#RRGGBB" / "#RRGGBBAA"): null, the file's own colors. "title": unselected `normalIconColor`;
     *      selected `selectedIconColor`, else `normalIconColor`; with neither: null (the tint is removed). A fixed color:
     *      unselected the color, in night mode `darkTint` when it is valid; selected `selectedIconColor` when present, else the
     *      fixed color (with `darkTint` in night mode). An 8-digit color is #RRGGBBAA.
     * [CN] 着色真值表（iOS、Android、鸿蒙、小程序相同），是唯一解析着色的地方。`tint` / `darkTint` 是已合并的文本（条目属性优先于来源选项）。
     *      `tint` 未设置或无效（既不是 "title"，也不是 "#RRGGBB" / "#RRGGBBAA"）：null，保持文件自身颜色。"title"：未选中为 `normalIconColor`；
     *      选中为 `selectedIconColor`，否则 `normalIconColor`；两者都没有：null（移除着色）。固定颜色：未选中为该颜色，夜间模式且 `darkTint` 有效时为 `darkTint`；
     *      选中且有 `selectedIconColor` 时为它，否则为固定颜色（夜间模式使用 `darkTint`）。8 位颜色为 #RRGGBBAA。
     */
    fun resolve(tint: String?, darkTint: String?, selected: Boolean, isDark: Boolean, normalIconColor: Int?, selectedIconColor: Int?): Int? {
        val text = tint?.trim()?.takeIf { it.isNotEmpty() } ?: return null
        if (text == TINT_TITLE) return if (selected) selectedIconColor ?: normalIconColor else normalIconColor
        val fixed = parseHex(text) ?: return null
        val night = if (isDark) darkTint?.let { parseHex(it) } else null
        val fixedForMode = night ?: fixed
        return if (selected) selectedIconColor ?: fixedForMode else fixedForMode
    }

    /**
     * [EN] Whether `text` is a usable `tint`: "title" or "#RRGGBB" / "#RRGGBBAA"; anything else (null, empty, invalid) counts as unset.
     * [CN] `text` 是否是可用的 `tint`："title" 或 "#RRGGBB" / "#RRGGBBAA"；其他（null、空、无效）都视为未设置。
     */
    fun isValidTint(text: String?): Boolean {
        val value = text?.trim()?.takeIf { it.isNotEmpty() } ?: return false
        return value == TINT_TITLE || parseHex(value) != null
    }

    /**
     * [EN] The `renderingMode` option, trimmed; null when missing, empty or unknown. [CN] 去除空白后的 `renderingMode` 选项；缺失、为空或未知时为 null。
     */
    fun renderingModeOption(options: Map<String, String>): CYLAnimationRenderingMode? =
        CYLAnimationRenderingMode.parse(options[CYLAnimationRenderingMode.OPTION_NAME])

    /**
     * [EN] The ITEM tint table (tint spec v2, the same on every platform), the only place that resolves the tint of an item's animation.
     *      `effectiveIconColor` is the icon color of the current state (explicit, else the stack's, else the built-in); `explicitSelectedIconColor`
     *      is the selected one WITHOUT built-ins (item / stack / host only). `tint` / `darkTint` are the merged texts.
     *      - Valid `tint` "title": `effectiveIconColor`.
     *      - Valid fixed `tint` ("#RRGGBB" / "#RRGGBBAA"): unselected: the color, in night mode `darkTint` when valid; selected: ONLY an explicit selected
     *        icon color replaces it (never the built-in selected color, or every fixed tint would turn blue when selected), else the fixed color.
     *      - `tint` unset or invalid: `mode` decides: `AlwaysOriginal` null; `AlwaysTemplate` `effectiveIconColor`; `Automatic` `effectiveIconColor`
     *        only when `kind` is `OneColor`, else null (the file's own colors).
     * [CN] 条目着色表（着色规范 v2，各平台相同），是唯一解析条目动画着色的地方。`effectiveIconColor` 是当前状态的图标颜色（显式、其次堆叠、再次内置）；
     *      `explicitSelectedIconColor` 是不含内置值的选中图标颜色（仅条目 / 堆叠 / 宿主）。`tint` / `darkTint` 是已合并的文本。
     *      - 有效 `tint` 为 "title"：`effectiveIconColor`。
     *      - 有效固定 `tint`（"#RRGGBB" / "#RRGGBBAA"）：未选中：该颜色，夜间模式且 `darkTint` 有效时为 `darkTint`；选中：只有显式的选中图标颜色可以替换它
     *        （绝不是内置选中色，否则每个固定着色选中时都会变蓝），否则为固定颜色。
     *      - `tint` 未设置或无效：由 `mode` 决定：`AlwaysOriginal` 为 null；`AlwaysTemplate` 为 `effectiveIconColor`；`Automatic` 仅当 `kind` 为 `OneColor` 时
     *        为 `effectiveIconColor`，否则为 null（文件自身颜色）。
     */
    fun resolveItem(
        tint: String?, darkTint: String?, mode: CYLAnimationRenderingMode, kind: CYLAnimationColorCount.Kind,
        selected: Boolean, isDark: Boolean, effectiveIconColor: Int?, explicitSelectedIconColor: Int?,
    ): Int? {
        val text = tint?.trim()?.takeIf { it.isNotEmpty() }
        if (text == TINT_TITLE) return effectiveIconColor
        val fixed = text?.let { parseHex(it) }
        if (fixed != null) {
            val forMode = (if (isDark) darkTint?.let { parseHex(it) } else null) ?: fixed
            return if (selected) explicitSelectedIconColor ?: forMode else forMode
        }
        return when (mode) {
            CYLAnimationRenderingMode.AlwaysOriginal -> null
            CYLAnimationRenderingMode.AlwaysTemplate -> effectiveIconColor
            CYLAnimationRenderingMode.Automatic -> if (kind == CYLAnimationColorCount.Kind.OneColor) effectiveIconColor else null
        }
    }

    /**
     * [EN] "#RRGGBB" or "#RRGGBBAA" (the iOS / Rive order) as an ARGB int; null for any other text. `Color.parseColor` reads
     *      8 digits as #AARRGGBB, so it is not used. [CN] "#RRGGBB" 或 "#RRGGBBAA"（iOS / Rive 的顺序）转为 ARGB 整数；其他文本为 null。
     *      `Color.parseColor` 把 8 位当作 #AARRGGBB，因此不使用它。
     */
    fun parseHex(text: String): Int? {
        val value = text.trim()
        if (!value.startsWith("#") || (value.length != 7 && value.length != 9)) return null
        val digits = value.substring(1)
        if (!digits.all { it in '0'..'9' || it in 'a'..'f' || it in 'A'..'F' }) return null
        val rgb = digits.substring(0, 6).toInt(16)
        val alpha = if (digits.length == 8) digits.substring(6).toInt(16) else 0xFF
        return (alpha shl 24) or rgb
    }

    /**
     * [EN] The `darkTint` option, trimmed; null when missing or empty. [CN] 去除空白后的 `darkTint` 选项；缺失或为空时为 null。
     */
    fun darkTintOption(options: Map<String, String>): String? =
        options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionDarkTint]?.trim()?.takeIf { it.isNotEmpty() }

    /**
     * [EN] The fixed tint for `configuration` (unselected): `darkTint` in night mode when it is valid, else `tint`; null for "title", an invalid or no tint.
     * [CN] `configuration` 下（未选中）的固定着色：夜间模式且 `darkTint` 有效时使用它，否则使用 `tint`；"title"、无效或未设置时为 null。
     */
    fun fixedTintColor(options: Map<String, String>, configuration: Configuration): Int? {
        return resolve(tintOption(options), darkTintOption(options), false, isNight(configuration), null, null)
    }

    /**
     * [EN] The color to draw for `options` given the one color a player gets (`titleColor`, of the state `selected`): the table
     *      with `titleColor` as the icon color of that state. No state (null) counts as unselected.
     * [CN] 在播放器只得到一个颜色（状态 `selected` 的 `titleColor`）时，`options` 应绘制的颜色：真值表，其中 `titleColor` 作为该状态的图标颜色。
     *      没有状态（null）视为未选中。
     */
    fun resolvedTintColor(options: Map<String, String>, titleColor: Int?, configuration: Configuration, selected: Boolean? = null): Int? {
        val isSelected = selected == true
        return resolve(
            tintOption(options), darkTintOption(options), isSelected, isNight(configuration),
            if (isSelected) null else titleColor, if (isSelected) titleColor else null,
        )
    }

    /**
     * [EN] Draws `view` in `color` (SRC_IN on its layer); null removes the tint. Applied only when the color changes.
     * [CN] 用 `color` 绘制 `view`（其图层上的 SRC_IN）；null 移除着色。只在颜色变化时应用。
     */
    fun apply(view: View, color: Int?) {
        // [EN] Untinted and asked for no tint: nothing to remove. [CN] 未着色且不要求着色：无需移除。
        if (view.cyl_getTag(TINT_TAG) == color) return
        view.cyl_setTag(TINT_TAG, color)
        val paint = color?.let { Paint().apply { colorFilter = PorterDuffColorFilter(it, PorterDuff.Mode.SRC_IN) } }
        if (view is TextureView) {
            view.setLayerPaint(paint)
        } else {
            view.setLayerType(if (paint != null) View.LAYER_TYPE_HARDWARE else View.LAYER_TYPE_NONE, paint)
        }
    }

    /**
     * [EN] The tint drawn on `view` by `apply`, or null. [CN] `apply` 在 `view` 上绘制的着色，没有时为 null。
     */
    fun appliedColor(view: View?): Int? = view?.cyl_getTag(TINT_TAG) as? Int

    private fun isNight(configuration: Configuration) =
        (configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
}

/**
 * [EN] A player that adds the `tint` / `darkTint` options to an engine's player: every member goes to `player`, and the
 *      tint is drawn on the view by `CYLTabBarItemAnimationTint`, unless the view draws its tint itself
 *      (`CYLTabBarItemAnimationPlayableView.cyl_drawsAnimationViewTint`).
 * [CN] 为引擎的播放器加上 `tint` / `darkTint` 选项的播放器：所有成员转发给 `player`，着色由 `CYLTabBarItemAnimationTint` 绘制在视图上，
 *      除非视图自己绘制着色（`CYLTabBarItemAnimationPlayableView.cyl_drawsAnimationViewTint`）。
 */
internal class CYLTabBarItemAnimationTintingPlayer(
    val player: CYLTabBarItemAnimationPlayer,
    private val sourceOptions: Map<String, String>,
) : CYLTabBarItemAnimationPlayer by player {
    // [EN] The source's options with the item's `animationTint` / `animationDarkTint` on top. [CN] 来源的选项，加上条目的 `animationTint` / `animationDarkTint`。
    private val options: Map<String, String> get() = CYLTabBarItemAnimationTint.effectiveOptions(animationView, sourceOptions)
    override var tintColor: Int?
        get() = player.tintColor
        set(value) {
            player.tintColor = value
            val view = animationView ?: return
            if (CYLTabBarItemAnimationTint.isManaged(view)) return
            CYLTabBarItemAnimationTint.apply(view, CYLTabBarItemAnimationTint.resolvedTintColor(options, value, view.resources.configuration, tintSelected))
        }
    private var tintSelected: Boolean? = null
    private var tintTitleColor: Int? = null
    override fun setTintColor(color: Int?, selected: Boolean) {
        tintSelected = selected
        tintTitleColor = color
        player.setTintColor(color, selected)
        val view = animationView ?: return
        if (CYLTabBarItemAnimationTint.isManaged(view)) return
        CYLTabBarItemAnimationTint.apply(view, CYLTabBarItemAnimationTint.resolvedTintColor(options, color, view.resources.configuration, selected))
    }
    override fun applyColors(colors: Map<String, Int>?, configuration: Configuration) {
        player.applyColors(colors, configuration)
        // [EN] Called when night mode changes: a fixed tint takes the new mode's color. [CN] 夜间模式变化时调用：固定着色使用新模式的颜色。
        val view = animationView ?: return
        if (CYLTabBarItemAnimationTint.isManaged(view)) return
        if (CYLTabBarItemAnimationTint.fixedTintColor(options, configuration) != null) {
            CYLTabBarItemAnimationTint.apply(view, CYLTabBarItemAnimationTint.resolvedTintColor(options, tintTitleColor, configuration, tintSelected))
        }
    }
}
