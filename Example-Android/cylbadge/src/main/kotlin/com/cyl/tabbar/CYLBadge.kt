// [EN] The method names are the iOS names on purpose (`cyl_…`, `tabBarController_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`、`tabBarController_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import com.cyl.animateditem.CYLOffset
import android.animation.ObjectAnimator
import com.cyl.badge.BuildConfig
import com.cyl.badge.R
import com.chenyilong.cyldeallocblockexecutor.BadgeEvents
import com.chenyilong.cyldeallocblockexecutor.LifecycleRegistry
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
 * [EN] `CYLBadgeView`: the badge drawn over a view: a red dot, a number (capped at `cylBadgeMaximumBadgeNumber`, "99+")
 *      or a text ("new"), with a border, a corner radius and an animation (`CYLBadgeAnimationType`).
 * [CN] `CYLBadgeView`：绘制在视图上的角标：红点、数字（超过 `cylBadgeMaximumBadgeNumber` 显示 "99+"）或文字（"new"），带边框、
 *      圆角与动画（`CYLBadgeAnimationType`）。
 */
class CYLBadgeView(context: Context) : View(context), CYLBadgeTextDisplaying {

    /**
     * [EN] The view the badge belongs to. [CN] 角标所属的视图。
     */
    var host: View? = null
        internal set
    override var text: String? = null
        set(value) {
            field = value
            requestLayout(); invalidate()
        }
    /**
     * [EN] `CYLBadgeTextDisplaying.font`: `badgeFont`. [CN] 即 `badgeFont`。
     */
    override var font: CYLFont
        get() = badgeFont
        set(value) { badgeFont = value; requestLayout() }
    /**
     * [EN] `CYLBadgeTextDisplaying.textColor`: `badgeTextColor`. [CN] 即 `badgeTextColor`。
     */
    override var textColor: Int
        get() = badgeTextColor
        set(value) { badgeTextColor = value; invalidate() }
    /**
     * [EN] `textAlignment` as a `Gravity` (start, center or end). [CN] 以 `Gravity` 表示的对齐方式。
     */
    override var textGravity: Int = android.view.Gravity.CENTER
        set(value) { field = value; invalidate() }
    @ColorInt var badgeBackgroundColor: Int = Color.RED
    @ColorInt var badgeTextColor: Int = Color.WHITE
    @ColorInt var badgeBorderColor: Int? = null
    var badgeBorderWidth: Float = 0f
    /**
     * [EN] The dot radius in dp (`cylBadgeRadius`). [CN] 红点半径（dp）。
     */
    var badgeRadius: Float = 4f
        set(value) { field = value; requestLayout(); invalidate() }
    var badgeCornerRadius: Float? = null
        set(value) { field = value; invalidate() }
    var badgeFont: CYLFont = CYLFont(9f, bold = true)
        set(value) { field = value; requestLayout(); invalidate() }
    var badgeMargin: Float = 8f
        set(value) { field = value; requestLayout(); invalidate() }
    private var refreshing = false

