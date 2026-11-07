package com.cyl.tabbar.demo

import android.app.AlertDialog
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.Menu
import android.view.MenuItem
import android.view.View
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLPlusButton
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.CYLTabBarItemButton
import com.cyl.tabbar.cyl_showBadgeValue

/**
 * [EN] The tab bar style of a demo, chosen from the action bar (iOS `CYLDemoTabBarStyle`): FlatDesign or the default
 *      style, so the same animated tabs can be compared. Kept in the app's preferences; `rebuild` creates the tab bar again.
 * [CN] 演示的 TabBar 样式，通过 ActionBar 选择（iOS `CYLDemoTabBarStyle`）：扁平样式或默认样式，便于比较同样的动画 Tab。保存在 App 的偏好设置中；
 *      `rebuild` 重新创建 TabBar。
 */
object DemoTabBarStyle {
    private const val KEY = "CYLDemoTabBarFlatDesign"
    private const val MENU_ID = 0x5717

    fun isFlatDesign(context: Context) = context.getSharedPreferences(KEY, Context.MODE_PRIVATE).getBoolean(KEY, false)

    fun styleType(context: Context) = if (isFlatDesign(context)) CYLEnums.CYLTabBarStyleType.FlatDesign else CYLEnums.CYLTabBarStyleType.Default

    /** [EN] Adds the switch to the action bar: its title is the style it switches to. [CN] 在 ActionBar 中添加切换按钮：标题为将切换到的样式。 */
    fun addMenuItem(context: Context, menu: Menu) {
        menu.add(Menu.NONE, MENU_ID, Menu.NONE, if (isFlatDesign(context)) "Default" else "Flat Design").setShowAsAction(MenuItem.SHOW_AS_ACTION_IF_ROOM)
    }

    /** [EN] Handles the switch; true when `item` was it. [CN] 处理切换；`item` 是该按钮时返回 true。 */
    fun onMenuItemSelected(context: Context, item: MenuItem, rebuild: () -> Unit): Boolean {
        if (item.itemId != MENU_ID) return false
        context.getSharedPreferences(KEY, Context.MODE_PRIVATE).edit().putBoolean(KEY, !isFlatDesign(context)).apply()
        rebuild()
        return true
    }
}

/**
 * [EN] The plus button badge and interactions shared by the demos (iOS `Example-Shared/CYLPlusButtonBadgeDemo.swift`,
 *      #535): a bounce tap animation, a long press that names the pressed tab, swiping to switch tabs, and a bouncing
 *      badge on the plus button: 1 after launch, +1 on each tap.
 * [CN] 各演示共用的 PlusButton 角标与交互（iOS `Example-Shared/CYLPlusButtonBadgeDemo.swift`，#535）：弹性点击动画、长按显示被按的 Tab、
 *      左右滑动切换 Tab，以及 PlusButton 上带弹跳动画的角标：启动后为 1，每次点击加 1。
 */
object DemoPlusButtonBadge {
    private val counts = java.util.WeakHashMap<CYLTabBarController, Int>()

    /** [EN] `-demoShowPlusButtonBadgeAfterLayout`: turns on the interactions and shows 1 after 1.5 s. [CN] 开启交互，1.5 秒后显示 1。 */
    fun showAfterLayout(controller: CYLTabBarController) {
        setUpInteractions(controller)
        Handler(Looper.getMainLooper()).postDelayed({ update(controller, addingOne = false) }, 1500)
    }

    /** [EN] `-demoPlusButtonDidTap:`: +1 when `control` is the plus button. [CN] `control` 是 PlusButton 时加 1。 */
    fun didSelectControl(controller: CYLTabBarController, control: View) {
        if (control is CYLPlusButton) update(controller, addingOne = true)
    }

    private fun update(controller: CYLTabBarController, addingOne: Boolean) {
        val plusButton = controller.tabBar.plusButton ?: return
        val count = counts[controller] ?: 0
        if (!addingOne && count > 0) return
        counts[controller] = count + 1
        plusButton.cyl_showBadgeValue((count + 1).toString(), CYLEnums.CYLBadgeAnimationType.Bounce)
    }

    private fun setUpInteractions(controller: CYLTabBarController) {
        controller.cyl_tabButtonTapAnimationType = CYLEnums.CYLTabButtonTapAnimationType.Bounce
        controller.cyl_swipeToSwitchTabEnabled = true
        controller.cyl_didLongPressControlBlock = { tabBarController, control ->
            val name = (control as? CYLTabBarItemButton)?.item?.title ?: (control as? CYLPlusButton)?.titleLabel?.text ?: "PlusButton"
            AlertDialog.Builder(tabBarController.activity).setTitle("Long pressed \"$name\"").setNegativeButton(android.R.string.cancel, null).show()
        }
    }
}

/**
 * [EN] The plus button of the demos that have none (iOS `Example-Shared` `DemoPlusButton`, #535): a round plus image with
 *      the title "Publish", no page: a tap only changes its badge.
 * [CN] 原本没有 PlusButton 的演示所用的 PlusButton（iOS `Example-Shared` 的 `DemoPlusButton`，#535）：圆形加号图片，标题为 "发布"，没有页面：
 *      点击只改变角标。
 */
object DemoPublishPlusButton : com.cyl.tabbar.CYLPlusButtonSubclassing {
    const val CONTEXT = "DemoPublishPlusButton"

    override fun plusButton(context: Context): CYLPlusButton = CYLPlusButton(context).apply {
        val density = resources.displayMetrics.density
        setImageDrawable(android.graphics.drawable.LayerDrawable(arrayOf(
            android.graphics.drawable.GradientDrawable().apply { shape = android.graphics.drawable.GradientDrawable.OVAL; setColor(android.graphics.Color.rgb(0, 122, 255)) },
            androidx.core.content.ContextCompat.getDrawable(context, android.R.drawable.ic_input_add)?.mutate()?.apply { setTint(android.graphics.Color.WHITE) },
        )).apply { setLayerInset(1, (6 * density).toInt(), (6 * density).toInt(), (6 * density).toInt(), (6 * density).toInt()) })
        setTitle(context.getString(com.cyl.tabbar.demokit.R.string.publish))
        minimumWidth = (36 * density).toInt()
        minimumHeight = (36 * density).toInt()
    }

    override fun tabBarContext() = CONTEXT
}
