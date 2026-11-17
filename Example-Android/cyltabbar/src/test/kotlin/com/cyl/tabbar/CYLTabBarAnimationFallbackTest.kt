package com.cyl.tabbar

import android.view.View
import androidx.fragment.app.Fragment
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] Tab attributes with an animation file whose library is not in the app (libpag is not on this classpath): no
 *      crash and a normal layout with the animation alone; the static image shows when both are given.
 * [CN] Tab 属性中传入动画文件、但 App 中没有对应动画库（本 classpath 没有 libpag）：只传动画时不崩溃、布局正常；同时传入时显示静态图片。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabBarAnimationFallbackTest {

    class Page : Fragment()

    @Test
    fun animationOnlyAndBothWithoutTheLibrary() = withActivity { activity ->
        val items = listOf(
            mapOf(CYLConstants.CYLTabBarItemTitle to "Only", CYLConstants.CYLTabBarPAGURL to "file:///android_asset/home.pag"),
            mapOf(CYLConstants.CYLTabBarItemTitle to "Both", CYLConstants.CYLTabBarItemImage to androidx.core.content.ContextCompat.getDrawable(activity, android.R.drawable.ic_menu_add),
                CYLConstants.CYLTabBarPAGURL to "file:///android_asset/home.pag"),
            mapOf(CYLConstants.CYLTabBarItemTitle to "Image", CYLConstants.CYLTabBarItemImage to androidx.core.content.ContextCompat.getDrawable(activity, android.R.drawable.ic_menu_add)),
        )
        val controller = CYLTabBarController(activity, items.map { Page() }, items)
        activity.setContentView(controller.view)
        idle()
        val (only, both, image) = controller.tabBar.tabBarButtonArray
        assertNull(only.cyl_tabBarItemAnimationView)
        assertNull(both.cyl_tabBarItemAnimationView)
        assertTrue(only.titleLabel.width > 0)
        assertEquals("tabs keep equal widths", image.width, only.width)
        assertNotNull("the static image is the fallback", both.iconView.drawable)
        assertEquals(View.VISIBLE, both.iconView.visibility)
        assertEquals("the same icon box as the image-only tab", image.iconView.width, both.iconView.width)
        assertEquals("titles line up", image.titleLabel.top, both.titleLabel.top)
        assertFalse(only.cyl_isTabBarItemAnimationReady())
        only.performClick()
        idle()
        assertEquals(0, controller.selectedIndex)
    }
}
