// [EN] The names are the iOS names on purpose (`CYLTabBarConfigurationParser`), see docs/Android-API-Map.md. [CN] 名称刻意沿用 iOS 名称，见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import java.io.ByteArrayOutputStream
import java.io.File
import java.io.StringReader
import java.nio.ByteBuffer
import java.nio.charset.CharacterCodingException
import java.nio.charset.Charset
import java.nio.charset.CodingErrorAction
import javax.xml.XMLConstants
import javax.xml.parsers.DocumentBuilderFactory
import javax.xml.parsers.SAXParserFactory
import org.w3c.dom.Element
import org.w3c.dom.Node
import org.xml.sax.Attributes
import org.xml.sax.InputSource
import org.xml.sax.SAXException
import org.xml.sax.helpers.DefaultHandler

/*
 * [EN] `CYLTabBarConfigurationParser` for Android, translated from CYLTabBarConfigurationParser.m: every format of the iOS
 *      library (JSON, JSON5 / JSONC, property lists in XML, binary and OpenStep form, .strings, YAML, TOML, INI,
 *      .properties / .env, XML, Protocol Buffers text and binary), with the same detection order, limits, error codes
 *      and values. Plain JVM code (no Android API), so it runs in JVM tests too.
 *      Values: strings, booleans, `Long` for integers, `Double` for decimals, `Map` for dictionaries, `List` for arrays;
 *      `null` stands for the iOS `NSNull`; a property list's `<date>` is a `java.util.Date` and its `<data>` a `ByteArray`.
 * [CN] Android 版 `CYLTabBarConfigurationParser`，由 CYLTabBarConfigurationParser.m 翻译：支持 iOS 库的全部格式（JSON、JSON5 / JSONC、
 *      XML / 二进制 / OpenStep 属性列表、.strings、YAML、TOML、INI、.properties / .env、XML、Protocol Buffers 文本与二进制），检测顺序、限制、
 *      错误码与值都与 iOS 相同。纯 JVM 代码（不使用 Android API），因此也能在 JVM 测试中运行。
 *      值：字符串、布尔值、整数为 `Long`、小数为 `Double`、字典为 `Map`、数组为 `List`；`null` 对应 iOS 的 `NSNull`；属性列表的 `<date>` 为
 *      `java.util.Date`，`<data>` 为 `ByteArray`。
 */

/** [EN] `CYLTabBarConfigurationErrorDomain`. [CN] 配置错误的错误域。 */
const val CYLTabBarConfigurationErrorDomain: String = "CYLTabBarConfigurationErrorDomain"
/** [EN] `CYLTabBarConfigurationMaximumLength`: the largest configuration read, 5 MB. [CN] 读取配置的最大长度，5 MB。 */
const val CYLTabBarConfigurationMaximumLength: Int = 5 * 1024 * 1024
/** [EN] `CYLTabBarConfigurationMaximumDepth`: the deepest nesting accepted, 64 levels. [CN] 允许的最大嵌套层数，64 层。 */
const val CYLTabBarConfigurationMaximumDepth: Int = 64

/** [EN] `CYLTabBarConfigurationFormat`, with the iOS raw values. [CN] 配置文件格式，原始值与 iOS 相同。 */
enum class CYLTabBarConfigurationFormat(val rawValue: Int) {
    Unknown(0),
    /** [EN] .json [CN] .json */
    JSON(1),
    /** [EN] .json5 / .jsonc: comments, trailing commas, single quotes, unquoted keys. [CN] 注释、尾逗号、单引号、不加引号的键。 */
    JSON5(2),
    /** [EN] .plist / .strings: XML, binary or OpenStep property lists. [CN] XML、二进制或 OpenStep 属性列表。 */
    PropertyList(3),
    /** [EN] .yaml / .yml [CN] .yaml / .yml */
    YAML(4),
    /** [EN] .toml [CN] .toml */
    TOML(5),
    /** [EN] .ini / .cfg / .conf: `[section.path]` and `key = value`. [CN] `[节.路径]` 与 `key = value`。 */
    INI(6),
    /** [EN] .properties / .env: `dotted.key.path = value`. [CN] `点.分隔.路径 = value`。 */
    Properties(7),
    /** [EN] .xml (not a plist): elements are keys, `<item>` children make an array. [CN] 元素即键，`<item>` 子元素组成数组。 */
    XML(8),
    /** [EN] .textproto / .txtpb / .pbtxt / .prototxt: Protocol Buffers text format. [CN] Protocol Buffers 文本格式。 */
    ProtobufText(9),
    /** [EN] .binpb / .pb / .protobuf: a binary `cyl.CYLTabBarConfiguration` message. [CN] 二进制 `cyl.CYLTabBarConfiguration` 消息。 */
    Protobuf(10),
}

/** [EN] `CYLTabBarConfigurationErrorCode`, with the iOS raw values. [CN] 配置错误码，原始值与 iOS 相同。 */
enum class CYLTabBarConfigurationErrorCode(val rawValue: Int) {
    FileNotFound(1), UnsupportedFormat(2), InvalidSyntax(3), NotADictionary(4), Network(5), Empty(6), TooLarge(7),
    TooDeep(8), NoTabs(9), MainThreadRequired(10), NoPages(11),
}

/**
 * [EN] The `NSError` of `CYLTabBarConfigurationErrorDomain`: `code` and a description (`message`).
 * [CN] `CYLTabBarConfigurationErrorDomain` 的 `NSError`：`code` 与描述（`message`）。
 */
class CYLTabBarConfigurationException(val code: CYLTabBarConfigurationErrorCode, message: String) : Exception(message) {
    /** [EN] Always `CYLTabBarConfigurationErrorDomain`. [CN] 始终为 `CYLTabBarConfigurationErrorDomain`。 */
    val domain: String get() = CYLTabBarConfigurationErrorDomain
}

// MARK: - Helpers 工具

/** [EN] The iOS `NSNull` while parsing; turned into `null` at the end. [CN] 解析过程中代表 iOS 的 `NSNull`，最后转换为 `null`。 */
private object CYLNull

private class CYLCursor(var index: Int)

private fun configurationError(code: CYLTabBarConfigurationErrorCode, description: String) = CYLTabBarConfigurationException(code, description)

private fun syntaxError(formatName: String, line: Int, reason: String): CYLTabBarConfigurationException {
    val description = if (line > 0) "$formatName configuration, line $line: $reason" else "$formatName configuration: $reason"
    return configurationError(CYLTabBarConfigurationErrorCode.InvalidSyntax, description)
}

private fun tooDeepError(formatName: String) = configurationError(
    CYLTabBarConfigurationErrorCode.TooDeep, "$formatName configuration: nested deeper than $CYLTabBarConfigurationMaximumDepth levels.")

// [EN] Reasons and format names used by several parsers. [CN] 多个解析器共用的原因与格式名称。
private const val UNTERMINATED_ARRAY = "unterminated array"
private const val UNTERMINATED_STRING = "unterminated string"
private const val INVALID_UNICODE_ESCAPE = "invalid unicode escape"
private const val INVALID_KEY = "invalid key"
private const val EXPECTED_CLOSING_BRACKET = "expected ']'"
private const val EXPECTED_KEY_VALUE = "expected \"key = value\""
private const val KEY_CONFLICT = "key conflicts with an existing value"
private const val INVALID_XML = "invalid XML"
private const val FORMAT_PROTOBUF_TEXT = "Protobuf text"
private const val FORMAT_PROPERTY_LIST = "Property List"
private const val INVALID_PROPERTY_LIST = "invalid property list"
private const val INVALID_CONTENT = "invalid content"

/** [EN] The deepest nesting of { [ ( outside quoted strings. [CN] 引号外 { [ ( 的最大嵌套深度。 */
private fun bracketDepth(text: String): Int {
    var depth = 0
    var deepest = 0
    var quote = 0.toChar()
    var i = 0
    while (i < text.length) {
        val c = text[i]
        when {
            quote != 0.toChar() -> if (c == '\\') i++ else if (c == quote) quote = 0.toChar()
            c == '"' || c == '\'' -> quote = c
            c == '{' || c == '[' || c == '(' -> {
                depth++
                deepest = maxOf(deepest, depth)
            }
            (c == '}' || c == ']' || c == ')') && depth > 0 -> depth--
        }
        i++
    }
    return deepest
}

/** [EN] The deepest nesting of <dict> / <array> of an XML property list. [CN] XML 属性列表中 <dict> / <array> 的最大嵌套深度。 */
private fun xmlPropertyListDepth(text: String): Int {
    var depth = 0
    var deepest = 0
    var search = 0
    while (search < text.length) {
        val open = text.indexOf('<', search)
        if (open < 0) break
        val close = text.indexOf('>', open)
        if (close < 0) break
        val tag = text.substring(open + 1, close)
        val selfClosing = tag.endsWith("/")
        if (!selfClosing && (tag.startsWith("dict") || tag.startsWith("array"))) {
            depth++
            deepest = maxOf(deepest, depth)
        } else if ((tag.startsWith("/dict") || tag.startsWith("/array")) && depth > 0) {
            depth--
        }
        search = close + 1
    }
    return deepest
}

private fun isInlineSpace(c: Char) = c == ' ' || c == '\t'
private fun isSpaceOrNewline(c: Char) = c == ' ' || c == '\t' || c == '\n' || c == '\r'
private fun trimmed(text: String) = text.trim()

/** [EN] UTF-16 / UTF-32 text with a BOM re-encoded as UTF-8 (A16); anything else as it is. [CN] 带 BOM 的 UTF-16 / UTF-32 文本转为 UTF-8（A16）；其他原样返回。 */
private fun utf8DataFromData(data: ByteArray): ByteArray {
    fun b(i: Int) = data[i].toInt() and 0xFF
    val (charset, bom) = when {
        data.size >= 4 && b(0) == 0xFF && b(1) == 0xFE && b(2) == 0 && b(3) == 0 -> "UTF-32LE" to 4
        data.size >= 4 && b(0) == 0 && b(1) == 0 && b(2) == 0xFE && b(3) == 0xFF -> "UTF-32BE" to 4
        data.size >= 2 && b(0) == 0xFF && b(1) == 0xFE -> "UTF-16LE" to 2
        data.size >= 2 && b(0) == 0xFE && b(1) == 0xFF -> "UTF-16BE" to 2
        else -> return data
    }
    val text = strictDecode(data.copyOfRange(bom, data.size), Charset.forName(charset)) ?: return data
    return text.toByteArray(Charsets.UTF_8)
}

private fun strictDecode(bytes: ByteArray, charset: Charset): String? = try {
    charset.newDecoder().onMalformedInput(CodingErrorAction.REPORT).onUnmappableCharacter(CodingErrorAction.REPORT)
        .decode(ByteBuffer.wrap(bytes)).toString()
} catch (error: CharacterCodingException) {
    null
}

/** [EN] The UTF-8 text of `data` without its BOM, or null when it is not UTF-8. [CN] `data` 的 UTF-8 文本（去掉 BOM），不是 UTF-8 时为 null。 */
private fun stringFromData(data: ByteArray): String? {
    val text = strictDecode(data, Charsets.UTF_8) ?: return null
    return if (text.startsWith('\uFEFF')) text.substring(1) else text
}

private fun lines(text: String): List<String> = text.replace("\r\n", "\n").replace('\r', '\n').split('\n')

private fun hexValue(text: String): Long? {
    if (text.isEmpty() || text.length > 16 || !text.all { it.isDigit() || it.lowercaseChar() in 'a'..'f' }) return null
    return java.lang.Long.parseUnsignedLong(text, 16)
}

/** [EN] A decimal or hexadecimal integer, or a float; `allowsUnderscores`: TOML's digit separators. [CN] 十进制或十六进制整数，或浮点数；`allowsUnderscores`：TOML 的数字分隔符。 */
private fun numberFromString(string: String, allowsUnderscores: Boolean): Number? {
    val text = if (allowsUnderscores) string.replace("_", "") else string
    if (text.isEmpty()) return null
    val first = text[0]
    val index = if (first == '+' || first == '-') 1 else 0
    if (index >= text.length) return null
    if (text.length > index + 2 && text[index] == '0' && (text[index + 1] == 'x' || text[index + 1] == 'X')) {
        val value = hexValue(text.substring(index + 2)) ?: return null
        return if (first == '-') -value else value
    }
    return decimalNumber(text, index)
}

private fun decimalNumber(text: String, start: Int): Number? {
    var sawDigit = false
    var sawDot = false
    var sawExponent = false
    var i = start
    while (i < text.length) {
        val c = text[i]
        when {
            c in '0'..'9' -> sawDigit = true
            c == '.' && !sawDot && !sawExponent -> sawDot = true
            (c == 'e' || c == 'E') && sawDigit && !sawExponent && i + 1 < text.length -> {
                sawExponent = true
                if (text[i + 1] == '+' || text[i + 1] == '-') i++
            }
            else -> return null
        }
        i++
    }
    if (!sawDigit) return null
    if (sawDot || sawExponent) return text.toDoubleOrNull()
    return text.toLongOrNull() ?: if (text.startsWith('-')) Long.MIN_VALUE else Long.MAX_VALUE
}

