/**
 * [EN] The countdown of cyl-animated-item (`itemStyle` 'countdown'), the mini program counterpart of iOS
 *      `CYLAnimatedItemView.style = .countdown` and Android `CYLAnimatedItemView.style = COUNTDOWN`: the "Get code" button of
 *      an SMS login. A state machine without any wx API (the clock and the storage are given), tested in Node
 *      (test/cyl_animated_item_countdown.test.js). The same rules as on the other platforms:
 *      - the end is a time, not a counter: the seconds spent in the background count, because the time left is read from the
 *        local clock on every tick and when the app is shown again (FIX: issue #1 of SMSCodeButton);
 *      - the start, the end and the longest duration are recorded; when the local clock is past the end, or was set back to
 *        before the start (a time left longer than the longest duration, one second of tolerance), the countdown is closed:
 *        the state is `finished` and a new countdown can start;
 *      - with a cache key the running countdown is kept in the storage, so a new item with the same key takes it up again
 *        after the mini program was ended in the background (no start callback).
 * [CN] cyl-animated-item 的倒计时（`itemStyle` 为 'countdown'），对应 iOS 的 `CYLAnimatedItemView.style = .countdown` 与 Android 的
 *      `CYLAnimatedItemView.style = COUNTDOWN`：短信登录的「获取验证码」按钮。不使用任何 wx API 的状态机（时钟与存储由外部传入），在 Node 中测试
 *      （test/cyl_animated_item_countdown.test.js）。规则与其他平台相同：
 *      - 结束是一个时间点，而不是计数器：后台度过的秒数计入，因为每次 tick 与小程序再次显示时都从本地时钟读取剩余时间（修复 SMSCodeButton 的 issue #1）；
 *      - 记录开始时间、结束时间与最长时长；本地时钟超过结束时间，或被调回到开始之前（剩余时间超过最长时长，允许 1 秒误差）时关闭倒计时：
 *        状态为 `finished`，可以重新开始；
 *      - 有缓存 key 时，运行中的倒计时保存到存储，小程序在后台被结束后，相同 key 的新条目接续倒计时（不触发开始回调）。
 */

/** [EN] The clock tolerance in ms. [CN] 时钟允许误差（毫秒）。 */
const CYL_COUNTDOWN_TOLERANCE = 1000

/**
 * [EN] How often a running countdown reads the clock (ms). [CN] 运行中的倒计时读取时钟的间隔（毫秒）。
 */
const CYL_COUNTDOWN_TICK_INTERVAL = 250

/**
 * [EN] `format` with its `%ld` (or `%d`) replaced by `seconds`. [CN] 把 `format` 中的 `%ld`（或 `%d`）替换为 `seconds`。
 */
function cylCountdownText(format, seconds) {
  return String(format).split('%ld').join(String(seconds)).split('%d').join(String(seconds))
}

/**
 * [EN] The storage name of a cache key. [CN] 缓存 key 在存储中的名称。
 */
function cylCountdownCacheName(key) {
  return `CYLAnimatedItemCountdown.${key}`
}

class CYLAnimatedItemCountdown {
  /**
   * [EN] `options`: `now()` (ms, default `Date.now`), `storage` (`get(name)`, `set(name, value)`, `remove(name)`; default none),
   *      `onStart()`, `onTick(seconds)`, `onFinish()`, `onChange()` (the state or the seconds changed: render).
   * [CN] `options`：`now()`（毫秒，默认 `Date.now`）、`storage`（`get(name)`、`set(name, value)`、`remove(name)`；默认没有）、
   *      `onStart()`、`onTick(seconds)`、`onFinish()`、`onChange()`（状态或秒数变化：重新渲染）。
   */
  constructor(options) {
    const o = options || {}
    this.now = o.now || (() => Date.now())
    this.storage = o.storage || null
    this.onStart = o.onStart || (() => {})
    this.onTick = o.onTick || (() => {})
    this.onFinish = o.onFinish || (() => {})
    this.onChange = o.onChange || (() => {})
    this.cacheKey = ''
    this.state = 'idle'
    this.start_ = 0
    this.end = 0
    this.duration = 0
    this.shownSeconds = -1
  }

  /** [EN] The whole seconds left (rounded up): 0 when it is not running. [CN] 剩余整秒数（向上取整）：未运行时为 0。 */
  get remainingSeconds() {
    if (this.state !== 'running') return 0
    const left = this.end - this.now()
    return left > 0 ? Math.ceil(left / 1000) : 0
  }

