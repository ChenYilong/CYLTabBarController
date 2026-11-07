// [EN] The method names are the iOS names on purpose (`cyl_…`, `tabBarController_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`、`tabBarController_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.content.Context
import android.graphics.Rect
import android.graphics.drawable.Drawable
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.annotation.ColorInt
import androidx.fragment.app.Fragment

/**
 * [EN] `CYLPlusButtonSubclassing`: what an app's plus button provides. On iOS these are class methods of a
 *      `CYLPlusButton` subclass; on Android the subclass implements this interface (usually in a companion `object`) and
 *      registers it with `CYLPlusButton.registerPlusButton(provider)`. Every method but `plusButton()` has the iOS
 *      default. `NOT_IMPLEMENTED` (NaN) from the position methods means "not implemented": the tab bar then presets the
 *      position as iOS does (centered, or raised so that a taller button's bottom meets the bar's).
 * [CN] `CYLPlusButtonSubclassing`：App 的 PlusButton 提供的内容。iOS 上为 `CYLPlusButton` 子类的类方法；Android 上由子类实现本接口（通常是
 *      伴生 `object`），并通过 `CYLPlusButton.registerPlusButton(provider)` 注册。除 `plusButton()` 外每个方法都有 iOS 的默认值。位置方法返回
 *      `NOT_IMPLEMENTED`（NaN）表示“未实现”：TabBar 按 iOS 的方式预设位置（居中，或更高的按钮底边与 TabBar 底边对齐）。
 */
interface CYLPlusButtonSubclassing {
    /** [EN] `+plusButton` (required): creates the button. [CN] 创建按钮（必须实现）。 */
    fun plusButton(context: Context): CYLPlusButton

    /** [EN] `+indexOfPlusButtonInTabBar`: the index among the tabs; `CYLPlusButton.INDEX_NOT_SET` means the middle (iOS requires it with an odd tab count or a child page; Android centers and warns). [CN] 在 Tab 中的下标；未设置时居中（iOS 在 Tab 数为奇数或有子页面时要求实现；Android 居中并警告）。 */
    fun indexOfPlusButtonInTabBar(): Int = CYLPlusButton.INDEX_NOT_SET

    /** [EN] `+multiplierOfTabBarHeight:`: the center Y as a multiple of the tab bar height (0.5: centered). [CN] 中心 Y 相对 TabBar 高度的倍数（0.5 居中）。 */
    fun multiplierOfTabBarHeight(tabBarHeight: Float): Float = CYLPlusButton.NOT_IMPLEMENTED

    /** [EN] `+constantOfPlusButtonCenterYOffsetForTabBarHeight:`: a dp offset added to the center Y (> 0 down). [CN] 中心 Y 的额外偏移（dp，大于 0 向下）。 */
    fun constantOfPlusButtonCenterYOffsetForTabBarHeight(tabBarHeight: Float): Float = CYLPlusButton.NOT_IMPLEMENTED

    /** [EN] `+plusChildViewController`: the page selected by the button, or null (the button only runs its own action). [CN] 点击按钮选中的页面；null 表示只执行按钮自己的动作。 */
    fun plusChildViewController(): Fragment? = null

    /** [EN] `+shouldSelectPlusChildViewController`. [CN] 点击是否选中子页面。 */
    fun shouldSelectPlusChildViewController(): Boolean = plusChildViewController() != null

    /** [EN] `+tabBarContext`: must match `CYLTabBarController.context`. [CN] 需与 `CYLTabBarController.context` 一致。 */
    fun tabBarContext(): String = CYLPlusButton.DEFAULT_TAB_BAR_CONTEXT

    /** [EN] `+alignsTitleWithTabBarItemTitles`: the plus title on the tab titles' line, with their font and colors. [CN] PlusButton 标题与 Tab 标题同一中心线、相同字体与颜色。 */
    fun alignsTitleWithTabBarItemTitles(): Boolean = false

    /** [EN] `+tabBarItemIdentifier` (#408): the identifier of the plus button; null: the class name. [CN] PlusButton 的标识；null 为类名。 */
    fun tabBarItemIdentifier(): String? = null

