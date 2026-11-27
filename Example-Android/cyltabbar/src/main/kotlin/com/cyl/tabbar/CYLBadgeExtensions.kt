// [EN] The method names are the iOS names on purpose (`cyl_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`），见 docs/Android-API-Map.md。
// [EN] kotlin:S1133: the deprecated members are the twins of deprecated iOS API, kept until iOS removes them. [CN] kotlin:S1133：已废弃的成员与 iOS 已废弃的 API 对应，在 iOS 移除前保留。
@file:Suppress("FunctionName", "kotlin:S100", "kotlin:S1133")

package com.cyl.tabbar

import android.app.AlertDialog
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.AbsListView
import android.widget.BaseAdapter
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import androidx.annotation.ColorInt
import androidx.fragment.app.Fragment

/*
 * [EN] The rest of the badge component (`CYLBadgeView` subspec): the app-wide appearance (#425), the text-displaying
 *      protocol and `CYLTabBarBadgeView`, badges on menu items (bar buttons), tab items and controls, the badge samples of
 *      the demos (rows, a sample table, a navigation badge) and the memory warning check (#426).
 * [CN] 角标组件（`CYLBadgeView` 子库）的其余部分：App 级外观（#425）、文字显示协议与 `CYLTabBarBadgeView`、菜单项（栏按钮）、Tab item 与控件上的
 *      角标、Demo 的角标示例（行、示例列表、导航栏角标）以及内存警告检查（#426）。
 */

// MARK: - UIControl (CYLBadgeExtention): Android controls are views, see the View extensions in CYLBadge.kt.

// MARK: - UITabBarItem (CYLBadgeExtention)

/**
 * [EN] `-[UITabBarItem cylIsShowBadge]`: the badge of the item's tab button. [CN] item 的 Tab 按钮上的角标是否显示。
 */
fun CYLTabBarItem.cylIsShowBadge(): Boolean = cyl_visiableTabButton?.cylIsShowBadge() ?: false
/**
 * [EN] The tab button forwards its events (and the posted badge moments) to its item, as the iOS tab button does to its `UITabBarItem`: `LifecycleRegistry.of(item)`
 *      then hears `cyl.badge.*`. Called before every badge call; forwarding to the same target again replaces the earlier forward, so it stays one.
 * [CN] Tab 按钮把自己的事件（以及发出的角标时机）转发给它的 item，与 iOS Tab 按钮转发给 `UITabBarItem` 相同：`LifecycleRegistry.of(item)` 即可收到
 *      `cyl.badge.*`。每次角标调用前都会调用；再次转发给同一目标会替换原来的转发，所以始终只有一个。
 */
private fun CYLTabBarItem.badgeButton(): View? = cyl_visiableTabButton?.also {
    com.chenyilong.cyldeallocblockexecutor.LifecycleRegistry.of(it).forwardLifecycleEvents(com.chenyilong.cyldeallocblockexecutor.LifecycleRegistry.of(this))
}

fun CYLTabBarItem.cylShowBadge() { badgeButton()?.cylShowBadge() }
fun CYLTabBarItem.cylShowBadgeValue(value: String, animationType: CYLEnums.CYLBadgeAnimationType) { badgeButton()?.cylShowBadgeValue(value, animationType) }
fun CYLTabBarItem.cylClearBadge() { badgeButton()?.cylClearBadge() }
fun CYLTabBarItem.cylResumeBadge() { cyl_visiableTabButton?.cylResumeBadge() }
fun CYLTabBarItem.cylIsPauseBadge(): Boolean = cyl_visiableTabButton?.cylIsPauseBadge() ?: false

// MARK: - UIBarButtonItem (CYLBadgeExtention): menu items of a Toolbar 工具栏菜单项

/**
 * [EN] The view of a menu item in a visible toolbar: its action view, else its button in an `ActionMenuView`. [CN] 菜单项在可见工具栏中的视图：其 action view，否则为 `ActionMenuView` 中的按钮。
 */
fun MenuItem.cylFindBarButtonContentView(): View? {
    actionView?.let { return it }
    for (controller in CYLTabBarController.cyl_liveTabBarControllers()) {
        controller.activity.window?.decorView?.let { root -> findMenuItemView(root, this)?.let { return it } }
    }
    return null
}

private fun findMenuItemView(view: View, item: MenuItem): View? {
    if (CYLReflection.call(view, "getItemData") === item) return view
    val group = view as? ViewGroup ?: return null
    for (index in 0 until group.childCount) findMenuItemView(group.getChildAt(index), item)?.let { return it }
    return null
}

