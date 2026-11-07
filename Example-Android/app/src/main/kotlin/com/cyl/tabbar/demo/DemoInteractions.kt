package com.cyl.tabbar.demo

import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.GradientDrawable
import android.media.RingtoneManager
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.SeekBar
import androidx.appcompat.widget.SwitchCompat
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLPlusButton
import com.cyl.tabbar.CYLPlusButtonSubclassing
import com.cyl.tabbar.CYLRectEdge
import com.cyl.tabbar.CYLSize
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.CYLTabBarControllerDelegate
import com.cyl.tabbar.CYLTabBarSlideTransitionAnimator
import com.cyl.tabbar.CYLTabButtonAnimation
import com.cyl.tabbar.CYLTabButtonBounceAnimation
import com.cyl.tabbar.CYLTabButtonFlipAnimation
import com.cyl.tabbar.CYLTabButtonRotationAnimation
import com.cyl.tabbar.CYLTabButtonScaleAnimation
import com.cyl.tabbar.CYLTabButtonZoomInAnimation
import com.cyl.tabbar.CYLViewController
import com.cyl.tabbar.cyl_popSelectTabBarChildViewControllerAtIndex
import com.cyl.tabbar.cyl_pushOrPopToViewController
import com.cyl.tabbar.cyl_pushViewController
import com.cyl.tabbar.cyl_tabBarController
import com.cyl.tabbar.cyl_tabButtonAnimation
import com.cyl.tabbar.cyl_tabIndex

/**
 * [EN] The rows of the library's settings groups after "Tab bar appearance": update tabs in place, pages / selection /
 *      login, the plus button, tab interactions and the helpers (iOS `UIViewController+CYLSettingsSection` and
 *      `UIViewController+CYLTabBarItemUpdate`).
 * [CN] 库设置分组中 "TabBar 外观" 之后的行：原地更新 Tab、页面 / 选中 / 登录、PlusButton、Tab 交互与工具方法（iOS
 *      `UIViewController+CYLSettingsSection` 与 `UIViewController+CYLTabBarItemUpdate`）。
 */
object DemoInteractions {

    // MARK: - Update tabs in place (#601) 原地更新 Tab

    /** [EN] The changes that are on, per tab bar controller (a second tap restores). [CN] 每个 TabBarController 已开启的修改（再点恢复）。 */
    private val updates = java.util.WeakHashMap<CYLTabBarController, MutableMap<String, Any?>>()
    private fun on(controller: CYLTabBarController) = updates.getOrPut(controller) { HashMap() }

    private fun toggle(page: DemoListFragment, key: String, apply: (CYLTabBarController, Int) -> Any?, restore: (CYLTabBarController, Int, Any?) -> Unit) {
        val controller = page.tabBarController ?: return
        val index = page.cyl_tabIndex.coerceAtLeast(0)
        val state = on(controller)
        if (state.containsKey(key)) restore(controller, index, state.remove(key)) else state[key] = apply(controller, index)
    }

    private fun isOn(page: DemoListFragment, key: String) = page.tabBarController?.let { on(it).containsKey(key) } == true

    private fun updateRow(key: String, title: String, subtitle: String, apply: (CYLTabBarController, Int) -> Any?, restore: (CYLTabBarController, Int, Any?) -> Unit) =
        DemoRow(title, { (if (isOn(this, key)) "✓ " else "") + subtitle }) { toggle(this, key, apply, restore) }

    private val networkIcons = listOf(
        "https://cdn-icons-png.flaticon.com/512/1946/1946488.png" to "https://cdn-icons-png.flaticon.com/512/1946/1946436.png",
        "https://cdn-icons-png.flaticon.com/512/2099/2099085.png" to "https://cdn-icons-png.flaticon.com/512/2099/2099085.png",
        "https://cdn-icons-png.flaticon.com/512/2099/2099100.png" to "https://cdn-icons-png.flaticon.com/512/2099/2099100.png",
        "https://cdn-icons-png.flaticon.com/512/1077/1077063.png" to "https://cdn-icons-png.flaticon.com/512/1077/1077114.png",
    )

    private fun restoreAll(controller: CYLTabBarController, saved: Any?) {
        @Suppress("UNCHECKED_CAST")
        (saved as? List<Map<String, Any?>>)?.let { controller.setViewControllers(controller.viewControllers, it) }
    }

