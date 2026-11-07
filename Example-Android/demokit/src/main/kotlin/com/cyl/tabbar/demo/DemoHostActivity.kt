package com.cyl.tabbar.demo

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import com.cyl.tabbar.CYLTabBarController

/**
 * [EN] Shows what a demo row pushes on iOS (`pushViewController:` of a tab bar controller, a gallery scene, a system tab
 *      bar for comparison): the row gives a builder, this activity shows its view. Back pops the selected page's pushed
 *      pages first (`cyl_pushViewController`), then closes.
 * [CN] 显示 iOS 演示行 push 的内容（push 一个 TabBarController、一个展示场景、用于对比的系统 TabBar）：行提供构建方法，本 Activity 显示其视图。
 *      返回键先弹出选中页面上 push 的页面（`cyl_pushViewController`），再关闭。
 */
class DemoHostActivity : AppCompatActivity() {

    /** [EN] The tab bar controller the builder made, if any. [CN] 构建方法创建的 TabBarController（如有）。 */
    var tabBarController: CYLTabBarController? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val key = intent.getStringExtra(KEY)
        val builder = key?.let { synchronized(builders) { builders[it] } }
        if (builder == null) {
            // [EN] The process was recreated and the builder is gone: nothing to show. [CN] 进程被重建，构建方法已不在：没有可显示的内容。
            finish()
            return
        }
        current = java.lang.ref.WeakReference(this)
        title = intent.getStringExtra(TITLE)
        setContentView(builder(this))
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                val page = tabBarController?.selectedViewController
                if (page != null && page.isAdded && page.childFragmentManager.backStackEntryCount > 0) {
                    page.childFragmentManager.popBackStack()
                } else {
                    finish()
                }
            }
        })
    }

    companion object {
        private const val KEY = "key"
        private const val TITLE = "title"
        private val builders = HashMap<String, (DemoHostActivity) -> View>()
        /** [EN] The last screen opened, for the simulations that close it. [CN] 最近打开的界面，供需要关闭它的模拟使用。 */
        var current: java.lang.ref.WeakReference<DemoHostActivity>? = null

        /** [EN] Opens a screen whose view `builder` makes. [CN] 打开一个由 `builder` 创建视图的界面。 */
        fun open(context: Context, title: String, builder: (DemoHostActivity) -> View) {
            val key = title + "#" + System.nanoTime()
            synchronized(builders) { builders[key] = builder }
            context.startActivity(Intent(context, DemoHostActivity::class.java).putExtra(KEY, key).putExtra(TITLE, title))
        }

        /** [EN] Opens a screen with a tab bar controller made by `builder`. [CN] 打开一个显示由 `builder` 创建的 TabBarController 的界面。 */
        fun openTabBar(context: Context, title: String, builder: (DemoHostActivity) -> CYLTabBarController) =
            open(context, title) { activity -> builder(activity).also { activity.tabBarController = it }.view }
    }
}
