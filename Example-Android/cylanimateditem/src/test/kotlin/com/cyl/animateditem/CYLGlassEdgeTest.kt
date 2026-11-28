package com.cyl.animateditem

import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] `CYLGlassEdge.drawSheen` / `drawRim`, the one drawing of the glass edge: a gradient fill for the sheen, an inset 1 dp stroke in the rim colour.
 * [CN] `CYLGlassEdge.drawSheen` / `drawRim`，玻璃边缘唯一的绘制：高光为渐变填充，细边为向内缩进的 1 dp 描边。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLGlassEdgeTest {

    private class Drawn(val rect: RectF, val radius: Float, val style: Paint.Style, val color: Int, val alpha: Int, val strokeWidth: Float, val gradient: Boolean)

    private class RecordingCanvas : Canvas() {
        val drawn = mutableListOf<Drawn>()
        override fun drawRoundRect(rect: RectF, rx: Float, ry: Float, paint: Paint) {
            // [EN] Robolectric returns a null style for a paint that never set one (the default is FILL). [CN] 从未设置样式的画笔在 Robolectric 中返回 null（默认是 FILL）。
            drawn += Drawn(RectF(rect), rx, paint.style ?: Paint.Style.FILL, paint.color, paint.alpha, paint.strokeWidth, paint.shader is LinearGradient)
        }
    }

    private val rect = RectF(10f, 20f, 210f, 100f)

    @Test
    fun theSheenIsAGradientFillOverTheWholeRect() {
        val canvas = RecordingCanvas()
        CYLGlassEdge.drawSheen(canvas, rect, 40f, dark = false)
        val sheen = canvas.drawn.single()
        assertTrue(sheen.gradient)
        assertEquals(Paint.Style.FILL, sheen.style)
        assertEquals(rect, sheen.rect)
        assertEquals(40f, sheen.radius, 0f)
        assertEquals(255, sheen.alpha)
    }

    @Test
    fun theSheenAlphaFadesAndZeroDrawsNothing() {
        val canvas = RecordingCanvas()
        CYLGlassEdge.drawSheen(canvas, rect, 40f, dark = true, alpha = 0.5f)
        assertEquals(128, canvas.drawn.single().alpha)
        CYLGlassEdge.drawSheen(canvas, rect, 40f, dark = true, alpha = 0f)
        assertEquals(1, canvas.drawn.size)
    }

    @Test
    fun theRimIsAnInsetOneDpStrokeInTheRimColour() {
        val canvas = RecordingCanvas()
        CYLGlassEdge.drawRim(canvas, rect, 40f, density = 2f, dark = false)
        CYLGlassEdge.drawRim(canvas, rect, 40f, density = 2f, dark = true)
        val light = canvas.drawn[0]
        val dark = canvas.drawn[1]
        assertEquals(Paint.Style.STROKE, light.style)
        assertEquals(CYLGlassEdge.rimColor(false), light.color)
        assertEquals(CYLGlassEdge.rimColor(true), dark.color)
        assertEquals(2f, light.strokeWidth, 0f)
        assertEquals(RectF(11f, 21f, 209f, 99f), light.rect)
        assertTrue(!light.gradient)
    }

    @Test
    fun theRimAlphaScalesTheColourAlpha() {
        val canvas = RecordingCanvas()
        CYLGlassEdge.drawRim(canvas, rect, 40f, density = 1f, dark = false, alpha = 0.5f)
        assertEquals(Math.round(0xB3 * 0.5f), canvas.drawn.single().color ushr 24)
        assertEquals(0xFFFFFF, canvas.drawn.single().color and 0xFFFFFF)
        CYLGlassEdge.drawRim(canvas, rect, 40f, density = 1f, dark = false, alpha = 0f)
        assertEquals(1, canvas.drawn.size)
    }

    @Test
    fun anExplicitColourAndWidthReplaceTheRim() {
        val canvas = RecordingCanvas()
        CYLGlassEdge.drawRim(canvas, rect, 40f, density = 3f, dark = false, color = 0xFF07C160.toInt(), widthPx = 4f)
        val stroke = canvas.drawn.single()
        assertEquals(0xFF07C160.toInt(), stroke.color)
        assertEquals(4f, stroke.strokeWidth, 0f)
        assertEquals(RectF(12f, 22f, 208f, 98f), stroke.rect)
    }
}