    /**
     * [EN] A badge in its host's parent overlay is not laid out by that parent: when its text or font changes, it measures
     *      itself again and goes back to the host's corner, so it always fits its text ("3", "99+", "new").
     * [CN] 位于宿主父视图 overlay 中的角标不由该父视图布局：文字或字体变化时自己重新测量并回到宿主角落，因此始终适配文字（"3"、"99+"、"new"）。
     */
    override fun requestLayout() {
        super.requestLayout()
        val host = host ?: return
        if (refreshing || host.cylBadgeState.overlayHost == null) return
        refreshing = true
        try { host.cylRefreshBadge() } finally { refreshing = false }
    }
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }
    private val density get() = resources.displayMetrics.density

    /**
     * [EN] A dot when the text is empty. [CN] 文字为空时为红点。
     */
    val isDot: Boolean get() = text.isNullOrEmpty()

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        if (isDot) {
            val size = (badgeRadius * 2 * density).toInt()
            setMeasuredDimension(size, size)
            return
        }
        textPaint.textSize = android.util.TypedValue.applyDimension(android.util.TypedValue.COMPLEX_UNIT_SP, badgeFont.size, resources.displayMetrics)
        textPaint.typeface = badgeFont.typeface ?: if (badgeFont.bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        // [EN] As iOS (`-cyl_adjustLabelWidth:` and `-cyl_addMargin`): the text's size plus `badgeMargin` once in each
        //      direction, never narrower than tall. [CN] 与 iOS 相同（`-cyl_adjustLabelWidth:` 与 `-cyl_addMargin`）：文字尺寸在两个方向各加一次
        //      `badgeMargin`，宽度不小于高度。
        val height = (kotlin.math.ceil(textPaint.fontSpacing) + badgeMargin * density).toInt()
        val width = maxOf(height, (kotlin.math.ceil(textPaint.measureText(text)) + badgeMargin * density).toInt())
        setMeasuredDimension(width, height)
    }

    private val rect = RectF()

    override fun onDraw(canvas: Canvas) {
        rect.set(0f, 0f, width.toFloat(), height.toFloat())
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
            val horizontal = textGravity and android.view.Gravity.HORIZONTAL_GRAVITY_MASK
            val inset = badgeMargin * density / 2 + textPaint.measureText(text ?: "") / 2
            val x = when (horizontal) {
                android.view.Gravity.START, android.view.Gravity.LEFT -> inset
                android.view.Gravity.END, android.view.Gravity.RIGHT -> width - inset
                else -> width / 2f
            }
            canvas.drawText(text ?: "", x, y, textPaint)
        }
    }

    private var running: android.animation.Animator? = null

    /**
     * [EN] Stops the running animation and resets the transform. [CN] 停止正在播放的动画并重置变换。
     */
    fun stopAnimation() {
        running?.cancel()
        running = null
        scaleX = 1f; scaleY = 1f; translationX = 0f; translationY = 0f; alpha = 1f; rotationX = 0f; rotation = 0f; rotationY = 0f
    }

    /**
     * [EN] Plays `type` (the iOS `CYLBadgeAnimationType`): scale, shake, bounce and breathe repeat until the badge is cleared
     *      or another animation plays; left-right, right-left, fade-in, rolling and scale play once. None: nothing.
     * [CN] 播放 `type`（iOS 的 `CYLBadgeAnimationType`）：缩放、摇晃、弹跳与呼吸一直重复到角标清除或播放其他动画；左右、右左、淡入、滚动与缩放只播放一次。
     */
    fun play(type: CYLEnums.CYLBadgeAnimationType) {
        stopAnimation()
        // [EN] Badge debugging build option (docs/Badge-Debugging.md): `-PcylBadgeAnimationDisabled=true` turns badge
        //      animations off, so a screenshot shows the badge at its laid-out place. Never ship a release with it.
        // [CN] 角标调试编译选项（docs/Badge-Debugging.md）：`-PcylBadgeAnimationDisabled=true` 关闭角标动画，截图中的角标就在布局位置。不要在发布版本中开启。
        if (BuildConfig.CYL_BADGE_ANIMATION_DISABLED) return
        val forever = ObjectAnimator.INFINITE
        val animator: android.animation.Animator = when (type) {
            CYLEnums.CYLBadgeAnimationType.None -> return
            CYLEnums.CYLBadgeAnimationType.Scale -> ObjectAnimator.ofPropertyValuesHolder(this, PropertyValuesHolder.ofFloat(SCALE_X, 1.4f, 0.6f), PropertyValuesHolder.ofFloat(SCALE_Y, 1.4f, 0.6f)).setDuration(1000).apply { repeatCount = forever; repeatMode = ObjectAnimator.REVERSE }
            CYLEnums.CYLBadgeAnimationType.Shake -> ObjectAnimator.ofFloat(this, TRANSLATION_X, 0f, -6f * density, 6f * density, -4f * density, 4f * density, 0f).setDuration(1000).apply { repeatCount = forever }
            CYLEnums.CYLBadgeAnimationType.Bounce -> ObjectAnimator.ofFloat(this, TRANSLATION_Y, 0f, -8f * density, 0f, -4f * density, 0f).setDuration(1000).apply { repeatCount = forever }
            CYLEnums.CYLBadgeAnimationType.Breathe -> ObjectAnimator.ofFloat(this, ALPHA, 1f, 0.1f, 1f).setDuration(1200).apply { repeatCount = forever }
            CYLEnums.CYLBadgeAnimationType.LeftRightOnce -> ObjectAnimator.ofFloat(this, TRANSLATION_X, -10f * density, 0f).setDuration(400)
            CYLEnums.CYLBadgeAnimationType.RightLeftOnce -> ObjectAnimator.ofFloat(this, TRANSLATION_X, 10f * density, 0f).setDuration(400)
            CYLEnums.CYLBadgeAnimationType.FadeInOnce -> ObjectAnimator.ofFloat(this, ALPHA, 0f, 1f).setDuration(400)
            CYLEnums.CYLBadgeAnimationType.RollingOnce -> ObjectAnimator.ofFloat(this, ROTATION_X, 90f, 0f).setDuration(400)
            CYLEnums.CYLBadgeAnimationType.ScaleOnce -> ObjectAnimator.ofPropertyValuesHolder(this, PropertyValuesHolder.ofFloat(SCALE_X, 0f, 1f), PropertyValuesHolder.ofFloat(SCALE_Y, 0f, 1f)).setDuration(300).apply { interpolator = OvershootInterpolator() }
        }
        runAndReport(animator, type)
    }

    /**
     * [EN] Starts [animator] and reports its moments on the badge's host view through CYLDeallocBlockExecutor: `cyl.badge.animationDidStart`
     *      now, `cyl.badge.animationDidStop` when it ends (`finished` true) or is cancelled (`finished` false). [CN] 启动 [animator]，并通过
     *      CYLDeallocBlockExecutor 在角标的宿主视图上报告时机：现在发出 `cyl.badge.animationDidStart`，结束（`finished` 为 true）或取消（为 false）时发出
     *      `cyl.badge.animationDidStop`。
     */
    private fun runAndReport(animator: android.animation.Animator, type: CYLEnums.CYLBadgeAnimationType?) {
        running = animator
        var cancelled = false
        animator.addListener(object : android.animation.AnimatorListenerAdapter() {
            override fun onAnimationCancel(a: android.animation.Animator) { cancelled = true }
            override fun onAnimationEnd(a: android.animation.Animator) {
                host?.cylPostBadgeEvent(BadgeEvents.animationDidStop, mapOf("finished" to !cancelled))
            }
        })
        animator.start()
        host?.cylPostBadgeEvent(BadgeEvents.animationDidStart, mapOf("animationType" to type?.name))
    }

    /**
     * [EN] Plays a custom `animator` on the badge (the iOS factory animations); `stopAnimation` stops it. [CN] 在角标上播放自定义 `animator`（iOS 的工厂动画）；`stopAnimation` 会停止它。
     */
    internal fun playAnimator(animator: android.animation.Animator) {
        stopAnimation()
        if (BuildConfig.CYL_BADGE_ANIMATION_DISABLED) return
        runAndReport(animator, null)
    }

    override fun onDetachedFromWindow() {
        stopAnimation()
        super.onDetachedFromWindow()
    }
}

