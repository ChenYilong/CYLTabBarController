package com.cyl.tabbar.demo

import android.app.Dialog
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.SeekBar
import android.widget.TextView
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLTabBarController

/**
 * [EN] The Liquid Glass surface tint row: a slider panel at the top of the screen, without dimming the window, so the dock
 *      stays in sight and changes as the slider moves (`CYLTabBar.cyl_liquidGlassSurfaceOpacity`, 0 to 1). The bar switches
 *      to Liquid Glass first if it shows another style.
 * [CN] 液态玻璃表面着色行：屏幕顶部的滑块面板，不调暗窗口，因此胶囊始终可见，并随滑块实时变化（`CYLTabBar.cyl_liquidGlassSurfaceOpacity`，0 到 1）。
 *      TabBar 当前不是液态玻璃时先切换为液态玻璃。
 */
object DemoLiquidGlassSurface {
    private const val STEPS = 100

    fun showSlider(context: Context, controller: CYLTabBarController, onDismiss: () -> Unit) {
        if (controller.tabBarStyleType != CYLEnums.CYLTabBarStyleType.LiquidGlass) controller.tabBarStyleType = CYLEnums.CYLTabBarStyleType.LiquidGlass
        val bar = controller.tabBar
        val density = context.resources.displayMetrics.density
        val padding = (20 * density).toInt()
        val label = TextView(context).apply { textSize = 15f }
        fun update() { label.text = "Surface opacity: ${"%.2f".format(bar.cyl_liquidGlassSurfaceOpacity)} (default 0.40)" }
        update()
        val slider = SeekBar(context).apply {
            max = STEPS
            progress = (bar.cyl_liquidGlassSurfaceOpacity * STEPS).toInt()
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
                    bar.cyl_liquidGlassSurfaceOpacity = progress / STEPS.toFloat()
                    update()
                }
                override fun onStartTrackingTouch(seekBar: SeekBar) { /* [EN] Only the value matters. [CN] 只关心数值。 */ }
                override fun onStopTrackingTouch(seekBar: SeekBar) { /* [EN] Only the value matters. [CN] 只关心数值。 */ }
            })
        }
        val reset = TextView(context).apply {
            text = "Reset to 0.40"
            setTextColor(Color.rgb(0, 122, 255))
            setPadding(0, padding / 2, 0, 0)
            setOnClickListener { slider.progress = (0.4f * STEPS).toInt() }
        }
        val panel = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(padding, padding, padding, padding)
            background = GradientDrawable().apply { cornerRadius = 16 * density; setColor(Color.WHITE) }
            addView(label)
            addView(slider)
            addView(reset)
        }
        Dialog(context).apply {
            setContentView(panel)
            window?.let { window ->
                window.setBackgroundDrawableResource(android.R.color.transparent)
                // [EN] No dimming, at the top: the dock at the bottom stays visible while the slider moves. [CN] 不调暗、位于顶部：拖动滑块时底部的胶囊始终可见。
                window.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
                window.setGravity(Gravity.TOP)
                window.setLayout((context.resources.displayMetrics.widthPixels * 0.9f).toInt(), WindowManager.LayoutParams.WRAP_CONTENT)
            }
            setOnDismissListener { onDismiss() }
            show()
        }
    }
}
