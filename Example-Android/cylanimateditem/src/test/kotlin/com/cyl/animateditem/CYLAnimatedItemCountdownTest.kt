package com.cyl.animateditem

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * [EN] The countdown state machine of `CYLAnimatedItemView` on a clock the tests move: the same cases as iOS
 *      `CYLAnimatedItemCountdownTests` and the mini program's `cyl_animated_item_countdown.test.js`.
 * [CN] `CYLAnimatedItemView` 的倒计时状态机，使用由测试拨动的时钟：用例与 iOS 的 `CYLAnimatedItemCountdownTests` 以及小程序的
 *      `cyl_animated_item_countdown.test.js` 相同。
 */
class CYLAnimatedItemCountdownTest {
    private class Clock(var millis: Long) {
        fun set(seconds: Double) { millis = (seconds * 1000).toLong() }
    }

    private class MemoryStorage : CYLAnimatedItemCountdownStorage {
        val values = HashMap<String, String>()
        override fun get(name: String) = values[name]
        override fun set(name: String, value: String) { values[name] = value }
        override fun remove(name: String) { values.remove(name) }
    }

    private class Recorder : CYLAnimatedItemCountdownListener {
        val events = ArrayList<String>()
        override fun onCountdownStarted() { events += "start" }
        override fun onCountdownTicked(remainingSeconds: Int) { events += "tick $remainingSeconds" }
        override fun onCountdownFinished() { events += "finish" }
    }

    private fun make(clock: Clock, storage: MemoryStorage? = null, key: String? = null, recorder: Recorder = Recorder()): Pair<CYLAnimatedItemCountdown, Recorder> {
        val countdown = CYLAnimatedItemCountdown({ clock.millis }, storage, recorder)
        if (key != null) countdown.setCacheKey(key)
        return countdown to recorder
    }

    @Test
    fun textReplacesTheNumber() {
        assertEquals("14 s left", CYLAnimatedItemCountdown.text("%d s left", 14))
        assertEquals("14 s left", CYLAnimatedItemCountdown.text("%ld s left", 14))
    }

    @Test
    fun theSecondsSpentInTheBackgroundCount() {
        val clock = Clock(1_000_000)
        val (countdown, recorder) = make(clock)
        countdown.start(10)
        assertEquals(CYLAnimatedItemCountdownState.Running, countdown.state)
        assertEquals(10, countdown.remainingSeconds)
        clock.set(1004.0)
        countdown.refresh()
        assertEquals(6, countdown.shownSeconds)
        clock.set(1020.0)
        countdown.refresh()
        assertEquals(CYLAnimatedItemCountdownState.Finished, countdown.state)
        assertEquals(listOf("start", "tick 10", "tick 6", "finish"), recorder.events)
    }

    @Test
    fun ticksOncePerSecondAndFinishesExactly() {
        val clock = Clock(500_000)
        val (countdown, recorder) = make(clock)
        countdown.start(3)
        clock.set(500.4); countdown.refresh()
        clock.set(500.9); countdown.refresh()
        assertEquals(3, countdown.shownSeconds)
        clock.set(501.1); countdown.refresh()
        assertEquals(2, countdown.shownSeconds)
        clock.set(503.0); countdown.refresh()
        assertEquals(CYLAnimatedItemCountdownState.Finished, countdown.state)
        countdown.refresh()
        assertEquals(listOf("start", "tick 3", "tick 2", "finish"), recorder.events)
    }

    @Test
    fun aClockSetBackToBeforeTheStartClosesTheCountdown() {
        val clock = Clock(10_000_000)
        val (countdown, _) = make(clock)
        countdown.start(60)
        clock.set(5000.0)
        countdown.refresh()
        assertEquals(CYLAnimatedItemCountdownState.Finished, countdown.state)
        countdown.start(60)
        assertEquals(CYLAnimatedItemCountdownState.Running, countdown.state)
    }

    @Test
    fun aClockPastTheLongestDurationClosesTheCountdown() {
        val clock = Clock(0)
        val (countdown, _) = make(clock)
        countdown.start(60)
        clock.set(100_000.0)
        countdown.refresh()
        assertEquals(CYLAnimatedItemCountdownState.Finished, countdown.state)
        assertEquals(0, countdown.remainingSeconds)
    }

    @Test
    fun aResetIsNotAFinish() {
        val clock = Clock(0)
        val (countdown, recorder) = make(clock)
        countdown.start(30)
        countdown.reset()
        assertEquals(CYLAnimatedItemCountdownState.Idle, countdown.state)
        assertFalse(recorder.events.contains("finish"))
    }

    @Test
    fun aCachedCountdownIsTakenUpAgainWithNoStartCallback() {
        val clock = Clock(1_000_000)
        val storage = MemoryStorage()
        make(clock, storage, "sms-code").first.start(60)
        clock.set(1042.0)
        val (countdown, recorder) = make(clock, storage, "sms-code")
        assertEquals(CYLAnimatedItemCountdownState.Running, countdown.state)
        assertEquals(18, countdown.shownSeconds)
        assertEquals(listOf("tick 18"), recorder.events)
    }

    @Test
    fun anExpiredFinishedResetOrFutureCacheIsNotTakenUp() {
        val storage = MemoryStorage()
        val clock = Clock(1_000_000)
        make(clock, storage, "k").first.start(60)
        clock.set(2000.0)
        assertEquals(CYLAnimatedItemCountdownState.Idle, make(clock, storage, "k").first.state)
        assertTrue("the expired cache is dropped", storage.values.isEmpty())

        clock.set(3000.0)
        val second = make(clock, storage, "k").first
        second.start(60)
        second.reset()
        assertEquals(CYLAnimatedItemCountdownState.Idle, make(clock, storage, "k").first.state)

        val third = make(clock, storage, "k").first
        third.start(60)
        clock.set(3061.0)
        third.refresh()
        assertEquals(CYLAnimatedItemCountdownState.Idle, make(clock, storage, "k").first.state)

        clock.set(10_000.0)
        make(clock, storage, "k").first.start(60)
        clock.set(2000.0)
        assertEquals("the clock was set back", CYLAnimatedItemCountdownState.Idle, make(clock, storage, "k").first.state)
    }
}
