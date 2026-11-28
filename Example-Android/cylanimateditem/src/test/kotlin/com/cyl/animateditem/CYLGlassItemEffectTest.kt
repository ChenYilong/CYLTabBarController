package com.cyl.animateditem

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The item glass shared with HarmonyOS (saturation 1.6, brightness 1.05) and the default dark tint of a clear-colour glass item.
 */
@RunWith(RobolectricTestRunner::class)
class CYLGlassItemEffectTest {

    private class RecordingCanvas(bitmap: Bitmap) : Canvas(bitmap) {
        val fills = ArrayList<Int>()
        override fun drawRoundRect(rect: RectF, rx: Float, ry: Float, paint: Paint) {
            fills.add(paint.color)
            super.drawRoundRect(rect, rx, ry, paint)
        }
    }

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    @Test
    fun itemEffectConstantsMatchHarmonyOS() {
        assertEquals(1.6f, CYLLiquidGlass.ITEM_SATURATION, 0f)
        assertEquals(1.05f, CYLLiquidGlass.ITEM_BRIGHTNESS, 0f)
    }

    @Test
    fun glassEffectsDefaultBrightnessIsOne() {
        assertEquals(1f, CYLGlassEffects().brightness, 0f)
        assertEquals(1f, CYLGlassEffects(saturation = 1.5f, blurRadius = 4f).brightness, 0f)
    }

    private fun itemFirstFill(style: CYLAnimatedItemBackgroundStyle): Pair<CYLAnimatedItemView, List<Int>> {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val item = CYLAnimatedItemView(context)
        item.itemBackgroundStyle = style
        item.itemBackgroundColor = android.graphics.Color.TRANSPARENT
        item.layout(0, 0, 200, 80)
        val canvas = RecordingCanvas(Bitmap.createBitmap(200, 80, Bitmap.Config.ARGB_8888))
        (item.itemLiquidGlassView as? CYLLiquidGlassView)?.draw(canvas)
        return item to canvas.fills
    }

    @Test
    @Config(sdk = [34], qualifiers = "night")
    fun aClearColourGlassItemInNightModeFillsWithTheDefaultDarkTint() {
        val (item, fills) = itemFirstFill(CYLAnimatedItemBackgroundStyle.LiquidGlass)
        assertTrue("the glass layer exists", item.itemLiquidGlassView != null)
        assertTrue("a fill was drawn", fills.isNotEmpty())
        assertEquals("white 0.04", 0x0AFFFFFF, fills.first())
    }

    @Test
    @Config(sdk = [34], qualifiers = "night")
    fun aFlatItemHasNoGlassLayerAndDrawsNoGlassFill() {
        val (item, fills) = itemFirstFill(CYLAnimatedItemBackgroundStyle.Flat)
        assertNull("flat: no glass layer", item.itemLiquidGlassView)
        assertTrue("flat: no glass fill", fills.isEmpty())
    }
}
