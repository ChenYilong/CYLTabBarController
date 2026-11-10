package com.cyl.tabbar

import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.fragment.app.FragmentActivity
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import android.os.Looper

/**
 * [EN] The library's texts in a chosen language (CYLLocalization, as iOS CYLSetLocalizationLanguage()) and the right-to-left
 *      tab bar.
 * [CN] 库文字使用所选语言（CYLLocalization，对应 iOS 的 CYLSetLocalizationLanguage()）以及从右到左的 TabBar。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLLocalizationTest {
    @After
    fun tearDown() {
        CYLLocalization.language = null
    }

    @Test
    fun theLibraryTextsFollowTheChosenLanguage() {
        val context = Robolectric.buildActivity(FragmentActivity::class.java).setup().get()
        CYLLocalization.language = "ar"
        assertEquals("رسائل جديدة: 3", CYLBadgeAccessibilityDescription(context, "3"))
        // [EN] The "NEW" token is shown in the language too, as iOS. [CN] 与 iOS 相同，"NEW" 标记也使用该语言显示。
        val tab = android.widget.FrameLayout(context)
        android.widget.FrameLayout(context).addView(tab)
        tab.cyl_showBadgeValue("NEW")
        assertEquals("جديد", tab.cyl_badge?.text)
        CYLLocalization.language = "zh-Hans"
        assertEquals("有新内容", CYLBadgeAccessibilityDescription(context, ""))
        assertEquals("加号按钮", CYLPlusButton(context).contentDescription)
        CYLLocalization.language = "es"
        assertEquals("Botón más", CYLPlusButton(context).contentDescription)
        // [EN] The title shown wins, and a description set by the app wins over both. [CN] 显示的标题优先，App 设置的描述优先于两者。
        val titled = CYLPlusButton(context).apply { setTitle("Post") }
        assertEquals("Post", titled.contentDescription)
        titled.contentDescription = "Compose"
        assertEquals("Compose", titled.contentDescription)
        assertTrue(CYLLocalization.isRightToLeft("ar"))
        assertFalse(CYLLocalization.isRightToLeft("zh-Hans"))
    }

    @Test
    fun aRightToLeftLanguageMirrorsTheTabBar() {
        val controller = Robolectric.buildActivity(FragmentActivity::class.java).setup()
        val activity = controller.get()
        val root = FrameLayout(activity)
        activity.setContentView(root)
        val host = CYLTabBarHostView(activity)
        root.addView(host, FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 300))
        host.language = "ar"
        assertEquals("ar", CYLLocalization.language)
        host.configuration = mapOf(
            CYLConstants.CYLTabBarControllerTabBarItemsAttributes to listOf(
                mapOf(CYLConstants.CYLTabBarItemTitle to "A", CYLConstants.CYLTabBarItemIdentifier to "a"),
                mapOf(CYLConstants.CYLTabBarItemTitle to "B", CYLConstants.CYLTabBarItemIdentifier to "b"),
            ),
        )
        val tabBarController = waitForController(host, root)
        val buttons = (0 until tabBarController.tabBar.childCount).map { tabBarController.tabBar.getChildAt(it) }.filterIsInstance<CYLTabBarItemButton>()
        // [EN] The first tab on the right, as iOS, also in this app without android:supportsRtl. [CN] 与 iOS 相同，第一个 Tab 位于最右侧；
        //      本测试 App 未声明 android:supportsRtl 也是如此。
        assertTrue(tabBarController.tabBar.cyl_isRightToLeftLayout)
        assertTrue(buttons[0].left > buttons[1].left)
        host.language = "en"
        val rebuilt = waitForController(host, root)
        val leftToRight = (0 until rebuilt.tabBar.childCount).map { rebuilt.tabBar.getChildAt(it) }.filterIsInstance<CYLTabBarItemButton>()
        assertTrue(leftToRight[0].left < leftToRight[1].left)
        controller.pause().stop().destroy()
    }

    /** [EN] The bar is built after its images load, then laid out. [CN] 图片加载后创建 TabBar，然后布局。 */
    private fun waitForController(host: CYLTabBarHostView, root: FrameLayout): CYLTabBarController {
        repeat(150) {
            root.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2000, View.MeasureSpec.EXACTLY))
            root.layout(0, 0, 1080, 2000)
            shadowOf(Looper.getMainLooper()).idle()
            val controller = host.tabBarController
            if (controller != null && controller.tabBar.width > 0) {
                root.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2000, View.MeasureSpec.EXACTLY))
                root.layout(0, 0, 1080, 2000)
                return controller
            }
            Thread.sleep(20)
        }
        throw AssertionError("the tab bar controller was not built")
    }
}
