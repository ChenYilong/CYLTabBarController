// [EN] The method names are the iOS names on purpose (`cyl_…`, `tabBarController_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`、`tabBarController_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.graphics.Typeface
import android.graphics.drawable.Drawable
import androidx.annotation.ColorInt
import androidx.fragment.app.Fragment

/**
 * [EN] One tab's item: the Android `UITabBarItem` plus the `UITabBarItem (CYLTabBarControllerExtention)` properties.
 *      The attributes dictionary (`CYLTabBarItemTitle`...) is kept as given, so page IDs, platforms and the other
 *      configuration keys stay readable.
 * [CN] 一个 Tab 的 item：Android 版 `UITabBarItem`，加上 `UITabBarItem (CYLTabBarControllerExtention)` 的属性。属性字典
 *      （`CYLTabBarItemTitle` 等）原样保留，页面 ID、平台等配置键仍可读取。
 */
class CYLTabBarItem(attributes: Map<String, Any?> = emptyMap()) {

    /** [EN] The attributes the item was created from. [CN] 创建该 item 的属性。 */
    var attributes: Map<String, Any?> = attributes
        internal set

    var title: String? = attributes[CYLConstants.CYLTabBarItemTitle] as? String
    var image: Drawable? = null
    var selectedImage: Drawable? = null
    /** [EN] `UITabBarItem.badgeValue`; nil hides the badge. [CN] 角标文字；nil 隐藏角标。 */
    var badgeValue: String? = null
    var accessibilityIdentifier: String? = attributes[CYLConstants.CYLTabBarItemAccessibilityIdentifier] as? String
    var accessibilityLabel: String? = attributes[CYLConstants.CYLTabBarItemAccessibilityLabel] as? String
    var accessibilityHint: String? = attributes[CYLConstants.CYLTabBarItemAccessibilityHint] as? String

    // MARK: - UITabBarItem (CYLTabBarControllerExtention)

    /** [EN] `CYLTabBarItemIdentifier`, see `CYLTabBarController (CYLTabBarItemIdentifier)`. [CN] Tab 标识。 */
    var cyl_tabBarItemIdentifier: String? = attributes[CYLConstants.CYLTabBarItemIdentifier] as? String
    /** [EN] `CYLTabBarItemSelectedTitle` (#433): the title shown while selected. [CN] 选中时显示的标题（#433）。 */
    var cyl_selectedTitle: String? = attributes[CYLConstants.CYLTabBarItemSelectedTitle] as? String
    /** [EN] The tab's animation file URL (Lottie, PAG, Rive...) and view size. [CN] 该 Tab 的动画文件 URL 与视图尺寸。 */
    var cyl_tabBarItemAnimationURL: String? = null
    var cyl_tabBarItemAnimationSizeValue: CYLSize? = null
    /** [EN] `cyl_imagePositionAdjustment`: moves the icon. [CN] 图标偏移。 */
    var cyl_imagePositionAdjustment: CYLOffset = CYLOffset.zero
    var cyl_titlePositionAdjustment: CYLOffset = CYLOffset.zero
    var cyl_imageInsets: CYLEdgeInsets = CYLEdgeInsets.zero
    /** [EN] An icon size (dp) set by `setTabBarItemIcon:selectedIcon:size:atIndex:` / `CYLTabBarItemImageURLSize`; null: the placeholder size. [CN] 由图标接口或 `CYLTabBarItemImageURLSize` 设置的图标尺寸（dp）；null 为占位尺寸。 */
    var cyl_iconSize: CYLSize? = null
    /** [EN] `cyl_doubleTapBlock`: called with the item and its index on a double tap (#535). [CN] 双击回调（#535）。 */
    var cyl_doubleTapBlock: ((CYLTabBarItem, Int) -> Unit)? = null
    /** [EN] `cyl_viewDidLayoutSubviewsBlock`: called after the tab bar laid the tab's button out. [CN] 该 Tab 按钮布局完成后的回调。 */
    var cyl_viewDidLayoutSubviewsBlock: ((CYLTabBar, CYLTabBarItem, Int) -> Unit)? = null

