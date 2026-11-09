package com.cyl.tabbar.demo

import android.app.AlertDialog
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLEdgeInsets
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLFont
import com.cyl.tabbar.CYLPlusButton
import com.cyl.tabbar.CYLPlusButtonSubclassing
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.CYLTabButtonBlockAnimation
import com.cyl.tabbar.CYLTabButtonBounceAnimation
import com.cyl.tabbar.CYLTabButtonPressAnimation
import com.cyl.tabbar.CYLTabButtonScaleAnimation
import com.cyl.tabbar.cyl_badgeBackgroundColor
import com.cyl.tabbar.cyl_showBadge
import com.cyl.tabbar.cyl_showBadgeValue
import com.cyl.tabbar.cyl_tabButtonAnimation
import com.google.android.material.bottomnavigation.BottomNavigationView

/**
 * [EN] The tab bar gallery (docs/Tab-Bar-Gallery.md), ported from the iOS `CYLGalleryProvider`: the same 10 sections and
 *      46 scenes, each a tab bar built with the public API. Scenes that exist only in UIKit (the system "More" editor,
 *      `UITab`, the Liquid Glass plus stand-in) say so instead of faking it.
 * [CN] TabBar 场景展示（docs/Tab-Bar-Gallery.md），移植自 iOS 的 `CYLGalleryProvider`：同样的 10 个分组与 46 个场景，每个都是用公开 API 构建的
 *      TabBar。只存在于 UIKit 的场景（系统 "More" 编辑、`UITab`、液态玻璃 PlusButton 替身）会说明原因，而不是伪造。
 */
class DemoGalleryActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "Tab Bar Gallery"
        val items = DemoGallery.sections.flatMap { section -> listOf<Any>(section.first) + section.second }
        val list = ListView(this)
        list.adapter = object : android.widget.BaseAdapter() {
            override fun getCount() = items.size
            override fun getItem(position: Int) = items[position]
            override fun getItemId(position: Int) = position.toLong()
            override fun getViewTypeCount() = 2
            override fun getItemViewType(position: Int) = if (items[position] is String) 0 else 1
            override fun isEnabled(position: Int) = items[position] is DemoGallery.Scene
            override fun getView(position: Int, convertView: View?, parent: android.view.ViewGroup): View {
                val density = resources.displayMetrics.density
                return when (val item = items[position]) {
                    is String -> ((convertView as? TextView) ?: TextView(parent.context).apply {
                        setPadding((16 * density).toInt(), (18 * density).toInt(), (16 * density).toInt(), (6 * density).toInt())
                        setTextColor(Color.GRAY); setTypeface(typeface, Typeface.BOLD)
                    }).apply { text = item }
                    else -> {
                        val scene = item as DemoGallery.Scene
                        ((convertView as? LinearLayout) ?: LinearLayout(parent.context).apply {
                            orientation = LinearLayout.VERTICAL
                            setPadding((16 * density).toInt(), (10 * density).toInt(), (16 * density).toInt(), (10 * density).toInt())
                            addView(TextView(parent.context).apply { textSize = 15f })
                            addView(TextView(parent.context).apply { textSize = 12f; setTextColor(Color.GRAY) })
                        }).apply {
                            (getChildAt(0) as TextView).text = scene.title
                            (getChildAt(1) as TextView).text = scene.subtitle
                        }
                    }
                }
            }
        }
        list.setOnItemClickListener { _, _, position, _ -> (items[position] as? DemoGallery.Scene)?.open(this) }
        setContentView(list)
    }
}

object DemoGallery {
    class Scene(val title: String, val subtitle: String, private val unavailable: String? = null, private val build: ((DemoHostActivity) -> View)? = null) {
        fun open(context: Context) {
            if (build == null) {
                AlertDialog.Builder(context).setTitle(title).setMessage(unavailable ?: subtitle).setPositiveButton(android.R.string.ok, null).show()
            } else {
                DemoHostActivity.open(context, title, build)
            }
        }
    }

