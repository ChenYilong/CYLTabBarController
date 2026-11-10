// [EN] The method names are the iOS names on purpose (`cyl_…`, `tabBarController_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`、`tabBarController_…`），见 docs/Android-API-Map.md。
// [EN] kotlin:S1133: the deprecated members are the twins of deprecated iOS API, kept until iOS removes them. [CN] kotlin:S1133：已废弃的成员与 iOS 已废弃的 API 对应，在 iOS 移除前保留。
@file:Suppress("FunctionName", "kotlin:S100", "kotlin:S1133")

package com.cyl.tabbar

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.MotionEvent
import android.view.HapticFeedbackConstants
import android.view.SoundEffectConstants
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import androidx.annotation.ColorInt
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.fragment.app.FragmentManager
import java.util.WeakHashMap

/**
 * [EN] `CYLTabBarController` for Android: the pages (Fragments) above a `CYLTabBar`, selected by index, with the
 *      plus button, badges, identifiers, login interception, themes, gestures, scroll hiding, the page registry and
 *      configurations of the iOS library. Create it, then show `view` (e.g. `activity.setContentView(controller.view)`).
 * [CN] Android 版 `CYLTabBarController`：`CYLTabBar` 上方的页面（Fragment），按下标选中，带 iOS 库的 PlusButton、角标、标识、登录拦截、主题、
 *      手势、滚动隐藏、页面注册表与配置。创建后显示 `view`（例如 `activity.setContentView(controller.view)`）。
 */
private val SYSTEM_BAR_TYPES = WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()

open class CYLTabBarController(val activity: FragmentActivity) {

    constructor(activity: FragmentActivity, viewControllers: List<Fragment>, tabBarItemsAttributes: List<Map<String, Any?>>) :
        this(activity, viewControllers, tabBarItemsAttributes, CYLEdgeInsets.zero, CYLOffset.zero, CYLEnums.CYLTabBarStyleType.Default, null)

    constructor(activity: FragmentActivity, viewControllers: List<Fragment>, tabBarItemsAttributes: List<Map<String, Any?>>, imageInsets: CYLEdgeInsets, titlePositionAdjustment: CYLOffset) :
        this(activity, viewControllers, tabBarItemsAttributes, imageInsets, titlePositionAdjustment, CYLEnums.CYLTabBarStyleType.Default, null)

    constructor(activity: FragmentActivity, viewControllers: List<Fragment>, tabBarItemsAttributes: List<Map<String, Any?>>, imageInsets: CYLEdgeInsets, titlePositionAdjustment: CYLOffset, context: String?) :
        this(activity, viewControllers, tabBarItemsAttributes, imageInsets, titlePositionAdjustment, CYLEnums.CYLTabBarStyleType.Default, context)

    constructor(activity: FragmentActivity, viewControllers: List<Fragment>, tabBarItemsAttributes: List<Map<String, Any?>>, styleType: CYLEnums.CYLTabBarStyleType, context: String?) :
        this(activity, viewControllers, tabBarItemsAttributes, CYLEdgeInsets.zero, CYLOffset.zero, styleType, context)

    /** [EN] The designated initializer of the iOS library. [CN] iOS 库的指定初始化方法。 */
    constructor(activity: FragmentActivity, viewControllers: List<Fragment>, tabBarItemsAttributes: List<Map<String, Any?>>, imageInsets: CYLEdgeInsets, titlePositionAdjustment: CYLOffset, styleType: CYLEnums.CYLTabBarStyleType, context: String?) : this(activity,
        mapOf(CYLConstants.CYLTabBarControllerViewControllers to viewControllers, CYLConstants.CYLTabBarControllerTabBarItemsAttributes to tabBarItemsAttributes,
              CYLConstants.CYLTabBarControllerImageInsets to imageInsets, CYLConstants.CYLTabBarControllerTitlePositionAdjustment to titlePositionAdjustment,
              CYLConstants.CYLTabBarControllerStyleType to styleType, CYLConstants.CYLTabBarControllerContext to context))

    /** [EN] `-initWithConfiguration:`: one dictionary with every key (`CYLTabBarControllerViewControllers`...). [CN] 一个字典包含所有键。 */
    constructor(activity: FragmentActivity, configuration: Map<String, Any?>) : this(activity) {
        initWithConfiguration(configuration)
    }

    // MARK: - Views

    /** [EN] The root view: the pages above the tab bar. [CN] 根视图：页面在 TabBar 之上。 */
    val view: ViewGroup = CYLTabBarControllerView(activity).also { it.controller = this }
    /** [EN] The container of the pages. [CN] 页面容器。 */
    val pagesContainer: FrameLayout = CYLTabBarPagesContainer(activity, this).apply {
        id = View.generateViewId()
        // [EN] The root view does not clip (the plus button rises above the bar), so the pages clip themselves to their bounds. [CN] 根视图不裁剪（PlusButton 凸出 TabBar），因此页面自己按边界裁剪。
        outlineProvider = android.view.ViewOutlineProvider.BOUNDS
        clipToOutline = true
    }
    /** [EN] `tabBar` / `cyl_tabBar`. [CN] TabBar。 */
    val tabBar: CYLTabBar = CYLTabBar(activity).apply { tabBarController = this@CYLTabBarController }
    val cyl_tabBar: CYLTabBar get() = tabBar
    val fragmentManager: FragmentManager get() = activity.supportFragmentManager
    private val fragmentTag = "CYLTabBarController-" + System.identityHashCode(this)

    private var pagesCommitPending = false

    private var receivedInsetsSinceAttach = false

    /**
     * [EN] The safe area, as on iOS: the pages keep clear of the status bar and the sides, and the tab bar grows by the
     *      navigation bar (`cyl_safeAreaBottom`) with its items above it, so the system bars neither cover nor cut them.
     * [CN] 安全区，与 iOS 相同：页面避开状态栏与两侧，TabBar 增高导航栏的高度（`cyl_safeAreaBottom`），各 Item 位于其上方，系统栏不会遮挡或切割它们。
     */
    private fun applySafeArea(bars: Insets) {
        view.setPadding(bars.left, bars.top, bars.right, 0)
        tabBar.cyl_safeAreaBottom = bars.bottom
    }

    /** [EN] A bar floating over the pages (FlatDesign, Liquid Glass) is their bottom inset, so a list can scroll its last rows above it. [CN] 浮在页面之上的 TabBar（扁平样式、液态玻璃）作为页面的底部 inset，列表可把最后几行滚到 TabBar 上方。 */
    private fun pagesBottomInset(): Int = if (tabBar.styleRenderer.drawsPagesUnderTabBar) cyl_overlayTabBarHeight() else 0

    /** [EN] The part of the window's system bars that overlaps this view on screen. [CN] 窗口系统栏与本视图在屏幕上重叠的部分。 */
    private fun applySafeAreaFromWindow() {
        val window = ViewCompat.getRootWindowInsets(view) ?: return
        val raw = window.getInsets(SYSTEM_BAR_TYPES)
        val location = IntArray(2)
        view.getLocationInWindow(location)
        val root = view.rootView
        val bars = Insets.of(
            maxOf(0, raw.left - location[0]),
            maxOf(0, raw.top - location[1]),
            maxOf(0, location[0] + view.width - (root.width - raw.right)),
            maxOf(0, location[1] + view.height - (root.height - raw.bottom)),
        )
        applySafeArea(bars)
        ViewCompat.dispatchApplyWindowInsets(pagesContainer, WindowInsetsCompat.Builder(window).setInsets(SYSTEM_BAR_TYPES, Insets.of(0, 0, 0, pagesBottomInset())).build())
    }

    /**
     * [EN] A bar that shows the pages through it (FlatDesign's blur, Liquid Glass) draws again when the pages changed in this
     *      frame (scrolling, an animation), and only then: invalidating it on every frame asked for the next frame forever
     *      (60 fps while idle), which kept the main thread busy and delayed switching pages.
     * [CN] 透出页面的 TabBar（扁平样式的模糊、液态玻璃）只在页面本帧有变化时（滚动、动画）重绘：每帧都 invalidate 会不断请求下一帧（空闲时也 60 fps），
     *      使主线程一直忙碌，延迟页面切换。
     */
    private val backdropListener = android.view.ViewTreeObserver.OnPreDrawListener {
        if (tabBar.styleRenderer.drawsPagesUnderTabBar && pagesContainer.isDirty) tabBar.invalidate()
        true
    }

    /** [EN] The height of a bar floating over the pages, in px. [CN] 浮在页面之上的 TabBar 的高度（像素）。 */
    internal fun cyl_overlayTabBarHeight(): Int {
        val itemsHeight = (tabBarHeight * activity.resources.displayMetrics.density).toInt()
        return tabBar.styleRenderer.barHeight(tabBar, itemsHeight, tabBar.cyl_safeAreaBottom)
    }

