// [EN] The method names are the iOS names on purpose (`cyl_…`, `tabBarController_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`、`tabBarController_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import androidx.fragment.app.Fragment
import com.cyl.tabbar.pages.PageSource
import com.cyl.tabbar.pages.SkipReason
import com.cyl.tabbar.pages.SkippedTab
import com.cyl.tabbar.pages.TabItem
import com.cyl.tabbar.pages.TabPageFactory
import com.cyl.tabbar.pages.TabPageRegistry
import com.cyl.tabbar.pages.TabPages

/** [EN] `CYLTabBarPageProvider`: creates the page of a tab from its page ID and attributes; null skips the tab. [CN] 由页面 ID 与属性创建页面；null 跳过该 Tab。 */
typealias CYLTabBarPageProvider = (pageIdentifier: String, tabAttributes: Map<String, Any?>) -> Fragment?

/** [EN] `CYLTabBarPageFactory`: the same with a typed request. [CN] 类型化请求的工厂。 */
typealias CYLTabBarPageFactory = (request: CYLTabBarPageRequest) -> Fragment?

/** [EN] `CYLTabBarPageCompletion` / `CYLTabBarAsyncPageFactory`: deliver the page later; the returned Fragment is shown meanwhile (null: a `CYLTabBarPagePlaceholder`). [CN] 异步交付页面；返回的 Fragment 为期间显示的占位（null 为内置占位）。 */
typealias CYLTabBarPageCompletion = (page: Fragment?) -> Unit
typealias CYLTabBarAsyncPageFactory = (request: CYLTabBarPageRequest, completion: CYLTabBarPageCompletion) -> Fragment?

/** [EN] `CYLTabBarPageSource`: where pages are looked up (`instance`, `resolver`, `shared`, `automatic`). [CN] 页面来源。 */
typealias CYLTabBarPageSource = PageSource

/** [EN] `CYLTabBarPageSkipReason`. [CN] 跳过原因。 */
typealias CYLTabBarPageSkipReason = SkipReason

/** [EN] `CYLTabBarSkippedTab`. [CN] 被跳过的 Tab。 */
typealias CYLTabBarSkippedTab = SkippedTab

/** [EN] `CYLTabBarPageRequest`: the typed request of a factory (public attributes only). [CN] 工厂的类型化请求（只含公开属性）。 */
class CYLTabBarPageRequest(val pageIdentifier: String, attributes: Map<String, Any?>) {
    val attributes: Map<String, Any?> = attributes.filterKeys { !it.startsWith("_") }
    val tabIdentifier: String? = attributes[CYLConstants.CYLTabBarItemIdentifier] as? String
    val title: String? = attributes[CYLConstants.CYLTabBarItemTitle] as? String
    val parameters: Map<String, Any?> = (attributes[CYLConstants.CYLTabBarItemPageParameters] as? Map<*, *>)?.entries?.associate { it.key.toString() to it.value } ?: emptyMap()
}

/** [EN] `CYLTabBarPageProviding`: any page source (`CYLTabBarPageRegistry`, a router, a mock). [CN] 任何页面来源。 */
fun interface CYLTabBarPageProviding {
    fun pageProviderForPageIdentifier(pageIdentifier: String): CYLTabBarPageProvider?
}

/** [EN] `CYLTabBarPage`: a Fragment class registered automatically under its page ID (through `TabPageFactory` / ServiceLoader on Android). [CN] 自动按页面 ID 注册的 Fragment 类（Android 通过 `TabPageFactory` / ServiceLoader）。 */
typealias CYLTabBarPage = TabPageFactory

/** [EN] `CYLTabBarPagePlaceholder`: shown while an asynchronous factory loads its page. [CN] 异步工厂加载页面期间显示。 */
open class CYLTabBarPagePlaceholder : Fragment()

