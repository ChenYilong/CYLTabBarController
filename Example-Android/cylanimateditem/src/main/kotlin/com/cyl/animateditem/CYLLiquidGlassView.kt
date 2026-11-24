package com.cyl.animateditem

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.util.AttributeSet
import android.view.View

/**
 * [EN] A Liquid Glass background for any view (the same names as iOS `CYLLiquidGlassView`): what is behind it (the pages,
 *      `backdropSource`) is blurred and refracted inside a rounded rectangle, tinted with `glassTintColor` and edged with the
 *      glass highlight. Where `CYLLiquidGlass.isActive()` is false, or the canvas is not hardware accelerated, it draws nothing
 *      (`isGlassDrawn` is false), so the caller keeps its flat background. It takes no touches and is hidden from accessibility.
 *      While a glass view draws the pages, other glass views in them draw nothing (no glass inside glass).
 * [CN] 任意视图的液态玻璃背景（与 iOS `CYLLiquidGlassView` 同名）：它后面的内容（页面，`backdropSource`）在圆角矩形内被模糊与折射，
 *      以 `glassTintColor` 着色并加上玻璃高光边缘。`CYLLiquidGlass.isActive()` 为 false 或画布未硬件加速时不绘制（`isGlassDrawn` 为
 *      false），调用方保持其扁平背景。不接收触摸，对辅助功能隐藏。某个玻璃视图绘制页面时，页面中的其他玻璃视图不绘制（玻璃里不嵌玻璃）。
 */
internal class CYLLiquidGlassView @JvmOverloads constructor(context: Context, attrs: AttributeSet? = null) : View(context, attrs) {

    private val backdrop = CYLGlassBackdrop()
    private val highlight = CYLGlassHighlight()
    private val tintPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val rect = RectF()
    private val here = IntArray(2)
    private val there = IntArray(2)

    /**
     * [EN] The tint of the glass, e.g. a tag's background color (an ARGB color); `null` for none.
     * [CN] 玻璃的着色，例如标签的背景色（ARGB 颜色）；`null` 表示不着色。
     */
    var glassTintColor: Int? = null
        set(value) {
            field = value
            invalidate()
        }

    /**
     * [EN] The corner radius the glass is clipped to, in px (at most half the shorter side).
     * [CN] 玻璃裁剪所用的圆角半径，单位像素（最大为较短边的一半）。
     */
    var cornerRadius: Float = 0f
        set(value) {
            field = value
            invalidate()
        }

    /**
     * [EN] The view drawn behind the glass; `null` (the default) is the root of the window's views.
     * [CN] 绘制在玻璃后面的视图；`null`（默认）为窗口视图的根。
     */
    var backdropSource: View? = null
        set(value) {
            field = value
            invalidate()
        }

    /**
     * [EN] Whether the glass is drawn now (`CYLLiquidGlass.isActive()`, a size and no software layer); when false the caller
     *      draws its flat background.
     * [CN] 现在是否绘制玻璃（`CYLLiquidGlass.isActive()`、有尺寸且不是软件图层）；为 false 时由调用方绘制扁平背景。
     */
    val isGlassDrawn: Boolean
        get() = CYLLiquidGlass.isActive() && width > 0 && height > 0 && layerType != LAYER_TYPE_SOFTWARE

    init {
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
        isClickable = false
        isFocusable = false
    }

    /**
     * [EN] Draws the glass again, e.g. after `CYLLiquidGlass.activeOverride` changed. [CN] 重新绘制玻璃，例如 `CYLLiquidGlass.activeOverride` 改变之后。
     */
    fun applyEffect() {
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        if (!isGlassDrawn || drawingGlass) return
        val source = backdropSource ?: rootView
        if (source.width <= 0 || source.height <= 0) return
        rect.set(0f, 0f, width.toFloat(), height.toFloat())
        val radius = cornerRadius.coerceAtMost(minOf(rect.width(), rect.height()) / 2f)
        val density = resources.displayMetrics.density
        getLocationInWindow(here)
        source.getLocationInWindow(there)
        val effects = CYLGlassEffects(
            saturation = 1.8f,
            blurRadius = 8f * density,
            refractionHeight = minOf(10f * density, rect.height() / 2f),
            refractionAmount = 14f * density,
        )
        drawingGlass = true
        val drawn = try {
            backdrop.draw(canvas, source, (here[0] - there[0]).toFloat(), (here[1] - there[1]).toFloat(), rect, radius, effects)
        } finally {
            drawingGlass = false
        }
        glassTintColor?.let {
            tintPaint.color = it
            canvas.drawRoundRect(rect, radius, radius, tintPaint)
        }
        if (drawn) highlight.draw(canvas, rect, radius, density, 1f)
    }

    private companion object {
        /** Set while a glass view draws the pages, so the glass views among them draw nothing. */
        var drawingGlass = false
    }
}
