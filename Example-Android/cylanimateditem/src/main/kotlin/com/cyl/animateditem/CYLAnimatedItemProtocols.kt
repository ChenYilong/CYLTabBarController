@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.animateditem

import android.graphics.drawable.Drawable
import android.view.View

/**
 * [EN] How the icon and the title are arranged: side by side (a tag, a chip) or the icon above the title (a tab, a
 *      placeholder, an empty state).
 * [CN] 图标与标题的排列：左右并排（标签、chip）或图标在标题上方（Tab、占位图、空状态）。
 */
enum class CYLAnimatedItemAxis { Horizontal, Vertical }

/**
 * [EN] Where the content group sits inside the view: centered (default) or against the leading edge.
 * [CN] 内容组在视图中的位置：居中（默认）或靠前缘。
 */
enum class CYLAnimatedItemAlignment { Center, Leading }

/**
 * [EN] Where the accessory icon goes: before the content, after it, or on the top trailing corner (over the icon, like
 *      a badge or a close button).
 * [CN] 附加图标的位置：内容之前、内容之后，或右上角（盖在图标上，像角标或关闭按钮）。
 */
enum class CYLAnimatedItemAccessoryPlacement { Leading, Trailing, TopTrailing }

/**
 * [EN] What the item shows. Every property can be set on `CYLAnimatedItemView`; a subclass may compute them instead.
 * [CN] 条目显示的内容。所有属性都可以在 `CYLAnimatedItemView` 上设置；子类也可以自行计算。
 */
interface CYLAnimatedItemContent {
    /**
     * [EN] The title, or null for an icon-only item. [CN] 标题；只有图标时为 null。
     */
    var title: CharSequence?

    /**
     * [EN] The static icon, shown until an animation is ready and whenever there is none. [CN] 静态图标：动画就绪前以及没有动画时显示。
     */
    var image: Drawable?

    /**
     * [EN] The icon while selected; null uses `image`. [CN] 选中时的图标；为 null 时使用 `image`。
     */
    var selectedImage: Drawable?
}

/**
 * [EN] The animated icon. Any file the animation engine knows plays (Lottie, PAG, Rive, GIF, SVGA, and every animator
 *      registered later): a new animation type is a new animator in `CYLTabBarItemAnimatorRegistry`, nothing else.
 *      The Play all / speed / loop controls of the examples map to `restartAnimation()`, `animationSpeed` and
 *      `animationLoops`.
 * [CN] 动效图标。动画引擎支持的文件都能播放（Lottie、PAG、Rive、GIF、SVGA，以及以后注册的 animator）：新增动画类型只需在
 *      `CYLTabBarItemAnimatorRegistry` 中新增一个 animator，其他地方都不用改。示例中的「全部播放」/ 倍速 / 循环分别对应
 *      `restartAnimation()`、`animationSpeed` 与 `animationLoops`。
 */
interface CYLAnimatedItemAnimating {
    /**
     * [EN] The animation file (path, asset or URL with options); null removes the animation. [CN] 动画文件（路径、asset 或带选项的 URL）；null 移除动画。
     */
    var animationURL: String?

    /**
     * [EN] Speed, 1 by default; 0 or less keeps the file's own speed. [CN] 速度，默认 1；0 或负数使用文件自身的速度。
     */
    var animationSpeed: Float

    /**
     * [EN] Whether the animation loops. [CN] 动画是否循环播放。
     */
    var animationLoops: Boolean

    /**
     * [EN] The progress shown while not playing (0 the first frame, 1 the last). [CN] 未播放时显示的进度（0 为首帧，1 为末帧）。
     */
    var animationRestingProgress: Float

    /**
     * [EN] Whether the animation view is in place. [CN] 动画视图是否已就绪。
     */
    val isAnimationReady: Boolean

    /**
     * [EN] Plays from the current progress. [CN] 从当前进度开始播放。
     */
    fun playAnimation()

    /**
     * [EN] Plays from progress 0 (the examples' "Play all"). [CN] 从进度 0 开始播放（示例中的「全部播放」）。
     */
    fun restartAnimation()

    /**
     * [EN] Stops and shows the resting progress. [CN] 停止并显示静止进度。
     */
    fun stopAnimation()

    /**
     * [EN] Shows the last frame without playing. [CN] 不播放，直接显示最后一帧。
     */
    fun showAnimationLastFrame()
}

