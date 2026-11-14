package com.cyl.tabbar.demo

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLOffset
import com.cyl.tabbar.CYLPlusButton
import com.cyl.tabbar.CYLPlusButtonSubclassing
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.cyl_badgeStyleCount
import com.cyl.tabbar.cyl_badgeTitleForRow
import com.cyl.tabbar.cyl_showBadgeValue
import com.cyl.tabbar.cyl_simulateMemoryWarningAndShowResult
import com.cyl.tabbar.demokit.R
import com.google.android.material.bottomnavigation.BottomNavigationView

/**
 * [EN] Every row of the iOS Example's tab pages, in the iOS order (docs/Android-Demo-Migration.md lists them with their
 *      status). The four pages share the demo sections (the library's settings groups, the FlatDesign rows, the scroll
 *      hiding simulations, the skins, the jump rows), then add their own rows: Home the gallery and 30 badge rows, Message
 *      the tab bar pushes and 15 badge rows, Discover 15 badge rows, Me 30 badge rows.
 * [CN] iOS Example 各 Tab 页面的每一行，顺序与 iOS 相同（docs/Android-Demo-Migration.md 列出它们及状态）。四个页面共用演示 section（库的设置分组、
 *      扁平样式行、滚动隐藏模拟、皮肤、跳转行），然后加上各自的行：首页为展示页与 30 个角标行，消息为 push TabBar 的行与 15 个角标行，发现为 15 个
 *      角标行，我的为 30 个角标行。
 */
object DemoCatalog {
    const val HOME = "home"
    const val MESSAGE = "message"
    const val DISCOVER = "discover"
    const val ME = "me"
    /** [EN] Only the library's settings rows, as iOS `CYLSettingsDemoTableViewController` (the PAG, GIF and Rive examples). [CN] 只有库的设置行，对应 iOS `CYLSettingsDemoTableViewController`（PAG、GIF、Rive 示例）。 */
    const val SETTINGS = "settings"

    /** [EN] The tab bar controller context of the demo's plus button. [CN] 演示 PlusButton 所属的 TabBarController context。 */
    const val PLUS_CONTEXT = "CYLConfigurationDemo"

