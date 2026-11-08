// [EN] The method names are the iOS names on purpose (`cyl_…`, `tabBarController_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`、`tabBarController_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import com.cyl.tabbar.pages.TabConfiguration
import java.io.File
import java.net.HttpURLConnection

/**
 * [EN] `CYLTabBarController (CYLConfiguration)` on Android: `cyl_normalizedConfiguration`, the file and URL loaders,
 *      and the value conversions of a configuration file ("{a, b, c, d}" insets, "#RRGGBB" colors, "bold:15" fonts,
 *      "system:house" / drawable names through `CYLTabBarImageResolver`). Every iOS format is read by `CYLTabBarConfigurationParser`.
 * [CN] Android 版 `CYLTabBarController (CYLConfiguration)`：`cyl_normalizedConfiguration`、文件与 URL 加载，以及配置文件值的转换
 *      （"{a, b, c, d}" 边距、"#RRGGBB" 颜色、"bold:15" 字体、"system:house" / drawable 名称通过 `CYLTabBarImageResolver`）。格式为
 *      由 `CYLTabBarConfigurationParser` 读取 iOS 的全部格式。
 */
object CYLTabBarConfiguration {

    /** [EN] `CYLTabBarConfigurationError` codes (the iOS values). [CN] 错误码（与 iOS 相同）。 */
    enum class CYLTabBarConfigurationError(val code: Int) {
        FileNotFound(1), UnknownFormat(2), InvalidSyntax(3), NotADictionary(4), Network(5), Empty(6), TooLarge(7), TooDeep(8), NoTabs(9), MainThreadRequired(10), NoPages(11);

        companion object {
            /** [EN] The error of a parser error code (`UnsupportedFormat` is `UnknownFormat`). [CN] 解析器错误码对应的错误（`UnsupportedFormat` 即 `UnknownFormat`）。 */
            @JvmStatic
            fun of(code: CYLTabBarConfigurationErrorCode): CYLTabBarConfigurationError = entries.first { it.code == code.rawValue }
        }
    }

    class CYLConfigurationException(val error: CYLTabBarConfigurationError, message: String) : Exception(message)

    /** [EN] Resolves image names of a configuration ("system:house", a drawable name, a file path) to drawables. [CN] 把配置中的图片名称解析为 drawable。 */
    fun interface CYLTabBarImageResolver {
        fun drawable(context: Context, name: String): Drawable?
    }

    /** [EN] The default resolver: a drawable resource by name, or a file path. [CN] 默认解析器：按名称查找 drawable 资源，或文件路径。 */
    @JvmStatic
    var imageResolver: CYLTabBarImageResolver = CYLTabBarImageResolver { context, name ->
        val resourceName = name.removePrefix("system:").substringBefore('.').replace('-', '_')
        // [EN] Configuration files name images, so the resource is looked up by name. [CN] 配置文件写的是图片名称，因此按名称查找资源。
        @android.annotation.SuppressLint("DiscouragedApi")
        val id = context.resources.getIdentifier(resourceName, "drawable", context.packageName)
        when {
            id != 0 -> ContextCompat.getDrawable(context, id)
            File(name).exists() -> Drawable.createFromPath(name)
            else -> null
        }
    }

    const val maximumFileSize = 5 * 1024 * 1024

    /** [EN] `+configurationWithContentsOfFile:error:`: a file path or an asset name. [CN] 文件路径或 asset 名称。 */
    @JvmStatic
    @Throws(CYLConfigurationException::class)
    fun configurationWithContentsOfFile(context: Context, path: String): Map<String, Any?> {
        val file = File(path)
        val data = when {
            file.isFile -> {
                // [EN] The size is checked before reading, as on iOS. [CN] 与 iOS 一样，读取前先检查大小。
                if (file.length() > maximumFileSize) throw CYLConfigurationException(CYLTabBarConfigurationError.TooLarge, "$path is larger than 5 MB")
                file.readBytes()
            }
            else -> try {
                context.assets.open(path).use { readLimited(it, path) }
            } catch (error: java.io.IOException) {
                throw CYLConfigurationException(CYLTabBarConfigurationError.FileNotFound, "$path: ${error.message}")
            }
        }
        return parse(data, CYLTabBarConfigurationParser.formatForPathExtension(path.substringAfterLast('/').substringAfterLast('.', "")))
    }

    /** [EN] Reads at most 5 MB (API 23: no `readNBytes`). [CN] 最多读取 5 MB（API 23 没有 `readNBytes`）。 */
    private fun readLimited(stream: java.io.InputStream, name: String): ByteArray {
        val output = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(64 * 1024)
        while (true) {
            val count = stream.read(buffer)
            if (count < 0) break
            output.write(buffer, 0, count)
            if (output.size() > maximumFileSize) throw CYLConfigurationException(CYLTabBarConfigurationError.TooLarge, "$name is larger than 5 MB")
        }
        return output.toByteArray()
    }

