package com.cyl.animateditem

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.drawable.Drawable
import android.util.AttributeSet
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.widget.FrameLayout
import android.widget.LinearLayout
import kotlin.math.abs

/**
 * [EN] A centered vertical stack whose every element is a `CYLAnimatedItemView` (an animated icon and a title): an empty
 *      state, a placeholder, an onboarding card. The Android counterpart of iOS `CYLAnimatedItemStackView`. The first item
 *      is the reserved one (the main icon and title); more items follow it: a hint, a button, a separator, an icon. A tap
 *      on an item performs its action (any string, e.g. "retry"), whose handler is given when the view is created or
 *      later; a tap anywhere else performs `backgroundAction`. Titles wrap to the view's width (`appendItem` lifts the
 *      one-line limit; for an item of your own set `titleView.maxLines`). Lengths are px except names ending in `Dp`.
 * [CN] 每个元素都是 `CYLAnimatedItemView`（动效图标加标题）的居中竖向堆叠视图：空状态、占位图、引导卡片。对应 iOS 的
 *      `CYLAnimatedItemStackView`。第一个条目是保留条目（主图标与标题），其后可追加提示、按钮、分隔符、图标等条目。点击条目执行它的动作
 *      （任意字符串，例如 "retry"），动作的处理在创建时或之后指定；点击其他位置执行 `backgroundAction`。标题按视图宽度换行（`appendItem`
 *      取消单行限制；自建条目请设置 `titleView.maxLines`）。长度单位为 px，名称以 `Dp` 结尾的除外。
 */
