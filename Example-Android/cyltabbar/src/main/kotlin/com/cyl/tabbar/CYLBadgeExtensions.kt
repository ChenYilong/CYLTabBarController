// [EN] The method names are the iOS names on purpose (`cyl_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`），见 docs/Android-API-Map.md。
// [EN] kotlin:S1133: the deprecated members are the twins of deprecated iOS API, kept until iOS removes them. [CN] kotlin:S1133：已废弃的成员与 iOS 已废弃的 API 对应，在 iOS 移除前保留。
@file:Suppress("FunctionName", "kotlin:S100", "kotlin:S1133")

package com.cyl.tabbar

import android.app.AlertDialog
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.AbsListView
import android.widget.BaseAdapter
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import androidx.annotation.ColorInt
import androidx.fragment.app.Fragment

/*
 * [EN] The rest of the badge component (`CYLBadgeView` subspec): the app-wide appearance (#425), the text-displaying
 *      protocol and `CYLTabBarBadgeView`, badges on menu items (bar buttons), tab items and controls, the badge samples of
 *      the demos (rows, a sample table, a navigation badge) and the memory warning check (#426).
 * [CN] 角标组件（`CYLBadgeView` 子库）的其余部分：App 级外观（#425）、文字显示协议与 `CYLTabBarBadgeView`、菜单项（栏按钮）、Tab item 与控件上的
 *      角标、Demo 的角标示例（行、示例列表、导航栏角标）以及内存警告检查（#426）。
 */

/**
 * [EN] `CYLBadgeAppearance` (#425): the app-wide default badge style. A value set on a view wins over it; it wins over the
 *      built-in default. Badges shown later use the new defaults.
 * [CN] `CYLBadgeAppearance`（#425）：App 级默认角标样式。视图上设置的值优先于它，它优先于内置默认值。之后显示的角标使用新的默认值。
 */
// [EN] kotlin:S6515: a class with one shared instance on purpose, as iOS `+[CYLBadgeAppearance appearance]`; the instance type stays public API. [CN] kotlin:S6515：刻意为只有一个共享实例的类，与 iOS `+[CYLBadgeAppearance appearance]` 相同；实例类型是公开 API。
@Suppress("kotlin:S6515")
class CYLBadgeAppearance private constructor() {
    /** [EN] Background color, red by default (`reset()` restores it). [CN] 背景色，默认红色（`reset()` 恢复）。 */
    @ColorInt var backgroundColor: Int = Color.RED
    /** [EN] Text color, white by default. [CN] 文字颜色，默认白色。 */
    @ColorInt var textColor: Int = Color.WHITE
    /** [EN] Text font, bold 9 sp by default, as on iOS. [CN] 字体，默认粗体 9 sp，与 iOS 相同。 */
    var font: CYLFont = DEFAULT_FONT
    /** [EN] Offset of the badge center from the host's top-right corner (dp); not finite: 0. [CN] 角标中心相对宿主右上角的偏移（dp）；非有限值视为 0。 */
    var centerOffset: CYLOffset = CYLOffset.zero
        set(value) { field = CYLOffset(value.horizontal.takeIf { it.isFinite() } ?: 0f, value.vertical.takeIf { it.isFinite() } ?: 0f) }
    /** [EN] Radius of the red dot (dp); 0, negative or not finite restores 4. [CN] 红点半径（dp）；0、负数或非有限值恢复为 4。 */
    var radius: Float = DEFAULT_RADIUS
        set(value) { field = if (value > 0 && value.isFinite()) value else DEFAULT_RADIUS }
    /** [EN] Space added once to the text's width and height in number and text badges (dp), 8 by default as on iOS; negative or not finite: 0. [CN] 数字与文字角标在文字宽度与高度上各加一次的边距（dp），默认 8，与 iOS 相同；负数或非有限值视为 0。 */
    var margin: Float = DEFAULT_MARGIN
        set(value) { field = if (value.isFinite()) value.coerceAtLeast(0f) else 0f }
    /** [EN] Numbers above it show as "<maximum>+"; below 1: 1. [CN] 超过它的数字显示为 "<maximum>+"；小于 1 时为 1。 */
    var maximumBadgeNumber: Int = 99
        set(value) { field = value.coerceAtLeast(1) }
    /** [EN] Corner radius of number and text badges (dp); 0 means a capsule. [CN] 数字与文字角标的圆角（dp）；0 表示胶囊形。 */
    var cornerRadius: Float = 0f
        set(value) { field = if (value.isFinite()) value.coerceAtLeast(0f) else 0f }
    /** [EN] Border color, drawn only when `borderWidth` > 0. [CN] 边框颜色，`borderWidth` > 0 时才绘制。 */
    @ColorInt var borderColor: Int? = null
    /** [EN] Border width (dp); negative or not finite: 0. [CN] 边框宽度（dp）；负数或非有限值视为 0。 */
    var borderWidth: Float = 0f
        set(value) { field = if (value.isFinite()) value.coerceAtLeast(0f) else 0f }

    /** [EN] `-reset`: every property back to its built-in default. [CN] 把所有属性恢复为内置默认值。 */
    fun reset() {
        backgroundColor = Color.RED; textColor = Color.WHITE; font = DEFAULT_FONT; centerOffset = CYLOffset.zero
        radius = DEFAULT_RADIUS; margin = DEFAULT_MARGIN; maximumBadgeNumber = 99; cornerRadius = 0f; borderColor = null; borderWidth = 0f
    }

