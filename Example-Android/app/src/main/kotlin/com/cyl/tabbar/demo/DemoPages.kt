package com.cyl.tabbar.demo

import androidx.fragment.app.Fragment
import com.cyl.tabbar.pages.TabItem
import com.cyl.tabbar.pages.TabPageFactory
import com.cyl.tabbar.pages.TabPageRegistry

/**
 * [EN] The pages of the demo, in the global registry, under the same page IDs as the iOS demo: "home", "message",
 *      "discover", "me", and "web", which shows the URL of its CYLTabBarItemPageParameters. An app registers its pages
 *      once at launch, like this.
 * [CN] 演示的页面，注册到全局注册表，页面 ID 与 iOS 演示相同："home"、"message"、"discover"、"me"，以及显示其
 *      CYLTabBarItemPageParameters 中 URL 的 "web"。App 在启动时这样注册一次自己的页面。
 */
object DemoPages {
    val shared = TabPageRegistry<Fragment>()

    private var registered = false

    @Synchronized
    fun registerOnce() {
        if (registered) return
        registered = true
        shared.register("home") { id, tab ->
            TextPageFragment.newInstance("${tab.title}\npage ID: $id", opensTwoTabBars = true)
        }
        shared.register("message", "discover", "me") { id, tab ->
            TextPageFragment.newInstance("${tab.title}\npage ID: $id")
        }
        shared.register("web") { id, tab ->
            val url = tab.pageParameters["url"]
            TextPageFragment.newInstance("Web\npage ID: $id\nCYLTabBarItemPageParameters.url:\n${url ?: "(no url)"}", url = url)
        }
    }
}

/**
 * [EN] Registered automatically under "auto" (META-INF/services), like a `CYLTabBarPage` class on iOS.
 * [CN] 通过 META-INF/services 自动注册为 "auto"，对应 iOS 上遵守 `CYLTabBarPage` 的类。
 */
class AutoPageFactory : TabPageFactory {
    override val pageId = "auto"
    override fun create(tab: TabItem): Any = TextPageFragment.newInstance("Auto\nAutoPageFactory (no registration code)")
}
