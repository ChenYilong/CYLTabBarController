package com.cyl.tabbar.pages

import java.io.StringReader
import java.util.Properties
import javax.xml.XMLConstants
import javax.xml.parsers.DocumentBuilderFactory
import org.json.JSONObject
import org.w3c.dom.Element
import org.w3c.dom.Node

/**
 * [EN] The configuration formats the Android side reads, with the same keys and rules as the iOS library: JSON (the
 *      shared format), XML property lists and Java `.properties` (dotted key paths, numbers for list indexes). The
 *      parsers use only the JVM (`org.json`, `javax.xml`, `java.util.Properties`); YAML, TOML and the other iOS formats
 *      are not supported here.
 * [CN] Android 侧读取的配置格式，键与规则与 iOS 库相同：JSON（共享格式）、XML plist 与 Java `.properties`（点分隔的键路径，列表下标
 *      用数字）。解析只依赖 JVM（`org.json`、`javax.xml`、`java.util.Properties`）；YAML、TOML 与 iOS 的其他格式这里不支持。
 */
enum class TabConfigurationFormat { JSON, PLIST, PROPERTIES }

object TabConfigurationFormats {
    /** [EN] The format of a file name, by extension; null when unknown. [CN] 按扩展名判断文件格式；未知时为 null。 */
    fun formatOf(fileName: String): TabConfigurationFormat? = when (fileName.substringAfterLast('.', "").lowercase()) {
        "json", "json5", "jsonc" -> TabConfigurationFormat.JSON
        "plist" -> TabConfigurationFormat.PLIST
        "properties" -> TabConfigurationFormat.PROPERTIES
        else -> null
    }

    /**
     * [EN] The format of a text by its content: a plist starts with `<?xml` / `<plist`, JSON with `{`, otherwise properties.
     * [CN] 按内容判断格式：plist 以 `<?xml` / `<plist` 开头，JSON 以 `{` 开头，否则为 properties。
     */
    fun detect(text: String): TabConfigurationFormat {
        val trimmed = text.trimStart()
        return when {
            trimmed.startsWith("<?xml") || trimmed.startsWith("<plist") -> TabConfigurationFormat.PLIST
            trimmed.startsWith("{") -> TabConfigurationFormat.JSON
            else -> TabConfigurationFormat.PROPERTIES
        }
    }

    /** [EN] The top-level dictionary of a configuration text. [CN] 配置文本的顶层字典。 */
    fun parse(text: String, format: TabConfigurationFormat = detect(text)): Map<String, Any?> = when (format) {
        TabConfigurationFormat.JSON -> TabConfiguration.toMap(JSONObject(text))
        TabConfigurationFormat.PLIST -> parsePlist(text)
        TabConfigurationFormat.PROPERTIES -> parseProperties(text)
    }

    // [EN] JAXP property names: identifiers, not URLs that are fetched. Spelled out because Android's XMLConstants does
    //      not have them (the React Native and Flutter wrappers compile this file against android.jar).
    // [CN] JAXP 属性名：是标识符，不是会被访问的 URL。直接写出字符串，因为 Android 的 XMLConstants 没有这两个常量（React Native 与 Flutter
    //      封装会用 android.jar 编译本文件）。
    @Suppress("kotlin:S5332")
    private const val ACCESS_EXTERNAL_DTD = "http://javax.xml.XMLConstants/property/accessExternalDTD"
    @Suppress("kotlin:S5332")
    private const val ACCESS_EXTERNAL_SCHEMA = "http://javax.xml.XMLConstants/property/accessExternalSchema"

