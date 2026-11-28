package com.cyl.animateditem

import android.content.Context
import android.graphics.Color
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
 * The flat-fill contrast rule (iOS `contrastApplies` / `flatReferenceLuminance`, `CYLAnimatedItemColorRoleTests`): in night mode an item that draws a flat fill
 * lifts its colours against that fill over black; flat without a fill, light mode and the disabled look are not adapted.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], qualifiers = "night")
class CYLAnimatedItemFlatContrastTest {

    private val app: Context = ApplicationProvider.getApplicationContext()
    private val grey = 0xFF3C3C43.toInt()
    private val darkFill = 0xFF1C1C1E.toInt()

    private class Tag(context: Context) : CYLAnimatedItemView(context) {
        fun builtInTitle(color: Int?) = applyTitleTintColor(color)
    }

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    private fun luminance(color: Int) = CYLAnimatedItemContrast.relativeLuminance(Color.red(color) / 255.0, Color.green(color) / 255.0, Color.blue(color) / 255.0)

    private fun contrastOn(color: Int, fill: Int) =
        CYLAnimatedItemContrast.contrastRatio(luminance(color), CYLAnimatedItemContrast.flatReferenceLuminance(fill))

    private fun flatItem(fill: Int?, item: CYLAnimatedItemView = CYLAnimatedItemView(app)): CYLAnimatedItemView {
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        item.title = "Title"
        item.titleColor = grey
        item.itemBackgroundColor = fill
        item.layout(0, 0, 200, 80)
        return item
    }

    @Test
    fun theFlatReferenceIsTheFillOverBlack() {
        assertEquals(luminance(darkFill), CYLAnimatedItemContrast.flatReferenceLuminance(darkFill), 1e-9)
        assertEquals("alpha 0 is black", 0.0, CYLAnimatedItemContrast.flatReferenceLuminance(0x00FFFFFF), 1e-9)
        // White at alpha 0.5 is a 0.5 grey: luminance about 0.214.
        assertEquals(0.214, CYLAnimatedItemContrast.flatReferenceLuminance(0x80FFFFFF.toInt()), 0.003)
    }

    @Test
    fun aDarkTitleOnTheDarkFlatFillReaches4Point5() {
        assertTrue("before: about 1.5:1", contrastOn(grey, darkFill) < 2.0)
        val item = flatItem(darkFill)
        assertEquals(darkFill, item.flatFill)
        val shown = item.titleView.currentTextColor
        assertTrue(contrastOn(shown, darkFill) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
        assertEquals("the property keeps the app's colour", grey, item.titleColor)
    }

    @Test
    fun aHalfAlphaWhiteFillCapsAtWhite() {
        val fill = 0x80FFFFFF.toInt()
        val shown = flatItem(fill).titleView.currentTextColor
        assertEquals("lifted as far as white goes", Color.WHITE, shown)
        // [EN] The cap is white's contrast, 1.05 / (L + 0.05): 3.95 for alpha 0x80 (128 / 255), 3.98 for exactly 0.5 (iOS). [CN] 上限为白色的对比度：0x80 时 3.95，恰好 0.5 时 3.98（iOS）。
        val cap = 1.05 / (CYLAnimatedItemContrast.flatReferenceLuminance(fill) + 0.05)
        assertEquals(cap, contrastOn(shown, fill), 1e-9)
        assertEquals(3.95, cap, 0.01)
        assertTrue("4.5 is out of reach", cap < CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
    }

    @Test
    fun aHalfAlphaDarkFillReaches4Point5() {
        val fill = 0x801C1C1E.toInt()
        val shown = flatItem(fill).titleView.currentTextColor
        assertTrue(contrastOn(shown, fill) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
    }

    @Test
    fun aLightFillNeverTurnsAMidGreyTitleWhite() {
        // [EN] On a light fill a lift only lowers contrast: the original (about 3.3:1) is kept, never white (1:1). [CN] 浅色填充上提亮只会降低对比度：保留原色（约 3.3:1），绝不变白（1:1）。
        val white = Color.WHITE
        val midGrey = 0xFF8E8E93.toInt()
        val item = flatItem(white)
        item.titleColor = midGrey
        assertEquals(midGrey, item.titleView.currentTextColor)
        assertEquals(midGrey, CYLAnimatedItemContrast.adjusted(midGrey, CYLAnimatedItemContrast.flatReferenceLuminance(white), CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST))
    }

    @Test
    fun flatWithoutAFillOrWithAClearFillIsNotAdapted() {
        val none = flatItem(null)
        assertNull(none.flatFill)
        assertEquals(grey, none.titleView.currentTextColor)
        val clear = flatItem(Color.TRANSPARENT)
        assertNull(clear.flatFill)
        assertEquals(grey, clear.titleView.currentTextColor)
    }

    @Test
    @Config(sdk = [34], qualifiers = "notnight")
    fun lightModeIsNotAdapted() {
        assertEquals(grey, flatItem(darkFill).titleView.currentTextColor)
    }

    @Test
    fun theDisabledLookIsNotAdapted() {
        val tag = Tag(app)
        flatItem(darkFill, tag)
        tag.titleColor = null
        tag.builtInTitle(grey)
        assertTrue(contrastOn(tag.titleView.currentTextColor, darkFill) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
        tag.isEnabled = false
        assertEquals(grey, tag.titleView.currentTextColor)
    }

    @Test
    fun removingTheFillRestoresTheColour() {
        val item = flatItem(darkFill)
        item.itemBackgroundColor = null
        assertEquals(grey, item.titleView.currentTextColor)
    }

    @Test
    fun thePressedColourIsTheFillWhilePressed() {
        val item = flatItem(null)
        item.itemHighlightedBackgroundColor = darkFill
        assertEquals("not pressed: no fill", grey, item.titleView.currentTextColor)
        item.isPressed = true
        assertEquals(darkFill, item.flatFill)
        assertTrue(contrastOn(item.titleView.currentTextColor, darkFill) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
        item.isPressed = false
        assertEquals(grey, item.titleView.currentTextColor)
    }

    @Test
    fun anExplicitIconColourIsLiftedTo3() {
        val item = flatItem(darkFill)
        item.iconColor = grey
        assertTrue(contrastOn(item.adaptedForContrast(grey, CYLAnimatedItemColorKind.Icon), darkFill) >= CYLAnimatedItemContrast.ICON_MINIMUM_CONTRAST)
    }

    @Test
    fun adaptedOnGlassForwardsToAdaptedForContrast() {
        val item = flatItem(darkFill)
        val lifted = item.adaptedForContrast(grey, CYLAnimatedItemColorKind.Title)
        assertTrue(contrastOn(lifted, darkFill) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
        assertEquals(lifted, item.adaptedOnGlass(grey, CYLAnimatedItemColorKind.Title))
        assertEquals("flat without a fill: as it is", grey, flatItem(null).adaptedForContrast(grey, CYLAnimatedItemColorKind.Title))
    }

    @Test
    fun glassKeepsTheGlassReference() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val item = CYLAnimatedItemView(app)
        item.title = "Title"
        item.titleColor = grey
        item.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        item.itemBackgroundColor = darkFill
        item.layout(0, 0, 200, 80)
        assertNull("glass is not a flat fill", item.flatFill)
        assertEquals(CYLAnimatedItemContrast.adjustedTitle(grey, darkFill, null), item.titleView.currentTextColor)
    }
}
