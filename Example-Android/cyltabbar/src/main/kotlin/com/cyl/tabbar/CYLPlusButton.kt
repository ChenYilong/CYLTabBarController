package com.cyl.tabbar

import android.content.Context
import android.graphics.Rect
import android.graphics.drawable.Drawable
import android.view.MotionEvent
import android.view.View
import androidx.annotation.ColorInt
import androidx.appcompat.widget.AppCompatImageButton
import androidx.fragment.app.Fragment

/**
 * [EN] `CYLPlusButtonSubclassing`: what an app's plus button provides. On iOS these are class methods of a
 *      `CYLPlusButton` subclass; on Android the subclass implements this interface and registers itself with
 *      `CYLPlusButton.registerPlusButton(provider)`. Every method but `plusButton()` has the iOS default.
 * [CN] `CYLPlusButtonSubclassing`：App 的 PlusButton 提供的内容。iOS 上为 `CYLPlusButton` 子类的类方法；Android 上由子类实现本接口并通过
 *      `CYLPlusButton.registerPlusButton(provider)` 注册。除 `plusButton()` 外每个方法都有 iOS 的默认值。
 */
interface CYLPlusButtonSubclassing {
    /** [EN] `+plusButton`: creates the button. [CN] 创建按钮。 */
    fun plusButton(context: Context): CYLPlusButton

    /** [EN] `+indexOfPlusButtonInTabBar`: the index among the tabs; `CYLPlusButton.indexNotSet` means the middle. [CN] 在 Tab 中的下标；未设置时居中。 */
    fun indexOfPlusButtonInTabBar(): Int = CYLPlusButton.INDEX_NOT_SET

    /** [EN] `+multiplierOfTabBarHeight:`: the button's center Y as a multiple of the tab bar height (0.5: centered). [CN] 按钮中心 Y 相对 TabBar 高度的倍数。 */
    fun multiplierOfTabBarHeight(tabBarHeight: Float): Float = 0.5f

    /** [EN] `+constantOfPlusButtonCenterYOffsetForTabBarHeight:`: a dp offset added to the center Y. [CN] 中心 Y 的额外偏移（dp）。 */
    fun constantOfPlusButtonCenterYOffsetForTabBarHeight(tabBarHeight: Float): Float = 0f

    /** [EN] `+plusChildViewController`: the page selected by the button, or null (the button only runs its own action). [CN] 点击按钮选中的页面；null 表示只执行按钮自己的动作。 */
    fun plusChildViewController(): Fragment? = null

    /** [EN] `+shouldSelectPlusChildViewController`: whether tapping the button selects the child. [CN] 点击是否选中子页面。 */
    fun shouldSelectPlusChildViewController(): Boolean = plusChildViewController() != null

    /** [EN] `+tabBarContext`: the tab bar controllers this button belongs to. [CN] 该按钮所属的 TabBarController 的 context。 */
    fun tabBarContext(): String = CYLPlusButton.DEFAULT_TAB_BAR_CONTEXT

    /** [EN] `+alignsTitleWithTabBarItemTitles`. [CN] 标题是否与 Tab 标题对齐。 */
    fun alignsTitleWithTabBarItemTitles(): Boolean = false

    /** [EN] `+tabBarItemIdentifier`: the identifier of the plus child's tab. [CN] PlusButton 子页面 Tab 的标识。 */
    fun tabBarItemIdentifier(): String? = null

    fun contentImage(): Drawable? = null
    fun selectedContentImage(): Drawable? = null
    fun selectedContentView(): View? = null
    fun matchedTabBarContext(context: String?): Boolean = context == null || context == tabBarContext()
}

/**
 * [EN] `CYLPlusButton`: the big center button of a tab bar. Subclass it, implement `CYLPlusButtonSubclassing` and
 *      register: `CYLPlusButton.registerPlusButton(MyPlusButton.Provider)`. One plus button per tab bar context.
 * [CN] `CYLPlusButton`：TabBar 中间的大按钮。子类化并实现 `CYLPlusButtonSubclassing`，然后注册：
 *      `CYLPlusButton.registerPlusButton(MyPlusButton.Provider)`。每个 TabBar context 一个 PlusButton。
 */
