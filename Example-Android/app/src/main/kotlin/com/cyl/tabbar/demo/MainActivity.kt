package com.cyl.tabbar.demo

import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLPlusButton
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.CYLTabBarIndicator
import com.cyl.tabbar.CYLTabBarScrollMode
import com.cyl.tabbar.cyl_navigationTitleFollowsTabBarItemTitle
import com.cyl.tabbar.cyl_showBadgeValue

/**
 * [EN] The iOS library's own sample file (shared as an asset) creates a `CYLTabBarController`: the tabs for Android and
 *      this app version, each page found by its page ID (`DemoPages`), a plus button (`DemoPlusButton`), a badge, the
 *      tap animation and the double tap. The four tabs are the demo lists of the iOS Example (`DemoListFragment`), and
 *      the action bar has its buttons: FlatDesign, Liquid Glass and the skins.
 * [CN] iOS 库自带的示例文件（作为 asset 共用）创建 `CYLTabBarController`：适用于 Android 与本 App 版本的 Tab、按页面 ID 找到的页面
 *      （`DemoPages`）、PlusButton（`DemoPlusButton`）、角标、点击动画与双击。四个 Tab 是 iOS Example 的演示列表（`DemoListFragment`），
 *      ActionBar 上有对应的按钮：扁平样式、液态玻璃与皮肤。
 */
class MainActivity : AppCompatActivity() {

    private var controller: CYLTabBarController? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DemoPages.registerOnce()
        // [EN] Image names come from the iOS example's asset catalog first. [CN] 图片名称先在 iOS 示例的资源目录中查找。
        DemoAssets.install()
        DemoTheme.registerOnce()
        CYLPlusButton.registerPlusButton(DemoPlusButton.Provider)
        showTabBar(CYLEnums.CYLTabBarStyleType.Default)
        // [EN] Back pops the pages pushed on the selected tab first (`cyl_pushViewController`). [CN] 返回键先弹出选中 Tab 上 push 的页面（`cyl_pushViewController`）。
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                val page = controller?.selectedViewController
                if (page != null && page.isAdded && page.childFragmentManager.backStackEntryCount > 0) page.childFragmentManager.popBackStack() else finish()
            }
        })
    }

    /** [EN] Creates the tab bar controller from the shared file, in `style` (the iOS "FlatDesign" / "LiquidGlass" buttons). [CN] 由共用文件以 `style` 样式创建 TabBarController（对应 iOS 的 "FlatDesign" / "LiquidGlass" 按钮）。 */
    private fun showTabBar(style: CYLEnums.CYLTabBarStyleType) {
        controller?.let { old -> supportFragmentManager.beginTransaction().apply { old.viewControllers.forEach { if (it.isAdded) remove(it) } }.commitNowAllowingStateLoss() }
        val controller = CYLTabBarController.tabBarControllerWithConfigurationFile(this, "cyl_tabbar_configuration.json")
        controller.tabBarStyleType = style
        controller.cyl_tabButtonTapAnimationType = CYLEnums.CYLTabButtonTapAnimationType.Scale
        controller.cyl_hidesBadgeOfSelectedTab = true
        controller.cyl_tabBarItemGestureHandler = { tabBarController, gesture, _, page ->
            if (gesture == CYLEnums.CYLTabBarItemGesture.DoubleTap) {
                val index = page?.let { tabBarController.viewControllers.indexOf(it) } ?: -1
                tabBarController.updateTabBarItemAtIndex(index, mapOf(CYLConstants.CYLTabBarItemTitle to getString(R.string.double_tapped)))
            }
        }
        this.controller = controller
        setContentView(controller.view)
        // [EN] As in the iOS example: the action bar shows the selected page's tab title, also after it changes in place
        //      ("Change every title", skins, the plus button's title). The plus button's page follows the plus button's title.
        // [CN] 与 iOS 示例相同：ActionBar 显示选中页面的 Tab 标题，原地修改后（「Change every title」、皮肤、PlusButton 的标题）也会同步。
        //      PlusButton 的页面跟随 PlusButton 的标题。
        controller.viewControllers.forEach { it.cyl_navigationTitleFollowsTabBarItemTitle = true }
        DemoPlusButton.Provider.plusChildViewController().cyl_navigationTitleFollowsTabBarItemTitle = true
        controller.tabBar.tabBarButtonArray.getOrNull(1)?.cyl_showBadgeValue("12")
        controller.tabBar.tabBarButtonArray.getOrNull(3)?.cyl_showBadgeValue("")
        applyAndroidExtras(controller)
    }

    private var androidExtras = false

    /**
     * [EN] The Android-only extras adapted from QMUI_Android: a selection indicator, swiping between the pages, and the
     *      scrollable mode (it scrolls once the tabs are wider than the bar). Off by default, as on iOS.
     * [CN] 改编自 QMUI_Android 的仅 Android 功能：选中指示条、滑动翻页与可滚动模式（Tab 总宽超过 TabBar 时可滚动）。默认关闭，与 iOS 一致。
     */
    private fun applyAndroidExtras(controller: CYLTabBarController) {
        controller.tabBar.cyl_indicator = if (androidExtras) CYLTabBarIndicator(height = 3f, top = true, cornerRadius = 1.5f) else null
        controller.cyl_swipesBetweenPages = androidExtras
        controller.tabBar.cyl_scrollMode = if (androidExtras) CYLTabBarScrollMode.Scrollable else CYLTabBarScrollMode.Fixed
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        menu.add(Menu.NONE, MENU_FLAT, Menu.NONE, "FlatDesign")
        menu.add(Menu.NONE, MENU_GLASS, Menu.NONE, "LiquidGlass")
        menu.add(Menu.NONE, MENU_EXTRAS, Menu.NONE, R.string.android_extras).isCheckable = true
        DemoTheme.all.forEachIndexed { index, theme -> menu.add(MENU_SKINS, MENU_SKIN + index, index, getString(R.string.skin_prefix) + theme.name) }
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        when {
            item.itemId == MENU_FLAT -> showTabBar(CYLEnums.CYLTabBarStyleType.FlatDesign)
            item.itemId == MENU_GLASS -> showTabBar(CYLEnums.CYLTabBarStyleType.LiquidGlass)
            item.itemId == MENU_EXTRAS -> {
                androidExtras = !androidExtras
                item.isChecked = androidExtras
                controller?.let { applyAndroidExtras(it) }
            }
            item.itemId >= MENU_SKIN -> DemoTheme.apply(DemoTheme.all[item.itemId - MENU_SKIN].name)
            else -> return super.onOptionsItemSelected(item)
        }
        return true
    }

    private companion object {
        const val MENU_FLAT = 1
        const val MENU_GLASS = 2
        const val MENU_SKINS = 3
        const val MENU_EXTRAS = 4
        const val MENU_SKIN = 100
    }
}