    companion object {
        // [EN] iOS `kCYLBadgeDefaultFont` (bold 9 pt) and `CYLBadgeAppearance`'s margin, 8 pt. [CN] iOS 的 `kCYLBadgeDefaultFont`（粗体 9 pt）与 `CYLBadgeAppearance` 的边距 8 pt。
        private val DEFAULT_FONT = CYLFont(9f, bold = true)
        private const val DEFAULT_RADIUS = 4f
        private const val DEFAULT_MARGIN = 8f
        /** [EN] The shared global appearance. [CN] 共享的全局外观。 */
        @JvmStatic
        val globalAppearance: CYLBadgeAppearance = CYLBadgeAppearance()
    }
}

/** [EN] `CYLBadgeTextDisplaying`: what a badge's text view provides. [CN] 角标文字视图提供的能力。 */
interface CYLBadgeTextDisplaying {
    var text: String?
    var font: CYLFont
    @get:ColorInt @setparam:ColorInt
    var textColor: Int
    /** [EN] `textAlignment` as a horizontal `Gravity`. [CN] 以水平 `Gravity` 表示的 `textAlignment`。 */
    var textGravity: Int
}

/** [EN] `UILabel (CYLBadgeTextDisplaying)`: a TextView seen as `CYLBadgeTextDisplaying`. [CN] 把 TextView 视为 `CYLBadgeTextDisplaying`。 */
class CYLTextViewBadgeTextDisplaying(val textView: TextView) : CYLBadgeTextDisplaying {
    override var text: String?
        get() = textView.text?.toString()
        set(value) { textView.text = value }
    override var font: CYLFont = CYLFont(
        if (android.os.Build.VERSION.SDK_INT >= 34) android.util.TypedValue.deriveDimension(android.util.TypedValue.COMPLEX_UNIT_SP, textView.textSize, textView.resources.displayMetrics)
        else textView.textSize / textView.resources.displayMetrics.density
    )
        set(value) {
            field = value
            textView.textSize = value.size
            textView.typeface = value.typeface ?: if (value.bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        }
    override var textColor: Int
        get() = textView.currentTextColor
        set(value) = textView.setTextColor(value)
    override var textGravity: Int
        get() = textView.gravity and Gravity.HORIZONTAL_GRAVITY_MASK
        set(value) { textView.gravity = value or Gravity.CENTER_VERTICAL }
}

/** [EN] `TextView` as `CYLBadgeTextDisplaying` (`UILabel (CYLBadgeTextDisplaying)`). [CN] 把 TextView 作为 `CYLBadgeTextDisplaying`。 */
fun TextView.cyl_badgeTextDisplaying(): CYLBadgeTextDisplaying = CYLTextViewBadgeTextDisplaying(this)

/**
 * [EN] `CYLTabBarBadgeView`: a badge view made of a label (`badgeLabel`) inside `badgeContentInset`, for a custom badge.
 * [CN] `CYLTabBarBadgeView`：由 `badgeContentInset` 内的标签（`badgeLabel`）组成的角标视图，用于自定义角标。
 */
open class CYLTabBarBadgeView(context: Context) : FrameLayout(context), CYLBadgeTextDisplaying {
    /** [EN] The label that draws the badge text. [CN] 绘制角标文字的标签。 */
    val badgeLabel: TextView = TextView(context).apply { gravity = Gravity.CENTER; maxLines = 1; setTextColor(Color.WHITE); textSize = 11f }
    /** [EN] The insets around the label (dp). [CN] 标签周围的边距（dp）。 */
    var badgeContentInset: CYLEdgeInsets = CYLEdgeInsets(0f, 4f, 0f, 4f)
        set(value) { field = value; applyInset() }
    private val adapter = CYLTextViewBadgeTextDisplaying(badgeLabel)

    init {
        background = GradientDrawable().apply { setColor(CYLBadgeAppearance.globalAppearance.backgroundColor); cornerRadius = 999f }
        addView(badgeLabel, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT, Gravity.CENTER))
        applyInset()
    }

    private fun applyInset() {
        val density = resources.displayMetrics.density
        setPadding((badgeContentInset.left * density).toInt(), (badgeContentInset.top * density).toInt(), (badgeContentInset.right * density).toInt(), (badgeContentInset.bottom * density).toInt())
    }

    /** [EN] Default centered. [CN] 默认居中。 */
    override var textGravity: Int by adapter::textGravity
    /** [EN] Default white. [CN] 默认白色。 */
    override var textColor: Int by adapter::textColor
    override var text: String? by adapter::text
    override var font: CYLFont by adapter::font
}

// MARK: - UIControl (CYLBadgeExtention): Android controls are views, see the View extensions in CYLBadge.kt.

// MARK: - UITabBarItem (CYLBadgeExtention)

/** [EN] `-[UITabBarItem cyl_isShowBadge]`: the badge of the item's tab button. [CN] item 的 Tab 按钮上的角标是否显示。 */
fun CYLTabBarItem.cyl_isShowBadge(): Boolean = cyl_visiableTabButton?.cyl_isShowBadge() ?: false
fun CYLTabBarItem.cyl_showBadge() { cyl_visiableTabButton?.cyl_showBadge() }
fun CYLTabBarItem.cyl_showBadgeValue(value: String, animationType: CYLEnums.CYLBadgeAnimationType) { cyl_visiableTabButton?.cyl_showBadgeValue(value, animationType) }
fun CYLTabBarItem.cyl_clearBadge() { cyl_visiableTabButton?.cyl_clearBadge() }
fun CYLTabBarItem.cyl_resumeBadge() { cyl_visiableTabButton?.cyl_resumeBadge() }
fun CYLTabBarItem.cyl_isPauseBadge(): Boolean = cyl_visiableTabButton?.cyl_isPauseBadge() ?: false