    // MARK: - Per-item styles (CYLTabBarItemTitleColor..., #758)

    @ColorInt var cyl_titleColor: Int? = null
    @ColorInt var cyl_selectedTitleColor: Int? = null
    @ColorInt var cyl_iconColor: Int? = null
    @ColorInt var cyl_selectedIconColor: Int? = null
    @ColorInt var cyl_backgroundColor: Int? = null
    @ColorInt var cyl_selectedBackgroundColor: Int? = null
    var cyl_titleFont: CYLFont? = null
    var cyl_selectedTitleFont: CYLFont? = null

    /** [EN] The tab's button once the tab bar built it (`cyl_visiableTabButton`). [CN] TabBar 创建后该 Tab 的按钮。 */
    var cyl_visiableTabButton: CYLTabBarItemButton? = null
        internal set
    val cyl_selectedTabButton: CYLTabBarItemButton?
        get() = cyl_visiableTabButton?.takeIf { it.isSelected }

    /** [EN] `-cyl_imageView`: the icon view of the tab's button. [CN] Tab 按钮的图标视图。 */
    fun cyl_imageView() = cyl_visiableTabButton?.iconView
    fun cyl_imageViewInTabBarButton() = cyl_imageView()

    /** [EN] The display name for logs and alerts: the title, else the identifier. [CN] 用于日志与提示的名称：标题，否则标识。 */
    val cyl_tabBarItemDisplayName: String
        get() = title ?: cyl_tabBarItemIdentifier ?: ""

    override fun toString(): String = "CYLTabBarItem(title=$title, identifier=$cyl_tabBarItemIdentifier)"
}

/** [EN] CGSize. [CN] 尺寸。 */
data class CYLSize(val width: Float, val height: Float) {
    companion object {
        @JvmField val zero = CYLSize(0f, 0f)
    }
}

/** [EN] UIOffset. [CN] 偏移。 */
data class CYLOffset(val horizontal: Float, val vertical: Float) {
    companion object {
        @JvmField val zero = CYLOffset(0f, 0f)
    }
}

/** [EN] UIEdgeInsets. [CN] 边距。 */
data class CYLEdgeInsets(val top: Float, val left: Float, val bottom: Float, val right: Float) {
    companion object {
        @JvmField val zero = CYLEdgeInsets(0f, 0f, 0f, 0f)
    }
}

/** [EN] UIFont: a size in sp and an optional typeface. [CN] 字体：字号（sp）与可选的 Typeface。 */
data class CYLFont(val size: Float, val typeface: Typeface? = null, val bold: Boolean = false) {
    companion object {
        /** [EN] "15", "bold:15" or "Family-Style:12" as in a configuration file. [CN] 配置文件中的写法。 */
        @JvmStatic
        fun fromConfigurationValue(value: Any?): CYLFont? {
            val text = when (value) {
                is Number -> return CYLFont(value.toFloat()).takeIf { value.toFloat() > 0 }
                is String -> value.trim()
                else -> return null
            }
            val parts = text.split(':')
            val size = parts.last().toFloatOrNull() ?: return null
            if (size <= 0 || size > 200) return null
            if (parts.size == 1) return CYLFont(size)
            val name = parts[0].trim()
            val weights = listOf("ultralight", "thin", "light", "regular", "medium", "semibold", "bold", "heavy", "black")
            return if (name.lowercase() in weights) {
                CYLFont(size, bold = name.lowercase() in listOf("semibold", "bold", "heavy", "black"))
            } else {
                CYLFont(size, Typeface.create(name.substringBefore('-'), if (name.contains("Bold", true)) Typeface.BOLD else Typeface.NORMAL))
            }
        }
    }
}

/** [EN] The page of a tab: a Fragment (the iOS `UIViewController`). [CN] Tab 的页面：Fragment（对应 iOS 的 `UIViewController`）。 */
typealias CYLViewController = Fragment
