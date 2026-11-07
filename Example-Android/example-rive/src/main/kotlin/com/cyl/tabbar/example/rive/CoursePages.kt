package com.cyl.tabbar.example.rive

import android.content.Context
import android.graphics.Color
import android.graphics.RenderEffect
import android.graphics.Shader
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.text.InputType
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.HorizontalScrollView
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.annotation.ColorInt
import androidx.annotation.DrawableRes
import androidx.appcompat.widget.SwitchCompat
import androidx.fragment.app.Fragment
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLSize
import com.cyl.tabbar.CYLTabBarAnimationURLWithOptions
import com.cyl.tabbar.CYLTabBarItemAnimationFactory
import com.cyl.tabbar.demo.DemoAssets
import com.cyl.tabbar.demo.DemoCatalog
import com.cyl.tabbar.demo.DemoListFragment

// [EN] A direct translation of the course screens of Example-SwiftUI-Rive, as Example-Rive shows them in its tabs
//      (HomeView, VCard, HCard, SideMenu, OnboardingView, SignInView, RiveMenuButtonDemoView): the same texts, fonts, sizes,
//      colors and timing; SwiftUI modifiers become views and drawables.
// [CN] Example-SwiftUI-Rive 课程界面的直接翻译，与 Example-Rive 在各 Tab 中显示的相同（HomeView、VCard、HCard、SideMenu、OnboardingView、
//      SignInView、RiveMenuButtonDemoView）：相同的文字、字体、尺寸、颜色与时序；SwiftUI 修饰符改为视图与 drawable。

/**
 * [EN] iOS `RiveAnimation` (Components/RiveAnimation.swift): `CYLTabBarItemAnimationFactory` makes the view from a
 *      `CYLTabBarAnimationURLWithOptions()` URL and its player plays and stops it, the same path the tab icons use.
 * [CN] iOS `RiveAnimation`（Components/RiveAnimation.swift）：`CYLTabBarItemAnimationFactory` 根据 `CYLTabBarAnimationURLWithOptions()`
 *      生成的 URL 创建视图，再由其播放器播放与停止，与 Tab 图标走同一条路径。
 */
class RiveAnimation(file: String, options: Map<String, String> = emptyMap()) {
    private val url = CYLTabBarAnimationURLWithOptions("$file.riv", options) ?: "$file.riv"
    private var view: View? = null

    /** [EN] The view (an empty view when rive-android cannot make it), sized `width` × `height` dp. [CN] 视图（rive-android 无法创建时为空视图），尺寸 `width` × `height` dp。 */
    fun view(context: Context, width: Float, height: Float = width): View =
        (CYLTabBarItemAnimationFactory.animationViewWithURL(context, url, CYLSize(width, height), ImageView.ScaleType.FIT_CENTER) ?: View(context)).also { view = it }

    fun play() = CYLTabBarItemAnimationFactory.playerForView(view)?.play()
    fun stop() = CYLTabBarItemAnimationFactory.playerForView(view)?.stop()
}

// MARK: - Styles (Styles/CustomFont.swift, CustomButton.swift, CustomTextField.swift) 样式

private fun Context.dp(value: Float) = (value * resources.displayMetrics.density).toInt()

/** [EN] iOS `TextStyle` with its font and size (`customFont`). [CN] iOS `TextStyle` 及其字体与字号（`customFont`）。 */
private enum class TextStyle(val font: String, val size: Float) {
    LargeTitle(POPPINS_BOLD, 34f), Title(POPPINS_BOLD, 28f), Title2(POPPINS_BOLD, 24f), Title3(POPPINS_BOLD, 20f),
    Body(INTER_REGULAR, 17f), Headline(INTER_SEMIBOLD, 17f), Subheadline(INTER_REGULAR, 15f), Subheadline2(INTER_SEMIBOLD, 15f),
    Footnote(INTER_REGULAR, 13f), Footnote2(INTER_SEMIBOLD, 13f), Caption(INTER_REGULAR, 12f), Caption2(INTER_SEMIBOLD, 12f),
}

/** [EN] The course's font files (Example-SwiftUI-Rive/AnimatedApp/Fonts). [CN] 课程的字体文件（Example-SwiftUI-Rive/AnimatedApp/Fonts）。 */
private const val POPPINS_BOLD = "Poppins-Bold.ttf"
private const val INTER_REGULAR = "Inter-Regular.ttf"
private const val INTER_SEMIBOLD = "Inter-SemiBold.ttf"

