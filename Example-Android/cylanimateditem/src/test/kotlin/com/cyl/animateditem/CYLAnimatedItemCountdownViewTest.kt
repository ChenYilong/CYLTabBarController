package com.cyl.animateditem

import android.app.Activity
import android.graphics.drawable.ColorDrawable
import android.view.View
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] The countdown style of `CYLAnimatedItemView` (the "Get code" button of SMSCodeButton) on a clock the tests move: a tap
 *      starts it, the seconds in the background count, a past clock closes it, a new view continues a cached countdown, the
 *      width stays and the icon changes while it runs. The state machine itself is in `CYLAnimatedItemCountdownTest`.
 * [CN] `CYLAnimatedItemView` 的倒计时样式（SMSCodeButton 的「获取验证码」按钮），使用由测试拨动的时钟：点击开始、后台的秒数计入、
 *      时钟过头时关闭、新视图接续缓存的倒计时、宽度不变、倒计时中图标变化。状态机本身在 `CYLAnimatedItemCountdownTest` 中测试。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemCountdownViewTest {
    private class Clock(var millis: Long) {
        fun set(seconds: Long) { millis = seconds * 1000 }
    }

    private class MemoryStorage : CYLAnimatedItemCountdownStorage {
        val values = HashMap<String, String>()
        override fun get(name: String) = values[name]
        override fun set(name: String, value: String) { values[name] = value }
        override fun remove(name: String) { values.remove(name) }
    }

    private class Recorder : CYLAnimatedItemGestureListener {
        val events = ArrayList<String>()
        override fun onItemTapped(item: CYLAnimatedItemView) { events += "tap" }
        override fun onCountdownStarted(item: CYLAnimatedItemView) { events += "start" }
        override fun onCountdownTicked(item: CYLAnimatedItemView, remainingSeconds: Int) { events += "tick $remainingSeconds" }
        override fun onCountdownFinished(item: CYLAnimatedItemView) { events += "finish" }
    }

    private fun makeView(clock: Clock, storage: MemoryStorage, recorder: Recorder = Recorder()): CYLAnimatedItemView {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        return CYLAnimatedItemView(activity).apply {
            countdownClock = { clock.millis }
            countdownStorage = storage
            countdownIdleTitle = "Get code"
            countdownRunningTitleFormat = "%d s left"
            countdownFinishedTitle = "Resend"
            gestureListener = recorder
            style = CYLAnimatedItemStyle.Countdown
        }
    }

    private fun width(view: CYLAnimatedItemView): Int {
        view.measure(View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED), View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
        return view.measuredWidth
    }

    @Test
    fun aTapStartsTheCountdownAndTheSecondsInTheBackgroundCount() {
        val clock = Clock(1_000_000)
        val recorder = Recorder()
        val view = makeView(clock, MemoryStorage(), recorder)
        view.startsCountdownOnTap = true
        assertEquals("Get code", view.title)
        view.performClick()
        assertEquals(CYLAnimatedItemCountdownState.Running, view.countdownState)
        assertEquals("60 s left", view.title)
        assertFalse("a running countdown takes no tap", view.isEnabled)
        assertEquals("60 s left", view.contentDescription)

        clock.set(1_046)
        view.refreshCountdown()
        assertEquals("14 s left", view.title)
        clock.set(1_060)
        view.refreshCountdown()
        assertEquals(CYLAnimatedItemCountdownState.Finished, view.countdownState)
        assertEquals("Resend", view.title)
        assertTrue(view.isEnabled)
        assertEquals(listOf("tap", "start", "tick 60", "tick 14", "finish"), recorder.events)
    }

    @Test
    fun aClockPastTheLongestDurationClosesTheCountdownAndTheViewIsUsableAgain() {
        val clock = Clock(0)
        val view = makeView(clock, MemoryStorage())
        view.startCountdown(60)
        clock.set(100_000)
        view.refreshCountdown()
        assertEquals(CYLAnimatedItemCountdownState.Finished, view.countdownState)
        assertTrue(view.isEnabled)
        view.startCountdown()
        assertEquals(CYLAnimatedItemCountdownState.Running, view.countdownState)
    }

    @Test
    fun aNewViewWithTheSameCacheKeyContinuesTheCountdown() {
        // [EN] `Clock(millis)` takes milliseconds and `set(seconds)` seconds: start at 1000 s, then 42 s later. [CN] `Clock(millis)` 以毫秒计，`set(seconds)` 以秒计：从 1000 秒开始，42 秒后。
        val clock = Clock(1_000_000)
        val storage = MemoryStorage()
        val first = makeView(clock, storage)
        first.countdownCacheKey = "sms-code"
        first.startCountdown(60)
        clock.set(1_042)

        val recorder = Recorder()
        val second = makeView(clock, storage, recorder)
        second.countdownCacheKey = "sms-code"
        assertEquals(CYLAnimatedItemCountdownState.Running, second.countdownState)
        assertEquals("18 s left", second.title)
        assertFalse(second.isEnabled)
        assertEquals("no start is announced", listOf("tick 18"), recorder.events)
    }

    @Test
    fun theWidthStaysAndTheIconChangesWhileItRuns() {
        val clock = Clock(0)
        val view = makeView(clock, MemoryStorage())
        val idle = ColorDrawable(0xFF0000FF.toInt())
        val timer = ColorDrawable(0xFF00FF00.toInt())
        view.image = idle
        view.countdownImage = timer
        view.countdownDuration = 60
        val idleWidth = width(view)
        assertSame(idle, view.iconView.drawable)

        view.startCountdown()
        assertSame(timer, view.iconView.drawable)
        assertEquals(idleWidth, width(view))
        clock.set(51)
        view.refreshCountdown()
        assertEquals("9 s left", view.title)
        assertEquals("two digits or one, the width stays", idleWidth, width(view))

        clock.set(60)
        view.refreshCountdown()
        assertSame(idle, view.iconView.drawable)
    }

    @Test
    fun thePlainStyleIsNotTouched() {
        val view = CYLAnimatedItemView(Robolectric.buildActivity(Activity::class.java).setup().get())
        view.title = "Home"
        view.refreshCountdown()
        assertEquals("Home", view.title)
        assertEquals(CYLAnimatedItemStyle.Plain, view.style)
    }
}