open class CYLPlusButton(context: Context) : AppCompatImageButton(context) {

    /** [EN] `touchableAreaOutsets`: extra touchable dp on each side (#91). [CN] 四边额外可点击的 dp（#91）。 */
    var touchableAreaOutsets: CYLEdgeInsets = CYLEdgeInsets.zero
    /** [EN] `touchableAreaScale`: the touchable area as a multiple of the bounds. [CN] 可点击区域相对边界的倍数。 */
    var touchableAreaScale: Float = 1f
    var showsTouchableArea: Boolean = false
    @ColorInt var touchableAreaColor: Int = 0x33FF0000
    var cyl_appliesCenterYOffsetWithoutTitle: Boolean = false
    /** [EN] The title under the button (`cyl_title`); null for none. [CN] 按钮下方的标题；null 表示没有。 */
    var cyl_title: String? = null
        private set
    var cyl_selectedTitle: String? = null
        private set
    var cyl_selectedTitleColor: Int? = null
        private set
    internal var provider: CYLPlusButtonSubclassing? = null
    internal var tabLabelHidden = false

    init {
        background = null
        scaleType = ScaleType.CENTER_INSIDE
        contentDescription = "Menu"
    }

    /** [EN] `-touchableRect`: the bounds grown by the outsets and the scale. [CN] 按 outsets 与倍数放大后的可点击矩形。 */
    open fun touchableRect(): Rect {
        val density = resources.displayMetrics.density
        val rect = Rect(0, 0, width, height)
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
        val mine = IntArray(2).also { getLocationInWindow(it) }
        val theirs = IntArray(2).also { view.getLocationInWindow(it) }
        rect.offset(mine[0] - theirs[0], mine[1] - theirs[1])
        return rect
    }

    /** [EN] `-isLayoutCentered`: whether the button is centered on its tab. [CN] 按钮是否在其 Tab 上居中。 */
    open fun isLayoutCentered(): Boolean = true

    /** [EN] `-hitTestInteractiveSubview:withEvent:`: the touchable rect decides. [CN] 由可点击矩形决定是否响应。 */
    open fun hitTestInteractiveSubview(event: MotionEvent): Boolean = touchableRect().contains(event.x.toInt(), event.y.toInt())

    /** [EN] `-setTabLabelHidden:`. [CN] 隐藏 / 显示标题。 */
    fun setTabLabelHidden(hidden: Boolean) {
        tabLabelHidden = hidden
        (parent as? CYLTabBar)?.requestLayout()
    }

    /** [EN] `-cyl_showsTitleInTabBarItem`. [CN] 标题是否显示在 Tab 中。 */
    fun cyl_showsTitleInTabBarItem(): Boolean = cyl_title != null && !tabLabelHidden

    /** [EN] `-cyl_updateTitle:image:selectedImage:` (#601): updates the button in place. [CN] 原地更新标题与图片（#601）。 */
    fun cyl_updateTitle(title: String?, image: Drawable?, selectedImage: Drawable?) {
        cyl_title = title
        if (image != null) setImageDrawable(image)
        selectedImage?.let { selected = it }
        (parent as? CYLTabBar)?.requestLayout()
    }

    fun cyl_setNeedsTitleAlignment() {
        (parent as? CYLTabBar)?.requestLayout()
    }

    /** [EN] `-plusChildViewControllerButtonClicked:`: selects the plus child, when there is one. [CN] 选中 PlusButton 的子页面（如有）。 */
    open fun plusChildViewControllerButtonClicked() {
        val tabBar = parent as? CYLTabBar ?: return
        tabBar.tabBarController()?.cyl_plusButtonTapped(this)
    }

    /** [EN] `-multiplierOfTabBarHeight:` / `-constantOfPlusButtonCenterYOffsetForTabBarHeight:` on the instance. [CN] 实例上的位置方法。 */
    fun multiplierOfTabBarHeight(tabBarHeight: Float): Float = provider?.multiplierOfTabBarHeight(tabBarHeight) ?: 0.5f
    fun constantOfPlusButtonCenterYOffsetForTabBarHeight(tabBarHeight: Float): Float =
        provider?.constantOfPlusButtonCenterYOffsetForTabBarHeight(tabBarHeight) ?: 0f