  /** [EN] The seconds the title shows. [CN] 标题显示的秒数。 */
  get shown() {
    return Math.max(this.shownSeconds, 0)
  }

  /**
   * [EN] Sets the cache key: the old cache is dropped, the running countdown is kept under the new key, otherwise a cached
   *      one is taken up. [CN] 设置缓存 key：丢弃旧缓存；运行中的倒计时保存到新 key，否则接续缓存的倒计时。
   */
  setCacheKey(key) {
    const next = key ? String(key) : ''
    if (next === this.cacheKey) return
    if (this.cacheKey) this.cyl_remove()
    this.cacheKey = next
    if (this.state === 'running') this.cyl_save()
    else this.restore()
  }

  /** [EN] Starts (or restarts) for `seconds`. [CN] 开始（或重新开始）`seconds` 秒。 */
  startFor(seconds) {
    const duration = Number(seconds) * 1000
    if (Number.isNaN(duration) || duration <= 0) {
      this.reset()
      return
    }
    const start = this.now()
    this.cyl_begin(start, start + duration, duration, true)
  }

  /** [EN] Stops and goes idle, with no finish callback. [CN] 停止并回到待机，不触发结束回调。 */
  reset() {
    this.state = 'idle'
    this.start_ = 0
    this.end = 0
    this.cyl_remove()
    this.onChange()
  }

  /**
   * [EN] Reads the clock: ticks when the whole seconds left changed, closes the countdown when the time is up or the clock is
   *      no longer plausible. Called by the timer and when the app is shown again. [CN] 读取时钟：剩余整秒数变化时 tick；时间到或时钟不再合理时关闭倒计时。
   *      由定时器与小程序再次显示时调用。
   */
  refresh() {
    if (this.state !== 'running') return
    const now = this.now()
    const left = this.end - now
    if (Number.isNaN(left) || left <= 0 || now - this.start_ < -CYL_COUNTDOWN_TOLERANCE || left > this.duration + CYL_COUNTDOWN_TOLERANCE) {
      this.cyl_finish()
      return
    }
    const seconds = Math.min(Math.ceil(left / 1000), Math.ceil(this.duration / 1000))
    if (seconds === this.shownSeconds) return
    this.shownSeconds = seconds
    this.onChange()
    this.onTick(seconds)
  }

  /**
   * [EN] Takes up a cached countdown that is still valid by the local clock (not over, not from the future, not longer than
   *      the longest duration it recorded); an invalid one is dropped. [CN] 接续按本地时钟仍然有效的缓存倒计时（未结束、不是来自未来、不超过其记录的最长时长）；无效的缓存被丢弃。
   */
  restore() {
    if (this.state === 'running' || !this.cacheKey || !this.storage) return
    const cached = this.storage.get(cylCountdownCacheName(this.cacheKey))
    if (!cached || typeof cached !== 'object') return
    const { start, end, duration } = cached
    const now = this.now()
    const valid = [start, end, duration].every((n) => Number.isFinite(n)) && duration > 0 && end - now > 0 &&
      now - start >= -CYL_COUNTDOWN_TOLERANCE && end - now <= duration + CYL_COUNTDOWN_TOLERANCE
    if (!valid) {
      this.cyl_remove()
      return
    }
    this.cyl_begin(start, end, duration, false)
  }

  cyl_begin(start, end, duration, announcesStart) {
    this.start_ = start
    this.end = end
    this.duration = duration
    this.state = 'running'
    this.shownSeconds = -1
    this.cyl_save()
    this.onChange()
    if (announcesStart) this.onStart()
    this.refresh()
  }

  cyl_finish() {
    this.state = 'finished'
    this.start_ = 0
    this.end = 0
    this.cyl_remove()
    this.onChange()
    this.onFinish()
  }

  cyl_save() {
    if (this.cacheKey && this.storage) {
      this.storage.set(cylCountdownCacheName(this.cacheKey), { start: this.start_, end: this.end, duration: this.duration })
    }
  }

  cyl_remove() {
    if (this.cacheKey && this.storage) this.storage.remove(cylCountdownCacheName(this.cacheKey))
  }
}

module.exports = {
  CYLAnimatedItemCountdown,
  CYL_COUNTDOWN_TICK_INTERVAL,
  CYL_COUNTDOWN_TOLERANCE,
  cylCountdownText,
  cylCountdownCacheName,
}
