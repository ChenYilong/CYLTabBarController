package com.cyl.tabbar.example.pag

import android.content.Context
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLPlusButton
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

/** [EN] The Android Example-PAG: PAG keys when the files exist, the Menu plus button, the guide, the Grapefruit swap. [CN] Android 版 Example-PAG：文件存在时的 PAG key、"菜单" PlusButton、引导页、西柚皮肤互换。 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class ExamplePAGTest {
    @Test
    fun tabsPlusButtonGuideAndSkin() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val activity = Robolectric.buildActivity(MainActivity::class.java).setup().get()
        shadowOf(Looper.getMainLooper()).idle()
        val controller = activity.tabBarController ?: error("no tab bar controller")
        assertEquals(4, controller.viewControllers.size)
        assertTrue(controller.viewControllers.last() is MePage)
        val plus: CYLPlusButton = controller.tabBar.plusButton ?: error("no plus button")
        assertEquals(context.getString(R.string.menu), plus.titleLabel.text.toString())
        assertEquals("the guide opens on first launch", GuideActivity::class.java.name, shadowOf(activity).nextStartedActivity?.component?.className)
        val downloaded = context.assets.list("").orEmpty().contains("tab_home.pag")
        val path = controller.tabBarItemsAttributes[0][CYLConstants.CYLTabBarAnimationFilePath]
        assertEquals(if (downloaded) "tab_home.pag" else null, path)
        if (downloaded) {
            DemoTheme.apply("Grapefruit")
            assertEquals("tab_me.pag", controller.tabBarItemAttributesAtIndex(2)?.get(CYLConstants.CYLTabBarAnimationFilePath))
            DemoTheme.apply("Default")
            assertEquals("tab_moments.pag", controller.tabBarItemAttributesAtIndex(2)?.get(CYLConstants.CYLTabBarAnimationFilePath))
        }
        CYLThemeManager.defaultManager.currentThemeIdentifier = "Default"
    }

    /** [EN] The methods the library calls by reflection exist in the libpag of this app. [CN] 库通过反射调用的方法在本 App 的 libpag 中存在。 */
    @Test
    fun libpagHasTheReflectedMethods() {
        val view = Class.forName("org.libpag.PAGView", false, javaClass.classLoader)
        val methods = view.methods.map { it.name to it.parameterTypes.map { type -> type.simpleName } }.toSet()
        for (expected in listOf("setPath" to listOf("String"), "flush" to emptyList(), "setScaleMode" to listOf("int"), "setRepeatCount" to listOf("int"),
                                 "setProgress" to listOf("double"), "getProgress" to emptyList(), "play" to emptyList(), "stop" to emptyList())) {
            assertTrue("$expected in PAGView", expected in methods)
        }
    }
}
