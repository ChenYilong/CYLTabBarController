// [EN] The method names are the iOS names on purpose (`cyl_…`, `tabBarController_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`、`tabBarController_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.view.View
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentManager

/*
 * [EN] `UIViewController (CYLTabBarControllerExtention)` as Fragment extensions: the page's tab, its tab button and
 *      badge, selecting another tab, and the navigation helpers (a child back stack stands in for the navigation
 *      controller).
 * [CN] 以 Fragment 扩展实现的 `UIViewController (CYLTabBarControllerExtention)`：页面所在的 Tab、其 Tab 按钮与角标、选中其他 Tab，以及导航
 *      辅助方法（子返回栈代替导航控制器）。
 */

/** [EN] `cyl_isEmbedInTabBarController`: the page is a tab of a tab bar controller. [CN] 页面是某个 TabBarController 的 Tab。 */
val Fragment.cyl_isEmbedInTabBarController: Boolean get() = cyl_tabBarController != null

/** [EN] `cyl_tabIndex`: the page's index among the tabs, or -1. [CN] 页面在 Tab 中的下标，没有则为 -1。 */
val Fragment.cyl_tabIndex: Int get() = cyl_tabBarController?.viewControllers?.indexOf(cyl_rootTab(this)) ?: -1

private fun cyl_rootTab(fragment: Fragment): Fragment {
    var tab = fragment
    val controller = fragment.cyl_tabBarController ?: return fragment
    while (tab !in controller.viewControllers && tab.parentFragment != null) tab = tab.parentFragment!!
    return tab
}

/** [EN] `cyl_tabBarItemIdentifier`: the identifier of the page's tab. [CN] 页面所在 Tab 的标识。 */
var Fragment.cyl_tabBarItemIdentifier: String?
    get() = cyl_tabBarController?.cyl_tabBarItemIdentifiers?.getOrNull(cyl_tabIndex)
    set(value) {
        val controller = cyl_tabBarController ?: return
        val index = cyl_tabIndex
        if (index >= 0) controller.tabBarItems[index].cyl_tabBarItemIdentifier = value
    }

/** [EN] `cyl_tabButton` / `cyl_visiableTabButton`: the page's tab button. [CN] 页面的 Tab 按钮。 */
val Fragment.cyl_tabButton: CYLTabBarItemButton? get() = cyl_tabBarController?.tabBar?.cyl_tabBarButtonWithTabIndex(cyl_tabIndex)
fun Fragment.cyl_visiableTabButton(): View? = cyl_tabButton

/** [EN] `cyl_isSystemStyleTabBar` / `cyl_isFlatDesignStyleTabBar`. [CN] 样式判断。 */
fun Fragment.cyl_isSystemStyleTabBar(): Boolean = cyl_tabBarController?.tabBarStyleType != CYLEnums.CYLTabBarStyleType.FlatDesign
fun Fragment.cyl_isFlatDesignStyleTabBar(): Boolean = cyl_tabBarController?.tabBarStyleType == CYLEnums.CYLTabBarStyleType.FlatDesign

// MARK: - Badges on the page's tab 页面 Tab 的角标

fun Fragment.cyl_isShowBadge(): Boolean = cyl_tabButton?.cyl_isShowBadge() ?: false
fun Fragment.cyl_showBadge() { cyl_tabButton?.cyl_showBadge() }
fun Fragment.cyl_showBadgeValue(value: String) { cyl_tabButton?.cyl_showBadgeValue(value) }
fun Fragment.cyl_showBadgeValue(value: String, animationType: CYLEnums.CYLBadgeAnimationType) { cyl_tabButton?.cyl_showBadgeValue(value, animationType) }
fun Fragment.cyl_clearBadge() { cyl_tabButton?.cyl_clearBadge() }
fun Fragment.cyl_resumeBadge() { cyl_tabButton?.cyl_resumeBadge() }
fun Fragment.cyl_isPauseBadge(): Boolean = cyl_tabButton?.cyl_isPauseBadge() ?: false

// MARK: - Selecting tabs 选中 Tab

/** [EN] `-cyl_popSelectTabBarChildViewControllerAtIndex:`: pops this page's stack to its root and selects the tab at `index`; the selected page, or null. [CN] 本页面返回栈回到根并选中第 `index` 个 Tab；返回选中的页面。 */
fun Fragment.cyl_popSelectTabBarChildViewControllerAtIndex(index: Int, animated: Boolean = true): Fragment? {
    val controller = cyl_tabBarController ?: return null
    val target = controller.viewControllers.getOrNull(index) ?: return null
    cyl_handleNavigationBackActionWithAnimated(animated, toRoot = true)
    controller.selectedIndex = index
    return target
}

fun Fragment.cyl_popSelectTabBarChildViewControllerAtIndex(index: Int, animated: Boolean, block: ((Fragment) -> Unit)?) {
    cyl_popSelectTabBarChildViewControllerAtIndex(index, animated)?.let { block?.invoke(it) }
}