private fun Context.text(value: String, style: TextStyle? = null, @ColorInt color: Int? = null, alpha: Float = 1f): TextView = TextView(this).apply {
    text = value
    style?.let { typeface = DemoAssets.font(context, it.font); textSize = it.size }
    color?.let(::setTextColor)
    this.alpha = alpha
}

private fun rounded(@ColorInt color: Int, radius: Float) = GradientDrawable().apply { setColor(color); cornerRadius = radius }

/** [EN] A color set of the course's asset catalog ("Background", "Background 2", "Shadow"), dark in this dark app. [CN] 课程资源目录中的颜色集（"Background"、"Background 2"、"Shadow"），本 App 为深色。 */
private fun Context.color(name: String) = DemoAssets.color(this, name, Color.BLACK)

private fun Context.image(@DrawableRes id: Int) = ImageView(this).apply { setImageResource(id) }

/** [EN] An image set of the course's asset catalog (PDFs rendered at the screen density). [CN] 课程资源目录中的图片集（PDF 按屏幕密度渲染）。 */
private fun Context.image(name: String) = ImageView(this).apply { setImageDrawable(DemoAssets.drawable(context, name)) }

private fun lp(width: Int, height: Int, block: LinearLayout.LayoutParams.() -> Unit = {}) = LinearLayout.LayoutParams(width, height).apply(block)

/** [EN] `blur(radius:)`, on Android 12 and later (RenderEffect); earlier, the view stays sharp. [CN] `blur(radius:)`，Android 12 及以后（RenderEffect）；更早的版本不模糊。 */
private fun View.blur(radius: Float) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) setRenderEffect(RenderEffect.createBlurEffect(radius, radius, Shader.TileMode.DECAL))
}

/** [EN] A page whose activity title is its navigation title while it is shown (the iOS navigation controller of each tab). [CN] 显示时把 Activity 标题设为其导航标题的页面（iOS 每个 Tab 的导航控制器）。 */
abstract class TitledPage(private val navigationTitle: String) : Fragment() {
    override fun onResume() { super.onResume(); if (!isHidden) activity?.title = navigationTitle }
    override fun onHiddenChanged(hidden: Boolean) { super.onHiddenChanged(hidden); if (!hidden) activity?.title = navigationTitle }
}

// MARK: - Chat: HomeView, VCard, HCard

private data class Course(val title: String, val subtitle: String, val caption: String, val color: Int, val image: String)
private data class CourseSection(val title: String, val caption: String, val color: Int, val image: String)

/** [EN] The course images of the iOS asset catalog. [CN] iOS 资源目录中的课程图片。 */
private const val TOPIC_1 = "Topic 1"
private const val TOPIC_2 = "Topic 2"

/** [EN] Model/Course.swift. [CN] Model/Course.swift。 */
private val courses = listOf(
    Course("Animations in SwiftUI", "Build and animate an iOS app from scratch", "20 sections - 3 hours", Color.parseColor("#7850F0"), TOPIC_1),
    Course("Build Quick Apps with SwiftUI", "Apply your Swift and SwiftUI knowledge by building real, quick and various applications from scratch", "47 sections - 11 hours", Color.parseColor("#6792FF"), TOPIC_2),
    Course("Build a SwiftUI app for iOS 15", "Design and code a SwiftUI 3 app with custom layouts, animations and gestures using Xcode 13, SF Symbols 3, Canvas, Concurrency, Searchable and a whole lot more", "21 sections - 4 hours", Color.parseColor("#005FE7"), TOPIC_1),
)

/** [EN] Model/CourseSection.swift. [CN] Model/CourseSection.swift。 */
private val courseSections = listOf(
    CourseSection("State Machine", "Watch video - 15 mins", Color.parseColor("#9CC5FF"), TOPIC_2),
    CourseSection("Animated Menu", "Watch video - 10 mins", Color.parseColor("#6E6AE8"), TOPIC_1),
    CourseSection("Tab Bar", "Watch video - 8 mins", Color.parseColor("#005FE7"), TOPIC_2),
    CourseSection("Button", "Watch video - 9 mins", Color.parseColor("#BBA6FF"), TOPIC_1),
)

