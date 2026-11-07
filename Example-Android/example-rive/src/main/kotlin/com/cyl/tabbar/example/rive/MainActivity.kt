package com.cyl.tabbar.example.rive

import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.content.Context
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLPlusButton
import com.cyl.tabbar.CYLPlusButtonSubclassing
import com.cyl.tabbar.CYLTabBarAnimationURLWithOptions
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.CYLThemeManager
import com.cyl.tabbar.demo.DemoTabBarActivity

/**
 * [EN] The tabs of Example-Rive (iOS `Tab` in TabItems.swift): each icon is an artboard of the course's icons.riv, given as
 *      `CYLTabBarRiveURL` with its state machine and its "active" input, like a Lottie or PAG file. Timer is not a tab: the
 *      plus button takes its place, as a phone tab bar shows at most 5 items.
 * [CN] Example-Rive 的 Tab（iOS TabItems.swift 中的 `Tab`）：每个图标是课程 icons.riv 中的一个画板，以 `CYLTabBarRiveURL` 传入，带状态机与
 *      "active" 输入，与 Lottie、PAG 文件一样。Timer 不是 Tab：手机 TabBar 最多显示 5 项，PlusButton 占用它的位置。
 */
enum class CourseTab(val artboard: String, val stateMachine: String, val icon: Int) {
    Chat("CHAT", "CHAT_Interactivity", android.R.drawable.ic_dialog_email),
    Search("SEARCH", "SEARCH_Interactivity", android.R.drawable.ic_menu_search),
    Timer("TIMER", "TIMER_Interactivity", android.R.drawable.ic_menu_recent_history),
    Bell("BELL", "BELL_Interactivity", android.R.drawable.ic_popup_reminder),
    User("USER", "USER_Interactivity", android.R.drawable.ic_menu_myplaces);

    /** [EN] The Rive keys of the tab's icon. [CN] Tab 图标的 Rive key。 */
    val animationAttributes: Map<String, Any?>
        get() = mapOf(
            CYLConstants.CYLTabBarRiveURL to CYLTabBarAnimationURLWithOptions("icons.riv", mapOf(
                CYLConstants.CYLTabBarAnimationOptionRiveArtboard to artboard,
                CYLConstants.CYLTabBarAnimationOptionRiveStateMachine to stateMachine,
                CYLConstants.CYLTabBarAnimationOptionRiveInput to "active",
            )),
            CYLConstants.CYLTabBarRiveSize to "{32, 32}",
        )

    fun attributes(context: Context): Map<String, Any?> {
        val image = ContextCompat.getDrawable(context, icon)
        return mapOf(CYLConstants.CYLTabBarItemTitle to name, CYLConstants.CYLTabBarItemImage to image, CYLConstants.CYLTabBarItemSelectedImage to image) + animationAttributes
    }

    fun page(): Fragment = when (this) {
        Chat -> CoursesPage()
        Search -> SideMenuPage()
        Timer -> OnboardingPage()
        Bell -> BellPage()
        User -> SignInPage()
    }
}

/** [EN] The course's colors. [CN] 课程的颜色。 */
object CourseColors {
    val accent = Color.rgb(0x78, 0x50, 0xF0)
    val background = Color.parseColor("#17203A")
    val background2 = Color.parseColor("#EEF1F8")
}

/**
 * [EN] The Android port of Example-Rive (iOS `SceneDelegate` + `RiveTabBarController` + `CourseTabBarController`): a dark
 *      tab bar with white tints, Rive tab icons, the "Start" plus button, the shared plus button badge, and the Grapefruit
 *      skin swapping the icons of "Chat" and "User" in place (#216).
 * [CN] Example-Rive 的 Android 版（iOS `SceneDelegate` + `RiveTabBarController` + `CourseTabBarController`）：白色强调色的深色 TabBar、Rive Tab
 *      图标、"Start" PlusButton、共用的 PlusButton 角标，以及西柚皮肤原地互换 "Chat" 与 "User" 的图标（#216）。
 */
class MainActivity : DemoTabBarActivity() {

    private val themeListener = CYLThemeManager.Listener { _, _, _ -> applySkinAnimations() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CYLThemeManager.defaultManager.addListener(themeListener)
    }

    override fun onDestroy() {
        CYLThemeManager.defaultManager.removeListener(themeListener)
        super.onDestroy()
    }

    override fun makeTabBarController(style: CYLEnums.CYLTabBarStyleType): CYLTabBarController {
        CYLPlusButton.registerPlusButton(StartPlusButton)
        val tabs = CourseTab.entries.filter { it != CourseTab.Timer }
        return CYLTabBarController(this, tabs.map { it.page() }, tabs.map { it.attributes(this) }, style, StartPlusButton.CONTEXT).apply {
            // [EN] `applyCourseTabBarAppearance()`: dark, translucent, white tints. [CN] 深色、半透明、白色强调色。
            cyl_tabBarBackgroundColor = Color.argb(204, 0x17, 0x20, 0x3A)
            cyl_tabBarItemTitleColor = Color.argb(153, 255, 255, 255)
            cyl_tabBarItemImageColor = Color.argb(153, 255, 255, 255)
            setTintColor(Color.WHITE)
        }
    }

    /** [EN] #216: the Grapefruit skin swaps the icons of "Chat" and "User". [CN] #216：西柚皮肤互换 "Chat" 与 "User" 的图标。 */
    private fun applySkinAnimations() {
        val controller = tabBarController ?: return
        val swaps = CYLThemeManager.defaultManager.currentThemeIdentifier == "Grapefruit"
        controller.updateTabBarItemAtIndex(0, (if (swaps) CourseTab.User else CourseTab.Chat).animationAttributes)
        controller.updateTabBarItemAtIndex(controller.viewControllers.lastIndex, (if (swaps) CourseTab.Chat else CourseTab.User).animationAttributes)
    }
}

/**
 * [EN] Example-Rive's plus button (iOS `RivePlusButton`): a purple circle with a plus, the title "Start" aligned with the tab
 *      titles (#636), between Search and Bell, whose page is the course's onboarding. Example-PAG shows the other layout.
 * [CN] Example-Rive 的 PlusButton（iOS `RivePlusButton`）：带加号的紫色圆形，标题 "Start" 与 Tab 标题对齐（#636），位于 Search 与 Bell 之间，
 *      其页面是课程的引导页。Example-PAG 演示另一种布局。
 */
object StartPlusButton : CYLPlusButtonSubclassing {
    const val CONTEXT = "ExampleRive"

    override fun plusButton(context: Context): CYLPlusButton = CYLPlusButton(context).apply {
        val density = resources.displayMetrics.density
        setImageDrawable(android.graphics.drawable.LayerDrawable(arrayOf(
            GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(CourseColors.accent) },
            ContextCompat.getDrawable(context, android.R.drawable.ic_input_add)?.mutate()?.apply { setTint(Color.WHITE) },
        )).apply { setLayerInset(1, (10 * density).toInt(), (10 * density).toInt(), (10 * density).toInt(), (10 * density).toInt()) })
        setTitle("Start", null, Color.WHITE)
        titleLabel.setTextColor(Color.WHITE)
        minimumWidth = (44 * density).toInt()
        minimumHeight = (44 * density).toInt()
    }

    override fun indexOfPlusButtonInTabBar() = 2
    override fun alignsTitleWithTabBarItemTitles() = true
    override fun plusChildViewController(): Fragment = CourseTab.Timer.page()
    override fun tabBarContext() = CONTEXT
}
