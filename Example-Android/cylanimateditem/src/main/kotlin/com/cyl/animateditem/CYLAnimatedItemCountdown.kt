package com.cyl.animateditem

/**
 * [EN] The look of `CYLAnimatedItemView`: the plain animated icon + title (default), or a countdown button, e.g. for "Get the
 *      SMS code" (see `CYLAnimatedItemView.startCountdown`).
 * [CN] `CYLAnimatedItemView` 的样式：普通的动效 icon + title（默认），或倒计时按钮，例如「获取验证码」（见 `CYLAnimatedItemView.startCountdown`）。
 */
enum class CYLAnimatedItemStyle {
    /**
     * [EN] The plain animated icon + title (default). [CN] 普通的动效 icon + title（默认）。
     */
    Plain,

    /**
     * [EN] A bordered countdown button: idle title, then "N seconds left" until the time is up, then a finished title.
     * [CN] 带边框的倒计时按钮：先显示待机标题，再显示「还剩 N 秒」直到时间到，最后显示结束标题。
     */
    Countdown,
}

/**
 * [EN] Where a countdown is. [CN] 倒计时所处的阶段。
 */
enum class CYLAnimatedItemCountdownState {
    /**
     * [EN] Not started: the idle title shows and a tap can start it. [CN] 未开始：显示待机标题，点击可以开始。
     */
    Idle,

    /**
     * [EN] Counting down: the item is disabled. [CN] 倒计时中：条目不可用。
     */
    Running,

    /**
     * [EN] The time is up: the finished title shows and a tap can start it again. [CN] 时间到：显示结束标题，点击可以再次开始。
     */
    Finished,
}

/**
 * [EN] Where a running countdown is kept across a restart (a `SharedPreferences` in the view). Values are strings.
 * [CN] 运行中的倒计时在重启之间的保存位置（视图中为 `SharedPreferences`）。值为字符串。
 */
interface CYLAnimatedItemCountdownStorage {
    /**
     * [EN] The value of `name`, or null. [CN] `name` 的值，没有时为 null。
     */
    fun get(name: String): String?

    /**
     * [EN] Keeps `value` under `name`. [CN] 以 `name` 保存 `value`。
     */
    fun set(name: String, value: String)

    /**
     * [EN] Drops `name`. [CN] 丢弃 `name`。
     */
    fun remove(name: String)
}

/**
 * [EN] What a countdown reports. Every method is optional. [CN] 倒计时的报告。所有方法都是可选的。
 */
interface CYLAnimatedItemCountdownListener {
    /**
     * [EN] The state or the seconds shown changed: render. [CN] 状态或显示的秒数变化：重新渲染。
     */
    fun onCountdownChanged() { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] The countdown started (not when a cached one is taken up again). [CN] 倒计时开始（接续缓存的倒计时时不触发）。
     */
    fun onCountdownStarted() { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] The whole seconds left changed, once per second. [CN] 剩余整秒数变化，每秒一次。
     */
    fun onCountdownTicked(remainingSeconds: Int) { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] The time is up, or the clock made the countdown invalid. [CN] 时间到，或时钟使倒计时失效。
     */
    fun onCountdownFinished() { /* [EN] Optional. [CN] 可选。 */ }
}