/**
 * [EN] Runs `action` on the item's view, now or once the toolbar laid it out (a few frames). [CN] 在菜单项的视图上执行 `action`，立即或等工具栏布局后。
 */
private fun MenuItem.withBarButtonView(attempts: Int = 10, action: (View) -> Unit) {
    val view = cylFindBarButtonContentView()
    if (view != null) return action(view)
    if (attempts <= 0) return
    android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({ withBarButtonView(attempts - 1, action) }, 50)
}

fun MenuItem.cylIsShowBadge(): Boolean = cylFindBarButtonContentView()?.cylIsShowBadge() ?: false
fun MenuItem.cylShowBadge() = withBarButtonView { it.cylShowBadge() }
fun MenuItem.cylShowBadgeValue(value: String, animationType: CYLEnums.CYLBadgeAnimationType) = withBarButtonView { it.cylShowBadgeValue(value, animationType) }
/**
 * [EN] `-cylShowBadgeValue:animationType:backgroundColor:`: null keeps the default color. [CN] null 保持默认颜色。
 */
fun MenuItem.cylShowBadgeValue(value: String, animationType: CYLEnums.CYLBadgeAnimationType, @ColorInt backgroundColor: Int?) = withBarButtonView { view ->
    backgroundColor?.let { view.cylBadgeBackgroundColor = it }
    view.cylShowBadgeValue(value, animationType)
}
fun MenuItem.cylClearBadge() { cylFindBarButtonContentView()?.cylClearBadge() }
fun MenuItem.cylResumeBadge() { cylFindBarButtonContentView()?.cylResumeBadge() }
fun MenuItem.cylIsPauseBadge(): Boolean = cylFindBarButtonContentView()?.cylIsPauseBadge() ?: false

// MARK: - The badge samples (UITableViewCell (CYLBadgeExtention)) 角标示例

/**
 * [EN] `CYLBadgeRowHeight`: a row height that leaves room around the icon for its badge (dp). [CN] 为图标的角标留出空间的行高（dp）。
 */
const val CYLBadgeRowHeight: Float = 60f

private data class CYLBadgeSample(
    val title: String,
    val api: String?,
    val value: String,
    val animationType: CYLEnums.CYLBadgeAnimationType = CYLEnums.CYLBadgeAnimationType.None,
    val repeats: Int = 0,
    val maximum: Int? = null,
    val colors: Boolean = false,
    val font: Boolean = false,
    val border: Boolean = false,
    val radius: Float? = null,
    val margin: Float? = null,
    val cornerRadius: Float? = null,
    val reduceMotion: Boolean = false,
    val position: String? = null,
    /**
     * [EN] An iOS factory animation (`CYLBadgeHelperAnimation`) that no `CYLBadgeAnimationType` matches. [CN] 没有对应 `CYLBadgeAnimationType` 的 iOS 工厂动画（`CYLBadgeHelperAnimation`）。
     */
    val factory: ((CYLBadgeView) -> android.animation.Animator)? = null,
)

/**
 * [EN] `cyl_rotationAnimationWithDuration:2 degree:2π direction:CYLAxisZ repeatCount:HUGE_VALF`: a full turn in the screen plane every 2 s. [CN] 每 2 秒在屏幕平面内转一整圈。
 */
private val CYLBadgeRotationForever: (CYLBadgeView) -> android.animation.Animator = { badge ->
    android.animation.ObjectAnimator.ofFloat(badge, View.ROTATION, 0f, 360f).setDuration(2000).apply {
        repeatCount = android.animation.ObjectAnimator.INFINITE
        interpolator = android.view.animation.LinearInterpolator()
    }
}

/**
 * [EN] `cyl_rotationAnimationWithDuration:1 degree:π direction:CYLAxisY repeatCount:2`: half a turn around the vertical axis, twice. [CN] 绕竖直轴转半圈，共两次。
 */
private val CYLBadgeFlipTwice: (CYLBadgeView) -> android.animation.Animator = { badge ->
    android.animation.ObjectAnimator.ofFloat(badge, View.ROTATION_Y, 0f, 180f).setDuration(1000).apply { repeatCount = 1 }
}

/**
 * [EN] Every badge style and animation, in the order of the iOS samples. [CN] 每种角标样式与动画，顺序与 iOS 示例相同。
 */
