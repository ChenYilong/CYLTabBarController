// [EN] The method names are the iOS names on purpose (`cyl_…`, `tabBarController_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`、`tabBarController_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

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
    val pagesContainer: FrameLayout = FrameLayout(activity).apply { id = View.generateViewId() }
    /** [EN] `tabBar` / `cyl_tabBar`. [CN] TabBar。 */
    val tabBar: CYLTabBar = CYLTabBar(activity).apply { tabBarController = this@CYLTabBarController }
    val cyl_tabBar: CYLTabBar get() = tabBar
    val fragmentManager: FragmentManager get() = activity.supportFragmentManager
    private val fragmentTag = "CYLTabBarController-" + System.identityHashCode(this)

    private var pagesCommitPending = false

    init {
        view.addView(pagesContainer, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f))
        view.addView(tabBar, LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
        // [EN] Fragments need their container in the window: transactions wait until `view` is attached. [CN] Fragment 需要容器已在窗口中：事务等到 `view` 附加后再提交。
        pagesContainer.addOnAttachStateChangeListener(object : View.OnAttachStateChangeListener {
            override fun onViewAttachedToWindow(v: View) {
                if (pagesCommitPending) commitPages()
                v.viewTreeObserver.addOnWindowFocusChangeListener(windowFocusListener)
                v.viewTreeObserver.addOnGlobalLayoutListener(keyboardListener)
            }
            override fun onViewDetachedFromWindow(v: View) {
                v.viewTreeObserver.removeOnWindowFocusChangeListener(windowFocusListener)
                v.viewTreeObserver.removeOnGlobalLayoutListener(keyboardListener)
            }
        })
        // [EN] The activity pausing (a call, another app, the recents screen) shows a bar hidden by scrolling (#13). [CN] Activity 暂停（来电、其他 App、最近任务）时恢复滚动隐藏的 TabBar（#13）。
        activity.lifecycle.addObserver(androidx.lifecycle.LifecycleEventObserver { _, event ->
            if (event == androidx.lifecycle.Lifecycle.Event.ON_PAUSE) cyl_restoreTabBarHiddenByScroll()
        })
        registerActive(this)
    }

    /** [EN] Adds the pages to the container and shows the selected one, now or once the view is attached. [CN] 把页面加入容器并显示选中的页面，立即或等视图附加后。 */
    private fun commitPages() {
        if (!pagesContainer.isAttachedToWindow || fragmentManager.isDestroyed) {
            pagesCommitPending = true
            return
        }
        pagesCommitPending = false
        val transaction = fragmentManager.beginTransaction()
        viewControllers.forEachIndexed { index, page ->
            if (!page.isAdded) transaction.add(pagesContainer.id, page, "$fragmentTag-$index")
            // [EN] A tab unloaded by a memory warning creates its view again when selected (#426). [CN] 被内存警告卸载的 Tab 在选中时重新创建视图（#426）。
            if (index == selectedIndex && page.isDetached) transaction.attach(page)
            if (index == selectedIndex) transaction.show(page) else transaction.hide(page)
        }
        transaction.commitNowAllowingStateLoss()
    }

    // MARK: - CYLTabBarController properties 属性

    var tabBarStyleType: CYLEnums.CYLTabBarStyleType = CYLEnums.CYLTabBarStyleType.Default
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
            field = value
            tabBar.plusButtonActive = false
            showSelectedPage()
            tabBar.refreshSelection()
            // [EN] Another tab: a bar hidden by scrolling comes back (issue #13, as on iOS). [CN] 切换到其他 Tab：滚动隐藏的 TabBar 恢复显示（issue #13，与 iOS 一致）。
            if (previous != value) cyl_restoreTabBarHiddenByScroll()
            if (previous != value) cyl_playSelectedTabBarItemAnimation(defaultSelected = false)
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
        val normalized = CYLTabBarConfiguration.cyl_normalizedConfiguration(configuration, "android", appVersion)
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
        (normalized[CYLConstants.CYLTabBarControllerTabBarItemAnimationSpeed]?.toString()?.toFloatOrNull())?.takeIf { it > 0 && it.isFinite() }?.let { tabBarItemAnimationSpeed = it }
        setViewControllers(pages, items)
        cyl_adoptPendingPages()
        cyl_didInitialize()
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
        commitPages()
        tabBar.cyl_reloadTabButtons()
        cyl_addTabBarItemAnimations()
        loadImageURLs()
        cyl_applyLaunchTabBarThemeIfNeeded()
        viewDidLayoutSubviewsBlock?.invoke(this)
    }

    private fun makeItem(attributes: Map<String, Any?>): CYLTabBarItem {
        val item = CYLTabBarItem(attributes)
        val resolver = CYLTabBarConfiguration.imageResolver
        (attributes[CYLConstants.CYLTabBarItemImage] as? String)?.let { item.image = resolver.drawable(activity, it) }
        (attributes[CYLConstants.CYLTabBarItemSelectedImage] as? String)?.let { item.selectedImage = resolver.drawable(activity, it) }
        (attributes[CYLConstants.CYLTabBarItemImage] as? android.graphics.drawable.Drawable)?.let { item.image = it }
        (attributes[CYLConstants.CYLTabBarItemSelectedImage] as? android.graphics.drawable.Drawable)?.let { item.selectedImage = it }
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
        val merged = ArrayList(tabBarItemsAttributes)
        merged[index] = current + attributes
        setViewControllers(viewControllers, merged)
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
    }

    /** [EN] `-setTabBarItemIconWithURL:selectedURL:size:atIndex:`: downloads on a background thread. [CN] 后台线程下载图标。 */
    fun setTabBarItemIconWithURL(url: String, selectedURL: String?, size: CYLSize?, index: Int) {
        Thread {
            val icon = loadDrawable(url)
            val selected = selectedURL?.let { loadDrawable(it) }
            Handler(Looper.getMainLooper()).post { setTabBarItemIcon(icon, selected, size, index) }
        }.start()
    }

    private fun loadDrawable(url: String): android.graphics.drawable.Drawable? = try {
        if (url.startsWith("http")) java.net.URI(url).toURL().openStream().use { android.graphics.drawable.Drawable.createFromStream(it, url) } else CYLTabBarConfiguration.imageResolver.drawable(activity, url)
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
    }

    fun updatePlusButtonWithAttributes(attributes: Map<String, Any?>) {
        val plus = tabBar.plusButton ?: return
        plus.cyl_updateTitle(attributes[CYLConstants.CYLTabBarItemTitle] as? String,
            (attributes[CYLConstants.CYLTabBarItemImage] as? String)?.let { CYLTabBarConfiguration.imageResolver.drawable(activity, it) },
            (attributes[CYLConstants.CYLTabBarItemSelectedImage] as? String)?.let { CYLTabBarConfiguration.imageResolver.drawable(activity, it) })
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
        if (fragmentManager.isDestroyed || fragmentManager.isStateSaved) return
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

    /** [EN] Whether the user is logged in: `cyl_loginStateProvider` when set, else the cached value. [CN] 用户是否已登录：设置了 `cyl_loginStateProvider` 时用它，否则为缓存值。 */
    var cyl_loggedIn: Boolean = false
        get() = cyl_loginStateProvider?.invoke() ?: field
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
        set(value) { field = value; tabBar.setBackgroundColor(value ?: 0xFFF9F9F9.toInt()) }
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
        if (previous != null && previous !== control) {
            val previousAnimation = animationForTabControl(previous)
            if (previousAnimation.cyl_implements(CYLTabButtonAnimationStep.Deselect)) {
                if (hasIndexes && previousAnimation!!.cyl_respondsToSelector("cyl_setToRight")) previousAnimation.cyl_setToRight(previousIndex < index)
                previousAnimation!!.cyl_play(CYLTabButtonAnimationStep.Deselect, previous, iconViewOf(previous), titleLabelOf(previous))
            }
        }
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
        val tabBarTheme = theme as? CYLTabBarTheme
        if (tabBarTheme == null) {
            originalAttributes?.let { setViewControllers(viewControllers, it) }
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
        }
        tabBarTheme.cyl_customizeTabBarController(this)
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
        @JvmStatic fun cyl_activeTabBarController(): CYLTabBarController? = synchronized(active) { active.entries.maxByOrNull { it.value }?.key }

        /** [EN] Every live controller, oldest first. [CN] 所有存活的控制器，按创建顺序。 */
        internal fun cyl_liveTabBarControllers(): List<CYLTabBarController> = synchronized(active) { active.entries.sortedBy { it.value }.map { it.key } }

        /** [EN] `+cyl_tabBarControllerForContext:`: the most recent live controller of that context. [CN] 该 context 最近创建且仍存活的控制器。 */
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

    init {
        orientation = VERTICAL
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