/**
 * [EN] The countdown of `CYLAnimatedItemView` (`CYLAnimatedItemStyle.Countdown`), the Android counterpart of iOS
 *      `CYLAnimatedItemView.style = .countdown`: the "Get code" button of an SMS login. A state machine without any Android
 *      class (the clock and the storage are given), so it is tested on the JVM. The same rules as on the other platforms:
 *      - the end is a time, not a counter: the seconds spent in the background count, because the time left is read from the
 *        local clock on every tick and when the window is shown again (FIX: issue #1 of SMSCodeButton);
 *      - the start, the end and the longest duration are recorded; when the local clock is past the end, or was set back to
 *        before the start (a time left longer than the longest duration, one second of tolerance), the countdown is closed:
 *        the state is `Finished` and a new countdown can start;
 *      - with a cache key the running countdown is kept in the storage, so a new item with the same key takes it up again
 *        after the process was ended in the background (no start callback).
 * [CN] `CYLAnimatedItemView` 的倒计时（`CYLAnimatedItemStyle.Countdown`），对应 iOS 的 `CYLAnimatedItemView.style = .countdown`：短信登录的
 *      「获取验证码」按钮。不使用任何 Android 类的状态机（时钟与存储由外部传入），因此可以在 JVM 上测试。规则与其他平台相同：
 *      - 结束是一个时间点，而不是计数器：后台度过的秒数计入，因为每次 tick 与窗口再次显示时都从本地时钟读取剩余时间（修复 SMSCodeButton 的 issue #1）；
 *      - 记录开始时间、结束时间与最长时长；本地时钟超过结束时间，或被调回到开始之前（剩余时间超过最长时长，允许 1 秒误差）时关闭倒计时：
 *        状态为 `Finished`，可以重新开始；
 *      - 有缓存 key 时，运行中的倒计时保存到存储，进程在后台被结束后，相同 key 的新条目接续倒计时（不触发开始回调）。
 */