    private fun tabBar(title: String, subtitle: String, build: (DemoHostActivity) -> CYLTabBarController) =
        Scene(title, subtitle) { activity -> build(activity).also { activity.tabBarController = it }.view }

    private val titles = listOf("Home", "Video", "Photo", "Message", "Me", "Favor", "Shop", "Search")
    private val icons = listOf(android.R.drawable.ic_menu_myplaces, android.R.drawable.ic_media_play, android.R.drawable.ic_menu_camera,
        android.R.drawable.ic_dialog_email, android.R.drawable.ic_menu_my_calendar, android.R.drawable.btn_star, android.R.drawable.ic_menu_agenda, android.R.drawable.ic_menu_search)

    private fun attributes(context: Context, count: Int, extra: (Int) -> Map<String, Any?> = { emptyMap() }) = (0 until count).map { index ->
        mapOf(CYLConstants.CYLTabBarItemTitle to titles[index], CYLConstants.CYLTabBarItemImage to ContextCompat.getDrawable(context, icons[index]),
              CYLConstants.CYLTabBarItemIdentifier to titles[index].lowercase()) + extra(index)
    }

    /** [EN] A tab bar controller of `count` text pages. [CN] 由 `count` 个文字页面组成的 TabBarController。 */
    private fun controller(activity: FragmentActivity, count: Int, style: CYLEnums.CYLTabBarStyleType = CYLEnums.CYLTabBarStyleType.Default,
                           context: String? = null, extra: (Int) -> Map<String, Any?> = { emptyMap() },
                           page: (Int) -> Fragment = { TextPageFragment.newInstance(titles[it]) }): CYLTabBarController =
        CYLTabBarController(activity, (0 until count).map(page), attributes(activity, count, extra), style, context)

    /**
     * [EN] Issue #787: Home and Video are templates (one gray image, red / bar tint when selected), Favor keeps its yellow
     *      star although it has an icon color ("original"), Shop is "automatic" without an icon color (drawn as it is).
     * [CN] Issue #787：Home 与 Video 为模板（一张灰色图片，选中时为红色 / TabBar 着色），Favor 虽有图标颜色仍保持黄色星星（"original"），
     *      Shop 为 "automatic" 且没有图标颜色（按原图绘制）。
     */
    private fun iconRenderingController(activity: FragmentActivity, style: CYLEnums.CYLTabBarStyleType): CYLTabBarController {
        val star = { ContextCompat.getDrawable(activity, android.R.drawable.btn_star_big_on) }
        val tabs = listOf(
            mapOf(CYLConstants.CYLTabBarItemIconRenderingMode to "template", CYLConstants.CYLTabBarItemIconColor to Color.GRAY, CYLConstants.CYLTabBarItemSelectedIconColor to Color.rgb(255, 59, 48)),
            mapOf(CYLConstants.CYLTabBarItemIconRenderingMode to "template"),
            mapOf(CYLConstants.CYLTabBarItemIconRenderingMode to "original", CYLConstants.CYLTabBarItemIconColor to Color.GRAY, CYLConstants.CYLTabBarItemImage to star()),
            mapOf(CYLConstants.CYLTabBarItemImage to star()),
        )
        val pages = listOf(0, 1, 5, 6)
        val attributes = pages.mapIndexed { index, title ->
            mapOf(CYLConstants.CYLTabBarItemTitle to titles[title], CYLConstants.CYLTabBarItemImage to ContextCompat.getDrawable(activity, icons[title]),
                  CYLConstants.CYLTabBarItemIdentifier to titles[title].lowercase()) + tabs[index]
        }
        return CYLTabBarController(activity, pages.map { TextPageFragment.newInstance(titles[it]) }, attributes, style, null)
    }

