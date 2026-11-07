package com.cyl.tabbar.example.pag

import android.content.Context
import android.graphics.Color
import android.view.View
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.cyl.tabbar.CYLPlusButton
import com.cyl.tabbar.CYLPlusButtonSubclassing

/**
 * [EN] Example-PAG's plus button (iOS `CYLPlusButtonSubclass`): the title "Menu" drawn on the tabbar_database background
 *      image, the third item, raised (multiplier 0.3), whose page is "Menu" (orange). Example-Rive shows the other layout,
 *      an image above a title aligned with the tab titles.
 * [CN] Example-PAG 的 PlusButton（iOS `CYLPlusButtonSubclass`）：标题 "菜单" 画在 tabbar_database 背景图上，位于第三项，向上凸出（倍数 0.3），
 *      其页面为 "菜单"（橙色）。Example-Rive 演示另一种布局：图片在上，标题与 Tab 标题对齐。
 */
object MenuPlusButton : CYLPlusButtonSubclassing {
    const val CONTEXT = "ExamplePAG"

    override fun plusButton(context: Context): CYLPlusButton = CYLPlusButton(context).apply {
        background = ContextCompat.getDrawable(context, R.drawable.tabbar_database)
        setTitle(context.getString(R.string.menu), context.getString(R.string.menu), Color.WHITE)
        titleLabel.setTextColor(Color.WHITE)
        titleLabel.textSize = 15f
        titleLabel.visibility = View.VISIBLE
        val density = resources.displayMetrics.density
        background?.let { minimumWidth = it.intrinsicWidth.coerceAtLeast((56 * density).toInt()); minimumHeight = it.intrinsicHeight.coerceAtLeast((56 * density).toInt()) }
    }

    override fun indexOfPlusButtonInTabBar() = 2
    override fun multiplierOfTabBarHeight(tabBarHeight: Float) = 0.3f
    override fun plusChildViewController(): Fragment = ColorPage.newInstance(R.string.menu, Color.rgb(255, 165, 0))
    override fun tabBarContext() = CONTEXT
}
