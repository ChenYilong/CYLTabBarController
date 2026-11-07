// [EN] The method names are the iOS names on purpose (`cyl_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.content.res.ColorStateList
import android.content.res.Configuration
import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.ColorDrawable
import android.graphics.drawable.Drawable
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.fragment.app.Fragment
import java.util.WeakHashMap

/*
 * [EN] Themes beyond the tab bar (issue #216): the managers by name (`CYLThemeManagerCenter`), theme colors, images and
 *      effects that ask a provider for the current theme, and how views (and the layer-like view colors) and pages follow
 *      a theme change. No framework method is hooked: when a manager's theme changes, the views of the live tab bar
 *      controllers' windows and their pages are told, as on iOS.
 * [CN] TabBar 以外的主题（issue #216）：按名称管理的主题管理器（`CYLThemeManagerCenter`）、向 provider 询问当前主题的主题颜色、图片与效果，
 *      以及视图（及类似图层的视图颜色）与页面如何跟随主题变化。不 hook 任何框架方法：管理器的主题变化时，通知存活 TabBarController 窗口中的视图
 *      及其页面，与 iOS 一致。
 */

/** [EN] `CYLThemeManagerNameDefault`: the name of `CYLThemeManagerCenter.defaultThemeManager`. [CN] 默认主题管理器的名称。 */
const val CYLThemeManagerNameDefault: String = CYLThemeManager.CYLThemeManagerNameDefault

/** [EN] `CYLThemeManagerCenter`: hands out the theme managers, one per name. [CN] 按名称提供主题管理器，每个名称一个。 */
object CYLThemeManagerCenter {
    private val managers = LinkedHashMap<Any, CYLThemeManager>()

    internal fun register(manager: CYLThemeManager) {
        synchronized(managers) { if (!managers.containsKey(manager.name)) managers[manager.name] = manager }
    }

    /** [EN] The manager named `CYLThemeManagerNameDefault`. [CN] 名为 `CYLThemeManagerNameDefault` 的管理器。 */
    @JvmStatic
    val defaultThemeManager: CYLThemeManager get() = CYLThemeManager.defaultManager

    /** [EN] Every manager created so far. [CN] 目前创建的所有管理器。 */
    @JvmStatic
    val themeManagers: List<CYLThemeManager> get() {
        defaultThemeManager
        return synchronized(managers) { managers.values.toList() }
    }

    /** [EN] The manager named `name`, created on first use. [CN] 名为 `name` 的管理器，首次使用时创建。 */
    @JvmStatic
    fun themeManagerWithName(name: Any): CYLThemeManager {
        if (name == CYLThemeManagerNameDefault) return defaultThemeManager
        synchronized(managers) { managers[name.toString()]?.let { return it } }
        return CYLThemeManager(name.toString())
    }

    /**
     * [EN] `+updateThemesForTraitCollection:`: `updateThemeForTraitCollection` for every manager; when no theme switches,
     *      the view colors set with `cyl_setThemeColor` are resolved again for the new appearance.
     * [CN] 对每个管理器调用 `updateThemeForTraitCollection`；没有主题切换时，用 `cyl_setThemeColor` 设置的视图颜色按新外观重新解析。
     */
    @JvmStatic
    fun updateThemesForTraitCollection(configuration: Configuration) {
        val before = themeManagers.map { it.currentThemeIdentifier }
        themeManagers.forEach { it.updateThemeForTraitCollection(configuration) }
        if (themeManagers.map { it.currentThemeIdentifier } == before) {
            for (controller in CYLTabBarController.cyl_liveTabBarControllers()) controller.activity.window?.decorView?.cyl_updateThemeColors()
        }
    }
}

/** [EN] `CYLThemeColorProvider`: the color (ARGB) for the current theme of `manager`. [CN] `manager` 当前主题下的颜色（ARGB）。 */
typealias CYLThemeColorProvider = (manager: CYLThemeManager, identifier: Any?, theme: Any?) -> Int
/** [EN] `CYLThemeImageProvider`: the image for the current theme of `manager`. [CN] `manager` 当前主题下的图片。 */
typealias CYLThemeImageProvider = (manager: CYLThemeManager, identifier: Any?, theme: Any?) -> Drawable?
/** [EN] `CYLThemeEffectProvider`: the effect (a `RenderEffect` on Android 12+) for the current theme of `manager`. [CN] `manager` 当前主题下的效果（Android 12+ 为 `RenderEffect`）。 */
typealias CYLThemeEffectProvider = (manager: CYLThemeManager, identifier: Any?, theme: Any?) -> Any?

