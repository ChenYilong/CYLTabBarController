package com.cyl.tabbar

import android.os.Looper
import androidx.fragment.app.FragmentActivity
import org.robolectric.Robolectric
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf

/**
 * [EN] Helpers shared by the Robolectric tests of this package.
 * [CN] 本包 Robolectric 测试共用的辅助方法。
 */

/**
 * [EN] Runs `block` with a fresh activity (Robolectric.buildActivity needs no manifest entry, ActivityScenario does), with
 *      the resource `qualifiers` (e.g. "night", "zh-rCN") when given, then destroys it.
 * [CN] 用新的 Activity 运行 `block`（Robolectric.buildActivity 不需要在清单中声明，ActivityScenario 需要），给出 `qualifiers`（如 "night"、
 *      "zh-rCN"）时使用该资源限定符，然后销毁它。
 */
internal fun <T> withActivity(qualifiers: String? = null, block: (FragmentActivity) -> T): T {
    if (qualifiers != null) RuntimeEnvironment.setQualifiers(qualifiers)
    val controller = Robolectric.buildActivity(FragmentActivity::class.java).setup()
    try {
        return block(controller.get())
    } finally {
        controller.pause().stop().destroy()
    }
}

/** [EN] Tab attributes with these titles; the identifier is the lowercase title. [CN] 使用这些标题的 Tab 属性；标识为小写标题。 */
internal fun attributes(vararg titles: String): List<Map<String, Any?>> =
    titles.map { mapOf(CYLConstants.CYLTabBarItemTitle to it, CYLConstants.CYLTabBarItemIdentifier to it.lowercase()) }

/** [EN] Runs what is queued on the main looper. [CN] 执行主线程 Looper 中排队的任务。 */
internal fun idle() = shadowOf(Looper.getMainLooper()).idle()