/** [EN] An unquoted scalar: booleans, null / ~ (YAML), numbers, else the text itself. [CN] 未加引号的标量：布尔值、null / ~（YAML）、数字，否则为文本本身。 */
private fun typedScalar(raw: String, allowsNull: Boolean): Any {
    val text = trimmed(raw)
    val lowercase = text.lowercase()
    if (lowercase == "true") return true
    if (lowercase == "false") return false
    if (allowsNull && (lowercase == "null" || text == "~" || text.isEmpty())) return CYLNull
    return numberFromString(text, false) ?: text
}

private fun appendUnicodeEscape(output: StringBuilder, hex: String): Boolean {
    val value = hexValue(hex) ?: return false
    if (value > 0x10FFFF) return false
    output.appendCodePoint(value.toInt())
    return true
}

private fun simpleEscape(e: Char): String? = when (e) {
    'n' -> "\n"; 't' -> "\t"; 'r' -> "\r"; 'b' -> "\b"; 'f' -> "\u000C"; '0' -> "\u0000"
    else -> null
}

/** [EN] A double-quoted string at `cursor` (on the quote), with JSON / TOML / YAML escapes; null when it is not closed. [CN] `cursor` 处的双引号字符串；未闭合时为 null。 */
private fun readDoubleQuoted(text: String, cursor: CYLCursor): String? {
    val output = StringBuilder()
    var i = cursor.index + 1
    while (i < text.length) {
        val c = text[i]
        if (c == '"') {
            cursor.index = i + 1
            return output.toString()
        }
        if (c == '\\' && i + 1 < text.length) {
            i = appendEscape(text, i, output) ?: return null
            continue
        }
        output.append(c)
        i++
    }
    return null
}

/** [EN] Appends the escape at `i` (on the backslash); the index after it, or null when a \u escape is invalid. [CN] 追加 `i` 处（反斜杠）的转义；返回其后的下标，\u 转义无效时为 null。 */
private fun appendEscape(text: String, i: Int, output: StringBuilder): Int? {
    val e = text[i + 1]
    if (e != 'u' && e != 'U') {
        output.append(simpleEscape(e) ?: e.toString())
        return i + 2
    }
    val count = if (e == 'u') 4 else 8
    val start = i + 2
    if (start + count > text.length || !appendUnicodeEscape(output, text.substring(start, start + count))) return null
    return start + count
}

/** [EN] A single-quoted string; `doubledQuoteEscapes`: YAML's '' for one quote. [CN] 单引号字符串；`doubledQuoteEscapes`：YAML 用 '' 表示一个引号。 */
private fun readSingleQuoted(text: String, cursor: CYLCursor, doubledQuoteEscapes: Boolean): String? {
    val output = StringBuilder()
    var i = cursor.index + 1
    while (i < text.length) {
        val c = text[i]
        if (c == '\'') {
            if (doubledQuoteEscapes && i + 1 < text.length && text[i + 1] == '\'') {
                output.append('\'')
                i += 2
                continue
            }
            cursor.index = i + 1
            return output.toString()
        }
        output.append(c)
        i++
    }
    return null
}

private fun unquotedOrTypedValue(raw: String): Any {
    val text = trimmed(raw)
    if (text.length >= 2) {
        val first = text[0]
        val last = text[text.length - 1]
        if (first == '"' && last == '"') {
            val cursor = CYLCursor(0)
            val string = readDoubleQuoted(text, cursor)
            if (string != null && cursor.index == text.length) return string
        }
        if (first == '\'' && last == '\'') return text.substring(1, text.length - 1)
    }
    return typedScalar(text, false)
}

/** [EN] The iOS `-description` of a scalar used as a key. [CN] 作为键的标量的 iOS `-description`。 */
private fun describe(value: Any?): String = when (value) {
    is String -> value
    is Boolean -> if (value) "1" else "0"
    is Double -> if (value.isFinite() && value == Math.floor(value) && kotlin.math.abs(value) < 1e15) value.toLong().toString() else value.toString()
    CYLNull, null -> "<null>"
    else -> value.toString()
}

// MARK: - Dotted paths (INI, .properties, TOML) 点分路径

@Suppress("UNCHECKED_CAST")
private fun childDictionary(dictionary: MutableMap<String, Any?>, key: String): MutableMap<String, Any?>? {
    val child = dictionary[key]
    if (child == null) {
        val created = LinkedHashMap<String, Any?>()
        dictionary[key] = created
        return created
    }
    if (child is MutableList<*>) return child.lastOrNull() as? MutableMap<String, Any?>
    return child as? MutableMap<String, Any?>
}

private fun setValueAtPath(root: MutableMap<String, Any?>, path: List<String>, value: Any?): Boolean {
    if (path.isEmpty()) return false
    var dictionary = root
    for (i in 0 until path.size - 1) dictionary = childDictionary(dictionary, path[i]) ?: return false
    dictionary[path.last()] = value
    return true
}

private fun readDottedKeyPart(key: String, cursor: CYLCursor): String? {
    val c = key[cursor.index]
    if (c == '"') return readDoubleQuoted(key, cursor)
    if (c == '\'') return readSingleQuoted(key, cursor, false)
    val start = cursor.index
    while (cursor.index < key.length && key[cursor.index] != '.') cursor.index++
    return trimmed(key.substring(start, cursor.index))
}

/** [EN] `a.b."c.d"` as its parts; null when it is invalid or deeper than the limit. [CN] 拆分点分键；无效或超过深度限制时为 null。 */
private fun splitDottedKey(key: String): List<String>? {
    val parts = ArrayList<String>()
    val cursor = CYLCursor(0)
    while (cursor.index <= key.length) {
        skipInlineSpace(key, cursor)
        if (cursor.index >= key.length) return null
        val part = readDottedKeyPart(key, cursor)
        if (part.isNullOrEmpty() || parts.size >= CYLTabBarConfigurationMaximumDepth) return null
        parts += part
        skipInlineSpace(key, cursor)
        if (cursor.index >= key.length) return parts
        if (key[cursor.index] != '.') return null
        cursor.index++
    }
    return parts
}

private fun skipInlineSpace(text: String, cursor: CYLCursor) {
    while (cursor.index < text.length && isInlineSpace(text[cursor.index])) cursor.index++
}

/** [EN] Dictionaries whose keys are all non-negative integers become arrays, in the order of the numbers. [CN] 键全为非负整数的字典转为数组，按数字排序。 */
private fun arraysFromNumericKeys(value: Any?): Any? = when (value) {
    is Map<*, *> -> {
        val converted = LinkedHashMap<String, Any?>()
        var allNumeric = value.isNotEmpty()
        for ((key, element) in value) {
            converted[key as String] = arraysFromNumericKeys(element)
            val number = key.trim().toLongOrNull()
            if (number == null || number < 0) allNumeric = false
        }
        if (!allNumeric) converted else ArrayList(converted.entries.sortedBy { it.key.trim().toLong() }.map { it.value })
    }
    is List<*> -> ArrayList(value.map { arraysFromNumericKeys(it) })
    else -> value
}

/** [EN] The final value: `CYLNull` becomes null, containers become plain maps and lists. [CN] 最终值：`CYLNull` 转为 null，容器转为普通 Map 与 List。 */
private fun finished(value: Any?): Any? = when (value) {
    CYLNull -> null
    is Map<*, *> -> LinkedHashMap<String, Any?>().also { map -> for ((key, element) in value) map[key.toString()] = finished(element) }
    is List<*> -> ArrayList(value.map { finished(it) })
    else -> value
}

// MARK: - JSON

/** [EN] A strict JSON reader with the rules of `NSJSONSerialization` (a top-level object or array). [CN] 遵循 `NSJSONSerialization` 规则的严格 JSON 读取器（顶层为对象或数组）。 */
private class CYLJSONReader(private val text: String) {
    private var index = 0

    fun read(): Any? {
        skipSpace()
        if (index >= text.length || (text[index] != '{' && text[index] != '[')) throw syntaxError("JSON", 0, "the top level must be an object or an array")
        val value = value()
        skipSpace()
        if (index != text.length) fail("garbage at the end")
        return value
    }

    private fun fail(reason: String): Nothing = throw syntaxError("JSON", 0, "$reason (offset $index)")

    private fun skipSpace() {
        while (index < text.length && isSpaceOrNewline(text[index])) index++
    }

    private fun value(): Any? {
        skipSpace()
        if (index >= text.length) fail("unexpected end")
        return when (val c = text[index]) {
            '{' -> obj()
            '[' -> array()
            '"' -> string()
            't' -> literal("true", true)
            'f' -> literal("false", false)
            'n' -> literal("null", CYLNull)
            else -> if (c == '-' || c in '0'..'9') number() else fail("unexpected character '$c'")
        }
    }

    private fun literal(word: String, value: Any): Any {
        if (!text.startsWith(word, index)) fail("invalid literal")
        index += word.length
        return value
    }

    private fun obj(): Map<String, Any?> {
        index++
        val map = LinkedHashMap<String, Any?>()
        skipSpace()
        if (index < text.length && text[index] == '}') { index++; return map }
        while (true) {
            skipSpace()
            if (index >= text.length || text[index] != '"') fail("expected a key")
            val key = string()
            skipSpace()
            if (index >= text.length || text[index] != ':') fail("expected ':'")
            index++
            map[key] = value()
            skipSpace()
            if (index >= text.length) fail("unterminated object")
            when (text[index++]) {
                ',' -> continue
                '}' -> return map
                else -> fail("expected ',' or '}'")
            }
        }
    }

    private fun array(): List<Any?> {
        index++
        val list = ArrayList<Any?>()
        skipSpace()
        if (index < text.length && text[index] == ']') { index++; return list }
        while (true) {
            list += value()
            skipSpace()
            if (index >= text.length) fail(UNTERMINATED_ARRAY)
            when (text[index++]) {
                ',' -> continue
                ']' -> return list
                else -> fail("expected ',' or ']'")
            }
        }
    }

    private fun string(): String {
        index++
        val output = StringBuilder()
        while (index < text.length) {
            val c = text[index++]
            when {
                c == '"' -> return output.toString()
                c == '\\' -> escape(output)
                c < ' ' -> fail("unescaped control character")
                else -> output.append(c)
            }
        }
        fail(UNTERMINATED_STRING)
    }

    private fun escape(output: StringBuilder) {
        if (index >= text.length) fail("unterminated escape")
        when (val e = text[index++]) {
            '"', '\\', '/' -> output.append(e)
            'b' -> output.append('\b')
            'f' -> output.append('\u000C')
            'n' -> output.append('\n')
            'r' -> output.append('\r')
            't' -> output.append('\t')
            'u' -> {
                if (index + 4 > text.length) fail(INVALID_UNICODE_ESCAPE)
                val code = hexValue(text.substring(index, index + 4)) ?: fail(INVALID_UNICODE_ESCAPE)
                output.append(code.toInt().toChar())
                index += 4
            }
            else -> fail("invalid escape")
        }
    }

    private fun number(): Number {
        val start = index
        if (text[index] == '-') index++
        while (index < text.length && (text[index].isDigit() || text[index] in ".eE+-")) index++
        val token = text.substring(start, index)
        val valid = Regex("-?(0|[1-9]\\d*)(\\.\\d+)?([eE][+-]?\\d+)?").matches(token)
        if (!valid) fail("invalid number")
        if (token.any { it == '.' || it == 'e' || it == 'E' }) return token.toDouble()
        return token.toLongOrNull() ?: token.toDouble()
    }
}

/** [EN] JSON5 / JSONC to JSON: no comments or trailing commas, single quotes and unquoted keys turned into JSON. [CN] JSON5 / JSONC 转为 JSON：去掉注释与尾逗号，单引号与无引号键转为 JSON。 */
private object CYLJSON5 {
    fun toJSON(text: String): String? {
        val output = StringBuilder(text.length)
        val cursor = CYLCursor(0)
        while (cursor.index < text.length) {
            if (!step(text, cursor, output)) return null
        }
        return output.toString()
    }

    private fun step(text: String, cursor: CYLCursor, output: StringBuilder): Boolean {
        val c = text[cursor.index]
        return when {
            c == '"' -> {
                val start = cursor.index
                readDoubleQuoted(text, cursor) ?: return false
                output.append(text, start, cursor.index)
                true
            }
            c == '\'' -> {
                val string = readSingleQuoted(text, cursor, false) ?: return false
                output.append('"').append(string.replace("\\", "\\\\").replace("\"", "\\\"")).append('"')
                true
            }
            c == '/' && text.startsWith("//", cursor.index) -> {
                while (cursor.index < text.length && text[cursor.index] != '\n') cursor.index++
                true
            }
            c == '/' && text.startsWith("/*", cursor.index) -> {
                val end = text.indexOf("*/", cursor.index + 2)
                if (end < 0) return false
                cursor.index = end + 2
                true
            }
            c == '}' || c == ']' -> {
                var back = output.length - 1
                while (back >= 0 && isSpaceOrNewline(output[back])) back--
                if (back >= 0 && output[back] == ',') output.deleteCharAt(back)
                output.append(c)
                cursor.index++
                true
            }
            isIdentifierStart(c) -> { identifier(text, cursor, output); true }
            else -> { output.append(c); cursor.index++; true }
        }
    }

