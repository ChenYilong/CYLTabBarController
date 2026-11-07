// [EN] The method names are the iOS names on purpose (`cyl_…`, `tabBarController_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`、`tabBarController_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.content.Context
import android.graphics.Canvas
import android.graphics.Rect
import android.graphics.Color
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.Typeface
import android.view.GestureDetector
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.annotation.ColorInt
import kotlin.math.abs

/**
 * [EN] One tab's button (`UITabBarButton` / `CYLFlatDesignTabBarItem`): an icon above a title, with the per-tab
 *      colors and fonts, the badge host, and the gestures (tap, double tap, long press, swipe) reported to the tab bar.
 * [CN] 一个 Tab 的按钮（`UITabBarButton` / `CYLFlatDesignTabBarItem`）：图标在上、标题在下，带每个 Tab 的颜色与字体、角标宿主，以及上报给
 *      TabBar 的手势（点击、双击、长按、滑动）。
 */
@android.annotation.SuppressLint("ViewConstructor") // [EN] Made by the tab bar for an item, never inflated. [CN] 由 TabBar 为 item 创建，不从 XML 加载。
class CYLTabBarItemButton(context: Context, val item: CYLTabBarItem, val index: Int) : FrameLayout(context) {

    val iconView = ImageView(context).apply { scaleType = ImageView.ScaleType.CENTER_INSIDE }
    /** [EN] The view of `setTabBarItemIconViewProvider`, laid out in place of the icon. [CN] `setTabBarItemIconViewProvider` 提供的视图，代替图标布局。 */
    internal var cyl_customIconView: View? = null
    internal var cyl_iconViewProvider: CYLTabBarItemIconViewProvider? = null

    /** [EN] Asks the icon view provider for the view of the current selection. [CN] 向图标视图 provider 请求当前选中状态的视图。 */
    internal fun cyl_applyIconViewProvider() {
        cyl_customIconView?.let { removeView(it) }
        cyl_customIconView = cyl_iconViewProvider?.invoke(isSelected)?.also { custom -> (custom.parent as? ViewGroup)?.removeView(custom); addView(custom) }
        iconView.visibility = if (cyl_customIconView == null && !cyl_isTabBarItemAnimationReady()) View.VISIBLE else View.INVISIBLE
        requestLayout()
    }
    val titleLabel = TextView(context).apply { gravity = Gravity.CENTER; maxLines = 1; textSize = 10f }
    internal var onTap: (() -> Unit)? = null
    internal var onDoubleTap: (() -> Unit)? = null
    internal var onLongPress: (() -> Unit)? = null
    internal var onSwipe: ((Boolean) -> Unit)? = null
    internal var doubleTapInterval = 0.3
    internal var longPressDuration = 0.5
    private var downTime = 0L
    private var lastTapTime = 0L
    private var downX = 0f
    private var longPressed = false
    private val longPressRunnable = Runnable {
        longPressed = true
        onLongPress?.invoke()
    }