    /** [EN] "Photo" opens a dialog instead of its page (`cyl_customActionTabBarItemIdentifiers`). [CN] "Photo" 打开弹窗而不是其页面。 */
    private fun photoOpensDialog(controller: CYLTabBarController) {
        controller.cyl_customActionTabBarItemIdentifiers = listOf("photo")
        controller.cyl_customActionBlock = { tabBarController, _ -> AlertDialog.Builder(tabBarController.activity).setMessage("Photo").setPositiveButton(android.R.string.ok, null).show() }
    }

    private fun systemBar(activity: FragmentActivity, count: Int, selected: Int = 0, badges: Boolean = false): View {
        val root = LinearLayout(activity).apply { orientation = LinearLayout.VERTICAL }
        val label = TextView(activity).apply { gravity = Gravity.CENTER; textSize = 18f }
        root.addView(label, LinearLayout.LayoutParams(-1, 0, 1f))
        val bar = BottomNavigationView(activity)
        // [EN] BottomNavigationView holds at most 5 items: the fifth becomes "More" with the others, as UIKit does. [CN] BottomNavigationView 最多 5 项：第 5 项成为 "More"，包含其余页面，与 UIKit 相同。
        val shown = if (count > 5) 4 else count
        (0 until shown).forEach { index -> bar.menu.add(0, index, index, titles[index]).setIcon(icons[index]) }
        if (count > 5) bar.menu.add(0, 4, 4, "More").setIcon(android.R.drawable.ic_menu_more)
        bar.setOnItemSelectedListener { item ->
            if (item.itemId == 4 && count > 5) {
                AlertDialog.Builder(activity).setTitle("More").setItems(titles.subList(4, count).toTypedArray()) { _, which -> label.text = titles[4 + which] }.show()
            } else label.text = item.title
            true
        }
        bar.selectedItemId = selected
        label.text = titles[selected]
        if (badges) { bar.getOrCreateBadge(0).number = 3; bar.getOrCreateBadge(1); bar.getOrCreateBadge(2).number = 120 }
        root.addView(bar)
        return root
    }

    private val bounce = { CYLTabButtonBounceAnimation() }