    private fun isIdentifierStart(c: Char) = c in 'A'..'Z' || c in 'a'..'z' || c == '_' || c == '$'
    private fun isIdentifierPart(c: Char) = isIdentifierStart(c) || c in '0'..'9'

    private fun identifier(text: String, cursor: CYLCursor, output: StringBuilder) {
        val start = cursor.index
        while (cursor.index < text.length && isIdentifierPart(text[cursor.index])) cursor.index++
        val identifier = text.substring(start, cursor.index)
        var next = cursor.index
        while (next < text.length && isSpaceOrNewline(text[next])) next++
        if (next < text.length && text[next] == ':') output.append('"').append(identifier).append('"') else output.append(identifier)
    }
}

// MARK: - YAML

private class CYLYAMLLine(var indent: Int, var text: String, val number: Int)

/** [EN] The YAML subset of configurations (no anchors, tags or multi-document streams). [CN] 配置中常用的 YAML 子集（不支持锚点、标签与多文档）。 */
private class CYLYAMLParser(text: String) {
    private val rawLines = lines(text)
    private val lines = ArrayList<CYLYAMLLine>()
    private var position = 0
    private var depth = 0
    var error: CYLTabBarConfigurationException? = null
        private set

    init {
        rawLines.forEachIndexed { index, raw ->
            val withoutComment = stripComment(raw)
            val content = trimmed(withoutComment)
            if (content.isEmpty() || content.startsWith("%") || content == "---" || content == "...") return@forEachIndexed
            var indent = 0
            while (indent < withoutComment.length && isInlineSpace(withoutComment[indent])) indent++
            lines += CYLYAMLLine(indent, trimmed(withoutComment.substring(indent)), index + 1)
        }
    }

    private fun stripComment(text: String): String {
        var inSingle = false
        var inDouble = false
        var i = 0
        while (i < text.length) {
            val c = text[i]
            when {
                c == '\\' && inDouble -> i++
                c == '"' && !inSingle -> inDouble = !inDouble
                c == '\'' && !inDouble -> inSingle = !inSingle
                c == '#' && !inSingle && !inDouble && (i == 0 || isInlineSpace(text[i - 1])) -> return text.substring(0, i)
            }
            i++
        }
        return text
    }

    private fun fail(line: Int, reason: String) {
        if (error == null) error = syntaxError("YAML", line, reason)
    }

    private fun current(): CYLYAMLLine? = lines.getOrNull(position)

    private fun isSequenceEntry(text: String) = text == "-" || text.startsWith("- ")

    private fun keyColonLocation(text: String): Int {
        var inSingle = false
        var inDouble = false
        var nesting = 0
        var i = 0
        while (i < text.length) {
            val c = text[i]
            if (c == '\\' && inDouble) {
                i += 2
                continue
            }
            when {
                c == '"' && !inSingle -> inDouble = !inDouble
                c == '\'' && !inDouble -> inSingle = !inSingle
                inSingle || inDouble -> Unit
                c == '[' || c == '{' -> nesting++
                c == ']' || c == '}' -> nesting--
                c == ':' && nesting == 0 && (i + 1 == text.length || isInlineSpace(text[i + 1])) -> return i
            }
            i++
        }
        return -1
    }

    private fun enterLevel(): Boolean {
        depth++
        if (depth > CYLTabBarConfigurationMaximumDepth) {
            if (error == null) error = tooDeepError("YAML")
            return false
        }
        return true
    }

    private fun parseBlock(indent: Int): Any? {
        val value = if (enterLevel()) parseBlockBody(indent) else null
        depth--
        return value
    }

    private fun parseBlockBody(indent: Int): Any? {
        val line = current()
        if (line == null || line.indent < indent) return CYLNull
        if (isSequenceEntry(line.text)) return parseSequence(line.indent)
        if (keyColonLocation(line.text) >= 0) return parseMapping(line.indent)
        position++
        return scalarOrFlow(line.text, line)
    }

    private fun parseSequence(indent: Int): MutableList<Any?> {
        val sequence = ArrayList<Any?>()
        while (error == null) {
            val line = current()
            if (line == null || line.indent != indent || !isSequenceEntry(line.text)) break
            val rest = if (line.text.length > 1) trimmed(line.text.substring(2)) else ""
            if (rest.isEmpty()) {
                position++
                val next = current()
                sequence += if (next != null && next.indent > indent) parseBlock(next.indent) ?: CYLNull else CYLNull
                continue
            }
            if (isSequenceEntry(rest) || keyColonLocation(rest) >= 0) {
                val restIndent = indent + (line.text.length - rest.length)
                line.indent = restIndent
                line.text = rest
                sequence += parseBlock(restIndent) ?: CYLNull
                continue
            }
            position++
            sequence += scalarOrFlow(rest, line) ?: CYLNull
        }
        return sequence
    }

    private fun parseMapping(indent: Int): MutableMap<String, Any?> {
        val mapping = LinkedHashMap<String, Any?>()
        while (error == null) {
            val line = current()
            if (line == null || line.indent != indent) {
                if (line != null && line.indent > indent) fail(line.number, "unexpected indentation")
                break
            }
            if (isSequenceEntry(line.text)) break
            val colon = keyColonLocation(line.text)
            if (colon < 0) {
                fail(line.number, "expected \"key: value\"")
                break
            }
            val key = describe(scalarOrFlow(trimmed(line.text.substring(0, colon)), null))
            val valueText = trimmed(line.text.substring(colon + 1))
            position++
            val value = mappingValue(valueText, indent, line)
            if (value != null && value != CYLNull) mapping[key] = value
        }
        return mapping
    }

    private fun mappingValue(valueText: String, indent: Int, line: CYLYAMLLine): Any? {
        if (valueText.isEmpty()) {
            val next = current() ?: return CYLNull
            val nested = next.indent > indent || (next.indent == indent && isSequenceEntry(next.text))
            return if (nested) parseBlock(next.indent) else CYLNull
        }
        if (valueText.startsWith("|") || valueText.startsWith(">")) return blockScalar(valueText.startsWith(">"), indent)
        return scalarOrFlow(valueText, line)
    }

    private fun blockScalar(folded: Boolean, parentIndent: Int): String {
        val first = current()
        if (first == null || first.indent <= parentIndent) return ""
        val blockIndent = first.indent
        var rawIndex = first.number - 1
        val parts = ArrayList<String>()
        while (rawIndex < rawLines.size) {
            val raw = rawLines[rawIndex]
            var rawIndent = 0
            while (rawIndent < raw.length && isInlineSpace(raw[rawIndent])) rawIndent++
            if (trimmed(raw).isNotEmpty() && rawIndent < blockIndent) break
            parts += if (raw.length > blockIndent) raw.substring(blockIndent) else ""
            rawIndex++
        }
        while (parts.isNotEmpty() && parts.last().isEmpty()) parts.removeAt(parts.size - 1)
        while (current()?.let { it.number <= rawIndex } == true) position++
        return parts.joinToString(if (folded) " " else "\n")
    }

    private fun scalarOrFlow(text: String, line: CYLYAMLLine?): Any? {
        if (text.isEmpty()) return CYLNull
        val number = line?.number ?: 0
        return when (text[0]) {
            '[', '{' -> flowCollection(text, number)
            '"' -> readDoubleQuoted(text, CYLCursor(0)) ?: run { fail(number, "unterminated double-quoted string"); null }
            '\'' -> readSingleQuoted(text, CYLCursor(0), true) ?: run { fail(number, "unterminated single-quoted string"); null }
            else -> typedScalar(text, true)
        }
    }

    private fun flowCollection(text: String, number: Int): Any? {
        val flow = StringBuilder(text)
        while (!flowIsBalanced(flow) && current() != null) {
            flow.append(' ').append(current()!!.text)
            position++
        }
        val flowText = flow.toString()
        val cursor = CYLCursor(0)
        val value = parseFlowValue(flowText, cursor, number)
        while (cursor.index < flowText.length && isSpaceOrNewline(flowText[cursor.index])) cursor.index++
        if (cursor.index != flowText.length && error == null) fail(number, "unexpected text after a flow collection")
        return value
    }

    private fun flowIsBalanced(text: CharSequence): Boolean {
        var nesting = 0
        var inSingle = false
        var inDouble = false
        var i = 0
        while (i < text.length) {
            val c = text[i]
            if (c == '\\' && inDouble) {
                i += 2
                continue
            }
            when {
                c == '"' && !inSingle -> inDouble = !inDouble
                c == '\'' && !inDouble -> inSingle = !inSingle
                inSingle || inDouble -> Unit
                c == '[' || c == '{' -> nesting++
                c == ']' || c == '}' -> nesting--
            }
            i++
        }
        return nesting <= 0
    }

    private fun parseFlowValue(text: String, cursor: CYLCursor, line: Int): Any? {
        val value = if (enterLevel()) parseFlowValueBody(text, cursor, line) else null
        depth--
        return value
    }

    private fun skipSpace(text: String, cursor: CYLCursor) {
        while (cursor.index < text.length && isSpaceOrNewline(text[cursor.index])) cursor.index++
    }

    private fun parseFlowValueBody(text: String, cursor: CYLCursor, line: Int): Any? {
        skipSpace(text, cursor)
        if (cursor.index >= text.length) {
            fail(line, "unexpected end of a flow collection")
            return null
        }
        return when (text[cursor.index]) {
            '[' -> parseFlowCollection(text, cursor, line, true)
            '{' -> parseFlowCollection(text, cursor, line, false)
            '"' -> readDoubleQuoted(text, cursor) ?: run { fail(line, "unterminated double-quoted string"); null }
            '\'' -> readSingleQuoted(text, cursor, true) ?: run { fail(line, "unterminated single-quoted string"); null }
            else -> flowPlainScalar(text, cursor)
        }
    }

    private fun flowPlainScalar(text: String, cursor: CYLCursor): Any {
        val start = cursor.index
        while (cursor.index < text.length) {
            val d = text[cursor.index]
            if (d == ',' || d == ']' || d == '}') break
            if (d == ':' && (cursor.index + 1 >= text.length || isSpaceOrNewline(text[cursor.index + 1]))) break
            cursor.index++
        }
        return typedScalar(text.substring(start, cursor.index), true)
    }

    private fun parseFlowCollection(text: String, cursor: CYLCursor, line: Int, isSequence: Boolean): Any? {
        val close = if (isSequence) ']' else '}'
        cursor.index++
        val array = ArrayList<Any?>()
        val dictionary = LinkedHashMap<String, Any?>()
        while (error == null) {
            skipSpace(text, cursor)
            if (cursor.index >= text.length) {
                fail(line, "unterminated flow collection")
                return null
            }
            if (text[cursor.index] == close) {
                cursor.index++
                break
            }
            val value = parseFlowValue(text, cursor, line)
            if (error != null) return null
            skipSpace(text, cursor)
            if (isSequence) array += value ?: CYLNull else if (!flowMappingEntry(text, cursor, line, value, dictionary)) return null
            if (cursor.index < text.length && text[cursor.index] == ',') cursor.index++
        }
        return if (isSequence) array else dictionary
    }

    private fun flowMappingEntry(text: String, cursor: CYLCursor, line: Int, key: Any?, dictionary: MutableMap<String, Any?>): Boolean {
        if (cursor.index >= text.length || text[cursor.index] != ':') {
            fail(line, "expected ':' in a flow mapping")
            return false
        }
        cursor.index++
        val mapped = parseFlowValue(text, cursor, line)
        if (error != null) return false
        if (mapped != null && mapped != CYLNull) dictionary[describe(key)] = mapped
        skipSpace(text, cursor)
        return true
    }

    fun parse(): Any? {
        if (lines.isEmpty()) return LinkedHashMap<String, Any?>()
        val value = parseBlock(0)
        val left = current()
        if (left != null && error == null) fail(left.number, "unexpected indentation")
        return if (error != null) null else value
    }
}

// MARK: - TOML

/** [EN] TOML without dates. [CN] 不含日期的 TOML。 */
private class CYLTOMLParser(private val text: String) {
    private var index = 0
    private var depth = 0
    var error: CYLTabBarConfigurationException? = null
        private set

    private fun currentLine(): Int = 1 + (0 until minOf(index, text.length)).count { text[it] == '\n' }

    private fun fail(reason: String) {
        if (error == null) error = syntaxError("TOML", currentLine(), reason)
    }

