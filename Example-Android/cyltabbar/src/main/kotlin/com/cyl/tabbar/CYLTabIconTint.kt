package com.cyl.tabbar

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import androidx.annotation.ColorInt
import java.util.WeakHashMap

/**
 * [EN] The color filter of a tinted tab icon. `SRC_IN` keeps the alpha of the SOURCE, so an icon asset whose most opaque pixel is only
 *      60 percent opaque (the Android platform's `ic_menu_*` icons have a maximum alpha of 153 of 255) would be drawn in a translucent
 *      tint, washed out in light mode and dim in dark mode. A tinted icon is drawn in the FULL tint color: the filter paints the constant
 *      RGB of the tint and scales the alpha of the asset by 255 / maxAlpha, so that its most opaque pixel becomes fully opaque (the
 *      tint's own alpha is kept). The maximum alpha is measured once per image (the pixels of a bitmap, a small render of any other
 *      drawable) and cached; an icon that is already opaque, or whose alpha cannot be measured, gets the plain `SRC_IN` filter.
 * [CN] 着色图标的颜色滤镜。`SRC_IN` 保留源图的 alpha，所以最不透明像素也只有 60% 不透明的图标资源（Android 平台的 `ic_menu_*` 图标最大 alpha 为 153/255）
 *      会以半透明着色绘制：浅色模式发白，深色模式发暗。着色图标以完整的着色颜色绘制：滤镜绘制着色的固定 RGB，并把图标的 alpha 乘以 255 / maxAlpha，
 *      使最不透明的像素完全不透明（保留着色自身的 alpha）。每张图只测量一次最大 alpha（位图读取像素，其他 drawable 渲染成小位图）并缓存；
 *      已经不透明或无法测量的图标使用普通的 `SRC_IN` 滤镜。
 */
internal object CYLTabIconTint {
    private const val RENDER_SIZE = 64
    private val bitmapAlpha = WeakHashMap<Bitmap, Int>()

    /**
     * [EN] The filter that draws `drawable` in `color`. [CN] 以 `color` 绘制 `drawable` 的滤镜。
     */
    fun filter(drawable: Drawable?, @ColorInt color: Int): ColorFilter {
        val maxAlpha = drawable?.let { maxAlpha(it) } ?: 0
        if (maxAlpha <= 0 || maxAlpha >= 250) return PorterDuffColorFilter(color, PorterDuff.Mode.SRC_IN)
        val scale = (color ushr 24) / 255f * 255f / maxAlpha
        val rgba = floatArrayOf(
            0f, 0f, 0f, 0f, ((color shr 16) and 0xFF).toFloat(),
            0f, 0f, 0f, 0f, ((color shr 8) and 0xFF).toFloat(),
            0f, 0f, 0f, 0f, (color and 0xFF).toFloat(),
            0f, 0f, 0f, scale, 0f)
        return ColorMatrixColorFilter(ColorMatrix(rgba))
    }

    /**
     * [EN] The most opaque alpha (0 to 255) of the drawable's pixels; 0 when it cannot be measured or the image is empty.
     * [CN] drawable 像素中最大的 alpha（0 到 255）；无法测量或图片为空时为 0。
     */
    internal fun maxAlpha(drawable: Drawable): Int {
        val bitmap = (drawable as? BitmapDrawable)?.bitmap
        if (bitmap != null) {
            synchronized(bitmapAlpha) { bitmapAlpha[bitmap] }?.let { return it }
            val measured = runCatching { measure(bitmap) }.getOrDefault(0)
            synchronized(bitmapAlpha) { bitmapAlpha[bitmap] = measured }
            return measured
        }
        return runCatching {
            val copy = drawable.constantState?.newDrawable()?.mutate() ?: return 0
            val render = Bitmap.createBitmap(RENDER_SIZE, RENDER_SIZE, Bitmap.Config.ARGB_8888)
            copy.setBounds(0, 0, RENDER_SIZE, RENDER_SIZE)
            copy.draw(Canvas(render))
            measure(render).also { render.recycle() }
        }.getOrDefault(0)
    }

    private fun measure(bitmap: Bitmap): Int {
        if (!bitmap.hasAlpha()) return 255
        val width = bitmap.width
        val height = bitmap.height
        val pixels = IntArray(width * height)
        val source = if (android.os.Build.VERSION.SDK_INT >= 26 && bitmap.config == Bitmap.Config.HARDWARE) bitmap.copy(Bitmap.Config.ARGB_8888, false) ?: return 0 else bitmap
        source.getPixels(pixels, 0, width, 0, 0, width, height)
        var max = 0
        for (pixel in pixels) { val alpha = pixel ushr 24; if (alpha > max) max = alpha }
        return max
    }
}
