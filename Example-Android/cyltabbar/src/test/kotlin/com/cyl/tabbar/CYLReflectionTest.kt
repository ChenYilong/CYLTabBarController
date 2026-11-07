package com.cyl.tabbar

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * [EN] `CYLReflection.callKotlin`: the animation libraries' Kotlin methods are called with their own default parameters
 *      (rive-android's `play(animationName, loop = Loop.AUTO, …)`), and the overload is chosen by the given arguments.
 * [CN] `CYLReflection.callKotlin`：动画库的 Kotlin 方法以其自身的默认参数调用（rive-android 的 `play(animationName, loop = Loop.AUTO, …)`），
 *      并按给定参数选择重载。
 */
class CYLReflectionTest {
    enum class Loop { ONESHOT, LOOP, AUTO }

    /** [EN] Shaped like rive-android's `RiveAnimationView.play` overloads. [CN] 形状与 rive-android 的 `RiveAnimationView.play` 重载相同。 */
    class FakeRiveView {
        var calls = ArrayList<String>()
        fun play(loop: Loop = Loop.AUTO, settle: Boolean = true) { calls += "play($loop, $settle)" }
        fun play(animationNames: List<String>, loop: Loop = Loop.AUTO, isStateMachine: Boolean = false) { calls += "list($animationNames, $loop, $isStateMachine)" }
        fun play(animationName: String, loop: Loop = Loop.AUTO, isStateMachine: Boolean = false) { calls += "one($animationName, $loop, $isStateMachine)" }
    }

    @Test
    fun defaultsAndOverloads() {
        val view = FakeRiveView()
        val default = CYLReflection.DEFAULT
        CYLReflection.callKotlin(view, "play", "active", default, false)
        CYLReflection.callKotlin(view, "play", default, default)
        CYLReflection.callKotlin(view, "play", "machine", Loop.LOOP, true)
        assertEquals(listOf("one(active, AUTO, false)", "play(AUTO, true)", "one(machine, LOOP, true)"), view.calls)
        assertNull("no overload with 7 parameters", CYLReflection.callKotlin(view, "play", 1, 2, 3, 4, 5, 6, 7))
        assertEquals(Loop.AUTO, CYLReflection.enumConstant(Loop::class.java.name, "AUTO"))
    }
}