    private fun atEnd() = index >= text.length
    private fun peek(): Char = if (atEnd()) 0.toChar() else text[index]
    private fun hasPrefix(prefix: String) = text.startsWith(prefix, index)

    private fun skipInlineSpace() {
        while (!atEnd() && isInlineSpace(peek())) index++
    }

    private fun skipToEndOfLine() {
        while (!atEnd() && peek() != '\n') index++
    }

    private fun skipSpaceNewlinesAndComments() {
        while (!atEnd()) {
            val c = peek()
            when {
                isSpaceOrNewline(c) -> index++
                c == '#' -> skipToEndOfLine()
                else -> return
            }
        }
    }

    private fun expectEndOfLine() {
        skipInlineSpace()
        if (peek() == '#') skipToEndOfLine()
        if (peek() == '\r') index++
        if (!atEnd() && peek() != '\n') fail("expected the end of the line")
    }

    private fun parseKeyUntil(terminators: String): List<String>? {
        val start = index
        var inSingle = false
        var inDouble = false
        while (!atEnd()) {
            val c = peek()
            when {
                c == '"' && !inSingle -> inDouble = !inDouble
                c == '\'' && !inDouble -> inSingle = !inSingle
                (!inSingle && !inDouble && c in terminators) || c == '\n' -> break
            }
            index++
        }
        val raw = text.substring(start, index)
        val parts = splitDottedKey(raw)?.takeIf { raw.contains('"') || raw.contains('\'') || it.all(::isBareKey) }
        if (parts == null) fail(INVALID_KEY)
        return parts
    }

    /** [EN] A bare TOML key: ASCII letters, digits, '_' and '-'. [CN] TOML 裸键：ASCII 字母、数字、'_' 与 '-'。 */
    private fun isBareKey(part: String) = part.all { (it.isLetterOrDigit() && it.code < 128) || it == '_' || it == '-' }

    private fun parseValue(): Any? {
        depth++
        if (depth > CYLTabBarConfigurationMaximumDepth) {
            if (error == null) error = tooDeepError("TOML")
            depth--
            return null
        }
        val value = parseValueBody()
        depth--
        return value
    }

    private fun parseValueBody(): Any? {
        skipInlineSpace()
        val c = peek()
        return when {
            hasPrefix("\"\"\"") || hasPrefix("'''") -> multilineString(c == '\'')
            c == '"' -> quoted { readDoubleQuoted(text, it) } ?: run { fail(UNTERMINATED_STRING); null }
            c == '\'' -> quoted { readSingleQuoted(text, it, false) } ?: run { fail("unterminated literal string"); null }
            c == '[' -> array()
            c == '{' -> inlineTable()
            else -> bareValue()
        }
    }

    private fun quoted(read: (CYLCursor) -> String?): String? {
        val cursor = CYLCursor(index)
        val string = read(cursor) ?: return null
        index = cursor.index
        return string
    }

    private fun multilineString(literal: Boolean): String? {
        val delimiter = if (literal) "'''" else "\"\"\""
        index += 3
        if (peek() == '\n') index++ else if (hasPrefix("\r\n")) index += 2
        val end = text.indexOf(delimiter, index)
        if (end < 0) {
            fail("unterminated multi-line string")
            return null
        }
        val body = text.substring(index, end)
        index = end + 3
        if (literal) return body
        return readDoubleQuoted("\"" + body.replace("\"", "\\\"") + "\"", CYLCursor(0)) ?: body
    }

    private fun array(): Any? {
        index++
        val array = ArrayList<Any?>()
        while (error == null) {
            skipSpaceNewlinesAndComments()
            if (atEnd()) {
                fail(UNTERMINATED_ARRAY)
                return null
            }
            if (peek() == ']') {
                index++
                break
            }
            array += parseValue() ?: return null
            skipSpaceNewlinesAndComments()
            if (peek() == ',') index++ else if (peek() != ']') {
                fail("expected ',' or ']' in an array")
                return null
            }
        }
        return array
    }

    private fun inlineTable(): Any? {
        index++
        val table = LinkedHashMap<String, Any?>()
        while (error == null) {
            skipInlineSpace()
            if (peek() == '}') {
                index++
                break
            }
            val key = parseKeyUntil("=")
            if (key == null || peek() != '=') {
                fail("expected '=' in an inline table")
                return null
            }
            index++
            val value = parseValue()
            if (value == null || !setValueAtPath(table, key, value)) {
                fail("invalid value in an inline table")
                return null
            }
            skipInlineSpace()
            if (peek() == ',') index++ else if (peek() != '}') {
                fail("expected ',' or '}' in an inline table")
                return null
            }
        }
        return table
    }

    private fun bareValue(): Any? {
        val start = index
        while (!atEnd()) {
            val d = peek()
            if (d == ',' || d == ']' || d == '}' || d == '#' || isSpaceOrNewline(d)) break
            index++
        }
        val token = text.substring(start, index)
        if (token == "true") return true
        if (token == "false") return false
        return numberFromString(token, true) ?: run { fail("invalid value \"$token\" (strings need quotes)"); null }
    }

    private fun arrayOfTables(root: MutableMap<String, Any?>): MutableMap<String, Any?>? {
        index += 2
        val path = parseKeyUntil("]")
        if (path == null || !hasPrefix("]]")) {
            fail("expected ']]'")
            return null
        }
        index += 2
        expectEndOfLine()
        var parent: MutableMap<String, Any?>? = root
        for (i in 0 until path.size - 1) parent = parent?.let { childDictionary(it, path[i]) }
        val existing = parent?.get(path.last())
        if (parent == null || (existing != null && existing !is MutableList<*>)) {
            fail("array of tables conflicts with an existing key")
            return null
        }
        @Suppress("UNCHECKED_CAST")
        val array = (existing as? MutableList<Any?>) ?: ArrayList()
        parent[path.last()] = array
        return LinkedHashMap<String, Any?>().also { array += it }
    }

    private fun table(root: MutableMap<String, Any?>): MutableMap<String, Any?>? {
        index++
        val path = parseKeyUntil("]")
        if (path == null || peek() != ']') {
            fail(EXPECTED_CLOSING_BRACKET)
            return null
        }
        index++
        expectEndOfLine()
        var table: MutableMap<String, Any?> = root
        for (part in path) {
            table = childDictionary(table, part) ?: run { fail("table conflicts with an existing key"); return null }
        }
        return table
    }

    private fun keyValue(table: MutableMap<String, Any?>): Boolean {
        val key = parseKeyUntil("=")
        if (key == null || peek() != '=') {
            fail(EXPECTED_KEY_VALUE)
            return false
        }
        index++
        val value = parseValue() ?: return false
        if (!setValueAtPath(table, key, value)) {
            fail(KEY_CONFLICT)
            return false
        }
        expectEndOfLine()
        return true
    }

    fun parse(): MutableMap<String, Any?>? {
        val root = LinkedHashMap<String, Any?>()
        var table: MutableMap<String, Any?> = root
        while (error == null) {
            skipSpaceNewlinesAndComments()
            if (atEnd()) break
            table = when {
                hasPrefix("[[") -> arrayOfTables(root) ?: break
                peek() == '[' -> table(root) ?: break
                else -> if (keyValue(table)) table else break
            }
        }
        return if (error != null) null else root
    }
}

// MARK: - INI and .properties / .env

private object CYLFlatFormats {
    fun ini(text: String): Any? {
        val root = LinkedHashMap<String, Any?>()
        var section: List<String> = emptyList()
        lines(text).forEachIndexed { index, raw ->
            val number = index + 1
            val line = trimmed(raw)
            if (line.isEmpty() || line.startsWith(";") || line.startsWith("#")) return@forEachIndexed
            if (line.startsWith("[")) {
                if (!line.endsWith("]")) throw syntaxError("INI", number, EXPECTED_CLOSING_BRACKET)
                section = splitDottedKey(line.substring(1, line.length - 1)) ?: throw syntaxError("INI", number, "invalid section name")
                return@forEachIndexed
            }
            val separator = iniSeparatorIndex(line)
            if (separator < 0) throw syntaxError("INI", number, EXPECTED_KEY_VALUE)
            val key = splitDottedKey(line.substring(0, separator)) ?: throw syntaxError("INI", number, INVALID_KEY)
            val value = unquotedOrTypedValue(line.substring(separator + 1))
            if (!setValueAtPath(root, section + key, value)) throw syntaxError("INI", number, KEY_CONFLICT)
        }
        return arraysFromNumericKeys(root)
    }

    /** [EN] The first '=' or ':' of an INI line, -1 without one. [CN] INI 行中第一个 '=' 或 ':'，没有时为 -1。 */
    private fun iniSeparatorIndex(line: String): Int {
        val equals = line.indexOf('=')
        val colon = line.indexOf(':')
        return if (equals < 0 || (colon >= 0 && colon < equals)) colon else equals
    }

    private fun unescaped(text: String): String {
        if (!text.contains('\\')) return text
        val output = StringBuilder()
        var i = 0
        while (i < text.length) {
            val c = text[i]
            if (c != '\\' || i + 1 >= text.length) {
                output.append(c)
                i++
                continue
            }
            i++
            val e = text[i]
            when {
                e == 'n' -> output.append('\n')
                e == 't' -> output.append('\t')
                e == 'r' -> output.append('\r')
                e == 'u' && i + 4 < text.length && appendUnicodeEscape(output, text.substring(i + 1, i + 5)) -> i += 4
                else -> output.append(e)
            }
            i++
        }
        return output.toString()
    }

    private fun separatorIndex(line: String): Int {
        var i = 0
        while (i < line.length) {
            val c = line[i]
            if (c == '\\') {
                i += 2
                continue
            }
            if (c == '=' || c == ':' || isInlineSpace(c)) return i
            i++
        }
        return -1
    }

    private fun trimSpaces(text: String) = text.trim(' ', '\t')

    private fun propertiesPath(key: String, number: Int): List<String> {
        val dotted = key.replace("__", ".")
        val path = if (dotted.contains('"')) splitDottedKey(dotted) else dotted.split('.')
        if (path.isNullOrEmpty() || path.size > CYLTabBarConfigurationMaximumDepth || path.any { it.isEmpty() }) {
            throw syntaxError("Properties", number, INVALID_KEY)
        }
        return path
    }

    fun properties(text: String): Any? {
        val root = LinkedHashMap<String, Any?>()
        val all = lines(text)
        var index = 0
        while (index < all.size) {
            val number = index + 1
            var line = trimSpaces(all[index])
            if (line.isEmpty() || line.startsWith("#") || line.startsWith("!")) {
                index++
                continue
            }
            while (line.endsWith("\\") && !line.endsWith("\\\\") && index + 1 < all.size) {
                index++
                line = line.substring(0, line.length - 1) + trimmed(all[index])
            }
            setProperty(root, line, number)
            index++
        }
        return arraysFromNumericKeys(root)
    }

    /** [EN] One `key = value` line (continuations joined) of a properties or dotenv file. [CN] properties 或 dotenv 文件中的一行 `key = value`（已合并续行）。 */
    private fun setProperty(root: MutableMap<String, Any?>, logicalLine: String, number: Int) {
        val line = if (logicalLine.startsWith("export ")) trimmed(logicalLine.substring(7)) else logicalLine
        val separator = separatorIndex(line)
        if (separator < 0) throw syntaxError("Properties", number, EXPECTED_KEY_VALUE)
        val key = unescaped(line.substring(0, separator))
        var rest = trimSpaces(line.substring(separator))
        if (rest.startsWith("=") || rest.startsWith(":")) rest = trimSpaces(rest.substring(1))
        val value = if (rest.length >= 2 && (rest.startsWith("\"") || rest.startsWith("'"))) unquotedOrTypedValue(rest) else typedScalar(unescaped(rest), false)
        if (!setValueAtPath(root, propertiesPath(key, number), value)) throw syntaxError("Properties", number, KEY_CONFLICT)
    }
}

// MARK: - XML (not a plist)

private class CYLXMLNode(val name: String, val attributes: Map<String, String>) {
    val children = ArrayList<CYLXMLNode>()
    val text = StringBuilder()
}

private class CYLXMLTooDeep : SAXException("too deep")

private class CYLXMLTreeBuilder : DefaultHandler() {
    var root: CYLXMLNode? = null
    private val stack = ArrayList<CYLXMLNode>()

    override fun startElement(uri: String?, localName: String?, qName: String, attributes: Attributes) {
        if (stack.size >= CYLTabBarConfigurationMaximumDepth) throw CYLXMLTooDeep()
        val node = CYLXMLNode(qName, (0 until attributes.length).associate { attributes.getQName(it) to attributes.getValue(it) })
        stack.lastOrNull()?.children?.add(node)
        if (root == null) root = node
        stack += node
    }

    override fun characters(ch: CharArray, start: Int, length: Int) {
        stack.lastOrNull()?.text?.append(ch, start, length)
    }

