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
    class Number(var number: Float) { fun getValue() = number }
    class Machine(private val name: String, private val inputs: List<String>, private val numbers: Map<String, Number> = emptyMap()) {
        fun getName() = name
        fun getInputNames() = inputs
        fun input(name: String): Any? = numbers[name]
    }

    /** [EN] Records reset / play / setBooleanState / fireState. [CN] 记录 reset / play / setBooleanState / fireState。 */
    open class FakeRive(context: Context, private val machines: List<Machine>) : View(context) {
        val calls = mutableListOf<String>()
        fun getStateMachines() = machines
        fun reset() { calls += "reset" }
        fun pause() { calls += "pause" }
        // [EN] Default arguments, as rive-android's: the view calls them through Kotlin's `play$default`. [CN] 与 rive-android 一样使用默认参数：视图通过 Kotlin 的 `play$default` 调用。
        fun play(loop: Any? = null, direction: Any? = null, settleInitialState: Boolean = true) { calls += "play" }
        fun play(animationName: String, loop: Any? = null, direction: Any? = null, isStateMachine: Boolean = false, settleInitialState: Boolean = true) { calls += "play:$animationName" }
        fun setBooleanState(machine: String, input: String, value: Boolean) { calls += "$input=$value" }
        fun fireState(machine: String, input: String) { calls += "fire:$input" }
        var playing = false
        fun isPlaying() = playing
        fun setNumberState(machine: String, input: String, value: Float) {
            calls += "$input=${value.toInt()}"
            machines.forEach { (it.input(input) as? Number)?.number = value }
        }
    }

    /**
     * [EN] rive-android's `RiveFileController`: `advance` moves the playing state machine, which pauses itself after
     *      `settlesAfter` steps (never when null, a file that moves by itself).
     * [CN] rive-android 的 `RiveFileController`：`advance` 推进正在播放的状态机，状态机在 `settlesAfter` 步后自行暂停（为 null 时从不暂停，即自行运动的文件）。
     */
    class FakeController(private val settlesAfter: Int?) {
        val calls = mutableListOf<String>()
        private val playing = mutableSetOf<Any>("machine")
        var steps = 0
        fun getPlayingStateMachines(): Set<Any> = playing
        fun advance(elapsed: Float) {
            steps++
            if (settlesAfter != null && steps >= settlesAfter) playing.clear()
        }
        fun pause() { calls += "pause"; playing.clear() }
    }

    class FakeRiveWithController(context: Context, machines: List<Machine>, private val fileController: FakeController) : FakeRive(context, machines) {
        fun getController() = fileController
    }

    private val context: Context = ApplicationProvider.getApplicationContext()
    private fun idle(ms: Long) = shadowOf(Looper.getMainLooper()).idleFor(ms, TimeUnit.MILLISECONDS)

    @Test
    fun aHeldInputPlaysAgain() {
        val rive = FakeRive(context, listOf(Machine("State Machine", listOf("isOpen"))))
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine", "input" to "isOpen", "duration" to "0"))
        view.cyl_playAnimationView(); idle(CYLRiveTabBarItemAnimationView.INPUT_OFF_MS + 10)
        view.cyl_playAnimationView(); idle(CYLRiveTabBarItemAnimationView.INPUT_OFF_MS + 10)
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

    @Test
    fun houseStepsItsRoomsNumberInput() {
        val rooms = Number(3f)
        val rive = FakeRive(context, listOf(Machine("State Machine 1", listOf("Rooms"), mapOf("Rooms" to rooms))))
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine 1", "numberInput" to "Rooms", "values" to "3,4,5,6"))
        repeat(4) { view.cyl_playAnimationView() }
        assertEquals(listOf("Rooms=4", "Rooms=5", "Rooms=6", "Rooms=3"), rive.calls)
    }

    @Test
    fun numberValuesAndNext() {
        assertEquals(listOf(3f, 4f, 5f), CYLRiveInputs.numberValues("3, 4,x,5"))
        assertEquals(4f, CYLRiveInputs.nextNumber(emptyList(), 3f))
        assertEquals(3f, CYLRiveInputs.nextNumber(listOf(3f, 4f), null))
        assertEquals(3f, CYLRiveInputs.nextNumber(listOf(3f, 4f), 4f))
    }

    @Test
    fun aLoopPassDoesNotRestartAFileStillMoving() {
        val rive = FakeRive(context, listOf(Machine("State Machine 1", emptyList())))
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine 1"))
        view.cyl_setAnimationViewLoops(true)
        view.cyl_playAnimationView()
        rive.playing = true
        idle((CYLRiveTabBarItemAnimationView.LOOP_SECONDS * 1000).toLong() * 2 + 60)
        assertEquals(1, rive.calls.count { it == "reset" })
        rive.playing = false
        idle((CYLRiveTabBarItemAnimationView.LOOP_SECONDS * 1000).toLong() + 60)
        assertEquals(2, rive.calls.count { it == "reset" })
    }

    @Test
    fun aLoadedFileRestsUntilItIsPlayed() {
        val rive = FakeRive(context, listOf(Machine("State Machine 1", emptyList())))
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine 1"))
        view.cyl_restUntilPlayed()
        assertEquals("without a controller (this fake view): paused at once, without waiting for a frame", listOf("pause"), rive.calls)
        view.cyl_playAnimationView()
        assertEquals("a play resumes only its state machine, then restarts it", listOf("pause", "play:State Machine 1", "reset", "play"), rive.calls)
    }

    @Test
    fun aStateMachineSettlesInFixedStepsBeforeItRests() {
        val controller = FakeController(settlesAfter = 30)
        val rive = FakeRiveWithController(context, listOf(Machine("State Machine", listOf("isOpen"))), controller)
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine", "input" to "isOpen", "duration" to "0"))
        view.cyl_restUntilPlayed()
        assertEquals("menu_button.riv: advanced until it settled, the same on every device", 30, controller.steps)
        assertEquals("a settled machine is not paused, so its inputs keep working", emptyList<String>(), controller.calls)
    }

    @Test
    fun aStateMachineThatMovesByItselfIsPausedAfterTheSteps() {
        val controller = FakeController(settlesAfter = null)
        val rive = FakeRiveWithController(context, listOf(Machine("State Machine 1", emptyList())), controller)
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine 1"))
        view.cyl_restUntilPlayed()
        assertEquals("shapes.riv: at most SETTLE_STEPS steps", CYLRiveTabBarItemAnimationView.SETTLE_STEPS, controller.steps)
        assertEquals(listOf("pause"), controller.calls)
    }

    @Test
    fun aSettledStateMachineIsPlayedAgainBeforeEachInput() {
        val controller = FakeController(settlesAfter = 1)
        val rive = FakeRiveWithController(context, listOf(Machine("State Machine", listOf("isOpen"))), controller)
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine", "input" to "isOpen", "duration" to "0"))
        view.cyl_restUntilPlayed()
        view.cyl_playAnimationView(); idle(CYLRiveTabBarItemAnimationView.INPUT_OFF_MS + 10)
        assertEquals("menu_button.riv on a slow emulator: the settled (paused) machine plays again before each input",
            listOf("play:State Machine", "play:State Machine", "isOpen=false", "play:State Machine", "isOpen=true"), rive.calls)
    }

    @Test
    fun aFileLoadedAgainAfterAPlayKeepsRunning() {
        val rive = FakeRive(context, listOf(Machine("State Machine 1", emptyList())))
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine 1"))
        view.cyl_playAnimationView()
        view.cyl_restUntilPlayed()
        assertEquals("a played icon is not paused again by a later load", listOf("reset", "play"), rive.calls)
    }

    @Test
    fun aHeldInputKeepsPlayingAfterItWasResumed() {
        val rive = FakeRive(context, listOf(Machine("State Machine", listOf("isOpen"))))
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine", "input" to "isOpen", "duration" to "0"))
        view.cyl_restUntilPlayed()
        view.cyl_playAnimationView(); idle(CYLRiveTabBarItemAnimationView.INPUT_OFF_MS + 10)
        view.cyl_playAnimationView(); idle(CYLRiveTabBarItemAnimationView.INPUT_OFF_MS + 10)
        assertEquals("menu_button.riv: resumed once, then every play toggles isOpen",
            listOf("pause", "play:State Machine", "isOpen=false", "isOpen=true", "isOpen=false", "isOpen=true"), rive.calls)
    }

    @Test
    fun aLoopedHeldInputStaysOffForHalfAPass() {
        val rive = FakeRive(context, listOf(Machine("State Machine", listOf("isOpen"))))
        val view = CYLRiveTabBarItemAnimationView(context, rive, mapOf("stateMachine" to "State Machine", "input" to "isOpen", "duration" to "0"))
        view.cyl_setAnimationViewLoops(true)
        view.cyl_playAnimationView()
        idle(100)
        assertEquals("still off a frame later, so a slow device renders the closed state", listOf("isOpen=false"), rive.calls)
        idle((CYLRiveTabBarItemAnimationView.LOOP_SECONDS * 1000 / 2).toLong())
        assertEquals(listOf("isOpen=false", "isOpen=true"), rive.calls)
    }
}