class CYLAnimatedItemCountdown(
    private val now: () -> Long = { System.currentTimeMillis() },
    var storage: CYLAnimatedItemCountdownStorage? = null,
    private val listener: CYLAnimatedItemCountdownListener = object : CYLAnimatedItemCountdownListener {},
) {
    /**
     * [EN] Where the countdown is. [CN] 倒计时所处的阶段。
     */
    var state: CYLAnimatedItemCountdownState = CYLAnimatedItemCountdownState.Idle
        private set

    /**
     * [EN] The whole seconds the title shows. [CN] 标题显示的整秒数。
     */
    val shownSeconds: Int get() = maxOf(shown, 0)

    /**
     * [EN] The cache key; set it with `setCacheKey`. [CN] 缓存 key；通过 `setCacheKey` 设置。
     */
    var cacheKey: String? = null
        private set

    private var startMillis = 0L
    private var endMillis = 0L
    private var durationMillis = 0L
    private var shown = -1

    /**
     * [EN] The whole seconds left (rounded up): 0 when it is not running. [CN] 剩余整秒数（向上取整）：未运行时为 0。
     */
    val remainingSeconds: Int
        get() {
            if (state != CYLAnimatedItemCountdownState.Running) return 0
            val left = endMillis - now()
            return if (left > 0) ceilSeconds(left) else 0
        }

    /**
     * [EN] When the running countdown ends (epoch millis); 0 when it is not running. [CN] 运行中的倒计时的结束时间（epoch 毫秒）；未运行时为 0。
     */
    val endTimeMillis: Long get() = if (state == CYLAnimatedItemCountdownState.Running) endMillis else 0L

    /**
     * [EN] Sets the cache key: the old cache is dropped, the running countdown is kept under the new key, otherwise a cached
     *      one is taken up. [CN] 设置缓存 key：丢弃旧缓存；运行中的倒计时保存到新 key，否则接续缓存的倒计时。
     */
    fun setCacheKey(key: String?) {
        val next = key?.takeIf { it.isNotEmpty() }
        if (next == cacheKey) return
        remove()
        cacheKey = next
        if (state == CYLAnimatedItemCountdownState.Running) save() else restore()
    }

    /**
     * [EN] Starts (or restarts) for `seconds`; 0 or less resets. [CN] 开始（或重新开始）`seconds` 秒；0 或更小则重置。
     */
    fun start(seconds: Int) {
        val duration = seconds * 1000L
        if (duration <= 0) {
            reset()
            return
        }
        val begin = now()
        begin(begin, begin + duration, duration, true)
    }

    /**
     * [EN] Stops and goes idle, with no finish callback. [CN] 停止并回到待机，不触发结束回调。
     */
    fun reset() {
        state = CYLAnimatedItemCountdownState.Idle
        startMillis = 0
        endMillis = 0
        remove()
        listener.onCountdownChanged()
    }

    /**
     * [EN] Reads the clock: ticks when the whole seconds left changed, closes the countdown when the time is up or the clock
     *      is no longer plausible. Called by the timer and when the window is shown again. [CN] 读取时钟：剩余整秒数变化时 tick；
     *      时间到或时钟不再合理时关闭倒计时。由定时器与窗口再次显示时调用。
     */
    fun refresh() {
        if (state != CYLAnimatedItemCountdownState.Running) return
        val current = now()
        val left = endMillis - current
        if (left <= 0 || current - startMillis < -TOLERANCE_MILLIS || left > durationMillis + TOLERANCE_MILLIS) {
            finish()
            return
        }
        val seconds = minOf(ceilSeconds(left), ceilSeconds(durationMillis))
        if (seconds == shown) return
        shown = seconds
        listener.onCountdownChanged()
        listener.onCountdownTicked(seconds)
    }

    /**
     * [EN] Takes up a cached countdown that is still valid by the local clock (not over, not from the future, not longer than
     *      the longest duration it recorded); an invalid one is dropped. [CN] 接续按本地时钟仍然有效的缓存倒计时（未结束、
     *      不是来自未来、不超过其记录的最长时长）；无效的缓存被丢弃。
     */
    fun restore() {
        val key = cacheKey ?: return
        val store = storage ?: return
        if (state == CYLAnimatedItemCountdownState.Running) return
        val parts = store.get(cacheName(key))?.split(",")?.mapNotNull { it.toLongOrNull() } ?: return
        if (parts.size != 3) {
            store.remove(cacheName(key))
            return
        }
        val (start, end, duration) = parts
        val current = now()
        val valid = duration > 0 && end - current > 0 && current - start >= -TOLERANCE_MILLIS && end - current <= duration + TOLERANCE_MILLIS
        if (!valid) {
            store.remove(cacheName(key))
            return
        }
        begin(start, end, duration, false)
    }

    private fun begin(start: Long, end: Long, duration: Long, announcesStart: Boolean) {
        startMillis = start
        endMillis = end
        durationMillis = duration
        state = CYLAnimatedItemCountdownState.Running
        shown = -1
        save()
        listener.onCountdownChanged()
        if (announcesStart) listener.onCountdownStarted()
        refresh()
    }

    private fun finish() {
        state = CYLAnimatedItemCountdownState.Finished
        startMillis = 0
        endMillis = 0
        remove()
        listener.onCountdownChanged()
        listener.onCountdownFinished()
    }

    private fun save() {
        val key = cacheKey ?: return
        storage?.set(cacheName(key), "$startMillis,$endMillis,$durationMillis")
    }

    private fun remove() {
        val key = cacheKey ?: return
        storage?.remove(cacheName(key))
    }

    private fun ceilSeconds(millis: Long): Int = ((millis + 999) / 1000).toInt()

    private fun cacheName(key: String) = "CYLAnimatedItemCountdown.$key"

    companion object {
        /**
         * [EN] The clock tolerance in ms. [CN] 时钟允许误差（毫秒）。
         */
        const val TOLERANCE_MILLIS = 1000L

        /**
         * [EN] How often a running countdown reads the clock (ms). [CN] 运行中的倒计时读取时钟的间隔（毫秒）。
         */
        const val TICK_INTERVAL_MILLIS = 250L

        /**
         * [EN] `format` with its `%d` (or `%ld`) replaced by `seconds`. [CN] 把 `format` 中的 `%d`（或 `%ld`）替换为 `seconds`。
         */
        fun text(format: String, seconds: Int): String = format.replace("%ld", seconds.toString()).replace("%d", seconds.toString())
    }
}