// MARK: - UIBarButtonItem (CYLBadgeExtention): menu items of a Toolbar 工具栏菜单项

/** [EN] The view of a menu item in a visible toolbar: its action view, else its button in an `ActionMenuView`. [CN] 菜单项在可见工具栏中的视图：其 action view，否则为 `ActionMenuView` 中的按钮。 */
fun MenuItem.cyl_findBarButtonContentView(): View? {
    actionView?.let { return it }
    for (controller in CYLTabBarController.cyl_liveTabBarControllers()) {
        controller.activity.window?.decorView?.let { root -> findMenuItemView(root, this)?.let { return it } }
    }
    return null
}

private fun findMenuItemView(view: View, item: MenuItem): View? {
    if (CYLReflection.call(view, "getItemData") === item) return view
    val group = view as? ViewGroup ?: return null
    for (index in 0 until group.childCount) findMenuItemView(group.getChildAt(index), item)?.let { return it }
    return null
}

/** [EN] Runs `action` on the item's view, now or once the toolbar laid it out (a few frames). [CN] 在菜单项的视图上执行 `action`，立即或等工具栏布局后。 */
private fun MenuItem.withBarButtonView(attempts: Int = 10, action: (View) -> Unit) {
    val view = cyl_findBarButtonContentView()
    if (view != null) return action(view)
    if (attempts <= 0) return
    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({ withBarButtonView(attempts - 1, action) }, 50)
}

fun MenuItem.cyl_isShowBadge(): Boolean = cyl_findBarButtonContentView()?.cyl_isShowBadge() ?: false
fun MenuItem.cyl_showBadge() = withBarButtonView { it.cyl_showBadge() }
fun MenuItem.cyl_showBadgeValue(value: String, animationType: CYLEnums.CYLBadgeAnimationType) = withBarButtonView { it.cyl_showBadgeValue(value, animationType) }
/** [EN] `-cyl_showBadgeValue:animationType:backgroundColor:`: null keeps the default color. [CN] null 保持默认颜色。 */
fun MenuItem.cyl_showBadgeValue(value: String, animationType: CYLEnums.CYLBadgeAnimationType, @ColorInt backgroundColor: Int?) = withBarButtonView { view ->
    backgroundColor?.let { view.cyl_badgeBackgroundColor = it }
    view.cyl_showBadgeValue(value, animationType)
}
fun MenuItem.cyl_clearBadge() { cyl_findBarButtonContentView()?.cyl_clearBadge() }
fun MenuItem.cyl_resumeBadge() { cyl_findBarButtonContentView()?.cyl_resumeBadge() }
fun MenuItem.cyl_isPauseBadge(): Boolean = cyl_findBarButtonContentView()?.cyl_isPauseBadge() ?: false

// MARK: - The badge samples (UITableViewCell (CYLBadgeExtention)) 角标示例

/** [EN] `CYLBadgeRowHeight`: a row height that leaves room around the icon for its badge (dp). [CN] 为图标的角标留出空间的行高（dp）。 */
const val CYLBadgeRowHeight: Float = 60f

private data class CYLBadgeSample(
    val title: String,
    val api: String?,
    val value: String,
    val animationType: CYLEnums.CYLBadgeAnimationType = CYLEnums.CYLBadgeAnimationType.None,
    val repeats: Int = 0,
    val maximum: Int? = null,
    val colors: Boolean = false,
    val font: Boolean = false,
    val border: Boolean = false,
    val radius: Float? = null,
    val margin: Float? = null,
    val cornerRadius: Float? = null,
    val reduceMotion: Boolean = false,
    val position: String? = null,
    /** [EN] An iOS factory animation (`CYLBadgeHelperAnimation`) that no `CYLBadgeAnimationType` matches. [CN] 没有对应 `CYLBadgeAnimationType` 的 iOS 工厂动画（`CYLBadgeHelperAnimation`）。 */
    val factory: ((CYLBadgeView) -> android.animation.Animator)? = null,
)

/** [EN] `cyl_rotationAnimationWithDuration:2 degree:2π direction:CYLAxisZ repeatCount:HUGE_VALF`: a full turn in the screen plane every 2 s. [CN] 每 2 秒在屏幕平面内转一整圈。 */
private val CYLBadgeRotationForever: (CYLBadgeView) -> android.animation.Animator = { badge ->
    android.animation.ObjectAnimator.ofFloat(badge, View.ROTATION, 0f, 360f).setDuration(2000).apply {
        repeatCount = android.animation.ObjectAnimator.INFINITE
        interpolator = android.view.animation.LinearInterpolator()
    }
}

/** [EN] `cyl_rotationAnimationWithDuration:1 degree:π direction:CYLAxisY repeatCount:2`: half a turn around the vertical axis, twice. [CN] 绕竖直轴转半圈，共两次。 */
private val CYLBadgeFlipTwice: (CYLBadgeView) -> android.animation.Animator = { badge ->
    android.animation.ObjectAnimator.ofFloat(badge, View.ROTATION_Y, 0f, 180f).setDuration(1000).apply { repeatCount = 1 }
}

