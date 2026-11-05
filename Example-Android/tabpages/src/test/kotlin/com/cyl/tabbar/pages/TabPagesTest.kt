package com.cyl.tabbar.pages

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

/**
 * [EN] The Android rules match the iOS library: the shared sample file, page IDs, the lookup order, several tab bars,
 *      platforms and versions.
 * [CN] Android 的规则与 iOS 库一致：共用的示例文件、页面 ID、查找顺序、多个 TabBar、平台与版本。
 */
class TabPagesTest {
    private val sharedJson: String
        get() = File(System.getProperty("cyl.sharedConfiguration")).readText()

    @Test
    fun sharedSampleGivesTheSameTabsAndPageIds() {
        val tabs = TabConfiguration.tabs(sharedJson, platform = "android", appVersion = "1.0.0")
        assertEquals(listOf("JSON", "Message", "Discover", "Me"), tabs.map { it.title })
        assertEquals(listOf("home", "message", "web", "me"), tabs.map { it.pageId })
        assertEquals("https://github.com/ChenYilong/CYLTabBarController", tabs[2].pageParameters["url"])
    }

    private fun sibling(extension: String): String =
        File(System.getProperty("cyl.sharedConfiguration")).let { File(it.parentFile, it.nameWithoutExtension + "." + extension) }.readText()

    @Test
    fun plistAndPropertiesGiveTheSameTabsAsJson() {
        // [EN] The iOS bundle ships the same configuration in every format. [CN] iOS 的 bundle 以每种格式提供同一份配置。
        val fromPlist = TabConfiguration.configuration(sibling("plist"), platform = "android", appVersion = "1.0.0")
        val fromProperties = TabConfiguration.configuration(sibling("properties"), platform = "android", appVersion = "1.0.0")
        assertEquals(TabConfigurationFormat.PLIST, TabConfigurationFormats.detect(sibling("plist")))
        assertEquals(TabConfigurationFormat.PROPERTIES, TabConfigurationFormats.formatOf("a.properties"))
        assertEquals(listOf("home", "message", "web", "me"), fromPlist.tabs.map { it.pageId })
        assertEquals(listOf("home", "message", "web", "me"), fromProperties.tabs.map { it.pageId })
        assertEquals("https://github.com/ChenYilong/CYLTabBarController", fromProperties.tabs[2].pageParameters["url"])
        assertEquals("CYLConfigurationDemo", fromPlist.attributes["CYLTabBarControllerContext"])
    }

    @Test
    fun lookupOrderAndSkippedTabsFollowTheIosRules() {
        val configuration = TabConfiguration.configuration(
            """{"CYLTabBarControllerPageLookupOrder": "shared, bogus", "CYLTabBarControllerAutomaticPageRegistration": "no",
                "CYLTabBarControllerTabBarItemsAttributes": [{"CYLTabBarItemTitle": "Home", "CYLTabBarItemIdentifier": "home"},
                {"CYLTabBarItemTitle": "Android", "CYLTabBarItemIdentifier": "home", "CYLTabBarItemPlatforms": "ios"},
                {"CYLTabBarItemTitle": "No ID"}, {"CYLTabBarItemTitle": "Missing", "CYLTabBarItemPageIdentifier": "missing"}]}""",
            platform = "android", appVersion = "1.0")
        assertEquals(listOf(PageSource.SHARED), configuration.lookupOrder)
        assertEquals(listOf(SkipReason.EXCLUDED), configuration.skipped.map { it.reason })
        val shared = TabPageRegistry<String>().apply { register("home") { _, _ -> "home page" } }
        val skipped = ArrayList<SkippedTab>()
        val pages = TabPages.resolve(configuration.tabs, String::class.java, shared = shared, lookupOrder = configuration.lookupOrder, skipped = skipped)
        assertEquals(listOf("home page"), pages.map { it.second })
        assertEquals(listOf(SkipReason.MISSING_IDENTIFIER, SkipReason.UNREGISTERED), skipped.map { it.reason })
    }

    @Test
    fun reloadReusesExistingPagesByPageId() {
        var created = 0
        val shared = TabPageRegistry<String>().apply { register("home", "me") { id, _ -> created++; "$id#$created" } }
        val first = TabPages.resolve(listOf(TabItem(mapOf("CYLTabBarItemIdentifier" to "home"))), String::class.java, shared = shared)
        val reuse = first.groupBy({ it.first.pageId!! }, { it.second })
        val second = TabPages.resolve(
            listOf(TabItem(mapOf("CYLTabBarItemIdentifier" to "me")), TabItem(mapOf("CYLTabBarItemIdentifier" to "home"))),
            String::class.java, shared = shared, reuse = reuse)
        assertEquals(listOf("me#2", "home#1"), second.map { it.second })
        assertEquals(2, created)
    }