private val CYLBadgeSamples: List<CYLBadgeSample> = run {
    listOf(
        CYLBadgeSample("Scale (forever)", "CYLBadgeAnimationTypeScale", "3", CYLEnums.CYLBadgeAnimationType.Scale),
        CYLBadgeSample("Shake (forever)", "CYLBadgeAnimationTypeShake", "3", CYLEnums.CYLBadgeAnimationType.Shake),
        CYLBadgeSample("Bounce (forever)", "CYLBadgeAnimationTypeBounce", "3", CYLEnums.CYLBadgeAnimationType.Bounce),
        CYLBadgeSample("Breathe (forever)", "CYLBadgeAnimationTypeBreathe", "", CYLEnums.CYLBadgeAnimationType.Breathe),
        CYLBadgeSample("Shake, stops with Reduce Motion", "cyl_badgeRespectsReduceMotion", "3", CYLEnums.CYLBadgeAnimationType.Shake, reduceMotion = true),
        CYLBadgeSample("Rotation (forever)", "cyl_rotationAnimationWithDuration:", "new", factory = CYLBadgeRotationForever),
        CYLBadgeSample("Spring (forever)", "cyl_springAnimationForDuration:", "3", CYLEnums.CYLBadgeAnimationType.ScaleOnce, repeats = -1),
        CYLBadgeSample("Shake ×3 (cyl_shakeAnimationRepeatTimes)", null, "3", CYLEnums.CYLBadgeAnimationType.Shake, repeats = 3),
        CYLBadgeSample("Bounce ×3 (cyl_bounceAnimationRepeatTimes)", null, "3", CYLEnums.CYLBadgeAnimationType.Bounce, repeats = 3),
        CYLBadgeSample("Scale ×3", "cyl_scaleAnimationFromScale:", "3", CYLEnums.CYLBadgeAnimationType.Scale, repeats = 3),
        CYLBadgeSample("Blink ×3", "cyl_opacityTimesAnimationRepeatTimes:", "", CYLEnums.CYLBadgeAnimationType.Breathe, repeats = 3),
        CYLBadgeSample("Flip ×2", "cyl_rotationAnimationWithDuration:", "3", factory = CYLBadgeFlipTwice),
        CYLBadgeSample("Left to right once", "CYLBadgeAnimationTypeLeftRightOnce", "3", CYLEnums.CYLBadgeAnimationType.LeftRightOnce),
        CYLBadgeSample("Right to left once", "CYLBadgeAnimationTypeRightLeftOnce", "3", CYLEnums.CYLBadgeAnimationType.RightLeftOnce),
        CYLBadgeSample("Fade in once", "CYLBadgeAnimationTypeFadeInOnce", "3", CYLEnums.CYLBadgeAnimationType.FadeInOnce),
        CYLBadgeSample("Rolling once", "CYLBadgeAnimationTypeRollingOnce", "3", CYLEnums.CYLBadgeAnimationType.RollingOnce),
        CYLBadgeSample("Scale once", "CYLBadgeAnimationTypeScaleOnce", "3", CYLEnums.CYLBadgeAnimationType.ScaleOnce),
        CYLBadgeSample("Spring once", "cyl_springAnimationForDuration:", "3", CYLEnums.CYLBadgeAnimationType.ScaleOnce),
        CYLBadgeSample("Red dot", "cyl_showBadge", ""),
        CYLBadgeSample("Number", "cyl_showBadgeValue:", "8"),
        CYLBadgeSample("Number above maximum", "cyl_badgeMaximumBadgeNumber", "100"),
        CYLBadgeSample("Custom maximum (9)", "cyl_badgeMaximumBadgeNumber", "10", maximum = 9),
        CYLBadgeSample("New", "cyl_showBadgeValue:@\"new\"", "new"),
        CYLBadgeSample("NEW", "cyl_showBadgeValue:@\"NEW\"", "NEW"),
        CYLBadgeSample("Other text", "cyl_showBadgeValue:", "hot"),
        CYLBadgeSample("Custom colors", "cyl_badgeBackgroundColor / cyl_badgeTextColor", "5", colors = true),
        CYLBadgeSample("Custom font", "cyl_badgeFont", "5", font = true),
        CYLBadgeSample("Border", "cyl_badgeBorderColor / cyl_badgeBorderWidth", "5", border = true),
        CYLBadgeSample("Border following Dark Mode", "cyl_badgeBorderColor", "5", border = true),
        CYLBadgeSample("Red dot radius", "cyl_badgeRadius", "", radius = 6f),
        CYLBadgeSample("Margin", "cyl_badgeMargin", "5", margin = 7f),
        CYLBadgeSample("Corner radius", "cyl_badgeCornerRadius", "new", cornerRadius = 3f),
        CYLBadgeSample("Top left", "cyl_badgeCenterOffset", "5", position = "topLeft"),
        CYLBadgeSample("Bottom left", "cyl_badgeCenterOffset", "5", position = "bottomLeft"),
        CYLBadgeSample("Bottom right", "cyl_badgeCenterOffset", "5", position = "bottomRight"),
    )
}

