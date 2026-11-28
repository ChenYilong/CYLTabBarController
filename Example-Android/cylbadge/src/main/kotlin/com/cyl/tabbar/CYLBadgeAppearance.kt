// [EN] The method names are the iOS names on purpose (`cyl_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 的名称（`cyl_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100", "kotlin:S1133")

package com.cyl.tabbar

// [EN] Moved unchanged from CYLBadgeExtensions.kt into `:cylbadge` (docs/Animated-Item-Badge-CrossPlatform.md, step A3): the app-wide appearance, the
//      text-displaying protocol and `CYLTabBarBadgeView`, which the badge itself needs. Not compiled yet.
// [CN] 从 CYLBadgeExtensions.kt 原样移入 `:cylbadge`（docs/Animated-Item-Badge-CrossPlatform.md，步骤 A3）：App 级外观、文字显示协议与
//      `CYLTabBarBadgeView`，角标自身需要它们。尚未编译。

import com.cyl.animateditem.CYLOffset
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.TextView
import androidx.annotation.ColorInt

/**
 * [EN] `CYLBadgeAppearance` (#425): the app-wide default badge style. A value set on a view wins over it; it wins over the
 *      built-in default. Badges shown later use the new defaults.
 * [CN] `CYLBadgeAppearance`（#425）：App 级默认角标样式。视图上设置的值优先于它，它优先于内置默认值。之后显示的角标使用新的默认值。
 */
// [EN] kotlin:S6515: a class with one shared instance on purpose, as iOS `+[CYLBadgeAppearance appearance]`; the instance type stays public API. [CN] kotlin:S6515：刻意为只有一个共享实例的类，与 iOS `+[CYLBadgeAppearance appearance]` 相同；实例类型是公开 API。
@Suppress("kotlin:S6515")
class CYLBadgeAppearance private constructor() {
    /**
     * [EN] Background color, red by default (`reset()` restores it). [CN] 背景色，默认红色（`reset()` 恢复）。
     */
    @ColorInt var backgroundColor: Int = Color.RED
    /**
     * [EN] Text color, white by default. [CN] 文字颜色，默认白色。
     */
    @ColorInt var textColor: Int = Color.WHITE
    /**
     * [EN] Text font, bold 9 sp by default, as on iOS. [CN] 字体，默认粗体 9 sp，与 iOS 相同。
     */
    var font: CYLFont = DEFAULT_FONT
    /**
     * [EN] Offset of the badge center from the host's top-right corner (dp); not finite: 0. [CN] 角标中心相对宿主右上角的偏移（dp）；非有限值视为 0。
     */
    var centerOffset: CYLOffset = CYLOffset.zero
        set(value) { field = CYLOffset(value.horizontal.takeIf { it.isFinite() } ?: 0f, value.vertical.takeIf { it.isFinite() } ?: 0f) }
    /**
     * [EN] Radius of the red dot (dp); 0, negative or not finite restores 4. [CN] 红点半径（dp）；0、负数或非有限值恢复为 4。
     */
    var radius: Float = DEFAULT_RADIUS
        set(value) { field = if (value > 0 && value.isFinite()) value else DEFAULT_RADIUS }
    /**
     * [EN] Space added once to the text's width and height in number and text badges (dp), 8 by default as on iOS; negative or not finite: 0. [CN] 数字与文字角标在文字宽度与高度上各加一次的边距（dp），默认 8，与 iOS 相同；负数或非有限值视为 0。
     */
    var margin: Float = DEFAULT_MARGIN
        set(value) { field = if (value.isFinite()) value.coerceAtLeast(0f) else 0f }
    /**
     * [EN] Numbers above it show as "<maximum>+"; below 1: 1. [CN] 超过它的数字显示为 "<maximum>+"；小于 1 时为 1。
     */
    var maximumBadgeNumber: Int = 99
        set(value) { field = value.coerceAtLeast(1) }
    /**
     * [EN] Corner radius of number and text badges (dp); 0 means a capsule. [CN] 数字与文字角标的圆角（dp）；0 表示胶囊形。
     */
    var cornerRadius: Float = 0f
        set(value) { field = if (value.isFinite()) value.coerceAtLeast(0f) else 0f }
    /**
     * [EN] Border color, drawn only when `borderWidth` > 0. [CN] 边框颜色，`borderWidth` > 0 时才绘制。
     */
    @ColorInt var borderColor: Int? = null
    /**
     * [EN] Border width (dp); negative or not finite: 0. [CN] 边框宽度（dp）；负数或非有限值视为 0。
     */
    var borderWidth: Float = 0f
        set(value) { field = if (value.isFinite()) value.coerceAtLeast(0f) else 0f }

