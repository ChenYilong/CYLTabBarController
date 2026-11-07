package com.cyl.tabbar

import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.view.View
import android.view.ViewGroup
import android.view.animation.OvershootInterpolator
import android.widget.FrameLayout
import androidx.annotation.ColorInt

/**
 * [EN] `CYLBadgeView`: the badge drawn over a view: a red dot, a number (capped at `cyl_badgeMaximumBadgeNumber`, "99+")
 *      or a text ("new"), with a border, a corner radius and an animation (`CYLBadgeAnimationType`).
 * [CN] `CYLBadgeView`：绘制在视图上的角标：红点、数字（超过 `cyl_badgeMaximumBadgeNumber` 显示 "99+"）或文字（"new"），带边框、
 *      圆角与动画（`CYLBadgeAnimationType`）。
 */
class CYLBadgeView(context: Context) : View(context) {

    var text: String? = null
        set(value) {
            field = value
            requestLayout(); invalidate()
        }
    @ColorInt var badgeBackgroundColor: Int = Color.RED
    @ColorInt var badgeTextColor: Int = Color.WHITE
    @ColorInt var badgeBorderColor: Int? = null
    var badgeBorderWidth: Float = 0f
    /** [EN] The dot radius in dp (`cyl_badgeRadius`). [CN] 红点半径（dp）。 */
    var badgeRadius: Float = 4f
    var badgeCornerRadius: Float? = null
    var badgeFont: CYLFont = CYLFont(11f)
    var badgeMargin: Float = 2f
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }
    private val density get() = resources.displayMetrics.density

    /** [EN] A dot when the text is empty. [CN] 文字为空时为红点。 */
    val isDot: Boolean get() = text.isNullOrEmpty()

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        if (isDot) {
            val size = (badgeRadius * 2 * density).toInt()
            setMeasuredDimension(size, size)
            return
        }
        textPaint.textSize = android.util.TypedValue.applyDimension(android.util.TypedValue.COMPLEX_UNIT_SP, badgeFont.size, resources.displayMetrics)
        textPaint.typeface = badgeFont.typeface ?: if (badgeFont.bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        val height = (textPaint.fontSpacing + badgeMargin * 2 * density).toInt()
        val width = maxOf(height, (textPaint.measureText(text) + badgeMargin * 2 * density + height / 2).toInt())
        setMeasuredDimension(width, height)
    }

    override fun onDraw(canvas: Canvas) {
        val rect = RectF(0f, 0f, width.toFloat(), height.toFloat())
        val radius = badgeCornerRadius?.let { it * density } ?: (height / 2f)
        paint.style = Paint.Style.FILL
        paint.color = badgeBackgroundColor
        canvas.drawRoundRect(rect, radius, radius, paint)
        val borderColor = badgeBorderColor
        if (borderColor != null && badgeBorderWidth > 0) {
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = badgeBorderWidth * density
            paint.color = borderColor
            rect.inset(paint.strokeWidth / 2, paint.strokeWidth / 2)
            canvas.drawRoundRect(rect, radius, radius, paint)
        }
        if (!isDot) {
            textPaint.color = badgeTextColor
            val y = height / 2f - (textPaint.descent() + textPaint.ascent()) / 2
            canvas.drawText(text ?: "", width / 2f, y, textPaint)
        }
    }

    /** [EN] Plays `type` once (none: nothing). [CN] 播放一次动画（none 不播放）。 */
    fun play(type: CYLEnums.CYLBadgeAnimationType) {
        when (type) {
            CYLEnums.CYLBadgeAnimationType.None -> Unit
            CYLEnums.CYLBadgeAnimationType.Scale -> ObjectAnimator.ofPropertyValuesHolder(this, PropertyValuesHolder.ofFloat(SCALE_X, 0f, 1f), PropertyValuesHolder.ofFloat(SCALE_Y, 0f, 1f)).setDuration(250).apply { interpolator = OvershootInterpolator() }.start()
            CYLEnums.CYLBadgeAnimationType.Shake -> ObjectAnimator.ofFloat(this, TRANSLATION_X, 0f, -6f * density, 6f * density, -4f * density, 4f * density, 0f).setDuration(400).start()
            CYLEnums.CYLBadgeAnimationType.Bounce -> ObjectAnimator.ofFloat(this, TRANSLATION_Y, 0f, -8f * density, 0f, -4f * density, 0f).setDuration(500).start()
            CYLEnums.CYLBadgeAnimationType.Breathe -> ObjectAnimator.ofFloat(this, ALPHA, 1f, 0.3f, 1f).setDuration(1200).apply { repeatCount = ObjectAnimator.INFINITE }.start()
        }
    }
}

