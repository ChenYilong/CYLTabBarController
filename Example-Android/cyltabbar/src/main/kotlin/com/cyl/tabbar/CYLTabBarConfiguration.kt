package com.cyl.tabbar

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import com.cyl.tabbar.pages.TabConfiguration
import com.cyl.tabbar.pages.TabConfigurationFormats
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

/**
 * [EN] `CYLTabBarController (CYLConfiguration)` on Android: `cyl_normalizedConfiguration`, the file and URL loaders,
 *      and the value conversions of a configuration file ("{a, b, c, d}" insets, "#RRGGBB" colors, "bold:15" fonts,
 *      "system:house" / drawable names through `CYLTabBarImageResolver`). The formats are the ones `TabConfigurationFormats`
 *      reads (JSON, XML plist, .properties); the iOS parser's other formats give `CYLTabBarConfigurationError.UnknownFormat`.
 * [CN] Android 版 `CYLTabBarController (CYLConfiguration)`：`cyl_normalizedConfiguration`、文件与 URL 加载，以及配置文件值的转换
 *      （"{a, b, c, d}" 边距、"#RRGGBB" 颜色、"bold:15" 字体、"system:house" / drawable 名称通过 `CYLTabBarImageResolver`）。格式为
 *      `TabConfigurationFormats` 支持的格式（JSON、XML plist、.properties）；iOS 解析器的其他格式返回 `CYLTabBarConfigurationError.UnknownFormat`。
 */
object CYLTabBarConfiguration {

    /** [EN] `CYLTabBarConfigurationError` codes (the iOS values). [CN] 错误码（与 iOS 相同）。 */
    enum class CYLTabBarConfigurationError(val code: Int) {
        UnknownFormat(1), InvalidSyntax(2), NotADictionary(3), FileNotFound(4), Network(5), Empty(6), TooLarge(7), TooDeep(8), NoTabs(9), MainThreadRequired(10), NoPages(11)
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
        val text = when {
            file.isFile -> {
                if (file.length() > maximumFileSize) throw CYLConfigurationException(CYLTabBarConfigurationError.TooLarge, "$path is larger than 5 MB")
                file.readText()
            }
            else -> try {
                context.assets.open(path).bufferedReader().use { it.readText() }
            } catch (error: java.io.IOException) {
                throw CYLConfigurationException(CYLTabBarConfigurationError.FileNotFound, "$path: ${error.message}")
            }
        }
        return parse(text, TabConfigurationFormats.formatOf(path) ?: TabConfigurationFormats.detect(text))
    }

    /** [EN] Parses a configuration text; `format` null detects it from the content. [CN] 解析配置文本；`format` 为 null 时按内容判断。 */
    @JvmStatic
    @Throws(CYLConfigurationException::class)
    fun parse(text: String, format: com.cyl.tabbar.pages.TabConfigurationFormat): Map<String, Any?> {
        if (text.isBlank()) throw CYLConfigurationException(CYLTabBarConfigurationError.Empty, "the configuration is empty")
        if (text.trimStart().startsWith("<") && !text.trimStart().startsWith("<?xml") && !text.trimStart().startsWith("<plist")) {
            throw CYLConfigurationException(CYLTabBarConfigurationError.NoTabs, "an HTML page, not a configuration")
        }
        val root = try {
            TabConfigurationFormats.parse(text, format)
        } catch (error: Exception) {
            throw CYLConfigurationException(CYLTabBarConfigurationError.InvalidSyntax, error.message ?: "invalid syntax")
        }
        if (root.isEmpty()) throw CYLConfigurationException(CYLTabBarConfigurationError.NoTabs, "no tab in the configuration")
        return root
    }

    /** [EN] `+loadConfigurationWithURL:completion:`: downloads on a background thread (15 s timeout), completes on the main thread. [CN] 后台线程下载（15 秒超时），主线程回调。 */
    @JvmStatic
    fun loadConfigurationWithURL(url: String, completion: (Map<String, Any?>?, CYLConfigurationException?) -> Unit) {
        val main = Handler(Looper.getMainLooper())
        Thread {
            var result: Map<String, Any?>? = null
            var failure: CYLConfigurationException? = null
            try {
                val connection = URL(url).openConnection() as HttpURLConnection
                connection.connectTimeout = 15_000
                connection.readTimeout = 15_000
                try {
                    if (connection.responseCode !in 200..299) throw CYLConfigurationException(CYLTabBarConfigurationError.Network, "HTTP ${connection.responseCode}")
                    val bytes = connection.inputStream.use { it.readBytes() }
                    if (bytes.size > maximumFileSize) throw CYLConfigurationException(CYLTabBarConfigurationError.TooLarge, "the response is larger than 5 MB")
                    val downloaded = String(bytes, Charsets.UTF_8)
                    result = parse(downloaded, TabConfigurationFormats.formatOf(url) ?: TabConfigurationFormats.detect(downloaded))
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
        val numbers = parts.map { (it as? Number)?.toFloat() ?: it.toString().trim().toFloatOrNull() ?: return null }
        return if (numbers.all { it.isFinite() }) numbers else null
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
    fun cyl_normalizedConfiguration(configuration: Map<String, Any?>, platform: String = "android", appVersion: String? = null): Map<String, Any?> {
        val normalized = LinkedHashMap<String, Any?>()
        for ((key, value) in configuration) if (value != null) normalized[key] = value
        val items: List<Any?> = when (val value = normalized[CYLConstants.CYLTabBarControllerTabBarItemsAttributes]) {
            is List<*> -> value
            is Map<*, *> -> listOf(value)
            null -> emptyList()
            else -> emptyList()
        }
        val seen = HashSet<String>()
        normalized[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] = items.map { item ->
            val attributes = (item as? Map<*, *>)?.entries?.associate { it.key.toString() to it.value }?.toMutableMap() ?: return@map emptyMap<String, Any?>()
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
        return normalized
    }

    const val EXCLUDED_KEY = "_CYLTabBarItemExcluded"
    const val EXCLUSION_REASON_KEY = "_CYLTabBarItemExclusionReason"
}
