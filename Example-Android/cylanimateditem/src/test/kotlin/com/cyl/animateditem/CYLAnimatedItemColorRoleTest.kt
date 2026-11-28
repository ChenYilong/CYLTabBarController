package com.cyl.animateditem

import android.content.Context
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
 * The colour-role registry (iOS `CYLAnimatedItemColorRoleTests`): a subclass role follows subclass-explicit > subclass built-in > component built-in, gets the one
 * contrast step by its kind, and is re-applied on state, configuration and background changes; `title` / `icon` keep today's chain through the new names.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], qualifiers = "night")
class CYLAnimatedItemColorRoleTest {

    private val app: Context = ApplicationProvider.getApplicationContext()
    private val grey = 0xFF3C3C43.toInt()
    private val darkFill = 0xFF1C1C1E.toInt()
    private val red = 0xFFFF0000.toInt()
    private val blue = 0xFF0000FF.toInt()

    /** A tag with a delete-indicator label as its own role (like ClassifyMenu's `CYLTagButton`). */
    private class Tag(context: Context, builtIn: Int? = null) : CYLAnimatedItemView(context) {
        var shown: CYLAnimatedItemResolvedColor? = null
        var applyCount = 0
        val cross = CYLAnimatedItemColorRole("deleteIndicator", CYLAnimatedItemColorKind.Title, componentBuiltIn = builtIn?.let { c -> { _: CYLAnimatedItemView, _: CYLAnimatedItemTitleState -> c } }) { item, resolved ->
            (item as Tag).shown = resolved
            item.applyCount++
        }

        init { register(cross) }

        fun crossColor(color: Int?, state: CYLAnimatedItemTitleState) = setSubclassColor(color, state, cross)
        fun crossBuiltIn(color: Int?) = applyBuiltInColor(color, cross)
        fun titleColor(color: Int?, state: CYLAnimatedItemTitleState) = setSubclassColor(color, state, CYLAnimatedItemColorRole.title)
        fun builtIn(color: Int?, role: CYLAnimatedItemColorRole) = applyBuiltInColor(color, role)
        fun registerAgain(role: CYLAnimatedItemColorRole) = register(role)
    }

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    private fun luminance(color: Int) = CYLAnimatedItemContrast.relativeLuminance(Color.red(color) / 255.0, Color.green(color) / 255.0, Color.blue(color) / 255.0)

    private fun contrastOnDarkFill(color: Int) = CYLAnimatedItemContrast.contrastRatio(luminance(color), CYLAnimatedItemContrast.flatReferenceLuminance(darkFill))

    private fun tag(builtIn: Int? = null): Tag {
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        return Tag(app, builtIn).apply { title = "Tag"; layout(0, 0, 200, 80) }
    }

    @Test
    fun registeringAppliesOnceAndAnUnsetRoleIsNone() {
        val tag = tag()
        assertEquals(CYLAnimatedItemResolvedColor(null, CYLAnimatedItemColorLevel.None), tag.shown)
        assertTrue(tag.applyCount >= 1)
    }

    @Test
    fun thePrecedenceIsExplicitThenSubclassBuiltInThenComponentBuiltIn() {
        val tag = tag(builtIn = blue)
        assertEquals(CYLAnimatedItemResolvedColor(blue, CYLAnimatedItemColorLevel.ComponentBuiltIn), tag.shown)
        tag.crossBuiltIn(red)
        assertEquals(CYLAnimatedItemResolvedColor(red, CYLAnimatedItemColorLevel.SubclassBuiltIn), tag.shown)
        tag.crossColor(grey, CYLAnimatedItemTitleState.Normal)
        assertEquals(CYLAnimatedItemResolvedColor(grey, CYLAnimatedItemColorLevel.Explicit), tag.shown)
        tag.crossColor(null, CYLAnimatedItemTitleState.Normal)
        assertEquals(red, tag.shown?.color)
        tag.crossBuiltIn(null)
        assertEquals(blue, tag.shown?.color)
    }

    @Test
    fun aMissingSelectedColourFallsBackToNormalAndSelectionReapplies() {
        val tag = tag()
        tag.crossColor(grey, CYLAnimatedItemTitleState.Normal)
        tag.isSelected = true
        assertEquals("fallback", grey, tag.shown?.color)
        tag.crossColor(red, CYLAnimatedItemTitleState.Selected)
        assertEquals(red, tag.shown?.color)
        tag.isSelected = false
        assertEquals(grey, tag.shown?.color)
    }

