package com.cyl.tabbar

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
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
    val view: ViewGroup = LinearLayout(activity).apply { orientation = LinearLayout.VERTICAL }
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
            override fun onViewAttachedToWindow(v: View) { if (pagesCommitPending) commitPages() }
            override fun onViewDetachedFromWindow(v: View) {}
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
    var tabBarItemAnimationSpeed: Float = 1f
    var noNeedUIDesignCompatibility: Boolean = false
    var allowsVerticalBar: Boolean = false
    var viewDidLayoutSubviewsBlock: ((CYLTabBarController) -> Unit)? = null
    val tabBarItemAnimationURLs: MutableList<String> = ArrayList()
    val tabBarItemAnimationSizes: MutableList<CYLSize> = ArrayList()
    val tabBarItemAnimationViewAdded: Boolean get() = false

    /** [EN] `selectedIndex`: setting it selects the page (no delegate questions). [CN] 设置即选中页面（不询问代理）。 */
    var selectedIndex: Int = 0
        set(value) {
            if (value < 0 || value >= viewControllers.size) return
            field = value
            tabBar.plusButtonActive = false
            showSelectedPage()
            tabBar.refreshSelection()
        }
    val selectedViewController: Fragment? get() = viewControllers.getOrNull(selectedIndex)

    var tabBarHidden: Boolean = false
        set(value) { setTabBarHidden(value, false) }

    /** [EN] `-setTabBarHidden:animated:`. [CN] 隐藏 / 显示 TabBar。 */
    fun setTabBarHidden(hidden: Boolean, animated: Boolean) {
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
        if (pages != null) {
            // [EN] From code, matched by index; an excluded tab takes its page out (B22). [CN] 代码传入，按下标对应；被排除的 Tab 连同页面一起移除（B22）。
            val keptItems = ArrayList<Map<String, Any?>>()
            val keptPages = ArrayList<Fragment>()
            for (index in 0 until maxOf(items.size, pages.size)) {
                val item = items.getOrNull(index)
                if (item?.get(CYLTabBarConfiguration.EXCLUDED_KEY) == true) {
                    skipped += CYLTabBarSkippedTab(CYLTabBarPageSkipReason.EXCLUDED, CYLTabBarPageRegistry.pageIdentifierOfTab(item), com.cyl.tabbar.pages.TabItem(item), item[CYLTabBarConfiguration.EXCLUSION_REASON_KEY] as? String)
                    continue
                }
                keptItems += item ?: emptyMap()
                pages.getOrNull(index)?.let { keptPages += it }
            }
            items = keptItems.take(keptPages.size).let { kept -> if (kept.size < keptPages.size) kept + List(keptPages.size - kept.size) { emptyMap<String, Any?>() } else kept }
            pages = keptPages
        } else {
            pagesFromPageIdentifiers = true
            cyl_pageRegistry = normalized[CYLConstants.CYLTabBarControllerPageRegistry] as? CYLTabBarPageProviding
            @Suppress("UNCHECKED_CAST")
            cyl_pageResolver = normalized[CYLConstants.CYLTabBarControllerPageResolver] as? CYLTabBarPageProvider
            @Suppress("UNCHECKED_CAST")
            cyl_pageLookupOrder = (normalized[CYLConstants.CYLTabBarControllerPageLookupOrder] as? List<CYLTabBarPageSource>) ?: CYLTabBarPageRegistry.defaultPageLookupOrder
            val resolvable = ArrayList<Map<String, Any?>>()
            for (item in items) {
                if (item.isEmpty()) { skipped += CYLTabBarSkippedTab(CYLTabBarPageSkipReason.INVALID_TAB, null, null, "a placeholder for a tab that is not a dictionary"); continue }
                if (item[CYLTabBarConfiguration.EXCLUDED_KEY] == true) { skipped += CYLTabBarSkippedTab(CYLTabBarPageSkipReason.EXCLUDED, CYLTabBarPageRegistry.pageIdentifierOfTab(item), com.cyl.tabbar.pages.TabItem(item), item[CYLTabBarConfiguration.EXCLUSION_REASON_KEY] as? String); continue }
                resolvable += item
            }
            val kept = ArrayList<Map<String, Any?>>()
            pages = CYLTabBarPageRegistry.pagesOfTabs(resolvable, cyl_pageRegistry, cyl_pageResolver, cyl_pageLookupOrder, kept, skipped)
            items = kept
        }
        cyl_skippedTabs = skipped
        imageInsets = (normalized[CYLConstants.CYLTabBarControllerImageInsets] as? CYLEdgeInsets) ?: CYLTabBarConfiguration.edgeInsetsValue(normalized[CYLConstants.CYLTabBarControllerImageInsets]) ?: CYLEdgeInsets.zero
        titlePositionAdjustment = (normalized[CYLConstants.CYLTabBarControllerTitlePositionAdjustment] as? CYLOffset) ?: CYLTabBarConfiguration.offsetValue(normalized[CYLConstants.CYLTabBarControllerTitlePositionAdjustment]) ?: CYLOffset.zero
        tabBarStyleType = (normalized[CYLConstants.CYLTabBarControllerStyleType] as? CYLEnums.CYLTabBarStyleType) ?: CYLEnums.CYLTabBarStyleType.Default
        context = normalized[CYLConstants.CYLTabBarControllerContext] as? String
        (normalized[CYLConstants.CYLTabBarControllerTabBarItemAnimationSpeed]?.toString()?.toFloatOrNull())?.takeIf { it > 0 && it.isFinite() }?.let { tabBarItemAnimationSpeed = it }
        setViewControllers(pages ?: emptyList(), items)
        cyl_adoptPendingPages()
        cyl_didInitialize()
    }

    /** [EN] `-cyl_didInitialize`: a hook for subclasses, called once at the end of every initializer. [CN] 子类钩子，每个初始化方法末尾调用一次。 */
    open fun cyl_didInitialize() {}

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
        item.cyl_tabBarItemAnimationURL = listOf(CYLConstants.CYLTabBarAnimationURL, CYLConstants.CYLTabBarLottieURL, CYLConstants.CYLTabBarPAGURL, CYLConstants.CYLTabBarRiveURL,
                                                 CYLConstants.CYLTabBarAnimationFilePath, CYLConstants.CYLTabBarLottieFilePath, CYLConstants.CYLTabBarPAGFilePath, CYLConstants.CYLTabBarRiveFilePath)
            .firstNotNullOfOrNull { attributes[it] as? String }
        item.cyl_tabBarItemAnimationSizeValue = listOf(CYLConstants.CYLTabBarAnimationSize, CYLConstants.CYLTabBarLottieSize, CYLConstants.CYLTabBarPAGSize, CYLConstants.CYLTabBarRiveSize)
            .firstNotNullOfOrNull { CYLTabBarConfiguration.sizeValue(attributes[it]) }
        return item
    }

    private fun showSelectedPage() {
        commitPages()
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
            delegate?.tabBarController_performCustomActionForViewController(this, page)
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
            tabBar.plusButtonActive = true
            tabBar.refreshSelection()
            delegate?.tabBarController_didSelectViewController(this, child)
        }
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
        item.image = icon
        item.selectedImage = selectedIcon ?: icon
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
        if (url.startsWith("http")) java.net.URL(url).openStream().use { android.graphics.drawable.Drawable.createFromStream(it, url) } else CYLTabBarConfiguration.imageResolver.drawable(activity, url)
    } catch (error: Exception) { null }

    /** [EN] `-setTabBarItemIconViewProvider:atIndex:`: a custom view in place of the icon. [CN] 用自定义视图代替图标。 */
    fun setTabBarItemIconViewProvider(provider: ((CYLTabBarItemButton) -> View)?, index: Int) {
        val button = tabBar.cyl_tabBarButtonWithTabIndex(index) ?: return
        button.iconView.visibility = if (provider == null) View.VISIBLE else View.INVISIBLE
        provider?.invoke(button)?.let { button.addView(it) }
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

    /** [EN] `-performWhenTabBarItemsReady:`: Android lays out synchronously, so the block runs now. [CN] Android 同步布局，立即执行。 */
    fun performWhenTabBarItemsReady(block: (CYLTabBarController) -> Unit) = block(this)
    fun reloadBadgesWithBlock(block: (CYLTabBarController) -> Unit) = block(this)
    fun setViewDidLayoutSubViewsBlock(block: ((CYLTabBarController) -> Unit)?) { viewDidLayoutSubviewsBlock = block }
    fun setViewDidLayoutSubViewsBlockInvokeOnce(once: Boolean, block: ((CYLTabBarController) -> Unit)?) {
        viewDidLayoutSubviewsBlock = if (once && block != null) { controller -> block(controller); viewDidLayoutSubviewsBlock = null } else block
    }
    fun updateImageInsets(insets: CYLEdgeInsets) { imageInsets = insets }
    fun hideTabBarShadowImageView() { tabBar.cyl_shadowColor = null; tabBar.refreshSelection() }
    fun setTintColor(@ColorInt color: Int) { tabBar.selectedTintColor = color; tabBar.refreshSelection() }
    /** [EN] `-unloadViewsOfUnselectedViewControllers`: Android keeps hidden fragments; nothing to unload. [CN] Android 保留隐藏的 Fragment，无需卸载。 */
    fun unloadViewsOfUnselectedViewControllers() {}
    open fun shouldUnloadViewOfViewController(viewController: Fragment): Boolean = unloadsUnselectedViewsOnMemoryWarning

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

    var cyl_loggedIn: Boolean = false
    var cyl_loginRequiredTabBarItemIdentifiers: List<String> = emptyList()
    var cyl_loginRequiredBlock: ((CYLTabBarController, Fragment) -> Boolean)? = null
    var cyl_presentLoginBlock: ((CYLTabBarController, Fragment, (Boolean) -> Unit) -> Unit)? = null

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

    var cyl_tabBarItemGestureHandler: ((CYLTabBarController, CYLEnums.CYLTabBarItemGesture, View, Fragment?) -> Unit)? = null
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

    var cyl_tabButtonTapAnimationType: CYLEnums.CYLTabButtonTapAnimationType = CYLEnums.CYLTabButtonTapAnimationType.None
    var cyl_tabButtonTapSoundEnabled: Boolean = false
    var cyl_tabButtonHapticFeedbackEnabled: Boolean = false
    var cyl_tabButtonHapticFeedbackStyle: CYLEnums.CYLImpactFeedbackStyle = CYLEnums.CYLImpactFeedbackStyle.Light
    var cyl_didLongPressControlBlock: ((CYLTabBarController, View) -> Unit)? = null
    var cyl_tabButtonLongPressMinimumDuration: Double
        get() = cyl_tabBarItemLongPressDuration
        set(value) { cyl_tabBarItemLongPressDuration = value }
    var cyl_swipeToSwitchTabEnabled: Boolean = false

    /** [EN] `-cyl_playTabButtonAnimationForControl:`: scale, zoom, bounce, rotation or flip of the icon. [CN] 图标的缩放、弹跳、旋转或翻转动画。 */
    fun cyl_playTabButtonAnimationForControl(control: View) {
        val icon = (control as? CYLTabBarItemButton)?.iconView ?: control
        val animator = icon.animate().setDuration(250)
        icon.scaleX = 1f; icon.scaleY = 1f; icon.rotation = 0f; icon.rotationY = 0f
        when (cyl_tabButtonTapAnimationType) {
            CYLEnums.CYLTabButtonTapAnimationType.None -> return
            CYLEnums.CYLTabButtonTapAnimationType.Scale, CYLEnums.CYLTabButtonTapAnimationType.ZoomIn -> { icon.scaleX = 0.7f; icon.scaleY = 0.7f; animator.scaleX(1f).scaleY(1f).setInterpolator(android.view.animation.OvershootInterpolator()) }
            CYLEnums.CYLTabButtonTapAnimationType.Bounce, CYLEnums.CYLTabButtonTapAnimationType.BounceWithFireworks -> animator.translationYBy(-10f * density).withEndAction { icon.animate().translationYBy(10f * density).setInterpolator(android.view.animation.BounceInterpolator()).start() }
            CYLEnums.CYLTabButtonTapAnimationType.Rotation -> animator.rotationBy(360f).setDuration(400)
            CYLEnums.CYLTabButtonTapAnimationType.Flip -> animator.rotationYBy(360f).setDuration(400)
            CYLEnums.CYLTabButtonTapAnimationType.Fume, CYLEnums.CYLTabButtonTapAnimationType.Frame, CYLEnums.CYLTabButtonTapAnimationType.Lottie -> { icon.alpha = 0.3f; animator.alpha(1f) }
        }
        animator.start()
    }

    /** [EN] `-cyl_playTabButtonTapFeedback`: the click sound and the haptic. [CN] 点击声音与触感。 */
    fun cyl_playTabButtonTapFeedback() {
        if (cyl_tabButtonTapSoundEnabled) tabBar.playSoundEffect(SoundEffectConstants.CLICK)
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
    var cyl_hidesTabBarOnScroll: Boolean = false
    var cyl_isTabBarHiddenByScroll: Boolean = false
        private set
    private var lastScrollY = 0
    /** [EN] Attach the page's scrolling view: the tab bar hides on scroll down and shows on scroll up (iOS observes it automatically). [CN] 关联页面的滚动视图：下滑隐藏、上滑显示（iOS 自动观察）。 */
    fun cyl_trackScrollView(scrollView: View) {
        scrollView.setOnScrollChangeListener { _, _, scrollY, _, oldScrollY -> cyl_scrollDidChange(scrollY - oldScrollY) }
    }
    fun cyl_scrollDidChange(delta: Int) {
        if (!cyl_hidesTabBarOnScroll || cyl_tabBarMinimizeBehavior == CYLEnums.CYLTabBarMinimizeBehavior.Never) return
        val down = delta > 0
        val hide = when (cyl_tabBarMinimizeBehavior) { CYLEnums.CYLTabBarMinimizeBehavior.OnScrollUp -> !down; else -> down }
        if (hide != cyl_isTabBarHiddenByScroll && kotlin.math.abs(delta) > 4) {
            cyl_isTabBarHiddenByScroll = hide
            setTabBarHidden(hide, true)
        }
    }
    fun cyl_simulateHideOnScrollForTesting() = cyl_scrollDidChange(20)

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
        private val active = WeakHashMap<CYLTabBarController, Boolean>()

        private fun registerActive(controller: CYLTabBarController) { synchronized(active) { active[controller] = true } }

        /** [EN] `+cyl_activeTabBarController`: the most recently created live controller. [CN] 最近创建且仍存活的控制器。 */
        @JvmStatic fun cyl_activeTabBarController(): CYLTabBarController? = synchronized(active) { active.keys.lastOrNull() }

        /** [EN] `+cyl_tabBarControllerForContext:`. [CN] 某 context 的控制器。 */
        @JvmStatic fun cyl_tabBarControllerForContext(context: String?): CYLTabBarController? = synchronized(active) { active.keys.lastOrNull { (it.context ?: CYLPlusButton.DEFAULT_TAB_BAR_CONTEXT) == (context ?: CYLPlusButton.DEFAULT_TAB_BAR_CONTEXT) } }

        /** [EN] `+cyl_simulateMemoryWarning`: nothing to free on Android (hidden fragments keep their views). [CN] Android 上无需释放。 */
        @JvmStatic fun cyl_simulateMemoryWarning() = Unit
        @JvmStatic fun cyl_simulateMemoryWarningForTabBarController(tabBarController: CYLTabBarController) = tabBarController.unloadViewsOfUnselectedViewControllers()

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

        @JvmStatic fun loadTabBarControllerWithConfigurationURL(activity: FragmentActivity, url: String, completion: (CYLTabBarController?, CYLTabBarConfiguration.CYLConfigurationException?) -> Unit) {
            CYLTabBarConfiguration.loadConfigurationWithURL(url) { configuration, error ->
                if (configuration == null) { completion(null, error); return@loadConfigurationWithURL }
                val controller = CYLTabBarController(activity, configuration)
                if (controller.viewControllers.isEmpty()) completion(null, CYLTabBarConfiguration.CYLConfigurationException(CYLTabBarConfiguration.CYLTabBarConfigurationError.NoPages, "no tab found its page")) else completion(controller, null)
            }
        }

        @JvmStatic fun cyl_normalizedConfiguration(configuration: Map<String, Any?>) = CYLTabBarConfiguration.cyl_normalizedConfiguration(configuration)
    }
}

/** [EN] `NSObject (CYLTabBarControllerReferenceExtension)`: the tab bar controller of a Fragment. [CN] Fragment 所属的 TabBarController。 */
val Fragment.cyl_tabBarController: CYLTabBarController?
    get() = CYLTabBarController.cyl_activeTabBarController()?.takeIf { this in it.viewControllers } ?: cyl_owningTabBarController()

fun Fragment.cyl_owningTabBarController(): CYLTabBarController? {
    var fragment: Fragment? = this
    while (fragment != null) {
        CYLTabBarController.cyl_activeTabBarController()?.let { controller -> if (fragment in controller.viewControllers) return controller }
        fragment = fragment.parentFragment
    }
    return null
}
