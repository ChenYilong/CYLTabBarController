package com.cyl.tabbar.demo

import android.graphics.Color
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.cyl.tabbar.pages.TabItem
import com.cyl.tabbar.pages.TabPageRegistry
import com.cyl.tabbar.pages.TabPages
import com.google.android.material.bottomnavigation.BottomNavigationView

/**
 * [EN] Two tab bars on one screen from the same tabs: each has its own registry, so the same page IDs ("home", "me")
 *      give different pages (blue and orange), like the iOS demo C16.
 * [CN] 同一屏幕上的两个 TabBar，使用同样的 Tab：各自有自己的注册表，因此相同的页面 ID（"home"、"me"）得到不同的页面（蓝色与橙色），
 *      与 iOS 演示 C16 相同。
 */
class TwoTabBarsActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_two_tab_bars)
        val tabs = listOf(
            TabItem(mapOf("CYLTabBarItemTitle" to "Home", "CYLTabBarItemImage" to "system:house", "CYLTabBarItemIdentifier" to "home")),
            TabItem(mapOf("CYLTabBarItemTitle" to "Me", "CYLTabBarItemImage" to "system:person", "CYLTabBarItemIdentifier" to "me")),
        )
        bind("A", Color.argb(64, 0, 122, 255), R.id.tabsA, R.id.pagesA, tabs)
        bind("B", Color.argb(64, 255, 149, 0), R.id.tabsB, R.id.pagesB, tabs)
    }

    private fun bind(name: String, color: Int, navigation: Int, container: Int, tabs: List<TabItem>) {
        val registry = TabPageRegistry<Fragment>().apply {
            register("home", "me") { id, _ -> TextPageFragment.newInstance("Tab bar $name · page ID \"$id\"", background = color) }
        }
        val pages = TabPages.resolve(tabs, Fragment::class.java, registry = registry)
        TabBarBinder.bind(findViewById<BottomNavigationView>(navigation), supportFragmentManager, container, "tabBar$name", pages)
    }
}