/** [EN] Every badge style and animation, in the order of the iOS samples. [CN] 每种角标样式与动画，顺序与 iOS 示例相同。 */
private val CYLBadgeSamples: List<CYLBadgeSample> = run {
    listOf(
        CYLBadgeSample("Scale (forever)", "CYLBadgeAnimationTypeScale", "3", CYLEnums.CYLBadgeAnimationType.Scale),
        CYLBadgeSample("Shake (forever)", "CYLBadgeAnimationTypeShake", "3", CYLEnums.CYLBadgeAnimationType.Shake),
        CYLBadgeSample("Bounce (forever)", "CYLBadgeAnimationTypeBounce", "3", CYLEnums.CYLBadgeAnimationType.Bounce),
        CYLBadgeSample("Breathe (forever)", "CYLBadgeAnimationTypeBreathe", "", CYLEnums.CYLBadgeAnimationType.Breathe),
        CYLBadgeSample("Shake, stops with Reduce Motion", "cyl_badgeRespectsReduceMotion", "3", CYLEnums.CYLBadgeAnimationType.Shake, reduceMotion = true),
        CYLBadgeSample("Rotation (forever)", "cyl_rotationAnimationWithDuration:", "new", factory = CYLBadgeRotationForever),
        CYLBadgeSample("Spring (forever)", "cyl_springAnimationForDuration:", "3", CYLEnums.CYLBadgeAnimationType.ScaleOnce, repeats = -1),
        CYLBadgeSample("Shake ×3 (cyl_shakeAnimationRepeatTimes)", null, "3", CYLEnums.CYLBadgeAnimationType.Shake, repeats = 3),
        CYLBadgeSample("Bounce ×3 (cyl_bounceAnimationRepeatTimes)", null, "3", CYLEnums.CYLBadgeAnimationType.Bounce, repeats = 3),
        CYLBadgeSample("Scale ×3", "cyl_scaleAnimationFromScale:", "3", CYLEnums.CYLBadgeAnimationType.Scale, repeats = 3),
        CYLBadgeSample("Blink ×3", "cyl_opacityTimesAnimationRepeatTimes:", "", CYLEnums.CYLBadgeAnimationType.Breathe, repeats = 3),
        CYLBadgeSample("Flip ×2", "cyl_rotationAnimationWithDuration:", "3", factory = CYLBadgeFlipTwice),
        CYLBadgeSample("Left to right once", "CYLBadgeAnimationTypeLeftRightOnce", "3", CYLEnums.CYLBadgeAnimationType.LeftRightOnce),
        CYLBadgeSample("Right to left once", "CYLBadgeAnimationTypeRightLeftOnce", "3", CYLEnums.CYLBadgeAnimationType.RightLeftOnce),
        CYLBadgeSample("Fade in once", "CYLBadgeAnimationTypeFadeInOnce", "3", CYLEnums.CYLBadgeAnimationType.FadeInOnce),
        CYLBadgeSample("Rolling once", "CYLBadgeAnimationTypeRollingOnce", "3", CYLEnums.CYLBadgeAnimationType.RollingOnce),
        CYLBadgeSample("Scale once", "CYLBadgeAnimationTypeScaleOnce", "3", CYLEnums.CYLBadgeAnimationType.ScaleOnce),
        CYLBadgeSample("Spring once", "cyl_springAnimationForDuration:", "3", CYLEnums.CYLBadgeAnimationType.ScaleOnce),
        CYLBadgeSample("Red dot", "cyl_showBadge", ""),
        CYLBadgeSample("Number", "cyl_showBadgeValue:", "8"),
        CYLBadgeSample("Number above maximum", "cyl_badgeMaximumBadgeNumber", "100"),
        CYLBadgeSample("Custom maximum (9)", "cyl_badgeMaximumBadgeNumber", "10", maximum = 9),
        CYLBadgeSample("New", "cyl_showBadgeValue:@\"new\"", "new"),
        CYLBadgeSample("NEW", "cyl_showBadgeValue:@\"NEW\"", "NEW"),
        CYLBadgeSample("Other text", "cyl_showBadgeValue:", "hot"),
        CYLBadgeSample("Custom colors", "cyl_badgeBackgroundColor / cyl_badgeTextColor", "5", colors = true),
        CYLBadgeSample("Custom font", "cyl_badgeFont", "5", font = true),
        CYLBadgeSample("Border", "cyl_badgeBorderColor / cyl_badgeBorderWidth", "5", border = true),
        CYLBadgeSample("Border following Dark Mode", "cyl_badgeBorderColor", "5", border = true),
        CYLBadgeSample("Red dot radius", "cyl_badgeRadius", "", radius = 6f),
        CYLBadgeSample("Margin", "cyl_badgeMargin", "5", margin = 7f),
        CYLBadgeSample("Corner radius", "cyl_badgeCornerRadius", "new", cornerRadius = 3f),
        CYLBadgeSample("Top left", "cyl_badgeCenterOffset", "5", position = "topLeft"),
        CYLBadgeSample("Bottom left", "cyl_badgeCenterOffset", "5", position = "bottomLeft"),
        CYLBadgeSample("Bottom right", "cyl_badgeCenterOffset", "5", position = "bottomRight"),
    )
}

private fun sampleForRow(row: Int) = CYLBadgeSamples[row.coerceAtLeast(0) % CYLBadgeSamples.size]

