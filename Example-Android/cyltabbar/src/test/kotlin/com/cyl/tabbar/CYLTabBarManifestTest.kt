package com.cyl.tabbar

import android.content.Context
import android.os.Looper
import androidx.test.core.app.ApplicationProvider
import com.cyl.tabbar.CYLTabBarConfiguration.CYLConfigurationException
import com.cyl.tabbar.CYLTabBarConfiguration.CYLTabBarConfigurationError
import com.cyl.tabbar.CYLTabBarManifest.CYLTabBarManifestSource
import org.json.JSONObject
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
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.File

/**
 * [EN] `CYLTabBarManifest` and `CYLTabBarManifestLoader` on the JVM (docs/Configuration-Manifest.md, cases M1–M14), the
 *      same cases as the iOS `CYLTabBarManifestTests`.
 * [CN] JVM 上的 `CYLTabBarManifest` 与 `CYLTabBarManifestLoader`（docs/Configuration-Manifest.md，情况 M1–M14），与 iOS 的
 *      `CYLTabBarManifestTests` 用例相同。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabBarManifestTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private lateinit var folder: File
    private val png = android.util.Base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==", 0)

    @Before
    fun setUp() {
        folder = File(context.filesDir, "cyl-manifest-" + java.util.UUID.randomUUID()).apply { mkdirs() }
        File(context.cacheDir, "CYLTabBarManifest").deleteRecursively()
    }

    @After
    fun tearDown() {
        folder.deleteRecursively()
        File(context.cacheDir, "CYLTabBarManifest").deleteRecursively()
    }

    private fun image(path: String) = File(folder, path).apply { parentFile?.mkdirs(); writeBytes(png) }

    private fun sample(): MutableMap<String, Any?> {
        for (path in listOf("Skins/2.1.0/light/home@3x.png", "Skins/2.1.0/light/home_selected@3x.png", "Skins/2.1.0/dark/home@3x.png", "Skins/2.1.0/light/me@3x.png", "Skins/2.1.0/light/plus@3x.png")) image(path)
        return linkedMapOf(
            "schemaVersion" to 1, "id" to "test-manifest", "version" to "2.1.0",
            "runtime" to mapOf("platforms" to listOf("ios", "android")),
            "fallback" to mapOf("onError" to "previous"),
            "assets" to mapOf("baseRoute" to "Skins/2.1.0", "list" to listOf(
                mapOf("key" to "home", "theme" to "light", "state" to "normal", "path" to "light/home@3x.png", "hash" to CYLTabBarManifest.hashOf(png)),
                mapOf("key" to "home", "theme" to "light", "state" to "selected", "path" to "light/home_selected@3x.png"),
                mapOf("key" to "home", "theme" to "dark", "state" to "normal", "path" to "dark/home@3x.png"),
                mapOf("key" to "me", "theme" to "light", "state" to "normal", "path" to "light/me@3x.png"),
                mapOf("key" to "plus", "theme" to "light", "state" to "normal", "path" to "light/plus@3x.png"))),
            "themes" to mapOf("default" to "light", "darkMode" to "dark", "managerName" to "CYLManifestTest", "list" to mapOf(
                "light" to mapOf("tabColor" to "#8E8E93", "tabSelectedColor" to "#007AFF", "tabBackgroundColor" to "#FFFFFF"),
                "dark" to mapOf("tabSelectedColor" to "#0A84FF", "tabBackgroundColor" to "#1C1C1E"))),
            "tabBar" to mapOf("styleType" to "liquidGlass", "color" to "@tabColor", "selectedColor" to "@tabSelectedColor", "backgroundColor" to "@tabBackgroundColor",
                "list" to listOf(
                    mapOf("key" to "home", "pagePath" to "home", "text" to "tab.home", "iconPath" to "asset:home", "selectedIconPath" to "asset:home?state=selected"),
                    mapOf("key" to "apple", "pagePath" to "apple", "text" to "iOS only", "iconPath" to "asset:home", "platforms" to listOf("ios")),
                    mapOf("key" to "hidden", "pagePath" to "hidden", "text" to "Hidden", "iconPath" to "asset:home", "visible" to false),
                    mapOf("key" to "me", "pagePath" to "me", "text" to "tab.me", "iconPath" to "asset:me", "minAppVersion" to "2.0.0")),
                "midButton" to mapOf("key" to "plus", "index" to 1, "text" to "Post", "width" to 55, "height" to 80, "iconPath" to "asset:plus", "action" to "page", "pagePath" to "publish")),
            "localization" to mapOf("tableName" to "Tabs", "route" to "Localization"),
        )
    }

    private fun manifest(dictionary: Map<String, Any?>) = CYLTabBarManifest.manifestWithDictionary(context, dictionary, folder.path)

    private fun expect(error: CYLTabBarConfigurationError, block: () -> Unit) {
        try {
            block(); fail("expected $error")
        } catch (exception: CYLConfigurationException) {
            assertEquals(error, exception.error)
        }
    }

    @Test
    fun schema() {
        expect(CYLTabBarConfigurationError.UnsupportedManifest) { manifest(mapOf("schemaVersion" to 1)) }
        expect(CYLTabBarConfigurationError.UnsupportedManifest) { manifest(sample() + ("schemaVersion" to 2)) }
        assertEquals("2.1.0", manifest(sample()).version)
    }

    @Test
    fun eligibility() {
        val now = 1_780_000_000_000L // 2026-05-28
        assertTrue(manifest(sample()).isEligible(now))
        assertEquals(CYLTabBarConfigurationError.NotEligible, manifest(sample() + ("runtime" to mapOf("platforms" to "ios"))).eligibilityError(now)?.error)
        assertFalse(manifest(sample() + ("runtime" to mapOf("minAppVersion" to "999.0"))).isEligible(now))
        assertTrue(manifest(sample() + ("runtime" to mapOf("startTime" to "2027-01-01T00:00:00Z"))).eligibilityError(now)?.message.orEmpty().contains("starts"))
        assertFalse(manifest(sample() + ("runtime" to mapOf("endTime" to "2020-01-01T00:00:00+08:00"))).isEligible(now))
        assertTrue(manifest(sample() + ("runtime" to mapOf("startTime" to "2020-01-01T00:00:00Z", "endTime" to "2030-01-01T00:00:00Z"))).isEligible(now))
    }

    @Test
    fun assetLookup() {
        val manifest = manifest(sample())
        fun name(reference: String) = manifest.pathForAssetReference(reference)?.substringAfter("2.1.0/")
        assertEquals("light/home@3x.png", name("asset:home"))
        assertEquals("light/home_selected@3x.png", name("asset:home?state=selected"))
        assertEquals("dark/home@3x.png", name("asset:home?theme=dark"))
        assertEquals("dark/home@3x.png", name("asset:home?theme=dark&state=selected"))
        assertEquals("light/me@3x.png", name("asset:me?theme=dark"))
        assertNull(name("asset:nothing"))
        val hostile = sample() + ("assets" to mapOf("baseRoute" to "Skins/2.1.0", "list" to listOf(mapOf("key" to "x", "path" to "../../../etc/hosts"))))
        assertNull(manifest(hostile).pathOfAsset("x"))
    }

    @Test
    fun assetVerification() {
        val manifest = manifest(sample())
        assertNull(manifest.assetError())
        File(folder, "Skins/2.1.0/light/home@3x.png").writeText("changed")
        assertTrue(manifest.assetError()?.message.orEmpty().contains("hash"))
        val missing = sample() + ("assets" to mapOf("baseRoute" to "Skins/2.1.0", "list" to listOf(mapOf("key" to "gone", "path" to "light/gone@3x.png"))))
        assertTrue(manifest(missing).assetError()?.message.orEmpty().contains("missing"))
    }

    @Test
    fun conditions() {
        val dictionary = sample() + mapOf(
            "conditions" to listOf(
                mapOf("name" to "android", "expression" to "device.os == 'android' && percent between 0 and 99"),
                mapOf("name" to "ios", "expression" to "device.os == 'ios'"),
                mapOf("name" to "future", "expression" to "app.version >= '999.0.0'"),
                mapOf("name" to "unknown", "expression" to "user.vip == true")),
            "overrides" to listOf(
                mapOf("condition" to "android", "tabBar" to mapOf("styleType" to "flatDesign")),
                mapOf("condition" to "ios", "tabBar" to mapOf("midButton" to mapOf("height" to 64))),
                mapOf("condition" to "future", "version" to "9.9.9"),
                mapOf("condition" to "unknown", "version" to "8.8.8")))
        val manifest = manifest(dictionary)
        val tabBar = manifest.dictionary["tabBar"] as Map<*, *>
        assertEquals("flatDesign", tabBar["styleType"])
        assertEquals(80, (tabBar["midButton"] as Map<*, *>)["height"])
        assertEquals("2.1.0", manifest.version)
    }

    @Test
    fun configuration() {
        val configuration = manifest(sample()).configuration()
        @Suppress("UNCHECKED_CAST")
        val items = configuration[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] as List<Map<String, Any?>>
        assertEquals(listOf("home", "me"), items.map { it[CYLConstants.CYLTabBarItemIdentifier] })
        assertEquals("@cyl.asset.home.normal", items[0][CYLConstants.CYLTabBarItemImage])
        assertEquals("2.0.0", items[1][CYLConstants.CYLTabBarItemMinimumAppVersion])
        val themes = configuration[CYLConstants.CYLTabBarControllerThemes] as Map<*, *>
        val dark = themes["dark"] as Map<*, *>
        assertEquals("#1C1C1E", dark[CYLConstants.CYLTabBarBackgroundColor])
        assertEquals("#8E8E93", dark[CYLConstants.CYLTabBarItemTitleColor])
        assertTrue((dark["cyl.asset.home.normal"] as String).endsWith("dark/home@3x.png"))
        assertTrue(((themes["light"] as Map<*, *>)["cyl.asset.home.selected"] as String).endsWith("light/home_selected@3x.png"))
        assertEquals("light", configuration[CYLConstants.CYLTabBarControllerThemeIdentifier])
        assertEquals("dark", configuration[CYLConstants.CYLTabBarControllerDarkThemeIdentifier])
        assertEquals("CYLManifestTest", configuration[CYLConstants.CYLTabBarControllerThemeManagerName])
        val plus = configuration[CYLConstants.CYLTabBarControllerPlusButton] as Map<*, *>
        assertEquals(1, plus[CYLConstants.CYLPlusButtonIndexInTabBar])
        assertEquals("{55, 80}", plus[CYLConstants.CYLPlusButtonSize])
        assertEquals("publish", plus[CYLConstants.CYLTabBarItemPageIdentifier])
        assertEquals("CYLTabBarManifest:test-manifest", configuration[CYLConstants.CYLTabBarControllerContext])
        assertEquals("Tabs", (configuration[CYLConstants.CYLTabBarControllerLocalization] as Map<*, *>)[CYLConstants.CYLTabBarLocalizationTableName])
        val callback = sample() - "themes" + ("tabBar" to ((sample()["tabBar"] as Map<*, *>) + ("midButton" to mapOf("key" to "plus", "action" to "callback", "pagePath" to "publish"))))
        val plain = manifest(callback).configuration()
        assertNull((plain[CYLConstants.CYLTabBarControllerPlusButton] as Map<*, *>)[CYLConstants.CYLTabBarItemPageIdentifier])
        @Suppress("UNCHECKED_CAST")
        assertTrue(((plain[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] as List<Map<String, Any?>>)[0][CYLConstants.CYLTabBarItemImage] as String).endsWith("light/home@3x.png"))
    }

    @Test
    fun manifestRouteKey() {
        val file = File(folder, "manifest.json").apply { writeText(JSONObject(sample()).toString()) }
        val merged = CYLTabBarConfiguration.withRoutedFile(context, mapOf(CYLConstants.CYLTabBarControllerManifestRoute to file.path, CYLConstants.CYLTabBarControllerStyleType to "default"))
        assertEquals("the dictionary wins over the manifest", "default", merged[CYLConstants.CYLTabBarControllerStyleType])
        @Suppress("UNCHECKED_CAST")
        assertEquals("home", (merged[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] as List<Map<String, Any?>>)[0][CYLConstants.CYLTabBarItemIdentifier])
        assertTrue(CYLConstants.CYLTabBarControllerManifestRoute !in merged)
        val missing = CYLTabBarConfiguration.withRoutedFile(context, mapOf(CYLConstants.CYLTabBarControllerManifestRoute to "sandbox:Caches/none.json", "a" to 1))
        assertEquals(mapOf("a" to 1), missing)
    }

    private fun publish(dictionary: Map<String, Any?>, name: String): String {
        val file = File(folder, name)
        file.writeText(JSONObject(dictionary).toString())
        return file.toURI().toString()
    }

    private fun load(loader: CYLTabBarManifestLoader, url: String): Triple<CYLTabBarManifest?, CYLTabBarManifestSource, CYLConfigurationException?> {
        var result: Triple<CYLTabBarManifest?, CYLTabBarManifestSource, CYLConfigurationException?>? = null
        loader.loadManifestWithURL(url) { manifest, source, error -> result = Triple(manifest, source, error) }
        val deadline = System.currentTimeMillis() + 10_000
        while (result == null && System.currentTimeMillis() < deadline) {
            Thread.sleep(20)
            shadowOf(Looper.getMainLooper()).idle()
        }
        return result ?: error("timed out")
    }

    @Test
    fun loaderFallbacks() {
        val events = ArrayList<String>()
        val loader = CYLTabBarManifestLoader(context)
        loader.delegate = object : CYLTabBarManifestLoader.Delegate {
            override fun didApplyManifest(manifest: CYLTabBarManifest, source: CYLTabBarManifestSource) { events += "apply:$source" }
            override fun didFail(error: CYLConfigurationException, fallbackSource: CYLTabBarManifestSource) { events += "fail:$fallbackSource" }
        }
        for (path in listOf("light/home@3x.png", "light/home_selected@3x.png", "dark/home@3x.png", "light/me@3x.png", "light/plus@3x.png")) image(path)
        val (good, goodSource, goodError) = load(loader, publish(sample(), "good.json"))
        assertNull(goodError)
        assertEquals(CYLTabBarManifestSource.Remote, goodSource)
        assertTrue(good!!.pathForAssetReference("asset:home").orEmpty().contains("CYLTabBarManifest/2.1.0"))
        assertEquals("2.1.0", loader.cachedManifest()?.version)

        val broken = sample() + mapOf("version" to "3.0.0", "assets" to mapOf("list" to listOf(mapOf("key" to "home", "path" to "light/home@3x.png", "hash" to "sha256-wrong"))))
        events.clear()
        val (fromCache, cacheSource, cacheError) = load(loader, publish(broken, "broken.json"))
        assertEquals(CYLTabBarConfigurationError.AssetInvalid, cacheError?.error)
        assertEquals(CYLTabBarManifestSource.Cache, cacheSource)
        assertEquals("2.1.0", fromCache?.version)
        assertEquals(listOf("fail:Cache", "apply:Cache"), events)

        File(context.cacheDir, "CYLTabBarManifest").deleteRecursively()
        val embeddedFile = File(folder, "embedded.json").apply { writeText(JSONObject(sample()).toString()) }
        loader.embeddedManifestRoute = embeddedFile.path
        val (embedded, embeddedSource, _) = load(loader, publish(broken, "broken.json"))
        assertEquals(CYLTabBarManifestSource.Embedded, embeddedSource)
        assertEquals("test-manifest", embedded?.identifier)

        val notForAndroid = sample() + mapOf("runtime" to mapOf("platforms" to listOf("ios")), "fallback" to mapOf("onError" to "none"))
        val (none, noneSource, noneError) = load(loader, publish(notForAndroid, "ios.json"))
        assertNull(none)
        assertEquals(CYLTabBarManifestSource.None, noneSource)
        assertEquals(CYLTabBarConfigurationError.NotEligible, noneError?.error)
    }
}