    @Test
    fun platformsAndMinimumVersionLeaveTabsOut() {
        // "Message" is for iOS and Android; "Me" needs 1.0.0. "Message" 适用于 iOS 与 Android；"Me" 需要 1.0.0。
        assertEquals(4, TabConfiguration.tabs(sharedJson, platform = "ios", appVersion = "1.0").size)
        assertEquals(3, TabConfiguration.tabs(sharedJson, platform = "android", appVersion = "0.9").size)
        assertEquals(3, TabConfiguration.tabs(sharedJson, platform = "web", appVersion = "2.0").size)
    }

    @Test
    fun versionsCompareNumberByNumber() {
        assertEquals(listOf(2L, 10L), TabConfiguration.versionNumbers("2.10"))
        assertNull(TabConfiguration.versionNumbers("2.x"))
        val tab = TabItem(mapOf(TabConfiguration.MINIMUM_APP_VERSION to "2.10"))
        assertTrue(TabConfiguration.exclusionReason(tab, "android", "2.9") != null)
        assertNull(TabConfiguration.exclusionReason(tab, "android", "2.10.0"))
        // Invalid values are ignored: the tab stays (B23, B24). 无效值被忽略：Tab 保留（B23、B24）。
        assertNull(TabConfiguration.exclusionReason(TabItem(mapOf(TabConfiguration.MINIMUM_APP_VERSION to "abc")), "android", "1.0"))
        assertNull(TabConfiguration.exclusionReason(TabItem(mapOf(TabConfiguration.PLATFORMS to 42)), "android", "1.0"))
    }

    @Test
    fun pageIdFallsBackToTheTabIdentifier() {
        assertEquals("home", TabItem(mapOf(TabConfiguration.IDENTIFIER to "home", TabConfiguration.PAGE_IDENTIFIER to " ")).pageId)
        assertEquals("web", TabItem(mapOf(TabConfiguration.IDENTIFIER to "discover", TabConfiguration.PAGE_IDENTIFIER to "web")).pageId)
        assertNull(TabItem(mapOf(TabConfiguration.TITLE to "No ID")).pageId)
    }

    @Test
    fun lookupOrderAndSkippedTabs() {
        val shared = TabPageRegistry<String>().apply {
            register("home", "me") { id, _ -> "shared:$id" }
        }
        val own = TabPageRegistry<String>().apply {
            register("home") { id, _ -> "own:$id" }
        }
        val tabs = TabConfiguration.tabs(sharedJson, appVersion = "1.0.0")
        val pages = TabPages.resolve(tabs, String::class.java, registry = own, shared = shared)
        // "message" and "web" are not registered: skipped. "message" 与 "web" 未注册：跳过。
        assertEquals(listOf("own:home", "shared:me"), pages.map { it.second })
    }

    @Test
    fun twoTabBarsMapOnePageIdToDifferentPages() {
        val tabs = TabConfiguration.tabs(sharedJson, appVersion = "1.0.0")
        val a = TabPageRegistry<String>().apply { register("home") { _, _ -> "A" } }
        val b = TabPageRegistry<String>().apply { register("home") { _, _ -> "B" } }
        assertEquals(listOf("A"), TabPages.resolve(tabs, String::class.java, registry = a).map { it.second })
        assertEquals(listOf("B"), TabPages.resolve(tabs, String::class.java, registry = b).map { it.second })
    }

    @Test
    fun badProvidersAreRefused() {
        val same = "one page"
        val registry = TabPageRegistry<String>().apply {
            register("home") { _, _ -> throw IllegalStateException("boom") }
            register("message", "web") { _, _ -> same }
        }
        val tabs = TabConfiguration.tabs(sharedJson, appVersion = "1.0.0")
        val pages = TabPages.resolve(tabs, String::class.java, registry = registry)
        // "home" throws, "web" returns the page of "message" again: both skipped. "home" 抛出异常，"web" 再次返回 "message" 的页面：都被跳过。
        assertEquals(listOf("message"), pages.map { it.first.pageId })
    }

    @Test
    fun automaticFactoriesAreFound() {
        assertTrue("auto" in TabPages.automaticFactories)
        val pages = TabPages.resolve(listOf(TabItem(mapOf(TabConfiguration.PAGE_IDENTIFIER to "auto"))), String::class.java)
        assertEquals(listOf("automatic page"), pages.map { it.second })
    }
}

/** [EN] Registered automatically through META-INF/services (test resources). [CN] 通过 META-INF/services（测试资源）自动注册。 */
class TestAutoPageFactory : TabPageFactory {
    override val pageId = "auto"
    override fun create(tab: TabItem): Any = "automatic page"
}