/**
 * [EN] `UIColor (CYLTheme)`: a color that follows the theme of a manager. `cyl_rawColor` asks the provider each time; a
 *      view color set with `View.cyl_setThemeColor` follows theme changes.
 * [CN] 跟随管理器主题的颜色。`cyl_rawColor` 每次都询问 provider；用 `View.cyl_setThemeColor` 设置的视图颜色会跟随主题变化。
 */
class CYLThemeColor private constructor(private val managerName: Any, val cyl_themeColorName: String?, private val provider: CYLThemeColorProvider) {
    /** [EN] true for a color created by the factory methods. [CN] 由工厂方法创建的颜色为 true。 */
    val cyl_isThemeColor: Boolean get() = true

    /** [EN] The value in the current theme. [CN] 当前主题下的值。 */
    val cyl_rawColor: Int
        get() {
            val manager = CYLThemeManagerCenter.themeManagerWithName(managerName)
            return provider(manager, manager.currentThemeIdentifier, manager.currentTheme)
        }

    /** [EN] A `ColorStateList` of the current value. [CN] 当前值的 `ColorStateList`。 */
    fun toColorStateList(): ColorStateList = ColorStateList.valueOf(cyl_rawColor)

    override fun toString(): String = "CYLThemeColor(${cyl_themeColorName ?: ""})"

    companion object {
        @JvmStatic fun cyl_colorWithThemeProvider(provider: CYLThemeColorProvider) = CYLThemeColor(CYLThemeManagerNameDefault, null, provider)
        @JvmStatic fun cyl_colorWithName(name: String?, themeProvider: CYLThemeColorProvider) = CYLThemeColor(CYLThemeManagerNameDefault, name, themeProvider)
        @JvmStatic fun cyl_colorWithThemeManagerName(managerName: Any, provider: CYLThemeColorProvider) = CYLThemeColor(managerName, null, provider)
        @JvmStatic fun cyl_colorWithName(name: String?, themeManagerName: Any, provider: CYLThemeColorProvider) = CYLThemeColor(themeManagerName, name, provider)
    }
}

/**
 * [EN] `UIImage (CYLTheme)`: a drawable that draws the provider's image for the current theme and switches when the theme
 *      changes, wherever it is set (an image view, a background, a compound drawable). A provider that returns null
 *      draws nothing.
 * [CN] 绘制 provider 为当前主题返回的图片，主题变化时切换，无论设置在哪里（图片视图、背景、复合图片）。provider 返回 null 时不绘制。
 */
class CYLThemeImage private constructor(private val managerName: Any, val cyl_themeImageName: String?, private val provider: CYLThemeImageProvider) : Drawable(), Drawable.Callback {
    private var current: Drawable? = null
    private var currentKey: Any? = Unit

    init {
        cyl_refresh()
    }

    /** [EN] true for an image created by the factory methods. [CN] 由工厂方法创建的图片为 true。 */
    val cyl_isThemeImage: Boolean get() = true

    /** [EN] The provider's image for the current theme (not a theme image). [CN] provider 为当前主题返回的图片（非主题图片）。 */
    val cyl_rawImage: Drawable? get() { cyl_refresh(); return current }

    /** [EN] Asks the provider again when the theme changed. [CN] 主题变化时重新询问 provider。 */
    internal fun cyl_refresh(): Boolean {
        val manager = CYLThemeManagerCenter.themeManagerWithName(managerName)
        val key = manager.currentThemeIdentifier
        if (key == currentKey && current != null) return false
        currentKey = key
        current?.callback = null
        current = provider(manager, key, manager.currentTheme)?.mutate()
        current?.callback = this
        current?.bounds = bounds
        invalidateSelf()
        return true
    }

    override fun draw(canvas: Canvas) { current?.draw(canvas) }
    override fun onBoundsChange(bounds: Rect) { current?.bounds = bounds }
    override fun getIntrinsicWidth(): Int = current?.intrinsicWidth ?: 1
    override fun getIntrinsicHeight(): Int = current?.intrinsicHeight ?: 1
    override fun setAlpha(alpha: Int) { current?.alpha = alpha }
    override fun setColorFilter(colorFilter: ColorFilter?) { current?.colorFilter = colorFilter }
    @Deprecated("Deprecated in Java")
    override fun getOpacity(): Int = PixelFormat.TRANSLUCENT
    override fun invalidateDrawable(who: Drawable) = invalidateSelf()
    override fun scheduleDrawable(who: Drawable, what: Runnable, `when`: Long) = scheduleSelf(what, `when`)
    override fun unscheduleDrawable(who: Drawable, what: Runnable) = unscheduleSelf(what)

