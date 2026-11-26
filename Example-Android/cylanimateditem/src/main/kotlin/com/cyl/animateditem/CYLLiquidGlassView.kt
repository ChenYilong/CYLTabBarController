package com.cyl.animateditem

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.util.AttributeSet
import android.view.View

/**
 * [EN] A Liquid Glass background for any view (the same names as iOS `CYLLiquidGlassView`): what is behind it (the pages,
 *      `backdropSource`) is blurred and refracted inside a rounded rectangle, tinted with `glassTintColor`, lit by the sheen
 *      (a top-to-bottom gradient over the tint) and edged with the uniform 1 dp rim (or the explicit `borderColor`/`borderWidth`),
 *      the same values as HarmonyOS (`CYLGlassEdge.rimColor`, `sheenColors`). Where `CYLLiquidGlass.isActive()` is false, or the canvas is not hardware accelerated, it draws nothing
 *      (`isGlassDrawn` is false), so the caller keeps its flat background. It takes no touches and is hidden from accessibility.
 *      While a glass view draws the pages, other glass views in them draw nothing (no glass inside glass). A glass view that sits
 *      inside its own `backdropSource` (e.g. a list cell, with the default source, the window's root) cannot sample it: drawing
 *      the source would draw the cells that are recording right now (`IllegalStateException`: "Recording currently in progress"),
 *      so it draws only the tint.
 * [CN] 任意视图的液态玻璃背景（与 iOS `CYLLiquidGlassView` 同名）：它后面的内容（页面，`backdropSource`）在圆角矩形内被模糊与折射，
 *      以 `glassTintColor` 着色，其上加自上而下渐变的高光，并以统一的 1 dp 细边（或显式的 `borderColor`/`borderWidth`）为边缘，
 *      数值与鸿蒙相同（`CYLGlassEdge.rimColor`、`sheenColors`）。`CYLLiquidGlass.isActive()` 为 false 或画布未硬件加速时不绘制（`isGlassDrawn` 为
 *      false），调用方保持其扁平背景。不接收触摸，对辅助功能隐藏。某个玻璃视图绘制页面时，页面中的其他玻璃视图不绘制（玻璃里不嵌玻璃）。
 *      位于自己的 `backdropSource` 之内的玻璃视图（例如列表单元格，默认源为窗口根视图）不能采样它：绘制源会绘制正在录制的单元格
 *      （`IllegalStateException`："Recording currently in progress"），所以只绘制着色。
 */
internal class CYLLiquidGlassView @JvmOverloads constructor(context: Context, attrs: AttributeSet? = null) : View(context, attrs) {

    private val backdrop = CYLGlassBackdrop()
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
     * [EN] The width of an explicit border, in px; 0 (the default) for none (the uniform rim is drawn then).
     * [CN] 显式边框的宽度，单位像素；0（默认）表示没有（此时绘制统一细边）。
     */
    var borderWidth: Float = 0f
        set(value) {
            field = value
            invalidate()
        }

    /**
     * [EN] The colour of an explicit border (ARGB); `null` or fully transparent for none. With a width above 0 it replaces the rim as the
     *      edge, and the sheen is still drawn under it.
     * [CN] 显式边框的颜色（ARGB）；`null` 或完全透明表示没有。宽度大于 0 时它取代细边作为边缘，高光仍绘制在它之下。
     */
    var borderColor: Int? = null
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
        val sampled = !isInside(source)
        getLocationInWindow(here)
        source.getLocationInWindow(there)
        val effects = CYLGlassEffects(
            // [EN] The item glass of HarmonyOS (saturation 1.6, brightness 1.05), only on this sampled path: the view exists only where the glass style is drawn (isGlassDrawn), flat items get no effect.
            // [CN] 与鸿蒙相同的条目玻璃（饱和度 1.6、亮度 1.05），仅在此采样路径：本视图只在绘制玻璃样式时存在（isGlassDrawn），扁平条目没有该效果。
            saturation = CYLLiquidGlass.ITEM_SATURATION,
            brightness = CYLLiquidGlass.ITEM_BRIGHTNESS,
            blurRadius = 8f * density,
            refractionHeight = minOf(10f * density, rect.height() / 2f),
            refractionAmount = 14f * density,
        )
        // [EN] Inside its own source: the source's draw would redraw this view's recording ancestors, so only the tint is drawn.
        // [CN] 位于自己的源之内：绘制源会重绘本视图正在录制的祖先，所以只绘制着色。
        var drawn = false
        if (sampled) {
            drawingGlass = true
            try {
                drawn = backdrop.draw(canvas, source, (here[0] - there[0]).toFloat(), (here[1] - there[1]).toFloat(), rect, radius, effects)
            } finally {
                drawingGlass = false
            }
        }
        // [EN] Without sampled glass (a tag in a list) a clear tint would draw nothing: the default frosted tint fills the shape then, so the tag is visible.
        // [CN] 没有采样的玻璃（列表中的标签）时，透明着色什么也画不出来：此时用默认磨砂着色填充形状，标签才看得见。
        val configured = glassTintColor
        val fill = if (!drawn && (configured == null || android.graphics.Color.alpha(configured) == 0)) {
            CYLAnimatedItemBackgroundRenderer.defaultGlassTint(resources)
        } else {
            configured
        }
        fill?.let {
            tintPaint.color = it
            canvas.drawRoundRect(rect, radius, radius, tintPaint)
        }
        val dark = CYLGlassEdge.isDark(resources)
        // [EN] The sheen over the tint, top to bottom, for sampled and non-sampled glass alike. [CN] 着色之上的高光，自上而下，采样与非采样玻璃相同。
        CYLGlassEdge.drawSheen(canvas, rect, radius, dark)
        // [EN] The edge: the explicit border (its colour and width) when set, else the uniform rim. [CN] 边缘：设置了显式边框时用它的颜色与宽度，否则为统一细边。
        val border = borderColor
        val explicit = borderWidth > 0f && border != null && android.graphics.Color.alpha(border) != 0
        CYLGlassEdge.drawRim(canvas, rect, radius, density, dark, 1f, if (explicit) border else null, if (explicit) borderWidth else null)
    }

    /**
     * [EN] Whether this view is `source` or one of its descendants: then `source` is in a drawing pass while this view draws.
     * [CN] 本视图是否为 `source` 或其后代：此时本视图绘制时 `source` 正处于绘制过程中。
     */
    internal fun isInside(source: View): Boolean {
        if (source === this) return true
        var ancestor = parent
        while (ancestor != null) {
            if (ancestor === source) return true
            ancestor = ancestor.parent
        }
        return false
    }

    private companion object {
        /** Set while a glass view draws the pages, so the glass views among them draw nothing. */
        var drawingGlass = false
    }
}