    init {
        view.addView(pagesContainer, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        view.addView(tabBar, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        // [EN] Edge-to-edge windows (forced from Android 15) draw under the system bars, as iOS does: the pages keep clear of
        //      the status bar and the sides, and the tab bar grows by the navigation bar like iOS's bottom safe area, so the
        //      system bar no longer covers or cuts the items. The bars' insets stop here; the keyboard's go on to the pages.
        // [CN] edge-to-edge 窗口（Android 15 起强制）绘制到系统栏下方，与 iOS 相同：页面避开状态栏与两侧，TabBar 像 iOS 的底部安全区一样
        //      增高导航栏的高度，系统栏不再遮挡或切割各 Item。系统栏的 insets 在此消费，键盘的 insets 继续传给页面。
        ViewCompat.setOnApplyWindowInsetsListener(view) { _, insets ->
            receivedInsetsSinceAttach = true
            applySafeArea(insets.getInsets(SYSTEM_BAR_TYPES))
            WindowInsetsCompat.Builder(insets).setInsets(SYSTEM_BAR_TYPES, Insets.of(0, 0, 0, pagesBottomInset())).build()
        }
        // [EN] A controller shown in place of another (`setContentView` again, e.g. to switch styles) may get no insets: AppCompat's
        //      action bar layout passes them to its content only when they change. Then the safe area is worked out from the
        //      window's insets and where this view is on screen, as iOS does, or the system bars would cover the tabs.
        // [CN] 替换另一个控制器显示时（再次 `setContentView`，例如切换样式）可能收不到 insets：AppCompat 的 ActionBar 布局只在 insets 变化时
        //      才传给内容。此时按窗口的 insets 与本视图在屏幕上的位置计算安全区，与 iOS 相同，否则系统栏会遮挡各 Tab。
        view.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                receivedInsetsSinceAttach = false
                ViewCompat.requestApplyInsets(v)
                v.post { if (!receivedInsetsSinceAttach) applySafeAreaFromWindow() }
            }
            override fun onViewDetachedFromWindow(v: View) = Unit
        })
        // [EN] Fragments need their container in the window: transactions wait until `view` is attached. [CN] Fragment 需要容器已在窗口中：事务等到 `view` 附加后再提交。
        pagesContainer.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                if (pagesCommitPending) commitPages()
                v.viewTreeObserver.addOnWindowFocusChangeListener(windowFocusListener)
                v.viewTreeObserver.addOnGlobalLayoutListener(keyboardListener)
                v.viewTreeObserver.addOnPreDrawListener(backdropListener)
            }
            override fun onViewDetachedFromWindow(v: View) {
                v.viewTreeObserver.removeOnWindowFocusChangeListener(windowFocusListener)
                v.viewTreeObserver.removeOnGlobalLayoutListener(keyboardListener)
                v.viewTreeObserver.removeOnPreDrawListener(backdropListener)
            }
        })
        // [EN] The activity pausing (a call, another app, the recents screen) shows a bar hidden by scrolling (#13). [CN] Activity 暂停（来电、其他 App、最近任务）时恢复滚动隐藏的 TabBar（#13）。
        activity.lifecycle.addObserver(androidx.lifecycle.LifecycleEventObserver { _, event ->
            if (event == androidx.lifecycle.Lifecycle.Event.ON_PAUSE) cyl_restoreTabBarHiddenByScroll()
        })
        registerActive(this)
    }

    /** [EN] Adds the pages to the container and shows the selected one, now or once the view is attached. [CN] 把页面加入容器并显示选中的页面，立即或等视图附加后。 */
    /**
     * [EN] Android only: where the pages live when they are not the controller's own fragments, e.g. an app's ViewPager2
     *      (`cyl_setupWithViewPager2`). The controller then asks it to show the selected page instead of showing and hiding
     *      fragments itself.
     * [CN] 仅 Android：页面不由控制器自己的 Fragment 事务管理时页面所在的位置，例如 App 的 ViewPager2（`cyl_setupWithViewPager2`）。此时控制器让它显示
     *      选中的页面，而不是自己显示和隐藏 Fragment。
     */
    internal interface CYLPagesHost {
        fun cyl_showPage(index: Int)
        fun cyl_pagesDidChange()
    }

    internal var cyl_pagesHost: CYLPagesHost? = null

    private fun commitPages() {
        if (!pagesContainer.isAttachedToWindow || fragmentManager.isDestroyed) {
            pagesCommitPending = true
            return
        }
        pagesCommitPending = false
        cyl_pagesHost?.let { host ->
            // [EN] The host's pages come back after the plus button's page hid them; the plus button's page leaves. [CN] PlusButton 的页面隐藏过的宿主页面重新显示；PlusButton 的页面离开。
            val transaction = fragmentManager.beginTransaction()
            for (page in viewControllers) if (page.isAdded && page.isHidden) transaction.show(page)
            fragmentManager.findFragmentByTag("$fragmentTag-plus")?.takeIf { it.isAdded && !it.isHidden && !tabBar.plusButtonActive }?.let { transaction.hide(it) }
            transaction.commitNowAllowingStateLoss()
            host.cyl_showPage(selectedIndex)
            return
        }
        val transaction = fragmentManager.beginTransaction()
        viewControllers.forEachIndexed { index, page ->
            if (!page.isAdded) transaction.add(pagesContainer.id, page, "$fragmentTag-$index")
            // [EN] A tab unloaded by a memory warning creates its view again when selected (#426). [CN] 被内存警告卸载的 Tab 在选中时重新创建视图（#426）。
            if (index == selectedIndex && page.isDetached) transaction.attach(page)
            if (index == selectedIndex) transaction.show(page) else transaction.hide(page)
        }
        // [EN] The plus button's page (`plusChildViewController`) leaves the screen when a tab is selected; it was added last,
        //      so left shown it would cover the selected tab's page. On iOS it is one of the view controllers and is replaced.
        // [CN] 选中 Tab 时 PlusButton 的页面（`plusChildViewController`）离开屏幕；它最后添加，若仍显示会盖住选中 Tab 的页面。iOS 上它是 viewControllers
        //      之一，会被替换。
        val plusChild = fragmentManager.findFragmentByTag("$fragmentTag-plus")
        if (plusChild != null && plusChild.isAdded && !plusChild.isHidden && !tabBar.plusButtonActive) transaction.hide(plusChild)
        transaction.commitNowAllowingStateLoss()
    }

    // MARK: - CYLTabBarController properties 属性

    /**
     * [EN] `tabBarStyleType`: the classic bar (`Default` / `System`), FlatDesign (translated from iOS `CYLFlatDesignTabBar`) or
     *      Liquid Glass (a floating glass capsule, after Kyant's AndroidLiquidGlass). FlatDesign and Liquid Glass float over
     *      the pages, which get the bar's height as their bottom inset. See `CYLTabBarStyle.kt`.
     * [CN] `tabBarStyleType`：经典 TabBar（`Default` / `System`）、扁平样式（由 iOS 的 `CYLFlatDesignTabBar` 翻译）或液态玻璃（浮动的玻璃胶囊，
     *      参考 Kyant 的 AndroidLiquidGlass）。扁平样式与液态玻璃浮在页面之上，页面以 TabBar 的高度作为底部 inset。见 `CYLTabBarStyle.kt`。
     */
    var tabBarStyleType: CYLEnums.CYLTabBarStyleType = CYLEnums.CYLTabBarStyleType.Default
        set(value) {
            field = value
            tabBar.styleRenderer = CYLTabBarStyleRenderer.forStyle(value)
            ViewCompat.requestApplyInsets(view)
            view.requestLayout()
        }
    /** [EN] `context`: selects the plus button (`CYLPlusButtonSubclassing.tabBarContext`). [CN] 选择 PlusButton 的 context。 */
    var context: String? = null
        set(value) { field = value; tabBar.context_ = value }
    var delegate: CYLTabBarControllerDelegate? = null
    var viewControllers: List<Fragment> = emptyList()
        private set
    /** [EN] The items, one per page. [CN] 每个页面一个 item。 */
    var tabBarItems: List<CYLTabBarItem> = emptyList()
        private set
    var tabBarItemsAttributes: List<Map<String, Any?>> = emptyList()
        private set
    var tabBarHeight: Float = CYLConstants.CYLTabBarHeight
        set(value) { field = value; tabBar.requestLayout() }
    var imageInsets: CYLEdgeInsets = CYLEdgeInsets.zero
        set(value) { field = value; tabBar.requestLayout() }
    var titlePositionAdjustment: CYLOffset = CYLOffset.zero
        set(value) { field = value; tabBar.requestLayout() }
    var imagePositionAdjustment: CYLOffset = CYLOffset.zero
    var automaticallyAdjustsImageOnlyTabs: Boolean = true
    var adjustTabBarItemImageViewSizeDependOnSuperView: Boolean = true
    var unloadsUnselectedViewsOnMemoryWarning: Boolean = false
    /** [EN] The playback speed of every tab animation (#428); 0, negative or not finite: the default. [CN] 所有 Tab 动画的播放速度（#428）；0、负数或非有限值表示默认值。 */
    var tabBarItemAnimationSpeed: Float = 1f
        set(value) {
            field = value
            for (button in tabBar.tabBarButtonArray) if (button.cyl_isTabBarItemAnimationReady()) button.cyl_setTabBarItemAnimationSpeed(value)
        }
    /** [EN] `noNeedUIDesignCompatibility`: false means FlatDesign (`tabBarStyleType`), true Liquid Glass; prefer `tabBarStyleType`. [CN] false 表示扁平样式（`tabBarStyleType`），true 表示液态玻璃；建议直接设置 `tabBarStyleType`。 */
    var noNeedUIDesignCompatibility: Boolean
        get() = tabBarStyleType != CYLEnums.CYLTabBarStyleType.FlatDesign
        set(value) { tabBarStyleType = if (value) CYLEnums.CYLTabBarStyleType.LiquidGlass else CYLEnums.CYLTabBarStyleType.FlatDesign }
    var allowsVerticalBar: Boolean = false
    var viewDidLayoutSubviewsBlock: CYLViewDidLayoutSubViewsBlock? = null
    /** [EN] The animation file of each animated tab, in tab order (`CYLTabBarAnimation…` and the library keys). [CN] 每个有动画的 Tab 的动画文件，按 Tab 顺序。 */
    val tabBarItemAnimationURLs: MutableList<String> = ArrayList()
    /** [EN] The animation size of each animated tab (dp). [CN] 每个有动画的 Tab 的动画尺寸（dp）。 */
    val tabBarItemAnimationSizes: MutableList<CYLSize> = ArrayList()
    /** [EN] Whether any tab shows an animation view. [CN] 是否有 Tab 显示动画视图。 */
    val tabBarItemAnimationViewAdded: Boolean get() = tabBar.tabBarButtonArray.any { it.cyl_isTabBarItemAnimationReady() }

    /** [EN] `lottieAnimationSpeed` (deprecated): `tabBarItemAnimationSpeed`. [CN] 已废弃：即 `tabBarItemAnimationSpeed`。 */
    @Deprecated("Use tabBarItemAnimationSpeed", ReplaceWith("tabBarItemAnimationSpeed"))
    var lottieAnimationSpeed: Float
        get() = tabBarItemAnimationSpeed
        set(value) { tabBarItemAnimationSpeed = value }
    /** [EN] `lottieViewAdded` (deprecated): `tabBarItemAnimationViewAdded`. [CN] 已废弃：即 `tabBarItemAnimationViewAdded`。 */
    @Deprecated("Use tabBarItemAnimationViewAdded", ReplaceWith("tabBarItemAnimationViewAdded"))
    val lottieViewAdded: Boolean get() = tabBarItemAnimationViewAdded
    /** [EN] `lottieURLs` (deprecated): `tabBarItemAnimationURLs`. [CN] 已废弃：即 `tabBarItemAnimationURLs`。 */
    @Deprecated("Use tabBarItemAnimationURLs", ReplaceWith("tabBarItemAnimationURLs"))
    val lottieURLs: MutableList<String> get() = tabBarItemAnimationURLs
    /** [EN] `lottieSizes` (deprecated): `tabBarItemAnimationSizes`. [CN] 已废弃：即 `tabBarItemAnimationSizes`。 */
    @Deprecated("Use tabBarItemAnimationSizes", ReplaceWith("tabBarItemAnimationSizes"))
    val lottieSizes: MutableList<CYLSize> get() = tabBarItemAnimationSizes

    /** [EN] `-lottieAnimationViewContentMode` (use `tabBarItemAnimationViewContentMode`); override in a subclass. [CN] 请使用 `tabBarItemAnimationViewContentMode`；可在子类中重写。 */
    open fun lottieAnimationViewContentMode(): android.widget.ImageView.ScaleType = android.widget.ImageView.ScaleType.FIT_CENTER
    /** [EN] `-tabBarItemAnimationViewContentMode`: the scale of every animation view, for any library; default `lottieAnimationViewContentMode()`. [CN] 所有动画视图的缩放方式；默认为 `lottieAnimationViewContentMode()`。 */
    open fun tabBarItemAnimationViewContentMode(): android.widget.ImageView.ScaleType = lottieAnimationViewContentMode()

    /** [EN] Adds the animation of every tab that names one (#604), and shows the selected one's last frame (#389). [CN] 为每个指定了动画的 Tab 添加动画，并显示选中 Tab 的最后一帧（#389）。 */
    private fun cyl_addTabBarItemAnimations() {
        tabBarItemAnimationURLs.clear()
        tabBarItemAnimationSizes.clear()
        tabBar.tabBarButtonArray.forEachIndexed { index, button ->
            val attributes = tabBarItemsAttributes.getOrNull(index) ?: return@forEachIndexed
            val url = CYLTabBarItemAnimationURLOfAttributes(attributes) ?: return@forEachIndexed
            val size = CYLTabBarConfiguration.sizeValue(CYLTabBarItemAttributesAnimationValue(attributes, CYLConstants.CYLTabBarAnimationSize))
                ?: CYLConstants.cyl_tabBarItemAnimationSizeValue(null, button.item.image)
            tabBarItemAnimationURLs += url
            tabBarItemAnimationSizes += size
            button.item.cyl_tabBarItemAnimationURL = url
            button.item.cyl_tabBarItemAnimationSizeValue = size
            button.cyl_addTabBarItemAnimationWithURL(url, size, tabBarItemAnimationViewContentMode(), tabBarItemAnimationSpeed)
        }
        cyl_playSelectedTabBarItemAnimation(defaultSelected = true)
    }

    /** [EN] Plays the selected tab's animation (or shows its last frame) and stops the others. [CN] 播放选中 Tab 的动画（或显示最后一帧），停止其他动画。 */
    private fun cyl_playSelectedTabBarItemAnimation(defaultSelected: Boolean) {
        if (tabBarItemAnimationURLs.isEmpty()) return
        val selected = if (tabBar.plusButtonActive) tabBar.plusButton else tabBar.cyl_tabBarButtonWithTabIndex(selectedIndex)
        val item = (selected as? CYLTabBarItemButton)?.item
        tabBar.cyl_animationLottieImageWithSelectedControl(selected, item?.cyl_tabBarItemAnimationURL, item?.cyl_tabBarItemAnimationSizeValue, defaultSelected, tabBarItemAnimationViewContentMode())
    }

    /** [EN] `selectedIndex`: setting it selects the page (no delegate questions). [CN] 设置即选中页面（不询问代理）。 */
    var selectedIndex: Int = 0
        set(value) {
            if (value < 0 || value >= viewControllers.size) return
            val previous = field
            // [EN] Back from the plus button's page to the same tab: its animation plays again. [CN] 从 PlusButton 页面回到同一个 Tab：其动画再次播放。
            val fromPlusPage = tabBar.plusButtonActive
            field = value
            tabBar.plusButtonActive = false
            showSelectedPage()
            tabBar.refreshSelection()
            cyl_applyNavigationTitleOfSelectedPage()
            // [EN] Another tab: a bar hidden by scrolling comes back (issue #13, as on iOS). [CN] 切换到其他 Tab：滚动隐藏的 TabBar 恢复显示（issue #13，与 iOS 一致）。
            if (previous != value) cyl_restoreTabBarHiddenByScroll()
            if (previous != value || fromPlusPage) cyl_playSelectedTabBarItemAnimation(defaultSelected = false)
            if (previous != value && !revertingTransition) runTransition(previous, value)
        }

    private var revertingTransition = false

    /**
     * [EN] Asks the delegate for a transition animator (`CYLTabBarSlideTransitionAnimator`) and, when it returns one, slides
     *      the pages; an interaction controller (`CYLTabBarInteractiveTransition`) makes the pan drive it. A cancelled
     *      interactive transition selects the previous tab again.
     * [CN] 向代理询问转场动画对象（`CYLTabBarSlideTransitionAnimator`），返回时滑动切换页面；交互控制器（`CYLTabBarInteractiveTransition`）
     *      让拖动驱动转场。取消的交互转场会重新选中之前的 Tab。
     */
    private fun runTransition(previous: Int, index: Int) {
        // [EN] A pager (`cyl_setupWithViewPager2`) moves its own pages. [CN] 翻页控件（`cyl_setupWithViewPager2`）自己移动页面。
        if (cyl_pagesHost != null) return
        val delegate = delegate ?: return
        val from = viewControllers.getOrNull(previous) ?: return
        val to = viewControllers.getOrNull(index) ?: return
        val toView = to.view ?: return
        val animator = delegate.tabBarController_animationControllerForTransition(this, from, to) ?: return
        val fromView = from.view
        val completion: (Boolean) -> Unit = { finished ->
            if (finished) {
                if (from.isHidden) fromView?.visibility = View.GONE
            } else {
                revertingTransition = true
                selectedIndex = previous
                revertingTransition = false
                if (to.isHidden) toView.visibility = View.GONE
            }
        }
        val interaction = delegate.tabBarController_interactionControllerForAnimationController(this, animator)
        if (interaction != null) {
            animator.prepare(fromView, toView, completion)
            interaction.startInteractiveTransition(animator, pagesContainer.width)
        } else {
            animator.animateTransition(fromView, toView, completion)
        }
    }
    val selectedViewController: Fragment? get() = viewControllers.getOrNull(selectedIndex)

    var tabBarHidden: Boolean = false
        set(value) { setTabBarHidden(value, false) }

    /** [EN] `-setTabBarHidden:animated:`: the app hides or shows the bar, which ends a scroll hiding session. [CN] App 隐藏或显示 TabBar，结束滚动隐藏会话。 */
    fun setTabBarHidden(hidden: Boolean, animated: Boolean) {
        cyl_isTabBarHiddenByScroll = false
        applyTabBarHidden(hidden, animated)
    }

    private fun applyTabBarHidden(hidden: Boolean, animated: Boolean) {
        val wasHidden = tabBar.visibility != View.VISIBLE
        if (wasHidden == hidden) return
        if (animated) {
            tabBar.animate().translationY(if (hidden) tabBar.height.toFloat() else 0f).setDuration(250).withEndAction {
                tabBar.visibility = if (hidden) View.GONE else View.VISIBLE
            }.start()
            if (!hidden) tabBar.visibility = View.VISIBLE
        } else {
            tabBar.translationY = 0f
            tabBar.visibility = if (hidden) View.GONE else View.VISIBLE
        }
    }

    // MARK: - Initialization 初始化

    private var pagesFromPageIdentifiers = false
    var cyl_pageRegistry: CYLTabBarPageProviding? = null
        private set
    var cyl_pageResolver: CYLTabBarPageProvider? = null
        private set
    var cyl_pageLookupOrder: List<CYLTabBarPageSource> = CYLTabBarPageRegistry.defaultPageLookupOrder
        private set
    var cyl_skippedTabs: List<CYLTabBarSkippedTab> = emptyList()
        private set
    val cyl_pagesFromPageIdentifiers: Boolean get() = pagesFromPageIdentifiers
    private val pagesByPageIdentifier = LinkedHashMap<String, MutableList<Fragment>>()

    private fun initWithConfiguration(configuration: Map<String, Any?>) {
        val appVersion = try { activity.packageManager.getPackageInfo(activity.packageName, 0).versionName } catch (error: Exception) { null }
        val darkMode = (activity.resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) == android.content.res.Configuration.UI_MODE_NIGHT_YES
        // [EN] Localized texts first, as on iOS (CYLTabBarControllerLocalization). [CN] 与 iOS 一样先本地化文本。
        val localized = CYLTabBarConfigurationLocalization.localize(activity, configuration)
        val normalized = CYLTabBarConfiguration.cyl_normalizedConfiguration(localized, "android", appVersion, darkMode)
        @Suppress("UNCHECKED_CAST")
        var items = (normalized[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] as? List<Map<String, Any?>>) ?: emptyList()
        @Suppress("UNCHECKED_CAST")
        var pages = (normalized[CYLConstants.CYLTabBarControllerViewControllers] as? List<*>)?.filterIsInstance<Fragment>()?.distinct()
        if (pages != null && pages.isEmpty()) pages = null
        val skipped = ArrayList<CYLTabBarSkippedTab>()
        val kept = ArrayList<Map<String, Any?>>()
        pages = if (pages != null) pagesFromCode(items, pages, kept, skipped) else pagesFromPageIdentifiers(normalized, items, kept, skipped)
        items = kept
        cyl_skippedTabs = skipped
        imageInsets = (normalized[CYLConstants.CYLTabBarControllerImageInsets] as? CYLEdgeInsets) ?: CYLTabBarConfiguration.edgeInsetsValue(normalized[CYLConstants.CYLTabBarControllerImageInsets]) ?: CYLEdgeInsets.zero
        titlePositionAdjustment = (normalized[CYLConstants.CYLTabBarControllerTitlePositionAdjustment] as? CYLOffset) ?: CYLTabBarConfiguration.offsetValue(normalized[CYLConstants.CYLTabBarControllerTitlePositionAdjustment]) ?: CYLOffset.zero
        tabBarStyleType = (normalized[CYLConstants.CYLTabBarControllerStyleType] as? CYLEnums.CYLTabBarStyleType) ?: CYLEnums.CYLTabBarStyleType.Default
        context = normalized[CYLConstants.CYLTabBarControllerContext] as? String
        // [EN] Before the tabs are set: the tab bar looks up the plus button of its context. [CN] 在设置 Tab 之前：TabBar 会查找其 context 的 PlusButton。
        // [EN] A plus button page (`CYLTabBarItemPageIdentifier`) is found like a tab's page. [CN] PlusButton 的页面按 Tab 页面的方式查找。
        CYLConfigurationPlusButton.registerIfNeeded(activity, normalized, context, items.size) { identifier ->
            CYLTabBarPageRegistry.pagesOfTabs(listOf(mapOf(CYLConstants.CYLTabBarItemPageIdentifier to identifier)), cyl_pageRegistry, cyl_pageResolver,
                cyl_pageLookupOrder, ArrayList(), ArrayList()).firstOrNull()
        }
        (normalized[CYLConstants.CYLTabBarControllerTabBarItemAnimationSpeed]?.toString()?.toFloatOrNull())?.takeIf { it > 0 && it.isFinite() }?.let { tabBarItemAnimationSpeed = it }
        // [EN] Interactions of the configuration; `CYLTabBarControllerUserInterfaceStyle` is iOS only (Android follows the system).
        // [CN] 配置中的交互；`CYLTabBarControllerUserInterfaceStyle` 仅用于 iOS（Android 跟随系统）。
        CYLTabBarConfiguration.tapAnimationValue(normalized[CYLConstants.CYLTabBarControllerTabButtonTapAnimation])?.let { cyl_tabButtonTapAnimationType = it }
        CYLTabBarConfiguration.boolValue(normalized[CYLConstants.CYLTabBarControllerSwipeToSwitchTab])?.let { cyl_swipeToSwitchTabEnabled = it }
        // [EN] Tabs that need login: a list of strings, or a comma-separated string (as iOS). [CN] 需要登录的 Tab：字符串列表或逗号分隔的字符串（与 iOS 相同）。
        when (val loginRequired = normalized[CYLConstants.CYLTabBarControllerLoginRequiredTabBarItemIdentifiers]) {
            is String -> cyl_loginRequiredTabBarItemIdentifiers = loginRequired.split(',').map { it.trim() }.filter { it.isNotEmpty() }
            is List<*> -> cyl_loginRequiredTabBarItemIdentifiers = loginRequired.mapNotNull { (it as? String)?.trim()?.takeIf { identifier -> identifier.isNotEmpty() } }
        }
        setViewControllers(pages, items)
        cyl_adoptPendingPages()
        (normalized[CYLConfigurationThemes.INFO_KEY] as? CYLConfigurationThemes.Info)?.let { cyl_applyConfigurationThemes(it) }
        cyl_didInitialize()
    }

    /**
     * [EN] Registers the skins of the configuration with the theme manager (`CYLTabBarControllerThemeManagerName`, or
     *      `cyl_themeManager`), and applies the first one unless a skin was chosen before. With a dark skin, the manager
     *      follows Dark Mode (`identifierForTrait`), unless it already has its own way or another skin was chosen.
     * [CN] 把配置中的皮肤注册到主题管理器（`CYLTabBarControllerThemeManagerName` 或 `cyl_themeManager`），除非之前已选择皮肤，否则应用首个皮肤。
     *      有深色皮肤时，管理器跟随深色模式（`identifierForTrait`），除非它已有自己的方式或已选择了其他皮肤。
     */
    private fun cyl_applyConfigurationThemes(info: CYLConfigurationThemes.Info) {
        info.managerName?.let { cyl_themeManager = CYLThemeManagerCenter.themeManagerWithName(it) }
        val manager = cyl_themeManager
        for (theme in info.themes) manager.addThemeIdentifier(theme.identifier, theme)
        // [EN] A skin of an earlier configuration that this one does not have is not a choice to keep (as iOS).
        // [CN] 之前配置中的皮肤、而本配置中没有，不属于需要保留的选择（与 iOS 相同）。
        val stale = manager.currentTheme is CYLTabBarConfigurationTheme && info.themes.none { it.identifier == manager.currentThemeIdentifier }
        val current = manager.currentThemeIdentifier.takeUnless { stale }
        if (current == null) manager.currentThemeIdentifier = info.initial
        val keepsChoice = current != null && current != info.base && current != info.dark
        val dark = info.dark
        if (dark != null && manager.identifierForTrait == null && !keepsChoice) {
            val base = info.base
            manager.identifierForTrait = { isDark -> if (isDark) dark else base }
            manager.updateThemeForTraitCollection(activity.resources.configuration)
        }
    }

    private fun excludedTab(item: Map<String, Any?>) = CYLTabBarSkippedTab(CYLTabBarPageSkipReason.EXCLUDED, CYLTabBarPageRegistry.pageIdentifierOfTab(item),
        com.cyl.tabbar.pages.TabItem(item), item[CYLTabBarConfiguration.EXCLUSION_REASON_KEY] as? String)

    /** [EN] Pages given from code, matched to the tabs by index; an excluded tab takes its page out (B22). [CN] 代码传入的页面，按下标对应 Tab；被排除的 Tab 连同页面一起移除（B22）。 */
    private fun pagesFromCode(items: List<Map<String, Any?>>, pages: List<Fragment>, kept: MutableList<Map<String, Any?>>, skipped: MutableList<CYLTabBarSkippedTab>): List<Fragment> {
        val keptPages = ArrayList<Fragment>()
        for (index in 0 until maxOf(items.size, pages.size)) {
            val item = items.getOrNull(index)
            if (item?.get(CYLTabBarConfiguration.EXCLUDED_KEY) == true) {
                skipped += excludedTab(item)
                continue
            }
            kept += item ?: emptyMap()
            pages.getOrNull(index)?.let { keptPages += it }
        }
        while (kept.size > keptPages.size) kept.removeAt(kept.size - 1)
        while (kept.size < keptPages.size) kept += emptyMap<String, Any?>()
        return keptPages
    }

    /** [EN] Pages resolved from the tabs' page IDs through the controller's page sources (docs/Tab-Page-Registry.md). [CN] 通过控制器的页面来源，按 Tab 的页面 ID 解析页面（docs/Tab-Page-Registry.md）。 */
    private fun pagesFromPageIdentifiers(normalized: Map<String, Any?>, items: List<Map<String, Any?>>, kept: MutableList<Map<String, Any?>>, skipped: MutableList<CYLTabBarSkippedTab>): List<Fragment> {
        pagesFromPageIdentifiers = true
        cyl_pageRegistry = normalized[CYLConstants.CYLTabBarControllerPageRegistry] as? CYLTabBarPageProviding
        @Suppress("UNCHECKED_CAST")
        cyl_pageResolver = normalized[CYLConstants.CYLTabBarControllerPageResolver] as? CYLTabBarPageProvider
        @Suppress("UNCHECKED_CAST")
        cyl_pageLookupOrder = (normalized[CYLConstants.CYLTabBarControllerPageLookupOrder] as? List<CYLTabBarPageSource>) ?: CYLTabBarPageRegistry.defaultPageLookupOrder
        val resolvable = ArrayList<Map<String, Any?>>()
        for (item in items) {
            when {
                item.isEmpty() -> skipped += CYLTabBarSkippedTab(CYLTabBarPageSkipReason.INVALID_TAB, null, null, "a placeholder for a tab that is not a dictionary")
                item[CYLTabBarConfiguration.EXCLUDED_KEY] == true -> skipped += excludedTab(item)
                else -> resolvable += item
            }
        }
        return CYLTabBarPageRegistry.pagesOfTabs(resolvable, cyl_pageRegistry, cyl_pageResolver, cyl_pageLookupOrder, kept, skipped)
    }

    /** [EN] `-cyl_didInitialize`: a hook for subclasses, called once at the end of every initializer. [CN] 子类钩子，每个初始化方法末尾调用一次。 */
    open fun cyl_didInitialize() { /* [EN] For subclasses. [CN] 供子类重写。 */ }

    /** [EN] `-setViewControllers:` with the attributes: builds the items and the tab buttons. [CN] 设置页面与属性：创建 item 与 Tab 按钮。 */
    fun setViewControllers(viewControllers: List<Fragment>, tabBarItemsAttributes: List<Map<String, Any?>>) {
        val removed = this.viewControllers.filter { it !in viewControllers && it.isAdded }
        if (removed.isNotEmpty()) fragmentManager.beginTransaction().apply { removed.forEach { remove(it) } }.commitNowAllowingStateLoss()
        this.viewControllers = viewControllers
        this.tabBarItemsAttributes = tabBarItemsAttributes
        tabBarItems = viewControllers.indices.map { index -> makeItem(tabBarItemsAttributes.getOrNull(index) ?: emptyMap()) }
        pagesByPageIdentifier.clear()
        viewControllers.forEachIndexed { index, page ->
            CYLTabBarPageRegistry.pageIdentifierOfTab(tabBarItemsAttributes.getOrNull(index) ?: emptyMap())?.let { pagesByPageIdentifier.getOrPut(it) { ArrayList() } += page }
        }
        if (selectedIndex >= viewControllers.size) selectedIndex = 0
        cyl_pagesHost?.cyl_pagesDidChange()
        commitPages()
        tabBar.cyl_reloadTabButtons()
        cyl_addTabBarItemAnimations()
        loadImageURLs()
        cyl_applyLaunchTabBarThemeIfNeeded()
        cyl_applyNavigationTitleOfSelectedPage()
        viewDidLayoutSubviewsBlock?.invoke(this)
    }

    private fun makeItem(attributes: Map<String, Any?>): CYLTabBarItem {
        val item = CYLTabBarItem(attributes)
        val resolver = CYLTabBarConfiguration.imageResolver
        (attributes[CYLConstants.CYLTabBarItemImage] as? String)?.let { item.image = resolver.drawable(activity, it) }
        (attributes[CYLConstants.CYLTabBarItemSelectedImage] as? String)?.let { item.selectedImage = resolver.drawable(activity, it) }
        (attributes[CYLConstants.CYLTabBarItemImage] as? android.graphics.drawable.Drawable)?.let { item.image = it }
        (attributes[CYLConstants.CYLTabBarItemSelectedImage] as? android.graphics.drawable.Drawable)?.let { item.selectedImage = it }
        // [EN] `CYLTabBarItemDarkImage` / `CYLTabBarItemSelectedDarkImage` in night mode, as iOS picks them in Dark Mode. [CN] 夜间模式下使用 `CYLTabBarItemDarkImage` / `CYLTabBarItemSelectedDarkImage`，与 iOS 深色模式一致。
        if ((activity.resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) == android.content.res.Configuration.UI_MODE_NIGHT_YES) {
            imageValue(attributes[CYLConstants.CYLTabBarItemDarkImage], resolver)?.let { item.image = it }
            imageValue(attributes[CYLConstants.CYLTabBarItemSelectedDarkImage], resolver)?.let { item.selectedImage = it }
        }
        if (item.selectedImage == null) item.selectedImage = item.image
        item.cyl_imageInsets = CYLTabBarConfiguration.edgeInsetsValue(attributes[CYLConstants.CYLTabBarItemImageInsets]) ?: CYLEdgeInsets.zero
        item.cyl_titlePositionAdjustment = CYLTabBarConfiguration.offsetValue(attributes[CYLConstants.CYLTabBarItemTitlePositionAdjustment]) ?: CYLOffset.zero
        item.cyl_imagePositionAdjustment = CYLTabBarConfiguration.offsetValue(attributes[CYLConstants.CYLTabBarItemImagePositionAdjustment]) ?: imagePositionAdjustment
        item.cyl_titleColor = CYLTabBarConfiguration.colorValue(attributes[CYLConstants.CYLTabBarItemTitleColor])
        item.cyl_selectedTitleColor = CYLTabBarConfiguration.colorValue(attributes[CYLConstants.CYLTabBarItemSelectedTitleColor])
        item.cyl_iconColor = CYLTabBarConfiguration.colorValue(attributes[CYLConstants.CYLTabBarItemIconColor])
        item.cyl_selectedIconColor = CYLTabBarConfiguration.colorValue(attributes[CYLConstants.CYLTabBarItemSelectedIconColor])
        item.cyl_backgroundColor = CYLTabBarConfiguration.colorValue(attributes[CYLConstants.CYLTabBarItemBackgroundColor])
        item.cyl_selectedBackgroundColor = CYLTabBarConfiguration.colorValue(attributes[CYLConstants.CYLTabBarItemSelectedBackgroundColor])
        item.cyl_titleFont = CYLFont.fromConfigurationValue(attributes[CYLConstants.CYLTabBarItemTitleFont])
        item.cyl_selectedTitleFont = CYLFont.fromConfigurationValue(attributes[CYLConstants.CYLTabBarItemSelectedTitleFont])
        item.cyl_tabBarItemAnimationURL = listOf(CYLConstants.CYLTabBarAnimationURL, CYLConstants.CYLTabBarLottieURL, CYLConstants.CYLTabBarPAGURL, CYLConstants.CYLTabBarRiveURL, CYLConstants.CYLTabBarGIFURL,
                                                 CYLConstants.CYLTabBarAnimationFilePath, CYLConstants.CYLTabBarLottieFilePath, CYLConstants.CYLTabBarPAGFilePath, CYLConstants.CYLTabBarRiveFilePath, CYLConstants.CYLTabBarGIFFilePath)
            .firstNotNullOfOrNull { attributes[it] as? String }
        item.cyl_tabBarItemAnimationSizeValue = listOf(CYLConstants.CYLTabBarAnimationSize, CYLConstants.CYLTabBarLottieSize, CYLConstants.CYLTabBarPAGSize, CYLConstants.CYLTabBarRiveSize, CYLConstants.CYLTabBarGIFSize)
            .firstNotNullOfOrNull { CYLTabBarConfiguration.sizeValue(attributes[it]) }
        return item
    }

    private fun imageValue(value: Any?, resolver: CYLTabBarConfiguration.CYLTabBarImageResolver): android.graphics.drawable.Drawable? = when (value) {
        is android.graphics.drawable.Drawable -> value
        is String -> resolver.drawable(activity, value)
        else -> null
    }

    /** [EN] `CYLTabBarItemImageURL` / `CYLTabBarItemSelectedImageURL` / `CYLTabBarItemImageURLSize`: icons downloaded after the tabs exist. [CN] 网络图标：Tab 创建后下载。 */
    private fun loadImageURLs() {
        tabBarItemsAttributes.forEachIndexed { index, attributes ->
            val url = attributes[CYLConstants.CYLTabBarItemImageURL] as? String ?: return@forEachIndexed
            val selected = attributes[CYLConstants.CYLTabBarItemSelectedImageURL] as? String
            setTabBarItemIconWithURL(url, selected, CYLTabBarConfiguration.sizeValue(attributes[CYLConstants.CYLTabBarItemImageURLSize]), index)
        }
    }

    private fun showSelectedPage() {
        commitPages()
        cyl_trackSelectedPageScrollView()
        if (cyl_hidesBadgeOfSelectedTab) {
            tabBar.tabBarButtonArray.forEachIndexed { index, button -> if (index == selectedIndex) button.cyl_pauseBadge() else if (button.cyl_isPauseBadge()) button.cyl_resumeBadge() }
        }
    }

    // MARK: - Tab taps 点击

    internal fun cyl_tabButtonTapped(button: CYLTabBarItemButton) {
        if (!button.item.isEnabled) return
        val index = button.index
        val page = viewControllers.getOrNull(index) ?: return
        val delegate = delegate
        if (delegate?.tabBarController_shouldPerformCustomActionForViewController(this, page) ?: cyl_isCustomActionTabViewController(page)) {
            // [EN] `cyl_customTabActionHandler` when set, else the delegate. [CN] 设置了 `cyl_customTabActionHandler` 时用它，否则用代理。
            cyl_customActionBlock?.invoke(this, page) ?: delegate?.tabBarController_performCustomActionForViewController(this, page)
            cyl_playTabButtonTapFeedback()
            delegate?.tabBarController_didRecognizeTabBarItemGesture(this, CYLEnums.CYLTabBarItemGesture.Tap, button, page)
            return
        }
        if (delegate?.tabBarController_shouldSelectViewController(this, page) == false) return
        if (cyl_interceptLoginIfNeededForViewController(page) { loggedIn -> if (loggedIn) selectIndexFromTap(index, button, page) }) return
        selectIndexFromTap(index, button, page)
    }

    private fun selectIndexFromTap(index: Int, button: CYLTabBarItemButton, page: Fragment) {
        val reselected = index == selectedIndex && !tabBar.plusButtonActive
        selectedIndex = index
        cyl_playTabButtonAnimationForControl(button)
        cyl_playTabButtonTapFeedback()
        delegate?.tabBarController_didSelectViewController(this, page)
        delegate?.tabBarController_didSelectControl(this, button)
        delegate?.tabBarController_didRecognizeTabBarItemGesture(this, CYLEnums.CYLTabBarItemGesture.Tap, button, page)
        if (reselected) cyl_performReselectBehavior(page)
    }

    internal fun cyl_tabButtonDoubleTapped(button: CYLTabBarItemButton) {
        val item = button.item
        item.cyl_doubleTapBlock?.invoke(item, button.index)
        cyl_tabBarItemGestureHandler?.invoke(this, CYLEnums.CYLTabBarItemGesture.DoubleTap, button, viewControllers.getOrNull(button.index))
        delegate?.tabBarController_didRecognizeTabBarItemGesture(this, CYLEnums.CYLTabBarItemGesture.DoubleTap, button, viewControllers.getOrNull(button.index))
    }

    internal fun cyl_tabButtonLongPressed(button: CYLTabBarItemButton) {
        cyl_didLongPressControlBlock?.invoke(this, button)
        cyl_tabBarItemGestureHandler?.invoke(this, CYLEnums.CYLTabBarItemGesture.LongPress, button, viewControllers.getOrNull(button.index))
        delegate?.tabBarController_didLongPressControl(this, button)
        delegate?.tabBarController_didRecognizeTabBarItemGesture(this, CYLEnums.CYLTabBarItemGesture.LongPress, button, viewControllers.getOrNull(button.index))
    }

    internal fun cyl_tabButtonSwiped(button: CYLTabBarItemButton, toLeft: Boolean) {
        val gesture = if (toLeft) CYLEnums.CYLTabBarItemGesture.SwipeLeft else CYLEnums.CYLTabBarItemGesture.SwipeRight
        cyl_tabBarItemGestureHandler?.invoke(this, gesture, button, viewControllers.getOrNull(button.index))
        delegate?.tabBarController_didRecognizeTabBarItemGesture(this, gesture, button, viewControllers.getOrNull(button.index))
        if (cyl_swipeToSwitchTabEnabled) cyl_switchToAdjacentTabWithStep(if (toLeft) 1 else -1, true)
    }

    // MARK: - Swiping between pages (Android only) 滑动翻页（仅 Android）

    /**
     * [EN] Android only (no iOS counterpart; adapted from QMUITabSegment with ViewPager): a horizontal drag on the pages moves
     *      to the neighbor tab, with the pages, the indicator (`CYLTabBar.cyl_indicator`) and the titles following the finger.
     *      Default false. Selecting this way tells the delegate as a tap does (`didSelectViewController`, `didSelectControl`),
     *      without the tap animation. See docs/Android-Library.md.
     * [CN] 仅 Android（iOS 无对应 API；改编自 QMUITabSegment 配合 ViewPager）：在页面上横向拖动切换到相邻 Tab，页面、指示条（`CYLTabBar.cyl_indicator`）
     *      与标题跟随手指。默认 false。以此方式选中时与点击一样通知代理（`didSelectViewController`、`didSelectControl`），但没有点击动画。
     *      见 docs/Android-Library.md。
     */
    var cyl_swipesBetweenPages: Boolean = false

    /** [EN] The page at `index` when a tap would select it now (no custom action, no login, `shouldSelect`), else null. [CN] 点击能立即选中时返回第 `index` 个页面（无自定义动作、无需登录、`shouldSelect`），否则为 null。 */
    internal fun cyl_swipeTargetPage(index: Int): Fragment? = cyl_gestureSelectablePage(index)?.takeIf { it.isAdded }

    /** [EN] The page at `index` when a gesture may select it (as a tap would), added or not. [CN] 手势可以选中（与点击一样）时返回第 `index` 个页面，无论是否已添加。 */
    internal fun cyl_gestureSelectablePage(index: Int): Fragment? {
        val page = viewControllers.getOrNull(index) ?: return null
        if (tabBar.plusButtonActive) return null
        val delegate = delegate
        if (delegate?.tabBarController_shouldPerformCustomActionForViewController(this, page) ?: cyl_isCustomActionTabViewController(page)) return null
        if (!cyl_loggedIn && (delegate?.tabBarController_requiresLoginToSelectViewController(this, page) ?: cyl_isLoginRequiredForViewController(page))) return null
        if (delegate?.tabBarController_shouldSelectViewController(this, page) == false) return null
        return page
    }

    /** [EN] Shows a page that has no view yet (a detached tab) under the selected one, for a swipe. [CN] 为滑动显示一个还没有视图的页面（被分离的 Tab）。 */
    internal fun cyl_showPageForSwipe(page: Fragment): View? {
        if (!pagesContainer.isAttachedToWindow || fragmentManager.isDestroyed || fragmentManager.isStateSaved) return null
        val transaction = fragmentManager.beginTransaction()
        if (page.isDetached) transaction.attach(page)
        transaction.show(page).commitNowAllowingStateLoss()
        return page.view
    }

    internal fun cyl_hidePageAfterSwipe(page: Fragment) {
        if (fragmentManager.isDestroyed || fragmentManager.isStateSaved) return
        fragmentManager.beginTransaction().hide(page).commitNowAllowingStateLoss()
    }

    /** [EN] Selects the tab a swipe ended on: the pages are already in place, so no transition runs. [CN] 选中滑动结束时的 Tab：页面已就位，不再运行转场。 */
    internal fun cyl_selectIndexFromSwipe(index: Int) {
        val page = viewControllers.getOrNull(index) ?: return
        revertingTransition = true
        selectedIndex = index
        revertingTransition = false
        delegate?.tabBarController_didSelectViewController(this, page)
        tabBar.cyl_tabBarButtonWithTabIndex(index)?.let { delegate?.tabBarController_didSelectControl(this, it) }
    }

    internal fun cyl_plusButtonTapped(plusButton: CYLPlusButton) {
        val provider = plusButton.provider ?: CYLPlusButton.providerForTabBarContext(context) ?: return
        val child = provider.plusChildViewController()
        if (child != null && provider.shouldSelectPlusChildViewController() && pagesContainer.isAttachedToWindow) {
            val transaction = fragmentManager.beginTransaction()
            if (!child.isAdded) transaction.add(pagesContainer.id, child, "$fragmentTag-plus")
            for (page in viewControllers) if (page.isAdded) transaction.hide(page)
            transaction.show(child).commitNowAllowingStateLoss()
            plusButton.cyl_plusViewControllerEverAdded = true
            tabBar.plusButtonActive = true
            tabBar.refreshSelection()
            cyl_applyNavigationTitleOfSelectedPage()
            // [EN] The tab selected before goes back to its unselected look, its animation too, as on iOS, where the system
            //      deselects the tab when the plus button's page is selected. Before, its animation kept the selected frame
            //      until another tab was selected.
            // [CN] 之前选中的 Tab 恢复未选中外观（包括其动画），与 iOS 相同：选中 PlusButton 的页面时系统会取消该 Tab 的选中。此前其动画一直停在选中帧，
            //      直到选中另一个 Tab。
            cyl_playSelectedTabBarItemAnimation(defaultSelected = false)
            delegate?.tabBarController_didSelectViewController(this, child)
        }
        cyl_playTabButtonAnimationForControl(plusButton)
        cyl_playTabButtonTapFeedback()
        delegate?.tabBarController_didSelectControl(this, plusButton)
    }

    // MARK: - hasPlusButton...

    fun hasPlusButton(): Boolean = tabBar.hasPlusButton()
    fun hasPlusChildViewController(): Boolean = tabBar.hasPlusChildViewController()
    /** [EN] `-allItemsInTabBarCount`: the tabs plus the plus button. [CN] Tab 数加 PlusButton。 */
    fun allItemsInTabBarCount(): Int = viewControllers.size + (if (hasPlusButton()) 1 else 0)
    /** [EN] `-visiableTabBarSize`: the tab bar size in dp. [CN] TabBar 尺寸（dp）。 */
    fun visiableTabBarSize(): CYLSize = CYLSize(tabBar.width / density, tabBar.height / density)
    private val density get() = activity.resources.displayMetrics.density

    // MARK: - Updates (#601, #481) 更新

    /** [EN] `-reloadTabBarItemsWithAttributes:`: new attributes for the same pages, or, when created from page IDs, new tabs resolved by ID (pages of kept IDs reused). [CN] 相同页面的新属性；由页面 ID 创建时按 ID 解析新 Tab（已有页面复用）。 */
    fun reloadTabBarItemsWithAttributes(tabBarItemsAttributes: List<Map<String, Any?>>) {
        if (pagesFromPageIdentifiers) {
            val normalized = CYLTabBarConfiguration.cyl_normalizedConfiguration(mapOf(CYLConstants.CYLTabBarControllerTabBarItemsAttributes to tabBarItemsAttributes))
            @Suppress("UNCHECKED_CAST")
            val items = (normalized[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] as? List<Map<String, Any?>>)?.filter { it.isNotEmpty() && it[CYLTabBarConfiguration.EXCLUDED_KEY] != true } ?: emptyList()
            val skipped = ArrayList<CYLTabBarSkippedTab>()
            val kept = ArrayList<Map<String, Any?>>()
            val pages = CYLTabBarPageRegistry.pagesOfTabs(items, cyl_pageRegistry, cyl_pageResolver, cyl_pageLookupOrder, kept, skipped, pagesByPageIdentifier)
            cyl_skippedTabs = skipped
            setViewControllers(pages, kept)
            cyl_adoptPendingPages()
            return
        }
        setViewControllers(viewControllers, tabBarItemsAttributes)
    }

    /** [EN] `-updateTabBarItemAtIndex:attributes:` (#601): one tab's title / icons in place. [CN] 原地更新一个 Tab（#601）。 */
    fun updateTabBarItemAtIndex(index: Int, attributes: Map<String, Any?>) {
        val current = tabBarItemsAttributes.getOrNull(index) ?: return
        val previous = tabBarItemsAttributes
        val merged = ArrayList(tabBarItemsAttributes)
        merged[index] = current + attributes
        setViewControllers(viewControllers, merged)
        cyl_postTabBarItemChanges(previous, tabBarItemsAttributes)
    }

    // MARK: - Tab change notifications (as on iOS) Tab 变化通知（与 iOS 相同）

    /**
     * [EN] Posts `name` about the tab at `index`, as iOS does: object is the tab's page; userInfo holds the controller, the
     *      index, the page, the tab's identifier and item, plus `extra`. The plus button's page has the index
     *      `viewControllers.size` (see `-cyl_tabIndexOfControl:`).
     * [CN] 与 iOS 相同地发送关于下标为 `index` 的 Tab 的通知 `name`：object 为该 Tab 的页面；userInfo 包含控制器、下标、页面、Tab 的标识与 item，
     *      以及 `extra`。PlusButton 的页面下标为 `viewControllers.size`（见 `-cyl_tabIndexOfControl:`）。
     */
    private fun cyl_postTabBarItemNotification(name: String, index: Int, page: Any?, extra: Map<String, Any?>) {
        val userInfo = LinkedHashMap<String, Any?>()
        userInfo[CYLConstants.CYLTabBarControllerKey] = this
        userInfo[CYLConstants.CYLTabBarItemIndexKey] = index
        (page as? Fragment)?.let { userInfo[CYLConstants.CYLTabBarItemViewControllerKey] = it }
        tabBarItems.getOrNull(index)?.let { item ->
            userInfo[CYLConstants.CYLTabBarItemKey] = item
            item.cyl_tabBarItemIdentifier?.let { userInfo[CYLConstants.CYLTabBarItemIdentifier] = it }
        }
        userInfo.putAll(extra)
        CYLNotificationCenter.post(name, page, userInfo)
    }

    /**
     * [EN] Compares each tab's attributes before and after an in-place change and, for every tab that changed, posts
     *      `CYLTabBarItemTitleDidChangeNotification` (title or selected title), `CYLTabBarItemIconDidChangeNotification`
     *      (image keys) and `CYLTabBarItemDidChangeNotification`, in this order, with the changed attributes. A skin replaces
     *      every tab's attributes at once on Android, so each tab is compared, not only the ones an update named.
     * [CN] 比较每个 Tab 在原地变化前后的属性，对每个有变化的 Tab 依次发送 `CYLTabBarItemTitleDidChangeNotification`（标题或选中标题）、
     *      `CYLTabBarItemIconDidChangeNotification`（图片 key）与 `CYLTabBarItemDidChangeNotification`，并附上变化的属性。Android 上皮肤一次替换所有 Tab
     *      的属性，因此逐个比较所有 Tab，而不只是更新时指定的 Tab。
     */
    private fun cyl_postTabBarItemChanges(previous: List<Map<String, Any?>>, current: List<Map<String, Any?>>) {
        if (previous.size != current.size) return
        for (index in current.indices) {
            val old = previous[index]
            val new = current[index]
            val changed = (old.keys + new.keys).filter { old[it] != new[it] }.associateWith { new[it] }
            if (changed.isEmpty()) continue
            val page = viewControllers.getOrNull(index)
            val base = mapOf(CYLConstants.CYLTabBarItemChangedAttributesKey to changed)
            if (CYLConstants.CYLTabBarItemTitle in changed || CYLConstants.CYLTabBarItemSelectedTitle in changed) {
                cyl_postTabBarItemNotification(CYLConstants.CYLTabBarItemTitleDidChangeNotification, index, page, base + mapOf(
                    CYLConstants.CYLTabBarItemTitle to new[CYLConstants.CYLTabBarItemTitle],
                    CYLConstants.CYLTabBarItemSelectedTitle to new[CYLConstants.CYLTabBarItemSelectedTitle],
                    CYLConstants.CYLTabBarItemOldTitleKey to old[CYLConstants.CYLTabBarItemTitle]))
            }
            if (changed.keys.any { it in ICON_ATTRIBUTE_KEYS }) {
                cyl_postTabBarItemNotification(CYLConstants.CYLTabBarItemIconDidChangeNotification, index, page, base)
            }
            cyl_postTabBarItemNotification(CYLConstants.CYLTabBarItemDidChangeNotification, index, page, base)
        }
    }

    fun updateTabBarItemForViewController(viewController: Fragment, attributes: Map<String, Any?>) {
        val index = viewControllers.indexOf(viewController)
        if (index >= 0) updateTabBarItemAtIndex(index, attributes)
    }

    fun updateTabBarItemsWithAttributes(attributes: List<Map<String, Any?>>) = reloadTabBarItemsWithAttributes(attributes)

    fun tabBarItemAttributesAtIndex(index: Int): Map<String, Any?>? = tabBarItemsAttributes.getOrNull(index)

    /** [EN] `-setTabBarItemIcon:selectedIcon:size:atIndex:`. [CN] 设置图标。 */
    fun setTabBarItemIcon(icon: android.graphics.drawable.Drawable?, selectedIcon: android.graphics.drawable.Drawable?, size: CYLSize?, index: Int) {
        val item = tabBarItems.getOrNull(index) ?: return
        if (icon == null && selectedIcon == null) return
        item.image = icon ?: item.image
        item.selectedImage = selectedIcon ?: icon ?: item.selectedImage
        size?.let { item.cyl_iconSize = it }
        tabBar.refreshSelection()
        cyl_postTabBarItemNotification(CYLConstants.CYLTabBarItemIconDidChangeNotification, index, viewControllers.getOrNull(index), emptyMap())
    }

    /** [EN] `-setTabBarItemIconWithURL:selectedURL:size:atIndex:`: downloads on a background thread. [CN] 后台线程下载图标。 */
    fun setTabBarItemIconWithURL(url: String, selectedURL: String?, size: CYLSize?, index: Int) {
        // [EN] One queue for every tab bar, so a URL is downloaded once and then read from the cache (as iOS `+cyl_loadImageWithURL:`).
        // [CN] 所有 TabBar 共用一个队列，同一 URL 只下载一次，之后读取缓存（与 iOS 的 `+cyl_loadImageWithURL:` 一致）。
        iconLoader.execute {
            val icon = loadDrawable(url)
            val selected = selectedURL?.let { loadDrawable(it) }
            Handler(Looper.getMainLooper()).post { setTabBarItemIcon(icon, selected, size, index) }
        }
    }

    /**
     * [EN] An icon from a URL, a path, an asset name or a resolver name. A GIF loops (`CYLGIFDrawable`), as a GIF image does
     *      on iOS (#605).
     * [CN] 来自 URL、路径、asset 名称或解析器名称的图标。GIF 循环播放（`CYLGIFDrawable`），与 iOS 的 GIF 图片一致（#605）。
     */
    private fun loadDrawable(url: String): android.graphics.drawable.Drawable? {
        iconCache.get(url)?.let { return it.newDrawable(activity.resources) }
        val drawable = decodeDrawable(url) ?: return null
        // [EN] A looping GIF is not shared (it keeps its own clock). [CN] 循环的 GIF 不共用（它有自己的时钟）。
        if (drawable !is CYLGIFDrawable) drawable.constantState?.let { iconCache.put(url, it) }
        return drawable
    }

    private fun decodeDrawable(url: String): android.graphics.drawable.Drawable? = try {
        val bytes = when {
            url.startsWith("http") -> java.net.URI(url).toURL().openStream().use { it.readBytes() }
            else -> CYLTabBarItemAnimationFiles.openLocal(activity, url)?.use { it.readBytes() }
        }
        when (bytes) {
            null -> CYLTabBarConfiguration.imageResolver.drawable(activity, url)
            // [EN] A GIF that cannot be decoded as a movie shows its first frame. [CN] 无法按动画解码的 GIF 显示其第一帧。
            else -> (if (CYLGIFDrawable.isGIF(bytes)) CYLGIFDrawable.fromBytes(bytes) else null)
                ?: android.graphics.drawable.BitmapDrawable(activity.resources, android.graphics.BitmapFactory.decodeByteArray(bytes, 0, bytes.size))
        }
    } catch (error: Exception) { null }

    /**
     * [EN] `-setTabBarItemIconViewProvider:atIndex:`: the tab shows `provider(selected)` in place of its icon, asked again when
     *      its selection changes; null shows the icon again.
     * [CN] Tab 用 `provider(selected)` 代替图标，选中状态变化时再次询问；null 恢复图标。
     */
    fun setTabBarItemIconViewProvider(provider: CYLTabBarItemIconViewProvider?, index: Int) {
        val button = tabBar.cyl_tabBarButtonWithTabIndex(index) ?: return
        button.cyl_iconViewProvider = provider
        button.cyl_applyIconViewProvider()
        cyl_postTabBarItemNotification(CYLConstants.CYLTabBarItemIconDidChangeNotification, index, viewControllers.getOrNull(index),
            mapOf(CYLConstants.CYLTabBarItemIconViewProviderKey to provider))
    }

    fun updatePlusButtonWithAttributes(attributes: Map<String, Any?>) {
        val plus = tabBar.plusButton ?: return
        val oldTitle = plus.cyl_title
        plus.cyl_updateTitle(attributes[CYLConstants.CYLTabBarItemTitle] as? String,
            (attributes[CYLConstants.CYLTabBarItemImage] as? String)?.let { CYLTabBarConfiguration.imageResolver.drawable(activity, it) },
            (attributes[CYLConstants.CYLTabBarItemSelectedImage] as? String)?.let { CYLTabBarConfiguration.imageResolver.drawable(activity, it) })
        cyl_applyNavigationTitleOfSelectedPage()
        // [EN] As on iOS: object is the plus button's page, or the plus button when it has none. [CN] 与 iOS 相同：object 为 PlusButton 的页面，没有页面时为 PlusButton。
        val plusChild = plus.provider?.plusChildViewController()
        val base = mapOf(CYLConstants.CYLTabBarItemChangedAttributesKey to attributes, CYLConstants.CYLPlusButtonKey to plus)
        val post = { name: String, extra: Map<String, Any?> ->
            cyl_postTabBarItemNotification(name, if (plusChild != null) viewControllers.size else -1, plusChild ?: plus, base + extra)
        }
        if (attributes.containsKey(CYLConstants.CYLTabBarItemTitle) && plus.cyl_title != oldTitle) {
            post(CYLConstants.CYLTabBarItemTitleDidChangeNotification, mapOf(
                CYLConstants.CYLTabBarItemTitle to plus.cyl_title, CYLConstants.CYLTabBarItemOldTitleKey to oldTitle))
        }
        if (attributes.keys.any { it in ICON_ATTRIBUTE_KEYS }) post(CYLConstants.CYLTabBarItemIconDidChangeNotification, emptyMap())
        post(CYLConstants.CYLTabBarItemDidChangeNotification, emptyMap())
    }

    /** [EN] `-replaceViewControllerAtIndex:withViewController:attributes:` (#481). [CN] 替换页面（#481）。 */
    fun replaceViewControllerAtIndex(index: Int, viewController: Fragment, attributes: Map<String, Any?>?) {
        if (index !in viewControllers.indices) return
        val pages = ArrayList(viewControllers); pages[index] = viewController
        val items = ArrayList(tabBarItemsAttributes); if (attributes != null && index < items.size) items[index] = attributes
        setViewControllers(pages, items)
    }

    /**
     * [EN] `-performWhenTabBarItemsReady:`: runs `block` once the tab buttons are laid out (now when they are), e.g. to
     *      show badges on them.
     * [CN] Tab 按钮布局完成后执行 `block`（已布局时立即执行），例如在按钮上显示角标。
     */
    fun performWhenTabBarItemsReady(block: (CYLTabBarController) -> Unit) {
        val ready = tabBar.isLaidOut && tabBar.tabBarButtonArray.all { it.width > 0 }
        if (ready) return block(this)
        tabBar.viewTreeObserver.addOnGlobalLayoutListener(object : android.view.ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                if (tabBar.tabBarButtonArray.any { it.width == 0 }) return
                tabBar.viewTreeObserver.removeOnGlobalLayoutListener(this)
                block(this@CYLTabBarController)
            }
        })
    }
    /** [EN] `-reloadBadgesWithBlock:`: `block` sets the badges once the tab buttons are ready. [CN] Tab 按钮就绪后由 `block` 设置角标。 */
    fun reloadBadgesWithBlock(block: (CYLTabBarController) -> Unit) = performWhenTabBarItemsReady(block)
    fun setViewDidLayoutSubViewsBlock(block: ((CYLTabBarController) -> Unit)?) { viewDidLayoutSubviewsBlock = block }
    fun setViewDidLayoutSubViewsBlockInvokeOnce(once: Boolean, block: ((CYLTabBarController) -> Unit)?) {
        viewDidLayoutSubviewsBlock = if (once && block != null) { controller -> block(controller); viewDidLayoutSubviewsBlock = null } else block
    }
    fun updateImageInsets(insets: CYLEdgeInsets) { imageInsets = insets }
    fun hideTabBarShadowImageView() { tabBar.cyl_shadowColor = null; tabBar.refreshSelection() }
    fun setTintColor(@ColorInt color: Int) { tabBar.selectedTintColor = color; tabBar.refreshSelection() }
    /**
     * [EN] `-unloadViewsOfUnselectedViewControllers` (#426): detaches the tabs that are not selected, which destroys their
     *      views (the page instances are kept); a detached tab creates its view again (`onCreateView`, the iOS
     *      `-viewDidLoad`) when it is selected. Tabs for which `shouldUnloadViewOfViewController` returns false are kept.
     * [CN] 分离未选中的 Tab（#426），销毁其视图（保留页面实例）；被分离的 Tab 在选中时重新创建视图（`onCreateView`，即 iOS 的 `-viewDidLoad`）。
     *      `shouldUnloadViewOfViewController` 返回 false 的 Tab 保留。
     */
    fun unloadViewsOfUnselectedViewControllers() {
        // [EN] A pager (`cyl_setupWithViewPager2`) keeps its own pages. [CN] 翻页控件（`cyl_setupWithViewPager2`）自己管理页面。
        if (fragmentManager.isDestroyed || fragmentManager.isStateSaved || cyl_pagesHost != null) return
        val transaction = fragmentManager.beginTransaction()
        var changed = false
        viewControllers.forEachIndexed { index, page ->
            if (index != selectedIndex && page.isAdded && !page.isDetached && page.view != null && shouldUnloadViewOfViewController(page)) {
                transaction.detach(page)
                changed = true
            }
        }
        if (changed) transaction.commitNowAllowingStateLoss()
    }
    /** [EN] `-shouldUnloadViewOfViewController:`: whether a tab may be unloaded; override it to keep some tabs. [CN] Tab 是否可以卸载；重写以保留部分 Tab。 */
    open fun shouldUnloadViewOfViewController(viewController: Fragment): Boolean = true

    /** [EN] A memory warning (`onTrimMemory` / `onLowMemory`): unloads when `unloadsUnselectedViewsOnMemoryWarning`. [CN] 内存警告：`unloadsUnselectedViewsOnMemoryWarning` 时卸载。 */
    internal fun cyl_didReceiveMemoryWarning() {
        cyl_restoreTabBarHiddenByScroll()
        if (unloadsUnselectedViewsOnMemoryWarning) unloadViewsOfUnselectedViewControllers()
    }

    private val memoryCallbacks: android.content.ComponentCallbacks2 = object : android.content.ComponentCallbacks2 {
        override fun onTrimMemory(level: Int) {
            @Suppress("DEPRECATION")
            if (level >= android.content.ComponentCallbacks2.TRIM_MEMORY_RUNNING_LOW) cyl_didReceiveMemoryWarning()
        }
        override fun onConfigurationChanged(newConfig: android.content.res.Configuration) { /* [EN] Not a memory warning. [CN] 不是内存警告。 */ }
        @Deprecated("Deprecated in Java")
        override fun onLowMemory() = cyl_didReceiveMemoryWarning()
    }.also { activity.registerComponentCallbacks(it) }

    // MARK: - CYLTabBarItemIdentifier 标识

    val cyl_tabBarItemIdentifiers: List<String> get() = tabBarItems.mapIndexed { index, item -> item.cyl_tabBarItemIdentifier ?: cyl_defaultTabBarItemIdentifierForViewController(viewControllers[index]) }
    val cyl_selectedTabBarItemIdentifier: String? get() = cyl_tabBarItemIdentifiers.getOrNull(selectedIndex)
    fun cyl_indexOfTabBarItemIdentifier(identifier: String): Int = cyl_tabBarItemIdentifiers.indexOf(identifier)
    fun cyl_viewControllerWithTabBarItemIdentifier(identifier: String): Fragment? = viewControllers.getOrNull(cyl_indexOfTabBarItemIdentifier(identifier))
    fun cyl_controlWithTabBarItemIdentifier(identifier: String): View? = tabBar.cyl_tabBarButtonWithTabIndex(cyl_indexOfTabBarItemIdentifier(identifier))
    /** [EN] `-cyl_selectTabBarItemWithIdentifier:`: true when the tab exists (the delegate and login are asked, like a tap). [CN] Tab 存在时返回 true（像点击一样询问代理与登录）。 */
    fun cyl_selectTabBarItemWithIdentifier(identifier: String): Boolean {
        val index = cyl_indexOfTabBarItemIdentifier(identifier)
        val button = tabBar.cyl_tabBarButtonWithTabIndex(index) ?: return false
        cyl_tabButtonTapped(button)
        return true
    }
    fun cyl_defaultTabBarItemIdentifierForViewController(viewController: Fragment): String = cyl_defaultTabBarItemIdentifierForClass(viewController.javaClass)

    // MARK: - CYLLogin (#19) 登录

    /**
     * [EN] Whether the user is logged in: `cyl_loginStateProvider` when set, else the cached value. As iOS (NSUserDefaults), the
     *      cached value is kept across launches, in the app's SharedPreferences.
     * [CN] 用户是否已登录：设置了 `cyl_loginStateProvider` 时用它，否则为缓存值。与 iOS（NSUserDefaults）相同，缓存值保存在 App 的 SharedPreferences 中，重启后保留。
     */
    var cyl_loggedIn: Boolean
        get() = cyl_loginStateProvider?.invoke() ?: loginPreferences().getBoolean(LOGGED_IN_KEY, false)
        set(value) {
            loginPreferences().edit().putBoolean(LOGGED_IN_KEY, value).apply()
            // [EN] As iOS: logging out while a tab that needs login is selected selects the first tab that does not.
            // [CN] 与 iOS 相同：选中需要登录的 Tab 时退出登录，会选中第一个不需要登录的 Tab。
            if (value) return
            fun requiresLogin(page: Fragment) = delegate?.tabBarController_requiresLoginToSelectViewController(this, page) ?: cyl_isLoginRequiredForViewController(page)
            val selected = viewControllers.getOrNull(selectedIndex) ?: return
            if (!requiresLogin(selected)) return
            viewControllers.indexOfFirst { !requiresLogin(it) }.takeIf { it >= 0 }?.let { selectedIndex = it }
        }
    private fun loginPreferences() = activity.getSharedPreferences(LOGIN_PREFERENCES, android.content.Context.MODE_PRIVATE)
    /** [EN] `cyl_loginStateProvider`: your app's own login state. [CN] App 自己的登录状态。 */
    var cyl_loginStateProvider: (() -> Boolean)? = null
    /** [EN] `cyl_loginHandler`: shows the login screen, then calls the completion with the result (`cyl_presentLoginBlock`). [CN] 展示登录界面，然后用结果调用 completion（即 `cyl_presentLoginBlock`）。 */
    var cyl_loginHandler: ((CYLTabBarController, Fragment, CYLTabBarLoginCompletion) -> Unit)?
        get() = cyl_presentLoginBlock
        set(value) { cyl_presentLoginBlock = value }
    var cyl_loginRequiredTabBarItemIdentifiers: List<String> = emptyList()
    var cyl_loginRequiredBlock: ((CYLTabBarController, Fragment) -> Boolean)? = null
    var cyl_presentLoginBlock: ((CYLTabBarController, Fragment, CYLTabBarLoginCompletion) -> Unit)? = null

    fun cyl_isLoginRequiredForViewController(viewController: Fragment): Boolean {
        cyl_loginRequiredBlock?.let { return it(this, viewController) }
        val index = viewControllers.indexOf(viewController)
        val identifier = cyl_tabBarItemIdentifiers.getOrNull(index) ?: return false
        return identifier in cyl_loginRequiredTabBarItemIdentifiers
    }

    /** [EN] `-cyl_interceptLoginIfNeededForViewController:`: true when the selection was intercepted (login is presented; `completion` continues it). [CN] 被拦截时返回 true（展示登录；`completion` 继续选中）。 */
    fun cyl_interceptLoginIfNeededForViewController(viewController: Fragment, completion: (Boolean) -> Unit = {}): Boolean {
        if (cyl_loggedIn) return false
        val required = delegate?.tabBarController_requiresLoginToSelectViewController(this, viewController) ?: cyl_isLoginRequiredForViewController(viewController)
        if (!required) return false
        val finish: (Boolean) -> Unit = { loggedIn -> if (loggedIn) cyl_loggedIn = true; completion(loggedIn) }
        cyl_presentLoginBlock?.let { it(this, viewController, finish); return true }
        delegate?.tabBarController_presentLoginForViewController(this, viewController, finish)
        return true
    }

    // MARK: - CYLTabBarItemGesture (#535) 手势

    var cyl_tabBarItemGestureHandler: CYLTabBarItemGestureHandler? = null
    var cyl_tabBarItemDoubleTapInterval: Double = 0.3
        set(value) { field = value; tabBar.tabBarButtonArray.forEach { it.doubleTapInterval = value } }
    var cyl_tabBarItemLongPressDuration: Double = 0.5
        set(value) { field = value; tabBar.tabBarButtonArray.forEach { it.longPressDuration = value } }

    // MARK: - CYLSelectedIndexIgnoringPlusButton (#515)

    val cyl_viewControllersIgnoringPlusButton: List<Fragment> get() = viewControllers
    var cyl_selectedIndexIgnoringPlusButton: Int
        get() = selectedIndex
        set(value) { selectedIndex = value }
    fun cyl_selectedIndexForIndexIgnoringPlusButton(index: Int): Int = index

    // MARK: - CYLTabBarItemStyle (#773)

    var cyl_tabBarItemTitleFont: CYLFont? = null
        set(value) { field = value; tabBar.refreshSelection() }
    var cyl_tabBarItemSelectedTitleFont: CYLFont? = null
        set(value) { field = value; tabBar.refreshSelection() }
    @ColorInt var cyl_tabBarItemTitleColor: Int? = null
        set(value) { field = value; tabBar.refreshSelection() }
    @ColorInt var cyl_tabBarItemSelectedTitleColor: Int? = null
        set(value) { field = value; tabBar.refreshSelection() }
    @ColorInt var cyl_tabBarItemImageColor: Int? = null
        set(value) { field = value; tabBar.refreshSelection() }
    @ColorInt var cyl_tabBarItemSelectedImageColor: Int? = null
        set(value) { field = value; tabBar.refreshSelection() }
    @ColorInt var cyl_tabBarBackgroundColor: Int? = null
        set(value) { field = value; tabBar.styleRenderer.applyBackgroundColor(tabBar, value) }
    @ColorInt var cyl_tabBarShadowColor: Int? = 0x33000000
        set(value) { field = value; tabBar.cyl_shadowColor = value; tabBar.refreshSelection() }
    var cyl_fixesOpaqueTabBarSafeAreaInsets: Boolean = true

    // MARK: - CYLReselect / CYLSelectedTabBadge / CYLCustomTabAction

    var cyl_reselectBehavior: CYLEnums.CYLTabBarReselectBehavior = CYLEnums.CYLTabBarReselectBehavior.None
    /** [EN] What a reselect does: pop the page's back stack and / or scroll its scrolling view to the top. [CN] 重复点击：弹出返回栈 / 滚动到顶部。 */
    private fun cyl_performReselectBehavior(page: Fragment) {
        val behavior = cyl_reselectBehavior
        if (behavior == CYLEnums.CYLTabBarReselectBehavior.PopToRoot || behavior == CYLEnums.CYLTabBarReselectBehavior.PopToRootThenScrollToTop) {
            page.childFragmentManager.popBackStack(null, FragmentManager.POP_BACK_STACK_INCLUSIVE)
        }
        if (behavior == CYLEnums.CYLTabBarReselectBehavior.ScrollToTop || behavior == CYLEnums.CYLTabBarReselectBehavior.PopToRootThenScrollToTop) {
            findScrollingView(page.view)?.let { scrolling -> if (scrolling is androidx.core.view.ScrollingView) (scrolling as View).scrollTo(0, 0) else scrolling.scrollTo(0, 0) }
        }
    }
    private fun findScrollingView(view: View?): View? {
        if (view == null) return null
        if (view is androidx.core.view.ScrollingView || view is android.widget.ScrollView || view is android.widget.AbsListView) return view
        if (view is ViewGroup) for (i in 0 until view.childCount) findScrollingView(view.getChildAt(i))?.let { return it }
        return null
    }

    var cyl_hidesBadgeOfSelectedTab: Boolean = false
        set(value) { field = value; showSelectedPage() }

    var cyl_customActionTabBarItemIdentifiers: List<String> = emptyList()
    var cyl_customActionBlock: ((CYLTabBarController, Fragment) -> Unit)? = null
    var cyl_customActionShouldPerformBlock: ((CYLTabBarController, Fragment) -> Boolean)? = null
    /** [EN] `cyl_shouldPerformCustomTabActionHandler`: whether a tab runs an action instead of being selected. [CN] Tab 是否执行动作而不是被选中。 */
    var cyl_shouldPerformCustomTabActionHandler: ((CYLTabBarController, Fragment) -> Boolean)?
        get() = cyl_customActionShouldPerformBlock
        set(value) { cyl_customActionShouldPerformBlock = value }
    /** [EN] `cyl_customTabActionHandler`: the action of such a tab. [CN] 这类 Tab 的动作。 */
    var cyl_customTabActionHandler: ((CYLTabBarController, Fragment) -> Unit)?
        get() = cyl_customActionBlock
        set(value) { cyl_customActionBlock = value }
    fun cyl_isCustomActionTabViewController(viewController: Fragment): Boolean {
        cyl_customActionShouldPerformBlock?.let { return it(this, viewController) }
        val identifier = cyl_tabBarItemIdentifiers.getOrNull(viewControllers.indexOf(viewController)) ?: return false
        return identifier in cyl_customActionTabBarItemIdentifiers
    }
    fun cyl_performCustomTabActionIfNeededForViewController(viewController: Fragment): Boolean {
        if (!cyl_isCustomActionTabViewController(viewController)) return false
        cyl_customActionBlock?.invoke(this, viewController) ?: delegate?.tabBarController_performCustomActionForViewController(this, viewController)
        return true
    }

    // MARK: - CYLInteraction (#535) 交互

    /** [EN] The built-in tap animation; `cyl_defaultTabButtonAnimation` and the page's `cyl_tabButtonAnimation` take precedence. [CN] 内置点击动画；`cyl_defaultTabButtonAnimation` 与页面的 `cyl_tabButtonAnimation` 优先。 */
    var cyl_tabButtonTapAnimationType: CYLEnums.CYLTabButtonTapAnimationType = CYLEnums.CYLTabButtonTapAnimationType.None
        set(value) { field = value; animationForTapAnimationType = CYLTabButtonAnimationForType(value) }
    private var animationForTapAnimationType: CYLTabButtonAnimation? = null
    /** [EN] `cyl_defaultTabButtonAnimation`: an animation object for every tab button and the plus button. [CN] 所有 Tab 按钮与 PlusButton 的动画对象。 */
    var cyl_defaultTabButtonAnimation: CYLTabButtonAnimation? = null
    var cyl_tabButtonTapSoundEnabled: Boolean = false
    /**
     * [EN] `cyl_tabButtonTapSoundURL`: the sound of a tap (a file, `content:`, `android.resource:` or asset URI); null, or a
     *      sound that cannot be played: the system click. The player is created once and released when it changes.
     * [CN] 点击音效（文件、`content:`、`android.resource:` 或 asset URI）；null 或无法播放时使用系统点击声。播放器只创建一次，更换时释放。
     */
    var cyl_tabButtonTapSoundURL: android.net.Uri? = null
        set(value) {
            field = value
            tapSoundPlayer?.release()
            tapSoundPlayer = value?.let { uri -> try { android.media.MediaPlayer.create(activity, uri) } catch (error: RuntimeException) { null } }
        }
    private var tapSoundPlayer: android.media.MediaPlayer? = null
    var cyl_tabButtonHapticFeedbackEnabled: Boolean = false
    var cyl_tabButtonHapticFeedbackStyle: CYLEnums.CYLImpactFeedbackStyle = CYLEnums.CYLImpactFeedbackStyle.Light
    var cyl_didLongPressControlBlock: CYLTabBarControllerDidLongPressControlBlock? = null
    var cyl_tabButtonLongPressMinimumDuration: Double
        get() = cyl_tabBarItemLongPressDuration
        set(value) { cyl_tabBarItemLongPressDuration = value }
    var cyl_swipeToSwitchTabEnabled: Boolean = false

    private fun iconViewOf(control: View): View = when (control) {
        is CYLTabBarItemButton -> control.iconView
        is CYLPlusButton -> control.imageView
        else -> control
    }

    private fun titleLabelOf(control: View): android.widget.TextView? = when (control) {
        is CYLTabBarItemButton -> control.titleLabel.takeIf { it.text.isNotEmpty() }
        is CYLPlusButton -> control.titleLabel.takeIf { it.text.isNotEmpty() }
        else -> null
    }

    /** [EN] The page index of a tab button, or of the plus button when it has a child page; -1 otherwise. [CN] Tab 按钮的页面下标，或有子页面的 PlusButton；否则为 -1。 */
    private fun viewControllerIndexForTabControl(control: View?): Int = when (control) {
        is CYLTabBarItemButton -> control.index.takeIf { it in viewControllers.indices } ?: -1
        is CYLPlusButton -> if (control.provider?.plusChildViewController() != null) viewControllers.size else -1
        else -> -1
    }

    /** [EN] The animation of `control`: its page's `cyl_tabButtonAnimation`, else `cyl_defaultTabButtonAnimation`, else the type's. [CN] `control` 的动画：页面的 `cyl_tabButtonAnimation`，否则 `cyl_defaultTabButtonAnimation`，否则类型对应的动画。 */
    private fun animationForTabControl(control: View): CYLTabButtonAnimation? {
        val page = when (control) {
            is CYLTabBarItemButton -> viewControllers.getOrNull(control.index)
            is CYLPlusButton -> control.provider?.plusChildViewController()
            else -> null
        }
        return page?.cyl_tabButtonAnimation ?: cyl_defaultTabButtonAnimation ?: animationForTapAnimationType
    }

    private var previousAnimatedControl: java.lang.ref.WeakReference<View>? = null
    private val lastSelectAnimations = java.util.WeakHashMap<View, CYLTabButtonAnimation>()

    /** [EN] When `control`'s last select animation is not `animation`, lets it undo what it left on the button. [CN] `control` 上次的选中动画不是 `animation` 时，让它撤销留在按钮上的状态。 */
    private fun resetAnimationIfReplaced(control: View, animation: CYLTabButtonAnimation?) {
        val last = lastSelectAnimations[control] ?: return
        if (last === animation) return
        if (last.cyl_respondsToSelector("cyl_resetTabButton")) last.cyl_resetTabButton(control, iconViewOf(control), titleLabelOf(control))
        lastSelectAnimations.remove(control)
    }

    /**
     * [EN] `-cyl_playTabButtonAnimationForControl:`: the button selected before plays its deselect animation, then this one
     *      plays its select animation (or its reselect animation on a tap of the selected tab), as on iOS.
     * [CN] 之前选中的按钮播放取消选中动画，然后本按钮播放选中动画（再次点击已选中的 Tab 时播放重选动画），与 iOS 一致。
     */
    fun cyl_playTabButtonAnimationForControl(control: View) {
        val previous = previousAnimatedControl?.get()
        if (previous != null && previous !== control) resetAnimationIfReplaced(previous, animationForTabControl(previous))
        val index = viewControllerIndexForTabControl(control)
        val previousIndex = viewControllerIndexForTabControl(previous)
        val hasIndexes = index >= 0 && previousIndex >= 0
        if (previous != null && previous !== control) playDeselectAnimation(previous, if (hasIndexes) previousIndex < index else null)
        // [EN] A plus button without a child page selects nothing: it is not recorded. [CN] 没有子页面的 PlusButton 不选中任何页面：不记录。
        if (!(control is CYLPlusButton && index < 0)) previousAnimatedControl = java.lang.ref.WeakReference(control)
        val animation = animationForTabControl(control)
        resetAnimationIfReplaced(control, animation)
        animation ?: return
        lastSelectAnimations[control] = animation
        val isReselect = previous === control && index >= 0 && (index == selectedIndex || control is CYLPlusButton)
        if (isReselect && animation.cyl_implements(CYLTabButtonAnimationStep.Reselect)) {
            animation.cyl_play(CYLTabButtonAnimationStep.Reselect, control, iconViewOf(control), titleLabelOf(control))
            return
        }
        if (hasIndexes && animation.cyl_respondsToSelector("cyl_setFromLeft")) animation.cyl_setFromLeft(previousIndex < index)
        animation.cyl_play(CYLTabButtonAnimationStep.Select, control, iconViewOf(control), titleLabelOf(control))
    }

    /** [EN] The deselect step of the previous tab; `toRight` when both tabs have an index. [CN] 上一个 Tab 的取消选中动画；两个 Tab 都有下标时传入 `toRight`。 */
    private fun playDeselectAnimation(previous: View, toRight: Boolean?) {
        val animation = animationForTabControl(previous) ?: return
        if (!animation.cyl_implements(CYLTabButtonAnimationStep.Deselect)) return
        if (toRight != null && animation.cyl_respondsToSelector("cyl_setToRight")) animation.cyl_setToRight(toRight)
        animation.cyl_play(CYLTabButtonAnimationStep.Deselect, previous, iconViewOf(previous), titleLabelOf(previous))
    }

    private var highlightedControl: java.lang.ref.WeakReference<View>? = null

    /** [EN] Plays the highlight (finger down) or dehighlight (finger up) animation; one button is highlighted at a time. [CN] 播放按下或抬起动画；同一时间只有一个按钮处于按下状态。 */
    internal fun cyl_setTabButtonHighlighted(highlighted: Boolean, control: View?) {
        val current = highlightedControl?.get()
        var target = control
        if (highlighted) {
            if (target == null || target === current) return
            if (current != null) cyl_setTabButtonHighlighted(false, current)
        } else {
            target = target ?: current
            if (target == null || target !== current) return
        }
        highlightedControl = if (highlighted) java.lang.ref.WeakReference(target) else null
        val animation = animationForTabControl(target)
        val step = if (highlighted) CYLTabButtonAnimationStep.Highlight else CYLTabButtonAnimationStep.Dehighlight
        if (animation.cyl_implements(step)) animation!!.cyl_play(step, target, iconViewOf(target), titleLabelOf(target))
    }

    internal fun cyl_tabButtonTouchDown(control: View) = cyl_setTabButtonHighlighted(true, control)
    internal fun cyl_tabButtonTouchUp(control: View) = cyl_setTabButtonHighlighted(false, control)

    /** [EN] An item's `badgeValue` got a new value: plays its badge-changed animation on the next frame. [CN] item 的 `badgeValue` 有了新值：在下一帧播放角标变化动画。 */
    internal fun cyl_tabBarItemBadgeValueDidChange(item: CYLTabBarItem) {
        val control = item.cyl_visiableTabButton ?: return
        val animation = animationForTabControl(control)
        if (!animation.cyl_implements(CYLTabButtonAnimationStep.BadgeChanged)) return
        control.post { animation!!.cyl_play(CYLTabButtonAnimationStep.BadgeChanged, control, control.iconView, null, control.cyl_badge) }
    }

    /** [EN] `-cyl_playTabButtonTapFeedback`: the tap sound (`cyl_tabButtonTapSoundURL`, else the click) and the haptic. [CN] 点击音效（`cyl_tabButtonTapSoundURL`，否则系统点击声）与触感。 */
    fun cyl_playTabButtonTapFeedback() {
        if (cyl_tabButtonTapSoundEnabled) {
            val player = tapSoundPlayer
            if (player != null) { player.seekTo(0); player.start() } else tabBar.playSoundEffect(SoundEffectConstants.CLICK)
        }
        if (cyl_tabButtonHapticFeedbackEnabled) tabBar.performHapticFeedback(if (cyl_tabButtonHapticFeedbackStyle == CYLEnums.CYLImpactFeedbackStyle.Light) HapticFeedbackConstants.KEYBOARD_TAP else HapticFeedbackConstants.LONG_PRESS)
    }

    /** [EN] `-cyl_switchToAdjacentTabWithStep:animated:`: true when a tab was selected. [CN] 切换到相邻 Tab；选中了则返回 true。 */
    fun cyl_switchToAdjacentTabWithStep(step: Int, animated: Boolean): Boolean {
        val target = selectedIndex + step
        if (target !in viewControllers.indices) return false
        val button = tabBar.cyl_tabBarButtonWithTabIndex(target) ?: return false
        cyl_tabButtonTapped(button)
        return true
    }

    // MARK: - CYLTabBarMinimize (#13) 滚动隐藏

    var cyl_tabBarMinimizeBehavior: CYLEnums.CYLTabBarMinimizeBehavior = CYLEnums.CYLTabBarMinimizeBehavior.Automatic
    /** [EN] `cyl_hidesTabBarOnScroll`: the selected page's scrolling view is observed automatically, as on iOS. [CN] 自动观察选中页面的滚动视图，与 iOS 一致。 */
    var cyl_hidesTabBarOnScroll: Boolean = false
        set(value) { field = value; if (value) cyl_trackSelectedPageScrollView() else cyl_restoreTabBarHiddenByScroll() }
    var cyl_isTabBarHiddenByScroll: Boolean = false
        private set
    private var lastScrollY = 0
    /** [EN] Attach the page's scrolling view: the tab bar hides on scroll down and shows on scroll up (iOS observes it automatically). [CN] 关联页面的滚动视图：下滑隐藏、上滑显示（iOS 自动观察）。 */
    fun cyl_trackScrollView(scrollView: View) {
        scrollView.setOnScrollChangeListener { _, _, scrollY, _, oldScrollY -> cyl_scrollDidChange(scrollY - oldScrollY) }
    }
    fun cyl_scrollDidChange(delta: Int) {
        if (!cyl_hidesTabBarOnScroll || cyl_tabBarMinimizeBehavior == CYLEnums.CYLTabBarMinimizeBehavior.Never) return
        // [EN] With the keyboard up the bar stays (iOS does not hide it while typing). [CN] 键盘弹出时 TabBar 保持显示（iOS 输入时不隐藏）。
        if (isKeyboardVisible()) return
        val down = delta > 0
        val hide = when (cyl_tabBarMinimizeBehavior) { CYLEnums.CYLTabBarMinimizeBehavior.OnScrollUp -> !down; else -> down }
        // [EN] The app hid the bar itself: scrolling does not show it. [CN] App 自己隐藏了 TabBar：滚动不会显示它。
        if (!cyl_isTabBarHiddenByScroll && tabBar.visibility != View.VISIBLE) return
        if (hide != cyl_isTabBarHiddenByScroll && kotlin.math.abs(delta) > 4) {
            cyl_isTabBarHiddenByScroll = hide
            applyTabBarHidden(hide, true)
        }
    }

    /**
     * [EN] Shows a bar hidden by scrolling, as iOS does after an interruption (issue #13): another tab, a push or pop, a
     *      dialog or another window taking the focus, the activity pausing, the keyboard, a memory warning, scroll hiding
     *      turned off. A bar the app hid itself stays hidden.
     * [CN] 恢复滚动隐藏的 TabBar，与 iOS 在意外情况之后的行为一致（issue #13）：切换 Tab、push 或 pop、弹窗或其他窗口获得焦点、Activity 暂停、
     *      键盘弹出、内存警告、关闭滚动隐藏。App 自己隐藏的 TabBar 保持隐藏。
     */
    internal fun cyl_restoreTabBarHiddenByScroll() {
        if (!cyl_isTabBarHiddenByScroll) return
        cyl_isTabBarHiddenByScroll = false
        applyTabBarHidden(false, true)
    }

    private fun isKeyboardVisible(): Boolean =
        androidx.core.view.ViewCompat.getRootWindowInsets(view)?.isVisible(androidx.core.view.WindowInsetsCompat.Type.ime()) == true

    private val windowFocusListener = android.view.ViewTreeObserver.OnWindowFocusChangeListener { hasFocus -> if (!hasFocus) cyl_restoreTabBarHiddenByScroll() }
    private val keyboardListener = android.view.ViewTreeObserver.OnGlobalLayoutListener { if (isKeyboardVisible()) cyl_restoreTabBarHiddenByScroll() }
    fun cyl_simulateHideOnScrollForTesting() = cyl_scrollDidChange(20)

    /** [EN] Finds the selected page's first scrolling view, after its layout, and tracks it. [CN] 在选中页面布局后找到其第一个滚动视图并观察它。 */
    private fun cyl_trackSelectedPageScrollView() {
        if (!cyl_hidesTabBarOnScroll) return
        val root = selectedViewController?.view ?: return
        root.post { findScrollingView(root)?.let { cyl_trackScrollView(it) } }
    }

    // MARK: - CYLTheme (#216) 主题

    var cyl_themeManager: CYLThemeManager = CYLThemeManager.defaultManager
        set(value) { field.removeListener(themeListener); field = value; value.addListener(themeListener); cyl_applyTabBarTheme(value.currentTheme) }
    private var originalAttributes: List<Map<String, Any?>>? = null
    private val themeListener = CYLThemeManager.Listener { manager, _, theme ->
        // [EN] The default manager drives the tab bar; another manager only with a tab bar theme, or null (restore). [CN] 默认管理器决定 TabBar；其他管理器仅在主题为 TabBar 主题或为 null（恢复）时生效。
        if (manager.name == CYLThemeManager.CYLThemeManagerNameDefault || theme is CYLTabBarTheme || theme == null) cyl_applyTabBarTheme(theme)
    }
    private var launchThemeApplied = false

    init {
        CYLThemeManager.defaultManager.addListener(themeListener)
    }

    private fun cyl_applyLaunchTabBarThemeIfNeeded() {
        if (launchThemeApplied) return
        launchThemeApplied = true
        cyl_themeManager.currentTheme?.let { cyl_applyTabBarTheme(it) }
    }

    /** [EN] `-cyl_applyTabBarTheme:`: a `CYLTabBarTheme` (null restores the launch attributes). [CN] 应用主题（null 恢复启动时的属性）。 */
    fun cyl_applyTabBarTheme(theme: Any?) {
        if (originalAttributes == null) originalAttributes = tabBarItemsAttributes
        val previous = tabBarItemsAttributes
        val tabBarTheme = theme as? CYLTabBarTheme
        if (tabBarTheme == null) {
            originalAttributes?.let { setViewControllers(viewControllers, it) }
            cyl_postThemeDidApply(previous, null)
            return
        }
        tabBarTheme.cyl_tabBarItemsAttributesForTabBarController(this)?.let { attributes ->
            val merged = (originalAttributes ?: tabBarItemsAttributes).mapIndexed { index, original -> original + (attributes.getOrNull(index) ?: emptyMap()) }
            setViewControllers(viewControllers, merged)
        }
        tabBarTheme.cyl_plusButtonAttributesForTabBarController(this)?.let { updatePlusButtonWithAttributes(it) }
        tabBarTheme.cyl_tabBarAppearanceForTabBarController(this)?.let { appearance ->
            appearance.backgroundColor?.let { cyl_tabBarBackgroundColor = it }
            appearance.shadowColor?.let { cyl_tabBarShadowColor = it }
            appearance.titleColor?.let { cyl_tabBarItemTitleColor = it }
            appearance.selectedTitleColor?.let { cyl_tabBarItemSelectedTitleColor = it }
            appearance.iconColor?.let { cyl_tabBarItemImageColor = it }
            appearance.selectedIconColor?.let { cyl_tabBarItemSelectedImageColor = it }
            // [EN] The bar's images and item layout go to the bar's appearance, which the classic and FlatDesign styles draw. [CN] TabBar 的图片与 Item 布局写入 TabBar 的外观，由经典与扁平样式绘制。
            if (appearance.backgroundImage != null || appearance.shadowImage != null || appearance.stackedItemPositioningCentered) {
                val current = tabBar.standardAppearance ?: CYLTabBarAppearance()
                tabBar.standardAppearance = current.copy(
                    backgroundImage = appearance.backgroundImage ?: current.backgroundImage,
                    shadowImage = appearance.shadowImage ?: current.shadowImage,
                    stackedItemPositioningCentered = appearance.stackedItemPositioningCentered || current.stackedItemPositioningCentered,
                    stackedItemWidth = if (appearance.stackedItemPositioningCentered) appearance.stackedItemWidth else current.stackedItemWidth,
                    stackedItemSpacing = if (appearance.stackedItemPositioningCentered) appearance.stackedItemSpacing else current.stackedItemSpacing,
                )
            }
        }
        tabBarTheme.cyl_customizeTabBarController(this)
        cyl_postThemeDidApply(previous, tabBarTheme)
    }

    /**
     * [EN] The per-tab notifications of the tabs a skin changed, then `CYLTabBarControllerThemeDidApplyNotification` about every
     *      tab (a skin applies to all of them), with their indexes and identifiers, as on iOS.
     * [CN] 先为皮肤改变的每个 Tab 发送各自的通知，再发送关于所有 Tab（皮肤作用于全部 Tab）的 `CYLTabBarControllerThemeDidApplyNotification`，附上其下标与标识，
     *      与 iOS 相同。
     */
    private fun cyl_postThemeDidApply(previous: List<Map<String, Any?>>, theme: CYLTabBarTheme?) {
        cyl_postTabBarItemChanges(previous, tabBarItemsAttributes)
        if (viewControllers.isEmpty()) return
        CYLNotificationCenter.post(CYLConstants.CYLTabBarControllerThemeDidApplyNotification, this, mapOf(
            CYLConstants.CYLTabBarControllerKey to this,
            CYLConstants.CYLTabBarThemeKey to theme,
            CYLConstants.CYLTabBarItemIndexesKey to viewControllers.indices.toList(),
            CYLConstants.CYLTabBarItemIdentifiersKey to tabBarItems.mapNotNull { it.cyl_tabBarItemIdentifier }))
    }

    // MARK: - Asynchronous pages 异步页面

    val cyl_pendingPages: List<Fragment> get() = viewControllers.filter { it.cyl_isPendingPage }

    private fun cyl_adoptPendingPages() {
        for (page in viewControllers) {
            if (page.cyl_isPendingPage) {
                page.cyl_pageLoadHandler = { placeholder -> cyl_placeholderDidFinishLoading(placeholder) }
            } else if (page.cyl_loadedPage != null || page.cyl_pageLoadFailed) {
                Handler(Looper.getMainLooper()).post { cyl_placeholderDidFinishLoading(page) }
            }
        }
    }

    private fun cyl_placeholderDidFinishLoading(placeholder: Fragment) {
        val index = viewControllers.indexOf(placeholder)
        if (index < 0) return
        placeholder.cyl_pageLoadHandler = null
        val page = placeholder.cyl_loadedPage
        val attributes = tabBarItemsAttributes.getOrNull(index) ?: emptyMap()
        val pages = ArrayList(viewControllers)
        val items = ArrayList(tabBarItemsAttributes)
        val problem = when {
            page == null -> "the asynchronous page factory delivered null"
            page.isAdded && page !in viewControllers -> "the delivered page already belongs to another container"
            page in viewControllers -> "the delivered page is already the page of another tab"
            else -> null
        }
        val wasSelected = selectedIndex == index
        if (problem != null) {
            pages.removeAt(index)
            if (index < items.size) items.removeAt(index)
            cyl_skippedTabs = cyl_skippedTabs + CYLTabBarSkippedTab(CYLTabBarPageSkipReason.PROVIDER_FAILED, CYLTabBarPageRegistry.pageIdentifierOfTab(attributes), com.cyl.tabbar.pages.TabItem(attributes), problem)
            Log.w(TAG, "the tab is removed: $problem")
        } else {
            pages[index] = page!!
        }
        setViewControllers(pages, items)
        if (wasSelected && pages.isNotEmpty()) selectedIndex = minOf(index, pages.size - 1)
        delegate?.cyl_tabBarController_didLoadPage(this, if (problem == null) page else null, placeholder, index)
    }

    // MARK: - CYLActiveTabBarController

    val cyl_isActive: Boolean get() = active[this] != null

    companion object {
        private const val TAG = "CYLTabBarController"
        private val active = WeakHashMap<CYLTabBarController, Long>()
        private var created = 0L

        private fun registerActive(controller: CYLTabBarController) { synchronized(active) { active[controller] = ++created } }

        /** [EN] `+cyl_activeTabBarController`: the most recently created live controller. [CN] 最近创建且仍存活的控制器。 */
        /** [EN] The queue that downloads and decodes the tab icons of every tab bar controller. [CN] 为所有 TabBarController 下载并解码 Tab 图标的队列。 */
        private val iconLoader = java.util.concurrent.Executors.newSingleThreadExecutor()
        /** [EN] Decoded tab icons by URL, shared by every tab bar controller. [CN] 按 URL 缓存的已解码 Tab 图标，所有 TabBarController 共用。 */
        private val iconCache = android.util.LruCache<String, android.graphics.drawable.Drawable.ConstantState>(64)

        @JvmStatic fun cyl_activeTabBarController(): CYLTabBarController? = synchronized(active) { active.entries.maxByOrNull { it.value }?.key }

        /** [EN] Every live controller, oldest first. [CN] 所有存活的控制器，按创建顺序。 */
        internal fun cyl_liveTabBarControllers(): List<CYLTabBarController> = synchronized(active) { active.entries.sortedBy { it.value }.map { it.key } }

        /** [EN] `+cyl_tabBarControllerForContext:`: the most recent live controller of that context. [CN] 该 context 最近创建且仍存活的控制器。 */
        /** [EN] Where the login state is cached; the key is the iOS NSUserDefaults key. [CN] 登录状态的缓存位置；键与 iOS 的 NSUserDefaults 键相同。 */
        private const val LOGIN_PREFERENCES = "CYLTabBarController"
        private const val LOGGED_IN_KEY = "CYLTabBarControllerLoggedIn"
        /** [EN] The keys whose change posts `CYLTabBarItemIconDidChangeNotification`, as on iOS. [CN] 变化时发送 `CYLTabBarItemIconDidChangeNotification` 的 key，与 iOS 相同。 */
        private val ICON_ATTRIBUTE_KEYS = setOf(CYLConstants.CYLTabBarItemImage, CYLConstants.CYLTabBarItemSelectedImage,
            CYLConstants.CYLTabBarItemDarkImage, CYLConstants.CYLTabBarItemSelectedDarkImage, CYLConstants.CYLTabBarItemImageURL,
            CYLConstants.CYLTabBarItemSelectedImageURL, CYLConstants.CYLTabBarItemImageURLSize)
        @JvmStatic fun cyl_tabBarControllerForContext(context: String?): CYLTabBarController? = synchronized(active) {
            active.entries.filter { (it.key.context ?: CYLPlusButton.DEFAULT_TAB_BAR_CONTEXT) == (context ?: CYLPlusButton.DEFAULT_TAB_BAR_CONTEXT) }.maxByOrNull { it.value }?.key
        }

        /** [EN] The live controller that holds `fragment` (or one of its parents) as a tab. [CN] 以 `fragment`（或其父 Fragment）为 Tab 的存活控制器。 */
        @JvmStatic fun cyl_tabBarControllerOfFragment(fragment: Fragment): CYLTabBarController? {
            val controllers = synchronized(active) { active.entries.sortedByDescending { it.value }.map { it.key } }
            var candidate: Fragment? = fragment
            while (candidate != null) {
                controllers.firstOrNull { candidate in it.viewControllers || it.tabBar.plusButton?.provider?.plusChildViewController() === candidate }?.let { return it }
                candidate = candidate.parentFragment
            }
            return null
        }

        /** [EN] `+cyl_simulateMemoryWarning`: a memory warning for the active controller. [CN] 为当前活跃的控制器模拟内存警告。 */
        @JvmStatic fun cyl_simulateMemoryWarning() = cyl_simulateMemoryWarningForTabBarController(cyl_activeTabBarController())
        /**
         * [EN] `+cyl_simulateMemoryWarningForTabBarController:`: what a real memory warning does (`unloadsUnselectedViewsOnMemoryWarning`
         *      unloads the unselected tabs, #426), then logs every tab: loaded or not, and its animation view.
         * [CN] 执行真实内存警告的处理（`unloadsUnselectedViewsOnMemoryWarning` 卸载未选中的 Tab，#426），然后输出每个 Tab：是否已加载及其动画视图。
         */
        @JvmStatic fun cyl_simulateMemoryWarningForTabBarController(tabBarController: CYLTabBarController?) {
            val controller = tabBarController ?: return
            controller.cyl_didReceiveMemoryWarning()
            controller.viewControllers.forEachIndexed { index, page ->
                val button = controller.tabBar.cyl_tabBarButtonWithTabIndex(index)
                android.util.Log.d("CYLTabBarController", "tab $index ${controller.tabBarItems.getOrNull(index)?.title ?: page.javaClass.simpleName}: view ${if (page.view != null) "loaded" else "unloaded"}, animation ${if (button?.cyl_isTabBarItemAnimationReady() == true) "added" else "none"}")
            }
        }

        /** [EN] `+cyl_defaultTabBarItemIdentifierForClass:`: the class name. [CN] 类名。 */
        @JvmStatic fun cyl_defaultTabBarItemIdentifierForClass(aClass: Class<*>): String = aClass.name

        // MARK: - CYLConfiguration 配置

        @JvmStatic fun tabBarControllerWithConfiguration(activity: FragmentActivity, configuration: Map<String, Any?>) = CYLTabBarController(activity, configuration)

        @JvmStatic fun tabBarControllerWithViewControllers(activity: FragmentActivity, viewControllers: List<Fragment>, tabBarItemsAttributes: List<Map<String, Any?>>) =
            CYLTabBarController(activity, viewControllers, tabBarItemsAttributes)

        /** [EN] `+configurationWithContentsOfFile:error:` / `+tabBarControllerWithConfigurationFile:error:`. [CN] 从文件创建。 */
        @JvmStatic @Throws(CYLTabBarConfiguration.CYLConfigurationException::class)
        fun configurationWithContentsOfFile(context: Context, path: String) = CYLTabBarConfiguration.configurationWithContentsOfFile(context, path)

        @JvmStatic @Throws(CYLTabBarConfiguration.CYLConfigurationException::class)
        fun tabBarControllerWithConfigurationFile(activity: FragmentActivity, path: String): CYLTabBarController {
            val controller = CYLTabBarController(activity, configurationWithContentsOfFile(activity, path))
            if (controller.viewControllers.isEmpty()) throw CYLTabBarConfiguration.CYLConfigurationException(CYLTabBarConfiguration.CYLTabBarConfigurationError.NoPages, "no tab of $path found its page")
            return controller
        }

        @JvmStatic fun loadConfigurationWithURL(url: String, completion: (Map<String, Any?>?, CYLTabBarConfiguration.CYLConfigurationException?) -> Unit) =
            CYLTabBarConfiguration.loadConfigurationWithURL(url, completion)

        /** [EN] `+loadConfigurationWithURLRequest:completion:`. [CN] 使用自己的请求加载配置。 */
        @JvmStatic fun loadConfigurationWithURLRequest(request: CYLTabBarConfiguration.CYLURLRequest, completion: (Map<String, Any?>?, CYLTabBarConfiguration.CYLConfigurationException?) -> Unit) =
            CYLTabBarConfiguration.loadConfigurationWithURLRequest(request, completion)

        @JvmStatic fun loadTabBarControllerWithConfigurationURL(activity: FragmentActivity, url: String, completion: (CYLTabBarController?, CYLTabBarConfiguration.CYLConfigurationException?) -> Unit) =
            loadTabBarControllerWithConfigurationURLRequest(activity, CYLTabBarConfiguration.CYLURLRequest(url), completion)

        /** [EN] `+loadTabBarControllerWithConfigurationURLRequest:completion:`: a controller from a configuration your request downloads. [CN] 用自己的请求下载配置并创建控制器。 */
        @JvmStatic fun loadTabBarControllerWithConfigurationURLRequest(activity: FragmentActivity, request: CYLTabBarConfiguration.CYLURLRequest, completion: (CYLTabBarController?, CYLTabBarConfiguration.CYLConfigurationException?) -> Unit) {
            CYLTabBarConfiguration.loadConfigurationWithURLRequest(request) { configuration, error ->
                if (configuration == null) { completion(null, error); return@loadConfigurationWithURLRequest }
                val controller = CYLTabBarController(activity, configuration)
                if (controller.viewControllers.isEmpty()) completion(null, CYLTabBarConfiguration.CYLConfigurationException(CYLTabBarConfiguration.CYLTabBarConfigurationError.NoPages, "no tab found its page")) else completion(controller, null)
            }
        }

        @JvmStatic fun cyl_normalizedConfiguration(configuration: Map<String, Any?>) = CYLTabBarConfiguration.cyl_normalizedConfiguration(configuration)
    }
}

