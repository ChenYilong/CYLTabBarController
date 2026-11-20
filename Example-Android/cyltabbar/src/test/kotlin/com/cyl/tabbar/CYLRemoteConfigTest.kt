package com.cyl.tabbar

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] Firebase Remote Config, without Firebase (docs/Configuration-File.md, "Firebase Remote Config"): the same tests as
 *      the iOS `CYLTabBarHostViewTests` (`testRemoteConfig…`). Values, the whole-file parameter, a template JSON and a
 *      `remote_config_defaults.xml` give the configuration of the `.json` file; invalid values keep the defaults.
 * [CN] Firebase Remote Config，但不依赖 Firebase（docs/Configuration-File.md，“Firebase Remote Config”）：与 iOS 的 `CYLTabBarHostViewTests`
 *      （`testRemoteConfig…`）相同的测试。值、整个文件参数、模板 JSON 与 `remote_config_defaults.xml` 都得到 `.json` 文件的配置；无效的值保留默认值。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLRemoteConfigTest {

    private val json = """{"CYLTabBarControllerStyleType": "flatDesign", "CYLTabBarControllerContext": "remote",
        "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemIdentifier": "home", "CYLTabBarItemTitle": "Home"},
        {"CYLTabBarItemIdentifier": "me", "CYLTabBarItemTitle": "Me"}],
        "CYLTabBarControllerPlusButton": {"CYLTabBarItemTitle": "Post", "CYLTabBarItemImage": "post"}}"""

    private val expected: Map<String, Any?>
        get() = CYLTabBarConfigurationParser.dictionaryWithData(json.toByteArray(), CYLTabBarConfigurationFormat.JSON)

    private val values = mapOf(
        "CYLTabBarControllerStyleType" to "flatDesign",
        "CYLTabBarControllerContext" to "remote",
        "CYLTabBarControllerTabBarItemsAttributes" to
            """[{"CYLTabBarItemIdentifier": "home", "CYLTabBarItemTitle": "Home"}, {"CYLTabBarItemIdentifier": "me", "CYLTabBarItemTitle": "Me"}]""",
        "CYLTabBarControllerPlusButton" to """{"CYLTabBarItemTitle": "Post", "CYLTabBarItemImage": "post"}""",
    )

    @Test
    fun valuesGiveTheConfigurationOfTheJSONFile() {
        // [EN] The app's other parameters and empty values are left out. [CN] App 的其他参数与空值会被忽略。
        val configuration = CYLTabBarConfiguration.configurationWithRemoteConfigValues(
            values + mapOf("welcome_message" to "Hello", "CYLTabBarControllerThemeIdentifier" to ""))
        assertEquals(expected, configuration)
    }

    @Test
    fun wholeConfigurationParameter() {
        assertEquals(expected, CYLTabBarConfigurationParser.dictionaryWithRemoteConfigValues(mapOf("CYLTabBarConfiguration" to json)))
        // [EN] A flat parameter replaces the key of the whole configuration. [CN] 扁平参数替换完整配置中的 key。
        val both = CYLTabBarConfigurationParser.dictionaryWithRemoteConfigValues(
            mapOf("CYLTabBarConfiguration" to json, "CYLTabBarControllerStyleType" to "liquidGlass"))
        assertEquals("liquidGlass", both["CYLTabBarControllerStyleType"])
        assertEquals(expected["CYLTabBarControllerPlusButton"], both["CYLTabBarControllerPlusButton"])
    }

    @Test
    fun templateAndAndroidDefaultsFiles() {
        val parameters = values.entries.joinToString(", ") { (key, value) ->
            val type = if (value.startsWith("{") || value.startsWith("[")) "JSON" else "STRING"
            "\"$key\": {\"defaultValue\": {\"value\": ${quoted(value)}}, \"valueType\": \"$type\"}"
        }
        // [EN] A parameter that uses the in-app default is left out. [CN] 使用 App 内默认值的参数会被忽略。
        val template = """{"parameters": {$parameters, "CYLTabBarControllerThemeIdentifier": {"defaultValue": {"useInAppDefault": true}}},
            "version": {"versionNumber": "7"}}"""
        // [EN] The template's `version` is the version of the configuration (docs/Configuration-File.md, "Versions and routes"). [CN] 模板的 `version` 是配置的版本。
        assertEquals(expected + ("CYLTabBarControllerConfigurationVersion" to mapOf("versionNumber" to 7L)),
            CYLTabBarConfigurationParser.dictionaryWithData(template.toByteArray(), CYLTabBarConfigurationFormat.Unknown))
        val entries = values.entries.joinToString("\n") { (key, value) ->
            "  <entry><key>$key</key><value>${value.replace("&", "&amp;").replace("<", "&lt;")}</value></entry>"
        }
        val xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<defaultsMap>\n$entries\n</defaultsMap>\n"
        assertEquals(expected, CYLTabBarConfigurationParser.dictionaryWithData(xml.toByteArray(), CYLTabBarConfigurationFormat.XML))
        // [EN] An iOS defaults property list: nested values as JSON strings, a geometry string kept.
        // [CN] iOS 默认值属性列表：嵌套的值为 JSON 字符串，几何字符串保持不变。
        val plistEntries = (values + ("CYLTabBarControllerTitlePositionAdjustment" to "{0, -2}")).entries.joinToString("\n") { (key, value) ->
            "<key>$key</key><string>${value.replace("&", "&amp;").replace("<", "&lt;")}</string>"
        }
        val plist = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<plist version=\"1.0\"><dict>\n$plistEntries\n</dict></plist>\n"
        assertEquals(expected + ("CYLTabBarControllerTitlePositionAdjustment" to "{0, -2}"),
            CYLTabBarConfigurationParser.dictionaryWithData(plist.toByteArray(), CYLTabBarConfigurationFormat.PropertyList))
    }

    @Test
    fun geometryAsJSONArraysOrAsStringsIsTheSame() {
        // [EN] Remote Config's JSON type holds arrays; the file formats' "{0, -2}" strings keep working (A1 of the audit in
        //      docs/Configuration-File.md): both read as the same inset and offset. A title that looks like a geometry stays text.
        // [CN] Remote Config 的 JSON 类型存数组；文件格式中的 "{0, -2}" 字符串仍可使用（docs/Configuration-File.md 审计中的 A1）：两种写法读出相同的内边距与偏移。
        //      看起来像几何值的标题仍是文本。
        val arrays = CYLTabBarConfiguration.configurationWithRemoteConfigValues(values + mapOf(
            "CYLTabBarControllerImageInsets" to "[1,0,-1,0]",
            "CYLTabBarControllerTitlePositionAdjustment" to "[0,-2]"))
        val strings = CYLTabBarConfiguration.configurationWithRemoteConfigValues(values + mapOf(
            "CYLTabBarControllerImageInsets" to "{1, 0, -1, 0}",
            "CYLTabBarControllerTitlePositionAdjustment" to "{0, -2}"))
        assertEquals(CYLEdgeInsets(1f, 0f, -1f, 0f), CYLTabBarConfiguration.edgeInsetsValue(arrays["CYLTabBarControllerImageInsets"]))
        assertEquals(CYLEdgeInsets(1f, 0f, -1f, 0f), CYLTabBarConfiguration.edgeInsetsValue(strings["CYLTabBarControllerImageInsets"]))
        assertEquals(CYLTabBarConfiguration.offsetValue(strings["CYLTabBarControllerTitlePositionAdjustment"]),
            CYLTabBarConfiguration.offsetValue(arrays["CYLTabBarControllerTitlePositionAdjustment"]))
        assertEquals(CYLOffset(0f, -2f), CYLTabBarConfiguration.offsetValue(arrays["CYLTabBarControllerTitlePositionAdjustment"]))
        val text = CYLTabBarConfiguration.configurationWithRemoteConfigValues(values + mapOf("CYLTabBarControllerContext" to "{1}"))
        assertEquals("{1}", text["CYLTabBarControllerContext"])
    }

    @Test
    fun invalidValuesKeepTheDefaults() {
        assertError(CYLTabBarConfiguration.CYLTabBarConfigurationError.InvalidSyntax, "CYLTabBarControllerPlusButton") {
            CYLTabBarConfiguration.configurationWithRemoteConfigValues(values + ("CYLTabBarControllerPlusButton" to """{"CYLTabBarItemTitle": """))
        }
        assertError(CYLTabBarConfiguration.CYLTabBarConfigurationError.Empty, null) {
            CYLTabBarConfiguration.configurationWithRemoteConfigValues(mapOf("welcome_message" to "Hello"))
        }
        assertError(CYLTabBarConfiguration.CYLTabBarConfigurationError.NoTabs, null) {
            CYLTabBarConfiguration.configurationWithRemoteConfigValues(mapOf("CYLTabBarControllerStyleType" to "flatDesign"))
        }
        assertError(CYLTabBarConfiguration.CYLTabBarConfigurationError.InvalidSyntax, null) {
            CYLTabBarConfiguration.configurationWithRemoteConfigValues(mapOf("CYLTabBarConfiguration" to "{ not a configuration"))
        }
    }

    private fun assertError(error: CYLTabBarConfiguration.CYLTabBarConfigurationError, mention: String?, block: () -> Unit) {
        try {
            block()
            fail("expected $error")
        } catch (exception: CYLTabBarConfiguration.CYLConfigurationException) {
            assertEquals(error, exception.error)
            if (mention != null) assertTrue(exception.message, exception.message?.contains(mention) == true)
        }
    }

    private fun quoted(value: String): String = "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
}