    init {
        addView(iconView, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT, Gravity.CENTER_HORIZONTAL))
        addView(titleLabel, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT, Gravity.BOTTOM))
        isClickable = true
        isFocusable = true
        contentDescription = item.accessibilityLabel ?: item.title
        item.cyl_visiableTabButton = this
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        val density = resources.displayMetrics.density
        val tabBar = parent as? CYLTabBar
        val hasTitle = titleLabel.text.isNotEmpty()
        titleLabel.measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.UNSPECIFIED)
        // [EN] `automaticallyAdjustsImageOnlyTabs` (default true): a tab without a title centers its icon; false keeps the title's room. [CN] 没有标题的 Tab 默认图标居中；false 时保留标题的空间。
        val keepsTitleRoom = tabBar?.tabBarController?.automaticallyAdjustsImageOnlyTabs == false
        val titleHeight = if (hasTitle || keepsTitleRoom) titleLabel.measuredHeight else 0
        val insets = item.cyl_imageInsets
        val controller = tabBar?.tabBarController
        val controllerInsets = controller?.imageInsets
        val placeholderHeight = if (controllerInsets != null) CYLConstants.CYLTabBarItemImagePlaceholderWidth - controllerInsets.top - controllerInsets.bottom else CYLConstants.CYLTabBarItemImagePlaceholderWidth
        var iconSize = ((item.cyl_iconSize?.height ?: placeholderHeight) * density).toInt()
        if (controller?.adjustTabBarItemImageViewSizeDependOnSuperView != false) iconSize = iconSize.coerceAtMost(height - titleHeight)
        val offset = item.cyl_imagePositionAdjustment
        val contentHeight = iconSize + titleHeight
        // [EN] FlatDesign (iOS `CYLFlatDesignTabBarButton`): the title 2 dp above the bottom and the icon centered above it; `layoutCentered` centers a lone icon or title. [CN] 扁平样式（iOS `CYLFlatDesignTabBarButton`）：标题位于底部上方 2 dp，图标在其上方居中；`layoutCentered` 使单独的图标或标题居中。
        val flat = tabBar?.styleRenderer is CYLFlatDesignTabBarStyle
        val hasIcon = iconView.drawable != null || cyl_tabBarItemAnimationView != null || cyl_customIconView != null
        val flatTitleHeight = titleLabel.measuredHeight
        val flatTitleTop = if (!hasIcon && item.layoutCentered) (height - flatTitleHeight) / 2 else height - flatTitleHeight - (2 * density).toInt()
        if (flat && hasTitle) iconSize = iconSize.coerceAtMost(flatTitleTop)
        val iconTop = if (flat) {
            ((if (!hasTitle && item.layoutCentered) (height - iconSize) / 2f else (flatTitleTop - iconSize) / 2f) + insets.top * density + offset.vertical * density).toInt()
        } else ((height - contentHeight) / 2f + insets.top * density + offset.vertical * density + (tabBar?.tabImageViewDefaultOffset ?: 0f) * density).toInt()
        val iconLeft = ((width - iconSize) / 2f + insets.left * density + offset.horizontal * density).toInt()
        iconView.layout(iconLeft, iconTop, iconLeft + iconSize, iconTop + iconSize)
        cyl_customIconView?.let { custom ->
            custom.measure(MeasureSpec.makeMeasureSpec(iconSize, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(iconSize, MeasureSpec.EXACTLY))
            custom.layout(iconLeft, iconTop, iconLeft + iconSize, iconTop + iconSize)
        }
        cyl_tabBarItemAnimationView?.let { animation ->
            // [EN] The animation view sits where the icon is, at its own size. [CN] 动画视图位于图标处，使用自己的尺寸。
            val animationWidth = animation.layoutParams.width.takeIf { it > 0 } ?: iconSize
            val animationHeight = animation.layoutParams.height.takeIf { it > 0 } ?: iconSize
            animation.measure(MeasureSpec.makeMeasureSpec(animationWidth, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(animationHeight, MeasureSpec.EXACTLY))
            val centerX = iconLeft + iconSize / 2
            val centerY = iconTop + iconSize / 2
            animation.layout(centerX - animationWidth / 2, centerY - animationHeight / 2, centerX + animationWidth / 2, centerY + animationHeight / 2)
        }
        val titleOffset = item.cyl_titlePositionAdjustment
        val controllerOffset = tabBar?.tabBarController?.titlePositionAdjustment ?: CYLOffset.zero
        val titleTop = ((if (flat) flatTitleTop.toFloat() else (iconTop + iconSize).toFloat()) + (titleOffset.vertical + controllerOffset.vertical) * density).toInt()
        val titleLeft = ((titleOffset.horizontal + controllerOffset.horizontal) * density).toInt()
        titleLabel.layout(titleLeft, titleTop, titleLeft + width, titleTop + if (flat) flatTitleHeight else titleHeight)
        for (child in 0 until childCount) {
            val badge = getChildAt(child) as? CYLBadgeView ?: continue
            badge.measure(MeasureSpec.UNSPECIFIED, MeasureSpec.UNSPECIFIED)
            val state = cyl_badgeState
            val badgeLeft = (iconView.right - badge.measuredWidth / 2 + state.centerOffset.horizontal * density).toInt()
            val badgeTop = (iconView.top - badge.measuredHeight / 2 + state.centerOffset.vertical * density).toInt()
            badge.layout(badgeLeft, badgeTop, badgeLeft + badge.measuredWidth, badgeTop + badge.measuredHeight)
        }
        item.cyl_viewDidLayoutSubviewsBlock?.let { block -> tabBar?.let { block(it, item, index) } }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                (parent as? CYLTabBar)?.tabBarController?.cyl_tabButtonTouchDown(this)
                downTime = event.eventTime
                downX = event.x
                longPressed = false
                postDelayed(longPressRunnable, (longPressDuration * 1000).toLong())
                isPressed = true
            }
            MotionEvent.ACTION_MOVE -> if (abs(event.x - downX) > 24 * resources.displayMetrics.density) removeCallbacks(longPressRunnable)
            MotionEvent.ACTION_UP -> {
                removeCallbacks(longPressRunnable)
                isPressed = false
                (parent as? CYLTabBar)?.tabBarController?.cyl_tabButtonTouchUp(this)
                val dx = event.x - downX
                if (abs(dx) > 48 * resources.displayMetrics.density) {
                    onSwipe?.invoke(dx < 0)
                } else if (!longPressed) {
                    val now = event.eventTime
                    if (now - lastTapTime <= doubleTapInterval * 1000) {
                        lastTapTime = 0
                        onDoubleTap?.invoke()
                    } else {
                        lastTapTime = now
                        performClick()
                    }
                }
            }
            MotionEvent.ACTION_CANCEL -> {
                removeCallbacks(longPressRunnable)
                isPressed = false
                (parent as? CYLTabBar)?.tabBarController?.cyl_tabButtonTouchUp(this)
            }
        }
        return true
    }

    override fun performClick(): Boolean {
        super.performClick()
        onTap?.invoke()
        return true
    }

    /** [EN] Applies the item's title, images and colors for the current selection. [CN] 按当前选中状态应用标题、图片与颜色。 */
    fun apply(selected: Boolean, tabBar: CYLTabBar) {
        val selectionChanged = isSelected != selected
        isSelected = selected
        if (selectionChanged && cyl_iconViewProvider != null) cyl_applyIconViewProvider()
        titleLabel.text = if (selected) item.cyl_selectedTitle ?: item.title ?: "" else item.title ?: ""
        iconView.setImageDrawable((if (selected) item.selectedImage ?: item.image else item.image)?.mutate())
        val controller = tabBar.tabBarController
        titleLabel.setTextColor(titleColor(selected, tabBar))
        val font = if (selected) item.cyl_selectedTitleFont ?: controller?.cyl_tabBarItemSelectedTitleFont ?: item.cyl_titleFont ?: controller?.cyl_tabBarItemTitleFont
                   else item.cyl_titleFont ?: controller?.cyl_tabBarItemTitleFont
        if (font != null) {
            titleLabel.textSize = font.size
            titleLabel.typeface = font.typeface ?: if (font.bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        }
        val iconColor = iconColor(selected, tabBar)
        if (iconColor != null) iconView.setColorFilter(iconColor, PorterDuff.Mode.SRC_IN) else iconView.clearColorFilter()
        val background = if (selected) item.cyl_selectedBackgroundColor else item.cyl_backgroundColor
        setBackgroundColor(background ?: Color.TRANSPARENT)
        contentDescription = item.accessibilityLabel ?: titleLabel.text
        requestLayout()
    }

    /** [EN] The title color of the tab, selected or not. [CN] Tab 的标题颜色（选中或未选中）。 */
    @ColorInt
    internal fun titleColor(selected: Boolean, tabBar: CYLTabBar): Int {
        val controller = tabBar.tabBarController
        return if (selected) item.cyl_selectedTitleColor ?: controller?.cyl_tabBarItemSelectedTitleColor ?: tabBar.selectedTintColor
               else item.cyl_titleColor ?: controller?.cyl_tabBarItemTitleColor ?: tabBar.unselectedTintColor
    }

    private fun iconColor(selected: Boolean, tabBar: CYLTabBar): Int? {
        val controller = tabBar.tabBarController
        return if (selected) item.cyl_selectedIconColor ?: controller?.cyl_tabBarItemSelectedImageColor else item.cyl_iconColor ?: controller?.cyl_tabBarItemImageColor
    }

    /**
     * [EN] QMUI `setSelectFraction`: while the pages are swiped, the title (and a tinted icon) blends from the normal color
     *      (0) to the selected one (1).
     * [CN] QMUI 的 `setSelectFraction`：滑动翻页时，标题（以及着色的图标）从普通颜色（0）渐变到选中颜色（1）。
     */
    internal fun cyl_setSelectionFraction(fraction: Float, tabBar: CYLTabBar) {
        titleLabel.setTextColor(CYLTabBarIndicator.blend(titleColor(false, tabBar), titleColor(true, tabBar), fraction))
        val normal = iconColor(false, tabBar)
        val selected = iconColor(true, tabBar)
        if (normal != null && selected != null) iconView.setColorFilter(CYLTabBarIndicator.blend(normal, selected, fraction), PorterDuff.Mode.SRC_IN)
    }

    /** [EN] The width of the content (the title, or the icon without a title), in px. [CN] 内容宽度（标题，没有标题时为图标），像素。 */
    internal fun cyl_contentWidth(): Int {
        val title = titleLabel.text
        if (title.isNotEmpty()) return kotlin.math.ceil(titleLabel.paint.measureText(title.toString())).toInt() + titleLabel.paddingLeft + titleLabel.paddingRight
        return if (iconView.width > 0) iconView.width else ((item.cyl_iconSize?.width ?: CYLConstants.CYLTabBarItemImagePlaceholderWidth) * resources.displayMetrics.density).toInt()
    }
}

