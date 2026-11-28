package com.cyl.animateditem

import android.content.res.Configuration
import android.graphics.Color
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
 *      color ("#RRGGBB" / "#AARRGGBB") uses `darkTint` in night mode when it is set.
 * [CN] Tab 动画 URL 中的 `tint` / `darkTint` 选项，适用于所有引擎（GIF、Lottie、PAG、SVGA、Rive），与 iOS 相同。单色图标像模板图片一样绘制：
 *      视图的图层经过 SRC_IN 颜色滤镜（PAG 与 Rive 的视图是 `TextureView`，作为其 layer paint），因此任何引擎都不需要自己的颜色 API。
 *      "title" 跟随 Tab 的标题颜色（播放器的 `tintColor`）；固定颜色（"#RRGGBB" / "#AARRGGBB"）在夜间模式且设置了 `darkTint` 时使用它。
 */
object CYLTabBarItemAnimationTint {
    /**
     * [EN] The `tint` option value that follows the tab's title color. [CN] 跟随 Tab 标题颜色的 `tint` 选项值。
     */
    const val TINT_TITLE = "title"

    private const val TINT_TAG = "cyl_tab_bar_item_animation_tint"

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
     * [EN] The fixed tint for `configuration`: `darkTint` in night mode when it is set, else `tint`; null for "title" or none.
     * [CN] `configuration` 下的固定着色：夜间模式且设置了 `darkTint` 时使用它，否则使用 `tint`；"title" 或未设置时为 null。
     */
    fun fixedTintColor(options: Map<String, String>, configuration: Configuration): Int? {
        val light = tintOption(options)?.takeIf { it != TINT_TITLE }?.let { parseColor(it) } ?: return null
        // [EN] Only a fixed tint has a night color: "title" follows the title colors. [CN] 只有固定着色才有夜间颜色："title" 跟随标题颜色。
        val dark = options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionDarkTint]?.trim()?.takeIf { it.isNotEmpty() }?.let { parseColor(it) }
        return if (isNight(configuration)) dark ?: light else light
    }

    /**
     * [EN] The color to draw for `options`: the fixed tint for `configuration`, or `titleColor` when the option is "title".
     * [CN] `options` 应绘制的颜色：`configuration` 下的固定着色，或选项为 "title" 时的 `titleColor`。
     */
    fun resolvedTintColor(options: Map<String, String>, titleColor: Int?, configuration: Configuration, selected: Boolean? = null): Int? {
        if (tintOption(options) == TINT_TITLE) return titleColor
        val fixed = fixedTintColor(options, configuration) ?: return null
        // [EN] A fixed tint colors only the unselected tab; the selected one takes the title's selected color (iOS 9a64feea).
        //      Without a state (null) the fixed tint stays in both states. [CN] 固定着色只用于未选中的 Tab；选中的 Tab 使用标题的选中颜色（iOS 9a64feea）。没有状态（null）时两种状态都使用固定着色。
        return if (selected == true) titleColor ?: fixed else fixed
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

    private fun parseColor(value: String): Int? = runCatching { Color.parseColor(value) }.getOrNull()

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
    private val options: Map<String, String>,
) : CYLTabBarItemAnimationPlayer by player {
    override var tintColor: Int?
        get() = player.tintColor
        set(value) {
            player.tintColor = value
            val view = animationView ?: return
            CYLTabBarItemAnimationTint.apply(view, CYLTabBarItemAnimationTint.resolvedTintColor(options, value, view.resources.configuration, tintSelected))
        }
    private var tintSelected: Boolean? = null
    private var tintTitleColor: Int? = null
    override fun setTintColor(color: Int?, selected: Boolean) {
        tintSelected = selected
        tintTitleColor = color
        player.setTintColor(color, selected)
        val view = animationView ?: return
        CYLTabBarItemAnimationTint.apply(view, CYLTabBarItemAnimationTint.resolvedTintColor(options, color, view.resources.configuration, selected))
    }
    override fun applyColors(colors: Map<String, Int>?, configuration: Configuration) {
        player.applyColors(colors, configuration)
        // [EN] Called when night mode changes: a fixed tint takes the new mode's color. [CN] 夜间模式变化时调用：固定着色使用新模式的颜色。
        val view = animationView ?: return
        if (CYLTabBarItemAnimationTint.fixedTintColor(options, configuration) != null) {
            CYLTabBarItemAnimationTint.apply(view, CYLTabBarItemAnimationTint.resolvedTintColor(options, tintTitleColor, configuration, tintSelected))
        }
    }
}