/** [EN] Chat: iOS `HomeView`, "Courses" (VCard, sideways) then "Recent" (HCard). [CN] Chat：iOS `HomeView`，"Courses"（VCard，横向）然后 "Recent"（HCard）。 */
class CoursesPage : TitledPage("Chat") {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val content = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL }
        content.addView(context.text("Courses", TextStyle.LargeTitle), lp(-1, -2) { marginStart = context.dp(20f); marginEnd = context.dp(20f) })
        val cards = LinearLayout(context).apply { setPadding(context.dp(20f), context.dp(20f), 0, context.dp(30f)); clipToPadding = false; clipChildren = false }
        courses.forEach { cards.addView(vCard(context, it), lp(context.dp(260f), context.dp(310f)) { marginEnd = context.dp(20f) }) }
        content.addView(HorizontalScrollView(context).apply { isHorizontalScrollBarEnabled = false; clipChildren = false; addView(cards) })
        val recent = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL; setPadding(context.dp(20f), context.dp(20f), context.dp(20f), context.dp(20f)) }
        recent.addView(context.text("Recent", TextStyle.Title3))
        courseSections.forEach { recent.addView(hCard(context, it), lp(-1, context.dp(110f)) { topMargin = context.dp(20f) }) }
        content.addView(recent)
        return ScrollView(context).apply { setBackgroundColor(context.color("Background")); addView(content) }
    }

    /** [EN] iOS `VCard`: 260 × 310, a gradient of the course color, three overlapping avatars, the topic image at the top right. [CN] iOS `VCard`：260 × 310，课程颜色的渐变，三个重叠的头像，右上角的主题图片。 */
    private fun vCard(context: Context, course: Course): View {
        val column = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(context.dp(30f), context.dp(30f), context.dp(30f), context.dp(30f))
            addView(context.text(course.title, TextStyle.Title2, Color.WHITE), lp(context.dp(170f), -2))
            addView(context.text(course.subtitle, color = Color.WHITE, alpha = 0.7f).apply { maxLines = 3 }, lp(-1, -2) { topMargin = context.dp(8f) })
            addView(context.text(course.caption.uppercase(), TextStyle.Footnote2, Color.WHITE, 0.7f), lp(-2, -2) { topMargin = context.dp(8f) })
            addView(View(context), lp(0, 0) { weight = 1f })
            addView(FrameLayout(context).apply {
                listOf(4, 5, 6).shuffled().forEachIndexed { index, number ->
                    val avatar = "Avatar $number"
                    addView(context.image(avatar).apply { clipToOutline = true; background = GradientDrawable().apply { shape = GradientDrawable.OVAL }; outlineProvider = android.view.ViewOutlineProvider.BACKGROUND },
                        FrameLayout.LayoutParams(context.dp(44f), context.dp(44f)).apply { marginStart = index * context.dp(24f) })
                }
            })
        }
        return FrameLayout(context).apply {
            background = GradientDrawable(GradientDrawable.Orientation.TL_BR, intArrayOf(course.color, (course.color and 0x00FFFFFF) or 0x80000000.toInt())).apply { cornerRadius = context.dp(30f).toFloat() }
            elevation = context.dp(8f).toFloat()
            outlineAmbientShadowColorCompat(course.color)
            addView(column, FrameLayout.LayoutParams(-1, -1))
            addView(context.image(course.image), FrameLayout.LayoutParams(-2, -2, Gravity.TOP or Gravity.END).apply { setMargins(0, context.dp(20f), context.dp(20f), 0) })
        }
    }

    /** [EN] iOS `HCard`: the section color, title and caption, a divider, the topic image. [CN] iOS `HCard`：小节颜色、标题与说明、分隔线、主题图片。 */
    private fun hCard(context: Context, section: CourseSection) = LinearLayout(context).apply {
        gravity = Gravity.CENTER_VERTICAL
        setPadding(context.dp(30f), context.dp(20f), context.dp(30f), context.dp(20f))
        background = rounded(section.color, context.dp(30f).toFloat())
        addView(LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            addView(context.text(section.title, TextStyle.Title2, Color.WHITE))
            addView(context.text(section.caption, TextStyle.Body, Color.WHITE), lp(-2, -2) { topMargin = context.dp(8f) })
        }, lp(0, -2) { weight = 1f })
        addView(View(context).apply { setBackgroundColor(Color.argb(60, 255, 255, 255)) }, lp(context.dp(1f), -1) { marginStart = context.dp(20f); marginEnd = context.dp(20f) })
        addView(context.image(section.image))
    }
}