    val sections: List<Pair<String, List<Scene>>> by lazy {
        listOf(
            "Basic" to listOf(
                Scene("UITabBarController style", "The system tab bar, for comparison") { systemBar(it, 3) },
                tabBar("CYLTabBarController like system style", "Three tabs; full width") { controller(it, 3) },
                tabBar("Mix styled and system items", "Tabs 1, 3 and 5 bounce; tabs 2 and 4 are plain") { activity ->
                    controller(activity, 5).also { c -> c.viewControllers.forEachIndexed { index, page -> if (index % 2 == 0) page.cyl_tabButtonAnimation = bounce() } }
                },
                tabBar("CYLTabBarController with Liquid Glass", "\"Photo\" opens a dialog (cyl_customActionTabBarItemIdentifiers)") { activity ->
                    controller(activity, 5, CYLEnums.CYLTabBarStyleType.LiquidGlass).also(::photoOpensDialog)
                },
                Scene("UITabBarController with 'More'", "Eight tabs; the system bar holds five, the fifth is \"More\"") { systemBar(it, 8) },
                tabBar("CYLTabBarController with 'More'", "Eight tabs, full width") { controller(it, 8) },
                tabBar("Mix styled and system items with 'More'", "Eight tabs; every other one bounces") { activity ->
                    controller(activity, 8).also { c -> c.viewControllers.forEachIndexed { index, page -> if (index % 2 == 0) page.cyl_tabButtonAnimation = bounce() } }
                },
                tabBar("Liquid Glass with 'More'", "Eight tabs with Liquid Glass") { controller(it, 8, CYLEnums.CYLTabBarStyleType.LiquidGlass) },
                Scene("UITabBarController with non-zero default index", "selectedIndex = 2 after presenting") { systemBar(it, 5, selected = 2) },
                tabBar("CYLTabBarController with non-zero default index", "selectedIndex = 2 after presenting") { activity ->
                    controller(activity, 5).also { c -> c.view.post { c.selectedIndex = 2 } }
                },
                tabBar("Classic design on every system", "CYLTabBarStyleTypeFlatDesign, white bar; \"Photo\" opens a dialog") { activity ->
                    controller(activity, 5, CYLEnums.CYLTabBarStyleType.FlatDesign).also { c -> c.cyl_tabBarBackgroundColor = Color.WHITE; photoOpensDialog(c) }
                },
                tabBar("Liquid Glass with badges", "New, 99+, a blue 1, a dot, none; the selected tab hides its badge") { activity ->
                    controller(activity, 5, CYLEnums.CYLTabBarStyleType.LiquidGlass).also { c ->
                        c.cyl_hidesBadgeOfSelectedTab = true
                        c.performWhenTabBarItemsReady { ready ->
                            val buttons = ready.tabBar.tabBarButtonArray
                            buttons.getOrNull(0)?.cyl_showBadgeValue("New")
                            buttons.getOrNull(1)?.cyl_showBadgeValue("120")
                            buttons.getOrNull(2)?.let { it.cyl_badgeBackgroundColor = Color.rgb(0, 122, 255); it.cyl_showBadgeValue("1") }
                            buttons.getOrNull(3)?.cyl_showBadge()
                        }
                    }
                },
                Scene("UITabBarController tab style", "UITab (iOS 18+), eight tabs, \"Favor\" selected",
                    "n/a on Android: UITab and the iOS 18 tab sidebar are UIKit API. The 8-tab scenes above show the same tabs with CYLTabBarController."),
            ),
            "Embed" to listOf(
                tabBar("UINavigationController embeds CYLTabBarController", "One action bar above the tab bar controller") { controller(it, 4) },
                tabBar("CYLTabBarController embeds UINavigationController", "A navigation stack in every tab (cyl_pushViewController)") { activity ->
                    controller(activity, 4, page = { DemoPopPushFragment() })
                },
            ),
            "Animation" to listOf(
                tabBar("Customize the selected color", "CYLTabBarItemTitleColor / IconColor per tab") { activity ->
                    val colors = listOf(Color.rgb(255, 59, 48), Color.rgb(52, 199, 89), Color.rgb(0, 122, 255), Color.rgb(255, 149, 0))
                    controller(activity, 4, extra = { mapOf(CYLConstants.CYLTabBarItemSelectedTitleColor to colors[it], CYLConstants.CYLTabBarItemSelectedIconColor to colors[it]) })
                },
                tabBar("Spring animation", "A CYLTabButtonAnimation that bounces on select and reselect") { activity ->
                    controller(activity, 4).also { it.cyl_defaultTabButtonAnimation = CYLTabButtonBounceAnimation() }
                },
                tabBar("Background color change", "CYLTabBarItemBackgroundColor / SelectedBackgroundColor") { activity ->
                    controller(activity, 4, extra = { mapOf(CYLConstants.CYLTabBarItemBackgroundColor to Color.rgb(240, 240, 245), CYLConstants.CYLTabBarItemSelectedBackgroundColor to Color.rgb(255, 214, 10)) })
                },
                tabBar("With a pressed effect", "Larger icons that shrink while pressed (highlight hooks)") { activity ->
                    controller(activity, 4, extra = { mapOf(CYLConstants.CYLTabBarItemImageInsets to CYLEdgeInsets(-3f, -3f, -3f, -3f)) }).also { it.cyl_defaultTabButtonAnimation = CYLTabButtonPressAnimation() }
                },
                tabBar("Suggest a click", "The middle tab pulses every 3 s until it is selected") { activity ->
                    controller(activity, 5).also { c ->
                        repeating(1000, 3000) {
                            val pulses = c.selectedIndex != 2 && !activity.isFinishing
                            if (pulses) c.tabBar.tabBarButtonArray.getOrNull(2)?.let { CYLTabButtonScaleAnimation().cyl_playSelectAnimationWithTabButton(it, it.iconView, it.titleLabel) }
                            pulses
                        }
                    }
                },
            ),
            "Irregular" to listOf(
                tabBar("A larger button in the middle", "A raised round CYLPlusButton that responds inside its circle") { activity ->
                    CYLPlusButton.registerPlusButton(largePlus)
                    controller(activity, 4, context = LARGE_PLUS)
                },
            ),
            "Customize click" to listOf(
                tabBar("Custom action for the button click", "The center button shows an action sheet instead of a page") { activity ->
                    CYLPlusButton.registerPlusButton(actionPlus)
                    controller(activity, 4, context = ACTION_PLUS)
                },
                tabBar("Add a special reminder bubble", "A bubble above \"Me\"; \"Photo\" opens a dialog") { activity ->
                    controller(activity, 5).also { c ->
                        photoOpensDialog(c)
                        c.performWhenTabBarItemsReady { ready ->
                            val me = ready.tabBar.tabBarButtonArray.getOrNull(4) ?: return@performWhenTabBarItemsReady
                            val bubble = TextView(activity).apply {
                                text = "New gift!"; setTextColor(Color.WHITE); textSize = 11f; setPadding(16, 6, 16, 6)
                                background = GradientDrawable().apply { cornerRadius = 24f; setColor(Color.rgb(255, 59, 48)) }
                            }
                            val root = ready.view as android.view.ViewGroup
                            root.clipChildren = false
                            (root.parent as? android.view.ViewGroup)?.let { host ->
                                val frame = FrameLayout(activity)
                                host.removeView(root); frame.addView(root); host.addView(frame, -1, -1)
                                frame.addView(bubble, FrameLayout.LayoutParams(-2, -2, Gravity.BOTTOM or Gravity.START).apply {
                                    leftMargin = me.left + me.width / 2 - 60; bottomMargin = ready.tabBar.height + 4
                                })
                            }
                        }
                    }
                },
            ),
            "Remind" to listOf(
                Scene("System remind style", "BottomNavigationView badges on the system tab bar") { systemBar(it, 4, badges = true) },
                tabBar("Imitate system remind style", "The same badges on CYLTabBarController") { activity ->
                    controller(activity, 4).also { c -> c.performWhenTabBarItemsReady { r -> r.tabBar.tabBarButtonArray.let { b -> b[0].cyl_showBadgeValue("3"); b[1].cyl_showBadge(); b[2].cyl_showBadgeValue("120") } } }
                },
                tabBar("Remind with animation", "The icon jumps when the badge appears (CYLTabButtonBlockAnimation.badgeChangedAnimation)") { activity ->
                    badgeAnimationScene(activity) { _, icon, _ -> icon.animate().translationY(-12f).setDuration(150).withEndAction { icon.animate().translationY(0f).setDuration(150).start() }.start() }
                },
                tabBar("Remind with animation (2)", "The badge scales in when it appears (CYLTabButtonBlockAnimation.badgeChangedAnimation)") { activity ->
                    badgeAnimationScene(activity) { _, _, badge -> badge?.let { it.scaleX = 0f; it.scaleY = 0f; it.animate().scaleX(1f).scaleY(1f).setDuration(300).start() } }
                },
                tabBar("Customize remind style", "A gray bubble instead of the red badge") { activity ->
                    controller(activity, 4).also { c -> c.performWhenTabBarItemsReady { r -> r.tabBar.tabBarButtonArray.forEach { b -> b.cyl_badgeBackgroundColor = Color.GRAY; b.cyl_showBadgeValue("8") } } }
                },
            ),
            "Lottie" to listOf(
                tabBar("Lottie", "The middle tab loops its Lottie animation until it is selected (CYLTabBarLottieLoopsWhenUnselected)") { activity ->
                    controller(activity, 5, extra = { index ->
                        if (index == 2) mapOf(CYLConstants.CYLTabBarLottieURL to "https://raw.githubusercontent.com/airbnb/lottie-android/master/sample/src/main/res/raw/heart.json",
                                              CYLConstants.CYLTabBarLottieLoopsWhenUnselected to true) else emptyMap()
                    })
                },
            ),
            "New APIs" to listOf(
                tabBar("Reselect: pop to root, then scroll to top", "cyl_reselectBehavior = PopToRootThenScrollToTop") { activity ->
                    controller(activity, 4, page = { DemoPopPushFragment() }).also { it.cyl_reselectBehavior = CYLEnums.CYLTabBarReselectBehavior.PopToRootThenScrollToTop }
                },
                tabBar("Press and reselect animations", "CYLTabButtonPressAnimation + a reselect turn") { activity ->
                    controller(activity, 4).also { c ->
                        c.cyl_defaultTabButtonAnimation = CYLTabButtonBlockAnimation().apply {
                            highlightAnimation = { button, _, _ -> button.animate().scaleX(0.9f).scaleY(0.9f).setDuration(100).start() }
                            dehighlightAnimation = { button, _, _ -> button.animate().scaleX(1f).scaleY(1f).setDuration(100).start() }
                            reselectAnimation = { _, icon, _ -> icon.animate().rotationBy(360f).setDuration(400).start() }
                        }
                    }
                },
                tabBar("Custom action on a regular tab", "cyl_customActionTabBarItemIdentifiers + cyl_customTabActionHandler") { activity ->
                    controller(activity, 4).also { c ->
                        c.cyl_customActionTabBarItemIdentifiers = listOf("message")
                        c.cyl_customTabActionHandler = { tabBarController, _ -> android.widget.Toast.makeText(tabBarController.activity, "Custom action", android.widget.Toast.LENGTH_SHORT).show() }
                    }
                },
                tabBar("Per-tab colors, fonts and backgrounds", "Every tab has its own title color, font and background") { activity ->
                    val colors = listOf(Color.rgb(255, 59, 48), Color.rgb(52, 199, 89), Color.rgb(0, 122, 255), Color.rgb(175, 82, 222))
                    controller(activity, 4, extra = { index ->
                        mapOf(CYLConstants.CYLTabBarItemSelectedTitleColor to colors[index], CYLConstants.CYLTabBarItemTitleColor to Color.GRAY,
                              CYLConstants.CYLTabBarItemSelectedTitleFont to CYLFont(12f, Typeface.DEFAULT_BOLD),
                              CYLConstants.CYLTabBarItemSelectedBackgroundColor to Color.argb(40, Color.red(colors[index]), Color.green(colors[index]), Color.blue(colors[index])))
                    })
                },
                tabBar("Icon rendering mode (#787)", "template: one image, two colors · original: own colors · automatic") { activity ->
                    iconRenderingController(activity, CYLEnums.CYLTabBarStyleType.Default)
                },
                tabBar("Icon rendering mode on Liquid Glass (#787)", "template icons take the bar's tint without an icon color") { activity ->
                    iconRenderingController(activity, CYLEnums.CYLTabBarStyleType.LiquidGlass)
                },
                tabBar("Accessibility identifiers", "Each tab has CYLTabBarItemAccessibilityIdentifier (home, video...) for UI tests") { activity ->
                    controller(activity, 4, extra = { mapOf(CYLConstants.CYLTabBarItemAccessibilityIdentifier to titles[it].lowercase(), CYLConstants.CYLTabBarItemAccessibilityLabel to titles[it]) }).also { c ->
                        c.performWhenTabBarItemsReady { r ->
                            AlertDialog.Builder(activity).setMessage(r.tabBar.tabBarButtonArray.joinToString("\n") { "${it.item.accessibilityIdentifier}: ${it.contentDescription}" }).show()
                        }
                    }
                },
                tabBar("Centered tabs around a plus button", "Tabs packed around the middle plus button (cyl_itemEdgeInsets)") { activity ->
                    CYLPlusButton.registerPlusButton(DemoPlusButton.Provider)
                    controller(activity, 4, context = DemoCatalog.PLUS_CONTEXT).also { c -> c.tabBar.cyl_itemEdgeInsets = CYLEdgeInsets(0f, 6f, 0f, 6f) }
                },
                tabBar("Edge insets and gaps between tabs", "cyl_itemEdgeInsets 16 dp + a 2 dp gap") { activity ->
                    controller(activity, 4, extra = { mapOf(CYLConstants.CYLTabBarItemBackgroundColor to Color.rgb(240, 240, 245)) }).also { c -> c.tabBar.cyl_itemEdgeInsets = CYLEdgeInsets(4f, 1f, 4f, 1f) }
                },
            ),
            "Liquid Glass robustness" to listOf(
                tabBar("Selected control with bounds checks", "\"Read\" shows the selected tab's index and class") { activity ->
                    controller(activity, 4).also { c ->
                        c.cyl_customActionTabBarItemIdentifiers = listOf("message")
                        c.cyl_customActionBlock = { t, _ ->
                            val control = t.tabBar.cyl_tabBarButtonWithTabIndex(t.selectedIndex)
                            AlertDialog.Builder(activity).setTitle("Read").setMessage("index ${t.selectedIndex}, ${control?.javaClass?.simpleName}").show()
                        }
                        c.updateTabBarItemAtIndex(1, mapOf(CYLConstants.CYLTabBarItemTitle to "Read"))
                    }
                },
                tabBar("Out-of-range reads return nil", "Index 99 on the tab button readers: null, no exception") { activity ->
                    controller(activity, 4).also { c ->
                        c.performWhenTabBarItemsReady { r ->
                            AlertDialog.Builder(activity).setMessage("cyl_tabBarButtonWithTabIndex(99) = ${r.tabBar.cyl_tabBarButtonWithTabIndex(99)}\nviewControllers.getOrNull(99) = ${r.viewControllers.getOrNull(99)}\ncyl_viewControllerWithTabBarItemIdentifier(\"none\") = ${r.cyl_viewControllerWithTabBarItemIdentifier("none")}").show()
                        }
                    }
                },
                tabBar("Marked views in tab buttons", "A star replaces Home's icon; \"Hide\" / \"Show\" toggles it") { activity ->
                    controller(activity, 4).also { c ->
                        var shown = true
                        val star = { _: Boolean -> TextView(activity).apply { text = "★"; textSize = 22f; gravity = Gravity.CENTER; setTextColor(Color.rgb(255, 204, 0)) } }
                        c.setTabBarItemIconViewProvider(star, 0)
                        c.cyl_customActionTabBarItemIdentifiers = listOf("video")
                        c.updateTabBarItemAtIndex(1, mapOf(CYLConstants.CYLTabBarItemTitle to "Hide / Show"))
                        c.cyl_customActionBlock = { t, _ -> shown = !shown; t.setTabBarItemIconViewProvider(if (shown) star else null, 0) }
                    }
                },
                Scene("Plus stand-in after an item image changes", "Liquid Glass only", "n/a on Android: the stand-in exists because UIKit rebuilds the Liquid Glass tab buttons. The Android plus button is a real view in the bar."),
                Scene("Plus stand-in on first display and rotation", "Liquid Glass only", "n/a on Android: there is no stand-in; after a rotation the activity lays the plus button out again."),
                Scene("More editing with 8 tabs", "UIKit's \"More\" editor", "n/a on Android: the system \"More\" editor (Edit, drag, Done) is UIKit API."),
            ),
            "More than five tabs" to listOf(
                tabBar("8 tabs without the system \"More\"", "Issue #472: the fifth tab opens your own menu of the other pages; the chosen page takes that slot with its own title and icon") { activity ->
                    val all = attributes(activity, 8)
                    val pages = (0 until 8).map { TextPageFragment.newInstance(titles[it]) }
                    controller(activity, 5, page = { pages[it] }).also { c ->
                        c.updateTabBarItemAtIndex(4, mapOf(CYLConstants.CYLTabBarItemTitle to "More", CYLConstants.CYLTabBarItemIdentifier to "more"))
                        c.cyl_customActionTabBarItemIdentifiers = listOf("more", "me", "favor", "shop", "search")
                        c.cyl_customActionBlock = { t, _ ->
                            AlertDialog.Builder(activity).setTitle("More").setItems(titles.subList(4, 8).toTypedArray()) { _, which ->
                                t.replaceViewControllerAtIndex(4, pages[4 + which], all[4 + which])
                                t.cyl_customActionTabBarItemIdentifiers = emptyList()
                                t.selectedIndex = 4
                                t.cyl_customActionTabBarItemIdentifiers = listOf("more", "me", "favor", "shop", "search")
                            }.show()
                        }
                    }
                },
                Scene("For comparison: 8 tabs with the system \"More\"", "The system bar shows four tabs and \"More\" once there are more than five") { systemBar(it, 8) },
            ),
        )
    }

