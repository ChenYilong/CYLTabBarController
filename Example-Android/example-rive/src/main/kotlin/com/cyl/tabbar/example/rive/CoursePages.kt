package com.cyl.tabbar.example.rive

import android.app.AlertDialog
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.text.InputType
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.fragment.app.Fragment
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLSize
import com.cyl.tabbar.CYLTabBarAnimationURLWithOptions
import com.cyl.tabbar.CYLTabBarItemAnimationFactory
import com.cyl.tabbar.demo.DemoCatalog
import com.cyl.tabbar.demo.DemoListFragment

/**
 * [EN] A Rive animation outside the tab bar (iOS `RiveAnimation`): `CYLTabBarItemAnimationFactory` makes the view from a
 *      `CYLTabBarAnimationURLWithOptions()` URL and its player plays and stops it, the same path the tab icons use.
 * [CN] TabBar 之外的 Rive 动画（iOS `RiveAnimation`）：`CYLTabBarItemAnimationFactory` 根据 `CYLTabBarAnimationURLWithOptions()` 生成的 URL
 *      创建视图，再由其播放器播放与停止，与 Tab 图标走同一条路径。
 */
class RiveAnimation(file: String, options: Map<String, String> = emptyMap()) {
    private val url = CYLTabBarAnimationURLWithOptions(file, options) ?: file
    private var view: View? = null

    /** [EN] The view, or an empty view when rive-android cannot make it. [CN] 视图；rive-android 无法创建时为空视图。 */
    fun view(context: Context, size: Float): View =
        (CYLTabBarItemAnimationFactory.animationViewWithURL(context, url, CYLSize(size, size), ImageView.ScaleType.FIT_CENTER) ?: View(context)).also { view = it }

    fun play() = CYLTabBarItemAnimationFactory.playerForView(view)?.play()
    fun stop() = CYLTabBarItemAnimationFactory.playerForView(view)?.stop()
}

private fun Context.dp(value: Float) = (value * resources.displayMetrics.density).toInt()

private fun Context.title(text: String, size: Float = 28f, color: Int = Color.BLACK) = TextView(this).apply {
    this.text = text
    textSize = size
    setTextColor(color)
    setTypeface(typeface, Typeface.BOLD)
}

/** [EN] The course card colors and texts (iOS `courses` and `courseSections`). [CN] 课程卡片的颜色与文字（iOS `courses` 与 `courseSections`）。 */
private val courses = listOf(
    Triple("Animations in SwiftUI", "20 sections - 3 hours", "#7850F0"),
    Triple("Build Quick Apps with SwiftUI", "47 sections - 11 hours", "#6792FF"),
    Triple("Build a SwiftUI app for iOS 15", "21 sections - 4 hours", "#005FE7"),
)
private val sections = listOf(
    Triple("State Machine", "Watch video - 15 mins", "#9CC5FF"),
    Triple("Animated Menu", "Watch video - 10 mins", "#6E6AE8"),
    Triple("Tab Bar", "Watch video - 8 mins", "#005FE7"),
    Triple("Button", "Watch video - 9 mins", "#BBA6FF"),
)

/** [EN] Chat (iOS `HomeView`): "Courses" cards to scroll sideways, then the "Recent" sections. [CN] Chat（iOS `HomeView`）：可横向滚动的 "Courses" 卡片，然后是 "Recent" 小节。 */
class CoursesPage : Fragment() {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val column = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL; setPadding(context.dp(20f), context.dp(20f), context.dp(20f), context.dp(20f)) }
        column.addView(context.title("Courses"))
        val cards = LinearLayout(context)
        for ((title, caption, color) in courses) cards.addView(card(context, title, caption, Color.parseColor(color), vertical = true),
            LinearLayout.LayoutParams(context.dp(260f), context.dp(310f)).apply { marginEnd = context.dp(20f) })
        column.addView(HorizontalScrollView(context).apply { isHorizontalScrollBarEnabled = false; addView(cards) }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = context.dp(16f) })
        column.addView(context.title("Recent", 20f), LinearLayout.LayoutParams(-2, -2).apply { topMargin = context.dp(24f) })
        for ((title, caption, color) in sections) column.addView(card(context, title, caption, Color.parseColor(color), vertical = false),
            LinearLayout.LayoutParams(-1, context.dp(110f)).apply { topMargin = context.dp(16f) })
        return ScrollView(context).apply { setBackgroundColor(CourseColors.background2); addView(column) }
    }

    private fun card(context: Context, title: String, caption: String, color: Int, vertical: Boolean) = LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        gravity = if (vertical) Gravity.TOP else Gravity.CENTER_VERTICAL
        setPadding(context.dp(24f), context.dp(24f), context.dp(24f), context.dp(24f))
        background = GradientDrawable().apply { cornerRadius = context.dp(30f).toFloat(); setColor(color) }
        addView(context.title(title, if (vertical) 24f else 20f, Color.WHITE))
        addView(TextView(context).apply { text = caption; setTextColor(Color.argb(180, 255, 255, 255)); textSize = 15f })
    }
}