/** [EN] `-cyl_popSelectTabBarChildViewControllerForClassType:`: the first tab of that class. [CN] 第一个该类的 Tab。 */
fun Fragment.cyl_popSelectTabBarChildViewControllerForClassType(classType: Class<out Fragment>, animated: Boolean = true): Fragment? {
    val index = cyl_tabBarController?.viewControllers?.indexOfFirst { classType.isInstance(it) } ?: -1
    return if (index >= 0) cyl_popSelectTabBarChildViewControllerAtIndex(index, animated) else null
}

fun Fragment.cyl_popSelectTabBarChildViewControllerForClassType(classType: Class<out Fragment>, animated: Boolean, block: ((Fragment) -> Unit)?) {
    cyl_popSelectTabBarChildViewControllerForClassType(classType, animated)?.let { block?.invoke(it) }
}

/** [EN] `-cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier:`. [CN] 按标识选中。 */
fun Fragment.cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier(identifier: String, animated: Boolean = true): Fragment? {
    val index = cyl_tabBarController?.cyl_indexOfTabBarItemIdentifier(identifier) ?: -1
    return if (index >= 0) cyl_popSelectTabBarChildViewControllerAtIndex(index, animated) else null
}

fun Fragment.cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier(identifier: String, animated: Boolean, block: ((Fragment) -> Unit)?) {
    cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier(identifier, animated)?.let { block?.invoke(it) }
}

/** [EN] `-cyl_isEqualToViewController:`: the same page, or the same page inside a container. [CN] 同一页面，或容器中的同一页面。 */
fun Fragment.cyl_isEqualToViewController(compared: Fragment?): Boolean = compared != null && (this === compared || cyl_rootTab(this) === cyl_rootTab(compared))

// MARK: - Navigation (a child back stack) 导航（子返回栈）

/** [EN] The container the page pushes into: its own view, as a child Fragment on the back stack. [CN] 页面 push 的容器：自身的视图，子 Fragment 加入返回栈。 */
private fun Fragment.cyl_pushContainerId(): Int? = (view as? android.view.ViewGroup)?.let { if (it.id == View.NO_ID) it.id = View.generateViewId(); it.id }

/** [EN] `-cyl_pushViewController:animated:`: shows `viewController` over this page (a child Fragment on the back stack). [CN] 在本页面之上显示 `viewController`（子 Fragment，加入返回栈）。 */
fun Fragment.cyl_pushViewController(viewController: Fragment, animated: Boolean = true) {
    val container = cyl_pushContainerId() ?: return
    childFragmentManager.beginTransaction().apply {
        if (animated) setTransition(androidx.fragment.app.FragmentTransaction.TRANSIT_FRAGMENT_OPEN)
        add(container, viewController).addToBackStack(null)
    }.commit()
}

/** [EN] `-cyl_pushOrPopToViewController:animated:`: pops back to it when it is on the stack, else pushes it. [CN] 已在栈中则弹回，否则 push。 */
fun Fragment.cyl_pushOrPopToViewController(viewController: Fragment, animated: Boolean = true) {
    if (childFragmentManager.fragments.contains(viewController)) {
        childFragmentManager.popBackStack()
    } else {
        cyl_pushViewController(viewController, animated)
    }
}

fun Fragment.cyl_pushOrPopToViewController(viewController: Fragment, animated: Boolean, completion: (() -> Unit)?) {
    cyl_pushOrPopToViewController(viewController, animated)
    completion?.invoke()
}

/** [EN] `-cyl_handleNavigationBackAction`: pops the page's stack (to the root with `toRoot`). [CN] 弹出页面的返回栈（`toRoot` 回到根）。 */
fun Fragment.cyl_handleNavigationBackAction() = cyl_handleNavigationBackActionWithAnimated(true)

fun Fragment.cyl_handleNavigationBackActionWithAnimated(animated: Boolean, toRoot: Boolean = false) {
    val manager = cyl_rootTab(this).childFragmentManager
    // [EN] Without animation the pop is executed at once, as `popViewControllerAnimated:NO` returns synchronously. [CN] 不带动画时立即执行，如同 `popViewControllerAnimated:NO` 同步返回。
    when {
        toRoot && animated -> manager.popBackStack(null, FragmentManager.POP_BACK_STACK_INCLUSIVE)
        toRoot -> manager.popBackStackImmediate(null, FragmentManager.POP_BACK_STACK_INCLUSIVE)
        animated -> manager.popBackStack()
        else -> manager.popBackStackImmediate()
    }
}

/** [EN] `-cyl_addChildViewController:`: adds a child page without the back stack. [CN] 添加子页面（不加入返回栈）。 */
fun Fragment.cyl_addChildViewController(child: Fragment) {
    val container = cyl_pushContainerId() ?: return
    childFragmentManager.beginTransaction().add(container, child).commit()
}
