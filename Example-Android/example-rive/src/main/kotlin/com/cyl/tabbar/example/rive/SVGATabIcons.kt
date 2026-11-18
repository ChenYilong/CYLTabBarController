package com.cyl.tabbar.example.rive

import android.app.Activity
import android.content.Context
import androidx.fragment.app.FragmentActivity
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLTabBarAnimationURLWithOptions
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.CYLTabBarPageRegistry

/**
 * [EN] Where the tab icons come from (iOS `CYLDemoTabIconSource`, SVGATabIcons.swift, issue #415): the Rive artboards,
 *      the same tabs with SVGA files given by the SVGA keys (`CYLTabBarSVGAURL`), or the tab bar of
 *      cyl_tabbar_configuration_svga.json (`CYLTabBarSVGAFilePath`, `tabBarControllerWithConfigurationFile`). Chosen on
 *      the Bell page and kept across launches; the launch extra `CYLDemoTabIconSource` 0|1|2 also sets it (screenshots).
 * [CN] Tab 图标的来源（iOS `CYLDemoTabIconSource`，SVGATabIcons.swift，issue #415）：Rive 画板、用 SVGA key（`CYLTabBarSVGAURL`）提供 SVGA
 *      文件的同一组 Tab，或 cyl_tabbar_configuration_svga.json 的 TabBar（`CYLTabBarSVGAFilePath`、`tabBarControllerWithConfigurationFile`）。
 *      在 Bell 页面选择，重启后保持；启动参数 `CYLDemoTabIconSource` 0|1|2 也可以设置（截图）。
 */
enum class CYLDemoTabIconSource(val title: String) {
    Rive("Rive"),
    SVGAKeys("SVGA (initialization keys)"),
    SVGAConfigurationFile("SVGA (configuration file)");

    val next: CYLDemoTabIconSource get() = entries[(ordinal + 1) % entries.size]

    companion object {
        private const val KEY = "CYLDemoTabIconSource"

        /**
         * [EN] The source in use; the launch extra wins once and is saved. [CN] 当前来源；启动参数优先一次并被保存。
         */
        fun current(activity: Activity): CYLDemoTabIconSource {
            val preferences = activity.getSharedPreferences(KEY, Context.MODE_PRIVATE)
            activity.intent?.takeIf { it.hasExtra(KEY) }?.let { intent ->
                val launched = intent.getStringExtra(KEY)?.toIntOrNull() ?: intent.getIntExtra(KEY, 0)
                preferences.edit().putInt(KEY, launched).apply()
                intent.removeExtra(KEY)
            }
            return entries.getOrElse(preferences.getInt(KEY, 0)) { Rive }
        }

        fun save(context: Context, source: CYLDemoTabIconSource) =
            context.getSharedPreferences(KEY, Context.MODE_PRIVATE).edit().putInt(KEY, source.ordinal).apply()
    }
}

/**
 * [EN] The SVGA file of each tab, one for one with its Rive artboard (iOS `CourseTab.svgaFileName`); the files are
 *      Example-SwiftUI-Rive's SVGAAssets, not a copy.
 * [CN] 每个 Tab 的 SVGA 文件，与其 Rive 画板一一对应（iOS `CourseTab.svgaFileName`）；文件来自 Example-SwiftUI-Rive 的 SVGAAssets，不是副本。
 */
val CourseTab.svgaFileName: String
    get() = when (this) {
        CourseTab.Chat -> "tab_chat.svga"
        CourseTab.Search -> "tab_search.svga"
        CourseTab.Timer -> "tab_activity.svga"
        CourseTab.Bell -> "tab_list.svga"
        CourseTab.User -> "tab_profile.svga"
    }

/**
 * [EN] The SVGA keys of the tab's icon (iOS `CourseTab.svgaAttributes`). [CN] Tab 图标的 SVGA key。
 */
fun CourseTab.svgaAttributes(tinted: Boolean = false): Map<String, Any?> = mapOf(
    CYLConstants.CYLTabBarSVGAURL to if (tinted) CYLTabBarAnimationURLWithOptions(svgaFileName, mapOf(CYLConstants.CYLTabBarAnimationOptionTint to "title")) else svgaFileName,
    CYLConstants.CYLTabBarSVGASize to "{32, 32}",
)

/**
 * [EN] The tab bar of cyl_tabbar_configuration_svga.json (Example-Rive/RiveApp/SVGA): tabs, plus button and SVGA icons from
 *      the file, pages from the page registry (svga-chat … svga-timer → the course pages).
 * [CN] cyl_tabbar_configuration_svga.json（Example-Rive/RiveApp/SVGA）中的 TabBar：Tab、PlusButton 与 SVGA 图标来自该文件，页面来自页面注册表
 *      （svga-chat … svga-timer → 课程页面）。
 */
object CYLDemoSVGAConfiguration {
    private var registered = false

    fun makeTabBarController(activity: FragmentActivity): CYLTabBarController? {
        if (!registered) {
            registered = true
            val pages = CourseTab.entries.associateBy { "svga-" + it.name.lowercase() }
            CYLTabBarPageRegistry.sharedRegistry.registerPageProvider({ id, _ -> pages.getValue(id).page() }, pages.keys.toList())
        }
        return runCatching { CYLTabBarController.tabBarControllerWithConfigurationFile(activity, "cyl_tabbar_configuration_svga.json") }.getOrNull()
    }
}
