package com.cyl.tabbar

import com.cyl.tabbar.CYLTabBarConfiguration.CYLConfigurationException
import com.cyl.tabbar.CYLTabBarConfiguration.CYLTabBarConfigurationError
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] The interfaces of the remote configuration (docs/Configuration-File.md, "Remote configuration interfaces"): a source
 *      fetches, a mapper maps into the library's own configuration, the loader merges over the defaults. A second, made-up
 *      service proves that a new service needs a source and a mapper only: the tab bar code is not touched.
 * [CN] 远程配置的接口（docs/Configuration-File.md，“Remote configuration interfaces”）：source 负责拉取，mapper 映射为本库自己的配置，loader 合并到默认值之上。
 *      另一个虚构的服务证明：新增服务只需要一个 source 和一个 mapper，无需改动 TabBar 的代码。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLRemoteConfigInterfacesTest {

    private val defaults: Map<String, Any?> = mapOf(
        "CYLTabBarControllerStyleType" to "default",
        "CYLTabBarControllerTabBarItemsAttributes" to listOf(
            mapOf("CYLTabBarItemIdentifier" to "home", "CYLTabBarItemTitle" to "Home"),
            mapOf("CYLTabBarItemIdentifier" to "me", "CYLTabBarItemTitle" to "Me")),
    )

    private class FakeSource(override val identifier: String, private val payload: CYLRemoteConfigPayload?, private val failure: Throwable? = null) :
        CYLRemoteConfigSource {
        var fetches = 0
        override fun fetch(completion: (CYLRemoteConfigPayload?, Throwable?) -> Unit) {
            fetches++
            completion(payload, failure)
        }
    }

    private fun load(source: CYLRemoteConfigSource, mapper: CYLRemoteConfigMapper? = null): CYLRemoteConfigResult {
        var result: CYLRemoteConfigResult? = null
        CYLRemoteConfigLoader(source, mapper).load(defaults) { result = it }
        assertNotNull("the loader calls back once", result)
        return result!!
    }

    @After
    fun unregisterTheMadeUpService() {
        CYLRemoteConfigMappers.unregister("acme")
    }

    @Test
    fun firebaseMapperIsRegisteredAndMapsFlatParameters() {
        assertSame(CYLFirebaseRemoteConfigMapper, CYLRemoteConfigMappers.mapper("firebase"))
        val payload = CYLRemoteConfigPayload("firebase", mapOf(
            "CYLTabBarControllerStyleType" to "flatDesign",
            "welcome_message" to "Hello",
            "CYLTabBarControllerTitlePositionAdjustment" to "[0,-2]"))
        val configuration = CYLFirebaseRemoteConfigMapper.configuration(payload)
        assertEquals("flatDesign", configuration["CYLTabBarControllerStyleType"])
        assertEquals(listOf(0L, -2L).map { it.toInt() }, (configuration["CYLTabBarControllerTitlePositionAdjustment"] as List<*>).map { (it as Number).toInt() })
        assertFalse("the app's other parameters are not read", configuration.containsKey("welcome_message"))
    }

    @Test
    fun aStringValueTypeKeepsTheTextAsText() {
        val values = mapOf("CYLTabBarControllerContext" to "12", "CYLTabBarControllerStyleType" to "default")
        val untyped = CYLFirebaseRemoteConfigMapper.configuration(CYLRemoteConfigPayload("firebase", values))
        assertTrue("without a type the scalar is typed by its look", untyped["CYLTabBarControllerContext"] is Number)
        val typed = CYLFirebaseRemoteConfigMapper.configuration(CYLRemoteConfigPayload("firebase", values,
            mapOf("CYLTabBarControllerContext" to CYLRemoteConfigValueType.STRING)))
        assertEquals("12", typed["CYLTabBarControllerContext"])
        assertEquals(CYLRemoteConfigValueType.JSON, CYLRemoteConfigValueType.of(" json "))
        assertNull(CYLRemoteConfigValueType.of("DATE"))
    }

    @Test
    fun loaderPutsTheFetchedValuesOverTheDefaults() {
        val source = FakeSource("firebase", CYLRemoteConfigPayload("firebase", mapOf("CYLTabBarControllerStyleType" to "flatDesign")))
        val result = load(source)
        assertTrue(result.isRemote)
        assertNull(result.error)
        assertEquals("flatDesign", result.configuration["CYLTabBarControllerStyleType"])
        // [EN] Only the style came from the service: the tabs are still the ones of the defaults. [CN] 只有样式来自服务：Tab 仍是默认值中的。
        assertEquals(defaults["CYLTabBarControllerTabBarItemsAttributes"], result.configuration["CYLTabBarControllerTabBarItemsAttributes"])
        assertEquals(1, source.fetches)
    }

    @Test
    fun aFailedFetchKeepsTheDefaults() {
        val failure = java.io.IOException("offline")
        val result = load(FakeSource("firebase", null, failure))
        assertFalse(result.isRemote)
        assertSame(failure, result.error)
        assertEquals(defaults, result.configuration)
    }

    @Test
    fun invalidValuesAndMissingMappersKeepTheDefaults() {
        val invalid = load(FakeSource("firebase", CYLRemoteConfigPayload("firebase",
            mapOf("CYLTabBarControllerTabBarItemsAttributes" to "[{\"broken\""))))
        assertFalse(invalid.isRemote)
        assertEquals(defaults, invalid.configuration)
        assertEquals(CYLTabBarConfigurationError.InvalidSyntax, (invalid.error as CYLConfigurationException).error)

        val unknown = load(FakeSource("nobody", CYLRemoteConfigPayload("nobody", mapOf("CYLTabBarControllerStyleType" to "x"))))
        assertFalse(unknown.isRemote)
        assertEquals(CYLTabBarConfigurationError.UnknownFormat, (unknown.error as CYLConfigurationException).error)

        // [EN] A console edit that leaves no tab never reaches the tab bar. [CN] 导致没有 Tab 的控制台编辑不会到达 TabBar。
        val noTabs = load(FakeSource("firebase", CYLRemoteConfigPayload("firebase",
            mapOf("CYLTabBarControllerTabBarItemsAttributes" to "[]"))))
        assertFalse(noTabs.isRemote)
        assertEquals(CYLTabBarConfigurationError.NoTabs, (noTabs.error as CYLConfigurationException).error)
        assertEquals(defaults, noTabs.configuration)
    }

    @Test
    fun aNewServiceNeedsOnlyASourceAndAMapper() {
        // [EN] "acme" delivers its own shape: {"tabs": ["home:Home", "me:Me"], "skin": "flat"}. Its mapper turns that into the
        //      library's keys; nothing else of the library changes. [CN] “acme” 下发自己的格式；其映射器把它转换为本库的 key，库的其他部分都不用改。
        val acme = object : CYLRemoteConfigMapper {
            override val sourceIdentifier = "acme"
            override fun configuration(payload: CYLRemoteConfigPayload): Map<String, Any?> {
                val tabs = (payload.values["tabs"] as List<*>).map { entry ->
                    val (identifier, title) = entry.toString().split(":")
                    mapOf("CYLTabBarItemIdentifier" to identifier, "CYLTabBarItemTitle" to title)
                }
                return mapOf("CYLTabBarControllerTabBarItemsAttributes" to tabs, "CYLTabBarControllerStyleType" to payload.values["skin"])
            }
        }
        CYLRemoteConfigMappers.register(acme)
        val payload = CYLRemoteConfigPayload("acme", mapOf("tabs" to listOf("shop:Shop", "me:Me"), "skin" to "flatDesign"))
        val result = load(FakeSource("acme", payload))
        assertTrue(result.isRemote)
        assertEquals("flatDesign", result.configuration["CYLTabBarControllerStyleType"])
        assertEquals(listOf("shop", "me"), (result.configuration["CYLTabBarControllerTabBarItemsAttributes"] as List<*>).map { (it as Map<*, *>)["CYLTabBarItemIdentifier"] })
        // [EN] An explicit mapper wins over the registry. [CN] 显式传入的映射器优先于注册表。
        assertTrue(load(FakeSource("acme", payload), acme).isRemote)
    }
}