/** [EN] `+cyl_badgeTitleForRow:`: "<row + 1>. <title> (<API>)". [CN] 第 row 行示例的标题与核心 API。 */
fun cyl_badgeTitleForRow(row: Int): String {
    val sample = sampleForRow(row)
    val title = if (sample.api != null && !sample.title.contains(sample.api)) "${sample.title} (${sample.api})" else sample.title
    return "${row + 1}. $title"
}

/** [EN] `+cyl_badgeStyleCount`: the number of samples. [CN] 示例数量。 */
fun cyl_badgeStyleCount(): Int = CYLBadgeSamples.size

/**
 * [EN] `-cyl_showBadgeForRow:` on the row's icon view: shows the sample icon and the row's badge (style and animation change
 *      with the row). Rows are reused: the previous badge and options are cleared first.
 * [CN] 在行的图标视图上显示示例图标与该行的角标（样式与动画随行变化）。行会复用：先清除之前的角标与选项。
 */
/**
 * [EN] `+cyl_badgeIcon`: the sample icon of the badge rows, the library's `cyl_badge_sample_icon` (the iOS resource bundle's
 *      image) with 6 dp rounded corners on a 30 dp square, as on iOS; a blue square if the image cannot be decoded.
 * [CN] `+cyl_badgeIcon`：角标示例行的图标，即库自带的 `cyl_badge_sample_icon`（iOS 资源 bundle 中的图片），在 30 dp 正方形上带 6 dp 圆角，
 *      与 iOS 相同；图片无法解码时为蓝色方块。
 */
fun cyl_badgeIcon(view: View): android.graphics.drawable.Drawable {
    val density = view.resources.displayMetrics.density
    val bitmap = android.graphics.BitmapFactory.decodeResource(view.resources, R.drawable.cyl_badge_sample_icon)
        ?: return GradientDrawable().apply { cornerRadius = 6 * density; setColor(Color.rgb(0, 122, 255)); setSize((30 * density).toInt(), (30 * density).toInt()) }
    return androidx.core.graphics.drawable.RoundedBitmapDrawableFactory.create(view.resources, bitmap).apply {
        cornerRadius = bitmap.width * 6f / 30f
        setAntiAlias(true)
    }
}

fun ImageView.cyl_showBadgeForRow(row: Int) {
    val sample = sampleForRow(row)
    val density = resources.displayMetrics.density
    setImageDrawable(cyl_badgeIcon(this))
    // [EN] The badge rises above the icon, past the row's top while it animates: neither the row nor the list clips it (iOS: `clipsToBounds = NO`). [CN] 角标凸出图标，动画时会超出行的顶部：行与列表都不裁剪它（iOS：`clipsToBounds = NO`）。
    (parent as? ViewGroup)?.let { row -> row.clipChildren = false; (row.parent as? ViewGroup)?.clipChildren = false }
    cyl_clearBadge()
    cyl_resetBadgeAppearance()
    applyBadgeSample(sample)
    cyl_showBadgeValue(sample.value, if (sample.repeats == 0) sample.animationType else CYLEnums.CYLBadgeAnimationType.None)
    if (sample.repeats != 0) repeatBadgeSampleAnimation(sample)
    sample.factory?.let { factory -> cyl_badge?.let { badge -> badge.playAnimator(factory(badge)) } }
}

/** [EN] The appearance options of a sample row. [CN] 示例行的外观选项。 */
private fun ImageView.applyBadgeSample(sample: CYLBadgeSample) {
    if (sample.colors) { cyl_badgeBackgroundColor = Color.rgb(128, 0, 128); cyl_badgeTextColor = Color.YELLOW }
    if (sample.font) cyl_badgeFont = CYLFont(12f, Typeface.create(Typeface.DEFAULT, Typeface.ITALIC))
    if (sample.border) {
        val dark = (resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) == android.content.res.Configuration.UI_MODE_NIGHT_YES
        cyl_badgeBorderColor = if (sample.title.contains("Dark")) (if (dark) Color.WHITE else Color.BLACK) else Color.WHITE
        cyl_badgeBorderWidth = 2f
    }
    sample.position?.let { position ->
        val toLeft = -(30f + 4f)
        cyl_badgeCenterOffset = when (position) { "topLeft" -> CYLOffset(toLeft, 0f); "bottomLeft" -> CYLOffset(toLeft, 30f); else -> CYLOffset(0f, 30f) }
    }
    sample.radius?.let { cyl_badgeRadius = it }
    sample.margin?.let { cyl_badgeMargin = it }
    sample.cornerRadius?.let { cyl_badgeCornerRadius = it }
    sample.maximum?.let { cyl_badgeMaximumBadgeNumber = it }
    cyl_badgeRespectsReduceMotion = sample.reduceMotion
}

/** [EN] The CAAnimation factory samples: the same animation, repeated a few times or forever. [CN] CAAnimation 工厂示例：同一动画重复几次或一直重复。 */
private fun ImageView.repeatBadgeSampleAnimation(sample: CYLBadgeSample) {
    val badge = cyl_badge ?: return
    var left = sample.repeats
    fun again() {
        badge.play(sample.animationType)
        if (left < 0 || --left > 0) badge.postDelayed({ if (badge.isAttachedToWindow) again() }, 1000)
    }
    again()
}

/** [EN] `-cyl_wrapsTextLabels`: the row's texts wrap onto as many lines as they need, never ellipsized. [CN] 行中的文字按需换行，不省略。 */
fun View.cyl_wrapsTextLabels() {
    if (this is TextView) { maxLines = Int.MAX_VALUE; ellipsize = null; setSingleLine(false) }
    (this as? ViewGroup)?.let { group -> for (index in 0 until group.childCount) group.getChildAt(index).cyl_wrapsTextLabels() }
}

