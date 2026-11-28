package com.cyl.tabbar.demo

import android.os.Looper
import com.cyl.tabbar.CYLTabBarController
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.time.Duration

/**
 * [EN] The teardown row of the Playback section (docs/Lifecycle-Library.md, step 21; iOS `CYLDemoReleaseRow`): destroying the host
 *      activity runs the dealloc callback armed on the controller, the countdown takes 3 s, and the texts are the shared ones.
 *      Written statically on the Mac, to be run once in the batch on the Windows machine.
 * [CN] Playback 部分的销毁行（docs/Lifecycle-Library.md，第 21 步；对应 iOS 的 `CYLDemoReleaseRow`）：销毁宿主 Activity 会运行登记在控制器上的
 *      dealloc 回调，倒计时为 3 秒，文字使用共用的文字。在 Mac 上静态编写，等测试批次在 Windows 机器上一次运行。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class DemoTeardownTest {
    @Before
    fun clean() = DemoTeardown.reset()

    @After
    fun cleanAfter() = DemoTeardown.reset()

    @Test
    fun theSummaryCountsTheCallbacksThatRan() {
        val activity = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        DemoTeardown.arm(CYLTabBarController.cyl_activeTabBarController() ?: error("no controller in ${activity.javaClass.simpleName}"), "x")
        assertEquals("dealloc callbacks ran: 0 / 1", DemoTeardown.summary())
        DemoTeardown.record("CYLTabBarController")
        assertEquals("dealloc callbacks ran: 1 / 1 (CYLTabBarController)", DemoTeardown.summary())
    }

    @Test
    fun destroyingTheHostActivityRunsTheArmedDeallocCallback() {
        val builder = Robolectric.buildActivity(MainActivity::class.java)
        val activity = builder.setup().get()
        shadowOf(Looper.getMainLooper()).idle()
        val controller = CYLTabBarController.cyl_activeTabBarController() ?: error("no controller in ${activity.javaClass.simpleName}")
        DemoTeardown.arm(controller, "CYLTabBarController")
        assertEquals(0, DemoTeardown.ranCount)
        builder.pause().stop().destroy()
        assertEquals(1, DemoTeardown.ranCount)
        assertEquals(1, DemoTeardown.armedCount)
    }

    @Test
    fun theCountdownTakesThreeSecondsThenShowsTheReleasedScreen() {
        val activity = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        val controller = CYLTabBarController.cyl_activeTabBarController() ?: error("no controller")
        var ticks = 0
        DemoTeardown.start(activity, controller) { ticks += 1 }
        assertEquals(3, DemoTeardown.remaining)
        assertEquals("teardown: releasing in 3 s", DemoTeardown.status())
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(2100))
        assertEquals(1, DemoTeardown.remaining)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(1000))
        assertEquals(0, DemoTeardown.remaining)
        val started = shadowOf(activity).nextStartedActivity
        assertTrue(started.component?.className?.endsWith("DemoReleasedActivity") == true)
        assertTrue(ticks >= 3)
    }
}
