package com.cyl.animateditem

import android.animation.ValueAnimator
import android.app.UiModeManager
import android.content.Context
import android.os.Build
import androidx.annotation.RestrictTo
import android.content.res.Configuration
import com.chenyilong.cyldeallocblockexecutor.AnimationEvents
import com.chenyilong.cyldeallocblockexecutor.LifecycleCenter
import com.chenyilong.cyldeallocblockexecutor.LifecycleRegistry
import android.graphics.Color
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.Drawable
import android.util.AttributeSet
import android.util.TypedValue
import android.view.GestureDetector
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewGroup
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import com.cyl.tabbar.CYLBadgeAccessibilityDescription
import com.cyl.tabbar.CYLBadgeAttributeKey
import com.cyl.tabbar.CYLBadgeHosting
import com.cyl.tabbar.cylApplyBadgeAttributes
import com.cyl.tabbar.cylBadgeState
import com.cyl.tabbar.cylBadgeRadius
import com.cyl.tabbar.cylClearBadge
import com.cyl.tabbar.cylIsShowBadge
import com.cyl.tabbar.cylShowBadgeValue
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * [EN] An animated icon + title view to subclass, shared by the tags of CollectionViewClassifyMenu and
 *      CYLSearchViewController, the placeholders of CYLTableViewPlaceHolder and the tab buttons of CYLTabBarController:
 *      - an icon (`iconView`) that plays any file of the animation engine (`animationURL`), its static `image` /
 *        `selectedImage` shown until the animation is ready;
 *      - a title (`titleView`), beside the icon (`CYLAnimatedItemAxis.Horizontal`) or under it (`Vertical`);
 *      - an optional accessory icon (`accessoryView`, e.g. a delete cross) with its own tap, placed before, after or on
 *        the top trailing corner;
 *      - gestures on the whole view, reported to `gestureListener`: tap, long press and drag (`isDragEnabled`).
 *      Subclasses change what they need: the content (`CYLAnimatedItemContent`), the layout (`layoutContent`,
 *      `measureContent`), the appearance per state (`onItemStateChanged`), the accessibility text
 *      (`accessibilityText`), more gestures (`onItemTouchEvent`), or the animation source (`animationSource`).
 *      Lengths are px unless a name ends in `Dp`.
 * [CN] 可继承的动效 icon + title 视图，供 CollectionViewClassifyMenu 与 CYLSearchViewController 的标签、CYLTableViewPlaceHolder 的
 *      占位图以及 CYLTabBarController 的 Tab 按钮共用：
 *      - 图标（`iconView`）可播放动画引擎支持的任意文件（`animationURL`），动画就绪前显示静态 `image` / `selectedImage`；
 *      - 标题（`titleView`），在图标旁（`CYLAnimatedItemAxis.Horizontal`）或下方（`Vertical`）；
 *      - 可选的附加图标（`accessoryView`，例如删除叉号），有自己的点击，位于内容前、后或右上角；
 *      - 整个视图的手势，报告给 `gestureListener`：点击、长按与拖拽（`isDragEnabled`）。
 *      子类按需修改：内容（`CYLAnimatedItemContent`）、布局（`layoutContent`、`measureContent`）、各状态的外观（`onItemStateChanged`）、
 *      无障碍文本（`accessibilityText`）、更多手势（`onItemTouchEvent`）或动画来源（`animationSource`）。
 *      长度单位为 px，名称以 `Dp` 结尾的除外。
 */
/**
 * [EN] The named constant of the capsule (1000 dp): pass it to `itemCornerRadius` instead of a literal. The view treats it as exactly half the height,
 *      following the size. (Any plain number is dp limited to half the height, so a number of half the height or more is a capsule too.)
 * [CN] 胶囊的命名常量（1000 dp）：传给 `itemCornerRadius`，不要写字面量。视图把它当作恰好半高，随尺寸变化。（任何普通数字都是 dp 且最大取半高，所以不小于半高的数字
 *      也是胶囊。）
 */
const val CYLAnimatedItemCornerRadiusCapsule: Float = 1000f

/**
 * [EN] The space between the outer border and the content on the left and right that an item with Liquid Glass gets while `itemContentHorizontalInset` is
 *      not set (14 dp): a capsule's round ends take room from the content, so the unset glass inset is wider; the unset flat inset is 0. The same
 *      condition as the unset `itemCornerRadius` (a capsule for Liquid Glass, square for flat). Pass it by name, never the literal.
 * [CN] 液态玻璃条目在未设置 `itemContentHorizontalInset` 时，外侧边框与内容之间左右的间距（14 dp）：胶囊的圆端会占去内容的空间，所以未设置时
 *      玻璃的间距更宽；未设置时扁平的间距为 0。与未设置的 `itemCornerRadius`（液态玻璃为胶囊、扁平为直角）条件相同。请用名称，不要写字面量。
 */
const val CYLAnimatedItemLiquidGlassContentInset: Float = 14f

/**
 * [EN] What the view's background is made of: the solid `itemBackgroundColor` (`Flat`, default), or Liquid Glass tinted with it
 *      (`LiquidGlass`; drawn only where the device draws Liquid Glass, `CYLAnimatedItemView.isLiquidGlassActive()`: Android 12
 *      and later, as the tab bar; elsewhere the style is ignored and the view stays flat). Same names as iOS and HarmonyOS.
 * [CN] 视图背景的构成：纯色 `itemBackgroundColor`（`Flat`，默认），或以它着色的液态玻璃（`LiquidGlass`；只在设备绘制液态玻璃处绘制，
 *      `CYLAnimatedItemView.isLiquidGlassActive()`：与 TabBar 一样为 Android 12 及以上；其他设备忽略该样式，保持扁平）。与 iOS、鸿蒙同名。
 */
enum class CYLAnimatedItemBackgroundStyle { Flat, LiquidGlass }

/**
 * [EN] The state a subclass hands a colour for (`setSubclassTitleColor` / `setSubclassIconColor`): the normal look, the selected look, the disabled
 *      look. A missing selected colour falls back to the normal one; a missing disabled colour shows the colour of the other state. Same names as iOS.
 * [CN] 子类为之提供颜色的状态（`setSubclassTitleColor` / `setSubclassIconColor`）：普通、选中、禁用外观。缺少选中颜色时回退到普通颜色；缺少禁用颜色时显示另一状态的颜色。与 iOS 同名。
 */
enum class CYLAnimatedItemTitleState { Normal, Selected, Disabled }

/**
 * [EN] The kind of colour `CYLAnimatedItemView.adaptedOnGlass` adapts: an icon / animation tint (least contrast 3) or title text (4.5).
 * [CN] `CYLAnimatedItemView.adaptedOnGlass` 所适配的颜色种类：图标 / 动画着色（最小对比度 3）或标题文字（4.5）。
 */
enum class CYLAnimatedItemColorKind { Icon, Title }

/**
 * [EN] Where a resolved colour of a [CYLAnimatedItemColorRole] came from (high to low), iOS `CYLAnimatedItemColorLevel`: `Explicit` (the item's own colour, the
 *      subclass-explicit colour, the stack's), `SubclassBuiltIn` (`applyBuiltInColor`), `ComponentBuiltIn` (the role's own built-in), `None`.
 * [CN] [CYLAnimatedItemColorRole] 解析出的颜色来自哪一层（由高到低），对应 iOS `CYLAnimatedItemColorLevel`：`Explicit`（条目自己的颜色、子类显式颜色、堆叠的颜色）、
 *      `SubclassBuiltIn`（`applyBuiltInColor`）、`ComponentBuiltIn`（角色自己的内置值）、`None`。
 */
enum class CYLAnimatedItemColorLevel { None, Explicit, SubclassBuiltIn, ComponentBuiltIn }

/**
 * [EN] The result of the item's ONE colour resolver for a role in the current state (iOS `CYLAnimatedItemResolvedColor`): the colour, already adapted by the contrast
 *      rule where it applies (never for the disabled look of a built-in level), and its level.
 * [CN] 条目唯一的颜色解析器对某角色在当前状态下的结果（对应 iOS `CYLAnimatedItemResolvedColor`）：颜色（规则适用时已按对比度调整，内置层的禁用外观除外）及其层级。
 */
data class CYLAnimatedItemResolvedColor(val color: Int?, val level: CYLAnimatedItemColorLevel)

/**
 * [EN] A DECLARED colour role of a [CYLAnimatedItemView] (iOS `CYLAnimatedItemColorRole`): one element whose colour the item resolves and writes. The item's own roles are
 *      [title] and [icon] (the animation tint follows the icon); a subclass declares its own elements (a delete-indicator label, a cross, editing icons) with
 *      `register(role)` and nothing else. One mechanism for every role: precedence subclass-explicit (`setSubclassColor`) > subclass built-in (`applyBuiltInColor`) >
 *      `componentBuiltIn`, (title and icon: own colour > subclass-explicit > stack > subclass built-in > component built-in, as before), then ONE contrast step by `kind`
 *      (icon 3:1, title 4.5:1; `adaptedForContrast`), re-applied on every change of state, configuration, colours and background. `apply` takes the ITEM as a parameter
 *      and must not capture it. Registering the same `id` again replaces the role.
 * [CN] [CYLAnimatedItemView] 声明的一个颜色角色（对应 iOS `CYLAnimatedItemColorRole`）：条目解析并写入颜色的一个元素。条目自己的角色是 [title] 与 [icon]（动画着色跟随图标）；
 *      子类用 `register(role)` 声明自己的元素（删除指示标签、叉号、编辑图标），无需其他处理。所有角色共用同一机制：优先级 子类显式（`setSubclassColor`）> 子类内置
 *      （`applyBuiltInColor`）> `componentBuiltIn`（标题与图标：自己的颜色 > 子类显式 > 堆叠 > 子类内置 > 组件内置，与以前相同），然后按 `kind` 做唯一的一次对比度调整
 *      （图标 3:1，标题 4.5:1；`adaptedForContrast`），状态、配置、颜色与背景每次变化时重新应用。`apply` 以条目为参数，不得捕获它。用相同 `id` 再次注册会替换该角色。
 */
class CYLAnimatedItemColorRole(
    val id: String,
    val kind: CYLAnimatedItemColorKind,
    val componentBuiltIn: ((CYLAnimatedItemView, CYLAnimatedItemTitleState) -> Int?)? = null,
    val apply: (CYLAnimatedItemView, CYLAnimatedItemResolvedColor) -> Unit,
) {
    companion object {
        /** [EN] The title text (4.5:1). [CN] 标题文字（4.5:1）。 */
        @JvmField val title = CYLAnimatedItemColorRole("title", CYLAnimatedItemColorKind.Title) { item, _ -> item.refreshColors() }

        /** [EN] The icon and the animation tint (3:1). [CN] 图标与动画着色（3:1）。 */
        @JvmField val icon = CYLAnimatedItemColorRole("icon", CYLAnimatedItemColorKind.Icon) { item, _ -> item.refreshColors() }
    }
}

open class CYLAnimatedItemView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : FrameLayout(context, attrs), CYLAnimatedItemContent, CYLAnimatedItemAnimating, CYLTabBarItemAnimationFailureHandling, CYLBadgeHosting {

    /** [EN] The badge goes on the anchor, which sits on the icon (`CYLBadgeHosting`). [CN] 角标放在位于图标上的锚点上（`CYLBadgeHosting`）。 */
    override val cylBadgeAnchorView: ViewGroup get() = badgeAnchorView

    /**
     * [EN] Creates the view with its background style: `CYLAnimatedItemView(context, CYLAnimatedItemBackgroundStyle.LiquidGlass)` is all an
     *      example needs to switch to Liquid Glass (a capsule by default; flat where the device draws none). Same as setting `itemBackgroundStyle`.
     * [CN] 以背景样式创建视图：`CYLAnimatedItemView(context, CYLAnimatedItemBackgroundStyle.LiquidGlass)` 即可让示例切换为液态玻璃（默认胶囊；设备不绘制时为扁平）。
     *      等同于设置 `itemBackgroundStyle`。
     */
    constructor(context: Context, itemBackgroundStyle: CYLAnimatedItemBackgroundStyle) : this(context, null) {
        this.itemBackgroundStyle = itemBackgroundStyle
    }

    /**
     * [EN] The static icon. Hidden from accessibility (the item reads as one element). [CN] 静态图标。对无障碍隐藏（条目作为一个元素朗读）。
     */
    val iconView: ImageView = ImageView(context).apply {
        scaleType = ImageView.ScaleType.FIT_CENTER
        cyl_hideFromAccessibility()
    }

    /**
     * [EN] The title. Hidden from accessibility (its text is part of the item's). [CN] 标题。对无障碍隐藏（文字包含在条目的文本中）。
     */
    val titleView: TextView = TextView(context).apply {
        maxLines = 1
        ellipsize = android.text.TextUtils.TruncateAt.END
        gravity = Gravity.CENTER
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
        importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
    }

    /**
     * [EN] The view playing `animationURL`, while ready. A subclass that makes the animation view itself (the tab bar's
     *      `CYLTabBarItemButton`) sets it, so `animationView`, `animationPlayer` and `isAnimationReady` describe that view.
     * [CN] 正在播放 `animationURL` 的视图（就绪时）。自己创建动画视图的子类（TabBar 的 `CYLTabBarItemButton`）会设置它，使
     *      `animationView`、`animationPlayer` 与 `isAnimationReady` 描述该视图。
     */
    var animationView: View? = null
        protected set

    /**
     * [EN] The player of `animationView`. [CN] `animationView` 的播放器。
     */
    val animationPlayer: CYLTabBarItemAnimationPlayer? get() = animationSource.playerForView(animationView)

    /**
     * [EN] Where animation views come from: the shared engine by default. [CN] 动画视图的来源：默认为共用引擎。
     */
    open var animationSource: CYLTabBarItemAnimationViewMaking = CYLAnimatedItemAnimationSource.shared
        set(value) { field = value; reloadAnimation() }

    /**
     * [EN] The listener of taps, long presses, accessory taps and drags. [CN] 点击、长按、附加图标点击与拖拽的监听者。
     */
    var gestureListener: CYLAnimatedItemGestureListener? = null

    // MARK: - Countdown 倒计时

    /**
     * [EN] The look: plain (default) or a countdown button. Countdown gives the view a border and a rounded corner and manages
     *      its title; set the `countdown…` properties, then call `startCountdown()` (or set `startsCountdownOnTap`). The end is
     *      a time read from the local clock, not a counter: the seconds spent in the background count, a clock past the longest
     *      duration or set back to before the start closes the countdown, and `countdownCacheKey` keeps it across a restart
     *      (FIX: issue #1 of SMSCodeButton). Only the title text changes, once per second, and the view keeps the width of its
     *      widest title, so nothing flickers or jumps. While it runs the view is disabled.
     * [CN] 样式：普通（默认）或倒计时按钮。倒计时样式为视图加上边框与圆角并接管标题；设置 `countdown…` 属性后调用 `startCountdown()`
     *      （或设置 `startsCountdownOnTap`）。结束是从本地时钟读取的时间点，而不是计数器：后台度过的秒数计入，时钟超过最长时长或被调回到开始之前时
     *      关闭倒计时，`countdownCacheKey` 使其在重启后继续（修复 SMSCodeButton 的 issue #1）。每秒只改变标题文字，视图保持最宽标题的宽度，
     *      因此不会闪烁或抖动。倒计时期间视图不可用。
     */
    var itemStyle: CYLAnimatedItemStyle = CYLAnimatedItemStyle.Plain
        set(value) {
            if (field == value) return
            field = value
            countdownStyleChanged()
        }

    /**
     * [EN] The length in seconds, 60 by default. Used by `startCountdown()`. [CN] 总时长（秒），默认 60。`startCountdown()` 使用。
     */
    var countdownDuration: Int = 60
        set(value) { field = value; updateCountdownTitleWidth() }

    /**
     * [EN] The title before it starts, e.g. "Get code" (the default text is English; set the app's localized text).
     * [CN] 开始前的标题，例如「获取验证码」（默认文本为英文；请设置 App 本地化后的文本）。
     */
    var countdownIdleTitle: String = "Get code"
        set(value) { field = value; refreshCountdownTitle() }

    /**
     * [EN] The title while counting: a format with one `%d` (or `%ld`), the whole seconds left, e.g. "%d s left".
     * [CN] 倒计时中的标题：带一个 `%d`（或 `%ld`，剩余整秒数）的格式，例如「还剩%d秒」。
     */
    var countdownRunningTitleFormat: String = "%d s left"
        set(value) { field = value; refreshCountdownTitle() }

    /**
     * [EN] The title once the time is up, e.g. "Resend". [CN] 时间到之后的标题，例如「重新获取」。
     */
    var countdownFinishedTitle: String = "Resend"
        set(value) { field = value; refreshCountdownTitle() }

    /**
     * [EN] The icon while counting (e.g. a clock); null keeps `image`. [CN] 倒计时中的图标（例如时钟）；为 null 时保持 `image`。
     */
    var countdownImage: Drawable? = null
        set(value) { field = value; updateIcon(); requestLayout() }

    /**
     * [EN] The title color while counting (gray by default). Idle and finished keep the title's own color.
     * [CN] 倒计时中的标题颜色（默认灰色）。待机与结束保持标题自己的颜色。
     */
    var countdownRunningTitleColor: Int = Color.GRAY
        set(value) { field = value; applyCountdownAppearance() }

    /**
     * [EN] The border color of the countdown style while it is not counting. [CN] 倒计时样式在非倒计时状态下的边框颜色。
     */
    var countdownBorderColor: Int = 0xFF07C160.toInt()
        set(value) { field = value; applyCountdownAppearance() }

    /**
     * [EN] Whether a tap starts the countdown after the listener's `onItemTapped` (off by default). With it off the app starts it
     *      itself, e.g. once the server accepted the request. [CN] 点击是否在监听者的 `onItemTapped` 之后开始倒计时（默认关闭）。
     *      关闭时由 App 自己开始，例如服务器接受请求之后。
     */
    var startsCountdownOnTap: Boolean = false

    /**
     * [EN] A key that keeps the running countdown in `countdownStorage`, so it survives the process being ended in the
     *      background (or the app quit) and started again: a view with the same key, in the countdown style, takes it up again,
     *      with the seconds that passed meanwhile counted. The cache holds the start, the end and the longest duration; it is
     *      dropped when the time is up, on `resetCountdown()`, and when it is no longer valid. null (default): nothing is kept.
     *      Use one key per thing counted, e.g. one per phone number.
     * [CN] 用于把运行中的倒计时保存到 `countdownStorage` 的 key，使倒计时在进程于后台被结束（或 App 退出）后再次启动时仍然有效：样式为倒计时且
     *      key 相同的视图会接着倒计时，期间经过的秒数同样计入。缓存保存开始时间、结束时间与最长时长；时间到、`resetCountdown()` 以及缓存失效时丢弃。
     *      null（默认）：不保存。每个被计时的对象使用一个 key，例如每个手机号一个。
     */
    var countdownCacheKey: String? = null
        set(value) {
            field = value
            if (itemStyle == CYLAnimatedItemStyle.Countdown) countdown.setCacheKey(value)
        }

