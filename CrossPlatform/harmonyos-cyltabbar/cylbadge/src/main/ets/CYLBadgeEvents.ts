/**
 * [EN] The badge's lifecycle event names, owned by CYLBadge (docs/Animated-Item-Badge-CrossPlatform.md, D8 / L2, criterion P1-9). The strings
 *      are the same on every platform; they are posted through the lifecycle library's generic custom-event API.
 * [CN] 角标的生命周期事件名，归 CYLBadge 所有（docs/Animated-Item-Badge-CrossPlatform.md，D8 / L2，验收项 P1-9）。各平台字符串相同，
 *      经生命周期库的通用自定义事件 API 发出。
 */
export const BadgeEvents = {
  didShow: 'cyl.badge.didShow',
  didClear: 'cyl.badge.didClear',
  didBecomeReady: 'cyl.badge.didBecomeReady',
  animationDidStart: 'cyl.badge.animationDidStart',
  animationDidStop: 'cyl.badge.animationDidStop',
} as const;
