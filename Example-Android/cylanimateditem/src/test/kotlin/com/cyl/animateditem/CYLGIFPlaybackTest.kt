package com.cyl.animateditem

import android.animation.ValueAnimator
import android.os.Looper
import android.widget.ImageView
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import java.time.Duration

/**
 * [EN] The GIF view obeys the player's loops, speed and progress (CYLAnimatedItemView `animationLoops`, `animationSpeed`,
 *      `restartAnimation()`), as the Lottie, PAG and Rive players do. Without a decoded movie (JVM) a GIF lasts 1 s.
 *      Robolectric does not time ValueAnimators like a phone, so the tests check how the animator is set up; the timing
 *      is checked on the emulator.
 * [CN] GIF 视图遵循播放器的 loops、speed 与 progress（CYLAnimatedItemView 的 `animationLoops`、`animationSpeed`、`restartAnimation()`），
 *      与 Lottie、PAG、Rive 播放器一致。没有解码的 movie（JVM）时 GIF 时长为 1 秒。Robolectric 不像手机那样计时 ValueAnimator，
 *      因此测试检查 animator 的配置；计时在模拟器上检查。
 */
@RunWith(RobolectricTestRunner::class)
class CYLGIFPlaybackTest {
    private fun view() = CYLGIFTabBarItemAnimationView(ApplicationProvider.getApplicationContext(), ImageView.ScaleType.FIT_CENTER)
    private fun player(view: CYLGIFTabBarItemAnimationView) = CYLGIFTabBarItemAnimator.animator.playerForAnimationView(view)!!
    private fun advance(ms: Long) = shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(ms))

    @Test
    fun withoutLoopsItPlaysOnceAndStaysOnTheLastFrame() {
        val view = view()
        player(view).play()
        assertEquals(0, view.currentAnimator!!.repeatCount)
        advance(1500)
        assertFalse(view.isPlaying)
        assertEquals(view.duration - 1, view.shownTime)
    }

    @Test
    fun loopsRepeatAndTurningThemOffEndsThePassPlaying() {
        val view = view()
        val player = player(view)
        player.loops = true
        player.play()
        // [EN] INFINITE on a phone; Robolectric's ValueAnimator shadow reports it as 1, so only "repeats" is checked.
        // [CN] 手机上为 INFINITE；Robolectric 的 ValueAnimator shadow 报告为 1，因此只检查“会重复”。
        assertNotEquals("repeats", 0, view.currentAnimator!!.repeatCount)
        player.loops = false
        assertEquals("the pass playing goes on, once", 0, view.currentAnimator!!.repeatCount)
    }

    @Test
    fun speedScalesTheTime() {
        val view = view()
        val player = player(view)
        player.animationSpeed = 2f
        player.play()
        assertEquals(((view.duration - 1) / 2f).toLong(), view.currentAnimator!!.duration)
        player.animationSpeed = 0.5f
        assertEquals("applied to the pass playing", ((view.duration - 1) / 0.5f).toLong(), view.currentAnimator!!.duration)
        player.animationSpeed = 0f
        assertEquals("0 or less: the GIF's own speed", (view.duration - 1).toLong(), view.currentAnimator!!.duration)
    }

    @Test
    fun restartStartsFromFrameZero() {
        val view = view()
        val player = player(view)
        player.play()
        advance(1500)
        assertEquals(view.duration - 1, view.shownTime)
        // [EN] CYLAnimatedItemView.restartAnimation(): progress 0, then play. [CN] 先 progress 0，再播放。
        player.progress = 0f
        assertEquals(0, view.shownTime)
        player.play()
        assertEquals(0, view.shownTime)
    }

    @Test
    fun loopsDoNotSpinWhenAnimationsAreOff() {
        // [EN] Developer options "Animator duration scale: off": every pass ends at once. [CN] 开发者选项关闭动画时长：每次播放立即结束。
        val setScale = ValueAnimator::class.java.getDeclaredMethod("setDurationScale", Float::class.javaPrimitiveType)
        setScale.invoke(null, 0f)
        try {
            val view = view()
            val player = player(view)
            player.loops = true
            player.play()
            advance(100)
            assertFalse("ends instead of repeating forever", view.isPlaying)
        } finally {
            setScale.invoke(null, 1f)
        }
    }
}
