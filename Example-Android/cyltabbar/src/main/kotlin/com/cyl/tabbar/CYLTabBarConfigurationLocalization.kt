package com.cyl.tabbar

import android.content.Context
import java.io.File
import java.util.Locale

/**
 * [EN] `CYLTabBarControllerLocalization` on Android, as on iOS (docs/Configuration-File.md, "Localization"): the texts of a
 *      configuration (`CYLTabBarItemTitle`, `CYLTabBarItemSelectedTitle`, `CYLTabBarItemAccessibilityLabel`,
 *      `CYLTabBarItemAccessibilityHint`, at any depth) are keys looked up in `<language>.lproj/<table>.strings`, the same files
 *      iOS reads. The tables are always the app's: in its assets (`CYLTabBarLocalizationBundleName` names a folder there,
 *      default the assets root) or at `CYLTabBarLocalizationPath`, a location route (docs/Configuration-Localization.md):
 *      "bundle:<path>" (the assets), "sandbox:Documents/…" (`filesDir`), "sandbox:Caches/…" or "sandbox:tmp/…" (`cacheDir`),
 *      a "file:" URL, an absolute path, "~/…" (the app's data folder), or a path relative to the configuration file (or
 *      to the asset it came from). A key without a translation stays as it is.
 * [CN] Android 版 `CYLTabBarControllerLocalization`，与 iOS 相同（docs/Configuration-File.md「本地化」）：配置中任意层级的文本
 *      （`CYLTabBarItemTitle`、`CYLTabBarItemSelectedTitle`、`CYLTabBarItemAccessibilityLabel`、`CYLTabBarItemAccessibilityHint`）作为键，在
 *      `<语言>.lproj/<表名>.strings` 中查找，与 iOS 读取同样的文件。字符串表总是属于 App：位于 assets 中（`CYLTabBarLocalizationBundleName` 指定其中
 *      的文件夹，默认 assets 根目录），或位于 `CYLTabBarLocalizationPath`：绝对路径、"file:" URL、"~/…"（App 数据目录）、"sandbox:Documents/…"
 *      （`filesDir`）、"sandbox:Caches/…" 或 "sandbox:tmp/…"（`cacheDir`），或相对于配置文件（或其所在 asset）的路径。没有译文的键保持原样。
 */
object CYLTabBarConfigurationLocalization {

    /** [EN] Private: where the configuration came from, set by the file loader ("asset:<folder>" or a folder path). [CN] 私有：配置的来源，由文件加载方法设置（"asset:<目录>" 或目录路径）。 */
    const val FILE_DIRECTORY_KEY = "_CYLTabBarControllerConfigurationFileDirectory"
    private const val ASSET_PREFIX = "asset:"

    private val textKeys = setOf(
        CYLConstants.CYLTabBarItemTitle, CYLConstants.CYLTabBarItemSelectedTitle,
        CYLConstants.CYLTabBarItemAccessibilityLabel, CYLConstants.CYLTabBarItemAccessibilityHint,
    )

    /** [EN] A folder of tables: in the assets or on disk. [CN] 字符串表所在目录：位于 assets 或磁盘上。 */
    private class Location(val assetFolder: String?, val folder: File?)

    /** [EN] `configuration` with its texts translated, without the private source key. [CN] 翻译文本后的配置，并移除私有来源键。 */
    @JvmStatic
    fun localize(context: Context, configuration: Map<String, Any?>): Map<String, Any?> {
        val source = configuration[FILE_DIRECTORY_KEY] as? String
        val plain = if (source != null) configuration - FILE_DIRECTORY_KEY else configuration
        val value = plain[CYLConstants.CYLTabBarControllerLocalization] ?: return plain
        val (location, table) = location(context, value, source) ?: return plain
        val strings = candidates(locale(context)).firstNotNullOfOrNull { read(context, location, "$it.lproj/$table.strings") }
        if (strings == null) {
            android.util.Log.w("CYLTabBarController", "configuration: no $table.strings for ${locale(context)}; the texts stay as they are")
            return plain
        }
        @Suppress("UNCHECKED_CAST")
        return translate(plain, strings) as Map<String, Any?>
    }