private fun sampleForRow(row: Int) = CYLBadgeSamples[row.coerceAtLeast(0) % CYLBadgeSamples.size]

/**
 * [EN] `+cylBadgeTitleForRow:`: "<row + 1>. <title> (<API>)". [CN] 第 row 行示例的标题与核心 API。
 */
fun cylBadgeTitleForRow(row: Int): String {
    val sample = sampleForRow(row)
    val title = if (sample.api != null && !sample.title.contains(sample.api)) "${sample.title} (${sample.api})" else sample.title
    return "${row + 1}. $title"
}

/**
 * [EN] `+cylBadgeStyleCount`: the number of samples. [CN] 示例数量。
 */
fun cylBadgeStyleCount(): Int = CYLBadgeSamples.size

/**
 * [EN] `-cylShowBadgeForRow:` on the row's icon view: shows the sample icon and the row's badge (style and animation change
 *      with the row). Rows are reused: the previous badge and options are cleared first.
 * [CN] 在行的图标视图上显示示例图标与该行的角标（样式与动画随行变化）。行会复用：先清除之前的角标与选项。
 */
/**
 * [EN] `+cylBadgeIcon`: the sample icon of the badge rows, the library's `cyl_badge_sample_icon` (the iOS resource bundle's
 *      image) with 6 dp rounded corners on a 30 dp square, as on iOS; a blue square if the image cannot be decoded.
 * [CN] `+cylBadgeIcon`：角标示例行的图标，即库自带的 `cyl_badge_sample_icon`（iOS 资源 bundle 中的图片），在 30 dp 正方形上带 6 dp 圆角，
 *      与 iOS 相同；图片无法解码时为蓝色方块。
 */
fun cylBadgeIcon(view: View): android.graphics.drawable.Drawable {
    val density = view.resources.displayMetrics.density
    val bitmap = android.graphics.BitmapFactory.decodeResource(view.resources, R.drawable.cyl_badge_sample_icon)
        ?: return GradientDrawable().apply { cornerRadius = 6 * density; setColor(Color.rgb(0, 122, 255)); setSize((30 * density).toInt(), (30 * density).toInt()) }
    return androidx.core.graphics.drawable.RoundedBitmapDrawableFactory.create(view.resources, bitmap).apply {
        cornerRadius = bitmap.width * 6f / 30f
        setAntiAlias(true)
    }
}

fun ImageView.cylShowBadgeForRow(row: Int) {
    val sample = sampleForRow(row)
    val density = resources.displayMetrics.density
    setImageDrawable(cylBadgeIcon(this))
    // [EN] The badge rises above the icon, past the row's top while it animates: neither the row nor the list clips it (iOS: `clipsToBounds = NO`). [CN] 角标凸出图标，动画时会超出行的顶部：行与列表都不裁剪它（iOS：`clipsToBounds = NO`）。
    (parent as? ViewGroup)?.let { row -> row.clipChildren = false; (row.parent as? ViewGroup)?.clipChildren = false }
    cylClearBadge()
    cylResetBadgeAppearance()
    applyBadgeSample(sample)
    cylShowBadgeValue(sample.value, if (sample.repeats == 0) sample.animationType else CYLEnums.CYLBadgeAnimationType.None)
    if (sample.repeats != 0) repeatBadgeSampleAnimation(sample)
    sample.factory?.let { factory -> cylBadge?.let { badge -> badge.playAnimator(factory(badge)) } }
}

/**
 * [EN] The appearance options of a sample row. [CN] 示例行的外观选项。
 */