/** [EN] The colored shadow of the cards (`shadow(color: course.color.opacity(0.3))`), on Android 9 and later. [CN] 卡片的彩色阴影（`shadow(color: course.color.opacity(0.3))`），Android 9 及以后。 */
private fun View.outlineAmbientShadowColorCompat(@ColorInt color: Int) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
        outlineAmbientShadowColor = color
        outlineSpotShadowColor = color
    }
}

// MARK: - Search: SideMenu

/**
 * [EN] Search: iOS `SideMenu` on the background 17203A. Each item's icon is an artboard of icons.riv ("active" for 2 s); a tap
 *      selects the item (the blue bar) and plays it. "Dark Mode" plays its icon while the switch is on.
 * [CN] Search：位于 17203A 背景上的 iOS `SideMenu`。每项的图标是 icons.riv 中的画板（"active" 持续 2 秒）；点击选中该项（蓝色背景）并播放图标。
 *      "Dark Mode" 开关打开期间播放其图标。
 */
class SideMenuPage : TitledPage("Search") {
    private data class MenuItem(val text: String, val artboard: String, val stateMachine: String, val duration: String = "2")

    private val browse = listOf(MenuItem("Home", "HOME", "HOME_interactivity"), MenuItem("Search", "SEARCH", "SEARCH_Interactivity"),
                                MenuItem("Favorites", "LIKE/STAR", "STAR_Interactivity"), MenuItem("Help", "CHAT", "CHAT_Interactivity"))
    private val history = listOf(MenuItem("History", "TIMER", "TIMER_Interactivity"), MenuItem("Notifications", "BELL", "BELL_Interactivity"))
    private val darkMode = MenuItem("Dark Mode", "SETTINGS", "SETTINGS_Interactivity", duration = "0")
    private val rows = ArrayList<Pair<MenuItem, View>>()
    private var selected = "Home"

