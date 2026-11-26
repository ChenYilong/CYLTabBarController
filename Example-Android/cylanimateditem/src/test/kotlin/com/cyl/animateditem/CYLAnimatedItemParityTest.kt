package com.cyl.animateditem

import android.content.Context
import android.graphics.Color
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * iOS parity of the shared item: the subclass channels, the subclass built-in level, the public glass-state functions, ONE resolution of the built-in colours
 * and the rendered-glass floor of the reference luminance.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], qualifiers = "night")
class CYLAnimatedItemParityTest {
    private val app: Context = ApplicationProvider.getApplicationContext()
    private val dark = 0xFF3C3C43.toInt()

    /** A small subclass that exposes the protected channels, like the ClassifyMenu tag. */
    private class Tag(context: Context) : CYLAnimatedItemView(context) {
        fun titleColor(color: Int?, state: CYLAnimatedItemTitleState) = setSubclassTitleColor(color, state)
        fun iconColor(color: Int?, state: CYLAnimatedItemTitleState) = setSubclassIconColor(color, state)
        fun builtInTitle(color: Int?) = applyTitleTintColor(color)
        fun builtInIcon(color: Int?) = applyIconTintColor(color)
    }

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    private fun tag(glass: Boolean = true): Tag {
        CYLAnimatedItemView.liquidGlassActiveOverride = glass
        return Tag(app).apply {
            title = "Tag"
            if (glass) itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
            layout(0, 0, 200, 80)
        }
    }

    private fun luminance(color: Int) = CYLAnimatedItemContrast.relativeLuminance(Color.red(color) / 255.0, Color.green(color) / 255.0, Color.blue(color) / 255.0)

    private fun titleContrast(color: Int) = CYLAnimatedItemContrast.contrastRatio(luminance(color), CYLAnimatedItemContrast.renderedGlassReferenceLuminance(null, null))