/** [EN] `+cyl_setUpAutomaticRowHeightForTableView:`: rows as high as their text, at least `CYLBadgeRowHeight`. [CN] 行高随文字变化，至少为 `CYLBadgeRowHeight`。 */
fun cyl_setUpAutomaticRowHeightForTableView(listView: AbsListView) {
    val minimum = (CYLBadgeRowHeight * listView.resources.displayMetrics.density).toInt()
    listView.setRecyclerListener { it.minimumHeight = minimum }
    listView.setOnHierarchyChangeListener(object : ViewGroup.OnHierarchyChangeListener {
        override fun onChildViewAdded(parent: View?, child: View?) { child?.minimumHeight = minimum }
        override fun onChildViewRemoved(parent: View?, child: View?) { /* [EN] Nothing to undo. [CN] 无需处理。 */ }
    })
}

// MARK: - UIViewController (CYLNavigationBadge)

/**
 * [EN] `-cyl_showNavigationBadgeValue:animationType:backgroundColor:`: shows `value` ("" a red dot) on the last action item of
 *      the activity's toolbar; without one, a bell item (no action) is added first. Returns the item, or null without a toolbar.
 * [CN] 在 Activity 工具栏的最后一个菜单项上显示 `value`（"" 为红点）；没有时先添加一个铃铛菜单项（无动作）。返回该菜单项；没有工具栏时为 null。
 */
fun Fragment.cyl_showNavigationBadgeValue(value: String, animationType: CYLEnums.CYLBadgeAnimationType, @ColorInt backgroundColor: Int?): MenuItem? {
    val root = activity?.window?.decorView ?: return null
    val toolbar = findToolbar(root) ?: return null
    val menu = toolbar.menu
    val item = (0 until menu.size()).map { menu.getItem(it) }.lastOrNull { it.isVisible }
        ?: menu.add(android.view.Menu.NONE, View.generateViewId(), android.view.Menu.NONE, "Badge").apply {
            setIcon(android.R.drawable.ic_popup_reminder)
            setShowAsAction(MenuItem.SHOW_AS_ACTION_IF_ROOM)
        }
    item.cyl_showBadgeValue(value, animationType, backgroundColor)
    return item
}

private fun findToolbar(view: View): androidx.appcompat.widget.Toolbar? {
    if (view is androidx.appcompat.widget.Toolbar) return view
    val group = view as? ViewGroup ?: return null
    for (index in 0 until group.childCount) findToolbar(group.getChildAt(index))?.let { return it }
    return null
}

// MARK: - CYLBadgeHelperTableViewController

/**
 * [EN] `CYLBadgeHelperTableViewController`: a list of every badge sample, one per row, after a memory warning row. Tap a
 *      sample to clear its badge; the tap also simulates a memory warning and logs the tab bar's state.
 * [CN] 列出每个角标示例（每行一个），前面是内存警告行。点击示例清除其角标，同时模拟内存警告并输出 TabBar 的状态。
 */
open class CYLBadgeHelperTableViewController : Fragment() {
    /** [EN] Called after a row is tapped: section 0 the settings row, section 1 the samples. [CN] 点击行之后调用：section 0 为设置行，section 1 为示例。 */
    var didSelectRowHandler: ((section: Int, row: Int) -> Unit)? = null

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val list = ListView(context)
        cyl_setUpAutomaticRowHeightForTableView(list)
        list.adapter = object : BaseAdapter() {
            override fun getCount() = 1 + cyl_badgeStyleCount()
            override fun getItem(position: Int): Any = position
            override fun getItemId(position: Int) = position.toLong()
            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                if (position == 0) return cyl_memoryWarningCellForTableView(parent)
                val row = (convertView?.takeIf { it.tag == "badge" } as? LinearLayout) ?: badgeRow(context)
                (row.getChildAt(0) as ImageView).cyl_showBadgeForRow(position - 1)
                (row.getChildAt(1) as TextView).text = cyl_badgeTitleForRow(position - 1)
                return row
            }
        }
        list.setOnItemClickListener { _, row, position, _ ->
            if (position == 0) {
                cyl_simulateMemoryWarningAndShowResult()
                didSelectRowHandler?.invoke(0, 0)
                return@setOnItemClickListener
            }
            ((row as? LinearLayout)?.getChildAt(0))?.cyl_clearBadge()
            CYLTabBarController.cyl_simulateMemoryWarning()
            didSelectRowHandler?.invoke(1, position - 1)
        }
        return list
    }

    private fun badgeRow(context: Context): LinearLayout {
        val density = context.resources.displayMetrics.density
        return LinearLayout(context).apply {
            tag = "badge"
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            clipChildren = false
            setPadding((16 * density).toInt(), 0, (16 * density).toInt(), 0)
            addView(ImageView(context), LinearLayout.LayoutParams((30 * density).toInt(), (30 * density).toInt()).apply { marginEnd = (16 * density).toInt() })
            addView(TextView(context).apply { textSize = 15f }, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
            cyl_wrapsTextLabels()
        }
    }
}

/** [EN] `-cyl_addBadgeHelperTable`: adds a `CYLBadgeHelperTableViewController` as a child filling this page's view. [CN] 添加填满本页面视图的 `CYLBadgeHelperTableViewController` 子页面。 */
fun Fragment.cyl_addBadgeHelperTable(): CYLBadgeHelperTableViewController {
    val table = CYLBadgeHelperTableViewController()
    cyl_addChildViewController(table)
    return table
}

