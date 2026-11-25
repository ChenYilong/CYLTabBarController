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

    /// [EN] The input stays NO at least one frame, so the state machine advances with it. [CN] 输入至少保持 NO 一帧，使状态机带着它前进。
    static let minimumOffSeconds: TimeInterval = 0.05
    /// [EN] ... and at most this long, for a machine that never settles (shapes.riv, truck.riv). [CN] 至多保持这么久，用于永不稳定的状态机（shapes.riv、truck.riv）。
    static let maximumOffSeconds: TimeInterval = 1.5

    /// [EN] The longest the NO window of a restart lasts: `maximumOffSeconds` for an input held YES (`activeDuration` 0), and for an
    ///      input with an `activeDuration` that duration (not below `minimumOffSeconds`, not above `maximumOffSeconds`), so a machine
    ///      that never settles does not delay a 0.3 s pass by the full 1.5 s. Android `CYLRiveInputPass.offWindowCapMilliseconds` and
    ///      HarmonyOS `cylRiveOffWindowCapMs` follow the same rule.
    ///      [CN] 重新播放的 NO 窗口最长持续多久：保持为 YES 的输入（`activeDuration` 为 0）为 `maximumOffSeconds`；带 `activeDuration` 的输入
    ///      为该时长（不小于 `minimumOffSeconds`，不大于 `maximumOffSeconds`），永不稳定的状态机不会让 0.3 秒的一遍白等 1.5 秒。
    ///      Android `CYLRiveInputPass.offWindowCapMilliseconds` 与 HarmonyOS `cylRiveOffWindowCapMs` 使用同一规则。
    static func offWindowCap(activeDuration: TimeInterval) -> TimeInterval {
        guard hasEnd(activeDuration: activeDuration) else { return maximumOffSeconds }
        return min(maximumOffSeconds, max(minimumOffSeconds, activeDuration))
    }

    /// [EN] Does the NO window of a restart end now? It lasts until the state machine has settled, so its NO pass is seen
    ///      (menu_button.riv shows its X for about 0.5 s), within `minimumOffSeconds` ... `offWindowCap(activeDuration:)`.
    ///      [CN] 重新播放的 NO 窗口现在是否结束？它持续到状态机稳定，使 NO 的那一遍被看到（menu_button.riv 约 0.5 秒显示 X），
    ///      范围为 `minimumOffSeconds` ... `offWindowCap(activeDuration:)`。
    static func offWindowEnds(elapsed: TimeInterval, isSettled: Bool, activeDuration: TimeInterval = 0) -> Bool {
        elapsed >= offWindowCap(activeDuration: activeDuration) || (elapsed >= minimumOffSeconds && isSettled)
    }

    /// [EN] Does the input pass end now? Called after `activeDuration` seconds have elapsed. [CN] 输入的这一遍现在是否结束？在经过 `activeDuration` 秒之后调用。
    static func ending(activeDuration: TimeInterval, isCancelled: Bool, loops: Bool) -> Ending {
        guard hasEnd(activeDuration: activeDuration), !isCancelled else {
            return .noEnd
        }
        return .ended(notifiesEnd: !loops)
    }
}