    override fun endElement(uri: String?, localName: String?, qName: String?) {
        stack.removeAt(stack.size - 1)
    }

    /** [EN] External entities resolve to nothing (XXE, A14). [CN] 外部实体解析为空（XXE，A14）。 */
    override fun resolveEntity(publicId: String?, systemId: String?): InputSource = InputSource(StringReader(""))
}

private object CYLXMLFormat {
    /** [EN] Secure processing where the parser supports it; external entities always resolve to nothing (`resolveEntity`). [CN] 解析器支持时开启安全处理；外部实体始终解析为空（`resolveEntity`）。 */
    private fun secureFactory(): SAXParserFactory = SAXParserFactory.newInstance().apply {
        isNamespaceAware = false
        isValidating = false
        try {
            setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true)
        } catch (ignored: Exception) {
            // [EN] Android's parser has no such feature; it never loads external entities. [CN] Android 的解析器没有该特性；它从不加载外部实体。
        }
    }

    fun dictionary(data: ByteArray): Any? {
        val builder = CYLXMLTreeBuilder()
        try {
            secureFactory().newSAXParser().parse(java.io.ByteArrayInputStream(data), builder)
        } catch (error: CYLXMLTooDeep) {
            throw tooDeepError("XML")
        } catch (error: org.xml.sax.SAXParseException) {
            throw syntaxError("XML", error.lineNumber.coerceAtLeast(0), error.message ?: INVALID_XML)
        } catch (error: SAXException) {
            throw syntaxError("XML", 0, error.message ?: INVALID_XML)
        } catch (error: java.io.IOException) {
            throw syntaxError("XML", 0, error.message ?: INVALID_XML)
        } catch (error: javax.xml.parsers.ParserConfigurationException) {
            throw syntaxError("XML", 0, error.message ?: "no XML parser")
        }
        val root = builder.root ?: throw syntaxError("XML", 0, INVALID_XML)
        val value = value(root)
        if (value is Map<*, *>) return value
        throw configurationError(CYLTabBarConfigurationErrorCode.NotADictionary, "XML configuration: the root element must contain elements")
    }

    /** [EN] An element as a value: an array of `<item>`s, a dictionary of children and attributes, or its text. [CN] 元素的值：`<item>` 数组、子元素与属性的字典，或其文本。 */
    private fun value(node: CYLXMLNode): Any? {
        val type = node.attributes["type"]
        val attributes = node.attributes - "type"
        val allItems = node.children.isNotEmpty() && node.children.all { it.name == "item" }
        if (type == "array" || allItems) return ArrayList(node.children.map { value(it) })
        if (node.children.isNotEmpty() || attributes.isNotEmpty() || type == "dict") {
            val dictionary = LinkedHashMap<String, Any?>()
            for ((key, attribute) in attributes) dictionary[key] = typedScalar(attribute, false)
            val groups = LinkedHashMap<String, MutableList<Any?>>()
            for (child in node.children) groups.getOrPut(child.name) { ArrayList() } += value(child)
            for ((name, group) in groups) dictionary[name] = if (group.size == 1) group[0] else group
            return dictionary
        }
        if (type == "string") return node.text.toString()
        return typedScalar(trimmed(node.text.toString()), false)
    }
}

// MARK: - Protocol Buffers text format

/** [EN] Protocol Buffers text format, without a schema; a name written several times makes an array. [CN] 无需结构定义的 Protocol Buffers 文本格式；同名字段写多次组成数组。 */
private class CYLTextProtoParser(private val text: String) {
    private var index = 0
    private var depth = 0
    var error: CYLTabBarConfigurationException? = null
        private set

    private fun currentLine(): Int = 1 + (0 until minOf(index, text.length)).count { text[it] == '\n' }

    private fun fail(reason: String) {
        if (error == null) error = syntaxError(FORMAT_PROTOBUF_TEXT, currentLine(), reason)
    }

    private fun atEnd() = index >= text.length
    private fun peek(): Char = if (atEnd()) 0.toChar() else text[index]

    private fun skipSpaceAndComments() {
        while (!atEnd()) {
            val c = peek()
            when {
                isSpaceOrNewline(c) -> index++
                c == '#' -> while (!atEnd() && peek() != '\n') index++
                else -> return
            }
        }
    }

    private fun isNameCharacter(c: Char) = c in 'A'..'Z' || c in 'a'..'z' || c in '0'..'9' || c == '_' || c == '.' || c == '/'

    private fun parseName(): String? {
        if (peek() == '[') {
            val end = text.indexOf(']', index)
            if (end < 0) {
                fail(EXPECTED_CLOSING_BRACKET)
                return null
            }
            val name = text.substring(index + 1, end)
            index = end + 1
            return trimmed(name)
        }
        val start = index
        while (!atEnd() && isNameCharacter(peek())) index++
        if (index == start) {
            fail("expected a field name")
            return null
        }
        return text.substring(start, index)
    }

    private fun octalByte(first: Char): Int {
        var value = first - '0'
        var n = 0
        while (n < 2 && !atEnd() && peek() in '0'..'7') {
            value = value * 8 + (peek() - '0')
            index++
            n++
        }
        return value and 0xFF
    }

    private fun hexByte(): Int {
        var value = 0
        var digits = 0
        while (digits < 2 && !atEnd() && (peek().isDigit() || peek().lowercaseChar() in 'a'..'f')) {
            value = value * 16 + Character.digit(peek(), 16)
            index++
            digits++
        }
        return value
    }

    private fun appendEscape(bytes: ByteArrayOutputStream): Boolean {
        index++
        val e = peek()
        index++
        when {
            e in '0'..'7' -> bytes.write(octalByte(e))
            e == 'x' || e == 'X' -> bytes.write(hexByte())
            e == 'u' || e == 'U' -> {
                val count = if (e == 'u') 4 else 8
                val character = StringBuilder()
                if (index + count > text.length || !appendUnicodeEscape(character, text.substring(index, index + count))) {
                    fail(INVALID_UNICODE_ESCAPE)
                    return false
                }
                index += count
                bytes.write(character.toString().toByteArray(Charsets.UTF_8))
            }
            else -> bytes.write(protoSimpleEscape(e)?.let { byteArrayOf(it) } ?: e.toString().toByteArray(Charsets.UTF_8))
        }
        return true
    }

    private fun protoSimpleEscape(e: Char): Byte? = when (e) {
        'n' -> 10; 't' -> 9; 'r' -> 13; 'a' -> 7; 'b' -> 8; 'f' -> 12; 'v' -> 11
        else -> null
    }

    private fun parseQuotedString(): String? {
        val quote = peek()
        index++
        val bytes = ByteArrayOutputStream()
        while (!atEnd()) {
            val c = peek()
            if (c == quote) {
                index++
                return strictDecode(bytes.toByteArray(), Charsets.UTF_8) ?: run { fail("a string is not valid UTF-8"); null }
            }
            if (c == '\n') break
            if (c != '\\') {
                val end = if (Character.isHighSurrogate(c) && index + 1 < text.length) index + 2 else index + 1
                bytes.write(text.substring(index, end).toByteArray(Charsets.UTF_8))
                index = end
                continue
            }
            if (!appendEscape(bytes)) return null
        }
        fail(UNTERMINATED_STRING)
        return null
    }

    private fun parseScalar(): Any? {
        val c = peek()
        if (c == '"' || c == '\'') {
            val string = StringBuilder()
            while (error == null && (peek() == '"' || peek() == '\'')) {
                string.append(parseQuotedString() ?: return null)
                skipSpaceAndComments()
            }
            return string.toString()
        }
        val start = index
        while (!atEnd()) {
            val d = peek()
            if (isSpaceOrNewline(d) || d in ",;}>]#") break
            index++
        }
        val token = text.substring(start, index)
        if (token.isEmpty()) {
            fail("expected a value")
            return null
        }
        return protobufScalarToken(token)
    }

    /** [EN] true / false (True, t...), a number (a float suffix f allowed), or the identifier itself (an enum value). [CN] true / false（True、t……）、数字（允许浮点后缀 f），或标识符本身（枚举值）。 */
    private fun protobufScalarToken(token: String): Any = when (token) {
        "true", "True", "t" -> true
        "false", "False", "f" -> false
        else -> {
            val hex = token.startsWith("0x") || token.startsWith("0X")
            val numeric = if (token.length > 1 && (token.endsWith("f") || token.endsWith("F")) && !hex) token.dropLast(1) else token
            numberFromString(numeric, false) ?: token
        }
    }

    private fun parseValue(): Any? {
        depth++
        if (depth > CYLTabBarConfigurationMaximumDepth) {
            if (error == null) error = tooDeepError(FORMAT_PROTOBUF_TEXT)
            depth--
            return null
        }
        val value = parseValueBody()
        depth--
        return value
    }

    private fun parseValueBody(): Any? {
        skipSpaceAndComments()
        val c = peek()
        if (c == '{' || c == '<') {
            index++
            val message = parseFieldsUntil(if (c == '{') '}' else '>') ?: return null
            index++
            return message
        }
        if (c == '[') return parseList()
        return parseScalar()
    }

    private fun parseList(): Any? {
        index++
        val array = ArrayList<Any?>()
        while (error == null) {
            skipSpaceAndComments()
            if (peek() == ']') {
                index++
                return array
            }
            array += parseValue() ?: return null
            skipSpaceAndComments()
            if (peek() == ',') index++ else if (peek() != ']') {
                fail("expected ',' or ']'")
                return null
            }
        }
        return null
    }

    private fun addField(message: MutableMap<String, Any?>, repeated: MutableSet<String>, name: String, value: Any) {
        val existing = message[name]
        when {
            existing == null -> message[name] = value
            name in repeated -> @Suppress("UNCHECKED_CAST") (existing as MutableList<Any?>).add(value)
            else -> {
                message[name] = arrayListOf(existing, value)
                repeated += name
            }
        }
    }

    /** [EN] The fields of a message until `terminator` (0: the end of the text). [CN] 读取消息字段直到 `terminator`（0 表示文本结尾）。 */
    fun parseFieldsUntil(terminator: Char): MutableMap<String, Any?>? {
        val message = LinkedHashMap<String, Any?>()
        val repeated = HashSet<String>()
        while (error == null) {
            skipSpaceAndComments()
            if (atEnd()) {
                if (terminator != 0.toChar()) {
                    fail("unterminated message")
                    return null
                }
                break
            }
            if (terminator != 0.toChar() && peek() == terminator) break
            val name = parseName() ?: return null
            if (!skipFieldSeparator(name)) return null
            addField(message, repeated, name, parseValue() ?: return null)
            skipSpaceAndComments()
            if (peek() == ',' || peek() == ';') index++
        }
        return if (error != null) null else message
    }

    /** [EN] The ':' after a field name (optional before a message); false, with the error set, when missing. [CN] 字段名后的 ':'（消息前可省略）；缺少时设置错误并返回 false。 */
    private fun skipFieldSeparator(name: String): Boolean {
        skipSpaceAndComments()
        when (peek()) {
            ':' -> {
                index++
                skipSpaceAndComments()
            }
            '{', '<' -> Unit
            else -> {
                fail("expected ':' or '{' after \"$name\"")
                return false
            }
        }
        return true
    }
}

// MARK: - Protocol Buffers binary

/** [EN] The built-in schema of Configurations/cyl_tabbar_configuration.proto: message -> field number -> (name, kind). [CN] 内置结构定义：消息 -> 字段编号 -> （名称，类型）。 */
private object CYLProtobufSchema {
    private val itemFields = listOf(
        "CYLTabBarItemTitle", "CYLTabBarItemImage", "CYLTabBarItemSelectedImage", "CYLTabBarItemDarkImage", "CYLTabBarItemSelectedDarkImage",
        "CYLTabBarItemImageURL", "CYLTabBarItemSelectedImageURL", "CYLTabBarItemImageURLSize", "CYLTabBarItemImageInsets",
        "CYLTabBarItemTitlePositionAdjustment", "CYLTabBarItemImagePositionAdjustment", "CYLTabBarLottieFilePath", "CYLTabBarLottieURL",
        "CYLTabBarLottieSize", "CYLTabBarItemIdentifier", "CYLTabBarLottieDarkURL", "CYLTabBarLottieDarkFilePath", "map:CYLTabBarLottieDarkColors",
        null, null, "CYLTabBarItemSelectedTitle", "CYLTabBarItemTitleColor", "CYLTabBarItemSelectedTitleColor", "CYLTabBarItemIconColor",
        "CYLTabBarItemSelectedIconColor", "CYLTabBarItemSelectedBackgroundColor", "CYLTabBarItemBackgroundColor", "CYLTabBarItemTitleFont",
        "CYLTabBarItemSelectedTitleFont", "CYLTabBarItemAccessibilityIdentifier", "CYLTabBarItemAccessibilityLabel", "CYLTabBarItemAccessibilityHint",
        "CYLTabBarItemPageIdentifier", "map:CYLTabBarItemPageParameters", "CYLTabBarItemPlatforms", "CYLTabBarItemMinimumAppVersion",
        "CYLTabBarAnimationURL", "CYLTabBarAnimationFilePath", "CYLTabBarAnimationSize", "CYLTabBarAnimationDarkURL", "CYLTabBarAnimationDarkFilePath",
        "map:CYLTabBarAnimationDarkColors", "map:CYLTabBarAnimationColors", "map:CYLTabBarAnimationOptions", "CYLTabBarLottieLoopsWhenUnselected",
        "CYLTabBarPAGURL", "CYLTabBarPAGFilePath", "CYLTabBarPAGSize", "CYLTabBarPAGDarkURL", "CYLTabBarPAGDarkFilePath",
        "CYLTabBarRiveURL", "CYLTabBarRiveFilePath", "CYLTabBarRiveSize", "CYLTabBarRiveDarkURL", "CYLTabBarRiveDarkFilePath", "map:CYLTabBarRiveDarkColors",
        // [EN] GIF tab icons (#605), fields 57–61. [CN] GIF Tab 图标（#605），字段 57–61。
        "CYLTabBarGIFURL", "CYLTabBarGIFFilePath", "CYLTabBarGIFSize", "CYLTabBarGIFDarkURL", "CYLTabBarGIFDarkFilePath",
    )