open class CYLAnimatedItemStackView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
) : FrameLayout(context, attrs) {

    /**
     * [EN] Runs on the main thread when an action is performed: a tap on an item, a tap on the background, or `performAction`.
     * [CN] 执行动作时在主线程调用：点击条目、点击背景或调用 `performAction`。
     */
    fun interface ActionHandler {
        /**
         * [EN] `action` was performed in `stackView`. [CN] `stackView` 中执行了 `action`。
         */
        fun onAction(stackView: CYLAnimatedItemStackView, action: String)
    }

    /**
     * [EN] A stack of `itemViews` (each with no action) and the handlers of `actions`. An action without a handler does nothing.
     * [CN] 由 `itemViews`（均无动作）组成的堆叠视图，以及 `actions` 中的处理。没有处理的动作什么都不做。
     */
    constructor(context: Context, itemViews: List<CYLAnimatedItemView>, actions: Map<String, ActionHandler> = emptyMap()) : this(context) {
        handlers.putAll(actions)
        itemViews.forEach { append(it) }
    }

    /**
     * [EN] The vertical stack holding the items: centered, sized by its items.
     * [CN] 容纳条目的竖向堆叠视图：居中，大小由条目决定。
     */
    val stackView: LinearLayout = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL
    }

    private val entries = ArrayList<Entry>()
    private val handlers = HashMap<String, ActionHandler>()
    private val touchSlop = ViewConfiguration.get(context).scaledTouchSlop
    private var downX = 0f
    private var downY = 0f

    /**
     * [EN] One item and its action. [CN] 一个条目及其动作。
     */
    private class Entry(val view: CYLAnimatedItemView, var action: String?, var spacingBeforeDp: Float? = null)

    /**
     * [EN] Every item, top to bottom. [CN] 所有条目，自上而下。
     */
    val itemViews: List<CYLAnimatedItemView> get() = entries.map { it.view }

    /**
     * [EN] The reserved first item (the main icon and title); null while the stack is empty.
     * [CN] 保留的第一个条目（主图标与标题）；堆叠为空时为 null。
     */
    val firstItemView: CYLAnimatedItemView? get() = entries.firstOrNull()?.view

    /**
     * [EN] The smallest space between the items and the view's edges, in dp (16 by default).
     * [CN] 条目与视图边缘之间的最小间距，单位 dp（默认 16）。
     */
    var contentMarginDp: Float = DEFAULT_SPACING_DP
        set(value) { field = maxOf(0f, value); updateMargins() }

    /**
     * [EN] The direction of the stack (iOS `axis`): `Vertical` (default, one item under the other) or `Horizontal` (one row,
     *      the spacing on the leading side).
     * [CN] 堆叠方向（iOS `axis`）：`Vertical`（默认，上下排列）或 `Horizontal`（一行，间距位于前侧）。
     */
    var axis: CYLAnimatedItemAxis = CYLAnimatedItemAxis.Vertical
        set(value) {
            field = value
            stackView.orientation = if (value == CYLAnimatedItemAxis.Horizontal) LinearLayout.HORIZONTAL else LinearLayout.VERTICAL
            stackView.gravity = if (value == CYLAnimatedItemAxis.Horizontal) Gravity.CENTER_VERTICAL else Gravity.CENTER_HORIZONTAL
            updateSpacing()
        }

    /**
     * [EN] The space between items appended without their own spacing, in dp (iOS `spacing`; 16 by default, never negative).
     * [CN] 追加时没有指定间距的条目之间的间距，单位 dp（iOS `spacing`；默认 16，不为负）。
     */
    var spacingDp: Float = DEFAULT_SPACING_DP
        set(value) { field = maxOf(0f, value); updateSpacing() }

    /**
     * [EN] The default icon color of the items (iOS stack `itemAppearance`): an item's own `iconColor` wins; null for none.
     * [CN] 条目的默认图标颜色（iOS 堆叠的 `itemAppearance`）：条目自己的 `iconColor` 优先；null 表示没有。
     */
    var iconColor: Int? = null
        set(value) { field = value; entries.forEach { it.view.stackIconColor = value } }

    /**
     * [EN] The default icon color of selected items; null uses `iconColor`. [CN] 选中条目的默认图标颜色；null 时使用 `iconColor`。
     */
    var selectedIconColor: Int? = null
        set(value) { field = value; entries.forEach { it.view.stackSelectedIconColor = value } }

    /**
     * [EN] The space before an item in dp: 0 for the first, else its own spacing or `spacingDp`. [CN] 条目之前的间距（dp）：第一个为 0，否则为其自身间距或 `spacingDp`。
     */
    fun spacingBeforeDpOf(itemView: CYLAnimatedItemView): Float {
        val index = entries.indexOfFirst { it.view === itemView }
        if (index <= 0) return 0f
        return entries[index].spacingBeforeDp ?: spacingDp
    }

    /**
     * [EN] Sets every item's margin on the stack's axis. [CN] 按堆叠方向设置每个条目的外边距。
     */
    private fun updateSpacing() {
        entries.forEach { entry ->
            val params = entry.view.layoutParams as? LinearLayout.LayoutParams ?: return@forEach
            val space = dp(spacingBeforeDpOf(entry.view))
            if (axis == CYLAnimatedItemAxis.Horizontal) {
                params.topMargin = 0
                params.marginStart = space
            } else {
                params.marginStart = 0
                params.topMargin = space
            }
            entry.view.layoutParams = params
        }
    }

    /**
     * [EN] The action of a tap anywhere outside an item with an action; null (default) turns that off. A screen reader
     *      reaches it through the first item when that item has no action of its own.
     * [CN] 点击带动作条目以外任意位置时执行的动作；null（默认）关闭。第一个条目没有自己的动作时，读屏通过它触发该动作。
     */
    var backgroundAction: String? = null
        set(value) {
            field = value?.takeIf { it.isNotEmpty() }
            entries.forEach { updateAccessibility(it) }
        }

    init {
        addView(stackView, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT, Gravity.CENTER))
        updateMargins()
        // [EN] A screen reader reads the items together, top to bottom. [CN] 读屏自上而下连续朗读这些条目。
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_YES
    }

    // MARK: - Items 条目

    /**
     * [EN] Appends an item under the last one, `spacingBeforeDp` below it (ignored for the first item); a tap on it performs
     *      `action` when that is not null. An item without an action does not take taps: they reach the background. An item
     *      already in the stack is left where it is. The stack sets the item's click listener.
     * [CN] 在最后一个条目下方 `spacingBeforeDp` 处追加条目（第一个条目忽略该值）；`action` 不为 null 时点击它执行该动作。没有动作的条目不接收点击：
     *      点击会传给背景。已在堆叠中的条目保持原位。堆叠视图会设置条目的点击监听。
     */
    @JvmOverloads
    open fun append(itemView: CYLAnimatedItemView, action: String? = null, spacingBeforeDp: Float? = null) {
        if (entries.any { it.view === itemView }) return
        val params = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        stackView.addView(itemView, params)
        // [EN] null: the stack's `spacingDp`. [CN] null：使用堆叠的 `spacingDp`。
        val entry = Entry(itemView, null, spacingBeforeDp?.let { maxOf(0f, it) })
        entries.add(entry)
        itemView.stackIconColor = iconColor
        itemView.stackSelectedIconColor = selectedIconColor
        updateSpacing()
        // [EN] Its own action, or for the first item without one the background action (reached by a screen reader: touches
        //      on items without an action go to the background). [CN] 执行自己的动作；没有动作的第一个条目执行背景动作（由读屏触发：
        //      落在无动作条目上的触摸交给背景）。
        itemView.setOnClickListener { view ->
            val item = view as CYLAnimatedItemView
            val ownAction = if (isItemInteractive(item)) action(item) else null
            val fallbackAction = if (item === firstItemView) backgroundAction else null
            val resolved = ownAction ?: fallbackAction
            if (resolved != null) performAction(resolved)
        }
        setAction(action, itemView)
    }

    /**
     * [EN] Makes, appends and returns an item with the icon above the title and titles on as many lines as they need.
     * [CN] 创建、追加并返回一个条目：图标在标题上方，标题按需多行显示。
     */
    @JvmOverloads
    open fun appendItem(
        title: CharSequence?,
        image: Drawable? = null,
        animationURL: String? = null,
        action: String? = null,
        spacingBeforeDp: Float? = null,
    ): CYLAnimatedItemView {
        val itemView = CYLAnimatedItemView(context)
        itemView.axis = CYLAnimatedItemAxis.Vertical
        itemView.titleView.maxLines = Int.MAX_VALUE
        itemView.titleView.ellipsize = null
        itemView.title = title
        itemView.image = image
        itemView.animationURL = animationURL
        append(itemView, action, spacingBeforeDp)
        return itemView
    }

    /**
     * [EN] Removes an item from the stack (and from the view hierarchy). [CN] 从堆叠视图中移除条目（同时移出视图层级）。
     */
    open fun remove(itemView: CYLAnimatedItemView) {
        val index = entries.indexOfFirst { it.view === itemView }
        if (index < 0) return
        entries.removeAt(index)
        itemView.setOnClickListener(null)
        itemView.isClickable = true
        itemView.importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_AUTO
        stackView.removeView(itemView)
        itemView.stackIconColor = null
        itemView.stackSelectedIconColor = null
        // [EN] The new first item has no spacing before it, and may carry the background action.
        // [CN] 新的第一个条目前没有间距，并可能承载背景动作。
        updateSpacing()
        entries.forEach { updateAccessibility(it) }
    }

    /**
     * [EN] Sets or, with null, removes the action of an item in the stack. [CN] 设置堆叠中某个条目的动作；传 null 移除。
     */
    open fun setAction(action: String?, itemView: CYLAnimatedItemView) {
        val entry = entries.firstOrNull { it.view === itemView } ?: return
        entry.action = action?.takeIf { it.isNotEmpty() }
        updateAccessibility(entry)
    }

    /**
     * [EN] The action of an item; null for none or an item not in the stack. [CN] 条目的动作；没有动作或条目不在堆叠中时为 null。
     */
    fun action(itemView: CYLAnimatedItemView): String? = entries.firstOrNull { it.view === itemView }?.action

    /**
     * [EN] Whether an item takes taps: its tap performs its action, a tap on it is not a background tap, and a screen reader
     *      reads it as a button. By default: it has an action and it is enabled. Override for items with their own switch
     *      (CYLTableViewPlaceHolder's tap interaction), then call `updateInteractionOfItemViews()` after that switch changes.
     * [CN] 条目是否接收点击：点击它执行其动作、点击它不算背景点击、读屏把它读作按钮。默认：有动作且可用。条目有自己的开关时（CYLTableViewPlaceHolder
     *      的点击交互）重写本方法，并在开关变化后调用 `updateInteractionOfItemViews()`。
     */
    open fun isItemInteractive(itemView: CYLAnimatedItemView): Boolean = action(itemView) != null && itemView.isEnabled

    /**
     * [EN] Applies `isItemInteractive` again to every item, after a change the stack cannot see.
     * [CN] 在堆叠视图无法感知的变化之后，对所有条目重新应用 `isItemInteractive`。
     */
    fun updateInteractionOfItemViews() {
        entries.forEach { updateAccessibility(it) }
    }

    /**
     * [EN] The first item whose tap performs `action`. [CN] 点击时执行 `action` 的第一个条目。
     */
    fun itemView(action: String): CYLAnimatedItemView? = entries.firstOrNull { it.action == action }?.view

    // MARK: - Actions 动作

    /**
     * [EN] Sets or, with null, removes the handler of an action. [CN] 设置动作的处理；传 null 移除。
     */
    fun setHandler(handler: ActionHandler?, action: String) {
        if (handler == null) handlers.remove(action) else handlers[action] = handler
    }

    /**
     * [EN] Runs the handler of `action`; false when it has none. [CN] 执行 `action` 的处理；没有处理时返回 false。
     */
    fun performAction(action: String): Boolean {
        val handler = handlers[action] ?: return false
        handler.onAction(this, action)
        return true
    }

    /**
     * [EN] The tap outside items with an action performs `backgroundAction`. [CN] 点击带动作条目以外的位置执行 `backgroundAction`。
     */
    override fun performClick(): Boolean {
        val handled = super.performClick()
        return backgroundAction?.let { performAction(it) } ?: handled
    }

    // MARK: - Touches 触摸

    /**
     * [EN] Takes the touch away from items without an action (and from the empty space), so it becomes a background tap;
     *      items with an action keep theirs.
     * [CN] 从没有动作的条目（以及空白处）接管触摸，使其成为背景点击；带动作的条目保留自己的触摸。
     */
    override fun onInterceptTouchEvent(event: MotionEvent): Boolean {
        if (event.actionMasked != MotionEvent.ACTION_DOWN) return false
        downX = event.x
        downY = event.y
        return itemWithActionAt(event.x, event.y) == null
    }

    @SuppressLint("ClickableViewAccessibility") // [EN] Taps go through performClick. [CN] 点击通过 performClick 触发。
    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> { downX = event.x; downY = event.y }
            MotionEvent.ACTION_UP -> if (abs(event.x - downX) <= touchSlop && abs(event.y - downY) <= touchSlop) performClick()
        }
        return backgroundAction != null
    }

    private fun itemWithActionAt(x: Float, y: Float): CYLAnimatedItemView? = entries.firstOrNull { entry ->
        val view = entry.view
        if (!isItemInteractive(view) || view.visibility != View.VISIBLE) return@firstOrNull false
        val left = stackView.left + view.left
        val top = stackView.top + view.top
        x >= left && x < left + view.width && y >= top && y < top + view.height
    }?.view

    // MARK: - Accessibility 无障碍

    /**
     * [EN] An item with an action is a button; one without is text; one with nothing to read (no title, no description, no
     *      action) is decoration and hidden from a screen reader. The first item reads as a button for the background action.
     * [CN] 带动作的条目是按钮；没有动作的是文字；没有可朗读内容（无标题、无描述、无动作）的是装饰，对读屏隐藏。第一个条目可作为背景动作的按钮。
     */
    private fun updateAccessibility(entry: Entry) {
        val view = entry.view
        // [EN] Clickable decides the role the item reports (button or text). [CN] 是否可点击决定条目报告的角色（按钮或文字）。
        view.isClickable = actsAsButton(entry)
        val reads = actsAsButton(entry) || !view.contentDescription.isNullOrEmpty() || !view.title.isNullOrEmpty()
        view.importantForAccessibility = if (reads) IMPORTANT_FOR_ACCESSIBILITY_YES else IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
    }

    private fun actsAsButton(entry: Entry) = isItemInteractive(entry.view) || (entry.view === firstItemView && backgroundAction != null)

    // MARK: - Layout 布局

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        // [EN] A title set after the item was added changes whether it is decoration. [CN] 条目加入后设置的标题会改变它是否为装饰。
        entries.forEach { updateAccessibility(it) }
        super.onLayout(changed, left, top, right, bottom)
    }

    private fun updateMargins() {
        val margin = dp(contentMarginDp)
        (stackView.layoutParams as? LayoutParams)?.let {
            it.setMargins(margin, margin, margin, margin)
            stackView.layoutParams = it
        }
    }

    private fun dp(value: Float): Int =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics).toInt()

    companion object {
        /**
         * [EN] The default space between items and around them, in dp. [CN] 条目之间及四周的默认间距，单位 dp。
         */
        const val DEFAULT_SPACING_DP = 16f
    }
}
