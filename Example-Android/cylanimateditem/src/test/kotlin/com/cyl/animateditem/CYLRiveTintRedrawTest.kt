package com.cyl.animateditem

import android.content.Context
import android.graphics.Color
import android.view.View
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * [EN] The Rive tab icon with `tint` "title" in light and dark mode: its tint is drawn again on every refresh. The tint lives on rive-android's
 *      inner view (a layer paint) and is lost when that view is created late or reset; a refresh that skipped a color it believed was
 *      already drawn left the icon in the file's own colors (black strokes on a dark bar: invisible), because in light mode the file's colors and
 *      the title color are both dark. Found on the Android example in dark mode (the Flutter search example, `_rive` configuration).
 * [CN] `tint` 为 "title" 的 Rive Tab 图标在浅色与深色模式下：每次刷新都重新绘制着色。着色位于 rive-android 内部视图上（layer paint），该视图
 *      晚创建或被重置时会丢失；跳过自认为已绘制的颜色的刷新会让图标保持文件自身颜色（深色 TabBar 上的黑色描边：看不见），因为浅色模式下文件颜色与
 *      标题颜色都是深色。发现于深色模式下的 Android 示例（Flutter search 示例，`_rive` 配置）。
 */
@RunWith(RobolectricTestRunner::class)
class CYLRiveTintRedrawTest {
    /** [EN] A host that makes the animation view itself, like the tab button. [CN] 自己创建动画视图的宿主，如 Tab 按钮。 */
    private class TabLike(context: Context) : CYLAnimatedItemView(context) {
        fun attach(view: View?) { animationView = view }
    }

    private val context: Context = ApplicationProvider.getApplicationContext()

    /** [EN] The title colors of the example: light label, dark label (iOS secondaryLabel / label), and the selected blue. [CN] 示例的标题颜色。 */
    private val colors = listOf(Color.BLACK, 0xFFEBEBF5.toInt(), 0xFF0091FF.toInt())

    @Test
    fun theTintIsDrawnAgainWhenTheRiveViewLostItsLayer() {
        colors.forEach { color ->
            val inner = View(context)
            val view = CYLRiveTabBarItemAnimationView(context, inner, mapOf("tint" to "title"))
            CYLTabBarItemAnimationTint.applyToAnimationView(view, color)
            assertEquals(View.LAYER_TYPE_HARDWARE, inner.layerType)
            assertEquals(color, view.appliedTintColor)
            // [EN] The inner view is rebuilt or reset: its layer is gone, the color the view remembers is the same. [CN] 内部视图被重建或重置：图层没了，视图记住的颜色相同。
            inner.setLayerType(View.LAYER_TYPE_NONE, null)
            CYLTabBarItemAnimationTint.applyToAnimationView(view, color)
            assertEquals("the tint $color is drawn again", View.LAYER_TYPE_HARDWARE, inner.layerType)
        }
    }

    @Test
    fun anItemRefreshRestoresTheTitleTintOfARiveIcon() {
        colors.forEach { color ->
            val inner = View(context)
            val rive = CYLRiveTabBarItemAnimationView(context, inner, mapOf("tint" to "title"))
            val item = TabLike(context).apply { animationTint = "title"; attach(rive) }
            item.hostIconColor = color
            assertEquals(color, rive.appliedTintColor)
            assertEquals(View.LAYER_TYPE_HARDWARE, inner.layerType)
            inner.setLayerType(View.LAYER_TYPE_NONE, null)
            item.refreshAnimationTint()
            assertEquals("the item refresh draws $color again", View.LAYER_TYPE_HARDWARE, inner.layerType)
        }
    }
}
