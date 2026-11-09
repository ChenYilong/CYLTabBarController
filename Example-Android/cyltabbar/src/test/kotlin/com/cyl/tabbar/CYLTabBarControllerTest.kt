package com.cyl.tabbar

import android.graphics.Color
import android.os.Looper
import android.view.View
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
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
        // [EN] As iOS (CYLBadgeAccessibilityDescription): a dot, a number, "99+", 0 and text. [CN] 与 iOS 相同：红点、数字、"99+"、0 与文字。
        assertEquals("New content", CYLBadgeAccessibilityDescription(button.context, ""))
        assertEquals("3 new messages", CYLBadgeAccessibilityDescription(button.context, "3"))
        assertEquals("99+ new messages", CYLBadgeAccessibilityDescription(button.context, "99+"))
        assertNull(CYLBadgeAccessibilityDescription(button.context, "0"))
        assertEquals("NEW", CYLBadgeAccessibilityDescription(button.context, "NEW"))
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
        assertTrue("the plus button's page leaves the screen", TestPlusButton.child.isHidden)
        assertFalse("the tapped tab's page shows again", controller.viewControllers[0].isHidden)
        controller.tabBar.tabBarButtonArray[1].performClick()
        idle()
        assertEquals(1, controller.selectedIndex)
        assertFalse(controller.viewControllers[1].isHidden)
        CYLPlusButton.removePlusButtonForTabBarContext("plus-test")
    }

    object TitledPlusButton : CYLPlusButtonSubclassing {
        override fun plusButton(context: android.content.Context) = CYLPlusButton.cyl_plusButtonWithImage(context, android.graphics.drawable.ColorDrawable(Color.BLUE).apply { setBounds(0, 0, 120, 120) }, "Plus", "Plus!", Color.RED).apply {
            minimumWidth = 120; minimumHeight = 120
            touchableAreaOutsets = CYLEdgeInsets(20f, 0f, 0f, 0f)
        }
        override fun indexOfPlusButtonInTabBar() = 1
        override fun alignsTitleWithTabBarItemTitles() = true
        override fun tabBarItemIdentifier() = "plus"
        override fun tabBarContext() = "titled-plus"
    }

    @Test
    fun plusButtonTitleAlignsWithTabTitlesAndTakesTouchesAboveTheBar() = withActivity { activity ->
        CYLPlusButton.registerPlusButton(TitledPlusButton)
        val controller = CYLTabBarController(activity, listOf(Page(), Page()), attributes("Home", "Me"), CYLEnums.CYLTabBarStyleType.Default, "titled-plus")
        activity.setContentView(controller.view)
        controller.view.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(1920, View.MeasureSpec.EXACTLY))
        controller.view.layout(0, 0, 1080, 1920)
        idle()
        val plus = controller.tabBar.plusButton!!
        assertEquals("plus", plus.cyl_tabBarItemIdentifier)
        assertTrue(plus.cyl_showsTitleInTabBarItem())
        assertEquals("Plus", plus.titleLabel.text)
        val reference = controller.tabBar.tabBarButtonArray[0]
        val tabTitleCenter = reference.top + (reference.titleLabel.top + reference.titleLabel.bottom) / 2
        val plusTitleCenter = plus.top + (plus.titleLabel.top + plus.titleLabel.bottom) / 2
        assertTrue("plus title line $plusTitleCenter near tab title line $tabTitleCenter", kotlin.math.abs(plusTitleCenter - tabTitleCenter) <= 2)
        assertEquals(reference.titleLabel.textSize, plus.titleLabel.textSize, 0.5f)
        assertEquals(1, controller.tabBar.plusButtonIndex())
        assertEquals(2, CYLTabBar.CYLTabbarItemsCount)
        assertEquals(1, CYLTabBar.CYLPlusButtonIndex)
        // [EN] A touch 10 px above the bar, inside the outsets, reaches the plus button (#91). [CN] TabBar 上方 10 px、outsets 之内的触摸到达 PlusButton（#91）。
        val x = (plus.left + plus.right) / 2f
        assertTrue(controller.tabBar.cyl_plusButtonTouchable(x, plus.top - 10f))
        assertFalse(controller.tabBar.cyl_plusButtonTouchable(x, plus.top - 200f))
        // [EN] The raised part above the bar is drawn, not clipped by the bar or the root view. [CN] TabBar 上方的凸起部分会被绘制，不被 TabBar 或根视图裁剪。
        assertTrue("the plus button rises above the bar", plus.top < 0)
        assertFalse(controller.tabBar.clipChildren)
        assertFalse(controller.view.clipChildren)
        plus.setTabLabelHidden(true)
        assertFalse(plus.cyl_showsTitleInTabBarItem())
        CYLPlusButton.removePlusButtonForTabBarContext("titled-plus")
        assertFalse(controller.hasPlusButton())
    }

    @Test
    fun fragmentExtensionsFindTheTabAndSelectOthers() = withActivity { activity ->
        val pages = listOf(Page(), Page(), Page())
        val controller = CYLTabBarController(activity, pages, attributes("Home", "Message", "Me"))
        activity.setContentView(controller.view)
        idle()
        assertTrue(pages[1].cyl_isEmbedInTabBarController)
        assertEquals(1, pages[1].cyl_tabIndex)
        assertEquals("message", pages[1].cyl_tabBarItemIdentifier)
        assertEquals(controller.tabBar.tabBarButtonArray[1], pages[1].cyl_tabButton)
        pages[1].cyl_showBadgeValue("5")
        assertTrue(controller.tabBar.tabBarButtonArray[1].cyl_isShowBadge())
        assertEquals(pages[2], pages[0].cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier("me"))
        assertEquals(2, controller.selectedIndex)
        assertEquals(pages[0], pages[2].cyl_popSelectTabBarChildViewControllerForClassType(Page::class.java))
        assertEquals(0, controller.selectedIndex)
        assertTrue(pages[0].cyl_isEqualToViewController(pages[0]))
        assertFalse(pages[0].cyl_isEqualToViewController(pages[1]))
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
        val json = File(requireNotNull(System.getProperty("cyl.sharedConfiguration"))).readText()
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

    /**
     * [EN] Edge-to-edge (forced from Android 15): the pages keep clear of the status bar and the sides, and the tab bar grows by
     *      the navigation bar (iOS's bottom safe area) while its items keep `tabBarHeight`, so the system bar does not cut them.
     * [CN] edge-to-edge（Android 15 起强制）：页面避开状态栏与两侧，TabBar 增高导航栏的高度（iOS 的底部安全区），各 Item 保持 `tabBarHeight`，
     *      系统栏不会切割它们。
     */
    @Test
    fun keepsTheTabItemsClearOfTheSystemBars() = withActivity { activity ->
        val controller = CYLTabBarController(activity, listOf(Page(), Page()), attributes("Home", "Me"))
        activity.setContentView(controller.view)
        idle()
        val insets = WindowInsetsCompat.Builder()
            .setInsets(WindowInsetsCompat.Type.statusBars(), Insets.of(0, 63, 0, 0))
            .setInsets(WindowInsetsCompat.Type.navigationBars(), Insets.of(0, 0, 0, 48))
            .build()
        ViewCompat.dispatchApplyWindowInsets(controller.view, insets)
        controller.view.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2400, View.MeasureSpec.EXACTLY))
        controller.view.layout(0, 0, 1080, 2400)

        val density = activity.resources.displayMetrics.density
        val itemsHeight = (controller.tabBarHeight * density).toInt()
        assertEquals("the pages start below the status bar", 63, controller.view.paddingTop)
        assertEquals("the bar grows by the navigation bar", itemsHeight + 48, controller.tabBar.height)
        assertEquals("the bar reaches the screen's bottom edge", 2400, controller.tabBar.bottom)
        for (button in controller.tabBar.tabBarButtonArray) {
            assertEquals("an item keeps tabBarHeight, above the navigation bar", itemsHeight, button.height)
        }
    }

    /**
     * [EN] A badge on a view that cannot hold children (an icon in a row): it stays on the icon's top-right corner instead of
     *      joining the row's `LinearLayout`, and it fits its text when the text changes.
     * [CN] 不能包含子视图的视图（行中的图标）上的角标：始终位于图标右上角，而不是成为行 `LinearLayout` 的子视图，并在文字变化时适配文字。
     */
    @Test
    fun badgeOfAnIconInARowSitsOnItsCornerAndFitsItsText() = withActivity { activity ->
        val row = android.widget.LinearLayout(activity).apply { orientation = android.widget.LinearLayout.HORIZONTAL }
        val icon = android.widget.ImageView(activity)
        row.addView(icon, android.widget.LinearLayout.LayoutParams(90, 90).apply { leftMargin = 40; topMargin = 30 })
        row.addView(android.widget.TextView(activity).apply { text = "Title" })
        activity.setContentView(row)
        idle()
        icon.cyl_showBadgeValue("3", CYLEnums.CYLBadgeAnimationType.None)
        idle()
        val badge = icon.cyl_badge!!
        assertEquals("the badge does not join the row", 2, row.childCount)
        // [EN] As iOS (`-cyl_layoutBadgeAtTopRightCorner`): 2 dp right of the right edge. [CN] 与 iOS 相同：右边缘右侧 2 dp。
        val gap = CYL_BADGE_CORNER_GAP_DP * icon.resources.displayMetrics.density
        assertEquals("centered 2 dp right of the icon's right edge", icon.right + gap, (badge.left + badge.right) / 2f, 1f)
        assertEquals("centered on the icon's top edge", icon.top.toFloat(), (badge.top + badge.bottom) / 2f, 1f)
        val narrow = badge.width
        icon.cyl_showBadgeValue("new", CYLEnums.CYLBadgeAnimationType.None)
        assertTrue("\"new\" is wider than \"3\"", badge.width > narrow)
        assertEquals(badge.measuredWidth, badge.width)
        icon.cyl_badgeFont = CYLFont(20f)
        assertEquals("a bigger font grows the badge", badge.measuredHeight, badge.height)
        icon.cyl_clearBadge()
        assertNull(icon.cyl_badge)
    }

    object BadgedPlusButton : CYLPlusButtonSubclassing {
        override fun plusButton(context: android.content.Context) = CYLPlusButton.cyl_plusButtonWithImage(context, android.graphics.drawable.ColorDrawable(Color.BLUE).apply { setBounds(0, 0, 120, 120) }, "Menu", null, null).apply {
            background = android.graphics.drawable.ColorDrawable(Color.MAGENTA)
            minimumWidth = 150; minimumHeight = 150
        }
        override fun indexOfPlusButtonInTabBar() = 1
        override fun tabBarContext() = "badged-plus"
    }

    /**
     * [EN] Each tap of the demo's plus button raises its badge: the button keeps its size (its badge used to widen it, which
     *      stretched its image a little more each time) and the badge stays on the icon's corner.
     * [CN] 演示中每次点击 PlusButton 都会增加角标：按钮保持尺寸（以前角标会加宽按钮，每次都把图片多拉伸一点），角标保持在图标右上角。
     */
    @Test
    fun aPlusButtonBadgeNeverResizesTheButton() = withActivity { activity ->
        CYLPlusButton.registerPlusButton(BadgedPlusButton)
        val controller = CYLTabBarController(activity, listOf(Page(), Page()), attributes("Home", "Me"), CYLEnums.CYLTabBarStyleType.Default, "badged-plus")
        activity.setContentView(controller.view)
        fun layout() {
            controller.view.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(1920, View.MeasureSpec.EXACTLY))
            controller.view.layout(0, 0, 1080, 1920)
        }
        idle(); layout()
        val plus = controller.tabBar.plusButton!!
        val width = plus.width
        val height = plus.height
        for (value in 1..5) {
            plus.cyl_showBadgeValue(value.toString(), CYLEnums.CYLBadgeAnimationType.None)
            idle(); layout()
            assertEquals("width after badge $value", width, plus.width)
            assertEquals("height after badge $value", height, plus.height)
        }
        val badge = plus.cyl_badge!!
        assertEquals("on the icon's right edge", plus.imageView.right.toFloat(), (badge.left + badge.right) / 2f, 1f)
        assertEquals("on the icon's top edge", plus.imageView.top.toFloat(), (badge.top + badge.bottom) / 2f, 1f)
        CYLPlusButton.removePlusButtonForTabBarContext("badged-plus")
    }
}