    private fun field(entry: String): Pair<String, String> =
        if (entry.startsWith("map:")) entry.removePrefix("map:") to "map" else entry to "string"

    val messages: Map<String, Map<Int, Pair<String, String>>> = mapOf(
        "CYLTabBarConfiguration" to mapOf(
            1 to ("CYLTabBarControllerTabBarItemsAttributes" to "repeated:CYLTabBarItem"),
            2 to ("CYLTabBarControllerImageInsets" to "string"),
            3 to ("CYLTabBarControllerTitlePositionAdjustment" to "string"),
            4 to ("CYLTabBarControllerStyleType" to "string"),
            5 to ("CYLTabBarControllerContext" to "string"),
            7 to ("CYLTabBarControllerTabBarItemAnimationSpeed" to "string"),
        ),
        "CYLTabBarItem" to itemFields.withIndex().filter { it.value != null }.associate { (index, entry) -> index + 1 to field(entry!!) },
        "CYLMapEntry" to mapOf(1 to ("key" to "string"), 2 to ("value" to "string")),
    )
}

private class CYLProtobufReader(private val bytes: ByteArray) {
    /** [EN] A varint at `offset`; null when it runs past `end` or is longer than 10 bytes. [CN] `offset` 处的 varint；越界或超过 10 字节时为 null。 */
    private fun varint(cursor: CYLCursor, end: Int): Long? {
        var result = 0L
        var shift = 0
        while (shift < 70) {
            if (cursor.index >= end) return null
            val byte = bytes[cursor.index++].toInt() and 0xFF
            if (shift < 64) result = result or ((byte and 0x7F).toLong() shl shift)
            if (byte and 0x80 == 0) return result
            shift += 7
        }
        return null
    }

    /** [EN] Decodes one message of the schema in [start, end); null on malformed data. [CN] 解码 [start, end) 中的一个消息；数据无效时为 null。 */
    fun message(start: Int, end: Int, name: String): MutableMap<String, Any?>? {
        val fields = CYLProtobufSchema.messages[name] ?: emptyMap()
        val message = LinkedHashMap<String, Any?>()
        val cursor = CYLCursor(start)
        while (cursor.index < end) {
            val key = varint(cursor, end) ?: return null
            if (key ushr 3 == 0L) return null
            val number = key ushr 3
            val field = if (number <= Int.MAX_VALUE) fields[number.toInt()] else null
            if (!skipOrReadField((key and 7).toInt(), cursor, end, field, message)) return null
        }
        return message
    }

    /** [EN] One field by its wire type: varints and fixed sizes are skipped, length-delimited ones read; false when broken. [CN] 按线路类型处理一个字段：跳过 varint 与定长字段，读取长度分隔字段；损坏时返回 false。 */
    private fun skipOrReadField(wireType: Int, cursor: CYLCursor, end: Int, field: Pair<String, String>?, message: MutableMap<String, Any?>): Boolean = when (wireType) {
        0 -> varint(cursor, end) != null
        1, 5 -> {
            val size = if (wireType == 1) 8 else 4
            (cursor.index + size <= end).also { if (it) cursor.index += size }
        }
        2 -> lengthDelimited(cursor, end, field, message)
        else -> false
    }

    private fun lengthDelimited(cursor: CYLCursor, end: Int, field: Pair<String, String>?, message: MutableMap<String, Any?>): Boolean {
        val size = varint(cursor, end) ?: return false
        if (size < 0 || size > end - cursor.index) return false
        val payloadStart = cursor.index
        val payloadEnd = payloadStart + size.toInt()
        cursor.index = payloadEnd
        val (name, kind) = field ?: return true
        when {
            kind == "string" -> message[name] = strictDecode(bytes.copyOfRange(payloadStart, payloadEnd), Charsets.UTF_8) ?: return false
            kind == "map" -> {
                val entry: Map<String, Any?> = message(payloadStart, payloadEnd, "CYLMapEntry") ?: return false
                @Suppress("UNCHECKED_CAST")
                val map = (message[name] as? Map<String, Any?>).orEmpty()
                message[name] = map + (((entry["key"] as? String) ?: "") to (entry["value"] ?: ""))
            }
            kind.startsWith("repeated:") -> {
                val element = message(payloadStart, payloadEnd, kind.removePrefix("repeated:")) ?: return false
                @Suppress("UNCHECKED_CAST")
                val array = (message[name] as? MutableList<Any?>) ?: ArrayList()
                array += element
                message[name] = array
            }
        }
        return true
    }
}

private fun dictionaryFromProtobuf(data: ByteArray): Map<String, Any?> =
    CYLProtobufReader(data).message(0, data.size, "CYLTabBarConfiguration")
        ?: throw syntaxError("Protobuf", 0, "the data is not a valid cyl.CYLTabBarConfiguration message (see cyl_tabbar_configuration.proto)")

private fun dataLooksBinary(data: ByteArray): Boolean = data.any { val b = it.toInt() and 0xFF; b < 0x20 && b != 9 && b != 10 && b != 13 }

private fun dataHasPrefix(data: ByteArray, prefix: String): Boolean =
    data.size >= prefix.length && prefix.indices.all { data[it] == prefix[it].code.toByte() }

// MARK: - Property lists 属性列表

/** [EN] Binary property lists ("bplist00"): the structure check of iOS (no recursion) and the decoder. [CN] 二进制属性列表：iOS 的结构检查（非递归）与解码。 */
private class CYLBinaryPropertyList(private val bytes: ByteArray) {
    private var offsetSize = 0
    private var referenceSize = 0
    private var objectCount = 0L
    private var topObject = 0L
    private var tableOffset = 0L
    var tooDeep = false
        private set

    private fun readBigEndian(offset: Long, size: Int): Long {
        var value = 0L
        for (i in 0 until size) value = (value shl 8) or (bytes[(offset + i).toInt()].toLong() and 0xFF)
        return value
    }

    private fun readTrailer(): Boolean {
        val length = bytes.size.toLong()
        if (length < 8 + 32) return false
        val trailer = length - 32
        offsetSize = bytes[(trailer + 6).toInt()].toInt() and 0xFF
        referenceSize = bytes[(trailer + 7).toInt()].toInt() and 0xFF
        objectCount = readBigEndian(trailer + 8, 8)
        topObject = readBigEndian(trailer + 16, 8)
        tableOffset = readBigEndian(trailer + 24, 8)
        return offsetSize in 1..8 && referenceSize in 1..8 && objectCount > 0 && topObject in 0 until objectCount &&
            tableOffset in 0 until length && objectCount <= (length - tableOffset) / offsetSize
    }

    private fun objectOffset(objectIndex: Long): Long = readBigEndian(tableOffset + objectIndex * offsetSize, offsetSize)

    /** [EN] The count of a container or string at `offset` and the position after it; null when invalid. [CN] `offset` 处容器或字符串的数量及其后的位置；无效时为 null。 */
    private fun countAndPosition(offset: Long): Pair<Long, Long>? {
        val count = (bytes[offset.toInt()].toInt() and 0x0F).toLong()
        val position = offset + 1
        if (count != 0x0FL) return count to position
        if (position >= tableOffset) return null
        val marker = bytes[position.toInt()].toInt() and 0xFF
        if (marker shr 4 != 0x1 || (marker and 0x0F) > 3) return null
        val size = 1 shl (marker and 0x0F)
        if (position + 1 + size > tableOffset) return null
        return readBigEndian(position + 1, size) to position + 1 + size
    }

    /** [EN] Every offset and reference in bounds, no container deeper than the limit, a bounded number of visits. [CN] 所有偏移与引用都在范围内，容器不超过深度限制，访问次数有上限。 */
    fun isSafe(): Boolean {
        tooDeep = false
        if (!readTrailer()) return false
        val stack = ArrayDeque<Pair<Long, Int>>()
        stack.addLast(topObject to 1)
        var visits = 0
        while (stack.isNotEmpty()) {
            val (objectIndex, depth) = stack.removeLast()
            visits++
            if (visits > 100_000 || !pushChildren(objectIndex, depth, stack)) return false
        }
        return true
    }

    /** [EN] Checks one object and pushes the objects an array, set or dictionary refers to; false when unsafe. [CN] 检查一个对象，并压入数组、集合或字典引用的对象；不安全时返回 false。 */
    private fun pushChildren(objectIndex: Long, depth: Int, stack: ArrayDeque<Pair<Long, Int>>): Boolean {
        if (objectIndex !in 0 until objectCount) return false
        val offset = objectOffset(objectIndex)
        if (offset !in 0 until tableOffset) return false
        val type = (bytes[offset.toInt()].toInt() and 0xFF) shr 4
        if (type != 0xA && type != 0xC && type != 0xD) return true
        if (depth > CYLTabBarConfigurationMaximumDepth) {
            tooDeep = true
            return false
        }
        val (count, position) = countAndPosition(offset) ?: return false
        val references = if (type == 0xD) count * 2 else count
        if (count > objectCount || references > (tableOffset - position) / referenceSize || stack.size + references > 200_000) return false
        for (i in 0 until references) stack.addLast(readBigEndian(position + i * referenceSize, referenceSize) to depth + 1)
        return true
    }

    /** [EN] The decoded top object (call after `isSafe()`). [CN] 解码后的顶层对象（在 `isSafe()` 之后调用）。 */
    fun decode(): Any? = try {
        value(topObject)
    } catch (error: IndexOutOfBoundsException) {
        throw syntaxError(FORMAT_PROPERTY_LIST, 0, "invalid binary property list structure")
    }

    private fun references(position: Long, count: Long): List<Long> = (0 until count).map { readBigEndian(position + it * referenceSize, referenceSize) }

    private fun value(objectIndex: Long): Any? {
        val offset = objectOffset(objectIndex)
        val marker = bytes[offset.toInt()].toInt() and 0xFF
        val low = marker and 0x0F
        return when (marker shr 4) {
            0x0 -> when (marker) { 0x08 -> false; 0x09 -> true; else -> CYLNull }
            0x1 -> integer(offset + 1, 1 shl low)
            0x2 -> real(offset + 1, 1 shl low)
            0x3 -> java.util.Date(((java.lang.Double.longBitsToDouble(readBigEndian(offset + 1, 8)) + 978_307_200.0) * 1000).toLong())
            0x4 -> countAndPosition(offset)?.let { (count, position) -> bytes.copyOfRange(position.toInt(), (position + count).toInt()) }
            0x5 -> countAndPosition(offset)?.let { (count, position) -> String(bytes, position.toInt(), count.toInt(), Charsets.US_ASCII) }
            0x6 -> countAndPosition(offset)?.let { (count, position) -> String(bytes, position.toInt(), (count * 2).toInt(), Charsets.UTF_16BE) }
            0x7 -> countAndPosition(offset)?.let { (count, position) -> String(bytes, position.toInt(), count.toInt(), Charsets.UTF_8) }
            0x8 -> mapOf("CF\$UID" to readBigEndian(offset + 1, low + 1))
            0xA, 0xC -> countAndPosition(offset)?.let { (count, position) -> ArrayList(references(position, count).map { value(it) }) }
            0xD -> countAndPosition(offset)?.let { (count, position) -> dictionary(position, count) }
            else -> throw syntaxError(FORMAT_PROPERTY_LIST, 0, "unknown binary property list object")
        }
    }

    /** [EN] 1, 2 and 4-byte integers are unsigned, 8-byte ones signed (two's complement), as in the format. [CN] 1、2、4 字节整数无符号，8 字节有符号。 */
    private fun integer(position: Long, size: Int): Long = readBigEndian(position, minOf(size, 8))

