package com.cyl.animateditem

import android.app.Activity
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.view.View
import android.widget.FrameLayout
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [glassViewsBehind]: the section card (a glass [CYLAnimatedItemView]) drawn before a tag that contains it is found; nothing else is.
 * The views are attached to an activity's window, as the discovery requires.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLGlassBehindTest {

    private val activity: Activity = Robolectric.buildActivity(Activity::class.java).setup().get()
    private val context: Context = activity
    private val list = FrameLayout(context)

    init {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        activity.setContentView(list, FrameLayout.LayoutParams(1000, 2000))
        list.layout(0, 0, 1000, 2000)
    }

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
        CYLLiquidGlassView.drawDepth = 0
    }

    private fun item(parent: FrameLayout, glass: Boolean, l: Int, t: Int, r: Int, b: Int): CYLAnimatedItemView {
        val view = CYLAnimatedItemView(context)
        if (glass) view.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        parent.addView(view, FrameLayout.LayoutParams(r - l, b - t))
        view.layout(l, t, r, b)
        return view
    }

    private fun glassOf(tag: CYLAnimatedItemView): View = tag.itemLiquidGlassView!!

    @Test
    fun theBoardBeforeATagThatItContainsIsFound() {
        val board = item(list, true, 0, 0, 600, 400)
        val tag = item(list, true, 20, 20, 120, 60)
        assertTrue(board.isAttachedToWindow)
        assertEquals(listOf<View>(board), glassViewsBehind(glassOf(tag)))
    }

    @Test
    fun aSiblingAfterTheTagIsNotFound() {
        val tag = item(list, true, 20, 20, 120, 60)
        item(list, true, 0, 0, 600, 400)
        assertEquals(emptyList<View>(), glassViewsBehind(glassOf(tag)))
    }

    @Test
    fun aBoardThatDoesNotContainTheTagIsNotFound() {
        item(list, true, 0, 0, 600, 400)
        val tag = item(list, true, 20, 500, 120, 540)
        assertEquals(emptyList<View>(), glassViewsBehind(glassOf(tag)))
    }

    @Test
    fun anAncestorAndAFlatItemAreNotFound() {
        item(list, false, 0, 0, 600, 400)
        val outer = item(list, true, 0, 0, 600, 400)
        val tag = item(outer, true, 20, 20, 120, 60)
        assertEquals(emptyList<View>(), glassViewsBehind(glassOf(tag)))
    }

    @Test
    fun aTagInACellInsideTheListStillFindsTheBoard() {
        val board = item(list, true, 0, 0, 600, 400)
        val cell = FrameLayout(context)
        list.addView(cell, FrameLayout.LayoutParams(200, 100))
        cell.layout(100, 100, 300, 200)
        val tag = item(cell, true, 10, 10, 110, 50)
        assertEquals(listOf<View>(board), glassViewsBehind(glassOf(tag)))
        cell.translationY = 1000f
        assertEquals("moved out of the board by the cell's translation", emptyList<View>(), glassViewsBehind(glassOf(tag)))
    }

    @Test
    fun theOuterBoardIsFirstInTheZOrder() {
        val back = item(list, true, 0, 0, 800, 800)
        val board = item(list, true, 0, 0, 600, 400)
        val cell = FrameLayout(context)
        list.addView(cell, FrameLayout.LayoutParams(200, 100))
        cell.layout(100, 100, 300, 200)
        val tag = item(cell, true, 10, 10, 110, 50)
        assertEquals(listOf<View>(back, board), glassViewsBehind(glassOf(tag)))
    }

    @Test
    fun aHigherElevationBoardIsDrawnLaterSoItIsNotBehind() {
        val board = item(list, true, 0, 0, 600, 400)
        val tag = item(list, true, 20, 20, 120, 60)
        assertEquals(listOf<View>(board), glassViewsBehind(glassOf(tag)))
        board.elevation = 10f
        assertEquals("a lower index but a higher z: drawn after the tag", emptyList<View>(), glassViewsBehind(glassOf(tag)))
    }

    @Test
    fun aHiddenOrTransparentBoardIsNotFound() {
        val board = item(list, true, 0, 0, 600, 400)
        val tag = item(list, true, 20, 20, 120, 60)
        board.alpha = 0f
        assertEquals(emptyList<View>(), glassViewsBehind(glassOf(tag)))
        board.alpha = 1f
        board.visibility = View.INVISIBLE
        assertEquals(emptyList<View>(), glassViewsBehind(glassOf(tag)))
    }

    /** A hardware-accelerated canvas that remembers the tints it was asked to draw. */
    private class TintCanvas : Canvas() {
        val tints = mutableListOf<Int>()
        override fun isHardwareAccelerated(): Boolean = true
        override fun drawRoundRect(rect: RectF, rx: Float, ry: Float, paint: Paint) {
            tints += paint.color
        }
    }

    @Test
    fun aBoardGlassRedrawnAtDepthOneStillDrawsItsTintAndAtDepthTwoNothing() {
        // [EN] No plate: the board sits inside the window root, so its glass takes the tint-only path that a bare Canvas can record (the sampled path needs hardware layers). [CN] 没有背景板：卡片位于窗口根视图之内，其玻璃走仅着色的路径，裸 Canvas 能记录该路径（采样路径需要硬件图层）。
        val board = item(list, true, 0, 0, 200, 80)
        val glass = glassOf(board) as CYLLiquidGlassView
        glass.glassTintColor = 0x66FF8800
        CYLLiquidGlassView.drawDepth = 1
        val one = TintCanvas()
        glass.draw(one)
        assertEquals("depth 1 draws the tint", 0x66FF8800, one.tints.first())
        assertEquals("the depth is restored", 1, CYLLiquidGlassView.drawDepth)
        CYLLiquidGlassView.drawDepth = 2
        val two = TintCanvas()
        glass.draw(two)
        assertEquals("depth 2 draws nothing", emptyList<Int>(), two.tints)
    }
}
