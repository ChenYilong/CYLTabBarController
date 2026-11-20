package com.cyl.tabbar

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.cyl.tabbar.CYLTabBarConfiguration.CYLConfigurationException
import com.cyl.tabbar.CYLTabBarConfiguration.CYLTabBarConfigurationError
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File

/**
 * [EN] What the study of Firebase Remote Config added (docs/Configuration-File.md, "Versions and routes"): the version of a
 *      configuration as a whole, read from a template's `version` and compared as numbers that only grow; and a route that is
 *      an ordered list (the downloaded file first, the built-in one after it) with the source of the resource named as
 *      Remote Config names the source of a value.
 * [CN] 研究 Firebase Remote Config 之后增加的内容（docs/Configuration-File.md，“Versions and routes”）：整份配置的版本，读取自模板的 `version`，按只增不减
 *      的数字比较；以及有序列表形式的路由（先下载的文件、后内置的文件），资源来源的命名与 Remote Config 对值来源的命名一致。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLConfigurationVersionAndRoutesTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private lateinit var folder: File

    @Before
    fun setUp() {
        folder = File(context.cacheDir, "cyl-version-test-" + java.util.UUID.randomUUID())
        assertTrue(folder.mkdirs())
    }

    @After
    fun tearDown() {
        folder.deleteRecursively()
    }

    private fun write(text: String, name: String) {
        File(folder, name).apply { parentFile?.mkdirs() }.writeText(text)
    }

    private val tabs = listOf(mapOf("CYLTabBarItemIdentifier" to "home", "CYLTabBarItemTitle" to "Home"))

    private fun configuration(version: Any?, style: String = "default"): Map<String, Any?> {
        val configuration = linkedMapOf<String, Any?>("CYLTabBarControllerStyleType" to style, "CYLTabBarControllerTabBarItemsAttributes" to tabs)
        if (version != null) configuration["CYLTabBarControllerConfigurationVersion"] = mapOf("versionNumber" to version)
        return configuration
    }

    // MARK: - Versions 版本

    @Test
    fun aTemplatesVersionBecomesTheVersionOfTheConfiguration() {
        // [EN] The REST API writes the int64 versionNumber as a string. [CN] REST API 把 int64 的 versionNumber 写成字符串。
        val template = """{"version": {"versionNumber": "12", "updateTime": "2026-11-20T01:02:03Z", "description": "winter skin",
            "updateOrigin": "CONSOLE", "updateType": "INCREMENTAL_UPDATE", "updateUser": {"email": "someone@example.com"}},
            "parameters": {"CYLTabBarControllerStyleType": {"defaultValue": {"value": "flatDesign"}, "valueType": "STRING"},
              "CYLTabBarControllerTabBarItemsAttributes": {"defaultValue": {"value": "[{\"CYLTabBarItemTitle\": \"Home\"}]"}, "valueType": "JSON"}}}"""
        val configuration = CYLTabBarConfigurationParser.dictionaryWithData(template.toByteArray(), CYLTabBarConfigurationFormat.JSON)
        assertEquals(12L, CYLTabBarConfiguration.versionNumber(configuration))
        @Suppress("UNCHECKED_CAST")
        val version = configuration["CYLTabBarControllerConfigurationVersion"] as Map<String, Any?>
        assertEquals("winter skin", version["description"])
        assertEquals("CONSOLE", version["updateOrigin"])
        assertFalse("who published it is not copied into the app", version.containsKey("updateUser"))
        assertEquals("flatDesign", configuration["CYLTabBarControllerStyleType"])
        // [EN] A version alone, with no "CYL…" parameter, is still an empty template. [CN] 只有版本、没有 "CYL…" 参数的模板仍是空模板。
        val empty = """{"version": {"versionNumber": "3"}, "parameters": {"welcome_message": {"defaultValue": {"value": "Hi"}}}}"""
        try {
            CYLTabBarConfigurationParser.dictionaryWithData(empty.toByteArray(), CYLTabBarConfigurationFormat.JSON)
            fail("expected the Empty error")
        } catch (error: CYLTabBarConfigurationException) {
            assertEquals(CYLTabBarConfigurationErrorCode.Empty, error.code)
        }
    }

    @Test
    fun versionNumberReadsNumbersAndNumericStrings() {
        assertEquals(7L, CYLTabBarConfiguration.versionNumber(configuration(7)))
        assertEquals(8L, CYLTabBarConfiguration.versionNumber(configuration(" 8 ")))
        assertNull(CYLTabBarConfiguration.versionNumber(configuration("x")))
        assertNull(CYLTabBarConfiguration.versionNumber(configuration(null)))
    }

    private class Source(private val values: Map<String, Any?>) : CYLRemoteConfigSource {
        override val identifier = "firebase"
        override fun fetch(completion: (CYLRemoteConfigPayload?, Throwable?) -> Unit) = completion(CYLRemoteConfigPayload("firebase", values), null)
    }

    private fun load(defaults: Map<String, Any?>, remoteVersion: Any?): CYLRemoteConfigResult {
        var result: CYLRemoteConfigResult? = null
        val values = mutableMapOf<String, Any?>("CYLTabBarControllerStyleType" to "flatDesign")
        if (remoteVersion != null) values["CYLTabBarControllerConfigurationVersion"] = """{"versionNumber": $remoteVersion}"""
        CYLRemoteConfigLoader(Source(values)).load(defaults) { result = it }
        return result!!
    }

    @Test
    fun aRemoteConfigurationOlderThanTheAppsOwnIsRefused() {
        val defaults = configuration(10)
        assertTrue("higher", load(defaults, 11).isRemote)
        assertTrue("the same number: the fetched values apply", load(defaults, 10).isRemote)
        val stale = load(defaults, 9)
        assertFalse(stale.isRemote)
        assertEquals(defaults, stale.configuration)
        assertEquals(CYLTabBarConfigurationError.NotEligible, (stale.error as CYLConfigurationException).error)
        assertTrue("no number in the remote values: they apply", load(defaults, null).isRemote)
        assertTrue("no number in the defaults: they apply", load(configuration(null), 1).isRemote)
        // [EN] A rollback is a new, higher number with old content, so it applies. [CN] 回滚是带旧内容的新的更大编号，因此会被应用。
        assertEquals(12L, CYLTabBarConfiguration.versionNumber(load(defaults, 12).configuration))
    }

    // MARK: - Routes 路由

    @Test
    fun anOrderedListOfRoutesTakesTheFirstFileThatExists() {
        write("""{"CYLTabBarControllerStyleType": "downloaded", "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home"}]}""", "tabbar@2.0.json")
        val downloaded = "sandbox:Caches/${folder.name}?name=tabbar"
        val missing = "sandbox:Caches/${folder.name}/nothing?name=tabbar"
        val builtIn = "bundle:Configurations?name=tabbar"

        assertEquals("downloaded", CYLTabBarConfiguration.configurationWithRoutes(context, listOf(downloaded, builtIn))["CYLTabBarControllerStyleType"])
        assertEquals("a route with no file is skipped", "downloaded",
            CYLTabBarConfiguration.configurationWithRoutes(context, listOf(missing, downloaded))["CYLTabBarControllerStyleType"])
        try {
            CYLTabBarConfiguration.configurationWithRoutes(context, listOf(missing, builtIn))
            fail("expected FileNotFound")
        } catch (error: CYLConfigurationException) {
            assertEquals(CYLTabBarConfigurationError.FileNotFound, error.error)
        }
        assertEquals(CYLResourceRoute.Source.Sandbox, CYLTabBarConfiguration.sourceOfRoutes(context, listOf(missing, downloaded, builtIn)))
        assertNull(CYLTabBarConfiguration.sourceOfRoutes(context, listOf(missing, builtIn)))

        // [EN] The configuration key takes the list too, and the dictionary's other keys still win. [CN] 配置键同样接受列表，字典中的其他键仍然优先。
        val merged = CYLTabBarConfiguration.withRoutedFile(context, mapOf(
            CYLConstants.CYLTabBarControllerConfigurationRoute to listOf(missing, downloaded, builtIn),
            "CYLTabBarControllerStyleType" to "code"))
        assertEquals("code", merged["CYLTabBarControllerStyleType"])
        assertTrue(merged[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] is List<*>)
        assertFalse(merged.containsKey(CYLConstants.CYLTabBarControllerConfigurationRoute))
    }

    @Test
    fun theSourceNamesWhereTheResourceComesFrom() {
        fun source(route: String, base: String? = null) = CYLResourceRoute.locationForRoute(context, route, base)!!.source
        assertEquals(CYLResourceRoute.Source.Bundle, source("bundle:Configurations"))
        assertEquals(CYLResourceRoute.Source.Bundle, source("Texts", "asset:Configurations"))
        assertEquals(CYLResourceRoute.Source.Bundle, source("Texts"))
        assertEquals(CYLResourceRoute.Source.Sandbox, source("sandbox:Caches/x"))
        assertEquals(CYLResourceRoute.Source.Sandbox, source("sandbox:Documents/x"))
        assertEquals(CYLResourceRoute.Source.Local, source("file:///var/tmp/x"))
        assertEquals(CYLResourceRoute.Source.Local, source("/var/tmp/x"))
        assertEquals(CYLResourceRoute.Source.Local, source("~/x"))
        // [EN] The query keeps the source of the folder it picks from. [CN] 查询参数保留所选目录的来源。
        write("{}", "tabbar@1.0.json")
        assertEquals(CYLResourceRoute.Source.Sandbox, source("sandbox:Caches/${folder.name}?name=tabbar"))
    }
}
