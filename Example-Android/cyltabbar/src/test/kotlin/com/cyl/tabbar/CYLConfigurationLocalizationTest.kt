package com.cyl.tabbar

import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.io.File
import java.util.Locale
import java.util.UUID

/**
 * [EN] `CYLTabBarControllerLocalization` on Android, as `testConfigurationFileLocalization` on iOS: a configuration file
 *      and its `.strings` tables in the same folder, the device language, a key without a translation, tables downloaded
 *      into the sandbox (`sandbox:Caches/…`), and nothing changed without the key.
 * [CN] Android 版 `CYLTabBarControllerLocalization`，与 iOS 的 `testConfigurationFileLocalization` 相同：配置文件与 `.strings` 字符串表在同一目录、
 *      设备语言、没有译文的键、下载到沙盒的字符串表（`sandbox:Caches/…`），以及没有该键时不做任何改变。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLConfigurationLocalizationTest {

    class Page : Fragment()

    private fun <T> withActivity(qualifiers: String, block: (FragmentActivity) -> T): T {
        RuntimeEnvironment.setQualifiers(qualifiers)
        val controller = Robolectric.buildActivity(FragmentActivity::class.java).setup()
        try {
            return block(controller.get())
        } finally {
            controller.pause().stop().destroy()
        }
    }

    private fun titles(activity: FragmentActivity, configuration: Map<String, Any?>): List<Map<String, Any?>> {
        val withPages = configuration + (CYLConstants.CYLTabBarControllerViewControllers to listOf(Page(), Page()))
        return CYLTabBarController(activity, withPages).tabBarItemsAttributes
    }

    private fun writeTables(folder: File) {
        File(folder, "Texts/en.lproj").apply { mkdirs() }.resolve("Tabs.strings")
            .writeText("\"tab.home\" = \"Home\";\n\"tab.me\" = \"Me\";\n\"tab.home.selected\" = \"Refresh\";\n")
        File(folder, "Texts/zh-Hans.lproj").apply { mkdirs() }.resolve("Tabs.strings")
            .writeText("/* 简体中文 */\n\"tab.home\" = \"首页\";\n\"tab.me\" = \"我的\";\n\"tab.home.selected\" = \"刷新\";\n")
    }

    private val json = """{"CYLTabBarControllerLocalization": {"CYLTabBarLocalizationTableName": "Tabs", "CYLTabBarLocalizationPath": "Texts"},
        "CYLTabBarControllerTabBarItemsAttributes": [
        {"CYLTabBarItemIdentifier": "home", "CYLTabBarItemTitle": "tab.home", "CYLTabBarItemSelectedTitle": "tab.home.selected", "CYLTabBarItemAccessibilityHint": "tab.missing"},
        {"CYLTabBarItemIdentifier": "me", "CYLTabBarItemTitle": "tab.me"}]}"""

    @Test
    fun aConfigurationFileFindsItsTablesNextToIt() {
        val folder = File(System.getProperty("java.io.tmpdir"), "cyl-localization-" + UUID.randomUUID()).apply { mkdirs() }
        writeTables(folder)
        val file = File(folder, "tabs.json").apply { writeText(json) }
        withActivity("en") { activity ->
            val items = titles(activity, CYLTabBarConfiguration.configurationWithContentsOfFile(activity, file.path))
            assertEquals("Home", items[0][CYLConstants.CYLTabBarItemTitle])
            assertEquals("Refresh", items[0][CYLConstants.CYLTabBarItemSelectedTitle])
            assertEquals("a key without a translation stays", "tab.missing", items[0][CYLConstants.CYLTabBarItemAccessibilityHint])
            assertEquals("Me", items[1][CYLConstants.CYLTabBarItemTitle])
        }
        withActivity("zh-rCN") { activity ->
            val items = titles(activity, CYLTabBarConfiguration.configurationWithContentsOfFile(activity, file.path))
            assertEquals("首页", items[0][CYLConstants.CYLTabBarItemTitle])
            assertEquals("我的", items[1][CYLConstants.CYLTabBarItemTitle])
        }
        folder.deleteRecursively()
    }

    @Test
    fun tablesDownloadedIntoTheSandboxAndNoKey() {
        withActivity("en") { activity ->
        val downloaded = "cyl-localization-" + UUID.randomUUID()
        File(activity.cacheDir, "$downloaded/en.lproj").apply { mkdirs() }.resolve("Localizable.strings").writeText("\"tab.home\" = \"Downloaded home\";")
        val items = titles(activity, mapOf(
            CYLConstants.CYLTabBarControllerLocalization to mapOf(CYLConstants.CYLTabBarLocalizationPath to "sandbox:Caches/$downloaded"),
            CYLConstants.CYLTabBarControllerTabBarItemsAttributes to listOf(mapOf(CYLConstants.CYLTabBarItemIdentifier to "home", CYLConstants.CYLTabBarItemTitle to "tab.home")),
        ))
        assertEquals("Downloaded home", items[0][CYLConstants.CYLTabBarItemTitle])
        val plain = titles(activity, mapOf(
            CYLConstants.CYLTabBarControllerTabBarItemsAttributes to listOf(mapOf(CYLConstants.CYLTabBarItemIdentifier to "home", CYLConstants.CYLTabBarItemTitle to "tab.home")),
        ))
        assertEquals("tab.home", plain[0][CYLConstants.CYLTabBarItemTitle])
        File(activity.cacheDir, downloaded).deleteRecursively()
        }
    }

    @Test
    fun stringsFilesAndLanguageNamesAsOnIOS() {
        val parsed = CYLTabBarConfigurationLocalization.parseStrings(
            "// comment\n\"a\" = \"A \\\"quoted\\\"\";\n/* block */ \"b\"=\"line\\nbreak\";\n\"c\" = \"\\U00e9\";".toByteArray())
        assertEquals(mapOf("a" to "A \"quoted\"", "b" to "line\nbreak", "c" to "é"), parsed)
        val utf16 = byteArrayOf(0xFF.toByte(), 0xFE.toByte()) + "\"k\" = \"值\";".toByteArray(Charsets.UTF_16LE)
        assertEquals(mapOf("k" to "值"), CYLTabBarConfigurationLocalization.parseStrings(utf16))
        assertEquals(listOf("zh-Hans", "zh", "Base", "en"), CYLTabBarConfigurationLocalization.candidates(Locale.SIMPLIFIED_CHINESE))
        assertEquals(listOf("zh-Hant", "zh", "Base", "en"), CYLTabBarConfigurationLocalization.candidates(Locale.TRADITIONAL_CHINESE))
        assertEquals(listOf("pt-BR", "pt", "Base", "en"), CYLTabBarConfigurationLocalization.candidates(Locale("pt", "BR")))
    }
}