/**
 * [EN] The root view: the pages above the tab bar. A touch in the plus button's touchable rect above the bar (#91) goes to
 *      the plus button, which is what `-hitTest:withEvent:` does on iOS.
 * [CN] 根视图：页面在 TabBar 之上。落在 TabBar 上方 PlusButton 可点击矩形内的触摸（#91）交给 PlusButton，对应 iOS 的 `-hitTest:withEvent:`。
 */
class CYLTabBarControllerView(context: Context) : LinearLayout(context) {
    internal var controller: CYLTabBarController? = null
    private var routedToPlus = false

    private val overlaysPages: Boolean get() = controller?.tabBar?.styleRenderer?.drawsPagesUnderTabBar == true

    /** [EN] FlatDesign and Liquid Glass: the pages fill the view and the bar floats over their bottom. [CN] 扁平样式与液态玻璃：页面铺满视图，TabBar 浮在页面底部之上。 */
    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val controller = controller
        if (!overlaysPages || controller == null) return super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        val width = MeasureSpec.getSize(widthMeasureSpec)
        val height = MeasureSpec.getSize(heightMeasureSpec)
        val innerWidth = MeasureSpec.makeMeasureSpec(width - paddingLeft - paddingRight, MeasureSpec.EXACTLY)
        controller.pagesContainer.measure(innerWidth, MeasureSpec.makeMeasureSpec(height - paddingTop, MeasureSpec.EXACTLY))
        controller.tabBar.measure(innerWidth, MeasureSpec.makeMeasureSpec(height, MeasureSpec.AT_MOST))
        setMeasuredDimension(width, height)
    }

    override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
        val controller = controller
        if (!overlaysPages || controller == null) return super.onLayout(changed, l, t, r, b)
        val pages = controller.pagesContainer
        pages.layout(paddingLeft, paddingTop, paddingLeft + pages.measuredWidth, paddingTop + pages.measuredHeight)
        val bar = controller.tabBar
        bar.layout(paddingLeft, height - bar.measuredHeight, paddingLeft + bar.measuredWidth, height)
    }

    init {
        orientation = VERTICAL
        // [EN] The tab bar's plus button draws above the bar, over the pages. [CN] TabBar 的 PlusButton 绘制在 TabBar 上方、页面之上。
        clipChildren = false
    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        val tabBar = controller?.tabBar ?: return super.dispatchTouchEvent(event)
        if (tabBar.visibility != View.VISIBLE) return super.dispatchTouchEvent(event)
        val x = event.x - tabBar.left
        val y = event.y - tabBar.top
        if (event.actionMasked == MotionEvent.ACTION_DOWN) {
            routedToPlus = y < 0 && tabBar.cyl_plusButtonTouchable(x, y)
        }
        if (routedToPlus) {
            val inBar = MotionEvent.obtain(event).apply { setLocation(x, y) }
            val handled = tabBar.cyl_dispatchTouchToPlusButton(inBar)
            inBar.recycle()
            if (event.actionMasked == MotionEvent.ACTION_UP || event.actionMasked == MotionEvent.ACTION_CANCEL) routedToPlus = false
            return handled
        }
        return super.dispatchTouchEvent(event)
    }
}

