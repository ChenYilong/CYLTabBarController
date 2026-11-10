package com.cyl.tabbar

import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.SystemClock
import android.text.SpannableString
import android.text.Spanned
import android.text.TextPaint
import android.view.MotionEvent
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import androidx.fragment.app.Fragment
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] The Android-only features adapted from QMUI_Android: the tab bar indicator and scrollable mode, swiping between pages,
 *      and theme values (rules, styles, layout attributes, spans, interceptors, one dispatch per change).
 * [CN] 改编自 QMUI_Android 的仅 Android 功能：TabBar 指示条与滚动模式、滑动翻页，以及主题值（规则、style、布局属性、span、拦截、每次变化只分发一次）。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLQMUIAdaptedFeaturesTest : CYLRobolectricTestCase() {
    // MARK: - Indicator 指示条

    @Test
    fun theIndicatorMovesToTheSelectedTabAndFollowsAPager() = withActivity { activity ->
        val controller = controllerWith(activity, "Home", "Message", "Me")
        val tabBar = controller.tabBar
        assertNull("no indicator by default, as on iOS", tabBar.cyl_indicator)
        tabBar.cyl_indicator = CYLTabBarIndicator(height = 3f, widthFollowsContent = false)
        idle()
        val buttons = tabBar.tabBarButtonArray
        assertEquals(buttons[0].left, tabBar.cyl_indicator!!.cyl_bounds!!.left)
        assertEquals(buttons[0].width, tabBar.cyl_indicator!!.cyl_bounds!!.width())

        controller.selectedIndex = 2
        idle()
        assertEquals("moved to the new tab", buttons[2].left, tabBar.cyl_indicator!!.cyl_bounds!!.left)

        // [EN] Half way to the left neighbor, as a pager would report it. [CN] 移向左侧相邻 Tab 一半，与翻页控件报告的一致。
        tabBar.cyl_updateIndicatorPosition(2, -0.5f)
        val half = tabBar.cyl_indicator!!.cyl_bounds!!.left
        assertTrue(half in buttons[1].left + 1 until buttons[2].left)
        val blended = buttons[1].titleLabel.currentTextColor
        assertNotEquals(buttons[1].titleColor(false, tabBar), blended)
        assertNotEquals(buttons[1].titleColor(true, tabBar), blended)

        tabBar.cyl_updateIndicatorPosition(2, 0f)
        assertEquals("back on the selected tab", buttons[2].left, tabBar.cyl_indicator!!.cyl_bounds!!.left)
    }

    @Test
    fun theIndicatorSpansTheTitleAndHidesForThePlusButton() = withActivity { activity ->
        val controller = controllerWith(activity, "A", "Message")
        val tabBar = controller.tabBar
        tabBar.cyl_indicator = CYLTabBarIndicator(color = Color.RED)
        idle()
        val bounds = tabBar.cyl_indicator!!.cyl_bounds!!
        val button = tabBar.tabBarButtonArray[0]
        assertTrue("narrower than the tab", bounds.width() < button.width)
        assertTrue("centered on the tab", kotlin.math.abs(button.left + button.width / 2 - bounds.centerX()) <= 1)
    }

    // MARK: - Scroll mode 滚动模式

    @Test
    fun theScrollableModeSizesTabsByContentAndScrolls() = withActivity { activity ->
        val titles = (1..8).map { "A rather long tab title $it" }.toTypedArray()
        val controller = controllerWith(activity, *titles)
        val tabBar = controller.tabBar
        val fixedWidths = tabBar.tabBarButtonArray.map { it.width }.toSet()
        assertEquals("equal tabs in the fixed mode", 1, fixedWidths.size)

        tabBar.cyl_scrollMode = CYLTabBarScrollMode.Scrollable
        idle()
        val buttons = tabBar.tabBarButtonArray
        assertTrue("wider than the bar", buttons.last().right > tabBar.width)
        assertTrue(buttons[0].width > tabBar.width / titles.size)

        controller.selectedIndex = 6
        idle()
        assertTrue("scrolled towards the selected tab", tabBar.scrollX > 0)
        assertEquals("the shadow line stays in place", tabBar.scrollX, tabBar.cyl_shadowImageView.left)
    }

    @Test
    fun theScrollableModeKeepsEqualTabsWhenTheyFit() = withActivity { activity ->
        val controller = controllerWith(activity, "A", "B", "C")
        controller.tabBar.cyl_scrollMode = CYLTabBarScrollMode.Scrollable
        idle()
        assertEquals(1, controller.tabBar.tabBarButtonArray.map { it.width }.toSet().size)
        assertEquals(0, controller.tabBar.scrollX)
    }

    // MARK: - Swiping between pages 滑动翻页

    private fun swipe(view: View, fromX: Float, toX: Float) {
        val start = SystemClock.uptimeMillis()
        val y = 100f
        val steps = 6
        view.dispatchTouchEvent(MotionEvent.obtain(start, start, MotionEvent.ACTION_DOWN, fromX, y, 0))
        for (step in 1..steps) {
            val x = fromX + (toX - fromX) * step / steps
            view.dispatchTouchEvent(MotionEvent.obtain(start, start + step * 50L, MotionEvent.ACTION_MOVE, x, y, 0))
        }
        view.dispatchTouchEvent(MotionEvent.obtain(start, start + steps * 50L + 50, MotionEvent.ACTION_UP, toX, y, 0))
    }

    @Test
    fun swipingMovesToTheNeighborTabAndTellsTheDelegate() = withActivity { activity ->
        val controller = controllerWith(activity, "Home", "Message", "Me")
        val selected = ArrayList<Fragment>()
        controller.delegate = object : CYLTabBarControllerDelegate {
            override fun tabBarController_didSelectViewController(tabBarController: CYLTabBarController, viewController: Fragment) { selected += viewController }
        }
        val width = controller.pagesContainer.width.toFloat()
        swipe(controller.pagesContainer, width * 0.9f, width * 0.1f)
        idle()
        assertEquals("nothing moves while it is off", 0, controller.selectedIndex)

        controller.cyl_swipesBetweenPages = true
        swipe(controller.pagesContainer, width * 0.9f, width * 0.1f)
        idle()
        assertEquals(1, controller.selectedIndex)
        assertEquals(listOf(controller.viewControllers[1]), selected)
        assertEquals(0f, controller.viewControllers[1].requireView().translationX)
        assertTrue(controller.viewControllers[0].isHidden)

        // [EN] A short drag springs back. [CN] 短距离拖动会弹回。
        swipe(controller.pagesContainer, width * 0.5f, width * 0.4f)
        idle()
        assertEquals(1, controller.selectedIndex)
        assertTrue(controller.viewControllers[2].isHidden)
        assertEquals(View.GONE, controller.viewControllers[2].view?.visibility ?: View.GONE)
    }

    @Test
    fun swipingRespectsShouldSelect() = withActivity { activity ->
        val controller = controllerWith(activity, "Home", "Message")
        controller.cyl_swipesBetweenPages = true
        controller.delegate = object : CYLTabBarControllerDelegate {
            override fun tabBarController_shouldSelectViewController(tabBarController: CYLTabBarController, viewController: Fragment) = viewController === tabBarController.viewControllers[0]
        }
        val width = controller.pagesContainer.width.toFloat()
        swipe(controller.pagesContainer, width * 0.9f, width * 0.1f)
        idle()
        assertEquals(0, controller.selectedIndex)
        assertNull(controller.cyl_swipeTargetPage(1))
        assertNull("no tab beyond the edges", controller.cyl_swipeTargetPage(-1))
    }

    // MARK: - Theme values 主题值

    private fun manager(name: String) = CYLThemeManagerCenter.themeManagerWithName(name)

    @Test
    fun aMapThemeDrivesTheRulesOfARegisteredView() = withActivity { activity ->
        val manager = manager("values-map")
        manager.addThemeIdentifier("light", mapOf("title" to Color.BLACK, "surface" to "#FFFFFF", "faded" to 0.5))
        manager.addThemeIdentifier("dark", mapOf("title" to Color.RED, "surface" to "#00FF00", "faded" to 1))
        manager.currentThemeIdentifier = "light"
        val text = TextView(activity)
        text.cyl_themeValueManager = manager
        text.cyl_setThemeValue(CYLThemeValueBuilder().textColor("title").background("surface").alpha("faded"))
        assertEquals(Color.BLACK, text.currentTextColor)
        assertEquals(Color.WHITE, (text.background as ColorDrawable).color)
        assertEquals(0.5f, text.alpha)

        CYLThemeValues.register(text, manager)
        manager.currentThemeIdentifier = "dark"
        assertEquals(Color.RED, text.currentTextColor)
        assertEquals(Color.GREEN, (text.background as ColorDrawable).color)
        assertEquals(1f, text.alpha)
        CYLThemeValues.unregister(text, manager)
        manager.currentThemeIdentifier = "light"
        assertEquals("no longer follows", Color.RED, text.currentTextColor)
    }

    @Test
    fun aStyleThemeResolvesThemeAttributes() = withActivity { activity ->
        val manager = manager("values-style")
        manager.addThemeIdentifier("dark", CYLThemeStyle(android.R.style.Theme_Material))
        manager.addThemeIdentifier("light", CYLThemeStyle(android.R.style.Theme_Material_Light))
        manager.currentThemeIdentifier = "dark"
        val dark = CYLThemeValues.value(activity, "colorBackground", manager)?.color
        manager.currentThemeIdentifier = "light"
        val light = CYLThemeValues.value(activity, "colorBackground", manager)?.color
        assertNotNull(dark)
        assertNotNull(light)
        assertNotEquals(dark, light)
        assertNull(CYLThemeValues.value(activity, "noSuchAttributeAnywhere", manager))
    }

    @Test
    fun layoutAttributesBecomeRulesThroughTheFactory() = withActivity { activity ->
        val attrs = Robolectric.buildAttributeSet()
            .addAttribute(R.attr.cyl_themeTextColor, "title")
            .addAttribute(R.attr.cyl_themeValue, "background:surface|hintColor:?attr/hint")
            .build()
        val view = CYLThemeLayoutInflaterFactory(activity).onCreateView(null, "TextView", activity, attrs)
        assertTrue(view is TextView)
        val rules = CYLThemeValueBuilder().convertFrom(view!!.cyl_themeValue).rules()
        assertEquals(mapOf("background" to "surface", "hintColor" to "hint", "textColor" to "title"), rules)
        assertNull("<fragment> stays with the activity", CYLThemeLayoutInflaterFactory(activity).onCreateView(null, "fragment", activity, attrs))
    }

    @Test
    fun spansCustomRulesAndInterceptorsFollowQMUI() = withActivity { activity ->
        val manager = manager("values-spans")
        manager.addThemeIdentifier("a", mapOf("link" to Color.BLUE, "lift" to 4))
        manager.addThemeIdentifier("b", mapOf("link" to Color.MAGENTA, "lift" to 8))
        manager.currentThemeIdentifier = "a"

        val root = FrameLayout(activity)
        val text = TextView(activity)
        val span = CYLThemeColorSpan("link")
        val calls = ArrayList<CYLThemeManager?>()
        val spannable = SpannableString("hello")
        spannable.setSpan(span, 0, 5, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        spannable.setSpan(CYLThemeSpan { _, changed -> calls += changed }, 0, 5, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
        text.text = spannable
        root.addView(text)

        CYLThemeValues.setRuleHandler("lift") { view, _, value -> view.elevation = value.float ?: 0f }
        val lifted = View(activity).apply { cyl_themeValueManager = manager; cyl_themeValue = "lift:lift" }
        root.addView(lifted)
        assertEquals(4f, lifted.elevation)

        val shielded = FrameLayout(activity).apply { cyl_interceptsThemeDispatch = true }
        val hidden = View(activity).apply { cyl_themeValueManager = manager; cyl_themeValue = "lift:lift" }
        shielded.addView(hidden)
        root.addView(shielded)

        // [EN] Registered twice (the root and its child): one dispatch per change. [CN] 登记两次（根视图与其子视图）：每次变化只分发一次。
        CYLThemeValues.register(root, manager)
        CYLThemeValues.register(text, manager)
        calls.clear()
        manager.currentThemeIdentifier = "b"
        assertEquals(listOf<CYLThemeManager?>(manager), calls)
        val paint = TextPaint()
        span.updateDrawState(paint)
        assertEquals(Color.MAGENTA, paint.color)
        assertEquals(8f, lifted.elevation)
        assertEquals("the interceptor kept the change out", 4f, hidden.elevation)
        CYLThemeValues.setRuleHandler("lift", null)
        CYLThemeValues.unregister(root, manager)
        CYLThemeValues.unregister(text, manager)
    }

    @Test
    fun aViewAttachedLaterCatchesUp() = withActivity { activity ->
        val manager = manager("values-attach")
        manager.addThemeIdentifier("a", mapOf("title" to Color.BLACK))
        manager.addThemeIdentifier("b", mapOf("title" to Color.YELLOW))
        manager.currentThemeIdentifier = "a"
        val text = TextView(activity).apply { cyl_themeValueManager = manager; cyl_themeValue = "textColor:title" }
        manager.currentThemeIdentifier = "b"
        assertEquals("not in a window yet", Color.BLACK, text.currentTextColor)
        activity.setContentView(text)
        idle()
        assertEquals(Color.YELLOW, text.currentTextColor)
        assertFalse(text.cyl_ignoresThemeApply)
    }
}