    /** [EN] `+contentImage` / `+selectedContentImage` / `+selectedContentView`: the normal and selected content. [CN] 常态与选中态的内容。 */
    fun contentImage(): Drawable? = null
    fun selectedContentImage(): Drawable? = null
    fun selectedContentView(context: Context): View? = null

    /** [EN] `+matchedTabBarContext:`: whether this button serves `context`. [CN] 该按钮是否服务于 `context`。 */
    fun matchedTabBarContext(context: String?): Boolean = (context ?: CYLPlusButton.DEFAULT_TAB_BAR_CONTEXT) == tabBarContext()
}

/**
 * [EN] `CYLPlusButton`: the big center button of a tab bar: an image (`setImageDrawable`) with an optional title under
 *      it (`cyl_plusButtonWithImage(...)`, `cyl_updateTitle(...)`), a touchable area larger than its bounds (#91), a
 *      badge like any view, and a selected state (its own page, `selectedContentImage` / `selectedContentView`).
 *      Subclass it, implement `CYLPlusButtonSubclassing` and register: `CYLPlusButton.registerPlusButton(MyPlusButton.Provider)`.
 * [CN] `CYLPlusButton`：TabBar 中间的大按钮：图片（`setImageDrawable`）加可选的标题（`cyl_plusButtonWithImage(...)`、`cyl_updateTitle(...)`）、
 *      大于边界的可点击区域（#91）、像任何视图一样的角标，以及选中态（自己的页面、`selectedContentImage` / `selectedContentView`）。
 *      子类化并实现 `CYLPlusButtonSubclassing`，然后注册：`CYLPlusButton.registerPlusButton(MyPlusButton.Provider)`。
 */
open class CYLPlusButton(context: Context) : FrameLayout(context) {

    /** [EN] The image (`imageView`) and the title (`titleLabel`), like `UIButton`. [CN] 图片与标题，与 `UIButton` 相同。 */
    val imageView: ImageView = ImageView(context).apply { scaleType = ImageView.ScaleType.CENTER_INSIDE }
    val titleLabel: TextView = TextView(context).apply { gravity = Gravity.CENTER; textSize = 10f; maxLines = 1; visibility = View.GONE }

    /** [EN] `touchableAreaOutsets`: extra touchable dp on each side (#91). [CN] 四边额外可点击的 dp（#91）。 */
    var touchableAreaOutsets: CYLEdgeInsets = CYLEdgeInsets.zero
        set(value) { field = value; (parent as? View)?.invalidate() }
    /** [EN] `touchableAreaScale`: the touchable area as a multiple of the bounds. [CN] 可点击区域相对边界的倍数。 */
    var touchableAreaScale: Float = 1f
        set(value) { field = value; (parent as? View)?.invalidate() }
    /** [EN] `showsTouchableArea`: draws the touchable area (debugging). [CN] 绘制可点击区域（调试）。 */
    var showsTouchableArea: Boolean = false
        set(value) { field = value; (parent as? View)?.invalidate() }
    @ColorInt var touchableAreaColor: Int = 0x33FF0000
    /** [EN] `cyl_appliesCenterYOffsetWithoutTitle`: the center Y offset also applies to a button without a title. [CN] 没有标题的按钮也应用中心 Y 偏移。 */
    var cyl_appliesCenterYOffsetWithoutTitle: Boolean = false
    /** [EN] The title under the button (`cyl_title`); null for none. [CN] 按钮下方的标题；null 表示没有。 */
    var cyl_title: String? = null
        private set
    var cyl_selectedTitle: String? = null
        private set
    @ColorInt var cyl_selectedTitleColor: Int? = null
        private set
    /** [EN] `cyl_tabBarItemIdentifier` (#408): the provider's, else the class name. [CN] 标识（#408）：提供者给出的，否则为类名。 */
    var cyl_tabBarItemIdentifier: String = javaClass.name
    /** [EN] `cyl_plusViewControllerEverAdded`: the child page was added to a tab bar controller. [CN] 子页面已加入过 TabBarController。 */
    var cyl_plusViewControllerEverAdded: Boolean = false
        internal set
    internal var provider: CYLPlusButtonSubclassing? = null
        set(value) {
            field = value
            value?.tabBarItemIdentifier()?.let { cyl_tabBarItemIdentifier = it }
            value?.contentImage()?.let { if (normalImage == null) setImageDrawable(it) }
            selectedImage = value?.selectedContentImage() ?: selectedImage
        }
    internal var tabLabelHidden = false
    private var normalImage: Drawable? = null
    private var selectedImage: Drawable? = null
    private var selectedContent: View? = null