/** [EN] `NSObject (CYLTabBarControllerReferenceExtension)`: the tab bar controller of a Fragment. [CN] Fragment 所属的 TabBarController。 */
val Fragment.cyl_tabBarController: CYLTabBarController?
    get() = CYLTabBarController.cyl_tabBarControllerOfFragment(this)

/** [EN] `-cyl_owningTabBarController`: the controller this page (or a parent) is a tab of. [CN] 本页面（或其父页面）所属的控制器。 */
fun Fragment.cyl_owningTabBarController(): CYLTabBarController? = CYLTabBarController.cyl_tabBarControllerOfFragment(this)

// MARK: - Block types (the iOS typedefs) 回调类型（iOS 的 typedef）

/** [EN] `CYLViewDidLayoutSubViewsBlock`: the controller laid its tab bar out. [CN] 控制器完成 TabBar 布局。 */
typealias CYLViewDidLayoutSubViewsBlock = (tabBarController: CYLTabBarController) -> Unit
/** [EN] `CYLTabBarDidLayoutSubViewsBlock`: the tab bar laid its buttons out. [CN] TabBar 完成按钮布局。 */
typealias CYLTabBarDidLayoutSubViewsBlock = (tabBar: CYLTabBar) -> Unit
/** [EN] `CYLTabBarControllerDidLongPressControlBlock`: a long press on a tab button. [CN] 长按 Tab 按钮。 */
typealias CYLTabBarControllerDidLongPressControlBlock = (tabBarController: CYLTabBarController, control: View) -> Unit
/** [EN] `CYLTabBarLoginCompletion` (#19): call it with the result of the login. [CN] 用登录结果调用它（#19）。 */
typealias CYLTabBarLoginCompletion = (loggedIn: Boolean) -> Unit
/** [EN] `CYLTabBarItemGestureHandler` (#535): a gesture on a tab button. [CN] Tab 按钮上的手势（#535）。 */
typealias CYLTabBarItemGestureHandler = (tabBarController: CYLTabBarController, gesture: CYLEnums.CYLTabBarItemGesture, control: View, viewController: Fragment?) -> Unit
/** [EN] `CYLTabBarItemIconViewProvider`: the view shown in place of a tab's icon, for its selection. [CN] 按选中状态代替 Tab 图标显示的视图。 */
typealias CYLTabBarItemIconViewProvider = (selected: Boolean) -> View?
/** [EN] `CYLTabBarControllerConfigurationCompletion`: a controller from a configuration, or the error. [CN] 由配置创建的控制器，或错误。 */
typealias CYLTabBarControllerConfigurationCompletion = (tabBarController: CYLTabBarController?, error: CYLTabBarConfiguration.CYLConfigurationException?) -> Unit
/** [EN] `CYLTabBarConfigurationCompletion`: a loaded configuration, or the error. [CN] 加载的配置，或错误。 */
typealias CYLTabBarConfigurationCompletion = (configuration: Map<String, Any?>?, error: CYLTabBarConfiguration.CYLConfigurationException?) -> Unit
