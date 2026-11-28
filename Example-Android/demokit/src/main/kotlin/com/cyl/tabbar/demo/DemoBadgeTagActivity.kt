package com.cyl.tabbar.demo

import android.graphics.Rect
import android.os.Bundle
import android.util.Log
import android.util.TypedValue
import android.view.View
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import androidx.appcompat.app.AppCompatActivity
import com.cyl.animateditem.CYLAnimatedItemBackgroundStyle
import com.cyl.animateditem.CYLAnimatedItemView
import com.cyl.animateditem.CYLSize
import com.cyl.tabbar.CYLBadgeAttributeKey
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.cylBadge
import com.cyl.tabbar.cylBadgeIcon
import com.cyl.tabbar.cylBadgeTitleForRow

/**
 * [EN] docs/Animated-Item-Badge.md, step A12: badges on tags made of CYLAnimatedItemView. A tag only sets `badgeValue` and
 *      `badgeAttributes`; its image is the plain icon. Repeat counts and the rotation have no attribute key, so those tags
 *      play them on the badge view. Every layout is logged ("CYLBadgeTag") for the acceptance measurements (AC1-AC3, AC7).
 * [CN] docs/Animated-Item-Badge.md，步骤 A12：由 CYLAnimatedItemView 组成的 Tag 上的角标。Tag 只设置 `badgeValue` 与
 *      `badgeAttributes`；图片是原始图标。重复次数与旋转没有对应的属性键，这些 Tag 在角标视图上播放。每次布局都记录日志
 *      （"CYLBadgeTag"），用于验收测量（AC1-AC3、AC7）。
 */
class DemoBadgeTagActivity : AppCompatActivity() {

    private class Sample(
        val value: String?,
        val animation: String? = null,
        val respectsReduceMotion: Boolean = false,
        val repeats: Int = 0,
        val repeated: CYLEnums.CYLBadgeAnimationType = CYLEnums.CYLBadgeAnimationType.None,
        val rotates: Boolean = false,
    )

    // [EN] The first nine badge samples, in the order of the iOS tags. [CN] 前九个角标示例，顺序与 iOS 的 Tag 相同。
    private val samples = listOf(
        Sample("3", "Scale"),
        Sample("3", "Shake"),
        Sample("3", "Bounce"),
        Sample("", "Breathe"),
        Sample("3", "Shake", respectsReduceMotion = true),
        Sample("new", rotates = true),
        Sample("3", repeats = -1, repeated = CYLEnums.CYLBadgeAnimationType.ScaleOnce),
        Sample("3", repeats = 3, repeated = CYLEnums.CYLBadgeAnimationType.Shake),
        Sample("3", repeats = 3, repeated = CYLEnums.CYLBadgeAnimationType.Bounce),
    )

    private val tags = mutableListOf<CYLAnimatedItemView>()
    private var showsBadges = true

    private fun dp(value: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics).toInt()

    private fun tag(title: String) = CYLAnimatedItemView(this).apply {
        this.title = title
        iconSizeDp = CYLSize(30f, 30f)
        image = cylBadgeIcon(this)
        spacingDp = 8f
        itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.Flat
        itemBackgroundColor = 0x33888888
        itemCornerRadius = 14f
        itemContentHorizontalInset = 14f
        minimumHeight = dp(52f)
    }

    private fun apply(item: CYLAnimatedItemView, sample: Sample) {
        if (!showsBadges) {
            item.badgeValue = null
            return
        }
        val attributes = mutableMapOf<String, Any?>(CYLBadgeAttributeKey.RESPECTS_REDUCE_MOTION to sample.respectsReduceMotion)
        sample.animation?.let { attributes[CYLBadgeAttributeKey.ANIMATION] = it }
        item.badgeAttributes = attributes
        item.badgeValue = sample.value
        val badge = item.badgeAnchorView.cylBadge ?: return
        if (sample.rotates) {
            badge.playAnimator(android.animation.ObjectAnimator.ofFloat(badge, View.ROTATION, 0f, 360f).apply {
                duration = 2000
                repeatCount = android.animation.ObjectAnimator.INFINITE
                interpolator = android.view.animation.LinearInterpolator()
            })
        }
        if (sample.repeats != 0) {
            var left = sample.repeats
            fun again() {
                badge.play(sample.repeated)
                if (left < 0 || --left > 0) badge.postDelayed({ if (badge.isAttachedToWindow && showsBadges) again() }, 1000)
                // [EN] Shake and bounce repeat forever once played: stop after the last time. [CN] 摇晃与弹跳播放后会一直重复：最后一次后停止。
                else badge.postDelayed({ badge.stopAnimation() }, 1000)
            }
            badge.post { again() }
        }
    }

