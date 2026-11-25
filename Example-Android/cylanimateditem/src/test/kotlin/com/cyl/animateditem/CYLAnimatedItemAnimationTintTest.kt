package com.cyl.animateditem

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.net.Uri
import android.util.Base64
import android.view.View
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.io.File

/**
 * [EN] `CYLAnimatedItemView.animationTint` / `animationDarkTint` against THE tint truth table (the same on iOS, Android, HarmonyOS and the
 *      mini program): `tintTable` lists every row (state x tint kind x which icon colors exist x night mode) once, and each row is
 *      checked on the pure function `CYLTabBarItemAnimationTint.resolve` and on a real item view. Unset or invalid text keeps the
 *      file's colors, "title" with no icon color removes the tint, a fixed color colors the unselected item (`animationDarkTint` at
 *      night) and the selected item takes its selected icon color, 8 digits are #RRGGBBAA. A GIF stands for every engine (the tint
 *      is a color filter on the animation view's layer, not an engine API).
 * [CN] `CYLAnimatedItemView.animationTint` / `animationDarkTint` 对照着色真值表（iOS、Android、鸿蒙、小程序相同）：`tintTable` 逐行列出
 *      （状态 x 着色类型 x 存在哪些图标颜色 x 夜间模式），每一行同时检查纯函数 `CYLTabBarItemAnimationTint.resolve` 与真实的条目视图。
 *      未设置或无效文本保持文件颜色，"title" 且没有图标颜色时移除着色，固定颜色为未选中条目着色（夜间使用 `animationDarkTint`），选中条目使用其选中
 *      图标颜色，8 位为 #RRGGBBAA。GIF 代表所有引擎（着色是动画视图图层上的颜色滤镜，而不是引擎 API）。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemAnimationTintTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val factory = CYLTabBarItemAnimationFactory(CYLTabBarItemAnimatorRegistry().apply { registerAnimator(CYLGIFTabBarItemAnimator.animator) })
    private val gif: String by lazy {
        File.createTempFile("cyl-item-tint", ".gif").apply { writeBytes(Base64.decode(CYLGIFDecoderTestData.THREE_FRAMES, Base64.DEFAULT)); deleteOnExit() }.absolutePath
    }
    private val tintKey = CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionTint
    private val darkTintKey = CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionDarkTint

    private fun item(options: Map<String, String>? = null, load: Boolean = true, configure: CYLAnimatedItemView.() -> Unit = {}): CYLAnimatedItemView =
        CYLAnimatedItemView(context).apply {
            animationSource = factory
            iconColor = Color.RED
            selectedIconColor = Color.BLUE
            configure()
            if (load) animationURL = CYLTabBarAnimationURLWithOptions(gif, options)
        }

    private fun applied(item: CYLAnimatedItemView) = CYLTabBarItemAnimationTint.appliedColor(item.animationView)

    private fun night(item: CYLAnimatedItemView, night: Boolean) {
        // [EN] The resources change first, so a refresh by a property set later sees the same mode. [CN] 先改变资源，这样之后设置属性触发的刷新看到同一模式。
        RuntimeEnvironment.setQualifiers(if (night) "+night" else "+notnight")
        item.dispatchConfigurationChanged(Configuration(item.resources.configuration))
    }

    /**
     * [EN] One row of the truth table. [CN] 真值表的一行。
     */
    private data class Row(
        val tint: String?, val darkTint: String?, val selected: Boolean, val night: Boolean,
        val normal: Int?, val selectedIcon: Int?, val expected: Int?,
    )

    private val n = Color.RED
    private val s = Color.BLUE
    private val fixed = Color.parseColor("#1C1C1E")
    private val dark = Color.WHITE
    private val alpha8 = 0x44112233

    private fun row(tint: String?, darkTint: String?, selected: Boolean, night: Boolean, normal: Int?, selectedIcon: Int?, expected: Int?) =
        Row(tint, darkTint, selected, night, normal, selectedIcon, expected)

    private val tintTable: List<Row> = buildList {
        // unset (property and URL): the file's own colors in every state
        for (selected in listOf(false, true)) for (night in listOf(false, true)) {
            add(row(null, null, selected, night, null, null, null))
            add(row(null, "#FFFFFF", selected, night, n, s, null))
        }
        // "title": unselected normalIconColor (else none); selected selectedIconColor, else normalIconColor, else none; darkTint never applies
        for (night in listOf(false, true)) for (darkTint in listOf(null, "#FFFFFF")) {
            add(row("title", darkTint, false, night, null, null, null))
            add(row("title", darkTint, false, night, n, null, n))
            add(row("title", darkTint, false, night, null, s, null))
            add(row("title", darkTint, false, night, n, s, n))
            add(row("title", darkTint, true, night, null, null, null))
            add(row("title", darkTint, true, night, n, null, n))
            add(row("title", darkTint, true, night, null, s, s))
            add(row("title", darkTint, true, night, n, s, s))
        }
        // "#RRGGBB": unselected the color (darkTint at night when valid); selected selectedIconColor, else the color (darkTint at night)
        for ((normal, selectedIcon) in listOf<Pair<Int?, Int?>>(null to null, n to null, null to s, n to s)) {
            add(row("#1C1C1E", null, false, false, normal, selectedIcon, fixed))
            add(row("#1C1C1E", null, false, true, normal, selectedIcon, fixed))
            add(row("#1C1C1E", "#FFFFFF", false, false, normal, selectedIcon, fixed))
            add(row("#1C1C1E", "#FFFFFF", false, true, normal, selectedIcon, dark))
            add(row("#1C1C1E", "nonsense", false, true, normal, selectedIcon, fixed))
            add(row("#1C1C1E", null, true, false, normal, selectedIcon, selectedIcon ?: fixed))
            add(row("#1C1C1E", "#FFFFFF", true, false, normal, selectedIcon, selectedIcon ?: fixed))
            add(row("#1C1C1E", "#FFFFFF", true, true, normal, selectedIcon, selectedIcon ?: dark))
            add(row("#1C1C1E", "nonsense", true, true, normal, selectedIcon, selectedIcon ?: fixed))
        }
        // "#RRGGBBAA": the last two digits are the alpha, as on iOS
        add(row("#11223344", null, false, false, n, s, alpha8))
        add(row("#11223344", "#FFFFFF80", false, true, n, s, 0x80FFFFFF.toInt()))
        add(row("#11223344", "#FFFFFF80", false, false, n, s, alpha8))
        add(row("#11223344", null, true, false, null, null, alpha8))
        add(row("#11223344", null, true, false, n, s, s))
        // an invalid tint text is unset
        for (text in listOf("red", "#12345", "#1234567", "#GGGGGG", "1C1C1E", "#FFF", "titl", "Title", "#1C1C1E80FF")) for (selected in listOf(false, true)) {
            add(row(text, "#FFFFFF", selected, true, n, s, null))
        }
    }

    private fun describe(row: Row) = "tint=${row.tint} darkTint=${row.darkTint} selected=${row.selected} night=${row.night} normal=${row.normal} selectedIcon=${row.selectedIcon}"

    @Test
    fun theTableOnThePureFunction() {
        tintTable.forEach { row ->
            assertEquals(describe(row), row.expected, CYLTabBarItemAnimationTint.resolve(row.tint, row.darkTint, row.selected, row.night, row.normal, row.selectedIcon))
        }
    }

    @Test
    fun theTableOnARealItem() {
        tintTable.forEach { row ->
            val item = CYLAnimatedItemView(context).apply {
                animationSource = factory
                iconColor = row.normal
                selectedIconColor = row.selectedIcon
                animationTint = row.tint
                animationDarkTint = row.darkTint
                animationURL = gif
            }
            night(item, row.night)
            item.isSelected = row.selected
            assertEquals(describe(row), row.expected, applied(item))
            assertEquals(describe(row), if (row.expected == null) View.LAYER_TYPE_NONE else View.LAYER_TYPE_HARDWARE, item.animationView!!.layerType)
        }
    }

    @Test
    fun theTableWithTheTintInTheSourceUrl() {
        // [EN] The URL's `tint` / `darkTint` options resolve like the properties. [CN] URL 中的 `tint` / `darkTint` 选项与属性相同。
        tintTable.filter { it.tint != null }.forEach { row ->
            val url = "$gif#tint=${Uri.encode(row.tint)}${row.darkTint?.let { "&darkTint=" + Uri.encode(it) } ?: ""}"
            val item = CYLAnimatedItemView(context).apply {
                animationSource = factory
                iconColor = row.normal
                selectedIconColor = row.selectedIcon
                animationURL = url
            }
            night(item, row.night)
            item.isSelected = row.selected
            assertEquals(url + " " + describe(row), row.expected, applied(item))
        }
    }

    @Test
    fun hexIsRRGGBBAA() {
        assertEquals(Color.parseColor("#1C1C1E"), CYLTabBarItemAnimationTint.parseHex("#1C1C1E"))
        assertEquals(Color.parseColor("#1c1c1e"), CYLTabBarItemAnimationTint.parseHex(" #1c1c1e "))
        assertEquals("the alpha is the LAST byte (Color.parseColor would read it first)", 0x80112233.toInt(), CYLTabBarItemAnimationTint.parseHex("#11223380"))
        assertEquals(0x00FF0000, CYLTabBarItemAnimationTint.parseHex("#FF000000"))
        listOf("", "#", "112233", "#123", "#1234567", "#GG0000", "red", "#112233800").forEach { assertNull(it, CYLTabBarItemAnimationTint.parseHex(it)) }
    }

    @Test
    fun hashAndQuestionMarkParseTheSameOptions() {
        listOf("a.gif#tint=title&darkTint=%23FFFFFF", "a.gif?tint=title&darkTint=%23FFFFFF", "a.gif#tint=title&darkTint=#FFFFFF").forEach {
            assertEquals(it, mapOf("tint" to "title", "darkTint" to "#FFFFFF"), CYLTabBarAnimationFileAndOptions(it).second)
            assertEquals(it, CYLAnimatedItemSource.parse(it).options, CYLTabBarAnimationFileAndOptions(it).second)
        }
    }

    @Test
    fun hostTitleColorsPlayTheIconColors() {
        // [EN] The tab bar passes its title colors as the icon colors of an item that has none. [CN] TabBar 把标题颜色作为图标颜色传给没有图标颜色的条目。
        val item = CYLAnimatedItemView(context).apply { animationSource = factory; animationTint = "title"; animationURL = gif }
        assertNull("no color at all: no tint", applied(item))
        item.hostIconColor = Color.GRAY
        item.hostSelectedIconColor = Color.MAGENTA
        assertEquals(Color.GRAY, applied(item))
        item.isSelected = true
        assertEquals(Color.MAGENTA, applied(item))
        item.animationTint = "#1C1C1E"
        assertEquals("a fixed tint: the selected item takes the title's selected color", Color.MAGENTA, applied(item))
        item.isSelected = false
        assertEquals(fixed, applied(item))
        item.selectedIconColor = Color.CYAN
        item.isSelected = true
        assertEquals("the item's own icon color wins over the host's", Color.CYAN, applied(item))
        item.animationTint = "title"
        item.selectedIconColor = null
        item.hostSelectedIconColor = null
        assertEquals("selected falls back to the normal color", Color.GRAY, applied(item))
        item.hostIconColor = null
        assertNull("title with no icon color removes the tint", applied(item))
        assertEquals(View.LAYER_TYPE_NONE, item.animationView!!.layerType)
    }

    @Test
    fun unsetKeepsTheFilesColors() {
        val item = item()
        assertNotNull(item.animationView)
        assertNull(applied(item))
        assertEquals(View.LAYER_TYPE_NONE, item.animationView!!.layerType)
        item.isSelected = true
        item.iconColor = Color.GREEN
        night(item, true)
        assertNull("icon color, state and night mode never recolor an item without animationTint", applied(item))
        assertEquals(View.LAYER_TYPE_NONE, item.animationView!!.layerType)
    }

    @Test
    fun theSourceOptionStaysWhenTheItemSetsNothing() {
        val item = item(mapOf(tintKey to "#1C1C1E"))
        item.isSelected = true
        item.isSelected = false
        night(item, true)
        assertEquals(Color.parseColor("#1C1C1E"), applied(item))
    }

    @Test
    fun titleDrawsInTheIconColorAndTheSelectedColorWhenSelected() {
        val item = item { animationTint = "title" }
        assertEquals(Color.RED, applied(item))
        assertEquals(View.LAYER_TYPE_HARDWARE, item.animationView!!.layerType)
        item.isSelected = true
        assertEquals(Color.BLUE, applied(item))
        item.isSelected = false
        assertEquals(Color.RED, applied(item))
        item.iconColor = Color.GREEN
        assertEquals("a new icon color is drawn at once", Color.GREEN, applied(item))
    }

    @Test
    fun aFixedColorColorsTheUnselectedItemAndItsDarkVariantRulesAtNight() {
        val item = item { animationTint = "#1C1C1E"; animationDarkTint = "#FFFFFF" }
        assertEquals(Color.parseColor("#1C1C1E"), applied(item))
        item.isSelected = true
        assertEquals("the selected item takes its icon color", Color.BLUE, applied(item))
        item.isSelected = false
        night(item, true)
        assertEquals(Color.WHITE, applied(item))
        item.isSelected = true
        assertEquals("selected stays on its icon color at night", Color.BLUE, applied(item))
        item.isSelected = false
        night(item, false)
        assertEquals(Color.parseColor("#1C1C1E"), applied(item))
    }

    @Test
    fun aFixedColorWithoutDarkVariantStaysAtNight() {
        val item = item { animationTint = "#1C1C1E" }
        night(item, true)
        assertEquals(Color.parseColor("#1C1C1E"), applied(item))
    }

    @Test
    fun thePropertyOverridesTheSourceOptionAndClearingRestoresIt() {
        val item = item(mapOf(tintKey to "#FF0000", darkTintKey to "#FFFF00"))
        assertEquals(Color.RED, applied(item))
        item.animationTint = "#00FF00"
        assertEquals(Color.GREEN, applied(item))
        // [EN] The tab bar's player keeps the override when it pushes a title color. [CN] TabBar 的播放器传入标题颜色时保留该覆盖。
        item.animationPlayer!!.setTintColor(Color.GRAY, selected = false)
        assertEquals(Color.GREEN, applied(item))
        night(item, true)
        assertEquals("the URL's darkTint is not overridden by a property that is unset", Color.YELLOW, applied(item))
        item.animationDarkTint = "#00FFFF"
        assertEquals(Color.CYAN, applied(item))
        item.animationTint = null
        item.animationDarkTint = null
        assertEquals(Color.YELLOW, applied(item))
        night(item, false)
        assertEquals(Color.RED, applied(item))
    }

    @Test
    fun setAndClearAfterTheFileLoaded() {
        val item = item()
        assertNull(applied(item))
        item.animationTint = "title"
        assertEquals(Color.RED, applied(item))
        item.animationTint = "#00FF00"
        assertEquals(Color.GREEN, applied(item))
        item.animationTint = null
        assertNull(applied(item))
        assertEquals(View.LAYER_TYPE_NONE, item.animationView!!.layerType)
    }

    @Test
    fun setBeforeTheFileLoadedAppliesWhenItLoads() {
        val item = item(load = false) { animationTint = "title" }
        assertNull(item.animationView)
        item.animationURL = gif
        assertEquals(Color.RED, applied(item))
        item.animationURL = CYLTabBarAnimationURLWithOptions(gif, mapOf("loops" to "1"))
        assertEquals("a reloaded view is tinted too", Color.RED, applied(item))
    }

    @Test
    fun blankValuesChangeNothing() {
        val item = item(mapOf(tintKey to "#FF0000")) { animationTint = "  " }
        assertEquals(Color.RED, applied(item))
    }
}