// MARK: - UIViewController (CYLMemoryWarning)

/** [EN] `-cyl_memoryWarningCellForTableView:`: the row of the memory warning check. [CN] 内存警告检查的行。 */
fun Fragment.cyl_memoryWarningCellForTableView(parent: ViewGroup): View {
    val context = parent.context
    val density = context.resources.displayMetrics.density
    return LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        setPadding((16 * density).toInt(), (10 * density).toInt(), (16 * density).toInt(), (10 * density).toInt())
        addView(TextView(context).apply { text = CYLLocalization.string(context, R.string.cyl_memory_warning_title); textSize = 15f; setTypeface(typeface, Typeface.BOLD) })
        addView(TextView(context).apply { text = CYLLocalization.string(context, R.string.cyl_memory_warning_detail); setTextColor(Color.GRAY) })
    }
}

/**
 * [EN] `-cyl_simulateMemoryWarningAndShowResult`: simulates a memory warning for this page's tab bar controller, then shows
 *      an alert that lists, for each tab, whether its view was unloaded and why not.
 * [CN] 为本页面所在的 TabBarController 模拟内存警告，然后弹窗列出每个 Tab 的视图是否被卸载以及未卸载的原因。
 */
fun Fragment.cyl_simulateMemoryWarningAndShowResult() {
    val context = context ?: return
    val controller = cyl_owningTabBarController() ?: cyl_tabBarController ?: CYLTabBarController.cyl_activeTabBarController()
    val message = CYLSimulateMemoryWarningReport(context, controller)
    AlertDialog.Builder(context).setTitle(CYLLocalization.string(context, R.string.cyl_memory_warning_alert_title)).setMessage(message)
        .setPositiveButton(android.R.string.ok, null).show()
}

/** [EN] The tab's title, or `fallback` without a tab item. [CN] Tab 的标题；没有 Tab 项时为 `fallback`。 */
private fun CYLMemoryWarningTabTitle(item: CYLTabBarItem?, selected: Boolean, fallback: String): String {
    if (item == null) return fallback
    val selectedTitle = if (selected) item.cyl_selectedTitle else null
    return selectedTitle ?: item.title ?: fallback
}

/**
 * [EN] `CYLSimulateMemoryWarningReport()`: simulates a memory warning for `controller` and returns what happened to each tab,
 *      one line per tab, in [CYLLocalization.language]: the message of `cyl_simulateMemoryWarningAndShowResult`, for any UI
 *      (e.g. `CYLTabBarHostView`).
 * [CN] 对 `controller` 模拟内存警告，并返回每个 Tab 的结果（每个 Tab 一行），使用 [CYLLocalization.language]：即
 *      `cyl_simulateMemoryWarningAndShowResult` 弹窗的内容，可用于任何界面（例如 `CYLTabBarHostView`）。
 */
fun CYLSimulateMemoryWarningReport(context: Context, controller: CYLTabBarController?): String {
    val pages = controller?.viewControllers.orEmpty()
    val wasLoaded = pages.map { it.view != null }
    CYLTabBarController.cyl_simulateMemoryWarningForTabBarController(controller)
    val text = { id: Int -> CYLLocalization.string(context, id) }
    val lines = ArrayList<String>()
    when {
        controller == null -> lines += text(R.string.cyl_memory_warning_no_controller)
        !controller.unloadsUnselectedViewsOnMemoryWarning -> lines += text(R.string.cyl_memory_warning_disabled)
    }
    val items = controller?.tabBarItems.orEmpty()
    val selectedIndex = controller?.selectedIndex
    pages.forEachIndexed { index, page ->
        // [EN] The title the tab shows, as iOS `tabBarItem.title`: the selected title on the selected tab. [CN] Tab 显示的标题，与 iOS 相同：选中的 Tab 显示选中标题。
        val title = CYLMemoryWarningTabTitle(items.getOrNull(index), index == selectedIndex, page.javaClass.simpleName)
        val status = when {
            !wasLoaded[index] -> R.string.cyl_memory_warning_not_loaded
            page.view == null -> R.string.cyl_memory_warning_unloaded
            index == selectedIndex -> R.string.cyl_memory_warning_kept_selected
            controller?.unloadsUnselectedViewsOnMemoryWarning == true && !controller.shouldUnloadViewOfViewController(page) -> R.string.cyl_memory_warning_kept_should_unload
            else -> R.string.cyl_memory_warning_kept
        }
        lines += "$title: ${text(status)}"
    }
    return lines.joinToString("\n")
}

// MARK: - Base view controllers 基类

/** [EN] `CYLBaseViewController`: a base page. [CN] 页面基类。 */
open class CYLBaseViewController : Fragment()

/** [EN] `CYLBaseTableViewController`: a base page whose view is a list (`listView`). [CN] 视图为列表（`listView`）的页面基类。 */
open class CYLBaseTableViewController : Fragment() {
    var listView: ListView? = null
        private set

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View =
        ListView(inflater.context).also { listView = it }

    override fun onDestroyView() {
        listView = null
        super.onDestroyView()
    }
}

