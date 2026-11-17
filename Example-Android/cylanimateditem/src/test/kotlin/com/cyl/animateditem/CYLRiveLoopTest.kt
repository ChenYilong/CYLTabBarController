package com.cyl.animateditem

import android.content.Context
import android.os.Looper
import android.view.View
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import java.util.concurrent.TimeUnit

/**
 * [EN] The Rive loop (docs/Animated-Item.md, "the Rive engine has no loop logic"): every play plays again (a held input, a
 *      state machine without the input, a trigger), and looping repeats each kind until it is turned off. A fake
 *      RiveAnimationView records the calls the view makes by reflection.
 * [CN] Rive 循环（docs/Animated-Item.md，"Rive 引擎没有循环逻辑"）：每次播放都会再次播放（保持的输入、没有该输入的状态机、trigger），循环会重复每种
 *      方式直到关闭。伪造的 RiveAnimationView 记录视图通过反射发出的调用。
 */
@RunWith(RobolectricTestRunner::class)
class CYLRiveLoopTest {
    class Machine(private val name: String, private val inputs: List<String>) {
        fun getName() = name
        fun getInputNames() = inputs
    }

    /** [EN] Records reset / play / setBooleanState / fireState. [CN] 记录 reset / play / setBooleanState / fireState。 */
    class FakeRive(context: Context, private val machines: List<Machine>) : View(context) {
        val calls = mutableListOf<String>()
        fun getStateMachines() = machines
        fun reset() { calls += "reset" }
        // [EN] Default arguments, as rive-android's: the view calls them through Kotlin's `play$default`. [CN] 与 rive-android 一样使用默认参数：视图通过 Kotlin 的 `play$default` 调用。
        fun play(loop: Any? = null, direction: Any? = null, settleInitialState: Boolean = true) { calls += "play" }
        fun play(animationName: String, loop: Any? = null, direction: Any? = null, isStateMachine: Boolean = false, settleInitialState: Boolean = true) { calls += "play:$animationName" }
        fun setBooleanState(machine: String, input: String, value: Boolean) { calls += "$input=$value" }
        fun fireState(machine: String, input: String) { calls += "fire:$input" }
    }

    private val context: Context = ApplicationProvider.getApplicationContext()
    private fun idle(ms: Long) = shadowOf(Looper.getMainLooper()).idleFor(ms, TimeUnit.MILLISECONDS)

    @Test
    fun aHeldInputPlaysAgain() {
        val rive = FakeRive(context, listOf(Machine("State Machine", listOf("isOpen"))))
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine", "input" to "isOpen", "duration" to "0"))
        view.cyl_playAnimationView(); idle(60)
        view.cyl_playAnimationView(); idle(60)
        assertEquals(listOf("isOpen=false", "isOpen=true", "isOpen=false", "isOpen=true"), rive.calls)
    }

    @Test
    fun aStateMachineWithoutTheInputRestarts() {
        val rive = FakeRive(context, listOf(Machine("State Machine 1", emptyList())))
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine 1"))
        view.cyl_playAnimationView()
        assertEquals(listOf("reset", "play"), rive.calls)
    }

    @Test
    fun aTriggerRestartsThenFires() {
        val rive = FakeRive(context, listOf(Machine("State Machine 1", listOf("Check"))))
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine 1", "triggerInput" to "Check"))
        view.cyl_playAnimationView()
        assertEquals(listOf("reset", "play"), rive.calls)
        idle(60)
        assertEquals(listOf("reset", "play", "fire:Check"), rive.calls)
    }

    @Test
    fun loopRepeatsUntilTurnedOff() {
        val rive = FakeRive(context, listOf(Machine("State Machine 1", listOf("Check"))))
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine 1", "triggerInput" to "Check"))
        view.cyl_setAnimationViewLoops(true)
        view.cyl_playAnimationView()
        idle((CYLRiveTabBarItemAnimationView.LOOP_SECONDS * 1000).toLong() + 60)
        idle((CYLRiveTabBarItemAnimationView.LOOP_SECONDS * 1000).toLong() + 60)
        assertEquals(3, rive.calls.count { it == "fire:Check" })
        view.cyl_setAnimationViewLoops(false)
        idle(5000)
        assertEquals(3, rive.calls.count { it == "fire:Check" })
    }
}