    /**
     * [EN] `-reset`: every property back to its built-in default. [CN] 把所有属性恢复为内置默认值。
     */
    fun reset() {
        backgroundColor = Color.RED; textColor = Color.WHITE; font = DEFAULT_FONT; centerOffset = CYLOffset.zero
        radius = DEFAULT_RADIUS; margin = DEFAULT_MARGIN; maximumBadgeNumber = 99; cornerRadius = 0f; borderColor = null; borderWidth = 0f
    }

    companion object {
        // [EN] iOS `kCYLBadgeDefaultFont` (bold 9 pt) and `CYLBadgeAppearance`'s margin, 8 pt. [CN] iOS 的 `kCYLBadgeDefaultFont`（粗体 9 pt）与 `CYLBadgeAppearance` 的边距 8 pt。
        private val DEFAULT_FONT = CYLFont(9f, bold = true)
        private const val DEFAULT_RADIUS = 4f
        private const val DEFAULT_MARGIN = 8f
        /**
         * [EN] The shared global appearance. [CN] 共享的全局外观。
         */
        @JvmStatic
        val globalAppearance: CYLBadgeAppearance = CYLBadgeAppearance()
    }
}

/**
 * [EN] `CYLBadgeTextDisplaying`: what a badge's text view provides. [CN] 角标文字视图提供的能力。
 */
interface CYLBadgeTextDisplaying {
    var text: String?
    var font: CYLFont
    @get:ColorInt @setparam:ColorInt
    var textColor: Int
    /**
     * [EN] `textAlignment` as a horizontal `Gravity`. [CN] 以水平 `Gravity` 表示的 `textAlignment`。
     */
    var textGravity: Int
}

/**
 * [EN] `UILabel (CYLBadgeTextDisplaying)`: a TextView seen as `CYLBadgeTextDisplaying`. [CN] 把 TextView 视为 `CYLBadgeTextDisplaying`。
 */
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

/**
 * [EN] `TextView` as `CYLBadgeTextDisplaying` (`UILabel (CYLBadgeTextDisplaying)`). [CN] 把 TextView 作为 `CYLBadgeTextDisplaying`。
 */
fun TextView.cylBadgeTextDisplaying(): CYLBadgeTextDisplaying = CYLTextViewBadgeTextDisplaying(this)

/**
 * [EN] `CYLTabBarBadgeView`: a badge view made of a label (`badgeLabel`) inside `badgeContentInset`, for a custom badge.
 * [CN] `CYLTabBarBadgeView`：由 `badgeContentInset` 内的标签（`badgeLabel`）组成的角标视图，用于自定义角标。
 */
open class CYLTabBarBadgeView(context: Context) : FrameLayout(context), CYLBadgeTextDisplaying {
    /**
     * [EN] The label that draws the badge text. [CN] 绘制角标文字的标签。
     */
    val badgeLabel: TextView = TextView(context).apply { gravity = Gravity.CENTER; maxLines = 1; setTextColor(Color.WHITE); textSize = 11f }
    /**
     * [EN] The insets around the label (dp). [CN] 标签周围的边距（dp）。
     */
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

    /**
     * [EN] Default centered. [CN] 默认居中。
     */
    override var textGravity: Int by adapter::textGravity
    /**
     * [EN] Default white. [CN] 默认白色。
     */
    override var textColor: Int by adapter::textColor
    override var text: String? by adapter::text
    override var font: CYLFont by adapter::font
}
