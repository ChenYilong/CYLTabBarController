package com.cyl.tabbar.pages

import org.json.JSONArray
import org.json.JSONObject

/**
 * [EN] One tab of the configuration, with the keys of the iOS library (`CYLTabBarItemTitle`, ...). [attributes] keeps
 *      every key, so a page can read the ones it needs.
 * [CN] 配置中的一个 Tab，使用 iOS 库的键（`CYLTabBarItemTitle` 等）。[attributes] 保留所有键，页面可以读取需要的键。
 */
data class TabItem(val attributes: Map<String, Any?>) {
    val title: String? get() = attributes[TabConfiguration.TITLE] as? String
    val image: String? get() = attributes[TabConfiguration.IMAGE] as? String
    val selectedImage: String? get() = attributes[TabConfiguration.SELECTED_IMAGE] as? String

    /**
     * [EN] The page ID: `CYLTabBarItemPageIdentifier`, or `CYLTabBarItemIdentifier` when it is missing or blank.
     * [CN] 页面 ID：`CYLTabBarItemPageIdentifier`；未设置或为空时使用 `CYLTabBarItemIdentifier`。
     */
    val pageId: String?
        get() = listOf(TabConfiguration.PAGE_IDENTIFIER, TabConfiguration.IDENTIFIER)
            .map { (attributes[it] as? String)?.trim().orEmpty() }
            .firstOrNull { it.isNotEmpty() }

    /** [EN] `CYLTabBarItemPageParameters`, or empty. [CN] `CYLTabBarItemPageParameters`，没有则为空。 */
    val pageParameters: Map<String, String>
        get() = (attributes[TabConfiguration.PAGE_PARAMETERS] as? Map<*, *>)
            ?.entries?.associate { it.key.toString() to it.value.toString() }
            .orEmpty()
}

/**
 * [EN] Reads a tab bar configuration file (JSON) with the rules of the iOS library: the tabs, in order, without the
 *      ones left out on this platform (`CYLTabBarItemPlatforms`) or for this app version
 *      (`CYLTabBarItemMinimumAppVersion`). Invalid values are ignored with a warning, as on iOS (edge cases B23–B25).
 * [CN] 按 iOS 库的规则读取 TabBar 配置文件（JSON）：按顺序返回各 Tab，去掉在本平台（`CYLTabBarItemPlatforms`）或本 App 版本
 *      （`CYLTabBarItemMinimumAppVersion`）不显示的 Tab。无效值会被忽略并输出警告，与 iOS 一致（边界情况 B23–B25）。
 */
/** [EN] Where a page is looked up, in the iOS order. [CN] 查找页面的来源，顺序与 iOS 相同。 */
enum class PageSource(val key: String) { INSTANCE("instance"), RESOLVER("resolver"), SHARED("shared"), AUTOMATIC("automatic") }

/** [EN] Why a tab got no page (the iOS `CYLTabBarPageSkipReason`). [CN] Tab 没有页面的原因（对应 iOS 的 `CYLTabBarPageSkipReason`）。 */
enum class SkipReason { INVALID_TAB, MISSING_IDENTIFIER, UNREGISTERED, EXCLUDED, PROVIDER_FAILED }

/** [EN] A tab without a page, and why. [CN] 没有页面的 Tab 及其原因。 */
data class SkippedTab(val reason: SkipReason, val pageId: String?, val tab: TabItem?, val detail: String? = null)

/** [EN] A parsed configuration: see [TabConfiguration.configuration]. [CN] 解析后的配置：见 [TabConfiguration.configuration]。 */
data class TabBarConfiguration(
    val attributes: Map<String, Any?>,
    val tabs: List<TabItem>,
    val lookupOrder: List<PageSource>,
    val skipped: List<SkippedTab>,
)

