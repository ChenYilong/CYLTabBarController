//
//  CYLRiveInputPass.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation

/**
 * [EN] The end rule of one pass of a Rive state machine input, as a pure function. `CYLRiveLegacyTabBarItemAnimationView` (the
 *      `Rive` subspec, compiled only with RiveRuntime) asks it when the input's `activeDuration` has elapsed; it lives in the
 *      core, without any Rive type, so a unit test can check the rule without RiveRuntime.
 * [CN] Rive 状态机输入一遍播放的结束规则，是一个纯函数。`CYLRiveLegacyTabBarItemAnimationView`（`Rive` 子库，只在引入 RiveRuntime 时编译）
 *      在输入的 `activeDuration` 经过之后向它询问；它放在组件核心（CYLAnimatedItem）中，不含任何 Rive 类型，因此单元测试无需 RiveRuntime 即可检查该规则。
 */
enum CYLRiveInputPass {

    /// [EN] What happens when the input's duration has elapsed. [CN] 输入的时长经过之后发生什么。
    enum Ending: Equatable {
        /// [EN] Nothing: an input held YES (`activeDuration` 0) has no end, and a cancelled pass (stopped or played again) is not
        ///      ended by the timer. [CN] 什么也不做：保持为 YES 的输入（`activeDuration` 为 0）没有结束，被取消的一遍（已停止或重新播放）不由计时结束。
        case noEnd
        /// [EN] The input goes back to NO; `notifiesEnd` tells whether the end handler is called (not while looping, as the
        ///      loop plays again). [CN] 输入恢复为 NO；`notifiesEnd` 表示是否调用结束回调（循环时不调用，因为循环会再次播放）。
        case ended(notifiesEnd: Bool)
    }

    /// [EN] Whether a pass of this duration ever ends by itself. [CN] 这个时长的一遍播放是否会自行结束。
    static func hasEnd(activeDuration: TimeInterval) -> Bool {
        activeDuration > 0
    }

    /// [EN] Does the input pass end now? Called after `activeDuration` seconds have elapsed. [CN] 输入的这一遍现在是否结束？在经过 `activeDuration` 秒之后调用。
    static func ending(activeDuration: TimeInterval, isCancelled: Bool, loops: Bool) -> Ending {
        guard hasEnd(activeDuration: activeDuration), !isCancelled else {
            return .noEnd
        }
        return .ended(notifiesEnd: !loops)
    }
}
