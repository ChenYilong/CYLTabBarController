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
        background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.rgb(0, 122, 255))
        }
        setImageDrawable(ContextCompat.getDrawable(context, android.R.drawable.ic_input_add))
        setColorFilter(Color.WHITE)
        minimumWidth = (56 * density).toInt()
        minimumHeight = (56 * density).toInt()
        touchableAreaScale = 1.2f
    }

    object Provider : CYLPlusButtonSubclassing {
        private val page: Fragment by lazy { TextPageFragment.newInstance("PlusButton\nplusChildViewController") }
        override fun plusButton(context: Context) = DemoPlusButton(context)
        override fun multiplierOfTabBarHeight(tabBarHeight: Float) = 0.3f
        override fun plusChildViewController(): Fragment = page
        override fun tabBarContext() = "CYLConfigurationDemo"
    }
}
