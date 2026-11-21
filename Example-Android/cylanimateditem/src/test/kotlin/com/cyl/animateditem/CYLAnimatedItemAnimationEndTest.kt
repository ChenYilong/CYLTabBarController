package com.cyl.animateditem

import android.app.Activity
import android.content.Context
import android.graphics.drawable.ColorDrawable
import android.view.View
import android.widget.ImageView
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper
import java.util.concurrent.TimeUnit

/**
 * [EN] `showsImageWhenAnimationEnds` and `animationEndListener`: a play-once animation is replaced by the still image when
 *      its player stops playing (or its progress reaches 1), and the next play shows the animation again.
 * [CN] `showsImageWhenAnimationEnds` 与 `animationEndListener`：只播放一次的动画在播放器停止播放（或进度到达 1）时换成静态图片，下一次播放重新显示动画。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemAnimationEndTest {

    /**
     * [EN] A player whose `isPlaying` the test sets; `tellsPlaying` false makes it answer null (progress only).
     * [CN] 由测试设置 `isPlaying` 的播放器；`tellsPlaying` 为 false 时返回 null（只有进度）。
     */
    class EndPlayer(override val animationView: View, private val tellsPlaying: Boolean) : CYLTabBarItemAnimationPlayer {
        var running = false
        var plays = 0
        override var progress = 0f
        override var loops = false
        override val isPlaying: Boolean? get() = if (tellsPlaying) running else null
        override fun play() { plays++; running = true; progress = 0f }
        override fun showLastFrame() { running = false; progress = 1f }
        override fun stop() { running = false; progress = 0f }
    }

    class EndSource(private val tellsPlaying: Boolean = true) : CYLTabBarItemAnimationViewMaking {
        val players = HashMap<View, EndPlayer>()
        override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View =
            View(context).also { players[it] = EndPlayer(it, tellsPlaying) }
        override fun playerForView(view: View?): CYLTabBarItemAnimationPlayer? = players[view]
        override fun isAnimationView(view: View?) = players.containsKey(view)
    }

    private fun item(source: EndSource): CYLAnimatedItemView {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        return CYLAnimatedItemView(activity).apply {
            animationSource = source
            image = ColorDrawable(0xFF00FF00.toInt()).apply { setBounds(0, 0, 24, 24) }
            animationURL = "success.fake"
            activity.setContentView(this)
        }
    }

    private fun frames(ms: Long = 100) = ShadowLooper.idleMainLooper(ms, TimeUnit.MILLISECONDS)

    @Test
    fun theStillImageReplacesAnEndedPlayOnceAnimationAndTheNextPlayShowsItAgain() {
        val source = EndSource()
        val view = item(source)
        view.showsImageWhenAnimationEnds = true
        var ended = 0
        view.animationEndListener = CYLAnimatedItemAnimationEndListener { assertSame(view, it); ended++ }
        val player = source.players.getValue(view.animationView!!)

        view.playAnimation()
        frames()
        assertFalse(view.isShowingImageAfterAnimationEnd)
        assertEquals(View.INVISIBLE, view.iconView.visibility)

        player.running = false
        frames()
        assertTrue(view.isShowingImageAfterAnimationEnd)
        assertEquals(1, ended)
        assertEquals(View.VISIBLE, view.iconView.visibility)
        assertSame(view.image, view.iconView.drawable)
        assertEquals(View.INVISIBLE, view.animationView!!.visibility)

        view.playAnimation()
        assertFalse(view.isShowingImageAfterAnimationEnd)
        assertEquals(View.VISIBLE, view.animationView!!.visibility)
        assertEquals(View.INVISIBLE, view.iconView.visibility)
        frames()
        player.running = false
        frames()
        assertEquals(2, ended)
        assertTrue(view.isShowingImageAfterAnimationEnd)
    }

    @Test
    fun offByDefaultTheLastFrameStaysButTheListenerIsStillTold() {
        val source = EndSource()
        val view = item(source)
        var ended = 0
        view.animationEndListener = CYLAnimatedItemAnimationEndListener { ended++ }
        view.playAnimation()
        frames()
        source.players.getValue(view.animationView!!).running = false
        frames()
        assertEquals(1, ended)
        assertFalse(view.isShowingImageAfterAnimationEnd)
        assertEquals(View.INVISIBLE, view.iconView.visibility)
        assertEquals(View.VISIBLE, view.animationView!!.visibility)
    }

    @Test
    fun aLoopingOrStoppedAnimationNeverEnds() {
        val source = EndSource()
        val view = item(source)
        view.showsImageWhenAnimationEnds = true
        var ended = 0
        view.animationEndListener = CYLAnimatedItemAnimationEndListener { ended++ }
        val player = source.players.getValue(view.animationView!!)

        view.animationLoops = true
        view.playAnimation()
        frames()
        player.running = false
        frames()
        assertEquals(0, ended)

        view.animationLoops = false
        view.playAnimation()
        frames()
        view.stopAnimation()
        frames()
        assertEquals(0, ended)
        assertFalse(view.isShowingImageAfterAnimationEnd)
    }

    @Test
    fun anEngineThatStartsLateIsNotEndedBeforeItPlays() {
        val source = EndSource()
        val view = item(source)
        view.showsImageWhenAnimationEnds = true
        val player = source.players.getValue(view.animationView!!)
        view.playAnimation()
        player.running = false
        frames()
        assertFalse(view.isShowingImageAfterAnimationEnd)
        player.running = true
        frames()
        player.running = false
        frames()
        assertTrue(view.isShowingImageAfterAnimationEnd)
    }

    @Test
    fun aPlayerWithoutIsPlayingEndsWhenItsProgressReachesOne() {
        val source = EndSource(tellsPlaying = false)
        val view = item(source)
        view.showsImageWhenAnimationEnds = true
        val player = source.players.getValue(view.animationView!!)
        view.playAnimation()
        player.progress = 0.4f
        frames()
        assertFalse(view.isShowingImageAfterAnimationEnd)
        player.progress = 1f
        frames()
        assertTrue(view.isShowingImageAfterAnimationEnd)
    }

    @Test
    fun turningTheSwitchOffShowsTheAnimationAgain() {
        val source = EndSource()
        val view = item(source)
        view.showsImageWhenAnimationEnds = true
        view.playAnimation()
        frames()
        source.players.getValue(view.animationView!!).running = false
        frames()
        assertTrue(view.isShowingImageAfterAnimationEnd)
        view.showsImageWhenAnimationEnds = false
        assertFalse(view.isShowingImageAfterAnimationEnd)
        assertEquals(View.VISIBLE, view.animationView!!.visibility)
    }

    @Test
    fun theGIFViewTellsWhetherItPlays() {
        val gif = CYLGIFTabBarItemAnimationView::class.java.declaredConstructors.first().let { constructor ->
            constructor.isAccessible = true
            constructor.newInstance(Robolectric.buildActivity(Activity::class.java).setup().get(), ImageView.ScaleType.FIT_CENTER) as CYLGIFTabBarItemAnimationView
        }
        assertEquals(false, gif.cyl_isAnimationViewPlaying())
    }
}