    companion object {
        @JvmStatic fun cyl_imageWithThemeProvider(provider: CYLThemeImageProvider) = CYLThemeImage(CYLThemeManagerNameDefault, null, provider)
        @JvmStatic fun cyl_imageWithName(name: String?, themeProvider: CYLThemeImageProvider) = CYLThemeImage(CYLThemeManagerNameDefault, name, themeProvider)
        @JvmStatic fun cyl_imageWithThemeManagerName(managerName: Any, provider: CYLThemeImageProvider) = CYLThemeImage(managerName, null, provider)
        @JvmStatic fun cyl_imageWithName(name: String?, themeManagerName: Any, provider: CYLThemeImageProvider) = CYLThemeImage(themeManagerName, name, provider)
    }
}

/**
 * [EN] `UIVisualEffect (CYLTheme)`: an effect that follows the theme of a manager; on Android 12+ a `RenderEffect` (blur)
 *      set with `View.cyl_setThemeEffect` is replaced when the theme changes. A provider that returns null clears it.
 * [CN] 跟随管理器主题的效果；Android 12+ 上用 `View.cyl_setThemeEffect` 设置的 `RenderEffect`（模糊）在主题变化时替换。provider 返回 null 时清除。
 */
class CYLThemeEffect private constructor(private val managerName: Any, private val provider: CYLThemeEffectProvider) {
    /** [EN] true for an effect created by the factory methods. [CN] 由工厂方法创建的效果为 true。 */
    val cyl_isThemeEffect: Boolean get() = true

    /** [EN] The provider's effect for the current theme. [CN] provider 为当前主题返回的效果。 */
    val cyl_rawEffect: Any?
        get() {
            val manager = CYLThemeManagerCenter.themeManagerWithName(managerName)
            return provider(manager, manager.currentThemeIdentifier, manager.currentTheme)
        }

    companion object {
        @JvmStatic fun cyl_effectWithThemeProvider(provider: CYLThemeEffectProvider) = CYLThemeEffect(CYLThemeManagerNameDefault, provider)
        @JvmStatic fun cyl_effectWithThemeManagerName(managerName: Any, provider: CYLThemeEffectProvider) = CYLThemeEffect(managerName, provider)
    }
}

// MARK: - Views 视图

/** [EN] A view or a page that wants to know about theme changes (the overridable `-cyl_themeDidChangeByManager:…`). [CN] 需要知道主题变化的视图或页面（可重写的 `-cyl_themeDidChangeByManager:…`）。 */
interface CYLThemeChangeObserving {
    fun cyl_themeDidChangeByManager(manager: CYLThemeManager?, identifier: Any?, theme: Any?)
}

private class CYLViewThemeState {
    val colors = LinkedHashMap<String, Any>()
    val properties = LinkedHashSet<String>()
    var block: (() -> Unit)? = null
    var effect: CYLThemeEffect? = null
}

private val viewThemeStates = WeakHashMap<View, CYLViewThemeState>()
private fun View.themeState(create: Boolean): CYLViewThemeState? = viewThemeStates[this] ?: if (create) CYLViewThemeState().also { viewThemeStates[this] = it } else null

private fun resolvedColor(color: Any?): Int? = when (color) {
    is CYLThemeColor -> color.cyl_rawColor
    is Int -> color
    else -> null
}

/** [EN] Sets the color property `key` of the view from `color`. [CN] 用 `color` 设置视图的颜色属性 `key`。 */
private fun View.applyColor(key: String, color: Int?) {
    val density = resources.displayMetrics.density
    when (key) {
        "backgroundColor" -> when (val background = background) {
            is GradientDrawable -> if (color == null) background.setColor(null as ColorStateList?) else background.setColor(color)
            else -> setBackgroundColor(color ?: android.graphics.Color.TRANSPARENT)
        }
        "borderColor" -> {
            val shape = (background as? GradientDrawable) ?: GradientDrawable().also { created ->
                (background as? ColorDrawable)?.let { created.setColor(it.color) }
                background = created
            }
            shape.setStroke(if (color == null) 0 else maxOf(1, density.toInt()), color ?: android.graphics.Color.TRANSPARENT)
        }
        "shadowColor" -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            outlineSpotShadowColor = color ?: android.graphics.Color.BLACK
            outlineAmbientShadowColor = color ?: android.graphics.Color.BLACK
        }
        "textColor" -> (this as? TextView)?.setTextColor(color ?: android.graphics.Color.BLACK)
        "tintColor" -> (this as? ImageView)?.imageTintList = color?.let { ColorStateList.valueOf(it) }
        else -> {
            val setter = "set" + key.replaceFirstChar { it.uppercase() }
            CYLReflection.call(this, setter, color ?: return)
        }
    }
}

