package com.cyl.tabbar

import android.content.res.Configuration
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] A live light / dark switch of a host that handles `uiMode` itself (Flutter, React Native): the bar resolves the colors of the new mode again, so
 *      every tab's title (and the icon color that follows it) is the style's default tint of the new mode, not the one of the mode before. Reported on the Flutter
 *      search example: after the switch the unselected icons were near-white on a bar that stayed light.
 * [CN] 自己处理 `uiMode` 的宿主（Flutter、React Native）运行中切换浅色 / 深色：TabBar 重新解析新模式的颜色，因此每个 Tab 的标题（以及随之的图标颜色）是新模式
 *      的样式默认着色，而不是之前模式的。发现于 Flutter search 示例：切换后未选中图标在仍为浅色的 TabBar 上近乎白色。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabBarNightSwitchTest {

    class Page : Fragment()

    private fun show(activity: FragmentActivity, style: CYLEnums.CYLTabBarStyleType): CYLTabBarController {
        val titles = arrayOf("Home", "Message", "Me")
        val controller = CYLTabBarController(activity, titles.map { Page() }, attributes(*titles), style, null)
        activity.setContentView(controller.view)
        idle()
        return controller
    }

    private fun switchTo(activity: FragmentActivity, controller: CYLTabBarController, night: Boolean) {
        val configuration = Configuration(activity.resources.configuration).apply {
            uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or (if (night) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO)
        }
        @Suppress("DEPRECATION")
        activity.resources.updateConfiguration(configuration, activity.resources.displayMetrics)
        controller.tabBar.dispatchConfigurationChanged(configuration)
        idle()
    }

    /** [EN] The title color of the first unselected tab (the second tab). [CN] 第一个未选中 Tab（第二个）的标题颜色。 */
    private fun unselectedTitle(controller: CYLTabBarController) = controller.tabBar.tabBarButtonArray[1].titleLabel.currentTextColor

    @Test
    fun theTitleColorsFollowALiveSwitchOfTheLiquidGlassBar() = withActivity { activity ->
        val controller = show(activity, CYLEnums.CYLTabBarStyleType.LiquidGlass)
        val light = controller.tabBar.unselectedTintColor
        assertEquals(light, unselectedTitle(controller))
        switchTo(activity, controller, night = true)
        val dark = controller.tabBar.unselectedTintColor
        assertNotEquals("the style's default tint differs in the two modes", light, dark)
        assertEquals("the unselected title takes the dark mode tint after the switch", dark, unselectedTitle(controller))
        switchTo(activity, controller, night = false)
        assertEquals("and the light one again", light, unselectedTitle(controller))
    }

    /** [EN] Owner decision D3 (2026-11-27): an unset classic background follows dark mode; a set one is kept. [CN] 负责人决定 D3：未设置的经典背景跟随深色模式；设置的保持不变。 */
    @Test
    fun anUnsetClassicBackgroundFollowsALiveSwitch() = withActivity { activity ->
        val controller = show(activity, CYLEnums.CYLTabBarStyleType.Default)
        fun background() = (controller.tabBar.background as android.graphics.drawable.ColorDrawable).color
        assertEquals(CYLClassicTabBarStyle.LIGHT_DEFAULT_BACKGROUND, background())
        switchTo(activity, controller, night = true)
        assertEquals(CYLClassicTabBarStyle.DARK_DEFAULT_BACKGROUND, background())
        switchTo(activity, controller, night = false)
        assertEquals(CYLClassicTabBarStyle.LIGHT_DEFAULT_BACKGROUND, background())
        controller.cyl_tabBarBackgroundColor = 0xFF336699.toInt()
        controller.tabBar.styleRenderer.applyBackgroundColor(controller.tabBar, controller.cyl_tabBarBackgroundColor)
        switchTo(activity, controller, night = true)
        assertEquals("a set color is kept", 0xFF336699.toInt(), background())
    }

    @Test
    fun theTitleColorsFollowALiveSwitchOfTheFlatBar() = withActivity { activity ->
        val controller = show(activity, CYLEnums.CYLTabBarStyleType.FlatDesign)
        switchTo(activity, controller, night = true)
        assertEquals(controller.tabBar.unselectedTintColor, unselectedTitle(controller))
        switchTo(activity, controller, night = false)
        assertEquals(controller.tabBar.unselectedTintColor, unselectedTitle(controller))
    }
}