    private fun icon(item: MenuItem) = RiveAnimation("icons", mapOf(CYLConstants.CYLTabBarAnimationOptionRiveArtboard to item.artboard,
        CYLConstants.CYLTabBarAnimationOptionRiveStateMachine to item.stateMachine, CYLConstants.CYLTabBarAnimationOptionRiveInput to "active",
        CYLConstants.CYLTabBarAnimationOptionRiveActiveDuration to item.duration))

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val background2 = context.color("Background 2")
        val menu = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL; setPadding(0, 0, 0, context.dp(8f)) }
        menu.addView(LinearLayout(context).apply {
            gravity = Gravity.CENTER_VERTICAL
            setPadding(context.dp(16f), context.dp(16f), context.dp(16f), context.dp(16f))
            addView(context.image(android.R.drawable.ic_menu_myplaces).apply {
                setColorFilter(Color.WHITE); setPadding(context.dp(12f), context.dp(12f), context.dp(12f), context.dp(12f))
                background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.argb(51, 255, 255, 255)) }
            }, lp(context.dp(48f), context.dp(48f)))
            addView(LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                addView(context.text("Meng To", color = Color.WHITE).apply { textSize = 17f })
                addView(context.text("UI Designer", color = Color.WHITE, alpha = 0.7f).apply { textSize = 15f })
            }, lp(-2, -2) { marginStart = context.dp(12f) })
        })
        for ((header, items) in listOf("BROWSE" to browse, "HISTORY" to history)) {
            menu.addView(context.text(header, color = Color.WHITE, alpha = 0.7f).apply { textSize = 15f; setTypeface(typeface, Typeface.BOLD) },
                lp(-1, -2) { marginStart = context.dp(24f); topMargin = context.dp(40f) })
            val group = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL; setPadding(context.dp(8f), context.dp(8f), context.dp(8f), context.dp(8f)) }
            items.forEach { item ->
                group.addView(View(context).apply { setBackgroundColor(Color.argb(26, 255, 255, 255)) }, lp(-1, context.dp(1f)) { marginStart = context.dp(16f); marginEnd = context.dp(16f) })
                group.addView(row(context, item, background2))
            }
            menu.addView(group)
        }
        menu.addView(View(context), lp(0, 0) { weight = 1f })
        val darkIcon = icon(darkMode)
        menu.addView(LinearLayout(context).apply {
            gravity = Gravity.CENTER_VERTICAL
            setPadding(context.dp(20f), context.dp(20f), context.dp(20f), context.dp(20f))
            addView(darkIcon.view(context, 32f).apply { alpha = 0.6f }, lp(context.dp(32f), context.dp(32f)))
            addView(context.text(darkMode.text, TextStyle.Headline, Color.WHITE), lp(0, -2) { weight = 1f; marginStart = context.dp(14f) })
            addView(SwitchCompat(context).apply { setOnCheckedChangeListener { _, on -> if (on) darkIcon.play() else darkIcon.stop() } })
        })
        return FrameLayout(context).apply {
            setBackgroundColor(background2)
            addView(ScrollView(context).apply {
                isFillViewport = true
                addView(menu)
                background = rounded(background2, context.dp(30f).toFloat())
            }, FrameLayout.LayoutParams(context.dp(288f), -1))
        }
    }

    private fun row(context: Context, item: MenuItem, background2: Int): View {
        val icon = icon(item)
        return LinearLayout(context).apply {
            gravity = Gravity.CENTER_VERTICAL
            setPadding(context.dp(12f), context.dp(12f), context.dp(12f), context.dp(12f))
            addView(icon.view(context, 32f).apply { alpha = 0.6f }, lp(context.dp(32f), context.dp(32f)))
            addView(context.text(item.text, TextStyle.Headline, Color.WHITE), lp(-2, -2) { marginStart = context.dp(14f) })
            setOnClickListener {
                selected = item.text
                updateSelection(background2)
                icon.play()
            }
            rows += item to this
            updateSelection(background2)
        }
    }

    /** [EN] The selected item has the blue rounded background. [CN] 选中的项带蓝色圆角背景。 */
    private fun updateSelection(background2: Int) {
        rows.forEach { (item, view) -> view.background = rounded(if (item.text == selected) Color.rgb(0, 122, 255) else background2, view.context.dp(10f).toFloat()) }
    }
}

// MARK: - Start: OnboardingView

/**
 * [EN] The plus button's page: iOS `OnboardingView`. The Spline image and shapes.riv, blurred, behind "Learn design & code";
 *      button.riv plays its "active" animation and, 0.8 s later, the sign-in card comes in over a dimmed page, with a close
 *      button under it.
 * [CN] PlusButton 的页面：iOS `OnboardingView`。模糊的 Spline 图片与 shapes.riv 位于 "Learn design & code" 之后；button.riv 播放 "active"
 *      动画，0.8 秒后登录卡片出现在变暗的页面上，下方有关闭按钮。
 */
