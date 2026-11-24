package com.cyl.animateditem

import android.content.Context
import com.chenyilong.cyldeallocblockexecutor.AnimationEvents
import com.chenyilong.cyldeallocblockexecutor.LifecycleCenter
import com.chenyilong.cyldeallocblockexecutor.LifecycleRegistry
import android.graphics.Color
import android.graphics.PorterDuff
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
 * [EN] What the view's background is made of: the solid `itemBackgroundColor` (`Flat`, default), or Liquid Glass tinted with it
 *      (`LiquidGlass`; drawn only where the device draws Liquid Glass, `CYLAnimatedItemView.isLiquidGlassActive()`: Android 12
 *      and later, as the tab bar; elsewhere the style is ignored and the view stays flat). Same names as iOS and HarmonyOS.
 * [CN] 视图背景的构成：纯色 `itemBackgroundColor`（`Flat`，默认），或以它着色的液态玻璃（`LiquidGlass`；只在设备绘制液态玻璃处绘制，
 *      `CYLAnimatedItemView.isLiquidGlassActive()`：与 TabBar 一样为 Android 12 及以上；其他设备忽略该样式，保持扁平）。与 iOS、鸿蒙同名。
 */
enum class CYLAnimatedItemBackgroundStyle { Flat, LiquidGlass }

