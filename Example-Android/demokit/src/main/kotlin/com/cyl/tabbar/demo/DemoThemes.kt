package com.cyl.tabbar.demo

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.drawable.Drawable
import androidx.core.content.ContextCompat
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLTabBarAppearance
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.CYLTabBarTheme
import com.cyl.tabbar.CYLThemeManager

/**
 * [EN] A tab icon drawn from an emoji, as the holiday skins of the iOS demo draw their icons from emoji names.
 * [CN] 由 emoji 绘制的 Tab 图标，对应 iOS 演示节日皮肤由 emoji 名称绘制的图标。
 */
class EmojiDrawable(private val emoji: String) : Drawable() {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { textAlign = Paint.Align.CENTER }

    override fun draw(canvas: Canvas) {
        val bounds = bounds
        paint.textSize = bounds.height() * 0.8f
        val baseline = bounds.exactCenterY() - (paint.descent() + paint.ascent()) / 2
        canvas.drawText(emoji, bounds.exactCenterX(), baseline, paint)
    }

    override fun setAlpha(alpha: Int) { paint.alpha = alpha }
    override fun setColorFilter(colorFilter: ColorFilter?) { /* [EN] Emoji keep their colors. [CN] emoji 保留自身颜色。 */ }
    @Deprecated("Deprecated in Java")
    override fun getOpacity() = PixelFormat.TRANSLUCENT
    override fun getIntrinsicWidth() = 96
    override fun getIntrinsicHeight() = 96
}

/**
 * [EN] One skin of the iOS demo's theme list (issue #216, `UIViewController+CYLThemeSettings`): a tint, a bar color, an
 *      unselected color, and for holiday skins one emoji icon per tab (the plus button gets the last one).
 * [CN] iOS 演示皮肤列表中的一个皮肤（issue #216，`UIViewController+CYLThemeSettings`）：强调色、TabBar 颜色、未选中颜色，节日皮肤还为每个 Tab
 *      提供一个 emoji 图标（PlusButton 使用最后一个）。
 */