/**
 * [EN] Search (iOS `SideMenu`): the profile, then the "BROWSE" and "HISTORY" items; each item's icon is an artboard of
 *      icons.riv that plays when the item is tapped.
 * [CN] Search（iOS `SideMenu`）：个人信息，然后是 "BROWSE" 与 "HISTORY" 菜单项；每项的图标是 icons.riv 中的画板，点击时播放。
 */
class SideMenuPage : Fragment() {
    private val browse = listOf("Home" to ("HOME" to "HOME_interactivity"), "Search" to ("SEARCH" to "SEARCH_Interactivity"),
                                "Favorites" to ("LIKE/STAR" to "STAR_Interactivity"), "Help" to ("CHAT" to "CHAT_Interactivity"))
    private val history = listOf("History" to ("TIMER" to "TIMER_Interactivity"), "Notifications" to ("BELL" to "BELL_Interactivity"))

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val column = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL; setPadding(context.dp(24f), context.dp(24f), context.dp(24f), context.dp(24f)) }
        column.addView(context.title("Meng To", 17f, Color.WHITE))
        column.addView(TextView(context).apply { text = "UI Designer"; setTextColor(Color.argb(180, 255, 255, 255)) })
        for ((header, items) in listOf("BROWSE" to browse, "HISTORY" to history)) {
            column.addView(TextView(context).apply { text = header; setTextColor(Color.argb(150, 255, 255, 255)); textSize = 13f },
                LinearLayout.LayoutParams(-2, -2).apply { topMargin = context.dp(32f) })
            for ((text, rive) in items) column.addView(menuItem(context, text, rive.first, rive.second))
        }
        return ScrollView(context).apply { setBackgroundColor(CourseColors.background); addView(column) }
    }

    private fun menuItem(context: Context, text: String, artboard: String, stateMachine: String): View {
        val icon = RiveAnimation("icons.riv", mapOf(CYLConstants.CYLTabBarAnimationOptionRiveArtboard to artboard,
            CYLConstants.CYLTabBarAnimationOptionRiveStateMachine to stateMachine, CYLConstants.CYLTabBarAnimationOptionRiveInput to "active"))
        return LinearLayout(context).apply {
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, context.dp(12f), 0, context.dp(12f))
            addView(icon.view(context, 32f), LinearLayout.LayoutParams(context.dp(32f), context.dp(32f)))
            addView(context.title(text, 17f, Color.WHITE), LinearLayout.LayoutParams(-2, -2).apply { marginStart = context.dp(14f) })
            setOnClickListener { icon.play() }
        }
    }
}

/**
 * [EN] The plus button's page (iOS `OnboardingView`): the shapes.riv background, the title, and the button.riv button whose
 *      "active" animation plays before the sign-in dialog opens.
 * [CN] PlusButton 的页面（iOS `OnboardingView`）：shapes.riv 背景、标题，以及 button.riv 按钮，点击后播放 "active" 动画再打开登录对话框。
 */
class OnboardingPage : Fragment() {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val shapes = RiveAnimation("shapes.riv")
        val button = RiveAnimation("button.riv", mapOf(CYLConstants.CYLTabBarAnimationOptionRiveAnimation to "active"))
        val column = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(context.dp(32f), context.dp(48f), context.dp(32f), context.dp(32f))
            addView(context.title("Learn design & code", 40f))
            addView(TextView(context).apply {
                text = "Don’t skip design. Learn design and code, by building real apps with React and Swift. Complete courses about the best tools."
                textSize = 17f; setTextColor(Color.DKGRAY)
            }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = context.dp(16f) })
            val buttonView = FrameLayout(context).apply {
                addView(button.view(context, 64f), FrameLayout.LayoutParams(-1, -1))
                addView(TextView(context).apply { text = "Start the course"; setTypeface(typeface, Typeface.BOLD); gravity = Gravity.CENTER }, FrameLayout.LayoutParams(-1, -1))
                setOnClickListener { button.play(); postDelayed({ SignInPage.showDialog(context) }, 800) }
            }
            addView(buttonView, LinearLayout.LayoutParams(context.dp(236f), context.dp(64f)).apply { topMargin = context.dp(40f) })
            addView(TextView(context).apply {
                text = "Purchase includes access to 30+ courses, 240+ premium tutorials, 120+ hours of videos, source files and certificates."
                setTextColor(Color.GRAY)
            }, LinearLayout.LayoutParams(-1, -2).apply { topMargin = context.dp(16f) })
        }
        return FrameLayout(context).apply {
            setBackgroundColor(Color.WHITE)
            addView(shapes.view(context, 400f), FrameLayout.LayoutParams(-1, -1))
            addView(column, FrameLayout.LayoutParams(-1, -1))
            post { shapes.play() }
        }
    }
}