    private fun real(position: Long, size: Int): Double =
        if (size == 4) java.lang.Float.intBitsToFloat(readBigEndian(position, 4).toInt()).toDouble() else java.lang.Double.longBitsToDouble(readBigEndian(position, 8))

    private fun dictionary(position: Long, count: Long): Map<String, Any?> {
        val keys = references(position, count)
        val values = references(position + count * referenceSize, count)
        return LinkedHashMap<String, Any?>().also { map -> keys.indices.forEach { map[describe(value(keys[it]))] = value(values[it]) } }
    }
}

/** [EN] XML property lists, external entities off. [CN] XML 属性列表，关闭外部实体。 */
private object CYLXMLPropertyList {
    fun parse(text: String): Any? {
        val factory = DocumentBuilderFactory.newInstance().apply {
            isNamespaceAware = false
            isExpandEntityReferences = false
            try {
                setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true)
            } catch (ignored: Exception) {
                // [EN] Android's parser has no such feature; external entities resolve to nothing below. [CN] Android 的解析器没有该特性；下面的外部实体解析为空。
            }
        }
        val builder = factory.newDocumentBuilder()
        builder.setErrorHandler(null)
        builder.setEntityResolver { _, _ -> InputSource(StringReader("")) }
        val document = try {
            builder.parse(InputSource(StringReader(text)))
        } catch (error: SAXException) {
            throw syntaxError(FORMAT_PROPERTY_LIST, 0, error.message ?: INVALID_PROPERTY_LIST)
        }
        val root = document.documentElement
        val element = if (root.tagName == "plist") children(root).firstOrNull() else root
        return element?.let { value(it) } ?: throw syntaxError(FORMAT_PROPERTY_LIST, 0, INVALID_PROPERTY_LIST)
    }

    private fun children(node: Node): List<Element> = (0 until node.childNodes.length).mapNotNull { node.childNodes.item(it) as? Element }

    private fun value(element: Element): Any? = when (element.tagName) {
        "dict" -> {
            val map = LinkedHashMap<String, Any?>()
            val elements = children(element)
            var i = 0
            while (i + 1 < elements.size) {
                if (elements[i].tagName != "key") throw syntaxError(FORMAT_PROPERTY_LIST, 0, "expected <key> in <dict>")
                map[elements[i].textContent] = value(elements[i + 1])
                i += 2
            }
            map
        }
        "array" -> ArrayList(children(element).map { value(it) })
        "string" -> element.textContent
        "integer" -> element.textContent.trim().let { it.toLongOrNull() ?: it.toDoubleOrNull() ?: throw syntaxError(FORMAT_PROPERTY_LIST, 0, "invalid <integer>") }
        "real" -> element.textContent.trim().toDoubleOrNull() ?: throw syntaxError(FORMAT_PROPERTY_LIST, 0, "invalid <real>")
        "true" -> true
        "false" -> false
        "date" -> date(element.textContent.trim())
        "data" -> base64(element.textContent)
        else -> throw syntaxError(FORMAT_PROPERTY_LIST, 0, "unknown element <${element.tagName}>")
    }

    private fun date(text: String): java.util.Date {
        val format = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", java.util.Locale.US)
        format.timeZone = java.util.TimeZone.getTimeZone("UTC")
        return try {
            format.parse(text) ?: throw syntaxError(FORMAT_PROPERTY_LIST, 0, "invalid <date>")
        } catch (error: java.text.ParseException) {
            throw syntaxError(FORMAT_PROPERTY_LIST, 0, "invalid <date>")
        }
    }

    private fun base64(text: String): ByteArray {
        val alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        val output = ByteArrayOutputStream()
        var buffer = 0
        var bits = 0
        for (c in text) {
            if (c == '=') break
            val value = alphabet.indexOf(c)
            if (value < 0) continue
            buffer = (buffer shl 6) or value
            bits += 6
            if (bits >= 8) {
                bits -= 8
                output.write((buffer shr bits) and 0xFF)
            }
        }
        return output.toByteArray()
    }
}

/** [EN] OpenStep (old-style) property lists and .strings: every scalar is a string, `<hex>` is data. [CN] OpenStep（旧式）属性列表与 .strings：标量均为字符串，`<hex>` 为数据。 */
private class CYLOpenStepParser(private val text: String) {
    private var index = 0

    private fun fail(reason: String): Nothing = throw syntaxError(FORMAT_PROPERTY_LIST, 0, reason)

    private fun atEnd() = index >= text.length

    private fun skipSpaceAndComments() {
        while (!atEnd()) {
            when {
                text[index].isWhitespace() -> index++
                text.startsWith("//", index) -> while (!atEnd() && text[index] != '\n') index++
                text.startsWith("/*", index) -> {
                    val end = text.indexOf("*/", index + 2)
                    if (end < 0) fail("unterminated comment")
                    index = end + 2
                }
                else -> return
            }
        }
    }

    private fun isUnquoted(c: Char) = c.isLetterOrDigit() || c in "_\$/:.-+"

    fun parseDocument(): Any? {
        val value = value()
        skipSpaceAndComments()
        if (!atEnd()) fail("unexpected text after the property list")
        return value
    }

    private fun value(): Any? {
        skipSpaceAndComments()
        if (atEnd()) fail("unexpected end")
        return when (val c = text[index]) {
            '{' -> dictionary()
            '(' -> array()
            '<' -> data()
            '"', '\'' -> quoted(c)
            else -> if (isUnquoted(c)) unquoted() else fail("unexpected character '$c'")
        }
    }

    private fun unquoted(): String {
        val start = index
        while (!atEnd() && isUnquoted(text[index])) index++
        return text.substring(start, index)
    }

    private fun quoted(quote: Char): String {
        index++
        val output = StringBuilder()
        while (!atEnd()) {
            val c = text[index++]
            if (c == quote) return output.toString()
            if (c != '\\') {
                output.append(c)
                continue
            }
            if (atEnd()) break
            escape(output)
        }
        fail(UNTERMINATED_STRING)
    }

    private fun escape(output: StringBuilder) {
        val e = text[index++]
        when {
            e in '0'..'7' -> {
                var value = e - '0'
                var n = 0
                while (n < 2 && !atEnd() && text[index] in '0'..'7') { value = value * 8 + (text[index++] - '0'); n++ }
                output.append(value.toChar())
            }
            e == 'U' -> {
                val end = minOf(index + 4, text.length)
                if (!appendUnicodeEscape(output, text.substring(index, end))) fail(INVALID_UNICODE_ESCAPE)
                index = end
            }
            else -> output.append(when (e) { 'n' -> '\n'; 't' -> '\t'; 'r' -> '\r'; 'a' -> '\u0007'; 'b' -> '\b'; 'f' -> '\u000C'; 'v' -> '\u000B'; else -> e })
        }
    }

    private fun data(): ByteArray {
        index++
        val output = ByteArrayOutputStream()
        val hex = StringBuilder()
        while (!atEnd() && text[index] != '>') {
            val c = text[index++]
            if (!c.isWhitespace()) hex.append(c)
        }
        if (atEnd() || hex.length % 2 != 0) fail("invalid data")
        index++
        for (i in hex.indices step 2) output.write(hexValue(hex.substring(i, i + 2))?.toInt() ?: fail("invalid data"))
        return output.toByteArray()
    }

    private fun array(): List<Any?> {
        index++
        val list = ArrayList<Any?>()
        while (true) {
            skipSpaceAndComments()
            if (atEnd()) fail(UNTERMINATED_ARRAY)
            if (text[index] == ')') { index++; return list }
            list += value()
            skipSpaceAndComments()
            if (!atEnd() && text[index] == ',') index++ else if (atEnd() || text[index] != ')') fail("expected ',' or ')'")
        }
    }

    private fun dictionary(): Map<String, Any?> {
        index++
        val map = LinkedHashMap<String, Any?>()
        while (true) {
            skipSpaceAndComments()
            if (atEnd()) fail("unterminated dictionary")
            if (text[index] == '}') { index++; return map }
            val key = value() as? String ?: fail("a key must be a string")
            map[key] = entryValue(key)
        }
    }

    private fun isAt(c: Char) = !atEnd() && text[index] == c

    /** [EN] The value after a key: `= value;`, or the key itself for a .strings entry `"key";`. [CN] 键之后的值：`= value;`，或 .strings 条目 `"key";` 的键本身。 */
    private fun entryValue(key: String): Any? {
        skipSpaceAndComments()
        if (isAt(';')) {
            index++
            return key
        }
        if (!isAt('=')) fail("expected '='")
        index++
        val value = value()
        skipSpaceAndComments()
        when {
            isAt(';') -> index++
            !isAt('}') -> fail("expected ';'")
        }
        return value
    }
}

private object CYLPropertyList {
    /** [EN] `NSPropertyListSerialization`: binary, XML or OpenStep by the content. [CN] 按内容判断二进制、XML 或 OpenStep。 */
    fun parse(data: ByteArray, text: String?): Any? {
        if (dataHasPrefix(data, "bplist")) {
            val plist = CYLBinaryPropertyList(data)
            plist.isSafe()
            return plist.decode()
        }
        val source = text ?: throw syntaxError(FORMAT_PROPERTY_LIST, 0, "the file is not UTF-8 text")
        if (trimmed(source).startsWith("<")) return CYLXMLPropertyList.parse(source)
        return CYLOpenStepParser(source).parseDocument()
    }
}

// MARK: - CYLTabBarConfigurationParser

/**
 * [EN] `CYLTabBarConfigurationParser`: reads key-value configuration files into dictionaries, in every
 *      `CYLTabBarConfigurationFormat`. Text formats are read as UTF-8 (UTF-16 / UTF-32 with a BOM are converted first).
 * [CN] `CYLTabBarConfigurationParser`：把键值配置文件读取为字典，支持所有 `CYLTabBarConfigurationFormat`。文本格式按 UTF-8 读取（带 BOM 的
 *      UTF-16 / UTF-32 会先转换）。
 */
object CYLTabBarConfigurationParser {

    private val formatsByPathExtension: Map<String, CYLTabBarConfigurationFormat> = mapOf(
        "json" to CYLTabBarConfigurationFormat.JSON,
        "json5" to CYLTabBarConfigurationFormat.JSON5,
        "jsonc" to CYLTabBarConfigurationFormat.JSON5,
        "plist" to CYLTabBarConfigurationFormat.PropertyList,
        "strings" to CYLTabBarConfigurationFormat.PropertyList,
        "yaml" to CYLTabBarConfigurationFormat.YAML,
        "yml" to CYLTabBarConfigurationFormat.YAML,
        "toml" to CYLTabBarConfigurationFormat.TOML,
        "ini" to CYLTabBarConfigurationFormat.INI,
        "cfg" to CYLTabBarConfigurationFormat.INI,
        "conf" to CYLTabBarConfigurationFormat.INI,
        "properties" to CYLTabBarConfigurationFormat.Properties,
        "env" to CYLTabBarConfigurationFormat.Properties,
        "xml" to CYLTabBarConfigurationFormat.XML,
        "textproto" to CYLTabBarConfigurationFormat.ProtobufText,
        "txtpb" to CYLTabBarConfigurationFormat.ProtobufText,
        "pbtxt" to CYLTabBarConfigurationFormat.ProtobufText,
        "prototxt" to CYLTabBarConfigurationFormat.ProtobufText,
        "binpb" to CYLTabBarConfigurationFormat.Protobuf,
        "pb" to CYLTabBarConfigurationFormat.Protobuf,
        "protobuf" to CYLTabBarConfigurationFormat.Protobuf,
    )

    /** [EN] `+supportedPathExtensions`, sorted. [CN] 支持的文件扩展名（已排序）。 */
    @JvmStatic
    fun supportedPathExtensions(): List<String> = formatsByPathExtension.keys.sorted()

    /** [EN] `+formatForPathExtension:`. [CN] 扩展名对应的格式。 */
    @JvmStatic
    fun formatForPathExtension(pathExtension: String?): CYLTabBarConfigurationFormat =
        pathExtension?.let { formatsByPathExtension[it.lowercase()] } ?: CYLTabBarConfigurationFormat.Unknown

    /** [EN] `+formatForMIMEType:`: the format of an HTTP Content-Type. [CN] HTTP Content-Type 对应的格式。 */
    @JvmStatic
    fun formatForMIMEType(mimeType: String?): CYLTabBarConfigurationFormat {
        val type = trimmed(mimeType?.split(';')?.firstOrNull()?.lowercase() ?: "")
        return when {
            type.isEmpty() -> CYLTabBarConfigurationFormat.Unknown
            type.contains("protobuf") || type.contains("textproto") ->
                if (type.startsWith("text/")) CYLTabBarConfigurationFormat.ProtobufText else CYLTabBarConfigurationFormat.Protobuf
            type.endsWith("json5") -> CYLTabBarConfigurationFormat.JSON5
            type.endsWith("json") -> CYLTabBarConfigurationFormat.JSON
            type.contains("yaml") -> CYLTabBarConfigurationFormat.YAML
            type.contains("toml") -> CYLTabBarConfigurationFormat.TOML
            type.contains("plist") -> CYLTabBarConfigurationFormat.PropertyList
            type.endsWith("/xml") || type.endsWith("+xml") -> CYLTabBarConfigurationFormat.Unknown
            type.contains("properties") -> CYLTabBarConfigurationFormat.Properties
            type.contains("ini") -> CYLTabBarConfigurationFormat.INI
            else -> CYLTabBarConfigurationFormat.Unknown
        }
    }