    init {
        addView(imageView, LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT, Gravity.CENTER))
        addView(titleLabel, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT, Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL))
        isClickable = true
        isFocusable = true
        contentDescription = "Menu"
    }

    /** [EN] `setImage:forState:UIControlStateNormal`. [CN] 常态图片。 */
    open fun setImageDrawable(drawable: Drawable?) {
        normalImage = drawable
        if (!isSelected || selectedImage == null) imageView.setImageDrawable(drawable)
        requestLayout()
    }

    /** [EN] `setImage:forState:UIControlStateSelected`. [CN] 选中态图片。 */
    fun setSelectedImageDrawable(drawable: Drawable?) {
        selectedImage = drawable
        if (isSelected && drawable != null) imageView.setImageDrawable(drawable)
    }

    /** [EN] `setImage:forState:` by state. [CN] 按状态设置图片。 */
    fun setImageForState(drawable: Drawable?, selected: Boolean) = if (selected) setSelectedImageDrawable(drawable) else setImageDrawable(drawable)

    val currentImage: Drawable? get() = imageView.drawable
    val currentTitle: String? get() = if (isSelected) cyl_selectedTitle ?: cyl_title else cyl_title

    /** [EN] `setTitle:forState:` for the normal state (and the selected one when `selectedTitle` is null). [CN] 设置标题。 */
    fun setTitle(title: String?, selectedTitle: String? = null, @ColorInt selectedTitleColor: Int? = null) {
        cyl_title = title
        cyl_selectedTitle = selectedTitle
        cyl_selectedTitleColor = selectedTitleColor
        applyTitle()
    }

    private fun applyTitle() {
        titleLabel.text = currentTitle ?: ""
        titleLabel.visibility = if (cyl_showsTitleInTabBarItem()) View.VISIBLE else View.GONE
        if (isSelected && cyl_selectedTitleColor != null) titleLabel.setTextColor(cyl_selectedTitleColor!!)
        requestLayout()
    }

    override fun setSelected(selected: Boolean) {
        super.setSelected(selected)
        imageView.setImageDrawable(if (selected && selectedImage != null) selectedImage else normalImage)
        val content = selectedContent ?: provider?.selectedContentView(context)?.also { selectedContent = it; addView(it, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)) }
        content?.visibility = if (selected) View.VISIBLE else View.GONE
        imageView.visibility = if (selected && content != null) View.INVISIBLE else View.VISIBLE
        applyTitle()
    }

    /** [EN] `-touchableRect`: the bounds grown by the scale and the outsets, in the parent's coordinates. [CN] 按倍数与 outsets 放大后的可点击矩形（父视图坐标）。 */
    open fun touchableRect(): Rect {
        val density = resources.displayMetrics.density
        val rect = Rect(left, top, right, bottom)
        val extraW = ((width * touchableAreaScale - width) / 2).toInt()
        val extraH = ((height * touchableAreaScale - height) / 2).toInt()
        rect.inset(-extraW, -extraH)
        rect.left -= (touchableAreaOutsets.left * density).toInt()
        rect.top -= (touchableAreaOutsets.top * density).toInt()
        rect.right += (touchableAreaOutsets.right * density).toInt()
        rect.bottom += (touchableAreaOutsets.bottom * density).toInt()
        return rect
    }

    /** [EN] `-touchableRectInView:`: the touchable rect in `view`'s coordinates. [CN] `view` 坐标系中的可点击矩形。 */
    fun touchableRectInView(view: View): Rect {
        val rect = touchableRect()
        val parentView = parent as? View ?: return rect
        val mine = IntArray(2).also { parentView.getLocationInWindow(it) }
        val theirs = IntArray(2).also { view.getLocationInWindow(it) }
        rect.offset(mine[0] - theirs[0], mine[1] - theirs[1])
        return rect
    }

    /** [EN] `-isLayoutCentered`: the button is centered on its slot (its frame was not moved by the app). [CN] 按钮在其 slot 上居中（App 未移动其 frame）。 */
    open fun isLayoutCentered(): Boolean = translationX == 0f

    /** [EN] `-hitTestInteractiveSubview:withEvent:`: the touchable rect decides, in the parent's coordinates. [CN] 由可点击矩形决定（父视图坐标）。 */
    open fun hitTestInteractiveSubview(event: MotionEvent): Boolean = touchableRect().contains((event.x + left).toInt(), (event.y + top).toInt())

    /** [EN] `-setTabLabelHidden:`. [CN] 隐藏 / 显示标题。 */
    fun setTabLabelHidden(hidden: Boolean) {
        tabLabelHidden = hidden
        applyTitle()
    }

    /** [EN] `-cyl_showsTitleInTabBarItem`. [CN] 标题是否显示。 */
    fun cyl_showsTitleInTabBarItem(): Boolean = !cyl_title.isNullOrEmpty() && !tabLabelHidden

    /** [EN] `-cyl_updateTitle:image:selectedImage:` (#601, #757): in place; the tab bar places the button again. [CN] 原地更新（#601、#757）；TabBar 重新放置按钮。 */
    fun cyl_updateTitle(title: String?, image: Drawable?, selectedImage: Drawable?) {
        if (title != null || image == null) setTitle(title, cyl_selectedTitle, cyl_selectedTitleColor)
        if (image != null) setImageDrawable(image)
        if (selectedImage != null) setSelectedImageDrawable(selectedImage)
        (parent as? CYLTabBar)?.requestLayout()
    }

    /** [EN] `-cyl_setNeedsTitleAlignment`: the tab bar aligns the title again (`alignsTitleWithTabBarItemTitles`). [CN] TabBar 重新对齐标题。 */
    fun cyl_setNeedsTitleAlignment() {
        (parent as? CYLTabBar)?.requestLayout()
    }

    /** [EN] `-cyl_alignsTitleWithTabBarItemTitles`. [CN] 标题是否与 Tab 标题对齐。 */
    fun cyl_alignsTitleWithTabBarItemTitles(): Boolean = provider?.alignsTitleWithTabBarItemTitles() ?: false

    /** [EN] `-plusChildViewControllerButtonClicked:`: selects the child page, when there is one, and tells the delegate. [CN] 选中子页面（如有）并通知代理。 */
    open fun plusChildViewControllerButtonClicked() {
        (parent as? CYLTabBar)?.tabBarController()?.cyl_plusButtonTapped(this)
    }

    /** [EN] `-multiplierOfTabBarHeight:` / `-constantOfPlusButtonCenterYOffsetForTabBarHeight:` on the instance: the provider's, or the preset. [CN] 实例上的位置方法：提供者的值，否则预设。 */
    fun multiplierOfTabBarHeight(tabBarHeight: Float): Float {
        val provided = provider?.multiplierOfTabBarHeight(tabBarHeight) ?: NOT_IMPLEMENTED
        if (!provided.isNaN()) return provided
        // [EN] Preset: centered; a button taller than the bar is raised so that its bottom meets the bar's. [CN] 预设：居中；高于 TabBar 的按钮底边与 TabBar 底边对齐。
        val density = resources.displayMetrics.density
        val heightDp = (if (measuredHeight > 0) measuredHeight else height) / density
        return if (heightDp > tabBarHeight && tabBarHeight > 0) (tabBarHeight - heightDp / 2) / tabBarHeight else 0.5f
    }

    fun constantOfPlusButtonCenterYOffsetForTabBarHeight(tabBarHeight: Float): Float {
        val provided = provider?.constantOfPlusButtonCenterYOffsetForTabBarHeight(tabBarHeight) ?: NOT_IMPLEMENTED
        return if (provided.isNaN()) 0f else provided
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        val density = resources.displayMetrics.density
        var width = measuredWidth
        var height = measuredHeight
        if (width < minimumWidth) width = minimumWidth
        if (height < minimumHeight) height = minimumHeight
        if (cyl_showsTitleInTabBarItem()) {
            titleLabel.measure(MeasureSpec.UNSPECIFIED, MeasureSpec.UNSPECIFIED)
            width = maxOf(width, titleLabel.measuredWidth)
            if (imageView.drawable != null) height = maxOf(height, imageView.drawable.intrinsicHeight + titleLabel.measuredHeight + (2 * density).toInt())
        }
        setMeasuredDimension(width, height)
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        val titleHeight = if (cyl_showsTitleInTabBarItem()) titleLabel.measuredHeight else 0
        val imageHeight = imageView.drawable?.intrinsicHeight?.coerceAtMost(height - titleHeight) ?: (height - titleHeight)
        val imageWidth = imageView.drawable?.intrinsicWidth?.coerceAtMost(width) ?: width
        val imageTop = (height - titleHeight - imageHeight) / 2
        imageView.layout((width - imageWidth) / 2, imageTop, (width + imageWidth) / 2, imageTop + imageHeight)
        titleLabel.layout(0, height - titleHeight, width, height)
        selectedContent?.layout(0, 0, width, height)
    }

    companion object {
        const val INDEX_NOT_SET = -1
        /** [EN] "Not implemented" for the position methods. [CN] 位置方法的“未实现”。 */
        const val NOT_IMPLEMENTED = Float.NaN
        const val DEFAULT_TAB_BAR_CONTEXT = "CYLTabBarController"
        /** [EN] `CYLExternPlusButton`: the plus button of the default context. [CN] 默认 context 的 PlusButton。 */
        @JvmStatic val CYLExternPlusButton: CYLPlusButton? get() = plusButtonForTabBarContext(DEFAULT_TAB_BAR_CONTEXT)
        @JvmStatic val CYLPlusChildViewController: Fragment? get() = plusChildViewControllerForTabBarContext(DEFAULT_TAB_BAR_CONTEXT)

        private val providers = LinkedHashMap<String, CYLPlusButtonSubclassing>()
        private val buttons = LinkedHashMap<String, CYLPlusButton>()

        /** [EN] `+registerPlusButton`: registers the provider under its `tabBarContext()`; call it before the tab bar controller is created. [CN] 按 `tabBarContext()` 注册；在创建 TabBarController 之前调用。 */
        @JvmStatic
        fun registerPlusButton(provider: CYLPlusButtonSubclassing) {
            synchronized(providers) {
                providers[provider.tabBarContext()] = provider
                buttons.remove(provider.tabBarContext())
            }
            CYLTabBarController.cyl_tabBarControllerForContext(provider.tabBarContext())?.tabBar?.cyl_reloadTabButtons()
        }

        /** [EN] `+registerSubclass` (deprecated): the same as `registerPlusButton`. [CN] 已弃用，同 `registerPlusButton`。 */
        @Deprecated("Use registerPlusButton", ReplaceWith("registerPlusButton(provider)"))
        @JvmStatic
        fun registerSubclass(provider: CYLPlusButtonSubclassing) = registerPlusButton(provider)

        @JvmStatic
        fun removePlusButton() = removePlusButtonForTabBarContext(DEFAULT_TAB_BAR_CONTEXT)

        /** [EN] `+removePlusButtonForTabBarContext:`: the tab bars of that context drop the button. [CN] 该 context 的 TabBar 移除按钮。 */
        @JvmStatic
        fun removePlusButtonForTabBarContext(context: String?) {
            val key = context ?: DEFAULT_TAB_BAR_CONTEXT
            synchronized(providers) {
                providers.remove(key)
                buttons.remove(key)
            }
            CYLTabBarController.cyl_tabBarControllerForContext(key)?.tabBar?.cyl_reloadTabButtons()
        }

        /** [EN] `+plusButtonForTabBarContext:`: the button created for a context, or null. [CN] 某 context 已创建的按钮，没有则为 null。 */
        @JvmStatic
        fun plusButtonForTabBarContext(context: String?): CYLPlusButton? = synchronized(providers) { buttons[context ?: DEFAULT_TAB_BAR_CONTEXT] }

        /** [EN] Creates (or returns) the plus button of `context` for a tab bar. [CN] 为 TabBar 创建（或返回）该 context 的 PlusButton。 */
        @JvmStatic
        fun plusButtonForTabBarContext(context: String?, viewContext: Context): CYLPlusButton? {
            val key = context ?: DEFAULT_TAB_BAR_CONTEXT
            synchronized(providers) {
                val provider = providers[key] ?: return null
                return buttons.getOrPut(key) { provider.plusButton(viewContext).also { it.provider = provider } }
            }
        }

        @JvmStatic
        fun plusChildViewControllerForTabBarContext(context: String?): Fragment? =
            synchronized(providers) { providers[context ?: DEFAULT_TAB_BAR_CONTEXT]?.plusChildViewController() }

        @JvmStatic
        fun hasPlusButtonForTabBarContext(context: String?): Boolean = synchronized(providers) { providers.containsKey(context ?: DEFAULT_TAB_BAR_CONTEXT) }

        @JvmStatic
        fun hasPlusChildViewControllerForTabBarContext(context: String?): Boolean = plusChildViewControllerForTabBarContext(context) != null

        /** [EN] `+plusButtonWidthForTabBarContext:`: the button's width in dp, or 0. [CN] 按钮宽度（dp），没有则为 0。 */
        @JvmStatic
        fun plusButtonWidthForTabBarContext(context: String?): Float {
            val button = plusButtonForTabBarContext(context) ?: return 0f
            val width = if (button.width > 0) button.width else button.measuredWidth
            return width / button.resources.displayMetrics.density
        }

        /** [EN] `+indexForTabbarItemsCount:`: the slot index: the registered index, else the middle (a warning with an odd count, where iOS throws). [CN] slot 下标：注册的下标，否则居中（Tab 数为奇数时警告；iOS 会抛出异常）。 */
        @JvmStatic
        fun indexForTabbarItemsCount(count: Int, context: String? = null): Int {
            val provider = synchronized(providers) { providers[context ?: DEFAULT_TAB_BAR_CONTEXT] }
            val index = provider?.indexOfPlusButtonInTabBar() ?: INDEX_NOT_SET
            if (index == INDEX_NOT_SET && provider != null && (count % 2 == 1 || provider.plusChildViewController() != null)) {
                android.util.Log.w("CYLPlusButton", "indexOfPlusButtonInTabBar() is required with an odd tab count or a plus child view controller; the middle is used.")
            }
            return if (index == INDEX_NOT_SET || index < 0 || index > count) count / 2 else index
        }

        @JvmStatic
        fun providerForTabBarContext(context: String?): CYLPlusButtonSubclassing? = synchronized(providers) { providers[context ?: DEFAULT_TAB_BAR_CONTEXT] }

        @JvmStatic
        fun matchedTabBarContext(context: String?): Boolean = hasPlusButtonForTabBarContext(context)

        @JvmStatic
        fun isPlusButtonView(view: View?): Boolean = view is CYLPlusButton

        /** [EN] `+cyl_plusButtonWithImage:title:selectedTitle:selectedTitleColor:`: a ready-made plus button with a title under its image. [CN] 现成的 PlusButton，图片下方带标题。 */
        @JvmStatic
        fun cyl_plusButtonWithImage(context: Context, image: Drawable?, title: String?, selectedTitle: String?, @ColorInt selectedTitleColor: Int?): CYLPlusButton {
            return CYLPlusButton(context).apply {
                setImageDrawable(image)
                setTitle(title, selectedTitle, selectedTitleColor)
            }
        }

        /** [EN] `+tabBarContextForOwner:` / `+plusButtonForOwner:` / `+plusChildViewControllerForOwner:` / `+plusButtonWidthForOwner:`. [CN] 按所属 TabBarController 查询。 */
        @JvmStatic fun tabBarContextForOwner(owner: CYLTabBarController): String = owner.context ?: DEFAULT_TAB_BAR_CONTEXT
        @JvmStatic fun plusButtonForOwner(owner: CYLTabBarController): CYLPlusButton? = owner.tabBar.plusButton
        @JvmStatic fun plusChildViewControllerForOwner(owner: CYLTabBarController): Fragment? = plusChildViewControllerForTabBarContext(tabBarContextForOwner(owner))
        @JvmStatic fun plusButtonWidthForOwner(owner: CYLTabBarController): Float = plusButtonWidthForTabBarContext(tabBarContextForOwner(owner))
    }
}
