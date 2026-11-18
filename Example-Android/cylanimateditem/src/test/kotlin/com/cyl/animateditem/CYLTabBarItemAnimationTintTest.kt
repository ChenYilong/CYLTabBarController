package com.cyl.animateditem

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.util.Base64
import android.view.View
import android.widget.ImageView
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import java.io.File

/**
 * [EN] The `tint` / `darkTint` options for every engine (`CYLTabBarItemAnimationTint`), the Android port of the iOS
 *      overlay (docs/Animated-Item.md, dark mode and tint for every engine). A GIF stands for every engine without a
 *      tint of its own: the factory draws a fixed tint at once, "title" follows the player's `tintColor`, `darkTint` is
 *      the night color, and a file without options is never tinted.
 * [CN] 所有引擎的 `tint` / `darkTint` 选项（`CYLTabBarItemAnimationTint`），iOS 覆盖层的 Android 移植（docs/Animated-Item.md，所有引擎的深色模式与
 *      着色）。GIF 代表所有没有自身着色的引擎：工厂立即绘制固定着色，"title" 跟随播放器的 `tintColor`，`darkTint` 是夜间颜色，没有选项的文件不着色。
 */
@RunWith(RobolectricTestRunner::class)
class CYLTabBarItemAnimationTintTest {
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val factory = CYLTabBarItemAnimationFactory(CYLTabBarItemAnimatorRegistry().apply { registerAnimator(CYLGIFTabBarItemAnimator.animator) })
    private val gif: String by lazy {
        File.createTempFile("cyl-tint", ".gif").apply { writeBytes(Base64.decode(CYLGIFDecoderTestData.THREE_FRAMES, Base64.DEFAULT)); deleteOnExit() }.absolutePath
    }

    private fun view(options: Map<CYLTabBarAnimationOption, String>?): View =
        factory.animationViewWithURL(context, CYLTabBarAnimationURLWithOptions(gif, options)!!, CYLSize(24f, 24f), ImageView.ScaleType.FIT_CENTER)!!

    private fun configuration(night: Boolean) = Configuration(context.resources.configuration).apply {
        uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
            (if (night) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO)
    }

    @Test
    fun aFixedTintIsDrawnWhenTheViewIsMade() {
        val view = view(mapOf(CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionTint to "#1C1C1E"))
        assertEquals(Color.parseColor("#1C1C1E"), CYLTabBarItemAnimationTint.appliedColor(view))
        assertEquals(View.LAYER_TYPE_HARDWARE, view.layerType)
    }

    @Test
    fun titleFollowsThePlayersTintColor() {
        val view = view(mapOf(CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionTint to "title"))
        assertNull("no title color yet", CYLTabBarItemAnimationTint.appliedColor(view))
        val player = factory.playerForView(view)
        assertNotNull(player)
        player!!.tintColor = Color.RED
        assertEquals(Color.RED, CYLTabBarItemAnimationTint.appliedColor(view))
        player.tintColor = Color.BLUE
        assertEquals(Color.BLUE, CYLTabBarItemAnimationTint.appliedColor(view))
        // [EN] The engine's own player still plays the view. [CN] 引擎自己的播放器仍然播放该视图。
        player.play()
        assertTrue((view as CYLGIFTabBarItemAnimationView).isPlaying)
    }

    @Test
    fun darkTintIsTheNightColorOfAFixedTint() {
        val view = view(mapOf(CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionTint to "#1C1C1E", CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionDarkTint to "#FFFFFF"))
        val player = factory.playerForView(view)!!
        player.applyColors(null, configuration(night = true))
        assertEquals(Color.WHITE, CYLTabBarItemAnimationTint.appliedColor(view))
        player.applyColors(null, configuration(night = false))
        assertEquals(Color.parseColor("#1C1C1E"), CYLTabBarItemAnimationTint.appliedColor(view))
        // [EN] A title color does not replace a fixed tint. [CN] 标题颜色不会替换固定着色。
        player.tintColor = Color.RED
        assertEquals(Color.parseColor("#1C1C1E"), CYLTabBarItemAnimationTint.appliedColor(view))
    }

    @Test
    fun withoutOptionsNothingIsTinted() {
        val view = view(null)
        factory.playerForView(view)!!.tintColor = Color.RED
        assertNull(CYLTabBarItemAnimationTint.appliedColor(view))
        assertEquals(View.LAYER_TYPE_NONE, view.layerType)
    }
}
