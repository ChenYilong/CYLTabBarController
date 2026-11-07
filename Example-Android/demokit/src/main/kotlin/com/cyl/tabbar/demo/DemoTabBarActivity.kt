package com.cyl.tabbar.demo

import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import android.view.View
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.CYLTabBarControllerDelegate

/**
 * [EN] The activity of the PAG, GIF and Rive examples (the iOS demos' `SceneDelegate` + tab bar controller subclass): it
 *      creates the tab bar controller with the chosen style (`DemoTabBarStyle`, the action bar switch), shows the plus
 *      button badge and interactions (`DemoPlusButtonBadge`), and pops a tab's pushed pages on Back.
 * [CN] PAG、GIF、Rive 示例的 Activity（对应 iOS 演示的 `SceneDelegate` + TabBarController 子类）：以选择的样式创建 TabBarController
 *      （`DemoTabBarStyle`，ActionBar 上的切换按钮），显示 PlusButton 角标与交互（`DemoPlusButtonBadge`），返回键弹出 Tab 上 push 的页面。
 */
abstract class DemoTabBarActivity : AppCompatActivity() {

    /** [EN] The tab bar controller on screen. [CN] 当前显示的 TabBarController。 */
    var tabBarController: CYLTabBarController? = null
        private set

    /** [EN] Makes the tab bar controller in `style` (register the plus button first). [CN] 以 `style` 样式创建 TabBarController（先注册 PlusButton）。 */
    abstract fun makeTabBarController(style: CYLEnums.CYLTabBarStyleType): CYLTabBarController

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DemoPages.registerOnce()
        // [EN] Image names come from the iOS example's asset catalog first. [CN] 图片名称先在 iOS 示例的资源目录中查找。
        DemoAssets.install()
        DemoTheme.registerOnce()
        showTabBarController()
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                val page = tabBarController?.selectedViewController
                if (page != null && page.isAdded && page.childFragmentManager.backStackEntryCount > 0) page.childFragmentManager.popBackStack() else finish()
            }
        })
    }

    /** [EN] Creates the tab bar controller again (iOS `rebuildRootViewController`), e.g. after the style changes. [CN] 重新创建 TabBarController（iOS `rebuildRootViewController`），例如样式改变之后。 */
    fun showTabBarController() {
        tabBarController?.let { old -> supportFragmentManager.beginTransaction().apply { old.viewControllers.forEach { if (it.isAdded) remove(it) } }.commitNowAllowingStateLoss() }
        val controller = makeTabBarController(DemoTabBarStyle.styleType(this))
        if (controller.delegate == null) controller.delegate = PlusBadgeDelegate
        tabBarController = controller
        setContentView(controller.view)
        DemoPlusButtonBadge.showAfterLayout(controller)
    }

    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        DemoTabBarStyle.addMenuItem(this, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean =
        DemoTabBarStyle.onMenuItemSelected(this, item) { invalidateOptionsMenu(); showTabBarController() } || super.onOptionsItemSelected(item)

    /** [EN] `-tabBarController:didSelectControl:` → the plus button badge goes up. [CN] 点击 PlusButton 时角标加 1。 */
    object PlusBadgeDelegate : CYLTabBarControllerDelegate {
        override fun tabBarController_didSelectControl(tabBarController: CYLTabBarController, control: View) =
            DemoPlusButtonBadge.didSelectControl(tabBarController, control)
    }
}
