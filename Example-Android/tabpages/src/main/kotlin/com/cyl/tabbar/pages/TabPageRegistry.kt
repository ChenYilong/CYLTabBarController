package com.cyl.tabbar.pages

import java.util.ServiceLoader

/**
 * [EN] Creates the page of a tab from its page ID and attributes; null skips the tab.
 * [CN] 根据页面 ID 与属性创建 Tab 的页面；返回 null 则跳过该 Tab。
 */
typealias TabPageProvider<P> = (pageId: String, tab: TabItem) -> P?

/**
 * [EN] A map from cross-platform page IDs to page providers: the Android twin of iOS's `CYLTabBarPageRegistry`. The
 *      configuration file names each tab's page by a string ID (`CYLTabBarItemPageIdentifier`, else
 *      `CYLTabBarItemIdentifier`); each platform registers what that ID creates. Create one registry per tab bar, and
 *      use [TabPageRegistry.shared]-style globals for pages every tab bar shares (see [TabPages.resolve]).
 * [CN] 跨端页面 ID 到页面提供者的映射，对应 iOS 的 `CYLTabBarPageRegistry`。配置文件用字符串 ID 指定每个 Tab 的页面
 *      （`CYLTabBarItemPageIdentifier`，否则为 `CYLTabBarItemIdentifier`），各平台注册该 ID 创建什么页面。每个 TabBar 可以有自己的注册表，
 *      所有 TabBar 共用的页面放在全局注册表中（见 [TabPages.resolve]）。
 */
class TabPageRegistry<P : Any> {
    private val providers = LinkedHashMap<String, TabPageProvider<P>>()

    /** [EN] Registers (or replaces) one provider for one or more page IDs; blank IDs are ignored. [CN] 为一个或多个页面 ID 注册（或替换）提供者；空 ID 会被忽略。 */
    @Synchronized
    fun register(vararg pageIds: String, provider: TabPageProvider<P>) {
        for (pageId in pageIds) {
            val id = pageId.trim()
            if (id.isNotEmpty()) providers[id] = provider
        }
    }

    /** [EN] Removes the provider of a page ID. [CN] 移除页面 ID 的提供者。 */
    @Synchronized
    fun unregister(pageId: String) {
        providers.remove(pageId.trim())
    }

    /** [EN] The provider of a page ID, or null. [CN] 页面 ID 的提供者，没有则为 null。 */
    @Synchronized
    fun provider(pageId: String): TabPageProvider<P>? = providers[pageId.trim()]

    /** [EN] The registered page IDs, sorted. [CN] 已注册的页面 ID（已排序）。 */
    @get:Synchronized
    val registeredPageIds: List<String>
        get() = providers.keys.sorted()
}

/**
 * [EN] Automatic registration, the Android twin of iOS's `CYLTabBarPage`: list a class that implements this interface
 *      in `META-INF/services/com.cyl.tabbar.pages.TabPageFactory` and it is found by [ServiceLoader], with no
 *      registration code. When two factories claim one ID, the first in class name order is kept.
 * [CN] 自动注册，对应 iOS 的 `CYLTabBarPage`：在 `META-INF/services/com.cyl.tabbar.pages.TabPageFactory` 中列出实现此接口的类，
 *      [ServiceLoader] 会找到它，无需注册代码。两个工厂声明同一个 ID 时，按类名顺序保留第一个。
 */
interface TabPageFactory {
    /** [EN] The page ID, e.g. "auto". [CN] 页面 ID，例如 "auto"。 */
    val pageId: String

    /** [EN] Creates the page (e.g. a Fragment); null skips the tab. [CN] 创建页面（例如 Fragment）；返回 null 则跳过该 Tab。 */
    fun create(tab: TabItem): Any?
}

/**
 * [EN] The pages of the tabs, found like on iOS.
 * [CN] 按与 iOS 相同的规则查找各 Tab 的页面。
 */
object TabPages {
    /** [EN] Factories found by [ServiceLoader], by page ID; loaded once. [CN] [ServiceLoader] 找到的工厂（按页面 ID）；只加载一次。 */
    val automaticFactories: Map<String, TabPageFactory> by lazy {
        val factories = ServiceLoader.load(TabPageFactory::class.java).toList().sortedBy { it.javaClass.name }
        val byId = LinkedHashMap<String, TabPageFactory>()
        for (factory in factories) {
            val id = factory.pageId.trim()
            if (id.isEmpty()) continue
            if (id in byId) {
                println("CYLTabBar: ${byId.getValue(id).javaClass.name} and ${factory.javaClass.name} both claim the page ID \"$id\"; the first is used.")
                continue
            }
            byId[id] = factory
        }
        byId
    }

    /**
     * [EN] The page of each tab, in the order of the tabs. Each page ID is looked up in this order: [registry] (the tab
     *      bar's own), [resolver], [shared] (the global registry), the [automaticFactories]; a tab without a page is
     *      skipped. A provider that throws, returns a page of the wrong type or a page already used by another tab is
     *      refused (iOS edge cases C12, C13).
     * [CN] 按 Tab 的顺序返回各 Tab 的页面。页面 ID 依次在 [registry]（该 TabBar 自己的）、[resolver]、[shared]（全局注册表）与
     *      [automaticFactories] 中查找；没有页面的 Tab 会被跳过。提供者抛出异常、返回错误类型或已被其他 Tab 使用的页面时会被拒绝
     *      （对应 iOS 的 C12、C13）。
     */
    fun <P : Any> resolve(
        tabs: List<TabItem>,
        pageClass: Class<P>,
        registry: TabPageRegistry<P>? = null,
        resolver: TabPageProvider<P>? = null,
        shared: TabPageRegistry<P>? = null,
    ): List<Pair<TabItem, P>> {
        val pages = ArrayList<Pair<TabItem, P>>()
        for (tab in tabs) {
            val pageId = tab.pageId
            if (pageId == null) {
                println("CYLTabBar: the tab \"${tab.title.orEmpty()}\" has no page ID; skipped.")
                continue
            }
            val candidates = listOfNotNull(
                registry?.provider(pageId),
                resolver,
                shared?.provider(pageId),
                automaticFactories[pageId]?.let { factory -> { _: String, item: TabItem -> pageClass.cast(factory.create(item)) } },
            )
            var page: P? = null
            for (provider in candidates) {
                page = call(provider, pageId, tab, pageClass, pages)
                if (page != null) break
            }
            if (page == null) {
                println("CYLTabBar: no page for \"$pageId\"; the tab is skipped.")
                continue
            }
            pages += tab to page
        }
        return pages
    }

    private fun <P : Any> call(provider: TabPageProvider<P>, pageId: String, tab: TabItem, pageClass: Class<P>,
                               used: List<Pair<TabItem, P>>): P? {
        val page: Any? = try {
            provider(pageId, tab)
        } catch (error: Exception) {
            println("CYLTabBar: the provider of \"$pageId\" threw $error; the tab is skipped.")
            return null
        }
        if (page == null) return null
        if (!pageClass.isInstance(page)) {
            println("CYLTabBar: the page of \"$pageId\" is not a ${pageClass.simpleName}; the tab is skipped.")
            return null
        }
        if (used.any { it.second === page }) {
            println("CYLTabBar: the page of \"$pageId\" is already the page of another tab; the tab is skipped.")
            return null
        }
        return pageClass.cast(page)
    }
}
