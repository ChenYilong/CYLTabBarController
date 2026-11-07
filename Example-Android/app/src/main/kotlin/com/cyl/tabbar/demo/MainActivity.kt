package com.cyl.tabbar.demo

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLPlusButton
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.cyl_showBadgeValue

/**
 * [EN] The iOS library's own sample file (shared as an asset) creates a `CYLTabBarController`: the tabs for Android and
 *      this app version, each page found by its page ID (`DemoPages`), a plus button (`DemoPlusButton`), a badge, the
 *      tap animation and the double tap.
 * [CN] iOS 库自带的示例文件（作为 asset 共用）创建 `CYLTabBarController`：适用于 Android 与本 App 版本的 Tab、按页面 ID 找到的页面
 *      （`DemoPages`）、PlusButton（`DemoPlusButton`）、角标、点击动画与双击。
 */
class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DemoPages.registerOnce()
        CYLPlusButton.registerPlusButton(DemoPlusButton.Provider)
        val controller = CYLTabBarController.tabBarControllerWithConfigurationFile(this, "cyl_tabbar_configuration.json")
        controller.cyl_tabButtonTapAnimationType = CYLEnums.CYLTabButtonTapAnimationType.Scale
        controller.cyl_hidesBadgeOfSelectedTab = true
        controller.cyl_tabBarItemGestureHandler = { tabBarController, gesture, _, page ->
            if (gesture == CYLEnums.CYLTabBarItemGesture.DoubleTap) {
                val index = page?.let { tabBarController.viewControllers.indexOf(it) } ?: -1
                tabBarController.updateTabBarItemAtIndex(index, mapOf(CYLConstants.CYLTabBarItemTitle to getString(R.string.double_tapped)))
            }
        }
        setContentView(controller.view)
        controller.tabBar.tabBarButtonArray.getOrNull(1)?.cyl_showBadgeValue("12")
        controller.tabBar.tabBarButtonArray.getOrNull(3)?.cyl_showBadgeValue("")
    }
}
