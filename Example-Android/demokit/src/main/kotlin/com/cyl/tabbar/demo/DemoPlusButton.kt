package com.cyl.tabbar.demo

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.cyl.tabbar.CYLPlusButton
import com.cyl.tabbar.CYLPlusButtonSubclassing

/**
 * [EN] The demo's plus button, like the iOS demo's `CYLPlusButtonSubclass`: a round blue button raised above the bar
 *      in the middle of the tabs, with its own page.
 * [CN] 演示的 PlusButton，对应 iOS 演示的 `CYLPlusButtonSubclass`：Tab 中间、凸出 TabBar 的蓝色圆形按钮，带自己的页面。
 */
class DemoPlusButton(context: Context) : CYLPlusButton(context) {

    init {
        val density = resources.displayMetrics.density
        // [EN] The iOS demo's images (`post_normal`, `post_highlight` when selected), copied from the ObjC Example; a blue round plus without them. [CN] iOS 演示的图片（`post_normal`，选中时 `post_highlight`），复制自 ObjC Example；没有时为蓝色圆形加号。
        val normal = DemoAssets.drawable(context, "post_normal")
        if (normal != null) {
            setImageDrawable(android.graphics.drawable.StateListDrawable().apply {
                DemoAssets.drawable(context, "post_highlight")?.let { addState(intArrayOf(android.R.attr.state_selected), it) }
                addState(intArrayOf(), normal)
            })
        } else {
            background = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.rgb(0, 122, 255))
            }
            setImageDrawable(ContextCompat.getDrawable(context, android.R.drawable.ic_input_add))
            imageView.setColorFilter(Color.WHITE)
        }
        minimumWidth = (56 * density).toInt()
        minimumHeight = (56 * density).toInt()
        touchableAreaScale = 1.2f
    }

    object Provider : CYLPlusButtonSubclassing {
        private const val CENTER_FROM_TOP_DP = 0.3f * 49f
        private val page: Fragment by lazy { TextPageFragment.newInstance("PlusButton\nplusChildViewController") }
        override fun plusButton(context: Context) = DemoPlusButton(context)
        /**
         * [EN] A raised plus button (AGENTS.md): its center stays 14.7 dp below the bar's top (0.3 of the iOS 49), so it
         *      rises above the bar at any height; the default height became the system tab bar's (80 dp with Material 3)
         *      on 2026-11-22, where 0.3 of the height left it level with the bar's top.
         * [CN] 凸起的 PlusButton（AGENTS.md）：其中心始终位于 TabBar 顶部下方 14.7 dp（iOS 49 的 0.3），任何高度下都高出 TabBar；2026-11-22 默认高度改为
         *      系统 TabBar 的高度（Material 3 为 80 dp），按高度的 0.3 计算时会与 TabBar 顶部齐平。
         */
        override fun multiplierOfTabBarHeight(tabBarHeight: Float) = if (tabBarHeight > 0) CENTER_FROM_TOP_DP / tabBarHeight else 0.3f
        override fun plusChildViewController(): Fragment = page
        override fun tabBarContext() = "CYLConfigurationDemo"
    }
}
