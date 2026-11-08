package com.cyl.tabbar

import android.graphics.Bitmap
import android.graphics.drawable.BitmapDrawable
import android.os.Looper
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.fragment.app.FragmentActivity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * [EN] `CYLTabBarHostView` (the view the React Native and Flutter components wrap) and `CYLTabBarControllerPlusButton`, on
 *      the JVM (Robolectric).
 * [CN] JVM 上（Robolectric）的 `CYLTabBarHostView`（React Native 与 Flutter 组件封装的视图）与 `CYLTabBarControllerPlusButton`。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabBarHostViewTest {

    private fun <T> withActivity(block: (FragmentActivity) -> T): T {
        val controller = Robolectric.buildActivity(FragmentActivity::class.java).setup()
        try {
            return block(controller.get())
        } finally {
            controller.pause().stop().destroy()
        }
    }

    private fun image(activity: FragmentActivity) = BitmapDrawable(activity.resources, Bitmap.createBitmap(24, 24, Bitmap.Config.ARGB_8888))

    /** [EN] A host view laid out at the bottom of the activity. [CN] 布局在 Activity 底部的宿主视图。 */
    private fun hostView(activity: FragmentActivity): CYLTabBarHostView {
        val root = FrameLayout(activity)
        activity.setContentView(root)
        val host = CYLTabBarHostView(activity)
        root.addView(host, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 300))
        root.measure(android.view.View.MeasureSpec.makeMeasureSpec(1080, android.view.View.MeasureSpec.EXACTLY), android.view.View.MeasureSpec.makeMeasureSpec(2000, android.view.View.MeasureSpec.EXACTLY))
        root.layout(0, 0, 1080, 2000)
        return host
    }

    /** [EN] Images load on a background thread, then the bar is built on the main thread. [CN] 图片在后台线程加载，然后在主线程创建 TabBar。 */
    private fun waitForController(host: CYLTabBarHostView): CYLTabBarController {
        repeat(150) {
            shadowOf(Looper.getMainLooper()).idle()
            host.tabBarController?.let { return it }
            Thread.sleep(20)
        }
        throw AssertionError("the tab bar controller was not built")
    }

    private fun items(vararg titles: String, identifiers: Boolean = true) = titles.map {
        if (identifiers) mapOf(CYLConstants.CYLTabBarItemTitle to it, CYLConstants.CYLTabBarItemIdentifier to it.lowercase()) else mapOf(CYLConstants.CYLTabBarItemTitle to it)
    }

    @Test
    fun invalidJSONChangesNothing() = withActivity { activity ->
        val host = CYLTabBarHostView(activity)
        assertFalse(host.setConfigurationJSON("[1, 2]"))
        assertFalse(host.setConfigurationJSON("not json"))
        assertNull(host.configuration)
        assertTrue(host.setConfigurationJSON("""{"CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "A"}]}"""))
        assertEquals(listOf(mapOf("CYLTabBarItemTitle" to "A")), host.configuration?.get(CYLConstants.CYLTabBarControllerTabBarItemsAttributes))
    }

    @Test
    fun buildsWithEmptyPagesAndItsOwnContext() = withActivity { activity ->
        val host = hostView(activity)
        host.configuration = mapOf(CYLConstants.CYLTabBarControllerTabBarItemsAttributes to items("Home", "Me"))
        val controller = waitForController(host)
        assertEquals(2, controller.viewControllers.size)
        assertTrue(controller.viewControllers.all { it is CYLTabBarHostEmptyPage })
        assertTrue(controller.context.orEmpty().startsWith("CYLTabBarHostView-"))
        assertSame(controller.view, host.getChildAt(0))
    }

    @Test
    fun tabsWithoutAnIdentifierStillGetPages() = withActivity { activity ->
        val host = hostView(activity)
        host.configuration = mapOf(CYLConstants.CYLTabBarControllerTabBarItemsAttributes to items("A", "B", identifiers = false))
        assertEquals(2, waitForController(host).viewControllers.size)
    }

    @Test
    fun selectedIndexAndTabCallback() = withActivity { activity ->
        val host = hostView(activity)
        var selected: Pair<Int, String>? = null
        host.didSelectTab = { index, identifier -> selected = index to identifier }
        host.selectedIndex = 1
        host.configuration = mapOf(CYLConstants.CYLTabBarControllerTabBarItemsAttributes to items("Home", "Me"))
        val controller = waitForController(host)
        assertEquals(1, controller.selectedIndex)
        controller.delegate?.tabBarController_didSelectViewController(controller, controller.viewControllers[0])
        assertEquals(0 to "home", selected)
    }

    @Test
    fun imageResolverTurnsValuesIntoDrawables() = withActivity { activity ->
        val host = hostView(activity)
        val drawable = image(activity)
        var calls = 0
        host.imageResolver = { value -> calls++; if (value == "custom:icon") drawable else null }
        host.configuration = mapOf(CYLConstants.CYLTabBarControllerTabBarItemsAttributes to listOf(
            mapOf(CYLConstants.CYLTabBarItemTitle to "A", CYLConstants.CYLTabBarItemIdentifier to "a", CYLConstants.CYLTabBarItemImage to "custom:icon"),
            mapOf(CYLConstants.CYLTabBarItemTitle to "B", CYLConstants.CYLTabBarItemIdentifier to "b"),
        ))
        val controller = waitForController(host)
        assertEquals(1, calls)
        assertSame(drawable, controller.tabBarItems[0].image)
    }

    @Test
    fun plusButtonKeyRegistersAPlusButtonWithItsAction() = withActivity { activity ->
        val host = hostView(activity)
        var taps = 0
        host.didTapPlusButton = { taps++ }
        host.configuration = mapOf(
            CYLConstants.CYLTabBarControllerContext to "host-test-plus",
            CYLConstants.CYLTabBarControllerTabBarItemsAttributes to items("Home", "Me"),
            CYLConstants.CYLTabBarControllerPlusButton to mapOf(CYLConstants.CYLTabBarItemTitle to "Post", CYLConstants.CYLTabBarItemImage to image(activity)),
        )
        val controller = waitForController(host)
        val plusButton = controller.tabBar.plusButton
        assertNotNull(plusButton)
        plusButton!!.plusChildViewControllerButtonClicked()
        assertEquals(1, taps)
    }

    @Test
    fun eachContextKeepsItsOwnPlusButton() = withActivity { activity ->
        var tapsA = 0
        var tapsB = 0
        CYLPlusButton.cyl_registerPlusButtonWithAttributes(activity, mapOf(CYLConstants.CYLTabBarItemTitle to "A", CYLConstants.CYLTabBarItemImage to image(activity)), { tapsA++ }, "host-test-a")
        CYLPlusButton.cyl_registerPlusButtonWithAttributes(activity, mapOf(CYLConstants.CYLTabBarItemImage to image(activity)), { tapsB++ }, "host-test-b")
        val plusA = CYLPlusButton.plusButtonForTabBarContext("host-test-a", activity)
        val plusB = CYLPlusButton.plusButtonForTabBarContext("host-test-b", activity)
        assertNotNull(plusA)
        assertNotNull(plusB)
        plusA!!.plusChildViewControllerButtonClicked()
        assertEquals(1 to 0, tapsA to tapsB)
        plusB!!.plusChildViewControllerButtonClicked()
        assertEquals(1 to 1, tapsA to tapsB)
    }

    @Test
    fun plusButtonLayoutKeys() = withActivity { activity ->
        CYLPlusButton.cyl_registerPlusButtonWithAttributes(activity, mapOf(
            CYLConstants.CYLTabBarItemTitle to "Menu",
            CYLConstants.CYLPlusButtonBackgroundImage to image(activity),
            CYLConstants.CYLTabBarItemTitleColor to "#FFFFFF",
            CYLConstants.CYLTabBarItemTitleFont to 15,
            CYLConstants.CYLPlusButtonIndexInTabBar to 1,
            CYLConstants.CYLPlusButtonCenterYMultiplier to 0.3,
            CYLConstants.CYLPlusButtonCenterYOffset to "-10",
            CYLConstants.CYLTabBarItemIdentifier to "plus",
        ), null, "host-test-layout")
        val plusButton = CYLPlusButton.plusButtonForTabBarContext("host-test-layout", activity)!!
        val provider = plusButton.provider!!
        assertEquals(1, provider.indexOfPlusButtonInTabBar())
        assertEquals(0.3f, provider.multiplierOfTabBarHeight(56f), 0.0001f)
        assertEquals(-10f, provider.constantOfPlusButtonCenterYOffsetForTabBarHeight(56f), 0.0001f)
        assertEquals("plus", provider.tabBarItemIdentifier())
        // [EN] A title on a background image does not line up with the tab titles. [CN] 画在背景图上的标题不与 Tab 标题对齐。
        assertFalse(provider.alignsTitleWithTabBarItemTitles())
        assertNotNull(plusButton.background)
        assertEquals(android.graphics.Color.WHITE, plusButton.titleLabel.currentTextColor)
        assertNull(provider.plusChildViewController())
    }

    @Test
    fun plusButtonPageAndInteractionKeys() = withActivity { activity ->
        val menu = androidx.fragment.app.Fragment()
        val controller = CYLTabBarController.tabBarControllerWithConfiguration(activity, mapOf(
            CYLConstants.CYLTabBarControllerContext to "host-test-page",
            CYLConstants.CYLTabBarControllerTabBarItemsAttributes to items("Home", "Me"),
            CYLConstants.CYLTabBarControllerPageResolver to { identifier: String, _: Map<String, Any?> -> if (identifier == "menu") menu else androidx.fragment.app.Fragment() },
            CYLConstants.CYLTabBarControllerPlusButton to mapOf(CYLConstants.CYLTabBarItemTitle to "Menu", CYLConstants.CYLTabBarItemImage to image(activity),
                CYLConstants.CYLTabBarItemPageIdentifier to "menu"),
            CYLConstants.CYLTabBarControllerTabButtonTapAnimation to "bounce",
            CYLConstants.CYLTabBarControllerSwipeToSwitchTab to true,
            CYLConstants.CYLTabBarControllerUserInterfaceStyle to "dark",
        ))
        assertSame(menu, CYLPlusButton.plusChildViewControllerForTabBarContext("host-test-page"))
        assertEquals(1, CYLPlusButton.plusButtonForTabBarContext("host-test-page", activity)!!.provider!!.indexOfPlusButtonInTabBar())
        assertEquals(CYLEnums.CYLTabButtonTapAnimationType.Bounce, controller.cyl_tabButtonTapAnimationType)
        assertTrue(controller.cyl_swipeToSwitchTabEnabled)
    }

    @Test
    fun hostReportsThePlusPageAsMinusOne() = withActivity { activity ->
        val host = hostView(activity)
        var selected: Pair<Int, String>? = null
        var taps = 0
        host.didSelectTab = { index, identifier -> selected = index to identifier }
        host.didTapPlusButton = { taps++ }
        host.configuration = mapOf(
            CYLConstants.CYLTabBarControllerTabBarItemsAttributes to items("Home", "Me"),
            CYLConstants.CYLTabBarControllerPlusButton to mapOf(CYLConstants.CYLTabBarItemTitle to "Menu", CYLConstants.CYLTabBarItemImage to image(activity),
                CYLConstants.CYLTabBarItemIdentifier to "plus", CYLConstants.CYLTabBarItemPageIdentifier to "menu"),
        )
        val controller = waitForController(host)
        assertEquals(2, controller.viewControllers.size)
        controller.tabBar.plusButton!!.plusChildViewControllerButtonClicked()
        assertEquals(1, taps)
        assertEquals(-1 to "plus", selected)
    }

    @Test
    fun plusButtonWithoutAnImageIsNotRegistered() = withActivity { activity ->
        CYLPlusButton.cyl_registerPlusButtonWithAttributes(activity, mapOf(CYLConstants.CYLTabBarItemTitle to "No image"), null, "host-test-no-image")
        assertNull(CYLPlusButton.plusButtonForTabBarContext("host-test-no-image", activity))
    }

    @Test
    fun configuredPlusTitleColorSurvivesTheTabBarTint() = withActivity { activity ->
        val host = hostView(activity)
        host.configuration = mapOf(
            CYLConstants.CYLTabBarControllerTabBarItemsAttributes to items("Home", "Me"),
            CYLConstants.CYLTabBarControllerPlusButton to mapOf(CYLConstants.CYLTabBarItemTitle to "Menu",
                CYLConstants.CYLPlusButtonBackgroundImage to image(activity), CYLConstants.CYLTabBarItemTitleColor to "#FFFFFF",
                CYLConstants.CYLTabBarItemSelectedTitleColor to "#FF0000", CYLConstants.CYLTabBarItemPageIdentifier to "menu"),
        )
        val controller = waitForController(host)
        val plus = controller.tabBar.plusButton as CYLConfigurationPlusButton
        fun drawnColor(): Int? = (plus.titleLabel.text as? android.text.Spanned)
            ?.getSpans(0, plus.titleLabel.text.length, android.text.style.ForegroundColorSpan::class.java)?.singleOrNull()?.foregroundColor
        // [EN] The tab bar tints the title on every selection change; the configured color is drawn over it.
        // [CN] TabBar 每次选中变化时为标题着色；配置的颜色绘制在其上。
        controller.selectedIndex = 1
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals(android.graphics.Color.WHITE, drawnColor())
        plus.isSelected = true
        assertEquals(android.graphics.Color.RED, drawnColor())
        plus.isSelected = false
        assertEquals(android.graphics.Color.WHITE, drawnColor())
    }

    @Test
    fun plusBadgeSitsOnTheVisibleImage() = withActivity { activity ->
        // [EN] A 40 x 40 image whose visible part is 10..30: 10 px of transparent margin on each side.
        // [CN] 40 x 40 的图片，可见部分为 10..30：四周各有 10 像素透明边距。
        val bitmap = Bitmap.createBitmap(40, 40, Bitmap.Config.ARGB_8888)
        for (y in 10 until 30) for (x in 10 until 30) bitmap.setPixel(x, y, android.graphics.Color.BLUE)
        val drawable = BitmapDrawable(activity.resources, bitmap).apply { setTargetDensity(activity.resources.displayMetrics) }
        val visible = CYLConfigurationPlusButton.opaqueBounds(drawable)!!
        val size = drawable.intrinsicWidth.toFloat()
        assertEquals(size / 4, visible.left.toFloat(), 1f)
        assertEquals(size * 3 / 4, visible.right.toFloat(), 1f)
        assertEquals(size / 4, visible.top.toFloat(), 1f)
        CYLPlusButton.cyl_registerPlusButtonWithAttributes(activity, mapOf(CYLConstants.CYLTabBarItemTitle to "Menu",
            CYLConstants.CYLPlusButtonBackgroundImage to drawable), null, "host-test-badge-offset")
        val plus = CYLPlusButton.plusButtonForTabBarContext("host-test-badge-offset", activity)!!
        val density = activity.resources.displayMetrics.density
        assertEquals(CYLOffset(-(drawable.intrinsicWidth - visible.right) / density, visible.top / density), plus.cyl_badgeCenterOffset)
        assertTrue(plus.cyl_badgeCenterOffset.horizontal < 0 && plus.cyl_badgeCenterOffset.vertical > 0)
        assertNull(CYLConfigurationPlusButton.opaqueBounds(BitmapDrawable(activity.resources, Bitmap.createBitmap(8, 8, Bitmap.Config.ARGB_8888))))
    }

    @Test
    fun transparentStripPassesTouchesExceptOnThePlusButton() = withActivity { activity ->
        val root = FrameLayout(activity)
        activity.setContentView(root)
        val host = CYLTabBarHostView(activity).apply { heightIncludesOverflow = true }
        root.addView(host, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 400))
        fun layOut() {
            root.measure(android.view.View.MeasureSpec.makeMeasureSpec(1080, android.view.View.MeasureSpec.EXACTLY), android.view.View.MeasureSpec.makeMeasureSpec(2000, android.view.View.MeasureSpec.EXACTLY))
            root.layout(0, 0, 1080, 2000)
            shadowOf(Looper.getMainLooper()).idle()
        }
        layOut()
        var taps = 0
        var rectsChanged = 0
        host.didTapPlusButton = { taps++ }
        host.touchableRectsDidChange = { rectsChanged++ }
        host.configuration = mapOf(
            CYLConstants.CYLTabBarControllerTabBarItemsAttributes to items("Home", "Me"),
            CYLConstants.CYLTabBarControllerPlusButton to mapOf(CYLConstants.CYLTabBarItemTitle to "Post",
                CYLConstants.CYLTabBarItemImage to BitmapDrawable(activity.resources, Bitmap.createBitmap(120, 120, Bitmap.Config.ARGB_8888)),
                CYLConstants.CYLPlusButtonCenterYMultiplier to 0.0),
        )
        val controller = waitForController(host)
        val density = activity.resources.displayMetrics.density
        // [EN] As React Native and Flutter do: the view takes its preferred height. [CN] 与 React Native、Flutter 相同：视图使用其需要的高度。
        repeat(3) {
            layOut()
            host.layoutParams = host.layoutParams.apply { height = (host.preferredHeight * density).toInt() }
        }
        layOut()
        assertEquals(2, host.touchableRects.size)
        assertTrue(rectsChanged > 0)
        val bar = host.touchableRects[0]
        val plus = host.touchableRects[1]
        // [EN] The content starts below the strip; only the plus button reaches into it. [CN] 内容从透明区域下方开始；只有 PlusButton 伸入其中。
        assertEquals(controller.view.top.toFloat(), bar.top * density, 1f)
        assertTrue(plus.top < bar.top)
        fun touch(action: Int, x: Float, y: Float): Boolean {
            val event = android.view.MotionEvent.obtain(0, 0, action, x, y, 0)
            return host.dispatchTouchEvent(event).also { event.recycle() }
        }
        // [EN] In the strip, beside the plus button: not taken. [CN] 透明区域中、PlusButton 旁边：不接收。
        assertFalse(touch(android.view.MotionEvent.ACTION_DOWN, 4f, plus.top * density + 2))
        // [EN] The plus button's part in the strip: taken, and a tap. [CN] PlusButton 位于透明区域中的部分：接收，并完成点击。
        val x = plus.centerX() * density
        val y = (plus.top + (bar.top - plus.top) / 2) * density
        assertTrue(touch(android.view.MotionEvent.ACTION_DOWN, x, y))
        touch(android.view.MotionEvent.ACTION_UP, x, y)
        shadowOf(Looper.getMainLooper()).idle()
        assertEquals(1, taps)
    }
}
