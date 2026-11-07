// [EN] The method names are the iOS names on purpose (`cyl_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.content.Context
import android.graphics.drawable.Drawable

/**
 * [EN] A skin of a configuration file (`CYLTabBarControllerThemes`, the same file as iOS): its named values, and the tab bar
 *      look they give (`CYLTabBarTheme`): the tabs' "@name" values, and the whole bar from the reserved names
 *      (`CYLTabBarBackgroundColor`, `CYLTabBarItemTitleColor`, ...). Created by the configuration initializers and registered
 *      with the theme manager. It is also a `CYLThemeValueProviding`, so views follow the same skins by name:
 *      `view.cyl_themeValue = "textColor:accent"` (adapted from QMUI's skins, where a view names a value of the skin).
 * [CN] 配置文件中的一个皮肤（`CYLTabBarControllerThemes`，与 iOS 同一个文件）：其命名值，以及这些值给出的 TabBar 外观（`CYLTabBarTheme`）：
 *      Tab 的 "@name" 值，以及由保留名称（`CYLTabBarBackgroundColor`、`CYLTabBarItemTitleColor` 等）决定的整个 TabBar。由配置初始化方法创建并注册到
 *      主题管理器。它也是 `CYLThemeValueProviding`，因此视图可以按名称跟随同样的皮肤：`view.cyl_themeValue = "textColor:accent"`（改编自 QMUI
 *      的换肤：视图引用皮肤中的值）。
 */
class CYLTabBarConfigurationTheme internal constructor(
    /** [EN] The skin's identifier, e.g. "dark". [CN] 皮肤的标识，例如 "dark"。 */
    val identifier: String,
    /** [EN] The named values, with the base skin's values for the names this skin does not give. [CN] 命名值；本皮肤没有的名称使用基础皮肤的值。 */
    val values: Map<String, Any?>,
    /** [EN] Per tab (its identifier, or its position without one): item key -> value name. [CN] 每个 Tab（其标识，没有时为位置）：item 键 -> 值名称。 */
    private val references: Map<Any, Map<String, String>>,
) : CYLTabBarTheme, CYLThemeValueProviding {

    /** [EN] `-valueForName:`: the value as written in the file. [CN] 文件中写的值。 */
    fun valueForName(name: String): Any? = values[name]

    /** [EN] `-colorForName:`: "#RGB", "#RRGGBB" or "#RRGGBBAA" (the iOS order), or null. [CN] 颜色（与 iOS 相同的写法），否则为 null。 */
    fun colorForName(name: String): Int? = CYLTabBarConfiguration.colorValue(values[name])

    /** [EN] `-fontForName:`: "15", "bold:15" or "Family-Style:12", or null. [CN] 字体，否则为 null。 */
    fun fontForName(name: String): CYLFont? = CYLFont.fromConfigurationValue(values[name])

    /** [EN] `-imageForName:`: through `CYLTabBarConfiguration.imageResolver`, or null. [CN] 通过 `CYLTabBarConfiguration.imageResolver` 解析的图片，否则为 null。 */
    fun imageForName(context: Context, name: String): Drawable? = when (val value = values[name]) {
        is Drawable -> value
        is String -> CYLTabBarConfiguration.imageResolver.drawable(context, value)
        else -> null
    }

    /** [EN] Theme values (`View.cyl_themeValue`): a color of the file becomes an ARGB Int, the rest stays as written. [CN] 主题值：文件中的颜色转换为 ARGB 整数，其他保持原样。 */
    override fun cyl_themeValueForName(name: String, context: Context): Any? {
        val value = values[name] ?: return null
        return (value as? String)?.takeIf { it.trim().startsWith("#") }?.let { colorForName(name) } ?: value
    }

    override fun cyl_tabBarItemsAttributesForTabBarController(tabBarController: CYLTabBarController): List<Map<String, Any?>>? {
        var themed = false
        var position = 0
        val items = tabBarController.tabBarItemsAttributes.map { item ->
            val identifier = (item[CYLConstants.CYLTabBarItemIdentifier] as? String)?.takeIf { it.isNotEmpty() }
            val keys = if (identifier != null) references[identifier] else references[position]
            position++
            // [EN] An empty entry keeps that tab as it is. [CN] 空条目让该 Tab 保持不变。
            val resolved = keys.orEmpty().mapNotNull { (key, name) -> values[name]?.let { key to it } }.toMap()
            if (resolved.isNotEmpty()) themed = true
            resolved
        }
        return if (themed) items else null
    }

    override fun cyl_tabBarAppearanceForTabBarController(tabBarController: CYLTabBarController): CYLTabBarAppearance? {
        val appearance = CYLTabBarAppearance(
            backgroundColor = colorForName(CYLConstants.CYLTabBarBackgroundColor),
            shadowColor = colorForName(CYLConstants.CYLTabBarShadowColor),
            titleColor = colorForName(CYLConstants.CYLTabBarItemTitleColor),
            selectedTitleColor = colorForName(CYLConstants.CYLTabBarItemSelectedTitleColor),
            iconColor = colorForName(CYLConstants.CYLTabBarItemIconColor),
            selectedIconColor = colorForName(CYLConstants.CYLTabBarItemSelectedIconColor),
        )
        // [EN] No bar-wide values: the app's own look stays. [CN] 没有整个 TabBar 的值：保留 App 自己的外观。
        return if (appearance == CYLTabBarAppearance()) null else appearance
    }

    override fun cyl_customizeTabBarController(tabBarController: CYLTabBarController) {
        val titleFont = fontForName(CYLConstants.CYLTabBarItemTitleFont)
        val selectedTitleFont = fontForName(CYLConstants.CYLTabBarItemSelectedTitleFont) ?: titleFont
        if (titleFont != null) tabBarController.cyl_tabBarItemTitleFont = titleFont
        if (selectedTitleFont != null) tabBarController.cyl_tabBarItemSelectedTitleFont = selectedTitleFont
    }

    override fun toString(): String = "CYLTabBarConfigurationTheme($identifier)"

    companion object {
        /**
         * [EN] `+colorNamed:`: a `CYLThemeColor` that follows the skin of the manager named `themeManagerName`: the value `name` of its current skin
         *      (or of the first skin of the file that has it, while another kind of theme is current).
         * [CN] 跟随名为 `themeManagerName` 的管理器皮肤的 `CYLThemeColor`：其当前皮肤中名为 `name` 的值（当前为其他类型的主题时，使用文件中第一个提供该值的皮肤）。
         */
        @JvmStatic
        @JvmOverloads
        fun colorNamed(name: String, themeManagerName: Any = CYLThemeManagerNameDefault): CYLThemeColor =
            CYLThemeColor.cyl_colorWithName(name, themeManagerName) { manager, _, theme ->
                (theme as? CYLTabBarConfigurationTheme)?.colorForName(name)
                    ?: manager.themes.firstNotNullOfOrNull { (it as? CYLTabBarConfigurationTheme)?.colorForName(name) }
                    ?: android.graphics.Color.TRANSPARENT
            }
    }
}