/**
 * [EN] `UIView (CYLBadgeExtention)` / `CYLBadgeProtocol`: a badge on any view, through Kotlin extension properties and
 *      functions with the iOS names. The badge is added to the view's parent (`cylGetActualBadgeSuperView`) and placed at
 *      the view's top-right corner, moved by `cylBadgeCenterOffset`.
 * [CN] `UIView (CYLBadgeExtention)` / `CYLBadgeProtocol`：任何视图上的角标，通过与 iOS 同名的 Kotlin 扩展属性与函数实现。角标添加到视图的
 *      父视图（`cylGetActualBadgeSuperView`），位于视图右上角，可用 `cylBadgeCenterOffset` 移动。
 */
class CYLBadgeState internal constructor() {
    var badge: CYLBadgeView? = null
    /**
     * [EN] The parent whose overlay holds the badge of a view that cannot hold children. [CN] 不能包含子视图的视图，其角标所在 overlay 的父视图。
     */
    internal var overlayHost: ViewGroup? = null
    internal var followsLayout = false
    var value: String? = null
    var paused = false
    var style = CYLEnums.CYLBadgeStyle.RedDot
    var animationType = CYLEnums.CYLBadgeAnimationType.None
    // [EN] A value set on the view wins over `CYLBadgeAppearance.globalAppearance` (#425); null follows it. [CN] 视图上设置的值优先于全局外观（#425）；null 跟随全局外观。
    private val global get() = CYLBadgeAppearance.globalAppearance
    internal var explicitMaximumBadgeNumber: Int? = null
    internal var explicitCenterOffset: CYLOffset? = null
    internal var explicitMargin: Float? = null
    internal var explicitRadius: Float? = null
    internal var explicitCornerRadius: Float? = null
    internal var explicitFont: CYLFont? = null
    internal var explicitBackgroundColor: Int? = null
    internal var explicitTextColor: Int? = null
    internal var explicitBorderColor: Int? = null
    internal var explicitBorderWidth: Float? = null
    var maximumBadgeNumber: Int get() = explicitMaximumBadgeNumber ?: global.maximumBadgeNumber; set(value) { explicitMaximumBadgeNumber = value }
    var centerOffset: CYLOffset get() = explicitCenterOffset ?: global.centerOffset; set(value) { explicitCenterOffset = value }
    var margin: Float get() = explicitMargin ?: global.margin; set(value) { explicitMargin = value }
    var radius: Float get() = explicitRadius ?: global.radius; set(value) { explicitRadius = value }
    var cornerRadius: Float? get() = explicitCornerRadius ?: global.cornerRadius.takeIf { it > 0 }; set(value) { explicitCornerRadius = value }
    var font: CYLFont get() = explicitFont ?: global.font; set(value) { explicitFont = value }
    var backgroundColor: Int get() = explicitBackgroundColor ?: global.backgroundColor; set(value) { explicitBackgroundColor = value }
    var textColor: Int get() = explicitTextColor ?: global.textColor; set(value) { explicitTextColor = value }
    var borderColor: Int? get() = explicitBorderColor ?: global.borderColor; set(value) { explicitBorderColor = value }
    var borderWidth: Float get() = explicitBorderWidth ?: global.borderWidth; set(value) { explicitBorderWidth = value }
    var respectsReduceMotion = true
    var hostReplacedByIconView = false
    var keepShowingPlusButtonLabel = false
    var delayIfNeededForSeconds = 0.0
}