    /**
     * [EN] Parses configuration data with `CYLTabBarConfigurationParser` (`Unknown`: detected from the content), then refuses
     *      what holds no tab (an HTML page, an empty dictionary), as the iOS category does.
     * [CN] 用 `CYLTabBarConfigurationParser` 解析配置数据（`Unknown` 时按内容判断），然后像 iOS 一样拒绝没有 Tab 的内容（HTML 页面、空字典）。
     */
    @JvmStatic
    @Throws(CYLConfigurationException::class)
    fun parse(data: ByteArray, format: CYLTabBarConfigurationFormat): Map<String, Any?> {
        val head = String(data, 0, minOf(data.size, 256), Charsets.UTF_8).trimStart('\uFEFF', ' ', '\n', '\r', '\t').lowercase()
        if (head.startsWith("<!doctype html") || head.startsWith("<html")) {
            throw CYLConfigurationException(CYLTabBarConfigurationError.NoTabs, "an HTML page, not a configuration")
        }
        val root = try {
            CYLTabBarConfigurationParser.dictionaryWithData(data, format)
        } catch (error: CYLTabBarConfigurationException) {
            throw CYLConfigurationException(CYLTabBarConfigurationError.of(error.code), error.message ?: error.code.name)
        }
        if (root.isEmpty()) throw CYLConfigurationException(CYLTabBarConfigurationError.NoTabs, "no tab in the configuration")
        return root
    }

    /** [EN] Parses a configuration text in one of the `tabpages` formats. [CN] 按 `tabpages` 的格式解析配置文本。 */
    @JvmStatic
    @Throws(CYLConfigurationException::class)
    fun parse(text: String, format: com.cyl.tabbar.pages.TabConfigurationFormat): Map<String, Any?> = parse(text.toByteArray(Charsets.UTF_8), when (format.name.lowercase()) {
        "json" -> CYLTabBarConfigurationFormat.JSON
        "plist", "propertylist" -> CYLTabBarConfigurationFormat.PropertyList
        "properties" -> CYLTabBarConfigurationFormat.Properties
        else -> CYLTabBarConfigurationFormat.Unknown
    })

    /** [EN] `+loadConfigurationWithURL:completion:`: downloads on a background thread (15 s timeout), completes on the main thread. [CN] 后台线程下载（15 秒超时），主线程回调。 */
    @JvmStatic
    fun loadConfigurationWithURL(url: String, completion: (Map<String, Any?>?, CYLConfigurationException?) -> Unit) =
        loadConfigurationWithURLRequest(CYLURLRequest(url), completion)

    /**
     * [EN] `NSURLRequest` for the configuration loaders: the URL, the timeout (seconds, default 15), the HTTP headers, the
     *      method and whether the HTTP cache may answer.
     * [CN] 配置加载使用的 `NSURLRequest`：URL、超时（秒，默认 15）、HTTP 头、方法，以及是否允许使用 HTTP 缓存。
     */
    data class CYLURLRequest @JvmOverloads constructor(
        val url: String,
        val timeoutInterval: Double = 15.0,
        val allHTTPHeaderFields: Map<String, String> = emptyMap(),
        val httpMethod: String = "GET",
        val allowsCache: Boolean = true,
    )

    /** [EN] `+loadConfigurationWithURLRequest:completion:`: like `loadConfigurationWithURL` with your own request; the completion runs on the main thread. [CN] 使用自己的请求加载配置；回调在主线程执行。 */
    fun loadConfigurationWithURLRequest(request: CYLURLRequest, completion: (Map<String, Any?>?, CYLConfigurationException?) -> Unit) {
        val main = Handler(Looper.getMainLooper())
        val url = request.url
        Thread {
            var result: Map<String, Any?>? = null
            var failure: CYLConfigurationException? = null
            try {
                val connection = java.net.URI(url).toURL().openConnection() as HttpURLConnection
                val timeout = (request.timeoutInterval.takeIf { it > 0 && it.isFinite() } ?: 15.0) * 1000
                connection.connectTimeout = timeout.toInt()
                connection.readTimeout = timeout.toInt()
                connection.requestMethod = request.httpMethod
                connection.useCaches = request.allowsCache
                request.allHTTPHeaderFields.forEach { (name, value) -> connection.setRequestProperty(name, value) }
                try {
                    if (connection.responseCode !in 200..299) throw CYLConfigurationException(CYLTabBarConfigurationError.Network, "HTTP ${connection.responseCode}")
                    val bytes = connection.inputStream.use { it.readBytes() }
                    if (bytes.size > maximumFileSize) throw CYLConfigurationException(CYLTabBarConfigurationError.TooLarge, "the response is larger than 5 MB")
                    // [EN] The format: the URL's extension, then the HTTP Content-Type, then the content (the parser sniffs it). [CN] 格式：URL 扩展名，然后 HTTP Content-Type，然后内容（由解析器判断）。
                    val byExtension = CYLTabBarConfigurationParser.formatForPathExtension(java.net.URI(url).path.orEmpty().substringAfterLast('/').substringAfterLast('.', ""))
                    val format = if (byExtension != CYLTabBarConfigurationFormat.Unknown) byExtension else CYLTabBarConfigurationParser.formatForMIMEType(connection.contentType)
                    result = parse(bytes, format)
                } finally {
                    connection.disconnect()
                }
            } catch (error: CYLConfigurationException) {
                failure = error
            } catch (error: Exception) {
                failure = CYLConfigurationException(CYLTabBarConfigurationError.Network, error.message ?: "network error")
            }
            main.post { completion(result, failure) }
        }.start()
    }

