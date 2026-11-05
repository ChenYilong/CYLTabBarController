package com.cyl.tabbar.demo

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import com.cyl.tabbar.pages.TabConfiguration
import com.cyl.tabbar.pages.TabPages
import com.google.android.material.bottomnavigation.BottomNavigationView

/**
 * [EN] Reads cyl_tabbar_configuration.json, the iOS library's own sample file (shared as an asset), keeps the tabs
 *      for Android and this app version, finds each page by its page ID and shows them in a bottom navigation bar.
 * [CN] 读取 iOS 库自带的示例文件 cyl_tabbar_configuration.json（作为 asset 共用），保留适用于 Android 与本 App 版本的 Tab，
 *      按页面 ID 找到各页面，并显示在底部导航栏中。
 */
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        DemoPages.registerOnce()
        val json = assets.open("cyl_tabbar_configuration.json").bufferedReader().use { it.readText() }
        val appVersion = packageManager.getPackageInfo(packageName, 0).versionName
        val tabs = TabConfiguration.tabs(json, platform = "android", appVersion = appVersion)
        val pages = TabPages.resolve(tabs, Fragment::class.java, shared = DemoPages.shared)
        TabBarBinder.bind(findViewById<BottomNavigationView>(R.id.tabs), supportFragmentManager, R.id.pages, "main", pages)
    }
}
