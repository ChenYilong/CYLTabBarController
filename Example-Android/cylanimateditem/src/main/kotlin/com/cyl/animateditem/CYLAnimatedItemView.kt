package com.cyl.animateditem

import android.content.Context
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
     * [EN] The view playing `animationURL`, while ready. [CN] 正在播放 `animationURL` 的视图（就绪时）。
     */
    var animationView: View? = null
        private set

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

    private var playing = false

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
        layoutContent(paddingLeft, paddingTop, r - l - paddingRight, b - t - paddingBottom)
    }

    /**
     * [EN] Places the icon, the animation view, the title and the accessory inside the given box (the view's bounds
     *      minus its padding). Override for another arrangement; call `placeAccessory` for the accessory.
     * [CN] 在给定区域（视图边界减去 padding）中放置图标、动画视图、标题与附加图标。需要其他排列时重写；附加图标调用 `placeAccessory`。
     */
    protected open fun layoutContent(left: Int, top: Int, right: Int, bottom: Int) {
        val accessorySize = dp(accessorySizeDp).roundToInt()
        val accessorySpacing = if (accessoryInline() && (showsIcon() || showsTitle())) dp(spacingDp).roundToInt() else 0
        var contentLeft = left
        var contentRight = right
        if (accessoryInline()) {
            if (accessoryPlacement == CYLAnimatedItemAccessoryPlacement.Leading) contentLeft += accessorySize + accessorySpacing
            else contentRight -= accessorySize + accessorySpacing
        }
        val (iconW, iconH) = if (showsIcon()) iconSize() else 0 to 0
        val spacing = if (showsIcon() && showsTitle()) dp(spacingDp).roundToInt() else 0
        val boxW = max(0, contentRight - contentLeft)
        val boxH = max(0, bottom - top)
        val maxTitleW = if (axis == CYLAnimatedItemAxis.Horizontal) max(0, boxW - iconW - spacing) else boxW
        titleView.measure(MeasureSpec.makeMeasureSpec(maxTitleW, MeasureSpec.AT_MOST), MeasureSpec.makeMeasureSpec(boxH, MeasureSpec.AT_MOST))
        val titleW = if (showsTitle()) titleView.measuredWidth else 0
        val titleH = if (showsTitle()) titleView.measuredHeight else 0
        val iconLeft: Int
        val iconTop: Int
        if (axis == CYLAnimatedItemAxis.Horizontal) {
            val group = iconW + spacing + titleW
            val start = if (alignment == CYLAnimatedItemAlignment.Leading) contentLeft else contentLeft + (boxW - group) / 2
            iconLeft = start
            iconTop = top + (boxH - iconH) / 2
            titleView.layout(start + iconW + spacing, top + (boxH - titleH) / 2, start + iconW + spacing + titleW, top + (boxH - titleH) / 2 + titleH)
        } else {
            val group = iconH + spacing + titleH
            val startY = top + (boxH - group) / 2
            iconLeft = if (alignment == CYLAnimatedItemAlignment.Leading) contentLeft else contentLeft + (boxW - iconW) / 2
            iconTop = startY
            val titleLeft = if (alignment == CYLAnimatedItemAlignment.Leading) contentLeft else contentLeft + (boxW - titleW) / 2
            titleView.layout(titleLeft, startY + iconH + spacing, titleLeft + titleW, startY + iconH + spacing + titleH)
        }
        placeIcon(iconLeft, iconTop, iconW, iconH)
        placeAccessory(left, top, right, bottom, iconLeft, iconTop, iconW)
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
        if (changed) { updateIcon(); onItemStateChanged(); updateAccessibility() }
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
    private fun animationShows() = animationView != null && !com.cyl.animateditem.CYLTabBarItemAnimationFailure.isLoading(animationView)

    /**
     * [EN] Shows the static image, else the placeholder, until the animation shows. A subclass that lays out its own
     *      icon (the tab bar's button) overrides it.
     * [CN] 在动画显示之前显示静态图片，没有时显示占位图。自行布局图标的子类（TabBar 的按钮）可以重写。
     */
    protected open fun updateIcon() {
        // [EN] The static image given, else the placeholder, until the animation shows (also while it downloads).
        // [CN] 在动画显示之前（包括下载期间）显示传入的静态图片，没有时显示占位图。
        iconView.setImageDrawable((if (isSelected && selectedImage != null) selectedImage else image) ?: placeholderIfNeeded())
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
            file.startsWith("/") -> missing(file)
            else -> false
        }
    }

    override fun playAnimation() {
        val player = animationPlayer ?: return
        playing = true
        player.loops = animationLoops
        if (animationSpeed > 0f) player.animationSpeed = animationSpeed
        player.play()
    }

    override fun restartAnimation() {
        animationPlayer?.progress = 0f
        playAnimation()
    }

    override fun stopAnimation() {
        val player = animationPlayer ?: return
        playing = false
        player.stop()
        player.progress = animationRestingProgress
    }

    override fun showAnimationLastFrame() {
        playing = false
        animationPlayer?.showLastFrame()
    }

    /**
     * [EN] The engine could not load the file: drop the animation and show the static icon. [CN] 引擎无法加载文件：移除动画并显示静态图标。
     */
    override fun cyl_animationViewDidLoad(animationView: View) {
        if (animationView === this.animationView) { updateIcon(); requestLayout() }
    }

    override fun cyl_animationViewDidFail(animationView: View) {
        if (animationView !== this.animationView) return
        removeView(animationView)
        this.animationView = null
        playing = false
        updateIcon()
        requestLayout()
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
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> { downX = event.rawX; downY = event.rawY; dragging = false; longPressed = false; isPressed = true }
            MotionEvent.ACTION_MOVE -> if (isDragEnabled) {
                val dx = event.rawX - downX
                val dy = event.rawY - downY
                if (!dragging && exceedsSlop(event) && !longPressed && gestureListener?.shouldBeginDrag(this) != false) {
                    dragging = true
                    isPressed = false
                    parent?.requestDisallowInterceptTouchEvent(true)
                    gestureListener?.onDragBegan(this)
                }
                if (dragging) {
                    if (dragMovesView) { translationX = dx; translationY = dy }
                    gestureListener?.onDragChanged(this, dx, dy)
                    return true
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
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
            }
        }
        detector.onTouchEvent(event)
        return true
    }

    /**
     * [EN] A subclass's own gestures: return true to consume the event before the built-in tap, long press and drag.
     * [CN] 子类自己的手势：返回 true 表示在内置的点击、长按与拖拽之前消费该事件。
     */
    protected open fun onItemTouchEvent(event: MotionEvent): Boolean = false

    override fun performClick(): Boolean {
        val handled = super.performClick()
        gestureListener?.onItemTapped(this)
        return handled
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
        info.className = Button::class.java.name
        info.isSelected = isSelected
    }

    /**
     * [EN] The measured width of a title in this view's title style, for callers that size items before creating them.
     * [CN] 以本视图标题样式测得的标题宽度，供在创建条目前计算尺寸的调用方使用。
     */
    fun titleWidth(text: CharSequence?): Int = if (text.isNullOrEmpty()) 0 else ceil(titleView.paint.measureText(text.toString())).toInt()

    companion object {
        private const val ANDROID_ASSET_PREFIX = "file:///android_asset/"

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
