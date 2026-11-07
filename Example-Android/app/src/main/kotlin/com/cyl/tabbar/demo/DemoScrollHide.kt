package com.cyl.tabbar.demo

import android.app.AlertDialog
import android.app.Dialog
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.view.inputmethod.InputMethodManager
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.PopupMenu
import android.widget.PopupWindow
import android.widget.TextView
import androidx.fragment.app.Fragment
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.cyl_handleNavigationBackActionWithAnimated
import com.cyl.tabbar.cyl_pushViewController
import com.cyl.tabbar.cyl_tabBarController
import com.google.android.material.bottomsheet.BottomSheetDialog

/**
 * [EN] Scroll hiding (issue #13): rows that simulate the interruptions a tab bar hidden by scrolling must come back from,
 *      ported from the iOS `CYLScrollHideSimulationSection`. Each row turns scroll hiding on, hides the bar as a downward
 *      scroll would (`cyl_simulateHideOnScrollForTesting`), fires its interruption 1.5 s later, and 1.5 s after that shows
 *      PASS or FAIL: "Restore" rows expect the bar back, "Keep" rows expect it to stay as it is. Titles name the Android
 *      API or event they trigger; events an app cannot trigger are manual or marked n/a.
 * [CN] 滚动隐藏（issue #13）：模拟各种意外情况的行，滚动隐藏的 TabBar 必须在这些情况后恢复，移植自 iOS 的 `CYLScrollHideSimulationSection`。
 *      每行开启滚动隐藏，像向下滚动一样隐藏 TabBar（`cyl_simulateHideOnScrollForTesting`），1.5 秒后触发意外情况，再过 1.5 秒显示 PASS 或 FAIL：
 *      "Restore" 行期望 TabBar 恢复，"Keep" 行期望保持原样。标题即触发的 Android API 或事件；App 无法触发的事件为手动或标记为 n/a。
 */
object DemoScrollHide {
    enum class Kind { Restore, Keep, Manual, NotApplicable, SelfTest }

    private class Simulation(val title: String, val kind: Kind, val expectsVisible: Boolean = kind == Kind.Restore,
                             val fire: (DemoListFragment, CYLTabBarController, () -> Unit) -> Unit = { _, _, done -> done() })

    private const val DELAY = 1500L
    private const val HOLD = 1500L
    private val handler = Handler(Looper.getMainLooper())
    private var expanded = false
    private val results = HashMap<Int, String>()

    private fun later(delay: Long, block: () -> Unit) = handler.postDelayed(block, delay)

    /** [EN] Shows a dialog and closes it after the hold. [CN] 显示弹窗，保持一段时间后关闭。 */
    private fun dialog(dialog: Dialog, done: () -> Unit) {
        dialog.show()
        later(HOLD) { dialog.dismiss(); done() }
    }

    /** [EN] Opens another activity (the app's window loses the focus and pauses), and closes it after the hold. [CN] 打开另一个 Activity（App 窗口失去焦点并暂停），保持一段时间后关闭。 */
    private fun activity(page: DemoListFragment, text: String, done: () -> Unit) {
        DemoHostActivity.open(page.requireContext(), text) { activity -> TextView(activity).apply { this.text = text; gravity = Gravity.CENTER } }
        later(HOLD) { DemoHostActivity.current?.get()?.finish(); later(500, done) }
    }

