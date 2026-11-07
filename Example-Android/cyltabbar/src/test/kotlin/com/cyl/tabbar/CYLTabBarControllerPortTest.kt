package com.cyl.tabbar

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Bundle
import android.os.Looper
import android.os.SystemClock
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.fragment.app.Fragment
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
import java.io.File

/**
 * [EN] The parts ported for the full API map: tap animation objects, transitions, the animation file layer (with a test
 *      animator and the real lottie-android), theme colors / images / views, badge appearance and samples, memory
 *      warnings, and the handler aliases.
 * [CN] 为完整 API 对照表移植的部分：点击动画对象、转场、动画文件层（测试 animator 与真实的 lottie-android）、主题颜色 / 图片 / 视图、角标外观与示例、
 *      内存警告，以及回调别名。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabBarControllerPortTest {

    /** [EN] A page that counts its view creations (the iOS `-viewDidLoad`). [CN] 记录视图创建次数的页面。 */
    class Page : Fragment() {
        var viewLoads = 0
        override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
            viewLoads++
            return FrameLayout(inflater.context)
        }
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

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun controllerIn(activity: FragmentActivity, pages: List<Fragment>, attributes: List<Map<String, Any?>>): CYLTabBarController {
        val controller = CYLTabBarController(activity, pages, attributes)
        activity.setContentView(controller.view)
        idle()
        return controller
    }

    // MARK: - Tap animations 点击动画

    @Test
    fun tapAnimationObjectsPlaySelectDeselectReselectAndHighlight() = withActivity { activity ->
        val controller = controllerIn(activity, listOf(Page(), Page(), Page()), attributes("Home", "Message", "Me"))
        val calls = ArrayList<String>()
        val animation = CYLTabButtonBlockAnimation().apply {
            selectAnimation = { button, _, _ -> calls += "select ${(button as CYLTabBarItemButton).index}" }
            deselectAnimation = { button, _, _ -> calls += "deselect ${(button as CYLTabBarItemButton).index}" }
            highlightAnimation = { button, _, _ -> calls += "highlight ${(button as CYLTabBarItemButton).index}" }
            dehighlightAnimation = { button, _, _ -> calls += "dehighlight ${(button as CYLTabBarItemButton).index}" }
        }
        controller.cyl_defaultTabButtonAnimation = animation
        val buttons = controller.tabBar.tabBarButtonArray
        buttons[1].performClick()
        buttons[2].performClick()
        assertEquals(listOf("select 1", "deselect 1", "select 2"), calls)

        calls.clear()
        buttons[2].performClick()
        assertEquals("without a reselect block the select animation plays again", listOf("select 2"), calls)
        animation.reselectAnimation = { _, _, _ -> calls += "reselect" }
        buttons[2].performClick()
        assertEquals(listOf("select 2", "reselect"), calls)
        assertTrue(animation.cyl_respondsToSelector("cyl_playReselectAnimationWithTabButton"))
        assertFalse(animation.cyl_respondsToSelector("cyl_playBadgeChangedAnimationWithTabButton"))

        calls.clear()
        controller.cyl_tabButtonTouchDown(buttons[0])
        controller.cyl_tabButtonTouchDown(buttons[1])
        controller.cyl_tabButtonTouchUp(buttons[1])
        assertEquals("one button is highlighted at a time", listOf("highlight 0", "dehighlight 0", "highlight 1", "dehighlight 1"), calls)

        // [EN] A page's own animation wins over the controller's. [CN] 页面自己的动画优先于控制器的。
        calls.clear()
        controller.viewControllers[0].cyl_tabButtonAnimation = CYLTabButtonBlockAnimation().apply { selectAnimation = { _, _, _ -> calls += "page" } }
        buttons[0].performClick()
        assertEquals(listOf("deselect 2", "page"), calls)
    }

    @Test
    fun tapAnimationTypesMapToTheAnimationClasses() {
        assertTrue(CYLTabButtonAnimationForType(CYLEnums.CYLTabButtonTapAnimationType.Scale) is CYLTabButtonScaleAnimation)
        assertTrue((CYLTabButtonAnimationForType(CYLEnums.CYLTabButtonTapAnimationType.BounceWithFireworks) as CYLTabButtonBounceAnimation).playsFireworks)
        assertTrue(CYLTabButtonAnimationForType(CYLEnums.CYLTabButtonTapAnimationType.Fume) is CYLTabButtonFumeAnimation)
        assertNull(CYLTabButtonAnimationForType(CYLEnums.CYLTabButtonTapAnimationType.None))
        // [EN] Classes implement what iOS implements. [CN] 各类实现的方法与 iOS 一致。
        assertTrue(CYLTabButtonFumeAnimation().cyl_respondsToSelector("cyl_resetTabButton"))
        assertFalse(CYLTabButtonScaleAnimation().cyl_respondsToSelector("cyl_playDeselectAnimationWithTabButton"))
        assertTrue(CYLTabButtonPressAnimation().cyl_respondsToSelector("cyl_playHighlightAnimationWithTabButton"))
    }

    @Test
    fun builtInAnimationsRunOnRealViews() = withActivity { activity ->
        val controller = controllerIn(activity, listOf(Page(), Page()), attributes("Home", "Me"))
        val frames = CYLTabButtonFrameAnimation().apply { images = listOf(ColorDrawable(Color.RED), ColorDrawable(Color.BLUE)); playsFireworks = true }
        for (animation in listOf(CYLTabButtonScaleAnimation(), CYLTabButtonZoomInAnimation(), CYLTabButtonBounceAnimation().apply { playsFireworks = true },
                CYLTabButtonRotationAnimation(), CYLTabButtonFumeAnimation(), CYLTabButtonFlipAnimation().apply { direction = 5 }, CYLTabButtonPressAnimation(), frames)) {
            controller.cyl_defaultTabButtonAnimation = animation
            controller.tabBar.tabBarButtonArray[1].performClick()
            controller.tabBar.tabBarButtonArray[0].performClick()
            shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofSeconds(2))
        }
        val icon = controller.tabBar.tabBarButtonArray[1].iconView
        assertEquals("the frame animation restores the icon after deselecting", 1f, icon.scaleX, 0.01f)
    }

    @Test
    fun badgeValueShowsTheBadgeAndPlaysTheBadgeChangedAnimation() = withActivity { activity ->
        val controller = controllerIn(activity, listOf(Page(), Page()), attributes("Home", "Me"))
        var played = 0
        controller.cyl_defaultTabButtonAnimation = CYLTabButtonBlockAnimation().apply { badgeChangedAnimation = { _, _, badge -> if (badge != null) played++ } }
        val item = controller.tabBarItems[1]
        item.badgeValue = "3"
        idle()
        assertTrue(item.cyl_isShowBadge())
        assertEquals(1, played)
        item.badgeValue = null
        assertFalse(item.cyl_isShowBadge())
        item.cyl_showBadgeValue("new", CYLEnums.CYLBadgeAnimationType.ScaleOnce)
        assertTrue(controller.tabBar.tabBarButtonArray[1].cyl_isShowBadge())
    }

    // MARK: - Transitions 转场

    @Test
    fun slideAndInteractiveTransitions() = withActivity { activity ->
        val pages = listOf(Page(), Page())
        val controller = controllerIn(activity, pages, attributes("Home", "Me"))
        val pan = CYLPanGestureRecognizer()
        var interactive: CYLTabBarInteractiveTransition? = null
        val animator = CYLTabBarSlideTransitionAnimator(CYLRectEdge.Left).apply { duration = 0.05 }
        controller.delegate = object : CYLTabBarControllerDelegate {
            override fun tabBarController_animationControllerForTransition(tabBarController: CYLTabBarController, fromViewController: Fragment, toViewController: Fragment) = animator
            override fun tabBarController_interactionControllerForAnimationController(tabBarController: CYLTabBarController, animationController: CYLTabBarSlideTransitionAnimator) = interactive
        }
        controller.selectedIndex = 1
        shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofSeconds(1))
        assertEquals(1, controller.selectedIndex)
        assertEquals(View.GONE, pages[0].view?.visibility)
        assertEquals(0f, pages[1].requireView().translationX, 0.01f)

        // [EN] A pan shorter than 40 % of the width cancels: the previous tab is selected again. [CN] 拖动不足宽度的 40% 时取消：重新选中之前的 Tab。
        interactive = CYLTabBarInteractiveTransition(pan)
        fun touch(action: Int, x: Float) = MotionEvent.obtain(SystemClock.uptimeMillis(), SystemClock.uptimeMillis(), action, x, 10f, 0).also { pan.onTouchEvent(it); it.recycle() }
        touch(MotionEvent.ACTION_DOWN, 300f)
        controller.selectedIndex = 0
        touch(MotionEvent.ACTION_MOVE, 280f)
        touch(MotionEvent.ACTION_UP, 280f)
        shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofSeconds(1))
        assertEquals("cancelled", 1, controller.selectedIndex)
    }

    // MARK: - Animation files 动画文件

    private class TestPlayer(view: View) : CYLTabBarItemAnimationBasePlayer(view) {
        val events = ArrayList<String>()
        override fun play() { events += "play" }
        override fun showLastFrame() { events += "last" }
        override fun stop() { events += "stop" }
        override var animationSpeed: Float = 1f
        var colors: Map<String, Int>? = null
        override fun applyColors(colors: Map<String, Int>?, configuration: Configuration) { this.colors = colors }
    }

    private class TestAnimator(override val identifier: String, private val extension: String, override val priority: Int = 0, override val attributeKeys: Map<String, String> = emptyMap()) : CYLTabBarItemAnimator {
        val players = HashMap<View, TestPlayer>()
        override val fileExtensions = listOf(extension)
        override fun canAnimateFileAtURL(url: String) = CYLTabBarAnimationFileExtension(url) == extension
        override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View = ImageView(context).also { it.contentDescription = url }
        override fun playerForAnimationView(view: View) = if (view is ImageView && view.contentDescription?.endsWith(extension) == true || view.contentDescription?.contains(".$extension#") == true) players.getOrPut(view) { TestPlayer(view) } else null
    }

    @Test
    fun animatorRegistryFactoryAndURLOptions() {
        val registry = CYLTabBarItemAnimatorRegistry()
        val json = TestAnimator("Test", "json", priority = CYLTabBarItemAnimatorPriorityFallback)
        val pag = TestAnimator("TestPAG", "pag", attributeKeys = mapOf(CYLConstants.CYLTabBarAnimationURL to CYLConstants.CYLTabBarPAGURL))
        registry.registerAnimator(json)
        registry.registerAnimator(pag)
        assertEquals(listOf("TestPAG", "Test"), registry.animators().map { it.identifier })
        assertSame(pag, registry.animatorForURL("https://example.com/icon.pag"))
        assertSame(json, registry.animatorForURL("a/b/icon.json#artboard=HOME"))
        registry.bindURL("icon.data", pag)
        assertSame(pag, registry.animatorForURL("icon.data"))
        assertSame(pag, registry.animatorForAttributes(mapOf(CYLConstants.CYLTabBarPAGURL to "x.pag")))
        assertEquals(CYLConstants.CYLTabBarPAGURL, registry.attributeKeyForGenericKey(CYLConstants.CYLTabBarAnimationURL, mapOf(CYLConstants.CYLTabBarPAGURL to "x.pag")))
        assertEquals(listOf("pag", "json"), registry.fileExtensions())
        registry.unregisterAnimatorWithIdentifier("TestPAG")
        assertNull(registry.animatorWithIdentifier("TestPAG"))

        val url = CYLTabBarAnimationURLWithOptions("file:///icons.riv", mapOf("stateMachine" to "Tab", "artboard" to "HOME & AWAY", "empty" to ""))
        assertEquals("file:///icons.riv#artboard=HOME%20%26%20AWAY&stateMachine=Tab", url)
        assertEquals(mapOf("artboard" to "HOME & AWAY", "stateMachine" to "Tab"), CYLTabBarAnimationFileAndOptions(url!!).second)
        assertNull(CYLTabBarAnimationURLWithOptions(null, mapOf("a" to "b")))
    }

    @Suppress("DEPRECATION")
    @Test
    fun animatedTabsPlayOnSelectionAndFollowDarkMode() = withActivity { activity ->
        val animator = TestAnimator("TestAnimated", "anim")
        CYLTabBarItemAnimatorRegistry.registerAnimator(animator)
        try {
            CYLConstants.cyl_registerDarkLottieURL("home_dark.anim", "home.anim")
            val tabs = listOf(
                mapOf(CYLConstants.CYLTabBarItemTitle to "Home", CYLConstants.CYLTabBarAnimationFilePath to "home.anim", CYLConstants.CYLTabBarAnimationColors to mapOf("**.Fill" to "#FF0000")),
                mapOf(CYLConstants.CYLTabBarItemTitle to "Me", CYLConstants.CYLTabBarAnimationFilePath to "me.anim", CYLConstants.CYLTabBarAnimationSize to "{40, 40}"),
                mapOf(CYLConstants.CYLTabBarItemTitle to "Static"),
            )
            val controller = controllerIn(activity, listOf(Page(), Page(), Page()), tabs)
            val buttons = controller.tabBar.tabBarButtonArray
            assertTrue(controller.tabBarItemAnimationViewAdded)
            assertEquals(listOf("home.anim", "me.anim"), controller.tabBarItemAnimationURLs)
            assertEquals(CYLSize(40f, 40f), controller.tabBarItemAnimationSizes[1])
            assertFalse(buttons[2].cyl_isTabBarItemAnimationReady())
            assertEquals(View.INVISIBLE, buttons[0].iconView.visibility)
            val home = buttons[0].cyl_tabBarItemAnimationPlayer as TestPlayer
            val me = buttons[1].cyl_tabBarItemAnimationPlayer as TestPlayer
            assertEquals("the tab selected at launch shows its last frame (#389)", "last", home.events.last())
            assertEquals(Color.RED, home.colors?.get("**.Fill"))
            buttons[1].performClick()
            assertEquals("play", me.events.last())
            assertEquals("stop", home.events.last())
            controller.tabBarItemAnimationSpeed = 2f
            assertEquals(2f, me.animationSpeed, 0.01f)
            val dark = Configuration(activity.resources.configuration).apply { uiMode = Configuration.UI_MODE_NIGHT_YES or (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) }
            assertEquals("home_dark.anim", CYLTabBarItemAnimationStyleSource.urlForStyle("home.anim", dark))
            assertTrue(CYLConstants.cyl_hasDarkLottieForLottieURL("home.anim"))
            assertTrue(CYLConstants.isTabBarItemAnimationEnabledWithURLs(null, tabs))
        } finally {
            CYLTabBarItemAnimatorRegistry.unregisterAnimatorWithIdentifier("TestAnimated")
        }
    }

    @Test
    fun lottieAnimatorWorksWithLottieAndroid() = withActivity { activity ->
        assertTrue("lottie-android is on the test classpath", CYLLottieTabBarItemAnimator.isAvailable)
        assertNotNull(CYLTabBarItemAnimatorRegistry.sharedRegistry.animatorWithIdentifier("Lottie"))
        val file = File.createTempFile("tab", ".json").apply {
            writeText("""{"v":"5.7.4","fr":30,"ip":0,"op":30,"w":30,"h":30,"layers":[{"ty":4,"nm":"Shape","ip":0,"op":30,"st":0,"ks":{},"shapes":[{"ty":"fl","nm":"Fill 1","c":{"a":0,"k":[1,0,0,1]},"o":{"a":0,"k":100}}]}]}""")
        }
        val view = CYLTabBarItemAnimationFactory.animationViewWithURL(activity, file.absolutePath, CYLSize(30f, 30f), ImageView.ScaleType.FIT_CENTER)
        assertNotNull(view)
        assertTrue(view!!.cyl_isLottieAnimationView())
        val player = CYLTabBarItemAnimationFactory.playerForView(view)!!
        player.animationSpeed = 1.5f
        assertEquals(1.5f, player.animationSpeed, 0.01f)
        player.applyColors(mapOf("Shape.Fill 1.Color" to Color.BLUE), activity.resources.configuration)
        player.play()
        player.showLastFrame()
        player.stop()
        assertEquals(0f, player.progress, 0.01f)
    }

    @Test
    fun gifAnimatorIsRegisteredAndGIFKeysAreRead() = withActivity { activity ->
        val gif = CYLTabBarItemAnimatorRegistry.sharedRegistry.animatorWithIdentifier("GIF")
        assertNotNull("GIF needs no library", gif)
        assertSame(gif, CYLTabBarItemAnimatorRegistry.animatorForURL("https://example.com/tab_home.gif"))
        assertSame(gif, CYLTabBarItemAnimatorRegistry.animatorForAttributes(mapOf(CYLConstants.CYLTabBarGIFFilePath to "tab.gif")))
        // [EN] A 1 × 1 GIF89a. [CN] 1 × 1 的 GIF89a。
        val bytes = android.util.Base64.decode("R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==", android.util.Base64.DEFAULT)
        val file = File.createTempFile("tab", ".gif").apply { writeBytes(bytes) }
        val tabs = listOf(mapOf(CYLConstants.CYLTabBarItemTitle to "Home", CYLConstants.CYLTabBarGIFFilePath to file.absolutePath, CYLConstants.CYLTabBarGIFSize to "{24, 24}"),
                          mapOf(CYLConstants.CYLTabBarItemTitle to "Me"))
        val controller = controllerIn(activity, listOf(Page(), Page()), tabs)
        idle()
        val button = controller.tabBar.tabBarButtonArray[0]
        assertTrue(button.cyl_isTabBarItemAnimationReady())
        val view = button.cyl_tabBarItemAnimationView as CYLGIFTabBarItemAnimationView
        assertEquals(CYLSize(24f, 24f), controller.tabBarItemAnimationSizes[0])
        val player = button.cyl_tabBarItemAnimationPlayer!!
        player.play(); player.stop(); player.showLastFrame()
        assertTrue(view.duration > 0)
    }

    // MARK: - Themes 主题

    class ThemePage : Fragment(), CYLThemeChangeObserving {
        val identifiers = ArrayList<Any?>()
        override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View = FrameLayout(inflater.context)
        override fun cyl_themeDidChangeByManager(manager: CYLThemeManager?, identifier: Any?, theme: Any?) { identifiers += identifier }
    }

    @Test
    fun themeColorsImagesAndViewsFollowTheTheme() = withActivity { activity ->
        val manager = CYLThemeManagerCenter.themeManagerWithName("port-test")
        assertSame(manager, CYLThemeManagerCenter.themeManagerWithName("port-test"))
        assertTrue(CYLThemeManagerCenter.themeManagers.contains(manager))
        assertSame(CYLThemeManager.defaultManager, CYLThemeManagerCenter.defaultThemeManager)
        manager.addThemeIdentifier("light", "L")
        manager.addThemeIdentifier("dark", "D")
        manager.currentThemeIdentifier = "light"
        val color = CYLThemeColor.cyl_colorWithName("background", "port-test") { _, identifier, _ -> if (identifier == "dark") Color.BLACK else Color.WHITE }
        val red = ColorDrawable(Color.RED)
        val blue = ColorDrawable(Color.BLUE)
        val image = CYLThemeImage.cyl_imageWithThemeManagerName("port-test") { _, identifier, _ -> if (identifier == "dark") blue else red }
        assertEquals(Color.WHITE, color.cyl_rawColor)
        assertEquals("background", color.cyl_themeColorName)

        val page = ThemePage()
        val controller = controllerIn(activity, listOf(page, Page()), attributes("Home", "Me"))
        val label = TextView(activity)
        (page.requireView() as ViewGroup).addView(label)
        label.cyl_setThemeColor(color, "backgroundColor")
        val imageView = ImageView(activity).apply { setImageDrawable(image) }
        (page.requireView() as ViewGroup).addView(imageView)
        var blockRuns = 0
        label.cyl_themeDidChangeBlock = { blockRuns++ }

        manager.currentThemeIdentifier = "dark"
        assertEquals(Color.BLACK, (label.background as ColorDrawable).color)
        assertSame(blue, image.cyl_rawImage?.let { if ((it as ColorDrawable).color == Color.BLUE) blue else red })
        assertEquals(1, blockRuns)
        assertTrue(page.identifiers.contains("dark"))
        assertSame(color, label.cyl_themeColorForKey("backgroundColor"))
        label.cyl_setThemeColor(null, "backgroundColor")
        assertNull(label.cyl_themeColorForKey("backgroundColor"))
        assertNotNull(controller)
    }

    // MARK: - Badges 角标

    @Test
    fun badgeAppearanceSamplesAndBadgeViews() = withActivity { activity ->
        val appearance = CYLBadgeAppearance.globalAppearance
        try {
            appearance.backgroundColor = Color.MAGENTA
            appearance.maximumBadgeNumber = 9
            val host = FrameLayout(activity)
            val view = View(activity)
            host.addView(view, 40, 40)
            activity.setContentView(host)
            view.cyl_showBadgeValue("12")
            assertEquals(Color.MAGENTA, view.cyl_badge?.badgeBackgroundColor)
            assertEquals("9+", view.cyl_badge?.text)
            view.cyl_badgeBackgroundColor = Color.GREEN
            view.cyl_showBadgeValue("3")
            assertEquals("a value set on the view wins", Color.GREEN, view.cyl_badge?.badgeBackgroundColor)
            view.cyl_resetBadgeAppearance()
            assertEquals(Color.MAGENTA, view.cyl_badgeBackgroundColor)
            appearance.radius = -1f
            assertEquals("not positive restores the default", 4f, appearance.radius, 0.01f)
        } finally {
            appearance.reset()
        }
        assertEquals(Color.RED, appearance.backgroundColor)

        assertEquals(35, cyl_badgeStyleCount())
        assertEquals("20. Number (cyl_showBadgeValue:)", cyl_badgeTitleForRow(19))
        assertEquals("8. Shake ×3 (cyl_shakeAnimationRepeatTimes)", cyl_badgeTitleForRow(7))
        val row = FrameLayout(activity)
        val icon = ImageView(activity)
        row.addView(icon, 90, 90)
        activity.setContentView(row)
        for (index in 0 until cyl_badgeStyleCount()) icon.cyl_showBadgeForRow(index)
        assertTrue(icon.cyl_isShowBadge())

        val badgeView = CYLTabBarBadgeView(activity)
        badgeView.text = "99+"
        badgeView.textColor = Color.YELLOW
        assertEquals("99+", badgeView.badgeLabel.text.toString())
        assertEquals(Color.YELLOW, badgeView.badgeLabel.currentTextColor)
        val label = TextView(activity).cyl_badgeTextDisplaying()
        label.text = "new"
        assertEquals("new", label.text)
    }

    @Test
    fun badgeAnimationTypesIncludeTheOnceTypes() = withActivity { activity ->
        val host = FrameLayout(activity)
        val view = View(activity)
        host.addView(view, 40, 40)
        activity.setContentView(host)
        for (type in CYLEnums.CYLBadgeAnimationType.values()) view.cyl_showBadgeValue("1", type)
        assertEquals(9, CYLEnums.CYLBadgeAnimationType.ScaleOnce.rawValue)
        view.cyl_clearBadge()
        assertFalse(view.cyl_isShowBadge())
    }

    // MARK: - Memory warnings, handlers 内存警告、回调

    @Test
    fun memoryWarningUnloadsUnselectedTabsThatLoadAgainWhenSelected() = withActivity { activity ->
        val pages = listOf(Page(), Page(), Page())
        val controller = controllerIn(activity, pages, attributes("Home", "Message", "Me"))
        assertEquals(1, pages[1].viewLoads)
        CYLTabBarController.cyl_simulateMemoryWarningForTabBarController(controller)
        assertNotNull("unloadsUnselectedViewsOnMemoryWarning is off by default", pages[1].view)

        controller.unloadsUnselectedViewsOnMemoryWarning = true
        CYLTabBarController.cyl_simulateMemoryWarningForTabBarController(controller)
        assertNull(pages[1].view)
        assertNull(pages[2].view)
        assertNotNull("the selected tab is kept", pages[0].view)
        controller.tabBar.tabBarButtonArray[1].performClick()
        idle()
        assertNotNull(pages[1].view)
        assertEquals("the view was created again (viewDidLoad)", 2, pages[1].viewLoads)
    }

    @Test
    fun loginAndCustomActionHandlersAndReadyBlocks() = withActivity { activity ->
        val controller = controllerIn(activity, listOf(Page(), Page()), attributes("Home", "Me"))
        var loggedIn = false
        controller.cyl_loginStateProvider = { loggedIn }
        assertFalse(controller.cyl_loggedIn)
        loggedIn = true
        assertTrue(controller.cyl_loggedIn)

        var actions = 0
        controller.cyl_shouldPerformCustomTabActionHandler = { _, page -> page === controller.viewControllers[1] }
        controller.cyl_customTabActionHandler = { _, _ -> actions++ }
        controller.tabBar.tabBarButtonArray[1].performClick()
        assertEquals(1, actions)
        assertEquals("a custom action tab is not selected", 0, controller.selectedIndex)

        var ready = 0
        controller.performWhenTabBarItemsReady { ready++ }
        controller.reloadBadgesWithBlock { ready++ }
        idle()
        assertEquals(2, ready)
        controller.noNeedUIDesignCompatibility = false
        assertEquals(CYLEnums.CYLTabBarStyleType.FlatDesign, controller.tabBarStyleType)
        assertEquals(15.0, CYLTabBarConfiguration.CYLURLRequest("https://example.com/tabs.json").timeoutInterval, 0.0)
    }

    @Test
    fun baseNavigationControllerHidesTheTabBarWhilePushed() = withActivity { activity ->
        val navigation = CYLBaseNavigationController(Page())
        val controller = controllerIn(activity, listOf(navigation, Page()), attributes("Home", "Me"))
        navigation.pushViewController(Page(), animated = false)
        idle()
        shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofSeconds(1))
        assertEquals(2, navigation.viewControllers.size)
        assertEquals(View.GONE, controller.tabBar.visibility)
        navigation.popToRootViewControllerAnimated(false)
        idle()
        shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofSeconds(1))
        assertEquals(View.VISIBLE, controller.tabBar.visibility)
    }
}
