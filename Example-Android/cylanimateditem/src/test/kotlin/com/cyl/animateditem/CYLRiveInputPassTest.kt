package com.cyl.animateditem

import android.content.Context
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import java.util.concurrent.TimeUnit

/**
 * [EN] The end of a Rive state machine input pass (iOS `CYLRiveInputPass`): icons.riv plays but rive-android's `isPlaying`
 *      stays true (its machines never settle), so the pass of an input with an `activeDuration` ends when the duration
 *      has elapsed, which lets `CYLAnimatedItemView` show the still image. A held input (duration 0) has no end.
 * [CN] Rive 状态机输入一遍播放的结束（iOS `CYLRiveInputPass`）：icons.riv 会播放，但 rive-android 的 `isPlaying` 一直为 true（其状态机
 *      从不稳定），所以带 `activeDuration` 的输入在该时长经过后这一遍结束，`CYLAnimatedItemView` 才能显示静态图片。保持的输入（时长 0）没有结束。
 */
@RunWith(RobolectricTestRunner::class)
class CYLRiveInputPassTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private fun idle(ms: Long) = shadowOf(Looper.getMainLooper()).idleFor(ms, TimeUnit.MILLISECONDS)

    /** [EN] A view whose `isPlaying` is always true, as icons.riv's. [CN] `isPlaying` 始终为 true 的视图，如 icons.riv。 */
    private fun riveView() = CYLRiveLoopTest.FakeRive(context, listOf(CYLRiveLoopTest.Machine("TIMER_Interactivity", listOf("active")))).apply { playing = true }

    private fun view(rive: CYLRiveLoopTest.FakeRive, duration: String) =
        CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "TIMER_Interactivity", "input" to "active", "duration" to duration))

    @Test
    fun ruleMatchesIOS() {
        assertTrue(CYLRiveInputPass.hasEnd(1.0))
        assertTrue(CYLRiveInputPass.hasEnd(0.5))
        assertFalse(CYLRiveInputPass.hasEnd(0.0))
    }

    @Test
    fun aPassWithADurationEndsAfterIt() {
        val rive = riveView()
        val view = view(rive, "2")
        view.cyl_playAnimationView()
        assertEquals(true, view.cyl_isAnimationViewPlaying())
        idle(1500)
        assertEquals("still inside the 2 s duration", true, view.cyl_isAnimationViewPlaying())
        idle(1000)
        assertEquals("the input went back to false: ended although rive-android still says playing", false, view.cyl_isAnimationViewPlaying())
        assertEquals(listOf("active=false", "active=true", "active=false"), rive.calls)
    }

    @Test
    fun aHeldInputHasNoEnd() {
        val rive = riveView()
        val view = view(rive, "0")
        view.cyl_playAnimationView()
        idle(5000)
        assertEquals("rive-android's answer", true, view.cyl_isAnimationViewPlaying())
    }

    @Test
    fun playingAgainOrStoppingCancelsTheEnd() {
        val rive = riveView()
        val view = view(rive, "1")
        view.cyl_playAnimationView(); idle(800)
        view.cyl_playAnimationView()
        idle(600)
        assertEquals("a new pass started 600 ms ago, the old timer did not end it", true, view.cyl_isAnimationViewPlaying())
        idle(1000)
        assertEquals(false, view.cyl_isAnimationViewPlaying())
        view.cyl_playAnimationView()
        view.cyl_stopAnimationView()
        assertEquals(false, view.cyl_isAnimationViewPlaying())
    }

    @Test
    fun otherKindsKeepRiveAndroidsAnswer() {
        val rive = riveView()
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "TIMER_Interactivity", "triggerInput" to "none"))
        view.cyl_playAnimationView()
        assertEquals(true, view.cyl_isAnimationViewPlaying())
        rive.playing = false
        assertEquals(false, view.cyl_isAnimationViewPlaying())
    }
}