    // [EN] External entities and DTD loading are off (the iOS parser does the same, edge case A14). [CN] 关闭外部实体与 DTD 加载（iOS 解析器相同，边界情况 A14）。
    private fun parsePlist(text: String): Map<String, Any?> {
        val factory = DocumentBuilderFactory.newInstance().apply {
            isNamespaceAware = false
            isExpandEntityReferences = false
            isXIncludeAware = false
            setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true)
            // [EN] The values of XMLConstants.ACCESS_EXTERNAL_DTD / ACCESS_EXTERNAL_SCHEMA, written out: android.jar lacks those
            //      constants, and the React Native and Flutter components compile these sources against it.
            // [CN] 即 XMLConstants.ACCESS_EXTERNAL_DTD / ACCESS_EXTERNAL_SCHEMA 的值：android.jar 没有这两个常量，而 React Native 与
            //      Flutter 组件会基于它编译这些源码。
            for (attribute in listOf(ACCESS_EXTERNAL_DTD, ACCESS_EXTERNAL_SCHEMA)) {
                try {
                    setAttribute(attribute, "")
                } catch (ignored: IllegalArgumentException) {
                    // [EN] An older parser without the attribute; secure processing still applies. [CN] 旧解析器没有该属性；安全处理仍然生效。
                }
            }
        }
        val builder = factory.newDocumentBuilder()
        // [EN] The plist DOCTYPE names Apple's DTD: never fetched, an empty one is used. [CN] plist 的 DOCTYPE 指向 Apple 的 DTD：从不下载，用空的代替。
        builder.setEntityResolver { _, _ -> org.xml.sax.InputSource(StringReader("")) }
        val document = builder.parse(org.xml.sax.InputSource(StringReader(text)))
        val root = childElements(document.documentElement).firstOrNull() ?: return emptyMap()
        @Suppress("UNCHECKED_CAST")
        return plistValue(root) as? Map<String, Any?> ?: emptyMap()
    }

    private fun childElements(node: Node): List<Element> =
        (0 until node.childNodes.length).mapNotNull { node.childNodes.item(it) as? Element }

    private fun plistValue(element: Element): Any? = when (element.tagName) {
        "dict" -> {
            val children = childElements(element)
            val map = LinkedHashMap<String, Any?>()
            var index = 0
            while (index + 1 < children.size) {
                val key = children[index]
                if (key.tagName == "key") map[key.textContent] = plistValue(children[index + 1])
                index += 2
            }
            map
        }
        "array" -> childElements(element).map { plistValue(it) }
        "string", "date", "data" -> element.textContent
        "integer" -> element.textContent.trim().toLongOrNull()
        "real" -> element.textContent.trim().toDoubleOrNull()
        "true" -> true
        "false" -> false
        else -> null
    }

    /**
     * [EN] `a.b.0.c = v` becomes nested maps, and a map whose keys are all numbers becomes a list ordered by number
     *      (the iOS parser's rule).
     * [CN] `a.b.0.c = v` 变为嵌套字典；键全部为数字的字典按数字顺序变为列表（iOS 解析器的规则）。
     */
    private fun parseProperties(text: String): Map<String, Any?> {
        val properties = Properties().apply { load(StringReader(text)) }
        val root = PropertyNode()
        for (name in properties.stringPropertyNames().sorted()) {
            val path = name.split('.')
            var node = root
            for (part in path.dropLast(1)) node = node.children.getOrPut(part) { PropertyNode() }
            node.children[path.last()] = PropertyNode(properties.getProperty(name))
        }
        return root.toMap()
    }

    /** [EN] A key path tree of a properties file. [CN] properties 文件的键路径树。 */
    private class PropertyNode(val value: String? = null) {
        val children = LinkedHashMap<String, PropertyNode>()

        fun toMap(): Map<String, Any?> = children.mapValues { it.value.toValue() }

        /** [EN] A leaf is its string; a node whose keys are all numbers is a list in number order. [CN] 叶子为其字符串；键全为数字的节点为按数字排序的列表。 */
        fun toValue(): Any? = when {
            children.isEmpty() -> value
            children.keys.all { it.toIntOrNull() != null } -> children.entries.sortedBy { it.key.toInt() }.map { it.value.toValue() }
            else -> toMap()
        }
    }
}
