package com.cyl.tabbar.demo

import android.content.Context
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
 * [EN] One skin of the iOS demo's theme list (issue #216, `CYLDemoTheme` in `UIViewController+CYLThemeSettings`): a tint, a
 *      bar color, an unselected color; a holiday skin's icons (`Skins/1.0.0/<theme>/<name>@3x.png` of Example-Shared/Configurations)
 *      in turn on every tab, selected in full color and unselected faded, the last one on the plus button; the network skin
 *      a "★" title prefix and icons downloaded from the network.
 * [CN] iOS 演示皮肤列表中的一个皮肤（issue #216，`UIViewController+CYLThemeSettings` 中的 `CYLDemoTheme`）：强调色、TabBar 颜色、未选中颜色；
 *      节日皮肤的图标（Example-Shared/Configurations 中的 `Skins/1.0.0/<主题>/<名称>@3x.png`）依次用于每个 Tab，选中时为全彩、未选中时为淡色，最后一个用于 PlusButton；
 *      网络皮肤为标题加 "★" 前缀，并从网络下载图标。
 */
class DemoTheme(
    val name: String,
    private val tint: Int?,
    private val bar: Int? = null,
    private val normal: Int? = null,
    private val iconNames: List<String> = emptyList(),
    private val titlePrefix: String? = null,
    private val iconURLs: List<Pair<String, String>> = emptyList(),
    private val plusButtonIconURLs: Pair<String, String>? = null,
) : CYLTabBarTheme {

    /**
     * [EN] A holiday icon of the app (Example-Shared/Configurations, the assets root): `Skins/1.0.0/<theme>/<icon>@3x.png`,
     *      the theme folder being the name in lowercase with "-" for spaces, as on iOS.
     * [CN] App 中的节日图标（Example-Shared/Configurations，即 assets 根目录）：`Skins/1.0.0/<主题>/<图标>@3x.png`，主题文件夹为小写名称、空格换成 "-"，与 iOS 相同。
     */
    private fun icon(context: Context, name: String): Drawable? {
        val folder = this.name.lowercase().replace("'", "").replace(" ", "-")
        return DemoAssets.file(context, "Skins/1.0.0/$folder/$name@3x.png", 3f)
    }

    override fun cyl_tabBarItemsAttributesForTabBarController(tabBarController: CYLTabBarController): List<Map<String, Any?>>? {
        val count = tabBarController.tabBarItemsAttributes.size
        if (iconURLs.isNotEmpty()) return networkItemsAttributes(tabBarController)
        // [EN] A color theme: empty changes, so the launch icons come back. [CN] 配色主题：空的修改，启动时的图标恢复。
        if (iconNames.isEmpty()) return List(count) { emptyMap() }
        return (0 until count).map { index ->
            val selected = icon(tabBarController.activity, iconNames[index % iconNames.size]) ?: return List(count) { emptyMap() }
            val faded = icon(tabBarController.activity, iconNames[index % iconNames.size])?.mutate()?.apply { alpha = FADED_ALPHA }
            mapOf(CYLConstants.CYLTabBarItemImage to faded, CYLConstants.CYLTabBarItemSelectedImage to selected)
        }
    }

    /** [EN] The network skin: every title with the prefix (once), the icons downloaded (24 × 24). [CN] 网络皮肤：每个标题加前缀（只加一次），图标从网络下载（24 × 24）。 */
    private fun networkItemsAttributes(tabBarController: CYLTabBarController): List<Map<String, Any?>> {
        val prefix = "${titlePrefix.orEmpty()} "
        return tabBarController.tabBarItemsAttributes.mapIndexed { index, attributes ->
            val (url, selectedURL) = iconURLs[index % iconURLs.size]
            var title = attributes[CYLConstants.CYLTabBarItemTitle] as? String ?: ""
            while (!titlePrefix.isNullOrEmpty() && title.startsWith(prefix)) title = title.removePrefix(prefix)
            mapOf(CYLConstants.CYLTabBarItemImageURL to url, CYLConstants.CYLTabBarItemSelectedImageURL to selectedURL,
                  CYLConstants.CYLTabBarItemImageURLSize to "{24, 24}", CYLConstants.CYLTabBarItemTitle to prefix + title)
        }
    }

    override fun cyl_tabBarAppearanceForTabBarController(tabBarController: CYLTabBarController): CYLTabBarAppearance? {
        val tint = tint ?: return null
        return CYLTabBarAppearance(backgroundColor = bar, titleColor = normal, selectedTitleColor = tint, iconColor = normal, selectedIconColor = tint)
    }

    override fun cyl_customizeTabBarController(tabBarController: CYLTabBarController) {
        // [EN] Colors a skin leaves out go back to the defaults; holiday icons keep their own colors (iOS: original images).
        // [CN] 皮肤未提供的颜色恢复默认；节日图标保留自身颜色（iOS：原始图片）。
        val keepsIconColors = iconNames.isNotEmpty() || iconURLs.isNotEmpty()
        tabBarController.cyl_tabBarBackgroundColor = bar
        tabBarController.cyl_tabBarItemTitleColor = normal
        tabBarController.cyl_tabBarItemSelectedTitleColor = tint
        tabBarController.cyl_tabBarItemImageColor = if (keepsIconColors) null else normal
        tabBarController.cyl_tabBarItemSelectedImageColor = if (keepsIconColors) null else tint
        val plusButton = tabBarController.tabBar.plusButton ?: return
        val context = plusButton.context
        val plusIcon = iconNames.lastOrNull()?.let { icon(context, it) }
        val plusURL = plusButtonIconURLs?.first
        when {
            plusIcon != null -> plusButton.setImageDrawable(plusIcon)
            plusURL != null -> Thread {
                val image = runCatching { java.net.URI(plusURL).toURL().openStream().use { android.graphics.drawable.Drawable.createFromStream(it, null) } }.getOrNull()
                plusButton.post { if (image != null) plusButton.setImageDrawable(image) }
            }.start()
            else -> plusButtonImage?.let { plusButton.setImageDrawable(it(context)) }
        }
    }

    companion object {
        private const val FADED_ALPHA = 110
        /** [EN] The app's own plus button image, restored by a color theme. [CN] App 自己的 PlusButton 图片，配色主题恢复它。 */
        var plusButtonImage: ((Context) -> Drawable?)? = { ContextCompat.getDrawable(it, android.R.drawable.ic_input_add) }

        private fun rgb(r: Int, g: Int, b: Int) = Color.rgb(r, g, b)

        /** [EN] The skins, in the iOS order and with the iOS colors, icons and URLs (`CYLDemoThemes()`). [CN] 皮肤，顺序、颜色、图标与 URL 与 iOS 相同（`CYLDemoThemes()`）。 */
        val all: List<DemoTheme> by lazy {
            listOf(
                DemoTheme("Default", null),
                DemoTheme("Grapefruit", rgb(239, 83, 98)),
                DemoTheme("Grass", rgb(110, 180, 60)),
                DemoTheme("Pink Rose", rgb(238, 133, 193)),
                DemoTheme("Dark", rgb(39, 192, 243), rgb(18, 18, 20), rgb(142, 142, 147)),
                DemoTheme("Spring Festival", rgb(255, 213, 79), rgb(196, 30, 58), rgb(255, 205, 210), listOf("red_envelope", "firecracker", "red_paper_lantern", "dragon", "fireworks")),
                DemoTheme("Christmas", rgb(255, 214, 102), rgb(22, 101, 52), rgb(200, 230, 201), listOf("christmas_tree", "wrapped_gift", "snowman", "bell", "star")),
                DemoTheme("Halloween", rgb(255, 145, 0), rgb(38, 20, 58), rgb(179, 157, 219), listOf("jack_o_lantern", "ghost", "bat", "spider", "candy")),
                DemoTheme("Valentine's Day", rgb(233, 30, 99), rgb(255, 235, 240), rgb(173, 120, 140), listOf("heart_with_ribbon", "rose", "love_letter", "chocolate_bar", "ring")),
                DemoTheme("Mid-Autumn", rgb(255, 193, 7), rgb(26, 35, 76), rgb(159, 168, 218), listOf("moon_cake", "full_moon", "rabbit", "teacup_without_handle", "crescent_moon")),
                DemoTheme("Easter", rgb(124, 179, 66), rgb(255, 250, 225), rgb(161, 136, 127), listOf("hatching_chick", "egg", "rabbit_face", "tulip", "basket")),
                DemoTheme("New Year", rgb(255, 215, 64), rgb(20, 20, 40), rgb(144, 164, 174), listOf("party_popper", "confetti_ball", "clinking_glasses", "sparkler", "alarm_clock")),
                DemoTheme("Summer", rgb(0, 151, 167), rgb(255, 248, 225), rgb(141, 110, 99), listOf("beach_with_umbrella", "watermelon", "palm_tree", "tropical_drink", "sun")),
                DemoTheme("Birthday", rgb(236, 64, 122), rgb(255, 243, 224), rgb(149, 117, 205), listOf("birthday_cake", "balloon", "candle", "teddy_bear", "wrapped_gift")),
                DemoTheme("Space", rgb(128, 222, 234), rgb(13, 17, 38), rgb(121, 134, 203), listOf("rocket", "ringed_planet", "flying_saucer", "glowing_star", "comet")),
                DemoTheme("Ocean", Color.WHITE, rgb(1, 87, 155), rgb(129, 212, 250), listOf("spouting_whale", "tropical_fish", "spiral_shell", "crab", "water_wave")),
                DemoTheme("Network", rgb(0, 122, 255), rgb(242, 247, 255), rgb(120, 134, 156), titlePrefix = "★",
                    iconURLs = listOf(
                        "https://cdn-icons-png.flaticon.com/512/1946/1946488.png" to "https://cdn-icons-png.flaticon.com/512/1946/1946436.png",
                        "https://cdn-icons-png.flaticon.com/512/2099/2099085.png" to "https://cdn-icons-png.flaticon.com/512/2099/2099085.png",
                        "https://cdn-icons-png.flaticon.com/512/2099/2099100.png" to "https://cdn-icons-png.flaticon.com/512/2099/2099100.png",
                        "https://cdn-icons-png.flaticon.com/512/1077/1077063.png" to "https://cdn-icons-png.flaticon.com/512/1077/1077114.png",
                    ),
                    plusButtonIconURLs = "https://cdn-icons-png.flaticon.com/512/992/992651.png" to "https://cdn-icons-png.flaticon.com/512/1828/1828817.png"),
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