    fun tabItemUpdateRows() = listOf(
        updateRow("title", "Change the tab title", "Changes the title of this page's tab in place; tap again to restore", { controller, index ->
            controller.tabBarItemAttributesAtIndex(index).also { controller.updateTabBarItemAtIndex(index, mapOf(CYLConstants.CYLTabBarItemTitle to "Courses")) }
        }) { controller, index, saved -> @Suppress("UNCHECKED_CAST") (saved as? Map<String, Any?>)?.let { controller.updateTabBarItemAtIndex(index, it) } },
        updateRow("iconView", "Switch the tab icon", "Replaces the icon of this page's tab with a custom view; tap again to restore", { controller, index ->
            controller.setTabBarItemIconViewProvider({ selected ->
                TextView(controller.activity).apply { text = if (selected) "★" else "☆"; textSize = 22f; gravity = Gravity.CENTER; setTextColor(Color.rgb(255, 149, 0)) }
            }, index)
        }) { controller, index, _ -> controller.setTabBarItemIconViewProvider(null, index) },
        updateRow("networkIcon", "Download a network icon", "Downloads the icon of this page's tab (cached); tap again to restore", { controller, index ->
            controller.tabBarItemsAttributes.toList().also {
                controller.setTabBarItemIconWithURL("https://cdn-icons-png.flaticon.com/512/3132/3132732.png", "https://cdn-icons-png.flaticon.com/512/3132/3132779.png", CYLSize(24f, 24f), index)
            }
        }) { controller, _, saved -> restoreAll(controller, saved) },
        updateRow("allNetworkIcons", "Download every network icon", "Downloads and updates the icons of every tab; tap again to restore", { controller, _ ->
            controller.tabBarItemsAttributes.toList().also {
                controller.tabBarItemsAttributes.indices.forEach { index ->
                    val (url, selected) = networkIcons[index % networkIcons.size]
                    controller.setTabBarItemIconWithURL(url, selected, CYLSize(24f, 24f), index)
                }
            }
        }) { controller, _, saved -> restoreAll(controller, saved) },
        updateRow("allLocalIcons", "Use local icons for every tab", "Updates every tab icon from local images (a resource, an asset file, a Drawable); tap again to restore", { controller, _ ->
            controller.tabBarItemsAttributes.toList().also {
                controller.tabBarItemsAttributes.indices.forEach { index ->
                    val icon = when (index % 3) {
                        0 -> ContextCompat.getDrawable(controller.activity, android.R.drawable.star_big_on)
                        1 -> assetImage(controller.activity, "cyl_tab_sample_animated.gif")
                        else -> GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.rgb(52, 199, 89)); setSize(48, 48) }
                    }
                    controller.setTabBarItemIcon(icon, icon, CYLSize(24f, 24f), index)
                }
            }
        }) { controller, _, saved -> restoreAll(controller, saved) },
        updateRow("gif", "GIF icon", "This page's tab shows a GIF (CYLTabBarGIFFilePath); tap again to restore", { controller, index ->
            controller.tabBarItemAttributesAtIndex(index).also {
                controller.updateTabBarItemAtIndex(index, mapOf(CYLConstants.CYLTabBarGIFFilePath to "file:///android_asset/cyl_tab_sample_animated.gif"))
            }
        }) { controller, index, saved -> @Suppress("UNCHECKED_CAST") (saved as? Map<String, Any?>)?.let { attributes ->
            controller.updateTabBarItemAtIndex(index, attributes + (CYLConstants.CYLTabBarGIFFilePath to null)) } },
        updateRow("allTitles", "Change every title", "Updates the titles of every tab at once; tap again to restore", { controller, _ ->
            controller.tabBarItemsAttributes.toList().also { saved ->
                controller.updateTabBarItemsWithAttributes(saved.mapIndexed { index, attributes -> attributes + (CYLConstants.CYLTabBarItemTitle to "Tab ${index + 1}") })
            }
        }) { controller, _, saved -> restoreAll(controller, saved) },
    )

    fun assetImage(context: Context, name: String) = try {
        context.assets.open(name).use { BitmapDrawable(context.resources, BitmapFactory.decodeStream(it)) }
    } catch (error: java.io.IOException) { null }

    // MARK: - Pages, selection, login 页面、选中与登录

    fun pageRows() = listOf(
        updateRow("replace", "Replace the pages of the neighboring tabs", "Replaces the tabs on both sides of this tab with other pages (issue #481); tap again to restore", { controller, index ->
            val saved = controller.viewControllers.toList() to controller.tabBarItemsAttributes.toList()
            listOf(index - 1, index + 1).filter { it in controller.viewControllers.indices }.forEach { side ->
                controller.replaceViewControllerAtIndex(side, TextPageFragment.newInstance("Replacement page ${side + 1}", background = Color.rgb(230, 230, 250)),
                    controller.tabBarItemsAttributes[side] + (CYLConstants.CYLTabBarItemTitle to "Replaced ${side + 1}"))
            }
            saved
        }) { controller, _, saved -> @Suppress("UNCHECKED_CAST") (saved as? Pair<List<Fragment>, List<Map<String, Any?>>>)?.let { controller.setViewControllers(it.first, it.second) } },
        DemoRow("selectedIndex and PlusButton (issue #515)", {
            val controller = tabBarController
            "selectedIndex = ${controller?.selectedIndex}, cyl_selectedIndexIgnoringPlusButton = ${controller?.cyl_selectedIndexIgnoringPlusButton}, plus button active: ${controller?.tabBar?.plusButtonActive}"
        }) {
            val controller = tabBarController ?: return@DemoRow
            controller.cyl_selectedIndexIgnoringPlusButton = (controller.cyl_selectedIndexIgnoringPlusButton + 1) % controller.viewControllers.size
        },
        DemoRow("Login state", { "Logged in: ${tabBarController?.cyl_loggedIn}. The \"Me\" tab needs a login (issue #19); tap to toggle" }) {
            val controller = tabBarController ?: return@DemoRow
            controller.cyl_loginRequiredTabBarItemIdentifiers = listOf(DemoCatalog.ME, "me")
            controller.cyl_presentLoginBlock = { tabBarController, _, completion ->
                android.app.AlertDialog.Builder(tabBarController.activity).setTitle("Log in")
                    .setPositiveButton("Log in") { _, _ -> completion(true) }
                    .setNegativeButton(android.R.string.cancel) { _, _ -> completion(false) }.show()
            }
            controller.cyl_loggedIn = !controller.cyl_loggedIn
        },
    )

    // MARK: - PlusButton

    fun plusButtonRows() = listOf(
        DemoRow("PlusButton touchable area (issue #91)", {
            val plus = tabBarController?.tabBar?.plusButton
            "Switch on to show the touchable area in translucent red; the slider scales it, current: ${plus?.touchableAreaScale ?: "-"}x"
        }) {
            val plus = tabBarController?.tabBar?.plusButton ?: return@DemoRow showMessage("PlusButton", "This tab bar has no plus button.")
            val context = requireContext()
            val switch = SwitchCompat(context).apply { text = "Show the touchable area"; isChecked = plus.showsTouchableArea }
            val slider = SeekBar(context).apply { max = 20; progress = ((plus.touchableAreaScale - 1f) * 10).toInt() }
            val content = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL; setPadding(48, 24, 48, 0); addView(switch); addView(slider) }
            android.app.AlertDialog.Builder(context).setTitle("PlusButton touchable area").setView(content)
                .setPositiveButton(android.R.string.ok) { _, _ ->
                    plus.showsTouchableArea = switch.isChecked
                    plus.touchableAreaScale = 1f + slider.progress / 10f
                    plus.invalidate()
                    reload()
                }.show()
        },
        DemoRow("PlusButton image set later", { "Pushes a tab bar controller whose plus button has no image; 2 s later the image loads, is replaced or removed, or a background loads. The layout must match a button that had its image from the start." }) {
            val cases = LateImagePlusButton.Case.values()
            choose("PlusButton image set later", cases.map { it.title }) { index -> LateImagePlusButton.open(requireContext(), cases[index]) }
        },
    )

    // MARK: - Tab interactions (#535) Tab 交互

    private class TapStep(val name: String, val type: CYLEnums.CYLTabButtonTapAnimationType = CYLEnums.CYLTabButtonTapAnimationType.None,
                          val animation: (() -> CYLTabButtonAnimation)? = null, val oneTab: Boolean = false)

    private val tapSteps = listOf(
        TapStep("None"),
        TapStep("Scale", CYLEnums.CYLTabButtonTapAnimationType.Scale),
        TapStep("Zoom in", CYLEnums.CYLTabButtonTapAnimationType.ZoomIn),
        TapStep("Bounce", CYLEnums.CYLTabButtonTapAnimationType.Bounce),
        TapStep("Bounce + fireworks", CYLEnums.CYLTabButtonTapAnimationType.BounceWithFireworks),
        TapStep("Rotation", CYLEnums.CYLTabButtonTapAnimationType.Rotation),
        TapStep("Flip", CYLEnums.CYLTabButtonTapAnimationType.Flip),
        TapStep("Fume", CYLEnums.CYLTabButtonTapAnimationType.Fume),
        TapStep("Slow scale (CYLTabButtonScaleAnimation, duration 1.2 s)", animation = { CYLTabButtonScaleAnimation().apply { duration = 1.2 } }),
        TapStep("Slow zoom in (CYLTabButtonZoomInAnimation, duration 1.2 s)", animation = { CYLTabButtonZoomInAnimation().apply { duration = 1.2 } }),
        TapStep("Star fireworks (CYLTabButtonBounceAnimation.fireworksImage)", animation = {
            CYLTabButtonBounceAnimation().apply { playsFireworks = true; fireworksImage = EmojiDrawable("⭐") }
        }),
        TapStep("Curl up (CYLTabButtonFlipAnimation.direction = 5)", animation = { CYLTabButtonFlipAnimation().apply { direction = 5; disablesDeselectAnimation = true } }),
        TapStep("Only this tab rotates (page.cyl_tabButtonAnimation)", animation = { CYLTabButtonRotationAnimation() }, oneTab = true),
    )
    private val tapStepOf = java.util.WeakHashMap<CYLTabBarController, Int>()

    private class FeedbackStep(val name: String, val sound: Boolean, val custom: Boolean = false, val haptic: CYLEnums.CYLImpactFeedbackStyle? = null)
    private val feedbackSteps = listOf(
        FeedbackStep("Off", false),
        FeedbackStep("Default tap sound", true),
        FeedbackStep("Custom sound file (cyl_tabButtonTapSoundURL)", true, custom = true),
        FeedbackStep("Light haptic", false, haptic = CYLEnums.CYLImpactFeedbackStyle.Light),
        FeedbackStep("Medium haptic", false, haptic = CYLEnums.CYLImpactFeedbackStyle.Medium),
        FeedbackStep("Heavy haptic", false, haptic = CYLEnums.CYLImpactFeedbackStyle.Heavy),
        FeedbackStep("Tap sound + haptic", true, haptic = CYLEnums.CYLImpactFeedbackStyle.Medium),
    )
    private val feedbackStepOf = java.util.WeakHashMap<CYLTabBarController, Int>()

    private val longPressDurations = listOf(0.3, 0.5, 1.0)
    private val doubleTapIntervals = listOf(0.2, 0.3, 0.5)

    fun interactionRows() = listOf(
        DemoRow("Tab tap animation (issue #535)", { "Tap to switch the tap animation of the tabs and the PlusButton, current: ${tapSteps[tabBarController?.let { tapStepOf[it] } ?: 0].name}" }) {
            val controller = tabBarController ?: return@DemoRow
            choose("Tab tap animation", tapSteps.map { it.name }, tapStepOf[controller] ?: 0) { index ->
                tapStepOf[controller] = index
                val step = tapSteps[index]
                controller.cyl_defaultTabButtonAnimation = null
                controller.viewControllers.forEach { it.cyl_tabButtonAnimation = null }
                controller.cyl_tabButtonTapAnimationType = step.type
                val animation = step.animation?.invoke()
                if (step.oneTab) controller.selectedViewController?.cyl_tabButtonAnimation = animation else controller.cyl_defaultTabButtonAnimation = animation
                controller.tabBar.tabBarButtonArray.getOrNull(controller.selectedIndex)?.let { controller.cyl_playTabButtonAnimationForControl(it) }
            }
        },
        DemoRow("Tab tap sound and haptic feedback (issue #535)", { "Current: ${feedbackSteps[tabBarController?.let { feedbackStepOf[it] } ?: 0].name}" }) {
            val controller = tabBarController ?: return@DemoRow
            choose("Tap feedback", feedbackSteps.map { it.name }, feedbackStepOf[controller] ?: 0) { index ->
                feedbackStepOf[controller] = index
                val step = feedbackSteps[index]
                controller.cyl_tabButtonTapSoundEnabled = step.sound
                controller.cyl_tabButtonTapSoundURL = if (step.custom) RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION) else null
                controller.cyl_tabButtonHapticFeedbackEnabled = step.haptic != null
                step.haptic?.let { controller.cyl_tabButtonHapticFeedbackStyle = it }
                controller.cyl_playTabButtonTapFeedback()
            }
        },
        DemoRow("Long press a tab (issue #535)", { "cyl_didLongPressControlBlock: ${if (tabBarController?.cyl_didLongPressControlBlock != null) "on" else "off"}" }) {
            val controller = tabBarController ?: return@DemoRow
            controller.cyl_didLongPressControlBlock = if (controller.cyl_didLongPressControlBlock != null) null else { tabBarController, control ->
                android.widget.Toast.makeText(tabBarController.activity, "Long pressed: " + ((control as? com.cyl.tabbar.CYLTabBarItemButton)?.item?.title ?: "PlusButton"), android.widget.Toast.LENGTH_SHORT).show()
            }
        },
        DemoRow("Long press duration and double tap interval (issue #535 / #152)", {
            "cyl_tabBarItemLongPressDuration = ${tabBarController?.cyl_tabBarItemLongPressDuration} s, cyl_tabBarItemDoubleTapInterval = ${tabBarController?.cyl_tabBarItemDoubleTapInterval} s"
        }) {
            val controller = tabBarController ?: return@DemoRow
            val options = longPressDurations.flatMap { press -> doubleTapIntervals.map { tap -> press to tap } }
            choose("Long press / double tap", options.map { "Long press ${it.first} s, double tap ${it.second} s" },
                options.indexOf(controller.cyl_tabBarItemLongPressDuration to controller.cyl_tabBarItemDoubleTapInterval)) { index ->
                controller.cyl_tabBarItemLongPressDuration = options[index].first
                controller.cyl_tabBarItemDoubleTapInterval = options[index].second
                controller.cyl_tabBarItemGestureHandler = { tabBarController, gesture, _, _ ->
                    android.widget.Toast.makeText(tabBarController.activity, gesture.name, android.widget.Toast.LENGTH_SHORT).show()
                }
            }
        },
        DemoRow("Swipe left or right to switch tabs (issue #535)", { "cyl_swipeToSwitchTabEnabled = ${tabBarController?.cyl_swipeToSwitchTabEnabled}" }) {
            tabBarController?.let { it.cyl_swipeToSwitchTabEnabled = !it.cyl_swipeToSwitchTabEnabled }
        },
        DemoRow("Switch to the previous / next tab (issue #535)", { "cyl_switchToAdjacentTabWithStep:animated:" }) {
            val controller = tabBarController ?: return@DemoRow
            choose("Adjacent tab", listOf("Previous tab", "Next tab")) { index -> controller.cyl_switchToAdjacentTabWithStep(if (index == 0) -1 else 1, true) }
        },
        DemoRow("Slide transition (CYLTabBarSlideTransitionAnimator)", { "Delegate returns a slide animator: ${if (tabBarController?.delegate is SlideDelegate) "on" else "off"}" }) {
            val controller = tabBarController ?: return@DemoRow
            controller.delegate = if (controller.delegate is SlideDelegate) null else SlideDelegate
        },
    )

    /** [EN] Slides the pages in the direction of the tab, as the iOS row's delegate. [CN] 按 Tab 方向滑动页面，对应 iOS 行的代理。 */
    private object SlideDelegate : CYLTabBarControllerDelegate {
        override fun tabBarController_animationControllerForTransition(tabBarController: CYLTabBarController, fromViewController: CYLViewController, toViewController: CYLViewController): CYLTabBarSlideTransitionAnimator {
            val toRight = tabBarController.viewControllers.indexOf(toViewController) > tabBarController.viewControllers.indexOf(fromViewController)
            return CYLTabBarSlideTransitionAnimator(if (toRight) CYLRectEdge.Left else CYLRectEdge.Right)
        }
    }

    // MARK: - Helpers 工具方法

    fun helperRows() = listOf(
        DemoRow("Hide the navigation bar without a base class (issue #535)", { "Pushes a page that hides the action bar while shown, with no base class" }) {
            cyl_pushViewController(NavigationBarHiddenPage())
        },
        DemoRow("Touches outside the super view (issue #535)", { "The plus button sticks out of the bar; its part above the bar responds (shown in red)" }) {
            val plus = tabBarController?.tabBar?.plusButton ?: return@DemoRow showMessage("PlusButton", "This tab bar has no plus button.")
            plus.showsTouchableArea = !plus.showsTouchableArea
            plus.invalidate()
        },
        DemoRow("Load an image from the bundle (issue #535)", { "The image of this page's tab from the app assets (the resource bundle of Android)" }) {
            val controller = tabBarController ?: return@DemoRow
            val icon = assetImage(requireContext(), "cyl_tab_sample_animated.gif")
            controller.setTabBarItemIcon(icon, icon, CYLSize(24f, 24f), cyl_tabIndex.coerceAtLeast(0))
        },
        DemoRow("Helpers: find tab buttons and weak references (issue #535)", { "cyl_controlWithTabBarItemIdentifier, cyl_viewControllerWithTabBarItemIdentifier, cyl_tabBarController" }) {
            val controller = tabBarController ?: return@DemoRow
            val lines = controller.cyl_tabBarItemIdentifiers.map { identifier ->
                "$identifier: button ${controller.cyl_controlWithTabBarItemIdentifier(identifier)?.javaClass?.simpleName}, page ${controller.cyl_viewControllerWithTabBarItemIdentifier(identifier)?.javaClass?.simpleName}"
            }
            val weak = java.lang.ref.WeakReference(controller)
            showMessage("CYLUtils", lines.joinToString("\n") + "\n\nWeak reference to the controller: ${weak.get() != null}\nselected: ${controller.cyl_selectedTabBarItemIdentifier}")
        },
    )
}

