package com.cyl.animateditem

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.drawable.GradientDrawable
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The lit glass edge, one definition shared with HarmonyOS: the uniform 1 dp rim (white 70% light, white 22% dark), the sheen over the tint,
 * and an explicit border that keeps its colour on top of the glass.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLLiquidGlassEdgeTest {

    private class Drawn(val style: Paint.Style, val color: Int, val strokeWidth: Float, val hasGradient: Boolean)

    private class RecordingCanvas : Canvas() {
        val drawn = mutableListOf<Drawn>()
        private fun record(paint: Paint) {
            // [EN] Robolectric returns a null style for a paint that never set one (the default is FILL). [CN] 从未设置样式的画笔在 Robolectric 中返回 null（默认是 FILL）。
            drawn += Drawn(paint.style ?: Paint.Style.FILL, paint.color, paint.strokeWidth, paint.shader is LinearGradient)
        }
        override fun drawRoundRect(rect: RectF, rx: Float, ry: Float, paint: Paint) = record(paint)
        override fun drawRoundRect(left: Float, top: Float, right: Float, bottom: Float, rx: Float, ry: Float, paint: Paint) = record(paint)
        val strokes get() = drawn.filter { it.style == Paint.Style.STROKE }
        val sheens get() = drawn.filter { it.hasGradient }
    }

    private val context: android.content.Context = ApplicationProvider.getApplicationContext()
    private val density get() = context.resources.displayMetrics.density

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    private fun glassItem(width: Int = 200, height: Int = 80, configure: CYLAnimatedItemView.() -> Unit = {}): CYLAnimatedItemView {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val item = CYLAnimatedItemView(context)
        item.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        item.configure()
        item.layout(0, 0, width, height)
        return item
    }

    private fun drawGlass(item: CYLAnimatedItemView): RecordingCanvas {
        val canvas = RecordingCanvas()
        (item.itemLiquidGlassView as CYLLiquidGlassView).draw(canvas)
        return canvas
    }

    private fun strokeWidthOf(box: GradientDrawable): Int {
        val state = GradientDrawable::class.java.getDeclaredField("mGradientState").apply { isAccessible = true }.get(box)
        return state.javaClass.getDeclaredField("mStrokeWidth").apply { isAccessible = true }.getInt(state)
    }

    @Test
    fun theConstantsEqualTheHarmonyOSValues() {
        assertEquals(0xB3FFFFFF.toInt(), CYLGlassEdge.rimColor(false))
        assertEquals(0x38FFFFFF, CYLGlassEdge.rimColor(true))
        assertEquals(1f, CYLGlassEdge.RIM_WIDTH_DP, 0f)
        assertArrayEquals(intArrayOf(0x66FFFFFF, 0x14FFFFFF, 0x00FFFFFF, 0x1FFFFFFF), CYLGlassEdge.sheenColors(false))
        assertArrayEquals(intArrayOf(0x2EFFFFFF, 0x0AFFFFFF, 0x00FFFFFF, 0x12FFFFFF), CYLGlassEdge.sheenColors(true))
        assertArrayEquals(floatArrayOf(0f, 0.35f, 0.6f, 1f), CYLGlassEdge.SHEEN_POSITIONS, 0f)
    }

    @Test
    fun aDrawnGlassDrawsTheUniformRimAndTheSheenInLightMode() {
        val canvas = drawGlass(glassItem())
        assertEquals(1, canvas.strokes.size)
        assertEquals(CYLGlassEdge.rimColor(false), canvas.strokes[0].color)
        assertEquals(density, canvas.strokes[0].strokeWidth, 0.001f)
        assertEquals("one sheen over the tint", 1, canvas.sheens.size)
    }

    @Test
    @Config(sdk = [34], qualifiers = "night")
    fun theRimIsTheDarkOneInNightMode() {
        val canvas = drawGlass(glassItem())
        assertEquals(1, canvas.strokes.size)
        assertEquals(CYLGlassEdge.rimColor(true), canvas.strokes[0].color)
        assertEquals(density, canvas.strokes[0].strokeWidth, 0.001f)
        assertEquals(1, canvas.sheens.size)
    }

    @Test
    fun anExplicitBorderKeepsItsColourOnTheGlassAndTheBoxDrawsNoStroke() {
        val item = glassItem { itemBorderWidth = 2f; itemBorderColor = 0xFF07C160.toInt() }
        val canvas = drawGlass(item)
        assertEquals(1, canvas.strokes.size)
        assertEquals(0xFF07C160.toInt(), canvas.strokes[0].color)
        assertEquals(Math.round(2f * density).toFloat(), canvas.strokes[0].strokeWidth, 0.001f)
        assertEquals("the sheen still applies", 1, canvas.sheens.size)
        assertEquals("the host box does not draw it under the glass", 0, strokeWidthOf(item.background as GradientDrawable))
    }

    @Test
    fun aBoardLikeLargeViewKeepsItsBorderAndGetsTheSheen() {
        val item = glassItem(width = 600, height = 900) {
            itemCornerRadius = 24f
            itemBorderWidth = 1f
            itemBorderColor = 0xFFFF8800.toInt()
        }
        val canvas = drawGlass(item)
        assertEquals(0xFFFF8800.toInt(), canvas.strokes.single().color)
        assertEquals(1, canvas.sheens.size)
        assertEquals(0, strokeWidthOf(item.background as GradientDrawable))
    }

    @Test
    fun aBoardLikeViewWithoutABorderGetsTheRim() {
        val item = glassItem(width = 600, height = 900) { itemCornerRadius = 24f }
        val canvas = drawGlass(item)
        assertEquals(CYLGlassEdge.rimColor(false), canvas.strokes.single().color)
    }

    @Test
    fun aTransparentBorderColourFallsBackToTheRim() {
        val canvas = drawGlass(glassItem { itemBorderWidth = 2f; itemBorderColor = Color.TRANSPARENT })
        assertEquals(CYLGlassEdge.rimColor(false), canvas.strokes.single().color)
    }

    @Test
    fun flatStyleAndInactiveGlassKeepTheBoxStroke() {
        val density = density
        val flat = CYLAnimatedItemView(context)
        flat.itemBackgroundColor = 0xFF336699.toInt()
        flat.itemBorderWidth = 2f
        flat.itemBorderColor = Color.RED
        flat.layout(0, 0, 200, 80)
        assertEquals(Math.round(2f * density), strokeWidthOf(flat.background as GradientDrawable))

        CYLAnimatedItemView.liquidGlassActiveOverride = false
        val inactive = CYLAnimatedItemView(context)
        inactive.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        inactive.itemBorderWidth = 2f
        inactive.itemBorderColor = Color.RED
        inactive.layout(0, 0, 200, 80)
        assertTrue(inactive.itemLiquidGlassView == null)
        assertEquals(Math.round(2f * density), strokeWidthOf(inactive.background as GradientDrawable))
        assertNotNull(inactive.background)
    }
}
