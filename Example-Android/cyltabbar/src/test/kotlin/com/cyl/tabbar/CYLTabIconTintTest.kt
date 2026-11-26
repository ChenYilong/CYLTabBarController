package com.cyl.tabbar

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.drawable.BitmapDrawable
import androidx.fragment.app.Fragment
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] A tinted tab icon is drawn in the FULL tint color. `SRC_IN` keeps the source alpha, so an asset whose most opaque pixel is 62 percent
 *      opaque (the platform's `ic_menu_*` icons are 60 percent) used to give a washed-out selected icon. The filter now scales the alpha so
 *      that the most opaque pixel is opaque; an opaque asset keeps the plain filter; the original mode stays untinted.
 * [CN] 着色的 Tab 图标以完整的着色颜色绘制。`SRC_IN` 保留源图 alpha，最不透明像素只有 62% 不透明的图片（平台 `ic_menu_*` 图标为 60%）以前会使选中图标发白。
 *      现在滤镜缩放 alpha，使最不透明的像素不透明；已经不透明的图片保持普通滤镜；original 模式仍不着色。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLTabIconTintTest {
    class Page : Fragment()

    private val selectedTint = 0xFFFF9500.toInt()
    private val unselectedTint = 0xFF34C759.toInt()

    private fun asset(alpha: Int) = BitmapDrawable(Bitmap.createBitmap(24, 24, Bitmap.Config.ARGB_8888).apply { eraseColor(Color.argb(alpha, 40, 40, 40)) })

    private fun controller(activity: androidx.fragment.app.FragmentActivity, alpha: Int, extra: Map<String, Any?>): CYLTabBarController {
        val tabs = listOf("A", "B").map { mapOf(CYLConstants.CYLTabBarItemTitle to it, CYLConstants.CYLTabBarItemImage to asset(alpha)) + extra }
        val controller = CYLTabBarController(activity, listOf(Page(), Page()), tabs, CYLEnums.CYLTabBarStyleType.FlatDesign, null)
        activity.setContentView(controller.view)
        idle()
        controller.tabBar.selectedTintColor = selectedTint
        controller.tabBar.unselectedTintColor = unselectedTint
        idle()
        return controller
    }

    /** [EN] The constant RGB and the alpha scale of a matrix filter. [CN] 矩阵滤镜的固定 RGB 与 alpha 缩放。 */
    private fun parts(filter: android.graphics.ColorFilter?): FloatArray {
        assertTrue("a ColorMatrixColorFilter, was $filter", filter is ColorMatrixColorFilter)
        val matrix = ColorMatrix()
        (filter as ColorMatrixColorFilter).getColorMatrix(matrix)
        val a = matrix.array
        return floatArrayOf(a[4], a[9], a[14], a[18])
    }

    private fun assertFull(color: Int, filter: android.graphics.ColorFilter?, alpha: Int) {
        val p = parts(filter)
        assertEquals(Color.red(color).toFloat(), p[0], 0.01f)
        assertEquals(Color.green(color).toFloat(), p[1], 0.01f)
        assertEquals(Color.blue(color).toFloat(), p[2], 0.01f)
        assertEquals("the alpha scale turns the most opaque pixel into 255", 255f, alpha * p[3], 0.5f)
    }

    @Test
    fun aTranslucentTemplateIconIsDrawnInTheFullBarTints() = withActivity { activity ->
        val controller = controller(activity, 158, mapOf(CYLConstants.CYLTabBarItemIconRenderingMode to "template"))
        val buttons = controller.tabBar.tabBarButtonArray
        assertFull(selectedTint, buttons[0].iconView.colorFilter, 158)
        assertFull(unselectedTint, buttons[1].iconView.colorFilter, 158)
        buttons[1].performClick()
        idle()
        assertFull(selectedTint, buttons[1].iconView.colorFilter, 158)
        assertFull(unselectedTint, buttons[0].iconView.colorFilter, 158)
    }

    @Test
    fun aTranslucentIconWithAnExplicitIconColorIsDrawnInTheFullColor() = withActivity { activity ->
        val controller = controller(activity, 153, mapOf(CYLConstants.CYLTabBarItemIconRenderingMode to "template", CYLConstants.CYLTabBarItemSelectedIconColor to "#FF3B30"))
        assertFull(0xFFFF3B30.toInt(), controller.tabBar.tabBarButtonArray[0].iconView.colorFilter, 153)
        val unset = controller(activity, 153, mapOf(CYLConstants.CYLTabBarItemSelectedIconColor to "#FF3B30"))
        assertFull(0xFFFF3B30.toInt(), unset.tabBar.tabBarButtonArray[0].iconView.colorFilter, 153)
        assertNull("the unset mode leaves the unselected icon untinted", unset.tabBar.tabBarButtonArray[1].iconView.colorFilter)
    }

    @Test
    fun anOpaqueAssetKeepsThePlainFilterAndOriginalStaysUntinted() = withActivity { activity ->
        val opaque = controller(activity, 255, mapOf(CYLConstants.CYLTabBarItemIconRenderingMode to "template"))
        assertEquals(PorterDuffColorFilter(selectedTint, PorterDuff.Mode.SRC_IN), opaque.tabBar.tabBarButtonArray[0].iconView.colorFilter)
        assertEquals(PorterDuffColorFilter(unselectedTint, PorterDuff.Mode.SRC_IN), opaque.tabBar.tabBarButtonArray[1].iconView.colorFilter)
        val original = controller(activity, 158, mapOf(CYLConstants.CYLTabBarItemIconRenderingMode to "original"))
        original.tabBar.tabBarButtonArray.forEach { assertNull(it.iconView.colorFilter) }
    }

    @Test
    fun theMaximumAlphaIsMeasuredFromThePixels() {
        assertEquals(158, CYLTabIconTint.maxAlpha(asset(158)))
        assertEquals(255, CYLTabIconTint.maxAlpha(asset(255)))
        assertEquals(0, CYLTabIconTint.maxAlpha(asset(0)))
    }

    /** [EN] A tint filter of this color, plain or alpha-normalised. [CN] 该颜色的着色滤镜，普通或 alpha 归一后的。 */
    private fun assertTint(color: Int, filter: android.graphics.ColorFilter?, what: String) {
        if (filter is ColorMatrixColorFilter) {
            val p = parts(filter)
            assertEquals(what, color, Color.rgb(p[0].toInt(), p[1].toInt(), p[2].toInt()))
        } else assertEquals(what, PorterDuffColorFilter(color, PorterDuff.Mode.SRC_IN), filter)
    }

    /**
     * [EN] The "More" button's own glyph takes the bar's tints: selected while its list shows, unselected otherwise (it stayed black before).
     * [CN] 「更多」按钮自带的图标使用 TabBar 的着色：其列表显示时为选中色，否则为未选中色（以前一直是黑色）。
     */
    @Test
    fun theMoreIconTakesTheBarTints() = withActivity { activity ->
        val titles = listOf("A", "B", "C", "D", "E", "F", "G")
        val tabs = titles.map { mapOf(CYLConstants.CYLTabBarItemTitle to it, CYLConstants.CYLTabBarItemImage to asset(255)) }
        val controller = CYLTabBarController(activity, titles.map { Page() }, tabs, CYLEnums.CYLTabBarStyleType.FlatDesign, null)
        activity.setContentView(controller.view)
        idle()
        controller.tabBar.selectedTintColor = selectedTint
        controller.tabBar.unselectedTintColor = unselectedTint
        idle()
        val more = controller.tabBar.cyl_moreButton!!
        assertTint(unselectedTint, more.iconView.colorFilter, "unselected More")
        more.performClick()
        idle()
        assertTrue(controller.cyl_isMoreSelected)
        assertTint(selectedTint, more.iconView.colorFilter, "selected More")
    }
}
