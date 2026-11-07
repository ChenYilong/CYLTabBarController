package com.cyl.tabbar.demo

import android.content.Context
import androidx.core.content.ContextCompat
import com.cyl.tabbar.CYLTabBarConfiguration
import com.cyl.tabbar.CYLTabBarPageRegistry
import com.cyl.tabbar.pages.TabItem
import com.cyl.tabbar.pages.TabPageFactory

/**
 * [EN] The pages of the shared sample file, registered in `CYLTabBarPageRegistry.sharedRegistry` under the same page IDs
 *      as the iOS demo (home, message, discover, me, web), and the icons of its "system:…" names.
 * [CN] 共用示例文件的页面，以与 iOS 演示相同的页面 ID（home、message、discover、me、web）注册在
 *      `CYLTabBarPageRegistry.sharedRegistry` 中，以及其 "system:…" 名称对应的图标。
 */
object DemoPages {
    private var registered = false

    /** [EN] SF Symbol names of the shared file -> Android drawables. [CN] 共用文件中的 SF Symbol 名称 -> Android 图标。 */
    private val icons = mapOf(
        "house" to android.R.drawable.ic_menu_myplaces,
        "message" to android.R.drawable.ic_dialog_email,
        "safari" to android.R.drawable.ic_menu_compass,
        "globe" to android.R.drawable.ic_menu_compass,
        "person" to android.R.drawable.ic_menu_my_calendar,
        "clock" to android.R.drawable.ic_menu_recent_history,
        "star" to android.R.drawable.btn_star,
    )

    @Synchronized
    fun registerOnce() {
        if (registered) return
        registered = true
        CYLTabBarConfiguration.imageResolver = CYLTabBarConfiguration.CYLTabBarImageResolver { context: Context, name: String ->
            val symbol = name.removePrefix("system:").substringBefore('.')
            ContextCompat.getDrawable(context, icons[symbol] ?: android.R.drawable.ic_menu_help)
        }
        val shared = CYLTabBarPageRegistry.sharedRegistry
        shared.registerPageProvider({ id, tab -> TextPageFragment.newInstance("${TabItem(tab).title}\npage ID: $id", opensTwoTabBars = true) }, "home")
        shared.registerPageProvider({ id, tab -> TextPageFragment.newInstance("${TabItem(tab).title}\npage ID: $id") }, listOf("message", "discover", "me"))
        shared.registerPageFactory({ request ->
            val url = request.parameters["url"] as? String
            TextPageFragment.newInstance("Web\npage ID: ${request.pageIdentifier}\nCYLTabBarItemPageParameters.url:\n${url ?: "(no url)"}", url = url)
        }, "web")
    }
}

/** [EN] A page registered automatically (`META-INF/services`), like a `CYLTabBarPage` class on iOS. [CN] 自动注册的页面（`META-INF/services`），对应 iOS 的 `CYLTabBarPage` 类。 */
class AutoPageFactory : TabPageFactory {
    override val pageId = "auto"
    override fun create(tab: TabItem): Any = TextPageFragment.newInstance("Auto\nAutoPageFactory (no registration code)")
}