/**
 * [EN] `CYLBaseNavigationController`: a navigation stack in a tab (child fragments on a back stack, the first is
 *      `rootViewController`); the tab bar hides while a page is pushed over the root and shows again at the root, as
 *      `cyl_hidesBottomBarWhenPushed` does on iOS.
 * [CN] Tab 中的导航栈（子 Fragment 在返回栈中，第一个是 `rootViewController`）；在根页面之上 push 页面时隐藏 TabBar，回到根页面时显示，
 *      与 iOS 的 `cyl_hidesBottomBarWhenPushed` 一致。
 */
open class CYLBaseNavigationController() : Fragment() {
    private var root: Fragment? = null
    private val containerId = View.generateViewId()

    constructor(rootViewController: Fragment) : this() { root = rootViewController }

    /** [EN] The pages of the stack, root first. [CN] 栈中的页面，根页面在前。 */
    val viewControllers: List<Fragment> get() = childFragmentManager.fragments.filter { it.id == containerId }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View =
        FrameLayout(inflater.context).apply { id = containerId }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val first = root
        if (first != null && childFragmentManager.fragments.isEmpty()) childFragmentManager.beginTransaction().add(containerId, first).commitNow()
        childFragmentManager.addOnBackStackChangedListener { toggleTabBarHidden() }
    }

    /** [EN] `-pushViewController:animated:`. [CN] push 页面。 */
    open fun pushViewController(viewController: Fragment, animated: Boolean) {
        childFragmentManager.beginTransaction().apply {
            if (animated) setTransition(androidx.fragment.app.FragmentTransaction.TRANSIT_FRAGMENT_OPEN)
            viewControllers.lastOrNull()?.let { hide(it) }
            add(containerId, viewController)
            addToBackStack(null)
        }.commit()
    }

    /** [EN] `-popViewControllerAnimated:`. [CN] 弹出页面。 */
    open fun popViewControllerAnimated(animated: Boolean) { childFragmentManager.popBackStack() }

    /** [EN] `-popToRootViewControllerAnimated:`. [CN] 回到根页面。 */
    open fun popToRootViewControllerAnimated(animated: Boolean) {
        if (childFragmentManager.backStackEntryCount > 0) childFragmentManager.popBackStack(childFragmentManager.getBackStackEntryAt(0).id, androidx.fragment.app.FragmentManager.POP_BACK_STACK_INCLUSIVE)
    }

    private fun toggleTabBarHidden() {
        val hidden = childFragmentManager.backStackEntryCount > 0
        cyl_tabBarController?.setTabBarHidden(hidden, true)
    }
}

// MARK: - Deprecated badge points (UIViewController / UIControl (CYLTabBarControllerExtentionDeprecated)) 已废弃的角标点

/** [EN] `-cyl_showTabBadgePoint` (deprecated): use `cyl_showBadge`. [CN] 已废弃，请使用 `cyl_showBadge`。 */
@Deprecated("Use cyl_showBadge", ReplaceWith("cyl_showBadge()"))
fun View.cyl_showTabBadgePoint() = cyl_showBadge()
/** [EN] `-cyl_removeTabBadgePoint` (deprecated): use `cyl_clearBadge`. [CN] 已废弃，请使用 `cyl_clearBadge`。 */
@Deprecated("Use cyl_clearBadge", ReplaceWith("cyl_clearBadge()"))
fun View.cyl_removeTabBadgePoint() = cyl_clearBadge()
/** [EN] `-cyl_isShowTabBadgePoint` (deprecated): use `cyl_isShowBadge`. [CN] 已废弃，请使用 `cyl_isShowBadge`。 */
@Deprecated("Use cyl_isShowBadge", ReplaceWith("cyl_isShowBadge()"))
fun View.cyl_isShowTabBadgePoint(): Boolean = cyl_isShowBadge()
/** [EN] `cyl_tabBadgePointView` (deprecated): the badge view. [CN] 已废弃：角标视图。 */
@Deprecated("Use cyl_badge", ReplaceWith("cyl_badge"))
val View.cyl_tabBadgePointView: View? get() = cyl_badge
/** [EN] `cyl_tabBadgePointViewOffset` (deprecated): `cyl_badgeCenterOffset`. [CN] 已废弃：即 `cyl_badgeCenterOffset`。 */
@Deprecated("Use cyl_badgeCenterOffset", ReplaceWith("cyl_badgeCenterOffset"))
var View.cyl_tabBadgePointViewOffset: CYLOffset
    get() = cyl_badgeCenterOffset
    set(value) { cyl_badgeCenterOffset = value }

/** [EN] The page's tab button versions. [CN] 页面 Tab 按钮上的版本。 */
@Deprecated("Use cyl_showBadge", ReplaceWith("cyl_showBadge()"))
fun Fragment.cyl_showTabBadgePoint() = cyl_showBadge()
@Deprecated("Use cyl_clearBadge", ReplaceWith("cyl_clearBadge()"))
fun Fragment.cyl_removeTabBadgePoint() = cyl_clearBadge()
@Deprecated("Use cyl_isShowBadge", ReplaceWith("cyl_isShowBadge()"))
fun Fragment.cyl_isShowTabBadgePoint(): Boolean = cyl_isShowBadge()
@Deprecated("Use the tab button's cyl_badge")
val Fragment.cyl_tabBadgePointView: View? get() = cyl_tabButton?.cyl_badge
@Deprecated("Use the tab button's cyl_badgeCenterOffset")
var Fragment.cyl_tabBadgePointViewOffset: CYLOffset
    get() = cyl_tabButton?.cyl_badgeCenterOffset ?: CYLOffset.zero
    set(value) { cyl_tabButton?.cyl_badgeCenterOffset = value }
