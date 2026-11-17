package com.cyl.tabbar

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * [EN] `CYLRiveInputs`: a missing state machine input is reported (so it is skipped), unknown answers are true.
 * [CN] `CYLRiveInputs`：报告不存在的状态机输入（从而跳过），无法判断时为 true。
 */
class CYLRiveInputsTest {
    class Machine(private val name: String, private val inputs: List<String>) {
        fun getName() = name
        fun getInputNames() = inputs
    }

    class RiveView(private val machines: List<Machine>) {
        fun getStateMachines() = machines
    }

    @Test
    fun missingInputIsReported() {
        val view = RiveView(listOf(Machine("State Machine 1", listOf("hover"))))
        assertFalse(CYLRiveInputs.hasInput(view, "State Machine 1", "active"))
        assertTrue(CYLRiveInputs.hasInput(view, "State Machine 1", "hover"))
    }

    @Test
    fun unknownAnswersAreTrue() {
        assertTrue(CYLRiveInputs.hasInput(Any(), "State Machine 1", "active"))
        assertTrue(CYLRiveInputs.hasInput(RiveView(emptyList()), "State Machine 1", "active"))
    }
}
