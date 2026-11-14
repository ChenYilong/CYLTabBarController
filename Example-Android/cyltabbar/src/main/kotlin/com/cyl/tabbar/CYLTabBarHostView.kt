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
import java.net.URI
import java.util.concurrent.Executors

/**
 * [EN] The page of every tab of a [CYLTabBarHostView]: the host draws the pages, so it is empty. [CN] [CYLTabBarHostView] 每个 Tab 的页面：页面由宿主绘制，因此为空。
 */
/**
 * [EN] The page of every tab of a host: an empty, transparent view, as the iOS host's pages, so a memory warning can unload
 *      it and selecting the tab loads it again (`CYLSimulateMemoryWarningReport`).
 * [CN] 宿主中每个 Tab 的页面：空白透明的视图，与 iOS 宿主的页面相同，因此内存警告可以卸载它，选中该 Tab 时重新加载
 *      （`CYLSimulateMemoryWarningReport`）。
 */
class CYLTabBarHostEmptyPage : Fragment() {
    override fun onCreateView(inflater: android.view.LayoutInflater, container: android.view.ViewGroup?, savedInstanceState: android.os.Bundle?): View =
        View(inflater.context)
}

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

    /**
     * [EN] The configuration; setting it rebuilds the tab bar. [CN] 配置；设置后重新创建 TabBar。
     */
    var configuration: Map<String, Any?>? = null
        set(value) {
            field = value
            reloadConfiguration()
        }

    /**
     * [EN] Builds the controller again from `configuration` (images first). [CN] 由 `configuration` 重新创建控制器（先加载图片）。
     */
    private fun reloadConfiguration() {
        generation++
        pendingConfiguration = null
        val current = configuration
        if (current == null) removeController() else loadImages(current, generation)
    }

    /**
     * [EN] The activity that hosts the fragments; by default the one the view's context wraps. [CN] 承载 Fragment 的 Activity；默认为视图 context 所包装的 Activity。
     */
    var activityProvider: () -> FragmentActivity? = { findActivity(context) }

    /**
     * [EN] Turns an image value into a Drawable on a background thread; null lets the view handle it. [CN] 在后台线程把图片值转为 Drawable；返回 null 时由视图处理。
     */
    var imageResolver: ((Any?) -> Drawable?)? = null

    /**
     * [EN] The selected tab, -1 to leave it to the user's taps. [CN] 选中的 Tab，-1 表示由用户点击决定。
     */
    var selectedIndex: Int = -1
        set(value) {
            field = value
            applySelectedIndex()
        }

    /**
     * [EN] A badge per tab: "" none, "dot" a red dot, anything else a text. [CN] 每个 Tab 一个角标：""无，"dot"红点，其他为文字。
     */
    var badgeValues: List<String> = emptyList()
        set(value) {
            field = value
            applyBadgeValues()
        }

    /**
     * [EN] The plus button's badge: "" or null none, "dot" a red dot, anything else a text. [CN] PlusButton 的角标："" 或 null 无，"dot" 红点，其他为文字。
     */
    var plusButtonBadgeValue: String? = null
        set(value) {
            field = value
            applyBadgeValues()
        }

    /**
     * [EN] The animation of text badges (tabs and plus button). [CN] 文字角标（Tab 与 PlusButton）的动画。
     */
    var badgeAnimationType: CYLEnums.CYLBadgeAnimationType = CYLEnums.CYLBadgeAnimationType.None
        set(value) {
            field = value
            applyBadgeValues()
        }

    /**
     * [EN] Badges with a style, one per tab, taking precedence over [badgeValues] for the tabs they cover: maps with
     *      [BADGE_VALUE] (as in [badgeValues]), and optionally [BADGE_COLOR] ("#RRGGBB" or a color Int), [BADGE_ANIMATION]
     *      (a [CYLEnums.CYLBadgeAnimationType], its raw value or its name: "scale", "shake", "bounce", "breathe"...),
     *      [BADGE_RADIUS] (the dot's radius, dp) and [BADGE_CENTER_OFFSET] ([x, y] in dp). An empty map or null leaves the
     *      tab to [badgeValues]. As `badgeAttributes` on iOS.
     * [CN] 带样式的角标，每个 Tab 一个，覆盖 [badgeValues] 中对应的 Tab：map 包含 [BADGE_VALUE]（写法同 [badgeValues]），可选 [BADGE_COLOR]
     *      （"#RRGGBB" 或颜色 Int）、[BADGE_ANIMATION]（[CYLEnums.CYLBadgeAnimationType]、其 rawValue 或名称："scale"、"shake"、"bounce"、
     *      "breathe" 等）、[BADGE_RADIUS]（红点半径，dp）与 [BADGE_CENTER_OFFSET]（[x, y]，dp）。空 map 或 null 表示该 Tab 使用 [badgeValues]。
     *      与 iOS 的 `badgeAttributes` 相同。
     */
    var badgeAttributes: List<Map<String, Any?>?> = emptyList()
        set(value) {
            field = value
            applyBadgeValues()
        }

    /**
     * [EN] The plus button's badge with a style, as an entry of [badgeAttributes]; wins over [plusButtonBadgeValue]. [CN] 带样式的 PlusButton 角标，写法同 [badgeAttributes] 的一项；优先于 [plusButtonBadgeValue]。
     */
    var plusButtonBadgeAttributes: Map<String, Any?>? = null
        set(value) {
            field = value
            applyBadgeValues()
        }

    /**
     * [EN] An image covering each tab's icon in both states ([CYLTabBarItemButton.cyl_coverView]), or null for none: a
     *      Drawable, a drawable name, a file path or a URL (loaded on a background thread, or by [imageResolver]).
     * [CN] 覆盖每个 Tab 图标的图片（两种状态，[CYLTabBarItemButton.cyl_coverView]），null 表示没有：Drawable、drawable 名称、文件路径或
     *      URL（在后台线程加载，或由 [imageResolver] 加载）。
     */
    var tabCoverImages: List<Any?> = emptyList()
        set(value) {
            field = value
            loadTabCoverImages(value)
        }

    /**
     * [EN] Also count what rises above the bar (plus button, badges) in [preferredHeight], for hosts that clip, like Flutter. [CN] [preferredHeight] 同时包含高出 TabBar 的部分，供会裁剪的宿主使用，例如 Flutter。
     */
    var heightIncludesOverflow: Boolean = false

    /**
     * [EN] The height the view needs, in dp; 0 before the tab bar is built. [CN] 视图需要的高度（dp）；创建 TabBar 之前为 0。
     */
    var preferredHeight: Float = 0f
        private set

    /**
     * [EN] A tab was tapped (index, identifier); the plus button's own page reports -1 and its identifier. [CN] 点击了 Tab（下标、标识）；PlusButton 自己的页面报告 -1 与其标识。
     */
    var didSelectTab: ((index: Int, identifier: String) -> Unit)? = null
    /**
     * [EN] A long press on a tab (its index) or on the plus button (-1), with the title it shows. [CN] 长按 Tab（其下标）或 PlusButton（-1），以及显示的标题。
     */
    var didLongPressTab: ((index: Int, identifier: String, title: String) -> Unit)? = null
    var didTapPlusButton: (() -> Unit)? = null

    /**
     * [EN] Login (#19), as iOS: [loggedIn] is the controller's `cyl_loggedIn`. While logged out, a tap on a tab listed in
     *      `CYLTabBarControllerLoginRequiredTabBarItemIdentifiers` does not select it: [didRequestLogin] reports it (index,
     *      identifier, title), and the app shows its login screen, then sets [loggedIn] and [selectedIndex] once logged in.
     *      Logging out while such a tab is selected selects the first tab that does not need login, reported by [didSelectTab].
     * [CN] 登录（#19），与 iOS 相同：[loggedIn] 即控制器的 `cyl_loggedIn`。未登录时，点击需要登录的 Tab 不会选中它：[didRequestLogin] 报告该 Tab，
     *      App 展示登录界面，登录后设置 [loggedIn] 与 [selectedIndex]。选中这类 Tab 时退出登录，会选中第一个不需要登录的 Tab，并通过 [didSelectTab] 报告。
     */
    var loggedIn: Boolean = false
        set(value) {
            field = value
            loggedInSet = true
            val controller = tabBarController ?: return
            if (controller.cyl_loggedIn == value) return
            val before = controller.selectedIndex
            controller.cyl_loggedIn = value
            // [EN] A selection the app set while logged out (it may come before the login state) is applied now.
            // [CN] App 在未登录时设置的选中（可能先于登录状态到达）现在生效。
            if (value) return applySelectedIndex()
            val after = controller.selectedIndex
            if (after != before && after >= 0) didSelectTab?.invoke(after, controller.cyl_tabBarItemIdentifiers.getOrNull(after).orEmpty())
        }
    var didRequestLogin: ((index: Int, identifier: String, title: String) -> Unit)? = null
    /**
     * [EN] The playback speed of every tab icon animation (`tabBarItemAnimationSpeed`); 0 or less: the library's default.
     *      Applies to the animations already playing.
     * [CN] 所有 Tab 图标动画的播放速度（`tabBarItemAnimationSpeed`）；0 或更小表示库的默认值。对正在播放的动画同样生效。
     */
    var animationSpeed: Float = 0f
        set(value) {
            field = value
            if (value > 0 && value.isFinite()) tabBarController?.tabBarItemAnimationSpeed = value
        }
    /**
     * [EN] Whether the tab icon animations repeat until this is turned off (`tabBarItemAnimationLoops`); applies to the
     *      animations already playing.
     * [CN] Tab 图标动画是否重复播放直到关闭（`tabBarItemAnimationLoops`）；对正在播放的动画同样生效。
     */
    var animationLoops: Boolean = false
        set(value) {
            field = value
            tabBarController?.tabBarItemAnimationLoops = value
        }
    /**
     * [EN] "Play all": every tab icon animation plays again from progress 0, with the speed and loop settings above
     *      (`cyl_playAllTabBarItemAnimations`).
     * [CN] 「全部播放」：每个 Tab 图标动画按上面的速度与循环设置从进度 0 重新播放（`cyl_playAllTabBarItemAnimations`）。
     */
    fun playAllAnimations() {
        tabBarController?.cyl_playAllTabBarItemAnimations()
    }
    /**
     * [EN] The login state the tab bar uses, reported once it is built: until the app sets [loggedIn], the state the library
     *      cached (`cyl_loggedIn`, kept across launches), so the app can start from it.
     * [CN] TabBar 使用的登录状态，在 TabBar 创建后报告：App 设置 [loggedIn] 之前为库缓存的状态（`cyl_loggedIn`，重启后保留），App 可以从它开始。
     */
    var loginStateDidChange: ((loggedIn: Boolean) -> Unit)? = null
    /**
     * [EN] The app set [loggedIn]. [CN] App 设置过 [loggedIn]。
     */
    private var loggedInSet = false

    /**
     * [EN] Forgets the state the app set with [loggedIn]: the next tab bar built uses the cached state again. [CN] 忘记 App 通过 [loggedIn] 设置的状态：之后创建的 TabBar 重新使用缓存的状态。
     */
    fun resetLoggedIn() {
        loggedInSet = false
    }

    /**
     * [EN] The language of the library's own texts and of the layout direction, as the iOS host: a BCP 47 tag such as "ar"
     *      or "zh-Hans", or null for the device language. Sets [CYLLocalization.language], lays the tab bar out right to
     *      left for a right-to-left language, and builds the tab bar again, as the Objective-C example rebuilds its root.
     *      The tab titles come from the configuration: translate them there.
     * [CN] 库自身文字与布局方向使用的语言，与 iOS 宿主相同：BCP 47 语言标签，如 "ar"、"zh-Hans"；null 表示设备语言。设置
     *      [CYLLocalization.language]，从右到左的语言使 TabBar 从右到左布局，并重新创建 TabBar，与 Objective-C 示例重建根控制器相同。
     *      Tab 标题来自配置：请在配置中翻译。
     */
    /**
     * [EN] Hides or shows the tab bar, animated (`CYLTabBarController.setTabBarHidden`), as the iOS host. A hidden tab bar
     *      takes no touches: [touchableRects] is empty and the page under it gets them.
     * [CN] 隐藏或显示 TabBar（带动画，`CYLTabBarController.setTabBarHidden`），与 iOS 宿主相同。隐藏的 TabBar 不接收触摸：
     *      [touchableRects] 为空，触摸交给其下方的页面。
     */
    var tabBarHidden: Boolean = false
        set(value) {
            if (field == value) return
            field = value
            tabBarController?.setTabBarHidden(value, true)
            updateTouchableRects()
        }

    /**
     * [EN] Simulates a memory warning for the tab bar controller and returns what happened to each tab, one line per tab,
     *      in [CYLLocalization.language] (`CYLSimulateMemoryWarningReport`, #426), as the iOS host. The configuration decides
     *      what is unloaded: `CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning`, `CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers`.
     * [CN] 对 TabBarController 模拟内存警告，并返回每个 Tab 的结果（每个 Tab 一行），使用 [CYLLocalization.language]
     *      （`CYLSimulateMemoryWarningReport`，#426），与 iOS 宿主相同。卸载哪些 Tab 由配置决定。
     */
    fun simulateMemoryWarning(): String = CYLSimulateMemoryWarningReport(context, tabBarController)

    /**
     * [EN] The title offset of every tab, set at runtime (`CYLTabBarController.titlePositionAdjustment`) without building the
     *      tab bar again; it wins over the configuration's `CYLTabBarControllerTitlePositionAdjustment`, as the iOS host. A
     *      plus button that aligns its title follows. null keeps the configuration's.
     * [CN] 所有 Tab 的标题偏移，在运行时设置（`CYLTabBarController.titlePositionAdjustment`），不重新创建 TabBar；优先于配置中的
     *      `CYLTabBarControllerTitlePositionAdjustment`，与 iOS 宿主相同。对齐标题的 PlusButton 随之移动。null 时使用配置中的值。
     */
    var titlePositionAdjustment: CYLOffset? = null
        set(value) {
            if (field == value) return
            field = value
            if (value != null) tabBarController?.titlePositionAdjustment = value
        }

    var language: String? = null
        set(value) {
            if (field == value) return
            field = value
            CYLLocalization.language = value
            layoutDirection = when {
                value == null -> View.LAYOUT_DIRECTION_LOCALE
                CYLLocalization.isRightToLeft(value) -> View.LAYOUT_DIRECTION_RTL
                else -> View.LAYOUT_DIRECTION_LTR
            }
            if (tabBarController != null) reloadConfiguration()
        }
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

    /**
     * [EN] [touchableRects] in pixels. [CN] 以像素表示的 [touchableRects]。
     */
    private var touchableRectsInPixels: List<Rect> = emptyList()

    /**
     * [EN] The tab bar controller, null until it is built. [CN] TabBarController，创建之前为 null。
     */
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
        // [EN] A hidden tab bar takes no touches: they go to the page under it. [CN] 隐藏的 TabBar 不接收触摸：交给其下方的页面。
        if (event.actionMasked == MotionEvent.ACTION_DOWN && tabBarHidden) return false
        if (event.actionMasked == MotionEvent.ACTION_DOWN && heightIncludesOverflow && touchableRectsInPixels.isNotEmpty() &&
            touchableRectsInPixels.none { it.contains(event.x.toInt(), event.y.toInt()) }) return false
        return super.dispatchTouchEvent(event)
    }

    override fun onLayout(changed: Boolean, left: Int, top: Int, right: Int, bottom: Int) {
        super.onLayout(changed, left, top, right, bottom)
        updateTouchableRects()
    }

    /**
     * [EN] Sets [configuration] from JSON text; false (and nothing changes) when it is not a JSON object. [CN] 用 JSON 文本设置 [configuration]；不是 JSON 对象时返回 false 且不做修改。
     */
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
        for (key in listOf(CYLConstants.CYLTabBarItemImage, CYLConstants.CYLTabBarItemSelectedImage, CYLConstants.CYLTabBarItemDarkImage,
                CYLConstants.CYLTabBarItemSelectedDarkImage, CYLConstants.CYLPlusButtonBackgroundImage)) {
            val value = result[key] ?: continue
            (resolver?.invoke(value) ?: (value as? String)?.takeIf { it.contains("://") }?.let { urlImage(it) })?.let { result[key] = it }
        }
        return result
    }

    private fun urlImage(value: String): Drawable? {
        val bytes = runCatching { URI(value).toURL().openStream().use { it.readBytes() } }.getOrNull() ?: return null
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
            // [EN] Loading the same configuration again builds the controller on the next attach.
            // [CN] 再次加载同一配置，在下次附加时重新创建控制器。
            removeController()
            reloadConfiguration()
        }
    }

    /**
     * [EN] What a tap on the plus button reports. [CN] 点击 PlusButton 时报告的内容。
     */
    private fun plusButtonAction(plus: Map<*, *>): (CYLPlusButton) -> Unit {
        val plusIdentifier = (plus[CYLConstants.CYLTabBarItemIdentifier] as? String).orEmpty()
        val plusHasPage = !(plus[CYLConstants.CYLTabBarItemPageIdentifier] as? String).isNullOrEmpty()
        return {
            didTapPlusButton?.invoke()
            // [EN] Its own page is shown: reported like iOS, index -1. [CN] 显示其自己的页面：与 iOS 相同，报告下标 -1。
            if (plusHasPage) didSelectTab?.invoke(-1, plusIdentifier)
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
            configuration[CYLConstants.CYLTabBarControllerPlusButtonAction] = plusButtonAction(plus)
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
        // [EN] The app's state once it set one; until then the cached one. [CN] App 设置过时使用其状态；之前使用缓存的状态。
        // [EN] `tabBarController` is still unset here, so the setter only stores the value. [CN] 此时 `tabBarController` 尚未设置，setter 只保存值。
        if (loggedInSet) {
            controller.cyl_loggedIn = loggedIn
        } else {
            loggedIn = controller.cyl_loggedIn
            loggedInSet = false
        }
        loginStateDidChange?.invoke(loggedIn)
        if (animationSpeed > 0 && animationSpeed.isFinite()) controller.tabBarItemAnimationSpeed = animationSpeed
        controller.tabBarItemAnimationLoops = animationLoops
        // [EN] The app shows the login screen: the tab is not selected now (see [didRequestLogin]). [CN] 由 App 展示登录界面：此时不选中该 Tab。
        if (tabBarHidden) controller.setTabBarHidden(true, false)
        titlePositionAdjustment?.let { controller.titlePositionAdjustment = it }
        controller.cyl_loginHandler = { tabBarController, page, completion ->
            completion(false)
            val index = tabBarController.viewControllers.indexOf(page)
            didRequestLogin?.invoke(index, tabBarController.cyl_tabBarItemIdentifiers.getOrNull(index).orEmpty(), tabBarController.tabBarItems.getOrNull(index)?.title.orEmpty())
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
        applyTabCoverImages()
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
        val page = controller.viewControllers.getOrNull(selectedIndex) ?: return
        // [EN] Never a tab that needs login while logged out, whatever the order the app sets the values in (as iOS).
        // [CN] 未登录时不选中需要登录的 Tab，无论 App 以何种顺序设置这些值（与 iOS 相同）。
        if (!controller.cyl_loggedIn && controller.cyl_isLoginRequiredForViewController(page)) return
        if (controller.selectedIndex != selectedIndex) controller.selectedIndex = selectedIndex
    }

    private fun applyBadgeValues() {
        val controller = tabBarController ?: return
        // [EN] Badges sit on the tab buttons, which exist once the bar is laid out. The values are read when the block runs, not
        //      now: a block can wait for a layout pass for a long time (React Native lays this view out itself, outside one), and
        //      run after later values were applied, which it must not undo.
        // [CN] 角标位于 Tab 按钮上，TabBar 布局后按钮才存在。在 block 执行时读取值，而不是现在：block 可能长时间等待一次布局
        //      （React Native 自行布局本视图，不经过布局流程），并在之后的值应用后才执行，不能把它们改回去。
        controller.performWhenTabBarItemsReady { tabBarController ->
            val values = badgeValues
            val animation = badgeAnimationType
            val styles = badgeAttributes
            tabBarController.tabBarItems.forEachIndexed { index, item ->
                val button = item.cyl_visiableTabButton ?: return@forEachIndexed
                val style = styles.getOrNull(index)?.takeIf { it.isNotEmpty() } ?: mapOf(BADGE_VALUE to values.getOrNull(index).orEmpty())
                showBadge(button, style, animation)
            }
            applyPlusButtonBadge()
        }
    }

    /**
     * [EN] The plus button and the badge last shown on it. [CN] 最近显示角标的 PlusButton 与角标值。
     */
    private var shownPlusButtonBadge: Pair<CYLPlusButton, Map<String, Any?>>? = null

    /**
     * [EN] The plus button joins the tab bar during a layout, possibly after the tab buttons: applied then too, and only when
     *      the button or the value changed, so an animated badge is not restarted by every layout.
     * [CN] PlusButton 在一次布局中加入 TabBar，可能晚于 Tab 按钮：因此布局时也应用一次，且仅在按钮或角标值变化时应用，避免每次布局都重新播放角标动画。
     */
    private fun applyPlusButtonBadge() {
        val plusButton = tabBarController?.tabBar?.plusButton ?: return
        val style = plusButtonBadgeAttributes?.takeIf { it.isNotEmpty() } ?: mapOf(BADGE_VALUE to plusButtonBadgeValue.orEmpty())
        val shown = shownPlusButtonBadge
        if (shown != null && shown.first === plusButton && shown.second == style) return
        shownPlusButtonBadge = plusButton to style
        showBadge(plusButton, style, badgeAnimationType)
        // [EN] A badge can rise above the plus button: measured again once it is laid out. [CN] 角标可能高出 PlusButton：布局后重新计算高度。
        plusButton.post { updatePreferredHeight() }
    }

    /**
     * [EN] Shows the badge `style` describes on `target` (a tab button or the plus button), its look first. [CN] 在 `target`（Tab 按钮或 PlusButton）上显示 `style` 描述的角标，先设置外观。
     */
    private fun showBadge(target: View, style: Map<String, Any?>, fallback: CYLEnums.CYLBadgeAnimationType) {
        val text = when (val value = style[BADGE_VALUE]) { is String -> value; is Number -> value.toString(); else -> "" }
        when (val color = style[BADGE_COLOR]) {
            is Int -> target.cyl_badgeBackgroundColor = color
            is String -> CYLTabBarConfiguration.colorValue(color)?.let { target.cyl_badgeBackgroundColor = it }
        }
        (style[BADGE_RADIUS] as? Number)?.let { target.cyl_badgeRadius = it.toFloat() }
        (style[BADGE_CENTER_OFFSET] as? List<*>)?.takeIf { it.size == 2 }?.let { offset ->
            val x = (offset[0] as? Number)?.toFloat(); val y = (offset[1] as? Number)?.toFloat()
            if (x != null && y != null) target.cyl_badgeCenterOffset = CYLOffset(x, y)
        }
        val animation = badgeAnimation(style[BADGE_ANIMATION]) ?: fallback
        when (text) {
            "" -> target.cyl_clearBadge()
            // [EN] A dot animates only with an animation of its own, as on iOS. [CN] 红点仅在自身指定动画时播放，与 iOS 相同。
            "dot" -> if (style[BADGE_ANIMATION] == null) target.cyl_showBadge() else target.cyl_showBadgeValue("", animation)
            else -> target.cyl_showBadgeValue(text, animation)
        }
    }

    private fun badgeAnimation(value: Any?): CYLEnums.CYLBadgeAnimationType? = when (value) {
        is CYLEnums.CYLBadgeAnimationType -> value
        is Number -> CYLEnums.CYLBadgeAnimationType.entries.firstOrNull { it.rawValue == value.toInt() }
        is String -> CYLEnums.CYLBadgeAnimationType.entries.firstOrNull { it.name.equals(value, ignoreCase = true) }
        else -> null
    }

    /**
     * [EN] [tabCoverImages] loaded (Drawable or null). [CN] 已加载的 [tabCoverImages]（Drawable 或 null）。
     */
    private var loadedTabCoverImages: List<Drawable?>? = null
    private var coverGeneration = 0

    private fun loadTabCoverImages(values: List<Any?>) {
        val generation = ++coverGeneration
        val resolver = imageResolver
        imageLoader.execute {
            val images = values.map { value ->
                resolver?.invoke(value) ?: when (value) {
                    is Drawable -> value
                    is String -> if (value.contains("://")) urlImage(value) else CYLTabBarConfiguration.imageResolver.drawable(context, value)
                    else -> null
                }
            }
            mainHandler.post {
                if (generation != coverGeneration) return@post
                loadedTabCoverImages = images
                applyTabCoverImages()
            }
        }
    }

    /**
     * [EN] Covers the tab buttons with the loaded images; a tab without one shows its icon. [CN] 用已加载的图片覆盖 Tab 按钮；没有图片的 Tab 显示其图标。
     */
    private fun applyTabCoverImages() {
        val controller = tabBarController ?: return
        if (loadedTabCoverImages == null) return
        // [EN] Read when the block runs, as the badges. [CN] 与角标相同，在 block 执行时读取。
        controller.performWhenTabBarItemsReady { tabBarController ->
            val images = loadedTabCoverImages ?: return@performWhenTabBarItemsReady
            tabBarController.tabBarItems.forEachIndexed { index, item ->
                val button = item.cyl_visiableTabButton ?: return@forEachIndexed
                button.cyl_coverView = images.getOrNull(index)?.let { image ->
                    android.widget.ImageView(context).apply {
                        setImageDrawable(image.constantState?.newDrawable()?.mutate() ?: image)
                        importantForAccessibility = View.IMPORTANT_FOR_ACCESSIBILITY_NO
                    }
                }
            }
        }
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
        if (tabBar != null && tabBar.isLaidOut && !tabBarHidden) {
            rects += rectInView(tabBar, Rect(0, 0, tabBar.width, tabBar.height))
            val plusButton = tabBar.plusButton?.takeIf { it.isAttachedToWindow && it.visibility == VISIBLE }
            if (plusButton != null) {
                val plusRect = rectInView(plusButton, plusButtonFrame(plusButton))
                rects += plusRect
                // [EN] The part of the plus button in the strip lies outside the content: this view hands its touches over.
                // [CN] PlusButton 位于透明区域中的部分在内容之外：由本视图转交其触摸。
                touchDelegate = if (heightIncludesOverflow) TouchDelegate(plusRect, plusButton) else null
            } else {
                touchDelegate = null
            }
        }
        if (rects.isEmpty()) touchDelegate = null
        if (rects == touchableRectsInPixels) return
        touchableRectsInPixels = rects
        val density = resources.displayMetrics.density
        touchableRects = rects.map { RectF(it.left / density, it.top / density, it.right / density, it.bottom / density) }
        touchableRectsDidChange?.invoke(touchableRects)
    }

    /**
     * [EN] The plus button's frame with its visible children (its badge and a title that reach outside it), in its
     *      own coordinates.
     * [CN] PlusButton 及其可见子视图（超出其范围的角标与标题）的范围，以其自身坐标表示。
     */
    private fun plusButtonFrame(plusButton: CYLPlusButton): Rect {
        val frame = Rect(0, 0, plusButton.width, plusButton.height)
        for (index in 0 until plusButton.childCount) {
            val child = plusButton.getChildAt(index)
            if (child.visibility != VISIBLE) continue
            val dx = child.translationX.toInt()
            val dy = child.translationY.toInt()
            frame.union(child.left + dx, child.top + dy, child.right + dx, child.bottom + dy)
        }
        return frame
    }

    /**
     * [EN] `rect`, in the coordinates of `view`, in this view's coordinates. [CN] 把 `view` 坐标中的 `rect` 转为本视图坐标。
     */
    private fun rectInView(view: View, rect: Rect): Rect {
        val location = IntArray(2)
        val own = IntArray(2)
        view.getLocationInWindow(location)
        getLocationInWindow(own)
        return Rect(rect).apply { offset(location[0] - own[0], location[1] - own[1]) }
    }

    companion object {
        /**
         * [EN] Keys of [badgeAttributes] / [plusButtonBadgeAttributes], as on iOS. [CN] [badgeAttributes] / [plusButtonBadgeAttributes] 的键，与 iOS 相同。
         */
        const val BADGE_VALUE = "value"
        const val BADGE_COLOR = "color"
        const val BADGE_ANIMATION = "animation"
        const val BADGE_RADIUS = "radius"
        const val BADGE_CENTER_OFFSET = "centerOffset"

        /**
         * [EN] The room left above the icons for a badge, in dp. [CN] 图标上方为角标留出的空间（dp）。
         */
        private const val BADGE_ROOM_DP = 8f
        /**
         * [EN] The room an animated badge grows into, in dp. [CN] 动画角标放大时占用的空间（dp）。
         */
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

        /**
         * [EN] A JSON object as the maps and lists of a configuration. [CN] 把 JSON 对象转为配置使用的 map 与 list。
         */
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