    @Test
    fun theRoleIsAdaptedByItsKindOnAFlatFillAndReappliedWhenTheFillChanges() {
        val tag = tag()
        tag.crossColor(grey, CYLAnimatedItemTitleState.Normal)
        assertEquals("no fill: as it is", grey, tag.shown?.color)
        tag.itemBackgroundColor = darkFill
        assertTrue(contrastOnDarkFill(tag.shown!!.color!!) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
        assertEquals(tag.adaptedForContrast(grey, CYLAnimatedItemColorKind.Title), tag.shown?.color)
    }

    @Test
    fun theDisabledLookOfABuiltInIsNotAdaptedButAnExplicitDisabledColourIs() {
        val tag = tag()
        tag.itemBackgroundColor = darkFill
        tag.crossBuiltIn(grey)
        assertTrue(contrastOnDarkFill(tag.shown!!.color!!) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
        tag.isEnabled = false
        assertEquals("disabled built-in: as it is", grey, tag.shown?.color)
        tag.crossColor(grey, CYLAnimatedItemTitleState.Disabled)
        assertEquals(CYLAnimatedItemColorLevel.Explicit, tag.shown?.level)
        assertTrue(contrastOnDarkFill(tag.shown!!.color!!) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
    }

    @Test
    fun theComponentBuiltInReceivesTheCurrentState() {
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        val states = mutableListOf<CYLAnimatedItemTitleState>()
        val tag = object : CYLAnimatedItemView(app) {
            val role = CYLAnimatedItemColorRole("state", CYLAnimatedItemColorKind.Icon, componentBuiltIn = { _, state -> states += state; null }) { _, _ -> }
            init { register(role) }
        }
        tag.isSelected = true
        tag.isEnabled = false
        assertTrue(states.contains(CYLAnimatedItemTitleState.Normal))
        assertTrue(states.contains(CYLAnimatedItemTitleState.Selected))
        assertEquals(CYLAnimatedItemTitleState.Disabled, states.last())
    }

    @Test
    fun titleAndIconKeepTheirChainThroughTheNewNames() {
        val tag = tag()
        tag.titleColor(red, CYLAnimatedItemTitleState.Normal)
        assertEquals(red, tag.titleView.currentTextColor)
        assertEquals(CYLAnimatedItemResolvedColor(red, CYLAnimatedItemColorLevel.Explicit), tag.resolvedColor(CYLAnimatedItemColorRole.title))
        tag.titleColor = blue
        assertEquals("the item's own colour wins", blue, tag.titleView.currentTextColor)
        tag.titleColor = null
        tag.titleColor(null, CYLAnimatedItemTitleState.Normal)
        tag.builtIn(grey, CYLAnimatedItemColorRole.title)
        assertEquals(CYLAnimatedItemResolvedColor(grey, CYLAnimatedItemColorLevel.SubclassBuiltIn), tag.resolvedColor(CYLAnimatedItemColorRole.title))
        tag.builtIn(grey, CYLAnimatedItemColorRole.icon)
        assertEquals(CYLAnimatedItemResolvedColor(grey, CYLAnimatedItemColorLevel.SubclassBuiltIn), tag.resolvedColor(CYLAnimatedItemColorRole.icon))
        tag.builtIn(null, CYLAnimatedItemColorRole.icon)
        assertEquals(CYLAnimatedItemColorLevel.ComponentBuiltIn, tag.resolvedColor(CYLAnimatedItemColorRole.icon).level)
    }

    @Test
    fun registeringTitleOrIconDoesNothingAndRegisteringAnIdAgainReplacesIt() {
        val tag = tag()
        tag.registerAgain(CYLAnimatedItemColorRole.title)
        tag.refreshColors()
        var replaced: Int? = null
        tag.registerAgain(CYLAnimatedItemColorRole("deleteIndicator", CYLAnimatedItemColorKind.Title, componentBuiltIn = { _, _ -> red }) { _, resolved -> replaced = resolved.color })
        assertEquals(red, replaced)
        val before = tag.applyCount
        tag.refreshColors()
        assertEquals("the old role is no longer applied", before, tag.applyCount)
    }
}