    /**
     * [EN] Where the cache is kept: a `SharedPreferences` file of the app by default. [CN] 缓存的保存位置：默认为 App 的一个 `SharedPreferences` 文件。
     */
    var countdownStorage: CYLAnimatedItemCountdownStorage? = null
        set(value) { field = value; countdown.storage = value ?: sharedPreferencesStorage }

    /**
     * [EN] The clock in epoch millis, for tests: null (default) is `System.currentTimeMillis()`.
     * [CN] 以 epoch 毫秒计的时钟，供测试使用：null（默认）为 `System.currentTimeMillis()`。
     */
    var countdownClock: (() -> Long)? = null

    /**
     * [EN] Where the countdown is. [CN] 倒计时所处的阶段。
     */
    val countdownState: CYLAnimatedItemCountdownState get() = countdown.state

    /**
     * [EN] The whole seconds left (rounded up): 0 when it is not running. [CN] 剩余整秒数（向上取整）：未运行时为 0。
     */
    val countdownRemainingSeconds: Int get() = countdown.remainingSeconds

    private val sharedPreferencesStorage = object : CYLAnimatedItemCountdownStorage {
        private val preferences get() = context.getSharedPreferences("CYLAnimatedItemCountdown", Context.MODE_PRIVATE)
        override fun get(name: String): String? = preferences.getString(name, null)
        override fun set(name: String, value: String) { preferences.edit().putString(name, value).apply() }
        override fun remove(name: String) { preferences.edit().remove(name).apply() }
    }

    private val countdown = CYLAnimatedItemCountdown(
        now = { countdownClock?.invoke() ?: System.currentTimeMillis() },
        storage = sharedPreferencesStorage,
        listener = object : CYLAnimatedItemCountdownListener {
            override fun onCountdownChanged() { countdownChanged() }
            override fun onCountdownStarted() { gestureListener?.onCountdownStarted(this@CYLAnimatedItemView) }
            override fun onCountdownTicked(remainingSeconds: Int) { gestureListener?.onCountdownTicked(this@CYLAnimatedItemView, remainingSeconds) }
            override fun onCountdownFinished() {
                announceForAccessibility(countdownFinishedTitle)
                gestureListener?.onCountdownFinished(this@CYLAnimatedItemView)
            }
        },
    )
    private var countdownDisabledIt = false
    private var restingTitleColor: Int? = null
    private val countdownTicker = Runnable { tickCountdown() }

    /**
     * [EN] One tick: refreshes the title and schedules the next one while it runs. [CN] 一次滴答：刷新标题，运行期间安排下一次。
     */
    private fun tickCountdown() {
        countdown.refresh()
        if (countdown.state == CYLAnimatedItemCountdownState.Running) postDelayed(countdownTicker, CYLAnimatedItemCountdown.TICK_INTERVAL_MILLIS)
    }

    // MARK: - Content 内容

    override var title: CharSequence?
        get() = titleView.text?.takeIf { it.isNotEmpty() }
        set(value) { titleView.text = value; updateAccessibility(); requestLayout(); applyBuiltInTitleOnce() }

    override var image: Drawable? = null
        set(value) { field = value; updateIcon(); requestLayout() }

    override var selectedImage: Drawable? = null
        set(value) { field = value; updateIcon() }

    /**
     * [EN] Shown when there is no static image (`image` / `selectedImage`) and `animationURL` cannot play (no library for
     *      the file, or a file it cannot read). null (default) uses `defaultPlaceholderImage`; an empty `ColorDrawable` with
     *      no size shows none (the title alone). The animation still wins once it can play.
     * [CN] 没有静态图片（`image` / `selectedImage`）且 `animationURL` 无法播放（没有该文件的动画库或文件无法读取）时显示。null（默认）使用
     *      `defaultPlaceholderImage`；没有尺寸的空 `ColorDrawable` 则不显示（只有标题）。动画能播放时仍优先显示动画。
     */
    var placeholderImage: Drawable? = null
        set(value) { field = value; updateIcon(); requestLayout() }

    private fun placeholderIfNeeded(): Drawable? {
        if (image != null || selectedImage != null || animationURL.isNullOrBlank() || animationShows()) return null
        val placeholder = placeholderImage ?: defaultPlaceholderImage(context)
        return placeholder?.takeIf { placeholderImage == null || (it.intrinsicWidth > 0 && it.intrinsicHeight > 0) }
    }

    // MARK: - Layout 布局

    /**
     * [EN] Icon beside the title (default) or above it. [CN] 图标在标题旁（默认）或上方。
     */
    var axis: CYLAnimatedItemAxis = CYLAnimatedItemAxis.Horizontal
        set(value) { field = value; requestLayout() }

    /**
     * [EN] Centered (default) or against the leading edge. [CN] 居中（默认）或靠前缘。
     */
    var alignment: CYLAnimatedItemAlignment = CYLAnimatedItemAlignment.Center
        set(value) { field = value; requestLayout() }

    /**
     * [EN] Space between the icon and the title, in dp (4 by default). [CN] 图标与标题的间距，单位 dp（默认 4）。
     */
    var spacingDp: Float = 4f
        set(value) { field = value; requestLayout() }

    /**
     * [EN] The icon's size in dp; null uses the image's own size (the animation then uses 24 dp). [CN] 图标尺寸（dp）；null 使用图片自身尺寸（动画则为 24 dp）。
     */
    var iconSizeDp: CYLSize? = null
        set(value) { field = value; reloadAnimation(); requestLayout() }

    // MARK: - Accessory 附加图标

    /**
     * [EN] An optional second icon with its own tap (`gestureListener.onAccessoryTapped`), e.g. a delete cross; null
     *      removes it. It is its own accessibility element: give it a `contentDescription`.
     * [CN] 可选的第二个图标，有自己的点击（`gestureListener.onAccessoryTapped`），例如删除叉号；null 移除。它是独立的无障碍元素：
     *      请设置 `contentDescription`。
     */
    var accessoryView: View? = null
        set(value) {
            field?.let { removeView(it) }
            field = value
            value?.let { accessory ->
                accessory.isClickable = true
                accessory.setOnClickListener { gestureListener?.onAccessoryTapped(this) }
                addView(accessory)
            }
            requestLayout()
        }

    /**
     * [EN] Where the accessory goes (after the content by default). [CN] 附加图标的位置（默认在内容之后）。
     */
    var accessoryPlacement: CYLAnimatedItemAccessoryPlacement = CYLAnimatedItemAccessoryPlacement.Trailing
        set(value) { field = value; requestLayout() }

    /**
     * [EN] The accessory's size in dp (18 by default). [CN] 附加图标的尺寸，单位 dp（默认 18）。
     */
    var accessorySizeDp: Float = 18f
        set(value) { field = value; requestLayout() }

    // MARK: - Animation 动画

    override var animationURL: String? = null
        set(value) { if (field != value) { field = value; reloadAnimation() } }

    override var animationSpeed: Float = 1f
        set(value) { field = value; animationPlayer?.let { if (value > 0f) it.animationSpeed = value } }

    override var animationLoops: Boolean = false
        set(value) { field = value; animationPlayer?.loops = value }

    override var animationRestingProgress: Float = 0f
        set(value) {
            field = value.coerceIn(0f, 1f)
            if (playing) return
            // [EN] A selected item that opted in rests on the last frame: a list re-applying the (unselected) resting progress on every
            //      bind must not put it back on the first one. [CN] 已选择启用的选中条目停在最后一帧：列表每次绑定都重设（未选中的）静止进度，不能把它放回第一帧。
            if (isSelected && showsLastFrameWhenSelected && animationPlayer != null) showAnimationLastFrame() else animationPlayer?.progress = field
        }

    override val isAnimationReady: Boolean get() = animationView != null

    /**
     * [EN] Whether a play-once animation (`animationLoops` off) is replaced by the still image when it ends: the animation
     *      view is hidden and `iconView` shows `selectedImage` / `image` (else the placeholder). Off by default, so the
     *      last frame stays. The next `playAnimation()`, `restartAnimation()`, `stopAnimation()` or
     *      `showAnimationLastFrame()` shows the animation again. For an animation whose last frame is empty (a success
     *      check that fades out). The end is read from the player's `isPlaying` (Lottie, PAG, Rive, GIF, SVGA), else from
     *      its `progress` reaching 1; a player that tells neither never ends. A subclass that lays out its own icon
     *      (overriding `updateIcon`) reads `isShowingImageAfterAnimationEnd`.
     * [CN] 只播放一次的动画（`animationLoops` 关闭）结束时是否换成静态图片：隐藏动画视图，`iconView` 显示 `selectedImage` / `image`
     *      （没有时显示占位图）。默认关闭，保留最后一帧。下一次 `playAnimation()`、`restartAnimation()`、`stopAnimation()` 或
     *      `showAnimationLastFrame()` 会重新显示动画。用于最后一帧为空的动画（逐渐消失的成功对勾）。结束从播放器的 `isPlaying` 读取
     *      （Lottie、PAG、Rive、GIF、SVGA），没有时判断 `progress` 是否到达 1；两者都无法提供的播放器不会结束。自行布局图标的子类
     *      （重写 `updateIcon`）读取 `isShowingImageAfterAnimationEnd`。
     */
    var showsImageWhenAnimationEnds: Boolean = false
        set(value) {
            field = value
            if (!value) showAnimationAgain()
            if (playing) watchForAnimationEnd()
        }

    /**
     * [EN] Called when a play-once animation ends (after the still image is shown, when `showsImageWhenAnimationEnds`).
     *      Not called for a looping animation, nor after `stopAnimation()`.
     * [CN] 只播放一次的动画结束时调用（开启 `showsImageWhenAnimationEnds` 时在显示静态图片之后）。循环动画以及 `stopAnimation()` 之后不会调用。
     */
    var animationEndListener: CYLAnimatedItemAnimationEndListener? = null
        set(value) { field = value; if (playing) watchForAnimationEnd() }

    /**
     * [EN] The end callback of `animatedItemPlayer.onEnded`. [CN] `animatedItemPlayer.onEnded` 的结束回调。
     */
    internal var playerEndedCallback: (() -> Unit)? = null
        set(value) { field = value; if (playing) watchForAnimationEnd() }

    /**
     * [EN] The player over whatever engine plays `animationURL` (HarmonyOS `CYLAnimatedItemPlayer`): `play`,
     *      `stopAtProgress`, `speed`, `loops`, `supports…`, `isPlaying`, `progress`, `onEnded`, `applyColors`.
     * [CN] 覆盖播放 `animationURL` 的任何引擎的播放器（对应鸿蒙 `CYLAnimatedItemPlayer`）。
     */
    val animatedItemPlayer: CYLAnimatedItemPlayer by lazy { CYLAnimatedItemPlayer(this) }

    /**
     * [EN] Whether the item applies the default rules itself: selected plays once from the start, unselected rests at
     *      `animationRestingProgress`, a grown `animationRestartToken` restarts, and a ready animation of a selected item
     *      plays. True is the default, as on iOS and HarmonyOS; false leaves all of that to the host, which plays through
     *      `animatedItemPlayer` (the tab bar's `CYLTabBarItemButton` sets false: the tab bar plays its icons itself). HarmonyOS: `drivesAnimationPlayback`.
     * [CN] 条目是否自行应用默认规则：选中时从头播放一次，未选中时停在 `animationRestingProgress`，`animationRestartToken` 增大时重新播放，
     *      选中条目的动画就绪后播放。默认 true，与 iOS、鸿蒙一致；false 则全部交给宿主，宿主通过
     *      `animatedItemPlayer` 播放（TabBar 的 `CYLTabBarItemButton` 设为 false：TabBar 自己播放图标）。鸿蒙：`drivesAnimationPlayback`。
     */
    var drivesAnimationPlayback: Boolean = true

    /**
     * [EN] A token that restarts the animation from the start when it changes (only while `drivesAnimationPlayback`); the
     *      value at creation is not a restart. [CN] 变化时让动画从头重新播放的令牌（仅在 `drivesAnimationPlayback` 时）；创建时的值不算重新播放。
     */
    var animationRestartToken: Int = 0
        set(value) {
            val changed = field != value
            field = value
            if (changed && drivesAnimationPlayback) restartAnimation()
        }

    /**
     * [EN] Called when the engine has loaded the file; with `onAnimationFailed`, what the bridges report. [CN] 引擎加载完文件时调用；与 `onAnimationFailed` 一起是桥接层上报的内容。
     */
    var onAnimationLoaded: (() -> Unit)? = null

    /**
     * [EN] Called when the engine could not load the file. [CN] 引擎无法加载文件时调用。
     */
    var onAnimationFailed: (() -> Unit)? = null

    /**
     * [EN] Called on the main thread when the animation file cannot be shown, with the file name or path as configured
     *      (`animationURL`) and a short reason (`CYLResourceMissingReason`: "not found", "unreadable", "decode failed",
     *      "engine library missing"). Once per resource per view; the item still shows its image or the placeholder.
     *      `CYLAnimationEngines.resourceMissingListener` hears the same call. iOS: `onResourceMissing`.
     * [CN] 动画文件无法显示时在主线程调用，参数为按配置给出的文件名或路径（`animationURL`）与简短原因。每个视图每个资源一次；条目仍显示图片或占位图。
     *      `CYLAnimationEngines.resourceMissingListener` 收到同一次调用。
     */
    var onResourceMissing: ((resource: String, reason: String) -> Unit)? = null

    private val reportedMissingResources = HashSet<String>()

    protected fun resourceMissing(resource: String, reason: String) {
        if (!reportedMissingResources.add(resource)) return
        CYLAnimationEngines.dispatchResourceMissing(context, resource, reason, onResourceMissing)
    }

    /**
     * [EN] Whether the still image replaces the ended animation now (`showsImageWhenAnimationEnds`). [CN] 静态图片当前是否替换了已结束的动画。
     */
    var isShowingImageAfterAnimationEnd: Boolean = false
        private set

    /**
     * [EN] Bumped by every play, stop and reload, so an older end watch stops. [CN] 每次播放、停止与重新加载时递增，使旧的结束检测停止。
     */
    private var endWatchGeneration = 0

    private var playing = false
    private var pausedByUser = false

    /**
     * [EN] The view's alpha while disabled (0.5 by default; 1 lets `onItemStateChanged` draw the disabled look).
     * [CN] 不可用时视图的透明度（默认 0.5；设为 1 时由 `onItemStateChanged` 绘制不可用外观）。
     */
    var disabledAlpha: Float = 0.5f

    // MARK: - Gestures 手势

    /**
     * [EN] Whether the view reports drags (off by default). With `dragMovesView` the view follows the finger.
     * [CN] 是否报告拖拽（默认关闭）。开启 `dragMovesView` 时视图跟随手指移动。
     */
    var isDragEnabled: Boolean = false

    /**
     * [EN] Whether a drag moves the view (translation) and springs it back at the end. [CN] 拖拽时视图是否跟随移动（translation），结束后弹回。
     */
    var dragMovesView: Boolean = false

    private val touchSlop = ViewConfiguration.get(context).scaledTouchSlop
    private var downX = 0f
    private var downY = 0f
    private var dragging = false
    private var longPressed = false
    private val detector = GestureDetector(context, object : GestureDetector.SimpleOnGestureListener() {
        override fun onDown(e: MotionEvent) = true
        override fun onSingleTapUp(e: MotionEvent): Boolean = performClick()
        override fun onLongPress(e: MotionEvent) {
            if (!dragging && isEnabled) longPressed = gestureListener?.onItemLongPressed(this@CYLAnimatedItemView) == true
        }
    })

    init {
        isClickable = true
        isFocusable = true
        // [EN] The pressed background (`itemHighlightedBackgroundColor`) is drawn in `onDraw`. [CN] 按下背景（`itemHighlightedBackgroundColor`）在 `onDraw` 中绘制。
        setWillNotDraw(false)
        addView(iconView)
        addView(titleView)
        // [EN] Not `updateAccessibility()`: a subclass's `accessibilityText()` would run before its own properties exist.
        // [CN] 不调用 `updateAccessibility()`：子类的 `accessibilityText()` 会在其属性初始化之前运行。
        contentDescription = CYLAnimatedItemAccessibilityText(title, null)
    }

    // MARK: - Measuring and layout 测量与布局