/**
 * [EN] `CYLTabBarPageRegistry`: page IDs -> providers, the shared registry, the lookup, and the asynchronous factories;
 *      a thin iOS-named layer over `TabPageRegistry` (`tabpages`).
 * [CN] `CYLTabBarPageRegistry`：页面 ID -> 提供者、全局注册表、查找与异步工厂；对 `TabPageRegistry`（`tabpages`）的薄封装，名称与 iOS 相同。
 */
class CYLTabBarPageRegistry : CYLTabBarPageProviding {

    val registry = TabPageRegistry<Fragment>()

    fun registerPageProvider(provider: CYLTabBarPageProvider, forPageIdentifier: String) {
        registry.register(forPageIdentifier) { id, tab -> provider(id, tab.attributes) }
    }

    fun registerPageProvider(provider: CYLTabBarPageProvider, forPageIdentifiers: List<String>) {
        forPageIdentifiers.forEach { registerPageProvider(provider, it) }
    }

    fun registerPageFactory(factory: CYLTabBarPageFactory, forPageIdentifier: String) =
        registerPageProvider({ id, attributes -> factory(CYLTabBarPageRequest(id, attributes)) }, forPageIdentifier)

    fun registerPageFactory(factory: CYLTabBarPageFactory, forPageIdentifiers: List<String>) =
        forPageIdentifiers.forEach { registerPageFactory(factory, it) }

    /** [EN] An asynchronous factory: the placeholder is returned at once, the page is swapped in by the tab bar controller when it arrives. [CN] 异步工厂：先返回占位，页面到达后由 TabBarController 换入。 */
    fun registerAsyncPageFactory(factory: CYLTabBarAsyncPageFactory, forPageIdentifier: String) {
        registerPageProvider({ id, attributes ->
            val load = CYLTabBarPageLoad()
            val placeholder = factory(CYLTabBarPageRequest(id, attributes)) { page -> load.finish(page) } ?: CYLTabBarPagePlaceholder()
            CYLTabBarPageLoad.attach(placeholder, load)
            placeholder
        }, forPageIdentifier)
    }

    fun registerAsyncPageFactory(factory: CYLTabBarAsyncPageFactory, forPageIdentifiers: List<String>) =
        forPageIdentifiers.forEach { registerAsyncPageFactory(factory, it) }

    /** [EN] `-registerPageClass:`: a `TabPageFactory` registered under its own ID. [CN] 按工厂自己的 ID 注册。 */
    fun registerPageClass(pageClass: TabPageFactory) {
        registry.register(pageClass.pageId) { _, tab -> pageClass.create(tab) as? Fragment }
    }

    fun unregisterPageIdentifier(pageIdentifier: String) = registry.unregister(pageIdentifier)

    fun removeAllPageProviders() = registry.registeredPageIds.forEach { registry.unregister(it) }

    override fun pageProviderForPageIdentifier(pageIdentifier: String): CYLTabBarPageProvider? {
        val provider = registry.provider(pageIdentifier) ?: return null
        return { id, attributes -> provider(id, TabItem(attributes)) }
    }

    val registeredPageIdentifiers: List<String> get() = registry.registeredPageIds

