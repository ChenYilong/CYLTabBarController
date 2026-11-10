// [EN] The method names are the iOS names on purpose (`cyl_…`, `tabBarController_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`、`tabBarController_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.content.Context
import android.content.res.Configuration
import java.util.concurrent.CopyOnWriteArrayList

/**
 * [EN] `CYLTabBarTheme` (issue #216): a skin of the tab bar. Every method optional; returning null keeps the current
 *      value.
 * [CN] `CYLTabBarTheme`（issue #216）：TabBar 的皮肤。每个方法可选；返回 null 保持当前值。
 */
interface CYLTabBarTheme {
    /** [EN] `-cyl_tabBarItemsAttributesForTabBarController:`: new attributes for every tab (title, icons, colors...). [CN] 每个 Tab 的新属性。 */
    fun cyl_tabBarItemsAttributesForTabBarController(tabBarController: CYLTabBarController): List<Map<String, Any?>>? = null

    /** [EN] `-cyl_plusButtonAttributesForTabBarController:`: title / image of the plus button. [CN] PlusButton 的标题 / 图片。 */
    fun cyl_plusButtonAttributesForTabBarController(tabBarController: CYLTabBarController): Map<String, Any?>? = null

    /** [EN] `-cyl_tabBarAppearanceForTabBarController:`: background, title and icon colors of the bar. [CN] TabBar 的背景、标题与图标颜色。 */
    fun cyl_tabBarAppearanceForTabBarController(tabBarController: CYLTabBarController): CYLTabBarAppearance? = null

    /** [EN] `-cyl_customizeTabBarController:`: anything else. [CN] 其他自定义。 */
    fun cyl_customizeTabBarController(tabBarController: CYLTabBarController) { /* [EN] Optional. [CN] 可选。 */ }
}

/**
 * [EN] `UITabBarAppearance`, the part the library sets. In the FlatDesign style, `backgroundColor` replaces the blur and
 *      `shadowColor` draws the top line.
 * [CN] TabBar 外观（库设置的部分）。扁平样式中，`backgroundColor` 代替模糊，`shadowColor` 绘制顶部线条。
 */
data class CYLTabBarAppearance(
    val backgroundColor: Int? = null,
    val shadowColor: Int? = null,
    val titleColor: Int? = null,
    val selectedTitleColor: Int? = null,
    val iconColor: Int? = null,
    val selectedIconColor: Int? = null,
    /** [EN] `stackedItemPositioning == .centered` (FlatDesign): items centered, `stackedItemWidth` wide (dp, 0: an equal share), `stackedItemSpacing` apart (dp). [CN] `stackedItemPositioning == .centered`（扁平样式）：item 居中，宽 `stackedItemWidth`（dp，0 表示平分），间距 `stackedItemSpacing`（dp）。 */
    val stackedItemPositioningCentered: Boolean = false,
    val stackedItemWidth: Float = 0f,
    val stackedItemSpacing: Float = 0f,
    /** [EN] `backgroundImage`: drawn behind the whole bar (the classic and FlatDesign styles). [CN] 绘制在整个 TabBar 后面（经典与扁平样式）。 */
    val backgroundImage: android.graphics.drawable.Drawable? = null,
    /** [EN] `shadowImage`: the line on top of the bar (the classic and FlatDesign styles). [CN] TabBar 顶部的线条（经典与扁平样式）。 */
    val shadowImage: android.graphics.drawable.Drawable? = null,
)

/**
 * [EN] `CYLThemeManager`: the registered themes, the current one, and the listeners (`CYLThemeDidChangeNotification`).
 *      `defaultManager` drives every tab bar controller; a manager you create is given to one with `cyl_themeManager`.
 * [CN] `CYLThemeManager`：已注册的主题、当前主题与监听者（`CYLThemeDidChangeNotification`）。`defaultManager` 驱动所有
 *      TabBarController；自己创建的管理器通过 `cyl_themeManager` 交给某一个。
 */
class CYLThemeManager(val name: String = CYLThemeManagerNameDefault) {

    init {
        CYLThemeManagerCenter.register(this)
    }

    fun interface Listener {
        fun cyl_themeDidChangeByManager(manager: CYLThemeManager, identifier: Any?, theme: Any?)
    }

    private val registered = LinkedHashMap<Any, Any>()
    private val listeners = CopyOnWriteArrayList<Listener>()

    /** [EN] `themeIdentifiers`, in registration order. [CN] 主题标识（按注册顺序）。 */
    val themeIdentifiers: List<Any> get() = synchronized(registered) { registered.keys.toList() }
    val themes: List<Any> get() = synchronized(registered) { registered.values.toList() }

