package com.cyl.tabbar

import android.content.Context
import android.content.ContextWrapper
import android.graphics.BitmapFactory
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.TouchDelegate
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.core.graphics.Insets
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import org.json.JSONArray
import org.json.JSONObject
import java.net.URL
import java.util.concurrent.Executors

/** [EN] The page of every tab of a [CYLTabBarHostView]: the host draws the pages, so it is empty. [CN] [CYLTabBarHostView] 每个 Tab 的页面：页面由宿主绘制，因此为空。 */
class CYLTabBarHostEmptyPage : Fragment()

/**
 * [EN] `CYLTabBarHostView`: a view that shows only the tab bar of a [CYLTabBarController] made from a configuration
 *      ([CYLTabBarController.tabBarControllerWithConfiguration], see docs/Configuration-File.md). The pages belong to someone
 *      else: React Native, Flutter, or an app that draws its own content; every tab gets an empty page. The React Native and
 *      Flutter components of `CrossPlatform/` are thin wrappers around it, as around the iOS view of the same name.
 *
 *      - The tab bar controller is built once the view is attached with a real width, in its [FragmentActivity] (the
 *        context's, or [activityProvider]'s).
 *      - Image values given as URL strings are downloaded on a background thread first; [imageResolver] handles other values
 *        (e.g. a Flutter asset); names and paths go to the library as they are.
 *      - Each view uses its own `CYLTabBarControllerContext` unless the configuration gives one.
 *      - Indexes ([selectedIndex], [badgeValues], [didSelectTab]) count the tabs of the configuration; the plus button is
 *        left out.
 *      - The bar sits at the bottom of the screen: it keeps the navigation bar's inset and drops the status bar's.
 * [CN] 只显示 TabBar 的视图：TabBar 来自根据配置创建的 [CYLTabBarController]。页面由别人绘制：React Native、Flutter，或自己绘制内容的 App；
 *      每个 Tab 得到一个空页面。`CrossPlatform/` 中的 React Native 与 Flutter 组件都是它的薄封装，与 iOS 同名视图相同。
 *
 *      - 视图附加到 window 并有真实宽度后，才在其 [FragmentActivity]（context 的或 [activityProvider] 的）中创建 TabBarController。
 *      - 以 URL 字符串给出的图片先在后台线程下载；其他值（例如 Flutter asset）由 [imageResolver] 处理；名称与路径原样交给库。
 *      - 配置没有给出 `CYLTabBarControllerContext` 时，每个视图使用自己的 context。
 *      - 下标（[selectedIndex]、[badgeValues]、[didSelectTab]）按配置中的 Tab 计算，不含 PlusButton。
 *      - TabBar 位于屏幕底部：保留导航栏的 inset，去掉状态栏的。
 */
open class CYLTabBarHostView @JvmOverloads constructor(context: Context, attrs: AttributeSet? = null) : FrameLayout(context, attrs) {

    /** [EN] The configuration; setting it rebuilds the tab bar. [CN] 配置；设置后重新创建 TabBar。 */
    var configuration: Map<String, Any?>? = null
        set(value) {
            field = value
            generation++
            pendingConfiguration = null
            if (value == null) removeController() else loadImages(value, generation)
        }

    /** [EN] The activity that hosts the fragments; by default the one the view's context wraps. [CN] 承载 Fragment 的 Activity；默认为视图 context 所包装的 Activity。 */
    var activityProvider: () -> FragmentActivity? = { findActivity(context) }

    /** [EN] Turns an image value into a Drawable on a background thread; null lets the view handle it. [CN] 在后台线程把图片值转为 Drawable；返回 null 时由视图处理。 */
    var imageResolver: ((Any?) -> Drawable?)? = null

    /** [EN] The selected tab, -1 to leave it to the user's taps. [CN] 选中的 Tab，-1 表示由用户点击决定。 */
    var selectedIndex: Int = -1
        set(value) {
            field = value
            applySelectedIndex()
        }

