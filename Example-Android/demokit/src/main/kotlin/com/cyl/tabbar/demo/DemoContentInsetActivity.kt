package com.cyl.tabbar.demo

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.cyl.animateditem.CYLAnimatedItemBackgroundStyle
import com.cyl.animateditem.CYLAnimatedItemView
import com.cyl.animateditem.CYLSize

/**
 * [EN] `itemContentHorizontalInset` left unset (docs/Animated-Item.md): the space between an item's content and the edge of its
 *      background. Unset it is the library's default for the style: a glass item gets the glass content inset, a flat item none. Four items,
 *      flat and Liquid Glass, normal and selected, each with an icon and a title, on a colorful backdrop so the glass shows.
 * [CN] 未设置 `itemContentHorizontalInset`（docs/Animated-Item.md）：条目内容与其背景边缘的间距。未设置时为该样式的库默认值：玻璃条目使用玻璃内容
 *      间距，扁平条目没有。四个条目：扁平与液态玻璃，常态与选中，各带图标与标题，放在彩色背景上以显示玻璃效果。
 */
class DemoContentInsetActivity : AppCompatActivity() {

    private fun dp(value: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics).toInt()

    private fun caption(text: String) = TextView(this).apply {
        this.text = text
        setTextColor(Color.parseColor("#3C3C43"))
        setPadding(dp(16f), dp(24f), dp(16f), dp(8f))
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
    }

    /** [EN] An item with the inset unset (null, the default). [CN] 间距未设置（null，默认值）的条目。 */
    private fun item(label: String, style: CYLAnimatedItemBackgroundStyle, selected: Boolean) = CYLAnimatedItemView(this).apply {
        title = label
        iconSizeDp = CYLSize(24f, 24f)
        image = androidx.core.content.ContextCompat.getDrawable(context, android.R.drawable.ic_menu_gallery)
        itemBackgroundStyle = style
        if (style == CYLAnimatedItemBackgroundStyle.Flat) itemBackgroundColor = Color.parseColor("#E5E5EA")
        itemCornerRadius = 22f
        itemContentHorizontalInset = null
        isSelected = selected
        contentDescription = label
    }

    private fun row(vararg items: CYLAnimatedItemView) = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
        items.forEach { view ->
            addView(view, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = dp(8f)
                marginEnd = dp(8f)
            })
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DemoText.attach(this)
        title = cylDemoText("Content inset")
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            background = GradientDrawable(GradientDrawable.Orientation.TL_BR, intArrayOf(Color.parseColor("#FFB199"), Color.parseColor("#7EC8E3"), Color.parseColor("#C3AED6")))
        }
        column.addView(caption(cylDemoText("Flat: itemContentHorizontalInset unset")))
        column.addView(row(item(cylDemoText("Normal"), CYLAnimatedItemBackgroundStyle.Flat, false), item(cylDemoText("Selected"), CYLAnimatedItemBackgroundStyle.Flat, true)))
        column.addView(caption(cylDemoText("Liquid Glass: itemContentHorizontalInset unset")))
        column.addView(row(item(cylDemoText("Normal"), CYLAnimatedItemBackgroundStyle.LiquidGlass, false), item(cylDemoText("Selected"), CYLAnimatedItemBackgroundStyle.LiquidGlass, true)))
        setContentView(column)
    }
}
