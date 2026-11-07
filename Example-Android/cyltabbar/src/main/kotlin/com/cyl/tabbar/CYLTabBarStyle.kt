package com.cyl.tabbar

import android.content.res.Configuration
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.ColorDrawable
import android.view.Choreographer
import android.view.MotionEvent
import android.view.View
import androidx.annotation.ColorInt
import kotlin.math.abs
import kotlin.math.roundToInt
import kotlin.math.sign

/**
 * [EN] The iOS FlatDesign names on Android. On iOS, `CYLFlatDesignTabBar` is the view that replaces the system
 *      `UITabBar`; on Android `CYLTabBar` already is that view, so the FlatDesign style (`CYLTabBarStyleType.FlatDesign`)
 *      is `CYLTabBar` drawn by `CYLFlatDesignTabBarStyle`, and its classes are the same classes under the iOS names.
 * [CN] iOS 扁平样式在 Android 上的名称。iOS 的 `CYLFlatDesignTabBar` 是替换系统 `UITabBar` 的视图；Android 的 `CYLTabBar` 本身就是这个视图，
 *      因此扁平样式（`CYLTabBarStyleType.FlatDesign`）就是由 `CYLFlatDesignTabBarStyle` 绘制的 `CYLTabBar`，其各个类即同一组类的 iOS 名称。
 */
typealias CYLFlatDesignTabBar = CYLTabBar
typealias CYLFlatDesignTabBarButton = CYLTabBarItemButton
typealias CYLFlatDesignTabBarItem = CYLTabBarItem

/**
 * [EN] How one tab bar style lays out and draws `CYLTabBar`: the bar's height, the frame of the items, what is drawn
 *      behind and above them, and touches of its own. The tab bar asks its `styleRenderer`, picked from the controller's
 *      `tabBarStyleType`, so each style lives in one place.
 * [CN] 一种 TabBar 样式如何布局与绘制 `CYLTabBar`：TabBar 的高度、Item 的区域、在 Item 后面与上面绘制的内容，以及自己的触摸。TabBar 询问根据
 *      控制器 `tabBarStyleType` 选出的 `styleRenderer`，因此每种样式都集中在一处。
 */
internal interface CYLTabBarStyleRenderer {
    /** [EN] The pages extend under the bar, which floats over them. [CN] 页面延伸到 TabBar 下方，TabBar 浮在页面之上。 */
    val drawsPagesUnderTabBar: Boolean get() = false
    /** [EN] The default selected and unselected tint, when the app sets none. [CN] App 未设置时的默认选中与未选中颜色。 */
    fun defaultTintColors(tabBar: CYLTabBar): Pair<Int, Int> = 0xFF007AFF.toInt() to 0xFF8E8E93.toInt()
    /** [EN] The bar's height for items of `itemsHeight` above a bottom safe area of `safeBottom`. [CN] Item 高度为 `itemsHeight`、底部安全区为 `safeBottom` 时 TabBar 的高度。 */
    fun barHeight(tabBar: CYLTabBar, itemsHeight: Int, safeBottom: Int): Int = itemsHeight + safeBottom
    /** [EN] The frame of the items inside the bar. [CN] Item 在 TabBar 中的区域。 */
    fun itemsFrame(tabBar: CYLTabBar, width: Int, height: Int, itemsHeight: Int, safeBottom: Int, out: Rect) {
        out.set(0, 0, width, itemsHeight)
    }
    fun onAttach(tabBar: CYLTabBar) {}
    fun onDetach(tabBar: CYLTabBar) {}
    /** [EN] Drawn behind the items. [CN] 绘制在 Item 后面。 */
    fun drawBehindItems(tabBar: CYLTabBar, canvas: Canvas) {}
    /** [EN] Drawn above the items. [CN] 绘制在 Item 上面。 */
    fun drawAboveItems(tabBar: CYLTabBar, canvas: Canvas) {}
    /** [EN] The selected tab changed. [CN] 选中的 Tab 已改变。 */
    fun onSelectionChanged(tabBar: CYLTabBar, animated: Boolean) {}
    fun onInterceptTouchEvent(tabBar: CYLTabBar, event: MotionEvent): Boolean = false
    fun onTouchEvent(tabBar: CYLTabBar, event: MotionEvent): Boolean = false
    /** [EN] The bar's background color changed (`cyl_tabBarBackgroundColor`). [CN] TabBar 背景色已改变（`cyl_tabBarBackgroundColor`）。 */
    fun applyBackgroundColor(tabBar: CYLTabBar, @ColorInt color: Int?) {}