    /** [EN] A badge per tab: "" none, "dot" a red dot, anything else a text. [CN] 每个 Tab 一个角标：""无，"dot"红点，其他为文字。 */
    var badgeValues: List<String> = emptyList()
        set(value) {
            field = value
            applyBadgeValues()
        }

    /** [EN] The plus button's badge: "" or null none, "dot" a red dot, anything else a text. [CN] PlusButton 的角标："" 或 null 无，"dot" 红点，其他为文字。 */
    var plusButtonBadgeValue: String? = null
        set(value) {
            field = value
            applyBadgeValues()
        }

    /** [EN] The animation of text badges (tabs and plus button). [CN] 文字角标（Tab 与 PlusButton）的动画。 */
    var badgeAnimationType: CYLEnums.CYLBadgeAnimationType = CYLEnums.CYLBadgeAnimationType.None
        set(value) {
            field = value
            applyBadgeValues()
        }

    /** [EN] Also count what rises above the bar (plus button, badges) in [preferredHeight], for hosts that clip, like Flutter. [CN] [preferredHeight] 同时包含高出 TabBar 的部分，供会裁剪的宿主使用，例如 Flutter。 */
    var heightIncludesOverflow: Boolean = false

    /** [EN] The height the view needs, in dp; 0 before the tab bar is built. [CN] 视图需要的高度（dp）；创建 TabBar 之前为 0。 */
    var preferredHeight: Float = 0f
        private set

    /** [EN] A tab was tapped (index, identifier); the plus button's own page reports -1 and its identifier. [CN] 点击了 Tab（下标、标识）；PlusButton 自己的页面报告 -1 与其标识。 */
    var didSelectTab: ((index: Int, identifier: String) -> Unit)? = null
    /** [EN] A long press on a tab (its index) or on the plus button (-1), with the title it shows. [CN] 长按 Tab（其下标）或 PlusButton（-1），以及显示的标题。 */
    var didLongPressTab: ((index: Int, identifier: String, title: String) -> Unit)? = null
    var didTapPlusButton: (() -> Unit)? = null
    var preferredHeightDidChange: ((height: Float) -> Unit)? = null

    /**
     * [EN] The parts of the view that take touches, in dp in its coordinates: the tab bar, and the plus button with its
     *      badge. With [heightIncludesOverflow], the strip above the bar is transparent: a touch there outside these rects
     *      goes to the views below, and the bar's content sits below the strip, the plus button reaching into it. Hosts
     *      that hit-test themselves (Flutter) read them; empty before the tab bar is built.
     * [CN] 视图中接收触摸的部分（dp，视图坐标）：TabBar，以及 PlusButton 与其角标。[heightIncludesOverflow] 时 TabBar 上方的区域是透明的：落在这些
     *      矩形之外的触摸交给下方的视图；TabBar 的内容位于该区域下方，只有 PlusButton 伸入其中。自己做命中测试的宿主（Flutter）读取它；创建 TabBar 之前为空。
     */
    var touchableRects: List<RectF> = emptyList()
        private set
    var touchableRectsDidChange: ((rects: List<RectF>) -> Unit)? = null

    /** [EN] [touchableRects] in pixels. [CN] 以像素表示的 [touchableRects]。 */
    private var touchableRectsInPixels: List<Rect> = emptyList()

    /** [EN] The tab bar controller, null until it is built. [CN] TabBarController，创建之前为 null。 */
    var tabBarController: CYLTabBarController? = null
        private set