private fun ImageView.applyBadgeSample(sample: CYLBadgeSample) {
    if (sample.colors) { cylBadgeBackgroundColor = Color.rgb(128, 0, 128); cylBadgeTextColor = Color.YELLOW }
    if (sample.font) cylBadgeFont = CYLFont(12f, Typeface.create(Typeface.DEFAULT, Typeface.ITALIC))
    if (sample.border) {
        val dark = (resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK) == android.content.res.Configuration.UI_MODE_NIGHT_YES
        cylBadgeBorderColor = if (sample.title.contains("Dark")) (if (dark) Color.WHITE else Color.BLACK) else Color.WHITE
        cylBadgeBorderWidth = 2f
    }
    sample.position?.let { position ->
        val toLeft = -(30f + 4f)
        cylBadgeCenterOffset = when (position) { "topLeft" -> CYLOffset(toLeft, 0f); "bottomLeft" -> CYLOffset(toLeft, 30f); else -> CYLOffset(0f, 30f) }
    }
    sample.radius?.let { cylBadgeRadius = it }
    sample.margin?.let { cylBadgeMargin = it }
    sample.cornerRadius?.let { cylBadgeCornerRadius = it }
    sample.maximum?.let { cylBadgeMaximumBadgeNumber = it }
    cylBadgeRespectsReduceMotion = sample.reduceMotion
}

/**
 * [EN] The CAAnimation factory samples: the same animation, repeated a few times or forever. [CN] CAAnimation 工厂示例：同一动画重复几次或一直重复。
 */
private fun ImageView.repeatBadgeSampleAnimation(sample: CYLBadgeSample) {
    val badge = cylBadge ?: return
    var left = sample.repeats
    fun again() {
        badge.play(sample.animationType)
        if (left < 0 || --left > 0) badge.postDelayed({ if (badge.isAttachedToWindow) again() }, 1000)
    }
    again()
}

/**
 * [EN] `-cyl_wrapsTextLabels`: the row's texts wrap onto as many lines as they need, never ellipsized. [CN] 行中的文字按需换行，不省略。
 */
fun View.cyl_wrapsTextLabels() {
    if (this is TextView) { maxLines = Int.MAX_VALUE; ellipsize = null; setSingleLine(false) }
    (this as? ViewGroup)?.let { group -> for (index in 0 until group.childCount) group.getChildAt(index).cyl_wrapsTextLabels() }
}

/**
 * [EN] `+cyl_setUpAutomaticRowHeightForTableView:`: rows as high as their text, at least `CYLBadgeRowHeight`. [CN] 行高随文字变化，至少为 `CYLBadgeRowHeight`。
 */
fun cyl_setUpAutomaticRowHeightForTableView(listView: AbsListView) {
    val minimum = (CYLBadgeRowHeight * listView.resources.displayMetrics.density).toInt()
    listView.setRecyclerListener { it.minimumHeight = minimum }
    listView.setOnHierarchyChangeListener(object : ViewGroup.OnHierarchyChangeListener {
        override fun onChildViewAdded(parent: View?, child: View?) { child?.minimumHeight = minimum }
        override fun onChildViewRemoved(parent: View?, child: View?) { /* [EN] Nothing to undo. [CN] 无需处理。 */ }
    })
}

// MARK: - UIViewController (CYLNavigationBadge)

/**
 * [EN] `-cylShowNavigationBadgeValue:animationType:backgroundColor:`: shows `value` ("" a red dot) on the last action item of
 *      the activity's toolbar; without one, a bell item (no action) is added first. Returns the item, or null without a toolbar.
 * [CN] 在 Activity 工具栏的最后一个菜单项上显示 `value`（"" 为红点）；没有时先添加一个铃铛菜单项（无动作）。返回该菜单项；没有工具栏时为 null。
 */
fun Fragment.cylShowNavigationBadgeValue(value: String, animationType: CYLEnums.CYLBadgeAnimationType, @ColorInt backgroundColor: Int?): MenuItem? {
    val root = activity?.window?.decorView ?: return null
    val toolbar = findToolbar(root) ?: return null
    val menu = toolbar.menu
    val item = (0 until menu.size()).map { menu.getItem(it) }.lastOrNull { it.isVisible }
        ?: menu.add(android.view.Menu.NONE, View.generateViewId(), android.view.Menu.NONE, "Badge").apply {
            setIcon(android.R.drawable.ic_popup_reminder)
            setShowAsAction(MenuItem.SHOW_AS_ACTION_IF_ROOM)
        }
    item.cylShowBadgeValue(value, animationType, backgroundColor)
    return item
}

private fun findToolbar(view: View): androidx.appcompat.widget.Toolbar? {
    if (view is androidx.appcompat.widget.Toolbar) return view
    val group = view as? ViewGroup ?: return null
    for (index in 0 until group.childCount) findToolbar(group.getChildAt(index))?.let { return it }
    return null
}

// MARK: - CYLBadgeHelperTableViewController

/**
 * [EN] `CYLBadgeHelperTableViewController`: a list of every badge sample, one per row, after a memory warning row. Tap a
 *      sample to clear its badge; the tap also simulates a memory warning and logs the tab bar's state.
 * [CN] 列出每个角标示例（每行一个），前面是内存警告行。点击示例清除其角标，同时模拟内存警告并输出 TabBar 的状态。
 */