/** [EN] A page that hides the action bar while it is shown (iOS `cyl_setNavigationBarHidden:` without a base class). [CN] 显示期间隐藏 ActionBar 的页面（iOS 无需基类的 `cyl_setNavigationBarHidden:`）。 */
class NavigationBarHiddenPage : Fragment() {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View =
        TextView(inflater.context).apply {
            text = "The action bar is hidden while this page is shown.\nPress Back."
            gravity = Gravity.CENTER
            setBackgroundColor(Color.rgb(255, 204, 0))
            isClickable = true
        }

    override fun onResume() { super.onResume(); (activity as? AppCompatActivity)?.supportActionBar?.hide() }
    override fun onPause() { (activity as? AppCompatActivity)?.supportActionBar?.show(); super.onPause() }
}

/**
 * [EN] The `cyl_pop` / `cyl_push` demo (iOS `CYLPopPushDemoViewController`): buttons that push, push or pop, and pop to
 *      another tab.
 * [CN] `cyl_pop` / `cyl_push` 演示（iOS `CYLPopPushDemoViewController`）：push、push 或 pop、pop 到其他 Tab 的按钮。
 */
class DemoPopPushFragment : Fragment() {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val column = LinearLayout(context).apply { orientation = LinearLayout.VERTICAL; gravity = Gravity.CENTER; setBackgroundColor(Color.WHITE); isClickable = true }
        fun button(title: String, action: () -> Unit) = column.addView(Button(context).apply { text = title; setOnClickListener { action() } })
        column.addView(TextView(context).apply { text = "Tab ${cyl_tabIndex + 1}"; gravity = Gravity.CENTER; textSize = 18f })
        button("cyl_pushViewController") { cyl_pushViewController(DemoPopPushFragment()) }
        button("cyl_pushOrPopToViewController (tab 1)") {
            cyl_pushOrPopToViewController(DemoPopPushFragment(), true) { stack, handler -> handler(stack.size > 1, stack.firstOrNull(), true, 0) }
        }
        button("cyl_popSelectTabBarChildViewControllerAtIndex: next tab") {
            val controller = cyl_tabBarController ?: return@button
            cyl_popSelectTabBarChildViewControllerAtIndex((cyl_tabIndex + 1) % controller.viewControllers.size)
        }
        return column
    }
}

