package com.cyl.animateditem

import android.content.res.Configuration
import android.content.res.Resources
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader

/**
 * [EN] The lit edge of every Liquid Glass surface, the ONE definition shared by tags, boards and the tab bar capsule (and by HarmonyOS
 *      `CYLLiquidGlass`): the sheen (a top-to-bottom gradient over the tint) and the uniform 1 dp rim. The tint and blur of each
 *      surface stay its own. Draw the sheen first, then the rim. Call from the UI thread (the paints are shared).
 * [CN] 所有液态玻璃表面的受光边缘，标签、看板与 TabBar 胶囊共用的唯一定义（也与鸿蒙 `CYLLiquidGlass` 相同）：高光（着色之上自上而下的渐变）
 *      与统一的 1 dp 细边。各表面的着色与模糊仍由其自己决定。先绘制高光，再绘制细边。请在 UI 线程调用（画笔是共用的）。
 */
object CYLGlassEdge {

    /**
     * [EN] The width of the glass rim, dp (HarmonyOS `CYLLiquidGlass.RIM_WIDTH`, 1 vp). [CN] 玻璃边缘细边的宽度，单位 dp（鸿蒙 `CYLLiquidGlass.RIM_WIDTH`，1 vp）。
     */
    const val RIM_WIDTH_DP = 1f

    /**
     * [EN] The positions of [sheenColors], top to bottom (the same on HarmonyOS). [CN] [sheenColors] 的位置，自上而下（与鸿蒙相同）。
     */
    val SHEEN_POSITIONS: FloatArray get() = floatArrayOf(0f, 0.35f, 0.6f, 1f)

    /**
     * [EN] Whether the night mode is on in `resources` (the rule of the rim and the sheen). [CN] `resources` 是否处于夜间模式（细边与高光的规则）。
     */
    fun isDark(resources: Resources): Boolean =
        resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES

    /**
     * [EN] The rim of every glass, the same on all four edges: white 70% on light glass (0xB3FFFFFF), white 22% on dark glass (0x38FFFFFF);
     *      HarmonyOS `CYLLiquidGlass.rimEdgeColors`. [CN] 所有玻璃的细边，四条边相同：浅色玻璃上为白色 70%（0xB3FFFFFF），深色玻璃上为白色 22%（0x38FFFFFF）；
     *      鸿蒙 `CYLLiquidGlass.rimEdgeColors`。
     */
    fun rimColor(dark: Boolean): Int = if (dark) 0x38FFFFFF else 0xB3FFFFFF.toInt()

    /**
     * [EN] The sheen of every glass over its tint, top to bottom at [SHEEN_POSITIONS]; HarmonyOS `CYLLiquidGlass.sheenColors`.
     * [CN] 所有玻璃在着色之上的高光，自上而下位于 [SHEEN_POSITIONS]；鸿蒙 `CYLLiquidGlass.sheenColors`。
     */
    fun sheenColors(dark: Boolean): IntArray =
        if (dark) intArrayOf(0x2EFFFFFF, 0x0AFFFFFF, 0x00FFFFFF, 0x12FFFFFF) else intArrayOf(0x66FFFFFF, 0x14FFFFFF, 0x00FFFFFF, 0x1FFFFFFF)

    private val sheenPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val rimPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }
    private val scratch = RectF()
    private var sheenShader: LinearGradient? = null
    private var sheenDark = false
    private var sheenTop = 0f
    private var sheenBottom = 0f

    /**
     * [EN] Draws the sheen over `rect` (rounded by `radius`): a top-to-bottom gradient at [SHEEN_POSITIONS], faded by `alpha` (0 to 1).
     * [CN] 在 `rect`（圆角 `radius`）上绘制高光：位于 [SHEEN_POSITIONS] 的自上而下渐变，按 `alpha`（0 到 1）淡化。
     */
    fun drawSheen(canvas: Canvas, rect: RectF, radius: Float, dark: Boolean, alpha: Float = 1f) {
        if (alpha <= 0f || rect.width() <= 0f || rect.height() <= 0f) return
        var shader = sheenShader
        if (shader == null || sheenDark != dark || sheenTop != rect.top || sheenBottom != rect.bottom) {
            shader = LinearGradient(0f, rect.top, 0f, rect.bottom, sheenColors(dark), SHEEN_POSITIONS, Shader.TileMode.CLAMP)
            sheenShader = shader
            sheenDark = dark
            sheenTop = rect.top
            sheenBottom = rect.bottom
        }
        sheenPaint.shader = shader
        sheenPaint.alpha = (alpha.coerceAtMost(1f) * 255f + 0.5f).toInt()
        canvas.drawRoundRect(rect, radius, radius, sheenPaint)
    }

    /**
     * [EN] Draws the rim: a stroke of 1 dp ([RIM_WIDTH_DP] × `density`) in [rimColor], inset by half its width so it stays inside `rect`, faded by
     *      `alpha` (0 to 1). `color` and `widthPx` replace the rim's colour and width for an explicit border (the same inset).
     * [CN] 绘制细边：1 dp（[RIM_WIDTH_DP] × `density`）、颜色为 [rimColor] 的描边，向内缩进宽度的一半以保持在 `rect` 之内，按 `alpha`（0 到 1）淡化。
     *      `color` 与 `widthPx` 用显式边框的颜色与宽度替代细边的（缩进相同）。
     */
    fun drawRim(canvas: Canvas, rect: RectF, radius: Float, density: Float, dark: Boolean, alpha: Float = 1f, color: Int? = null, widthPx: Float? = null) {
        if (alpha <= 0f || rect.width() <= 0f || rect.height() <= 0f) return
        val width = widthPx ?: (RIM_WIDTH_DP * density)
        val base = color ?: rimColor(dark)
        val faded = if (alpha >= 1f) base else (base and 0x00FFFFFF) or (Math.round((base ushr 24) * alpha) shl 24)
        rimPaint.strokeWidth = width
        rimPaint.color = faded
        val inset = width / 2f
        scratch.set(rect.left + inset, rect.top + inset, rect.right - inset, rect.bottom - inset)
        canvas.drawRoundRect(scratch, radius, radius, rimPaint)
    }
}
