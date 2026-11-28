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
    private class Entry(val view: CYLAnimatedItemView, var action: String?, var spacingBeforeDp: Float? = null) {
        /** [EN] Set when the entry is made. [CN] 条目创建时设置。 */
        lateinit var divider: CYLAnimatedItemView
        /** [EN] This gap's own choice: true a divider (`setDivider`), false none (`removeDivider`), null follows `showsDividers`. [CN] 本间隙自己的选择：true 有分隔线（`setDivider`），false 没有（`removeDivider`），null 跟随 `showsDividers`。 */
        var dividerOwn: Boolean? = null
        /** [EN] The divider's own spacing before and after it, dp; null falls back. [CN] 分隔线自己的前后间距（dp）；null 时回退。 */
        var dividerBeforeDp: Float? = null
        var dividerAfterDp: Float? = null
    }

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
            dividers.forEach { it.dividerAxis = value }
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
        set(value) { field = value; entries.forEach { it.view.stackIconColor = value; it.divider.stackIconColor = value } }

    /**
     * [EN] The default icon color of selected items; null uses `iconColor`. [CN] 选中条目的默认图标颜色；null 时使用 `iconColor`。
     */
    var selectedIconColor: Int? = null
        set(value) { field = value; entries.forEach { it.view.stackSelectedIconColor = value; it.divider.stackSelectedIconColor = value } }

    /**
     * [EN] The default animation tint of the items (the same names and values as [CYLAnimatedItemView.animationTint]): set once, it
     *      applies to every item held now and appended later, and again after a night-mode change. An item's own non-empty value wins;
     *      null / empty on the item inherits this; clearing it removes the inherited value from the items that set none.
     * [CN] 条目的默认动画着色（名称与取值同 [CYLAnimatedItemView.animationTint]）：设置一次，对现有及之后追加的所有条目生效，夜间模式变化后重新应用。
     *      条目自己的非空值优先；条目上的 null / 空表示继承此值；清除后，没有自己设置的条目不再继承。
     */
    var animationTint: String? = null
        set(value) { field = value?.takeIf { it.isNotEmpty() }; entries.forEach { it.view.stackAnimationTint = field; it.divider.stackAnimationTint = field } }

    /**
     * [EN] The default night-mode color of a fixed `animationTint`, inherited like `animationTint`. [CN] 固定 `animationTint` 的默认夜间颜色，继承规则同 `animationTint`。
     */
    var animationDarkTint: String? = null
        set(value) { field = value?.takeIf { it.isNotEmpty() }; entries.forEach { it.view.stackAnimationDarkTint = field; it.divider.stackAnimationDarkTint = field } }

    /**
     * [EN] How the items' animations WITHOUT a tint are drawn, inherited like `animationTint` (see [CYLAnimatedItemView.animationRenderingMode]): an item's
     *      own non-null mode wins; null (default) lets the URL option `renderingMode=` and then `Automatic` decide.
     * [CN] 条目中没有着色的动画如何绘制，继承规则同 `animationTint`（见 [CYLAnimatedItemView.animationRenderingMode]）：条目自己的非 null 模式优先；
     *      null（默认）时由 URL 选项 `renderingMode=` 再到 `Automatic` 决定。
     */
    var animationRenderingMode: CYLAnimationRenderingMode? = null
        set(value) { field = value; entries.forEach { it.view.stackAnimationRenderingMode = value } }

    /**
     * [EN] The color of the divider lines (an ARGB color, used as it is); null (default) derives it: the stack's EXPLICIT `iconColor` at
     *      `CYLAnimatedItemDividerAlpha` (0.6), else the built-in secondary text color of the divider's own night mode
     *      (`CYLAnimatedItemBuiltInColors.divider`, contrast >= 3:1 on a white and on a dark bar).
     * [CN] 分隔线的颜色（ARGB 颜色，按原样使用）；null（默认）时推导：堆叠的显式 `iconColor` 以 `CYLAnimatedItemDividerAlpha`（0.6）的不透明度，
     *      否则取分隔线自身夜间模式的内置次要文字色（`CYLAnimatedItemBuiltInColors.divider`，在白色与深色栏上对比度 >= 3:1）。
     */
    var dividerColor: Int? = null
        set(value) { if (field != value) { field = value; dividers.forEach { it.stackDividerColor = value } } }

    /**
     * [EN] The length of the divider lines in dp (`CYLAnimatedItemDividerLength`, 20, by default; never negative). A line is 1 dp
     *      thick and centered in its slot: the slot is 1 x length in a horizontal stack, swapped in a vertical one.
     * [CN] 分隔线的长度，单位 dp（默认 `CYLAnimatedItemDividerLength`，20；不为负）。线粗 1 dp，在其位置内居中：水平堆叠中位置为 1 x 长度，垂直堆叠中互换。
     */
    var dividerLengthDp: Float = CYLAnimatedItemDividerLength
        set(value) { field = maxOf(0f, value); dividers.forEach { it.dividerLengthDp = field } }

    /**
     * [EN] Whether every gap has a divider line (false by default); `removeDivider` turns one gap off, `setDivider` one on. A divider is
     *      owned by the stack, never an item: it is not in `itemViews`, takes no taps, is hidden from a screen reader. It belongs to the
     *      gap AFTER an item (it moves with that item and goes with it), and shows only if that item is not GONE and a later item
     *      that is not GONE exists (hidden items leave neither divider nor spacing). Appending, removing, moving and hiding update it by itself.
     *      The gap with a divider is `before + 1 dp + after` (see `dividerSpacingBeforeDp`); the next item's spacing is never added on top.
     * [CN] 是否每个间隙都有分隔线（默认 false）；`removeDivider` 关闭某个间隙，`setDivider` 开启某个间隙。分隔线由堆叠拥有，不是条目：不在 `itemViews` 中、
     *      不接收点击、对读屏隐藏。它属于某个条目「之后」的间隙（随该条目移动、随它删除），只有该条目不是 GONE 且之后还有非 GONE 的条目时才显示
     *      （隐藏的条目既不留分隔线也不留间距）。追加、移除、移动、隐藏都会自动更新。带分隔线的间隙为 `前 + 1 dp + 后`（见 `dividerSpacingBeforeDp`）；
     *      不会再叠加下一个条目的间距。
     */
    var showsDividers: Boolean = false
        set(value) { if (field != value) { field = value; updateSpacing() } }

    /**
     * [EN] The default space before a divider line, in dp, for dividers without their own value; null (default) is `spacingDp`.
     *      Gap with a divider = before + 1 dp + after; before = the divider's own value, else this, else `spacingDp`. Example: `spacingDp` 12, a
     *      divider of (8, 8) makes the gap 8 + 1 + 8 = 17, not 12 + 8 + 1 + 8 + 12.
     * [CN] 没有自己取值的分隔线之前的默认间距（dp）；null（默认）为 `spacingDp`。带分隔线的间隙 = 前 + 1 dp + 后；前 = 分隔线自己的值，其次本属性，
     *      再次 `spacingDp`。例：`spacingDp` 为 12、分隔线为 (8, 8) 时间隙为 8 + 1 + 8 = 17，而不是 12 + 8 + 1 + 8 + 12。
     */
    var dividerSpacingBeforeDp: Float? = null
        set(value) { field = value?.let { maxOf(0f, it) }; updateSpacing() }

    /**
     * [EN] The default space after a divider line, in dp, for dividers without their own value; null (default): the NEXT item's
     *      own `spacingBeforeDp`, else `spacingDp`. That value is only a fallback, never added to the divider's space.
     * [CN] 没有自己取值的分隔线之后的默认间距（dp）；null（默认）：下一个条目自己的 `spacingBeforeDp`，否则 `spacingDp`。该值只是回退值，
     *      不会叠加到分隔线的间距上。
     */
    var dividerSpacingAfterDp: Float? = null
        set(value) { field = value?.let { maxOf(0f, it) }; updateSpacing() }

    /**
     * [EN] Attaches a divider after the CURRENT LAST item (nothing on an empty stack), with its own spacing before and after in dp
     *      (null: the stack's `dividerSpacingBeforeDp` / `dividerSpacingAfterDp`, then the fallbacks). Use between two appends:
     *      `append(camera); appendDivider(8f, 8f); append(searchButton)`.
     * [CN] 在当前最后一个条目之后附加分隔线（空堆叠上什么都不做），可带自己的前后间距（dp）（null：堆叠的 `dividerSpacingBeforeDp` /
     *      `dividerSpacingAfterDp`，再回退）。用在两次追加之间：`append(camera); appendDivider(8f, 8f); append(searchButton)`。
     */
    @JvmOverloads
    fun appendDivider(spacingBeforeDp: Float? = null, spacingAfterDp: Float? = null) {
        entries.lastOrNull()?.let { setDivider(it.view, spacingBeforeDp, spacingAfterDp) }
    }

    /**
     * [EN] Gives the gap right after `itemView` a divider with its own spacing (see `appendDivider`); replaces the one it has. Does
     *      nothing for an item not in the stack. [CN] 给 `itemView` 之后的间隙设置分隔线及自己的间距（见 `appendDivider`）；替换已有的。条目不在堆叠中时什么都不做。
     */
    @JvmOverloads
    fun setDivider(itemView: CYLAnimatedItemView, spacingBeforeDp: Float? = null, spacingAfterDp: Float? = null) {
        val entry = entries.firstOrNull { it.view === itemView } ?: return
        entry.dividerOwn = true
        entry.dividerBeforeDp = spacingBeforeDp?.let { maxOf(0f, it) }
        entry.dividerAfterDp = spacingAfterDp?.let { maxOf(0f, it) }
        updateSpacing()
    }

    /**
     * [EN] Turns the gap right after `itemView` off, also while `showsDividers` is true. [CN] 关闭 `itemView` 之后的间隙，`showsDividers` 为 true 时也一样。
     */
    fun removeDivider(itemView: CYLAnimatedItemView) {
        val entry = entries.firstOrNull { it.view === itemView } ?: return
        entry.dividerOwn = false
        entry.dividerBeforeDp = null
        entry.dividerAfterDp = null
        updateSpacing()
    }

    /**
     * [EN] Whether the gap after `itemView` has a divider: set by `setDivider` / `appendDivider`, not removed, or `showsDividers`
     *      (false for an item not in the stack). Whether it is on screen also depends on the neighbours being shown.
     * [CN] `itemView` 之后的间隙是否有分隔线：由 `setDivider` / `appendDivider` 设置且未被移除，或 `showsDividers`（不在堆叠中的条目为 false）。
     *      是否显示在屏幕上还取决于相邻条目是否显示。
     */
    fun hasDivider(itemView: CYLAnimatedItemView): Boolean {
        val entry = entries.firstOrNull { it.view === itemView } ?: return false
        return entry.dividerOwn ?: showsDividers
    }

    private val dividers: List<CYLAnimatedItemView> get() = entries.map { it.divider }

    /**
     * [EN] The internal item that draws the divider after `itemView` (an item of this component in its internal divider mode; never in
     *      `itemViews`): visible while the divider shows. Internal, for tests. [CN] 绘制 `itemView` 之后分隔线的内部条目（本组件的条目，处于内部分隔线模式；
     *      永远不在 `itemViews` 中）：分隔线显示时可见。内部使用，供测试。
     */
    internal fun dividerViewAfter(itemView: CYLAnimatedItemView): CYLAnimatedItemView? = entries.firstOrNull { it.view === itemView }?.divider

    /**
     * [EN] Makes the internal item of a divider and hands it the stack's defaults like any other item.
     * [CN] 创建分隔线的内部条目，并像其他条目一样交给它堆叠的默认值。
     */
    private fun makeDivider(): CYLAnimatedItemView = CYLAnimatedItemView(context).apply {
        isDividerMode = true
        visibility = View.GONE
        stackIconColor = this@CYLAnimatedItemStackView.iconColor
        stackSelectedIconColor = this@CYLAnimatedItemStackView.selectedIconColor
        stackAnimationTint = this@CYLAnimatedItemStackView.animationTint
        stackAnimationDarkTint = this@CYLAnimatedItemStackView.animationDarkTint
        stackDividerColor = this@CYLAnimatedItemStackView.dividerColor
        dividerLengthDp = this@CYLAnimatedItemStackView.dividerLengthDp
        dividerAxis = this@CYLAnimatedItemStackView.axis
    }

    /**
     * [EN] The default title color of the items (iOS `itemAppearance.normal.titleColor`); an item's own `titleColor` wins; null for none.
     * [CN] 条目的默认标题颜色（iOS `itemAppearance.normal.titleColor`）；条目自己的 `titleColor` 优先；null 表示没有。
     */
    var titleColor: Int? = null
        set(value) { field = value; entries.forEach { it.view.stackTitleColor = value } }

    /**
     * [EN] Whether the stack handles taps itself (default true): sets the items' click listeners, performs their actions and
     *      `backgroundAction`, takes over touches on items without an action, and sets the items' clickable and accessibility state.
     *      False: the stack touches none of that (no listener, no interception, no accessibility change, the item order for a screen
     *      reader is the view order), so a host that handles taps (a search bar row, a tab bar) keeps full control.
     * [CN] 堆叠是否自己处理点击（默认 true）：设置条目的点击监听、执行其动作与 `backgroundAction`、接管无动作条目上的触摸，并设置条目的可点击与
     *      无障碍状态。false：堆叠不做其中任何一项（不设监听、不拦截、不改无障碍，读屏顺序就是视图顺序），自行处理点击的宿主（搜索栏行、TabBar）完全掌控。
     */
    var dispatchesItemTaps: Boolean = true
        set(value) {
            if (field == value) return
            field = value
            entries.forEach { entry ->
                if (value) {
                    installClickListener(entry.view)
                    updateAccessibility(entry)
                } else {
                    entry.view.setOnClickListener(null)
                    entry.view.isClickable = true
                    entry.view.importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_AUTO
                }
            }
        }

    private fun isShowing(entry: Entry) = entry.view.visibility != View.GONE

    /**
     * [EN] Whether the divider after `entries[index]` is on screen: wanted, its owner showing, and a later item showing.
     * [CN] `entries[index]` 之后的分隔线是否显示：已设置、所属条目显示，且之后还有显示的条目。
     */
    private fun dividerShows(index: Int): Boolean {
        val entry = entries[index]
        return isShowing(entry) && (entry.dividerOwn ?: showsDividers) && entries.drop(index + 1).any { isShowing(it) }
    }

    private fun dividerBeforeDpOf(owner: Entry) = owner.dividerBeforeDp ?: dividerSpacingBeforeDp ?: spacingDp

    private fun dividerAfterDpOf(owner: Entry, next: Entry) =
        owner.dividerAfterDp ?: dividerSpacingAfterDp ?: next.spacingBeforeDp ?: spacingDp

    /**
     * [EN] The space before an item in dp: 0 for the first item showing (an item that is GONE takes no space), the space after the
     *      divider when the item showing before it has a divider, else its own spacing or `spacingDp`.
     * [CN] 条目之前的间距（dp）：第一个显示的条目为 0（GONE 的条目不占空间）；前一个显示的条目带分隔线时为分隔线之后的间距；否则为其自身间距或 `spacingDp`。
     */
    fun spacingBeforeDpOf(itemView: CYLAnimatedItemView): Float {
        val index = entries.indexOfFirst { it.view === itemView }
        if (index < 0) return 0f
        val previous = entries.take(index).indexOfLast { isShowing(it) }
        if (previous < 0) return 0f
        return if (dividerShows(previous)) dividerAfterDpOf(entries[previous], entries[index]) else entries[index].spacingBeforeDp ?: spacingDp
    }

    /**
     * [EN] Shows the dividers that belong, then sets the margin of every item and divider on the stack's axis: a divider has the space
     *      before it, the next item the space after it. `relayout` false: while measuring (the margins are read right after).
     * [CN] 显示应当显示的分隔线，然后按堆叠方向设置每个条目与分隔线的外边距：分隔线带「前」间距，下一个条目带「后」间距。`relayout` 为 false：测量期间调用
     *      （边距随后立即被读取）。
     */
    private fun updateSpacing(relayout: Boolean = true) {
        entries.forEachIndexed { index, entry ->
            val visibility = if (dividerShows(index)) View.VISIBLE else View.GONE
            if (entry.divider.visibility != visibility) entry.divider.visibility = visibility
        }
        entries.forEachIndexed { index, entry ->
            applyMargin(entry.view, dp(spacingBeforeDpOf(entry.view)), relayout)
            applyMargin(entry.divider, if (dividerShows(index)) dp(dividerBeforeDpOf(entry)) else 0, relayout)
        }
    }

    private fun applyMargin(view: View, space: Int, relayout: Boolean) {
        val params = view.layoutParams as? LinearLayout.LayoutParams ?: return
        val horizontal = axis == CYLAnimatedItemAxis.Horizontal
        val start = if (horizontal) space else 0
        val top = if (horizontal) 0 else space
        if (params.marginStart == start && params.topMargin == top) return
        params.topMargin = top
        params.marginStart = start
        // [EN] While measuring, the margins are read right after: `marginStart` reaches `leftMargin` only when the direction is resolved, which
        //      `layoutParams =` does but this path does not, so resolve it here (a stale margin left the old first item's space in the width).
        // [CN] 测量期间边距随后立即被读取：`marginStart` 只有在解析布局方向后才会写入 `leftMargin`；`layoutParams =` 会解析而此路径不会，所以在这里解析
        //      （否则旧的第一个条目的间距会留在宽度里）。
        if (relayout) view.layoutParams = params else params.resolveLayoutDirection(view.layoutDirection)
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        // [EN] An item hidden or shown since the last pass changes who is first. [CN] 自上次测量后隐藏或显示的条目会改变谁是第一个。
        updateSpacing(relayout = false)
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
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
        insert(itemView, entries.size, action, spacingBeforeDp)
    }

    /**
     * [EN] Inserts an item at `index` (clamped to 0..count), like `append` otherwise. An item already in the stack is left where it
     *      is: use `move`. Items may be subclasses of `CYLAnimatedItemView`.
     * [CN] 在 `index`（限制在 0..数量）处插入条目，其余同 `append`。已在堆叠中的条目保持原位：请用 `move`。条目可以是 `CYLAnimatedItemView` 的子类。
     */
    @JvmOverloads
    open fun insert(itemView: CYLAnimatedItemView, index: Int, action: String? = null, spacingBeforeDp: Float? = null) {
        if (entries.any { it.view === itemView }) return
        val at = index.coerceIn(0, entries.size)
        val params = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
        // [EN] Each item is followed by its divider view (GONE unless it shows), so item i sits at child 2 * i.
        // [CN] 每个条目之后跟着它的分隔线视图（不显示时为 GONE），所以第 i 个条目位于子视图 2 * i。
        stackView.addView(itemView, 2 * at, params)
        // [EN] null: the stack's `spacingDp`. [CN] null：使用堆叠的 `spacingDp`。
        val entry = Entry(itemView, null, spacingBeforeDp?.let { maxOf(0f, it) })
        entry.divider = makeDivider()
        stackView.addView(entry.divider, 2 * at + 1, LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT))
        entries.add(at, entry)
        if (itemGlassBackdropSource != null) itemView.itemGlassBackdropSource = itemGlassBackdropSource
        itemView.stackIconColor = iconColor
        itemView.stackSelectedIconColor = selectedIconColor
        itemView.stackTitleColor = titleColor
        itemView.stackAnimationTint = animationTint
        itemView.stackAnimationDarkTint = animationDarkTint
        itemView.stackAnimationRenderingMode = animationRenderingMode
        updateSpacing()
        if (dispatchesItemTaps) installClickListener(itemView)
        setAction(action, itemView)
        // [EN] The item before and after it may have been the first or last. [CN] 前后的条目可能是原来的第一个或最后一个。
        entries.forEach { updateAccessibility(it) }
    }

    /**
     * [EN] Its own action, or for the first item without one the background action (reached by a screen reader: touches
     *      on items without an action go to the background). [CN] 执行自己的动作；没有动作的第一个条目执行背景动作（由读屏触发：
     *      落在无动作条目上的触摸交给背景）。
     */
    private fun installClickListener(itemView: CYLAnimatedItemView) {
        itemView.setOnClickListener { view ->
            val item = view as CYLAnimatedItemView
            val ownAction = if (isItemInteractive(item)) action(item) else null
            val fallbackAction = if (item === firstItemView) backgroundAction else null
            val resolved = ownAction ?: fallbackAction
            if (resolved != null) performAction(resolved)
        }
    }

    /**
     * [EN] Moves an item to `index` (clamped to 0..count-1); its action and spacing go with it. Does nothing for an item not in the stack.
     * [CN] 把条目移到 `index`（限制在 0..数量-1）；其动作与间距随之移动。条目不在堆叠中时什么都不做。
     */
    open fun move(itemView: CYLAnimatedItemView, index: Int) {
        val from = entries.indexOfFirst { it.view === itemView }
        if (from < 0) return
        val to = index.coerceIn(0, entries.size - 1)
        if (from == to) return
        val entry = entries.removeAt(from)
        entries.add(to, entry)
        stackView.removeView(itemView)
        stackView.removeView(entry.divider)
        stackView.addView(itemView, 2 * to)
        stackView.addView(entry.divider, 2 * to + 1)
        updateSpacing()
        entries.forEach { updateAccessibility(it) }
    }

    /**
     * [EN] Makes the stack hold exactly `itemViews`, in that order: the others are removed, new ones appended (no action), the ones
     *      already held keep their action and spacing and are moved into place.
     * [CN] 让堆叠恰好容纳 `itemViews` 并按此顺序：其他条目被移除，新条目被追加（无动作），已有的条目保留动作与间距并移到相应位置。
     */
    open fun setItemViews(itemViews: List<CYLAnimatedItemView>) {
        entries.map { it.view }.filter { held -> itemViews.none { it === held } }.forEach { remove(it) }
        itemViews.forEachIndexed { index, view ->
            if (entries.any { it.view === view }) move(view, index) else insert(view, index)
        }
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
        val removed = entries.removeAt(index)
        itemView.setOnClickListener(null)
        itemView.isClickable = true
        itemView.importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_AUTO
        stackView.removeView(itemView)
        stackView.removeView(removed.divider)
        itemView.stackIconColor = null
        itemView.stackSelectedIconColor = null
        itemView.stackTitleColor = null
        itemView.stackAnimationTint = null
        itemView.stackAnimationDarkTint = null
        itemView.stackAnimationRenderingMode = null
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
        if (!dispatchesItemTaps) return handled
        return backgroundAction?.let { performAction(it) } ?: handled
    }

    // MARK: - Touches 触摸

    /**
     * [EN] Takes the touch away from items without an action (and from the empty space), so it becomes a background tap;
     *      items with an action keep theirs.
     * [CN] 从没有动作的条目（以及空白处）接管触摸，使其成为背景点击；带动作的条目保留自己的触摸。
     */
    override fun onInterceptTouchEvent(event: MotionEvent): Boolean {
        if (!dispatchesItemTaps || event.actionMasked != MotionEvent.ACTION_DOWN) return false
        downX = event.x
        downY = event.y
        return itemWithActionAt(event.x, event.y) == null
    }

    @SuppressLint("ClickableViewAccessibility") // [EN] Taps go through performClick. [CN] 点击通过 performClick 触发。
    override fun onTouchEvent(event: MotionEvent): Boolean {
        if (!dispatchesItemTaps) return super.onTouchEvent(event)
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
        if (!dispatchesItemTaps) return
        // [EN] Clickable decides the role the item reports (button or text). [CN] 是否可点击决定条目报告的角色（按钮或文字）。
        view.isClickable = actsAsButton(entry)
        val reads = actsAsButton(entry) || !view.contentDescription.isNullOrEmpty() || !view.title.isNullOrEmpty()
        view.importantForAccessibility = if (reads) IMPORTANT_FOR_ACCESSIBILITY_YES else IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
    }

    private fun actsAsButton(entry: Entry) = isItemInteractive(entry.view) || (entry.view === firstItemView && backgroundAction != null)

    // MARK: - Background 背景

    /**
     * [EN] The background of the whole stack, the same rules as [CYLAnimatedItemView]: Flat (default) fills it with [itemBackgroundColor];
     *      LiquidGlass draws Liquid Glass behind the items where the device draws it ([CYLAnimatedItemView.isLiquidGlassActive]), flat
     *      elsewhere. Nothing is drawn until one of the `item…` background properties is set.
     * [CN] 整个堆叠的背景，规则与 [CYLAnimatedItemView] 相同：Flat（默认）用 [itemBackgroundColor] 填充；LiquidGlass 在设备绘制液态玻璃处于条目后面
     *      绘制液态玻璃，其他设备为扁平。设置任一 `item…` 背景属性之前不绘制任何背景。
     */
    var itemBackgroundStyle: CYLAnimatedItemBackgroundStyle = CYLAnimatedItemBackgroundStyle.Flat
        set(value) { if (field != value) { field = value; itemBackgroundDidChange() } }

    /** [EN] The fill (flat) or the tint (glass), an ARGB color. [CN] 填充色（扁平）或着色（玻璃），ARGB 颜色。 */
    var itemBackgroundColor: Int? = null
        set(value) { if (field != value) { field = value; itemBackgroundDidChange() } }

    /**
     * [EN] The corner radius in dp: 0 is square, [CYLAnimatedItemCornerRadiusCapsule] a capsule, any other value dp limited to half the
     *      height; null (the default) is a capsule for Liquid Glass and square for flat, as [CYLAnimatedItemView.itemCornerRadius].
     * [CN] 圆角半径（dp）：0 为直角，[CYLAnimatedItemCornerRadiusCapsule] 为胶囊，其他值为 dp 且最大取半高；null（默认）时液态玻璃为胶囊、扁平为直角，
     *      与 [CYLAnimatedItemView.itemCornerRadius] 相同。
     */
    var itemCornerRadius: Float? = null
        set(value) { if (field != value) { field = value; itemBackgroundDidChange() } }

    /**
     * [EN] The space between the stack's outer border and its items on the left and right, in dp, added to [contentMarginDp] horizontally only; null
     *      (the default) is [CYLAnimatedItemLiquidGlassContentInset] for Liquid Glass and 0 for flat, as [CYLAnimatedItemView.itemContentHorizontalInset].
     * [CN] 堆叠外侧边框与条目之间左右的间距（dp），仅在水平方向叠加到 [contentMarginDp] 上；null（默认）时液态玻璃为
     *      [CYLAnimatedItemLiquidGlassContentInset]、扁平为 0，与 [CYLAnimatedItemView.itemContentHorizontalInset] 相同。
     */
    var itemContentHorizontalInset: Float? = null
        set(value) { if (field != value) { field = value; updateMargins() } }

    /** [EN] The inset really applied, in dp. [CN] 实际应用的间距（dp）。 */
    val resolvedItemContentHorizontalInset: Float
        get() = CYLAnimatedItemBackgroundRenderer.resolvedContentInset(itemContentHorizontalInset, itemBackgroundStyle)

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
     * [EN] The view a Liquid Glass background blurs and refracts, as [CYLAnimatedItemView.itemGlassBackdropSource]: null (the default) is the root of the
     *      window's views; a view BEHIND the stack and NOT an ancestor of it (a sibling plate) is sampled; else only the tint and the hairline rim are drawn
     *      (the same fallback as a single glass item, also per hosted item). It reaches the stack's own glass layer and the glass layer of every item the
     *      stack hosts, items added later too; setting it again re-applies it to the existing ones. Not used by the flat style.
     *      Besides the source, the glass samples, automatically, the Liquid Glass items BEHIND it that cover it (see [CYLAnimatedItemView.itemGlassBackdropSource]).
     * [CN] 液态玻璃背景所模糊、折射的视图，同 [CYLAnimatedItemView.itemGlassBackdropSource]：null（默认）为窗口视图的根；位于堆叠后面且不是其祖先的视图
     *      （同级背板）会被采样；否则只绘制着色与细边（与单个玻璃条目相同的回退，每个托管的条目也一样）。它作用于堆叠自己的玻璃层以及它托管的每个条目的玻璃层，
     *      之后加入的条目也一样；再次设置会重新应用到已有条目。扁平样式不使用。除源之外，玻璃还会自动采样位于它后面并覆盖它的液态玻璃条目（见 [CYLAnimatedItemView.itemGlassBackdropSource]）。
     */
    var itemGlassBackdropSource: View? = null
        set(value) {
            if (field === value) return
            field = value
            entries.forEach { it.view.itemGlassBackdropSource = value }
            if (usesItemBackground) itemBackgroundDidChange()
        }

    /** [EN] The background really drawn (Flat where the device draws no glass). [CN] 实际绘制的背景（设备不绘制玻璃时为 Flat）。 */
    val resolvedItemBackgroundStyle: CYLAnimatedItemBackgroundStyle
        get() = itemBackgroundRenderer.resolvedStyle(itemBackgroundStyle)

    /** [EN] The Liquid Glass layer behind the items while it is drawn; null otherwise. [CN] 绘制时位于条目后面的液态玻璃层；否则为 null。 */
    val itemLiquidGlassView: View? get() = itemBackgroundRenderer.glassView

    private val itemBackgroundRenderer = CYLAnimatedItemBackgroundRenderer(this)
    private var usesItemBackground = false

    private fun itemBackgroundDidChange() {
        usesItemBackground = true
        applyItemBackground()
        updateMargins() // the unset content inset follows the resolved style
        invalidate()
    }

    private fun applyItemBackground() {
        if (!usesItemBackground) return
        itemBackgroundRenderer.apply(itemBackgroundStyle, itemBackgroundColor, itemCornerRadius, itemBorderWidth, itemBorderColor, itemGlassTintAlpha, itemGlassBackdropSource)
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        applyItemBackground()
    }

    // MARK: - Layout 布局

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        // [EN] A title set after the item was added changes whether it is decoration. [CN] 条目加入后设置的标题会改变它是否为装饰。
        entries.forEach { updateAccessibility(it) }
        super.onLayout(changed, left, top, right, bottom)
        itemBackgroundRenderer.layoutGlass(right - left, bottom - top)
    }

    private fun updateMargins() {
        val margin = dp(contentMarginDp)
        val side = margin + dp(resolvedItemContentHorizontalInset)
        (stackView.layoutParams as? LayoutParams)?.let {
            it.setMargins(side, margin, side, margin)
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

/**
 * [EN] The share of opacity (0.6, was 0.3) of the divider lines' color when it is derived from an EXPLICIT icon color
 *      (`CYLAnimatedItemStackView.showsDividers`). The same on iOS, HarmonyOS and the mini program.
 * [CN] 分隔线颜色由显式图标颜色推导时的不透明度（0.6，原为 0.3，`CYLAnimatedItemStackView.showsDividers`）。与 iOS、鸿蒙、小程序相同。
 */
const val CYLAnimatedItemDividerAlpha: Float = 0.6f

/**
 * [EN] The default length of a divider line, in dp (20): the line is 1 dp thick and this long, centered in its slot, never the full
 *      height or width (`CYLAnimatedItemStackView.dividerLengthDp`). Pass it by name, never the literal.
 * [CN] 分隔线的默认长度，单位 dp（20）：线粗 1 dp、长度为该值，在其位置内居中，而不是整个高度或宽度（`CYLAnimatedItemStackView.dividerLengthDp`）。请用名称，不要写字面量。
 */
const val CYLAnimatedItemDividerLength: Float = 20f