open class CYLBadgeHelperTableViewController : Fragment() {
    /**
     * [EN] Called after a row is tapped: section 0 the settings row, section 1 the samples. [CN] 点击行之后调用：section 0 为设置行，section 1 为示例。
     */
    var didSelectRowHandler: ((section: Int, row: Int) -> Unit)? = null

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val list = ListView(context)
        cyl_setUpAutomaticRowHeightForTableView(list)
        list.adapter = object : BaseAdapter() {
            override fun getCount() = 1 + cylBadgeStyleCount()
            override fun getItem(position: Int): Any = position
            override fun getItemId(position: Int) = position.toLong()
            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                if (position == 0) return cyl_memoryWarningCellForTableView(parent)
                val row = (convertView?.takeIf { it.tag == "badge" } as? LinearLayout) ?: badgeRow(context)
                (row.getChildAt(0) as ImageView).cylShowBadgeForRow(position - 1)
                (row.getChildAt(1) as TextView).text = cylBadgeTitleForRow(position - 1)
                return row
            }
        }
        list.setOnItemClickListener { _, row, position, _ ->
            if (position == 0) {
                cyl_simulateMemoryWarningAndShowResult()
                didSelectRowHandler?.invoke(0, 0)
                return@setOnItemClickListener
            }
            ((row as? LinearLayout)?.getChildAt(0))?.cylClearBadge()
            CYLTabBarController.cyl_simulateMemoryWarning()
            didSelectRowHandler?.invoke(1, position - 1)
        }
        return list
    }

    private fun badgeRow(context: Context): LinearLayout {
        val density = context.resources.displayMetrics.density
        return LinearLayout(context).apply {
            tag = "badge"
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            clipChildren = false
            setPadding((16 * density).toInt(), 0, (16 * density).toInt(), 0)
            addView(ImageView(context), LinearLayout.LayoutParams((30 * density).toInt(), (30 * density).toInt()).apply { marginEnd = (16 * density).toInt() })
            addView(TextView(context).apply { textSize = 15f }, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
            cyl_wrapsTextLabels()
        }
    }
}

/**
 * [EN] `-cylAddBadgeHelperTable`: adds a `CYLBadgeHelperTableViewController` as a child filling this page's view. [CN] 添加填满本页面视图的 `CYLBadgeHelperTableViewController` 子页面。
 */
fun Fragment.cylAddBadgeHelperTable(): CYLBadgeHelperTableViewController {
    val table = CYLBadgeHelperTableViewController()
    cyl_addChildViewController(table)
    return table
}

// MARK: - UIViewController (CYLMemoryWarning)

/**
 * [EN] `-cyl_memoryWarningCellForTableView:`: the row of the memory warning check. [CN] 内存警告检查的行。
 */
fun Fragment.cyl_memoryWarningCellForTableView(parent: ViewGroup): View {
    val context = parent.context
    val density = context.resources.displayMetrics.density
    return LinearLayout(context).apply {
        orientation = LinearLayout.VERTICAL
        setPadding((16 * density).toInt(), (10 * density).toInt(), (16 * density).toInt(), (10 * density).toInt())
        addView(TextView(context).apply { text = CYLLocalization.string(context, R.string.cyl_memory_warning_title); textSize = 15f; setTypeface(typeface, Typeface.BOLD) })
        addView(TextView(context).apply { text = CYLLocalization.string(context, R.string.cyl_memory_warning_detail); setTextColor(Color.GRAY) })
    }
}

/**
 * [EN] `-cyl_simulateMemoryWarningAndShowResult`: simulates a memory warning for this page's tab bar controller, then shows
 *      an alert that lists, for each tab, whether its view was unloaded and why not.
 * [CN] 为本页面所在的 TabBarController 模拟内存警告，然后弹窗列出每个 Tab 的视图是否被卸载以及未卸载的原因。
 */
fun Fragment.cyl_simulateMemoryWarningAndShowResult() {
    val context = context ?: return
    val controller = cyl_owningTabBarController() ?: cyl_tabBarController ?: CYLTabBarController.cyl_activeTabBarController()
    val message = CYLSimulateMemoryWarningReport(context, controller)
    AlertDialog.Builder(context).setTitle(CYLLocalization.string(context, R.string.cyl_memory_warning_alert_title)).setMessage(message)
        .setPositiveButton(android.R.string.ok, null).show()
}

