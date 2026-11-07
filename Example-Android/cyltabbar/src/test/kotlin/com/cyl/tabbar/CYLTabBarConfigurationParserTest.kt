package com.cyl.tabbar

import java.io.File
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test

/**
 * [EN] The checks of scripts/configuration-tests (ConfigurationParserTests.m) for the Kotlin parser: the 17 samples of the
 *      iOS bundle, the edge-case files of make-fixtures.py with their expected error codes and values, and the exported
 *      configuration files of every Example. Values are compared with `-[NSObject isEqual:]` semantics (numbers by value,
 *      booleans as 1 / 0, protobuf map entries as dictionaries).
 * [CN] 用 scripts/configuration-tests（ConfigurationParserTests.m）的检查验证 Kotlin 解析器：iOS bundle 的 17 个示例、make-fixtures.py 生成的
 *      边界情况文件及其预期错误码与值，以及每个 Example 导出的配置文件。值按 `-[NSObject isEqual:]` 的语义比较（数字按值、布尔值为 1 / 0、
 *      protobuf map 条目视为字典）。
 */
class CYLTabBarConfigurationParserTest {

    private val root: File = generateSequence(File(".").absoluteFile) { it.parentFile }.first { File(it, "CYLTabBarController.podspec").exists() }
    private val samples = File(root, "CYLTabBarController/Resources/CYLTabBarController.bundle/Configurations")

    private fun parse(file: File, sniff: Boolean): Map<String, Any?> =
        if (sniff) CYLTabBarConfigurationParser.dictionaryWithData(file.readBytes(), CYLTabBarConfigurationFormat.Unknown)
        else CYLTabBarConfigurationParser.dictionaryWithContentsOfFile(file.path)

    private fun attempt(file: File, sniff: Boolean): Pair<Map<String, Any?>?, CYLTabBarConfigurationException?> = try {
        parse(file, sniff) to null
    } catch (error: CYLTabBarConfigurationException) {
        null to error
    }

    /** [EN] `CYLNormalized` of the iOS test, with NSNumber equality. [CN] iOS 测试的 `CYLNormalized`，按 NSNumber 判断相等。 */
    private fun normalized(value: Any?): Any? = when (value) {
        is Boolean -> if (value) 1.0 else 0.0
        is Number -> value.toDouble()
        is List<*> -> {
            val entries = value.isNotEmpty() && value.all { it is Map<*, *> && it.size == 2 && it.containsKey("key") }
            if (entries) value.associate { (it as Map<*, *>)["key"] to normalized(it["value"]) } else value.map { normalized(it) }
        }
        is Map<*, *> -> if (value.size == 2 && value.containsKey("key") && value.containsKey("value")) mapOf(value["key"] to normalized(value["value"]))
                         else value.mapValues { normalized(it.value) }
        else -> value
    }

    private fun comparable(dictionary: Map<String, Any?>?): Map<*, *>? {
        val normalized = normalized(dictionary) as? Map<*, *> ?: return null
        val items = normalized["CYLTabBarControllerTabBarItemsAttributes"]
        return if (items is Map<*, *>) normalized + ("CYLTabBarControllerTabBarItemsAttributes" to listOf(items)) else normalized
    }

    private fun valueAtPath(rootValue: Any?, path: String): Any? = path.split('.').fold(rootValue) { value, part ->
        when (value) {
            is List<*> -> value.getOrNull(part.toIntOrNull() ?: -1)
            is Map<*, *> -> value[part]
            else -> null
        }
    }

    private fun itemsWithoutFirstTitle(dictionary: Map<String, Any?>?): List<Any?>? {
        val items = (comparable(dictionary)?.get("CYLTabBarControllerTabBarItemsAttributes") as? List<*>)?.toMutableList() ?: return null
        if (items.isNotEmpty()) items[0] = (items[0] as Map<*, *>) + ("CYLTabBarItemTitle" to "<format>")
        return items
    }

