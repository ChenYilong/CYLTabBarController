package com.cyl.tabbar.example.gif

import android.graphics.Color
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLPlusButton
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.demo.DemoCatalog
import com.cyl.tabbar.demo.DemoListFragment
import com.cyl.tabbar.demo.DemoPublishPlusButton
import com.cyl.tabbar.demo.DemoTabBarActivity
import com.cyl.tabbar.demo.TextPageFragment

/**
 * [EN] The Android port of Example-GIF (issue #605): how a GIF plays depends on the key that gives it.
 *      - Tab 1, a GIF key (`CYLTabBarGIFFilePath`): the first frame, then once when selected, staying on the last frame.
 *      - Tab 2, the generic key (`CYLTabBarAnimationFilePath`, the ".gif" extension picks GIF): the same.
 *      - Tab 3, an image entry (`CYLTabBarItemImageURL`): no animation key, so the GIF keeps looping, selected or not.
 *      The first tab is the settings list (iOS `CYLSettingsDemoTableViewController`); the plus button only changes its badge.
 * [CN] Example-GIF 的 Android 版（issue #605）：GIF 如何播放取决于传入它的 key。
 *      - 第 1 个 Tab，GIF key（`CYLTabBarGIFFilePath`）：显示第一帧，选中时播放一次，然后停在最后一帧。
 *      - 第 2 个 Tab，通用 key（`CYLTabBarAnimationFilePath`，".gif" 扩展名选择 GIF）：同上。
 *      - 第 3 个 Tab，图片入口（`CYLTabBarItemImageURL`）：没有动画 key，因此 GIF 一直循环，无论是否选中。
 *      第一个 Tab 是设置列表（iOS `CYLSettingsDemoTableViewController`）；PlusButton 只改变角标。
 */
class MainActivity : DemoTabBarActivity() {

    override fun makeTabBarController(style: CYLEnums.CYLTabBarStyleType): CYLTabBarController {
        CYLPlusButton.registerPlusButton(DemoPublishPlusButton)
        val size = "{30, 30}"
        val titles = listOf(R.string.tab_home, R.string.tab_city, R.string.tab_message, R.string.tab_me).map(::getString)
        val images = listOf("home_normal", "mycity_normal", "message_normal", "account_normal")
        val items = titles.indices.map { index ->
            mutableMapOf<String, Any?>(
                CYLConstants.CYLTabBarItemTitle to titles[index],
                CYLConstants.CYLTabBarItemImage to images[index],
                CYLConstants.CYLTabBarItemSelectedImage to images[index].replace("_normal", "_highlight"),
            )
        }
        items[0][CYLConstants.CYLTabBarGIFFilePath] = "tab_rocket.gif"
        items[0][CYLConstants.CYLTabBarGIFSize] = size
        items[1][CYLConstants.CYLTabBarAnimationFilePath] = "tab_star.gif"
        items[1][CYLConstants.CYLTabBarAnimationSize] = size
        items[2][CYLConstants.CYLTabBarItemImageURL] = "tab_fire.gif"
        items[2][CYLConstants.CYLTabBarItemImageURLSize] = size
        val pages = listOf(
            DemoListFragment.newInstance(DemoCatalog.SETTINGS),
            TextPageFragment.newInstance(titles[1], background = Color.BLUE),
            TextPageFragment.newInstance(titles[2], background = Color.GRAY),
            TextPageFragment.newInstance(titles[3], background = Color.GREEN),
        )
        return CYLTabBarController(this, pages, items, style, DemoPublishPlusButton.CONTEXT).apply {
            // [EN] Issue #428: tab icon animations at 1.5x. [CN] Issue #428：Tab 图标动画 1.5 倍速。
            tabBarItemAnimationSpeed = 1.5f
            setTintColor(Color.rgb(255, 102, 0))
        }
    }
}
