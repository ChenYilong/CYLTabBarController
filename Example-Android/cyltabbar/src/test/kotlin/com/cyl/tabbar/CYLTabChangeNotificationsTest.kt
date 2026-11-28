package com.cyl.tabbar

import android.graphics.Color
import android.os.Looper
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertSame
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * [EN] The tab change notifications and the navigation titles that follow the tab titles, as on iOS
 *      (`testNavigationTitleFollowsTabBarItemTitle`, `testSkinUpdatesFollowingNavigationTitlesAndPostsNotifications`,
 *      `testPlusButtonTitleUpdatesItsPageNavigationTitle`).
 * [CN] Tab 变化通知与跟随 Tab 标题的导航标题，与 iOS 的同名测试一致。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabChangeNotificationsTest {

    class Page : Fragment()

    /** [EN] Records every notification posted while `block` runs. [CN] 记录 `block` 执行期间发送的所有通知。 */
    private fun recording(block: () -> Unit): List<CYLNotification> {
        val notes = ArrayList<CYLNotification>()
        val token = CYLNotificationCenter.addObserver(null) { notes += it }
        try {
            block()
        } finally {
            CYLNotificationCenter.removeObserver(token)
        }
        return notes
    }

    @Test
    fun updatesPostExactNotificationsAndTheFollowingPageTitleFollows() = withActivity { activity ->
        val pages = listOf(Page(), Page())
        val controller = CYLTabBarController(activity, pages, attributes("Home", "Me"))
        activity.setContentView(controller.view)
        idle()
        pages.forEach { it.cyl_navigationTitleFollowsTabBarItemTitle = true }
        assertEquals("the selected page's tab title", "Home", activity.title)
        assertEquals("Me", pages[1].cyl_tabBarItemTitle)

        val notes = recording { controller.updateTabBarItemAtIndex(1, mapOf(CYLConstants.CYLTabBarItemTitle to "★ Me")) }
        assertEquals(listOf(CYLConstants.CYLTabBarItemTitleDidChangeNotification, CYLConstants.CYLTabBarItemDidChangeNotification), notes.map { it.name })
        val title = notes[0]
        assertSame(pages[1], title.`object`)
        assertEquals(1, title.userInfo[CYLConstants.CYLTabBarItemIndexKey])
        assertEquals("me", title.userInfo[CYLConstants.CYLTabBarItemIdentifier])
        assertSame(controller, title.userInfo[CYLConstants.CYLTabBarControllerKey])
        assertSame(pages[1], title.userInfo[CYLConstants.CYLTabBarItemViewControllerKey])
        assertSame(controller.tabBarItems[1], title.userInfo[CYLConstants.CYLTabBarItemKey])
        assertEquals("★ Me", title.userInfo[CYLConstants.CYLTabBarItemTitle])
        assertEquals("Me", title.userInfo[CYLConstants.CYLTabBarItemOldTitleKey])
        assertEquals(mapOf(CYLConstants.CYLTabBarItemTitle to "★ Me"), title.userInfo[CYLConstants.CYLTabBarItemChangedAttributesKey])
        assertEquals("an unselected page does not take the title", "Home", activity.title)
        controller.selectedIndex = 1
        assertEquals("★ Me", activity.title)

        val icons = recording { controller.updateTabBarItemAtIndex(0, mapOf(CYLConstants.CYLTabBarItemImage to "missing_icon")) }
        assertEquals(listOf(CYLConstants.CYLTabBarItemIconDidChangeNotification, CYLConstants.CYLTabBarItemDidChangeNotification), icons.map { it.name })
        assertSame(pages[0], icons[0].`object`)
        assertEquals("home", icons[0].userInfo[CYLConstants.CYLTabBarItemIdentifier])

        val provider: CYLTabBarItemIconViewProvider = { _ -> null }
        val providers = recording { controller.setTabBarItemIconViewProvider(provider, 0) }
        assertEquals(listOf(CYLConstants.CYLTabBarItemIconDidChangeNotification), providers.map { it.name })
        assertSame(provider, providers[0].userInfo[CYLConstants.CYLTabBarItemIconViewProviderKey])

        val unchanged = recording { controller.updateTabBarItemAtIndex(1, mapOf(CYLConstants.CYLTabBarItemTitle to "★ Me")) }
        assertEquals("no change, no notification", emptyList<String>(), unchanged.map { it.name })
    }

    @Test
    fun skinsPostPerTabNotificationsThenTheSkinNotification() = withActivity { activity ->
        val pages = listOf(Page(), Page())
        val controller = CYLTabBarController(activity, pages, attributes("A", "B"))
        activity.setContentView(controller.view)
        idle()
        pages[0].cyl_navigationTitleFollowsTabBarItemTitle = true
        val theme = object : CYLTabBarTheme {
            override fun cyl_tabBarItemsAttributesForTabBarController(tabBarController: CYLTabBarController) = listOf(mapOf(CYLConstants.CYLTabBarItemTitle to "★ A"))
            override fun cyl_tabBarAppearanceForTabBarController(tabBarController: CYLTabBarController) = CYLTabBarAppearance(backgroundColor = Color.BLACK)
        }
        val manager = CYLThemeManager("notifications-test")
        manager.addThemeIdentifier("star", theme)
        controller.cyl_themeManager = manager

        val applied = recording { manager.currentThemeIdentifier = "star" }
        assertEquals(listOf(CYLConstants.CYLTabBarItemTitleDidChangeNotification, CYLConstants.CYLTabBarItemDidChangeNotification,
                            CYLConstants.CYLTabBarControllerThemeDidApplyNotification), applied.map { it.name })
        assertSame("only the tab the skin changed", pages[0], applied[0].`object`)
        val skin = applied[2]
        assertSame(controller, skin.`object`)
        assertSame(theme, skin.userInfo[CYLConstants.CYLTabBarThemeKey])
        assertEquals(listOf(0, 1), skin.userInfo[CYLConstants.CYLTabBarItemIndexesKey])
        assertEquals(listOf("a", "b"), skin.userInfo[CYLConstants.CYLTabBarItemIdentifiersKey])
        assertEquals("★ A", activity.title)

        val restored = recording { manager.currentThemeIdentifier = null }
        assertEquals("A", restored[0].userInfo[CYLConstants.CYLTabBarItemTitle])
        assertEquals(CYLConstants.CYLTabBarControllerThemeDidApplyNotification, restored.last().name)
        assertEquals("A", activity.title)
    }

    object NotifyingPlusButton : CYLPlusButtonSubclassing {
        val child = Page()
        override fun plusButton(context: android.content.Context) = CYLPlusButton.cyl_plusButtonWithImage(context, android.graphics.drawable.ColorDrawable(Color.BLUE), "Post", null, Color.RED)
        override fun indexOfPlusButtonInTabBar() = 1
        override fun plusChildViewController() = child
        override fun tabBarContext() = "notifying-plus"
    }

    @Test
    fun plusButtonTitleUpdatesItsPageTitleAndPostsWithThePlusButton() = withActivity { activity ->
        CYLPlusButton.registerPlusButton(NotifyingPlusButton)
        try {
            val controller = CYLTabBarController(activity, listOf(Page(), Page()), attributes("Home", "Me"), CYLEnums.CYLTabBarStyleType.Default, "notifying-plus")
            activity.setContentView(controller.view)
            idle()
            val child = NotifyingPlusButton.child
            child.cyl_navigationTitleFollowsTabBarItemTitle = true
            controller.tabBar.plusButton!!.performClick()
            idle()
            assertEquals("Post", child.cyl_tabBarItemTitle)
            assertEquals("Post", activity.title)

            val notes = recording { controller.updatePlusButtonWithAttributes(mapOf(CYLConstants.CYLTabBarItemTitle to "★ Post")) }
            assertEquals(listOf(CYLConstants.CYLTabBarItemTitleDidChangeNotification, CYLConstants.CYLTabBarItemDidChangeNotification), notes.map { it.name })
            assertSame(child, notes[0].`object`)
            assertSame(controller.tabBar.plusButton, notes[0].userInfo[CYLConstants.CYLPlusButtonKey])
            assertSame(child, notes[0].userInfo[CYLConstants.CYLTabBarItemViewControllerKey])
            assertEquals("★ Post", notes[0].userInfo[CYLConstants.CYLTabBarItemTitle])
            assertEquals("Post", notes[0].userInfo[CYLConstants.CYLTabBarItemOldTitleKey])
            assertEquals("★ Post", activity.title)
            assertNotEquals("★ Post", controller.viewControllers[0].cyl_tabBarItemTitle)
            controller.updatePlusButtonWithAttributes(mapOf(CYLConstants.CYLTabBarItemTitle to ""))
            assertEquals("no title names no other page", "", activity.title.toString())
        } finally {
            CYLPlusButton.removePlusButtonForTabBarContext("notifying-plus")
        }
    }
}