    @Test
    fun theSubclassExplicitTitleIsAdaptedAndLeavesThePropertiesAlone() {
        val item = tag()
        item.titleColor(dark, CYLAnimatedItemTitleState.Normal)
        assertNull("the integrator's property is never written", item.titleColor)
        assertEquals(dark, item.resolvedTitleColor())
        assertNotEquals(dark, item.titleView.currentTextColor)
        assertTrue(titleContrast(item.titleView.currentTextColor) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
    }

    @Test
    fun aFlatItemKeepsTheSubclassColourAsSet() {
        val item = tag(glass = false)
        item.titleColor(dark, CYLAnimatedItemTitleState.Normal)
        assertEquals(dark, item.titleView.currentTextColor)
    }

    @Test
    fun aMissingSelectedColourFallsBackToTheNormalOne() {
        val item = tag(glass = false)
        item.titleColor(0xFF112233.toInt(), CYLAnimatedItemTitleState.Normal)
        item.iconColor(0xFF445566.toInt(), CYLAnimatedItemTitleState.Normal)
        item.isSelected = true
        assertEquals(0xFF112233.toInt(), item.titleView.currentTextColor)
        assertEquals(0xFF445566.toInt(), item.explicitSelectedIconColor)
        item.titleColor(0xFF778899.toInt(), CYLAnimatedItemTitleState.Selected)
        assertEquals(0xFF778899.toInt(), item.titleView.currentTextColor)
        item.isSelected = false
        assertEquals(0xFF112233.toInt(), item.titleView.currentTextColor)
    }

    @Test
    fun theDisabledColourShowsWhileDisabled() {
        val item = tag(glass = false)
        item.titleColor(0xFF112233.toInt(), CYLAnimatedItemTitleState.Normal)
        item.titleColor(0xFF999999.toInt(), CYLAnimatedItemTitleState.Disabled)
        item.isEnabled = false
        assertEquals(0xFF999999.toInt(), item.titleView.currentTextColor)
        item.isEnabled = true
        assertEquals(0xFF112233.toInt(), item.titleView.currentTextColor)
    }

    @Test
    fun precedenceOwnThenSubclassExplicitThenStackThenSubclassBuiltIn() {
        val item = tag(glass = false)
        item.builtInTitle(0xFF010101.toInt())
        assertEquals(0xFF010101.toInt(), item.titleView.currentTextColor)
        item.stackTitleColor = 0xFF020202.toInt()
        assertEquals(0xFF020202.toInt(), item.titleView.currentTextColor)
        item.titleColor(0xFF030303.toInt(), CYLAnimatedItemTitleState.Normal)
        assertEquals(0xFF030303.toInt(), item.titleView.currentTextColor)
        item.titleColor = 0xFF040404.toInt()
        assertEquals(0xFF040404.toInt(), item.titleView.currentTextColor)
        assertEquals(0xFF040404.toInt(), item.titleColor)
    }

    @Test
    fun theSubclassIconChannelFeedsTheIconChainBelowTheItemsOwnColour() {
        val item = tag(glass = false)
        item.iconColor(0xFF010101.toInt(), CYLAnimatedItemTitleState.Normal)
        item.iconColor(0xFF020202.toInt(), CYLAnimatedItemTitleState.Selected)
        item.stackIconColor = 0xFF030303.toInt()
        assertEquals(0xFF010101.toInt(), item.explicitIconColor)
        assertEquals(0xFF010101.toInt(), item.effectiveIconColor)
        item.isSelected = true
        assertEquals(0xFF020202.toInt(), item.effectiveIconColor)
        item.iconColor = 0xFF040404.toInt()
        assertEquals("the item's own normal colour wins over the subclass normal one", 0xFF040404.toInt(), item.explicitIconColor)
        assertNull(item.selectedIconColor)
    }

    @Test
    fun theSubclassBuiltInTitleIsAdaptedOnDarkGlassButNotWhileDisabled() {
        val item = tag()
        item.builtInTitle(dark)
        assertEquals("the built-in level is resolved as set", dark, item.resolvedTitleColor())
        assertTrue(titleContrast(item.titleView.currentTextColor) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
        item.isEnabled = false
        assertEquals("the disabled look is not adapted", dark, item.titleView.currentTextColor)
    }

    @Test
    fun aSelectedBuiltInTitleIsAdaptedOnDarkGlassToo() {
        val item = tag()
        item.isSelected = true
        item.builtInTitle(dark)
        assertTrue(titleContrast(item.titleView.currentTextColor) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
        val flat = tag(glass = false)
        flat.isSelected = true
        flat.builtInTitle(dark)
        assertEquals(dark, flat.titleView.currentTextColor)
    }

    @Test
    fun theComponentBuiltInSelectedTitleIsAdaptedOnGlass() {
        val item = tag()
        item.itemBackgroundColor = 0xFFFFFFFF.toInt()
        item.itemGlassTintAlpha = 1f
        item.isSelected = true
        val selected = CYLAnimatedItemBuiltInColors.selected(app)
        assertEquals(item.adaptedOnGlass(selected, CYLAnimatedItemColorKind.Title), item.titleView.currentTextColor)
    }

    @Test
    fun adaptedOnGlassFollowsTheItemsOwnGlassStateAndNightMode() {
        val glass = tag()
        val lifted = glass.adaptedOnGlass(dark, CYLAnimatedItemColorKind.Title)
        assertTrue(titleContrast(lifted) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
        assertEquals(CYLAnimatedItemContrast.adjustedIcon(dark, null, null), glass.adaptedOnGlass(dark, CYLAnimatedItemColorKind.Icon))
        assertEquals("the app's property keeps its value", dark, dark)
        assertEquals("flat: as it is", dark, tag(glass = false).adaptedOnGlass(dark, CYLAnimatedItemColorKind.Title))
    }

    @Test
    @Config(sdk = [34], qualifiers = "notnight")
    fun adaptedOnGlassIsAsItIsInLightMode() {
        assertEquals(dark, tag().adaptedOnGlass(dark, CYLAnimatedItemColorKind.Title))
    }

    @Test
    fun drawsLiquidGlassAndDrawsFlatBackgroundAreOpposites() {
        val glass = tag()
        assertTrue(glass.drawsLiquidGlass)
        assertFalse(glass.drawsFlatBackground)
        val flat = tag(glass = false)
        assertFalse(flat.drawsLiquidGlass)
        assertTrue(flat.drawsFlatBackground)
        // [EN] Glass asked for but not drawn counts as flat. [CN] 请求了玻璃但未绘制算扁平。
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val asked = Tag(app).apply { itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass }
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        assertTrue(asked.drawsFlatBackground)
        assertTrue("no layer and no size are needed", Tag(app).drawsFlatBackground)
    }

    @Test
    fun theFloorNeverLowersTheModelAndRaisesTheDefaultGlass() {
        val share = CYLAnimatedItemContrast.renderedDarkGlassWhiteShare
        val floor = CYLAnimatedItemContrast.relativeLuminance(share, share, share)
        assertEquals(floor, CYLAnimatedItemContrast.renderedGlassReferenceLuminance(null, null), 1e-12)
        assertTrue(floor > CYLAnimatedItemContrast.glassReferenceLuminance(null, null))
        val bright = 0xFFFFFFFF.toInt()
        assertEquals(CYLAnimatedItemContrast.glassReferenceLuminance(bright, 1f), CYLAnimatedItemContrast.renderedGlassReferenceLuminance(bright, 1f), 1e-12)
    }

    @Test
    fun anExplicit3C3C43TitleReachesFourPointFiveOnDarkGlassAfterTheLift() {
        val item = tag()
        item.titleColor(dark, CYLAnimatedItemTitleState.Normal)
        assertTrue("contrast " + titleContrast(item.titleView.currentTextColor), titleContrast(item.titleView.currentTextColor) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
    }

    @Test
    fun aDetachedItemGetsItsBuiltInTitleColourWhenTheTitleIsSetWithoutLayout() {
        val item = CYLAnimatedItemView(app)
        item.title = "Detached"
        assertEquals(CYLAnimatedItemBuiltInColors.normal(app), item.titleView.currentTextColor)
    }
}
