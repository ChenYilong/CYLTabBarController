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

    /** [EN] The tabs of a JSON configuration for [platform] and [appVersion]. [CN] JSON 配置中适用于 [platform] 与 [appVersion] 的 Tab。 */
    fun tabs(json: String, platform: String = "android", appVersion: String? = null): List<TabItem> {
        val root = JSONObject(json)
        val items = when (val value = root.opt(ITEMS)) {
            is JSONArray -> (0 until value.length()).mapNotNull { value.opt(it) as? JSONObject }
            is JSONObject -> listOf(value)
            else -> emptyList()
        }
        return items.map { TabItem(toMap(it)) }.filter { exclusionReason(it, platform, appVersion) == null }
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

    private fun toMap(json: JSONObject): Map<String, Any?> =
        json.keys().asSequence().associateWith { key -> toValue(json.opt(key)) }

    private fun toValue(value: Any?): Any? = when (value) {
        is JSONObject -> toMap(value)
        is JSONArray -> (0 until value.length()).map { toValue(value.opt(it)) }
        JSONObject.NULL -> null
        else -> value
    }
}