    fun sections(page: DemoListFragment): List<DemoSection> {
        val sections = ArrayList<DemoSection>()
        page.url?.let { url ->
            // [EN] The shared file gives this tab the page ID "web" with a URL parameter (docs/Tab-Page-Registry.md). [CN] 共用文件为此 Tab 指定页面 ID "web" 与 URL 参数（docs/Tab-Page-Registry.md）。
            sections += DemoSection("Page ID \"web\" · CYLTabBarItemPageParameters", listOf(DemoRow(url, { "Open in the browser" }) {
                startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, android.net.Uri.parse(url)))
            }))
        }
        if (page.page == SETTINGS) return sections + settingsSections(page)
        sections += DemoSection("General", listOf(languageRow(), memoryWarningRow()))
        sections += DemoSection("Tab bar appearance", appearanceRows() + flatDesignRows())
        sections += DemoScrollHide.section(page)
        sections += DemoSection("Update tabs in place", DemoInteractions.tabItemUpdateRows())
        sections += DemoSection("Tab pages, selection and login", DemoInteractions.pageRows())
        sections += DemoSection("PlusButton", DemoInteractions.plusButtonRows())
        sections += DemoSection("Skins: holiday and color themes (${DemoTheme.all.size})", DemoTheme.all.map(::themeRow))
        sections += DemoSection("Tab interactions", DemoInteractions.interactionRows())
        sections += DemoSection("No base class, and helpers", DemoInteractions.helperRows())
        sections += DemoSection("Configuration file", DemoConfiguration.rows())
        sections += DemoSection("Jump and compare", jumpRows())
        when (page.page) {
            HOME -> {
                sections += DemoSection("Tab Bar Gallery", listOf(DemoRow("Open the tab bar gallery",
                    { "Every scene is a tab bar built with the public API: styles, animations, badges, Lottie and the newer tab API" }) {
                    startActivity(android.content.Intent(requireContext(), DemoGalleryActivity::class.java))
                }))
                sections += DemoSection("Badges", badgeRows(page, maxOf(30, cyl_badgeStyleCount())))
            }
            MESSAGE -> {
                // [EN] Not on the first tab (AGENTS.md "Demo table rows"). [CN] 不放在第一个 Tab（AGENTS.md「Demo table rows」）。
                sections += playbackSection()
                sections += DemoSection("Badges", messageRows() + badgeRows(page, maxOf(15, cyl_badgeStyleCount())).drop(2))
            }
            DISCOVER -> sections += DemoSection("Badges", badgeRows(page, maxOf(15, cyl_badgeStyleCount())))
            else -> sections += DemoSection("Badges", badgeRows(page, maxOf(30, cyl_badgeStyleCount())))
        }
        return sections
    }

    /** [EN] The settings groups of the library, in the iOS order. [CN] 库的设置分组，顺序与 iOS 相同。 */
    private fun settingsSections(page: DemoListFragment) = listOf(
        DemoSection("General", listOf(languageRow(), memoryWarningRow())),
        DemoSection("Tab bar appearance", appearanceRows()),
        DemoScrollHide.section(page),
        DemoSection("Update tabs in place", DemoInteractions.tabItemUpdateRows()),
        DemoSection("Tab pages, selection and login", DemoInteractions.pageRows()),
        DemoSection("PlusButton", DemoInteractions.plusButtonRows()),
        DemoSection("Tab interactions", DemoInteractions.interactionRows()),
        DemoSection("No base class, and helpers", DemoInteractions.helperRows()),
        DemoSection("Configuration file", DemoConfiguration.rows()),
        playbackSection(),
    )

    /**
     * [EN] Playback of the tab icon animations: Play all, speed, loop (AGENTS.md "Animated icon examples").
     * [CN] Tab 图标动画的播放：全部播放、倍速、循环（AGENTS.md「Animated icon examples」）。
     */
    private fun playbackSection() = DemoSection("Playback", listOf(DemoRow("Tab icon animations: Play all, speed, loop", {
        val controller = tabBarController
        "Speed ${DemoPlaybackControls.speedText(controller?.tabBarItemAnimationSpeed?.takeIf { it > 0 && it.isFinite() } ?: 1f)}, loop ${if (controller?.tabBarItemAnimationLoops == true) "on" else "off"}; tap for the controls"
    }) {
        val controller = tabBarController ?: return@DemoRow
        DemoPlaybackControls.show(requireContext(), controller) { reload() }
    }))

    // MARK: - General 通用

    private fun languageRow() = DemoRow("Language", { "Current: " + (AppCompatDelegate.getApplicationLocales().toLanguageTags().ifEmpty { "system" }) }) {
        val tags = listOf("", "en", "zh-CN")
        val names = listOf("Follow the system", "English", getString(R.string.language_chinese))
        val current = tags.indexOf(AppCompatDelegate.getApplicationLocales().toLanguageTags()).coerceAtLeast(0)
        choose("Language", names, current) { index -> AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(tags[index])) }
    }

    private fun memoryWarningRow() = DemoRow(
        "Simulate a memory warning", { "Unloads the views of unselected tabs when unloadsUnselectedViewsOnMemoryWarning is on (#426), then lists each tab" },
    ) {
        tabBarController?.unloadsUnselectedViewsOnMemoryWarning = true
        cyl_simulateMemoryWarningAndShowResult()
    }

    // MARK: - Tab bar appearance TabBar 外观

    private val titleOffsets = listOf(0f, -4f, 4f)
    private var appearanceIndex = 0
    private val appearanceNames = listOf("System default", "Dark", "Centered capsule", "Green line")

    private fun appearanceRows() = listOf(
        DemoRow("Title offset (titlePositionAdjustment)", {
            val offset = tabBarController?.titlePositionAdjustment ?: CYLOffset.zero
            "Tap to cycle the vertical offset of every tab title, current: (${offset.horizontal}, ${offset.vertical})"
        }) {
            val controller = tabBarController ?: return@DemoRow
            val next = titleOffsets[(titleOffsets.indexOf(controller.titlePositionAdjustment.vertical) + 1) % titleOffsets.size]
            controller.titlePositionAdjustment = CYLOffset(0f, next)
            controller.tabBar.requestLayout()
            controller.tabBar.tabBarButtonArray.forEach { it.requestLayout() }
        },
        DemoRow("Liquid Glass surface tint (cyl_liquidGlassSurfaceOpacity)", {
            val opacity = tabBarController?.tabBar?.cyl_liquidGlassSurfaceOpacity ?: 0.4f
            "Android only: drag the slider to see the dock change, from clear glass (0) to a solid board (1); now ${"%.2f".format(opacity)}"
        }) {
            val controller = tabBarController ?: return@DemoRow
            DemoLiquidGlassSurface.showSlider(requireContext(), controller) { reload() }
        },
        DemoRow("standardAppearance theme (shared by Liquid Glass and FlatDesign)", { "Current: ${appearanceNames[appearanceIndex]}; tap for the next one" }) {
            val controller = tabBarController ?: return@DemoRow
            appearanceIndex = (appearanceIndex + 1) % appearanceNames.size
            applyAppearance(controller, appearanceIndex)
        },
        DemoRow("Skin (CYLThemeManager, issue #216)", { "Current: ${DemoTheme.currentName}" }) {
            choose("Choose a skin", DemoTheme.all.map { it.name }, DemoTheme.all.indexOfFirst { it.name == DemoTheme.currentName }) { DemoTheme.apply(DemoTheme.all[it].name) }
        },
        DemoRow("Shrink / hide the tab bar on scroll (issue #13)", {
            val controller = tabBarController
            "cyl_hidesTabBarOnScroll = ${controller?.cyl_hidesTabBarOnScroll}, cyl_tabBarMinimizeBehavior = ${controller?.cyl_tabBarMinimizeBehavior}"
        }) {
            val controller = tabBarController ?: return@DemoRow
            val behaviors = CYLEnums.CYLTabBarMinimizeBehavior.values().toList()
            choose("cyl_tabBarMinimizeBehavior", behaviors.map { it.name }, behaviors.indexOf(controller.cyl_tabBarMinimizeBehavior)) { index ->
                controller.cyl_tabBarMinimizeBehavior = behaviors[index]
                controller.cyl_hidesTabBarOnScroll = behaviors[index] != CYLEnums.CYLTabBarMinimizeBehavior.Never
            }
        },
    )

    /** [EN] The iOS `standardAppearance` themes, as the bar colors Android has. [CN] iOS 的 `standardAppearance` 主题，用 Android 的 TabBar 颜色表示。 */
    private fun applyAppearance(controller: CYLTabBarController, index: Int) {
        val (background, shadow, normal, selected) = when (index) {
            1 -> listOf(Color.rgb(20, 20, 20), Color.TRANSPARENT, Color.LTGRAY, Color.WHITE)
            2 -> listOf(null, null, Color.GRAY, Color.rgb(255, 45, 85))
            3 -> listOf(Color.WHITE, Color.rgb(52, 199, 89), Color.GRAY, Color.rgb(52, 199, 89))
            else -> listOf(null, 0x33000000, null, null)
        }
        controller.cyl_tabBarBackgroundColor = background
        controller.cyl_tabBarShadowColor = shadow
        controller.cyl_tabBarItemTitleColor = normal
        controller.cyl_tabBarItemImageColor = normal
        controller.cyl_tabBarItemSelectedTitleColor = selected
        controller.cyl_tabBarItemSelectedImageColor = selected
        controller.tabBar.tabBarButtonArray.forEachIndexed { tab, button ->
            // [EN] The centered capsule: a translucent pink background behind the selected tab. [CN] 居中胶囊：选中 Tab 后的半透明粉色背景。
            val capsule = if (index == 2) Color.argb(51, 255, 45, 85) else null
            controller.updateTabBarItemAtIndex(tab, mapOf(CYLConstants.CYLTabBarItemSelectedBackgroundColor to capsule))
            button.requestLayout()
        }
    }

    // MARK: - FlatDesign rows (CYLTabBarDemoSection) 扁平样式行

    private var savedTabBarHeight: Float? = null

    private fun flatDesignRows() = listOf(
        DemoRow("Show / hide the tab bar (setTabBarHidden:animated:)") {
            val controller = tabBarController ?: return@DemoRow
            controller.setTabBarHidden(controller.tabBar.visibility == View.VISIBLE, true)
        },
        DemoRow("Change the tab bar height", { "tabBarHeight = ${tabBarController?.tabBarHeight}" }) {
            val controller = tabBarController ?: return@DemoRow
            val original = savedTabBarHeight ?: controller.tabBarHeight.also { savedTabBarHeight = it }
            controller.tabBarHeight = if (controller.tabBarHeight == original) original + 20 else original
            controller.tabBar.requestLayout()
        },
        DemoRow("Tab items not centered (system layout)") { setItemsCentered(tabBarController, false) },
        DemoRow("Tab items centered") { setItemsCentered(tabBarController, true) },
        DemoRow("Set the tab item background color", { "CYLTabBarItemBackgroundColor / CYLTabBarItemSelectedBackgroundColor" }) {
            val controller = tabBarController ?: return@DemoRow
            val on = controller.tabBarItemAttributesAtIndex(0)?.get(CYLConstants.CYLTabBarItemBackgroundColor) == null
            controller.tabBarItemsAttributes.indices.forEach { index ->
                controller.updateTabBarItemAtIndex(index, mapOf(
                    CYLConstants.CYLTabBarItemBackgroundColor to if (on) Color.rgb(255, 240, 200) else null,
                    CYLConstants.CYLTabBarItemSelectedBackgroundColor to if (on) Color.rgb(255, 204, 0) else null))
            }
        },
    )

    /** [EN] Centered items: tabs packed around the middle with a fixed width (`cyl_itemEdgeInsets`). [CN] 居中：Tab 以固定宽度集中在中间（`cyl_itemEdgeInsets`）。 */
    private fun setItemsCentered(controller: CYLTabBarController?, centered: Boolean) {
        val tabBar = controller?.tabBar ?: return
        val inset = if (centered) tabBar.tabBarItemWidth * 0.15f else 0f
        tabBar.cyl_itemEdgeInsets = com.cyl.tabbar.CYLEdgeInsets(0f, inset, 0f, inset)
        tabBar.requestLayout()
    }

    // MARK: - Skins 皮肤

    private fun themeRow(theme: DemoTheme) = DemoRow((if (theme.name == DemoTheme.currentName) "✓ " else "") + theme.name) { DemoTheme.apply(theme.name) }

    // MARK: - Jump and compare 跳转与对比

    private fun jumpRows() = listOf(
        DemoRow("Compare with the system tab bar", { "BottomNavigationView, the Android system tab bar, with the same tabs" }) {
            DemoHostActivity.open(requireContext(), "BottomNavigationView") { activity -> systemTabBar(activity) }
        },
        DemoRow("Push to the system tab bar (another PlusButton)", { "The system bar has no plus button: a floating action button stands in" }) {
            DemoHostActivity.open(requireContext(), "System tab bar") { activity -> systemTabBar(activity, withPlus = true) }
        },
        DemoRow("Push to another CYLTabBarController (another PlusButton)", { "A tab bar controller of another context, with a square plus button" }) {
            DemoHostActivity.openTabBar(requireContext(), "Another plus button") { activity -> DemoTabs.controller(activity, SQUARE_PLUS_CONTEXT, squarePlus) }
        },
        DemoRow("cyl_pop / cyl_push methods", { "cyl_pushViewController, cyl_popSelectTabBarChildViewControllerAtIndex, cyl_pushOrPopToViewController" }) {
            DemoHostActivity.openTabBar(requireContext(), "cyl_pop / cyl_push") { activity -> DemoTabs.controller(activity, null, null) { DemoPopPushFragment() } }
        },
    )

    private fun systemTabBar(activity: FragmentActivity, withPlus: Boolean = false): View {
        val root = android.widget.LinearLayout(activity).apply { orientation = android.widget.LinearLayout.VERTICAL }
        val label = TextView(activity).apply { gravity = Gravity.CENTER; textSize = 18f; text = "Home" }
        root.addView(FrameLayout(activity).apply {
            addView(label, FrameLayout.LayoutParams(-1, -1))
            if (withPlus) addView(com.google.android.material.floatingactionbutton.FloatingActionButton(activity).apply {
                setImageResource(android.R.drawable.ic_input_add)
                setOnClickListener { label.text = "PlusButton" }
            }, FrameLayout.LayoutParams(-2, -2, Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL).apply { bottomMargin = 24 })
        }, android.widget.LinearLayout.LayoutParams(-1, 0, 1f))
        val bar = BottomNavigationView(activity)
        listOf("Home" to android.R.drawable.ic_menu_myplaces, "Message" to android.R.drawable.ic_dialog_email,
               "Discover" to android.R.drawable.ic_menu_compass, "Me" to android.R.drawable.ic_menu_my_calendar).forEachIndexed { index, (title, icon) ->
            bar.menu.add(0, index, index, title).setIcon(icon)
        }
        bar.setOnItemSelectedListener { item -> label.text = item.title; true }
        bar.getOrCreateBadge(1).number = 12
        root.addView(bar)
        return root
    }

    private const val SQUARE_PLUS_CONTEXT = "SquarePlus"
    private val squarePlus = object : CYLPlusButtonSubclassing {
        override fun plusButton(context: Context) = CYLPlusButton(context).apply {
            background = GradientDrawable().apply { cornerRadius = 12 * resources.displayMetrics.density; setColor(Color.rgb(255, 149, 0)) }
            setImageDrawable(androidx.core.content.ContextCompat.getDrawable(context, android.R.drawable.ic_menu_add))
            imageView.setColorFilter(Color.WHITE)
        }
        override fun tabBarContext() = SQUARE_PLUS_CONTEXT
    }

    // MARK: - Page rows 页面自己的行

    private fun messageRows() = listOf(
        DemoRow("Push a TabBarController of the same context (the same PlusButton class)", { cyl_badgeTitleForRow(0) }, 0) {
            val context = tabBarController?.context ?: PLUS_CONTEXT
            DemoHostActivity.openTabBar(requireContext(), "Same context") { activity -> DemoTabs.controller(activity, context, null) }
        },
        DemoRow("Push a TabBarController of a new context (PlusButton with a tappable X, issue #202)",
            { "Tap the X at the top right of the PlusButton: the X changes color at random and the PlusButton does not respond" }, 1) {
            DemoHostActivity.openTabBar(requireContext(), "Issue #202") { activity -> DemoTabs.controller(activity, CloseSubviewPlusButton.CONTEXT, CloseSubviewPlusButton.Provider) }
        },
    )

    private fun badgeRows(page: DemoListFragment, count: Int): List<DemoRow> = (0 until count).map { row ->
        DemoRow(cyl_badgeTitleForRow(row), { "${pageTitle(page.page)} CYLTabBarController on Android ${Build.VERSION.RELEASE}" }, row) {
            when (page.page) {
                HOME -> {
                    activity?.title = "Home($row)"
                    pushText("CYLBaseViewController", Color.rgb(255, 165, 0))
                }
                MESSAGE -> DemoHostActivity.openTabBar(requireContext(), "Alternate plus button") { activity -> DemoTabs.controller(activity, SQUARE_PLUS_CONTEXT, squarePlus) }
                DISCOVER -> pushText("CYLDetailsViewController (navigation bar hidden)", Color.rgb(90, 200, 250))
                else -> {
                    tabBarController?.tabBar?.tabBarButtonArray?.getOrNull(3)?.cyl_showBadgeValue(row.toString(), CYLEnums.CYLBadgeAnimationType.None)
                    pushText("testPush", Color.RED)
                }
            }
        }
    }

    private fun pageTitle(page: String) = when (page) { HOME -> "Home"; MESSAGE -> "Message"; DISCOVER -> "Discover"; else -> "Me" }
}

