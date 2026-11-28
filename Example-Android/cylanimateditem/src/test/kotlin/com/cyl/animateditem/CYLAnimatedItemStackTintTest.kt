package com.cyl.animateditem

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.util.Base64
import android.view.View
import android.widget.LinearLayout
import androidx.test.core.app.ApplicationProvider
import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

/**
 * [EN] The stack-owned dividers (`showsDividers`, `appendDivider`, `setDivider`, `removeDivider`, gap math), the stack-level defaults (`animationTint`, `animationDarkTint`, `dividerColor`, `iconColor`,
 *      `titleColor`) and what a host row needs from `CYLAnimatedItemStackView` (horizontal axis, spacing, margin 0, hidden items,
 *      insert / move / setItemViews, `dispatchesItemTaps = false`), as the iOS tests. Divider colors and inheritance are table driven.
 * [CN] 堆叠拥有的分隔线（`showsDividers`、`appendDivider`、`setDivider`、`removeDivider`、间隙计算）、堆叠级默认值（`animationTint`、`animationDarkTint`、`dividerColor`、`iconColor`、`titleColor`）以及宿主行
 *      对 `CYLAnimatedItemStackView` 的要求（水平方向、间距、边距 0、隐藏条目、insert / move / setItemViews、`dispatchesItemTaps = false`），
 *      与 iOS 测试一致。分隔线颜色与继承由表驱动。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemStackTintTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val factory = CYLTabBarItemAnimationFactory(CYLTabBarItemAnimatorRegistry().apply { registerAnimator(CYLGIFTabBarItemAnimator.animator) })
    private val gif: String by lazy {
        File.createTempFile("cyl-stack-tint", ".gif").apply { writeBytes(Base64.decode(CYLGIFDecoderTestData.THREE_FRAMES, Base64.DEFAULT)); deleteOnExit() }.absolutePath
    }

    private fun item(load: Boolean = true) = CYLAnimatedItemView(context).apply {
        animationSource = factory
        if (load) animationURL = gif
    }

    private fun applied(item: CYLAnimatedItemView) = CYLTabBarItemAnimationTint.appliedColor(item.animationView)

    private fun night(view: View, night: Boolean) {
        RuntimeEnvironment.setQualifiers(if (night) "+night" else "+notnight")
        view.dispatchConfigurationChanged(Configuration(view.resources.configuration))
    }

    private val alpha = (CYLAnimatedItemDividerAlpha * 255f).let { Math.round(it) }
    private fun withAlpha(color: Int) = Color.argb(alpha, Color.red(color), Color.green(color), Color.blue(color))
    private fun builtInDivider(night: Boolean) = CYLAnimatedItemBuiltInColors.divider(context, Configuration(context.resources.configuration).apply {
        uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or (if (night) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO)
    })

    private data class DividerRow(val dividerColor: Int?, val iconColor: Int?, val night: Boolean, val expected: Int)

    private fun dividerTable(): List<DividerRow> = buildList {
        for (night in listOf(false, true)) {
            add(DividerRow(Color.GREEN, Color.RED, night, Color.GREEN))   // dividerColor wins, used as is
            add(DividerRow(Color.GREEN, null, night, Color.GREEN))
            add(DividerRow(null, Color.RED, night, withAlpha(Color.RED))) // the stack's explicit icon color at 0.6
            add(DividerRow(null, null, night, builtInDivider(night)))     // built-in secondary text color
        }
    }

    private fun colorOf(stack: CYLAnimatedItemStackView, config: Configuration? = null): Int {
        val divider = stack.dividerViewAfter(stack.firstItemView!!)!!
        return if (config == null) divider.resolvedDividerColor() else divider.resolvedDividerColor(config)
    }

    @Test
    fun dividerColorTable() {
        dividerTable().forEach { row ->
            val stack = CYLAnimatedItemStackView(context)
            stack.append(sized(10))
            stack.dividerColor = row.dividerColor
            stack.iconColor = row.iconColor
            night(stack, row.night)
            assertEquals(row.toString(), row.expected, colorOf(stack))
        }
    }

    @Test
    fun dividerColorReresolvesWhenColorsChange() {
        val stack = CYLAnimatedItemStackView(context)
        stack.append(sized(10))
        assertEquals(builtInDivider(false), colorOf(stack, Configuration()))
        stack.iconColor = Color.RED
        assertEquals(withAlpha(Color.RED), colorOf(stack))
        stack.dividerColor = Color.GREEN
        assertEquals(Color.GREEN, colorOf(stack))
        stack.dividerColor = null
        stack.iconColor = null
        assertEquals(builtInDivider(false), colorOf(stack))
        night(stack, true)
        assertEquals(builtInDivider(true), colorOf(stack))
        val later = sized(10)                                  // a divider made later gets the same defaults
        stack.iconColor = Color.BLUE
        stack.append(later)
        assertEquals(withAlpha(Color.BLUE), stack.dividerViewAfter(later)!!.resolvedDividerColor())
    }

    private fun childrenOf(stack: CYLAnimatedItemStackView) = (0 until stack.stackView.childCount).map { stack.stackView.getChildAt(it) }

    /** [EN] The gaps after each item that show a divider. [CN] 每个条目之后显示分隔线的间隙。 */
    private fun shown(stack: CYLAnimatedItemStackView) = stack.itemViews.map { stack.dividerViewAfter(it)!!.visibility == View.VISIBLE }

    @Test
    fun appendDividerOnAnEmptyStackDoesNothing() {
        val stack = row()
        stack.appendDivider(8f, 8f)
        assertEquals(0, stack.itemViews.size)
        val camera = sized(10)
        val search = sized(10)
        stack.append(camera)
        stack.appendDivider(8f, 8f)
        stack.append(search)
        layOut(stack)
        assertTrue(stack.hasDivider(camera))
        assertFalse(stack.hasDivider(search))
        assertEquals(listOf(true, false), shown(stack))
        assertEquals(listOf(camera, search), stack.itemViews)       // the divider is not an item
        assertEquals(4, stack.stackView.childCount)
        assertEquals(10 + 8 + 1 + 8 + 10, stack.measuredWidth)
    }

    /** [EN] One row of the gap math. [CN] 间隙计算的一行。 */
    private data class GapRow(
        val spacing: Float, val nextBefore: Float?, val stackBefore: Float?, val stackAfter: Float?,
        val ownBefore: Float?, val ownAfter: Float?, val gap: Int,
    )

    private val gapTable = listOf(
        GapRow(12f, null, null, null, 8f, 8f, 17),        // the worked example: 8 + 1 + 8, never 12 + 8 + 1 + 8 + 12
        GapRow(12f, null, null, null, null, null, 25),    // all fall back: spacing + 1 + spacing
        GapRow(12f, 5f, null, null, null, null, 18),      // after falls back to the next item's spacingBefore
        GapRow(12f, 5f, 3f, null, null, null, 9),         // stack before; after = next item's 5
        GapRow(12f, 5f, 3f, 4f, null, null, 8),           // both stack defaults
        GapRow(12f, 5f, 3f, 4f, 8f, null, 13),            // own before wins, stack after
        GapRow(12f, 5f, 3f, 4f, null, 9f, 13),            // stack before, own after
        GapRow(12f, 5f, 3f, 4f, 8f, 9f, 18),              // own both
        GapRow(12f, null, null, 4f, null, 0f, 13),        // own 0 is a value, not a fallback
    )

    @Test
    fun gapMathTable() {
        gapTable.forEach { row ->
            val a = sized(10)
            val b = sized(10)
            val stack = CYLAnimatedItemStackView(context).apply {
                axis = CYLAnimatedItemAxis.Horizontal
                contentMarginDp = 0f
                spacingDp = row.spacing
                dividerSpacingBeforeDp = row.stackBefore
                dividerSpacingAfterDp = row.stackAfter
                append(a)
                setDivider(a, row.ownBefore, row.ownAfter)
                append(b, null, row.nextBefore)
            }
            layOut(stack)
            assertEquals(row.toString(), 10 + row.gap + 10, stack.measuredWidth)
            assertEquals(row.gap - 1 - (stack.dividerViewAfter(a)!!.layoutParams as LinearLayout.LayoutParams).marginStart, (b.layoutParams as LinearLayout.LayoutParams).marginStart)
        }
    }

    @Test
    fun withoutADividerTheNextItemsSpacingIsTheGap() {
        val a = sized(10)
        val b = sized(10)
        val stack = row(a)
        stack.append(b, null, 5f)
        layOut(stack)
        assertEquals(10 + 5 + 10, stack.measuredWidth)
    }

    @Test
    fun dividerSizeIsSwappedInAColumnAndFollowsTheLength() {
        val a = sized(10)
        val b = sized(10)
        val stack = row(a, b)
        stack.showsDividers = true
        layOut(stack)
        stack.dividerLengthDp = 30f
        layOut(stack)
        assertEquals(1, stack.dividerViewAfter(a)!!.measuredWidth)
        assertEquals(30, stack.dividerViewAfter(a)!!.measuredHeight)
        assertEquals(30, stack.measuredHeight)
        stack.axis = CYLAnimatedItemAxis.Vertical
        layOut(stack)
        assertEquals(30, stack.dividerViewAfter(a)!!.measuredWidth)
        assertEquals(1, stack.dividerViewAfter(a)!!.measuredHeight)
        assertEquals(20f, CYLAnimatedItemDividerLength)
    }

    @Test
    fun showsDividersAndRemoveDividerTurnsOneGapOff() {
        val a = sized(10)
        val b = sized(10)
        val c = sized(10)
        val stack = row(a, b, c)
        layOut(stack)
        assertEquals(listOf(false, false, false), shown(stack))
        stack.showsDividers = true
        layOut(stack)
        assertEquals(listOf(true, true, false), shown(stack))     // never after the last item
        assertEquals(6, stack.stackView.childCount)
        assertEquals(listOf(a, b, c), stack.itemViews)
        val line = stack.dividerViewAfter(a)!!
        assertFalse(line.isClickable)
        assertFalse(line.performClick())
        assertEquals(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS, line.importantForAccessibility)
        // gap = 8 + 1 + 8 twice, around items of 10
        assertEquals(10 + 17 + 10 + 17 + 10, stack.measuredWidth)
        stack.removeDivider(a)                                    // one gap off although showsDividers
        layOut(stack)
        assertFalse(stack.hasDivider(a))
        assertEquals(listOf(false, true, false), shown(stack))
        assertEquals(10 + 8 + 10 + 17 + 10, stack.measuredWidth)
        stack.setDivider(a)                                       // back on, default spacing
        layOut(stack)
        assertEquals(listOf(true, true, false), shown(stack))
        stack.showsDividers = false
        layOut(stack)
        assertEquals(listOf(true, false, false), shown(stack))    // a's own divider stays
    }

    @Test
    fun hiddenOwnerOrNextItemLeavesNoDividerOrSpacing() {
        val a = sized(10)
        val b = sized(10)
        val c = sized(10)
        val stack = row(a, b, c)
        stack.showsDividers = true
        b.visibility = View.GONE
        layOut(stack)
        assertEquals(listOf(true, false, false), shown(stack))    // a | c
        assertEquals(10 + 17 + 10, stack.measuredWidth)
        c.visibility = View.GONE
        layOut(stack)
        assertEquals(listOf(false, false, false), shown(stack))   // a alone: no later visible item
        assertEquals(10, stack.measuredWidth)
        a.visibility = View.GONE
        c.visibility = View.VISIBLE
        layOut(stack)
        assertEquals(listOf(false, false, false), shown(stack))   // c alone: owner hidden, nothing before c
        assertEquals(10, stack.measuredWidth)
        a.visibility = View.VISIBLE
        b.visibility = View.VISIBLE
        layOut(stack)
        assertEquals(listOf(true, true, false), shown(stack))
    }

    @Test
    fun dividerMovesWithItsItemAndGoesWithIt() {
        val a = sized(10)
        val b = sized(10)
        val c = sized(10)
        val stack = row(a, b, c)
        stack.setDivider(a, 3f, 4f)
        layOut(stack)
        assertEquals(listOf(true, false, false), shown(stack))
        stack.move(a, 1)                                       // b a c: the divider is after a
        layOut(stack)
        assertEquals(listOf(b, a, c), stack.itemViews)
        assertEquals(listOf(false, true, false), shown(stack))
        assertTrue(stack.hasDivider(a))
        assertEquals(b to stack.dividerViewAfter(b), childrenOf(stack).let { it[0] to it[1] })
        assertEquals(10 + 8 + 10 + 3 + 1 + 4 + 10, stack.measuredWidth)
        stack.move(a, 2)                                       // b c a: a is last, no divider on screen
        layOut(stack)
        assertEquals(listOf(false, false, false), shown(stack))
        assertTrue(stack.hasDivider(a))
        stack.append(sized(10))                                // a gets a later item: the divider appears
        layOut(stack)
        assertEquals(listOf(false, false, true, false), shown(stack))
        stack.remove(a)                                        // goes with its item
        layOut(stack)
        assertEquals(6, stack.stackView.childCount)
        assertEquals(listOf(false, false, false), shown(stack))
        assertFalse(stack.hasDivider(a))
    }

    @Test
    fun setItemViewsKeepsDividersWithTheirItems() {
        val a = sized(10)
        val b = sized(10)
        val c = sized(10)
        val stack = row(a, b)
        stack.setDivider(b)
        stack.setItemViews(listOf(c, b, a))
        layOut(stack)
        assertEquals(listOf(c, b, a), stack.itemViews)
        assertEquals(listOf(false, true, false), shown(stack))
        assertEquals(6, stack.stackView.childCount)
    }

    // MARK: - Inheritance

    @Test
    fun stackTintInheritance() {
        val stack = CYLAnimatedItemStackView(context)
        stack.iconColor = Color.RED
        stack.selectedIconColor = Color.BLUE
        stack.animationRenderingMode = CYLAnimationRenderingMode.AlwaysOriginal  // the one-color test GIF would be tinted by `Automatic`
        val inheriting = item()
        stack.append(inheriting)
        assertNull(applied(inheriting))                               // nothing set

        stack.animationTint = "title"                                 // stack only
        assertEquals(Color.RED, applied(inheriting))

        val own = item().apply { animationTint = "#00FF00" }         // item wins
        stack.append(own)
        assertEquals(Color.GREEN, applied(own))
        assertEquals(Color.RED, applied(inheriting))

        val later = item()                                            // appended later
        stack.append(later)
        assertEquals(Color.RED, applied(later))

        val empty = item().apply { animationTint = "" }              // empty inherits
        stack.append(empty)
        assertEquals(Color.RED, applied(empty))

        later.isSelected = true                                       // state follows the table
        assertEquals(Color.BLUE, applied(later))
        later.isSelected = false

        stack.animationTint = null                                    // cleared: own stays, inherited goes
        assertNull(applied(inheriting))
        assertNull(applied(later))
        assertNull(applied(empty))
        assertEquals(Color.GREEN, applied(own))

        stack.remove(own)                                             // a removed item keeps only its own
        stack.animationTint = "title"
        assertEquals(Color.GREEN, applied(own))
    }

    @Test
    fun stackDarkTintAndAppearanceChange() {
        val stack = CYLAnimatedItemStackView(context)
        stack.animationTint = "#1C1C1E"
        stack.animationDarkTint = "#FFFFFF"
        val inheriting = item()
        val own = item().apply { animationDarkTint = "#FF0000" }
        stack.append(inheriting)
        stack.append(own)
        night(inheriting, false)
        assertEquals(Color.parseColor("#1C1C1E"), applied(inheriting))
        night(inheriting, true)
        night(own, true)
        assertEquals(Color.WHITE, applied(inheriting))
        assertEquals(Color.RED, applied(own))
        stack.animationDarkTint = null
        assertEquals(Color.parseColor("#1C1C1E"), applied(inheriting))
        assertEquals(Color.RED, applied(own))
        night(inheriting, false)
        assertEquals(Color.parseColor("#1C1C1E"), applied(inheriting))
    }

    @Test
    fun stackDefaultsOfColors() {
        val stack = CYLAnimatedItemStackView(context)
        stack.titleColor = Color.MAGENTA
        val inheriting = item(load = false)
        val own = item(load = false).apply { titleColor = Color.YELLOW }
        stack.append(inheriting)
        stack.append(own)
        assertEquals(Color.MAGENTA, inheriting.titleView.currentTextColor)
        assertEquals(Color.YELLOW, own.titleView.currentTextColor)
        stack.titleColor = null
        assertEquals("cleared: the built-in normal color", CYLAnimatedItemBuiltInColors.normal(context), inheriting.titleView.currentTextColor)
        assertEquals(Color.YELLOW, own.titleView.currentTextColor)
    }

    // MARK: - Host row

    private fun layOut(stack: CYLAnimatedItemStackView, width: Int = 1000, height: Int = 200) {
        stack.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.AT_MOST), View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.AT_MOST))
        stack.layout(0, 0, stack.measuredWidth, stack.measuredHeight)
    }

    private fun row(vararg views: CYLAnimatedItemView) = CYLAnimatedItemStackView(context).apply {
        axis = CYLAnimatedItemAxis.Horizontal
        contentMarginDp = 0f
        spacingDp = 8f
        views.forEach { append(it) }
    }

    private fun sized(width: Int) = CYLAnimatedItemView(context).apply { setPadding(width, 0, 0, 0) }

    @Test
    fun rowHugsItemsWithMarginZeroAndSpacing() {
        val a = sized(10)
        val b = sized(30)
        val stack = row(a, b)
        stack.append(sized(5), null, 0f) // own spacing 0
        layOut(stack)
        assertEquals(10, a.measuredWidth)
        assertEquals(30, b.measuredWidth)
        assertEquals(10 + 8 + 30 + 0 + 5, stack.measuredWidth)
        assertEquals(0, a.left)
    }

    @Test
    fun goneItemLeavesNoSpacing() {
        val a = sized(10)
        val b = sized(10)
        val c = sized(10)
        val stack = row(a, b, c)
        layOut(stack)
        assertEquals(10 + 8 + 10 + 8 + 10, stack.measuredWidth)
        a.visibility = View.GONE
        layOut(stack)
        assertEquals(0f, stack.spacingBeforeDpOf(b))
        assertEquals(10 + 8 + 10, stack.measuredWidth)
        c.visibility = View.GONE
        layOut(stack)
        assertEquals(10, stack.measuredWidth)
        a.visibility = View.VISIBLE
        layOut(stack)
        assertEquals(10 + 8 + 10, stack.measuredWidth)
        b.alpha = 0f // faded, not hidden: keeps its room
        layOut(stack)
        assertEquals(10 + 8 + 10, stack.measuredWidth)
    }

    @Test
    fun insertMoveAndSetItemViews() {
        val a = sized(1)
        val b = sized(2)
        val c = sized(3)
        val stack = row(a, b)
        stack.setAction("go", b)
        stack.insert(c, 0)
        assertEquals(listOf(c, a, b), stack.itemViews)
        assertEquals(listOf(c, a, b), childrenOf(stack).filter { v -> stack.itemViews.any { it === v } })
        stack.move(c, 2)
        assertEquals(listOf(a, b, c), stack.itemViews)
        assertEquals(listOf(a, b, c), childrenOf(stack).filter { v -> stack.itemViews.any { it === v } })
        assertEquals(0f, stack.spacingBeforeDpOf(a))
        val d = sized(4)
        stack.setItemViews(listOf(d, c, b))
        assertEquals(listOf(d, c, b), stack.itemViews)
        assertSame(d, stack.firstItemView)
        assertEquals("go", stack.action(b))
        assertEquals(null, a.parent)
        val params = c.layoutParams as LinearLayout.LayoutParams
        assertEquals(8, params.marginStart)
        assertEquals(0, (d.layoutParams as LinearLayout.LayoutParams).marginStart)
    }

    @Test
    fun subclassItemsAreAccepted() {
        class Mine(context: Context) : CYLAnimatedItemView(context)
        val stack = CYLAnimatedItemStackView(context)
        val mine = Mine(context)
        stack.append(mine, "x")
        assertSame(mine, stack.itemViews.single())
        assertEquals("x", stack.action(mine))
    }

    @Test
    fun dispatchesItemTapsFalseLeavesTapsToTheHost() {
        val a = sized(10)
        val stack = row(a)
        stack.setAction("go", a)
        stack.backgroundAction = "bg"
        assertTrue(a.hasOnClickListeners())
        stack.dispatchesItemTaps = false
        assertFalse(a.hasOnClickListeners())
        assertTrue(a.isClickable)
        assertEquals(View.IMPORTANT_FOR_ACCESSIBILITY_AUTO, a.importantForAccessibility)
        val down = android.view.MotionEvent.obtain(0, 0, android.view.MotionEvent.ACTION_DOWN, 1f, 1f, 0)
        assertFalse(stack.onInterceptTouchEvent(down))
        down.recycle()
        var performed = 0
        stack.setHandler({ _, _ -> performed++ }, "go")
        stack.setHandler({ _, _ -> performed++ }, "bg")
        a.performClick()
        assertEquals(0, performed)
        // items appended while off get no listener and no accessibility change
        val b = sized(10)
        a.importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_YES
        stack.append(b, "go")
        layOut(stack)
        assertFalse(b.hasOnClickListeners())
        assertEquals(View.IMPORTANT_FOR_ACCESSIBILITY_YES, a.importantForAccessibility)
        stack.dispatchesItemTaps = true
        assertTrue(a.hasOnClickListeners())
        assertTrue(b.hasOnClickListeners())
    }
}