/**
 * [EN] `CYLTabBar`: lays the tab buttons out in a row, with the plus button at its slot (`plusButtonIndex`), drawn on
 *      top, centered on its slot and raised by `multiplierOfTabBarHeight`; the background and shadow line come from the
 *      controller's `cyl_tabBarBackgroundColor` / `cyl_tabBarShadowColor` or a theme.
 * [CN] `CYLTabBar`：把 Tab 按钮排成一行，PlusButton 在其 slot（`plusButtonIndex`），绘制在最上层、在 slot 上居中并按
 *      `multiplierOfTabBarHeight` 上移；背景与阴影线来自控制器的 `cyl_tabBarBackgroundColor` / `cyl_tabBarShadowColor` 或主题。
 */
class CYLTabBar(context: Context) : ViewGroup(context) {

    /** [EN] `tabBarController`: the owner. [CN] 所属控制器。 */
    internal var tabBarController: CYLTabBarController? = null
    fun tabBarController(): CYLTabBarController? = tabBarController

    /** [EN] `context` (the plus button context). [CN] context（PlusButton 的 context）。 */
    var context_: String? = null
    /** [EN] `tabImageViewDefaultOffset`: moves every icon, in dp. [CN] 所有图标的默认偏移（dp）。 */
    var tabImageViewDefaultOffset: Float = 0f
    /** [EN] `cyl_itemEdgeInsets`: insets of every tab button. [CN] 每个 Tab 按钮的边距。 */
    var cyl_itemEdgeInsets: CYLEdgeInsets = CYLEdgeInsets.zero
    /** [EN] `didLayoutSubViewsBlock`. [CN] 布局完成回调。 */
    var didLayoutSubViewsBlock: CYLTabBarDidLayoutSubViewsBlock? = null
    var syncsClassicStylesToAppearance = true
    /** [EN] `plusButton`: the plus button of this bar, or null. [CN] 本 TabBar 的 PlusButton，没有则为 null。 */
    var plusButton: CYLPlusButton? = null
        internal set
    /** [EN] `plusButtonActive`: whether the plus button's own page is selected. [CN] PlusButton 的页面是否被选中。 */
    var plusButtonActive: Boolean = false
        internal set
    /** [EN] `tabBarButtonArray` (`cyl_subTabBarButtons`): one button per tab, in order. [CN] 每个 Tab 一个按钮，按顺序。 */
    val tabBarButtonArray: List<CYLTabBarItemButton> get() = buttons.toList()
    /** [EN] `tabBarItemWidth`: the width of one tab, in dp. [CN] 一个 Tab 的宽度（dp）。 */
    val tabBarItemWidth: Float get() = if (slotCount() == 0) 0f else width / slotCount().toFloat() / resources.displayMetrics.density
    /** [EN] The selected tint; by default the style's (blue, or the Liquid Glass accent). [CN] 选中颜色；默认使用样式的颜色（蓝色，或液态玻璃的强调色）。 */
    @get:ColorInt @setparam:ColorInt
    var selectedTintColor: Int
        get() = customSelectedTintColor ?: styleRenderer.defaultTintColors(this).first
        set(value) { customSelectedTintColor = value; refreshSelection() }
    /** [EN] The unselected tint; by default the style's (gray, or the Liquid Glass label color). [CN] 未选中颜色；默认使用样式的颜色（灰色，或液态玻璃的文字颜色）。 */
    @get:ColorInt @setparam:ColorInt
    var unselectedTintColor: Int
        get() = customUnselectedTintColor ?: styleRenderer.defaultTintColors(this).second
        set(value) { customUnselectedTintColor = value; refreshSelection() }
    private var customSelectedTintColor: Int? = null
    private var customUnselectedTintColor: Int? = null

    // MARK: - Styles (classic, FlatDesign, Liquid Glass) 样式（经典、扁平、液态玻璃）

    /** [EN] Draws and lays out the bar in the controller's `tabBarStyleType` (see `CYLTabBarStyle.kt`). [CN] 按控制器的 `tabBarStyleType` 绘制与布局 TabBar（见 `CYLTabBarStyle.kt`）。 */
    internal var styleRenderer: CYLTabBarStyleRenderer = CYLClassicTabBarStyle
        set(value) {
            if (field === value) return
            field.onDetach(this)
            field = value
            value.onAttach(this)
            refreshSelection()
            requestLayout()
            invalidate()
        }
    /** [EN] The frame of the items inside the bar, from the style. [CN] Item 在 TabBar 中的区域，由样式给出。 */
    internal val cyl_itemsFrame = Rect()
    internal val cyl_touchSlop: Int get() = touchSlop

    // MARK: - CYLFlatDesignTabBar (FlatDesign style) 扁平样式

    /** [EN] `CYLFlatDesignTabBar.tintColor`: the selected tint (`selectedTintColor`). [CN] 选中颜色（`selectedTintColor`）。 */
    @get:ColorInt @setparam:ColorInt
    var tintColor: Int
        get() = selectedTintColor
        set(value) { selectedTintColor = value }
    /** [EN] `barTintColor`: a color over the FlatDesign blur (default clear). [CN] 叠加在扁平样式模糊之上的颜色（默认透明）。 */
    @get:ColorInt @setparam:ColorInt
    var barTintColor: Int = Color.TRANSPARENT
        set(value) { field = value; invalidate() }
    /** [EN] `backgroundImage`: replaces the FlatDesign blur. [CN] 代替扁平样式的模糊。 */
    var backgroundImage: android.graphics.drawable.Drawable? = null
        set(value) { field = value; invalidate() }
    /** [EN] `shadowImage`: the FlatDesign top line (none by default). [CN] 扁平样式顶部的线条（默认没有）。 */
    var shadowImage: android.graphics.drawable.Drawable? = null
        set(value) { field = value; invalidate() }
    /** [EN] `standardAppearance`: the FlatDesign appearance; the selected item's own one wins. [CN] 扁平样式的外观；选中 item 自身的优先。 */
    var standardAppearance: CYLTabBarAppearance? = null
        set(value) { field = value; refreshSelection(); requestLayout(); invalidate() }
    /**
     * [EN] `useLayoutSafeAreaInsets` / `respectsVerticalStatusBarSafeArea`: kept for the iOS API. On Android the controller's
     *      root view already keeps the items clear of the system bars and the display cutout.
     * [CN] 为与 iOS API 一致而保留。在 Android 上，控制器的根视图已让各 Item 避开系统栏与屏幕挖孔。
     */
    var useLayoutSafeAreaInsets: Boolean = true
    var respectsVerticalStatusBarSafeArea: Boolean = false

