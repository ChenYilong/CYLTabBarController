package com.cyl.animateditem

import android.animation.ValueAnimator
import android.os.Looper
import android.util.Base64
import android.widget.ImageView
import android.app.Activity
import android.widget.FrameLayout
import org.robolectric.Robolectric
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import java.time.Duration

/**
 * [EN] The GIF view obeys the player's loops, speed and progress (CYLAnimatedItemView `animationLoops`, `animationSpeed`,
 *      `restartAnimation()`), as the Lottie, PAG and Rive players do. The GIF: three frames of 100, 200 and 300 ms (600 ms).
 *      The view plays on the frame clock, so the main looper's clock drives it here.
 * [CN] GIF 视图遵循播放器的 loops、speed 与 progress（CYLAnimatedItemView 的 `animationLoops`、`animationSpeed`、`restartAnimation()`），
 *      与 Lottie、PAG、Rive 播放器一致。GIF：三帧，分别 100、200、300 毫秒（共 600 毫秒）。视图基于帧时钟播放，因此这里由主 looper 的时钟驱动。
 */
@RunWith(RobolectricTestRunner::class)
class CYLGIFPlaybackTest {
    /** [EN] In a window, as in an app: the frame clock runs for attached views. [CN] 位于窗口中，与应用相同：帧时钟为已附加的视图运行。 */
    private fun view(): CYLGIFTabBarItemAnimationView {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val view = CYLGIFTabBarItemAnimationView(activity, ImageView.ScaleType.FIT_CENTER)
        activity.setContentView(FrameLayout(activity).apply { addView(view, FrameLayout.LayoutParams(40, 40)) })
        shadowOf(Looper.getMainLooper()).idle()
        view.setData(Base64.decode(CYLGIFDecoderTestData.THREE_FRAMES, Base64.DEFAULT))
        return view
    }
    private fun player(view: CYLGIFTabBarItemAnimationView) = CYLGIFTabBarItemAnimator.animator.playerForAnimationView(view)!!
    private fun advance(ms: Long) = shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(ms))

    @Test
    fun withoutLoopsItPlaysOnceAndStaysOnTheLastFrame() {
        val view = view()
        player(view).play()
        advance(150)
        assertTrue(view.isPlaying)
        assertEquals("the second frame at 150 ms", 1, view.shownFrame)
        advance(600)
        assertFalse(view.isPlaying)
        assertEquals(2, view.shownFrame)
        assertEquals(view.duration - 1, view.shownTime)
    }

    @Test
    fun pauseFreezesTheFrameAndResumeContinuesFromIt() {
        val view = view()
        val player = player(view)
        player.play()
        advance(150)
        assertEquals(1, view.shownFrame)
        player.pause()
        assertFalse("a paused pass does not play", view.isPlaying)
        advance(1000)
        assertEquals("the frame stays while paused", 1, view.shownFrame)
        player.resume()
        assertTrue(view.isPlaying)
        advance(100)
        assertEquals("continues from the second frame (time ~250 ms)", 1, view.shownFrame)
        advance(700)
        assertFalse(view.isPlaying)
        assertEquals(2, view.shownFrame)
    }

    @Test
    fun resumeWithoutPauseDoesNothing() {
        val view = view()
        val player = player(view)
        player.resume()
        assertFalse(view.isPlaying)
    }

    @Test
    fun withLoopsItPlaysAgainUntilTurnedOff() {
        val view = view()
        val player = player(view)
        player.loops = true
        player.play()
        advance(1350)
        assertTrue("still playing after two passes", view.isPlaying)
        assertEquals("150 ms into the third pass", 1, view.shownFrame)
        player.loops = false
        advance(700)
        assertFalse("ends after the pass playing when loops is turned off", view.isPlaying)
        assertEquals(2, view.shownFrame)
    }

    @Test
    fun speedScalesTheTime() {
        val view = view()
        val player = player(view)
        player.animationSpeed = 3f
        player.play()
        advance(250)
        assertFalse("3x: a 600 ms GIF ends within 250 ms", view.isPlaying)
        player.animationSpeed = 0.5f
        player.play()
        advance(1000)
        assertTrue("half as fast: still playing after 1 s", view.isPlaying)
    }

    @Test
    fun restartStartsFromFrameZero() {
        val view = view()
        val player = player(view)
        player.play()
        advance(800)
        assertEquals(2, view.shownFrame)
        // [EN] CYLAnimatedItemView.restartAnimation(): progress 0, then play. [CN] 先 progress 0，再播放。
        player.progress = 0f
        assertEquals(0, view.shownFrame)
        player.play()
        advance(50)
        assertTrue(view.isPlaying)
        assertEquals(0, view.shownFrame)
    }

    @Test
    fun itPlaysWhenTheAnimatorDurationScaleIsZero() {
        // [EN] An emulator gave apps a scale of 0 with the setting unset, and a ValueAnimator then ended at once (B24); Lottie
        //      kept playing, and so does the GIF now. [CN] 模拟器在设置未设置时给应用的缩放为 0，ValueAnimator 因此立即结束（B24）；Lottie 仍在播放，GIF 现在也是。
        val setScale = ValueAnimator::class.java.getDeclaredMethod("setDurationScale", Float::class.javaPrimitiveType)
        setScale.invoke(null, 0f)
        try {
            val view = view()
            player(view).play()
            advance(150)
            assertTrue(view.isPlaying)
            assertEquals(1, view.shownFrame)
        } finally {
            setScale.invoke(null, 1f)
        }
    }
}
