package com.cyl.animateditem

import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] `itemContentHorizontalInset` is the partner of `itemCornerRadius`: unset, Liquid Glass (a capsule) gets 14 dp between the outer border and the
 *      content, flat gets 0; an explicit value wins; the same condition (`resolvedItemBackgroundStyle`) decides both.
 * [CN] `itemContentHorizontalInset` 与 `itemCornerRadius` 一一对应：未设置时液态玻璃（胶囊）在外侧边框与内容之间为 14 dp，扁平为 0；显式值优先。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemContentInsetTest {

    private val context = ApplicationProvider.getApplicationContext<android.content.Context>()

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    private fun wrapWidth(view: CYLAnimatedItemView): Int {
        val unspecified = android.view.View.MeasureSpec.makeMeasureSpec(0, android.view.View.MeasureSpec.UNSPECIFIED)
        view.measure(unspecified, unspecified)
        return view.measuredWidth
    }

    @Test
    fun unsetIsFourteenOnGlassAndZeroOnFlat() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val view = CYLAnimatedItemView(context)
        assertEquals(0f, view.resolvedItemContentHorizontalInset, 0f)
        view.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        assertEquals(CYLAnimatedItemLiquidGlassContentInset, view.resolvedItemContentHorizontalInset, 0f)
    }

    @Test
    fun glassOnADeviceWithoutGlassStaysFlatAndGetsNoInset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        val view = CYLAnimatedItemView(context)
        view.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        assertEquals("the unset radius is square there, so the inset is 0 too", 0f, view.resolvedItemContentHorizontalInset, 0f)
    }

    @Test
    fun anExplicitValueWinsAlsoZeroOnGlass() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val view = CYLAnimatedItemView(context)
        view.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        view.itemContentHorizontalInset = 0f
        assertEquals(0f, view.resolvedItemContentHorizontalInset, 0f)
        view.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.Flat
        view.itemContentHorizontalInset = 20f
        assertEquals(20f, view.resolvedItemContentHorizontalInset, 0f)
    }

    @Test
    fun theWrapContentWidthGrowsByTwiceTheInset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val view = CYLAnimatedItemView(context)
        view.title = "Spring camping"
        val flat = wrapWidth(view)
        view.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        val density = context.resources.displayMetrics.density
        assertEquals(flat + 2 * (CYLAnimatedItemLiquidGlassContentInset * density).toInt(), wrapWidth(view))
    }

    @Test
    fun aFlatStackKeepsItsMarginsAndAGlassStackAddsTheInsetOnTheSides() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val stack = CYLAnimatedItemStackView(context)
        val density = context.resources.displayMetrics.density
        val flatLeft = (stack.stackView.layoutParams as android.widget.FrameLayout.LayoutParams).leftMargin
        stack.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        val glass = stack.stackView.layoutParams as android.widget.FrameLayout.LayoutParams
        assertEquals(flatLeft + (CYLAnimatedItemLiquidGlassContentInset * density).toInt(), glass.leftMargin)
        assertEquals(flatLeft + (CYLAnimatedItemLiquidGlassContentInset * density).toInt(), glass.rightMargin)
        assertEquals("top and bottom are unchanged", flatLeft, glass.topMargin)
    }
}
