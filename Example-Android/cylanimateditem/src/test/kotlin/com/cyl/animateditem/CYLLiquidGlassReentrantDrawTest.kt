package com.cyl.animateditem

import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.widget.FrameLayout
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * A glass view inside the view it samples (a list cell whose source is the window's root): the cell is recording its display
 * list, and drawing the source would draw the cell again (`IllegalStateException`: "Recording currently in progress"). The glass
 * draws only its tint then. [RecordingGroup] throws that exception from `draw` while its `dispatchDraw` runs, like a view whose
 * `RenderNode` is recording.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLLiquidGlassReentrantDrawTest {

    private class RecordingGroup(context: Context) : FrameLayout(context) {
        var recording = false
        var sampledWhileRecording = 0

        override fun draw(canvas: Canvas) {
            if (recording) {
                sampledWhileRecording++
                throw IllegalStateException("Recording currently in progress - missing #endRecording() call?")
            }
            super.draw(canvas)
        }
    }

    /** A hardware-accelerated canvas that remembers the tint it was asked to draw. */
    private class TintCanvas : Canvas() {
        val tints = mutableListOf<Int>()
        override fun isHardwareAccelerated(): Boolean = true
        override fun drawRoundRect(rect: RectF, rx: Float, ry: Float, paint: Paint) {
            tints += paint.color
        }
    }

    private val context: Context = ApplicationProvider.getApplicationContext()

    @After
    fun reset() {
        CYLLiquidGlass.activeOverride = null
    }

    private fun cellInPage(): Triple<RecordingGroup, FrameLayout, CYLLiquidGlassView> {
        val page = RecordingGroup(context)
        val cell = FrameLayout(context)
        val glass = CYLLiquidGlassView(context)
        glass.glassTintColor = 0x66FF8800
        glass.cornerRadius = 12f
        cell.addView(glass, FrameLayout.LayoutParams(200, 80))
        page.addView(cell, FrameLayout.LayoutParams(200, 80))
        page.layout(0, 0, 400, 800)
        cell.layout(0, 0, 200, 80)
        glass.layout(0, 0, 200, 80)
        return Triple(page, cell, glass)
    }

    @Test
    fun aViewInsideItsSourceIsDetected() {
        val (page, cell, glass) = cellInPage()
        assertTrue(glass.isInside(page))
        assertTrue(glass.isInside(cell))
        assertTrue(glass.isInside(glass))
        assertFalse("a sibling page is not an ancestor", glass.isInside(FrameLayout(context)))
    }

    @Test
    fun theDefaultSourceIsTheRootThatContainsTheCellSoOnlyTheTintIsDrawn() {
        val (page, _, glass) = cellInPage()
        page.recording = true
        val canvas = TintCanvas()
        glass.draw(canvas)
        assertEquals("the page is not drawn while it records", 0, page.sampledWhileRecording)
        assertEquals("the tint fallback", listOf(0x66FF8800), canvas.tints)
    }

    @Test
    fun anExplicitAncestorSourceDrawsOnlyTheTintToo() {
        val (page, cell, glass) = cellInPage()
        glass.backdropSource = cell
        page.recording = true
        val canvas = TintCanvas()
        glass.draw(canvas)
        assertEquals(0, page.sampledWhileRecording)
        assertEquals(listOf(0x66FF8800), canvas.tints)
    }

    @Test
    fun aFailingRecordingIsCaughtAndTheTintIsStillDrawn() {
        // [EN] A source that is NOT an ancestor but throws while recording: the last-resort catch keeps the draw alive.
        val (page, _, glass) = cellInPage()
        val other = RecordingGroup(context)
        other.layout(0, 0, 400, 800)
        other.recording = true
        glass.backdropSource = other
        val canvas = TintCanvas()
        glass.draw(canvas)
        assertEquals("the tint fallback survives the exception", listOf(0x66FF8800), canvas.tints)
        assertEquals(0, page.sampledWhileRecording)
    }
}