private val badgeStates = java.util.WeakHashMap<View, CYLBadgeState>()

/**
 * [EN] The badge state of a view (created on first use). [CN] 视图的角标状态（首次使用时创建）。
 */
val View.cylBadgeState: CYLBadgeState
    get() = synchronized(badgeStates) { badgeStates.getOrPut(this) { CYLBadgeState() } }

/**
 * [EN] `CYLBadgeAccessibilityDescription()`: what TalkBack says for a badge value, as iOS: "New content" for a dot, "N new
 *      messages" for a number ("99+" too; nothing for 0), the text itself otherwise. In [CYLLocalization.language].
 * [CN] TalkBack 朗读的角标描述，与 iOS 相同：红点为“有新内容”，数字（含“99+”；0 不朗读）为“N 条新消息”，其他为文字本身。
 *      使用 [CYLLocalization.language]。
 */
fun CYLBadgeAccessibilityDescription(context: Context, value: String?): String? = when {
    value == null -> null
    value.isEmpty() -> CYLLocalization.string(context, R.string.cyl_badge_new_content)
    Regex("^[0-9]+\\+?$").matches(value) ->
        if ((value.trimEnd('+').toLongOrNull() ?: 0L) > 0L) CYLLocalization.string(context, R.string.cyl_badge_new_messages, value) else null
    else -> value
}

/**
 * [EN] `cylBadge`: the badge view, or null before `cylShowBadge`. [CN] 角标视图；`cylShowBadge` 之前为 null。
 */
val View.cylBadge: CYLBadgeView? get() = cylBadgeState.badge

/**
 * [EN] `-cylIsShowBadge`. [CN] 角标是否显示。
 */
fun View.cylIsShowBadge(): Boolean = cylBadgeState.badge?.visibility == View.VISIBLE

/**
 * [EN] `-cylShowBadge`: a red dot. [CN] 显示红点。
 */
fun View.cylShowBadge() = cylShowBadgeValue("", cylBadgeState.animationType)

/**
 * [EN] `-cylShowBadgeValue:`: "" a dot, a number (capped), or a text. [CN] "" 为红点，数字（有上限）或文字。
 */
fun View.cylShowBadgeValue(value: String) = cylShowBadgeValue(value, cylBadgeState.animationType)

