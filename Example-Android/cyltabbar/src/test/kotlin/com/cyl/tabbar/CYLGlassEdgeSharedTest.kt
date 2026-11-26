package com.cyl.tabbar

import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RectF
import android.view.View
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import com.cyl.animateditem.CYLGlassEdge
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] The Liquid Glass tab bar capsule draws the SAME edge as a tag's glass: the rim colour and the sheen gradient of `CYLGlassEdge`
 *      (one definition for tags, boards and the capsule), in light and in night mode.
 * [CN] 液态玻璃 TabBar 胶囊绘制与标签玻璃相同的边缘：`CYLGlassEdge` 的细边颜色与高光渐变（标签、看板与胶囊共用一个定义），浅色与夜间模式皆然。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLGlassEdgeSharedTest {

    class Page : Fragment()

    private class Drawn(val style: Paint.Style, val color: Int, val strokeWidth: Float, val hasGradient: Boolean)

    private class RecordingCanvas : Canvas() {
        val drawn = mutableListOf<Drawn>()
        private fun record(paint: Paint) {
            // [EN] Robolectric returns a null style for a paint that never set one (the default is FILL). [CN] 从未设置样式的画笔在 Robolectric 中返回 null（默认是 FILL）。
            drawn += Drawn(paint.style ?: Paint.Style.FILL, paint.color, paint.strokeWidth, paint.shader is LinearGradient)
        }
        override fun drawRoundRect(rect: RectF, rx: Float, ry: Float, paint: Paint) = record(paint)
        override fun drawRoundRect(left: Float, top: Float, right: Float, bottom: Float, rx: Float, ry: Float, paint: Paint) = record(paint)
        val strokes get() = drawn.filter { it.style == Paint.Style.STROKE }
        val sheens get() = drawn.filter { it.hasGradient }
    }

    /** [EN] Draws the capsule's style layers (behind and above the items) of a laid out Liquid Glass bar. [CN] 绘制已布局的液态玻璃 TabBar 的样式层（Tab 之后与之上）。 */
    private fun drawCapsule(activity: FragmentActivity): RecordingCanvas {
        val titles = arrayOf("Home", "Message", "Me")
        val controller = CYLTabBarController(activity, titles.map { Page() }, attributes(*titles), CYLEnums.CYLTabBarStyleType.LiquidGlass, null)
        activity.setContentView(controller.view)
        idle()
        controller.view.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(2400, View.MeasureSpec.EXACTLY))
        controller.view.layout(0, 0, 1080, 2400)
        val canvas = RecordingCanvas()
        controller.tabBar.styleRenderer.drawBehindItems(controller.tabBar, canvas)
        controller.tabBar.styleRenderer.drawAboveItems(controller.tabBar, canvas)
        return canvas
    }

    @Test
    fun theCapsuleDrawsTheTagGlassRimAndSheenInLightMode() = withActivity { activity ->
        val canvas = drawCapsule(activity)
        assertTrue("the capsule draws the rim", canvas.strokes.isNotEmpty())
        assertEquals(CYLGlassEdge.rimColor(false), canvas.strokes.last().color)
        assertEquals(CYLGlassEdge.RIM_WIDTH_DP * activity.resources.displayMetrics.density, canvas.strokes.last().strokeWidth, 0.001f)
        assertEquals("one sheen gradient over the capsule", 1, canvas.sheens.size)
        assertTrue("the sheen is drawn before the rim", canvas.drawn.indexOf(canvas.sheens[0]) < canvas.drawn.indexOf(canvas.strokes.last()))
    }

    @Test
    fun theCapsuleDrawsTheTagGlassRimAndSheenInNightMode() = withActivity("night") { activity ->
        val canvas = drawCapsule(activity)
        assertTrue(CYLGlassEdge.isDark(activity.resources))
        assertEquals(CYLGlassEdge.rimColor(true), canvas.strokes.last().color)
        assertEquals(1, canvas.sheens.size)
    }
}
