package com.cyl.animateditem

import android.app.Activity
import android.graphics.drawable.ColorDrawable
import android.os.SystemClock
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * [EN] CYLAnimatedItemStackView on the JVM: every element is a CYLAnimatedItemView; order, spacing, actions, the
 *      background action, screen reader roles and wrapping, as the iOS tests (CYLAnimatedItemStackViewTests.m).
 * [CN] JVM 上的 CYLAnimatedItemStackView：每个元素都是 CYLAnimatedItemView；顺序、间距、动作、背景动作、读屏角色与换行，与 iOS 测试
 *      （CYLAnimatedItemStackViewTests.m）一致。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
// [EN] Native graphics: the legacy mode lays every text out on one line, so wrapping could not be checked.
// [CN] 原生图形：旧模式把所有文字排成一行，无法检查换行。
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class CYLAnimatedItemStackViewTest {

    private val activity: Activity = Robolectric.buildActivity(Activity::class.java).setup().get()

    private fun item(title: String?) = CYLAnimatedItemView(activity).apply {
        axis = CYLAnimatedItemAxis.Vertical
        this.title = title
    }

    private fun layOut(view: View, width: Int, height: Int) {
        view.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))
        view.layout(0, 0, width, height)
    }

    private fun tap(view: ViewGroup, x: Float, y: Float) {
        val time = SystemClock.uptimeMillis()
        val down = MotionEvent.obtain(time, time, MotionEvent.ACTION_DOWN, x, y, 0)
        val up = MotionEvent.obtain(time, time + 50, MotionEvent.ACTION_UP, x, y, 0)
        view.dispatchTouchEvent(down)
        view.dispatchTouchEvent(up)
        down.recycle()
        up.recycle()
    }

    private fun nodeInfo(view: View): AccessibilityNodeInfo = AccessibilityNodeInfo.obtain().also { view.onInitializeAccessibilityNodeInfo(it) }

    @Test
    fun theStackHasTheSameBackgroundRulesAsTheItemView() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val stack = CYLAnimatedItemStackView(activity)
        stack.itemBackgroundColor = 0xFF336699.toInt()
        stack.layout(0, 0, 200, 80)
        assertEquals(0f, (stack.background as android.graphics.drawable.GradientDrawable).cornerRadius, "flat, unset: square")
        stack.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        stack.layout(0, 0, 200, 80)
        assertTrue(stack.itemLiquidGlassView != null, "glass layer behind the items")
        assertEquals(40f, (stack.background as android.graphics.drawable.GradientDrawable).cornerRadius, "glass, unset: a capsule")
        stack.itemCornerRadius = CYLAnimatedItemCornerRadiusCapsule
        stack.layout(0, 0, 200, 80)
        assertEquals(40f, (stack.background as android.graphics.drawable.GradientDrawable).cornerRadius, "the capsule constant")
        stack.itemCornerRadius = 0f
        stack.layout(0, 0, 200, 80)
        assertEquals(0f, (stack.background as android.graphics.drawable.GradientDrawable).cornerRadius, "0 is square")
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    @Test
    fun itemsAreArrangedInOrderAndTheFirstIsReserved() {
        val first = item("No messages")
        val second = item("Pull to refresh")
        val stack = CYLAnimatedItemStackView(activity, listOf(first, second))
        assertEquals(listOf(first, second), stack.itemViews)
        assertSame(first, stack.firstItemView)
        assertEquals(LinearLayout.VERTICAL, stack.stackView.orientation)
        for (index in 0 until stack.stackView.childCount) {
            assertTrue(stack.stackView.getChildAt(index) is CYLAnimatedItemView)
        }
    }

    @Test
    fun emptyStackHasNoFirstItem() {
        val stack = CYLAnimatedItemStackView(activity)
        assertNull(stack.firstItemView)
        assertTrue(stack.itemViews.isEmpty())
    }

    @Test
    fun appendIgnoresDuplicatesAndSetsSpacing() {
        val stack = CYLAnimatedItemStackView(activity)
        val first = stack.appendItem("Empty", spacingBeforeDp = 0f)
        val second = stack.appendItem("Retry", action = "retry", spacingBeforeDp = 24f)
        stack.append(first, null, 8f)
        assertEquals(2, stack.itemViews.size)
        val density = activity.resources.displayMetrics.density
        assertEquals(0, (first.layoutParams as LinearLayout.LayoutParams).topMargin)
        assertEquals((24 * density).toInt(), (second.layoutParams as LinearLayout.LayoutParams).topMargin)
        assertEquals(CYLAnimatedItemAxis.Vertical, second.axis)
        assertEquals(Int.MAX_VALUE, second.titleView.maxLines)
    }

    @Test
    fun itemTapPerformsItsAction() {
        var performed: String? = null
        val stack = CYLAnimatedItemStackView(activity, emptyList(), mapOf("retry" to CYLAnimatedItemStackView.ActionHandler { _, action -> performed = action }))
        stack.appendItem("Empty")
        val retry = stack.appendItem("Retry", action = "retry")
        retry.performClick()
        assertEquals("retry", performed)
        assertSame(retry, stack.itemView("retry"))
        assertEquals("retry", stack.action(retry))
        assertNull(stack.itemView("missing"))
    }

    @Test
    fun handlersCanBeSetAndRemoved() {
        var count = 0
        val stack = CYLAnimatedItemStackView(activity)
        assertFalse(stack.performAction("retry"))
        stack.setHandler({ _, _ -> count++ }, "retry")
        assertTrue(stack.performAction("retry"))
        stack.setHandler(null, "retry")
        assertFalse(stack.performAction("retry"))
        assertEquals(1, count)
    }

    @Test
    fun aTapOnAnItemWithoutActionReachesTheBackground() {
        val events = ArrayList<String>()
        val stack = CYLAnimatedItemStackView(activity, emptyList(), mapOf(
            "reload" to CYLAnimatedItemStackView.ActionHandler { _, action -> events.add(action) },
            "retry" to CYLAnimatedItemStackView.ActionHandler { _, action -> events.add(action) },
        ))
        val hint = stack.appendItem("No connection")
        val retry = stack.appendItem("Retry", action = "retry")
        stack.backgroundAction = "reload"
        layOut(stack, 400, 800)
        // [EN] On the hint (no action): background. On the empty corner: background. On Retry: its own action.
        // [CN] 点在提示上（无动作）：背景。点在空白角落：背景。点在 Retry 上：它自己的动作。
        tap(stack, stack.stackView.left + hint.left + hint.width / 2f, stack.stackView.top + hint.top + hint.height / 2f)
        tap(stack, 2f, 2f)
        tap(stack, stack.stackView.left + retry.left + retry.width / 2f, stack.stackView.top + retry.top + retry.height / 2f)
        assertEquals(listOf("reload", "reload", "retry"), events)
    }

    @Test
    fun screenReaderRoles() {
        var count = 0
        val stack = CYLAnimatedItemStackView(activity, emptyList(), mapOf("reload" to CYLAnimatedItemStackView.ActionHandler { _, _ -> count++ }))
        val first = stack.appendItem("No connection")
        val retry = stack.appendItem("Retry", action = "retry")
        assertEquals(TextView::class.java.name, nodeInfo(first).className, "text without an action is not a button")
        assertEquals(Button::class.java.name, nodeInfo(retry).className)
        stack.backgroundAction = "reload"
        assertEquals(Button::class.java.name, nodeInfo(first).className, "the first item reaches the background action")
        assertTrue(first.performAccessibilityAction(AccessibilityNodeInfo.ACTION_CLICK, null))
        assertEquals(1, count)
        stack.backgroundAction = null
        assertEquals(TextView::class.java.name, nodeInfo(first).className)
    }

    @Test
    fun decorativeItemIsHiddenFromTheScreenReader() {
        val stack = CYLAnimatedItemStackView(activity)
        stack.appendItem("Empty")
        val separator = stack.appendItem(null, image = ColorDrawable(0xFF888888.toInt()))
        assertEquals(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS, separator.importantForAccessibility)
        separator.title = "Divider"
        layOut(stack, 400, 800)
        assertEquals(View.IMPORTANT_FOR_ACCESSIBILITY_YES, separator.importantForAccessibility)
    }

    @Test
    fun removeMovesTheReservedRole() {
        val stack = CYLAnimatedItemStackView(activity)
        val first = stack.appendItem("One")
        val second = stack.appendItem("Two", spacingBeforeDp = 24f)
        stack.backgroundAction = "reload"
        stack.remove(first)
        assertNull(first.parent)
        assertSame(second, stack.firstItemView)
        assertEquals(0, (second.layoutParams as LinearLayout.LayoutParams).topMargin)
        assertEquals(Button::class.java.name, nodeInfo(second).className)
    }

    @Test
    fun longTitleWrapsToTheViewWidth() {
        val stack = CYLAnimatedItemStackView(activity)
        val hint = stack.appendItem("A very long hint that cannot fit on one line of a narrow placeholder, so it wraps onto several lines")
        val oneLine = CYLAnimatedItemView(activity).apply { title = "A" }
        oneLine.measure(View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED), View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
        layOut(stack, 300, 1200)
        val margin = (16 * activity.resources.displayMetrics.density).toInt()
        assertTrue(hint.width <= 300 - 2 * margin, "the item fits inside the margins")
        assertTrue(hint.height > oneLine.measuredHeight * 2, "the title wraps instead of widening the stack: hint ${hint.width}x${hint.height}, one line ${oneLine.measuredHeight}, title lines ${hint.titleView.lineCount}")
    }

    @Test
    fun aDisabledItemOrOneTheSubclassBlocksLetsTheBackgroundAct() {
        val events = ArrayList<String>()
        val blocked = HashSet<CYLAnimatedItemView>()
        val stack = object : CYLAnimatedItemStackView(activity) {
            override fun isItemInteractive(itemView: CYLAnimatedItemView) = super.isItemInteractive(itemView) && itemView !in blocked
        }
        stack.setHandler({ _, action -> events.add(action) }, "retry")
        stack.setHandler({ _, action -> events.add(action) }, "reload")
        stack.appendItem("No connection")
        val retry = stack.appendItem("Retry", action = "retry")
        stack.backgroundAction = "reload"
        layOut(stack, 400, 800)
        val x = stack.stackView.left + retry.left + retry.width / 2f
        val y = stack.stackView.top + retry.top + retry.height / 2f
        blocked.add(retry)
        stack.updateInteractionOfItemViews()
        assertEquals(TextView::class.java.name, nodeInfo(retry).className)
        tap(stack, x, y)
        blocked.clear()
        stack.updateInteractionOfItemViews()
        retry.isEnabled = false
        tap(stack, x, y)
        retry.isEnabled = true
        tap(stack, x, y)
        assertEquals(listOf("reload", "reload", "retry"), events)
    }

    @Test
    fun aHorizontalStackLaysItsItemsInARowWithTheSpacingOnTheLeadingSide() {
        val stack = CYLAnimatedItemStackView(activity)
        val density = activity.resources.displayMetrics.density
        val edit = stack.appendItem("Edit")
        val remove = stack.appendItem("Remove")
        val close = stack.appendItem("Close", spacingBeforeDp = 4f)
        assertEquals(LinearLayout.VERTICAL, stack.stackView.orientation, "vertical by default")
        assertEquals((16 * density).toInt(), (remove.layoutParams as LinearLayout.LayoutParams).topMargin)
        stack.axis = CYLAnimatedItemAxis.Horizontal
        stack.spacingDp = 10f
        assertEquals(LinearLayout.HORIZONTAL, stack.stackView.orientation)
        val removeParams = remove.layoutParams as LinearLayout.LayoutParams
        assertEquals((10 * density).toInt(), removeParams.marginStart, "as iOS stackView.spacing")
        assertEquals(0, removeParams.topMargin)
        assertEquals((4 * density).toInt(), (close.layoutParams as LinearLayout.LayoutParams).marginStart, "its own spacing wins")
        assertEquals(0, (edit.layoutParams as LinearLayout.LayoutParams).marginStart, "the first item has none")
        stack.remove(edit)
        assertEquals(0f, stack.spacingBeforeDpOf(remove), "the new first item has none")
    }

    @Test
    fun theStackIconColorTintsItemsWithoutTheirOwn() {
        val stack = CYLAnimatedItemStackView(activity)
        val edit = stack.appendItem(null, ColorDrawable(0xFF000000.toInt()))
        val remove = stack.appendItem(null, ColorDrawable(0xFF000000.toInt()))
        assertNull(edit.effectiveIconColor, "no tint by default")
        assertNull(edit.iconView.colorFilter)
        stack.iconColor = 0xFF8E8E93.toInt()
        remove.iconColor = 0xFFFF3B30.toInt()
        assertEquals(0xFF8E8E93.toInt(), edit.effectiveIconColor)
        assertEquals(0xFFFF3B30.toInt(), remove.effectiveIconColor, "an item's own color wins")
        assertTrue(edit.iconView.colorFilter != null)
        stack.selectedIconColor = 0xFF007AFF.toInt()
        edit.isSelected = true
        assertEquals(0xFF007AFF.toInt(), edit.effectiveIconColor)
        stack.remove(edit)
        edit.isSelected = false
        assertNull(edit.effectiveIconColor, "a removed item drops the stack color")
        assertNull(edit.iconView.colorFilter)
    }
}