/**
 * [EN] `UIView (CYLBadgeExtention)` / `CYLBadgeProtocol`: a badge on any view, through Kotlin extension properties and
 *      functions with the iOS names. The badge is added to the view's parent (`cyl_getActualBadgeSuperView`) and placed at
 *      the view's top-right corner, moved by `cyl_badgeCenterOffset`.
 * [CN] `UIView (CYLBadgeExtention)` / `CYLBadgeProtocol`：任何视图上的角标，通过与 iOS 同名的 Kotlin 扩展属性与函数实现。角标添加到视图的
 *      父视图（`cyl_getActualBadgeSuperView`），位于视图右上角，可用 `cyl_badgeCenterOffset` 移动。
 */
class CYLBadgeState internal constructor() {
    var badge: CYLBadgeView? = null
    var value: String? = null
    var paused = false
    var style = CYLEnums.CYLBadgeStyle.RedDot
    var animationType = CYLEnums.CYLBadgeAnimationType.None
    var maximumBadgeNumber = 99
    var centerOffset = CYLOffset.zero
    var margin = 2f
    var radius = 4f
    var cornerRadius: Float? = null
    var font = CYLFont(11f)
    var backgroundColor = Color.RED
    var textColor = Color.WHITE
    var borderColor: Int? = null
    var borderWidth = 0f
    var respectsReduceMotion = true
    var hostReplacedByIconView = false
    var keepShowingPlusButtonLabel = false
    var delayIfNeededForSeconds = 0.0
}

private val badgeStates = java.util.WeakHashMap<View, CYLBadgeState>()

/** [EN] The badge state of a view (created on first use). [CN] 视图的角标状态（首次使用时创建）。 */
val View.cyl_badgeState: CYLBadgeState
    get() = synchronized(badgeStates) { badgeStates.getOrPut(this) { CYLBadgeState() } }

/** [EN] `CYLBadgeAccessibilityDescription()`: what VoiceOver / TalkBack says for a badge value. [CN] 无障碍朗读的角标描述。 */
fun CYLBadgeAccessibilityDescription(value: String?): String? = when {
    value == null -> null
    value.isEmpty() -> "New"
    value.toIntOrNull() != null -> "$value new items"
    else -> value
}

/** [EN] `cyl_badge`: the badge view, or null before `cyl_showBadge`. [CN] 角标视图；`cyl_showBadge` 之前为 null。 */
val View.cyl_badge: CYLBadgeView? get() = cyl_badgeState.badge

/** [EN] `-cyl_isShowBadge`. [CN] 角标是否显示。 */
fun View.cyl_isShowBadge(): Boolean = cyl_badgeState.badge?.visibility == View.VISIBLE

/** [EN] `-cyl_showBadge`: a red dot. [CN] 显示红点。 */
fun View.cyl_showBadge() = cyl_showBadgeValue("", cyl_badgeState.animationType)

/** [EN] `-cyl_showBadgeValue:`: "" a dot, a number (capped), or a text. [CN] "" 为红点，数字（有上限）或文字。 */
fun View.cyl_showBadgeValue(value: String) = cyl_showBadgeValue(value, cyl_badgeState.animationType)

