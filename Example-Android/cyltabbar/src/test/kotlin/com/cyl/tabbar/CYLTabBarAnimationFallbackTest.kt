package com.cyl.tabbar

import android.content.Context
import android.view.View
import android.widget.ImageView
import androidx.fragment.app.Fragment
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] Tab attributes with an animation file whose library is not in the app (libpag is not on this classpath): no
 *      crash, and the placeholder with the animation alone; the static image shows when both are given.
 * [CN] Tab 属性中传入动画文件、但 App 中没有对应动画库（本 classpath 没有 libpag）：只传动画时不崩溃并显示占位图；同时传入时显示静态图片。
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
        assertNotNull("only an animation that cannot play: the placeholder", only.iconView.drawable)
        assertEquals(View.VISIBLE, only.iconView.visibility)
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

    /**
     * [EN] TODO 4 of docs/Animated-Item.md: the tab button is the animated item component, keeps its tab look and its
     *      own label, and stays a frame for badges.
     * [CN] docs/Animated-Item.md 的 TODO 4：Tab 按钮即动效组件，保留 Tab 外观与自己的朗读文本，并仍是可承载角标的帧布局。
     */
    @Test
    fun theTabButtonIsTheAnimatedItemComponent() = withActivity { activity ->
        val items = listOf(
            mapOf(CYLConstants.CYLTabBarItemTitle to "Home", CYLConstants.CYLTabBarItemImage to androidx.core.content.ContextCompat.getDrawable(activity, android.R.drawable.ic_menu_add)),
            mapOf(CYLConstants.CYLTabBarItemTitle to "Me", CYLConstants.CYLTabBarItemImage to androidx.core.content.ContextCompat.getDrawable(activity, android.R.drawable.ic_menu_add)),
        )
        val controller = CYLTabBarController(activity, items.map { Page() }, items)
        activity.setContentView(controller.view)
        idle()
        val button = controller.tabBar.tabBarButtonArray[1]
        // [EN] Checked by the compiler: the component, and a frame for badges. [CN] 由编译器检查：即动效组件，并且是可承载角标的帧布局。
        val component: com.cyl.animateditem.CYLAnimatedItemView = button
        val frame: android.widget.FrameLayout = button
        assertSame(component, frame)
        assertSame(button.titleView, button.titleLabel)
        assertEquals("Me", button.titleLabel.text.toString())
        assertEquals(android.util.TypedValue.applyDimension(android.util.TypedValue.COMPLEX_UNIT_SP, 10f, activity.resources.displayMetrics), button.titleLabel.textSize, 0.01f)
        assertNotNull(button.iconView.drawable)
        assertTrue(button.iconView.width > 0)
        button.performClick()
        idle()
        assertEquals(1, controller.selectedIndex)
        assertEquals("Me", button.contentDescription.toString())
        button.item.isEnabled = false
        assertEquals("a disabled tab is not dimmed", 1f, button.alpha, 0f)
    }

    /**
     * [EN] An animator whose views wait for a download. [CN] 视图需要等待下载的 animator。
     */
    private class DownloadingAnimator : CYLTabBarItemAnimator {
        override val identifier = "TestDownloading"
        override val fileExtensions = listOf("slow")
        val views = ArrayList<View>()
        override fun canAnimateFileAtURL(url: String) = CYLTabBarAnimationFileExtension(url) == "slow"
        override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View =
            View(context).also { views += it; CYLTabBarItemAnimationFailure.markLoading(it) }
        override fun playerForAnimationView(view: View): CYLTabBarItemAnimationPlayer? = null
    }

    @Test
    fun whileATabsRemoteFileDownloadsItsImageOrThePlaceholderShows() = withActivity { activity ->
        val animator = DownloadingAnimator()
        CYLTabBarItemAnimatorRegistry.registerAnimator(animator)
        try {
            val image = androidx.core.content.ContextCompat.getDrawable(activity, android.R.drawable.ic_menu_add)
            val items = listOf(
                mapOf(CYLConstants.CYLTabBarItemTitle to "Image", CYLConstants.CYLTabBarItemImage to image, CYLConstants.CYLTabBarAnimationURL to "https://example.com/a.slow"),
                mapOf(CYLConstants.CYLTabBarItemTitle to "None", CYLConstants.CYLTabBarAnimationURL to "https://example.com/b.slow"),
            )
            val controller = CYLTabBarController(activity, items.map { Page() }, items)
            activity.setContentView(controller.view)
            idle()
            val (withImage, withoutImage) = controller.tabBar.tabBarButtonArray
            assertTrue(withImage.cyl_isTabBarItemAnimationReady())
            assertEquals("downloading: the tab's image", View.VISIBLE, withImage.iconView.visibility)
            assertNotNull(withImage.iconView.drawable)
            assertEquals("downloading, no image: the placeholder", View.VISIBLE, withoutImage.iconView.visibility)
            assertNotNull(withoutImage.iconView.drawable)
            animator.views.forEach { CYLTabBarItemAnimationFailure.reportLoaded(it) }
            idle()
            assertEquals("downloaded: the animation", View.INVISIBLE, withImage.iconView.visibility)
            assertEquals(View.INVISIBLE, withoutImage.iconView.visibility)
        } finally {
            CYLTabBarItemAnimatorRegistry.unregisterAnimatorWithIdentifier("TestDownloading")
        }
    }
}
