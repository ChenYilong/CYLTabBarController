package com.cyl.tabbar

import kotlin.math.sqrt

/**
 * [EN] A damped spring, as Compose's `spring(dampingRatio, stiffness)` that Backdrop's tab bar animates with: `target`
 *      moves `value`, stepped from frame times.
 * [CN] 阻尼弹簧，对应 Backdrop 的 TabBar 所用的 Compose `spring(dampingRatio, stiffness)`：`target` 驱动 `value`，按帧时间步进。
 */
class CYLSpring(var value: Float, private val dampingRatio: Float, private val stiffness: Float, private val threshold: Float) {
    var target: Float = value
    var velocity: Float = 0f
        private set
    val isAtRest: Boolean get() = kotlin.math.abs(target - value) < threshold && kotlin.math.abs(velocity) < threshold * 10f

    fun snap(to: Float) {
        value = to
        target = to
        velocity = 0f
    }

    /**
     * [EN] Moves by `seconds`; true while it is still moving. [CN] 前进 `seconds` 秒；仍在运动时返回 true。
     */
    fun step(seconds: Float): Boolean {
        val omega = sqrt(stiffness)
        var remaining = seconds.coerceAtMost(0.064f)
        while (remaining > 0f) {
            val dt = remaining.coerceAtMost(0.004f)
            val acceleration = -stiffness * (value - target) - 2f * dampingRatio * omega * velocity
            velocity += acceleration * dt
            value += velocity * dt
            remaining -= dt
        }
        if (isAtRest) snap(target)
        return !isAtRest
    }
}