open class CYLAnimatedItemView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : FrameLayout(context, attrs), CYLAnimatedItemContent, CYLAnimatedItemAnimating, CYLTabBarItemAnimationFailureHandling {

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
        set(value) { titleView.text = value; updateAccessibility(); requestLayout() }

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
        set(value) { field = value.coerceIn(0f, 1f); if (!playing) animationPlayer?.progress = field }

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
        val widthLimit = if (MeasureSpec.getMode(widthMeasureSpec) == MeasureSpec.UNSPECIFIED) Int.MAX_VALUE / 2 else MeasureSpec.getSize(widthMeasureSpec)
        val (iconW, _) = if (showsIcon()) iconSize() else 0 to 0
        val reserved = paddingLeft + paddingRight + (if (accessoryInline()) dp(accessorySizeDp + spacingDp).roundToInt() else 0) +
            (if (axis == CYLAnimatedItemAxis.Horizontal && showsIcon()) iconW + dp(spacingDp).roundToInt() else 0)
        val (contentW, contentH) = measureContent(max(0, widthLimit - reserved))
        val width = resolveSize(contentW + paddingLeft + paddingRight, widthMeasureSpec)
        val height = resolveSize(contentH + paddingTop + paddingBottom, heightMeasureSpec)
        setMeasuredDimension(width, height)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        glassLayer?.let { if (it.parent != null) it.layout(0, 0, r - l, b - t) }
        layoutContent(paddingLeft, paddingTop, r - l - paddingRight, b - t - paddingBottom)
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
        return if (accessoryPlacement == CYLAnimatedItemAccessoryPlacement.Leading) left + inset to right else left to right - inset
    }

    /**
     * [EN] Horizontal axis: the icon then the title, centred (or leading) in `box`; returns the icon's origin.
     * [CN] 水平方向：图标在前、标题在后，在 `box` 中居中（或靠前）；返回图标的原点。
     */
    private fun layoutRow(box: android.graphics.Rect, iconW: Int, iconH: Int, titleW: Int, titleH: Int, spacing: Int): Pair<Int, Int> {
        val group = iconW + spacing + titleW
        val start = if (alignment == CYLAnimatedItemAlignment.Leading) box.left else box.left + (box.width() - group) / 2
        val titleTop = box.top + (box.height() - titleH) / 2
        titleView.layout(start + iconW + spacing, titleTop, start + iconW + spacing + titleW, titleTop + titleH)
        return start to box.top + (box.height() - iconH) / 2
    }

    /**
     * [EN] Vertical axis: the icon above the title, centred (or leading) in `box`; returns the icon's origin.
     * [CN] 垂直方向：图标在上、标题在下，在 `box` 中居中（或靠前）；返回图标的原点。
     */
    private fun layoutColumn(box: android.graphics.Rect, iconW: Int, iconH: Int, titleW: Int, titleH: Int, spacing: Int): Pair<Int, Int> {
        val startY = box.top + (box.height() - (iconH + spacing + titleH)) / 2
        val leading = alignment == CYLAnimatedItemAlignment.Leading
        val titleLeft = if (leading) box.left else box.left + (box.width() - titleW) / 2
        titleView.layout(titleLeft, startY + iconH + spacing, titleLeft + titleW, startY + iconH + spacing + titleH)
        return (if (leading) box.left else box.left + (box.width() - iconW) / 2) to startY
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
    }

    /**
     * [EN] Places the accessory: at the leading or trailing edge of the box, or on the icon's top trailing corner.
     * [CN] 放置附加图标：区域的前缘或后缘，或图标的右上角。
     */
    protected fun placeAccessory(left: Int, top: Int, right: Int, bottom: Int, iconLeft: Int, iconTop: Int, iconWidth: Int) {
        val accessory = accessoryView ?: return
        val size = dp(accessorySizeDp).roundToInt()
        accessory.measure(MeasureSpec.makeMeasureSpec(size, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(size, MeasureSpec.EXACTLY))
        val (x, y) = when (accessoryPlacement) {
            CYLAnimatedItemAccessoryPlacement.Leading -> left to top + (bottom - top - size) / 2
            CYLAnimatedItemAccessoryPlacement.Trailing -> right - size to top + (bottom - top - size) / 2
            CYLAnimatedItemAccessoryPlacement.TopTrailing -> min(right - size, iconLeft + iconWidth - size / 2) to max(0, iconTop - size / 2)
        }
        accessory.layout(x, y, x + size, y + size)
    }

    // MARK: - State 状态

    override fun setSelected(selected: Boolean) {
        val changed = selected != isSelected
        super.setSelected(selected)
        if (changed) { updateIcon(); applyIconColor(); onItemStateChanged(); updateAccessibility() }
        if (changed && drivesAnimationPlayback && animationView != null) { if (selected) restartAnimation() else stopAnimation() }
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

    /**
     * [EN] The icon color in effect now, or null. [CN] 当前生效的图标颜色，没有时为 null。
     */
    val effectiveIconColor: Int?
        get() {
            if (isSelected) (selectedIconColor ?: stackSelectedIconColor)?.let { return it }
            return iconColor ?: stackIconColor
        }

    private fun applyIconColor() {
        val color = effectiveIconColor
        if (color != null) {
            iconView.setColorFilter(color, PorterDuff.Mode.SRC_IN)
            appliesIconColor = true
        } else if (appliesIconColor) {
            // [EN] Only a filter this view set is cleared (a tab button sets its own). [CN] 只清除本视图设置的滤镜（Tab 按钮会设置自己的）。
            iconView.clearColorFilter()
            appliesIconColor = false
        }
    }

    override fun setEnabled(enabled: Boolean) {
        super.setEnabled(enabled)
        alpha = if (enabled) 1f else disabledAlpha
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
        val shown = countdownImage.takeIf { running } ?: selectedImage.takeIf { isSelected } ?: image
        iconView.setImageDrawable(shown ?: placeholderIfNeeded())
        iconView.visibility = if (animationShows()) View.INVISIBLE else View.VISIBLE
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
        if (!url.isNullOrBlank() && !localFileIsMissing(url)) {
            val (w, h) = iconSizeDp?.let { it.width to it.height } ?: (24f to 24f)
            // [EN] No engine, no library or a file it cannot read: no view, the static image stays (an app's own source that
            //      throws is treated the same way). [CN] 没有引擎、没有动画库或文件无法读取：不创建视图，保留静态图片（App 自己的来源抛出异常时同样处理）。
            val made = try { animationSource.animationViewWithURL(context, url, CYLSize(w, h), ImageView.ScaleType.FIT_CENTER) } catch (error: RuntimeException) { null }
            made?.let { view ->
                view.cyl_hideFromAccessibility()
                addView(view, indexOfChild(iconView) + 1)
                animationView = view
                animationPlayer?.let { player ->
                    player.loops = animationLoops
                    if (animationSpeed > 0f) player.animationSpeed = animationSpeed
                    player.progress = animationRestingProgress
                }
                if (drivesAnimationPlayback && isSelected) playAnimation()
            } ?: CYLAnimationEngines.warnMissingEngine(context, null, url)
        }
        updateIcon()
        requestLayout()
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

    override fun playAnimation() {
        val player = animationPlayer ?: return
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
        updateIcon()
        requestLayout()
        if (drivesAnimationPlayback && isSelected) playAnimation()
        onAnimationLoaded?.invoke()
    }

    override fun cyl_animationViewDidFail(animationView: View) {
        if (animationView !== this.animationView) return
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
        if (!isEnabled) return false
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
            setColor(0xFFF2F2F7.toInt())
            setStroke(max(1, dp(0.5f).roundToInt()), if (running) Color.LTGRAY else countdownBorderColor)
        }
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

    // MARK: - Accessibility 无障碍

    /**
     * [EN] What a screen reader says for the item: the title by default. Subclasses add a badge, a count or a state.
     * [CN] 读屏朗读的条目文本：默认为标题。子类可以加入角标、数量或状态。
     */
    protected open fun accessibilityText(): CharSequence = CYLAnimatedItemAccessibilityText(title, null)

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
        set(value) { field = value; itemBackgroundDidChange() }

    /** [EN] The solid fill when flat, the glass tint when Liquid Glass (an ARGB color); null for none. [CN] 扁平时的纯色填充，液态玻璃时的着色（ARGB 颜色）；null 表示无。 */
    var itemBackgroundColor: Int? = null
        set(value) { field = value; itemBackgroundDidChange() }

    /**
     * [EN] The corner radius in dp, applied as `min(radius, height / 2)`: 0 is square, a large value such as 1000 is a capsule.
     * [CN] 圆角半径（dp），实际取 `min(radius, height / 2)`：0 为直角，较大的值（如 1000）为胶囊。
     */
    var itemCornerRadius: Float = 0f
        set(value) { field = value; itemBackgroundDidChange() }

    /** [EN] The border width in dp. [CN] 边框宽度（dp）。 */
    var itemBorderWidth: Float = 0f
        set(value) { field = value; itemBackgroundDidChange() }

    /** [EN] The border color (an ARGB color); null for none. [CN] 边框颜色（ARGB 颜色）；null 表示无。 */
    var itemBorderColor: Int? = null
        set(value) { field = value; itemBackgroundDidChange() }

    /**
     * [EN] The background really drawn: `itemBackgroundStyle`, or `Flat` where `isLiquidGlassActive()` is false.
     * [CN] 实际绘制的背景：`itemBackgroundStyle`，`isLiquidGlassActive()` 为 false 时为 `Flat`。
     */
    val resolvedItemBackgroundStyle: CYLAnimatedItemBackgroundStyle
        get() = if (itemBackgroundStyle == CYLAnimatedItemBackgroundStyle.LiquidGlass && isLiquidGlassActive()) {
            CYLAnimatedItemBackgroundStyle.LiquidGlass
        } else {
            CYLAnimatedItemBackgroundStyle.Flat
        }

    /**
     * [EN] The Liquid Glass layer behind the content while it is drawn; null while the view is flat.
     * [CN] 绘制液态玻璃时位于内容后面的玻璃层；视图为扁平时为 null。
     */
    val itemLiquidGlassView: View? get() = glassLayer?.takeIf { it.parent != null }

    private val itemBox = GradientDrawable()
    private var usesItemBackground = false
    private var glassLayer: CYLLiquidGlassView? = null

    private fun itemBackgroundDidChange() {
        usesItemBackground = true
        applyItemBackground()
        invalidate()
    }

    /** [EN] Applies the background, radius and border for the current size. [CN] 按当前尺寸应用背景、圆角与边框。 */
    private fun applyItemBackground() {
        if (!usesItemBackground) return
        val density = resources.displayMetrics.density
        val radius = min(max(itemCornerRadius, 0f) * density, height / 2f)
        itemBox.cornerRadius = radius
        itemBox.setStroke((itemBorderWidth * density).roundToInt(), itemBorderColor ?: Color.TRANSPARENT)
        var glassDrawn = false
        if (resolvedItemBackgroundStyle == CYLAnimatedItemBackgroundStyle.LiquidGlass) {
            val glass = glassLayer ?: CYLLiquidGlassView(context).also { glassLayer = it }
            glass.glassTintColor = itemBackgroundColor
            glass.cornerRadius = radius
            if (glass.parent == null) addView(glass, 0)
            glass.visibility = VISIBLE
            glass.layout(0, 0, width, height)
            glass.applyEffect()
            glassDrawn = glass.isGlassDrawn
        }
        if (!glassDrawn) glassLayer?.let { if (it.parent != null) removeView(it) }
        itemBox.setColor(if (glassDrawn) Color.TRANSPARENT else (itemBackgroundColor ?: Color.TRANSPARENT))
        if (background !== itemBox) background = itemBox
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        applyItemBackground()
    }

    companion object {
        /**
         * [EN] Whether the device draws Liquid Glass, the one rule the tab bar uses too: Android 12 and later (Android 13+ the full
         *      glass with refraction, Android 12 the blur only); false on older versions. Same name as iOS and HarmonyOS.
         * [CN] 设备是否绘制液态玻璃，TabBar 也使用这唯一的规则：Android 12 及以上（Android 13+ 完整玻璃含折射，Android 12 只有模糊）；更早的版本为 false。与 iOS、鸿蒙同名。
         */
        @JvmStatic fun isLiquidGlassActive(): Boolean = CYLLiquidGlass.isActive()

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