    /** [EN] The appearance drawn now: the selected item's, else the bar's. [CN] 当前绘制所用的外观：选中 item 的，否则为 TabBar 的。 */
    internal fun cyl_effectiveAppearance(): CYLTabBarAppearance? {
        val selected = tabBarController?.selectedIndex ?: -1
        return buttons.getOrNull(selected)?.item?.standardAppearance ?: standardAppearance
    }

    internal fun cyl_setShadowVisible(visible: Boolean) {
        shadow.visibility = if (visible) View.VISIBLE else View.GONE
    }

    internal fun cyl_slotCount(): Int = slotCount()

    /** [EN] The slot of the selected tab (the plus button's when it is active), or -1. [CN] 选中 Tab 的 slot（PlusButton 激活时为其 slot），没有则为 -1。 */
    internal fun cyl_selectedSlot(): Int {
        val plusIndex = plusButtonIndex()
        if (plusButtonActive && plusIndex >= 0) return plusIndex
        val index = tabBarController?.selectedIndex ?: return -1
        if (index < 0 || index >= buttons.size) return -1
        return if (plusIndex in 0..index) index + 1 else index
    }

    /** [EN] The tab slot nearest to `position`, skipping a plus button without a page. [CN] 离 `position` 最近的 Tab slot，跳过没有页面的 PlusButton。 */
    internal fun cyl_nearestTabSlot(position: Float): Int {
        val plusIndex = plusButtonIndex()
        val selectable = (0 until slotCount()).filter { it != plusIndex || hasPlusChildViewController() }
        return selectable.minByOrNull { abs(it - position) } ?: 0
    }

    /** [EN] Selects the tab at `slot`, as a tap on it does. [CN] 选中 `slot` 处的 Tab，与点击它相同。 */
    internal fun cyl_selectSlot(slot: Int) {
        val plusIndex = plusButtonIndex()
        if (slot == plusIndex) { plusButton?.performClick(); return }
        val index = if (plusIndex in 0 until slot) slot - 1 else slot
        val button = buttons.getOrNull(index) ?: return
        if (index == tabBarController?.selectedIndex && !plusButtonActive) { refreshSelection(); return }
        tabBarController?.cyl_tabButtonTapped(button)
    }
    @ColorInt var cyl_shadowColor: Int? = 0x33000000
    private val buttons = ArrayList<CYLTabBarItemButton>()
    private val shadow = View(context)

    // MARK: - Indicator and scroll mode (Android only, adapted from QMUITabSegment) 指示器与滚动模式（仅 Android，改编自 QMUITabSegment）

    /** [EN] Android only: the selection indicator (`CYLTabBarIndicator`), or null (default, as on iOS). [CN] 仅 Android：选中指示条（`CYLTabBarIndicator`），默认 null（与 iOS 一致）。 */
    var cyl_indicator: CYLTabBarIndicator? = null
        set(value) { field = value; indicatorIndex = -1; layoutIndicator(animated = false); invalidate() }
    /** [EN] Android only: the duration of the indicator's move to a newly selected tab, in seconds (default 0.2). [CN] 仅 Android：指示条移动到新选中 Tab 的时长（秒，默认 0.2）。 */
    var cyl_indicatorAnimationDuration: Double = 0.2
    /** [EN] Android only: `Fixed` (default) or `Scrollable` (`CYLTabBarScrollMode`). [CN] 仅 Android：`Fixed`（默认）或 `Scrollable`（`CYLTabBarScrollMode`）。 */
    var cyl_scrollMode: CYLTabBarScrollMode = CYLTabBarScrollMode.Fixed
        set(value) { field = value; scrollTo(0, 0); requestLayout() }
    /** [EN] Android only: the room added to each tab's content in the scrollable mode, in dp (default 24). [CN] 仅 Android：滚动模式下每个 Tab 内容之外的空间（dp，默认 24）。 */
    var cyl_itemSpaceInScrollMode: Float = 24f
        set(value) { field = value; requestLayout() }
    private var slotWidths = IntArray(0)

    /**
     * [EN] The system navigation bar's height (px), as iOS's bottom safe area: the bar grows by it, its background reaches
     *      the screen's bottom edge, and the items stay in the top `tabBarHeight`. Set by the controller from the window
     *      insets (edge-to-edge, forced from Android 15); 0 when the window is not edge-to-edge.
     * [CN] 系统导航栏的高度（px），对应 iOS 的底部安全区：TabBar 增高该值，背景延伸到屏幕底边，各 Item 仍位于顶部的 `tabBarHeight` 内。
     *      由控制器根据窗口 insets 设置（edge-to-edge，Android 15 起强制）；窗口不是 edge-to-edge 时为 0。
     */
    internal var cyl_safeAreaBottom: Int = 0
        set(value) {
            if (field == value) return
            field = value
            requestLayout()
        }

    /** [EN] The height of the items' area: the bar without the bottom safe area. [CN] Item 区域的高度：不含底部安全区的 TabBar 高度。 */
    private val itemsHeight: Int get() = cyl_itemsFrame.height().takeIf { it > 0 } ?: (height - cyl_safeAreaBottom)
    private var contentWidth = 0
    private var indicatorIndex = -1
    private var indicatorAnimator: android.animation.ValueAnimator? = null
    private val scroller = android.widget.OverScroller(context)
    private var velocityTracker: android.view.VelocityTracker? = null
    private val touchSlop = android.view.ViewConfiguration.get(context).scaledTouchSlop
    private var dragStartX = 0f
    private var lastDragX = 0f
    private var dragging = false
    private val maxScrollX: Int get() = maxOf(0, contentWidth - (cyl_itemsFrame.width().takeIf { it > 0 } ?: width))
    private var titleAlignedPlusLabel: TextView? = null

    // MARK: - UITabBar (CYLBarBackground) 背景