/**
 * [EN] `-cylShowBadgeValue:animationType:`. [CN] 显示角标并播放动画。
 */
fun View.cylShowBadgeValue(value: String, animationType: CYLEnums.CYLBadgeAnimationType) {
    val state = cylBadgeState
    state.value = value
    state.animationType = animationType
    val host = cylGetActualBadgeSuperView() ?: return
    val badge = state.badge ?: CYLBadgeView(context).also {
        state.badge = it
        it.host = this
    }
    cylAttachBadge(badge, host)
    val number = value.toIntOrNull()
    badge.text = when {
        value.isEmpty() -> null
        number != null && number > state.maximumBadgeNumber -> "${state.maximumBadgeNumber}+"
        number != null && number <= 0 -> null
        // [EN] "new" / "NEW" are tokens, shown in [CYLLocalization.language], as iOS `-cyl_showNewBadge:`.
        // [CN] "new" / "NEW" 是标记，使用 [CYLLocalization.language] 显示，与 iOS `-cyl_showNewBadge:` 相同。
        value == "new" -> CYLLocalization.string(context, R.string.cyl_badge_new_lowercase)
        value == "NEW" -> CYLLocalization.string(context, R.string.cyl_badge_new_uppercase)
        else -> value
    }
    if (number != null && number <= 0) {
        cylClearBadge()
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
    badge.contentDescription = CYLBadgeAccessibilityDescription(context, value)
    badge.visibility = if (state.paused) View.INVISIBLE else View.VISIBLE
    cylRefreshBadge()
    val reduceMotion = state.respectsReduceMotion && android.provider.Settings.Global.getFloat(context.contentResolver, android.provider.Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
    if (!reduceMotion) badge.play(animationType)
    cylPostBadgeEvent(BadgeEvents.didShow, mapOf("value" to value, "animationType" to animationType.name))
    // [EN] The host is laid out: the badge is ready (at once when it is, on its first layout otherwise). [CN] 宿主已布局：角标就绪（已布局则立即发出，否则在首次布局时）。
    if (isLaidOut) cylPostBadgeEvent(BadgeEvents.didBecomeReady) else addOnLayoutChangeListener(object : View.OnLayoutChangeListener {
        override fun onLayoutChange(v: View, l: Int, t: Int, r: Int, b: Int, ol: Int, ot: Int, oR: Int, ob: Int) {
            v.removeOnLayoutChangeListener(this)
            v.cylPostBadgeEvent(BadgeEvents.didBecomeReady)
        }
    })
}

/**
 * [EN] Posts a badge moment through CYLDeallocBlockExecutor on this view (`LifecycleRegistry.of(view).addCustomCallback(BadgeEvents.didShow)`,
 *      on the tab button's `CYLTabBarItem` through the forward, or `LifecycleCenter.addCustomCallback` for every badge). [CN] 通过
 *      CYLDeallocBlockExecutor 在本视图上发出角标时机事件（可在本视图、经转发在 Tab 按钮的 `CYLTabBarItem` 上监听，或用 `LifecycleCenter` 监听所有角标）。
 */
internal fun View.cylPostBadgeEvent(name: String, userInfo: Map<String, Any?>? = null) {
    LifecycleRegistry.of(this).postLifecycleEvent(name, userInfo)
}

/**
 * [EN] `-cylClearBadge`: removes the badge. [CN] 移除角标。
 */
fun View.cylClearBadge() {
    val state = cylBadgeState
    val had = state.badge != null
    state.badge?.let { badge -> badge.stopAnimation(); cylDetachBadge(badge) }
    state.badge = null
    state.value = null
    state.paused = false
    if (had) cylPostBadgeEvent(BadgeEvents.didClear)
}

/**
 * [EN] `-cylResumeBadge`: shows a paused badge again. [CN] 重新显示暂停的角标。
 */
fun View.cylResumeBadge() {
    val state = cylBadgeState
    state.paused = false
    state.badge?.visibility = View.VISIBLE
}

/**
 * [EN] `-cylIsPauseBadge`: hidden but kept (e.g. the selected tab with `cyl_hidesBadgeOfSelectedTab`). [CN] 是否暂停（隐藏但保留）。
 */
fun View.cylIsPauseBadge(): Boolean = cylBadgeState.paused

/**
 * [EN] Hides the badge without removing it (the iOS "pause"). [CN] 隐藏但不移除角标（iOS 的“暂停”）。
 */
fun View.cylPauseBadge() {
    val state = cylBadgeState
    state.paused = true
    state.badge?.visibility = View.INVISIBLE
}

/**
 * [EN] `-cylIsHidden`: the view or one of its parents is hidden. [CN] 视图或其父视图是否隐藏。
 */
fun View.cylIsHidden(): Boolean {
    var view: View? = this
    while (view != null) {
        if (view.visibility != View.VISIBLE) return true
        view = view.parent as? View
    }
    return false
}

/**
 * [EN] `-cylGetActualBadgeSuperView`: the parent the badge is added to. [CN] 角标实际添加到的父视图。
 */
fun View.cylGetActualBadgeSuperView(): ViewGroup? = (this as? CYLBadgeHosting)?.cylBadgeAnchorView ?: (parent as? ViewGroup)

/**
 * [EN] A view that names the view its badge is added to (owner answer to the Android extraction question, docs/Animated-Item-Badge-CrossPlatform.md:
 *      the same `CYLBadgeHosting` as iOS, so `:cylbadge` never names a tab bar class). The tab button and the plus button adopt it.
 *      Requirements only; a new member of this released interface is always optional (a default implementation).
 * [CN] 给出其角标所加到的视图的视图（对 Android 抽离问题的回答，见 docs/Animated-Item-Badge-CrossPlatform.md：与 iOS 相同的 `CYLBadgeHosting`，
 *      因此 `:cylbadge` 从不提到 TabBar 的类）。Tab 按钮与加号按钮遵守它。这里只有要求；此接口发布后新增的成员一律是可选的（带默认实现）。
 */
interface CYLBadgeHosting {
    /** [EN] The view the badge is added to. [CN] 角标所加到的视图。 */
    val cylBadgeAnchorView: ViewGroup

    /** [EN] The view the badge is placed against, the icon; default the host itself. [CN] 角标对齐的视图，即图标；默认是宿主自身。 */
    val cylBadgeIconView: View get() = cylBadgeAnchorView

    /**
     * [EN] true: the host places its badge itself in its own layout (the plus button), so the badge gets no margins; default false.
     * [CN] true：宿主在自己的布局中放置角标（加号按钮），因此角标没有外边距；默认 false。
     */
    val cylBadgePlacesBadge: Boolean get() = false
}

/**
 * [EN] `-cylIsReady`: the view is laid out. [CN] 视图已布局。
 */
fun View.cylIsReady(): Boolean = width > 0 && height > 0

/**
 * [EN] `-cylFindBarButtonContentView`: this view (Android bar buttons are plain views). [CN] 本视图（Android 的栏按钮即普通视图）。
 */
fun View.cylFindBarButtonContentView(): View = this

/**
 * [EN] Adds the badge to `host`. A tab button or the plus button holds it as a child. Any other view (an `ImageView`, a
 *      label) cannot, so, as on iOS where the badge is a subview of the view above everything, it goes into the parent's
 *      overlay: drawn above the parent's children, never laid out by the parent (a `LinearLayout` would otherwise place
 *      it after the other children), and moved with the view whenever it is laid out.
 * [CN] 把角标添加到 `host`。Tab 按钮或 PlusButton 把它作为子视图。其他视图（`ImageView`、文字）不能包含子视图，因此与 iOS 角标是视图的子视图、
 *      位于最上层一样，放入父视图的 overlay：绘制在父视图所有子视图之上，不参与父视图的布局（否则 `LinearLayout` 会把它排在其他子视图后面），
 *      并在视图每次布局时跟随移动。
 */
private fun View.cylAttachBadge(badge: CYLBadgeView, host: ViewGroup) {
    val state = cylBadgeState
    if (host === this) {
        if (badge.parent !== host) {
            cylDetachBadge(badge)
            host.addView(badge, ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        }
        return
    }
    if (state.overlayHost !== host) {
        cylDetachBadge(badge)
        host.overlay.add(badge)
        state.overlayHost = host
    }
    if (!state.followsLayout) {
        state.followsLayout = true
        addOnLayoutChangeListener { view, _, _, _, _, _, _, _, _ -> view.cylRefreshBadge() }
    }
}

private fun View.cylDetachBadge(badge: CYLBadgeView) {
    val state = cylBadgeState
    state.overlayHost?.let { overlayHost -> overlayHost.overlay.remove(badge); state.overlayHost = null }
    (badge.parent as? ViewGroup)?.removeView(badge)
}

/**
 * [EN] `-[UIView cyl_layoutBadgeAtTopRightCorner]`: the badge's left and top for an anchor whose top-right corner is
 *      (`anchorRight`, `anchorTop`): its center at (right + 2, top) plus `cylBadgeCenterOffset`, as on iOS.
 * [CN] 锚点右上角为 (`anchorRight`, `anchorTop`) 时角标的 left 与 top：中心位于 (right + 2, top) 再加上 `cylBadgeCenterOffset`，与 iOS 相同。
 */
internal fun cylBadgeOrigin(anchorRight: Int, anchorTop: Int, badge: View, offset: CYLOffset, density: Float): Pair<Int, Int> {
    val left = (anchorRight + CYL_BADGE_CORNER_GAP_DP * density - badge.measuredWidth / 2f + offset.horizontal * density).toInt()
    val top = (anchorTop - badge.measuredHeight / 2f + offset.vertical * density).toInt()
    return left to top
}

/**
 * [EN] iOS puts a badge's center 2 pt right of its host's right edge. [CN] iOS 把角标中心放在宿主右边缘右侧 2 pt 处。
 */
internal const val CYL_BADGE_CORNER_GAP_DP = 2f

/**
 * [EN] `-cylRefreshBadge`: places the badge at the top-right corner plus `cylBadgeCenterOffset`. [CN] 把角标放到右上角并加上偏移。
 */
fun View.cylRefreshBadge() {
    val state = cylBadgeState
    val badge = state.badge ?: return
    badge.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED)
    val density = resources.displayMetrics.density
    state.overlayHost?.let {
        // [EN] In the parent's overlay: the view's top-right corner in the parent's coordinates. [CN] 在父视图的 overlay 中：视图右上角在父视图中的坐标。
        val (left, top) = cylBadgeOrigin(right, top, badge, state.centerOffset, density)
        badge.layout(left, top, left + badge.measuredWidth, top + badge.measuredHeight)
        return
    }
    val host = badge.parent as? ViewGroup ?: return
    val anchor = (this as? CYLBadgeHosting)?.cylBadgeIconView ?: this
    val anchorRight = if (host === this) anchor.right else right
    val anchorTop = if (host === this) anchor.top else top
    // [EN] The plus button places its badge itself (the host's own layout, `cylBadgePlacesBadge`), with no margins: margins make the FrameLayout
    //      measure itself around the badge, so each new badge value widened the button by half a badge and stretched its image.
    // [CN] PlusButton 自己放置角标（`CYLPlusButton.onLayout`），不使用 margin：margin 会让 FrameLayout 把角标计入自身尺寸，每次角标变化都会把按钮
    //      加宽半个角标并拉伸图片。
    if (host is CYLBadgeHosting && host.cylBadgePlacesBadge) {
        (badge.layoutParams as? ViewGroup.MarginLayoutParams)?.let { params -> params.setMargins(0, 0, 0, 0); badge.layoutParams = params }
        host.requestLayout()
        badge.bringToFront()
        return
    }
    val params = badge.layoutParams as? FrameLayout.LayoutParams ?: FrameLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)
    params.leftMargin = (anchorRight - badge.measuredWidth / 2 + state.centerOffset.horizontal * density).toInt()
    params.topMargin = (anchorTop - badge.measuredHeight / 2 + state.centerOffset.vertical * density).toInt()
    if (host is FrameLayout) badge.layoutParams = params
    else badge.layout(params.leftMargin, params.topMargin, params.leftMargin + badge.measuredWidth, params.topMargin + badge.measuredHeight)
    badge.bringToFront()
}

/**
 * [EN] `-cylResetBadgeAppearance`: drops the values set on this view, so it follows `CYLBadgeAppearance` again. [CN] 清除本视图上设置的值，重新跟随 `CYLBadgeAppearance`。
 */
fun View.cylResetBadgeAppearance() {
    val state = cylBadgeState
    state.explicitBackgroundColor = null; state.explicitTextColor = null; state.explicitBorderColor = null; state.explicitBorderWidth = null
    state.explicitRadius = null; state.explicitCornerRadius = null; state.explicitFont = null; state.explicitMargin = null; state.explicitCenterOffset = null
    state.explicitMaximumBadgeNumber = null
    state.value?.let { cylShowBadgeValue(it, CYLEnums.CYLBadgeAnimationType.None) }
}

// MARK: - CYLBadgeProtocol properties 属性

var View.cylBadgeBackgroundColor: Int
    get() = cylBadgeState.backgroundColor
    set(value) { cylBadgeState.backgroundColor = value; cylBadge?.badgeBackgroundColor = value; cylBadge?.invalidate() }
var View.cylBadgeTextColor: Int
    get() = cylBadgeState.textColor
    set(value) { cylBadgeState.textColor = value; cylBadge?.badgeTextColor = value; cylBadge?.invalidate() }
var View.cylBadgeBorderColor: Int?
    get() = cylBadgeState.borderColor
    set(value) { cylBadgeState.borderColor = value; cylBadge?.badgeBorderColor = value; cylBadge?.invalidate() }
var View.cylBadgeBorderWidth: Float
    get() = cylBadgeState.borderWidth
    set(value) { cylBadgeState.borderWidth = value; cylBadge?.badgeBorderWidth = value; cylBadge?.invalidate() }
var View.cylBadgeFont: CYLFont
    get() = cylBadgeState.font
    set(value) { cylBadgeState.font = value; cylBadge?.badgeFont = value; cylBadge?.requestLayout() }
var View.cylBadgeCenterOffset: CYLOffset
    get() = cylBadgeState.centerOffset
    set(value) { cylBadgeState.centerOffset = value; cylRefreshBadge() }
var View.cylBadgeAnimationType: CYLEnums.CYLBadgeAnimationType
    get() = cylBadgeState.animationType
    set(value) { cylBadgeState.animationType = value }
var View.cylBadgeMaximumBadgeNumber: Int
    get() = cylBadgeState.maximumBadgeNumber
    set(value) { cylBadgeState.maximumBadgeNumber = value; cylBadgeState.value?.let { cylShowBadgeValue(it, CYLEnums.CYLBadgeAnimationType.None) } }
var View.cylBadgeRadius: Float
    get() = cylBadgeState.radius
    set(value) { cylBadgeState.radius = value; cylBadge?.badgeRadius = value; cylBadge?.requestLayout() }
var View.cylBadgeMargin: Float
    get() = cylBadgeState.margin
    set(value) { cylBadgeState.margin = value; cylBadge?.badgeMargin = value; cylBadge?.requestLayout() }
var View.cylBadgeCornerRadius: Float?
    get() = cylBadgeState.cornerRadius
    set(value) { cylBadgeState.cornerRadius = value; cylBadge?.badgeCornerRadius = value; cylBadge?.invalidate() }
var View.cylBadgeRespectsReduceMotion: Boolean
    get() = cylBadgeState.respectsReduceMotion
    set(value) { cylBadgeState.respectsReduceMotion = value }
var View.cylBadgeHostReplacedByIconView: Boolean
    get() = cylBadgeState.hostReplacedByIconView
    set(value) { cylBadgeState.hostReplacedByIconView = value }
var View.cylKeepShowingPlusButtonLabel: Boolean
    get() = cylBadgeState.keepShowingPlusButtonLabel
    set(value) { cylBadgeState.keepShowingPlusButtonLabel = value }
/**
 * [EN] `cylDelayIfNeededForSeconds`: iOS delays the badge until the tab bar is laid out; Android lays out synchronously, so the value is kept only. [CN] iOS 延迟到 TabBar 布局完成；Android 同步布局，只保存该值。
 */
var View.cylDelayIfNeededForSeconds: Double
    get() = cylBadgeState.delayIfNeededForSeconds
    set(value) { cylBadgeState.delayIfNeededForSeconds = value }
/**
 * [EN] `cylBadgeFrame`: the badge's frame in its parent, in px. [CN] 角标在父视图中的位置（px）。
 */
val View.cylBadgeFrame: RectF
    get() = cylBadge?.let { RectF(it.left.toFloat(), it.top.toFloat(), it.right.toFloat(), it.bottom.toFloat()) } ?: RectF()
