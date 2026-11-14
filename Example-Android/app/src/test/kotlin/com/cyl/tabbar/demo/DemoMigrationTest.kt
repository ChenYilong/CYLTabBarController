package com.cyl.tabbar.demo

import android.os.Looper
import android.view.View
import androidx.fragment.app.FragmentActivity
import com.cyl.tabbar.CYLTabBarController
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.time.Duration

/**
 * [EN] The demo rows ported from the iOS Example (docs/Android-Demo-Migration.md): the counts match iOS, every row runs
 *      without an exception, the configuration failures give a result, the scroll hiding simulations pass, and every
 *      gallery scene opens.
 * [CN] 移植自 iOS Example 的演示行（docs/Android-Demo-Migration.md）：数量与 iOS 一致，每一行运行时不抛异常，配置意外情况都有结果，滚动隐藏模拟通过，
 *      每个展示场景都能打开。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class DemoMigrationTest {

    private fun idle(millis: Long = 0) {
        if (millis > 0) shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(millis)) else shadowOf(Looper.getMainLooper()).idle()
    }

    private fun launch(): Pair<MainActivity, DemoListFragment> {
        val activity = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        idle()
        val home = activity.supportFragmentManager.fragments.filterIsInstance<DemoListFragment>().first { it.page == DemoCatalog.HOME }
        return activity to home
    }

    private fun controllerOf(activity: FragmentActivity): CYLTabBarController =
        CYLTabBarController.cyl_activeTabBarController() ?: error("no tab bar controller in ${activity.javaClass.simpleName}")

    @Test
    fun countsMatchTheIOSExample() {
        assertEquals("configuration edge cases", 46, DemoConfiguration.edgeCaseCount)
        assertEquals("scroll hiding simulations", 39, DemoScrollHide.count)
        assertEquals("gallery scenes", 46, DemoGallery.sceneCount)
        assertEquals("gallery sections", 10, DemoGallery.sections.size)
        assertEquals("skins", 17, DemoTheme.all.size)
    }

    @Test
    fun theFourTabsAreDemoListsWithTheirOwnRows() {
        val (activity, home) = launch()
        val pages = activity.supportFragmentManager.fragments.filterIsInstance<DemoListFragment>()
        assertEquals(listOf(DemoCatalog.HOME, DemoCatalog.MESSAGE, DemoCatalog.DISCOVER, DemoCatalog.ME), pages.map { it.page })
        val titles = DemoCatalog.sections(home).map { it.title }
        for (expected in listOf("General", "Tab bar appearance", "Update tabs in place", "Tab pages, selection and login", "PlusButton", "Tab interactions",
                                "No base class, and helpers", "Configuration file", "Jump and compare", "Tab Bar Gallery", "Badges")) {
            assertTrue("$expected in $titles", titles.contains(expected))
        }
        assertTrue(DemoCatalog.sections(home).first { it.title == "Badges" }.rows.size >= 30)
        val message = pages.first { it.page == DemoCatalog.MESSAGE }
        assertTrue(DemoCatalog.sections(message).first { it.title == "Badges" }.rows.first().title.startsWith("Push a TabBarController of the same context"))
        val discover = pages.first { it.page == DemoCatalog.DISCOVER }
        assertNotNull("the web page ID keeps its URL parameter", discover.url)
    }

    @Test
    fun everySettingsRowRunsWithoutAnException() {
        val (_, home) = launch()
        val skipped = setOf("Badges", "Tab Bar Gallery", "Configuration file")
        for (section in DemoCatalog.sections(home).filter { it.title !in skipped && !it.title.startsWith("Scroll hiding") }) {
            for (row in section.rows) {
                row.subtitle?.invoke(home)
                row.action(home)
                idle()
            }
        }
        // [EN] The rows that toggle a change, run a second time, restore it. [CN] 切换修改的行再运行一次即可恢复。
        for (row in DemoCatalog.sections(home).first { it.title == "Update tabs in place" }.rows) { row.action(home); idle() }
    }

    @Test
    fun everyConfigurationFailureGivesAResult() {
        val (_, home) = launch()
        val network = setOf("D3", "D4", "D5", "D7 · An HTML page (network)", "D10", "C10", "C16")
        val rows = DemoCatalog.sections(home).first { it.title == "Configuration file" }.rows.drop(1)
        assertEquals(46, rows.size)
        for (row in rows.filter { row -> network.none { row.title.startsWith(it) } }) {
            row.action(home)
            idle(2500)
            // [EN] E1 parses on a real background thread, then posts to the main thread. [CN] E1 在真实的后台线程解析，然后投递到主线程。
            repeat(50) { if (row.subtitle?.invoke(home) == null) { Thread.sleep(100); idle(100) } }
            val result = row.subtitle?.invoke(home)
            assertNotNull("${row.title} has a result", result)
            assertTrue("${row.title}: $result", result!!.startsWith("✅") || result.startsWith("❌"))
        }
        val created = rows.associate { it.title to it.subtitle?.invoke(home) }
        assertTrue(created["C11 · Unregistered page IDs"]!!.contains("Skipped 2 tabs"))
        assertTrue(created["A2 · Missing file"]!!.startsWith("❌"))
        assertTrue(created["B27 · Reload with new tabs (code)"]!!.contains("home page reused: true"))
    }

    @Test
    fun scrollHidingSimulationsPass() {
        val (activity, home) = launch()
        val controller = controllerOf(activity)
        val section = DemoScrollHide.section(home)
        section.rows[1].action(home) // [EN] Expand the list. [CN] 展开列表。
        val rows = DemoScrollHide.section(home).rows.drop(2)
        val automatic = listOf("cyl_pushViewController, then pop", "selectedIndex + 1, then back", "onTrimMemory (memory warning)",
                               "cyl_hidesTabBarOnScroll = false, then true", "selectedIndex = the same tab (no change)",
                               "cyl_hidesTabBarOnScroll = true again (no change)", "App: setTabBarHidden(false)", "App: setTabBarHidden(true) for 4 s",
                               "push a page that hides the tab bar (hidesBottomBarWhenPushed), then pop")
        for (title in automatic) {
            val row = rows.first { it.title == title }
            row.action(home)
            idle(6000)
            val result = row.subtitle?.invoke(home)
            assertTrue("$title: $result", result?.startsWith("PASS") == true)
            controller.setTabBarHidden(false, false)
        }
    }

    @Test
    fun aRestoreAfterAWindowFocusLossOrPause() {
        val (activity, _) = launch()
        val controller = controllerOf(activity)
        controller.cyl_hidesTabBarOnScroll = true
        controller.cyl_simulateHideOnScrollForTesting()
        assertTrue(controller.cyl_isTabBarHiddenByScroll)
        // [EN] What the window does when a dialog takes the focus (a hidden framework method). [CN] 弹窗获得焦点时窗口所做的事（框架的隐藏方法）。
        android.view.ViewTreeObserver::class.java.getDeclaredMethod("dispatchOnWindowFocusChange", Boolean::class.javaPrimitiveType)
            .apply { isAccessible = true }.invoke(controller.view.viewTreeObserver, false)
        assertTrue("a dialog took the focus: the bar is back", !controller.cyl_isTabBarHiddenByScroll && controller.tabBar.visibility == View.VISIBLE)
        controller.cyl_simulateHideOnScrollForTesting()
        controller.setTabBarHidden(true, false)
        assertTrue("the app hid the bar: not a scroll hiding session", !controller.cyl_isTabBarHiddenByScroll)
        controller.cyl_scrollDidChange(-40)
        assertEquals("scrolling does not show a bar the app hid", View.GONE, controller.tabBar.visibility)
    }

    @Test
    fun everyGallerySceneOpens() {
        val (activity, _) = launch()
        for ((_, scenes) in DemoGallery.sections) {
            for (scene in scenes) {
                scene.open(activity)
                val intent = shadowOf(activity).nextStartedActivity ?: continue
                val host = Robolectric.buildActivity(DemoHostActivity::class.java, intent).setup()
                idle(1500)
                assertTrue("${scene.title} shows a view", host.get().window.decorView.findViewById<View>(android.R.id.content) != null)
                host.pause().stop().destroy()
            }
        }
    }
}