/**
 * [EN] `-[CALayer cyl_setThemeColor:forKey:]` on a view (Android draws with views, not layers): sets the color property `key`
 *      (`backgroundColor`, `borderColor`, `shadowColor`, `textColor`, `tintColor`, or any `set<Key>(Int)`) from `color`
 *      (a `CYLThemeColor` or an ARGB Int), and keeps doing so when the theme changes. null clears it and stops following.
 * [CN] 在视图上实现的 `-[CALayer cyl_setThemeColor:forKey:]`（Android 用视图而不是图层绘制）：用 `color`（`CYLThemeColor` 或 ARGB 整数）设置颜色属性
 *      `key`（`backgroundColor`、`borderColor`、`shadowColor`、`textColor`、`tintColor` 或任意 `set<Key>(Int)`），主题变化时继续设置。null 清除并停止跟随。
 */
fun View.cyl_setThemeColor(color: Any?, key: String) {
    if (color == null) {
        themeState(false)?.colors?.remove(key)
        applyColor(key, null)
        return
    }
    themeState(true)!!.colors[key] = color
    applyColor(key, resolvedColor(color))
}

/** [EN] `-cyl_themeColorForKey:`: the color set for `key`, else null. [CN] 为 `key` 设置的颜色，没有时为 null。 */
fun View.cyl_themeColorForKey(key: String): Any? = themeState(false)?.colors?.get(key)

/** [EN] `-cyl_updateThemeColors`: sets the colors of `cyl_setThemeColor` again, for this view and its subviews. [CN] 为本视图及子视图重新设置 `cyl_setThemeColor` 的颜色。 */
fun View.cyl_updateThemeColors() {
    themeState(false)?.colors?.forEach { (key, color) -> applyColor(key, resolvedColor(color)) }
    (this as? ViewGroup)?.let { group -> for (index in 0 until group.childCount) group.getChildAt(index).cyl_updateThemeColors() }
}

/** [EN] `cyl_themeBackgroundColor` (`-cyl_setThemeColor:forKey:` with "backgroundColor"). [CN] 背景主题颜色。 */
var View.cyl_themeBackgroundColor: Any?
    get() = cyl_themeColorForKey("backgroundColor")
    set(value) = cyl_setThemeColor(value, "backgroundColor")
/** [EN] `cyl_themeBorderColor`: the stroke of the view's shape background. [CN] 视图形状背景的描边颜色。 */
var View.cyl_themeBorderColor: Any?
    get() = cyl_themeColorForKey("borderColor")
    set(value) = cyl_setThemeColor(value, "borderColor")
/** [EN] `cyl_themeShadowColor`: the outline shadow colors (Android 9+). [CN] 轮廓阴影颜色（Android 9+）。 */
var View.cyl_themeShadowColor: Any?
    get() = cyl_themeColorForKey("shadowColor")
    set(value) = cyl_setThemeColor(value, "shadowColor")

/** [EN] Sets a theme effect on the view (`RenderEffect`, Android 12+), replaced when the theme changes. [CN] 为视图设置主题效果（Android 12+ 的 `RenderEffect`），主题变化时替换。 */
fun View.cyl_setThemeEffect(effect: CYLThemeEffect?) {
    themeState(effect != null)?.effect = effect
    applyEffect(effect?.cyl_rawEffect)
}

private fun View.applyEffect(effect: Any?) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) setRenderEffect(effect as? android.graphics.RenderEffect)
}

/**
 * [EN] `-cyl_registerThemeColorProperties:`: properties to set again when the theme changes, by their getter names (e.g.
 *      "background", "textColors"): a theme image is refreshed, a theme color set with `cyl_setThemeColor` resolved again,
 *      any other object set again as is; plain colors and images are left alone.
 * [CN] 主题变化时重新设置的属性（按 getter 名称，例如 "background"、"textColors"）：主题图片刷新，用 `cyl_setThemeColor` 设置的主题颜色重新解析，
 *      其他对象原样再设置一次；普通颜色与图片保持不变。
 */
fun View.cyl_registerThemeColorProperties(getters: List<String>) { themeState(true)!!.properties += getters }

/** [EN] `-cyl_unregisterThemeColorProperties:`. [CN] 移除登记的属性。 */
fun View.cyl_unregisterThemeColorProperties(getters: List<String>) { themeState(false)?.properties?.removeAll(getters.toSet()) }

