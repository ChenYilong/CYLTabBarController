package com.cyl.animateditem

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [CYLLiquidGlassView.drawForBackdrop]: the glass as it goes into the backdrop of a glass in front of it (a section board behind a tag): the tint and fill
 * only, no sheen and no rim, so the glass on top does not light the same edge twice. The normal (on-screen) draw keeps the tint, the sheen and the rim.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLLiquidGlassBackdropEdgeTest {

    private class Drawn(val style: Paint.Style, val color: Int, val hasGradient: Boolean)

    private class RecordingCanvas : Canvas() {
        val drawn = mutableListOf<Drawn>()
        private fun record(paint: Paint) {
            // [EN] Robolectric returns a null style for a paint that never set one (the default is FILL). [CN] 从未设置样式的画笔在 Robolectric 中返回 null（默认是 FILL）。
            drawn += Drawn(paint.style ?: Paint.Style.FILL, paint.color, paint.shader is LinearGradient)
        }
        override fun drawRoundRect(rect: RectF, rx: Float, ry: Float, paint: Paint) = record(paint)
        override fun drawRoundRect(left: Float, top: Float, right: Float, bottom: Float, rx: Float, ry: Float, paint: Paint) = record(paint)
        val strokes get() = drawn.filter { it.style == Paint.Style.STROKE }
        val sheens get() = drawn.filter { it.hasGradient }
        val fills get() = drawn.filter { it.style == Paint.Style.FILL && !it.hasGradient }
    }

    private val context: android.content.Context = ApplicationProvider.getApplicationContext()

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
        CYLLiquidGlassView.drawDepth = 0
    }

    private fun glass(tint: Int? = null): CYLLiquidGlassView {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val item = CYLAnimatedItemView(context)
        item.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        if (tint != null) item.itemBackgroundColor = tint
        item.layout(0, 0, 200, 80)
        return item.itemLiquidGlassView as CYLLiquidGlassView
    }

    @Test
    fun theBackdropDrawHasTheTintButNoSheenAndNoStroke() {
        val canvas = RecordingCanvas()
        glass().drawForBackdrop(canvas)
        assertTrue("the tint / fill is drawn", canvas.fills.isNotEmpty())
        assertEquals("no sheen shader paint", 0, canvas.sheens.size)
        assertEquals("no rim stroke", 0, canvas.strokes.size)
    }

    @Test
    fun theBackdropDrawKeepsAnExplicitTintAndStillHasNoEdge() {
        val canvas = RecordingCanvas()
        glass(Color.argb(0x40, 0x30, 0xD1, 0x58)).drawForBackdrop(canvas)
        assertTrue(canvas.fills.any { Color.alpha(it.color) != 0 })
        assertEquals(0, canvas.sheens.size)
        assertEquals(0, canvas.strokes.size)
    }

    @Test
    fun theNormalDrawOfTheSameViewStillHasTheTintTheSheenAndTheRim() {
        val view = glass()
        val canvas = RecordingCanvas()
        view.draw(canvas)
        assertTrue(canvas.fills.isNotEmpty())
        assertEquals(1, canvas.sheens.size)
        assertEquals(1, canvas.strokes.size)
        val backdrop = RecordingCanvas()
        view.drawForBackdrop(backdrop)
        val again = RecordingCanvas()
        view.draw(again)
        assertEquals("a backdrop draw leaves the on-screen draw unchanged", 1, again.sheens.size)
        assertEquals(1, again.strokes.size)
    }

    @Test
    fun theBackdropDrawDrawsNothingAtDepthTwoOrWhenNotDrawn() {
        val view = glass()
        CYLLiquidGlassView.drawDepth = 2
        val deep = RecordingCanvas()
        view.drawForBackdrop(deep)
        assertEquals(0, deep.drawn.size)
        CYLLiquidGlassView.drawDepth = 0
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        val off = RecordingCanvas()
        view.drawForBackdrop(off)
        assertEquals(0, off.drawn.size)
    }
}