/**
 * [EN] The skins of a configuration, shared with iOS: `CYLTabBarControllerThemes` in the dictionary or the list form, the
 *      "@name" values of the tabs ("@@" for a literal "@"), the base skin every skin falls back to, the dark one, and the
 *      one used first (a skin chosen before is kept).
 * [CN] 配置中的皮肤（与 iOS 相同）：字典或列表形式的 `CYLTabBarControllerThemes`、Tab 中的 "@name" 值（"@@" 表示普通的 "@"）、每个皮肤回退的基础皮肤、
 *      深色皮肤，以及首先使用的皮肤（之前选择的皮肤保持不变）。
 */
internal object CYLConfigurationThemes {
    const val INFO_KEY = "_CYLTabBarControllerConfigurationThemes"

    /** [EN] What the normalization hands to the controller. [CN] 规范化交给控制器的信息。 */
    class Info(val values: Map<String, Map<String, Any?>>, val base: String, val dark: String?, val initial: String, val managerName: String?) {
        var themes: List<CYLTabBarConfigurationTheme> = emptyList()
            internal set
    }

    private fun valuesOf(value: Any?): Map<String, Any?>? {
        val map = when (value) {
            null -> emptyMap<Any?, Any?>()
            is Map<*, *> -> if (value.size == 2 && value.containsKey("key") && value.containsKey("value")) mapOf(value["key"] to value["value"]) else value
            // [EN] Protobuf map entries. [CN] Protobuf 的 map 条目。
            is List<*> -> value.associate { entry -> val pair = entry as? Map<*, *> ?: return null; pair["key"] to pair["value"] }
            else -> return null
        }
        return map.entries.filter { it.key is String && it.value != null }.associate { it.key as String to it.value }
    }