    companion object {
        fun forStyle(style: CYLEnums.CYLTabBarStyleType): CYLTabBarStyleRenderer = when (style) {
            CYLEnums.CYLTabBarStyleType.FlatDesign -> CYLFlatDesignTabBarStyle()
            CYLEnums.CYLTabBarStyleType.LiquidGlass -> CYLLiquidGlassTabBarStyle()
            else -> CYLClassicTabBarStyle
        }
    }
}

/** [EN] Whether the app runs in Dark Mode. [CN] App 是否处于深色模式。 */
private fun View.cyl_isDarkMode(): Boolean =
    (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

/**
 * [EN] The classic tab bar (`Default` / `System`): an opaque bar below the pages with a hairline on top, as `UITabBar`
 *      before Liquid Glass.
 * [CN] 经典 TabBar（`Default` / `System`）：页面下方的不透明 TabBar，顶部有一条细线，与液态玻璃之前的 `UITabBar` 相同。
 */
internal object CYLClassicTabBarStyle : CYLTabBarStyleRenderer {
    override fun onAttach(tabBar: CYLTabBar) {
        applyBackgroundColor(tabBar, tabBar.tabBarController?.cyl_tabBarBackgroundColor)
        tabBar.cyl_setShadowVisible(true)
    }

    override fun applyBackgroundColor(tabBar: CYLTabBar, color: Int?) {
        tabBar.background = ColorDrawable(color ?: 0xFFF9F9F9.toInt())
    }
}

/**
 * [EN] FlatDesign, translated from iOS `CYLFlatDesignTabBar`: a blur of the pages behind the bar (`UIBlurEffectStyleProminent`)
 *      under `barTintColor`, or `backgroundImage` instead of the blur; `shadowImage` (or the appearance's shadow color) as
 *      the top line; `standardAppearance` of the selected item, else of the bar; buttons equally wide, or centered with
 *      `CYLTabBarAppearance.stackedItemWidth` / `stackedItemSpacing`; the title 2 dp above the bottom and the icon centered
 *      above it (`layoutCentered` centers a lone icon or title); tint blue when selected, gray otherwise.
 * [CN] 扁平样式，由 iOS 的 `CYLFlatDesignTabBar` 翻译而来：TabBar 后面页面的模糊（`UIBlurEffectStyleProminent`）上叠加 `barTintColor`，
 *      或以 `backgroundImage` 代替模糊；顶部线条为 `shadowImage`（或 appearance 的阴影色）；外观取选中 item 的 `standardAppearance`，
 *      否则取 TabBar 的；按钮等宽，或按 `CYLTabBarAppearance.stackedItemWidth` / `stackedItemSpacing` 居中；标题位于底部上方 2 dp，图标
 *      在其上方居中（`layoutCentered` 使只有图标或只有标题时居中）；选中为蓝色，否则为灰色。
 */
internal class CYLFlatDesignTabBarStyle : CYLTabBarStyleRenderer {
    private val backdrop = CYLTabBarBackdrop()
    private val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val rect = RectF()

    override val drawsPagesUnderTabBar: Boolean get() = true

    override fun onAttach(tabBar: CYLTabBar) {
        tabBar.background = null
        tabBar.setWillNotDraw(false)
        tabBar.cyl_setShadowVisible(false)
    }

    override fun applyBackgroundColor(tabBar: CYLTabBar, color: Int?) {
        tabBar.barTintColor = color ?: Color.TRANSPARENT
    }

    override fun itemsFrame(tabBar: CYLTabBar, width: Int, height: Int, itemsHeight: Int, safeBottom: Int, out: Rect) {
        val appearance = tabBar.cyl_effectiveAppearance()
        val itemWidth = appearance?.stackedItemWidth ?: 0f
        val count = tabBar.cyl_slotCount()
        if (appearance?.stackedItemPositioningCentered == true && count > 0) {
            // [EN] `.centered`: items of `stackedItemWidth` (or an equal share) spaced by `stackedItemSpacing`, centered; when they do not fit, they fill the width. [CN] `.centered`：item 宽为 `stackedItemWidth`（或平分），间距 `stackedItemSpacing`，整体居中；放不下时铺满宽度。
            val density = tabBar.resources.displayMetrics.density
            val space = (appearance.stackedItemSpacing * density).coerceAtLeast(0f)
            val each = if (itemWidth > 0f) itemWidth * density else (width - (count - 1) * space) / count
            val total = (count * each + (count - 1) * space).roundToInt()
            if (each > 0f && total <= width) {
                val left = (width - total) / 2
                out.set(left, 0, left + total, itemsHeight)
                return
            }
        }
        out.set(0, 0, width, itemsHeight)
    }

    override fun drawBehindItems(tabBar: CYLTabBar, canvas: Canvas) {
        val appearance = tabBar.cyl_effectiveAppearance()
        rect.set(0f, 0f, tabBar.width.toFloat(), tabBar.height.toFloat())
        val image = tabBar.backgroundImage
        if (image != null && appearance?.backgroundColor == null) {
            image.setBounds(0, 0, tabBar.width, tabBar.height)
            image.draw(canvas)
        } else {
            // [EN] `UIBlurEffectStyleProminent`: a strong blur under a near-opaque system background. [CN] `UIBlurEffectStyleProminent`：强模糊，上面是接近不透明的系统背景色。
            val pages = tabBar.tabBarController?.pagesContainer
            val dark = tabBar.cyl_isDarkMode()
            val blurred = pages != null && backdrop.draw(canvas, pages, tabBar.x - pages.x, tabBar.y - pages.y, rect, 0f,
                CYLGlassEffects(saturation = 1.8f, blurRadius = 30f * tabBar.resources.displayMetrics.density))
            fillPaint.color = when {
                blurred -> if (dark) 0xB31C1C1E.toInt() else 0xBFF9F9F9.toInt()
                else -> if (dark) 0xF21C1C1E.toInt() else 0xF2F9F9F9.toInt()
            }
            canvas.drawRect(rect, fillPaint)
            fillPaint.color = appearance?.backgroundColor ?: tabBar.barTintColor
            if (Color.alpha(fillPaint.color) > 0) canvas.drawRect(rect, fillPaint)
        }
        val shadowImage = tabBar.shadowImage
        val density = tabBar.resources.displayMetrics.density
        if (shadowImage != null) {
            val height = shadowImage.intrinsicHeight.takeIf { it > 0 && appearance != null } ?: 1
            shadowImage.setBounds(0, 0, tabBar.width, height)
            shadowImage.draw(canvas)
        } else {
            val shadowColor = appearance?.shadowColor ?: return
            fillPaint.color = shadowColor
            canvas.drawRect(0f, 0f, tabBar.width.toFloat(), maxOf(1f, 0.5f * density), fillPaint)
        }
    }
}

/**
 * [EN] Liquid Glass. iOS draws it in the system (`UITabBar` on iOS 26), so there is no iOS code to translate: this is
 *      Kyant's `LiquidBottomTabs` (AndroidLiquidGlass) on views. A capsule 64 dp tall floats over the pages, 16 dp from
 *      the sides, above the navigation bar; its glass is the pages under it with vibrancy, an 8 dp blur and a 24 dp lens,
 *      tinted `#FAFAFA` / `#121212` at 40 %. A selection bubble one tab wide sits behind the selected tab (10 % black or
 *      white); pressing it grows it (×78/56) into a lens with chromatic dispersion, a rim highlight and a shadow, it can be
 *      dragged to another tab, and it follows taps with a spring. Selected tabs use the accent `#0088FF` / `#0091FF`.
 *      Android 13+ draws the lens, Android 12 the blur only, older versions a translucent capsule.
 * [CN] 液态玻璃。iOS 由系统绘制（iOS 26 的 `UITabBar`），没有可翻译的 iOS 代码：这是 Kyant 的 `LiquidBottomTabs`（AndroidLiquidGlass）的
 *      View 版本。一个 64 dp 高的胶囊浮在页面之上，距两侧 16 dp，位于导航栏上方；其玻璃是下方页面加上鲜艳度、8 dp 模糊与 24 dp 透镜，
 *      着色为 40 % 的 `#FAFAFA` / `#121212`。一个与 Tab 等宽的选中气泡位于选中 Tab 后面（10 % 黑色或白色）；按下时放大（×78/56）为带色散的
 *      透镜，并有边缘高光与阴影，可拖到其他 Tab，点击时按弹簧动画跟随。选中 Tab 使用强调色 `#0088FF` / `#0091FF`。Android 13+ 绘制透镜，
 *      Android 12 只有模糊，更早的版本为半透明胶囊。
 */
internal class CYLLiquidGlassTabBarStyle : CYLTabBarStyleRenderer {
    private val panelBackdrop = CYLTabBarBackdrop()
    private val bubbleBackdrop = CYLTabBarBackdrop()
    private val highlight = CYLGlassHighlight()
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG)
    private val panel = RectF()
    private val panelShape = RectF()
    private val bubble = RectF()
    private var tint: Int? = null
    private var host: CYLTabBar? = null

    /** [EN] The bubble's position, in slots. [CN] 气泡的位置（以 slot 为单位）。 */
    private val position = CYLSpring(0f, 1f, 1000f, 0.001f)
    private val pressProgress = CYLSpring(0f, 1f, 1000f, 0.001f)
    private val scaleX = CYLSpring(1f, 0.6f, 250f, 0.001f)
    private val scaleY = CYLSpring(1f, 0.7f, 250f, 0.001f)
    /** [EN] The drag offset that nudges the panel (up to 4 dp), back to 0 with a spring. [CN] 拖动产生的面板偏移（最多 4 dp），用弹簧回到 0。 */
    private val panelDrag = CYLSpring(0f, 0.5f, 300f, 0.5f)
    private var positioned = false
    private var frameTime = 0L
    private val frameCallback = Choreographer.FrameCallback { now -> onFrame(now) }

    private var downX = 0f
    private var lastX = 0f
    private var pressedOnBubble = false
    private var dragging = false

    override val drawsPagesUnderTabBar: Boolean get() = true

    override fun defaultTintColors(tabBar: CYLTabBar): Pair<Int, Int> =
        if (tabBar.cyl_isDarkMode()) 0xFF0091FF.toInt() to 0xFFEBEBF5.toInt() else 0xFF0088FF.toInt() to 0xFF1C1C1E.toInt()

    override fun barHeight(tabBar: CYLTabBar, itemsHeight: Int, safeBottom: Int): Int {
        val density = tabBar.resources.displayMetrics.density
        return (PANEL_HEIGHT * density).toInt() + bottomGap(safeBottom, density)
    }

    private fun bottomGap(safeBottom: Int, density: Float): Int = maxOf(safeBottom, (BOTTOM_MARGIN * density).toInt())

    override fun itemsFrame(tabBar: CYLTabBar, width: Int, height: Int, itemsHeight: Int, safeBottom: Int, out: Rect) {
        val density = tabBar.resources.displayMetrics.density
        val side = (SIDE_MARGIN * density).toInt()
        val padding = (PANEL_PADDING * density).toInt()
        val bottom = height - bottomGap(safeBottom, density)
        val top = bottom - (PANEL_HEIGHT * density).toInt()
        panel.set(side.toFloat(), top.toFloat(), (width - side).toFloat(), bottom.toFloat())
        out.set(side + padding, top + padding, width - side - padding, bottom - padding)
    }

    override fun onAttach(tabBar: CYLTabBar) {
        host = tabBar
        tabBar.background = null
        tabBar.setWillNotDraw(false)
        tabBar.cyl_setShadowVisible(false)
        tint = tabBar.tabBarController?.cyl_tabBarBackgroundColor
        positioned = false
    }

    override fun onDetach(tabBar: CYLTabBar) {
        Choreographer.getInstance().removeFrameCallback(frameCallback)
        host = null
    }

    override fun applyBackgroundColor(tabBar: CYLTabBar, color: Int?) {
        tint = color
        tabBar.invalidate()
    }

    override fun onSelectionChanged(tabBar: CYLTabBar, animated: Boolean) {
        val slot = tabBar.cyl_selectedSlot()
        if (slot < 0) return
        if (!positioned || !animated || !tabBar.isAttachedToWindow) {
            position.snap(slot.toFloat())
            positioned = true
            tabBar.invalidate()
            return
        }
        position.target = slot.toFloat()
        animate()
    }

    private fun animate() {
        frameTime = 0L
        Choreographer.getInstance().removeFrameCallback(frameCallback)
        Choreographer.getInstance().postFrameCallback(frameCallback)
    }

    private fun onFrame(now: Long) {
        val tabBar = host ?: return
        val seconds = if (frameTime == 0L) 1f / 60f else (now - frameTime) / 1_000_000_000f
        frameTime = now
        var moving = position.step(seconds)
        moving = pressProgress.step(seconds) || moving
        moving = scaleX.step(seconds) || moving
        moving = scaleY.step(seconds) || moving
        moving = panelDrag.step(seconds) || moving
        tabBar.invalidate()
        if (moving) Choreographer.getInstance().postFrameCallback(frameCallback)
    }

    private fun slotWidth(tabBar: CYLTabBar): Float {
        val frame = tabBar.cyl_itemsFrame
        val count = tabBar.cyl_slotCount()
        return if (count == 0) 0f else frame.width() / count.toFloat()
    }

    /** [EN] `LiquidBottomTabs`' panel offset: 4 dp at most, eased. [CN] `LiquidBottomTabs` 的面板偏移：最多 4 dp，带缓动。 */
    private fun panelOffset(tabBar: CYLTabBar): Float {
        val width = tabBar.width.toFloat().takeIf { it > 0f } ?: return 0f
        val fraction = (panelDrag.value / width).coerceIn(-1f, 1f)
        val eased = 1f - (1f - abs(fraction)) * (1f - abs(fraction))
        return 4f * tabBar.resources.displayMetrics.density * fraction.sign * eased
    }

    override fun drawBehindItems(tabBar: CYLTabBar, canvas: Canvas) {
        if (!positioned) onSelectionChanged(tabBar, animated = false)
        val density = tabBar.resources.displayMetrics.density
        val dark = tabBar.cyl_isDarkMode()
        val offset = panelOffset(tabBar)
        val pages = tabBar.tabBarController?.pagesContainer
        val press = pressProgress.value

        // [EN] The panel: vibrancy, an 8 dp blur and a 24 dp lens, grown by 16 dp while the bubble is pressed. [CN] 面板：鲜艳度、8 dp 模糊与 24 dp 透镜，按下气泡时放大 16 dp。
        val grow = 1f + 16f * density / panel.width().coerceAtLeast(1f) * press
        val shape = panelShape.apply {
            set(panel)
            offset(offset, 0f)
            inset(-width() * (grow - 1f) / 2f, -height() * (grow - 1f) / 2f)
        }
        val radius = shape.height() / 2f
        // [EN] Backdrop's default `Shadow`: 24 dp, 4 dp down, 10 % black, so the dock shows on a white page as on iOS. [CN] Backdrop 默认的 `Shadow`：24 dp、向下 4 dp、10 % 黑色，使胶囊在白色页面上也可见，与 iOS 相同。
        shadowPaint.color = if (dark) Color.BLACK else Color.WHITE
        shadowPaint.setShadowLayer(12f * density, 0f, 4f * density, if (dark) 0x40000000 else 0x1A000000)
        canvas.drawRoundRect(shape, radius, radius, shadowPaint)
        val glass = pages != null && panelBackdrop.draw(canvas, pages, tabBar.x - pages.x + shape.left, tabBar.y - pages.y + shape.top, shape, radius,
            CYLGlassEffects(blurRadius = 8f * density, refractionHeight = 24f * density, refractionAmount = 24f * density))
        paint.color = tint ?: if (dark) 0x66121212 else 0x66FAFAFA
        if (!glass) paint.color = if (dark) 0xE6121212.toInt() else 0xE6FAFAFA.toInt()
        canvas.drawRoundRect(shape, radius, radius, paint)

        // [EN] The bubble behind the selected tab. [CN] 选中 Tab 后面的气泡。
        val width = slotWidth(tabBar)
        if (width <= 0f || tabBar.cyl_selectedSlot() < 0) return
        val frame = tabBar.cyl_itemsFrame
        val bubbleHeight = BUBBLE_HEIGHT * density
        val centerX = frame.left + (position.value + 0.5f) * width + offset
        val centerY = panel.centerY()
        val velocity = position.velocity / 10f
        val sx = scaleX.value / (1f - (velocity * 0.75f).coerceIn(-0.2f, 0.2f))
        val sy = scaleY.value * (1f - (velocity * 0.25f).coerceIn(-0.2f, 0.2f))
        bubble.set(centerX - width / 2f * sx, centerY - bubbleHeight / 2f * sy, centerX + width / 2f * sx, centerY + bubbleHeight / 2f * sy)
        val bubbleRadius = bubble.height() / 2f
        if (press > 0.01f && pages != null) {
            bubbleBackdrop.draw(canvas, pages, tabBar.x - pages.x + bubble.left, tabBar.y - pages.y + bubble.top, bubble, bubbleRadius,
                CYLGlassEffects(saturation = 1f, refractionHeight = 10f * density * press, refractionAmount = 14f * density * press, chromaticAberration = true))
        }
        paint.color = if (dark) Color.WHITE else Color.BLACK
        paint.alpha = ((0.1f * (1f - press) + 0.03f * press) * 255).toInt()
        canvas.drawRoundRect(bubble, bubbleRadius, bubbleRadius, paint)
    }

    override fun drawAboveItems(tabBar: CYLTabBar, canvas: Canvas) {
        // [EN] Backdrop's default `Highlight` on the dock: the 0.5 dp rim. [CN] 胶囊上 Backdrop 默认的 `Highlight`：0.5 dp 的边缘高光。
        if (!panelShape.isEmpty) highlight.draw(canvas, panelShape, panelShape.height() / 2f, tabBar.resources.displayMetrics.density, 1f)
        val press = pressProgress.value
        if (press > 0.01f && !bubble.isEmpty) highlight.draw(canvas, bubble, bubble.height() / 2f, tabBar.resources.displayMetrics.density, press)
    }

    // MARK: - Pressing and dragging the bubble (DampedDragAnimation) 按下与拖动气泡

    override fun onInterceptTouchEvent(tabBar: CYLTabBar, event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                downX = event.x
                lastX = event.x
                dragging = false
                pressedOnBubble = bubble.contains(event.x, event.y)
                if (pressedOnBubble) press(true)
            }
            MotionEvent.ACTION_MOVE -> if (pressedOnBubble && abs(event.x - downX) > tabBar.cyl_touchSlop) {
                dragging = true
                lastX = event.x
                tabBar.parent?.requestDisallowInterceptTouchEvent(true)
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> if (pressedOnBubble && !dragging) press(false)
        }
        return dragging
    }

    override fun onTouchEvent(tabBar: CYLTabBar, event: MotionEvent): Boolean {
        if (!pressedOnBubble) return false
        when (event.actionMasked) {
            MotionEvent.ACTION_MOVE -> {
                val dx = event.x - lastX
                lastX = event.x
                val width = slotWidth(tabBar).takeIf { it > 0f } ?: return true
                val rtl = tabBar.layoutDirection == View.LAYOUT_DIRECTION_RTL
                val last = (tabBar.cyl_slotCount() - 1).toFloat()
                position.target = (position.target + dx / width * (if (rtl) -1f else 1f)).coerceIn(0f, last)
                position.snap(position.target)
                panelDrag.snap(panelDrag.value + dx)
                panelDrag.target = panelDrag.value
                tabBar.invalidate()
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                val slot = tabBar.cyl_nearestTabSlot(position.target)
                position.target = slot.toFloat()
                panelDrag.target = 0f
                press(false)
                if (event.actionMasked == MotionEvent.ACTION_UP) tabBar.cyl_selectSlot(slot)
                pressedOnBubble = false
                dragging = false
            }
        }
        return true
    }

    private fun press(pressed: Boolean) {
        pressProgress.target = if (pressed) 1f else 0f
        val scale = if (pressed) PRESSED_SCALE else 1f
        scaleX.target = scale
        scaleY.target = scale
        animate()
    }

    companion object {
        const val PANEL_HEIGHT = 64f
        const val PANEL_PADDING = 4f
        const val BUBBLE_HEIGHT = 56f
        const val SIDE_MARGIN = 16f
        const val BOTTOM_MARGIN = 12f
        const val PRESSED_SCALE = 78f / 56f
    }
}
