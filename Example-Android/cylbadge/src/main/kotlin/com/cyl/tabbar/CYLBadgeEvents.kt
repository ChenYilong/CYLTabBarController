package com.cyl.tabbar

/**
 * [EN] The badge's lifecycle event names, owned by CYLBadge (docs/Animated-Item-Badge-CrossPlatform.md, D8 / L2, criterion P1-9): the
 *      badge posts them through CYLDeallocBlockExecutor's generic custom-event API. The strings are the same on every platform, so an
 *      observer registered with an equal string keeps working.
 * [CN] 角标的生命周期事件名，归 CYLBadge 所有（docs/Animated-Item-Badge-CrossPlatform.md，D8 / L2，验收项 P1-9）：角标通过
 *      CYLDeallocBlockExecutor 的通用自定义事件 API 发出它们。各平台字符串相同，因此用相同字符串注册的观察者继续有效。
 */
object BadgeEvents {
    const val didShow = "cyl.badge.didShow"
    const val didClear = "cyl.badge.didClear"
    const val didBecomeReady = "cyl.badge.didBecomeReady"
    const val animationDidStart = "cyl.badge.animationDidStart"
    const val animationDidStop = "cyl.badge.animationDidStop"
}
