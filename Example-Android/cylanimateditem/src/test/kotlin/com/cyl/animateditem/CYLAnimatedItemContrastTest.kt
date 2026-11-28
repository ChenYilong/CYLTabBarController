package com.cyl.animateditem

import android.graphics.Color
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The dark-glass contrast rule (ClassifyMenu's `CYLIconContrast`): the pure function, and the view applying it only where dark glass is drawn.
 */
@RunWith(RobolectricTestRunner::class)
class CYLAnimatedItemContrastTest {

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    private val grey = 0xFF3C3C43.toInt()

    private fun luminance(color: Int) = CYLAnimatedItemContrast.relativeLuminance(
        Color.red(color) / 255.0, Color.green(color) / 255.0, Color.blue(color) / 255.0,
    )

    private fun contrast(color: Int, tint: Int? = null, tintAlpha: Float? = null) =
        CYLAnimatedItemContrast.contrastRatio(luminance(color), CYLAnimatedItemContrast.glassReferenceLuminance(tint, tintAlpha))

    private fun hue(color: Int): Float = CYLAnimatedItemContrast.hslFromRGB(Color.red(color) / 255f, Color.green(color) / 255f, Color.blue(color) / 255f)[0]

    @Test
    fun darkTextOnTheDefaultDarkGlassBecomesLighterAndPasses4Point5() {
        assertTrue(contrast(grey) < 4.5)
        val lifted = CYLAnimatedItemContrast.adjustedTitle(grey, null, null)
        assertTrue(contrast(lifted) >= 4.5)
        assertTrue(luminance(lifted) > luminance(grey))
        assertEquals(0xFF, Color.alpha(lifted))
    }

    @Test
    fun iconTintPassesThreeAndTitleNeedsMore() {
        val dark = 0xFF1B5E63.toInt()
        val icon = CYLAnimatedItemContrast.adjustedIcon(dark, null, null)
        val title = CYLAnimatedItemContrast.adjustedTitle(dark, null, null)
        assertTrue(contrast(icon) >= 3.0)
        assertTrue(contrast(title) >= 4.5)
        assertTrue(luminance(title) >= luminance(icon))
    }

    @Test
    fun aPassingLightColourAndWhiteAreUnchanged() {
        val light = 0xFFE0E0E0.toInt()
        assertEquals(light, CYLAnimatedItemContrast.adjustedTitle(light, null, null))
        assertEquals(Color.WHITE, CYLAnimatedItemContrast.adjustedTitle(Color.WHITE, null, null))
        assertEquals(Color.WHITE, CYLAnimatedItemContrast.adjustedIcon(Color.WHITE, 0xFFFFFFFF.toInt(), 1f))
    }

    @Test
    fun alphaAndHueAreKeptAndTheResultNeverExceedsWhite() {
        val teal = 0x80103A40.toInt()
        val lifted = CYLAnimatedItemContrast.adjustedTitle(teal, null, null)
        assertEquals(0x80, Color.alpha(lifted))
        assertEquals(hue(teal), hue(lifted), 0.02f)
        assertTrue(contrast(lifted) >= 4.5)
        // Black always reaches the target and stays a valid colour.
        val black = CYLAnimatedItemContrast.adjustedTitle(Color.BLACK, null, null)
        assertTrue(contrast(black) >= 4.49)
        assertTrue(Color.red(black) <= 255)
    }

    @Test
    fun deterministic() {
        assertEquals(CYLAnimatedItemContrast.adjustedTitle(grey, null, null), CYLAnimatedItemContrast.adjustedTitle(grey, null, null))
    }

    @Test
    fun anExplicitTintChangesTheReference() {
        val frosted = CYLAnimatedItemContrast.glassReferenceLuminance(null, null)
        assertEquals("alpha 0 is the frosted default", frosted, CYLAnimatedItemContrast.glassReferenceLuminance(0x00FF0000, null), 0.0)
        assertEquals(luminance(0xFF242424.toInt()), frosted, 0.01)
        val bright = 0xFF808080.toInt()
        val reference = CYLAnimatedItemContrast.glassReferenceLuminance(bright, null)
        assertTrue(reference > frosted)
        // 0xFF at 0.75 of alpha 1.0: the colour x 0.75.
        assertEquals(luminance(0xFF606060.toInt()), reference, 0.002)
        assertTrue(CYLAnimatedItemContrast.glassReferenceLuminance(bright, 1f) > reference)
        // The same colour needs a lighter result on the brighter glass.
        assertTrue(luminance(CYLAnimatedItemContrast.adjustedTitle(grey, bright, null)) > luminance(CYLAnimatedItemContrast.adjustedTitle(grey, null, null)))
    }

    private fun glassItem(): CYLAnimatedItemView {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val item = CYLAnimatedItemView(context)
        item.title = "Title"
        item.titleColor = grey
        item.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        item.layout(0, 0, 200, 80)
        return item
    }

    @Test
    @Config(sdk = [34], qualifiers = "night")
    fun glassItemInNightModeLiftsAnExplicitDarkTitleColour() {
        val item = glassItem()
        assertTrue("glass drawn", item.itemLiquidGlassView != null)
        val shown = item.titleView.currentTextColor
        assertTrue(luminance(shown) > luminance(grey))
        assertTrue(contrast(shown) >= 4.5)
        assertEquals("the property keeps the app's colour", grey, item.titleColor)
    }

    @Test
    @Config(sdk = [34])
    fun glassItemInLightModeKeepsTheColour() {
        val item = glassItem()
        assertTrue(item.itemLiquidGlassView != null)
        assertEquals(grey, item.titleView.currentTextColor)
    }

    @Test
    @Config(sdk = [34], qualifiers = "night")
    fun aFlatItemKeepsTheColourInNightMode() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val item = CYLAnimatedItemView(context)
        item.title = "Title"
        item.titleColor = grey
        item.layout(0, 0, 200, 80)
        assertEquals(grey, item.titleView.currentTextColor)
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        item.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        item.layout(0, 0, 200, 80)
        assertEquals("glass style ignored: flat", grey, item.titleView.currentTextColor)
    }
}