    // MARK: - Value conversions 值转换

    /** [EN] "{a, b, c, d}", [a, b, c, d] or {top:, left:, bottom:, right:}. [CN] 边距的三种写法。 */
    @JvmStatic
    fun edgeInsetsValue(value: Any?): CYLEdgeInsets? {
        val numbers = numbers(value, 4, listOf("top", "left", "bottom", "right")) ?: return null
        return CYLEdgeInsets(numbers[0], numbers[1], numbers[2], numbers[3])
    }

    @JvmStatic
    fun offsetValue(value: Any?): CYLOffset? = numbers(value, 2, listOf("horizontal", "vertical"))?.let { CYLOffset(it[0], it[1]) }

    @JvmStatic
    fun sizeValue(value: Any?): CYLSize? = numbers(value, 2, listOf("width", "height"))?.let { CYLSize(it[0], it[1]) }

    /**
     * [EN] A tap animation name ("none", "scale", "zoomIn", "bounce", "bounceWithFireworks", "rotation", "flip", "fume") or
     *      its number, as `CYLTabBarControllerTabButtonTapAnimation` on iOS; null when it is neither.
     * [CN] 点击动画名称（"none"、"scale"、"zoomIn"、"bounce"、"bounceWithFireworks"、"rotation"、"flip"、"fume"）或其数字，与 iOS 的
     *      `CYLTabBarControllerTabButtonTapAnimation` 相同；两者都不是时返回 null。
     */
    @JvmStatic
    fun tapAnimationValue(value: Any?): CYLEnums.CYLTabButtonTapAnimationType? {
        val names = listOf("none", "scale", "zoomin", "bounce", "bouncewithfireworks", "rotation", "flip", "fume")
        val index = when (value) {
            is String -> names.indexOf(value.trim().lowercase())
            is Number -> value.toInt().takeIf { it in names.indices } ?: -1
            else -> -1
        }
        return CYLEnums.CYLTabButtonTapAnimationType.values().firstOrNull { it.rawValue == index && index >= 0 }
    }

    /** [EN] "#RGB", "#RRGGBB" or "#RRGGBBAA" (the iOS order). [CN] 三种十六进制写法（与 iOS 相同的顺序）。 */
    @JvmStatic
    fun colorValue(value: Any?): Int? {
        val text = (value as? String)?.trim()?.removePrefix("#") ?: return value as? Int
        return try {
            when (text.length) {
                3 -> Color.parseColor("#" + text.map { "$it$it" }.joinToString(""))
                6 -> Color.parseColor("#$text")
                8 -> Color.parseColor("#" + text.substring(6, 8) + text.substring(0, 6))
                else -> null
            }
        } catch (error: IllegalArgumentException) {
            null
        }
    }

    private fun numbers(value: Any?, count: Int, keys: List<String>): List<Float>? {
        val parts: List<Any?> = when (value) {
            is String -> value.trim().removePrefix("{").removeSuffix("}").split(",", " ").filter { it.isNotBlank() }
            is List<*> -> value
            is Map<*, *> -> keys.map { key -> value.entries.firstOrNull { it.key.toString().equals(key, true) }?.value }
            else -> return null
        }
        if (parts.size != count) return null
        val numbers = parts.mapNotNull { part -> if (part is Number) part.toFloat() else part.toString().trim().toFloatOrNull() }
        return if (numbers.size == count && numbers.all { it.isFinite() }) numbers else null
    }