/**
 * [EN] The tab's title, or `fallback` without a tab item. [CN] Tab 的标题；没有 Tab 项时为 `fallback`。
 */
private fun CYLMemoryWarningTabTitle(item: CYLTabBarItem?, selected: Boolean, fallback: String): String {
    if (item == null) return fallback
    val selectedTitle = if (selected) item.cyl_selectedTitle else null
    return selectedTitle ?: item.title ?: fallback
}

/**
 * [EN] `CYLSimulateMemoryWarningReport()`: simulates a memory warning for `controller` and returns what happened to each tab,
 *      one line per tab, in [CYLLocalization.language]: the message of `cyl_simulateMemoryWarningAndShowResult`, for any UI
 *      (e.g. `CYLTabBarHostView`).
 * [CN] 对 `controller` 模拟内存警告，并返回每个 Tab 的结果（每个 Tab 一行），使用 [CYLLocalization.language]：即
 *      `cyl_simulateMemoryWarningAndShowResult` 弹窗的内容，可用于任何界面（例如 `CYLTabBarHostView`）。
 */
fun CYLSimulateMemoryWarningReport(context: Context, controller: CYLTabBarController?): String {
    val pages = controller?.viewControllers.orEmpty()
    val wasLoaded = pages.map { it.view != null }
    CYLTabBarController.cyl_simulateMemoryWarningForTabBarController(controller)
    val text = { id: Int -> CYLLocalization.string(context, id) }
    val lines = ArrayList<String>()
    when {
        controller == null -> lines += text(R.string.cyl_memory_warning_no_controller)
        !controller.unloadsUnselectedViewsOnMemoryWarning -> lines += text(R.string.cyl_memory_warning_disabled)
    }
    val items = controller?.tabBarItems.orEmpty()
    val selectedIndex = controller?.selectedIndex
    pages.forEachIndexed { index, page ->
        // [EN] The title the tab shows, as iOS `tabBarItem.title`: the selected title on the selected tab. [CN] Tab 显示的标题，与 iOS 相同：选中的 Tab 显示选中标题。
        val title = CYLMemoryWarningTabTitle(items.getOrNull(index), index == selectedIndex, page.javaClass.simpleName)
        val status = when {
            !wasLoaded[index] -> R.string.cyl_memory_warning_not_loaded
            page.view == null -> R.string.cyl_memory_warning_unloaded
            index == selectedIndex -> R.string.cyl_memory_warning_kept_selected
            controller?.unloadsUnselectedViewsOnMemoryWarning == true && !controller.shouldUnloadViewOfViewController(page) -> R.string.cyl_memory_warning_kept_should_unload
            else -> R.string.cyl_memory_warning_kept
        }
        lines += "$title: ${text(status)}"
    }
    return lines.joinToString("\n")
}

// MARK: - Base view controllers 基类

/**
 * [EN] `CYLBaseViewController`: a base page. [CN] 页面基类。
 */
open class CYLBaseViewController : Fragment()

/**
 * [EN] `CYLBaseTableViewController`: a base page whose view is a list (`listView`). [CN] 视图为列表（`listView`）的页面基类。
 */
open class CYLBaseTableViewController : Fragment() {
    var listView: ListView? = null
        private set

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View =
        ListView(inflater.context).also { listView = it }

    override fun onDestroyView() {
        listView = null
        super.onDestroyView()
    }
}

/**
 * [EN] `CYLBaseNavigationController`: a navigation stack in a tab (child fragments on a back stack, the first is
 *      `rootViewController`); the tab bar hides while a page is pushed over the root and shows again at the root, as
 *      `cyl_hidesBottomBarWhenPushed` does on iOS.
 * [CN] Tab 中的导航栈（子 Fragment 在返回栈中，第一个是 `rootViewController`）；在根页面之上 push 页面时隐藏 TabBar，回到根页面时显示，
 *      与 iOS 的 `cyl_hidesBottomBarWhenPushed` 一致。
 */
open class CYLBaseNavigationController() : Fragment() {
    private var root: Fragment? = null
    private val containerId = View.generateViewId()

    constructor(rootViewController: Fragment) : this() { root = rootViewController }

