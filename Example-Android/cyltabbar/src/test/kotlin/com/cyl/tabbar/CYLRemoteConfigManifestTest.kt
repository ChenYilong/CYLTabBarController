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
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.File

/**
 * [EN] Audit item A4 of docs/Configuration-File.md: a whole tab bar manifest travels as the `CYLTabBarManifest` parameter of Remote Config
 *      (a string), its images stay files at `assets.baseURL` (Firebase Hosting, Cloud Storage, any CDN) and are checked by their hashes before
 *      the switch; the conditions of that manifest are not evaluated again, the service chose it. A folder of files stands in for the CDN.
 * [CN] docs/Configuration-File.md 审计项 A4：完整的 TabBar 清单作为 Remote Config 的 `CYLTabBarManifest` 参数（字符串）下发，其图片仍是 `assets.baseURL`
 *      （Firebase Hosting、Cloud Storage、任意 CDN）处的文件，切换之前按哈希校验；该清单的条件不会再次计算，因为它是服务选定的。用一个文件夹代替 CDN。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLRemoteConfigManifestTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private lateinit var cdn: File
    private val png = android.util.Base64.decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==", 0)

    @Before
    fun setUp() {
        cdn = File(context.filesDir, "cyl-cdn-" + java.util.UUID.randomUUID()).apply { mkdirs() }
        File(cdn, "light").mkdirs()
        File(cdn, "light/home@3x.png").writeBytes(png)
        File(context.cacheDir, "CYLTabBarManifest").deleteRecursively()
    }

    @After
    fun tearDown() {
        cdn.deleteRecursively()
        File(context.cacheDir, "CYLTabBarManifest").deleteRecursively()
    }

    private fun manifest(version: String = "1.0.0", hash: String = CYLTabBarManifest.hashOf(png), extra: Map<String, Any?> = emptyMap()): Map<String, Any?> = linkedMapOf<String, Any?>(
        "schemaVersion" to 1, "id" to "rc-manifest", "version" to version,
        "runtime" to mapOf("platforms" to listOf("ios", "android")),
        "assets" to mapOf("baseURL" to cdn.toURI().toString(),
            "list" to listOf(mapOf("key" to "home", "theme" to "light", "state" to "normal", "path" to "light/home@3x.png", "hash" to hash))),
        "themes" to mapOf("default" to "light", "list" to mapOf("light" to mapOf("tabColor" to "#8E8E93"))),
        "tabBar" to mapOf("styleType" to "liquidGlass", "color" to "@tabColor",
            "list" to listOf(mapOf("key" to "home", "pagePath" to "home", "text" to "Home", "iconPath" to "asset:home")))) + extra

    private class Source(private val values: Map<String, Any?>) : CYLRemoteConfigSource {
        override val identifier = "firebase"
        override fun fetch(completion: (CYLRemoteConfigPayload?, Throwable?) -> Unit) = completion(CYLRemoteConfigPayload("firebase", values), null)
    }

    private val defaults: Map<String, Any?> = mapOf(
        "CYLTabBarControllerStyleType" to "default",
        "CYLTabBarControllerTabBarItemsAttributes" to listOf(mapOf("CYLTabBarItemIdentifier" to "local", "CYLTabBarItemTitle" to "Local")))

    private fun load(manifest: Map<String, Any?>?, more: Map<String, Any?> = emptyMap(), withContext: Boolean = true, base: Map<String, Any?> = defaults): CYLRemoteConfigResult {
        val values = more.toMutableMap()
        if (manifest != null) values[CYLRemoteConfigLoader.MANIFEST_KEY] = JSONObject(manifest).toString()
        var result: CYLRemoteConfigResult? = null
        CYLRemoteConfigLoader(Source(values), null, if (withContext) context else null).load(base) { result = it }
        val deadline = System.currentTimeMillis() + 10_000
        while (result == null && System.currentTimeMillis() < deadline) {
            Thread.sleep(20)
            shadowOf(Looper.getMainLooper()).idle()
        }
        return result ?: error("timed out")
    }

    @Suppress("UNCHECKED_CAST")
    private fun titles(configuration: Map<String, Any?>) =
        (configuration[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] as List<Map<String, Any?>>).map { it[CYLConstants.CYLTabBarItemTitle] }

    @Test
    fun aManifestParameterBringsItsTabsAndItsVerifiedImages() {
        val result = load(manifest(), more = mapOf("CYLTabBarControllerStyleType" to "flatDesign"))
        assertNull(result.error)
        assertTrue(result.isRemote)
        assertEquals(CYLTabBarManifestSource.Remote, result.manifestSource)
        assertEquals("the manifest's tabs replace the defaults'", listOf<Any?>("Home"), titles(result.configuration))
        assertEquals("the other remote values win over the manifest's configuration", "flatDesign", result.configuration[CYLConstants.CYLTabBarControllerStyleType])
        assertFalse("the raw manifest is not left in the configuration", result.configuration.containsKey(CYLRemoteConfigLoader.MANIFEST_KEY))
        // [EN] The image was downloaded from the CDN into the app's cache and checked by its hash. [CN] 图片已从 CDN 下载到 App 的缓存，并按哈希校验。
        assertTrue(File(context.cacheDir, "CYLTabBarManifest/1.0.0/light/home@3x.png").isFile)
    }

    @Test
    fun theConditionsOfThatManifestAreNotEvaluatedAgain() {
        val conditional = manifest(extra = mapOf(
            "conditions" to listOf(mapOf("name" to "android", "expression" to "device.os == 'android'")),
            "overrides" to listOf(mapOf("condition" to "android", "tabBar" to mapOf("styleType" to "flatDesign")))))
        val styleOfManifestRoute = (CYLTabBarManifest.manifestWithDictionary(context, conditional, null).dictionary["tabBar"] as Map<*, *>)["styleType"]
        assertEquals("through a file or a URL the condition applies", "flatDesign", styleOfManifestRoute)
        val result = load(conditional)
        assertEquals("through Remote Config the service has chosen: the condition is left alone", "liquidGlass",
            result.configuration[CYLConstants.CYLTabBarControllerStyleType])
        val loaded = CYLTabBarManifest.manifestWithDictionary(context, conditional, null, evaluatesConditions = false)
        assertEquals("liquidGlass", (loaded.dictionary["tabBar"] as Map<*, *>)["styleType"])
    }

    @Test
    fun aWrongHashKeepsTheManifestOfTheCacheAndTellsWhy() {
        assertEquals(CYLTabBarManifestSource.Remote, load(manifest()).manifestSource)
        val result = load(manifest(version = "2.0.0", hash = "sha256-wrong"))
        assertEquals(CYLTabBarConfigurationError.AssetInvalid, (result.error as CYLConfigurationException).error)
        assertEquals("the verified manifest of before stays", CYLTabBarManifestSource.Cache, result.manifestSource)
        assertEquals(listOf<Any?>("Home"), titles(result.configuration))
        assertFalse("the broken version was not kept", File(context.cacheDir, "CYLTabBarManifest/2.0.0").exists())
    }

    @Test
    fun anUnusableManifestKeepsTheDefaults() {
        val notForAndroid = manifest(extra = mapOf("runtime" to mapOf("platforms" to listOf("ios")), "fallback" to mapOf("onError" to "none")))
        val refused = load(notForAndroid)
        assertFalse(refused.isRemote)
        assertEquals(CYLTabBarConfigurationError.NotEligible, (refused.error as CYLConfigurationException).error)
        assertEquals(CYLTabBarManifestSource.None, refused.manifestSource)
        assertEquals(defaults, refused.configuration)

        val withoutBase = manifest() + mapOf("assets" to mapOf("list" to listOf(mapOf("key" to "home", "path" to "light/home@3x.png"))))
        val needsBase = load(withoutBase)
        assertEquals(CYLTabBarConfigurationError.AssetInvalid, (needsBase.error as CYLConfigurationException).error)
        assertTrue((needsBase.error as CYLConfigurationException).message.orEmpty().contains("assets.baseURL"))

        val noContext = load(manifest(), withContext = false)
        assertFalse(noContext.isRemote)
        assertEquals(CYLTabBarConfigurationError.UnsupportedManifest, (noContext.error as CYLConfigurationException).error)
        assertEquals(defaults, noContext.configuration)
    }

    @Test
    fun theTabsMayComeFromTheManifestAlone() {
        val result = load(manifest(), base = mapOf("CYLTabBarControllerStyleType" to "default"))
        assertNull(result.error)
        assertTrue(result.isRemote)
        assertNotNull(result.configuration[CYLConstants.CYLTabBarControllerTabBarItemsAttributes])
        assertEquals(listOf<Any?>("Home"), titles(result.configuration))
    }
}
