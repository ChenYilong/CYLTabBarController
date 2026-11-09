package com.cyl.tabbar

import android.graphics.Color
import android.os.Looper
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.ByteArrayOutputStream
import java.util.UUID

/**
 * [EN] Skins in a configuration file (`CYLTabBarControllerThemes`, shared with iOS): "@name" values, the dictionary and the
 *      list form, the base skin fallback, "@@", Dark Mode, a skin chosen before, theme values of views, and Protobuf.
 * [CN] 配置文件中的皮肤（`CYLTabBarControllerThemes`，与 iOS 相同）："@name" 值、字典与列表形式、回退到基础皮肤、"@@"、深色模式、之前选择的皮肤、
 *      视图的主题值，以及 Protobuf。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLConfigurationThemesTest {

    class Page : Fragment()

    private fun <T> withActivity(qualifiers: String? = null, block: (FragmentActivity) -> T): T {
        if (qualifiers != null) org.robolectric.RuntimeEnvironment.setQualifiers(qualifiers)
        val controller = Robolectric.buildActivity(FragmentActivity::class.java).setup()
        try {
            return block(controller.get())
        } finally {
            controller.pause().stop().destroy()
        }
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun configuration(managerName: String, themes: Any?, extra: Map<String, Any?> = emptyMap()): Map<String, Any?> = mapOf(
        CYLConstants.CYLTabBarControllerViewControllers to listOf(Page(), Page()),
        CYLConstants.CYLTabBarControllerThemeManagerName to managerName,
        CYLConstants.CYLTabBarControllerThemes to themes,
        CYLConstants.CYLTabBarControllerThemeIdentifier to "light",
        CYLConstants.CYLTabBarControllerTabBarItemsAttributes to listOf(
            mapOf(CYLConstants.CYLTabBarItemTitle to "@homeTitle", CYLConstants.CYLTabBarItemIdentifier to "home", CYLConstants.CYLTabBarItemTitleColor to "@accent"),
            mapOf(CYLConstants.CYLTabBarItemTitle to "@@me", CYLConstants.CYLTabBarItemIdentifier to "me"),
        ),
    ) + extra

    private val skins = mapOf(
        "light" to mapOf("homeTitle" to "Home", "accent" to "#FF0000", CYLConstants.CYLTabBarBackgroundColor to "#FFFFFF"),
        "dark" to mapOf("homeTitle" to "Home (dark)", CYLConstants.CYLTabBarBackgroundColor to "#000000"),
    )

    private fun item(controller: CYLTabBarController, identifier: String) = controller.tabBarItemsAttributes.first { it[CYLConstants.CYLTabBarItemIdentifier] == identifier }

    @Test
    fun namedValuesResolveAndTheSkinsSwitchTheTabBar() = withActivity { activity ->
        val name = UUID.randomUUID().toString()
        val controller = CYLTabBarController(activity, configuration(name, skins))
        activity.setContentView(controller.view)
        idle()
        val manager = CYLThemeManagerCenter.themeManagerWithName(name)
        assertSame(manager, controller.cyl_themeManager)
        assertEquals(listOf("dark", "light"), manager.themeIdentifiers.map { it.toString() }.sorted())
        assertEquals("light", manager.currentThemeIdentifier)
        assertEquals("Home", item(controller, "home")[CYLConstants.CYLTabBarItemTitle])
        assertEquals("@me", item(controller, "me")[CYLConstants.CYLTabBarItemTitle])
        assertEquals("Home", controller.tabBar.tabBarButtonArray[0].titleLabel.text)
        assertEquals(Color.RED, controller.tabBar.tabBarButtonArray[0].titleColor(false, controller.tabBar))
        assertEquals(Color.WHITE, controller.cyl_tabBarBackgroundColor)

        val dark = manager.themeForIdentifier("dark") as CYLTabBarConfigurationTheme
        assertEquals("#FF0000", dark.valueForName("accent"))
        manager.currentThemeIdentifier = "dark"
        idle()
        assertEquals("Home (dark)", controller.tabBar.tabBarButtonArray[0].titleLabel.text)
        assertEquals("@me", controller.tabBar.tabBarButtonArray[1].titleLabel.text)
        assertEquals(Color.BLACK, controller.cyl_tabBarBackgroundColor)

        // [EN] Views follow the same skins by name. [CN] 视图按名称跟随同样的皮肤。
        val text = TextView(activity).apply { cyl_themeValueManager = manager; cyl_themeValue = "textColor:accent" }
        assertEquals(Color.RED, text.currentTextColor)
        assertEquals(Color.RED, CYLTabBarConfigurationTheme.colorNamed("accent", name).cyl_rawColor)
    }

    @Test
    fun aSkinOfAnEarlierConfigurationIsReplacedButTheAppsOwnSkinStays() = withActivity { activity ->
        val name = UUID.randomUUID().toString()
        val manager = CYLThemeManagerCenter.themeManagerWithName(name)
        fun build(skin: String) = CYLTabBarController(activity, configuration(name, mapOf(skin to mapOf("accent" to "#FF0000")),
            mapOf(CYLConstants.CYLTabBarControllerThemeIdentifier to skin)))
        build("Default")
        assertEquals("Default", manager.currentThemeIdentifier)
        build("Christmas")
        assertEquals("a skin only an earlier configuration had is not kept", "Christmas", manager.currentThemeIdentifier)
        manager.addThemeIdentifier("App", Any())
        manager.currentThemeIdentifier = "App"
        build("Ocean")
        assertEquals("a skin the app chose stays", "App", manager.currentThemeIdentifier)
    }

    @Test
    fun theListFormAndProtobufMapsAndAChosenSkin() = withActivity { activity ->
        val name = UUID.randomUUID().toString()
        val manager = CYLThemeManagerCenter.themeManagerWithName(name)
        manager.addThemeIdentifier("mine", "the app's own theme")
        manager.currentThemeIdentifier = "mine"
        val list = listOf(mapOf(CYLConstants.CYLTabBarThemeIdentifier to "light", CYLConstants.CYLTabBarThemeValues to listOf(mapOf("key" to "homeTitle", "value" to "Home"))))
        val controller = CYLTabBarController(activity, configuration(name, list))
        assertEquals("a skin chosen before stays", "mine", manager.currentThemeIdentifier)
        assertEquals("Home", item(controller, "home")[CYLConstants.CYLTabBarItemTitle])
        assertNull("a name no skin gives leaves the key out", item(controller, "home")[CYLConstants.CYLTabBarItemTitleColor])
    }

    @Test
    fun aDarkSkinIsUsedInDarkMode() = withActivity("night") { activity ->
        val name = UUID.randomUUID().toString()
        val controller = CYLTabBarController(activity, configuration(name, skins, mapOf(CYLConstants.CYLTabBarControllerDarkThemeIdentifier to "dark")))
        val manager = CYLThemeManagerCenter.themeManagerWithName(name)
        assertEquals("dark", manager.currentThemeIdentifier)
        assertEquals("Home (dark)", item(controller, "home")[CYLConstants.CYLTabBarItemTitle])
        assertNotNull(manager.identifierForTrait)
        assertEquals("light", manager.identifierForTrait?.invoke(false))
    }

    @Test
    fun withoutSkinsAnAtSignIsPlainText() {
        val normalized = CYLTabBarConfiguration.cyl_normalizedConfiguration(mapOf(
            CYLConstants.CYLTabBarControllerTabBarItemsAttributes to listOf(mapOf(CYLConstants.CYLTabBarItemTitle to "@homeTitle")),
        ))
        @Suppress("UNCHECKED_CAST")
        val items = normalized[CYLConstants.CYLTabBarControllerTabBarItemsAttributes] as List<Map<String, Any?>>
        assertEquals("@homeTitle", items[0][CYLConstants.CYLTabBarItemTitle])
        assertNull(CYLConfigurationThemes.themes(listOf("not a skin")))
    }

    @Test
    fun theSampleFilesGiveTheSameSkinsInEveryFormat() {
        val folder = java.io.File(System.getProperty("cyl.sharedConfiguration") ?: return).parentFile
        val expected = CYLConfigurationThemes.themes(CYLTabBarConfigurationParser.dictionaryWithContentsOfFile(java.io.File(folder, "cyl_tabbar_configuration.json").path)[CYLConstants.CYLTabBarControllerThemes])
        assertEquals(setOf("light", "dark"), expected?.keys)
        for (extension in listOf("yaml", "yml", "textproto")) {
            val parsed = CYLTabBarConfigurationParser.dictionaryWithContentsOfFile(java.io.File(folder, "cyl_tabbar_configuration.$extension").path)
            assertEquals(extension, expected, CYLConfigurationThemes.themes(parsed[CYLConstants.CYLTabBarControllerThemes]))
            assertEquals(extension, "dark", parsed[CYLConstants.CYLTabBarControllerDarkThemeIdentifier])
        }
    }

    // MARK: - Protobuf binary

    private fun ByteArrayOutputStream.varint(value: Int) {
        var v = value
        while (v >= 0x80) { write((v and 0x7F) or 0x80); v = v ushr 7 }
        write(v)
    }

    private fun field(number: Int, payload: ByteArray) = ByteArrayOutputStream().apply { varint(number shl 3 or 2); varint(payload.size); write(payload) }.toByteArray()
    private fun text(number: Int, value: String) = field(number, value.toByteArray())

    @Test
    fun skinsArriveFromAProtobufBinaryFile() {
        val entry = text(1, "accent") + text(2, "#FF0000")
        val skin = text(1, "dark") + field(2, entry)
        val data = field(8, skin) + text(9, "dark") + text(10, "dark") + text(11, "manager")
        val parsed = CYLTabBarConfigurationParser.dictionaryWithData(data, CYLTabBarConfigurationFormat.Protobuf)
        assertEquals("dark", parsed[CYLConstants.CYLTabBarControllerThemeIdentifier])
        assertEquals("manager", parsed[CYLConstants.CYLTabBarControllerThemeManagerName])
        val themes = CYLConfigurationThemes.themes(parsed[CYLConstants.CYLTabBarControllerThemes])
        assertEquals(mapOf("dark" to mapOf("accent" to "#FF0000")), themes)
        assertTrue(CYLTabBarConfigurationParser.dictionaryWithData(data, CYLTabBarConfigurationFormat.Protobuf).containsKey(CYLConstants.CYLTabBarControllerDarkThemeIdentifier))
    }

    /**
     * [EN] The bar's images and item layout from a skin, with the same names as iOS (`CYLTabBarBackgroundImage`,
     *      `CYLTabBarShadowImage`, `CYLTabBarStackedItemPositioning` / `Width` / `Spacing`): they reach the bar's appearance,
     *      and the classic bar centers its items.
     * [CN] 皮肤中 TabBar 的图片与 Item 布局，名称与 iOS 相同（`CYLTabBarBackgroundImage`、`CYLTabBarShadowImage`、
     *      `CYLTabBarStackedItemPositioning` / `Width` / `Spacing`）：写入 TabBar 的外观，经典 TabBar 让各 Item 居中。
     */
    @Test
    fun aSkinSetsTheBarImagesAndCentersTheItems() = withActivity { activity ->
        val name = UUID.randomUUID().toString()
        val bar = mapOf(
            "light" to mapOf(
                "homeTitle" to "Home",
                CYLConstants.CYLTabBarBackgroundImage to android.graphics.drawable.ColorDrawable(android.graphics.Color.YELLOW),
                CYLConstants.CYLTabBarShadowImage to android.graphics.drawable.ColorDrawable(android.graphics.Color.GRAY),
                CYLConstants.CYLTabBarStackedItemPositioning to "centered",
                CYLConstants.CYLTabBarStackedItemWidth to 60,
                CYLConstants.CYLTabBarStackedItemSpacing to 10,
            ),
        )
        val controller = CYLTabBarController(activity, configuration(name, bar))
        activity.setContentView(controller.view)
        idle()
        val appearance = controller.tabBar.standardAppearance!!
        assertNotNull(appearance.backgroundImage)
        assertNotNull(appearance.shadowImage)
        assertTrue(appearance.stackedItemPositioningCentered)
        assertEquals(60f, appearance.stackedItemWidth, 0f)
        assertEquals(10f, appearance.stackedItemSpacing, 0f)
        controller.view.measure(android.view.View.MeasureSpec.makeMeasureSpec(1080, android.view.View.MeasureSpec.EXACTLY), android.view.View.MeasureSpec.makeMeasureSpec(1920, android.view.View.MeasureSpec.EXACTLY))
        controller.view.layout(0, 0, 1080, 1920)
        val density = activity.resources.displayMetrics.density
        val buttons = controller.tabBar.tabBarButtonArray
        assertEquals("each item is stackedItemWidth wide", (60 * density), buttons[0].width.toFloat(), 1f)
        assertEquals("stackedItemSpacing apart", (10 * density), (buttons[1].left - buttons[0].right).toFloat(), 1f)
        assertEquals("centered", 1080f - buttons[1].right, buttons[0].left.toFloat(), 2f)
    }
}