    private val simulations: List<Simulation> = listOf(
        Simulation("AlertDialog (alert)", Kind.Restore) { page, _, done -> dialog(AlertDialog.Builder(page.requireContext()).setMessage("Alert").create(), done) },
        Simulation("BottomSheetDialog (action sheet)", Kind.Restore) { page, _, done ->
            dialog(BottomSheetDialog(page.requireContext()).apply { setContentView(TextView(context).apply { text = "Action sheet"; setPadding(48, 48, 48, 48) }) }, done)
        },
        Simulation("startActivity (full screen modal)", Kind.Restore) { page, _, done -> activity(page, "Full screen modal", done) },
        Simulation("Dialog with a page (page sheet)", Kind.Restore) { page, _, done ->
            dialog(Dialog(page.requireContext()).apply { setContentView(TextView(context).apply { text = "Page sheet"; setPadding(96, 192, 96, 192) }) }, done)
        },
        Simulation("cyl_pushViewController, then pop", Kind.Restore) { page, _, done ->
            page.pushText("Pushed")
            later(HOLD) { page.cyl_handleNavigationBackActionWithAnimated(false); done() }
        },
        Simulation("push a page that hides the tab bar (hidesBottomBarWhenPushed), then pop", Kind.Restore) { page, _, done ->
            page.cyl_pushViewController(HidesTabBarPage())
            later(HOLD) { page.cyl_handleNavigationBackActionWithAnimated(false); done() }
        },
        Simulation("selectedIndex + 1, then back", Kind.Restore) { _, controller, done ->
            val index = controller.selectedIndex
            controller.selectedIndex = (index + 1) % controller.viewControllers.size
            later(HOLD / 2) { controller.selectedIndex = index; done() }
        },
        Simulation("onPause (a call, low battery, a system dialog): a translucent activity", Kind.Restore) { page, _, done -> activity(page, "onPause", done) },
        Simulation("onStop / onStart: an activity covers the app", Kind.Restore) { page, _, done -> activity(page, "onStop", done) },
        Simulation("Notification tap: come back, then push", Kind.Restore) { page, _, done ->
            activity(page, "Notification") { page.pushText("From the notification"); later(HOLD) { page.cyl_handleNavigationBackActionWithAnimated(false); done() } }
        },
        Simulation("onTrimMemory (memory warning)", Kind.Restore) { _, _, done -> CYLTabBarController.cyl_simulateMemoryWarning(); done() },
        Simulation("PopupWindow, focusable (another window)", Kind.Restore) { page, _, done ->
            val popup = PopupWindow(TextView(page.requireContext()).apply { text = "Overlay window"; setBackgroundColor(Color.YELLOW); setPadding(48, 48, 48, 48) }, -2, -2, true)
            popup.showAtLocation(page.requireView(), Gravity.CENTER, 0, 0)
            later(HOLD) { popup.dismiss(); done() }
        },
        Simulation("EditText requestFocus (keyboard)", Kind.Restore) { page, _, done -> withKeyboard(page, done) { } },
        Simulation("Intent.createChooser (share sheet)", Kind.Restore) { page, _, done ->
            page.startActivity(Intent.createChooser(Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, "CYLTabBarController"), "Share"))
            later(HOLD) { done() }
        },
        Simulation("smoothScrollToPosition(0) (scroll to top in code)", Kind.Restore) { page, controller, done ->
            page.listView?.setSelection(0)
            controller.cyl_scrollDidChange(-20)
            done()
        },
        Simulation("smoothScrollBy: down, in code", Kind.Keep, expectsVisible = false) { page, _, done -> page.listView?.smoothScrollBy(300, 200); later(500, done) },
        Simulation("App: setTabBarHidden(true) for 4 s", Kind.Keep, expectsVisible = false) { _, controller, done ->
            controller.setTabBarHidden(true, true)
            done()
            later(4000) { controller.setTabBarHidden(false, true) }
        },
        Simulation("cyl_hidesTabBarOnScroll = false, then true", Kind.Restore) { _, controller, done ->
            controller.cyl_hidesTabBarOnScroll = false
            controller.cyl_hidesTabBarOnScroll = true
            done()
        },
        Simulation("TalkBack turned on or off", Kind.NotApplicable),
        Simulation("Keyboard up: scroll, the bar must not hide", Kind.Keep, expectsVisible = true) { page, controller, done ->
            withKeyboard(page, done) { controller.cyl_scrollDidChange(40) }
        },
        Simulation("Animator duration scale (reduce motion) changed", Kind.NotApplicable),
        Simulation("Battery saver turned on (ACTION_POWER_SAVE_MODE_CHANGED)", Kind.NotApplicable),
        Simulation("Manual: rotate the device (the activity is recreated, the bar starts shown)", Kind.Manual),
        Simulation("A translucent page over the current one (over current context), then back", Kind.Restore) { page, _, done ->
            page.cyl_pushViewController(TranslucentPage())
            later(HOLD) { page.cyl_handleNavigationBackActionWithAnimated(false); done() }
        },
        Simulation("PopupMenu (popover)", Kind.Restore) { page, _, done ->
            val menu = PopupMenu(page.requireContext(), page.requireView(), Gravity.CENTER).apply { menu.add("Popover") }
            menu.show()
            later(HOLD) { menu.dismiss(); done() }
        },
        Simulation("A side drawer slides in and away (a dialog from the left)", Kind.Restore) { page, _, done ->
            dialog(Dialog(page.requireContext()).apply {
                setContentView(TextView(context).apply { text = "Drawer"; setPadding(96, 400, 200, 400); setBackgroundColor(Color.WHITE) })
                window?.setGravity(Gravity.START)
            }, done)
        },
        Simulation("Status bar height change (in-call / hotspot bar)", Kind.NotApplicable),
        Simulation("Manual: split screen, tap the other app (this window loses the focus)", Kind.Manual),
        Simulation("Manual: long press a row (context menu)", Kind.Manual),
        Simulation("Manual: tap an action bar menu", Kind.Manual),
        Simulation("Manual: after a restore, fling on without lifting; only a new drag hides it", Kind.Manual),
        Simulation("Real: open Settings (the app really goes to the background; come back)", Kind.Manual) { page, _, done -> page.startActivity(Intent(Settings.ACTION_SETTINGS)); done() },
        Simulation("Real system dialog: tel: dialer (press Back)", Kind.Manual) { page, _, done -> page.startActivity(Intent(Intent.ACTION_DIAL, Uri.parse("tel:10086"))); done() },
        Simulation("Keyboard of another app", Kind.NotApplicable),
        Simulation("startLockTask (screen pinning, the Android guided access)", Kind.Restore) { page, _, done ->
            val activity = page.requireActivity()
            try { activity.startLockTask() } catch (error: IllegalStateException) { /* [EN] Pinning not allowed. [CN] 不允许固定屏幕。 */ }
            later(HOLD) { try { activity.stopLockTask() } catch (error: IllegalStateException) { /* [EN] Not pinned. [CN] 未固定。 */ }; done() }
        },
        Simulation("selectedIndex = the same tab (no change)", Kind.Keep, expectsVisible = false) { _, controller, done ->
            // [EN] The setter runs with the tab already selected, as an app selecting the same tab again. [CN] 以已选中的 Tab 调用 setter，如同 App 再次选中同一个 Tab。
            val sameTab = controller.selectedIndex
            controller.selectedIndex = sameTab
            done()
        },
        Simulation("cyl_hidesTabBarOnScroll = true again (no change)", Kind.Keep, expectsVisible = false) { _, controller, done -> controller.cyl_hidesTabBarOnScroll = true; done() },
        Simulation("App: setTabBarHidden(false)", Kind.Restore) { _, controller, done -> controller.setTabBarHidden(false, true); done() },
        Simulation("Self-test: run every automatic simulation, report PASS / FAIL", Kind.SelfTest),
    )

    val count: Int get() = simulations.size

    private fun withKeyboard(page: DemoListFragment, done: () -> Unit, whileUp: () -> Unit) {
        val root = page.view as? FrameLayout ?: return done()
        val field = EditText(page.requireContext()).apply { hint = "Keyboard"; setBackgroundColor(Color.WHITE) }
        root.addView(field, FrameLayout.LayoutParams(-1, -2, Gravity.TOP))
        field.requestFocus()
        page.activity?.window?.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_STATE_VISIBLE)
        (page.requireContext().getSystemService(InputMethodManager::class.java))?.showSoftInput(field, InputMethodManager.SHOW_IMPLICIT)
        later(HOLD / 2) { whileUp() }
        later(HOLD) {
            page.requireContext().getSystemService(InputMethodManager::class.java)?.hideSoftInputFromWindow(field.windowToken, 0)
            root.removeView(field)
            done()
        }
    }

    fun section(page: DemoListFragment): DemoSection {
        val rows = ArrayList<DemoRow>()
        rows += DemoRow("Scroll hiding: simulated interruptions (issue #13)", { "Choose one from a list; the same simulations as the rows below" }) {
            choose("Simulated interruptions", simulations.map { it.title }) { index -> run(this, index) }
        }
        rows += DemoRow(if (expanded) "Collapse the simulations" else "Expand all ${simulations.size} simulations") { expanded = !expanded }
        if (expanded) simulations.forEachIndexed { index, simulation ->
            rows += DemoRow(simulation.title, { results[index] ?: hint(simulation) }) { run(this, index) }
        }
        return DemoSection("Scroll hiding: simulated interruptions (issue #13)", rows)
    }

    private fun hint(simulation: Simulation) = when (simulation.kind) {
        Kind.Restore -> "Tap: the bar hides, then the interruption comes. Expected: the bar comes back."
        Kind.Keep -> if (simulation.expectsVisible) "Expected: the bar stays shown." else "Expected: the bar stays as it is (no restore)."
        Kind.Manual -> "Manual: tap to turn scroll hiding on, scroll down to hide the bar, then do what the title says. Expected: the bar comes back."
        Kind.NotApplicable -> "n/a on Android: an app cannot post this system event."
        Kind.SelfTest -> "Runs every automatic row, one after the other."
    }

    private fun run(page: DemoListFragment, index: Int) {
        val controller = page.tabBarController ?: return
        val simulation = simulations[index]
        when (simulation.kind) {
            Kind.NotApplicable -> page.showMessage(simulation.title, hint(simulation))
            Kind.Manual -> { controller.cyl_hidesTabBarOnScroll = true; simulation.fire(page, controller) { } }
            Kind.SelfTest -> selfTest(page, controller)
            else -> runOne(page, controller, index) { result -> results[index] = result; if (page.isAdded) page.reload() }
        }
    }

    private fun runOne(page: DemoListFragment, controller: CYLTabBarController, index: Int, completion: (String) -> Unit) {
        val simulation = simulations[index]
        controller.setTabBarHidden(false, false)
        controller.cyl_hidesTabBarOnScroll = true
        controller.cyl_simulateHideOnScrollForTesting()
        if (!controller.cyl_isTabBarHiddenByScroll) return completion("FAIL: the bar did not hide (cyl_simulateHideOnScrollForTesting)")
        later(DELAY) {
            if (!page.isAdded) return@later
            simulation.fire(page, controller) {
                later(HOLD) {
                    completion(verdict(controller, simulation))
                    if (!simulation.expectsVisible) controller.setTabBarHidden(false, true)
                }
            }
        }
    }

    /** [EN] "PASS" or "FAIL", with the state of the bar and the expected one. [CN] "PASS" 或 "FAIL"，以及 TabBar 的状态与预期状态。 */
    private fun verdict(controller: CYLTabBarController, simulation: Simulation): String {
        val visible = controller.tabBar.visibility == View.VISIBLE && !controller.cyl_isTabBarHiddenByScroll
        val result = if (visible == simulation.expectsVisible) "PASS" else "FAIL"
        return "$result: the bar is ${shownOrHidden(visible)}, expected ${shownOrHidden(simulation.expectsVisible)}"
    }

    private fun shownOrHidden(visible: Boolean) = if (visible) "shown" else "hidden"

    private fun selfTest(page: DemoListFragment, controller: CYLTabBarController) {
        val automatic = simulations.indices.filter { simulations[it].kind == Kind.Restore || simulations[it].kind == Kind.Keep }
        val report = ArrayList<String>()
        fun next(position: Int) {
            if (position >= automatic.size || !page.isAdded) {
                if (page.isAdded) page.showMessage("Self-test", "${report.count { it.startsWith("PASS") }} / ${report.size} PASS\n\n" + report.joinToString("\n"))
                return
            }
            val index = automatic[position]
            runOne(page, controller, index) { result ->
                results[index] = result
                report += "$result · ${simulations[index].title}"
                later(600) { next(position + 1) }
            }
        }
        next(0)
    }
}