    companion object {
        /** [EN] `+sharedRegistry`. [CN] 全局注册表。 */
        @JvmStatic val sharedRegistry = CYLTabBarPageRegistry()

        /** [EN] `+automaticallyRegisteredPageClasses`: the `TabPageFactory`s found by ServiceLoader. [CN] ServiceLoader 找到的工厂。 */
        @JvmStatic val automaticallyRegisteredPageClasses: Map<String, TabPageFactory> get() = TabPages.automaticFactories

        /** [EN] `+rescanPageClasses` / `+prepareAutomaticRegistrationInBackground`: ServiceLoader loads once; a rescan is a no-op on Android. [CN] ServiceLoader 只加载一次；Android 上重新扫描无操作。 */
        @JvmStatic fun rescanPageClasses() = Unit
        @JvmStatic fun prepareAutomaticRegistrationInBackground() { Thread { TabPages.automaticFactories }.start() }

        @JvmStatic val defaultPageLookupOrder: List<CYLTabBarPageSource> get() = PageSource.entries

        /** [EN] `+pageIdentifierOfTab:`. [CN] Tab 的页面 ID。 */
        @JvmStatic fun pageIdentifierOfTab(tabAttributes: Map<String, Any?>): String? = TabItem(tabAttributes).pageId

        /**
         * [EN] `+pagesOfTabs:registry:resolver:lookupOrder:keptTabs:skipped:`: the pages of `tabs`, in order; tabs
         *      without a page go to `skipped`, the kept attributes to `keptTabs`.
         * [CN] `tabs` 的页面（按顺序）；没有页面的 Tab 记录到 `skipped`，保留的属性记录到 `keptTabs`。
         */
        @JvmStatic
        fun pagesOfTabs(
            tabs: List<Map<String, Any?>>,
            registry: CYLTabBarPageProviding?,
            resolver: CYLTabBarPageProvider?,
            lookupOrder: List<CYLTabBarPageSource>?,
            keptTabs: MutableList<Map<String, Any?>>?,
            skipped: MutableList<CYLTabBarSkippedTab>?,
            reuse: Map<String, List<Fragment>>? = null,
        ): List<Fragment> {
            val instance = registry?.let { providing ->
                TabPageRegistry<Fragment>().also { bridge ->
                    for (tab in tabs) {
                        val id = TabItem(tab).pageId ?: continue
                        providing.pageProviderForPageIdentifier(id)?.let { provider -> bridge.register(id) { pageId, item -> provider(pageId, item.attributes) } }
                    }
                }
            }
            val items = tabs.map { TabItem(it) }
            val resolved = TabPages.resolve(
                items, Fragment::class.java, registry = instance,
                resolver = resolver?.let { r -> { id: String, item: TabItem -> r(id, item.attributes) } },
                shared = sharedRegistry.registry,
                options = TabPages.Options(lookupOrder ?: PageSource.entries, skipped, reuse),
            )
            keptTabs?.addAll(resolved.map { it.first.attributes })
            return resolved.map { it.second }
        }
    }
}

/** [EN] The pending load behind a placeholder (`cyl_isPendingPage`, `cyl_loadedPage`, `cyl_pageLoadFailed`). [CN] 占位背后的待完成加载。 */
class CYLTabBarPageLoad {
    @Volatile var finished = false
        private set
    @Volatile var page: Fragment? = null
        private set
    val failed: Boolean get() = finished && page == null
    @Volatile var handler: ((Fragment) -> Unit)? = null
    internal var placeholder: Fragment? = null

    fun finish(page: Fragment?) {
        val main = android.os.Handler(android.os.Looper.getMainLooper())
        if (android.os.Looper.myLooper() != android.os.Looper.getMainLooper()) {
            main.post { finish(page) }
            return
        }
        if (finished) return
        finished = true
        this.page = page
        placeholder?.let { handler?.invoke(it) }
    }

    companion object {
        private val loads = java.util.WeakHashMap<Fragment, CYLTabBarPageLoad>()
        internal fun attach(placeholder: Fragment, load: CYLTabBarPageLoad) {
            load.placeholder = placeholder
            synchronized(loads) { loads[placeholder] = load }
        }
        fun of(fragment: Fragment): CYLTabBarPageLoad? = synchronized(loads) { loads[fragment] }
    }
}

/** [EN] `UIViewController (CYLTabBarPageLoading)`. [CN] 页面加载状态。 */
val Fragment.cyl_isPendingPage: Boolean get() = CYLTabBarPageLoad.of(this)?.let { !it.finished } ?: false
val Fragment.cyl_loadedPage: Fragment? get() = CYLTabBarPageLoad.of(this)?.takeIf { it.finished }?.page
val Fragment.cyl_pageLoadFailed: Boolean get() = CYLTabBarPageLoad.of(this)?.failed ?: false
var Fragment.cyl_pageLoadHandler: ((Fragment) -> Unit)?
    get() = CYLTabBarPageLoad.of(this)?.handler
    set(value) { CYLTabBarPageLoad.of(this)?.handler = value }
