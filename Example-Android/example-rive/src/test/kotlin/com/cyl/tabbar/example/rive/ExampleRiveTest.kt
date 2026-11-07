package com.cyl.tabbar.example.rive

import android.os.Looper
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLThemeManager
import com.cyl.tabbar.demo.DemoTheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

/**
 * [EN] The Android Example-Rive: four Rive tabs and the Start plus button (Timer's page), the Grapefruit swap. rive-android
 *      loads native code, which the JVM cannot: the views fall back, the keys and pages are checked.
 * [CN] Android 版 Example-Rive：四个 Rive Tab 与 Start PlusButton（Timer 的页面）、西柚皮肤互换。rive-android 加载原生代码，JVM 无法加载：视图会回退，
 *      这里检查 key 与页面。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ExampleRiveTest {
    @Test
    fun riveTabsPlusButtonAndSkin() {
        val activity = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        shadowOf(Looper.getMainLooper()).idle()
        val controller = activity.tabBarController ?: error("no tab bar controller")
        assertEquals(listOf("Chat", "Search", "Bell", "User"), controller.tabBarItems.map { it.title })
        val url = controller.tabBarItemsAttributes[0][CYLConstants.CYLTabBarRiveURL] as String
        assertTrue(url, url.startsWith("icons.riv#") && url.contains("artboard=CHAT") && url.contains("input=active"))
        assertEquals("Start", controller.tabBar.plusButton?.titleLabel?.text?.toString())
        assertTrue(StartPlusButton.plusChildViewController() is OnboardingPage)
        DemoTheme.apply("Grapefruit")
        assertTrue((controller.tabBarItemAttributesAtIndex(0)?.get(CYLConstants.CYLTabBarRiveURL) as String).contains("artboard=USER"))
        DemoTheme.apply("Default")
        assertTrue((controller.tabBarItemAttributesAtIndex(0)?.get(CYLConstants.CYLTabBarRiveURL) as String).contains("artboard=CHAT"))
        CYLThemeManager.defaultManager.currentThemeIdentifier = "Default"
    }

    /**
     * [EN] The methods the library calls by reflection exist in the rive-android of this app (classes inspected without
     *      loading its native code).
     * [CN] 库通过反射调用的方法在本 App 的 rive-android 中存在（只检查类，不加载其原生代码）。
     */
    @Test
    fun riveAndroidHasTheReflectedMethods() {
        val view = Class.forName("app.rive.runtime.kotlin.RiveAnimationView", false, javaClass.classLoader)
        val methods = view.methods.map { it.name to it.parameterTypes.size }.toSet()
        for (expected in listOf("setRiveBytes\$default" to 12, "play\$default" to 8, "play\$default" to 6, "setBooleanState" to 3, "fireState" to 2,
                                 "reset" to 0, "stop" to 0, "pause" to 0)) {
            assertTrue("$expected in RiveAnimationView", expected in methods)
        }
    }
}
