package com.cyl.tabbar.demo

import android.app.Dialog
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.SeekBar
import android.widget.TextView
import androidx.appcompat.widget.SwitchCompat
import androidx.core.view.ViewCompat
import com.cyl.tabbar.CYLTabBarController

/**
 * [EN] The playback controls AGENTS.md asks of every example that shows tab icon animations ("Animated icon examples:
 *      Play all, speed slider, loop switch"): a panel at the top of the screen, without dimming the window, so the tab bar
 *      stays in sight. The three controls combine into one playback policy, applied live: Play all restarts every tab icon
 *      from progress 0 (`cyl_playAllTabBarItemAnimations`), the slider (0.25× to 3×) sets `tabBarItemAnimationSpeed`, the
 *      switch sets `tabBarItemAnimationLoops`.
 * [CN] AGENTS.md 要求每个展示 Tab 图标动画的示例提供的播放控件（「全部播放」、倍速滑块、循环开关）：位于屏幕顶部的面板，不调暗
 *      窗口，因此 TabBar 始终可见。三个控件组合成一个实时生效的播放策略：「全部播放」让每个 Tab 图标从进度 0 重新播放
 *      （`cyl_playAllTabBarItemAnimations`），滑块（0.25× 至 3×）设置 `tabBarItemAnimationSpeed`，开关设置
 *      `tabBarItemAnimationLoops`。
 */
object DemoPlaybackControls {
    private const val MINIMUM_SPEED = 0.25f
    private const val MAXIMUM_SPEED = 3f
    private const val STEP = 0.05f
    private val STEPS = Math.round((MAXIMUM_SPEED - MINIMUM_SPEED) / STEP)

    /** [EN] The speed as text: "1.5×". [CN] 速度的文字：「1.5×」。 */
    fun speedText(speed: Float): String = "%.2f".format(speed).trimEnd('0').trimEnd('.', ',') + "×"

    /** [EN] What TalkBack reads for the slider: "1.5 times". [CN] TalkBack 为滑块朗读的内容：「1.5 times」。 */
    fun speedDescription(speed: Float): String = speedText(speed).dropLast(1) + " times"

    fun show(context: Context, controller: CYLTabBarController, onDismiss: () -> Unit) {
        val density = context.resources.displayMetrics.density
        val padding = (20 * density).toInt()
        val current = controller.tabBarItemAnimationSpeed.takeIf { it > 0 && it.isFinite() } ?: 1f

        val playAll = Button(context).apply {
            text = "Play all"
            isAllCaps = false
            setOnClickListener { controller.cyl_playAllTabBarItemAnimations() }
        }
        // [EN] The panel is white in both themes, so its texts are dark in both. [CN] 面板在两种主题下都是白色，因此文字在两种主题下都是深色。
        val textColor = Color.rgb(28, 28, 30)
        val speedLabel = TextView(context).apply {
            textSize = 15f
            setTextColor(textColor)
            setPadding(0, padding / 2, 0, 0)
            // [EN] The slider reads the value. [CN] 数值由滑块朗读。
            importantForAccessibility = TextView.IMPORTANT_FOR_ACCESSIBILITY_NO
        }
        val slider = SeekBar(context).apply {
            max = STEPS
            progress = Math.round((current.coerceIn(MINIMUM_SPEED, MAXIMUM_SPEED) - MINIMUM_SPEED) / STEP)
            contentDescription = "Speed"
        }
        fun update(speed: Float) {
            speedLabel.text = "Speed: ${speedText(speed)}"
            ViewCompat.setStateDescription(slider, speedDescription(speed))
        }
        update(current)
        slider.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar, progress: Int, fromUser: Boolean) {
                val speed = MINIMUM_SPEED + progress * STEP
                controller.tabBarItemAnimationSpeed = speed
                update(speed)
            }
            override fun onStartTrackingTouch(seekBar: SeekBar) { /* [EN] Only the value matters. [CN] 只关心数值。 */ }
            override fun onStopTrackingTouch(seekBar: SeekBar) { /* [EN] Only the value matters. [CN] 只关心数值。 */ }
        })
        val loop = SwitchCompat(context).apply {
            text = "Loop"
            textSize = 15f
            setTextColor(textColor)
            isChecked = controller.tabBarItemAnimationLoops
            setPadding(0, padding / 2, 0, 0)
            setOnCheckedChangeListener { _, checked -> controller.tabBarItemAnimationLoops = checked }
        }
        val panel = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(padding, padding, padding, padding)
            background = GradientDrawable().apply { cornerRadius = 16 * density; setColor(Color.WHITE) }
            addView(playAll)
            addView(speedLabel)
            addView(slider)
            addView(loop)
        }
        Dialog(context).apply {
            setContentView(panel)
            window?.let { window ->
                window.setBackgroundDrawableResource(android.R.color.transparent)
                // [EN] No dimming, at the top: the tab bar at the bottom stays visible while the controls change. [CN] 不调暗、位于顶部：调整控件时底部的 TabBar 始终可见。
                window.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND)
                window.setGravity(Gravity.TOP)
                window.setLayout((context.resources.displayMetrics.widthPixels * 0.9f).toInt(), WindowManager.LayoutParams.WRAP_CONTENT)
            }
            setOnDismissListener { onDismiss() }
            show()
        }
    }
}