    @Test
    fun protobufReadsTheGIFFields57To61() {
        // [EN] An item with field 58 (`CYLTabBarGIFFilePath`, tag 58 << 3 | 2 = 0xD2 0x03) inside top-level field 1. [CN] 顶层字段 1 中带字段 58 的 item。
        val path = "tab_home.gif".toByteArray()
        val item = byteArrayOf(0xD2.toByte(), 0x03, path.size.toByte()) + path
        val message = byteArrayOf(0x0A, item.size.toByte()) + item
        val configuration = CYLTabBarConfigurationParser.dictionaryWithData(message, CYLTabBarConfigurationFormat.Protobuf)
        @Suppress("UNCHECKED_CAST")
        val items = configuration["CYLTabBarControllerTabBarItemsAttributes"] as List<Map<String, Any?>>
        assertEquals("tab_home.gif", items[0]["CYLTabBarGIFFilePath"])
    }

    @Test
    fun everySampleGivesTheTabsOfTheJSONSample() {
        val expected = itemsWithoutFirstTitle(parse(File(samples, "cyl_tabbar_configuration.json"), false))
        assertNotNull(expected)
        val files = samples.listFiles().orEmpty().filter { !it.name.endsWith(".proto") && !it.name.startsWith(".") }.sortedBy { it.name }
        assertEquals("the 17 samples", 17, files.size)
        val failures = ArrayList<String>()
        for (file in files) for (sniff in listOf(false, true)) {
            val (parsed, error) = attempt(file, sniff)
            if (itemsWithoutFirstTitle(parsed) != expected) failures += "${file.name} (${if (sniff) "content" else "extension"}): ${error?.message ?: "different dictionary"}"
        }
        assertTrue(failures.joinToString("\n"), failures.isEmpty())
    }

    private fun fixtures(): File? {
        val folder = File(root, "Example-Android/cyltabbar/build/tmp/cyl-configuration-fixtures")
        val process = try {
            ProcessBuilder("python3", File(root, "scripts/configuration-tests/make-fixtures.py").path, folder.path).redirectErrorStream(true).start()
        } catch (error: java.io.IOException) {
            return null
        }
        process.inputStream.readBytes()
        return if (process.waitFor(120, TimeUnit.SECONDS) && process.exitValue() == 0) folder else null
    }

    @Test
    fun edgeCasesGiveTheExpectedResults() {
        val folder = fixtures()
        assumeTrue("python3 is needed to write the fixtures (make-fixtures.py)", folder != null)
        // [EN] The manifest is a JSON array: wrapped, so the parser reads it as a dictionary. [CN] 清单是 JSON 数组：包装后作为字典读取。
        val manifestText = "{\"cases\": " + File(folder, "manifest.json").readText() + "}"
        val cases = CYLTabBarConfigurationParser.dictionaryWithData(manifestText.toByteArray(), CYLTabBarConfigurationFormat.JSON)["cases"] as List<*>
        assertTrue(cases.size >= 40)
        val failures = ArrayList<String>()
        for (case in cases.map { it as Map<*, *> }) {
            val file = File(folder, case["file"] as String)
            for (sniff in listOf(false, true)) checkCase(case, file, folder!!, sniff, failures)
        }
        assertTrue(failures.joinToString("\n"), failures.isEmpty())
    }

    private fun checkCase(case: Map<*, *>, file: File, folder: File, sniff: Boolean, failures: MutableList<String>) {
        val mode = if (sniff) "content" else "extension"
        val label = "[${case["case"]}] ${file.name} ($mode)"
        val expect = case["expect"]
        val (parsed, error) = attempt(file, sniff)
        if (expect !is String) {
            val code = (expect as Number).toInt()
            if (!sniff && (parsed != null || error?.code?.rawValue != code)) failures += "$label: expected error $code, got ${error?.let { "${it.code.rawValue} ${it.message}" } ?: "a dictionary"}"
            return
        }
        if (parsed == null) {
            failures += "$label: expected a dictionary, got error ${error?.code?.rawValue} ${error?.message}"
            return
        }
        (case["equals"] as? String)?.let { equals ->
            if (comparable(parsed) != comparable(parse(File(folder, equals), false))) failures += "$label: not equal to $equals: $parsed"
        }
        (case["values"] as? Map<*, *>)?.forEach { (path, wanted) ->
            val value = valueAtPath(parsed, path as String)
            if (value == null || normalized(value) != normalized(wanted)) failures += "$label: $path is $value, expected $wanted"
        }
    }