    /** [EN] A BOOL: true / false, yes / no, 1 / 0. [CN] 布尔值。 */
    @JvmStatic
    fun boolValue(value: Any?): Boolean? = when (value) {
        is Boolean -> value
        is Number -> value.toInt() != 0
        is String -> when (value.trim().lowercase()) { "true", "yes", "1" -> true; "false", "no", "0" -> false; else -> null }
        else -> null
    }

    /**
     * [EN] `+cyl_normalizedConfiguration:`: the iOS normalization that applies on Android: null values removed, a
     *      single tab dictionary wrapped in a list, non-dictionary tabs replaced by placeholders, platforms / minimum
     *      version exclusion (marked with `_CYLTabBarItemExcluded`), duplicate identifiers renamed, the style name,
     *      the lookup order and the automatic flag. Values stay as given; `CYLTabBarController` converts them.
     * [CN] Android 上适用的 iOS 规范化：去掉 null、单个 Tab 字典包装为数组、非字典 Tab 替换为占位、平台 / 最低版本排除（标记
     *      `_CYLTabBarItemExcluded`）、重复标识重命名、样式名称、查找顺序与自动注册开关。值原样保留，由 `CYLTabBarController` 转换。
     */
    @JvmStatic
    @JvmOverloads
    fun cyl_normalizedConfiguration(configuration: Map<String, Any?>, platform: String = "android", appVersion: String? = null, darkMode: Boolean = false): Map<String, Any?> {
        val normalized = LinkedHashMap<String, Any?>()
        for ((key, value) in configuration) if (value != null) normalized[key] = value
        // [EN] Skins: the "@name" values of the tabs take the first skin's values (`CYLTabBarConfigurationTheme`). [CN] 皮肤：Tab 中的 "@name" 值取首个皮肤的值（`CYLTabBarConfigurationTheme`）。
        val themes = if (normalized.containsKey(CYLConstants.CYLTabBarControllerThemes)) CYLConfigurationThemes.info(normalized, darkMode) else null
        val initialValues = themes?.values?.get(themes.initial)
        val itemReferences = ArrayList<Map<String, String>>()
        val items: List<Any?> = when (val value = normalized[CYLConstants.CYLTabBarControllerTabBarItemsAttributes]) {
            is List<*> -> value
            is Map<*, *> -> listOf(value)
            null -> emptyList()
            else -> emptyList()
        }
        val seen = HashSet<String>()
        normalized[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] = items.map { item ->
            val references = LinkedHashMap<String, String>()
            itemReferences += references
            val raw = (item as? Map<*, *>)?.entries?.associate { it.key.toString() to it.value } ?: return@map emptyMap<String, Any?>()
            val attributes = (if (initialValues != null) CYLConfigurationThemes.resolve(raw, initialValues, references) else raw).toMutableMap()
            val tab = com.cyl.tabbar.pages.TabItem(attributes)
            val reason = TabConfiguration.exclusionReason(tab, platform, appVersion)
            if (reason != null) {
                return@map mapOf(EXCLUDED_KEY to true, EXCLUSION_REASON_KEY to reason,
                    CYLConstants.CYLTabBarItemTitle to attributes[CYLConstants.CYLTabBarItemTitle],
                    CYLConstants.CYLTabBarItemIdentifier to attributes[CYLConstants.CYLTabBarItemIdentifier],
                    CYLConstants.CYLTabBarItemPageIdentifier to attributes[CYLConstants.CYLTabBarItemPageIdentifier])
            }
            val identifier = attributes[CYLConstants.CYLTabBarItemIdentifier] as? String
            if (identifier != null) {
                var unique: String = identifier
                var n = 2
                while (!seen.add(unique)) {
                    unique = "$identifier-$n"
                    n++
                }
                attributes[CYLConstants.CYLTabBarItemIdentifier] = unique
            }
            attributes
        }
        normalized[CYLConstants.CYLTabBarControllerPageLookupOrder] =
            TabConfiguration.lookupOrder(normalized[CYLConstants.CYLTabBarControllerPageLookupOrder], normalized[CYLConstants.CYLTabBarControllerAutomaticPageRegistration])
        (normalized[CYLConstants.CYLTabBarControllerStyleType] as? String)?.let { normalized[CYLConstants.CYLTabBarControllerStyleType] = CYLEnums.CYLTabBarStyleType.fromName(it) }
        if (themes != null) {
            @Suppress("UNCHECKED_CAST")
            CYLConfigurationThemes.finish(themes, normalized[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] as List<Map<String, Any?>>, itemReferences)
            normalized[CYLConfigurationThemes.INFO_KEY] = themes
        }
        return normalized
    }

    const val EXCLUDED_KEY = "_CYLTabBarItemExcluded"
    const val EXCLUSION_REASON_KEY = "_CYLTabBarItemExclusionReason"
}