    /** [EN] The app's language (API 23 too, through `ConfigurationCompat`). [CN] App 的语言（通过 `ConfigurationCompat`，也支持 API 23）。 */
    private fun locale(context: Context): Locale =
        androidx.core.os.ConfigurationCompat.getLocales(context.resources.configuration)[0] ?: Locale.getDefault()

    /** [EN] The `.lproj` names to try, as on iOS: the language, its script, its code, "Base", "en". [CN] 依次尝试的 `.lproj` 名称，与 iOS 相同：语言、其文字、语言代码、"Base"、"en"。 */
    internal fun candidates(locale: Locale): List<String> {
        val language = locale.language.ifEmpty { "en" }
        val script = locale.script.ifEmpty {
            if (language == "zh") (if (locale.country in setOf("TW", "HK", "MO")) "Hant" else "Hans") else ""
        }
        return listOfNotNull(
            if (script.isNotEmpty()) "$language-$script" else null,
            if (locale.country.isNotEmpty() && language != "zh") "$language-${locale.country}" else null,
            language, "Base", "en",
        ).distinct()
    }

    private fun location(context: Context, value: Any?, source: String?): Pair<Location, String>? {
        var table = "Localizable"
        val assetsRoot = Location("", null)
        when (value) {
            is Boolean -> return if (value) assetsRoot to table else null
            is String -> {
                val text = value.trim()
                return when (text.lowercase()) {
                    "true", "yes" -> assetsRoot to table
                    "", "false", "no" -> null
                    else -> assetsRoot to text
                }
            }
            is Map<*, *> -> {
                (value[CYLConstants.CYLTabBarLocalizationTableName] as? String)?.takeIf { it.isNotBlank() }?.let { table = it.removeSuffix(".strings") }
                (value[CYLConstants.CYLTabBarLocalizationPath] as? String)?.takeIf { it.isNotBlank() }?.let { return resolve(context, it, source) to table }
                val bundle = (value[CYLConstants.CYLTabBarLocalizationBundleName] as? String)?.takeIf { it.isNotBlank() && it != "main" }
                    ?: return assetsRoot to table
                return Location(if (bundle.endsWith(".bundle")) bundle else "$bundle.bundle", null) to table
            }
            else -> {
                android.util.Log.w("CYLTabBarController", "configuration: invalid ${CYLConstants.CYLTabBarControllerLocalization}: $value")
                return null
            }
        }
    }

    /** [EN] `CYLTabBarLocalizationPath` to a folder. [CN] 把 `CYLTabBarLocalizationPath` 解析为目录。 */
    private fun resolve(context: Context, path: String, source: String?): Location {
        val dataFolder = context.filesDir.parentFile ?: context.filesDir
        // [EN] The location routes (docs/Configuration-Localization.md), in this order, as on iOS. [CN] 位置路由
        //      （docs/Configuration-Localization.md），与 iOS 顺序相同。
        return when {
            path.startsWith("bundle:") -> Location(path.removePrefix("bundle:").trim('/'), null)
            path.startsWith("file:") -> Location(null, File(java.net.URI(path).path ?: path.removePrefix("file:")))
            path.startsWith("sandbox:") -> {
                val rest = path.removePrefix("sandbox:").trimStart('/')
                val first = rest.substringBefore('/')
                val remainder = if ('/' in rest) rest.substringAfter('/') else ""
                when (first) {
                    "Documents" -> Location(null, File(context.filesDir, remainder))
                    "Caches", "tmp" -> Location(null, File(context.cacheDir, remainder))
                    else -> Location(null, File(dataFolder, rest))
                }
            }
            path.startsWith("~/") -> Location(null, File(dataFolder, path.removePrefix("~/")))
            path.startsWith("/") -> Location(null, File(path))
            source != null && source.startsWith(ASSET_PREFIX) -> Location(join(source.removePrefix(ASSET_PREFIX), path), null)
            source != null -> Location(null, File(source, path))
            else -> Location(path.trimEnd('/'), null)
        }
    }