    /**
     * [EN] The pages of the stack, root first. [CN] 栈中的页面，根页面在前。
     */
    val viewControllers: List<Fragment> get() = childFragmentManager.fragments.filter { it.id == containerId }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View =
        FrameLayout(inflater.context).apply { id = containerId }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val first = root
        if (first != null && childFragmentManager.fragments.isEmpty()) childFragmentManager.beginTransaction().add(containerId, first).commitNow()
        childFragmentManager.addOnBackStackChangedListener { toggleTabBarHidden() }
    }

    /**
     * [EN] `-pushViewController:animated:`. [CN] push 页面。
     */
    open fun pushViewController(viewController: Fragment, animated: Boolean) {
        childFragmentManager.beginTransaction().apply {
            if (animated) setTransition(androidx.fragment.app.FragmentTransaction.TRANSIT_FRAGMENT_OPEN)
            viewControllers.lastOrNull()?.let { hide(it) }
            add(containerId, viewController)
            addToBackStack(null)
        }.commit()
    }

    /**
     * [EN] `-popViewControllerAnimated:`. [CN] 弹出页面。
     */
    open fun popViewControllerAnimated(animated: Boolean) { childFragmentManager.popBackStack() }

    /**
     * [EN] `-popToRootViewControllerAnimated:`. [CN] 回到根页面。
     */
    open fun popToRootViewControllerAnimated(animated: Boolean) {
        if (childFragmentManager.backStackEntryCount > 0) childFragmentManager.popBackStack(childFragmentManager.getBackStackEntryAt(0).id, androidx.fragment.app.FragmentManager.POP_BACK_STACK_INCLUSIVE)
    }

    private fun toggleTabBarHidden() {
        val hidden = childFragmentManager.backStackEntryCount > 0
        cyl_tabBarController?.setTabBarHidden(hidden, true)
    }
}

// MARK: - Deprecated badge points (UIViewController / UIControl (CYLTabBarControllerExtentionDeprecated)) 已废弃的角标点

/**
 * [EN] `-cylShowTabBadgePoint` (deprecated): use `cylShowBadge`. [CN] 已废弃，请使用 `cylShowBadge`。
 */
@Deprecated("Use cylShowBadge", ReplaceWith("cylShowBadge()"))
fun View.cylShowTabBadgePoint() = cylShowBadge()
/**
 * [EN] `-cylRemoveTabBadgePoint` (deprecated): use `cylClearBadge`. [CN] 已废弃，请使用 `cylClearBadge`。
 */
@Deprecated("Use cylClearBadge", ReplaceWith("cylClearBadge()"))
fun View.cylRemoveTabBadgePoint() = cylClearBadge()
/**
 * [EN] `-cylIsShowTabBadgePoint` (deprecated): use `cylIsShowBadge`. [CN] 已废弃，请使用 `cylIsShowBadge`。
 */
@Deprecated("Use cylIsShowBadge", ReplaceWith("cylIsShowBadge()"))
fun View.cylIsShowTabBadgePoint(): Boolean = cylIsShowBadge()
/**
 * [EN] `cylTabBadgePointView` (deprecated): the badge view. [CN] 已废弃：角标视图。
 */
@Deprecated("Use cylBadge", ReplaceWith("cylBadge"))
val View.cylTabBadgePointView: View? get() = cylBadge
/**
 * [EN] `cylTabBadgePointViewOffset` (deprecated): `cylBadgeCenterOffset`. [CN] 已废弃：即 `cylBadgeCenterOffset`。
 */
@Deprecated("Use cylBadgeCenterOffset", ReplaceWith("cylBadgeCenterOffset"))
var View.cylTabBadgePointViewOffset: CYLOffset
    get() = cylBadgeCenterOffset
    set(value) { cylBadgeCenterOffset = value }

/**
 * [EN] The page's tab button versions. [CN] 页面 Tab 按钮上的版本。
 */
@Deprecated("Use cylShowBadge", ReplaceWith("cylShowBadge()"))
fun Fragment.cylShowTabBadgePoint() = cylShowBadge()
@Deprecated("Use cylClearBadge", ReplaceWith("cylClearBadge()"))
fun Fragment.cylRemoveTabBadgePoint() = cylClearBadge()
@Deprecated("Use cylIsShowBadge", ReplaceWith("cylIsShowBadge()"))
fun Fragment.cylIsShowTabBadgePoint(): Boolean = cylIsShowBadge()
@Deprecated("Use the tab button's cylBadge")
val Fragment.cylTabBadgePointView: View? get() = cyl_tabButton?.cylBadge
@Deprecated("Use the tab button's cylBadgeCenterOffset")
var Fragment.cylTabBadgePointViewOffset: CYLOffset
    get() = cyl_tabButton?.cylBadgeCenterOffset ?: CYLOffset.zero
    set(value) { cyl_tabButton?.cylBadgeCenterOffset = value }