/** [EN] `cyl_themeDidChangeBlock`: runs at the end of `cyl_themeDidChangeByManager`. [CN] 在 `cyl_themeDidChangeByManager` 末尾运行。 */
var View.cyl_themeDidChangeBlock: (() -> Unit)?
    get() = themeState(false)?.block
    set(value) { themeState(value != null)?.block = value }

private fun View.refreshThemeImages() {
    fun refresh(drawable: Drawable?) { (drawable as? CYLThemeImage)?.cyl_refresh() }
    refresh(background)
    refresh(foreground)
    (this as? ImageView)?.let { refresh(it.drawable) }
    (this as? TextView)?.compoundDrawablesRelative?.forEach { refresh(it) }
}

private fun View.reapplyRegisteredProperties() {
    val state = themeState(false) ?: return
    for (getter in state.properties) {
        val key = getter.removePrefix("get").replaceFirstChar { it.lowercase() }
        val themeColor = state.colors[key]
        if (themeColor != null) {
            applyColor(key, resolvedColor(themeColor))
            continue
        }
        val value = CYLReflection.call(this, if (getter.startsWith("get") || getter.startsWith("is")) getter else "get" + getter.replaceFirstChar { it.uppercase() })
        when (value) {
            is CYLThemeImage -> value.cyl_refresh()
            is Drawable, is Int, Unit, null -> Unit
            else -> CYLReflection.call(this, "set" + key.replaceFirstChar { it.uppercase() }, value)
        }
    }
    state.effect?.let { applyEffect(it.cyl_rawEffect) }
}

/**
 * [EN] `-cyl_themeDidChangeByManager:identifier:theme:`: sets the registered properties and theme colors again, refreshes
 *      theme images, redraws, tells a `CYLThemeChangeObserving` view, runs `cyl_themeDidChangeBlock`, then does the same for
 *      every subview.
 * [CN] 重新设置登记的属性与主题颜色，刷新主题图片并重绘，通知实现了 `CYLThemeChangeObserving` 的视图，运行 `cyl_themeDidChangeBlock`，然后对每个子视图执行同样操作。
 */
fun View.cyl_themeDidChangeByManager(manager: CYLThemeManager?, identifier: Any?, theme: Any?) {
    themeState(false)?.colors?.forEach { (key, color) -> applyColor(key, resolvedColor(color)) }
    reapplyRegisteredProperties()
    refreshThemeImages()
    invalidate()
    (this as? CYLThemeChangeObserving)?.cyl_themeDidChangeByManager(manager, identifier, theme)
    themeState(false)?.block?.invoke()
    (this as? ViewGroup)?.let { group -> for (index in 0 until group.childCount) group.getChildAt(index).cyl_themeDidChangeByManager(manager, identifier, theme) }
}

/** [EN] `-cyl_applyCurrentTheme`: brings the view and its subviews to the current themes now. [CN] 立即让本视图及子视图使用当前主题。 */
fun View.cyl_applyCurrentTheme() = cyl_themeDidChangeByManager(null, null, null)

// MARK: - Pages 页面

/**
 * [EN] `-[UIViewController cyl_themeDidChangeByManager:identifier:theme:]`: tells the page (when it is a
 *      `CYLThemeChangeObserving`), its views when they exist (shown or not), then every child page.
 * [CN] 通知页面（实现了 `CYLThemeChangeObserving` 时）、页面已创建的视图（无论是否显示），然后通知每个子页面。
 */
fun Fragment.cyl_themeDidChangeByManager(manager: CYLThemeManager, identifier: Any?, theme: Any?) {
    (this as? CYLThemeChangeObserving)?.cyl_themeDidChangeByManager(manager, identifier, theme)
    if (isAdded) {
        view?.takeIf { it.parent == null || !it.isAttachedToWindow }?.cyl_themeDidChangeByManager(manager, identifier, theme)
        for (child in childFragmentManager.fragments) child.cyl_themeDidChangeByManager(manager, identifier, theme)
    }
}

/** [EN] Tells the windows and pages of the live tab bar controllers about a theme change. [CN] 把主题变化通知存活 TabBarController 的窗口与页面。 */
internal object CYLThemeDispatcher {
    fun dispatch(manager: CYLThemeManager, identifier: Any?, theme: Any?) {
        val activities = LinkedHashSet<androidx.fragment.app.FragmentActivity>()
        for (controller in CYLTabBarController.cyl_liveTabBarControllers()) activities += controller.activity
        for (activity in activities) {
            activity.window?.decorView?.cyl_themeDidChangeByManager(manager, identifier, theme)
            if (!activity.supportFragmentManager.isDestroyed) for (page in activity.supportFragmentManager.fragments) page.cyl_themeDidChangeByManager(manager, identifier, theme)
        }
    }
}
