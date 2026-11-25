package com.cyl.animateditem

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
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
 * [EN] `CYLAnimatedItemView.animationTint` / `animationDarkTint`, the Android counterpart of iOS `animationTint`: unset keeps the
 *      file's colors, "title" draws in the icon color (the selected one while selected), a fixed color colors only the unselected
 *      item with `animationDarkTint` at night, the property replaces the source URL's option, and it works after the file loaded.
 *      A GIF stands for every engine (the tint is a color filter on the animation view's layer, not an engine API).
 * [CN] `CYLAnimatedItemView.animationTint` / `animationDarkTint`，iOS `animationTint` 的 Android 对应：未设置时保持文件颜色，"title" 以图标颜色
 *      绘制（选中时为选中颜色），固定颜色只为未选中的条目着色且夜间使用 `animationDarkTint`，属性替换来源 URL 中的选项，文件加载后设置同样有效。
 *      GIF 代表所有引擎（着色是动画视图图层上的颜色滤镜，而不是引擎 API）。
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
