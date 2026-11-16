// [EN] The method names use the library's `cyl_` prefix, see docs/Android-API-Map.md. [CN] 方法名使用库的 `cyl_` 前缀，见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.core.view.ViewCompat
import androidx.fragment.app.Fragment

/**
 * [EN] The page of the "More" tab (UIKit's `moreNavigationController` list): one row per tab past the ones in the bar, with
 *      its icon, title and badge. A row selects its tab as a tap on it would (the delegate's `shouldSelect`, login and custom
 *      actions apply); the bar then keeps "More" selected. Every row is one accessibility element ("Messages, 3 new
 *      messages"), the title is a heading. Made by `CYLTabBarController.cyl_moreViewController`.
 * [CN] 「更多」Tab 的页面（对应 UIKit `moreNavigationController` 的列表）：TabBar 中放不下的每个 Tab 一行，带图标、标题与角标。点击一行与点击该 Tab
 *      一样选中它（代理的 `shouldSelect`、登录与自定义动作都适用）；之后 TabBar 中保持「更多」为选中状态。每一行是一个无障碍元素（如“消息，3 条新消息”），
 *      标题为 heading。由 `CYLTabBarController.cyl_moreViewController` 创建。
 */
class CYLTabBarMoreListFragment : Fragment() {
    internal var cyl_tabBarController: CYLTabBarController? = null
    private var rows: LinearLayout? = null

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val content = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        rows = content
        cyl_reloadRows()
        return ScrollView(context).apply { addView(content, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)) }
    }

    override fun onDestroyView() {
        rows = null
        super.onDestroyView()
    }

    /**
     * [EN] The rows of the tabs under "More" now (titles, icons and badges as they are). [CN] 当前「更多」下各 Tab 的行（标题、图标与角标为当前状态）。
     */
    fun cyl_reloadRows() {
        val content = rows ?: return
        val controller = cyl_tabBarController ?: return
        val context = content.context
        val density = context.resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()
        content.removeAllViews()
        val title = TextView(context).apply {
            text = CYLLocalization.string(context, R.string.cyl_more)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
            setTypeface(typeface, android.graphics.Typeface.BOLD)
            setPadding(dp(16), dp(16), dp(16), dp(8))
        }
        ViewCompat.setAccessibilityHeading(title, true)
        content.addView(title)
        val bar = controller.tabBar
        for (index in bar.cyl_visibleTabCount until controller.viewControllers.size) {
            val button = bar.cyl_tabBarButtonWithTabIndex(index) ?: continue
            content.addView(row(button, controller, ::dp))
        }
    }

    private fun row(button: CYLTabBarItemButton, controller: CYLTabBarController, dp: (Int) -> Int): View {
        val context = button.context
        val item = button.item
        val badge = button.cyl_badgeState.badge?.takeIf { button.cyl_isShowBadge() }
        val selectable = TypedValue().also { context.theme.resolveAttribute(android.R.attr.selectableItemBackground, it, true) }
        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            minimumHeight = dp(56)
            setPadding(dp(16), 0, dp(16), 0)
            isClickable = true
            isFocusable = true
            if (selectable.resourceId != 0) setBackgroundResource(selectable.resourceId)
            addView(ImageView(context).apply {
                setImageDrawable(item.image?.constantState?.newDrawable()?.mutate() ?: item.image)
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            }, LinearLayout.LayoutParams(dp(28), dp(28)).apply { marginEnd = dp(16) })
            addView(TextView(context).apply {
                text = item.title ?: ""
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 17f)
                importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
            }, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
            badge?.text?.let { text ->
                addView(TextView(context).apply {
                    this.text = text
                    setTextColor(badge.badgeTextColor)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
                    setPadding(dp(8), dp(2), dp(8), dp(2))
                    background = android.graphics.drawable.GradientDrawable().apply { setColor(badge.badgeBackgroundColor); cornerRadius = dp(10).toFloat() }
                    importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
                })
            }
            contentDescription = listOfNotNull(item.accessibilityLabel ?: item.title, badge?.contentDescription).joinToString(", ")
            setOnClickListener { controller.cyl_tabButtonTapped(button) }
        }
    }
}