    private var generation = 0
    private var pendingConfiguration: Map<String, Any?>? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        // [EN] The plus button and the badges rise above the bar. [CN] PlusButton 与角标会高出 TabBar。
        clipChildren = false
        clipToPadding = false
        ViewCompat.setOnApplyWindowInsetsListener(this) { _, insets ->
            val types = WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
            val bars = insets.getInsets(types)
            val bottomOnly = WindowInsetsCompat.Builder(insets).setInsets(types, Insets.of(bars.left, 0, bars.right, bars.bottom)).build()
            for (index in 0 until childCount) ViewCompat.dispatchApplyWindowInsets(getChildAt(index), bottomOnly)
            WindowInsetsCompat.CONSUMED
        }
    }

    /**
     * [EN] With [heightIncludesOverflow], a touch that starts in the transparent strip, away from the plus button and its
     *      badge, is not taken: the parent gives it to the views below.
     * [CN] [heightIncludesOverflow] 时，从透明区域开始、且不在 PlusButton 与其角标上的触摸不被接收：父视图把它交给下方的视图。
     */
    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        if (event.actionMasked == MotionEvent.ACTION_DOWN && heightIncludesOverflow && touchableRectsInPixels.isNotEmpty() &&
            touchableRectsInPixels.none { it.contains(event.x.toInt(), event.y.toInt()) }) return false
        return super.dispatchTouchEvent(event)
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        super.onLayout(changed, left, top, right, bottom)
        updateTouchableRects()
    }

    /** [EN] Sets [configuration] from JSON text; false (and nothing changes) when it is not a JSON object. [CN] 用 JSON 文本设置 [configuration]；不是 JSON 对象时返回 false 且不做修改。 */
    fun setConfigurationJSON(json: String?): Boolean {
        val map = runCatching { toMap(JSONObject(json ?: return false)) }.getOrNull() ?: return false
        configuration = map
        return true
    }

    // MARK: - Images

    private fun loadImages(source: Map<String, Any?>, generation: Int) {
        val resolver = imageResolver
        imageLoader.execute {
            val resolved = configurationWithImages(source, resolver)
            mainHandler.post {
                if (generation != this.generation) return@post
                pendingConfiguration = resolved
                buildIfReady()
            }
        }
    }

    private fun configurationWithImages(source: Map<String, Any?>, resolver: ((Any?) -> Drawable?)?): Map<String, Any?> {
        val result = source.toMutableMap()
        (source[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] as? List<*>)?.let { items ->
            result[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] = items.mapIndexed { index, item ->
                val attributes = (item as? Map<*, *>)?.let { attributesWithImages(it, resolver).toMutableMap() } ?: return@mapIndexed item
                // [EN] Pages are looked up by page ID: a tab with neither a page ID nor an identifier would get no page, and no
                //      tab. The host's pages are empty anyway, so it gets one of its own; the identifier reported stays empty.
                // [CN] 页面按页面 ID 查找：既没有页面 ID 也没有 identifier 的 Tab 得不到页面，也就不会显示。宿主的页面本来就是空的，因此为它
                //      指定一个页面 ID；回调中的 identifier 仍为空。
                if ((attributes[CYLConstants.CYLTabBarItemPageIdentifier] as? String).isNullOrEmpty() && (attributes[CYLConstants.CYLTabBarItemIdentifier] as? String).isNullOrEmpty()) {
                    attributes[CYLConstants.CYLTabBarItemPageIdentifier] = "CYLTabBarHostView-tab-$index"
                }
                attributes
            }
        }
        (source[CYLConstants.CYLTabBarControllerPlusButton] as? Map<*, *>)?.let {
            result[CYLConstants.CYLTabBarControllerPlusButton] = attributesWithImages(it, resolver)
        }
        return result
    }

    private fun attributesWithImages(attributes: Map<*, *>, resolver: ((Any?) -> Drawable?)?): Map<String, Any?> {
        val result = attributes.entries.associate { it.key.toString() to it.value }.toMutableMap()
        for (key in listOf(CYLConstants.CYLTabBarItemImage, CYLConstants.CYLTabBarItemSelectedImage)) {
            val value = result[key] ?: continue
            (resolver?.invoke(value) ?: (value as? String)?.takeIf { it.contains("://") }?.let { urlImage(it) })?.let { result[key] = it }
        }
        return result
    }

    private fun urlImage(value: String): Drawable? {
        val bytes = runCatching { URL(value).openStream().use { it.readBytes() } }.getOrNull() ?: return null
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: return null
        return BitmapDrawable(resources, bitmap)
    }

    // MARK: - The tab bar controller

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        buildIfReady()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        post { buildIfReady() }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        // [EN] Rebuilt when attached again: the fragments cannot outlive the view tree. [CN] 再次附加时重新创建：Fragment 不能比视图树存活更久。
        if (tabBarController != null && configuration != null) {
            removeController()
            configuration = configuration
        }
    }

    private fun buildIfReady() {
        val source = pendingConfiguration ?: return
        if (!isAttachedToWindow || width <= 0) return
        val activity = activityProvider() ?: return
        pendingConfiguration = null
        removeController()
        val configuration = source.toMutableMap()
        if (configuration[CYLConstants.CYLTabBarControllerContext] !is String) {
            configuration[CYLConstants.CYLTabBarControllerContext] = "CYLTabBarHostView-${System.identityHashCode(this)}"
        }
        configuration[CYLConstants.CYLTabBarControllerPageResolver] = { _: String, _: Map<String, Any?> -> CYLTabBarHostEmptyPage() }
        configuration[CYLConstants.CYLTabBarControllerPageLookupOrder] = listOf(CYLTabBarPageSource.RESOLVER.key)
        (configuration[CYLConstants.CYLTabBarControllerPlusButton] as? Map<*, *>)?.let { plus ->
            val plusIdentifier = (plus[CYLConstants.CYLTabBarItemIdentifier] as? String).orEmpty()
            val plusHasPage = !(plus[CYLConstants.CYLTabBarItemPageIdentifier] as? String).isNullOrEmpty()
            configuration[CYLConstants.CYLTabBarControllerPlusButtonAction] = { _: CYLPlusButton ->
                didTapPlusButton?.invoke()
                // [EN] Its own page is shown: reported like iOS, index -1. [CN] 显示其自己的页面：与 iOS 相同，报告下标 -1。
                if (plusHasPage) didSelectTab?.invoke(-1, plusIdentifier)
            }
        }
        val controller = CYLTabBarController.tabBarControllerWithConfiguration(activity, configuration)
        if (controller.viewControllers.isEmpty()) return
        controller.delegate = object : CYLTabBarControllerDelegate {
            override fun tabBarController_didSelectViewController(tabBarController: CYLTabBarController, viewController: CYLViewController) {
                val index = tabBarController.viewControllers.indexOf(viewController)
                if (index >= 0) didSelectTab?.invoke(index, tabBarController.cyl_tabBarItemIdentifiers.getOrNull(index).orEmpty())
            }
        }
        controller.cyl_didLongPressControlBlock = { tabBarController, control ->
            val index = (control as? CYLTabBarItemButton)?.index ?: -1
            val identifier = if (index >= 0) tabBarController.cyl_tabBarItemIdentifiers.getOrNull(index).orEmpty() else plusIdentifier(configuration)
            val title = if (index >= 0) tabBarController.tabBarItems.getOrNull(index)?.title.orEmpty()
                else (configuration[CYLConstants.CYLTabBarControllerPlusButton] as? Map<*, *>)?.get(CYLConstants.CYLTabBarItemTitle)?.toString().orEmpty()
            didLongPressTab?.invoke(index, identifier, title)
        }
        tabBarController = controller
        preferredHeight = 0f
        addView(controller.view, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        (controller.view as? ViewGroup)?.clipChildren = false
        (parent as? ViewGroup)?.clipChildren = false
        ViewCompat.requestApplyInsets(this)
        controller.tabBar.addOnLayoutChangeListener { _, _, _, _, _, _, _, _, _ ->
            updatePreferredHeight()
            applyPlusButtonBadge()
        }
        applySelectedIndex()
        applyBadgeValues()
    }

    private fun plusIdentifier(configuration: Map<String, Any?>): String =
        ((configuration[CYLConstants.CYLTabBarControllerPlusButton] as? Map<*, *>)?.get(CYLConstants.CYLTabBarItemIdentifier) as? String).orEmpty()

    private fun removeController() {
        val controller = tabBarController ?: return
        val activity = controller.activity
        if (!activity.isFinishing && !activity.supportFragmentManager.isStateSaved) {
            activity.supportFragmentManager.beginTransaction().apply {
                controller.viewControllers.forEach { if (it.isAdded) remove(it) }
            }.commitNowAllowingStateLoss()
        }
        removeView(controller.view)
        tabBarController = null
        updateTouchableRects()
    }

    private fun applySelectedIndex() {
        val controller = tabBarController ?: return
        if (selectedIndex in controller.viewControllers.indices && controller.selectedIndex != selectedIndex) controller.selectedIndex = selectedIndex
    }

    private fun applyBadgeValues() {
        val controller = tabBarController ?: return
        val values = badgeValues
        val animation = badgeAnimationType
        // [EN] Badges sit on the tab buttons, which exist once the bar is laid out. [CN] 角标位于 Tab 按钮上，TabBar 布局后按钮才存在。
        controller.performWhenTabBarItemsReady { tabBarController ->
            tabBarController.tabBarItems.forEachIndexed { index, item ->
                when (val value = values.getOrNull(index).orEmpty()) {
                    "" -> item.cyl_clearBadge()
                    "dot" -> item.cyl_showBadge()
                    else -> item.cyl_showBadgeValue(value, animation)
                }
            }
            applyPlusButtonBadge()
        }
    }

    /** [EN] The plus button and the badge last shown on it. [CN] 最近显示角标的 PlusButton 与角标值。 */
    private var shownPlusButtonBadge: Pair<CYLPlusButton, String>? = null

    /**
     * [EN] The plus button joins the tab bar during a layout, possibly after the tab buttons: applied then too, and only when
     *      the button or the value changed, so an animated badge is not restarted by every layout.
     * [CN] PlusButton 在一次布局中加入 TabBar，可能晚于 Tab 按钮：因此布局时也应用一次，且仅在按钮或角标值变化时应用，避免每次布局都重新播放角标动画。
     */
    private fun applyPlusButtonBadge() {
        val plusButton = tabBarController?.tabBar?.plusButton ?: return
        val value = plusButtonBadgeValue.orEmpty()
        val shown = shownPlusButtonBadge
        if (shown != null && shown.first === plusButton && shown.second == value) return
        shownPlusButtonBadge = plusButton to value
        when (value) {
            "" -> plusButton.cyl_clearBadge()
            "dot" -> plusButton.cyl_showBadge()
            else -> plusButton.cyl_showBadgeValue(value, badgeAnimationType)
        }
        // [EN] A badge can rise above the plus button: measured again once it is laid out. [CN] 角标可能高出 PlusButton：布局后重新计算高度。
        plusButton.post { updatePreferredHeight() }
    }

    private fun updatePreferredHeight() {
        val tabBar = tabBarController?.tabBar ?: return
        if (tabBar.height <= 0) return
        val density = resources.displayMetrics.density
        var height = tabBar.height / density
        if (heightIncludesOverflow) {
            val plusButton = tabBar.plusButton
            var overflow = 0f
            if (plusButton != null && plusButton.isAttachedToWindow) {
                // [EN] The plus button and what sits on it, its badge first, which can rise above the button.
                // [CN] PlusButton 及其上的内容，尤其是可能高出按钮的角标。
                var top = plusButton.top + plusButton.translationY
                for (index in 0 until plusButton.childCount) {
                    val child = plusButton.getChildAt(index)
                    if (child.visibility == VISIBLE) top = minOf(top, plusButton.top + plusButton.translationY + child.top + child.translationY)
                }
                // [EN] And a little room for an animated badge (bounce, scale). [CN] 以及为动画角标（弹跳、缩放）留出的少许空间。
                overflow = maxOf(0f, -top) / density + BADGE_ANIMATION_ROOM_DP
            }
            height += maxOf(overflow, BADGE_ROOM_DP)
        }
        height = kotlin.math.ceil(height)
        placeContentBelowStrip(if (heightIncludesOverflow) maxOf(0, (height * density).toInt() - tabBar.height) else 0)
        updateTouchableRects()
        if (kotlin.math.abs(height - preferredHeight) < 0.5f) return
        preferredHeight = height
        preferredHeightDidChange?.invoke(height)
    }

    /**
     * [EN] The bar's content starts below the strip, so nothing but the plus button and its badge covers it: hosts that
     *      hit-test the view tree (React Native) find nothing there.
     * [CN] TabBar 的内容从透明区域下方开始，除 PlusButton 与其角标外没有视图覆盖该区域：按视图树做命中测试的宿主（React Native）在那里找不到视图。
     */
    private fun placeContentBelowStrip(strip: Int) {
        val content = tabBarController?.view ?: return
        val params = content.layoutParams as? LayoutParams ?: return
        if (params.topMargin == strip) return
        params.topMargin = strip
        content.layoutParams = params
    }

    private fun updateTouchableRects() {
        val tabBar = tabBarController?.tabBar
        val rects = mutableListOf<Rect>()
        if (tabBar != null && tabBar.isLaidOut) {
            rects += rectInView(tabBar, Rect(0, 0, tabBar.width, tabBar.height))
            val plusButton = tabBar.plusButton
            if (plusButton != null && plusButton.isAttachedToWindow && plusButton.visibility == VISIBLE) {
                val frame = Rect(0, 0, plusButton.width, plusButton.height)
                for (index in 0 until plusButton.childCount) {
                    val child = plusButton.getChildAt(index)
                    if (child.visibility == VISIBLE) frame.union(child.left + child.translationX.toInt(), child.top + child.translationY.toInt(), child.right + child.translationX.toInt(), child.bottom + child.translationY.toInt())
                }
                val plusRect = rectInView(plusButton, frame)
                rects += plusRect
                // [EN] The part of the plus button in the strip lies outside the content: this view hands its touches over.
                // [CN] PlusButton 位于透明区域中的部分在内容之外：由本视图转交其触摸。
                touchDelegate = if (heightIncludesOverflow) TouchDelegate(plusRect, plusButton) else null
            } else {
                touchDelegate = null
            }
        }
        if (rects == touchableRectsInPixels) return
        touchableRectsInPixels = rects
        val density = resources.displayMetrics.density
        touchableRects = rects.map { RectF(it.left / density, it.top / density, it.right / density, it.bottom / density) }
        touchableRectsDidChange?.invoke(touchableRects)
    }

    /** [EN] `rect`, in the coordinates of `view`, in this view's coordinates. [CN] 把 `view` 坐标中的 `rect` 转为本视图坐标。 */
    private fun rectInView(view: View, rect: Rect): Rect {
        val location = IntArray(2)
        val own = IntArray(2)
        view.getLocationInWindow(location)
        getLocationInWindow(own)
        return Rect(rect).apply { offset(location[0] - own[0], location[1] - own[1]) }
    }

    companion object {
        /** [EN] The room left above the icons for a badge, in dp. [CN] 图标上方为角标留出的空间（dp）。 */
        private const val BADGE_ROOM_DP = 8f
        /** [EN] The room an animated badge grows into, in dp. [CN] 动画角标放大时占用的空间（dp）。 */
        private const val BADGE_ANIMATION_ROOM_DP = 4f

        private val imageLoader = Executors.newCachedThreadPool()

        private fun findActivity(context: Context): FragmentActivity? {
            var current: Context? = context
            while (current is ContextWrapper) {
                if (current is FragmentActivity) return current
                current = current.baseContext
            }
            return null
        }

        /** [EN] A JSON object as the maps and lists of a configuration. [CN] 把 JSON 对象转为配置使用的 map 与 list。 */
        @JvmStatic
        fun toMap(json: JSONObject): Map<String, Any?> = json.keys().asSequence().associateWith { toValue(json.opt(it)) }

        private fun toValue(value: Any?): Any? = when (value) {
            is JSONObject -> toMap(value)
            is JSONArray -> (0 until value.length()).map { toValue(value.opt(it)) }
            JSONObject.NULL -> null
            else -> value
        }
    }
}
