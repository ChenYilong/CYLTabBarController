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
        val iconTop = ((height - contentHeight) / 2f + insets.top * density + offset.vertical * density + (tabBar?.tabImageViewDefaultOffset ?: 0f) * density).toInt()
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
        val titleTop = (iconTop + iconSize + (titleOffset.vertical + controllerOffset.vertical) * density).toInt()
        val titleLeft = ((titleOffset.horizontal + controllerOffset.horizontal) * density).toInt()
        titleLabel.layout(titleLeft, titleTop, titleLeft + width, titleTop + titleHeight)
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
        val titleColor = (if (selected) item.cyl_selectedTitleColor ?: controller?.cyl_tabBarItemSelectedTitleColor ?: tabBar.selectedTintColor
                          else item.cyl_titleColor ?: controller?.cyl_tabBarItemTitleColor ?: tabBar.unselectedTintColor)
        titleLabel.setTextColor(titleColor)
        val font = if (selected) item.cyl_selectedTitleFont ?: controller?.cyl_tabBarItemSelectedTitleFont ?: item.cyl_titleFont ?: controller?.cyl_tabBarItemTitleFont
                   else item.cyl_titleFont ?: controller?.cyl_tabBarItemTitleFont
        if (font != null) {
            titleLabel.textSize = font.size
            titleLabel.typeface = font.typeface ?: if (font.bold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        }
        val iconColor = if (selected) item.cyl_selectedIconColor ?: controller?.cyl_tabBarItemSelectedImageColor else item.cyl_iconColor ?: controller?.cyl_tabBarItemImageColor
        if (iconColor != null) iconView.setColorFilter(iconColor, PorterDuff.Mode.SRC_IN) else iconView.clearColorFilter()
        val background = if (selected) item.cyl_selectedBackgroundColor else item.cyl_backgroundColor
        setBackgroundColor(background ?: Color.TRANSPARENT)
        contentDescription = item.accessibilityLabel ?: titleLabel.text
        requestLayout()
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
    @ColorInt var selectedTintColor: Int = 0xFF007AFF.toInt()
    @ColorInt var unselectedTintColor: Int = 0xFF8E8E93.toInt()
    @ColorInt var cyl_shadowColor: Int? = 0x33000000
    private val buttons = ArrayList<CYLTabBarItemButton>()
    private val shadow = View(context)
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
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val height = ((tabBarController?.tabBarHeight ?: CYLConstants.CYLTabBarHeight) * resources.displayMetrics.density).toInt()
        val slots = maxOf(slotCount(), 1)
        val slotWidth = width / slots
        for (button in buttons) {
            button.measure(MeasureSpec.makeMeasureSpec(slotWidth, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY))
        }
        plusButton?.measure(MeasureSpec.UNSPECIFIED, MeasureSpec.UNSPECIFIED)
        setMeasuredDimension(width, height)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        val density = resources.displayMetrics.density
        val slots = maxOf(slotCount(), 1)
        val slotWidth = width / slots
        val plusIndex = plusButtonIndex()
        var slot = 0
        for ((index, button) in buttons.withIndex()) {
            if (index == plusIndex) slot++
            val left = slot * slotWidth + (cyl_itemEdgeInsets.left * density).toInt()
            button.layout(left, (cyl_itemEdgeInsets.top * density).toInt(), slot * slotWidth + slotWidth - (cyl_itemEdgeInsets.right * density).toInt(), height - (cyl_itemEdgeInsets.bottom * density).toInt())
            slot++
        }
        plusButton?.let { layoutPlusButton(it, plusIndex * slotWidth + slotWidth / 2, slotWidth, density) }
        shadow.layout(0, 0, width, maxOf(1, (0.5f * density).toInt()))
        for (background in listOfNotNull(if (childCount > 0 && getChildAt(0) !is CYLTabBarItemButton && getChildAt(0) !== shadow) getChildAt(0) else null, effectView)) {
            background.measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY))
            background.layout(0, 0, width, height)
        }
        for (child in 0 until childCount) {
            // [EN] Badges of the plus button (or any direct child) follow their host after a layout. [CN] PlusButton（或任何直接子视图）的角标在布局后跟随宿主。
            val badge = getChildAt(child) as? CYLBadgeView ?: continue
            badge.host?.cyl_refreshBadge()
        }
        updateGlobals()
        didLayoutSubViewsBlock?.invoke(this)
    }

    /** [EN] The plus button centered on `centerX`, its centerY from the multiplier and offset, grown down to the tab titles' line when the title is aligned. [CN] PlusButton 以 `centerX` 居中，centerY 来自倍数与偏移；标题对齐时向下延伸到 Tab 标题所在的线。 */
    private fun layoutPlusButton(plus: CYLPlusButton, centerX: Int, slotWidth: Int, density: Float) {
        val tabBarHeight = height / density
        val appliesOffset = plus.cyl_showsTitleInTabBarItem() || plus.cyl_appliesCenterYOffsetWithoutTitle || plus.provider != null
        val offset = if (appliesOffset) plus.constantOfPlusButtonCenterYOffsetForTabBarHeight(tabBarHeight) else 0f
        val centerY = (height * plus.multiplierOfTabBarHeight(tabBarHeight) + offset * density).toInt()
        val w = if (plus.measuredWidth > 0) plus.measuredWidth else slotWidth
        var h = if (plus.measuredHeight > 0) plus.measuredHeight else height
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

    override fun dispatchDraw(canvas: Canvas) {
        super.dispatchDraw(canvas)
        val plus = plusButton ?: return
        if (plus.showsTouchableArea) {
            // [EN] `showsTouchableArea` (#91): the touchable rect, for debugging. [CN] `showsTouchableArea`（#91）：绘制可点击区域，用于调试。
            touchableAreaPaint.color = plus.touchableAreaColor
            canvas.drawRect(plus.touchableRect(), touchableAreaPaint)
        }
    }

    /** [EN] Whether a touch (in this bar's coordinates) falls in the plus button's touchable rect, inside or outside the bar (#91). [CN] 触摸（本 TabBar 坐标）是否落在 PlusButton 的可点击矩形内，无论在 TabBar 内外（#91）。 */
    fun cyl_plusButtonTouchable(x: Float, y: Float): Boolean = plusButton?.touchableRect()?.contains(x.toInt(), y.toInt()) ?: false

    /** [EN] Sends a touch (in this bar's coordinates) to the plus button. [CN] 把触摸（本 TabBar 坐标）交给 PlusButton。 */
    fun cyl_dispatchTouchToPlusButton(event: MotionEvent): Boolean {
        val plus = plusButton ?: return false
        val forwarded = MotionEvent.obtain(event).apply { offsetLocation(-plus.left.toFloat(), -plus.top.toFloat()) }
        val handled = plus.dispatchTouchEvent(forwarded)
        forwarded.recycle()
        return handled
    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        if (event.actionMasked == MotionEvent.ACTION_DOWN && cyl_plusButtonTouchable(event.x, event.y) && plusButton?.let { !Rect(it.left, it.top, it.right, it.bottom).contains(event.x.toInt(), event.y.toInt()) } == true) {
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