class OnboardingPage : TitledPage("Start") {
    private var modal: View? = null

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val root = FrameLayout(context)
        root.addView(context.image("Spline").apply { blur(50f); translationX = context.dp(200f).toFloat(); translationY = context.dp(100f).toFloat() },
            FrameLayout.LayoutParams(-2, -2, Gravity.CENTER))
        val shapes = RiveAnimation("shapes")
        root.addView(shapes.view(context, 400f, 800f).apply { blur(30f) }, FrameLayout.LayoutParams(-1, -1))
        val button = RiveAnimation("button", mapOf(CYLConstants.CYLTabBarAnimationOptionRiveAnimation to "active"))
        val content = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(context.dp(40f), context.dp(80f), context.dp(40f), context.dp(40f))
            addView(context.text("Learn design & code", TextStyle.LargeTitle).apply { textSize = 60f; setLineSpacing(0f, 0.9f) }, lp(context.dp(260f), -2))
            addView(context.text("Don’t skip design. Learn design and code, by building real apps with React and Swift. Complete courses about the best tools.",
                TextStyle.Body, alpha = 0.7f), lp(-1, -2) { topMargin = context.dp(16f) })
            addView(View(context), lp(0, 0) { weight = 1f })
            addView(FrameLayout(context).apply {
                addView(View(context).apply { background = rounded(Color.argb(77, 0, 0, 0), context.dp(30f).toFloat()); blur(10f); translationY = context.dp(10f).toFloat() }, FrameLayout.LayoutParams(-1, -1))
                addView(button.view(context, 236f, 64f), FrameLayout.LayoutParams(-1, -1))
                addView(context.text("→  Start the course", TextStyle.Headline, Color.BLACK).apply {
                    gravity = Gravity.CENTER; translationX = context.dp(4f).toFloat(); translationY = context.dp(4f).toFloat()
                }, FrameLayout.LayoutParams(-1, -1))
                setOnClickListener {
                    button.play()
                    Handler(Looper.getMainLooper()).postDelayed({ if (isAdded) showModal(root) }, 800)
                }
            }, lp(context.dp(236f), context.dp(64f)))
            addView(context.text("Purchase includes access to 30+ courses, 240+ premium tutorials, 120+ hours of videos, source files and certificates.",
                TextStyle.Footnote, alpha = 0.7f), lp(-1, -2) { topMargin = context.dp(16f) })
        }
        root.addView(content, FrameLayout.LayoutParams(-1, -1))
        root.setBackgroundColor(context.color("Background"))
        root.post { shapes.play() }
        return root
    }

    /** [EN] The sign-in card over a dimmed page (`Color("Shadow").opacity(0.4)`), and its white close button. [CN] 变暗页面上的登录卡片（`Color("Shadow").opacity(0.4)`）及其白色关闭按钮。 */
    private fun showModal(root: FrameLayout) {
        if (modal != null) return
        val context = root.context
        val shadow = context.color("Shadow")
        val layer = FrameLayout(context).apply {
            setBackgroundColor((shadow and 0x00FFFFFF) or (0x66 shl 24))
            isClickable = true
            val card = SignInPage.card(context) { dismissModal(root) }
            addView(card, FrameLayout.LayoutParams(-1, -2, Gravity.CENTER).apply { setMargins(context.dp(16f), 0, context.dp(16f), context.dp(40f)) })
            addView(context.text("✕", color = Color.BLACK).apply {
                gravity = Gravity.CENTER; textSize = 16f
                background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.WHITE) }
                elevation = context.dp(5f).toFloat()
                setOnClickListener { dismissModal(root) }
            }, FrameLayout.LayoutParams(context.dp(36f), context.dp(36f), Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL).apply { bottomMargin = context.dp(24f) })
            alpha = 0f
            translationY = -context.dp(50f).toFloat()
        }
        root.addView(layer, FrameLayout.LayoutParams(-1, -1))
        layer.animate().alpha(1f).translationY(0f).setDuration(350).start()
        modal = layer
    }

    private fun dismissModal(root: FrameLayout) {
        val layer = modal ?: return
        modal = null
        layer.animate().alpha(0f).setDuration(250).withEndAction { root.removeView(layer) }.start()
    }
}

// MARK: - Bell: settings with RiveMenuButtonDemoView

/**
 * [EN] Bell: iOS `settingsViewController(headerView: RiveMenuButtonDemoView())`. menu_button.riv (88 × 88, state machine
 *      input "isOpen", held until stopped: duration 0) and "Play / Stop" above the settings list.
 * [CN] Bell：iOS `settingsViewController(headerView: RiveMenuButtonDemoView())`。设置列表上方是 menu_button.riv（88 × 88，状态机输入
 *      "isOpen"，保持到停止：duration 为 0）与 "播放 / 停止"。
 */
class BellPage : TitledPage("Bell") {
    private var isOn = false

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val menuButton = RiveAnimation("menu_button", mapOf(CYLConstants.CYLTabBarAnimationOptionRiveStateMachine to "State Machine",
            CYLConstants.CYLTabBarAnimationOptionRiveInput to "isOpen", CYLConstants.CYLTabBarAnimationOptionRiveActiveDuration to "0"))
        val list = FrameLayout(context).apply { id = View.generateViewId() }
        val header = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(0, context.dp(16f), 0, context.dp(8f))
            addView(menuButton.view(context, 88f), lp(context.dp(88f), context.dp(88f)))
            addView(context.text(getString(R.string.play_stop)).apply {
                textSize = 17f; setTypeface(typeface, Typeface.BOLD); setTextColor(Color.rgb(0, 122, 255)); setPadding(0, context.dp(12f), 0, 0)
                setOnClickListener { isOn = !isOn; if (isOn) menuButton.play() else menuButton.stop() }
            })
        }
        if (savedInstanceState == null) childFragmentManager.beginTransaction().add(list.id, DemoListFragment.newInstance(DemoCatalog.SETTINGS)).commit()
        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            addView(header)
            addView(list, lp(-1, 0) { weight = 1f })
        }
    }
}