    /** [EN] `currentThemeIdentifier`: setting it applies the theme and notifies. [CN] 当前主题标识：设置即应用并通知。 */
    var currentThemeIdentifier: Any? = null
        set(value) {
            val theme = value?.let { themeForIdentifier(it) }
            if (value != null && theme == null) return
            field = value
            themeVersion++
            persisted?.edit()?.putString(persistenceKey, value?.toString())?.apply()
            for (listener in listeners) listener.cyl_themeDidChangeByManager(this, value, theme)
            // [EN] Then every view and page of the live tab bar controllers' windows (UIView / UIViewController (CYLTheme)). [CN] 然后通知存活 TabBarController 窗口中的所有视图与页面。
            CYLThemeDispatcher.dispatch(this, value, theme)
        }
    /** [EN] Counts the theme changes; a view reached twice in one change is brought to it once. [CN] 主题变化次数；同一次变化中访问两次的视图只处理一次。 */
    internal var themeVersion: Int = 0
        private set
    val currentTheme: Any? get() = currentThemeIdentifier?.let { themeForIdentifier(it) }

    /** [EN] `persistsCurrentThemeIdentifier`: remembered across launches through `persistIn(context)`. [CN] 通过 `persistIn(context)` 跨启动记住当前主题。 */
    var persistsCurrentThemeIdentifier: Boolean = false
    /**
     * [EN] `themeChangeAnimationDuration`: when greater than 0, a theme change cross-fades over this many seconds, as on
     *      iOS: each window of the live tab bar controllers (and each registered root) is covered by a snapshot of itself,
     *      restyled underneath, and the snapshot fades out. Default 0 (no animation), as on iOS.
     * [CN] 大于 0 时，主题切换以该秒数交叉淡入淡出，与 iOS 一致：存活 TabBarController 的每个窗口（以及每个登记的根视图）先被自身截图覆盖，在其下更新样式，
     *      然后截图淡出。默认 0（无动画），与 iOS 一致。
     */
    var themeChangeAnimationDuration: Double = 0.0
    /** [EN] `themeGenerator`: makes a theme for an unknown identifier. [CN] 为未知标识生成主题。 */
    var themeGenerator: ((Any) -> Any?)? = null
    /** [EN] `themeIdentifierGenerator`: the identifier of a theme. [CN] 主题的标识。 */
    var themeIdentifierGenerator: ((Any) -> Any?)? = null
    /** [EN] `identifierForTrait`: the identifier to use in Dark Mode / light mode (`updateThemeForTraitCollection`). [CN] 深色 / 浅色模式对应的标识。 */
    var identifierForTrait: ((Boolean) -> Any?)? = null
    private var persisted: android.content.SharedPreferences? = null
    private val persistenceKey get() = "CYLThemeManager.$name.currentThemeIdentifier"

    fun addThemeIdentifier(identifier: Any, theme: Any) {
        synchronized(registered) { registered[identifier] = theme }
    }

    fun removeThemeIdentifier(identifier: Any) {
        synchronized(registered) { registered.remove(identifier) }
    }

    fun removeTheme(theme: Any) {
        synchronized(registered) { registered.entries.removeAll { it.value === theme } }
    }

    fun themeForIdentifier(identifier: Any): Any? =
        synchronized(registered) { registered[identifier] } ?: themeGenerator?.invoke(identifier)?.also { addThemeIdentifier(identifier, it) }

    fun identifierForTheme(theme: Any): Any? =
        synchronized(registered) { registered.entries.firstOrNull { it.value === theme }?.key } ?: themeIdentifierGenerator?.invoke(theme)

    /** [EN] `-updateThemeForTraitCollection:`: picks the identifier of the current interface style. [CN] 按当前界面样式选择主题。 */
    fun updateThemeForTraitCollection(configuration: Configuration) {
        val dark = (configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        identifierForTrait?.invoke(dark)?.let { currentThemeIdentifier = it }
    }

    /** [EN] Remembers the current identifier in SharedPreferences and restores it now. [CN] 用 SharedPreferences 记住当前标识，并立即恢复。 */
    fun persistIn(context: Context) {
        persisted = context.applicationContext.getSharedPreferences("CYLThemeManager", Context.MODE_PRIVATE)
        persistsCurrentThemeIdentifier = true
        val saved = persisted?.getString(persistenceKey, null) ?: return
        themeIdentifiers.firstOrNull { it.toString() == saved }?.let { currentThemeIdentifier = it }
    }

    fun addListener(listener: Listener) = listeners.addIfAbsent(listener)
    fun removeListener(listener: Listener) = listeners.remove(listener)

    companion object {
        const val CYLThemeManagerNameDefault = "CYLThemeManagerNameDefault"
        /** [EN] `+defaultManager`. [CN] 默认管理器。 */
        @JvmStatic val defaultManager = CYLThemeManager()
    }
}
