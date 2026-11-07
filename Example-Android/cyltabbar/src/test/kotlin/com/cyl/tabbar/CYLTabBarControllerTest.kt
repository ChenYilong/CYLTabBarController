package com.cyl.tabbar

import android.graphics.Color
import android.os.Looper
import android.view.View
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import org.robolectric.Robolectric
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.File

/**
 * [EN] The Android `CYLTabBarController` on the JVM (Robolectric): selection, delegate, identifiers, login, badges,
 *      the plus button, reload, themes, the configuration file and the page registry.
 * [CN] JVM 上（Robolectric）的 Android `CYLTabBarController`：选中、代理、标识、登录、角标、PlusButton、重新加载、主题、配置文件与页面注册表。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabBarControllerTest {

    class Page : Fragment()

    private fun attributes(vararg titles: String) = titles.map { mapOf(CYLConstants.CYLTabBarItemTitle to it, CYLConstants.CYLTabBarItemIdentifier to it.lowercase()) }

    private fun <T> withActivity(block: (FragmentActivity) -> T): T {
        // [EN] Robolectric.buildActivity needs no manifest entry (ActivityScenario does). [CN] Robolectric.buildActivity 不需要在清单中声明。
        val controller = Robolectric.buildActivity(FragmentActivity::class.java).setup()
        try {
            return block(controller.get())
        } finally {
            controller.pause().stop().destroy()
        }
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    @Test
    fun selectsPagesAndAsksTheDelegate() = withActivity { activity ->
        val pages = listOf(Page(), Page(), Page())
        val controller = CYLTabBarController(activity, pages, attributes("Home", "Message", "Me"))
        activity.setContentView(controller.view)
        idle()
        assertEquals(3, controller.viewControllers.size)
        assertEquals(3, controller.tabBar.tabBarButtonArray.size)
        assertEquals(0, controller.selectedIndex)
        assertTrue(pages[0].isAdded && !pages[0].isHidden)
        assertTrue(pages[1].isAdded && pages[1].isHidden)

        val selected = ArrayList<Int>()
        controller.delegate = object : CYLTabBarControllerDelegate {
            override fun tabBarController_shouldSelectViewController(tabBarController: CYLTabBarController, viewController: Fragment) = viewController !== pages[2]
            override fun tabBarController_didSelectViewController(tabBarController: CYLTabBarController, viewController: Fragment) { selected += tabBarController.viewControllers.indexOf(viewController) }
        }
        controller.tabBar.tabBarButtonArray[1].performClick()
        idle()
        assertEquals(1, controller.selectedIndex)
        assertEquals(listOf(1), selected)
        controller.tabBar.tabBarButtonArray[2].performClick()
        idle()
        assertEquals("the delegate refused the third tab", 1, controller.selectedIndex)
        assertEquals("message", controller.cyl_selectedTabBarItemIdentifier)
        assertEquals(2, controller.cyl_indexOfTabBarItemIdentifier("me"))
        assertTrue(controller.cyl_selectTabBarItemWithIdentifier("home"))
        assertEquals(0, controller.selectedIndex)
    }

    @Test
    fun loginInterceptsATabUntilLoggedIn() = withActivity { activity ->
        val controller = CYLTabBarController(activity, listOf(Page(), Page()), attributes("Home", "Me"))
        activity.setContentView(controller.view)
        controller.cyl_loginRequiredTabBarItemIdentifiers = listOf("me")
        var presented = 0
        controller.cyl_presentLoginBlock = { _, _, completion -> presented++; completion(true) }
        controller.tabBar.tabBarButtonArray[1].performClick()
        idle()
        assertEquals(1, presented)
        assertTrue(controller.cyl_loggedIn)
        assertEquals("selected once the login completed", 1, controller.selectedIndex)
        controller.selectedIndex = 0
        controller.tabBar.tabBarButtonArray[1].performClick()
        idle()
        assertEquals("no second login", 1, presented)
    }

    @Test
    fun badgesOnTabButtons() = withActivity { activity ->
        val controller = CYLTabBarController(activity, listOf(Page(), Page()), attributes("Home", "Me"))
        activity.setContentView(controller.view)
        idle()
        val button = controller.tabBar.tabBarButtonArray[1]
        assertFalse(button.cyl_isShowBadge())
        button.cyl_showBadgeValue("120")
        assertTrue(button.cyl_isShowBadge())
        assertEquals("99+", button.cyl_badge?.text)
        button.cyl_badgeMaximumBadgeNumber = 999
        assertEquals("120", button.cyl_badge?.text)
        button.cyl_showBadge()
        assertTrue(button.cyl_badge!!.isDot)
        button.cyl_badgeBackgroundColor = Color.BLUE
        assertEquals(Color.BLUE, button.cyl_badge?.badgeBackgroundColor)
        controller.cyl_hidesBadgeOfSelectedTab = true
        controller.selectedIndex = 1
        assertTrue(button.cyl_isPauseBadge())
        controller.selectedIndex = 0
        assertFalse(button.cyl_isPauseBadge())
        button.cyl_clearBadge()
        assertNull(button.cyl_badge)
        assertEquals("3 new items", CYLBadgeAccessibilityDescription("3"))
    }

    object TestPlusButton : CYLPlusButtonSubclassing {
        val child = Page()
        override fun plusButton(context: android.content.Context) = CYLPlusButton(context).apply { contentDescription = "Plus" }
        override fun indexOfPlusButtonInTabBar() = 1
        override fun plusChildViewController() = child
        override fun tabBarContext() = "plus-test"
    }

    @Test
    fun plusButtonAtItsIndexSelectsItsChild() = withActivity { activity ->
        CYLPlusButton.registerPlusButton(TestPlusButton)
        val controller = CYLTabBarController(activity, listOf(Page(), Page()), attributes("Home", "Me"), CYLEnums.CYLTabBarStyleType.Default, "plus-test")
        activity.setContentView(controller.view)
        idle()
        assertTrue(controller.hasPlusButton())
        assertTrue(controller.hasPlusChildViewController())
        assertEquals(3, controller.allItemsInTabBarCount())
        assertEquals(1, controller.tabBar.plusButtonIndex())
        controller.tabBar.plusButton!!.performClick()
        idle()
        assertTrue(controller.tabBar.plusButtonActive)
        assertTrue(TestPlusButton.child.isAdded && !TestPlusButton.child.isHidden)
        controller.tabBar.tabBarButtonArray[0].performClick()
        idle()
        assertFalse(controller.tabBar.plusButtonActive)
        CYLPlusButton.removePlusButtonForTabBarContext("plus-test")
    }

    @Test
    fun reloadUpdatesTitlesAndKeepsPages() = withActivity { activity ->
        val pages = listOf(Page(), Page())
        val controller = CYLTabBarController(activity, pages, attributes("Home", "Me"))
        activity.setContentView(controller.view)
        controller.updateTabBarItemAtIndex(0, mapOf(CYLConstants.CYLTabBarItemTitle to "Start"))
        assertEquals("Start", controller.tabBarItems[0].title)
        assertEquals(pages, controller.viewControllers)
        controller.reloadTabBarItemsWithAttributes(attributes("A", "B"))
        assertEquals(listOf("A", "B"), controller.tabBarItems.map { it.title })
        assertEquals(listOf("a", "b"), controller.cyl_tabBarItemIdentifiers)
        val replacement = Page()
        controller.replaceViewControllerAtIndex(1, replacement, null)
        assertEquals(replacement, controller.viewControllers[1])
    }

    @Test
    fun themesChangeTheTabsAndRestore() = withActivity { activity ->
        val controller = CYLTabBarController(activity, listOf(Page(), Page()), attributes("Home", "Me"))
        activity.setContentView(controller.view)
        val theme = object : CYLTabBarTheme {
            override fun cyl_tabBarItemsAttributesForTabBarController(tabBarController: CYLTabBarController) = listOf(mapOf(CYLConstants.CYLTabBarItemTitle to "Themed"))
            override fun cyl_tabBarAppearanceForTabBarController(tabBarController: CYLTabBarController) = CYLTabBarAppearance(backgroundColor = Color.BLACK, selectedTitleColor = Color.YELLOW)
        }
        val manager = CYLThemeManager("test")
        manager.addThemeIdentifier("dark", theme)
        controller.cyl_themeManager = manager
        manager.currentThemeIdentifier = "dark"
        assertEquals("Themed", controller.tabBarItems[0].title)
        assertEquals(Color.YELLOW, controller.cyl_tabBarItemSelectedTitleColor)
        manager.currentThemeIdentifier = null
        assertEquals("Home", controller.tabBarItems[0].title)
    }

    @Test
    fun configurationFromTheSharedFileResolvesPagesByIdAndSkipsTheRest() = withActivity { activity ->
        val json = File(System.getProperty("cyl.sharedConfiguration")).readText()
        val registry = CYLTabBarPageRegistry()
        registry.registerPageProvider({ _, _ -> Page() }, listOf("home", "message", "me"))
        registry.registerPageFactory({ request -> if (request.parameters["url"] != null) Page() else null }, "web")
        val configuration = CYLTabBarConfiguration.parse(json, com.cyl.tabbar.pages.TabConfigurationFormat.JSON) + mapOf(CYLConstants.CYLTabBarControllerPageRegistry to registry)
        val controller = CYLTabBarController(activity, configuration)
        activity.setContentView(controller.view)
        assertTrue(controller.cyl_pagesFromPageIdentifiers)
        assertEquals(listOf("JSON", "Message", "Discover", "Me"), controller.tabBarItems.map { it.title })
        assertEquals("CYLConfigurationDemo", controller.context)
        assertEquals(0, controller.cyl_skippedTabs.size)
        controller.reloadTabBarItemsWithAttributes(listOf(mapOf(CYLConstants.CYLTabBarItemTitle to "Me", CYLConstants.CYLTabBarItemIdentifier to "me"), mapOf(CYLConstants.CYLTabBarItemTitle to "Missing", CYLConstants.CYLTabBarItemIdentifier to "missing")))
        assertEquals(listOf("Me"), controller.tabBarItems.map { it.title })
        assertEquals(1, controller.cyl_skippedTabs.size)
        assertEquals("missing", controller.cyl_skippedTabs[0].pageId)
    }

    @Test
    fun configurationValuesAreConverted() {
        assertEquals(CYLEdgeInsets(1f, 2f, 3f, 4f), CYLTabBarConfiguration.edgeInsetsValue("{1, 2, 3, 4}"))
        assertEquals(CYLOffset(0f, -3f), CYLTabBarConfiguration.offsetValue(listOf(0, -3)))
        assertEquals(Color.RED, CYLTabBarConfiguration.colorValue("#FF0000"))
        assertEquals(Color.argb(0x80, 0xFF, 0, 0), CYLTabBarConfiguration.colorValue("#FF000080"))
        assertNull(CYLTabBarConfiguration.colorValue("red"))
        assertEquals(15f, CYLFont.fromConfigurationValue("bold:15")?.size)
        assertTrue(CYLFont.fromConfigurationValue("bold:15")!!.bold)
        assertEquals(true, CYLTabBarConfiguration.boolValue("yes"))
        assertEquals(CYLEnums.CYLTabBarStyleType.LiquidGlass, CYLEnums.CYLTabBarStyleType.fromName("liquidGlass"))
        val normalized = CYLTabBarConfiguration.cyl_normalizedConfiguration(mapOf(CYLConstants.CYLTabBarControllerTabBarItemsAttributes to listOf(
            mapOf(CYLConstants.CYLTabBarItemIdentifier to "tab"), mapOf(CYLConstants.CYLTabBarItemIdentifier to "tab"), "not a tab",
            mapOf(CYLConstants.CYLTabBarItemIdentifier to "ios", CYLConstants.CYLTabBarItemPlatforms to "ios"))))
        @Suppress("UNCHECKED_CAST")
        val items = normalized[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] as List<Map<String, Any?>>
        assertEquals(listOf("tab", "tab-2"), items.take(2).map { it[CYLConstants.CYLTabBarItemIdentifier] })
        assertTrue(items[2].isEmpty())
        assertEquals(true, items[3][CYLTabBarConfiguration.EXCLUDED_KEY])
    }

    @Test
    fun asynchronousPagesAreSwappedIn() = withActivity { activity ->
        val registry = CYLTabBarPageRegistry()
        var deliver: CYLTabBarPageCompletion? = null
        registry.registerAsyncPageFactory({ _, completion -> deliver = completion; null }, "later")
        registry.registerPageProvider({ _, _ -> Page() }, "home")
        val controller = CYLTabBarController(activity, mapOf(CYLConstants.CYLTabBarControllerPageRegistry to registry,
            CYLConstants.CYLTabBarControllerTabBarItemsAttributes to attributes("Later", "Home")))
        activity.setContentView(controller.view)
        assertEquals(1, controller.cyl_pendingPages.size)
        assertTrue(controller.viewControllers[0] is CYLTabBarPagePlaceholder)
        val page = Page()
        deliver!!(page)
        idle()
        assertEquals(page, controller.viewControllers[0])
        assertEquals(0, controller.cyl_pendingPages.size)
    }

    @Test
    fun tabBarHiddenAndScrollHiding() = withActivity { activity ->
        val controller = CYLTabBarController(activity, listOf(Page()), attributes("Home"))
        activity.setContentView(controller.view)
        controller.setTabBarHidden(true, false)
        assertEquals(View.GONE, controller.tabBar.visibility)
        controller.setTabBarHidden(false, false)
        assertEquals(View.VISIBLE, controller.tabBar.visibility)
        controller.cyl_hidesTabBarOnScroll = true
        controller.cyl_simulateHideOnScrollForTesting()
        assertTrue(controller.cyl_isTabBarHiddenByScroll)
        controller.cyl_scrollDidChange(-30)
        assertFalse(controller.cyl_isTabBarHiddenByScroll)
        assertNotNull(CYLTabBarController.cyl_activeTabBarController())
    }
}