    private fun dp(value: Float) = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics)

    /**
     * [EN] The icon's size in px. [CN] 图标尺寸（px）。
     */
    protected open fun iconSize(): Pair<Int, Int> {
        iconSizeDp?.let { return dp(it.width).roundToInt() to dp(it.height).roundToInt() }
        val drawable = iconView.drawable
        if (animationView == null && drawable != null && drawable.intrinsicWidth > 0 && drawable.intrinsicHeight > 0) {
            return drawable.intrinsicWidth to drawable.intrinsicHeight
        }
        // [EN] The size follows what is shown, never `animationURL` alone: a file that cannot play (no engine or library)
        //      leaves the layout of the static image, or of the title alone, unchanged.
        // [CN] 尺寸取决于实际显示的内容，而不是只看 `animationURL`：无法播放的文件（没有引擎或动画库）不会改变静态图片或纯标题的布局。
        return if (animationView != null || drawable != null) dp(24f).roundToInt().let { it to it } else 0 to 0
    }

    private fun showsIcon() = animationView != null || iconView.drawable != null
    private fun showsTitle() = !title.isNullOrEmpty()
    private fun accessoryInline() = accessoryView != null && accessoryPlacement != CYLAnimatedItemAccessoryPlacement.TopTrailing

    /**
     * [EN] The content's natural size (without padding), the title measured with `maxTitleWidth`. Override with
     *      `layoutContent` for another arrangement.
     * [CN] 内容的自然尺寸（不含 padding），标题按 `maxTitleWidth` 测量。若需其他排列，与 `layoutContent` 一起重写。
     */
    protected open fun measureContent(maxTitleWidth: Int): Pair<Int, Int> {
        val (iconW, iconH) = if (showsIcon()) iconSize() else 0 to 0
        val spacing = if (showsIcon() && showsTitle()) dp(spacingDp).roundToInt() else 0
        titleView.measure(MeasureSpec.makeMeasureSpec(max(0, maxTitleWidth), MeasureSpec.AT_MOST), MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED))
        val titleW = if (showsTitle()) titleView.measuredWidth else 0
        val titleH = if (showsTitle()) titleView.measuredHeight else 0
        val accessory = if (accessoryInline()) dp(accessorySizeDp).roundToInt() else 0
        val accessorySpacing = if (accessory > 0 && (showsIcon() || showsTitle())) dp(spacingDp).roundToInt() else 0
        return if (axis == CYLAnimatedItemAxis.Horizontal) {
            (iconW + spacing + titleW + accessory + accessorySpacing) to max(max(iconH, titleH), accessory)
        } else {
            (max(iconW, titleW) + accessory + accessorySpacing) to max(iconH + spacing + titleH, accessory)
        }
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        applyBuiltInTitleOnce()
        if (isDividerMode) {
            val vertical = dividerAxis == CYLAnimatedItemAxis.Horizontal
            val thickness = dividerThickness()
            val length = dp(dividerLengthDp).roundToInt()
            setMeasuredDimension(if (vertical) thickness else length, if (vertical) length else thickness)
            return
        }
        val widthLimit = if (MeasureSpec.getMode(widthMeasureSpec) == MeasureSpec.UNSPECIFIED) Int.MAX_VALUE / 2 else MeasureSpec.getSize(widthMeasureSpec)
        val (iconW, _) = if (showsIcon()) iconSize() else 0 to 0
        // [EN] `reservesBadgeSpace` (D6): the badge's overhang is reserved on both sides, so a tight host does not clip it. [CN] `reservesBadgeSpace`（D6）：在两侧都预留角标伸出的部分，使紧凑的宿主不会裁剪它。
        val reserve = badgeReservePx()
        val inset = 2 * contentInsetPx() + 2 * reserve
        val reserved = paddingLeft + paddingRight + inset + (if (accessoryInline()) dp(accessorySizeDp + spacingDp).roundToInt() else 0) +
            (if (axis == CYLAnimatedItemAxis.Horizontal && showsIcon()) iconW + dp(spacingDp).roundToInt() else 0)
        val (contentW, contentH) = measureContent(max(0, widthLimit - reserved))
        val width = resolveSize(contentW + paddingLeft + paddingRight + inset, widthMeasureSpec)
        val height = resolveSize(contentH + paddingTop + paddingBottom + 2 * reserve, heightMeasureSpec)
        setMeasuredDimension(width, height)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        // [EN] An item nothing was set on has not applied its built-in title colour yet (no state change ran): do it once, else the TextView default (a dark theme text colour) stays. [CN] 什么都没设置的条目尚未应用内置标题颜色（没有状态变化发生）：应用一次，否则保留 TextView 默认色（深色主题文字色）。
        applyBuiltInTitleOnce()
        itemBackgroundRenderer.layoutGlass(r - l, b - t)
        if (isDividerMode) return
        val reserve = badgeReservePx()
        val inset = contentInsetPx() + reserve
        layoutContent(paddingLeft + inset, paddingTop + reserve, r - l - paddingRight - inset, b - t - paddingBottom - reserve)
    }

    /**
     * [EN] Places the icon, the animation view, the title and the accessory inside the given box (the view's bounds
     *      minus its padding). Override for another arrangement; call `placeAccessory` for the accessory.
     * [CN] 在给定区域（视图边界减去 padding）中放置图标、动画视图、标题与附加图标。需要其他排列时重写；附加图标调用 `placeAccessory`。
     */
    protected open fun layoutContent(left: Int, top: Int, right: Int, bottom: Int) {
        val (contentLeft, contentRight) = contentHorizontalBounds(left, right)
        val (iconW, iconH) = if (showsIcon()) iconSize() else 0 to 0
        val spacing = if (showsIcon() && showsTitle()) dp(spacingDp).roundToInt() else 0
        val boxW = max(0, contentRight - contentLeft)
        val boxH = max(0, bottom - top)
        val maxTitleW = if (axis == CYLAnimatedItemAxis.Horizontal) max(0, boxW - iconW - spacing) else boxW
        titleView.measure(MeasureSpec.makeMeasureSpec(maxTitleW, MeasureSpec.AT_MOST), MeasureSpec.makeMeasureSpec(boxH, MeasureSpec.AT_MOST))
        val titleW = if (showsTitle()) titleView.measuredWidth else 0
        val titleH = if (showsTitle()) titleView.measuredHeight else 0
        val box = android.graphics.Rect(contentLeft, top, contentLeft + boxW, top + boxH)
        val (iconLeft, iconTop) = if (axis == CYLAnimatedItemAxis.Horizontal) layoutRow(box, iconW, iconH, titleW, titleH, spacing)
            else layoutColumn(box, iconW, iconH, titleW, titleH, spacing)
        placeIcon(iconLeft, iconTop, iconW, iconH)
        placeAccessory(left, top, right, bottom, iconLeft, iconTop, iconW)
    }

    /**
     * [EN] The left and right of the icon and title, without an inline accessory's room. [CN] 图标与标题的左右边界，除去行内附加图标占用的空间。
     */
    private fun contentHorizontalBounds(left: Int, right: Int): Pair<Int, Int> {
        if (!accessoryInline()) return left to right
        val accessorySpacing = if (showsIcon() || showsTitle()) dp(spacingDp).roundToInt() else 0
        val inset = dp(accessorySizeDp).roundToInt() + accessorySpacing
        return if ((accessoryPlacement == CYLAnimatedItemAccessoryPlacement.Leading) != isRightToLeft) left + inset to right else left to right - inset
    }

    private val isRightToLeft: Boolean get() = layoutDirection == View.LAYOUT_DIRECTION_RTL

    /**
     * [EN] Horizontal axis: the icon then the title, centred (or leading) in `box`; returns the icon's origin.
     * [CN] 水平方向：图标在前、标题在后，在 `box` 中居中（或靠前）；返回图标的原点。
     */
    private fun layoutRow(box: android.graphics.Rect, iconW: Int, iconH: Int, titleW: Int, titleH: Int, spacing: Int): Pair<Int, Int> {
        val group = iconW + spacing + titleW
        val rtl = isRightToLeft
        val start = if (alignment != CYLAnimatedItemAlignment.Leading) box.left + (box.width() - group) / 2 else if (rtl) box.right - group else box.left
        // [EN] Right-to-left: the title comes first from the left, the icon last (iOS mirrors the row the same way). [CN] 从右到左：标题在左、图标在右（与 iOS 的镜像一致）。
        val titleLeft = if (rtl) start else start + iconW + spacing
        val titleTop = box.top + (box.height() - titleH) / 2
        titleView.layout(titleLeft, titleTop, titleLeft + titleW, titleTop + titleH)
        return (if (rtl) start + titleW + spacing else start) to box.top + (box.height() - iconH) / 2
    }

    /**
     * [EN] Vertical axis: the icon above the title, centred (or leading) in `box`; returns the icon's origin.
     * [CN] 垂直方向：图标在上、标题在下，在 `box` 中居中（或靠前）；返回图标的原点。
     */
    private fun layoutColumn(box: android.graphics.Rect, iconW: Int, iconH: Int, titleW: Int, titleH: Int, spacing: Int): Pair<Int, Int> {
        val startY = box.top + (box.height() - (iconH + spacing + titleH)) / 2
        val leading = alignment == CYLAnimatedItemAlignment.Leading
        // [EN] The x of an element of `width`: centred, or against the leading edge (the right one in right-to-left). [CN] 宽 `width` 的元素的 x：居中，或靠前缘（从右到左时为右侧）。
        fun x(width: Int) = if (!leading) box.left + (box.width() - width) / 2 else if (isRightToLeft) box.right - width else box.left
        val titleLeft = x(titleW)
        titleView.layout(titleLeft, startY + iconH + spacing, titleLeft + titleW, startY + iconH + spacing + titleH)
        return x(iconW) to startY
    }

    /**
     * [EN] Places the icon and the animation view at the same frame. [CN] 将图标与动画视图放在同一位置。
     */
    protected fun placeIcon(left: Int, top: Int, width: Int, height: Int) {
        iconView.measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY))
        iconView.layout(left, top, left + width, top + height)
        animationView?.let {
            it.measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY))
            it.layout(left, top, left + width, top + height)
        }
        // [EN] The badge anchor sits on the icon itself, above the icon and the animation view; not measured. [CN] 角标锚点位于图标本身之上、图标与动画视图上方；不参与测量。
        storedBadgeAnchor?.let {
            it.measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY))
            it.layout(left, top, left + width, top + height)
            it.visibility = if (isDividerMode || !showsIcon()) View.GONE else View.VISIBLE
            it.bringToFront()
        }
    }

    /**
     * [EN] Places the accessory: at the leading or trailing edge of the box, or on the icon's top trailing corner.
     * [CN] 放置附加图标：区域的前缘或后缘，或图标的右上角。
     */
    protected fun placeAccessory(left: Int, top: Int, right: Int, bottom: Int, iconLeft: Int, iconTop: Int, iconWidth: Int) {
        val accessory = accessoryView ?: return
        val size = dp(accessorySizeDp).roundToInt()
        accessory.measure(MeasureSpec.makeMeasureSpec(size, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(size, MeasureSpec.EXACTLY))
        val rtl = isRightToLeft
        val (x, y) = when (accessoryPlacement) {
            CYLAnimatedItemAccessoryPlacement.Leading -> (if (rtl) right - size else left) to top + (bottom - top - size) / 2
            CYLAnimatedItemAccessoryPlacement.Trailing -> (if (rtl) left else right - size) to top + (bottom - top - size) / 2
            CYLAnimatedItemAccessoryPlacement.TopTrailing ->
                (if (rtl) max(left, iconLeft - size / 2) else min(right - size, iconLeft + iconWidth - size / 2)) to max(0, iconTop - size / 2)
        }
        accessory.layout(x, y, x + size, y + size)
    }

    // MARK: - State 状态

    override fun setSelected(selected: Boolean) {
        val changed = selected != isSelected
        super.setSelected(selected)
        if (changed) { updateIcon(); applyIconColor(); applyTitleColor(); onItemStateChanged(); updateAccessibility() }
        if (changed && animationView != null) {
            if (drivesAnimationPlayback) {
                if (selected) { if (showsLastFrameWhenSelected) showAnimationLastFrame() else restartAnimation() } else stopAnimation()
            } else if (selected && showsLastFrameWhenSelected) {
                // [EN] A host-driven item that opted in still rests on the last frame when selected. [CN] 已选择启用的宿主驱动条目，选中时仍停在最后一帧。
                showAnimationLastFrame()
            }
        }
    }

    // MARK: - Icon color 图标颜色

    /**
     * [EN] The icon color (iOS `itemAppearance.normal.iconColor`): the static icon is drawn in it (a template / symbol image
     *      takes it whole); null (default) leaves the image as it is, or uses the stack's color in a `CYLAnimatedItemStackView`.
     * [CN] 图标颜色（iOS `itemAppearance.normal.iconColor`）：静态图标按此颜色绘制（模板 / 符号图片整体着色）；null（默认）保持图片原样，
     *      在 `CYLAnimatedItemStackView` 中则使用堆叠的颜色。
     */
    var iconColor: Int? = null
        set(value) { field = value; applyIconColor() }

    /**
     * [EN] The icon color while selected (iOS `itemAppearance.selected.iconColor`); null uses `iconColor`.
     * [CN] 选中时的图标颜色（iOS `itemAppearance.selected.iconColor`）；null 时使用 `iconColor`。
     */
    var selectedIconColor: Int? = null
        set(value) { field = value; applyIconColor() }

    /**
     * [EN] The colors of the stack that holds the item, used when the item has none. [CN] 容纳该条目的堆叠视图的颜色，条目没有自己的颜色时使用。
     */
    internal var stackIconColor: Int? = null
        set(value) { field = value; applyIconColor() }
    internal var stackSelectedIconColor: Int? = null
        set(value) { field = value; applyIconColor() }
    private var appliesIconColor = false
    private var appliedIconFilter: android.graphics.ColorFilter? = null
    private var staticImageKinds: java.util.WeakHashMap<Drawable, CYLAnimationColorCount.Kind>? = null

    /**
     * [EN] Whether the static image follows the rendering mode as an animation does (2026-11-28; the owner asked why a ClassifyMenu tag, also a
     *      CYLAnimatedItemView, did not follow the tint rule). With no explicit icon colour, `animationRenderingMode` (else the stack's, else `Automatic`)
     *      decides: `Automatic` tints an image detected as one colour (`CYLAnimationColorCount.drawableKind`, the GIF counter) with `resolvedIconColor`
     *      (built-ins included) through the contrast rule; `AlwaysTemplate` tints any image; `AlwaysOriginal` never. A multi-colour image keeps its colours.
     *      A colour filter the host set on `iconView` itself is never replaced by this path. An explicit `iconColor` tints the image whole, as before.
     *      True by default; a subclass that tints its own icon (the tab bar's button) returns false.
     * [CN] 静态图片是否像动画一样遵循渲染方式（2026-11-28；所有者询问同为 CYLAnimatedItemView 的 ClassifyMenu 标签为何没有遵循着色规则）。没有显式图标颜色时由
     *      `animationRenderingMode`（其次堆叠的，最后 `Automatic`）决定：`Automatic` 对检测为单色的图片（`CYLAnimationColorCount.drawableKind`，与 GIF 相同的计数）按
     *      `resolvedIconColor`（含内置值）着色并经过对比度规则；`AlwaysTemplate` 对任何图片着色；`AlwaysOriginal` 从不着色。多色图片保持原色。宿主自己在 `iconView`
     *      上设置的颜色滤镜不会被此路径替换。显式 `iconColor` 仍整体着色。默认为 true；自行为图标着色的子类（TabBar 的按钮）返回 false。
     */
    protected open val tintsStaticImageAutomatically: Boolean get() = true

    /**
     * [EN] The kind of the static image `drawable`, cached per drawable. [CN] 静态图片 `drawable` 的类型，按 drawable 缓存。
     */
    internal fun staticImageKind(drawable: Drawable): CYLAnimationColorCount.Kind {
        val kinds = staticImageKinds ?: java.util.WeakHashMap<Drawable, CYLAnimationColorCount.Kind>().also { staticImageKinds = it }
        return kinds.getOrPut(drawable) { CYLAnimationColorCount.drawableKind(drawable) }
    }

    /**
     * [EN] The colour the rendering mode gives the shown static image when no explicit icon colour is set, or null (see [tintsStaticImageAutomatically]).
     * [CN] 没有显式图标颜色时渲染方式给显示中的静态图片的颜色，没有时为 null（见 [tintsStaticImageAutomatically]）。
     */
    internal fun staticImageRenderingColor(configuration: Configuration = resources.configuration): Int? {
        if (!tintsStaticImageAutomatically) return null
        val shown = iconView.drawable ?: return null
        val tints = when (animationRenderingMode ?: stackAnimationRenderingMode ?: CYLAnimationRenderingMode.Automatic) {
            CYLAnimationRenderingMode.AlwaysOriginal -> false
            CYLAnimationRenderingMode.AlwaysTemplate -> true
            CYLAnimationRenderingMode.Automatic -> staticImageKind(shown) == CYLAnimationColorCount.Kind.OneColor
        }
        if (!tints) return null
        val (color, level) = iconResolution(configuration) ?: return null
        // [EN] The disabled look is never adapted, as for the animation. [CN] 与动画相同，禁用外观从不调整。
        return if (level == ColorLevel.DisabledBuiltIn) color else adaptedIconColor(color, configuration)
    }

    /**
     * [EN] The title color (iOS `itemAppearance.normal.titleColor`); null (default) keeps the text view's own color, or uses the
     *      stack's `titleColor` in a `CYLAnimatedItemStackView`.
     * [CN] 标题颜色（iOS `itemAppearance.normal.titleColor`）；null（默认）保持文本视图自身颜色，在 `CYLAnimatedItemStackView` 中则使用堆叠的 `titleColor`。
     */
    var titleColor: Int? = null
        set(value) { field = value; applyTitleColor() }

    /**
     * [EN] The stack's defaults, used when the item sets none (null / empty on the item means inherit). Set by `CYLAnimatedItemStackView`.
     * [CN] 堆叠的默认值，条目自己没有设置时使用（条目上的 null / 空表示继承）。由 `CYLAnimatedItemStackView` 设置。
     */
    internal var stackTitleColor: Int? = null
        set(value) { field = value; applyTitleColor() }
    internal var stackAnimationTint: String? = null
        set(value) { if (field != value) { field = value; refreshAnimationTint() } }
    internal var stackAnimationDarkTint: String? = null
        set(value) { if (field != value) { field = value; refreshAnimationTint() } }
    internal var stackAnimationRenderingMode: CYLAnimationRenderingMode? = null
        set(value) { if (field != value) { field = value; refreshAnimationTint() } }
    internal var stackDividerColor: Int? = null
        set(value) { if (field != value) { field = value; invalidate() } }
    private var defaultTitleColor: Int? = null
    private var appliesTitleColor = false

    /**
     * [EN] Whether the built-in colors (`CYLAnimatedItemBuiltInColors`: theme text color, `colorPrimary` when selected, dimmed when disabled) fill in
     *      what neither the item nor its stack sets: the title color and the tint of the animation. true by default; a subclass that has its own colors per
     *      state (the tab button, whose tab bar sets the title colors) returns false. A subclass that sets colors in `onItemStateChanged` wins anyway
     *      (it runs after the built-ins). [CN] 内置颜色（`CYLAnimatedItemBuiltInColors`：主题文字色、选中时 `colorPrimary`、禁用时变淡）是否补上条目与堆叠都没有设置的
     *      标题颜色与动画着色。默认 true；自己按状态设置颜色的子类（Tab 按钮，其颜色由 TabBar 设置）返回 false。在 `onItemStateChanged` 中设置颜色的子类始终优先（它在内置值之后执行）。
     */
    protected open val usesBuiltInColors: Boolean get() = true

    /**
     * [EN] Whether the disabled built-in color replaces the normal one: the view is disabled and does not dim itself (`disabledAlpha` 1), else the
     *      alpha 0.5 default would dim twice. [CN] 禁用的内置颜色是否取代普通颜色：视图被禁用且自己不变淡（`disabledAlpha` 为 1），否则默认的 0.5 alpha 会变淡两次。
     */
    private fun showsDisabledColor() = !isEnabled && disabledAlpha >= 1f

    /**
     * [EN] Where a resolved colour comes from: an EXPLICIT one (the app's, the subclass's explicit channel, the stack's, the host's), a BUILT-IN one (the subclass's
     *      `applyTitleTintColor` / `applyIconTintColor`, else the component's), or the built-in of the DISABLED look. The first two are adapted on drawn dark glass, the last is not.
     * [CN] 解析出的颜色来自哪里：显式（应用的、子类显式通道的、堆叠的、宿主的）、内置（子类的 `applyTitleTintColor` / `applyIconTintColor`，其次组件的）、禁用外观的内置色。
     *      前两者在深色玻璃绘制时适配，最后一种不适配。
     */
    private enum class ColorLevel { Explicit, BuiltIn, DisabledBuiltIn }

    private val subclassTitleColors = arrayOfNulls<Int>(CYLAnimatedItemTitleState.values().size)
    private val subclassIconColors = arrayOfNulls<Int>(CYLAnimatedItemTitleState.values().size)
    private var subclassBuiltInTitle: Int? = null
    private var subclassBuiltInIcon: Int? = null

    /**
     * [EN] Subclass-explicit title colour of `state` (the ClassifyMenu tag's channel): counts as explicit (adapted on drawn dark glass, title 4.5) WITHOUT touching
     *      `titleColor` or the stack's. Precedence: `titleColor` > this (for the current state) > the stack's > `applyTitleTintColor` > the component's built-in.
     *      A missing selected colour falls back to the normal one. null clears the state.
     * [CN] 子类显式标题颜色（ClassifyMenu 标签的通道）：视为显式颜色（深色玻璃绘制时适配，标题 4.5），且不改动 `titleColor` 与堆叠的颜色。优先级：
     *      `titleColor` > 本通道（当前状态）> 堆叠的 > `applyTitleTintColor` > 组件内置。缺少选中颜色时回退到普通颜色。null 清除该状态。
     */
    protected fun setSubclassTitleColor(color: Int?, state: CYLAnimatedItemTitleState) {
        subclassTitleColors[state.ordinal] = color
        applyTitleColor()
    }

    /**
     * [EN] Subclass-explicit icon colour of `state`; same rules as [setSubclassTitleColor] (icon and animation tint 3). It recolours the static image like `iconColor`.
     * [CN] 子类显式图标颜色；规则同 [setSubclassTitleColor]（图标与动画着色 3）。与 `iconColor` 一样为静态图片着色。
     */
    protected fun setSubclassIconColor(color: Int?, state: CYLAnimatedItemTitleState) {
        subclassIconColors[state.ordinal] = color
        applyIconColor()
    }

    /**
     * [EN] The built-in title colour of a subclass (below every explicit colour, above the component's built-in): adapted on drawn dark glass like the explicit
     *      ones, except while the item is disabled. null removes it.
     * [CN] 子类的内置标题颜色（低于所有显式颜色，高于组件内置色）：深色玻璃绘制时与显式颜色一样适配，禁用时除外。null 移除。
     */
    protected fun applyTitleTintColor(color: Int?) {
        subclassBuiltInTitle = color
        applyTitleColor()
    }

    /**
     * [EN] The built-in icon colour of a subclass (twin of [applyTitleTintColor]); it tints the animation and, since 2026-11-28, a one-colour static image
     *      under `Automatic` ([tintsStaticImageAutomatically]).
     * [CN] 子类的内置图标颜色（[applyTitleTintColor] 的对应项）；用于动画着色，自 2026-11-28 起也用于 `Automatic` 下的单色静态图片（[tintsStaticImageAutomatically]）。
     */
    protected fun applyIconTintColor(color: Int?) {
        subclassBuiltInIcon = color
        applyIconColor()
    }

    // MARK: - Colour roles 颜色角色

    /** [EN] The roles a subclass registered (title and icon are always there and not stored). Created on first use. [CN] 子类注册的角色（标题与图标始终存在，不存储）。首次使用时创建。 */
    private var registeredRoles: LinkedHashMap<String, CYLAnimatedItemColorRole>? = null
    private var subclassRoleColors: HashMap<String, Array<Int?>>? = null
    private var subclassRoleBuiltIns: HashMap<String, Int>? = null

    private fun isItemRole(role: CYLAnimatedItemColorRole) = role.id == CYLAnimatedItemColorRole.title.id || role.id == CYLAnimatedItemColorRole.icon.id

    /**
     * [EN] Declares a colour role (iOS `register(_:)`): from now on the item resolves it with the one precedence chain and contrast step and applies it on every change.
     *      Applied once right away. The item's own `title` and `icon` roles are always registered (registering them does nothing).
     * [CN] 声明一个颜色角色（对应 iOS `register(_:)`）：此后条目按唯一的优先级链与对比度调整解析它，并在每次变化时应用。注册时立即应用一次。条目自己的 `title` 与 `icon`
     *      角色始终已注册（再注册不起作用）。
     */
    protected fun register(role: CYLAnimatedItemColorRole) {
        if (isItemRole(role)) return
        (registeredRoles ?: LinkedHashMap<String, CYLAnimatedItemColorRole>().also { registeredRoles = it })[role.id] = role
        role.apply(this, resolvedColor(role))
    }

    /**
     * [EN] The subclass-explicit colour of `role` for `state` (iOS `setSubclassColor(_:for:role:)`): counts as explicit (adapted by the contrast rule); a missing selected
     *      colour falls back to the normal one; null clears the state. For `title` / `icon` it is [setSubclassTitleColor] / [setSubclassIconColor].
     * [CN] `role` 在 `state` 下的子类显式颜色（对应 iOS `setSubclassColor(_:for:role:)`）：视为显式颜色（按对比度规则调整）；缺少选中颜色时回退到普通颜色；null 清除该状态。
     *      对 `title` / `icon` 即 [setSubclassTitleColor] / [setSubclassIconColor]。
     */
    protected fun setSubclassColor(color: Int?, state: CYLAnimatedItemTitleState, role: CYLAnimatedItemColorRole) {
        when (role.id) {
            CYLAnimatedItemColorRole.title.id -> setSubclassTitleColor(color, state)
            CYLAnimatedItemColorRole.icon.id -> setSubclassIconColor(color, state)
            else -> {
                val colors = subclassRoleColors ?: HashMap<String, Array<Int?>>().also { subclassRoleColors = it }
                colors.getOrPut(role.id) { arrayOfNulls(CYLAnimatedItemTitleState.values().size) }[state.ordinal] = color
                applyRole(role.id)
            }
        }
    }

    /**
     * [EN] The subclass built-in colour of `role` (iOS `applyBuiltInColor(_:role:)`): below every explicit colour, above the role's `componentBuiltIn`; adapted except while
     *      disabled. null removes it. For `title` / `icon` it is [applyTitleTintColor] / [applyIconTintColor].
     * [CN] `role` 的子类内置颜色（对应 iOS `applyBuiltInColor(_:role:)`）：低于所有显式颜色，高于角色的 `componentBuiltIn`；禁用时之外都会调整。null 移除。
     *      对 `title` / `icon` 即 [applyTitleTintColor] / [applyIconTintColor]。
     */
    protected fun applyBuiltInColor(color: Int?, role: CYLAnimatedItemColorRole) {
        when (role.id) {
            CYLAnimatedItemColorRole.title.id -> applyTitleTintColor(color)
            CYLAnimatedItemColorRole.icon.id -> applyIconTintColor(color)
            else -> {
                val builtIns = subclassRoleBuiltIns ?: HashMap<String, Int>().also { subclassRoleBuiltIns = it }
                if (color == null) builtIns.remove(role.id) else builtIns[role.id] = color
                applyRole(role.id)
            }
        }
    }

    private fun currentState() = when {
        !isEnabled -> CYLAnimatedItemTitleState.Disabled
        isSelected -> CYLAnimatedItemTitleState.Selected
        else -> CYLAnimatedItemTitleState.Normal
    }

    /**
     * [EN] THE resolver of a role in the current state (iOS `resolvedColor(_:state:)`), adapted by the contrast rule except the disabled look of a built-in level. For
     *      `title` it is the colour the title shows; for `icon` the effective icon colour (built-ins included, as `resolvedIconColor`), which tints the animation; the
     *      static image takes only explicit colours (tint spec v2).
     * [CN] 角色在当前状态下的唯一解析器（对应 iOS `resolvedColor(_:state:)`），按对比度规则调整（内置层的禁用外观除外）。对 `title` 是标题显示的颜色；对 `icon` 是有效图标颜色
     *      （含内置值，同 `resolvedIconColor`），用于动画着色；静态图片只使用显式颜色（着色规范 v2）。
     */
    fun resolvedColor(role: CYLAnimatedItemColorRole): CYLAnimatedItemResolvedColor {
        val configuration = resources.configuration
        val (color, level, builtInOfSubclass) = when (role.id) {
            CYLAnimatedItemColorRole.title.id -> titleResolution(configuration).let { Triple(it?.first, it?.second, subclassBuiltInTitle) }
            CYLAnimatedItemColorRole.icon.id -> iconResolution(configuration).let { Triple(it?.first, it?.second, subclassBuiltInIcon) }
            else -> roleResolution(role).let { Triple(it?.first, it?.second, subclassRoleBuiltIns?.get(role.id)) }
        }
        if (color == null || level == null) return CYLAnimatedItemResolvedColor(null, CYLAnimatedItemColorLevel.None)
        val publicLevel = when {
            level == ColorLevel.Explicit -> CYLAnimatedItemColorLevel.Explicit
            builtInOfSubclass != null && color == builtInOfSubclass -> CYLAnimatedItemColorLevel.SubclassBuiltIn
            else -> CYLAnimatedItemColorLevel.ComponentBuiltIn
        }
        val shown = if (level == ColorLevel.DisabledBuiltIn) color else contrastAdapted(color, role.kind, configuration)
        return CYLAnimatedItemResolvedColor(shown, publicLevel)
    }

    /** [EN] The precedence chain of a subclass role. [CN] 子类角色的优先级链。 */
    private fun roleResolution(role: CYLAnimatedItemColorRole): Pair<Int, ColorLevel>? {
        subclassRoleColors?.get(role.id)?.let { colors ->
            (if (isSelected) subclassColor(colors, true) ?: subclassColor(colors, false) else subclassColor(colors, false))?.let { return it to ColorLevel.Explicit }
        }
        val builtInLevel = if (!isEnabled) ColorLevel.DisabledBuiltIn else ColorLevel.BuiltIn
        subclassRoleBuiltIns?.get(role.id)?.let { return it to builtInLevel }
        return role.componentBuiltIn?.invoke(this, currentState())?.let { it to builtInLevel }
    }

    private fun applyRole(id: String) {
        val role = registeredRoles?.get(id) ?: return
        role.apply(this, resolvedColor(role))
    }

    /** [EN] Applies every registered subclass role. [CN] 应用所有已注册的子类角色。 */
    private fun applyRegisteredRoles() {
        val roles = registeredRoles ?: return
        for (role in roles.values.toList()) role.apply(this, resolvedColor(role))
    }

    /**
     * [EN] ONE refresh of every role (iOS `refreshColors()`): the title, the icon (and the animation tint), then the registered roles. The item calls it itself on every
     *      change of state, configuration, colours and background; a subclass calls it after changing what its `componentBuiltIn` reads.
     * [CN] 所有角色的唯一刷新（对应 iOS `refreshColors()`）：标题、图标（及动画着色），然后是已注册的角色。条目在状态、配置、颜色与背景每次变化时自己调用；子类在改变其
     *      `componentBuiltIn` 读取的内容后调用。
     */
    fun refreshColors() {
        applyTitleColor()
        applyIconColor()
    }

    private fun subclassColor(colors: Array<Int?>, forSelected: Boolean): Int? {
        if (!isEnabled) colors[CYLAnimatedItemTitleState.Disabled.ordinal]?.let { return it }
        return colors[(if (forSelected) CYLAnimatedItemTitleState.Selected else CYLAnimatedItemTitleState.Normal).ordinal]
    }

    private fun titleResolution(configuration: Configuration): Pair<Int, ColorLevel>? {
        titleColor?.let { return it to ColorLevel.Explicit }
        (if (isSelected) subclassColor(subclassTitleColors, true) ?: subclassColor(subclassTitleColors, false) else subclassColor(subclassTitleColors, false))?.let { return it to ColorLevel.Explicit }
        stackTitleColor?.let { return it to ColorLevel.Explicit }
        subclassBuiltInTitle?.let { return it to (if (!isEnabled) ColorLevel.DisabledBuiltIn else ColorLevel.BuiltIn) }
        if (!usesBuiltInColors) return null
        return when {
            showsDisabledColor() -> CYLAnimatedItemBuiltInColors.disabled(context, configuration) to ColorLevel.DisabledBuiltIn
            isSelected -> CYLAnimatedItemBuiltInColors.selected(context, configuration) to ColorLevel.BuiltIn
            else -> CYLAnimatedItemBuiltInColors.normal(context, configuration) to ColorLevel.BuiltIn
        }
    }

    /**
     * [EN] The title color in effect (NOT adapted to glass): `titleColor`, else the subclass-explicit one, else the stack's, else the subclass built-in, else the
     *      built-in of the state (selected, disabled, normal); null without any.
     * [CN] 生效的标题颜色（未按玻璃适配）：`titleColor`，其次子类显式的，再次堆叠的，再次子类内置的，最后当前状态的内置值（选中、禁用、普通）；都没有时为 null。
     */
    internal fun resolvedTitleColor(configuration: Configuration = resources.configuration): Int? = titleResolution(configuration)?.first

    /** [EN] Applies the title colour once, for an item nothing was set on (no state change ran). [CN] 为什么都没设置的条目（没有状态变化发生）应用一次标题颜色。 */
    private fun applyBuiltInTitleOnce() {
        if (!appliesTitleColor) applyTitleColor()
    }

    private fun applyTitleColor(configuration: Configuration = resources.configuration) {
        val color = titleResolution(configuration)?.let { (resolved, level) ->
            // [EN] Explicit and built-in colours (not the disabled look) are adapted where the contrast rule applies ([contrastApplies]). [CN] 显式与内置颜色（禁用外观除外）在对比度规则适用时（[contrastApplies]）才适配。
            if (level != ColorLevel.DisabledBuiltIn) contrastAdapted(resolved, CYLAnimatedItemColorKind.Title, configuration) else resolved
        }
        if (color != null) {
            if (!appliesTitleColor) defaultTitleColor = titleView.currentTextColor
            titleView.setTextColor(color)
            appliesTitleColor = true
        } else if (appliesTitleColor) {
            // [EN] Only a color this view set is undone. [CN] 只撤销本视图设置的颜色。
            defaultTitleColor?.let { titleView.setTextColor(it) }
            appliesTitleColor = false
        }
        // [EN] Every path that re-applies the title (state, configuration, background, contrast) re-applies the registered roles too. [CN] 每条重新应用标题的路径（状态、配置、背景、对比度）也重新应用已注册的角色。
        applyRegisteredRoles()
    }

    /**
     * [EN] The icon color in effect now, or null. [CN] 当前生效的图标颜色，没有时为 null。
     */
    val effectiveIconColor: Int?
        get() {
            if (isSelected) (selectedIconColor ?: subclassColor(subclassIconColors, true) ?: stackSelectedIconColor)?.let { return it }
            return iconColor ?: subclassColor(subclassIconColors, false) ?: stackIconColor
        }

    /**
     * [EN] The EXPLICIT icon colors (item, else the subclass channel, else stack, else host; NO built-ins) of the normal and the selected state. [CN] 普通与选中状态的显式图标颜色
     *      （条目，其次堆叠，再次宿主；不含内置值）。
     */
    val explicitIconColor: Int? get() = iconColor ?: subclassColor(subclassIconColors, false) ?: stackIconColor ?: hostIconColor
    val explicitSelectedIconColor: Int?
        get() = selectedIconColor ?: subclassColor(subclassIconColors, true) ?: (if (iconColor == null) subclassColor(subclassIconColors, false) else null) ?: stackSelectedIconColor ?: hostSelectedIconColor

    /**
     * [EN] The EFFECTIVE icon color of the current state for `configuration` (default: the item's own): disabled built-in while it shows the disabled
     *      look, else for a selected item the explicit selected color, else the built-in selected color; for an unselected one the explicit color, else the
     *      built-in normal color. A selected item with nothing set takes the built-in selected color, so selecting changes it. null only when the
     *      state has none and `usesBuiltInColors` is false. The static `image` is NOT recolored by it (`effectiveIconColor` is explicit only).
     * [CN] 当前状态在 `configuration`（默认：条目自己的）下的有效图标颜色：显示禁用外观时为内置禁用色；选中的条目为显式选中色，否则为内置选中色；
     *      未选中的条目为显式颜色，否则为内置普通色。什么都没设置的选中条目取内置选中色，所以选中会改变颜色。仅当该状态没有颜色且 `usesBuiltInColors` 为 false 时为 null。
     *      静态 `image` 不会被它重新着色（`effectiveIconColor` 仅为显式颜色）。
     */
    fun resolvedIconColor(configuration: Configuration = resources.configuration): Int? = iconResolution(configuration)?.first

    private fun iconResolution(configuration: Configuration): Pair<Int, ColorLevel>? {
        if (usesBuiltInColors && showsDisabledColor()) return CYLAnimatedItemBuiltInColors.disabled(context, configuration) to ColorLevel.DisabledBuiltIn
        (if (isSelected) explicitSelectedIconColor else explicitIconColor)?.let { return it to ColorLevel.Explicit }
        subclassBuiltInIcon?.let { return it to (if (!isEnabled) ColorLevel.DisabledBuiltIn else ColorLevel.BuiltIn) }
        if (!usesBuiltInColors) return null
        return (if (isSelected) CYLAnimatedItemBuiltInColors.selected(context, configuration) else CYLAnimatedItemBuiltInColors.normal(context, configuration)) to ColorLevel.BuiltIn
    }

        private fun applyIconColor(configuration: Configuration = resources.configuration) {
        // [EN] Explicit colour first (tints any image whole); else the rendering mode, unless the host put its own filter on the icon.
        // [CN] 先用显式颜色（整体着色任何图片）；否则按渲染方式，除非宿主在图标上设置了自己的滤镜。
        val foreignFilter = iconView.colorFilter != null && iconView.colorFilter !== appliedIconFilter
        val color = effectiveIconColor?.let { adaptedIconColor(it, configuration) }
            ?: if (foreignFilter) null else staticImageRenderingColor(configuration)
        if (color != null) {
            val filter = PorterDuffColorFilter(color, PorterDuff.Mode.SRC_IN)
            iconView.colorFilter = filter
            appliedIconFilter = filter
            appliesIconColor = true
        } else if (appliesIconColor) {
            // [EN] Only a filter this view set is cleared (a tab button or a host sets its own). [CN] 只清除本视图设置的滤镜（Tab 按钮或宿主会设置自己的）。
            if (!foreignFilter) iconView.clearColorFilter()
            appliedIconFilter = null
            appliesIconColor = false
        }
        refreshAnimationTint(configuration)
        invalidate()
    }

    /**
     * [EN] True when Liquid Glass is really drawn: the resolved background style is `LiquidGlass` (asked for AND `isLiquidGlassActive()`). Not based on the glass layer
     *      or the size (they change before layout): glass asked for but not drawn counts as flat. The one property the contrast rule reads.
     * [CN] 液态玻璃是否真正绘制：解析后的背景样式为 `LiquidGlass`（已请求且 `isLiquidGlassActive()` 为 true）。不依赖玻璃层或尺寸（它们在布局前就会变化）：
     *      请求了玻璃但未绘制算扁平。对比度规则读取的唯一属性。
     */
    val drawsLiquidGlass: Boolean get() = resolvedItemBackgroundStyle == CYLAnimatedItemBackgroundStyle.LiquidGlass

    /** [EN] The opposite of [drawsLiquidGlass]. [CN] [drawsLiquidGlass] 的反面。 */
    val drawsFlatBackground: Boolean get() = !drawsLiquidGlass

    /**
     * [EN] The contrast rule for a colour the host draws itself (a subclass's delete cross, a label of its own), iOS `adaptedForContrast(_:kind:)`: `color` unchanged unless the
     *      item is in night mode (its own resources configuration) AND draws Liquid Glass or a flat fill; then lifted to the least contrast of `kind` (icon 3:1, title 4.5:1)
     *      against it: the rendered glass (`itemBackgroundColor`, `itemGlassTintAlpha`) or the flat fill over black. The item applies it to its own title and icon colours.
     *      Limits: the rule only RAISES lightness: light mode is never adapted and there is no darkening rule, so LIGHT text on a mid-luminance fill (white on an orange fill,
     *      2.89:1; the countdown's light built-in fill) is NOT fixed (white is the cap; on a white 0.5-alpha fill the cap is 3.98:1). The disabled look is never adapted. Flat
     *      WITHOUT a fill (tab bar items, tags without a background) is NOT adapted: the item cannot know what is behind it. The 0.37 floor is glass-only. A fixed `animationTint`
     *      is adapted on glass only.
     * [CN] 宿主自己绘制的颜色（子类的删除叉号、自己的标签）适用的对比度规则，对应 iOS `adaptedForContrast(_:kind:)`：除非条目处于夜间模式（自己的资源配置）且绘制液态玻璃或扁平填充，
     *      否则原样返回 `color`；适用时按 `kind`（图标 3:1，标题 4.5:1）对照它提亮：实际渲染的玻璃（`itemBackgroundColor`、`itemGlassTintAlpha`）或叠在黑色上的扁平填充。
     *      条目自己的标题与图标颜色也使用该规则。限制：规则只会提亮：浅色模式从不调整，也没有压暗规则，所以中等亮度填充上的浅色文字（橙色填充上的白色 2.89:1；倒计时的浅色内置填充）
     *      不会被修复（白色是上限；白色 0.5 透明度填充上限为 3.98:1）。禁用外观从不调整。没有填充的扁平背景（Tab 栏条目、没有背景的标签）不调整：条目无法知道其后是什么。
     *      0.37 下限仅用于玻璃。固定的 `animationTint` 只在玻璃上调整。
     */
    fun adaptedForContrast(color: Int, kind: CYLAnimatedItemColorKind): Int = contrastAdapted(color, kind, resources.configuration)

    /**
     * [EN] The former name of [adaptedForContrast], kept (not deprecated, the other platforms use it); it forwards, so it now adapts on a flat fill too.
     * [CN] [adaptedForContrast] 的旧名称，保留（不弃用，其他平台使用该名称）；它转发调用，因此现在在扁平填充上也会调整。
     */
    fun adaptedOnGlass(color: Int, kind: CYLAnimatedItemColorKind): Int = adaptedForContrast(color, kind)

    /**
     * [EN] THE predicate of the contrast rule: `configuration` is night AND something known is behind the content: drawn Liquid Glass or a flat fill ([flatFill]).
     *      The glass-only rules (default tint, floor, a fixed `animationTint`) keep [drawsLiquidGlass].
     * [CN] 对比度规则的唯一判断：`configuration` 为夜间模式，且内容后面有已知的东西：绘制的液态玻璃或扁平填充（[flatFill]）。仅玻璃的规则（默认着色、下限、固定的 `animationTint`）仍用 [drawsLiquidGlass]。
     */
    private fun contrastApplies(configuration: Configuration): Boolean =
        (configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES && (drawsLiquidGlass || flatFill != null)

    /**
     * [EN] The fill a flat item draws now, or null: the pressed colour while it is drawn, else the countdown's built-in fill, else `itemBackgroundColor`; a clear fill
     *      (alpha 0) is null. Always null while glass is drawn.
     * [CN] 扁平条目当前绘制的填充，没有时为 null：绘制按下背景时为按下颜色，其次倒计时的内置填充，再次 `itemBackgroundColor`；透明填充（alpha 0）为 null。绘制玻璃时总为 null。
     */
    internal val flatFill: Int?
        get() {
            if (drawsLiquidGlass) return null
            val fill = (if (highlightApplies()) itemHighlightedBackgroundColor else null)
                ?: (if (itemStyle == CYLAnimatedItemStyle.Countdown) COUNTDOWN_FILL else itemBackgroundColor)
            return fill?.takeIf { (it ushr 24) != 0 }
        }

    /**
     * [EN] THE reference of the contrast rule: the rendered glass, or the flat fill over black. Only read while [contrastApplies].
     * [CN] 对比度规则的唯一对照：实际渲染的玻璃，或叠在黑色上的扁平填充。只在 [contrastApplies] 时读取。
     */
    private fun contrastReferenceLuminance(): Double {
        val fill = flatFill
        return if (drawsLiquidGlass || fill == null) CYLAnimatedItemContrast.renderedGlassReferenceLuminance(itemBackgroundColor, itemGlassTintAlpha)
        else CYLAnimatedItemContrast.flatReferenceLuminance(fill)
    }

    /** [EN] THE adaptation step. [CN] 唯一的调整步骤。 */
    private fun contrastAdapted(color: Int, kind: CYLAnimatedItemColorKind, configuration: Configuration): Int {
        if (!contrastApplies(configuration)) return color
        val minimum = if (kind == CYLAnimatedItemColorKind.Icon) CYLAnimatedItemContrast.ICON_MINIMUM_CONTRAST else CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST
        return CYLAnimatedItemContrast.adjusted(color, contrastReferenceLuminance(), minimum)
    }

    /** [EN] The reference the colours were last adapted to (null: the rule did not apply). [CN] 颜色上次适配所用的对照（null：规则不适用）。 */
    private var contrastKey: Double? = null

    /** [EN] Re-applies the colours when the reference (or whether the rule applies) changed: glass, fill, press, style. [CN] 对照（或规则是否适用）变化时重新应用颜色：玻璃、填充、按下、样式。 */
    private fun refreshContrastColorsIfNeeded() {
        val configuration = resources.configuration
        val key = if (contrastApplies(configuration)) contrastReferenceLuminance() else null
        if (key == contrastKey) return
        contrastKey = key
        applyTitleColor(configuration)
        applyIconColor(configuration)
    }

    /** [EN] An explicit icon colour, adapted where the contrast rule applies. [CN] 规则适用时调整显式图标颜色。 */
    private fun adaptedIconColor(color: Int, configuration: Configuration): Int = contrastAdapted(color, CYLAnimatedItemColorKind.Icon, configuration)

    // MARK: - Divider mode 分隔线模式

    /**
     * [EN] Internal, not API: `CYLAnimatedItemStackView` makes one item of this component per divider and puts it in this mode. The item
     *      then shows NO icon, title, animation or badge, only ONE line, 1 dp thick and `dividerLengthDp` long, centered in the item, and its
     *      own size is that line's (1 x length in a row, swapped in a column: `dividerAxis`). It takes no taps and is hidden from a screen
     *      reader. Line color: `stackDividerColor`, else the EXPLICIT normal icon color (own, the stack's, the host's) at `CYLAnimatedItemDividerAlpha` (0.6),
     *      else the built-in secondary text color (`CYLAnimatedItemBuiltInColors.divider`, contrast >= 3:1); resolved with the item's own night mode, re-resolved on every configuration or color change.
     * [CN] 内部使用，不是 API：`CYLAnimatedItemStackView` 为每条分隔线创建一个本组件的条目并设为该模式。此时条目不显示图标、标题、动画与角标，只有一条线，
     *      粗 1 dp、长 `dividerLengthDp`，在条目内居中，条目自身尺寸即这条线的尺寸（行中为 1 x 长度，列中互换：`dividerAxis`）。不接收点击，对读屏隐藏。
     *      线颜色：`stackDividerColor`，其次显式的普通图标颜色（自身、堆叠、宿主）以 `CYLAnimatedItemDividerAlpha`（0.6）的不透明度，最后是内置的次要文字色（`CYLAnimatedItemBuiltInColors.divider`，对比度 >= 3:1）；按条目自身的夜间模式解析，
     *      配置或颜色变化时重新解析。
     */
    internal var isDividerMode: Boolean = false
        set(value) {
            if (field == value) return
            field = value
            isClickable = !value
            isFocusable = !value
            importantForAccessibility = if (value) IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS else IMPORTANT_FOR_ACCESSIBILITY_AUTO
            requestLayout()
            invalidate()
        }
    internal var dividerLengthDp: Float = CYLAnimatedItemDividerLength
        set(value) { field = maxOf(0f, value); requestLayout(); invalidate() }
    internal var dividerAxis: CYLAnimatedItemAxis = CYLAnimatedItemAxis.Horizontal
        set(value) { if (field != value) { field = value; requestLayout(); invalidate() } }

    /**
     * [EN] The line color in effect for `configuration` (default: the item's own). [CN] 在 `configuration` 下生效的线颜色（默认：条目自身的）。
     */
    internal fun resolvedDividerColor(configuration: Configuration = resources.configuration): Int {
        stackDividerColor?.let { return it }
        explicitIconColor?.let { return CYLAnimatedItemBuiltInColors.withAlpha(it, CYLAnimatedItemDividerAlpha) }
        return CYLAnimatedItemBuiltInColors.divider(context, configuration)
    }

    private val dividerPaint = android.graphics.Paint()

    private fun dividerThickness() = max(1, dp(1f).roundToInt())

    override fun dispatchDraw(canvas: android.graphics.Canvas) {
        if (!isDividerMode) {
            super.dispatchDraw(canvas)
            if (showsOutlineWhenIncreaseContrast && isIncreaseContrastEnabled(context)) drawOutline(canvas)
            return
        }
        val vertical = dividerAxis == CYLAnimatedItemAxis.Horizontal
        val w = if (vertical) dividerThickness().toFloat() else dp(dividerLengthDp)
        val h = if (vertical) dp(dividerLengthDp) else dividerThickness().toFloat()
        val left = (width - w) / 2f
        val top = (height - h) / 2f
        dividerPaint.color = resolvedDividerColor()
        canvas.drawRect(left, top, left + w, top + h, dividerPaint)
    }

    // MARK: - Animation tint 动画着色

    /**
     * [EN] How the animation is drawn in the item's icon color, the same names and values as the `tint` option of the
     *      animation source (`CYLTabBarAnimationOptionTint`) and iOS `animationTint`. "title": drawn like a template image in
     *      `effectiveIconColor` (the selected icon color while selected). "#RRGGBB" / "#RRGGBBAA": that color on the UNSELECTED
     *      item, the selected item takes its selected icon color. Without an explicit icon color "title" uses the built-in color of the state (`CYLAnimatedItemBuiltInColors`; `resolvedIconColor`). Set, it replaces the option
     *      of the source URL; null (default) leaves the URL's option, and without one the file's own colors. Works before and after the file loads, for every engine
     *      (`CYLTabBarItemAnimationTint`).
     * [CN] 动画如何以条目的图标颜色绘制，名称与取值同动画来源的 `tint` 选项（`CYLTabBarAnimationOptionTint`）及 iOS 的 `animationTint`。
     *      "title"：像模板图片一样以 `effectiveIconColor` 绘制（选中时为选中图标颜色）。"#RRGGBB" / "#RRGGBBAA"：该颜色只用于未选中的条目，
     *      选中的条目使用其选中图标颜色。没有显式图标颜色时 "title" 使用该状态的内置颜色（`CYLAnimatedItemBuiltInColors`；`resolvedIconColor`）。设置后替换来源 URL 中的选项；null（默认）保留 URL 中的选项，没有选项时保持文件自身颜色。文件加载前后设置都有效，
     *      适用于所有引擎（`CYLTabBarItemAnimationTint`）。
     */
    var animationTint: String? = null
        set(value) { if (field != value) { field = value; refreshAnimationTint() } }

    /**
     * [EN] The night-mode color of a fixed `animationTint` (the `darkTint` option); not needed for "title". Re-applied when the
     *      configuration changes. null (default) keeps the URL's option.
     * [CN] 固定 `animationTint` 的夜间模式颜色（`darkTint` 选项）；"title" 不需要。配置变化时重新应用。null（默认）保留 URL 中的选项。
     */
    var animationDarkTint: String? = null
        set(value) { if (field != value) { field = value; refreshAnimationTint() } }

    /**
     * [EN] How an animation WITHOUT a tint is drawn (`automatic`, `alwaysTemplate`, `alwaysOriginal`; see `CYLAnimationRenderingMode`); an explicit
     *      `animationTint` (or the URL's `tint`) always wins. Precedence: this, else the stack's, else the URL option `renderingMode=`, else
     *      `Automatic`: tinted with `resolvedIconColor` only when the file is detected as one-color (`CYLAnimationColorCount`). null (default): inherit.
     * [CN] 没有着色的动画如何绘制（`automatic`、`alwaysTemplate`、`alwaysOriginal`；见 `CYLAnimationRenderingMode`）；显式的 `animationTint`（或 URL 的 `tint`）始终优先。
     *      优先级：本属性，其次堆叠的，再次 URL 选项 `renderingMode=`，最后 `Automatic`：仅当文件被检测为单色（`CYLAnimationColorCount`）时以 `resolvedIconColor` 着色。null（默认）：继承。
     */
    var animationRenderingMode: CYLAnimationRenderingMode? = null
        set(value) { if (field != value) { field = value; refreshAnimationTint() } }

    /**
     * [EN] The title colors of a host that draws this item's title (the tab bar), used as the icon colors of the tint table when
     *      the item has no icon color of its own; they never recolor the static icon. null (default): none.
     * [CN] 绘制本条目标题的宿主（TabBar）的标题颜色，条目自己没有图标颜色时作为着色真值表的图标颜色；不会改变静态图标的颜色。null（默认）：没有。
     */
    @RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
    var hostIconColor: Int? = null
        set(value) { if (field != value) { field = value; refreshAnimationTint(); invalidate() } }

    /**
     * [EN] The selected counterpart of `hostIconColor`. [CN] `hostIconColor` 的选中状态对应值。
     */
    @RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
    var hostSelectedIconColor: Int? = null
        set(value) { if (field != value) { field = value; refreshAnimationTint() } }

    /**
     * [EN] Draws the animation's tint for the current state (selection, icon colors, night mode): the options of the source
     *      (`#name=value` and `?name=value` alike) with `animationTint` / `animationDarkTint` on top, resolved by the
     *      item table `CYLTabBarItemAnimationTint.resolveItem` (tint spec v2). The explicit normal icon color is `iconColor`, else the stack's,
     *      else the host's title color; the selected one is `selectedIconColor`, else the stack's, else the host's; the effective color adds the
     *      built-ins. No tint: `animationRenderingMode` decides (default `Automatic`: tinted only when the file is detected as one-color,
     *      else the file's own colors, and a previous tint is removed). A subclass that makes the animation view itself (the tab button)
     *      calls it after setting `animationView`.
     * [CN] 按当前状态（选中、图标颜色、夜间模式）绘制动画着色：来源的选项（`#name=value` 与 `?name=value` 相同）加上 `animationTint` /
     *      `animationDarkTint`，由真值表 `CYLTabBarItemAnimationTint.resolve` 解析。普通图标颜色为 `iconColor`，其次堆叠的颜色，再次宿主的标题颜色；
     *      选中的为 `selectedIconColor`，其次堆叠的，再次宿主的。什么都没设置：保持文件自身颜色，并移除之前的着色。自己创建动画视图的子类
     *      （Tab 按钮）在设置 `animationView` 后调用。
     */
    fun refreshAnimationTint(configuration: Configuration = resources.configuration) {
        val view = animationView ?: return
        applyDisabledAnimationAlpha()
        CYLTabBarItemAnimationTint.setOverride(
            view,
            animationTint?.takeIf { it.isNotBlank() } ?: stackAnimationTint,
            animationDarkTint?.takeIf { it.isNotBlank() } ?: stackAnimationDarkTint,
        )
        CYLTabBarItemAnimationTint.setManaged(view)
        val source = CYLTabBarItemAnimationFactory.optionsOf(view)
            ?: animationURL?.takeIf { it.isNotBlank() }?.let { CYLTabBarAnimationFileAndOptions(it).second }.orEmpty()
        val options = CYLTabBarItemAnimationTint.effectiveOptions(view, source)
        val night = (configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        val tint = CYLTabBarItemAnimationTint.tintOption(options)
        val tintIsSet = CYLTabBarItemAnimationTint.isValidTint(tint)
        val mode = animationRenderingMode ?: stackAnimationRenderingMode ?: CYLTabBarItemAnimationTint.renderingModeOption(options) ?: CYLAnimationRenderingMode.Automatic
        // [EN] The file is read only when it decides (no tint, automatic). [CN] 只有在它起决定作用时才读取文件（没有着色、自动模式）。
        val kind = if (!tintIsSet && mode == CYLAnimationRenderingMode.Automatic) {
            CYLAnimationColorCount.kindOfSource(context, animationURL?.takeIf { it.isNotBlank() } ?: (view.cyl_getTag(CYLTabBarItemAnimationFailure.RESOURCE_TAG) as? String))
        } else CYLAnimationColorCount.Kind.Undetectable
        val resolution = iconResolution(configuration)
        val resolvedIcon = resolution?.first
        var color = CYLTabBarItemAnimationTint.resolveItem(
            tint, CYLTabBarItemAnimationTint.darkTintOption(options), mode, kind, isSelected, night,
            CYLTabBarItemAnimationTint.IconColors(resolvedIcon, explicitSelectedIconColor),
        )
        // [EN] Where the contrast rule applies: the icon colours (explicit and built-in) are adapted; a fixed tint only on drawn glass; the disabled look never.
        // [CN] 对比度规则适用时：图标颜色（显式与内置）会被调整；固定着色只在绘制玻璃时调整；禁用外观从不调整。
        val disabledLook = color == resolvedIcon && resolution?.second == ColorLevel.DisabledBuiltIn
        val fixedTint = tintIsSet && tint?.trim() != CYLTabBarItemAnimationTint.TINT_TITLE && !(isSelected && explicitSelectedIconColor != null)
        if (color != null && !disabledLook && (!fixedTint || drawsLiquidGlass)) color = contrastAdapted(color, CYLAnimatedItemColorKind.Icon, configuration)
        CYLTabBarItemAnimationTint.applyToAnimationView(view, color)
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        applyItemBackground()
        applyTitleColor(newConfig)
        applyIconColor(newConfig)
        invalidate()
    }

    override fun setEnabled(enabled: Boolean) {
        super.setEnabled(enabled)
        alpha = if (enabled) 1f else disabledAlpha
        applyDisabledAnimationAlpha()
        if (disabledWinsImage) updateIcon()
        invalidate()
        applyTitleColor()
        refreshAnimationTint()
        onItemStateChanged()
    }

    /**
     * [EN] Called when selected or enabled changes: subclasses update colors, backgrounds and borders here.
     * [CN] 选中或可用状态变化时调用：子类在这里更新颜色、背景与边框。
     */
    protected open fun onItemStateChanged() { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] Whether the animation is on screen: made, and not waiting for its file (a download). [CN] 动画是否已显示：已创建且不在等待其文件（下载）。
     */
    private fun animationShows() = animationView != null && !isShowingImageAfterAnimationEnd && !com.cyl.animateditem.CYLTabBarItemAnimationFailure.isLoading(animationView)

    /**
     * [EN] Shows the static image, else the placeholder, until the animation shows. A subclass that lays out its own
     *      icon (the tab bar's button) overrides it.
     * [CN] 在动画显示之前显示静态图片，没有时显示占位图。自行布局图标的子类（TabBar 的按钮）可以重写。
     */
    protected open fun updateIcon() {
        // [EN] The static image given, else the placeholder, until the animation shows (also while it downloads).
        // [CN] 在动画显示之前（包括下载期间）显示传入的静态图片，没有时显示占位图。
        val running = countdown.state == CYLAnimatedItemCountdownState.Running
        val shown = countdownImage.takeIf { running } ?: selectedImage.takeIf { isSelected && !(disabledWinsImage && !isEnabled) } ?: image
        iconView.setImageDrawable(shown ?: placeholderIfNeeded())
        iconView.visibility = if (animationShows()) View.INVISIBLE else View.VISIBLE
        // [EN] The shown image decides the static rendering mode (one colour or not), so a new image re-applies the icon colour.
        // [CN] 显示的图片决定静态渲染方式（是否单色），所以换图后重新应用图标颜色。
        if (tintsStaticImageAutomatically) applyIconColor()
    }

    // MARK: - Animation 动画

    /**
     * [EN] Builds the animation view for `animationURL` again (after a source, a size or a file change).
     * [CN] 重新为 `animationURL` 创建动画视图（来源、尺寸或文件变化后）。
     */
    fun reloadAnimation() {
        animationView?.let { removeView(it) }
        animationView = null
        playing = false
        endWatchGeneration++
        isShowingImageAfterAnimationEnd = false
        val url = animationURL
        val fileMissing = !url.isNullOrBlank() && localFileIsMissing(url)
        if (fileMissing && url != null) {
            resourceMissing(url.substringBefore('#'), if (localFileExists(url)) CYLResourceMissingReason.UNREADABLE else CYLResourceMissingReason.NOT_FOUND)
        }
        if (!url.isNullOrBlank() && !fileMissing) makeAnimationView(url)
        updateIcon()
        requestLayout()
    }

    /**
     * [EN] Creates and attaches the animation view of `url`, or reports why there is none (the static image stays).
     * [CN] 创建并添加 `url` 的动画视图；无法创建时报告原因（保留静态图片）。
     */
    private fun makeAnimationView(url: String) {
        val (w, h) = iconSizeDp?.let { it.width to it.height } ?: (24f to 24f)
        // [EN] No engine, no library or a file it cannot read: no view, the static image stays (an app's own source that
        //      throws is treated the same way). [CN] 没有引擎、没有动画库或文件无法读取：不创建视图，保留静态图片（App 自己的来源抛出异常时同样处理）。
        val made = try { animationSource.animationViewWithURL(context, url, CYLSize(w, h), ImageView.ScaleType.FIT_CENTER) } catch (error: RuntimeException) { null }
        if (made == null) {
            reportMissingEngine(url)
            return
        }
        made.cyl_hideFromAccessibility()
        addView(made, indexOfChild(iconView) + 1)
        animationView = made
        animationPlayer?.let { player ->
            player.loops = animationLoops
            if (animationSpeed > 0f) player.animationSpeed = animationSpeed
            player.progress = animationRestingProgress
        }
        refreshAnimationTint()
        if (isSelected) {
            if (showsLastFrameWhenSelected) showAnimationLastFrame() else if (drivesAnimationPlayback) playAnimation()
        }
    }

    private fun reportMissingEngine(url: String) {
        CYLAnimationEngines.warnMissingEngine(context, null, url)
        val type = CYLAnimationEngines.typeOf(null, url)
        resourceMissing(url.substringBefore('#'), when {
            type != null && !CYLAnimationEngines.isAvailable(type) -> CYLResourceMissingReason.ENGINE_LIBRARY_MISSING
            type != null -> CYLResourceMissingReason.UNREADABLE
            else -> CYLResourceMissingReason.DECODE_FAILED
        })
    }

    /**
     * [EN] Whether `url` names a local file (a path, `file://`, an asset) that is missing or empty: no animation view is made
     *      for it, so the static image or the placeholder shows at once. Remote files are checked by the animator, which
     *      reports a failed download (`CYLTabBarItemAnimationFailure`).
     * [CN] `url` 是否指向不存在或为空的本地文件（路径、`file://`、asset）：不为其创建动画视图，立即显示静态图片或占位图。远程文件由 animator 检查，
     *      下载失败时报告（`CYLTabBarItemAnimationFailure`）。
     */
    protected open fun localFileIsMissing(url: String): Boolean {
        val file = url.substringBefore('#')
        fun missing(path: String?) = path == null || java.io.File(path).let { !it.isFile || it.length() == 0L }
        return when {
            file.startsWith(ANDROID_ASSET_PREFIX) -> try {
                context.assets.open(file.removePrefix(ANDROID_ASSET_PREFIX)).use { it.read() < 0 }
            } catch (error: java.io.IOException) { true }
            file.startsWith("file:") -> missing(android.net.Uri.parse(file).path)
            // [EN] An absolute path ("/..." on Android; also a drive path when the JVM tests run on Windows). [CN] 绝对路径（Android 上为 "/..."；JVM 测试在 Windows 上运行时也包括盘符路径）。
            java.io.File(file).isAbsolute -> missing(file)
            else -> false
        }
    }

    /**
     * [EN] Whether the local file of `url` exists (so a missing one is empty rather than absent). [CN] `url` 的本地文件是否存在（不存在与存在但为空的区别）。
     */
    private fun localFileExists(url: String): Boolean {
        val file = url.substringBefore('#')
        return when {
            file.startsWith(ANDROID_ASSET_PREFIX) -> try { context.assets.open(file.removePrefix(ANDROID_ASSET_PREFIX)).close(); true } catch (error: java.io.IOException) { false }
            file.startsWith("file:") -> android.net.Uri.parse(file).path?.let { java.io.File(it).isFile } == true
            else -> java.io.File(file).isFile
        }
    }

    override fun playAnimation() {
        val player = animationPlayer ?: return
        if (respectsReduceMotion && isReduceMotionEnabled()) {
            // [EN] Reduce Motion: the state frame instead of a run (selected: the last frame, else the resting one). [CN] 减弱动态效果：显示状态帧而不是播放（选中：最后一帧，否则静止帧）。
            if (isSelected) { showAnimationLastFrame() } else {
                showAnimationAgain(); playing = false; endWatchGeneration++; player.progress = animationRestingProgress
            }
            return
        }
        showAnimationAgain()
        playing = true
        pausedByUser = false
        player.loops = animationLoops
        if (animationSpeed > 0f) player.animationSpeed = animationSpeed
        player.play()
        watchForAnimationEnd()
        PlayingViews.add(this)
        postAnimationEvent(AnimationEvents.didStart, mapOf("loops" to animationLoops))
    }

    /**
     * [EN] Pauses the running animation on its current frame and posts `cyl.animation.didPause`. Nothing happens when no animation plays
     *      or the engine has no pause. [CN] 把正在播放的动画暂停在当前帧，并发出 `cyl.animation.didPause`。没有动画在播放或引擎不支持暂停时无事发生。
     */
    fun pauseAnimation() {
        val player = animationPlayer ?: return
        if (!playing || pausedByUser) return
        pausedByUser = true
        player.pause()
        postAnimationEvent(AnimationEvents.didPause, null)
    }

    /**
     * [EN] Continues an animation paused by [pauseAnimation] and posts `cyl.animation.didResume`. [CN] 继续被 [pauseAnimation] 暂停的动画，并发出 `cyl.animation.didResume`。
     */
    fun resumeAnimation() {
        val player = animationPlayer ?: return
        if (!pausedByUser) return
        pausedByUser = false
        player.resume()
        postAnimationEvent(AnimationEvents.didResume, null)
    }

    /**
     * [EN] Posts a moment of this animation through CYLDeallocBlockExecutor: `LifecycleRegistry.of(view).addCustomCallback(AnimationEvents.didPause)`
     *      for one item, or `LifecycleCenter.addCustomCallback` for every item. [CN] 通过 CYLDeallocBlockExecutor 发出本动画的时机事件。
     */
    private fun postAnimationEvent(name: String, userInfo: Map<String, Any?>?) {
        LifecycleRegistry.of(this).postLifecycleEvent(name, userInfo)
    }

    override fun restartAnimation() {
        animationPlayer?.progress = 0f
        playAnimation()
    }

    override fun stopAnimation() {
        val player = animationPlayer ?: return
        val wasPlaying = playing
        playing = false
        pausedByUser = false
        endWatchGeneration++
        showAnimationAgain()
        player.stop()
        player.progress = animationRestingProgress
        PlayingViews.remove(this)
        if (wasPlaying) postAnimationEvent(AnimationEvents.didStop, mapOf("finished" to false))
    }

    override fun showAnimationLastFrame() {
        playing = false
        endWatchGeneration++
        showAnimationAgain()
        animationPlayer?.showLastFrame()
    }

    /**
     * [EN] Watches a play-once pass on the display's frame clock until it ends: the player's `isPlaying` goes false after it
     *      was seen true (an engine may start a frame late), or, without `isPlaying`, `progress` reaches 1 after it was
     *      below. Only when `showsImageWhenAnimationEnds` or `animationEndListener` needs it.
     * [CN] 基于显示帧时钟检测一次只播放一次的动画，直到结束：播放器的 `isPlaying` 在曾为 true 之后变为 false（引擎可能晚一帧开始），
     *      或在没有 `isPlaying` 时 `progress` 从小于 1 到达 1。只在 `showsImageWhenAnimationEnds` 或 `animationEndListener` 需要时检测。
     */
    private fun watchForAnimationEnd() {
        val generation = ++endWatchGeneration
        // [EN] Always watched now: `cyl.animation.didStop` (finished) needs the end of a play-once pass too. [CN] 现在总是检测：`cyl.animation.didStop`（finished）也需要知道只播放一次的动画何时结束。
        var started = false
        lateinit var check: Runnable
        check = Runnable {
            if (generation != endWatchGeneration || !playing) return@Runnable
            // [EN] A paused animation is not an ended one. [CN] 暂停的动画不等于已结束的动画。
            if (pausedByUser) {
                postOnAnimationDelayed(check, END_WATCH_INTERVAL_MS)
                return@Runnable
            }
            // [EN] Looping: keep watching, a later `animationLoops = false` lets the pass end. [CN] 循环时继续检测，之后关闭循环会让这一遍结束。
            val player = animationPlayer ?: return@Runnable
            val running = !animationLoops && isPassRunning(player)
            if (running) started = true
            val ended = !animationLoops && !running && started
            if (ended) animationDidEnd() else postOnAnimationDelayed(check, END_WATCH_INTERVAL_MS)
        }
        postOnAnimationDelayed(check, END_WATCH_INTERVAL_MS)
    }

    /**
     * [EN] Whether the player is still playing: its `isPlaying`, or, without it, `progress` below the end.
     * [CN] 播放器是否仍在播放：其 `isPlaying`，没有时则 `progress` 小于结束值。
     */
    private fun isPassRunning(player: CYLTabBarItemAnimationPlayer): Boolean =
        player.isPlaying ?: (player.progress < END_PROGRESS)

    private fun animationDidEnd() {
        playing = false
        endWatchGeneration++
        PlayingViews.remove(this)
        postAnimationEvent(AnimationEvents.didStop, mapOf("finished" to true))
        if (showsImageWhenAnimationEnds && animationView != null) {
            isShowingImageAfterAnimationEnd = true
            animationView?.visibility = View.INVISIBLE
            updateIcon()
            requestLayout()
        }
        animationEndListener?.onAnimationEnd(this)
        playerEndedCallback?.invoke()
    }

    /**
     * [EN] Shows the animation again in place of the still image shown after its end. [CN] 重新显示动画，替换结束后显示的静态图片。
     */
    private fun showAnimationAgain() {
        if (!isShowingImageAfterAnimationEnd) return
        isShowingImageAfterAnimationEnd = false
        animationView?.visibility = View.VISIBLE
        updateIcon()
        requestLayout()
    }

    /**
     * [EN] The engine could not load the file: drop the animation and show the static icon. [CN] 引擎无法加载文件：移除动画并显示静态图标。
     */
    override fun cyl_animationViewDidLoad(animationView: View) {
        if (animationView !== this.animationView) return
        refreshAnimationTint()
        updateIcon()
        requestLayout()
        if (isSelected) { if (showsLastFrameWhenSelected) showAnimationLastFrame() else if (drivesAnimationPlayback) playAnimation() }
        onAnimationLoaded?.invoke()
    }

    override fun cyl_animationViewDidFail(animationView: View) {
        // [EN] The tab bar's own animation view (not `this.animationView`) reports the file it was made for. [CN] TabBar 自己的动画视图（不是 `this.animationView`）报告其对应的文件。
        if (animationView !== this.animationView) {
            CYLTabBarItemAnimationFailure.missingResource(animationView)?.let { (resource, reason) -> resourceMissing(resource, reason) }
            return
        }
        animationURL?.takeIf { it.isNotBlank() }?.let {
            val reason = CYLTabBarItemAnimationFailure.reasonOf(animationView)
            resourceMissing(it.substringBefore('#'), reason)
        }
        removeView(animationView)
        this.animationView = null
        playing = false
        updateIcon()
        requestLayout()
        onAnimationFailed?.invoke()
    }

    // MARK: - Touches 触摸

    override fun onInterceptTouchEvent(event: MotionEvent): Boolean {
        // [EN] A drag that starts on the accessory still drags the item. [CN] 从附加图标开始的拖拽仍然拖动条目。
        if (isDragEnabled && event.actionMasked == MotionEvent.ACTION_MOVE && !dragging && exceedsSlop(event)) return true
        if (event.actionMasked == MotionEvent.ACTION_DOWN) { downX = event.rawX; downY = event.rawY }
        return false
    }

    private fun exceedsSlop(event: MotionEvent) = abs(event.rawX - downX) > touchSlop || abs(event.rawY - downY) > touchSlop

    @android.annotation.SuppressLint("ClickableViewAccessibility") // [EN] Taps go through performClick. [CN] 点击通过 performClick 触发。
    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (!isEnabled || isDividerMode) return false
        if (onItemTouchEvent(event)) return true
        val consumed = when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> { downX = event.rawX; downY = event.rawY; dragging = false; longPressed = false; isPressed = true; false }
            MotionEvent.ACTION_MOVE -> isDragEnabled && handleDragMove(event)
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> handleRelease(event)
            else -> false
        }
        if (consumed) return true
        detector.onTouchEvent(event)
        return true
    }

    /**
     * [EN] A move: starts the drag past the touch slop (unless a long press fired or the listener refuses), then moves.
     *      True when the drag consumed the event.
     * [CN] 移动：超过触摸阈值后开始拖拽（除非已触发长按或监听者拒绝），然后移动。拖拽消费事件时返回 true。
     */
    private fun handleDragMove(event: MotionEvent): Boolean {
        if (!dragging && exceedsSlop(event) && !longPressed && gestureListener?.shouldBeginDrag(this) != false) {
            dragging = true
            isPressed = false
            parent?.requestDisallowInterceptTouchEvent(true)
            gestureListener?.onDragBegan(this)
        }
        if (!dragging) return false
        val dx = event.rawX - downX
        val dy = event.rawY - downY
        if (dragMovesView) { translationX = dx; translationY = dy }
        gestureListener?.onDragChanged(this, dx, dy)
        return true
    }

    /**
     * [EN] Up or cancel: ends a drag (the view springs back) or a long press. True when either consumed the event.
     * [CN] 抬起或取消：结束拖拽（视图弹回）或长按。任一消费事件时返回 true。
     */
    private fun handleRelease(event: MotionEvent): Boolean {
        isPressed = false
        if (dragging) {
            dragging = false
            val dx = event.rawX - downX
            val dy = event.rawY - downY
            if (dragMovesView) animate().translationX(0f).translationY(0f).setDuration(200).start()
            gestureListener?.onDragEnded(this, dx, dy, event.actionMasked == MotionEvent.ACTION_CANCEL)
            return true
        }
        if (longPressed) { longPressed = false; return true }
        return false
    }

    /**
     * [EN] A subclass's own gestures: return true to consume the event before the built-in tap, long press and drag.
     * [CN] 子类自己的手势：返回 true 表示在内置的点击、长按与拖拽之前消费该事件。
     */
    protected open fun onItemTouchEvent(event: MotionEvent): Boolean = false

    override fun performClick(): Boolean {
        if (isDividerMode) return false
        val handled = super.performClick()
        gestureListener?.onItemTapped(this)
        // [EN] After the listener handled the tap (send the code there), the countdown starts. [CN] 监听者处理点击（在那里发送验证码）之后开始倒计时。
        if (itemStyle == CYLAnimatedItemStyle.Countdown && startsCountdownOnTap && countdown.state != CYLAnimatedItemCountdownState.Running) startCountdown()
        return handled
    }

    // MARK: - Countdown logic 倒计时逻辑

    /**
     * [EN] Starts (or restarts) for `durationSeconds` (default `countdownDuration`, e.g. the server's "retry after"). Switches
     *      the view to the countdown style when it is not. [CN] 开始（或重新开始）`durationSeconds` 秒（默认 `countdownDuration`，
     *      例如服务器返回的「多少秒后重试」）。视图不是倒计时样式时切换为倒计时样式。
     */
    @JvmOverloads
    fun startCountdown(durationSeconds: Int = countdownDuration) {
        if (itemStyle != CYLAnimatedItemStyle.Countdown) itemStyle = CYLAnimatedItemStyle.Countdown
        countdown.start(durationSeconds)
    }

    /**
     * [EN] Stops and shows the idle title, with no finish callback. [CN] 停止并显示待机标题，不触发结束回调。
     */
    fun resetCountdown() {
        countdown.reset()
    }

    /**
     * [EN] Reads the clock now (done by the view itself on every tick and when the window is shown again).
     * [CN] 立即读取时钟（视图自己会在每次 tick 与窗口再次显示时读取）。
     */
    fun refreshCountdown() {
        countdown.refresh()
    }

    private fun countdownStyleChanged() {
        if (itemStyle == CYLAnimatedItemStyle.Countdown) {
            // [EN] The default look of a countdown button: a rounded border and a light background, as the original SMSCodeButton.
            // [CN] 倒计时按钮的默认外观：圆角边框与浅色背景，与最初的 SMSCodeButton 一致。
            if (paddingLeft == 0 && paddingTop == 0 && paddingRight == 0 && paddingBottom == 0) {
                setPadding(dp(12f).roundToInt(), dp(8f).roundToInt(), dp(12f).roundToInt(), dp(8f).roundToInt())
            }
            countdown.storage = countdownStorage ?: sharedPreferencesStorage
            countdownChanged()
            countdown.setCacheKey(countdownCacheKey)
        } else {
            countdown.reset()
            background = null
            titleView.minWidth = 0
            refreshContrastColorsIfNeeded()
        }
        requestLayout()
    }

    /**
     * [EN] The state or the seconds changed: the title, the icon, the look, enabled and the ticker.
     * [CN] 状态或秒数变化：标题、图标、外观、可用状态与定时 tick。
     */
    private fun countdownChanged() {
        if (itemStyle != CYLAnimatedItemStyle.Countdown) return
        val running = countdown.state == CYLAnimatedItemCountdownState.Running
        if (running && restingTitleColor == null) restingTitleColor = titleView.currentTextColor
        if (!running) restingTitleColor?.let { titleView.setTextColor(it); restingTitleColor = null }
        title = when (countdown.state) {
            CYLAnimatedItemCountdownState.Running -> CYLAnimatedItemCountdown.text(countdownRunningTitleFormat, countdown.shownSeconds)
            CYLAnimatedItemCountdownState.Finished -> countdownFinishedTitle
            CYLAnimatedItemCountdownState.Idle -> countdownIdleTitle
        }
        if (running && isEnabled) { countdownDisabledIt = true; isEnabled = false }
        if (!running && countdownDisabledIt) { countdownDisabledIt = false; isEnabled = true }
        updateIcon()
        applyCountdownAppearance()
        updateCountdownTitleWidth()
        removeCallbacks(countdownTicker)
        if (running) postDelayed(countdownTicker, CYLAnimatedItemCountdown.TICK_INTERVAL_MILLIS)
        requestLayout()
    }

    private fun refreshCountdownTitle() {
        if (itemStyle == CYLAnimatedItemStyle.Countdown) countdownChanged()
    }

    /**
     * [EN] The border, the background and the title color of the countdown style, for the state it is in.
     * [CN] 倒计时样式在当前状态下的边框、背景与标题颜色。
     */
    private fun applyCountdownAppearance() {
        if (itemStyle != CYLAnimatedItemStyle.Countdown) return
        val running = countdown.state == CYLAnimatedItemCountdownState.Running
        background = GradientDrawable().apply {
            cornerRadius = dp(6f)
            setColor(COUNTDOWN_FILL)
            setStroke(max(1, dp(0.5f).roundToInt()), if (running) Color.LTGRAY else countdownBorderColor)
        }
        // [EN] Before the running colour, which must win. [CN] 在倒计时颜色之前，倒计时颜色必须优先。
        refreshContrastColorsIfNeeded()
        if (running) titleView.setTextColor(countdownRunningTitleColor)
    }

    /**
     * [EN] The widest title the countdown shows (idle, finished, the running one with the widest digits of the duration) is the
     *      title's minimum width, so the view keeps its width while the digits change. [CN] 倒计时会显示的最宽标题（待机、结束、
     *      以时长位数的最宽数字组成的倒计时）作为标题的最小宽度，使视图在数字变化时保持宽度。
     */
    private fun updateCountdownTitleWidth() {
        if (itemStyle != CYLAnimatedItemStyle.Countdown) return
        val digits = max(1, countdownDuration).toString().length
        val widest = "8".repeat(digits).toInt()
        titleView.minWidth = maxOf(
            titleWidth(countdownIdleTitle),
            titleWidth(countdownFinishedTitle),
            titleWidth(CYLAnimatedItemCountdown.text(countdownRunningTitleFormat, widest)),
        )
    }

    override fun onWindowVisibilityChanged(visibility: Int) {
        super.onWindowVisibilityChanged(visibility)
        // [EN] The window is shown again (the app returns from the background): read the clock at once. [CN] 窗口再次显示（App 从后台返回）：立即读取时钟。
        if (visibility == View.VISIBLE) countdown.refresh()
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        countdown.refresh()
        if (countdown.state == CYLAnimatedItemCountdownState.Running) {
            removeCallbacks(countdownTicker)
            postDelayed(countdownTicker, CYLAnimatedItemCountdown.TICK_INTERVAL_MILLIS)
        }
    }

    override fun onDetachedFromWindow() {
        removeCallbacks(countdownTicker)
        super.onDetachedFromWindow()
    }

    // MARK: - Badge 角标

    /**
     * [EN] null: no badge (default); "": a dot; otherwise the text (a number above the maximum shows "99+"). Sets the badge on [badgeAnchorView] through
     *      `:cylbadge`; `cylShowBadgeValue(...)` on the item reaches the same view. Written statically, not compiled yet.
     * [CN] null：没有角标（默认）；""：红点；否则为文字（超过最大值的数字显示 "99+"）。通过 `:cylbadge` 在 [badgeAnchorView] 上设置角标；在 item 上调用
     *      `cylShowBadgeValue(...)` 落在同一个视图。静态编写，尚未编译。
     */
    var badgeValue: String? = null
        set(value) {
            if (field == value) return
            field = value
            updateBadge()
        }

    /**
     * [EN] The badge's style, the keys of [CYLBadgeAttributeKey]. null: the defaults of `CYLBadgeAppearance`.
     * [CN] 角标样式，键为 [CYLBadgeAttributeKey]。null：`CYLBadgeAppearance` 的默认值。
     */
    var badgeAttributes: Map<String, Any?>? = null
        set(value) {
            field = value
            updateBadge()
        }

    /**
     * [EN] false (default): the badge is not measured. true: measuring reserves its overhang on both sides (D6).
     * [CN] false（默认）：测量时不计入角标。true：测量时在两侧预留角标伸出的部分（D6）。
     */
    var reservesBadgeSpace: Boolean = false
        set(value) {
            if (field == value) return
            field = value
            requestLayout()
        }

    /** [EN] True while a badge is shown. [CN] 显示角标时为 true。 */
    val isShowingBadge: Boolean get() = storedBadgeAnchor?.cylIsShowBadge() == true

    private var storedBadgeAnchor: FrameLayout? = null

    /**
     * [EN] A transparent view kept on the icon itself at every layout, above the icon and the animation view; created once, never replaced, so an image or
     *      animation switch never hides the badge. Not measured, not clickable, hidden from accessibility. A subclass that overrides [layoutContent] calls
     *      `placeIcon`, which places it.
     * [CN] 在每次布局时保持在图标本身之上的透明视图，位于图标与动画视图上方；只创建一次、从不替换，因此切换图片或动画不会隐藏角标。不参与测量、不可点击、对无障碍隐藏。
     *      重写 [layoutContent] 的子类调用 `placeIcon`，由它放置锚点。
     */
    val badgeAnchorView: FrameLayout
        get() = storedBadgeAnchor ?: FrameLayout(context).apply {
            clipChildren = false
            clipToPadding = false
            isClickable = false
            isFocusable = false
            importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
            cylBadgeState.mirrorsInRightToLeft = true
            this@CYLAnimatedItemView.addView(this, LayoutParams(0, 0))
            storedBadgeAnchor = this
        }

    private fun updateBadge() {
        val value = badgeValue
        if (value == null) {
            storedBadgeAnchor?.cylClearBadge()
        } else {
            val attributes = badgeAttributes.orEmpty()
            val anchor = badgeAnchorView
            anchor.cylApplyBadgeAttributes(attributes)
            anchor.cylShowBadgeValue(value, CYLBadgeAttributeKey.animationType(attributes))
            // [EN] The border is a property of the badge view, which exists only now. [CN] 边框是角标视图的属性，它到现在才存在。
            anchor.cylApplyBadgeAttributes(attributes)
        }
        clipChildren = false
        requestLayout()
        updateAccessibility()
    }

    /** [EN] The badge description read after the title, from `:cylbadge`. [CN] 在标题之后朗读的角标描述，来自 `:cylbadge`。 */
    private fun badgeAccessibilityText(): String? = badgeValue?.let { CYLBadgeAccessibilityDescription(context, it) }

    /**
     * [EN] The extra room [reservesBadgeSpace] asks for when measuring: the badge's radius on each side, in px. Zero when off or without a badge.
     * [CN] 开启 [reservesBadgeSpace] 时测量要求的额外空间：每侧一个角标半径（px）。关闭或没有角标时为零。
     */
    protected fun badgeReservePx(): Int =
        if (reservesBadgeSpace && badgeValue != null) (storedBadgeAnchor?.cylBadgeRadius ?: 0f).let { dp(it).roundToInt() } else 0

    // MARK: - Accessibility 无障碍

    /**
     * [EN] What a screen reader says for the item: the title by default. Subclasses add a badge, a count or a state.
     * [CN] 读屏朗读的条目文本：默认为标题。子类可以加入角标、数量或状态。
     */
    protected open fun accessibilityText(): CharSequence = CYLAnimatedItemAccessibilityText(title, badgeAccessibilityText())

    /**
     * [EN] Updates the content description after a change the view cannot see (a subclass's badge, for example).
     * [CN] 在视图无法感知的变化（例如子类的角标）之后更新 contentDescription。
     */
    fun updateAccessibility() {
        contentDescription = accessibilityText()
    }

    override fun onInitializeAccessibilityNodeInfo(info: AccessibilityNodeInfo) {
        super.onInitializeAccessibilityNodeInfo(info)
        // [EN] A button while it takes taps; text otherwise (an item a container made not clickable, e.g. a hint in
        //      `CYLAnimatedItemStackView`). [CN] 接收点击时为按钮；否则为文字（容器设为不可点击的条目，例如 `CYLAnimatedItemStackView` 中的提示）。
        info.className = if (isClickable) Button::class.java.name else android.widget.TextView::class.java.name
        info.isSelected = isSelected
    }

    /**
     * [EN] The measured width of a title in this view's title style, for callers that size items before creating them.
     * [CN] 以本视图标题样式测得的标题宽度，供在创建条目前计算尺寸的调用方使用。
     */
    fun titleWidth(text: CharSequence?): Int = if (text.isNullOrEmpty()) 0 else ceil(titleView.paint.measureText(text.toString())).toInt()

    /**
     * [EN] The views that play now, held weakly: what `pausesAnimationsWhileUserScrolls` pauses and resumes. [CN] 正在播放的视图（弱引用）：`pausesAnimationsWhileUserScrolls` 暂停与恢复的对象。
     */
    private object PlayingViews {
        private val views = java.util.WeakHashMap<CYLAnimatedItemView, Boolean>()
        private var scrollObservers: (() -> Unit)? = null

        fun add(view: CYLAnimatedItemView) { synchronized(views) { views[view] = true } }
        fun remove(view: CYLAnimatedItemView) { synchronized(views) { views.remove(view) } }
        private fun snapshot(): List<CYLAnimatedItemView> = synchronized(views) { views.keys.toList() }

        fun pauseAll() = snapshot().forEach { it.pauseAnimation() }
        fun resumeAll() = snapshot().forEach { it.resumeAnimation() }

        fun setPausesWhileScrolling(enabled: Boolean) {
            scrollObservers?.invoke()
            scrollObservers = if (enabled) LifecycleCenter.whileUserScrolls(key = "cyl.animatedItem.scroll", pause = ::pauseAll, resume = ::resumeAll) else null
        }

        val pausesWhileScrolling: Boolean get() = scrollObservers != null
    }

    // MARK: Options (defaults off / null) 选项（默认关闭 / null）

    /**
     * [EN] The pressed background (a solid ARGB colour) drawn while the item is pressed AND enabled, clipped to the item's corner radius, over the glass or the flat colour
     *      and under the content. null (default): no pressed look. iOS `itemHighlightedBackgroundColor`.
     * [CN] 条目被按下且可用时绘制的按下背景（ARGB 纯色），按条目圆角裁剪，位于玻璃或扁平颜色之上、内容之下。null（默认）：没有按下外观。对应 iOS `itemHighlightedBackgroundColor`。
     */
    var itemHighlightedBackgroundColor: Int? = null
        set(value) { if (field != value) { field = value; refreshContrastColorsIfNeeded(); invalidate() } }

    /**
     * [EN] The animation view's alpha while the item is disabled (0...1); null (default) is 1 (the view's own `disabledAlpha` still applies to the whole item).
     *      iOS `itemDisabledAnimationAlpha`.
     * [CN] 条目禁用时动画视图的透明度（0...1）；null（默认）为 1（整个条目仍受视图自己的 `disabledAlpha` 影响）。对应 iOS `itemDisabledAnimationAlpha`。
     */
    var itemDisabledAnimationAlpha: Float? = null
        set(value) { if (field != value) { field = value; applyDisabledAnimationAlpha() } }

    /**
     * [EN] true: a selected item shows the LAST frame of its animation instead of playing it. A self-driven item (`drivesAnimationPlayback`)
     *      shows it instead of playing; a host-driven item shows it too when it becomes selected and again whenever its animation view is
     *      made or has loaded (a frame set before the animation file has loaded is lost, so it is applied again then). A host-driven item
     *      without this option gets nothing automatic. Default false. iOS `showsLastFrameWhenSelected`.
     * [CN] 为 true 时，选中的条目显示动画的最后一帧而不是播放。自行驱动播放（`drivesAnimationPlayback`）的条目显示最后一帧而不播放；宿主驱动的条目
     *      在被选中时同样显示最后一帧，并在其动画视图创建或加载完成时再次应用（动画文件加载完成之前设置的帧会丢失，所以此时重新应用）。
     *      没有此选项的宿主驱动条目不会有任何自动行为。默认 false。对应 iOS `showsLastFrameWhenSelected`。
     */
    var showsLastFrameWhenSelected: Boolean = false
        set(value) {
            if (field == value) return
            field = value
            if (isSelected && animationView != null) {
                if (drivesAnimationPlayback) { if (value) showAnimationLastFrame() else restartAnimation() } else if (value) showAnimationLastFrame()
            }
        }

    /**
     * [EN] true: while the system Increase Contrast setting is on, an outline in the title colour is drawn around the item. Needs API 34 or later
     *      (`UiModeManager.getContrast()`, a public API); below it the setting cannot be read and the option has no effect. Default false.
     *      iOS `showsOutlineWhenIncreaseContrast`.
     * [CN] 为 true 时，系统「增强对比度」开启期间，在条目周围绘制标题颜色的轮廓。需要 API 34 及以上（公开 API `UiModeManager.getContrast()`）；更低版本读不到该设置，选项不起作用。
     *      默认 false。对应 iOS `showsOutlineWhenIncreaseContrast`。
     */
    var showsOutlineWhenIncreaseContrast: Boolean = false
        set(value) { if (field != value) { field = value; invalidate() } }

    /**
     * [EN] true: `playAnimation` shows the state frame (selected: the last frame, else the resting frame) instead of running while the system animations are off
     *      (`ValueAnimator.areAnimatorsEnabled()`: Remove animations / animator duration scale 0). Default false. iOS `respectsReduceMotion`.
     * [CN] 为 true 时，系统动画关闭（`ValueAnimator.areAnimatorsEnabled()`：移除动画 / 动画时长缩放为 0）期间，`playAnimation` 显示状态帧（选中：最后一帧，否则静止帧）而不是播放。
     *      默认 false。对应 iOS `respectsReduceMotion`。
     */
    var respectsReduceMotion: Boolean = false

    /**
     * [EN] true: `selectedImage` shows only while the item is selected AND enabled (a disabled selected item shows `image`). Default false. iOS `disabledWinsImage`.
     * [CN] 为 true 时，`selectedImage` 只在条目选中且可用时显示（禁用的选中条目显示 `image`）。默认 false。对应 iOS `disabledWinsImage`。
     */
    var disabledWinsImage: Boolean = false
        set(value) { if (field != value) { field = value; updateIcon() } }

    private fun applyDisabledAnimationAlpha() {
        animationView?.alpha = if (isEnabled) 1f else (itemDisabledAnimationAlpha ?: 1f).coerceIn(0f, 1f)
    }

    private val optionPaint = android.graphics.Paint(android.graphics.Paint.ANTI_ALIAS_FLAG)

    /** [EN] The corner radius in px as the background draws it. [CN] 背景绘制所用的圆角半径（px）。 */
    private fun cornerRadiusPx(): Float {
        val explicit = itemCornerRadius
        val half = height / 2f
        return when {
            explicit != null -> if (explicit == CYLAnimatedItemCornerRadiusCapsule) half else min(max(explicit, 0f) * resources.displayMetrics.density, half)
            drawsLiquidGlass -> half
            else -> 0f
        }
    }

    private fun highlightApplies() = itemHighlightedBackgroundColor != null && isPressed && isEnabled && !isDividerMode

    private fun drawHighlight(canvas: android.graphics.Canvas) {
        val color = itemHighlightedBackgroundColor ?: return
        optionPaint.style = android.graphics.Paint.Style.FILL
        optionPaint.color = color
        val radius = cornerRadiusPx()
        canvas.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), radius, radius, optionPaint)
    }

    override fun onDraw(canvas: android.graphics.Canvas) {
        super.onDraw(canvas)
        // [EN] Under glass the highlight is drawn right after the glass layer (see `drawChild`). [CN] 有玻璃时按下背景紧跟在玻璃层之后绘制（见 `drawChild`）。
        if (highlightApplies() && itemBackgroundRenderer.glassView == null) drawHighlight(canvas)
    }

    override fun drawChild(canvas: android.graphics.Canvas, child: View, drawingTime: Long): Boolean {
        val drawn = super.drawChild(canvas, child, drawingTime)
        if (child === itemBackgroundRenderer.glassView && highlightApplies()) drawHighlight(canvas)
        return drawn
    }

    override fun setPressed(pressed: Boolean) {
        super.setPressed(pressed)
        if (itemHighlightedBackgroundColor != null) { refreshContrastColorsIfNeeded(); invalidate() }
    }

    private fun drawOutline(canvas: android.graphics.Canvas) {
        val stroke = max(1f, 2f * resources.displayMetrics.density)
        optionPaint.style = android.graphics.Paint.Style.STROKE
        optionPaint.strokeWidth = stroke
        optionPaint.color = titleView.currentTextColor
        val radius = max(0f, cornerRadiusPx() - stroke / 2f)
        canvas.drawRoundRect(stroke / 2f, stroke / 2f, width - stroke / 2f, height - stroke / 2f, radius, radius, optionPaint)
    }

    // MARK: Background (flat or Liquid Glass), corner radius and border

    /**
     * [EN] The background: `Flat` (default) fills the view with `itemBackgroundColor`; `LiquidGlass` draws Liquid Glass behind
     *      the content, tinted with `itemBackgroundColor`, clipped to `itemCornerRadius`. Where the device draws no Liquid Glass
     *      (`isLiquidGlassActive()`) the style is ignored and the view stays flat (`resolvedItemBackgroundStyle`). Setting any
     *      `item…` background property makes the view draw its background, corner radius and border (the countdown style keeps
     *      its own). Same names as iOS and HarmonyOS.
     * [CN] 背景：`Flat`（默认）用 `itemBackgroundColor` 填充；`LiquidGlass` 在内容后面绘制液态玻璃，以 `itemBackgroundColor` 着色并按
     *      `itemCornerRadius` 裁剪。设备不使用液态玻璃（`isLiquidGlassActive()`）时忽略该样式，保持扁平（`resolvedItemBackgroundStyle`）。
     *      设置任一 `item…` 背景属性后，视图绘制其背景、圆角与边框（倒计时样式保持自己的外观）。与 iOS、鸿蒙同名。
     */
    var itemBackgroundStyle: CYLAnimatedItemBackgroundStyle = CYLAnimatedItemBackgroundStyle.Flat
        set(value) { if (field != value) { field = value; itemBackgroundDidChange() } }

    /** [EN] The solid fill when flat, the glass tint when Liquid Glass (an ARGB color); null for none. A Liquid Glass color with alpha 0 (`Color.TRANSPARENT`) draws the default frosted tint, as null. [CN] 扁平时的纯色填充，液态玻璃时的着色（ARGB 颜色）；null 表示无。液态玻璃的颜色透明度为 0（`Color.TRANSPARENT`）时使用默认的磨砂着色，与 null 相同。 */
    var itemBackgroundColor: Int? = null
        set(value) { if (field != value) { field = value; itemBackgroundDidChange() } }

    /**
     * [EN] The corner radius in dp, applied as `min(radius, height / 2)`: 0 is square, [CYLAnimatedItemCornerRadiusCapsule] is the named constant of the capsule (exactly half the height, following the size); any other number is dp limited to half the height. null
     *      (the default) is not set: the Liquid Glass style is a capsule (half the height), so a host gets a capsule without setting
     *      anything and customizes it by setting this property; the flat style is square.
     * [CN] 圆角半径（dp），实际取 `min(radius, height / 2)`：0 为直角，[CYLAnimatedItemCornerRadiusCapsule] 是胶囊的命名常量（恰好半高，随尺寸变化），其他数字为 dp 且最大取半高。null（默认）表示未设置：液态玻璃样式为胶囊
     *      （半高），宿主无需设置任何属性即可得到胶囊，要自定义时设置此属性即可；扁平样式为直角。
     */
    var itemCornerRadius: Float? = null
        set(value) { if (field != value) { field = value; itemBackgroundDidChange() } }

    /**
     * [EN] The space between the outer border and the content on the left and right, in dp, on top of the view's padding. null (the default) is not
     *      set: Liquid Glass gets [CYLAnimatedItemLiquidGlassContentInset] (a capsule's round ends take room from the content), flat gets 0 (the
     *      view looks as before); any number is explicit, also 0 on glass. The one-to-one partner of `itemCornerRadius`: the same condition
     *      (`resolvedItemBackgroundStyle`) decides both.
     * [CN] 外侧边框与内容之间左右的间距（dp），叠加在视图 padding 之上。null（默认）表示未设置：液态玻璃取 [CYLAnimatedItemLiquidGlassContentInset]
     *      （胶囊圆端会占去内容空间），扁平为 0（与以往相同）；任何数字为显式值，玻璃上也可为 0。与 `itemCornerRadius` 一一对应：由同一条件
     *      （`resolvedItemBackgroundStyle`）决定两者。
     */
    var itemContentHorizontalInset: Float? = null
        set(value) { if (field != value) { field = value; requestLayout() } }

    /** [EN] The inset really applied, in dp: the explicit value, else the glass default or 0. [CN] 实际应用的间距（dp）：显式值，否则玻璃默认值或 0。 */
    val resolvedItemContentHorizontalInset: Float
        get() = CYLAnimatedItemBackgroundRenderer.resolvedContentInset(itemContentHorizontalInset, itemBackgroundStyle)

    private fun contentInsetPx(): Int = dp(resolvedItemContentHorizontalInset).roundToInt()

    /** [EN] The border width in dp. [CN] 边框宽度（dp）。 */
    var itemBorderWidth: Float = 0f
        set(value) { if (field != value) { field = value; itemBackgroundDidChange() } }

    /** [EN] The border color (an ARGB color); null for none. [CN] 边框颜色（ARGB 颜色）；null 表示无。 */
    var itemBorderColor: Int? = null
        set(value) { if (field != value) { field = value; itemBackgroundDidChange() } }

    /**
     * [EN] The share of the color's alpha that tints a Liquid Glass: null (the default) is 0.75, so an opaque color tints the glass instead of
     *      covering it; 1 uses the color as it is (a selected tag keeps its full color, still glass). Not used by the flat style.
     * [CN] 颜色透明度中用于给液态玻璃着色的比例：null（默认）为 0.75，不透明的颜色是给玻璃着色而不是盖住它；1 表示按原色（选中的标签保持完整颜色，仍是玻璃）。
     *      扁平样式不使用。
     */
    var itemGlassTintAlpha: Float? = null
        set(value) { if (field != value) { field = value; itemBackgroundDidChange() } }

    /**
     * [EN] The view a Liquid Glass background blurs and refracts: null (the default) is the root of the window's views. The source must be a view BEHIND this
     *      item and NOT an ancestor of it (a sibling plate, e.g. the gradient behind a list): a glass inside its own source cannot sample it and draws only
     *      its tint and rim. Applied to the glass layer, also when the layer is created later, and re-applied to the shown glass when set. Below API 31
     *      (no glass is drawn) the property is kept but has no effect and the item draws its flat color. Not used by the flat style.
     *      Besides the source, the glass samples, automatically, the Liquid Glass items BEHIND it that cover it (an earlier sibling of it or of one of its
     *      ancestors, e.g. the section card a tag sits on), drawn over the source: so a tag looks lighter than its card, as on HarmonyOS. Nothing to set.
     * [CN] 液态玻璃背景所模糊、折射的视图：null（默认）为窗口视图的根。源必须是位于该条目后面、且不是其祖先的视图（同级的背板，例如列表后面的渐变）：
     *      位于自己的源之内的玻璃不能采样它，只绘制着色与边缘。应用到玻璃层，层稍后创建时也会应用，设置时重新应用到正在显示的玻璃。API 31 以下
     *      （不绘制玻璃）属性被保留但不起作用，条目绘制其扁平颜色。扁平样式不使用。除源之外，玻璃还会自动采样位于它后面并覆盖它的液态玻璃条目
     *      （它自己或其某个祖先的前面的同级，例如标签所在的分区卡片），绘制在源之上：因此标签比所在的卡片更亮，与鸿蒙一致。无需设置。
     */
    var itemGlassBackdropSource: View? = null
        set(value) { if (field !== value) { field = value; if (usesItemBackground) itemBackgroundDidChange() } }

    /**
     * [EN] The background really drawn: `itemBackgroundStyle`, or `Flat` where `isLiquidGlassActive()` is false.
     * [CN] 实际绘制的背景：`itemBackgroundStyle`，`isLiquidGlassActive()` 为 false 时为 `Flat`。
     */
    val resolvedItemBackgroundStyle: CYLAnimatedItemBackgroundStyle
        get() = itemBackgroundRenderer.resolvedStyle(itemBackgroundStyle)

    /**
     * [EN] The Liquid Glass layer behind the content while it is drawn; null while the view is flat.
     * [CN] 绘制液态玻璃时位于内容后面的玻璃层；视图为扁平时为 null。
     */
    val itemLiquidGlassView: View? get() = itemBackgroundRenderer.glassView

    private val itemBackgroundRenderer = CYLAnimatedItemBackgroundRenderer(this)
    private var usesItemBackground = false

    private fun itemBackgroundDidChange() {
        usesItemBackground = true
        applyItemBackground()
        invalidate()
    }

    /** [EN] Applies the background, radius and border for the current size ([CYLAnimatedItemBackgroundRenderer]). [CN] 按当前尺寸应用背景、圆角与边框。 */
    private fun applyItemBackground() {
        if (!usesItemBackground) return
        itemBackgroundRenderer.apply(itemBackgroundStyle, itemBackgroundColor, itemCornerRadius, itemBorderWidth, itemBorderColor, itemGlassTintAlpha, itemGlassBackdropSource)
        // [EN] The background (glass or fill) decides the contrast adaptation. [CN] 背景（玻璃或填充）决定对比度调整。
        refreshContrastColorsIfNeeded()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        applyItemBackground()
    }

    companion object {
        /** [EN] The built-in fill of the countdown style (the original SMSCodeButton look). [CN] 倒计时样式的内置填充（最初 SMSCodeButton 的外观）。 */
        internal const val COUNTDOWN_FILL: Int = 0xFFF2F2F7.toInt()

        /**
         * [EN] Whether the device draws Liquid Glass, the one rule the tab bar uses too: Android 12 and later (Android 13+ the full
         *      glass with refraction, Android 12 the blur only); false on older versions. Same name as iOS and HarmonyOS.
         * [CN] 设备是否绘制液态玻璃，TabBar 也使用这唯一的规则：Android 12 及以上（Android 13+ 完整玻璃含折射，Android 12 只有模糊）；更早的版本为 false。与 iOS、鸿蒙同名。
         */
        @JvmStatic fun isLiquidGlassActive(): Boolean = CYLLiquidGlass.isActive()

        /**
         * [EN] The alpha of the default glass tint in light mode (225, 222, 220), used when the item's color is unset or clear. Same value as iOS `defaultGlassTintAlphaLight`.
         * [CN] 浅色模式下默认玻璃着色（225, 222, 220）的透明度，条目颜色未设置或透明时使用。与 iOS `defaultGlassTintAlphaLight` 同值。
         */
        const val defaultGlassTintAlphaLight: Float = 0.10f

        /**
         * [EN] The alpha of the default glass tint in dark mode (white), used when the item's color is unset or clear. Same value as iOS `defaultGlassTintAlphaDark`.
         * [CN] 深色模式下默认玻璃着色（白色）的透明度，条目颜色未设置或透明时使用。与 iOS `defaultGlassTintAlphaDark` 同值。
         */
        const val defaultGlassTintAlphaDark: Float = 0.04f

        /**
         * [EN] The default glass tint in light mode as an ARGB color: the frosted (225, 222, 220) at [defaultGlassTintAlphaLight] (0x1AE1DEDC).
         * [CN] 浅色模式默认玻璃着色（ARGB）：磨砂色 (225, 222, 220)，透明度 [defaultGlassTintAlphaLight]（0x1AE1DEDC）。
         */
        const val defaultGlassTintLight: Int = 0x1AE1DEDC

        /**
         * [EN] The default glass tint in dark mode as an ARGB color: white at [defaultGlassTintAlphaDark] (0x0AFFFFFF).
         * [CN] 深色模式默认玻璃着色（ARGB）：白色，透明度 [defaultGlassTintAlphaDark]（0x0AFFFFFF）。
         */
        const val defaultGlassTintDark: Int = 0x0AFFFFFF

        /**
         * [EN] The content inset in dp `style` resolves to for an `explicit` value (the one rule of `resolvedItemContentHorizontalInset`, usable while a view is still being built):
         *      the explicit value (never negative), else [CYLAnimatedItemLiquidGlassContentInset] where the glass is drawn, else 0.
         * [CN] 显式值 `explicit` 在样式 `style` 下解析出的内容间距（dp）（`resolvedItemContentHorizontalInset` 的同一规则，可在视图构建过程中使用）：显式值（不为负），否则玻璃绘制时为
         *      [CYLAnimatedItemLiquidGlassContentInset]，否则为 0。
         */
        @JvmStatic fun resolvedContentHorizontalInset(explicit: Float?, style: CYLAnimatedItemBackgroundStyle?): Float =
            CYLAnimatedItemBackgroundRenderer.resolvedContentInset(explicit, style)

        /**
         * [EN] Whether an animation engine library (Lottie, PAG, Rive or SVGA) is in the app; GIF is decoded by the system and not counted. A runtime check
         *      (`CYLAnimationEngines.isAvailable`). iOS `isAnimationEngineAvailable`.
         * [CN] App 中是否有动画引擎库（Lottie、PAG、Rive 或 SVGA）；GIF 由系统解码，不计入。运行时检查（`CYLAnimationEngines.isAvailable`）。对应 iOS `isAnimationEngineAvailable`。
         */
        @JvmStatic val isAnimationEngineAvailable: Boolean
            get() = listOf("Lottie", "PAG", "Rive", "SVGA").any { CYLAnimationEngines.isAvailable(it) }

        /**
         * [EN] For tests: replaces the system check of [isReduceMotionEnabled] (null, the default, asks the system). [CN] 供测试使用：替代 [isReduceMotionEnabled] 对系统的检查（默认 null）。
         */
        @JvmStatic var reduceMotionOverride: Boolean? = null

        /**
         * [EN] For tests: replaces the system check of [isIncreaseContrastEnabled] (null, the default, asks the system). [CN] 供测试使用：替代 [isIncreaseContrastEnabled] 对系统的检查（默认 null）。
         */
        @JvmStatic var increaseContrastOverride: Boolean? = null

        /**
         * [EN] Whether the system animations are off: `!ValueAnimator.areAnimatorsEnabled()` (public, API 26 and later; false below, where it cannot be read).
         *      The Android counterpart of iOS Reduce Motion.
         * [CN] 系统动画是否关闭：`!ValueAnimator.areAnimatorsEnabled()`（公开 API，API 26 及以上；更低版本读不到，为 false）。对应 iOS 的「减弱动态效果」。
         */
        @JvmStatic fun isReduceMotionEnabled(): Boolean =
            reduceMotionOverride ?: (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && !ValueAnimator.areAnimatorsEnabled())

        /**
         * [EN] Whether the system contrast setting is above standard: `UiModeManager.getContrast()` > 0 (medium 0.5, high 1.0), public API 34 and later.
         *      No effect below API 34 (false): the hidden high text contrast flag is deliberately not used. The Android counterpart of iOS Increase Contrast.
         * [CN] 系统对比度设置是否高于标准：`UiModeManager.getContrast()` > 0（中 0.5，高 1.0），公开 API，API 34 及以上。API 34 以下不起作用（为 false）：刻意不使用隐藏的高对比度文字标志。
         *      对应 iOS 的「增强对比度」。
         */
        @JvmStatic fun isIncreaseContrastEnabled(context: Context): Boolean {
            increaseContrastOverride?.let { return it }
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) return false
            return (context.getSystemService(Context.UI_MODE_SERVICE) as? UiModeManager)?.contrast?.let { it > 0f } ?: false
        }

        /**
         * [EN] For tests: replaces the device check of `isLiquidGlassActive()` (null, the default, asks the device).
         * [CN] 供测试使用：替代 `isLiquidGlassActive()` 对设备的检查（默认 null，询问设备）。
         */
        @JvmStatic var liquidGlassActiveOverride: Boolean?
            get() = CYLLiquidGlass.activeOverride
            set(value) { CYLLiquidGlass.activeOverride = value }

        /**
         * [EN] True: every playing animated item pauses while any observed scroll source (`LifecycleCenter`: a `RecyclerView` through
         *      `AndroidBinding.observeScrolling`, a view controller's scroll view) is dragged or decelerating, and resumes when scrolling
         *      ended. Default false. [CN] 为 true 时，任意被观察的滚动源（`LifecycleCenter`）被拖动或减速时，所有正在播放的动效 item 暂停，滚动结束后恢复。默认 false。
         */
        @JvmStatic var pausesAnimationsWhileUserScrolls: Boolean
            get() = PlayingViews.pausesWhileScrolling
            set(value) = PlayingViews.setPausesWhileScrolling(value)

        /**
         * [EN] Pauses every animated item that plays now (they post `cyl.animation.didPause`). For hosts that decide themselves,
         *      such as the React Native and Flutter wrappers. [CN] 暂停当前所有正在播放的动效 item（发出 `cyl.animation.didPause`）。供自行决定的宿主使用，如 React Native 与 Flutter 包装层。
         */
        @JvmStatic fun pauseAllAnimations() = PlayingViews.pauseAll()

        /** [EN] Resumes what [pauseAllAnimations] paused (`cyl.animation.didResume`). [CN] 恢复 [pauseAllAnimations] 暂停的动画。 */
        @JvmStatic fun resumeAllAnimations() = PlayingViews.resumeAll()

        private const val ANDROID_ASSET_PREFIX = "file:///android_asset/"
        private const val END_WATCH_INTERVAL_MS = 16L
        private const val END_PROGRESS = 0.999f

        /**
         * [EN] The library's placeholder, `R.drawable.cyl_animated_item_placeholder` (24 dp, a tab icon's size; the same
         *      drawing as iOS's `CYLAnimatedItem.bundle`). Copyright and policy: `META-INF/cylanimateditem/`.
         * [CN] 本库的占位图 `R.drawable.cyl_animated_item_placeholder`（24 dp，Tab 图标尺寸；与 iOS 的 `CYLAnimatedItem.bundle` 图形相同）。版权与政策：
         *      `META-INF/cylanimateditem/`。
         */
        @JvmStatic
        fun defaultPlaceholderImage(context: Context): Drawable? =
            com.cyl.animateditem.CYLAnimatedItemResources.id(context, "cyl_animated_item_placeholder", "drawable").takeIf { it != 0 }?.let { androidx.core.content.ContextCompat.getDrawable(context, it) }
    }
}