/**
 * [EN] Tab bar controllers the rows push: the four demo tabs, each a `DemoListFragment` (or the page `pageFactory`
 *      makes), with the plus button of `context`.
 * [CN] 演示行 push 的 TabBarController：四个演示 Tab，每个是 `DemoListFragment`（或 `pageFactory` 创建的页面），使用 `context` 的 PlusButton。
 */
object DemoTabs {
    val icons = listOf(android.R.drawable.ic_menu_myplaces, android.R.drawable.ic_dialog_email, android.R.drawable.ic_menu_compass, android.R.drawable.ic_menu_my_calendar)
    val titles = listOf("Home", "Message", "Discover", "Me")
    val pages = listOf(DemoCatalog.HOME, DemoCatalog.MESSAGE, DemoCatalog.DISCOVER, DemoCatalog.ME)

    /** [EN] The ObjC Example's tab images (copied into `assets/objc-example`), normal and selected. [CN] ObjC Example 的 Tab 图片（复制到 `assets/objc-example`），普通与选中。 */
    private val objcImages = listOf("home", "message", "fishpond", "account")

    fun attributes(context: Context, count: Int = 4): List<Map<String, Any?>> = (0 until count).map { index ->
        val name = objcImages[index % 4]
        mapOf(CYLConstants.CYLTabBarItemTitle to titles[index % 4] + (if (index >= 4) " ${index + 1}" else ""),
              CYLConstants.CYLTabBarItemImage to (DemoAssets.drawable(context, "${name}_normal") ?: androidx.core.content.ContextCompat.getDrawable(context, icons[index % 4])),
              CYLConstants.CYLTabBarItemSelectedImage to DemoAssets.drawable(context, "${name}_highlight"),
              CYLConstants.CYLTabBarItemIdentifier to pages[index % 4] + (if (index >= 4) "${index + 1}" else ""))
    }

    fun controller(activity: FragmentActivity, context: String?, plus: CYLPlusButtonSubclassing?, count: Int = 4,
                   pageFactory: ((Int) -> Fragment)? = null): CYLTabBarController {
        plus?.let { CYLPlusButton.registerPlusButton(it) }
        val pages = (0 until count).map { index -> pageFactory?.invoke(index) ?: DemoListFragment.newInstance(this.pages[index % 4]) }
        return CYLTabBarController(activity, pages, attributes(activity, count), CYLEnums.CYLTabBarStyleType.Default, context)
    }
}