    private fun join(folder: String, path: String): String = listOf(folder, path).filter { it.isNotEmpty() }.joinToString("/").trimEnd('/')

    private fun read(context: Context, location: Location, relative: String): Map<String, String>? {
        val bytes = try {
            when {
                location.folder != null -> File(location.folder, relative).takeIf { it.isFile }?.readBytes()
                else -> context.assets.open(join(location.assetFolder ?: "", relative)).use { it.readBytes() }
            }
        } catch (error: java.io.IOException) {
            null
        } ?: return null
        return parseStrings(bytes)
    }

    /**
     * [EN] A `.strings` file: `"key" = "value";` lines, `//` and `/* */` comments, UTF-8 or UTF-16 (with its byte order mark),
     *      and the escapes `\"`, `\\`, `\n`, `\t`, `\r` and `\U`/`\u` followed by four hex digits.
     * [CN] `.strings` 文件：`"键" = "值";` 行、`//` 与 `/* */` 注释、UTF-8 或 UTF-16（带字节顺序标记），以及转义 `\"`、`\\`、`\n`、`\t`、`\r`
     *      与后跟四位十六进制数的 `\U`/`\u`。
     */
    internal fun parseStrings(bytes: ByteArray): Map<String, String> {
        val text = when {
            bytes.size >= 2 && bytes[0] == 0xFF.toByte() && bytes[1] == 0xFE.toByte() -> String(bytes, 2, bytes.size - 2, Charsets.UTF_16LE)
            bytes.size >= 2 && bytes[0] == 0xFE.toByte() && bytes[1] == 0xFF.toByte() -> String(bytes, 2, bytes.size - 2, Charsets.UTF_16BE)
            bytes.size >= 3 && bytes[0] == 0xEF.toByte() && bytes[1] == 0xBB.toByte() && bytes[2] == 0xBF.toByte() -> String(bytes, 3, bytes.size - 3, Charsets.UTF_8)
            else -> String(bytes, Charsets.UTF_8)
        }
        val result = LinkedHashMap<String, String>()
        var index = 0
        fun skip() {
            while (index < text.length) {
                when {
                    text[index].isWhitespace() -> index++
                    text.startsWith("//", index) -> index = text.indexOf('\n', index).let { if (it < 0) text.length else it + 1 }
                    text.startsWith("/*", index) -> index = text.indexOf("*/", index + 2).let { if (it < 0) text.length else it + 2 }
                    else -> return
                }
            }
        }
        fun quoted(): String? {
            if (index >= text.length || text[index] != '"') return null
            index++
            val builder = StringBuilder()
            while (index < text.length && text[index] != '"') {
                val c = text[index++]
                if (c != '\\' || index >= text.length) { builder.append(c); continue }
                when (val e = text[index++]) {
                    'n' -> builder.append('\n')
                    't' -> builder.append('\t')
                    'r' -> builder.append('\r')
                    'u', 'U' -> {
                        val hex = text.substring(index, minOf(index + 4, text.length))
                        hex.toIntOrNull(16)?.let { builder.append(it.toChar()); index += 4 } ?: builder.append(e)
                    }
                    else -> builder.append(e)
                }
            }
            index++
            return builder.toString()
        }
        while (true) {
            skip()
            val key = quoted() ?: break
            skip()
            if (index < text.length && text[index] == '=') { index++; skip() } else break
            val value = quoted() ?: break
            result[key] = value
            skip()
            if (index < text.length && text[index] == ';') index++
        }
        return result
    }

    private fun translate(value: Any?, strings: Map<String, String>): Any? = when (value) {
        is Map<*, *> -> value.entries.associate { (key, item) ->
            key to if (key in textKeys && item is String) (strings[item] ?: item) else translate(item, strings)
        }
        is List<*> -> value.map { translate(it, strings) }
        else -> value
    }
}
