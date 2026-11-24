package com.cyl.animateditem

/**
 * [EN] The end rule of one pass of a Rive state machine boolean input, as on iOS (`CYLRiveInputPass.swift`): a pass ends
 *      by itself only when the input has an `activeDuration` above 0 (the input goes back to false after it); an input
 *      held true (`activeDuration` 0) has no end. A pure function, tested without rive-android.
 * [CN] Rive 状态机布尔输入一遍播放的结束规则，与 iOS（`CYLRiveInputPass.swift`）相同：只有输入的 `activeDuration` 大于 0 时，
 *      这一遍才会自行结束（经过该时长后输入恢复为 false）；保持为 true 的输入（`activeDuration` 为 0）没有结束。纯函数，无需 rive-android 即可测试。
 */
internal object CYLRiveInputPass {
    /**
     * [EN] Whether a pass of this duration (seconds) ever ends by itself. [CN] 这个时长（秒）的一遍播放是否会自行结束。
     */
    fun hasEnd(activeDuration: Double): Boolean = activeDuration > 0
}