    /** [EN] `cyl_shadowImageView`: the shadow line at the top of the bar (`cyl_tabBarShadowColor`). [CN] TabBar 顶部的阴影线。 */
    val cyl_shadowImageView: View get() = shadow
    /** [EN] `cyl_backgroundView`: a full-size view behind the tabs, for a background color, image or drawable. [CN] Tab 后面的全尺寸视图，用于背景颜色、图片或 drawable。 */
    val cyl_backgroundView: View by lazy { View(context).also { addView(it, 0) } }
    private var effectView: View? = null
    /** [EN] `cyl_effectViews`: the effect views behind the tabs (the blur of `cyl_backgroundEffect`). [CN] Tab 后面的效果视图（`cyl_backgroundEffect` 的模糊）。 */
    val cyl_effectViews: List<View> get() = listOfNotNull(effectView)
    /** [EN] `cyl_effectView`: the first effect view, or null. [CN] 第一个效果视图，没有时为 null。 */
    val cyl_effectView: View? get() = effectView
    /**
     * [EN] `cyl_backgroundEffect`: an effect drawn behind the tabs: a `RenderEffect` (Android 12+, e.g. a blur of
     *      `cyl_backgroundView`'s drawable), applied to an effect view; null removes it. A `CYLThemeEffect` follows the theme.
     * [CN] 绘制在 Tab 后面的效果：`RenderEffect`（Android 12+，例如对 `cyl_backgroundView` drawable 的模糊），应用到效果视图；null 移除。
     *      `CYLThemeEffect` 会跟随主题。
     */
    var cyl_backgroundEffect: Any? = null
        set(value) {
            field = value
            if (value == null) {
                effectView?.let { removeView(it) }
                effectView = null
                return
            }
            val view = effectView ?: View(context).also { effectView = it; addView(it, if (indexOfChild(cyl_backgroundView) >= 0) 1 else 0) }
            view.background = cyl_backgroundView.background?.constantState?.newDrawable()?.mutate() ?: background?.constantState?.newDrawable()?.mutate()
            val effect = (value as? CYLThemeEffect)?.cyl_rawEffect ?: value
            if (value is CYLThemeEffect) view.cyl_setThemeEffect(value)
            else if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) view.setRenderEffect(effect as? android.graphics.RenderEffect)
            applyEffectForeground()
        }
    /** [EN] `cyl_effectForegroundColor`: a color laid over the effect view (a tint of the blur). [CN] 叠加在效果视图上的颜色（模糊的着色）。 */
    @ColorInt var cyl_effectForegroundColor: Int? = null
        set(value) { field = value; applyEffectForeground() }

    private fun applyEffectForeground() {
        val view = effectView ?: return
        view.foreground = cyl_effectForegroundColor?.let { android.graphics.drawable.ColorDrawable(it) }
    }

    init {
        setBackgroundColor(0xFFF9F9F9.toInt())
        addView(shadow)
        isClickable = true
        // [EN] The plus button rises above the bar and must not be cut (iOS: the tab bar does not clip); the root view
        //      (`CYLTabBarControllerView`) does not clip either and sends touches on the raised part to it (#91).
        // [CN] PlusButton 凸出 TabBar 上方，不能被裁剪（iOS：TabBar 不裁剪子视图）；根视图（`CYLTabBarControllerView`）同样不裁剪，
        //      并把凸起部分上的触摸交给 PlusButton（#91）。
        clipChildren = false
        clipToPadding = false
    }

    /** [EN] `-hasPlusButton`. [CN] 是否有 PlusButton。 */
    fun hasPlusButton(): Boolean = plusButton != null

    /** [EN] `-hasPlusChildViewController`. [CN] PlusButton 是否有子页面。 */
    fun hasPlusChildViewController(): Boolean = CYLPlusButton.hasPlusChildViewControllerForTabBarContext(context_)

    /** [EN] `-plusButtonIndex`: the slot of the plus button among the tabs, or -1. [CN] PlusButton 在 Tab 中的 slot 下标，没有则为 -1。 */
    fun plusButtonIndex(): Int = if (plusButton == null) -1 else CYLPlusButton.indexForTabbarItemsCount(buttons.size, context_)

    /** [EN] `-isPlusButtonLayoutCentered`. [CN] PlusButton 是否居中布局。 */
    fun isPlusButtonLayoutCentered(): Boolean = plusButton?.isLayoutCentered() ?: false

    private fun slotCount(): Int = buttons.size + (if (plusButton != null) 1 else 0)

    /** [EN] `-cyl_reloadTabButtons`: builds the buttons again from the controller's items. [CN] 根据控制器的 item 重新创建按钮。 */
    fun cyl_reloadTabButtons() {
        val controller = tabBarController ?: return
        for (button in buttons) removeView(button)
        buttons.clear()
        plusButton?.let { removeView(it) }
        plusButton = null
        controller.tabBarItems.forEachIndexed { index, item ->
            val button = CYLTabBarItemButton(context, item, index)
            button.doubleTapInterval = controller.cyl_tabBarItemDoubleTapInterval
            button.longPressDuration = controller.cyl_tabBarItemLongPressDuration
            button.onTap = { controller.cyl_tabButtonTapped(button) }
            button.onDoubleTap = { controller.cyl_tabButtonDoubleTapped(button) }
            button.onLongPress = { controller.cyl_tabButtonLongPressed(button) }
            button.onSwipe = { toLeft -> controller.cyl_tabButtonSwiped(button, toLeft) }
            addView(button)
            buttons.add(button)
        }
        val plus = CYLPlusButton.plusButtonForTabBarContext(context_, context)
        if (plus != null) {
            (plus.parent as? ViewGroup)?.removeView(plus)
            plus.setOnClickListener { plus.plusChildViewControllerButtonClicked() }
            addView(plus)
            plusButton = plus
        }
        refreshSelection()
        requestLayout()
        updateGlobals()
    }

    /** [EN] Dark Mode changed: every tab's animation swaps to the current style (#442). [CN] 深色模式变化：每个 Tab 的动画切换为当前风格（#442）。 */
    override fun onConfigurationChanged(newConfig: android.content.res.Configuration?) {
        super.onConfigurationChanged(newConfig)
        for (button in buttons) button.cyl_reloadTabBarItemAnimationViewForCurrentStyle()
        plusButton?.cyl_reloadTabBarItemAnimationViewForCurrentStyle()
        // [EN] A manager that follows Dark Mode (`identifierForTrait`, e.g. a dark skin of a configuration) switches now, as iOS does. [CN] 跟随深色模式的管理器（`identifierForTrait`，例如配置中的深色皮肤）立即切换，与 iOS 一致。
        newConfig?.let { configuration -> tabBarController?.cyl_themeManager?.takeIf { it.identifierForTrait != null }?.updateThemeForTraitCollection(configuration) }
    }

    /** [EN] The iOS globals `CYLTabbarItemsCount`, `CYLPlusButtonIndex`, `CYLPlusButtonWidth`, `CYLTabBarItemWidth`, `CYLTabBarHeight`: the latest tab bar's values. [CN] iOS 的全局变量：最近布局的 TabBar 的值。 */
    private fun updateGlobals() {
        CYLTabbarItemsCount = buttons.size
        CYLPlusButtonIndex = plusButtonIndex()
        CYLPlusButtonWidth = plusButton?.let { it.width / resources.displayMetrics.density } ?: 0f
        CYLTabBarItemWidth = tabBarItemWidth
        CYLTabBarHeight = height / resources.displayMetrics.density
    }

    internal fun refreshSelection() {
        val controller = tabBarController ?: return
        buttons.forEachIndexed { index, button -> button.apply(index == controller.selectedIndex && !plusButtonActive, this) }
        plusButton?.let { plus ->
            plus.isSelected = plusButtonActive
            if (plus.cyl_alignsTitleWithTabBarItemTitles()) {
                // [EN] The tab titles' font and colors (the selected tab's color while the plus button is selected). [CN] Tab 标题的字体与颜色（PlusButton 选中时用选中 Tab 的颜色）。
                val reference = buttons.firstOrNull { it.titleLabel.text.isNotEmpty() && it.titleLabel.visibility == View.VISIBLE }
                if (reference != null) {
                    plus.titleLabel.typeface = reference.titleLabel.typeface
                    plus.titleLabel.setTextSize(android.util.TypedValue.COMPLEX_UNIT_PX, reference.titleLabel.textSize)
                    val selectedColor = controller.cyl_tabBarItemSelectedTitleColor ?: selectedTintColor
                    val normalColor = controller.cyl_tabBarItemTitleColor ?: unselectedTintColor
                    plus.titleLabel.setTextColor(if (plusButtonActive) selectedColor else normalColor)
                }
            } else if (!plusButtonActive || plus.cyl_selectedTitleColor == null) {
                plus.titleLabel.setTextColor(unselectedTintColor)
            }
        }
        shadow.setBackgroundColor(cyl_shadowColor ?: Color.TRANSPARENT)
        layoutIndicator(animated = true)
        scrollSelectedTabIntoView()
        styleRenderer.onSelectionChanged(this, animated = true)
        invalidate()
    }

    private fun indicatorTarget(): Int = if (plusButtonActive) -1 else tabBarController?.selectedIndex ?: -1

    /** [EN] `layoutIndicator`: puts the indicator on the selected tab, moving it there when `animated`. [CN] 把指示条放到选中 Tab 上，`animated` 时移动过去。 */
    private fun layoutIndicator(animated: Boolean) {
        val indicator = cyl_indicator ?: return
        val target = indicatorTarget()
        val targetButton = buttons.getOrNull(target)
        if (targetButton == null || targetButton.width == 0) {
            if (target < 0) indicator.hide()
            indicatorIndex = if (targetButton == null) -1 else indicatorIndex
            invalidate()
            return
        }
        val previous = buttons.getOrNull(indicatorIndex)
        indicatorAnimator?.cancel()
        if (animated && previous != null && previous !== targetButton && cyl_indicatorAnimationDuration > 0) {
            indicatorAnimator = android.animation.ValueAnimator.ofFloat(0f, 1f).apply {
                duration = (cyl_indicatorAnimationDuration * 1000).toLong()
                addUpdateListener { layoutIndicatorInTransition(previous, targetButton, it.animatedValue as Float) }
                addListener(object : android.animation.AnimatorListenerAdapter() {
                    override fun onAnimationEnd(animation: android.animation.Animator) { if (indicatorAnimator === animation) indicatorAnimator = null }
                })
                start()
            }
        } else {
            layoutIndicatorInTransition(targetButton, targetButton, 1f)
        }
        indicatorIndex = target
    }

    private fun indicatorLeft(button: CYLTabBarItemButton, follows: Boolean): Int =
        if (follows) button.left + (button.width - minOf(button.width, button.cyl_contentWidth())) / 2 else button.left

    private fun indicatorWidth(button: CYLTabBarItemButton, follows: Boolean): Int = if (follows) minOf(button.width, button.cyl_contentWidth()) else button.width

    /** [EN] `layoutIndicatorInTransition`: between two tabs, position, width and color blended by `fraction`. [CN] 在两个 Tab 之间，按 `fraction` 渐变位置、宽度与颜色。 */
    private fun layoutIndicatorInTransition(from: CYLTabBarItemButton, to: CYLTabBarItemButton, fraction: Float) {
        val indicator = cyl_indicator ?: return
        val follows = indicator.widthFollowsContent
        val left = indicatorLeft(from, follows) + ((indicatorLeft(to, follows) - indicatorLeft(from, follows)) * fraction).toInt()
        val width = indicatorWidth(from, follows) + ((indicatorWidth(to, follows) - indicatorWidth(from, follows)) * fraction).toInt()
        indicator.update(left, width, CYLTabBarIndicator.blend(from.titleColor(true, this), to.titleColor(true, this), fraction))
        invalidate()
    }

    /**
     * [EN] Android only, QMUI `updateIndicatorPosition`: for a pager of the app, places the indicator (and blends the two
     *      titles) between tab `index` and its neighbor: `offsetPercent` in (0, 1] moves towards `index + 1`, in [-1, 0)
     *      towards `index - 1`; 0 puts it back on `index`. `CYLTabBarController.cyl_swipesBetweenPages` calls it itself.
     * [CN] 仅 Android，QMUI 的 `updateIndicatorPosition`：供 App 自己的翻页控件使用，把指示条放在第 `index` 个 Tab 与相邻 Tab 之间（并渐变两个标题）：
     *      `offsetPercent` 在 (0, 1] 时移向 `index + 1`，在 [-1, 0) 时移向 `index - 1`；0 时回到 `index`。
     *      `CYLTabBarController.cyl_swipesBetweenPages` 会自行调用。
     */
    fun cyl_updateIndicatorPosition(index: Int, offsetPercent: Float) {
        val from = buttons.getOrNull(index) ?: return
        indicatorAnimator?.cancel()
        if (offsetPercent == 0f) {
            refreshSelection()
            return
        }
        val to = buttons.getOrNull(if (offsetPercent < 0) index - 1 else index + 1) ?: return
        val fraction = kotlin.math.abs(offsetPercent).coerceAtMost(1f)
        from.cyl_setSelectionFraction(1 - fraction, this)
        to.cyl_setSelectionFraction(fraction, this)
        layoutIndicatorInTransition(from, to, fraction)
    }

    /** [EN] In the scrollable mode, scrolls the selected tab to the middle when it can. [CN] 滚动模式下，尽量把选中 Tab 滚动到中间。 */
    private fun scrollSelectedTabIntoView() {
        if (maxScrollX <= 0) return
        val button = buttons.getOrNull(indicatorTarget()) ?: return
        if (button.width == 0) return
        val target = (button.left + button.width / 2 - width / 2).coerceIn(0, maxScrollX)
        scroller.forceFinished(true)
        scroller.startScroll(scrollX, 0, target - scrollX, 0, 250)
        startScrollStep()
    }

    /** [EN] Drives the scroller once per frame (not from `computeScroll`, so it also runs without a draw pass). [CN] 每帧推进 scroller（不依赖 `computeScroll`，没有绘制时也能运行）。 */
    private val scrollStep = Runnable { stepScroll() }

    private fun stepScroll() {
        if (!scroller.computeScrollOffset()) return
        scrollTo(scroller.currX.coerceIn(0, maxScrollX), 0)
        postOnAnimation(scrollStep)
    }

    private fun startScrollStep() {
        removeCallbacks(scrollStep)
        postOnAnimation(scrollStep)
    }

    override fun onScrollChanged(l: Int, t: Int, oldl: Int, oldt: Int) {
        super.onScrollChanged(l, t, oldl, oldt)
        layoutFixedChildren()
    }

    override fun onInterceptTouchEvent(event: MotionEvent): Boolean {
        if (styleRenderer.onInterceptTouchEvent(this, event)) return true
        if (maxScrollX <= 0) return false
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> { dragStartX = event.x; lastDragX = event.x; dragging = !scroller.isFinished; scroller.forceFinished(true) }
            MotionEvent.ACTION_MOVE -> if (abs(event.x - dragStartX) > touchSlop) { dragging = true; lastDragX = event.x }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> dragging = false
        }
        if (dragging) parent?.requestDisallowInterceptTouchEvent(true)
        return dragging
    }

    @android.annotation.SuppressLint("ClickableViewAccessibility") // [EN] Dragging scrolls; taps go to the tab buttons. [CN] 拖动用于滚动；点击交给 Tab 按钮。
    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (styleRenderer.onTouchEvent(this, event)) return true
        if (maxScrollX <= 0) return super.onTouchEvent(event)
        val tracker = velocityTracker ?: android.view.VelocityTracker.obtain().also { velocityTracker = it }
        tracker.addMovement(event)
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> { lastDragX = event.x; scroller.forceFinished(true) }
            MotionEvent.ACTION_MOVE -> {
                scrollTo((scrollX + (lastDragX - event.x)).toInt().coerceIn(0, maxScrollX), 0)
                lastDragX = event.x
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                tracker.computeCurrentVelocity(1000)
                scroller.fling(scrollX, 0, -tracker.xVelocity.toInt(), 0, 0, maxScrollX, 0, 0)
                startScrollStep()
                tracker.recycle()
                velocityTracker = null
                dragging = false
            }
        }
        return true
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val tabBarHeight = ((tabBarController?.tabBarHeight ?: CYLConstants.CYLTabBarHeight) * resources.displayMetrics.density).toInt()
        val barHeight = styleRenderer.barHeight(this, tabBarHeight, cyl_safeAreaBottom)
        styleRenderer.itemsFrame(this, width, barHeight, tabBarHeight, cyl_safeAreaBottom, cyl_itemsFrame)
        val height = cyl_itemsFrame.height()
        plusButton?.measure(MeasureSpec.UNSPECIFIED, MeasureSpec.UNSPECIFIED)
        slotWidths = computeSlotWidths(cyl_itemsFrame.width())
        contentWidth = slotWidths.sum()
        val plusIndex = plusButtonIndex()
        var slot = 0
        for ((index, button) in buttons.withIndex()) {
            if (index == plusIndex) slot++
            button.measure(MeasureSpec.makeMeasureSpec(slotWidths.getOrElse(slot) { 0 }, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY))
            slot++
        }
        setMeasuredDimension(width, barHeight)
    }

    /**
     * [EN] The width of each slot: equal slots in the fixed mode (and in the scrollable mode when the content fits), each
     *      tab's content plus `cyl_itemSpaceInScrollMode` otherwise (QMUI `MODE_SCROLLABLE`).
     * [CN] 每个 slot 的宽度：固定模式下等宽（滚动模式下内容放得下时也等宽），否则为每个 Tab 的内容加 `cyl_itemSpaceInScrollMode`（QMUI 的 `MODE_SCROLLABLE`）。
     */
    private fun computeSlotWidths(width: Int): IntArray {
        val slots = slotCount()
        val spacing = styleRenderer.itemSpacing(this)
        val equal = IntArray(slots) { (width - spacing * maxOf(slots - 1, 0)) / maxOf(slots, 1) }
        if (cyl_scrollMode == CYLTabBarScrollMode.Fixed || slots == 0) return equal
        val space = (cyl_itemSpaceInScrollMode * resources.displayMetrics.density).toInt()
        val plusIndex = plusButtonIndex()
        var button = 0
        val widths = IntArray(slots) { slot ->
            if (slot == plusIndex) maxOf(plusButton?.measuredWidth ?: 0, width / maxOf(slots, 1) / 2)
            else buttons[button++].cyl_contentWidth() + space
        }
        return if (widths.sum() <= width) equal else widths
    }

    private fun slotLeft(slot: Int): Int { var left = cyl_itemsFrame.left + slot * styleRenderer.itemSpacing(this); for (index in 0 until slot) left += slotWidths.getOrElse(index) { 0 }; return left }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        val density = resources.displayMetrics.density
        styleRenderer.itemsFrame(this, width, height, ((tabBarController?.tabBarHeight ?: CYLConstants.CYLTabBarHeight) * density).toInt(), cyl_safeAreaBottom, cyl_itemsFrame)
        if (slotWidths.size != slotCount()) slotWidths = computeSlotWidths(cyl_itemsFrame.width())
        val plusIndex = plusButtonIndex()
        var slot = 0
        for ((index, button) in buttons.withIndex()) {
            if (index == plusIndex) slot++
            val slotStart = slotLeft(slot)
            val left = slotStart + (cyl_itemEdgeInsets.left * density).toInt()
            val itemsTop = cyl_itemsFrame.top
            button.layout(left, itemsTop + (cyl_itemEdgeInsets.top * density).toInt(), slotStart + slotWidths.getOrElse(slot) { 0 } - (cyl_itemEdgeInsets.right * density).toInt(), itemsTop + itemsHeight - (cyl_itemEdgeInsets.bottom * density).toInt())
            slot++
        }
        plusButton?.let { plus -> val plusWidth = slotWidths.getOrElse(plusIndex) { 0 }; layoutPlusButton(plus, slotLeft(plusIndex) + plusWidth / 2, plusWidth, density) }
        if (scrollX > maxScrollX) scrollTo(maxScrollX, 0)
        layoutFixedChildren()
        if (changed || indicatorAnimator == null) layoutIndicator(animated = false)
        for (child in 0 until childCount) {
            // [EN] Badges of the plus button (or any direct child) follow their host after a layout. [CN] PlusButton（或任何直接子视图）的角标在布局后跟随宿主。
            val badge = getChildAt(child) as? CYLBadgeView ?: continue
            badge.host?.cyl_refreshBadge()
        }
        updateGlobals()
        didLayoutSubViewsBlock?.invoke(this)
    }

    /** [EN] The plus button centered on `centerX`, its centerY from the multiplier and offset, grown down to the tab titles' line when the title is aligned. [CN] PlusButton 以 `centerX` 居中，centerY 来自倍数与偏移；标题对齐时向下延伸到 Tab 标题所在的线。 */
    /** [EN] The shadow line, background and effect views stay in place while the tabs scroll. [CN] 阴影线、背景与效果视图在 Tab 滚动时保持不动。 */
    private fun layoutFixedChildren() {
        val density = resources.displayMetrics.density
        shadow.layout(scrollX, 0, scrollX + width, maxOf(1, (0.5f * density).toInt()))
        for (background in listOfNotNull(if (childCount > 0 && getChildAt(0) !is CYLTabBarItemButton && getChildAt(0) !== shadow) getChildAt(0) else null, effectView)) {
            background.measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY))
            background.layout(scrollX, 0, scrollX + width, height)
        }
    }

    private fun layoutPlusButton(plus: CYLPlusButton, centerX: Int, slotWidth: Int, density: Float) {
        val tabBarHeight = itemsHeight / density
        val appliesOffset = plus.cyl_showsTitleInTabBarItem() || plus.cyl_appliesCenterYOffsetWithoutTitle || plus.provider != null
        val offset = if (appliesOffset) plus.constantOfPlusButtonCenterYOffsetForTabBarHeight(tabBarHeight) else 0f
        val centerY = cyl_itemsFrame.top + (itemsHeight * plus.multiplierOfTabBarHeight(tabBarHeight) + offset * density).toInt()
        val w = if (plus.measuredWidth > 0) plus.measuredWidth else slotWidth
        var h = if (plus.measuredHeight > 0) plus.measuredHeight else itemsHeight
        val top = centerY - h / 2
        if (plus.cyl_alignsTitleWithTabBarItemTitles() && plus.cyl_showsTitleInTabBarItem()) {
            // [EN] The plus title's center on the tab titles' line: the button grows down to that line. [CN] PlusButton 标题中心线与 Tab 标题对齐：按钮向下延伸到该线。
            val reference = buttons.firstOrNull { it.titleLabel.text.isNotEmpty() && it.titleLabel.visibility == View.VISIBLE }
            if (reference != null) {
                val titleCenter = reference.top + (reference.titleLabel.top + reference.titleLabel.bottom) / 2
                val titleHeight = plus.titleLabel.measuredHeight.takeIf { it > 0 } ?: reference.titleLabel.height
                h = maxOf(h, titleCenter + titleHeight / 2 - top)
            }
        }
        plus.layout(centerX - w / 2, top, centerX + w / 2, top + h)
        plus.bringToFront()
    }

    private val touchableAreaPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    /** [EN] True while the plus button is drawn on its own, after everything else. [CN] 单独绘制 PlusButton（在其他内容之后）时为 true。 */
    private var drawingPlusButtonLast = false

    /** [EN] The plus button is skipped in the children's pass and drawn last by `dispatchDraw`. [CN] PlusButton 在子视图的绘制中跳过，由 `dispatchDraw` 最后绘制。 */
    override fun drawChild(canvas: Canvas, child: View, drawingTime: Long): Boolean {
        if (child === plusButton && !drawingPlusButtonLast) return false
        return super.drawChild(canvas, child, drawingTime)
    }

    /**
     * [EN] The plus button is always on top, as on iOS: drawn after the tabs, the style's layers above them (the Liquid
     *      Glass dock's rim and bubble highlight) and the indicator, so nothing the bar draws cuts it where it rises past
     *      the bar. Neither the bar nor the root view clips it, and the root view sends touches on its raised part to it
     *      (`CYLTabBarControllerView.dispatchTouchEvent`, #91).
     * [CN] PlusButton 始终在最上层，与 iOS 相同：在 Tab、样式在 Tab 之上绘制的内容（液态玻璃胶囊的边缘与气泡高光）以及指示条之后绘制，
     *      因此凸出 TabBar 的部分不会被 TabBar 绘制的任何内容切割。TabBar 与根视图都不裁剪它，根视图把凸起部分上的触摸交给它
     *      （`CYLTabBarControllerView.dispatchTouchEvent`，#91）。
     */
    override fun dispatchDraw(canvas: Canvas) {
        styleRenderer.drawBehindItems(this, canvas)
        super.dispatchDraw(canvas)
        styleRenderer.drawAboveItems(this, canvas)
        cyl_indicator?.draw(canvas, cyl_itemsFrame.top + paddingTop, cyl_itemsFrame.top + itemsHeight - paddingBottom, resources.displayMetrics.density)
        val plus = plusButton ?: return
        if (plus.visibility == View.VISIBLE || plus.animation != null) {
            drawingPlusButtonLast = true
            drawChild(canvas, plus, drawingTime)
            drawingPlusButtonLast = false
        }
        if (plus.showsTouchableArea) {
            // [EN] `showsTouchableArea` (#91): the touchable rect, for debugging. [CN] `showsTouchableArea`（#91）：绘制可点击区域，用于调试。
            touchableAreaPaint.color = plus.touchableAreaColor
            canvas.drawRect(plus.touchableRect(), touchableAreaPaint)
        }
    }

    /** [EN] Whether a touch (in this bar's coordinates) falls in the plus button's touchable rect, inside or outside the bar (#91). [CN] 触摸（本 TabBar 坐标）是否落在 PlusButton 的可点击矩形内，无论在 TabBar 内外（#91）。 */
    fun cyl_plusButtonTouchable(x: Float, y: Float): Boolean = plusButton?.touchableRect()?.contains((x + scrollX).toInt(), y.toInt()) ?: false

    /** [EN] Sends a touch (in this bar's coordinates) to the plus button. [CN] 把触摸（本 TabBar 坐标）交给 PlusButton。 */
    fun cyl_dispatchTouchToPlusButton(event: MotionEvent): Boolean {
        val plus = plusButton ?: return false
        val forwarded = MotionEvent.obtain(event).apply { offsetLocation(scrollX - plus.left.toFloat(), -plus.top.toFloat()) }
        val handled = plus.dispatchTouchEvent(forwarded)
        forwarded.recycle()
        return handled
    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        if (event.actionMasked == MotionEvent.ACTION_DOWN && cyl_plusButtonTouchable(event.x, event.y) && plusButton?.let { !Rect(it.left, it.top, it.right, it.bottom).contains((event.x + scrollX).toInt(), event.y.toInt()) } == true) {
            plusRoutedTouch = true
        }
        if (plusRoutedTouch) {
            val handled = cyl_dispatchTouchToPlusButton(event)
            if (event.actionMasked == MotionEvent.ACTION_UP || event.actionMasked == MotionEvent.ACTION_CANCEL) plusRoutedTouch = false
            return handled
        }
        return super.dispatchTouchEvent(event)
    }

    private var plusRoutedTouch = false

    /** [EN] `-cyl_tabBarButtonWithTabIndex:`. [CN] 第 `index` 个 Tab 的按钮。 */
    fun cyl_tabBarButtonWithTabIndex(index: Int): CYLTabBarItemButton? = buttons.getOrNull(index)

    companion object {
        /** [EN] The iOS globals (`CYLTabBarController.h`), updated by the latest tab bar layout. [CN] iOS 的全局变量，由最近一次 TabBar 布局更新。 */
        @JvmStatic var CYLTabbarItemsCount: Int = 0
        @JvmStatic var CYLPlusButtonIndex: Int = -1
        @JvmStatic var CYLPlusButtonWidth: Float = 0f
        @JvmStatic var CYLTabBarItemWidth: Float = 0f
        @JvmStatic var CYLTabBarHeight: Float = CYLConstants.CYLTabBarHeight
    }
}