    /** [EN] identifier -> named values; null when there is no valid skin. [CN] 标识 -> 命名值；没有有效皮肤时为 null。 */
    fun themes(value: Any?): Map<String, Map<String, Any?>>? {
        val themes = LinkedHashMap<String, Map<String, Any?>>()
        val list: List<*> = when {
            value is List<*> -> value
            value is Map<*, *> && value.containsKey(CYLConstants.CYLTabBarThemeIdentifier) -> listOf(value)
            value is Map<*, *> -> {
                for ((key, values) in value) {
                    val identifier = key?.toString()?.takeIf { it.isNotEmpty() } ?: continue
                    valuesOf(values)?.let { themes[identifier] = it }
                }
                emptyList<Any?>()
            }
            else -> emptyList<Any?>()
        }
        for (entry in list) {
            val skin = entry as? Map<*, *> ?: continue
            val identifier = skin[CYLConstants.CYLTabBarThemeIdentifier]?.toString()?.takeIf { it.isNotEmpty() } ?: continue
            valuesOf(skin[CYLConstants.CYLTabBarThemeValues])?.let { themes[identifier] = it }
        }
        return themes.takeIf { it.isNotEmpty() }
    }

    fun info(configuration: Map<String, Any?>, darkMode: Boolean): Info? {
        val themes = themes(configuration[CYLConstants.CYLTabBarControllerThemes]) ?: return null
        val identifiers = themes.keys.sorted()
        val base = (configuration[CYLConstants.CYLTabBarControllerThemeIdentifier]?.toString())?.takeIf { it in themes } ?: identifiers.first()
        val dark = configuration[CYLConstants.CYLTabBarControllerDarkThemeIdentifier]?.toString()?.takeIf { it in themes }
        val managerName = configuration[CYLConstants.CYLTabBarControllerThemeManagerName]?.toString()?.takeIf { it.isNotEmpty() }
        val manager = managerName?.let { CYLThemeManagerCenter.themeManagerWithName(it) } ?: CYLThemeManagerCenter.defaultThemeManager
        val current = manager.currentThemeIdentifier as? String
        val initial = when {
            current != null && current in themes -> current
            dark != null && darkMode -> dark
            else -> base
        }
        val merged = identifiers.associateWith { identifier -> themes.getValue(base) + themes.getValue(identifier) }
        return Info(merged, base, dark, initial, managerName)
    }

    /** [EN] A tab with its "@name" values taken from `values`; the keys that refer to a name go to `references`. [CN] 用 `values` 替换 Tab 中的 "@name" 值；引用名称的键记录到 `references`。 */
    fun resolve(item: Map<String, Any?>, values: Map<String, Any?>, references: MutableMap<String, String>): Map<String, Any?> {
        val resolved = LinkedHashMap(item)
        for ((key, value) in item) {
            val text = value as? String ?: continue
            if (!text.startsWith("@")) continue
            if (text.startsWith("@@")) {
                resolved[key] = text.substring(1)
                continue
            }
            val name = text.substring(1).trim().takeIf { it.isNotEmpty() } ?: continue
            references[key] = name
            val themed = values[name]
            if (themed != null) resolved[key] = themed else {
                android.util.Log.w("CYLTabBarController", "configuration: no skin gives the value \"$name\" of $key; the key is left out.")
                resolved.remove(key)
            }
        }
        return resolved
    }

    /** [EN] The skins, with the "@name" keys of every kept tab (by identifier, or position without one). [CN] 生成皮肤，带上每个保留 Tab 的 "@name" 键（按标识，没有时按位置）。 */
    fun finish(info: Info, items: List<Map<String, Any?>>, itemReferences: List<Map<String, String>>) {
        val references = LinkedHashMap<Any, Map<String, String>>()
        var position = 0
        items.forEachIndexed { index, item ->
            if (item[CYLTabBarConfiguration.EXCLUDED_KEY] == true) return@forEachIndexed
            val keys = itemReferences.getOrNull(index).orEmpty()
            val identifier = (item[CYLConstants.CYLTabBarItemIdentifier] as? String)?.takeIf { it.isNotEmpty() }
            if (keys.isNotEmpty()) references[identifier ?: position] = keys
            position++
        }
        info.themes = info.values.map { (identifier, values) -> CYLTabBarConfigurationTheme(identifier, values, references) }
    }
}
