package com.cyl.tabbar

import android.os.Bundle
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.viewpager2.widget.ViewPager2
import org.junit.Assert.assertEquals
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.time.Duration
import java.util.UUID

/**
 * [EN] The last open items of the QMUI comparison: tab widths by weight, the theme cross-fade
 *      (`themeChangeAnimationDuration`) and the one-line ViewPager2 binding (`cyl_setupWithViewPager2`).
 * [CN] QMUI 对比中最后的待办：按权重分配 Tab 宽度、主题交叉淡入淡出（`themeChangeAnimationDuration`）与一行代码绑定 ViewPager2（`cyl_setupWithViewPager2`）。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLOpenItemsTest {

    class Page : Fragment() {
        override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View = FrameLayout(inflater.context)
    }

    private fun attributes(vararg titles: String) = titles.map { mapOf(CYLConstants.CYLTabBarItemTitle to it, CYLConstants.CYLTabBarItemIdentifier to it.lowercase()) }

    private fun <T> withActivity(block: (FragmentActivity) -> T): T {
        val controller = Robolectric.buildActivity(FragmentActivity::class.java).setup()
        try {
            return block(controller.get())
        } finally {
            controller.pause().stop().destroy()
        }
    }

    private fun idle(seconds: Long = 1) = shadowOf(Looper.getMainLooper()).idleFor(Duration.ofSeconds(seconds))

    private fun controllerWith(activity: FragmentActivity, vararg titles: String): CYLTabBarController {
        val controller = CYLTabBarController(activity, titles.map { Page() }, attributes(*titles))
        activity.setContentView(controller.view)
        idle()
        return controller
    }

    @Test
    fun tabWidthsFollowTheirWeights() = withActivity { activity ->
        val controller = controllerWith(activity, "A", "B", "C")
        val buttons = controller.tabBar.tabBarButtonArray
        assertEquals("equal by default, as on iOS", 1, buttons.map { it.width }.toSet().size)
        controller.tabBar.cyl_itemWidthWeights = listOf(1f, 2f, Float.NaN)
        idle()
        assertTrue(kotlin.math.abs(buttons[1].width - 2 * buttons[0].width) <= 2)
        assertTrue("an invalid weight counts as 1", kotlin.math.abs(buttons[2].width - buttons[0].width) <= 1)
        controller.tabBar.cyl_itemWidthWeights = null
        idle()
        assertEquals(1, buttons.map { it.width }.toSet().size)
    }

    @Test
    fun aThemeChangeCrossFadesWhenAsked() = withActivity { activity ->
        controllerWith(activity, "A", "B")
        val manager = CYLThemeManagerCenter.themeManagerWithName(UUID.randomUUID().toString())
        assertEquals("no animation by default, as on iOS", 0.0, manager.themeChangeAnimationDuration, 0.0)
        manager.addThemeIdentifier("a", "theme a")
        manager.addThemeIdentifier("b", "theme b")
        manager.currentThemeIdentifier = "a"
        assertEquals(0, CYLThemeDispatcher.cyl_snapshotCount)
        manager.themeChangeAnimationDuration = 0.3
        manager.currentThemeIdentifier = "b"
        assertTrue("the window is covered by its snapshot", CYLThemeDispatcher.cyl_snapshotCount > 0)
        idle()
        assertEquals("the snapshot faded out and left", 0, CYLThemeDispatcher.cyl_snapshotCount)
    }

    @Test
    fun aViewPager2HoldsThePagesAndFollowsTheTabs() = withActivity { activity ->
        val controller = controllerWith(activity, "Home", "Message", "Me")
        val selected = ArrayList<Fragment>()
        controller.delegate = object : CYLTabBarControllerDelegate {
            override fun tabBarController_shouldSelectViewController(tabBarController: CYLTabBarController, viewController: Fragment) = viewController !== tabBarController.viewControllers[2]
            override fun tabBarController_didSelectViewController(tabBarController: CYLTabBarController, viewController: Fragment) { selected += viewController }
        }
        controller.cyl_swipesBetweenPages = true
        val pager = ViewPager2(activity)
        controller.cyl_setupWithViewPager2(pager)
        idle()
        assertSame(pager, controller.cyl_viewPager2)
        assertSame(controller.pagesContainer, pager.parent)
        assertEquals(3, pager.adapter?.itemCount)
        assertEquals(false, controller.cyl_swipesBetweenPages)
        assertTrue("every page alive", controller.viewControllers.all { it.isAdded })

        // [EN] A swipe of the pager selects the tab and tells the delegate. [CN] 滑动翻页控件选中 Tab 并通知代理。
        pager.currentItem = 1
        idle()
        assertEquals(1, controller.selectedIndex)
        assertEquals(listOf(controller.viewControllers[1]), selected)

        // [EN] A page `shouldSelect` refuses bounces back. [CN] `shouldSelect` 拒绝的页面会弹回。
        pager.currentItem = 2
        idle()
        assertEquals(1, controller.selectedIndex)
        assertEquals(1, pager.currentItem)

        // [EN] Selecting a tab moves the pager. [CN] 选中 Tab 时移动翻页控件。
        controller.selectedIndex = 0
        idle()
        assertEquals(0, pager.currentItem)

        // [EN] New pages reach the pager. [CN] 新的页面会同步到翻页控件。
        controller.setViewControllers(listOf(Page(), Page()), attributes("One", "Two"))
        idle()
        assertEquals(2, pager.adapter?.itemCount)
        assertTrue(controller.viewControllers.all { it.isAdded })
    }
}