/**
 * [EN] The iOS "PlusButton image set later" scenes: a plus button created without an image, whose image arrives 2 s later.
 * [CN] iOS "PlusButton 图片之后才加载" 场景：创建时没有图片的 PlusButton，图片 2 秒后才到。
 */
object LateImagePlusButton {
    enum class Case(val title: String) {
        Loaded("Load an image"), Replaced("Replace with a larger image"), Removed("Remove the image"), BackgroundLoaded("Load a background image"),
        ReadyImage("Image from the start (reference)"), ReadyLargerImage("Larger image from the start (reference)"), ReadyBackground("Background from the start (reference)"),
    }

    private const val CONTEXT = "LateImagePlusButton"

    fun open(context: Context, case: Case) {
        val provider = object : CYLPlusButtonSubclassing {
            override fun plusButton(context: Context) = CYLPlusButton(context).apply {
                setTitle("Publish")
                val small = ContextCompat.getDrawable(context, android.R.drawable.ic_input_add)
                val large = ContextCompat.getDrawable(context, android.R.drawable.ic_menu_add)
                val background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.rgb(0, 122, 255)) }
                when (case) {
                    Case.ReadyImage -> setImageDrawable(small)
                    Case.ReadyLargerImage -> setImageDrawable(large)
                    Case.ReadyBackground -> this.background = background
                    Case.Removed -> setImageDrawable(small)
                    else -> Unit
                }
                Handler(Looper.getMainLooper()).postDelayed({
                    when (case) {
                        Case.Loaded -> setImageDrawable(small)
                        Case.Replaced -> { setImageDrawable(small); postDelayed({ setImageDrawable(large) }, 1000) }
                        Case.Removed -> setImageDrawable(null)
                        Case.BackgroundLoaded -> this.background = background
                        else -> Unit
                    }
                }, 2000)
            }
            override fun tabBarContext() = CONTEXT
            override fun plusChildViewController(): Fragment = TextPageFragment.newInstance("Publish")
        }
        DemoHostActivity.openTabBar(context, case.title) { activity -> DemoTabs.controller(activity, CONTEXT, provider) }
    }
}

