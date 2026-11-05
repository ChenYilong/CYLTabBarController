package com.cyl.tabbar.demo

import android.view.Menu
import androidx.annotation.IdRes
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentManager
import com.cyl.tabbar.pages.TabItem
import com.google.android.material.bottomnavigation.BottomNavigationView

/**
 * [EN] Shows tabs and their pages in a BottomNavigationView: one menu item per tab, in the configuration's order, and
 *      one Fragment per tab (shown / hidden, so each keeps its state). Fragments restored after a configuration change
 *      are reused by tag.
 * [CN] 在 BottomNavigationView 中显示各 Tab 及其页面：按配置的顺序每个 Tab 一个菜单项、一个 Fragment（显示 / 隐藏，保留各自状态）。
 *      配置变化后恢复的 Fragment 按 tag 复用。
 */
object TabBarBinder {
    /** [EN] SF Symbol names of the shared file -> Android drawables. [CN] 共用文件中的 SF Symbol 名称 -> Android 图标。 */
    private val icons = mapOf(
        "house" to android.R.drawable.ic_menu_myplaces,
        "message" to android.R.drawable.ic_dialog_email,
        "safari" to android.R.drawable.ic_menu_compass,
        "globe" to android.R.drawable.ic_menu_compass,
        "person" to android.R.drawable.ic_menu_my_calendar,
    )

    private fun icon(tab: TabItem): Int {
        val name = tab.image?.removePrefix("system:")?.substringBefore('.')
        return icons[name] ?: android.R.drawable.ic_menu_help
    }

    fun bind(
        navigation: BottomNavigationView,
        fragmentManager: FragmentManager,
        @IdRes container: Int,
        tag: String,
        pages: List<Pair<TabItem, Fragment>>,
    ) {
        navigation.menu.clear()
        val fragments = pages.mapIndexed { index, (tab, page) ->
            navigation.menu.add(Menu.NONE, index, index, tab.title ?: tab.pageId).setIcon(icon(tab))
            fragmentManager.findFragmentByTag("$tag-$index") ?: page
        }
        fragmentManager.beginTransaction().apply {
            fragments.forEachIndexed { index, fragment ->
                if (!fragment.isAdded) add(container, fragment, "$tag-$index")
                if (index == 0) show(fragment) else hide(fragment)
            }
        }.commitNow()
        navigation.setOnItemSelectedListener { item ->
            fragmentManager.beginTransaction().apply {
                fragments.forEachIndexed { index, fragment -> if (index == item.itemId) show(fragment) else hide(fragment) }
            }.commit()
            true
        }
    }
}
