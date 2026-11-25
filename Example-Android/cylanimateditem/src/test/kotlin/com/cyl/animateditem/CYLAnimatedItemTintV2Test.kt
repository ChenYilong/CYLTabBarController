package com.cyl.animateditem

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.net.Uri
import android.util.Base64
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.io.File

/**
 * [EN] Tint spec v2 (the same on iOS, Android, HarmonyOS and the mini program): the item tint table with rendering modes and one-color
 *      detection (`CYLTabBarItemAnimationTint.resolveItem`, on the pure function and on real items), the explicit-vs-effective icon
 *      color split, the fixed-tint-selected row, the built-in colors (pinned probe constants, theme attributes of the item's own context),
 *      the rendering mode of item / stack / URL option, the detector on the shared fixtures, and the divider contrast (>= 3:1 on white and
 *      on a dark bar). Run with Robolectric (`org.json` is real there).
 * [CN] 着色规范 v2（iOS、Android、鸿蒙、小程序相同）：带渲染模式与单色检测的条目着色表（`CYLTabBarItemAnimationTint.resolveItem`，同时测纯函数与真实条目）、
 *      显式与有效图标颜色的区分、固定着色选中行、内置颜色（固定的探测常量、条目自己 context 的主题属性）、条目 / 堆叠 / URL 选项的渲染模式、
 *      在共用夹具上的检测器，以及分隔线对比度（在白色与深色栏上 >= 3:1）。使用 Robolectric 运行（那里的 `org.json` 是真实的）。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemTintV2Test {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val factory = CYLTabBarItemAnimationFactory(CYLTabBarItemAnimatorRegistry().apply { registerAnimator(CYLGIFTabBarItemAnimator.animator) })

    // [EN] A one-color GIF (the first frame of THREE_FRAMES is all red) and a multi-color one (random indices). [CN] 单色 GIF（THREE_FRAMES 第一帧全红）与多色 GIF（随机索引）。
    private val oneColorGif: String by lazy { temp(CYLGIFDecoderTestData.THREE_FRAMES, "one") }
    private val multiColorGif: String by lazy { temp(CYLGIFDecoderTestData.NOISE, "multi") }

    private fun temp(base64: String, name: String): String =
        File.createTempFile("cyl-v2-$name", ".gif").apply { writeBytes(Base64.decode(base64, Base64.DEFAULT)); deleteOnExit() }.absolutePath

    private fun fixture(name: String): ByteArray = javaClass.classLoader!!.getResourceAsStream("fixtures/$name")!!.use { it.readBytes() }
    private fun fixtureText(name: String) = String(fixture(name), Charsets.UTF_8)

    @Before
    fun clear() = CYLAnimationColorCount.clearCache()

    private fun configuration(night: Boolean) = Configuration(context.resources.configuration).apply {
        uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or (if (night) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO)
    }

    private fun night(item: CYLAnimatedItemView, night: Boolean) {
        RuntimeEnvironment.setQualifiers(if (night) "+night" else "+notnight")
        item.dispatchConfigurationChanged(Configuration(item.resources.configuration))
    }

    private fun applied(item: CYLAnimatedItemView) = CYLTabBarItemAnimationTint.appliedColor(item.animationView)

    private val one = CYLAnimationColorCount.Kind.OneColor
    private val multi = CYLAnimationColorCount.Kind.MultiColor
    private val unknown = CYLAnimationColorCount.Kind.Undetectable
    private val automatic = CYLAnimationRenderingMode.Automatic
    private val template = CYLAnimationRenderingMode.AlwaysTemplate
    private val original = CYLAnimationRenderingMode.AlwaysOriginal

    private val n = Color.RED
    private val s = Color.BLUE
    private val e = Color.GREEN       // an effective color a row passes to the pure function
    private val fixed = Color.parseColor("#1C1C1E")
    private val darkFixed = Color.WHITE

    // MARK: - The pure table 纯函数表

    private data class Pure(
        val tint: String?, val dark: String?, val mode: CYLAnimationRenderingMode, val kind: CYLAnimationColorCount.Kind,
        val selected: Boolean, val night: Boolean, val effective: Int?, val explicitSelected: Int?, val expected: Int?,
    )

    private val pureTable: List<Pure> = buildList {
        // a valid tint wins over the mode and the kind; the kind never matters for it
        for (mode in listOf(automatic, template, original)) for (kind in listOf(one, multi, unknown)) {
            add(Pure("title", null, mode, kind, false, false, e, null, e))
            add(Pure("title", null, mode, kind, true, false, e, s, e))                     // title: the EFFECTIVE color of the state
            add(Pure("title", null, mode, kind, true, true, null, null, null))             // nothing effective (a host without built-ins)
            add(Pure("#1C1C1E", null, mode, kind, false, false, e, s, fixed))
            add(Pure("#1C1C1E", "#FFFFFF", mode, kind, false, true, e, s, darkFixed))
            add(Pure("#1C1C1E", "nonsense", mode, kind, false, true, e, s, fixed))
        }
        // THE FIXED-TINT-SELECTED ROW: a fixed tint on a SELECTED item yields ONLY to an EXPLICIT selected icon color, never to the built-in selected color
        for (mode in listOf(automatic, template, original)) {
            add(Pure("#1C1C1E", null, mode, one, true, false, s /* effective = built-in selected */, null, fixed))
            add(Pure("#1C1C1E", "#FFFFFF", mode, one, true, true, s, null, darkFixed))
            add(Pure("#1C1C1E", null, mode, one, true, false, n, n, n))                    // explicit selected: wins
            add(Pure("#1C1C1E", "#FFFFFF", mode, one, true, true, n, n, n))
        }
        // no (valid) tint: the mode decides
        for (tint in listOf(null, "", "  ", "red", "#12345", "titl", "Title")) for (selected in listOf(false, true)) for (night in listOf(false, true)) {
            add(Pure(tint, "#FFFFFF", original, one, selected, night, e, n, null))
            add(Pure(tint, "#FFFFFF", original, multi, selected, night, e, n, null))
            add(Pure(tint, "#FFFFFF", template, one, selected, night, e, n, e))
            add(Pure(tint, "#FFFFFF", template, multi, selected, night, e, n, e))
            add(Pure(tint, "#FFFFFF", template, unknown, selected, night, e, n, e))
            add(Pure(tint, "#FFFFFF", template, unknown, selected, night, null, null, null))
            add(Pure(tint, "#FFFFFF", automatic, one, selected, night, e, n, e))           // automatic: one-color only
            add(Pure(tint, "#FFFFFF", automatic, multi, selected, night, e, n, null))
            add(Pure(tint, "#FFFFFF", automatic, unknown, selected, night, e, n, null))    // undetectable keeps the original colors
        }
    }

    private fun describe(row: Pure) = row.toString()

    @Test
    fun theItemTableOnThePureFunction() {
        pureTable.forEach { row ->
            assertEquals(describe(row), row.expected, CYLTabBarItemAnimationTint.resolveItem(
                row.tint, row.dark, row.mode, row.kind, row.selected, row.night, row.effective, row.explicitSelected,
            ))
        }
    }

    // MARK: - The table on a real item 真实条目上的表

    private data class Real(
        val tint: String?, val dark: String?, val mode: CYLAnimationRenderingMode?, val file: CYLAnimationColorCount.Kind,
        val selected: Boolean, val night: Boolean, val normal: Int?, val selectedIcon: Int?,
        /** [EN] Given the built-in normal and selected colors of the item's own mode. [CN] 给定条目自己模式下的内置普通与选中颜色。 */
        val expected: (builtInNormal: Int, builtInSelected: Int) -> Int?,
    )

    private val realTable: List<Real> = buildList {
        for (selected in listOf(false, true)) for (night in listOf(false, true)) {
            // Automatic (mode unset): a one-color file takes the effective color, a multi-color file keeps its colors
            add(Real(null, null, null, one, selected, night, null, null) { bn, bs -> if (selected) bs else bn })
            add(Real(null, null, null, one, selected, night, n, null) { bn, bs -> if (selected) bs else n })          // selected without explicit: built-in selected
            add(Real(null, null, null, one, selected, night, n, s) { _, _ -> if (selected) s else n })
            add(Real(null, null, null, multi, selected, night, n, s) { _, _ -> null })
            add(Real(null, null, template, multi, selected, night, n, s) { _, _ -> if (selected) s else n })
            add(Real(null, null, template, multi, selected, night, null, null) { bn, bs -> if (selected) bs else bn })
            add(Real(null, null, original, one, selected, night, n, s) { _, _ -> null })
            // an explicit tint beats the mode
            add(Real("title", null, original, multi, selected, night, n, s) { _, _ -> if (selected) s else n })
            add(Real("title", null, automatic, one, selected, night, null, null) { bn, bs -> if (selected) bs else bn })
            add(Real("#1C1C1E", "#FFFFFF", original, one, selected, night, n, null) { _, _ -> if (selected) (if (night) darkFixed else fixed) else (if (night) darkFixed else fixed) })
            add(Real("#1C1C1E", null, template, multi, selected, night, n, s) { _, _ -> if (selected) s else fixed })
            // an invalid tint is unset: the mode applies
            add(Real("nonsense", null, automatic, one, selected, night, n, s) { _, _ -> if (selected) s else n })
            add(Real("nonsense", null, automatic, multi, selected, night, n, s) { _, _ -> null })
        }
    }

    private fun builtIn(item: CYLAnimatedItemView, selected: Boolean): Int {
        val configuration = item.resources.configuration
        return if (selected) CYLAnimatedItemBuiltInColors.selected(context, configuration) else CYLAnimatedItemBuiltInColors.normal(context, configuration)
    }

    private fun makeItem(row: Real, url: String? = null) = CYLAnimatedItemView(context).apply {
        animationSource = factory
        iconColor = row.normal
        selectedIconColor = row.selectedIcon
        animationTint = row.tint
        animationDarkTint = row.dark
        animationRenderingMode = row.mode
        animationURL = url ?: if (row.file == one) oneColorGif else multiColorGif
    }

    @Test
    fun theItemTableOnARealItem() {
        realTable.forEach { row ->
            val item = makeItem(row)
            night(item, row.night)
            item.isSelected = row.selected
            val expected = row.expected(builtIn(item, false), builtIn(item, true))
            assertEquals(row.toString(), expected, applied(item))
        }
    }

    @Test
    fun theUrlOptionsResolveLikeTheProperties() {
        // [EN] `tint`, `darkTint` and `renderingMode` in the source URL; the item sets nothing. [CN] 来源 URL 中的 `tint`、`darkTint` 与 `renderingMode`；条目什么都不设置。
        realTable.filter { it.tint != null || it.mode != null }.forEach { row ->
            val file = if (row.file == one) oneColorGif else multiColorGif
            val options = listOfNotNull(
                row.tint?.let { "tint=" + Uri.encode(it) }, row.dark?.let { "darkTint=" + Uri.encode(it) }, row.mode?.let { "renderingMode=" + it.optionValue },
            ).joinToString("&")
            val item = CYLAnimatedItemView(context).apply {
                animationSource = factory
                iconColor = row.normal
                selectedIconColor = row.selectedIcon
                animationURL = "$file#$options"
            }
            night(item, row.night)
            item.isSelected = row.selected
            val expected = row.expected(builtIn(item, false), builtIn(item, true))
            assertEquals("$options $row", expected, applied(item))
        }
    }

    // MARK: - Explicit vs effective 显式与有效

    @Test
    fun explicitAndEffectiveIconColors() {
        val item = CYLAnimatedItemView(context)
        val configuration = configuration(false)
        assertNull(item.explicitIconColor)
        assertNull(item.explicitSelectedIconColor)
        assertEquals("nothing set: the built-in normal color", CYLAnimatedItemBuiltInColors.normal(context, configuration), item.resolvedIconColor(configuration))
        item.isSelected = true
        assertEquals("selecting changes the color with nothing set", CYLAnimatedItemBuiltInColors.selected(context, configuration), item.resolvedIconColor(configuration))
        item.iconColor = Color.RED
        assertEquals("an explicit normal color does not make the selected one", CYLAnimatedItemBuiltInColors.selected(context, configuration), item.resolvedIconColor(configuration))
        assertNull(item.explicitSelectedIconColor)
        item.hostSelectedIconColor = Color.MAGENTA
        assertEquals(Color.MAGENTA, item.explicitSelectedIconColor)
        assertEquals(Color.MAGENTA, item.resolvedIconColor(configuration))
        item.selectedIconColor = Color.CYAN
        assertEquals("item over host", Color.CYAN, item.resolvedIconColor(configuration))
        item.isSelected = false
        assertEquals(Color.RED, item.explicitIconColor)
        assertEquals(Color.RED, item.resolvedIconColor(configuration))
        item.iconColor = null
        assertNull(item.explicitIconColor)
        assertEquals("assigning null resets to the built-in", CYLAnimatedItemBuiltInColors.normal(context, configuration), item.resolvedIconColor(configuration))
    }

    @Test
    fun theFixedTintOfASelectedItemYieldsOnlyToAnExplicitSelectedColor() {
        val item = CYLAnimatedItemView(context).apply {
            animationSource = factory
            animationRenderingMode = automatic
            iconColor = Color.RED                     // explicit normal only
            animationTint = "#1C1C1E"
            animationURL = oneColorGif
        }
        item.isSelected = true
        assertEquals("not the built-in selected (blue) color", fixed, applied(item))
        item.selectedIconColor = Color.CYAN
        assertEquals(Color.CYAN, applied(item))
        item.selectedIconColor = null
        assertEquals(fixed, applied(item))
        // the stack's explicit selected color counts as explicit too
        val stack = CYLAnimatedItemStackView(context)
        stack.selectedIconColor = Color.MAGENTA
        stack.append(item)
        assertEquals(Color.MAGENTA, applied(item))
    }

    @Test
    fun disabledUsesTheDisabledBuiltInOnlyWhenTheViewDoesNotDimItself() {
        val dims = CYLAnimatedItemView(context).apply { animationSource = factory; animationRenderingMode = template; animationURL = oneColorGif }
        val configuration = dims.resources.configuration
        dims.isEnabled = false
        assertEquals("disabledAlpha 0.5 dims the view: no second dimming", CYLAnimatedItemBuiltInColors.normal(context, configuration), applied(dims))
        val item = CYLAnimatedItemView(context).apply { animationSource = factory; animationRenderingMode = template; disabledAlpha = 1f; animationURL = oneColorGif }
        item.isEnabled = false
        assertEquals(CYLAnimatedItemBuiltInColors.disabled(context, configuration), applied(item))
        item.isEnabled = true
        assertEquals(CYLAnimatedItemBuiltInColors.normal(context, configuration), applied(item))
    }

    // MARK: - Rendering mode 渲染模式

    @Test
    fun renderingModePrecedenceItemStackOptionAutomatic() {
        val stack = CYLAnimatedItemStackView(context)
        stack.iconColor = Color.RED
        val inheriting = CYLAnimatedItemView(context).apply { animationSource = factory; animationURL = multiColorGif }
        val own = CYLAnimatedItemView(context).apply { animationSource = factory; animationURL = multiColorGif; animationRenderingMode = original }
        val option = CYLAnimatedItemView(context).apply { animationSource = factory; animationURL = "$multiColorGif#renderingMode=alwaysTemplate" }
        stack.append(inheriting)
        stack.append(own)
        stack.append(option)
        assertNull("automatic, multi-color: original colors", applied(inheriting))
        assertEquals("the URL option", Color.RED, applied(option))
        stack.animationRenderingMode = template
        assertEquals("the stack's mode, inherited", Color.RED, applied(inheriting))
        assertNull("an item's own mode wins", applied(own))
        assertEquals(Color.RED, applied(option))
        stack.animationRenderingMode = original
        assertNull(applied(inheriting))
        assertNull("the stack's mode beats the URL option", applied(option))
        own.animationRenderingMode = template
        assertEquals(Color.RED, applied(own))
        own.animationRenderingMode = null
        assertNull("null inherits the stack's alwaysOriginal", applied(own))
        stack.animationRenderingMode = null
        assertNull("cleared: back to automatic", applied(inheriting))
        stack.remove(inheriting)
        stack.animationRenderingMode = template
        assertNull("a removed item drops the inherited mode", applied(inheriting))
    }

    @Test
    fun renderingModeOptionParsing() {
        assertEquals(template, CYLAnimationRenderingMode.parse(" alwaysTemplate "))
        assertEquals(original, CYLAnimationRenderingMode.parse("ALWAYSORIGINAL"))
        assertEquals(automatic, CYLAnimationRenderingMode.parse("automatic"))
        listOf(null, "", "  ", "template", "original", "auto").forEach { assertNull(it, CYLAnimationRenderingMode.parse(it)) }
        assertEquals("renderingMode", CYLAnimationRenderingMode.OPTION_NAME)
    }

    @Test
    fun theDetectorReadsTheFileOnlyWhenItDecides() {
        // [EN] A one-color file with the file missing is undetectable (not cached), so it keeps its colors until the file exists. [CN] 文件缺失时的单色文件无法检测（不缓存），文件出现之前保持原色。
        val path = File(File(oneColorGif).parentFile, "cyl-v2-late-" + System.nanoTime() + ".gif")
        assertEquals(unknown, CYLAnimationColorCount.kindOfSource(context, path.absolutePath))
        path.writeBytes(File(oneColorGif).readBytes())
        path.deleteOnExit()
        assertEquals(one, CYLAnimationColorCount.kindOfSource(context, path.absolutePath + "#tint=title"))
        path.delete()
        assertEquals("cached per file URL", one, CYLAnimationColorCount.kindOfSource(context, path.absolutePath))
    }

    // MARK: - Detector 检测器

    @Test
    fun fixturesOnLottie() {
        assertEquals("camera (one near-black color; the stand-in for the search bar camera)", one, CYLAnimationColorCount.lottieKind(fixtureText("camera-one-color.json")))
        assertEquals("a tab icon with one color", one, CYLAnimationColorCount.lottieKind(fixtureText("tab-home-one-color.json")))
        assertEquals("three colors (green tab)", multi, CYLAnimationColorCount.lottieKind(fixtureText("green-multi-color.json")))
        assertEquals("a gradient", multi, CYLAnimationColorCount.lottieKind(fixtureText("gradient-multi-color.json")))
        assertEquals(one, CYLAnimationColorCount.kind("json", fixture("camera-one-color.json")))
    }

    @Test
    fun fixturesOnGif() {
        assertEquals("all red", one, gifKindOf(CYLGIFDecoderTestData.THREE_FRAMES))
        assertEquals("random indices", multi, gifKindOf(CYLGIFDecoderTestData.NOISE))
        assertEquals(multi, CYLAnimationColorCount.gifKind(fixture("nofavorites.gif")))
        assertEquals(multi, CYLAnimationColorCount.gifKind(fixture("ring.gif")))
        assertEquals(multi, CYLAnimationColorCount.gifKind(fixture("throbber.gif")))
        assertEquals(unknown, CYLAnimationColorCount.gifKind(byteArrayOf(1, 2, 3)))
        assertEquals("other engines are undetectable", unknown, CYLAnimationColorCount.kind("pag", fixture("camera-one-color.json")))
        assertEquals(unknown, CYLAnimationColorCount.kind("riv", ByteArray(4)))
    }

    private fun gifKindOf(base64: String) = CYLAnimationColorCount.gifKind(Base64.decode(base64, Base64.DEFAULT))

    private fun rgb(r: Int, g: Int, b: Int) = "[${r / 255.0},${g / 255.0},${b / 255.0}]"
    private fun fill(color: String, extra: String = "") = """{"ty":"fl","c":{"a":0,"k":$color}$extra}"""
    private fun lottie(shapes: String, assets: String = "", layerExtra: String = "") =
        """{"v":"5.5.2","assets":[$assets],"layers":[{"ty":4,"shapes":[{"ty":"gr","it":[$shapes]}]$layerExtra}]}"""

    @Test
    fun lottieColorRules() {
        fun kind(text: String) = CYLAnimationColorCount.lottieKind(text)
        assertEquals(one, kind(lottie(fill("[0,0,0,1]"))))
        assertEquals("alpha is ignored", one, kind(lottie(fill("[0.5,0.5,0.5,1]") + "," + fill("[0.5,0.5,0.5,0.4]"))))
        assertEquals("within +-2/255 is the same color", one, kind(lottie(fill(rgb(100, 100, 100)) + "," + fill(rgb(102, 98, 100)))))
        assertEquals("3/255 apart is another color", multi, kind(lottie(fill(rgb(100, 100, 100)) + "," + fill(rgb(103, 100, 100)))))
        assertEquals("a fully transparent color (alpha 0) is skipped", one, kind(lottie(fill("[1,0,0,1]") + "," + fill("[0,1,0,0]"))))
        assertEquals("a fill with static opacity 0 is skipped", one, kind(lottie(fill("[1,0,0,1]") + "," + fill("[0,1,0,1]", ""","o":{"a":0,"k":0}"""))))
        assertEquals("strokes count", multi, kind(lottie(fill("[1,0,0,1]") + ",{\"ty\":\"st\",\"c\":{\"a\":0,\"k\":[0,0,1,1]}}")))
        assertEquals("the same color in a fill and a stroke", one, kind(lottie(fill("[1,0,0,1]") + ",{\"ty\":\"st\",\"c\":{\"a\":0,\"k\":[1,0,0,1]}}")))
        assertEquals("a gradient fill", multi, kind(lottie(fill("[0,0,0,1]") + ",{\"ty\":\"gf\"}")))
        assertEquals("a gradient stroke", multi, kind(lottie("{\"ty\":\"gs\"}")))
        assertEquals("keyframe values count: s", multi, kind(lottie(fill("""[{"t":0,"s":[1,0,0,1]},{"t":10,"s":[0,0,1,1]}]""").replace("\"a\":0", "\"a\":1"))))
        assertEquals("keyframe values count: old-style e", multi, kind(lottie(fill("""[{"t":0,"s":[1,0,0,1],"e":[0,0,1,1]}]""").replace("\"a\":0", "\"a\":1"))))
        assertEquals("equal keyframes are one color", one, kind(lottie(fill("""[{"t":0,"s":[1,0,0,1]},{"t":10,"s":[1,0,0,1]}]""").replace("\"a\":0", "\"a\":1"))))
        assertEquals("an image layer", multi, kind("""{"layers":[{"ty":2,"refId":"image_0"},{"ty":4,"shapes":[${fill("[0,0,0,1]")}]}]}"""))
        assertEquals("an image asset", multi, kind(lottie(fill("[0,0,0,1]"), """{"id":"image_0","w":10,"h":10,"u":"images/","p":"img_0.png"}""")))
        assertEquals("a precomp asset is read like the root", multi, kind("""{"assets":[{"id":"c","layers":[{"ty":4,"shapes":[${fill("[1,0,0,1]")}]}]}],"layers":[{"ty":4,"shapes":[${fill("[0,0,1,1]")}]}]}"""))
        assertEquals("an effect with ty 2 is not an image layer", one, kind(lottie(fill("[0,0,0,1]"), "", ""","ef":[{"ty":2}]""")))
        assertEquals("no color at all", unknown, kind("""{"layers":[{"ty":4,"shapes":[{"ty":"sh"}]}]}"""))
        assertEquals("not JSON", unknown, kind("not json"))
        assertEquals("a JSON array", unknown, kind("[1,2]"))
        assertEquals("empty", unknown, kind(""))
    }

    @Test
    fun gifFirstFrameRules() {
        fun px(alpha: Int, rgb: Int) = (alpha shl 24) or rgb
        fun kind(vararg parts: Pair<Int, Int>): CYLAnimationColorCount.Kind {
            val list = ArrayList<Int>()
            parts.forEach { (pixel, count) -> repeat(count) { list.add(pixel) } }
            return CYLAnimationColorCount.gifKind(list.toIntArray())
        }
        val black = px(255, 0x000000)
        assertEquals(one, kind(black to 100))
        assertEquals("98 of 100 in one bucket", one, kind(black to 98, px(255, 0xFF0000) to 2))
        assertEquals("97 of 100", multi, kind(black to 97, px(255, 0xFF0000) to 3))
        assertEquals("the same 4-bit bucket is one color (0x00 vs 0x0F)", one, kind(black to 50, px(255, 0x0F0F0F) to 50))
        assertEquals("the next bucket is another color (0x10)", multi, kind(black to 50, px(255, 0x101010) to 50))
        assertEquals("alpha < 0.1 is ignored", one, kind(black to 10, px(24, 0xFF0000) to 90))
        assertEquals("alpha 26 (>= 0.1) counts", multi, kind(black to 10, px(26, 0xFF0000) to 90))
        assertEquals("anti-aliased edges of one color (un-premultiplied) stay one color", one, kind(black to 60, px(128, 0x000000) to 20, px(40, 0x000000) to 20))
        assertEquals("fully transparent frame", unknown, kind(px(0, 0) to 10))
        assertEquals("no pixel", unknown, CYLAnimationColorCount.gifKind(IntArray(0)))
    }

    // MARK: - Built-in colors 内置颜色

    @Test
    fun theProbeConstantsArePinned() {
        assertEquals(0xFF000000.toInt(), CYLAnimatedItemBuiltInColors.NORMAL_LIGHT)
        assertEquals(0xFFFFFFFF.toInt(), CYLAnimatedItemBuiltInColors.NORMAL_DARK)
        assertEquals(Color.rgb(0, 136, 255), CYLAnimatedItemBuiltInColors.SELECTED_LIGHT)
        assertEquals(Color.rgb(0, 145, 255), CYLAnimatedItemBuiltInColors.SELECTED_DARK)
        assertEquals(Color.argb(115, 134, 134, 134), CYLAnimatedItemBuiltInColors.DISABLED_LIGHT)     // 134,134,134 @ 0.45
        assertEquals(Color.argb(89, 140, 140, 140), CYLAnimatedItemBuiltInColors.DISABLED_DARK)       // 140,140,140 @ 0.35
        assertEquals(Color.argb(153, 60, 60, 67), CYLAnimatedItemBuiltInColors.DIVIDER_LIGHT)         // secondaryLabel 60,60,67 @ 0.60
        assertEquals(Color.argb(153, 235, 235, 245), CYLAnimatedItemBuiltInColors.DIVIDER_DARK)       // 235,235,245 @ 0.60
        assertEquals(0.38f, CYLAnimatedItemBuiltInColors.DISABLED_ALPHA)
        assertEquals(0.6f, CYLAnimatedItemDividerAlpha)
        assertEquals(20f, CYLAnimatedItemDividerLength)
    }

    @Test
    fun builtInsComeFromTheThemeOfTheViewsOwnContext() {
        listOf(false, true).forEach { night ->
            val configuration = configuration(night)
            val themed = CYLAnimatedItemBuiltInColors.themeColor(context, android.R.attr.textColorPrimary)
            if (!night && themed != null) assertEquals(themed, CYLAnimatedItemBuiltInColors.normal(context, configuration))
            val selected = CYLAnimatedItemBuiltInColors.themeColor(context, androidx.appcompat.R.attr.colorPrimary)
                ?: CYLAnimatedItemBuiltInColors.themeColor(context, android.R.attr.colorPrimary)
            if (!night && selected != null) assertEquals(selected, CYLAnimatedItemBuiltInColors.selected(context, configuration))
            val base = CYLAnimatedItemBuiltInColors.normal(context, configuration)
            val disabled = CYLAnimatedItemBuiltInColors.disabled(context, configuration)
            if (themed != null && !night) {
                assertEquals("disabled = primary text at 38% of its alpha", Math.round(Color.alpha(base) * 0.38f), Color.alpha(disabled))
                assertEquals(Color.red(base), Color.red(disabled))
            }
        }
        assertNull("an attribute the theme does not have", CYLAnimatedItemBuiltInColors.themeColor(context, 0))
    }

    @Test
    fun anItemResolvesBuiltInsWithItsOwnNightMode() {
        val item = CYLAnimatedItemView(context)
        listOf(false, true).forEach { night ->
            night(item, night)
            val configuration = item.resources.configuration
            assertEquals(CYLAnimatedItemBuiltInColors.normal(context, configuration), item.resolvedIconColor())
            item.isSelected = true
            assertEquals(CYLAnimatedItemBuiltInColors.selected(context, configuration), item.resolvedIconColor())
            item.isSelected = false
        }
    }

    @Test
    fun theTitleColorFollowsExplicitThenStackThenBuiltIn() {
        val item = CYLAnimatedItemView(context)
        val configuration = item.resources.configuration
        item.isSelected = true
        assertEquals("selected: the built-in selected color", CYLAnimatedItemBuiltInColors.selected(context, configuration), item.titleView.currentTextColor)
        item.isSelected = false
        assertEquals(CYLAnimatedItemBuiltInColors.normal(context, configuration), item.titleView.currentTextColor)
        item.titleColor = Color.YELLOW
        assertEquals(Color.YELLOW, item.titleView.currentTextColor)
        item.isSelected = true
        assertEquals("an explicit title color is kept when selecting", Color.YELLOW, item.titleView.currentTextColor)
        item.titleColor = null
        assertEquals("null resets to the built-in", CYLAnimatedItemBuiltInColors.selected(context, configuration), item.titleView.currentTextColor)
        item.isSelected = false
        item.disabledAlpha = 1f
        item.isEnabled = false
        assertEquals(CYLAnimatedItemBuiltInColors.disabled(context, configuration), item.titleView.currentTextColor)
    }

    // MARK: - Divider contrast 分隔线对比度

    private val white = Color.WHITE
    private val black = Color.BLACK
    private val darkBar = Color.rgb(0x1C, 0x1C, 0x1E)

    @Test
    fun theBuiltInDividerHasAtLeastThreeToOneContrast() {
        assertTrue(CYLAnimatedItemBuiltInColors.contrast(CYLAnimatedItemBuiltInColors.DIVIDER_LIGHT, white).toString(), CYLAnimatedItemBuiltInColors.contrast(CYLAnimatedItemBuiltInColors.DIVIDER_LIGHT, white) >= 3.0)
        assertTrue(CYLAnimatedItemBuiltInColors.contrast(CYLAnimatedItemBuiltInColors.DIVIDER_DARK, black) >= 3.0)
        assertTrue(CYLAnimatedItemBuiltInColors.contrast(CYLAnimatedItemBuiltInColors.DIVIDER_DARK, darkBar) >= 3.0)
        // [EN] The iOS `separator` (60,60,67 @ 0.12) is far below: why it is not the default. [CN] iOS 的 `separator`（60,60,67 @ 0.12）远低于此：所以它不是默认值。
        assertTrue(CYLAnimatedItemBuiltInColors.contrast(Color.argb(31, 60, 60, 67), white) < 1.5)
    }

    @Test
    fun anItemsDividerDefaultIsTheBuiltInAndAnExplicitIconColorIsUsedAtPointSix() {
        val stack = CYLAnimatedItemStackView(context)
        val first = CYLAnimatedItemView(context)
        stack.append(first)
        val divider = stack.dividerViewAfter(first)!!
        listOf(false, true).forEach { night ->
            night(stack, night)
            assertEquals(CYLAnimatedItemBuiltInColors.divider(context, divider.resources.configuration), divider.resolvedDividerColor())
        }
        // explicit icon colors at alpha 0.6 keep >= 3:1 for the usual explicit colors
        stack.iconColor = Color.BLACK
        assertEquals(Color.argb(153, 0, 0, 0), divider.resolvedDividerColor())
        assertTrue(CYLAnimatedItemBuiltInColors.contrast(divider.resolvedDividerColor(), white) >= 3.0)
        stack.iconColor = Color.WHITE
        assertEquals(Color.argb(153, 255, 255, 255), divider.resolvedDividerColor())
        assertTrue(CYLAnimatedItemBuiltInColors.contrast(divider.resolvedDividerColor(), black) >= 3.0)
        assertTrue(CYLAnimatedItemBuiltInColors.contrast(divider.resolvedDividerColor(), darkBar) >= 3.0)
        stack.dividerColor = Color.GREEN
        assertEquals("an explicit dividerColor is used as it is", Color.GREEN, divider.resolvedDividerColor())
    }
}
