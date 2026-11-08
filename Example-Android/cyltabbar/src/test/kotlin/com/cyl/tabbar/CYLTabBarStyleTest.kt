package com.cyl.tabbar

import android.graphics.drawable.ColorDrawable
import android.os.Looper
import android.view.View
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import org.junit.Assert.assertEquals
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
 * [EN] The tab bar styles (`CYLTabBarStyle.kt`): FlatDesign, translated from iOS `CYLFlatDesignTabBar`, and Liquid Glass,
 *      after Kyant's `LiquidBottomTabs`: where the bar and its items go, the pages under a floating bar, the flat button
 *      layout, appearances, the glass bubble's slots, and switching styles at runtime.
 * [CN] TabBar 样式（`CYLTabBarStyle.kt`）：由 iOS `CYLFlatDesignTabBar` 翻译的扁平样式，以及参考 Kyant `LiquidBottomTabs` 的液态玻璃：TabBar
 *      与各 Item 的位置、浮动 TabBar 下方的页面、扁平按钮布局、外观、玻璃气泡的 slot，以及运行时切换样式。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabBarStyleTest {

    class Page : Fragment()

    private val statusBar = 63
    private val navigationBar = 48

    private fun attributes(vararg titles: String) = titles.map { mapOf(CYLConstants.CYLTabBarItemTitle to it, CYLConstants.CYLTabBarItemIdentifier to it.lowercase()) }

    private fun <T> withActivity(block: (FragmentActivity) -> T): T {
        val activity = Robolectric.buildActivity(FragmentActivity::class.java).setup()
        try {
            return block(activity.get())
        } finally {
            activity.pause().stop().destroy()
        }
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    /** [EN] Shows a controller in `style` with a status bar and a navigation bar, laid out on a 1080 × 2400 screen. [CN] 以 `style` 显示控制器，带状态栏与导航栏，在 1080 × 2400 的屏幕上布局。 */
    private fun show(activity: FragmentActivity, style: CYLEnums.CYLTabBarStyleType, vararg titles: String = arrayOf("Home", "Message", "Me")): CYLTabBarController {
        val controller = CYLTabBarController(activity, titles.map { Page() }, attributes(*titles), style, null)
        activity.setContentView(controller.view)
        idle()
        val insets = WindowInsetsCompat.Builder()
            .setInsets(WindowInsetsCompat.Type.statusBars(), Insets.of(0, statusBar, 0, 0))
            .setInsets(WindowInsetsCompat.Type.navigationBars(), Insets.of(0, 0, 0, navigationBar))
            .build()
        ViewCompat.dispatchApplyWindowInsets(controller.view, insets)
        layout(controller)
        return controller
    }

    private fun layout(controller: CYLTabBarController) {
        controller.view.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2400, View.MeasureSpec.EXACTLY))
        controller.view.layout(0, 0, 1080, 2400)
    }

    private fun dp(activity: FragmentActivity, value: Float) = (value * activity.resources.displayMetrics.density).toInt()

    @Test
    fun flatDesignFloatsOverThePagesWithItsItemsAboveTheNavigationBar() = withActivity { activity ->
        val controller = show(activity, CYLEnums.CYLTabBarStyleType.FlatDesign)
        val itemsHeight = dp(activity, controller.tabBarHeight)
        assertTrue(controller.tabBar.styleRenderer is CYLFlatDesignTabBarStyle)
        assertEquals("the pages reach the bottom, under the bar", 2400 - statusBar, controller.pagesContainer.height)
        assertEquals(2400, controller.tabBar.bottom)
        assertEquals(itemsHeight + navigationBar, controller.tabBar.height)
        for (button in controller.tabBar.tabBarButtonArray) {
            assertEquals(0, button.top)
            assertEquals(itemsHeight, button.height)
        }
        assertNull("the blur is drawn by the style, not a background drawable", controller.tabBar.background)
        assertEquals("iOS FlatDesign: blue when selected", 0xFF007AFF.toInt(), controller.tabBar.tintColor)
        assertEquals("gray otherwise", 0xFF8E8E93.toInt(), controller.tabBar.unselectedTintColor)
    }

    @Test
    fun flatDesignButtonPutsItsTitleTwoDpAboveTheBottom() = withActivity { activity ->
        val controller = show(activity, CYLEnums.CYLTabBarStyleType.FlatDesign)
        val button = controller.tabBar.tabBarButtonArray[0]
        assertEquals((button.height - dp(activity, 2f)).toFloat(), button.titleLabel.bottom.toFloat(), 1f)
        assertTrue("the icon sits above the title", button.iconView.bottom <= button.titleLabel.top)
    }

    @Test
    fun flatDesignCentersStackedItemsAndTheSelectedItemsAppearanceWins() = withActivity { activity ->
        val controller = show(activity, CYLEnums.CYLTabBarStyleType.FlatDesign)
        val bar = CYLTabBarAppearance(backgroundColor = 0xFF112233.toInt(), stackedItemPositioningCentered = true, stackedItemWidth = 60f, stackedItemSpacing = 10f)
        controller.tabBar.standardAppearance = bar
        layout(controller)
        val buttons = controller.tabBar.tabBarButtonArray
        val width = dp(activity, 60f)
        val total = 3 * width + 2 * dp(activity, 10f)
        assertEquals(width.toFloat(), buttons[0].width.toFloat(), 1f)
        assertEquals("centered", (1080 - total) / 2f, buttons[0].left.toFloat(), 2f)
        assertSame(bar, controller.tabBar.cyl_effectiveAppearance())
        val own = CYLTabBarAppearance(backgroundColor = 0xFF445566.toInt())
        controller.tabBarItems[1].standardAppearance = own
        controller.selectedIndex = 1
        assertSame("the selected item's own appearance styles the bar", own, controller.tabBar.cyl_effectiveAppearance())
    }

    @Test
    fun liquidGlassDockFloatsAboveTheNavigationBar() = withActivity { activity ->
        val controller = show(activity, CYLEnums.CYLTabBarStyleType.LiquidGlass)
        val dock = dp(activity, CYLLiquidGlassTabBarStyle.PANEL_HEIGHT)
        val padding = dp(activity, CYLLiquidGlassTabBarStyle.PANEL_PADDING)
        val side = dp(activity, CYLLiquidGlassTabBarStyle.SIDE_MARGIN)
        assertTrue(controller.tabBar.styleRenderer is CYLLiquidGlassTabBarStyle)
        assertEquals("the dock and the navigation bar below it", dock + navigationBar, controller.tabBar.height)
        val frame = controller.tabBar.cyl_itemsFrame
        assertEquals(side + padding, frame.left)
        assertEquals(1080 - side - padding, frame.right)
        assertEquals("the items fill the dock inside its padding", dock - 2 * padding, frame.height())
        val button = controller.tabBar.tabBarButtonArray[0]
        assertEquals(padding, button.top)
        assertTrue("above the navigation bar", controller.tabBar.top + button.bottom <= 2400 - navigationBar)
        assertEquals("the LiquidBottomTabs accent", 0xFF0088FF.toInt(), controller.tabBar.tintColor)
    }

    @Test
    fun liquidGlassBubbleSnapsToTabSlotsAndSkipsAPlusButtonWithoutAPage() = withActivity { activity ->
        CYLPlusButton.registerPlusButton(object : CYLPlusButtonSubclassing {
            override fun plusButton(context: android.content.Context) = CYLPlusButton(context).apply { minimumWidth = 100; minimumHeight = 100 }
            override fun indexOfPlusButtonInTabBar() = 1
            override fun tabBarContext() = "glass-plus"
        })
        val controller = CYLTabBarController(activity, listOf(Page(), Page()), attributes("Home", "Me"), CYLEnums.CYLTabBarStyleType.LiquidGlass, "glass-plus")
        activity.setContentView(controller.view)
        idle()
        layout(controller)
        val bar = controller.tabBar
        assertEquals(3, bar.cyl_slotCount())
        assertEquals(0, bar.cyl_selectedSlot())
        assertEquals("a drag that ends on the plus button goes to a tab", 2, bar.cyl_nearestTabSlot(1.4f))
        bar.cyl_selectSlot(2)
        idle()
        assertEquals("slot 2 is the tab after the plus button", 1, controller.selectedIndex)
        assertEquals(2, bar.cyl_selectedSlot())
        CYLPlusButton.removePlusButtonForTabBarContext("glass-plus")
    }

    /** [EN] The tab buttons of a bar, in order. [CN] TabBar 的各 Tab 按钮（按顺序）。 */
    private fun tabButtons(view: View): List<CYLTabBarItemButton> = when (view) {
        is CYLTabBarItemButton -> listOf(view)
        is android.view.ViewGroup -> (0 until view.childCount).flatMap { tabButtons(view.getChildAt(it)) }
        else -> emptyList()
    }.sortedBy { it.index }

    @Test
    fun liquidGlassDrawsUnselectedTitlesInTheSystemColorAsIOS26() = withActivity { activity ->
        val controller = show(activity, CYLEnums.CYLTabBarStyleType.Default)
        controller.cyl_tabBarItemTitleColor = android.graphics.Color.RED
        controller.cyl_tabBarItemSelectedTitleColor = android.graphics.Color.GREEN
        val bar = controller.tabBar
        val button = tabButtons(bar)[1]
        assertEquals("classic: the app's unselected color", android.graphics.Color.RED, button.titleColor(false, bar))
        controller.tabBarStyleType = CYLEnums.CYLTabBarStyleType.LiquidGlass
        layout(controller)
        assertEquals("Liquid Glass: the system's unselected color", bar.unselectedTintColor, button.titleColor(false, bar))
        assertEquals("the selected color stays the app's", android.graphics.Color.GREEN, button.titleColor(true, bar))
    }

    @Test
    fun aPlusButtonWithItsOwnPageKeepsItsNormalImageWhenSelectedOnLiquidGlass() = withActivity { activity ->
        val normal = ColorDrawable(android.graphics.Color.WHITE)
        val selected = ColorDrawable(android.graphics.Color.YELLOW)
        val page = Page()
        CYLPlusButton.registerPlusButton(object : CYLPlusButtonSubclassing {
            override fun plusButton(context: android.content.Context) = CYLPlusButton(context).apply {
                setImageDrawable(normal)
                setSelectedImageDrawable(selected)
            }
            override fun plusChildViewController() = page
            override fun indexOfPlusButtonInTabBar() = 1
            override fun tabBarContext() = "glass-plus-image"
        })
        val controller = CYLTabBarController(activity, listOf(Page(), Page()), attributes("Home", "Me"), CYLEnums.CYLTabBarStyleType.LiquidGlass, "glass-plus-image")
        activity.setContentView(controller.view)
        idle()
        layout(controller)
        val plus = controller.tabBar.plusButton!!
        plus.isSelected = true
        assertSame("Liquid Glass: the normal image, as iOS", normal, plus.imageView.drawable)
        controller.tabBarStyleType = CYLEnums.CYLTabBarStyleType.FlatDesign
        layout(controller)
        val flatPlus = controller.tabBar.plusButton!!
        flatPlus.isSelected = false
        flatPlus.isSelected = true
        assertSame("FlatDesign: the selected image", selected, flatPlus.imageView.drawable)
        CYLPlusButton.removePlusButtonForTabBarContext("glass-plus-image")
    }

    @Test
    fun aFloatingBarGivesItsHeightToThePagesAsTheirBottomInset() = withActivity { activity ->
        val controller = show(activity, CYLEnums.CYLTabBarStyleType.LiquidGlass)
        var pagesBottom = -1
        ViewCompat.setOnApplyWindowInsetsListener(controller.pagesContainer) { _, insets ->
            pagesBottom = insets.getInsets(WindowInsetsCompat.Type.systemBars()).bottom
            insets
        }
        val insets = WindowInsetsCompat.Builder().setInsets(WindowInsetsCompat.Type.navigationBars(), Insets.of(0, 0, 0, navigationBar)).build()
        ViewCompat.dispatchApplyWindowInsets(controller.view, insets)
        assertEquals(controller.cyl_overlayTabBarHeight(), pagesBottom)
        assertTrue(pagesBottom > navigationBar)
    }

    @Test
    fun theStyleCanChangeAtRuntime() = withActivity { activity ->
        val controller = show(activity, CYLEnums.CYLTabBarStyleType.Default)
        assertSame(CYLClassicTabBarStyle, controller.tabBar.styleRenderer)
        assertEquals(0xFFF9F9F9.toInt(), (controller.tabBar.background as ColorDrawable).color)
        controller.tabBarStyleType = CYLEnums.CYLTabBarStyleType.LiquidGlass
        layout(controller)
        assertTrue(controller.tabBar.styleRenderer is CYLLiquidGlassTabBarStyle)
        assertNull(controller.tabBar.background)
        controller.cyl_tabBarBackgroundColor = 0x80FF0000.toInt()
        controller.tabBarStyleType = CYLEnums.CYLTabBarStyleType.Default
        layout(controller)
        assertEquals("back to the classic bar, with the app's background color", 0x80FF0000.toInt(), (controller.tabBar.background as ColorDrawable).color)
        assertEquals("below the pages again", controller.pagesContainer.bottom, controller.tabBar.top)
    }
}
