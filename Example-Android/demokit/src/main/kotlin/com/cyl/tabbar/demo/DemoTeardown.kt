package com.cyl.tabbar.demo

import android.os.Handler
import android.os.Looper
import com.chenyilong.cyldeallocblockexecutor.LifecycleRegistry
import com.cyl.tabbar.CYLTabBarController

/**
 * [EN] The teardown demo of the Playback section, the counterpart of iOS `CYLDemoTeardown` / `CYLDemoReleaseRow` (docs/Lifecycle-Library.md,
 *      step 21): "Release the tab bar controller (in 3 s)" counts down, arms a dealloc callback on the controller
 *      (CYLDeallocBlockExecutor, `LifecycleRegistry.addDeallocCallback`), then replaces the task with [DemoReleasedActivity].
 *      Destroying the host activity runs the controller's teardown blocks (`ON_DESTROY`), so the number "dealloc callbacks ran:
 *      N / M" is the library's own evidence that the controller was released. The texts go through `cylDemoText` (33 languages).
 * [CN] Playback 部分的销毁演示，对应 iOS 的 `CYLDemoTeardown` / `CYLDemoReleaseRow`（docs/Lifecycle-Library.md，第 21 步）：
 *      「Release the tab bar controller (in 3 s)」先倒计时，在控制器上登记 dealloc 回调（CYLDeallocBlockExecutor，
 *      `LifecycleRegistry.addDeallocCallback`），然后用 [DemoReleasedActivity] 替换任务。宿主 Activity 销毁时运行控制器的销毁块
 *      （`ON_DESTROY`），因此「dealloc callbacks ran: N / M」是库本身给出的「控制器已释放」的证据。文字经 `cylDemoText`（33 种语言）。
 */
object DemoTeardown {
    private const val KEY = "cyl.demo.teardown"
    private const val SECONDS = 3
    private val armed = mutableListOf<String>()
    private val ran = mutableListOf<String>()
    private val listeners = mutableListOf<() -> Unit>()
    private val handler = Handler(Looper.getMainLooper())

    /** [EN] Seconds left of a running countdown, 0 when none runs. [CN] 倒计时剩余秒数，没有倒计时时为 0。 */
    var remaining = 0
        private set

    val armedCount: Int get() = armed.size
    val ranCount: Int get() = ran.size

    /** [EN] Registers a dealloc callback on `owner`, named `name` in the report. [CN] 在 `owner` 上登记 dealloc 回调，报告中名为 `name`。 */
    fun arm(owner: CYLTabBarController, name: String) {
        armed.add(name)
        LifecycleRegistry.of(owner).addDeallocCallback<CYLTabBarController>(KEY) { _, _, _ -> record(name) }
    }

    /** [EN] A dealloc callback ran. [CN] 一个 dealloc 回调已执行。 */
    fun record(name: String) {
        ran.add(name)
        listeners.toList().forEach { it() }
    }

    /** [EN] Forgets the earlier run (tests, a second try). [CN] 忘记之前的运行（测试、再试一次）。 */
    fun reset() {
        handler.removeCallbacksAndMessages(null)
        armed.clear()
        ran.clear()
        remaining = 0
    }

    fun addListener(listener: () -> Unit) { listeners.add(listener) }

    fun removeListener(listener: () -> Unit) { listeners.remove(listener) }

    /** [EN] "dealloc callbacks ran: 1 / 1 (CYLTabBarController)". [CN] 「dealloc callbacks ran: 1 / 1 (CYLTabBarController)」。 */
    fun summary(): String =
        if (ran.isEmpty()) cylDemoText("dealloc callbacks ran: %d / %d", ran.size, armed.size)
        else cylDemoText("dealloc callbacks ran: %d / %d (%@)", ran.size, armed.size, ran.joinToString(", "))

    /** [EN] The status line of the row. [CN] 该行的状态文字。 */
    fun status(): String =
        if (remaining > 0) cylDemoText("teardown: releasing in %d s", remaining) else cylDemoText("teardown: not run")

    /**
     * [EN] Starts the countdown for `controller` hosted by `host`: arms the controller (and the host's class name), ticks every second
     *      through `onTick`, and at zero starts [DemoReleasedActivity] in a new task, which destroys the host.
     * [CN] 为 `host` 所承载的 `controller` 开始倒计时：登记控制器（以及宿主的类名），每秒通过 `onTick` 通知，到零时在新任务中启动
     *      [DemoReleasedActivity]，宿主随之销毁。
     */
    fun start(host: android.app.Activity, controller: CYLTabBarController, onTick: () -> Unit) {
        if (remaining > 0) return
        reset()
        arm(controller, "CYLTabBarController")
        remaining = SECONDS
        onTick()
        val tick = object : Runnable {
            override fun run() {
                remaining -= 1
                if (remaining > 0 && !host.isFinishing) {
                    onTick()
                    handler.postDelayed(this, 1000)
                    return
                }
                remaining = 0
                host.startActivity(android.content.Intent(host, DemoReleasedActivity::class.java)
                    .addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TASK))
            }
        }
        handler.postDelayed(tick, 1000)
    }
}
