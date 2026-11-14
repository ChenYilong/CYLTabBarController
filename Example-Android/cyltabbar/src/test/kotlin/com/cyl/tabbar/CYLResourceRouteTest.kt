package com.cyl.tabbar

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
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
 * [EN] `CYLResourceRoute` (docs/Resource-Routes.md) and the configuration functions that take a route; the same cases as
 *      the iOS `CYLResourceRouteTests`.
 * [CN] `CYLResourceRoute`（docs/Resource-Routes.md）以及接受路由的配置方法；与 iOS 的 `CYLResourceRouteTests` 用例相同。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLResourceRouteTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private lateinit var folder: File

    @Before
    fun setUp() {
        folder = File(context.cacheDir, "cyl-route-test-" + java.util.UUID.randomUUID())
        assertTrue(folder.mkdirs())
    }

    @After
    fun tearDown() {
        folder.deleteRecursively()
    }

    private fun write(text: String, name: String) {
        val file = File(folder, name)
        file.parentFile?.mkdirs()
        file.writeText(text)
    }

    @Test
    fun prefixesLeadToTheirFolders() {
        val data = context.filesDir.parentFile!!
        fun location(route: String, base: String? = null) = CYLResourceRoute.locationForRoute(context, route, base)!!
        assertEquals("Configurations", location("bundle:Configurations", "/base").assetPath)
        assertEquals("a/b", location("bundle:/a/b/").assetPath)
        assertEquals(File(context.filesDir, "i18n"), location("sandbox:Documents/i18n").file)
        assertEquals(File(context.cacheDir, "i18n"), location("sandbox:Caches/i18n").file)
        assertEquals(File(context.cacheDir, "i18n"), location("sandbox:tmp/i18n").file)
        assertEquals(File(data, "Library/i18n"), location("sandbox:Library/i18n").file)
        assertEquals(File("/var/tmp/a b.json"), location("file:///var/tmp/a%20b.json").file)
        assertEquals(File("/var/tmp/x"), location("/var/tmp/x", "/base").file)
        assertEquals(File(data, "x"), location("~/x").file)
        assertEquals(File("/base/Texts"), location("Texts", "/base").file)
        assertEquals("Configurations/Texts", location("Texts", "asset:Configurations").assetPath)
        assertEquals("Texts", location(" Texts \n").assetPath)
        assertNull(CYLResourceRoute.locationForRoute(context, ""))
    }

    @Test
    fun queryPicksOneFile() {
        for (name in listOf("tabbar.json", "tabbar@1.0.json", "tabbar@1.9.json", "tabbar@1.10.yaml", "tabbar-dark@2.0.yaml",
                "tabbar-dark@2.0.json", "tabbar-dark.plist", "tabbar.txt", "tabbarx@3.0.json", "._tabbar@9.0.json", "other@5.0.json")) {
            write("{}", name)
        }
        fun pick(query: String) = CYLResourceRoute.pathForRoute(context, "sandbox:Caches/${folder.name}?$query")?.let { File(it).name }
        assertEquals("the highest version, compared as numbers", "tabbar@1.10.yaml", pick("name=tabbar"))
        assertEquals("tabbar@1.9.json", pick("name=tabbar&version=1.9"))
        assertEquals("tabbar@1.9.json", pick("name=tabbar&format=json"))
        assertEquals("same version: JSON before YAML", "tabbar-dark@2.0.json", pick("name=tabbar&theme=dark"))
        assertEquals("yml and yaml are one format", "tabbar-dark@2.0.yaml", pick("name=tabbar&theme=dark&format=yml"))
        assertEquals("tabbar-dark.plist", pick("name=tabbar&theme=dark&format=plist"))
        assertEquals("keys and formats ignore case", "tabbar@1.0.json", pick("NAME=tabbar&Format=JSON&version=1.0"))
        assertNull(pick("name=tabbar&version=7.0"))
        assertNull(pick("name=tabbar&theme=light"))
        assertNull(pick("name=missing"))
        assertNull("a query needs a name", pick("theme=dark"))
        assertNull(CYLResourceRoute.pathForRoute(context, "sandbox:Caches/no-such-folder?name=tabbar"))
        assertEquals("other@5.0.json", CYLResourceRoute.pickFile(folder.list()!!.toList(), "other", null, null, null))
    }

    @Test
    fun configurationFromSandboxRouteWithLocalization() {
        val json = """{"CYLTabBarControllerLocalization": {"CYLTabBarLocalizationTableName": "Tabs", "CYLTabBarLocalizationPath": "Localization"},
            "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemIdentifier": "home", "CYLTabBarItemTitle": "%s"}]}"""
        write(json.format("Home"), "tabbar@1.0.json")
        write(json.format("Me"), "tabbar@2.0.json")
        write("\"Home\" = \"Accueil\";\n\"Me\" = \"Moi\";\n", "Localization/en.lproj/Tabs.strings")
        val configuration = CYLTabBarController.configurationWithRoute(context, "sandbox:Caches/${folder.name}?name=tabbar")
        @Suppress("UNCHECKED_CAST")
        val items = (configuration[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] as List<Map<String, Any?>>)
        assertEquals("version 2.0 wins", "Me", items[0][CYLConstants.CYLTabBarItemTitle])
        val localized = CYLTabBarConfigurationLocalization.localize(context, configuration)
        @Suppress("UNCHECKED_CAST")
        val title = (localized[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] as List<Map<String, Any?>>)[0][CYLConstants.CYLTabBarItemTitle]
        assertEquals("the relative table path is resolved against the routed file's folder", "Moi", title)
    }

    @Test
    fun configurationRouteKeyReadsTheFileUnderTheOtherKeys() {
        write("""{"CYLTabBarControllerTitlePositionAdjustment": "{0, -5}", "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home"}]}""", "tabbar-dark.json")
        val route = "sandbox:Caches/${folder.name}?name=tabbar&theme=dark"
        val merged = CYLTabBarConfiguration.withRoutedFile(context, mapOf(
            CYLConstants.CYLTabBarControllerConfigurationRoute to route, CYLConstants.CYLTabBarControllerTitlePositionAdjustment to "{0, -1}"))
        assertEquals("the dictionary wins over the file", "{0, -1}", merged[CYLConstants.CYLTabBarControllerTitlePositionAdjustment])
        assertTrue("keys it does not give come from the file", merged[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] is List<*>)
        assertTrue(CYLConstants.CYLTabBarControllerConfigurationRoute !in merged)
        val missing = CYLTabBarConfiguration.withRoutedFile(context, mapOf(CYLConstants.CYLTabBarControllerConfigurationRoute to "sandbox:Caches/none?name=x", "a" to 1))
        assertEquals("a route without a file is ignored", mapOf("a" to 1), missing)
    }

    @Test
    fun routeWithoutFileThrowsFileNotFound() {
        for (route in listOf("sandbox:Caches/${folder.name}?name=nothing", "")) {
            try {
                CYLTabBarController.configurationWithRoute(context, route)
                fail("expected FileNotFound for \"$route\"")
            } catch (error: CYLTabBarConfiguration.CYLConfigurationException) {
                assertEquals(CYLTabBarConfiguration.CYLTabBarConfigurationError.FileNotFound, error.error)
                assertTrue(error.message.orEmpty().contains("\"$route\""))
            }
        }
    }
}