    @Test
    fun everyExportedExampleConfigurationReadsTheSameInEveryFormat() {
        val folders = root.listFiles().orEmpty().filter { it.name.startsWith("Example") }.map { File(it, "Configurations") }.filter { it.isDirectory }
        assertTrue("exported configurations", folders.isNotEmpty())
        val failures = ArrayList<String>()
        val checks = folders.sumOf { compareExports(it, failures) }
        assertTrue("files compared", checks > folders.size)
        assertTrue(failures.joinToString("\n"), failures.isEmpty())
    }

    /** [EN] Compares every format of each JSON export of `folder` with the JSON; returns the number of comparisons. [CN] 将 `folder` 中每个 JSON 导出的各种格式与 JSON 比较；返回比较次数。 */
    private fun compareExports(folder: File, failures: MutableList<String>): Int {
        val files = folder.listFiles().orEmpty().sortedBy { it.name }
        var checks = 0
        for (json in files.filter { it.extension == "json" }) {
            val reference = comparable(parse(json, false))
            for (file in files.filter { it.name.startsWith(json.nameWithoutExtension + ".") }) {
                checks += 2
                compareFormat(file, reference, failures)
            }
        }
        return checks
    }

    /** [EN] One exported file, read by its extension and by its content, against the JSON. [CN] 一个导出文件，分别按扩展名与内容读取，与 JSON 比较。 */
    private fun compareFormat(file: File, reference: Any?, failures: MutableList<String>) {
        for (sniff in listOf(false, true)) {
            val (parsed, error) = attempt(file, sniff)
            if (parsed == null || comparable(parsed) != reference) {
                failures += "${file.parentFile?.parentFile?.name}/${file.name} (${if (sniff) "content" else "extension"}): ${error?.message ?: "different dictionary"}"
            }
        }
    }

    @Test
    fun detectionAndNamesFollowIOS() {
        assertEquals(CYLTabBarConfigurationFormat.JSON5, CYLTabBarConfigurationParser.formatForPathExtension("JSONC"))
        assertEquals(CYLTabBarConfigurationFormat.Unknown, CYLTabBarConfigurationParser.formatForPathExtension(null))
        assertEquals(CYLTabBarConfigurationFormat.YAML, CYLTabBarConfigurationParser.formatForMIMEType("application/x-yaml; charset=utf-8"))
        assertEquals(CYLTabBarConfigurationFormat.ProtobufText, CYLTabBarConfigurationParser.formatForMIMEType("text/x-protobuf"))
        assertEquals(CYLTabBarConfigurationFormat.Protobuf, CYLTabBarConfigurationParser.formatForMIMEType("application/x-protobuf"))
        assertEquals(CYLTabBarConfigurationFormat.Unknown, CYLTabBarConfigurationParser.formatForMIMEType("text/xml"))
        assertEquals("Protobuf text", CYLTabBarConfigurationParser.nameOfFormat(CYLTabBarConfigurationFormat.ProtobufText))
        assertEquals(21, CYLTabBarConfigurationParser.supportedPathExtensions().size)
        assertEquals(CYLTabBarConfigurationFormat.TOML, CYLTabBarConfigurationParser.formatBySniffingData("a = \"b\"\n[c]\nd = 1\n".toByteArray()))
        assertEquals(CYLTabBarConfigurationFormat.YAML, CYLTabBarConfigurationParser.formatBySniffingData("a:\n  - b: c\n".toByteArray()))
        assertEquals(5 * 1024 * 1024, CYLTabBarConfigurationMaximumLength)
        assertEquals(64, CYLTabBarConfigurationMaximumDepth)
        assertEquals("CYLTabBarConfigurationErrorDomain", CYLTabBarConfigurationErrorDomain)
        val missing = try {
            CYLTabBarConfigurationParser.dictionaryWithContentsOfFile("/no/such/file.json")
            null
        } catch (error: CYLTabBarConfigurationException) {
            error
        }
        assertEquals(CYLTabBarConfigurationErrorCode.FileNotFound, missing?.code)
    }
}