// MARK: - User: SignInView

/**
 * [EN] User: iOS `SignInView`. "Sign in" shows check.riv ("Check" with an email, "Error" without) 1 s later; on success
 *      confetti.riv plays at 3 s and the card closes at 4 s when it is a modal.
 * [CN] User：iOS `SignInView`。"Sign in" 1 秒后显示 check.riv（有邮箱时为 "Check"，否则为 "Error"）；成功时 3 秒播放 confetti.riv，作为弹层时 4 秒关闭卡片。
 */
class SignInPage : TitledPage("User") {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        return ScrollView(context).apply {
            setBackgroundColor(context.color("Background"))
            addView(FrameLayout(context).apply { setPadding(context.dp(16f), context.dp(16f), context.dp(16f), context.dp(16f)); addView(card(context) {}) })
        }
    }

    companion object {
        /** [EN] The sign-in card; `close` is iOS `show.toggle()`. [CN] 登录卡片；`close` 对应 iOS 的 `show.toggle()`。 */
        fun card(context: Context, close: () -> Unit): View {
            val trigger = { name: String -> RiveAnimation("check", mapOf(CYLConstants.CYLTabBarAnimationOptionRiveStateMachine to "State Machine 1", CYLConstants.CYLTabBarAnimationOptionRiveTriggerInput to name)) }
            val checkSucceeded = trigger("Check")
            val checkFailed = trigger("Error")
            val confetti = RiveAnimation("confetti", mapOf(CYLConstants.CYLTabBarAnimationOptionRiveStateMachine to "State Machine 1",
                CYLConstants.CYLTabBarAnimationOptionRiveTriggerInput to "Trigger explosion"))
            val handler = Handler(Looper.getMainLooper())
            val email = field(context, "Icon Email", InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS)
            val password = field(context, "Icon Lock", InputType.TYPE_CLASS_TEXT or InputType.TYPE_TEXT_VARIATION_PASSWORD)
            val succeededView = checkSucceeded.view(context, 100f).apply { visibility = View.INVISIBLE }
            val failedView = checkFailed.view(context, 100f).apply { visibility = View.INVISIBLE }
            val secondary = Color.argb(153, 128, 128, 128)
            val form = LinearLayout(context).apply {
                orientation = LinearLayout.VERTICAL
                gravity = Gravity.CENTER_HORIZONTAL
                setPadding(context.dp(30f), context.dp(30f), context.dp(30f), context.dp(30f))
                fun gap() = lp(-1, -2) { topMargin = context.dp(24f) }
                addView(context.text("Sign in", TextStyle.LargeTitle))
                addView(context.text("Access to 240+ hours of content. Learn design and code, by building real apps with React and Swift.", color = secondary).apply { gravity = Gravity.CENTER }, gap())
                addView(labeled(context, "Email", email, secondary), gap())
                addView(labeled(context, "Password", password, secondary), gap())
                addView(signInButton(context) {
                    if (email.text.isNotEmpty()) {
                        showCheck(handler, checkSucceeded, succeededView, failedView) { confetti.play() }
                        handler.postDelayed(close, 4000)
                    } else {
                        showCheck(handler, checkFailed, failedView, succeededView) {}
                    }
                }, gap())
                addView(orDivider(context), gap())
                addView(context.text("Sign up with Email, Apple, Google", TextStyle.Subheadline, secondary), gap())
                addView(logos(context), gap())
            }
            return FrameLayout(context).apply {
                // [EN] `.regularMaterial`, a 20 pt card with a light border and a soft shadow. [CN] `.regularMaterial`：20 pt 圆角卡片，带浅色描边与柔和阴影。
                background = GradientDrawable().apply {
                    setColor(Color.argb(235, 255, 255, 255)); cornerRadius = context.dp(20f).toFloat(); setStroke(context.dp(1f), Color.argb(204, 255, 255, 255))
                }
                elevation = context.dp(12f).toFloat()
                addView(form, FrameLayout.LayoutParams(-1, -2))
                addView(confetti.view(context, 300f).apply { scaleX = 3f; scaleY = 3f; isClickable = false }, FrameLayout.LayoutParams(-1, -1))
                addView(succeededView, FrameLayout.LayoutParams(context.dp(100f), context.dp(100f), Gravity.CENTER))
                addView(failedView, FrameLayout.LayoutParams(context.dp(100f), context.dp(100f), Gravity.CENTER))
            }
        }

        /**
         * [EN] Shows `shown` (hiding `hidden`), plays `check` 1 s later, and at 3 s hides both and runs `then`.
         * [CN] 显示 `shown`（隐藏 `hidden`），1 秒后播放 `check`，3 秒时隐藏两者并执行 `then`。
         */
        private fun showCheck(handler: Handler, check: RiveAnimation, shown: View, hidden: View, then: () -> Unit) {
            shown.visibility = View.VISIBLE
            hidden.visibility = View.INVISIBLE
            handler.postDelayed({ check.play() }, 1000)
            handler.postDelayed({
                then()
                shown.visibility = View.INVISIBLE
            }, 3000)
        }

        /** [EN] `largeButton()`: F77D8E, corners 20 except the top left (8), "→ Sign in". [CN] `largeButton()`：F77D8E，左上角为 8，其余为 20，"→ Sign in"。 */
        private fun signInButton(context: Context, logIn: () -> Unit) = context.text("→  Sign in", TextStyle.Headline, Color.WHITE).apply {
            gravity = Gravity.CENTER
            setPadding(context.dp(20f), context.dp(20f), context.dp(20f), context.dp(20f))
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#F77D8E"))
                val big = context.dp(20f).toFloat()
                val small = context.dp(8f).toFloat()
                cornerRadii = floatArrayOf(small, small, big, big, big, big, big, big)
            }
            elevation = context.dp(10f).toFloat()
            setOnClickListener { logIn() }
        }

        /** [EN] Two faint lines around "OR". [CN] "OR" 两侧的淡色线条。 */
        private fun orDivider(context: Context) = LinearLayout(context).apply {
            gravity = Gravity.CENTER_VERTICAL
            addView(View(context).apply { setBackgroundColor(Color.argb(26, 0, 0, 0)) }, lp(0, context.dp(1f)) { weight = 1f })
            addView(context.text("OR", TextStyle.Subheadline2, Color.argb(77, 0, 0, 0)), lp(-2, -2) { marginStart = context.dp(8f); marginEnd = context.dp(8f) })
            addView(View(context).apply { setBackgroundColor(Color.argb(26, 0, 0, 0)) }, lp(0, context.dp(1f)) { weight = 1f })
        }

        /** [EN] The Email, Apple and Google logos, spread out. [CN] 均匀分布的 Email、Apple 与 Google 标志。 */
        private fun logos(context: Context) = LinearLayout(context).apply {
            listOf("Logo Email", "Logo Apple", "Logo Google").forEachIndexed { index, logo ->
                if (index > 0) addView(View(context), lp(0, 0) { weight = 1f })
                addView(context.image(logo))
            }
        }

        /** [EN] `customTextField(image:)`: white, 10 pt corners, a 10 % border, the icon at the leading edge. [CN] `customTextField(image:)`：白色、10 pt 圆角、10% 描边，图标在前端。 */
        private fun field(context: Context, icon: String, type: Int) = EditText(context).apply {
            inputType = type
            setTextColor(Color.BLACK)
            setPadding(context.dp(44f), context.dp(15f), context.dp(15f), context.dp(15f))
            background = GradientDrawable().apply { setColor(Color.WHITE); cornerRadius = context.dp(10f).toFloat(); setStroke(context.dp(1f), Color.argb(26, 0, 0, 0)) }
            setCompoundDrawablesRelativeWithIntrinsicBounds(DemoAssets.drawable(context, icon), null, null, null)
            compoundDrawablePadding = context.dp(12f)
            setPaddingRelative(context.dp(8f), context.dp(15f), context.dp(15f), context.dp(15f))
        }

        private fun labeled(context: Context, label: String, field: View, @ColorInt secondary: Int) = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            addView(context.text(label, TextStyle.Subheadline, secondary))
            addView(field, lp(-1, -2) { topMargin = context.dp(8f) })
        }
    }
}
