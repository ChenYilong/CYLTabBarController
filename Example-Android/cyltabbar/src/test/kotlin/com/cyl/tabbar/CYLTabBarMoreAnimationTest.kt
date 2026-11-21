package com.cyl.tabbar

import android.content.Context
import android.view.View
import android.widget.ImageView
import androidx.fragment.app.Fragment
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] docs/CYLTabBarController-Integration.md, "two tab items stay selected after a quick switch in the SVGA tab bar":
 *      a tap on "More" must stop the animation of the tab that was selected before, exactly as every other tab switch
 *      and the plus button's page already do; before the fix `cyl_moreButtonTapped` never called
 *      `cyl_stopAnimationsOfAllTabBarItemsExcept`, so a tab whose animator has no deselect step of its own (SVGA: it only
 *      rewinds on `stop()`) kept playing and looked selected at the same time as "More".
 * [CN] docs/CYLTabBarController-Integration.md「SVGA TabBar 快速切换后两个 Tab 同时处于选中状态」：点击「更多」必须停止此前选中 Tab 的动画，
 *      与其他切换 Tab 的路径、PlusButton 页面完全一致；修复前 `cyl_moreButtonTapped` 从未调用 `cyl_stopAnimationsOfAllTabBarItemsExcept`，
 *      因此没有自己「取消选中」步骤的动画库（SVGA 只在 `stop()` 时回到第一帧）会继续播放，与「更多」同时呈选中外观。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabBarMoreAnimationTest {

    class Page : Fragment()

    private val sevenTitles = arrayOf("Home", "Message", "Find", "Shop", "Video", "Music", "Me")

    /**
     * [EN] A player that only records whether it is playing, like SVGA: no deselect step, `stop()` is the only way back.
     * [CN] 只记录是否在播放的播放器，与 SVGA 一样：没有取消选中步骤，`stop()` 是唯一的回退方式。
     */
    private class RecordingPlayer(view: View) : CYLTabBarItemAnimationBasePlayer(view) {
        var playing = false
        override fun play() { playing = true }
        override fun showLastFrame() { playing = true }
        override fun stop() { playing = false }
    }

    private class RecordingAnimator : CYLTabBarItemAnimator {
        override val identifier = "TestRecording"
        override val fileExtensions = listOf("rec")
        val players = HashMap<View, RecordingPlayer>()
        override fun canAnimateFileAtURL(url: String) = CYLTabBarAnimationFileExtension(url) == "rec"
        override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View =
            View(context).also { players[it] = RecordingPlayer(it) }
        override fun playerForAnimationView(view: View): CYLTabBarItemAnimationPlayer? = players[view]
    }

    @Test
    fun moreStopsTheAnimationOfTheTabSelectedBefore() = withActivity { activity ->
        val animator = RecordingAnimator()
        CYLTabBarItemAnimatorRegistry.registerAnimator(animator)
        try {
            val items = sevenTitles.map {
                mapOf(CYLConstants.CYLTabBarItemTitle to it, CYLConstants.CYLTabBarItemIdentifier to it.lowercase(),
                    CYLConstants.CYLTabBarAnimationURL to "file:///android_asset/$it.rec")
            }
            val controller = CYLTabBarController(activity, items.map { Page() }, items)
            activity.setContentView(controller.view)
            idle()
            val home = controller.tabBar.tabBarButtonArray[0]
            val homePlayer = animator.players[home.cyl_tabBarItemAnimationView]
            assertTrue("Home is selected at launch: its animation looks selected", homePlayer?.playing == true)
            controller.tabBar.cyl_moreButton!!.performClick()
            idle()
            assertTrue("More is now selected", controller.cyl_isMoreSelected)
            assertFalse("More has no animation of its own, but Home must stop, as every other tab switch does",
                homePlayer?.playing == true)
        } finally {
            CYLTabBarItemAnimatorRegistry.unregisterAnimatorWithIdentifier("TestRecording")
        }
    }
}