class DemoTheme(
    val name: String,
    private val tint: Int?,
    private val bar: Int? = null,
    private val normal: Int? = null,
    private val emojis: List<String> = emptyList(),
) : CYLTabBarTheme {

    override fun cyl_tabBarItemsAttributesForTabBarController(tabBarController: CYLTabBarController): List<Map<String, Any?>>? {
        // [EN] No emoji: empty changes, so the launch icons come back. [CN] 没有 emoji：空的修改，启动时的图标恢复。
        return tabBarController.tabBarItemsAttributes.indices.map { index ->
            if (emojis.isEmpty()) emptyMap() else mapOf(CYLConstants.CYLTabBarItemImage to EmojiDrawable(emojis[index % (emojis.size - 1)]),
                  CYLConstants.CYLTabBarItemSelectedImage to EmojiDrawable(emojis[index % (emojis.size - 1)]))
        }
    }

    override fun cyl_tabBarAppearanceForTabBarController(tabBarController: CYLTabBarController): CYLTabBarAppearance? {
        val tint = tint ?: return null
        return CYLTabBarAppearance(backgroundColor = bar, titleColor = normal, selectedTitleColor = tint, iconColor = normal, selectedIconColor = tint)
    }

    override fun cyl_customizeTabBarController(tabBarController: CYLTabBarController) {
        // [EN] Colors a skin leaves out go back to the defaults (the appearance only sets what it has). [CN] 皮肤未提供的颜色恢复默认（外观只设置它提供的值）。
        tabBarController.cyl_tabBarBackgroundColor = bar
        tabBarController.cyl_tabBarItemTitleColor = normal
        tabBarController.cyl_tabBarItemImageColor = normal
        tabBarController.cyl_tabBarItemSelectedTitleColor = tint
        tabBarController.cyl_tabBarItemSelectedImageColor = tint
        val plusButton = tabBarController.tabBar.plusButton ?: return
        val emoji = emojis.lastOrNull()
        plusButton.setImageDrawable(if (emoji != null) EmojiDrawable(emoji) else ContextCompat.getDrawable(plusButton.context, android.R.drawable.ic_input_add))
    }

    companion object {
        /** [EN] The skins, in the iOS order; "Default" restores the launch look. [CN] 皮肤，顺序与 iOS 相同；"Default" 恢复启动时的外观。 */
        val all: List<DemoTheme> by lazy {
            listOf(
                DemoTheme("Default", null),
                DemoTheme("Grapefruit", Color.rgb(239, 83, 98)),
                DemoTheme("Grass", Color.rgb(110, 180, 60)),
                DemoTheme("Pink Rose", Color.rgb(238, 133, 193)),
                DemoTheme("Dark", Color.rgb(39, 192, 243), Color.rgb(18, 18, 20), Color.rgb(142, 142, 147)),
                DemoTheme("Spring Festival", Color.rgb(255, 213, 79), Color.rgb(196, 30, 58), Color.rgb(255, 205, 210), listOf("🧧", "🧨", "🏮", "🐉", "🎆")),
                DemoTheme("Christmas", Color.rgb(255, 214, 102), Color.rgb(22, 101, 52), Color.rgb(200, 230, 201), listOf("🎄", "🎁", "⛄", "🔔", "⭐")),
                DemoTheme("Halloween", Color.rgb(255, 145, 0), Color.rgb(38, 20, 58), Color.rgb(179, 157, 219), listOf("🎃", "👻", "🦇", "🕷", "🍬")),
                DemoTheme("Valentine's Day", Color.rgb(233, 30, 99), Color.rgb(255, 235, 240), Color.rgb(173, 120, 140), listOf("💝", "🌹", "💌", "🍫", "💍")),
                DemoTheme("Mid-Autumn", Color.rgb(255, 193, 7), Color.rgb(26, 35, 76), Color.rgb(159, 168, 218), listOf("🥮", "🌕", "🐇", "🍵", "🌙")),
                DemoTheme("Easter", Color.rgb(124, 179, 66), Color.rgb(255, 250, 225), Color.rgb(161, 136, 127), listOf("🐣", "🥚", "🐰", "🌷", "🧺")),
                DemoTheme("New Year", Color.rgb(255, 215, 64), Color.rgb(20, 20, 40), Color.rgb(144, 164, 174), listOf("🎉", "🎊", "🥂", "🎇", "⏰")),
                DemoTheme("Summer", Color.rgb(0, 151, 167), Color.rgb(255, 248, 225), Color.rgb(141, 110, 99), listOf("🏖", "🍉", "🌴", "🍹", "☀️")),
                DemoTheme("Birthday", Color.rgb(236, 64, 122), Color.rgb(255, 243, 224), Color.rgb(149, 117, 205), listOf("🎂", "🎈", "🕯", "🧸", "🎁")),
                DemoTheme("Space", Color.rgb(128, 222, 234), Color.rgb(13, 17, 38), Color.rgb(121, 134, 203), listOf("🚀", "🪐", "🛸", "🌟", "☄️")),
                DemoTheme("Ocean", Color.WHITE, Color.rgb(1, 87, 155), Color.rgb(129, 212, 250), listOf("🐳", "🐠", "🐚", "🦀", "🌊")),
                DemoTheme("Network", Color.rgb(0, 122, 255), null, null, listOf("🌐", "📡", "🛰", "📶", "🔗")),
            )
        }

        @Synchronized
        fun registerOnce() {
            val manager = CYLThemeManager.defaultManager
            if (manager.themeIdentifiers.isNotEmpty()) return
            all.forEach { manager.addThemeIdentifier(it.name, it) }
        }

        /** [EN] The current skin's name ("Default" when none). [CN] 当前皮肤名称（没有时为 "Default"）。 */
        val currentName: String get() = CYLThemeManager.defaultManager.currentThemeIdentifier as? String ?: "Default"

        /** [EN] Switches the skin of every tab bar controller (the default manager drives them). [CN] 切换所有 TabBarController 的皮肤（由默认管理器驱动）。 */
        fun apply(name: String) {
            registerOnce()
            CYLThemeManager.defaultManager.currentThemeIdentifier = name
        }
    }
}
