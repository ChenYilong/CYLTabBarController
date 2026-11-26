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
 *      While a glass view draws the pages, other glass views in them draw nothing (no glass inside glass), with one exception: after the
 *      pages it also draws the glass views BEHIND it that cover it ([glassViewsBehind]: the section card a tag sits on), so a tag is lighter
 *      than its card as on HarmonyOS; such a card samples only the pages it is given (depth 2 draws nothing). A glass view that sits
 *      inside its own `backdropSource` (e.g. a list cell, with the default source, the window's root) cannot sample it: drawing
 *      the source would draw the cells that are recording right now (`IllegalStateException`: "Recording currently in progress"),
 *      so it draws only the tint. The board drawn into the backdrop of a tag has no sheen and no rim ([drawForBackdrop]): the tag adds its own.
 * [CN] 任意视图的液态玻璃背景（与 iOS `CYLLiquidGlassView` 同名）：它后面的内容（页面，`backdropSource`）在圆角矩形内被模糊与折射，
 *      以 `glassTintColor` 着色，其上加自上而下渐变的高光，并以统一的 1 dp 细边（或显式的 `borderColor`/`borderWidth`）为边缘，
 *      数值与鸿蒙相同（`CYLGlassEdge.rimColor`、`sheenColors`）。`CYLLiquidGlass.isActive()` 为 false 或画布未硬件加速时不绘制（`isGlassDrawn` 为
 *      false），调用方保持其扁平背景。不接收触摸，对辅助功能隐藏。某个玻璃视图绘制页面时，页面中的其他玻璃视图不绘制（玻璃里不嵌玻璃）。
 *      例外：在页面之后，它还会绘制位于其后面并覆盖它的玻璃视图（[glassViewsBehind]：标签所在的分区卡片），因此标签比卡片更亮（与鸿蒙一致）；
 *      这样的卡片只采样交给它的页面（第 2 层什么也不绘制）。位于自己的 `backdropSource` 之内的玻璃视图（例如列表单元格，默认源为窗口根视图）不能采样它：绘制源会绘制正在录制的单元格
 *      （`IllegalStateException`："Recording currently in progress"），所以只绘制着色。绘制到标签背景中的看板没有高光与细边（[drawForBackdrop]）：标签自己再加。
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

    override fun onDraw(canvas: Canvas) = drawGlass(canvas, withEdge = true)

    /**
     * [EN] Draws this glass into the backdrop of a glass in FRONT of it (the tag's pass draws the section board this way): the sampled pages and the tint
     *      only, WITHOUT the sheen and the rim, so the glass on top does not light the same edge a second time (a double sheen). The on-screen drawing
     *      of this view ([onDraw]) is unchanged. Same guards as [onDraw] (not drawn, or depth 2 and above: nothing).
     * [CN] 把本玻璃绘制到其前面玻璃的背景中（标签的录制过程以此方式绘制分区面板）：只有被采样的页面与着色，不含高光与细边，
     *      这样上层玻璃不会把同一条边再照亮一次（双重高光）。本视图在屏幕上的绘制（[onDraw]）不变。守卫与 [onDraw] 相同（未绘制，或第 2 层及以上：什么也不画）。
     */
    internal fun drawForBackdrop(canvas: Canvas) = drawGlass(canvas, withEdge = false)

    private fun drawGlass(canvas: Canvas, withEdge: Boolean) {
        // [EN] Depth 0 (a glass on screen) and depth 1 (a card redrawn inside the pass of a glass on top of it, its glass child included) draw normally; depth 2 and above draw nothing.
        // [CN] 第 0 层（屏幕上的玻璃）与第 1 层（在其上方玻璃的录制过程中重绘的卡片，包括其玻璃子视图）正常绘制；第 2 层及以上什么也不绘制。
        if (!isGlassDrawn || drawDepth >= 2) return
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
            val nested = drawDepth == 1
            // [EN] Only a glass on screen (depth 0) looks for the glass behind it; the cards it draws are recorded with the plate in ONE pass (one blur, one saturation/brightness).
            // [CN] 只有屏幕上的玻璃（第 0 层）才寻找其后面的玻璃；它绘制的卡片与背板在同一次录制中完成（一次模糊、一次饱和度/亮度）。
            val behind = if (nested) emptyList<View>() else glassViewsBehind(this).filter { it !== source && !isInside(it) && !it.hasAncestor(source) }
            drawDepth++
            try {
                drawn = backdrop.draw(canvas, source, (here[0] - there[0]).toFloat(), (here[1] - there[1]).toFloat(), rect, radius, effects, behind, nested)
            } finally {
                drawDepth--
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
        if (!withEdge) return
        CYLGlassEdge.drawSheen(canvas, rect, radius, dark)
        // [EN] The edge: the explicit border (its colour and width) when set, else the uniform rim. [CN] 边缘：设置了显式边框时用它的颜色与宽度，否则为统一细边。
        val border = borderColor
        val explicit = borderWidth > 0f && border != null && android.graphics.Color.alpha(border) != 0
        CYLGlassEdge.drawRim(canvas, rect, radius, density, dark, 1f, if (explicit) border else null, if (explicit) borderWidth else null)
    }

    private fun View.hasAncestor(source: View): Boolean {
        var ancestor = parent
        while (ancestor != null) {
            if (ancestor === source) return true
            ancestor = ancestor.parent
        }
        return false
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

    internal companion object {
        /** How many glass passes are running (the UI thread only): 1 inside the pass of a glass on screen, 2 inside a card's own glass pass; at 2 glass views draw nothing (see onDraw). */
        internal var drawDepth = 0
    }
}
