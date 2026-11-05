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

    // [EN] External entities and DTD loading are off (the iOS parser does the same, edge case A14). [CN] 关闭外部实体与 DTD 加载（iOS 解析器相同，边界情况 A14）。
    private fun parsePlist(text: String): Map<String, Any?> {
        val factory = DocumentBuilderFactory.newInstance().apply {
            isNamespaceAware = false
            isExpandEntityReferences = false
            setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true)
            setFeature("http://apache.org/xml/features/nonvalidating/load-external-dtd", false)
            setFeature("http://xml.org/sax/features/external-general-entities", false)
            setFeature("http://xml.org/sax/features/external-parameter-entities", false)
        }
        val document = factory.newDocumentBuilder().parse(org.xml.sax.InputSource(StringReader(text)))
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
        val root = LinkedHashMap<String, Any?>()
        for (name in properties.stringPropertyNames().sorted()) {
            val path = name.split('.')
            var node = root
            for (part in path.dropLast(1)) {
                @Suppress("UNCHECKED_CAST")
                node = node.getOrPut(part) { LinkedHashMap<String, Any?>() } as? LinkedHashMap<String, Any?> ?: return root
            }
            node[path.last()] = properties.getProperty(name)
        }
        return listsFromNumberedKeys(root) as Map<String, Any?>
    }

    private fun listsFromNumberedKeys(value: Any?): Any? = when (value) {
        is Map<*, *> -> {
            val converted = LinkedHashMap<String, Any?>()
            for ((key, child) in value) converted[key.toString()] = listsFromNumberedKeys(child)
            if (converted.isNotEmpty() && converted.keys.all { it.toIntOrNull() != null }) {
                converted.entries.sortedBy { it.key.toInt() }.map { it.value }
            } else {
                converted
            }
        }
        else -> value
    }
}
