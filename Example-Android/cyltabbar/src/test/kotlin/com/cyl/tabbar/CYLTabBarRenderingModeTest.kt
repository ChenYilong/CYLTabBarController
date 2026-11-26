package com.cyl.tabbar

import androidx.fragment.app.Fragment
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] Tint spec v2, item 6, changed by the owner on 2026-11-27 (as iOS): the tab flow forces no mode; a tab whose animation URL has no usable `tint` and no
 *      `renderingMode` uses the component's `automatic` (a one-color Lottie / GIF follows the title color, other files keep theirs); options are read by
 *      the component. A tab button uses no built-in colors (its tab bar passes the title colors).
 * [CN] 着色规范 v2 第 6 条，负责人于 2026-11-27 修改（与 iOS 一致）：Tab 流程不强制任何模式；动画 URL 没有可用 `tint` 也没有 `renderingMode` 的 Tab 使用组件的 `automatic`
 *      （单色 Lottie / GIF 跟随标题颜色，其他文件保持自身颜色）；选项由组件读取。Tab 按钮不使用内置颜色（其 TabBar 传入标题颜色）。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabBarRenderingModeTest {
    class Page : Fragment()

    @Test
    fun aTabUrlWithoutTintOrRenderingModeIsAutomatic() = withActivity { activity ->
        val items = listOf(mapOf(CYLConstants.CYLTabBarItemTitle to "Home"))
        val controller = CYLTabBarController(activity, items.map { Page() }, items)
        activity.setContentView(controller.view)
        idle()
        val button = controller.tabBar.tabBarButtonArray[0]
        assertNull("nothing set before an animation is attached", button.animationRenderingMode)
        // [EN] Owner decision (2026-11-27): nothing is forced, the component's default `Automatic` applies (one-colour files tinted). [CN] 负责人决定：不再强制，使用组件默认的 `Automatic`。
        listOf("home.json", "home.json#loops=1", "home.json#tint=nonsense", "home.gif#tint=", "home.json?speed=2", "home.json#tint=title",
            "home.json#tint=%23FF0000", "home.json#renderingMode=automatic", "home.json#renderingMode=alwaysTemplate", "home.json?tint=title").forEach { url ->
            button.cyl_setTabBarItemAnimationView(null, url)
            assertNull(url, button.animationRenderingMode)
        }
        button.cyl_setTabBarItemAnimationView(null, "home.json#renderingMode=alwaysOriginal")
        assertNull("the URL option is read by the component itself", button.animationRenderingMode)
    }
}
