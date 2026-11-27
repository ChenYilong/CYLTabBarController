/**
 * [EN] The animation moments of cyl-animated-item through CYLDeallocBlockExecutor, and "pause every playing item while the user scrolls".
 *      An item posts `cyl.animation.didStart` / `didPause` / `didResume` / `didStop` on its own registry; `cylPausesAnimationsWhileUserScrolls(true)`
 *      pauses every playing item while any observed scroll source (`LifecycleCenter`: a page through `controller.onPageScroll`) scrolls, and resumes
 *      them afterwards.
 * [CN] cyl-animated-item 通过 CYLDeallocBlockExecutor 发出动画时机事件，以及“用户滚动时暂停所有正在播放的条目”。条目在自己的注册表上发出
 *      `cyl.animation.didStart` / `didPause` / `didResume` / `didStop`；`cylPausesAnimationsWhileUserScrolls(true)` 在任意被观察的滚动源
 *      （`LifecycleCenter`：页面通过 `controller.onPageScroll`）滚动时暂停所有正在播放的条目，滚动结束后恢复。
 */
const { AnimationEvents, LifecycleCenter } = require('../cyl-dealloc-block-executor/index')

const cylPlayingItems = new Set()
let cylStopScrollObserver = null

/** [EN] Posts `name` on the item's registry (nothing before `attached` created the controller). [CN] 在条目的注册表上发出 `name`（`attached` 创建控制器之前不发出）。 */
function cylPostAnimationEvent(item, name, userInfo) {
  if (item.cylLifecycle && !item.cylLifecycle.isDetached) item.cylLifecycle.registry.postLifecycleEvent(name, userInfo)
}

function cylAnimationDidStart(item, userInfo) {
  cylPlayingItems.add(item)
  item.cylPausedByUser = false
  cylPostAnimationEvent(item, AnimationEvents.didStart, userInfo)
}

function cylAnimationDidStop(item, finished) {
  // [EN] Only an item that played reports a stop, once. [CN] 只有播放过的条目才报告停止，且只报告一次。
  if (!cylPlayingItems.delete(item)) return
  const wasPaused = item.cylPausedByUser
  item.cylPausedByUser = false
  cylPostAnimationEvent(item, AnimationEvents.didStop, { finished, paused: wasPaused === true })
}

/** [EN] The item is gone: forget it. [CN] 条目已销毁：不再跟踪。 */
function cylForgetAnimation(item) {
  cylPlayingItems.delete(item)
}

/** [EN] Pauses a playing item once (false when nothing plays or it is paused already). [CN] 暂停正在播放的条目（只暂停一次；没有播放或已暂停时返回 false）。 */
function cylPauseAnimation(item) {
  if (!cylPlayingItems.has(item) || item.cylPausedByUser) return false
  item.cylPausedByUser = true
  const engine = item.selectComponent ? item.selectComponent('#cyl-animated-item-engine') : null
  if (engine && typeof engine.cylPause === 'function') engine.cylPause()
  cylPostAnimationEvent(item, AnimationEvents.didPause)
  return true
}

function cylResumeAnimation(item) {
  if (!item.cylPausedByUser) return false
  item.cylPausedByUser = false
  const engine = item.selectComponent ? item.selectComponent('#cyl-animated-item-engine') : null
  if (engine && typeof engine.cylPlay === 'function') engine.cylPlay()
  cylPostAnimationEvent(item, AnimationEvents.didResume)
  return true
}

/**
 * [EN] true: every playing item pauses while the user scrolls an observed source and resumes when scrolling ended; false stops observing.
 * [CN] 为 true 时，用户滚动被观察的滚动源时所有正在播放的条目暂停，滚动结束后恢复；为 false 时停止观察。
 */
function cylPausesAnimationsWhileUserScrolls(enabled) {
  if (cylStopScrollObserver) cylStopScrollObserver()
  cylStopScrollObserver = enabled
    ? LifecycleCenter.whileUserScrolls(
      () => [...cylPlayingItems].forEach(cylPauseAnimation),
      () => [...cylPlayingItems].forEach(cylResumeAnimation),
      { key: 'cyl.animatedItem.scroll' },
    )
    : null
}

module.exports = {
  cylPostAnimationEvent,
  cylAnimationDidStart,
  cylAnimationDidStop,
  cylForgetAnimation,
  cylPauseAnimation,
  cylResumeAnimation,
  cylPausesAnimationsWhileUserScrolls,
}
