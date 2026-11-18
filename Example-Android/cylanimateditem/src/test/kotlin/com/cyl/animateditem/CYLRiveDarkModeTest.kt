package com.cyl.animateditem

import android.content.Context
import android.content.res.Configuration
import android.view.View
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * [EN] Rive Dark Mode options, the Android port of the iOS ones (docs/Animated-Item.md, "Rive Dark Mode API in the core"):
 *      `darkTint` gives a fixed tint its night-mode color, and `viewModelInstance` / `darkViewModelInstance` bind the named
 *      view model instance of the current mode, keeping the selected state. A fake rive-android object graph records the
 *      reflection calls.
 * [CN] Rive 深色模式选项，iOS 选项的 Android 移植（docs/Animated-Item.md，"Rive Dark Mode API in the core"）：`darkTint` 为固定着色提供
 *      夜间模式颜色，`viewModelInstance` / `darkViewModelInstance` 绑定当前模式的具名 view model 实例并保持选中状态。伪造的 rive-android 对象
 *      记录反射调用。
 */
@RunWith(RobolectricTestRunner::class)
class CYLRiveDarkModeTest {
    class BooleanProperty { var value: Boolean? = null; fun setValue(newValue: Boolean) { value = newValue } }
    class Instance(val name: String) {
        val active = BooleanProperty()
        fun getBooleanProperty(path: String): BooleanProperty? = if (path == "active") active else null
    }
    class ViewModel {
        val created = mutableMapOf<String, Instance>()
        fun createInstanceFromName(name: String): Instance? =
            if (name == "Light" || name == "Dark") created.getOrPut(name) { Instance(name) } else null
        fun createDefaultInstance() = created.getOrPut("") { Instance("") }
    }
    class Artboard
    class File(private val viewModel: ViewModel) { fun defaultViewModelForArtboard(artboard: Artboard) = viewModel }
    class Machine { var bound: Instance? = null; fun setViewModelInstance(instance: Instance) { bound = instance } }
    class Controller(val file: File, val artboard: Artboard, val machines: List<Machine>) {
        fun getFile() = file
        fun getActiveArtboard() = artboard
        fun getStateMachines() = machines
    }
    class FakeRive(context: Context, private val controller: Controller) : View(context) {
        fun getController() = controller
    }

    private val context: Context = ApplicationProvider.getApplicationContext()
    private fun configuration(night: Boolean) = Configuration(context.resources.configuration).apply {
        uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
            (if (night) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO)
    }

    @Test
    fun darkTintIsTheNightColorOfAFixedTint() {
        val view = CYLRiveTabBarItemAnimationView(context, View(context), mapOf("tint" to "#1C1C1E", "darkTint" to "#FFFFFF"))
        assertEquals(android.graphics.Color.parseColor("#1C1C1E"), view.fixedTintColor(configuration(night = false)))
        assertEquals(android.graphics.Color.WHITE, view.fixedTintColor(configuration(night = true)))
        val title = CYLRiveTabBarItemAnimationView(context, View(context), mapOf("tint" to "title", "darkTint" to "#FFFFFF"))
        // [EN] "title" follows the title colors; darkTint only applies to a fixed tint. [CN] "title" 跟随标题颜色；darkTint 只用于固定着色。
        assertNull(title.fixedTintColor(configuration(night = true)))
        assertNull(title.fixedTintColor(configuration(night = false)))
    }

    @Test
    fun theThemeInstanceFollowsNightModeAndKeepsTheSelection() {
        val viewModel = ViewModel()
        val machine = Machine()
        val rive = FakeRive(context, Controller(File(viewModel), Artboard(), listOf(machine)))
        val view = CYLRiveTabBarItemAnimationView(context, rive,
            mapOf("viewModelInstance" to "Light", "darkViewModelInstance" to "Dark"))
        view.cyl_bindThemeInstance(configuration(night = false))
        assertEquals("Light", machine.bound?.name)
        view.cyl_showAnimationViewLastFrame()
        view.cyl_bindThemeInstance(configuration(night = true))
        assertEquals("Dark", machine.bound?.name)
        assertEquals(true, viewModel.created["Dark"]?.active?.value)
        view.cyl_bindThemeInstance(configuration(night = false))
        assertSame(viewModel.created["Light"], machine.bound)
    }

    @Test
    fun withoutTheOptionsNothingIsBound() {
        val machine = Machine()
        val rive = FakeRive(context, Controller(File(ViewModel()), Artboard(), listOf(machine)))
        val view = CYLRiveTabBarItemAnimationView(context, rive, emptyMap())
        view.cyl_bindThemeInstance(configuration(night = true))
        assertNull(machine.bound)
        assertNull(view.boundThemeInstance)
    }
}