object TabConfiguration {
    const val ITEMS = "CYLTabBarControllerTabBarItemsAttributes"
    const val TITLE = "CYLTabBarItemTitle"
    const val IMAGE = "CYLTabBarItemImage"
    const val SELECTED_IMAGE = "CYLTabBarItemSelectedImage"
    const val IDENTIFIER = "CYLTabBarItemIdentifier"
    const val PAGE_IDENTIFIER = "CYLTabBarItemPageIdentifier"
    const val PAGE_PARAMETERS = "CYLTabBarItemPageParameters"
    const val PLATFORMS = "CYLTabBarItemPlatforms"
    const val MINIMUM_APP_VERSION = "CYLTabBarItemMinimumAppVersion"

    const val PAGE_LOOKUP_ORDER = "CYLTabBarControllerPageLookupOrder"
    const val AUTOMATIC_PAGE_REGISTRATION = "CYLTabBarControllerAutomaticPageRegistration"

    /**
     * [EN] The tabs of a configuration text (JSON, XML plist or `.properties`, see [TabConfigurationFormats]) for
     *      [platform] and [appVersion]. Left-out tabs are not returned; [configuration] also reports them.
     * [CN] 配置文本（JSON、XML plist 或 `.properties`，见 [TabConfigurationFormats]）中适用于 [platform] 与 [appVersion] 的 Tab。
     *      被排除的 Tab 不返回；[configuration] 会同时报告它们。
     */
    fun tabs(text: String, platform: String = "android", appVersion: String? = null): List<TabItem> =
        configuration(text, platform, appVersion).tabs

    /**
     * [EN] The whole configuration: the top-level attributes, the tabs for this platform and app version, the lookup
     *      order (`CYLTabBarControllerPageLookupOrder` / `CYLTabBarControllerAutomaticPageRegistration`, the iOS rules)
     *      and the tabs left out, with their reason.
     * [CN] 整份配置：顶层属性、适用于本平台与 App 版本的 Tab、查找顺序（`CYLTabBarControllerPageLookupOrder` /
     *      `CYLTabBarControllerAutomaticPageRegistration`，规则与 iOS 相同）以及被排除的 Tab 及原因。
     */
    fun configuration(text: String, platform: String = "android", appVersion: String? = null,
                      format: TabConfigurationFormat = TabConfigurationFormats.detect(text)): TabBarConfiguration {
        val root = TabConfigurationFormats.parse(text, format)
        val items: List<Map<String, Any?>> = when (val value = root[ITEMS]) {
            is List<*> -> value.mapNotNull { item -> (item as? Map<*, *>)?.entries?.associate { it.key.toString() to it.value } }
            is Map<*, *> -> listOf(value.entries.associate { it.key.toString() to it.value })
            else -> emptyList()
        }
        val tabs = ArrayList<TabItem>()
        val skipped = ArrayList<SkippedTab>()
        for (item in items) {
            val tab = TabItem(item)
            val reason = exclusionReason(tab, platform, appVersion)
            if (reason == null) tabs += tab else skipped += SkippedTab(SkipReason.EXCLUDED, tab.pageId, tab, reason)
        }
        return TabBarConfiguration(root, tabs, lookupOrder(root[PAGE_LOOKUP_ORDER], root[AUTOMATIC_PAGE_REGISTRATION]), skipped)
    }

