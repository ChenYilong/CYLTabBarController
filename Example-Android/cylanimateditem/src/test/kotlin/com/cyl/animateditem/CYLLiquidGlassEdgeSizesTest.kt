package com.cyl.animateditem

import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.drawable.GradientDrawable
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * A Liquid Glass item without an explicit border gets the same rim and sheen at any size (a tag capsule and a board).
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLLiquidGlassEdgeSizesTest {

    private class Drawn(val style: Paint.Style, val color: Int, val strokeWidth: Float, val gradient: Boolean, val order: Int)

    private class RecordingCanvas : Canvas() {
        val drawn = mutableListOf<Drawn>()
        private fun record(paint: Paint) {
            drawn += Drawn(paint.style ?: Paint.Style.FILL, paint.color, paint.strokeWidth, paint.shader is LinearGradient, drawn.size)
        }
        override fun drawRoundRect(rect: RectF, rx: Float, ry: Float, paint: Paint) = record(paint)
        override fun drawRoundRect(left: Float, top: Float, right: Float, bottom: Float, rx: Float, ry: Float, paint: Paint) = record(paint)
        val strokes get() = drawn.filter { it.style == Paint.Style.STROKE }
        val sheens get() = drawn.filter { it.gradient }
    }

    private val context: android.content.Context = ApplicationProvider.getApplicationContext()
    private val density get() = context.resources.displayMetrics.density

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    private fun glassItem(widthDp: Int, heightDp: Int, padded: Boolean = false): CYLAnimatedItemView {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val item = CYLAnimatedItemView(context)
        item.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        if (padded) item.setPadding(12, 8, 12, 8)
        item.layout(0, 0, Math.round(widthDp * density), Math.round(heightDp * density))
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

    private fun check(dark: Boolean) {
        val tag = glassItem(120, 32)
        val board = glassItem(360, 200)
        val padded = glassItem(120, 32, padded = true)
        for (item in listOf(tag, board, padded)) {
            assertNotNull(item.itemLiquidGlassView)
            val canvas = drawGlass(item)
            assertEquals(1, canvas.strokes.size)
            val rim = canvas.strokes[0]
            assertEquals(CYLGlassEdge.rimColor(dark), rim.color)
            assertEquals(CYLGlassEdge.RIM_WIDTH_DP * density, rim.strokeWidth, 0.001f)
            assertEquals(Paint.Style.STROKE, rim.style)
            assertEquals("one sheen gradient", 1, canvas.sheens.size)
            assertEquals("the sheen is drawn before the rim", true, canvas.sheens[0].order < rim.order)
            assertEquals("the host box draws no stroke under the glass", 0, strokeWidthOf(item.background as GradientDrawable))
        }
        // [EN] The sheen shader is the one CYLGlassEdge builds: its colours/positions are the shared constants (checked on the constants, the shader is opaque).
        assertEquals(CYLGlassEdge.sheenColors(dark).size, CYLGlassEdge.SHEEN_POSITIONS.size)
    }

    @Test
    fun tagAndBoardGetTheSameRimAndSheenInLightMode() = check(dark = false)

    @Test
    @Config(sdk = [34], qualifiers = "night")
    fun tagAndBoardGetTheSameRimAndSheenInNightMode() = check(dark = true)

    @Test
    fun theGlassLayerFillsTheHostAndIsNotClippedToItsPadding() {
        val item = glassItem(120, 32, padded = true)
        val glass = item.itemLiquidGlassView!!
        assertEquals(item.width, glass.width)
        assertEquals(item.height, glass.height)
        assertFalse("clipToPadding would clip the rim on a padded capsule", item.clipToPadding)
    }

    @Test
    fun theGlassLayerFollowsASizeChange() {
        val item = glassItem(120, 32)
        item.layout(0, 0, Math.round(360 * density), Math.round(200 * density))
        val glass = item.itemLiquidGlassView!!
        assertEquals(item.width, glass.width)
        assertEquals(item.height, glass.height)
    }
}
