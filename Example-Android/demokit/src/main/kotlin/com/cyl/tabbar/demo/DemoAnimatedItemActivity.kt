package com.cyl.tabbar.demo

import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import com.cyl.animateditem.CYLAnimatedItemAxis
import com.cyl.animateditem.CYLAnimatedItemGestureListener
import com.cyl.animateditem.CYLAnimatedItemView
import com.cyl.animateditem.CYLSize
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLTabBarAnimationURLWithOptions

/**
 * [EN] docs/Animated-Item.md, TODO 6: CYLAnimatedItemView on its own, with the public API only. A GIF (no library), a
 *      Lottie file (lottie-android is in this app), a missing file (the placeholder), and a vertical item with an
 *      accessory and dragging. Tapping an item plays its animation; the last event shows at the bottom.
 * [CN] docs/Animated-Item.md，TODO 6：单独使用 CYLAnimatedItemView，只用公开 API。GIF（无需动画库）、Lottie 文件（本 App 引入了 lottie-android）、
 *      缺失的文件（占位图），以及带附加图标与拖拽的纵向条目。点按条目播放其动画；最后一个事件显示在底部。
 */
class DemoAnimatedItemActivity : AppCompatActivity() {

    private lateinit var status: TextView

    private fun dp(value: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics).toInt()

    private val listener = object : CYLAnimatedItemGestureListener {
        override fun onItemTapped(item: CYLAnimatedItemView) {
            item.restartAnimation()
            status.text = "Tapped: ${item.title}"
        }

        override fun onItemLongPressed(item: CYLAnimatedItemView): Boolean {
            status.text = "Long pressed: ${item.title}"
            return true
        }

        override fun onAccessoryTapped(item: CYLAnimatedItemView) {
            status.text = "Accessory tapped: ${item.title}"
        }

        override fun onDragChanged(item: CYLAnimatedItemView, dx: Float, dy: Float) {
            item.translationX = dx
            item.translationY = dy
            status.text = "Dragging: ${item.title} (${dx.toInt()}, ${dy.toInt()})"
        }

        override fun onDragEnded(item: CYLAnimatedItemView, dx: Float, dy: Float, cancelled: Boolean) {
            item.animate().translationX(0f).translationY(0f).start()
            status.text = "Dropped: ${item.title}"
        }
    }

    private fun item(title: String, url: String?, configure: CYLAnimatedItemView.() -> Unit = {}) = CYLAnimatedItemView(this).apply {
        this.title = title
        iconSizeDp = CYLSize(40f, 40f)
        animationURL = url
        gestureListener = listener
        configure()
    }

    private fun caption(text: String) = TextView(this).apply {
        this.text = text
        setPadding(dp(16f), dp(16f), dp(16f), dp(4f))
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 13f)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "CYLAnimatedItemView"
        status = TextView(this).apply {
            text = "Tap, long press or drag an item"
            setPadding(dp(16f), dp(16f), dp(16f), dp(16f))
            // [EN] Read out when it changes. [CN] 变化时朗读。
            accessibilityLiveRegion = android.view.View.ACCESSIBILITY_LIVE_REGION_POLITE
        }
        val column = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        column.addView(caption("GIF, drawn without any animation library"))
        column.addView(item("GIF", "file:///android_asset/cyl_tab_sample_animated.gif"))
        column.addView(caption("Lottie (lottie-android is in this app)"))
        column.addView(item("Lottie", "file:///android_asset/green_lottie_tab_discover.json"))
        // [EN] The same file with the tint options (docs/Tab-Bar-Item-Animation.md, "Tint, or keep the original colors"): the row
        //      above keeps the file's own colors, the default; this one is drawn in one color, dark blue by day and white at night.
        // [CN] 同一文件加上着色选项（docs/Tab-Bar-Item-Animation.md，"Tint, or keep the original colors"）：上一行保持文件自身颜色（默认）；
        //      这一行用单一颜色绘制，日间深蓝，夜间白色。
        column.addView(caption("Lottie with tint #3A57ED, darkTint #FFFFFF (the row above keeps its colors)"))
        column.addView(item("Lottie tinted", CYLTabBarAnimationURLWithOptions("file:///android_asset/green_lottie_tab_discover.json", mapOf(
            CYLConstants.CYLTabBarAnimationOptionTint to "#3A57ED",
            CYLConstants.CYLTabBarAnimationOptionDarkTint to "#FFFFFF",
        ))))
        column.addView(caption("A missing file: the placeholder shows"))
        column.addView(item("Missing", "file:///android_asset/cyl_missing_animation.json"))
        column.addView(caption("Vertical, with an accessory (×) and dragging"))
        column.addView(item("Drag me", "file:///android_asset/cyl_tab_sample_animated.gif") {
            axis = CYLAnimatedItemAxis.Vertical
            isDragEnabled = true
            accessoryView = ImageView(context).apply {
                setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
                contentDescription = "Remove"
            }
        }, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { gravity = Gravity.CENTER_HORIZONTAL })
        column.addView(status)
        val scroll = ScrollView(this).apply { addView(column); clipToPadding = false }
        // [EN] The page ends above the navigation bar (edge to edge). [CN] 页面在导航栏上方结束（全面屏）。
        androidx.core.view.ViewCompat.setOnApplyWindowInsetsListener(scroll) { view, insets ->
            view.setPadding(view.paddingLeft, view.paddingTop, view.paddingRight, insets.getInsets(androidx.core.view.WindowInsetsCompat.Type.systemBars()).bottom)
            insets
        }
        setContentView(scroll)
        // [EN] Edge to edge (Android 15+), the page starts at the top of the window, behind the status bar and the action
        //      bar: it starts below the action bar's bottom, measured once laid out (its height differs between devices).
        // [CN] 全面屏（Android 15+）下页面从窗口顶部开始，位于状态栏与操作栏之后：在布局完成后测得操作栏底部（不同设备高度不同），从其下方开始。
        scroll.post {
            val bar = findViewById<android.view.View>(androidx.appcompat.R.id.action_bar_container)
            val location = IntArray(2)
            bar?.getLocationInWindow(location)
            scroll.setPadding(scroll.paddingLeft, if (bar != null) location[1] + bar.height else 0, scroll.paddingRight, scroll.paddingBottom)
            scroll.scrollTo(0, 0)
        }
    }
}
