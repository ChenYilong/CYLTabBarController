package com.cyl.tabbar.demo

import android.graphics.Color
import android.os.Bundle
import android.widget.LinearLayout
import androidx.appcompat.app.AppCompatActivity
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.CYLTabBarPageRegistry

/**
 * [EN] Two `CYLTabBarController`s on one screen (the iOS demo C16): the same page IDs, each tab bar with its own
 *      `CYLTabBarPageRegistry`, so "home" and "me" give different pages.
 * [CN] 同一屏幕上的两个 `CYLTabBarController`（iOS 演示 C16）：相同的页面 ID，各自的 `CYLTabBarPageRegistry`，因此 "home" 与 "me"
 *      得到不同的页面。
 */
class TwoTabBarsActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val column = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        for ((name, color) in listOf("A" to Color.argb(64, 0, 122, 255), "B" to Color.argb(64, 255, 149, 0))) {
            val registry = CYLTabBarPageRegistry().apply {
                registerPageProvider({ id, _ -> TextPageFragment.newInstance("Tab bar $name · page ID \"$id\"", background = color) }, listOf("home", "me"))
            }
            val controller = CYLTabBarController(this, mapOf(
                CYLConstants.CYLTabBarControllerPageRegistry to registry,
                CYLConstants.CYLTabBarControllerContext to "two-tab-bars-$name",
                CYLConstants.CYLTabBarControllerTabBarItemsAttributes to listOf(
                    mapOf(CYLConstants.CYLTabBarItemTitle to "Home", CYLConstants.CYLTabBarItemImage to "system:house", CYLConstants.CYLTabBarItemIdentifier to "home"),
                    mapOf(CYLConstants.CYLTabBarItemTitle to "Me", CYLConstants.CYLTabBarItemImage to "system:person", CYLConstants.CYLTabBarItemIdentifier to "me"),
                ),
            ))
            column.addView(controller.view, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f))
        }
        setContentView(column)
    }
}