/** [EN] A pushed page that hides the tab bar while shown (`hidesBottomBarWhenPushed`). [CN] 显示期间隐藏 TabBar 的 push 页面（`hidesBottomBarWhenPushed`）。 */
class HidesTabBarPage : Fragment() {
    override fun onCreateView(inflater: android.view.LayoutInflater, container: android.view.ViewGroup?, savedInstanceState: android.os.Bundle?): View =
        TextView(inflater.context).apply { text = "hidesBottomBarWhenPushed"; gravity = Gravity.CENTER; setBackgroundColor(Color.rgb(255, 204, 0)); isClickable = true }

    override fun onResume() { super.onResume(); cyl_tabBarController?.setTabBarHidden(true, true) }
    override fun onPause() { cyl_tabBarController?.setTabBarHidden(false, true); super.onPause() }
}

/** [EN] A translucent page over the current one (`UIModalPresentationOverCurrentContext`). [CN] 覆盖当前页面的半透明页面。 */
class TranslucentPage : Fragment() {
    override fun onCreateView(inflater: android.view.LayoutInflater, container: android.view.ViewGroup?, savedInstanceState: android.os.Bundle?): View =
        TextView(inflater.context).apply { text = "Over current context"; gravity = Gravity.CENTER; setBackgroundColor(Color.argb(128, 0, 0, 0)); setTextColor(Color.WHITE); isClickable = true }
}
