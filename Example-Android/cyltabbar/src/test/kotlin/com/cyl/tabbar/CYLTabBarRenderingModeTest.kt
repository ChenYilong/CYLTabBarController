package com.cyl.tabbar

import androidx.fragment.app.Fragment
import com.cyl.animateditem.CYLAnimationRenderingMode
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] Tint spec v2, item 6: the tab flow keeps today's look. A tab whose animation URL has no usable `tint` and no `renderingMode` is
 *      `alwaysOriginal` (a one-color tab icon without `#tint` is not recolored); a `tint` (title or a color) or a `renderingMode` option leaves
 *      the mode to the component. A tab button uses no built-in colors (its tab bar passes the title colors).
 * [CN] 着色规范 v2 第 6 条：Tab 流程保持现有外观。动画 URL 没有可用 `tint` 也没有 `renderingMode` 的 Tab 为 `alwaysOriginal`（没有 `#tint` 的单色 Tab 图标不会被重新着色）；
 *      有 `tint`（title 或颜色）或 `renderingMode` 选项时，模式交给组件。Tab 按钮不使用内置颜色（其 TabBar 传入标题颜色）。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabBarRenderingModeTest {
    class Page : Fragment()

    @Test
    fun aTabUrlWithoutTintOrRenderingModeIsAlwaysOriginal() = withActivity { activity ->
        val items = listOf(mapOf(CYLConstants.CYLTabBarItemTitle to "Home"))
        val controller = CYLTabBarController(activity, items.map { Page() }, items)
        activity.setContentView(controller.view)
        idle()
        val button = controller.tabBar.tabBarButtonArray[0]
        assertNull("nothing set before an animation is attached", button.animationRenderingMode)
        val original = CYLAnimationRenderingMode.AlwaysOriginal
        listOf("home.json", "home.json#loops=1", "home.json#tint=nonsense", "home.gif#tint=", "home.json?speed=2").forEach { url ->
            button.cyl_setTabBarItemAnimationView(null, url)
            assertEquals(url, original, button.animationRenderingMode)
        }
        listOf("home.json#tint=title", "home.json#tint=%23FF0000", "home.json#renderingMode=automatic", "home.json#renderingMode=alwaysTemplate", "home.json?tint=title").forEach { url ->
            button.cyl_setTabBarItemAnimationView(null, url)
            assertNull(url, button.animationRenderingMode)
        }
        button.cyl_setTabBarItemAnimationView(null, "home.json")
        button.cyl_setTabBarItemAnimationView(null, null)
        assertEquals("removing the animation leaves the mode as it was", original, button.animationRenderingMode)
    }
}
