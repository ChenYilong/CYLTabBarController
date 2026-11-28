package com.cyl.tabbar

import android.content.Context
import android.os.Handler
import android.os.Looper
import androidx.fragment.app.FragmentActivity
import com.cyl.tabbar.CYLTabBarConfiguration.CYLConfigurationException
import com.cyl.tabbar.CYLTabBarConfiguration.CYLTabBarConfigurationError
import java.io.File
import java.net.URI
import java.security.MessageDigest
import java.util.Locale

/**
 * [EN] A tab bar manifest (docs/Configuration-Manifest.md), as `CYLTabBarManifest` on iOS: after uni-app's `tabBar` /
 *      `midButton` / `theme.json`, Expo Updates' manifest (`id`, `version`, `assets[]` with SHA-256, the embedded fallback)
 *      and Firebase Remote Config's conditions. [configuration] turns it into the dictionary of `CYLTabBarController`.
 *      Icons are asset references, `asset:<key>?state=<normal|selected>&theme=<theme>`, found in `assets.list` under
 *      `assets.baseRoute` (a resource route that holds the version): one image per version, theme, tab and state.
 * [CN] TabBar 配置清单（docs/Configuration-Manifest.md），与 iOS 的 `CYLTabBarManifest` 相同：参照 uni-app 的 `tabBar` / `midButton` / `theme.json`、
 *      Expo Updates 清单（`id`、`version`、带 SHA-256 的 `assets[]`、内置备用）与 Firebase Remote Config 的条件。[configuration] 把它转换为
 *      `CYLTabBarController` 的字典。图标写作资源引用 `asset:<key>?state=<normal|selected>&theme=<主题>`，在 `assets.baseRoute`（包含版本的资源路由）下的
 *      `assets.list` 中查找：每张图片由版本、主题、Tab 与状态唯一确定。
 */