/**
 * [EN] Bell (iOS `settingsViewController(headerView: RiveMenuButtonDemoView())`): the menu_button.riv view with "Play / Stop"
 *      (state machine input "isOpen", held until stopped: duration 0) above the settings list.
 * [CN] Bell（iOS `settingsViewController(headerView: RiveMenuButtonDemoView())`）：设置列表上方是 menu_button.riv 视图与 "播放 / 停止" 按钮
 *      （状态机输入 "isOpen"，保持到停止：duration 为 0）。
 */
class BellPage : Fragment() {
    private var isOn = false

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val menuButton = RiveAnimation("menu_button.riv", mapOf(CYLConstants.CYLTabBarAnimationOptionRiveStateMachine to "State Machine",
            CYLConstants.CYLTabBarAnimationOptionRiveInput to "isOpen", CYLConstants.CYLTabBarAnimationOptionRiveActiveDuration to "0"))
        val list = FrameLayout(context).apply { id = View.generateViewId() }
        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            addView(menuButton.view(context, 88f), LinearLayout.LayoutParams(context.dp(88f), context.dp(88f)).apply { topMargin = context.dp(16f) })
            addView(Button(context).apply {
                text = "Play / Stop"
                setOnClickListener { isOn = !isOn; if (isOn) menuButton.play() else menuButton.stop() }
            })
            addView(list, LinearLayout.LayoutParams(-1, 0, 1f))
            if (savedInstanceState == null) childFragmentManager.beginTransaction().add(list.id, DemoListFragment.newInstance(DemoCatalog.SETTINGS)).commit()
        }
    }
}

/**
 * [EN] User (iOS `SignInView`): email and password; "Sign in" plays check.riv ("Check" with both fields, "Error" without)
 *      and, on success, confetti.riv.
 * [CN] User（iOS `SignInView`）：邮箱与密码；"Sign in" 播放 check.riv（两项都填时为 "Check"，否则为 "Error"），成功时再播放 confetti.riv。
 */
class SignInPage : Fragment() {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View =
        ScrollView(inflater.context).apply { setBackgroundColor(CourseColors.background2); addView(form(inflater.context)) }

    companion object {
        /** [EN] The sign-in form, also shown as a dialog by the onboarding. [CN] 登录表单，引导页也以对话框显示它。 */
        fun form(context: Context): View {
            val trigger = { name: String -> RiveAnimation("check.riv", mapOf(CYLConstants.CYLTabBarAnimationOptionRiveStateMachine to "State Machine 1", CYLConstants.CYLTabBarAnimationOptionRiveTriggerInput to name)) }
            val succeeded = trigger("Check")
            val failed = trigger("Error")
            val confetti = RiveAnimation("confetti.riv", mapOf(CYLConstants.CYLTabBarAnimationOptionRiveStateMachine to "State Machine 1",
                CYLConstants.CYLTabBarAnimationOptionRiveTriggerInput to "Trigger explosion"))
            val email = EditText(context).apply { hint = "Email"; inputType = InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS or InputType.TYPE_CLASS_TEXT }
            val password = EditText(context).apply { hint = "Password"; inputType = InputType.TYPE_TEXT_VARIATION_PASSWORD or InputType.TYPE_CLASS_TEXT }
            val successView = succeeded.view(context, 100f).apply { visibility = View.INVISIBLE }
            val failureView = failed.view(context, 100f).apply { visibility = View.INVISIBLE }
            return LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(context.dp(30f), context.dp(30f), context.dp(30f), context.dp(30f))
                addView(context.title("Sign in", 34f))
                addView(TextView(context).apply { text = "Access to 240+ hours of content. Learn design and code, by building real apps with React and Swift."; setTextColor(Color.DKGRAY) })
                addView(email); addView(password)
                addView(Button(context).apply {
                    text = "Sign in"
                    setOnClickListener {
                        val ok = email.text.isNotBlank() && password.text.isNotBlank()
                        successView.visibility = if (ok) View.VISIBLE else View.INVISIBLE
                        failureView.visibility = if (ok) View.INVISIBLE else View.VISIBLE
                        if (ok) { succeeded.play(); confetti.play() } else failed.play()
                    }
                })
                addView(FrameLayout(context).apply {
                    addView(confetti.view(context, 300f), FrameLayout.LayoutParams(-1, -1))
                    addView(successView, FrameLayout.LayoutParams(context.dp(100f), context.dp(100f), Gravity.CENTER))
                    addView(failureView, FrameLayout.LayoutParams(context.dp(100f), context.dp(100f), Gravity.CENTER))
                }, LinearLayout.LayoutParams(-1, context.dp(220f)))
                addView(TextView(context).apply { text = "Sign up with Email, Apple, Google"; setTextColor(Color.GRAY); gravity = Gravity.CENTER })
            }
        }

        fun showDialog(context: Context) {
            AlertDialog.Builder(context).setView(form(context)).setNegativeButton(android.R.string.cancel, null).show()
        }
    }
}