/**
 * [EN] Issue #202: a plus button with a tappable X at its top right; tapping the X changes its color and does not tap the
 *      plus button.
 * [CN] Issue #202：右上角带可点击 X 的 PlusButton；点击 X 改变其颜色，不会触发 PlusButton。
 */
object CloseSubviewPlusButton {
    const val CONTEXT = "CloseSubviewPlusButton"

    val Provider = object : CYLPlusButtonSubclassing {
        override fun plusButton(context: Context): CYLPlusButton {
            val density = context.resources.displayMetrics.density
            return object : CYLPlusButton(context) {
                val close = TextView(context).apply {
                    text = "✕"; gravity = Gravity.CENTER; setTextColor(Color.WHITE); textSize = 10f
                    background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.RED) }
                    setOnClickListener { (background as GradientDrawable).setColor(Color.rgb((0..255).random(), (0..255).random(), (0..255).random())) }
                }
                init {
                    background = GradientDrawable().apply { shape = GradientDrawable.OVAL; setColor(Color.rgb(88, 86, 214)) }
                    setImageDrawable(ContextCompat.getDrawable(context, android.R.drawable.ic_input_add))
                    imageView.setColorFilter(Color.WHITE)
                    minimumWidth = (52 * density).toInt(); minimumHeight = (52 * density).toInt()
                    clipChildren = false
                    addView(close, LayoutParams((18 * density).toInt(), (18 * density).toInt()))
                }
                override fun onLayout(changed: Boolean, l: Int, t: Int, r: Int, b: Int) {
                    super.onLayout(changed, l, t, r, b)
                    val size = (18 * density).toInt()
                    close.layout(width - size, 0, width, size)
                }
            }
        }
        override fun multiplierOfTabBarHeight(tabBarHeight: Float) = 0.3f
        override fun tabBarContext() = CONTEXT
        override fun plusChildViewController(): Fragment = TextPageFragment.newInstance("PlusButton (issue #202)")
    }
}