    private fun frameIn(item: View, view: View): Rect {
        val origin = IntArray(2).also(item::getLocationInWindow)
        val position = IntArray(2).also(view::getLocationInWindow)
        val left = position[0] - origin[0]
        val top = position[1] - origin[1]
        return Rect(left, top, left + view.width, top + view.height)
    }

    private fun logFrames() {
        val density = resources.displayMetrics.density
        tags.forEachIndexed { index, item ->
            val icon = frameIn(item, item.iconView)
            // [EN] The badge is drawn in an overlay: its layout frame is in that host's coordinates (the item for this anchor), without the animation's transform.
            // [CN] 角标画在 overlay 中：布局位置使用承载视图（对该锚点即 item）的坐标，不含动画变换。
            val badge = item.badgeAnchorView.cylBadge?.takeIf { item.isShowingBadge }?.let { Rect(it.left, it.top, it.right, it.bottom) }
            Log.i("CYLBadgeTag", "tag=${index + 1} density=$density item=${item.width}x${item.height} icon=${icon.toShortString()} " +
                "anchor=${frameIn(item, item.badgeAnchorView).toShortString()} badge=${badge?.toShortString()} badgeParent=${item.badgeAnchorView.cylBadge?.parent?.javaClass?.simpleName} rtl=${item.layoutDirection == View.LAYOUT_DIRECTION_RTL} " +
                "iconCentreOffsetDp=${(icon.exactCenterY() - item.height / 2f) / density} description=${item.contentDescription}")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        DemoText.attach(this)
        title = "CYLAnimatedItemView badges"
        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            clipChildren = false
            setPadding(dp(16f), dp(12f), dp(16f), dp(24f))
        }
        fun add(view: View) = column.addView(view, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply { topMargin = dp(8f) })
        add(Button(this).apply {
            isAllCaps = false
            text = "badgeValue = nil"
            setOnClickListener {
                showsBadges = !showsBadges
                text = if (showsBadges) "badgeValue = nil" else "badgeValue"
                tags.take(samples.size).forEachIndexed { index, item -> apply(item, samples[index]) }
                column.postDelayed(::logFrames, 500)
            }
        })
        samples.forEachIndexed { index, sample ->
            val item = tag(DemoTagList.tagText(cylBadgeTitleForRow(index), null).first)
            tags += item
            add(item)
            apply(item, sample)
        }
        // [EN] The reference without a badge (AC1). [CN] 没有角标的对照（AC1）。
        tag("badgeValue = nil").also { tags += it; add(it) }
        // [EN] A badge on an animated icon (AC6): a tap plays it. [CN] 动画图标上的角标（AC6）：点按播放。
        tag("GIF · badgeValue = \"8\"").also { item ->
            item.animationURL = "file:///android_asset/cyl_tab_sample_animated.gif"
            item.animationLoops = true
            // [EN] This GIF only changes colour: keep its colours, so playback shows. [CN] 该 GIF 只变颜色：保留原色，播放才看得出。
            item.animationRenderingMode = com.cyl.animateditem.CYLAnimationRenderingMode.AlwaysOriginal
            item.badgeValue = "8"
            item.post { item.restartAnimation() }
            tags += item
            add(item)
        }
        setContentView(ScrollView(this).apply {
            clipChildren = false
            fitsSystemWindows = true
            addView(column)
        })
        column.postDelayed(::logFrames, 1500)
    }
}