    /**
     * [EN] The lookup order of a configuration value (a list or a comma-separated string of `instance`, `resolver`,
     *      `shared`, `automatic`), without `automatic` when the flag is false; unknown entries are dropped with a warning,
     *      the default order is used when nothing is left (iOS edge case C18).
     * [CN] 配置值中的查找顺序（`instance`、`resolver`、`shared`、`automatic` 的列表或逗号分隔的字符串）；开关为 false 时去掉 `automatic`；
     *      未知项丢弃并警告，没有剩余项时使用默认顺序（iOS 边界情况 C18）。
     */
    fun lookupOrder(value: Any?, automatic: Any?): List<PageSource> {
        val names: List<Any?> = when (value) {
            null -> emptyList()
            is String -> value.split(",")
            is List<*> -> value
            else -> { println("CYLTabBar: invalid $PAGE_LOOKUP_ORDER $value; ignored."); emptyList() }
        }
        val order = ArrayList<PageSource>()
        for (name in names) {
            val source = (name as? String)?.trim()?.let { trimmed -> PageSource.entries.firstOrNull { it.key.equals(trimmed, ignoreCase = true) } }
            if (source != null) { if (source !in order) order += source } else println("CYLTabBar: invalid $PAGE_LOOKUP_ORDER entry $name; ignored.")
        }
        val result = if (order.isEmpty()) PageSource.entries.toMutableList() else order
        val automaticOn = when (automatic) {
            null -> true
            is Boolean -> automatic
            is String -> automatic.trim().lowercase() !in listOf("false", "no", "0")
            is Number -> automatic.toInt() != 0
            else -> { println("CYLTabBar: invalid $AUTOMATIC_PAGE_REGISTRATION $automatic; ignored."); true }
        }
        if (!automaticOn) result.remove(PageSource.AUTOMATIC)
        return result
    }

    /** [EN] Why a tab is left out, or null. [CN] Tab 被排除的原因，没有则为 null。 */
    fun exclusionReason(tab: TabItem, platform: String, appVersion: String?): String? {
        val platforms = platforms(tab.attributes[PLATFORMS])
        if (platforms != null && platform.lowercase() !in platforms) {
            return "its platforms are ${platforms.joinToString()}"
        }
        val minimum = tab.attributes[MINIMUM_APP_VERSION] as? String ?: return null
        val minimumNumbers = versionNumbers(minimum)
        if (minimumNumbers == null) {
            println("CYLTabBar: invalid $MINIMUM_APP_VERSION \"$minimum\"; ignored.")
            return null
        }
        val appNumbers = appVersion?.let(::versionNumbers) ?: return null
        return if (isLower(appNumbers, minimumNumbers)) "it needs version $minimum (this app is $appVersion)" else null
    }

    /** [EN] A list of strings or a comma-separated string, as lowercase names; null when missing or invalid. [CN] 字符串数组或逗号分隔的字符串，转为小写名称；未设置或无效时为 null。 */
    fun platforms(value: Any?): List<String>? {
        val names: List<Any?> = when (value) {
            null -> return null
            is String -> value.split(",")
            is List<*> -> value
            else -> {
                println("CYLTabBar: invalid $PLATFORMS $value; ignored.")
                return null
            }
        }
        val platforms = names.map { (it as? String)?.trim()?.lowercase().orEmpty() }
        if (platforms.isEmpty() || platforms.any { it.isEmpty() }) {
            println("CYLTabBar: invalid $PLATFORMS $value; ignored.")
            return null
        }
        return platforms
    }

    /** [EN] "2.10.1" -> [2, 10, 1]; null when a part is not a number. [CN] "2.10.1" -> [2, 10, 1]；某部分不是数字时为 null。 */
    fun versionNumbers(version: String): List<Long>? {
        val parts = version.trim().split(".")
        if (parts.isEmpty() || parts.any { part -> part.isEmpty() || !part.all { it.isDigit() } }) return null
        return parts.map { it.toLongOrNull() ?: return null }
    }

    private fun isLower(version: List<Long>, minimum: List<Long>): Boolean {
        for (i in 0 until maxOf(version.size, minimum.size)) {
            val a = version.getOrElse(i) { 0 }
            val b = minimum.getOrElse(i) { 0 }
            if (a != b) return a < b
        }
        return false
    }

    internal fun toMap(json: JSONObject): Map<String, Any?> =
        json.keys().asSequence().associateWith { key -> toValue(json.opt(key)) }

    private fun toValue(value: Any?): Any? = when (value) {
        is JSONObject -> toMap(value)
        is JSONArray -> (0 until value.length()).map { toValue(value.opt(it)) }
        JSONObject.NULL -> null
        else -> value
    }
}