    /** [EN] `+nameOfFormat:`. [CN] 格式名称。 */
    @JvmStatic
    fun nameOfFormat(format: CYLTabBarConfigurationFormat): String = when (format) {
        CYLTabBarConfigurationFormat.JSON -> "JSON"
        CYLTabBarConfigurationFormat.JSON5 -> "JSON5"
        CYLTabBarConfigurationFormat.PropertyList -> FORMAT_PROPERTY_LIST
        CYLTabBarConfigurationFormat.YAML -> "YAML"
        CYLTabBarConfigurationFormat.TOML -> "TOML"
        CYLTabBarConfigurationFormat.INI -> "INI"
        CYLTabBarConfigurationFormat.Properties -> "Properties"
        CYLTabBarConfigurationFormat.XML -> "XML"
        CYLTabBarConfigurationFormat.ProtobufText -> FORMAT_PROTOBUF_TEXT
        CYLTabBarConfigurationFormat.Protobuf -> "Protobuf"
        CYLTabBarConfigurationFormat.Unknown -> "Unknown"
    }

    private fun sniffCandidates(trimmedText: String): List<CYLTabBarConfigurationFormat> {
        val first = trimmedText[0]
        val candidates = ArrayList<CYLTabBarConfigurationFormat>()
        if (first == '{') {
            candidates += listOf(CYLTabBarConfigurationFormat.JSON, CYLTabBarConfigurationFormat.JSON5)
        } else {
            if (first == '/' || first == '[') candidates += CYLTabBarConfigurationFormat.JSON5
            candidates += listOf(CYLTabBarConfigurationFormat.TOML, CYLTabBarConfigurationFormat.YAML, CYLTabBarConfigurationFormat.ProtobufText)
            val hasSections = trimmedText.startsWith("[") || trimmedText.contains("\n[")
            candidates += if (hasSections) listOf(CYLTabBarConfigurationFormat.INI, CYLTabBarConfigurationFormat.Properties)
                          else listOf(CYLTabBarConfigurationFormat.Properties, CYLTabBarConfigurationFormat.INI)
        }
        candidates += CYLTabBarConfigurationFormat.PropertyList
        return candidates
    }

    /** [EN] `+formatBySniffingData:`: the format of `data` by its content; `Unknown` when none fits. [CN] 按内容判断 `data` 的格式；都不匹配时为 `Unknown`。 */
    @JvmStatic
    fun formatBySniffingData(data: ByteArray): CYLTabBarConfigurationFormat {
        val utf8 = utf8DataFromData(data)
        if (dataHasPrefix(utf8, "bplist")) return CYLTabBarConfigurationFormat.PropertyList
        if (dataLooksBinary(utf8)) {
            val dictionary = try { dictionaryFromProtobuf(utf8) } catch (error: CYLTabBarConfigurationException) { null }
            return if (!dictionary.isNullOrEmpty()) CYLTabBarConfigurationFormat.Protobuf else CYLTabBarConfigurationFormat.Unknown
        }
        val content = trimmed(stringFromData(utf8) ?: "")
        if (content.isEmpty()) return CYLTabBarConfigurationFormat.Unknown
        if (content[0] == '<') {
            val isPlist = content.contains("<plist") || content.contains("DOCTYPE plist")
            return if (isPlist) CYLTabBarConfigurationFormat.PropertyList else CYLTabBarConfigurationFormat.XML
        }
        // [EN] Plain text is a valid YAML scalar, not a configuration. [CN] 纯文本是合法的 YAML 标量，但不是配置。
        return sniffCandidates(content).firstOrNull { candidate ->
            (candidate != CYLTabBarConfigurationFormat.YAML || content.contains(':')) && readsAs(utf8, candidate)
        } ?: CYLTabBarConfigurationFormat.Unknown
    }

    /** [EN] Whether `data` reads as `format` (too deep counts: the format is right). [CN] `data` 能否按 `format` 读取（过深也算：格式正确）。 */
    private fun readsAs(data: ByteArray, format: CYLTabBarConfigurationFormat): Boolean = try {
        parseData(data, format)
        true
    } catch (error: CYLTabBarConfigurationException) {
        error.code == CYLTabBarConfigurationErrorCode.TooDeep
    }

    /**
     * [EN] `+dictionaryWithData:format:error:`: parses `data` in `format` (`Unknown`: detected from the content). When the
     *      format is wrong (a syntax error) and the content is clearly another format, that one is read instead.
     * [CN] 按 `format` 解析 `data`（`Unknown` 时按内容判断）。格式不对（语法错误）且内容明显是另一种格式时，按那种格式读取。
     * @throws CYLTabBarConfigurationException [EN] with the iOS error code. [CN] 带 iOS 错误码。
     */
    @JvmStatic
    @Throws(CYLTabBarConfigurationException::class)
    fun dictionaryWithData(data: ByteArray, format: CYLTabBarConfigurationFormat): Map<String, Any?> {
        val utf8 = utf8DataFromData(data)
        val firstError = try {
            return parseData(utf8, format)
        } catch (error: CYLTabBarConfigurationException) {
            error
        }
        val retry = format != CYLTabBarConfigurationFormat.Unknown &&
            (firstError.code == CYLTabBarConfigurationErrorCode.InvalidSyntax || firstError.code == CYLTabBarConfigurationErrorCode.NotADictionary)
        if (!retry) throw firstError
        val detected = formatBySniffingData(utf8)
        // [EN] A17: a broken file is not read again as .properties, INI or Protobuf text, which accept almost anything. [CN] A17：损坏的文件不再按 .properties、INI 或 Protobuf 文本重读，它们几乎接受任何内容。
        val distinctive = detected != CYLTabBarConfigurationFormat.Properties && detected != CYLTabBarConfigurationFormat.INI &&
            detected != CYLTabBarConfigurationFormat.ProtobufText
        if (detected != CYLTabBarConfigurationFormat.Unknown && detected != format && distinctive) {
            try {
                return parseData(utf8, detected)
            } catch (ignored: CYLTabBarConfigurationException) {
                // [EN] The first error is the one reported. [CN] 报告第一个错误。
            }
        }
        throw firstError
    }

    /**
     * [EN] `+dictionaryWithContentsOfFile:error:`: the format comes from the extension, else from the content.
     * [CN] 格式来自扩展名，否则按内容判断。
     */
    @JvmStatic
    @Throws(CYLTabBarConfigurationException::class)
    fun dictionaryWithContentsOfFile(path: String): Map<String, Any?> {
        val file = File(path)
        val exists = path.isNotEmpty() && file.isFile
        val size = if (exists) file.length() else 0L
        if (size > CYLTabBarConfigurationMaximumLength) {
            throw configurationError(CYLTabBarConfigurationErrorCode.TooLarge, "\"${file.name}\" is $size bytes, more than the $CYLTabBarConfigurationMaximumLength allowed.")
        }
        val data = if (exists) try { file.readBytes() } catch (error: java.io.IOException) { null } else null
        data ?: throw configurationError(CYLTabBarConfigurationErrorCode.FileNotFound, "No configuration file at \"$path\".")
        return dictionaryWithData(data, formatForPathExtension(file.extension))
    }

    // MARK: - One format 单一格式

    private fun parseData(data: ByteArray, requested: CYLTabBarConfigurationFormat): Map<String, Any?> {
        if (data.size > CYLTabBarConfigurationMaximumLength) {
            throw configurationError(CYLTabBarConfigurationErrorCode.TooLarge, "The configuration is ${data.size} bytes, more than the $CYLTabBarConfigurationMaximumLength allowed.")
        }
        val text = stringFromData(data)
        if (data.isEmpty() || (text != null && trimmed(text).isEmpty())) {
            throw configurationError(CYLTabBarConfigurationErrorCode.Empty, "The configuration is empty.")
        }
        var format = requested
        if (format == CYLTabBarConfigurationFormat.Unknown) {
            format = formatBySniffingData(data)
            if (format == CYLTabBarConfigurationFormat.Unknown) {
                throw configurationError(CYLTabBarConfigurationErrorCode.UnsupportedFormat,
                    "The configuration format could not be detected. Supported file extensions: ${supportedPathExtensions().joinToString(", ")}.")
            }
        }
        val formatName = nameOfFormat(format)
        val result = finished(rawValue(data, text, format, formatName))
        if (result is Map<*, *> && result.isEmpty()) {
            throw configurationError(CYLTabBarConfigurationErrorCode.Empty, "$formatName configuration: no key (only whitespace or comments).")
        }
        @Suppress("UNCHECKED_CAST")
        return result as? Map<String, Any?> ?: throw configurationError(CYLTabBarConfigurationErrorCode.NotADictionary,
            "$formatName configuration: the top level must be a dictionary (key-value pairs).")
    }

    private fun rawValue(data: ByteArray, text: String?, format: CYLTabBarConfigurationFormat, formatName: String): Any? = when (format) {
        CYLTabBarConfigurationFormat.PropertyList -> propertyList(data, text, formatName)
        CYLTabBarConfigurationFormat.XML -> CYLXMLFormat.dictionary(data)
        CYLTabBarConfigurationFormat.Protobuf -> dictionaryFromProtobuf(data)
        else -> textValue(text ?: throw syntaxError(formatName, 0, "the file is not UTF-8 text"), format, formatName)
    }

    private fun textValue(text: String, format: CYLTabBarConfigurationFormat, formatName: String): Any? = when (format) {
        CYLTabBarConfigurationFormat.JSON, CYLTabBarConfigurationFormat.JSON5 -> {
            val json = (if (format == CYLTabBarConfigurationFormat.JSON5) CYLJSON5.toJSON(text) else text) ?: ""
            if (bracketDepth(json) > CYLTabBarConfigurationMaximumDepth) throw tooDeepError(formatName)
            try {
                CYLJSONReader(json).read()
            } catch (error: CYLTabBarConfigurationException) {
                throw syntaxError(formatName, 0, error.message?.removePrefix("JSON configuration: ") ?: "invalid JSON")
            }
        }
        CYLTabBarConfigurationFormat.YAML -> CYLYAMLParser(text).let { parser -> parser.parse() ?: throw (parser.error ?: syntaxError(formatName, 0, INVALID_CONTENT)) }
        CYLTabBarConfigurationFormat.TOML -> CYLTOMLParser(text.replace("\r\n", "\n").replace('\r', '\n')).let { parser ->
            parser.parse() ?: throw (parser.error ?: syntaxError(formatName, 0, INVALID_CONTENT))
        }
        CYLTabBarConfigurationFormat.INI -> CYLFlatFormats.ini(text)
        CYLTabBarConfigurationFormat.Properties -> CYLFlatFormats.properties(text)
        CYLTabBarConfigurationFormat.ProtobufText -> CYLTextProtoParser(text).let { parser ->
            parser.parseFieldsUntil(0.toChar()) ?: throw (parser.error ?: syntaxError(formatName, 0, INVALID_CONTENT))
        }
        else -> throw syntaxError(formatName, 0, INVALID_CONTENT)
    }

    private fun propertyList(data: ByteArray, text: String?, formatName: String): Any? {
        if (dataHasPrefix(data, "bplist")) {
            val plist = CYLBinaryPropertyList(data)
            if (!plist.isSafe()) {
                throw if (plist.tooDeep) tooDeepError(formatName) else syntaxError(formatName, 0, "invalid binary property list structure")
            }
            return plist.decode()
        }
        val plistText = text ?: ""
        val isXML = plistText.contains("<plist") || trimmed(plistText).startsWith("<")
        val depth = if (isXML) xmlPropertyListDepth(plistText) else bracketDepth(plistText)
        if (depth > CYLTabBarConfigurationMaximumDepth) throw tooDeepError(formatName)
        return try {
            CYLPropertyList.parse(data, text)
        } catch (error: CYLTabBarConfigurationException) {
            // [EN] A .strings file: "key" = value; lines without the braces. [CN] .strings 文件：没有花括号的 "key" = value; 行。
            if (text == null) throw error
            try {
                CYLOpenStepParser("{\n$text\n}").parseDocument()
            } catch (ignored: CYLTabBarConfigurationException) {
                throw syntaxError(formatName, 0, error.message?.removePrefix("$FORMAT_PROPERTY_LIST configuration: ") ?: INVALID_PROPERTY_LIST)
            }
        }
    }
}
