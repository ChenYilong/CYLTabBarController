package com.cyl.tabbar.example.gif

import android.os.Looper
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLGIFDrawable
import com.cyl.tabbar.cyl_badge
import com.cyl.tabbar.demo.DemoListFragment
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.time.Duration

/** [EN] The Android Example-GIF: the three GIF uses, the settings list, the plus button badge. [CN] Android 版 Example-GIF：三种 GIF 用法、设置列表、PlusButton 角标。 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ExampleGIFTest {
    @Test
    fun theThreeGIFUsesAndTheSharedDemo() {
        val activity = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        val controller = activity.tabBarController ?: error("no tab bar controller")
        assertEquals(4, controller.viewControllers.size)
        assertTrue(controller.viewControllers.first() is DemoListFragment)
        assertEquals("tab_rocket.gif", controller.tabBarItemsAttributes[0][CYLConstants.CYLTabBarGIFFilePath])
        assertEquals("tab_star.gif", controller.tabBarItemsAttributes[1][CYLConstants.CYLTabBarAnimationFilePath])
        assertEquals(1.5f, controller.tabBarItemAnimationSpeed)
        assertNotNull("plus button", controller.tabBar.plusButton)
        shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(2000))
        assertEquals("plus button badge after launch", "1", controller.tabBar.plusButton?.cyl_badge?.text)
    }

    @Test
    fun theGIFGivenAsAnImageLoops() {
        val activity = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        val controller = activity.tabBarController ?: error("no tab bar controller")
        // [EN] The image entry: the GIF loops (a CYLGIFDrawable), it is not an animation. Movie decodes nothing on the JVM, so
        //      this part runs only where it can (a device, or a Robolectric with native graphics).
        // [CN] 图片入口：GIF 循环播放（CYLGIFDrawable），不是动画。Movie 在 JVM 上无法解码，因此这部分只在能运行的环境中执行（设备，或使用原生图形的 Robolectric）。
        val gif = activity.assets.open("tab_fire.gif").use { it.readBytes() }
        assumeTrue("Movie decodes GIFs here", CYLGIFDrawable.fromBytes(gif) != null)
        repeat(30) { if (controller.tabBarItems[2].image !is CYLGIFDrawable) { Thread.sleep(100); shadowOf(Looper.getMainLooper()).idle() } }
        assertTrue(controller.tabBarItems[2].image is CYLGIFDrawable)
    }
}
