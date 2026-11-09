// [EN] The method names are the iOS names on purpose (`cyl_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import androidx.fragment.app.Fragment
import java.util.WeakHashMap

/*
 * [EN] `UIViewController (CYLTabBarItemTitle)` as Fragment extensions: the title of the page's tab, and a page whose
 *      navigation title follows it. An Android activity has one action bar for every tab (an iOS tab has its own navigation
 *      bar), so a following page puts its tab title in the activity's title while it is selected, and again whenever that
 *      title changes in place (`updateTabBarItemAtIndex`, a skin, `updatePlusButtonWithAttributes`). A page with a toolbar
 *      of its own observes `CYLTabBarItemTitleDidChangeNotification` instead.
 * [CN] 以 Fragment 扩展实现的 `UIViewController (CYLTabBarItemTitle)`：页面所在 Tab 的标题，以及导航标题跟随它的页面。Android 的 Activity 只有一个
 *      ActionBar，所有 Tab 共用（iOS 的每个 Tab 有自己的导航栏），因此跟随的页面在被选中时把 Tab 标题写入 Activity 的标题，标题原地变化时
 *      （`updateTabBarItemAtIndex`、皮肤、`updatePlusButtonWithAttributes`）再次写入。有自己 Toolbar 的页面改为观察
 *      `CYLTabBarItemTitleDidChangeNotification`。
 */

private val followingPages = WeakHashMap<Fragment, Boolean>()

/** [EN] The page itself, or the tab (or plus button's page) that holds it. [CN] 页面本身，或包含它的 Tab（或 PlusButton 的页面）。 */
private fun CYLTabBarController.cyl_pageOfFragment(fragment: Fragment): Fragment? {
    var candidate: Fragment? = fragment
    val plusChild = tabBar.plusButton?.provider?.plusChildViewController()
    while (candidate != null) {
        if (candidate in viewControllers || candidate === plusChild) return candidate
        candidate = candidate.parentFragment
    }
    return null
}

/**
 * [EN] `cyl_tabBarItemTitle`: the title of the page's tab (the plus button's title for the plus button's page), or null.
 * [CN] 页面所在 Tab 的标题（PlusButton 的页面为 PlusButton 的标题），没有时为 null。
 */
val Fragment.cyl_tabBarItemTitle: String?
    get() {
        val controller = cyl_tabBarController ?: return null
        val page = controller.cyl_pageOfFragment(this) ?: return null
        val plusButton = controller.tabBar.plusButton
        if (plusButton != null && page === plusButton.provider?.plusChildViewController()) return plusButton.cyl_title
        val index = controller.viewControllers.indexOf(page)
        return controller.tabBarItemsAttributes.getOrNull(index)?.get(CYLConstants.CYLTabBarItemTitle) as? String
    }

/**
 * [EN] `cyl_navigationTitleFollowsTabBarItemTitle`: the activity's title follows this page's tab title while the page is
 *      selected. Set it on the tab's page (or a fragment inside it), e.g. in `onCreate`.
 * [CN] 页面被选中时，Activity 的标题跟随该页面的 Tab 标题。设置在 Tab 的页面（或其中的 Fragment）上，例如在 `onCreate` 中。
 */
var Fragment.cyl_navigationTitleFollowsTabBarItemTitle: Boolean
    get() = followingPages[this] == true
    set(value) {
        if (value) followingPages[this] = true else followingPages.remove(this)
        if (value) cyl_tabBarController?.cyl_applyNavigationTitleOfSelectedPage()
    }

/**
 * [EN] Writes the selected page's tab title into the activity's title when that page (or the fragment that holds it) follows
 *      its tab title. Called on selection and after every in-place change.
 * [CN] 选中的页面（或包含它的 Fragment）跟随 Tab 标题时，把其 Tab 标题写入 Activity 的标题。在选中时以及每次原地变化后调用。
 */
internal fun CYLTabBarController.cyl_applyNavigationTitleOfSelectedPage() {
    val page = (if (tabBar.plusButtonActive) tabBar.plusButton?.provider?.plusChildViewController() else selectedViewController) ?: return
    val follows = followingPages.keys.any { it.cyl_navigationTitleFollowsTabBarItemTitle && cyl_pageOfFragment(it) === page }
    if (!follows) return
    // [EN] No tab title (e.g. a plus button without a title): an empty title, as the page's own navigation bar on iOS; the
    //      shared action bar kept the previous tab's title, which named the wrong page.
    // [CN] 没有 Tab 标题时（例如 PlusButton 没有标题）使用空标题，与 iOS 上页面自己的导航栏一致；以前共用的 ActionBar 保留上一个 Tab 的标题，
    //      显示的是错误页面的名称。
    val title = page.cyl_tabBarItemTitle.orEmpty()
    if (activity.title?.toString() != title) activity.title = title
}
