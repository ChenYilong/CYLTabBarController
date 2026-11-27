package com.cyl.tabbar

import android.view.View
import android.view.ViewGroup
import android.widget.ScrollView
import androidx.fragment.app.Fragment
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] The "More" tab, as on iOS: more than five view controllers show the first four tabs (three with a plus button that
 *      has its own page) and "More"; `cyl_showsAllTabs` (Android only) and the scrollable mode show every tab.
 * [CN] 与 iOS 一致的「更多」Tab：超过五个视图控制器时显示前四个 Tab（PlusButton 有自己的页面时为三个）和「更多」；`cyl_showsAllTabs`（仅 Android）
 *      与可滚动模式显示全部 Tab。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabBarMoreTest {

    class Page : Fragment()

    private val sevenTitles = arrayOf("Home", "Message", "Find", "Shop", "Video", "Music", "Me")

    private fun controller(activity: androidx.fragment.app.FragmentActivity, vararg titles: String): CYLTabBarController {
        val controller = CYLTabBarController(activity, titles.map { Page() }, attributes(*titles))
        activity.setContentView(controller.view)
        idle()
        return controller
    }

    private fun moreRows(controller: CYLTabBarController): List<View> {
        val scroll = controller.cyl_moreViewController.view as ScrollView
        val content = scroll.getChildAt(0) as ViewGroup
        return (1 until content.childCount).map { content.getChildAt(it) }
    }

    @Test
    fun fiveTabsHaveNoMore() = withActivity { activity ->
        val controller = controller(activity, "Home", "Message", "Find", "Shop", "Me")
        assertNull(controller.tabBar.cyl_moreButton)
        assertEquals(5, controller.tabBar.cyl_visibleTabCount)
        assertTrue(controller.tabBar.tabBarButtonArray.all { it.visibility == View.VISIBLE })
    }

    @Test
    fun moreThanFiveTabsShowFourAndMore() = withActivity { activity ->
        val controller = controller(activity, *sevenTitles)
        val bar = controller.tabBar
        assertEquals(4, bar.cyl_visibleTabCount)
        val more = bar.cyl_moreButton
        assertNotNull(more)
        more!!
        assertEquals("More", more.contentDescription?.toString()?.substringBefore(','))
        assertEquals("every tab keeps its button", 7, bar.tabBarButtonArray.size)
        assertEquals(View.GONE, bar.tabBarButtonArray[4].visibility)
        assertEquals(View.VISIBLE, bar.tabBarButtonArray[3].visibility)
        assertTrue(more.width > 0)
        assertEquals("equal widths", bar.tabBarButtonArray[0].width, more.width)
    }

    @Test
    fun moreShowsTheListAndAsksTheDelegate() = withActivity { activity ->
        val controller = controller(activity, *sevenTitles)
        val asked = ArrayList<Fragment>()
        val selected = ArrayList<Fragment>()
        controller.delegate = object : CYLTabBarControllerDelegate {
            override fun tabBarController_shouldSelectViewController(tabBarController: CYLTabBarController, viewController: Fragment): Boolean { asked += viewController; return true }
            override fun tabBarController_didSelectViewController(tabBarController: CYLTabBarController, viewController: Fragment) { selected += viewController }
        }
        controller.tabBar.cyl_moreButton!!.performClick()
        idle()
        assertTrue(controller.cyl_isMoreSelected)
        assertSame(controller.cyl_moreViewController, asked.last())
        assertSame(controller.cyl_moreViewController, selected.last())
        assertTrue(controller.cyl_moreViewController.isAdded && !controller.cyl_moreViewController.isHidden)
        assertTrue("the selected tab's page is hidden", controller.viewControllers[0].isHidden)
        assertTrue(controller.tabBar.cyl_moreButton!!.isSelected)
        assertFalse(controller.tabBar.tabBarButtonArray[0].isSelected)
        assertEquals(3, moreRows(controller).size)
    }

    @Test
    fun theDelegateCanRefuseMore() = withActivity { activity ->
        val controller = controller(activity, *sevenTitles)
        controller.delegate = object : CYLTabBarControllerDelegate {
            override fun tabBarController_shouldSelectViewController(tabBarController: CYLTabBarController, viewController: Fragment) = viewController !== tabBarController.cyl_moreViewController
        }
        controller.tabBar.cyl_moreButton!!.performClick()
        idle()
        assertFalse(controller.cyl_isMoreSelected)
        assertEquals(0, controller.selectedIndex)
    }

    @Test
    fun aRowSelectsTheHiddenTabWithMoreHighlighted() = withActivity { activity ->
        val controller = controller(activity, *sevenTitles)
        controller.tabBar.tabBarButtonArray[5].cylShowBadgeValue("3")
        controller.tabBar.cyl_moreButton!!.performClick()
        idle()
        val rows = moreRows(controller)
        assertTrue("the badge is read with its row", rows[1].contentDescription.toString().startsWith("Music"))
        assertTrue(rows[1].contentDescription.toString().contains("3"))
        rows[1].performClick()
        idle()
        assertEquals(5, controller.selectedIndex)
        assertFalse(controller.cyl_isMoreSelected)
        assertFalse(controller.viewControllers[5].isHidden)
        assertTrue(controller.cyl_moreViewController.isHidden)
        assertTrue("More stays highlighted for a tab under it", controller.tabBar.cyl_moreButton!!.isSelected)
        controller.selectedIndex = 1
        idle()
        assertFalse(controller.tabBar.cyl_moreButton!!.isSelected)
        assertTrue(controller.tabBar.tabBarButtonArray[1].isSelected)
    }

    @Test
    fun selectingAHiddenTabInCodeShowsItsPage() = withActivity { activity ->
        val controller = controller(activity, *sevenTitles)
        controller.selectedIndex = 6
        idle()
        assertFalse(controller.viewControllers[6].isHidden)
        assertTrue(controller.tabBar.cyl_moreButton!!.isSelected)
    }

    @Test
    fun showsAllTabsTurnsMoreOff() = withActivity { activity ->
        val controller = controller(activity, *sevenTitles)
        controller.cyl_showsAllTabs = true
        idle()
        assertNull(controller.tabBar.cyl_moreButton)
        assertEquals(7, controller.tabBar.cyl_visibleTabCount)
        assertTrue(controller.tabBar.tabBarButtonArray.all { it.visibility == View.VISIBLE })
        controller.cyl_showsAllTabs = false
        idle()
        assertNotNull(controller.tabBar.cyl_moreButton)
    }

    @Test
    fun theConfigurationKeyShowsAllTabs() = withActivity { activity ->
        val controller = CYLTabBarController.tabBarControllerWithConfiguration(activity, mapOf(
            CYLConstants.CYLTabBarControllerTabBarItemsAttributes to attributes(*sevenTitles),
            CYLConstants.CYLTabBarControllerPageResolver to { _: String, _: Map<String, Any?> -> Page() },
            CYLConstants.CYLTabBarControllerShowsAllTabs to true,
        ))
        activity.setContentView(controller.view)
        idle()
        assertTrue(controller.cyl_showsAllTabs)
        assertNull(controller.tabBar.cyl_moreButton)
    }

    @Test
    fun theScrollableModeShowsAllTabs() = withActivity { activity ->
        val controller = controller(activity, *sevenTitles)
        controller.tabBar.cyl_scrollMode = CYLTabBarScrollMode.Scrollable
        idle()
        assertNull(controller.tabBar.cyl_moreButton)
        assertEquals(7, controller.tabBar.cyl_visibleTabCount)
    }

    object MorePlusButton : CYLPlusButtonSubclassing {
        val child = Page()
        override fun plusButton(context: android.content.Context) = CYLPlusButton(context).apply { contentDescription = "Plus" }
        override fun indexOfPlusButtonInTabBar() = 1
        override fun plusChildViewController() = child
        override fun tabBarContext() = "more-plus-test"
    }

    @Test
    fun aPlusButtonWithAPageCountsAsAViewController() = withActivity { activity ->
        CYLPlusButton.registerPlusButton(MorePlusButton)
        try {
            val titles = arrayOf("Home", "Message", "Find", "Shop", "Me")
            val controller = CYLTabBarController(activity, titles.map { Page() }, attributes(*titles), CYLEnums.CYLTabBarStyleType.Default, "more-plus-test")
            activity.setContentView(controller.view)
            idle()
            assertEquals("five tabs and the plus page are six", 3, controller.tabBar.cyl_visibleTabCount)
            assertNotNull(controller.tabBar.cyl_moreButton)
        } finally {
            CYLPlusButton.removePlusButtonForTabBarContext("more-plus-test")
        }
    }
}