    val sceneCount: Int get() = sections.sumOf { it.second.size }

    private fun badgeAnimationScene(activity: FragmentActivity, animation: (View, View, View?) -> Unit): CYLTabBarController =
        controller(activity, 4).also { c ->
            c.cyl_defaultTabButtonAnimation = CYLTabButtonBlockAnimation().apply { badgeChangedAnimation = animation }
            var count = 0
            repeating(1000, 2000) {
                if (!activity.isFinishing) c.tabBar.tabBarButtonArray.getOrNull(1)?.cyl_showBadgeValue((++count).toString())
                !activity.isFinishing
            }
        }

    /** [EN] Runs `step` after `initialDelay` ms, then every `interval` ms while it returns true. [CN] `initialDelay` 毫秒后运行 `step`，之后每 `interval` 毫秒运行一次，直到它返回 false。 */
    private fun repeating(initialDelay: Long, interval: Long, step: () -> Boolean) {
        val handler = Handler(Looper.getMainLooper())
        fun tick() {
            if (step()) handler.postDelayed(::tick, interval)
        }
        handler.postDelayed(::tick, initialDelay)
    }

    private const val LARGE_PLUS = "GalleryLargePlus"
    private val largePlus = object : CYLPlusButtonSubclassing {
        override fun plusButton(context: Context) = CYLPlusButton(context).apply {
            val density = resources.displayMetrics.density
            background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.rgb(255, 45, 85)) }
            setImageDrawable(ContextCompat.getDrawable(context, android.R.drawable.ic_input_add))
            imageView.setColorFilter(Color.WHITE)
            minimumWidth = (72 * density).toInt(); minimumHeight = (72 * density).toInt()
        }
        override fun multiplierOfTabBarHeight(tabBarHeight: Float) = 0.1f
        override fun tabBarContext() = LARGE_PLUS
        override fun plusChildViewController(): Fragment = TextPageFragment.newInstance("PlusButton")
    }

    private const val ACTION_PLUS = "GalleryActionPlus"
    private val actionPlus = object : CYLPlusButtonSubclassing {
        override fun plusButton(context: Context): CYLPlusButton = object : CYLPlusButton(context) {
            init {
                background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.rgb(52, 199, 89)) }
                setImageDrawable(ContextCompat.getDrawable(context, android.R.drawable.ic_input_add))
                imageView.setColorFilter(Color.WHITE)
            }
            override fun plusChildViewControllerButtonClicked() {
                AlertDialog.Builder(context).setTitle("Publish").setItems(arrayOf("Photo", "Video", "Text"), null).setNegativeButton(android.R.string.cancel, null).show()
            }
        }
        override fun tabBarContext() = ACTION_PLUS
    }
}