class CYLTabBarManifest private constructor(
    /**
     * [EN] The manifest after the overrides of its matching conditions. [CN] 合并成立条件覆盖项后的清单。
     */
    val dictionary: Map<String, Any?>,
    /**
     * [EN] Where relative routes start: a folder, or "asset:<folder>". [CN] 相对路由的起点：目录或 "asset:<目录>"。
     */
    val baseDirectory: String?,
    private val context: Context,
) {
    /**
     * [EN] Where an applied manifest came from. [CN] 已生效清单的来源。
     */
    enum class CYLTabBarManifestSource { None, Remote, Cache, Embedded }

    val identifier: String? get() = string(dictionary, "id")
    val version: String? get() = string(dictionary, "version")

    companion object {
        /**
         * [EN] The manifest format this library reads. [CN] 本库读取的清单格式版本。
         */
        const val supportedSchemaVersion = 1
        private const val ASSET_NAME_PREFIX = "cyl.asset."
        /**
         * [EN] The scheme of an asset reference ("asset:home?state=selected"). [CN] 资源引用的 scheme。
         */
        private const val ASSET_REFERENCE_PREFIX = "asset:"

        /**
         * [EN] A manifest from a dictionary; `UnsupportedManifest` when it is not one. [CN] 由字典创建清单；不是清单时抛出 `UnsupportedManifest`。
         */
        @JvmStatic
        @Throws(CYLConfigurationException::class)
        fun manifestWithDictionary(context: Context, dictionary: Map<String, Any?>, baseDirectory: String?): CYLTabBarManifest {
            if (dictionary["tabBar"] !is Map<*, *>) throw CYLConfigurationException(CYLTabBarConfigurationError.UnsupportedManifest, "Not a tab bar manifest: it has no \"tabBar\" dictionary.")
            val schema = (dictionary["schemaVersion"] as? Number)?.toInt() ?: (dictionary["schemaVersion"] as? String)?.toIntOrNull()
            if (schema != supportedSchemaVersion) {
                throw CYLConfigurationException(CYLTabBarConfigurationError.UnsupportedManifest, "schemaVersion ${dictionary["schemaVersion"] ?: "(missing)"} is not supported (this library reads $supportedSchemaVersion).")
            }
            var merged: Map<String, Any?> = dictionary
            // [EN] Overrides of the conditions that hold, in order (Firebase). [CN] 按顺序合并成立条件的覆盖项（Firebase）。
            val overrides = dictionary["overrides"] as? List<*> ?: emptyList<Any?>()
            for (condition in dictionary["conditions"] as? List<*> ?: emptyList<Any?>()) {
                val name = string(condition, "name") ?: continue
                if (!CYLManifestConditions.holds(context, string(condition, "expression"))) continue
                for (override in overrides) {
                    if (string(override, "condition") != name) continue
                    @Suppress("UNCHECKED_CAST")
                    merged = merge(merged, (override as Map<String, Any?>) - "condition") as Map<String, Any?>
                }
            }
            return CYLTabBarManifest(merged, baseDirectory, context.applicationContext)
        }

        /**
         * [EN] A manifest from a resource route (docs/Resource-Routes.md). [CN] 由资源路由创建清单（docs/Resource-Routes.md）。
         */
        @JvmStatic
        @Throws(CYLConfigurationException::class)
        fun manifestWithRoute(context: Context, route: String): CYLTabBarManifest {
            val location = CYLResourceRoute.locationForRoute(context, route)
                ?: throw CYLConfigurationException(CYLTabBarConfigurationError.FileNotFound, "No manifest matches the route \"$route\".")
            val dictionary = CYLTabBarConfiguration.configurationWithContentsOfFile(context, location.path) - CYLTabBarConfigurationLocalization.FILE_DIRECTORY_KEY
            val base = location.file?.parent ?: (CYLResourceRoute.ASSET_PREFIX + location.assetPath.orEmpty().substringBeforeLast('/', ""))
            return manifestWithDictionary(context, dictionary, base)
        }

        internal fun string(container: Any?, key: String): String? = when (val value = (container as? Map<*, *>)?.get(key)) {
            is Number -> value.toString()
            is String -> value.trim().ifEmpty { null }
            else -> null
        }

        internal fun merge(base: Any?, override: Any?): Any? {
            if (base !is Map<*, *> || override !is Map<*, *>) return override
            val merged = LinkedHashMap<Any?, Any?>(base)
            for ((key, value) in override) merged[key] = merge(base[key], value)
            return merged
        }

        /**
         * [EN] "1.10.0" > "1.9": each number compared as a number, missing parts count as 0. [CN] 逐段按数值比较，缺少的段视为 0。
         */
        internal fun compareVersions(first: String, second: String): Int {
            val a = first.split('.')
            val b = second.split('.')
            for (index in 0 until maxOf(a.size, b.size)) {
                val x = a.getOrNull(index)?.trim()?.toLongOrNull() ?: 0
                val y = b.getOrNull(index)?.trim()?.toLongOrNull() ?: 0
                if (x != y) return x.compareTo(y)
            }
            return 0
        }

        internal fun platforms(value: Any?): List<String> = when (value) {
            is List<*> -> value.mapNotNull { (it as? String)?.trim()?.lowercase()?.ifEmpty { null } }
            is String -> value.split(',').mapNotNull { it.trim().lowercase().ifEmpty { null } }
            else -> emptyList()
        }

        internal fun allowsAndroid(value: Any?): Boolean = platforms(value).let { it.isEmpty() || "all" in it || "android" in it }

        internal fun appVersion(context: Context): String = try {
            context.packageManager.getPackageInfo(context.packageName, 0).versionName ?: "0"
        } catch (error: Exception) {
            "0"
        }

        /**
         * [EN] "sha256-" and the Base64URL digest, without padding (Expo's asset hash). [CN] "sha256-" 加无填充的 Base64URL 摘要（Expo 的资源哈希）。
         */
        @JvmStatic
        fun hashOf(data: ByteArray): String {
            val digest = MessageDigest.getInstance("SHA-256").digest(data)
            // [EN] android.util.Base64: java.util.Base64 needs API 26. [CN] android.util.Base64：java.util.Base64 需要 API 26。
            return "sha256-" + android.util.Base64.encodeToString(digest, android.util.Base64.URL_SAFE or android.util.Base64.NO_PADDING or android.util.Base64.NO_WRAP)
        }
    }

    /**
     * [EN] Whether this app may use it (platforms, app versions, time window); the reason otherwise. [CN] 本 App 能否使用（平台、App 版本、时间段）；否则给出原因。
     */
    fun eligibilityError(nowMillis: Long = System.currentTimeMillis()): CYLConfigurationException? {
        val runtime = dictionary["runtime"] as? Map<*, *>
        val app = appVersion(context)
        val minimum = string(runtime, "minAppVersion")
        val maximum = string(runtime, "maxAppVersion")
        val start = string(runtime, "startTime")?.let(::isoMillis)
        val end = string(runtime, "endTime")?.let(::isoMillis)
        val reason = when {
            !allowsAndroid(runtime?.get("platforms")) -> "runtime.platforms ${platforms(runtime?.get("platforms"))} does not include android."
            minimum != null && compareVersions(app, minimum) < 0 -> "It needs app version $minimum or later (this app is $app)."
            maximum != null && compareVersions(app, maximum) > 0 -> "It is for app version $maximum or earlier (this app is $app)."
            start != null && nowMillis < start -> "It starts at ${string(runtime, "startTime")}."
            end != null && nowMillis >= end -> "It ended at ${string(runtime, "endTime")}."
            else -> null
        }
        return reason?.let { CYLConfigurationException(CYLTabBarConfigurationError.NotEligible, it) }
    }

    fun isEligible(nowMillis: Long = System.currentTimeMillis()) = eligibilityError(nowMillis) == null

    /**
     * [EN] An ISO 8601 time ("2026-12-01T00:00:00Z", "+08:00"); java.time needs API 26. [CN] ISO 8601 时间；java.time 需要 API 26。
     */
    private fun isoMillis(text: String): Long? {
        val normalized = text.replace(Regex("Z$"), "+0000").replace(Regex("([+-]\\d{2}):(\\d{2})$"), "$1$2")
        return runCatching { java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ", Locale.US).parse(normalized)?.time }.getOrNull()
    }

    private val assetsLocation: CYLResourceRoute.Location?
        get() {
            val route = string(dictionary["assets"], "baseRoute") ?: "."
            return CYLResourceRoute.locationForRoute(context, route, baseDirectory)
        }

    internal fun assetEntries(): List<Map<*, *>> = ((dictionary["assets"] as? Map<*, *>)?.get("list") as? List<*>).orEmpty()
        .filterIsInstance<Map<*, *>>().filter { string(it, "key") != null && string(it, "path") != null && allowsAndroid(it["platforms"]) }

    /**
     * [EN] An entry's file or asset path inside the assets folder only ("../" cannot leave it). [CN] 资源项在资源目录内的路径（"../" 不能跳出）。
     */
    internal fun pathOfEntry(entry: Map<*, *>): String? {
        val location = assetsLocation ?: return null
        val relative = string(entry, "path") ?: return null
        location.file?.let { folder ->
            val root = folder.canonicalFile
            val file = File(root, relative).canonicalFile
            return if (file.path.startsWith(root.path + File.separator)) file.path else null
        }
        val parts = ArrayList<String>()
        for (part in (location.assetPath.orEmpty() + "/" + relative).split('/')) {
            when (part) {
                "", "." -> Unit
                ".." -> if (parts.isEmpty()) return null else parts.removeAt(parts.size - 1)
                else -> parts.add(part)
            }
        }
        val path = parts.joinToString("/")
        val root = location.assetPath.orEmpty().split('/').filter { it.isNotEmpty() && it != "." }.let { normalize(it) }
        return if (root.isEmpty() || path.startsWith("$root/")) "${CYLResourceRoute.ASSET_PREFIX}$path" else null
    }

    private fun normalize(parts: List<String>): String {
        val out = ArrayList<String>()
        for (part in parts) if (part == "..") { if (out.isNotEmpty()) out.removeAt(out.size - 1) } else out.add(part)
        return out.joinToString("/")
    }

    private fun exists(path: String): Boolean = if (path.startsWith(CYLResourceRoute.ASSET_PREFIX)) {
        runCatching { context.assets.open(path.removePrefix(CYLResourceRoute.ASSET_PREFIX)).close(); true }.getOrDefault(false)
    } else File(path).isFile

    private fun read(path: String): ByteArray? = runCatching {
        if (path.startsWith(CYLResourceRoute.ASSET_PREFIX)) context.assets.open(path.removePrefix(CYLResourceRoute.ASSET_PREFIX)).use { it.readBytes() } else File(path).readBytes()
    }.getOrNull()

    private val defaultTheme: String? get() = string(dictionary["themes"], "default")

    /**
     * [EN] The image of `key` in `theme` (null: `themes.default`) and `state`: this theme and state, this theme's "normal",
     *      the default theme's state and "normal", then any theme. An asset is "asset:<path>", a file its path.
     * [CN] `key` 在 `theme`（null 表示 `themes.default`）与 `state` 下的图片：该主题与状态、该主题的 "normal"、默认主题的该状态与 "normal"，
     *      最后是任意主题。asset 写作 "asset:<路径>"，文件为其路径。
     */
    fun pathOfAsset(key: String, theme: String? = null, state: String? = null): String? {
        val wantedState = state?.ifEmpty { null } ?: "normal"
        val attempts = listOf(theme?.ifEmpty { null } ?: defaultTheme.orEmpty(), defaultTheme.orEmpty(), "*").flatMap { listOf(it to wantedState, it to "normal") }
        val entries = assetEntries()
        for ((attemptTheme, attemptState) in attempts) {
            for (entry in entries) {
                val themeMatches = attemptTheme == "*" || (string(entry, "theme") ?: "") == attemptTheme
                if (string(entry, "key") == key && themeMatches && (string(entry, "state") ?: "normal") == attemptState) {
                    pathOfEntry(entry)?.takeIf { exists(it) }?.let { return it }
                }
            }
        }
        return null
    }

    /**
     * [EN] The path an asset reference ("asset:home?state=selected") leads to. [CN] 资源引用对应的路径。
     */
    fun pathForAssetReference(reference: String): String? {
        if (!reference.startsWith(ASSET_REFERENCE_PREFIX)) return null
        val rest = reference.removePrefix(ASSET_REFERENCE_PREFIX)
        val query = rest.substringAfter('?', "").split('&').associate { it.substringBefore('=') to java.net.URLDecoder.decode(it.substringAfter('=', ""), "UTF-8") }
        val key = rest.substringBefore('?').ifEmpty { return null }
        return pathOfAsset(key, query["theme"], query["state"])
    }

    /**
     * [EN] Every asset exists and matches its `hash`; the first problem otherwise. [CN] 每个资源都存在并与其 `hash` 一致；否则给出第一个问题。
     */
    fun assetError(): CYLConfigurationException? {
        for (entry in assetEntries()) {
            val data = pathOfEntry(entry)?.let { read(it) }
                ?: return CYLConfigurationException(CYLTabBarConfigurationError.AssetInvalid, "Asset ${string(entry, "path")} is missing.")
            val hash = string(entry, "hash")
            if (hash != null && hash != hashOf(data)) return CYLConfigurationException(CYLTabBarConfigurationError.AssetInvalid, "Asset ${string(entry, "path")} does not match its hash.")
        }
        return null
    }

    private fun resolved(value: Any?, theme: String?): Any? {
        if (value !is String || !value.startsWith("@")) return value
        val list = (dictionary["themes"] as? Map<*, *>)?.get("list") as? Map<*, *>
        val name = value.removePrefix("@")
        return (list?.get(theme) as? Map<*, *>)?.get(name) ?: (list?.get(defaultTheme) as? Map<*, *>)?.get(name)
    }

    /**
     * [EN] An image value: an asset reference, a resource route, or an `@name` of the themes. [CN] 图片值：资源引用、资源路由或主题中的 `@名称`。
     */
    private fun imagePath(value: Any?, theme: String?): String? {
        val text = resolved(value, theme) as? String ?: return null
        if (text.isEmpty()) return null
        if (text.startsWith(ASSET_REFERENCE_PREFIX)) {
            val reference = if (theme != null && !text.contains("theme=")) text + (if ('?' in text) "&" else "?") + "theme=$theme" else text
            return pathForAssetReference(reference)?.let(::imageValue)
        }
        val location = CYLResourceRoute.locationForRoute(context, text, baseDirectory) ?: return null
        return location.file?.takeIf { it.isFile }?.path ?: location.assetPath?.takeIf { exists(CYLResourceRoute.ASSET_PREFIX + it) }
    }

    /**
     * [EN] A path `CYLTabBarController` reads: a file path, or an asset name. [CN] `CYLTabBarController` 能读取的路径：文件路径或 asset 名称。
     */
    private fun imageValue(path: String) = path.removePrefix(CYLResourceRoute.ASSET_PREFIX)

    private fun isForThisApp(item: Map<*, *>): Boolean {
        if (!allowsAndroid(item["platforms"])) return false
        val maximum = string(item, "maxAppVersion") ?: return true
        return compareVersions(appVersion(context), maximum) <= 0
    }

    /**
     * [EN] The dictionary of `CYLTabBarController`: tabs, the plus button, themes (colors and every tab's image per theme),
     *      the style and the localization; the same keys as iOS.
     * [CN] `CYLTabBarController` 的字典：Tab、PlusButton、主题（颜色与每个主题下每个 Tab 的图片）、样式与本地化；键与 iOS 相同。
     */
    fun configuration(): Map<String, Any?> {
        val tabBar = dictionary["tabBar"] as? Map<*, *> ?: emptyMap<String, Any?>()
        val themes = dictionary["themes"] as? Map<*, *>
        val themeList = themes?.get("list") as? Map<*, *> ?: emptyMap<String, Any?>()
        val configuration = LinkedHashMap<String, Any?>()
        string(tabBar, "styleType")?.let { configuration[CYLConstants.CYLTabBarControllerStyleType] = it }
        val sources = (tabBar["list"] as? List<*>).orEmpty().filterIsInstance<Map<*, *>>().filter { it["visible"] != false && isForThisApp(it) }
        val defaultName = defaultTheme ?: themeList.keys.firstOrNull() as? String
        val items = sources.map { item ->
            val key = string(item, "key").orEmpty()
            val attributes = linkedMapOf<String, Any?>(
                CYLConstants.CYLTabBarItemIdentifier to string(item, "key"),
                CYLConstants.CYLTabBarItemTitle to string(item, "text"),
                CYLConstants.CYLTabBarItemPageIdentifier to string(item, "pagePath"),
                CYLConstants.CYLTabBarItemMinimumAppVersion to string(item, "minAppVersion"),
            )
            if (themeList.isNotEmpty()) {
                attributes[CYLConstants.CYLTabBarItemImage] = "@$ASSET_NAME_PREFIX$key.normal"
                attributes[CYLConstants.CYLTabBarItemSelectedImage] = "@$ASSET_NAME_PREFIX$key.selected"
            } else {
                attributes[CYLConstants.CYLTabBarItemImage] = imagePath(item["iconPath"], null)
                attributes[CYLConstants.CYLTabBarItemSelectedImage] = imagePath(item["selectedIconPath"], null)
            }
            attributes.filterValues { it != null }
        }
        if (themeList.isNotEmpty()) {
            val barKeys = mapOf("color" to CYLConstants.CYLTabBarItemTitleColor, "selectedColor" to CYLConstants.CYLTabBarItemSelectedTitleColor, "backgroundColor" to CYLConstants.CYLTabBarBackgroundColor)
            configuration[CYLConstants.CYLTabBarControllerThemes] = themeList.keys.filterIsInstance<String>().associateWith { theme ->
                val values = LinkedHashMap<String, Any?>()
                (themeList[theme] as? Map<*, *>)?.forEach { (name, value) -> if (name is String) values[name] = value }
                barKeys.forEach { (manifestKey, key) -> resolved(tabBar[manifestKey], theme)?.let { values[key] = it } }
                for (item in sources) {
                    val key = string(item, "key").orEmpty()
                    val normal = imagePath(item["iconPath"], theme)
                    values["$ASSET_NAME_PREFIX$key.normal"] = normal
                    values["$ASSET_NAME_PREFIX$key.selected"] = imagePath(item["selectedIconPath"], theme) ?: normal
                }
                values
            }
            configuration[CYLConstants.CYLTabBarControllerThemeIdentifier] = defaultName
            string(themes, "managerName")?.let { configuration[CYLConstants.CYLTabBarControllerThemeManagerName] = it }
            string(themes, "darkMode")?.takeIf { themeList.containsKey(it) }?.let { configuration[CYLConstants.CYLTabBarControllerDarkThemeIdentifier] = it }
        }
        configuration[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] = items
        (tabBar["midButton"] as? Map<*, *>)?.takeIf { isForThisApp(it) }?.let { mid ->
            configuration[CYLConstants.CYLTabBarControllerPlusButton] = plusButton(mid, defaultName)
            configuration[CYLConstants.CYLTabBarControllerContext] = "CYLTabBarManifest:" + (identifier ?: "manifest")
        }
        (dictionary["localization"] as? Map<*, *>)?.let { configuration.putAll(localization(it)) }
        return configuration
    }

    /**
     * [EN] The plus button's attributes from `tabBar.midButton`. [CN] 由 `tabBar.midButton` 得到的 PlusButton 属性。
     */
    private fun plusButton(mid: Map<*, *>, defaultName: String?): Map<String, Any?> {
        val plus = linkedMapOf<String, Any?>(
            CYLConstants.CYLTabBarItemIdentifier to string(mid, "key"),
            CYLConstants.CYLTabBarItemTitle to string(mid, "text"),
            CYLConstants.CYLTabBarItemImage to imagePath(mid["iconPath"], defaultName),
            CYLConstants.CYLPlusButtonBackgroundImage to imagePath(mid["backgroundImage"], defaultName),
        )
        (mid["index"] as? Number)?.let { plus[CYLConstants.CYLPlusButtonIndexInTabBar] = it.toInt() }
        val width = (mid["width"] as? Number)?.toDouble()
        val height = (mid["height"] as? Number)?.toDouble()
        if (width != null && height != null) plus[CYLConstants.CYLPlusButtonSize] = "{${format(width)}, ${format(height)}}"
        if (string(mid, "action") != "callback") plus[CYLConstants.CYLTabBarItemPageIdentifier] = string(mid, "pagePath")
        return plus.filterValues { it != null }
    }

    /**
     * [EN] The localization keys from `localization`. [CN] 由 `localization` 得到的本地化键。
     */
    private fun localization(localization: Map<*, *>): Map<String, Any?> {
        val value = LinkedHashMap<String, Any?>()
        string(localization, "tableName")?.let { value[CYLConstants.CYLTabBarLocalizationTableName] = it }
        string(localization, "route")?.let { value[CYLConstants.CYLTabBarLocalizationPath] = it }
        val keys = linkedMapOf<String, Any?>(CYLConstants.CYLTabBarControllerLocalization to value)
        // [EN] A relative table route starts from the manifest's folder. [CN] 相对的字符串表路由以清单所在目录为起点。
        baseDirectory?.let { keys[CYLTabBarConfigurationLocalization.FILE_DIRECTORY_KEY] = it }
        return keys
    }

    private fun format(value: Double) = if (value == Math.floor(value)) value.toLong().toString() else value.toString()

    /**
     * [EN] A tab bar controller from [configuration]; `NoPages` when no tab finds its page. [CN] 由 [configuration] 创建 TabBarController；没有 Tab 找到页面时抛出 `NoPages`。
     */
    @Throws(CYLConfigurationException::class)
    fun tabBarController(activity: FragmentActivity): CYLTabBarController {
        val controller = CYLTabBarController.tabBarControllerWithConfiguration(activity, configuration())
        if (controller.viewControllers.isEmpty()) throw CYLConfigurationException(CYLTabBarConfigurationError.NoPages, "No tab of the manifest found its page: register the pages first (docs/Tab-Page-Registry.md).")
        return controller
    }

    /**
     * [EN] A copy whose assets are read from `folder` (a cached download). [CN] 从 `folder` 读取资源的副本（缓存的下载）。
     */
    internal fun cachedCopy(folder: File): CYLTabBarManifest {
        val assets = LinkedHashMap<String, Any?>()
        (dictionary["assets"] as? Map<*, *>)?.forEach { (key, value) -> if (key is String) assets[key] = value }
        assets["baseRoute"] = "."
        return CYLTabBarManifest(dictionary + ("assets" to assets), folder.path, context)
    }
}

/**
 * [EN] Firebase Remote Config's expression subset: device.os, app.version, device.language, percent. [CN] Firebase Remote Config 表达式的子集。
 */
internal object CYLManifestConditions {
    private val comparison = Regex("""^(device\.os|app\.version|percent)\s*(==|!=|>=|<=|>|<)\s*(.+)$""")
    private val between = Regex("""^percent\s+between\s+(\d+)\s+and\s+(\d+)$""")
    private val language = Regex("""^device\.language\s+in\s+\[(.*)]$""")

    fun holds(context: Context, expression: String?): Boolean =
        !expression.isNullOrBlank() && expression.split("&&").all { element(context, it.trim()) }

    private fun unquoted(text: String) = text.trim().removeSurrounding("'").removeSurrounding("\"")

    private fun compare(order: Int, operator: String) = when (operator) {
        "==" -> order == 0; "!=" -> order != 0; ">=" -> order >= 0; "<=" -> order <= 0; ">" -> order > 0; "<" -> order < 0; else -> false
    }

    /**
     * [EN] 0–99, the same for this install. [CN] 0–99，本次安装固定不变。
     */
    private fun percentile(context: Context): Int {
        val preferences = context.getSharedPreferences("cyl_tabbar_manifest", Context.MODE_PRIVATE)
        if (!preferences.contains("percentile")) preferences.edit().putInt("percentile", java.security.SecureRandom().nextInt(100)).apply()
        return preferences.getInt("percentile", 0)
    }

    private fun element(context: Context, text: String): Boolean {
        comparison.matchEntire(text)?.let { match ->
            val (subject, operator, raw) = match.destructured
            val value = unquoted(raw)
            return when (subject) {
                "device.os" -> (value.lowercase() == "android").let { if (operator == "==") it else if (operator == "!=") !it else false }
                "app.version" -> compare(CYLTabBarManifest.compareVersions(CYLTabBarManifest.appVersion(context), value), operator)
                else -> compare(percentile(context).compareTo(value.toIntOrNull() ?: 0), operator)
            }
        }
        between.matchEntire(text)?.let { match ->
            val p = percentile(context)
            return p >= match.groupValues[1].toInt() && p <= match.groupValues[2].toInt()
        }
        language.matchEntire(text)?.let { match ->
            val current = (CYLLocalization.language ?: Locale.getDefault().toLanguageTag()).lowercase()
            return match.groupValues[1].split(',').map { unquoted(it).lowercase() }.any { it.isNotEmpty() && (current == it || current.startsWith("$it-")) }
        }
        android.util.Log.w("CYLTabBarController", "manifest: unknown condition \"$text\" is false")
        return false
    }
}

/**
 * [EN] Downloads a manifest and its assets, checks them, keeps them in `sandbox:Caches/CYLTabBarManifest/<version>/`, and
 *      falls back as `fallback.onError` says ("previous", "embedded" → [embeddedManifestRoute], "none"), as on iOS.
 *      Callbacks on the main thread.
 * [CN] 下载清单及其资源，校验后保存到 `sandbox:Caches/CYLTabBarManifest/<version>/`，并按 `fallback.onError` 回退（"previous"、"embedded" →
 *      [embeddedManifestRoute]、"none"），与 iOS 相同。回调在主线程执行。
 */
class CYLTabBarManifestLoader(context: Context) {
    interface Delegate {
        fun shouldApplyManifest(manifest: CYLTabBarManifest, source: CYLTabBarManifest.CYLTabBarManifestSource): Boolean = true
        fun didApplyManifest(manifest: CYLTabBarManifest, source: CYLTabBarManifest.CYLTabBarManifestSource) {
            // [EN] Optional: nothing to do by default. [CN] 可选：默认不做任何事。
        }
        fun didFail(error: CYLConfigurationException, fallbackSource: CYLTabBarManifest.CYLTabBarManifestSource) {
            // [EN] Optional: nothing to do by default. [CN] 可选：默认不做任何事。
        }
    }

    private val context = context.applicationContext
    var delegate: Delegate? = null
    var embeddedManifestRoute: String? = null
    /**
     * [EN] The time the window is checked against (default: now; for tests). [CN] 检查时间段使用的时间（默认：现在；用于测试）。
     */
    var nowMillis: Long? = null

    private val cacheDirectory get() = File(context.cacheDir, "CYLTabBarManifest")

    /**
     * [EN] The newest verified manifest in the cache. [CN] 缓存中最新的已验证清单。
     */
    fun cachedManifest(): CYLTabBarManifest? {
        val versions = cacheDirectory.listFiles().orEmpty().filter { it.isDirectory && !it.name.endsWith(".download") }
            .sortedWith { a, b -> CYLTabBarManifest.compareVersions(b.name, a.name) }
        for (folder in versions) {
            val file = File(folder, "manifest.json").takeIf { it.isFile } ?: continue
            val manifest = runCatching {
                CYLTabBarManifest.manifestWithDictionary(context, CYLTabBarConfigurationParser.dictionaryWithData(file.readBytes(), CYLTabBarConfigurationFormat.JSON), folder.path)
            }.getOrNull() ?: continue
            if (manifest.isEligible(nowMillis ?: System.currentTimeMillis()) && manifest.assetError() == null) return manifest
        }
        return null
    }

    /**
     * [EN] Loads `url` (http, https or file) on a background thread. [CN] 在后台线程加载 `url`（http、https 或 file）。
     */
    fun loadManifestWithURL(url: String, completion: (CYLTabBarManifest?, CYLTabBarManifest.CYLTabBarManifestSource, CYLConfigurationException?) -> Unit) {
        Thread {
            var failed: Map<String, Any?>? = null
            var error: CYLConfigurationException? = null
            val saved = try {
                val data = URI(url).toURL().openStream().use { it.readBytes() }
                val dictionary = CYLTabBarConfigurationParser.dictionaryWithData(data, CYLTabBarConfigurationFormat.JSON)
                failed = dictionary
                val manifest = CYLTabBarManifest.manifestWithDictionary(context, dictionary, null)
                manifest.eligibilityError(nowMillis ?: System.currentTimeMillis())?.let { throw it }
                save(manifest, url)
            } catch (exception: CYLConfigurationException) {
                error = exception; null
            } catch (exception: CYLTabBarConfigurationException) {
                error = CYLConfigurationException(CYLTabBarConfigurationError.of(exception.code), exception.message.orEmpty()); null
            } catch (exception: Exception) {
                error = CYLConfigurationException(CYLTabBarConfigurationError.Network, exception.message ?: exception.toString()); null
            }
            Handler(Looper.getMainLooper()).post { finish(saved, failed, error, completion) }
        }.start()
    }

    /**
     * [EN] Downloads every asset next to the manifest, keeps the folder only when all match (Expo). [CN] 下载清单旁边的每个资源，全部一致才保留目录（Expo）。
     */
    private fun save(manifest: CYLTabBarManifest, url: String): CYLTabBarManifest {
        val version = manifest.version ?: "0"
        if ('/' in version || ".." in version) throw CYLConfigurationException(CYLTabBarConfigurationError.UnsupportedManifest, "The manifest version is not a valid folder name.")
        val folder = File(cacheDirectory, version)
        val staging = File(cacheDirectory, "$version.download").apply { deleteRecursively(); mkdirs() }
        val staged = manifest.cachedCopy(staging)
        val baseURL = CYLTabBarManifest.string(manifest.dictionary["assets"], "baseURL") ?: url.substringBeforeLast('/') + "/"
        try {
            for (entry in staged.assetEntries()) {
                val path = staged.pathOfEntry(entry) ?: throw CYLConfigurationException(CYLTabBarConfigurationError.AssetInvalid, "Asset ${CYLTabBarManifest.string(entry, "path")} is outside the assets folder.")
                val source = CYLTabBarManifest.string(entry, "url") ?: URI(baseURL).resolve(CYLTabBarManifest.string(entry, "path").orEmpty()).toString()
                val data = runCatching { URI(source).toURL().openStream().use { it.readBytes() } }.getOrNull()
                    ?: throw CYLConfigurationException(CYLTabBarConfigurationError.AssetInvalid, "Asset ${CYLTabBarManifest.string(entry, "path")} could not be downloaded.")
                File(path).apply { parentFile?.mkdirs(); writeBytes(data) }
            }
            staged.assetError()?.let { throw it }
            File(staging, "manifest.json").writeText(org.json.JSONObject(staged.dictionary).toString())
            folder.deleteRecursively()
            if (!staging.renameTo(folder)) throw CYLConfigurationException(CYLTabBarConfigurationError.AssetInvalid, "The download could not be kept.")
        } catch (exception: CYLConfigurationException) {
            staging.deleteRecursively()
            throw exception
        }
        return manifest.cachedCopy(folder)
    }

    private fun finish(remote: CYLTabBarManifest?, failed: Map<String, Any?>?, error: CYLConfigurationException?,
                       completion: (CYLTabBarManifest?, CYLTabBarManifest.CYLTabBarManifestSource, CYLConfigurationException?) -> Unit) {
        if (remote != null && delegate?.shouldApplyManifest(remote, CYLTabBarManifest.CYLTabBarManifestSource.Remote) != false) {
            delegate?.didApplyManifest(remote, CYLTabBarManifest.CYLTabBarManifestSource.Remote)
            return completion(remote, CYLTabBarManifest.CYLTabBarManifestSource.Remote, null)
        }
        val fallback = failed?.get("fallback") as? Map<*, *>
        val policy = CYLTabBarManifest.string(fallback, "onError") ?: "previous"
        val embedded = embeddedManifestRoute ?: CYLTabBarManifest.string(fallback, "embeddedRoute")
        var manifest: CYLTabBarManifest? = null
        var source = CYLTabBarManifest.CYLTabBarManifestSource.None
        if (policy == "previous") cachedManifest()?.let { manifest = it; source = CYLTabBarManifest.CYLTabBarManifestSource.Cache }
        if (manifest == null && policy != "none" && embedded != null) {
            runCatching { CYLTabBarManifest.manifestWithRoute(context, embedded) }.getOrNull()?.let { manifest = it; source = CYLTabBarManifest.CYLTabBarManifestSource.Embedded }
        }
        if (manifest != null && delegate?.shouldApplyManifest(manifest!!, source) == false) {
            manifest = null; source = CYLTabBarManifest.CYLTabBarManifestSource.None
        }
        val reason = error ?: CYLConfigurationException(CYLTabBarConfigurationError.UnsupportedManifest, "The manifest was refused.")
        delegate?.didFail(reason, source)
        manifest?.let { delegate?.didApplyManifest(it, source) }
        completion(manifest, source, reason)
    }
}