    private var selected: Drawable? = null

    override fun setSelected(selected: Boolean) {
        super.setSelected(selected)
        if (selected && this.selected != null) setImageDrawable(this.selected)
    }

    companion object {
        const val INDEX_NOT_SET = -1
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
        }

        /** [EN] `+registerSubclass` (deprecated): the same as `registerPlusButton`. [CN] 已弃用，同 `registerPlusButton`。 */
        @Deprecated("Use registerPlusButton", ReplaceWith("registerPlusButton(provider)"))
        @JvmStatic
        fun registerSubclass(provider: CYLPlusButtonSubclassing) = registerPlusButton(provider)

        @JvmStatic
        fun removePlusButton() = removePlusButtonForTabBarContext(DEFAULT_TAB_BAR_CONTEXT)

        @JvmStatic
        fun removePlusButtonForTabBarContext(context: String?) {
            synchronized(providers) {
                providers.remove(context ?: DEFAULT_TAB_BAR_CONTEXT)
                buttons.remove(context ?: DEFAULT_TAB_BAR_CONTEXT)
            }
        }

        /** [EN] `+plusButtonForTabBarContext:`: the registered button of a context (created once per context, with a view context on first use). [CN] 某 context 已注册的按钮。 */
        @JvmStatic
        fun plusButtonForTabBarContext(context: String?): CYLPlusButton? = synchronized(providers) { buttons[context ?: DEFAULT_TAB_BAR_CONTEXT] }

        /** [EN] Creates (or returns) the plus button of `tabBarContext` for a tab bar. [CN] 为 TabBar 创建（或返回）该 context 的 PlusButton。 */
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
            return button.width / button.resources.displayMetrics.density
        }

        /** [EN] `+indexForTabbarItemsCount:`: the slot index: the registered index, else the middle (an odd count puts it in the middle). [CN] slot 下标：注册的下标，否则居中。 */
        @JvmStatic
        fun indexForTabbarItemsCount(count: Int, context: String? = null): Int {
            val provider = synchronized(providers) { providers[context ?: DEFAULT_TAB_BAR_CONTEXT] }
            val index = provider?.indexOfPlusButtonInTabBar() ?: INDEX_NOT_SET
            return if (index == INDEX_NOT_SET || index < 0 || index > count) count / 2 else index
        }

        @JvmStatic
        fun providerForTabBarContext(context: String?): CYLPlusButtonSubclassing? = synchronized(providers) { providers[context ?: DEFAULT_TAB_BAR_CONTEXT] }

        @JvmStatic
        fun isPlusButtonView(view: View?): Boolean = view is CYLPlusButton

        /** [EN] `+cyl_plusButtonWithImage:title:selectedTitle:selectedTitleColor:`: a ready-made plus button. [CN] 现成的 PlusButton。 */
        @JvmStatic
        fun cyl_plusButtonWithImage(context: Context, image: Drawable?, title: String?, selectedTitle: String?, @ColorInt selectedTitleColor: Int?): CYLPlusButton {
            return CYLPlusButton(context).apply {
                setImageDrawable(image)
                cyl_title = title
                cyl_selectedTitle = selectedTitle
                cyl_selectedTitleColor = selectedTitleColor
            }
        }

        /** [EN] `+tabBarContextForOwner:` / `+plusButtonForOwner:` / `+plusChildViewControllerForOwner:` / `+plusButtonWidthForOwner:`. [CN] 按所属 TabBarController 查询。 */
        @JvmStatic fun tabBarContextForOwner(owner: CYLTabBarController): String = owner.context ?: DEFAULT_TAB_BAR_CONTEXT
        @JvmStatic fun plusButtonForOwner(owner: CYLTabBarController): CYLPlusButton? = owner.tabBar.plusButton
        @JvmStatic fun plusChildViewControllerForOwner(owner: CYLTabBarController): Fragment? = plusChildViewControllerForTabBarContext(tabBarContextForOwner(owner))
        @JvmStatic fun plusButtonWidthForOwner(owner: CYLTabBarController): Float = plusButtonWidthForTabBarContext(tabBarContextForOwner(owner))
    }
}
