package com.cyl.tabbar

import android.content.Context
import android.view.View
import android.widget.ImageView
import androidx.fragment.app.Fragment
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] Every tab switch stops all the other animations (the iOS contract, CYLAnimatedItemView): tapping a tab and then "More"
 *      used to leave the first tab playing and looking selected next to "More", because only the selection path stopped the
 *      other tabs and "More" selects through its own function. The tabs use an animator that records what is played and stopped,
 *      since no animation library is on this test classpath.
 * [CN] 每次切换 Tab 都停止其他所有动画（iOS 约定，CYLAnimatedItemView）：先点一个 Tab 再点「更多」时，第一个 Tab 曾继续播放并与「更多」同时呈选中外观，
 *      因为只有选中路径会停止其他 Tab，而「更多」通过自己的方法选中。测试使用会记录播放与停止的 animator，因为本测试 classpath 上没有动画库。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabBarMoreAnimationTest {

    class Page : Fragment()

    /** [EN] What the animator was asked to do, in order: "play 1", "stop 0"…. [CN] animator 被要求做的事，按顺序："play 1"、"stop 0"……。 */
    private val log = ArrayList<String>()

    private inner class RecordingAnimator : CYLTabBarItemAnimator {
        override val identifier = "TestRecording"
        override val fileExtensions = listOf("rec")
        override fun canAnimateFileAtURL(url: String) = CYLTabBarAnimationFileExtension(url) == "rec"

        override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View =
            View(context).also { it.tag = url.substringAfterLast('/').substringBefore('.') }

        override fun playerForAnimationView(view: View): CYLTabBarItemAnimationPlayer = object : CYLTabBarItemAnimationPlayer {
            override val animationView: View? = view
            override fun play() { log += "play ${view.tag}" }
            override fun showLastFrame() { log += "last ${view.tag}" }
            override fun stop() { log += "stop ${view.tag}" }
        }
    }

    private fun controller(activity: androidx.fragment.app.FragmentActivity): CYLTabBarController {
        val titles = listOf("Home", "Message", "Find", "Shop", "Video", "Music", "Me")
        // [EN] Seven tabs: the first four and "More". The animated tabs are the visible ones. [CN] 七个 Tab：前四个与「更多」。有动画的是可见的 Tab。
        val items = titles.mapIndexed { index, title ->
            val item = mutableMapOf<String, Any?>(CYLConstants.CYLTabBarItemTitle to title, CYLConstants.CYLTabBarItemIdentifier to title.lowercase())
            if (index < 4) item[CYLConstants.CYLTabBarAnimationURL] = "https://example.com/$index.rec"
            item
        }
        val controller = CYLTabBarController(activity, titles.map { Page() }, items)
        activity.setContentView(controller.view)
        idle()
        return controller
    }

    @Test
    fun tappingMoreStopsTheAnimationOfTheTabSelectedBefore() = withActivity { activity ->
        val animator = RecordingAnimator()
        CYLTabBarItemAnimatorRegistry.registerAnimator(animator)
        try {
            val controller = controller(activity)
            val buttons = controller.tabBar.tabBarButtonArray
            buttons[1].performClick()
            idle()
            assertTrue("the tapped tab plays", "play 1" in log)

            log.clear()
            controller.tabBar.cyl_moreButton!!.performClick()
            idle()
            assertTrue(controller.cyl_isMoreSelected)
            assertTrue("the tab selected before is stopped, so it goes back to its unselected look: $log", "stop 1" in log)
            assertTrue("no tab is told to play behind \"More\": $log", log.none { it.startsWith("play") })
            val more = controller.tabBar.cyl_moreButton!!
            val selected = buttons.filter { it.isSelected } + listOf(more).filter { it.isSelected }
            assertEquals("exactly one item looks selected, \"More\"", listOf<View>(more), selected)
        } finally {
            CYLTabBarItemAnimatorRegistry.unregisterAnimatorWithIdentifier("TestRecording")
        }
    }

    @Test
    fun aTapOnATabAfterMoreStopsNothingItShouldNotAndPlaysTheTab() = withActivity { activity ->
        val animator = RecordingAnimator()
        CYLTabBarItemAnimatorRegistry.registerAnimator(animator)
        try {
            val controller = controller(activity)
            val buttons = controller.tabBar.tabBarButtonArray
            buttons[1].performClick()
            controller.tabBar.cyl_moreButton!!.performClick()
            idle()
            log.clear()
            buttons[2].performClick()
            idle()
            assertTrue("the new tab plays: $log", "play 2" in log)
            assertTrue("the others are stopped first: $log", log.indexOf("stop 1") in 0 until log.indexOf("play 2"))
        } finally {
            CYLTabBarItemAnimatorRegistry.unregisterAnimatorWithIdentifier("TestRecording")
        }
    }
}
