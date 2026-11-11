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

    /**
     * [EN] Private: where the configuration came from, set by the file loader ("asset:<folder>" or a folder path). [CN] 私有：配置的来源，由文件加载方法设置（"asset:<目录>" 或目录路径）。
     */
    const val FILE_DIRECTORY_KEY = "_CYLTabBarControllerConfigurationFileDirectory"

    private val textKeys = setOf(
        CYLConstants.CYLTabBarItemTitle, CYLConstants.CYLTabBarItemSelectedTitle,
        CYLConstants.CYLTabBarItemAccessibilityLabel, CYLConstants.CYLTabBarItemAccessibilityHint,
    )

    /**
     * [EN] A folder of tables: in the assets or on disk. [CN] 字符串表所在目录：位于 assets 或磁盘上。
     */
    private class Location(val assetFolder: String?, val folder: File?)

    /**
     * [EN] `configuration` with its texts translated, without the private source key. [CN] 翻译文本后的配置，并移除私有来源键。
     */
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

    /**
     * [EN] The app's language (API 23 too, through `ConfigurationCompat`). [CN] App 的语言（通过 `ConfigurationCompat`，也支持 API 23）。
     */
    private fun locale(context: Context): Locale =
        androidx.core.os.ConfigurationCompat.getLocales(context.resources.configuration)[0] ?: Locale.getDefault()

    /**
     * [EN] The `.lproj` names to try, as on iOS: the language, its script, its code, "Base", "en". [CN] 依次尝试的 `.lproj` 名称，与 iOS 相同：语言、其文字、语言代码、"Base"、"en"。
     */
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

    private val assetsRoot = Location("", null)

    private fun location(context: Context, value: Any?, source: String?): Pair<Location, String>? = when (value) {
        is Boolean -> if (value) assetsRoot to DEFAULT_TABLE else null
        is String -> when (value.trim().lowercase()) {
            "true", "yes" -> assetsRoot to DEFAULT_TABLE
            "", "false", "no" -> null
            else -> assetsRoot to value.trim()
        }
        is Map<*, *> -> dictionaryLocation(context, value, source)
        else -> {
            android.util.Log.w("CYLTabBarController", "configuration: invalid ${CYLConstants.CYLTabBarControllerLocalization}: $value")
            null
        }
    }

    /**
     * [EN] The dictionary form: a table name, then a path or a bundle name. [CN] 字典形式：表名，然后是路径或 bundle 名称。
     */
    private fun dictionaryLocation(context: Context, value: Map<*, *>, source: String?): Pair<Location, String> {
        val table = (value[CYLConstants.CYLTabBarLocalizationTableName] as? String)?.takeIf { it.isNotBlank() }?.removeSuffix(".strings") ?: DEFAULT_TABLE
        val path = (value[CYLConstants.CYLTabBarLocalizationPath] as? String)?.takeIf { it.isNotBlank() }
        if (path != null) return resolve(context, path, source) to table
        val bundle = (value[CYLConstants.CYLTabBarLocalizationBundleName] as? String)?.takeIf { it.isNotBlank() && it != "main" }
            ?: return assetsRoot to table
        return Location(if (bundle.endsWith(".bundle")) bundle else "$bundle.bundle", null) to table
    }

    private const val DEFAULT_TABLE = "Localizable"

    /**
     * [EN] `CYLTabBarLocalizationPath`, a location route (`CYLResourceRoute`), to a folder. [CN] 把位置路由 `CYLTabBarLocalizationPath`（`CYLResourceRoute`）解析为目录。
     */
    private fun resolve(context: Context, path: String, source: String?): Location {
        val location = CYLResourceRoute.locationForRoute(context, path, source) ?: return assetsRoot
        return Location(location.assetPath?.trimEnd('/'), location.file)
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
    internal fun parseStrings(bytes: ByteArray): Map<String, String> = CYLStringsScanner(decodeStrings(bytes)).entries()

    /**
     * [EN] The text of a `.strings` file, by its byte order mark (UTF-8 without one). [CN] 按字节顺序标记解码 `.strings` 文件（没有标记时为 UTF-8）。
     */
    private fun decodeStrings(bytes: ByteArray): String {
        fun startsWith(vararg mark: Int) = bytes.size >= mark.size && mark.indices.all { bytes[it] == mark[it].toByte() }
        return when {
            startsWith(0xFF, 0xFE) -> String(bytes, 2, bytes.size - 2, Charsets.UTF_16LE)
            startsWith(0xFE, 0xFF) -> String(bytes, 2, bytes.size - 2, Charsets.UTF_16BE)
            startsWith(0xEF, 0xBB, 0xBF) -> String(bytes, 3, bytes.size - 3, Charsets.UTF_8)
            else -> String(bytes, Charsets.UTF_8)
        }
    }

    /**
     * [EN] Reads `"key" = "value";` entries from the text of a `.strings` file. [CN] 从 `.strings` 文件的文本中读取 `"键" = "值";` 条目。
     */
    private class CYLStringsScanner(private val text: String) {
        private var index = 0

        fun entries(): Map<String, String> {
            val result = LinkedHashMap<String, String>()
            while (true) {
                skipSpacesAndComments()
                val key = quoted() ?: break
                if (!consume('=')) break
                val value = quoted() ?: break
                result[key] = value
                consume(';')
            }
            return result
        }

        /**
         * [EN] Skips spaces and comments, then takes `char` when it comes next. [CN] 跳过空白与注释，下一个字符为 `char` 时读取它。
         */
        private fun consume(char: Char): Boolean {
            skipSpacesAndComments()
            if (index >= text.length || text[index] != char) return false
            index++
            skipSpacesAndComments()
            return true
        }

        private fun skipSpacesAndComments() {
            while (index < text.length) {
                index = when {
                    text[index].isWhitespace() -> index + 1
                    text.startsWith("//", index) -> text.indexOf('\n', index).let { if (it < 0) text.length else it + 1 }
                    text.startsWith("/*", index) -> text.indexOf("*/", index + 2).let { if (it < 0) text.length else it + 2 }
                    else -> return
                }
            }
        }

        private fun quoted(): String? {
            if (index >= text.length || text[index] != '"') return null
            index++
            val builder = StringBuilder()
            while (index < text.length && text[index] != '"') {
                val char = text[index++]
                if (char == '\\' && index < text.length) appendEscape(builder) else builder.append(char)
            }
            index++
            return builder.toString()
        }

        /**
         * [EN] The character after a backslash: `\n`, `\t`, `\r`, `\U`/`\u` + four hex digits, or itself. [CN] 反斜杠后的字符。
         */
        private fun appendEscape(builder: StringBuilder) {
            when (val escaped = text[index++]) {
                'n' -> builder.append('\n')
                't' -> builder.append('\t')
                'r' -> builder.append('\r')
                'u', 'U' -> {
                    val code = text.substring(index, minOf(index + 4, text.length)).toIntOrNull(16)
                    if (code != null) { builder.append(code.toChar()); index += 4 } else builder.append(escaped)
                }
                else -> builder.append(escaped)
            }
        }
    }

    private fun translate(value: Any?, strings: Map<String, String>): Any? = when (value) {
        is Map<*, *> -> value.entries.associate { (key, item) ->
            key to if (key in textKeys && item is String) (strings[item] ?: item) else translate(item, strings)
        }
        is List<*> -> value.map { translate(it, strings) }
        else -> value
    }
}
