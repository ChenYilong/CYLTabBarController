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

    /**
     * [EN] How long a held input (duration 0) stays off before it goes on again: half a loop pass while looping, and also
     *      when the input is already on (`wasOn`: every Play after the first), so the false pass of the state machine is
     *      seen to its end (menu_button.riv: isOpen=false plays `open` to the X; a 150 ms window reversed it at the hamburger
     *      and it only twitched); otherwise INPUT_OFF_MS: from the X pose (`wasOn` false) the machine already rests there.
     * [CN] 保持的输入（时长 0）在重新打开前关闭多久：循环时为半个循环周期；输入本来就是开着时（`wasOn`：第一次之后的每次播放）也是，
     *      使状态机 false 的那一遍播放到结束（menu_button.riv：isOpen=false 播放 `open` 到 X；150 ms 的窗口在汉堡处就把它反转，只是抖了一下）；
     *      其他情况为 INPUT_OFF_MS：从 X 姿态出发（`wasOn` 为 false）状态机已停在那里。
     */
    fun offMilliseconds(activeDuration: Double, loops: Boolean, wasOn: Boolean): Long =
        if ((loops || wasOn) && activeDuration <= 0) (CYLRiveTabBarItemAnimationView.LOOP_SECONDS * 1000 / 2).toLong()
        else CYLRiveTabBarItemAnimationView.INPUT_OFF_MS
}