/** [EN] `-cyl_showBadgeValue:animationType:`. [CN] 显示角标并播放动画。 */
fun View.cyl_showBadgeValue(value: String, animationType: CYLEnums.CYLBadgeAnimationType) {
    val state = cyl_badgeState
    state.value = value
    state.animationType = animationType
    val host = cyl_getActualBadgeSuperView() ?: return
    val badge = state.badge ?: CYLBadgeView(context).also {
        state.badge = it
        host.addView(it, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    }
    if (badge.parent !== host) {
        (badge.parent as? ViewGroup)?.removeView(badge)
        host.addView(badge, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    }
    val number = value.toIntOrNull()
    badge.text = when {
        value.isEmpty() -> null
        number != null && number > state.maximumBadgeNumber -> "${state.maximumBadgeNumber}+"
        number != null && number <= 0 -> null
        else -> value
    }
    if (number != null && number <= 0) {
        cyl_clearBadge()
        return
    }
    badge.badgeBackgroundColor = state.backgroundColor
    badge.badgeTextColor = state.textColor
    badge.badgeBorderColor = state.borderColor
    badge.badgeBorderWidth = state.borderWidth
    badge.badgeRadius = state.radius
    badge.badgeCornerRadius = state.cornerRadius
    badge.badgeFont = state.font
    badge.badgeMargin = state.margin
    badge.contentDescription = CYLBadgeAccessibilityDescription(value)
    badge.visibility = if (state.paused) View.INVISIBLE else View.VISIBLE
    cyl_refreshBadge()
    val reduceMotion = state.respectsReduceMotion && android.provider.Settings.Global.getFloat(context.contentResolver, android.provider.Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
    if (!reduceMotion) badge.play(animationType)
}

/** [EN] `-cyl_clearBadge`: removes the badge. [CN] 移除角标。 */
fun View.cyl_clearBadge() {
    val state = cyl_badgeState
    state.badge?.let { (it.parent as? ViewGroup)?.removeView(it) }
    state.badge = null
    state.value = null
    state.paused = false
}

/** [EN] `-cyl_resumeBadge`: shows a paused badge again. [CN] 重新显示暂停的角标。 */
fun View.cyl_resumeBadge() {
    val state = cyl_badgeState
    state.paused = false
    state.badge?.visibility = View.VISIBLE
}

/** [EN] `-cyl_isPauseBadge`: hidden but kept (e.g. the selected tab with `cyl_hidesBadgeOfSelectedTab`). [CN] 是否暂停（隐藏但保留）。 */
fun View.cyl_isPauseBadge(): Boolean = cyl_badgeState.paused

/** [EN] Hides the badge without removing it (the iOS "pause"). [CN] 隐藏但不移除角标（iOS 的“暂停”）。 */
fun View.cyl_pauseBadge() {
    val state = cyl_badgeState
    state.paused = true
    state.badge?.visibility = View.INVISIBLE
}

/** [EN] `-cyl_isHidden`: the view or one of its parents is hidden. [CN] 视图或其父视图是否隐藏。 */
fun View.cyl_isHidden(): Boolean {
    var view: View? = this
    while (view != null) {
        if (view.visibility != View.VISIBLE) return true
        view = view.parent as? View
    }
    return false
}

/** [EN] `-cyl_getActualBadgeSuperView`: the parent the badge is added to. [CN] 角标实际添加到的父视图。 */
fun View.cyl_getActualBadgeSuperView(): ViewGroup? = (this as? CYLTabBarItemButton) ?: (parent as? ViewGroup)

/** [EN] `-cyl_isReady`: the view is laid out. [CN] 视图已布局。 */
fun View.cyl_isReady(): Boolean = width > 0 && height > 0

/** [EN] `-cyl_findBarButtonContentView`: this view (Android bar buttons are plain views). [CN] 本视图（Android 的栏按钮即普通视图）。 */
fun View.cyl_findBarButtonContentView(): View = this

/** [EN] `-cyl_refreshBadge`: places the badge at the top-right corner plus `cyl_badgeCenterOffset`. [CN] 把角标放到右上角并加上偏移。 */
fun View.cyl_refreshBadge() {
    val state = cyl_badgeState
    val badge = state.badge ?: return
    val host = badge.parent as? ViewGroup ?: return
    badge.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED)
    val density = resources.displayMetrics.density
    val anchor = if (this is CYLTabBarItemButton) iconView else this
    val anchorRight = if (host === this) anchor.right else right
    val anchorTop = if (host === this) anchor.top else top
    val params = badge.layoutParams as? FrameLayout.LayoutParams ?: FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    params.leftMargin = (anchorRight - badge.measuredWidth / 2 + state.centerOffset.horizontal * density).toInt()
    params.topMargin = (anchorTop - badge.measuredHeight / 2 + state.centerOffset.vertical * density).toInt()
    if (host is FrameLayout) badge.layoutParams = params else badge.layout(params.leftMargin, params.topMargin, params.leftMargin + badge.measuredWidth, params.topMargin + badge.measuredHeight)
    badge.bringToFront()
}

/** [EN] `-cyl_resetBadgeAppearance`: back to the defaults. [CN] 恢复默认外观。 */
fun View.cyl_resetBadgeAppearance() {
    val state = cyl_badgeState
    state.backgroundColor = Color.RED; state.textColor = Color.WHITE; state.borderColor = null; state.borderWidth = 0f
    state.radius = 4f; state.cornerRadius = null; state.font = CYLFont(11f); state.margin = 2f; state.centerOffset = CYLOffset.zero
    state.maximumBadgeNumber = 99
    state.value?.let { cyl_showBadgeValue(it, CYLEnums.CYLBadgeAnimationType.None) }
}

// MARK: - CYLBadgeProtocol properties 属性

var View.cyl_badgeBackgroundColor: Int
    get() = cyl_badgeState.backgroundColor
    set(value) { cyl_badgeState.backgroundColor = value; cyl_badge?.badgeBackgroundColor = value; cyl_badge?.invalidate() }
var View.cyl_badgeTextColor: Int
    get() = cyl_badgeState.textColor
    set(value) { cyl_badgeState.textColor = value; cyl_badge?.badgeTextColor = value; cyl_badge?.invalidate() }
var View.cyl_badgeBorderColor: Int?
    get() = cyl_badgeState.borderColor
    set(value) { cyl_badgeState.borderColor = value; cyl_badge?.badgeBorderColor = value; cyl_badge?.invalidate() }
var View.cyl_badgeBorderWidth: Float
    get() = cyl_badgeState.borderWidth
    set(value) { cyl_badgeState.borderWidth = value; cyl_badge?.badgeBorderWidth = value; cyl_badge?.invalidate() }
var View.cyl_badgeFont: CYLFont
    get() = cyl_badgeState.font
    set(value) { cyl_badgeState.font = value; cyl_badge?.badgeFont = value; cyl_badge?.requestLayout() }
var View.cyl_badgeCenterOffset: CYLOffset
    get() = cyl_badgeState.centerOffset
    set(value) { cyl_badgeState.centerOffset = value; cyl_refreshBadge() }
var View.cyl_badgeAnimationType: CYLEnums.CYLBadgeAnimationType
    get() = cyl_badgeState.animationType
    set(value) { cyl_badgeState.animationType = value }
var View.cyl_badgeMaximumBadgeNumber: Int
    get() = cyl_badgeState.maximumBadgeNumber
    set(value) { cyl_badgeState.maximumBadgeNumber = value; cyl_badgeState.value?.let { cyl_showBadgeValue(it, CYLEnums.CYLBadgeAnimationType.None) } }
var View.cyl_badgeRadius: Float
    get() = cyl_badgeState.radius
    set(value) { cyl_badgeState.radius = value; cyl_badge?.badgeRadius = value; cyl_badge?.requestLayout() }
var View.cyl_badgeMargin: Float
    get() = cyl_badgeState.margin
    set(value) { cyl_badgeState.margin = value; cyl_badge?.badgeMargin = value; cyl_badge?.requestLayout() }
var View.cyl_badgeCornerRadius: Float?
    get() = cyl_badgeState.cornerRadius
    set(value) { cyl_badgeState.cornerRadius = value; cyl_badge?.badgeCornerRadius = value; cyl_badge?.invalidate() }
var View.cyl_badgeRespectsReduceMotion: Boolean
    get() = cyl_badgeState.respectsReduceMotion
    set(value) { cyl_badgeState.respectsReduceMotion = value }
var View.cyl_badgeHostReplacedByIconView: Boolean
    get() = cyl_badgeState.hostReplacedByIconView
    set(value) { cyl_badgeState.hostReplacedByIconView = value }
var View.cyl_keepShowingPlusButtonLabel: Boolean
    get() = cyl_badgeState.keepShowingPlusButtonLabel
    set(value) { cyl_badgeState.keepShowingPlusButtonLabel = value }
/** [EN] `cyl_delayIfNeededForSeconds`: iOS delays the badge until the tab bar is laid out; Android lays out synchronously, so the value is kept only. [CN] iOS 延迟到 TabBar 布局完成；Android 同步布局，只保存该值。 */
var View.cyl_delayIfNeededForSeconds: Double
    get() = cyl_badgeState.delayIfNeededForSeconds
    set(value) { cyl_badgeState.delayIfNeededForSeconds = value }
/** [EN] `cyl_badgeFrame`: the badge's frame in its parent, in px. [CN] 角标在父视图中的位置（px）。 */
val View.cyl_badgeFrame: RectF
    get() = cyl_badge?.let { RectF(it.left.toFloat(), it.top.toFloat(), it.right.toFloat(), it.bottom.toFloat()) } ?: RectF()