/**
 * [EN] The listener of an item's gestures. Every method has a default, so implement only what you need.
 * [CN] 条目手势的监听者。每个方法都有默认实现，只需实现需要的方法。
 */
interface CYLAnimatedItemGestureListener {
    /**
     * [EN] The item was tapped (not on its accessory). [CN] 点击了条目（不是附加图标）。
     */
    fun onItemTapped(item: CYLAnimatedItemView) { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] The item was long-pressed; return true when handled (no tap follows). [CN] 长按了条目；处理后返回 true（之后不再触发点击）。
     */
    fun onItemLongPressed(item: CYLAnimatedItemView): Boolean = false

    /**
     * [EN] The accessory icon was tapped. [CN] 点击了附加图标。
     */
    fun onAccessoryTapped(item: CYLAnimatedItemView) { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] The countdown started. [CN] 倒计时开始。
     */
    fun onCountdownStarted(item: CYLAnimatedItemView) { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] The whole seconds left changed, once per second. [CN] 剩余整秒数变化，每秒一次。
     */
    fun onCountdownTicked(item: CYLAnimatedItemView, remainingSeconds: Int) { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] The time is up. [CN] 时间到。
     */
    fun onCountdownFinished(item: CYLAnimatedItemView) { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] Whether a drag may start (only asked when `isDragEnabled`). [CN] 是否允许开始拖拽（仅在 `isDragEnabled` 时询问）。
     */
    fun shouldBeginDrag(item: CYLAnimatedItemView): Boolean = true

    /**
     * [EN] A drag started. [CN] 拖拽开始。
     */
    fun onDragBegan(item: CYLAnimatedItemView) { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] The finger moved by (dx, dy) px from where the drag started. [CN] 手指相对拖拽起点移动了 (dx, dy) 像素。
     */
    fun onDragChanged(item: CYLAnimatedItemView, dx: Float, dy: Float) { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] The drag ended (or was cancelled) at (dx, dy) px. [CN] 拖拽在 (dx, dy) 像素处结束（或取消）。
     */
    fun onDragEnded(item: CYLAnimatedItemView, dx: Float, dy: Float, cancelled: Boolean) { /* [EN] Optional. [CN] 可选。 */ }
}

/**
 * [EN] Where items get their animation views: the shared animation engine by default. A library that keeps its own
 *      registry (or a test) sets `CYLAnimatedItemView.animationSource`; it is the engine's own
 *      `CYLTabBarItemAnimationViewMaking`, so any factory fits.
 * [CN] 条目获取动画视图的来源：默认是共用的动画引擎。有自己注册表的库（或测试）设置 `CYLAnimatedItemView.animationSource`；它就是引擎的
 *      `CYLTabBarItemAnimationViewMaking`，任何工厂都适用。
 */
object CYLAnimatedItemAnimationSource {
    /**
     * [EN] The shared engine. [CN] 共用的动画引擎。
     */
    @JvmStatic
    val shared: CYLTabBarItemAnimationViewMaking get() = CYLTabBarItemAnimationFactory.sharedFactory
}

/**
 * [EN] The accessibility text of an item: its title, then the accessory's description when it has one, joined by ", ".
 * [CN] 条目的无障碍文本：标题，以及附加图标的描述（如有），以 "，" 连接。
 */
fun CYLAnimatedItemAccessibilityText(title: CharSequence?, extra: CharSequence?): String =
    listOfNotNull(title?.toString()?.takeIf { it.isNotBlank() }, extra?.toString()?.takeIf { it.isNotBlank() }).joinToString(", ")

/**
 * [EN] Hides a decorative view from accessibility services. [CN] 让装饰性视图不被无障碍服务读取。
 */
internal fun View.cyl_hideFromAccessibility() {
    importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
}

/**
 * [EN] Told when a play-once animation of a `CYLAnimatedItemView` ends (`CYLAnimatedItemView.animationEndListener`).
 * [CN] `CYLAnimatedItemView` 只播放一次的动画结束时收到通知（`CYLAnimatedItemView.animationEndListener`）。
 */
fun interface CYLAnimatedItemAnimationEndListener {
    /**
     * [EN] The animation of `item` reached its end. [CN] `item` 的动画播放到结尾。
     */
    fun onAnimationEnd(item: CYLAnimatedItemView)
}
