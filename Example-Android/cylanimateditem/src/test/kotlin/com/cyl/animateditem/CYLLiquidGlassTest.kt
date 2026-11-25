package com.cyl.animateditem

import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * The availability rule and the background API of `CYLAnimatedItemView` (the same names as iOS and HarmonyOS): flat color, Liquid
 * Glass where the device draws it, corner radius and border.
 */
@RunWith(RobolectricTestRunner::class)
class CYLLiquidGlassTest {

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    @Test
    @Config(sdk = [34])
    fun aTransparentColorMeansNoColorAndGetsTheDefaultFrostedTint() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val renderer = CYLAnimatedItemBackgroundRenderer(android.widget.FrameLayout(context))
        val frosted = renderer.glassTint(null)
        assertEquals("null: the default frosted tint", android.graphics.Color.argb(128, 225, 222, 220), frosted)
        assertEquals("Color.TRANSPARENT is no color: the same default tint", frosted, renderer.glassTint(android.graphics.Color.TRANSPARENT))
        assertEquals("also an RGB with alpha 0", frosted, renderer.glassTint(0x00FF0000))
        // A color with a real alpha tints at 75% of it.
        assertEquals(android.graphics.Color.argb(Math.round(0x66 * 0.75f), 255, 136, 0), renderer.glassTint(0x66FF8800))
    }

    @Test
    @Config(sdk = [34])
    fun itemGlassBackdropSourceReachesTheGlassLayerAndNullKeepsTheWindowRoot() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val item = CYLAnimatedItemView(context)
        item.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        item.layout(0, 0, 200, 80)
        val glass = item.itemLiquidGlassView as CYLLiquidGlassView
        assertEquals("default: the window root", null, glass.backdropSource)
        val plate = android.view.View(context)
        item.itemGlassBackdropSource = plate
        assertEquals("the plate reaches the glass layer", plate, glass.backdropSource)
        item.itemGlassBackdropSource = null
        assertEquals("null keeps today's behavior (the window root)", null, glass.backdropSource)
        // A glass layer made later takes the source too.
        val late = CYLAnimatedItemView(context)
        late.itemGlassBackdropSource = plate
        late.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        late.layout(0, 0, 200, 80)
        assertEquals(plate, (late.itemLiquidGlassView as CYLLiquidGlassView).backdropSource)
    }

    @Test
    @Config(sdk = [34])
    fun theStackForwardsItsGlassBackdropSourceToEveryHostedItem() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val plate = android.view.View(context)
        val stack = CYLAnimatedItemStackView(context)
        val first = CYLAnimatedItemView(context).apply { itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass }
        stack.append(first)
        stack.itemGlassBackdropSource = plate
        assertEquals("an existing item takes it", plate, first.itemGlassBackdropSource)
        val later = CYLAnimatedItemView(context).apply { itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass }
        stack.append(later)
        assertEquals("an item added later takes it", plate, later.itemGlassBackdropSource)
        first.layout(0, 0, 200, 80)
        assertEquals("it reaches the glass layer of a hosted item", plate, (first.itemLiquidGlassView as CYLLiquidGlassView).backdropSource)
        stack.itemGlassBackdropSource = null
        assertEquals("null restores the window root", null, first.itemGlassBackdropSource)
        assertEquals(null, (first.itemLiquidGlassView as CYLLiquidGlassView).backdropSource)
        assertEquals(null, later.itemGlassBackdropSource)
    }

    @Test
    @Config(sdk = [34])
    fun aGlassInsideItsOwnSourceDrawsTheFrostedTintAndTheRimInsteadOfNothing() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val host = android.widget.FrameLayout(context)
        val item = CYLAnimatedItemView(context).apply { itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass }
        host.addView(item, android.widget.FrameLayout.LayoutParams(200, 80))
        host.measure(android.view.View.MeasureSpec.makeMeasureSpec(400, android.view.View.MeasureSpec.EXACTLY), android.view.View.MeasureSpec.makeMeasureSpec(300, android.view.View.MeasureSpec.EXACTLY))
        host.layout(0, 0, 400, 300)
        item.itemGlassBackdropSource = host // an ancestor: nothing can be sampled
        var roundRects = 0
        val canvas = object : android.graphics.Canvas() {
            override fun drawRoundRect(rect: android.graphics.RectF, rx: Float, ry: Float, paint: android.graphics.Paint) { roundRects++ }
            override fun drawRoundRect(left: Float, top: Float, right: Float, bottom: Float, rx: Float, ry: Float, paint: android.graphics.Paint) { roundRects++ }
        }
        (item.itemLiquidGlassView as CYLLiquidGlassView).draw(canvas)
        assertEquals("the frosted tint and the hairline rim are drawn", 2, roundRects)
    }

    @Test
    @Config(sdk = [34])
    fun aTintAlphaOfOneKeepsTheColorAsItIs() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val renderer = CYLAnimatedItemBackgroundRenderer(android.widget.FrameLayout(context))
        assertEquals("the default share is 0.75", android.graphics.Color.argb(Math.round(0xFF * 0.75f), 7, 193, 96), renderer.glassTint(0xFF07C160.toInt()))
        assertEquals("1: the color as it is", 0xFF07C160.toInt(), renderer.glassTint(0xFF07C160.toInt(), 1f))
    }

    @Test
    fun aNestedCaptureIsRefusedAndTheFlagIsAlwaysReset() {
        // The glass of a tag inside the captured page: while a capture runs, a nested one gets null (the caller draws the tint).
        val outer = CYLGlassBackdrop.captureOnce { CYLGlassBackdrop.captureOnce { "nested" } }
        assertEquals("the nested capture is refused", null, outer)
        // After it, a capture works again.
        assertEquals("again", CYLGlassBackdrop.captureOnce { "again" })
        // An exception while recording must not leave every glass on its fallback for good.
        try {
            CYLGlassBackdrop.captureOnce<Unit> { throw IllegalStateException("recording failed") }
        } catch (expected: IllegalStateException) {
            // expected
        }
        assertEquals("the flag was reset in a finally", "ok", CYLGlassBackdrop.captureOnce { "ok" })
    }

    @Test
    @Config(sdk = [30])
    fun isInactiveBeforeAndroid12() {
        assertFalse(CYLLiquidGlass.isActive())
    }

    @Test
    @Config(sdk = [31])
    fun isActiveFromAndroid12() {
        assertTrue(CYLLiquidGlass.isActive())
    }

    @Test
    @Config(sdk = [34])
    fun theOverrideReplacesTheDeviceCheck() {
        CYLLiquidGlass.activeOverride = false
        assertFalse(CYLLiquidGlass.isActive())
        CYLLiquidGlass.activeOverride = true
        assertTrue(CYLLiquidGlass.isActive())
    }

    @Test
    @Config(sdk = [34])
    fun theViewDrawsGlassOnlyWhereGlassIsActiveAndItHasASize() {
        val view = CYLLiquidGlassView(ApplicationProvider.getApplicationContext())
        view.glassTintColor = 0x66FF8800
        view.cornerRadius = 12f
        assertEquals(0x66FF8800, view.glassTintColor)
        assertEquals(12f, view.cornerRadius)
        assertFalse("no size yet", view.isGlassDrawn)
        view.layout(0, 0, 200, 80)
        assertTrue(view.isGlassDrawn)
        CYLLiquidGlass.activeOverride = false
        assertFalse("flat where glass is inactive", view.isGlassDrawn)
        assertEquals(View_IMPORTANT_NO, view.importantForAccessibility)
        assertFalse(view.isClickable)
    }

    @Test
    @Config(sdk = [34])
    fun anUnsetRadiusIsACapsuleForGlassAndSquareForFlatAndASetRadiusWins() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val view = CYLAnimatedItemView(context)
        view.itemBackgroundColor = 0xFF336699.toInt()
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        view.layout(0, 0, 200, 80)
        assertEquals("flat, unset: square", 0f, (view.background as android.graphics.drawable.GradientDrawable).cornerRadius)
        view.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        view.layout(0, 0, 200, 80)
        assertEquals("glass, unset: a capsule", 40f, (view.background as android.graphics.drawable.GradientDrawable).cornerRadius)
        view.itemCornerRadius = 6f
        view.layout(0, 0, 200, 80)
        assertEquals("a set radius customizes it", 6f * context.resources.displayMetrics.density, (view.background as android.graphics.drawable.GradientDrawable).cornerRadius)
    }

    @Test
    @Config(sdk = [34])
    fun theItemDrawsItsFlatBackgroundRadiusAndBorderAndGlassOnlyWhereTheDeviceDrawsIt() {
        val context = ApplicationProvider.getApplicationContext<android.content.Context>()
        val view = CYLAnimatedItemView(context)
        view.itemBackgroundColor = 0xFF336699.toInt()
        view.itemCornerRadius = CYLAnimatedItemCornerRadiusCapsule
        view.itemBorderWidth = 1f
        view.itemBorderColor = android.graphics.Color.RED
        view.layout(0, 0, 200, 80)
        assertTrue("a background is drawn once an item… property is set", view.background != null)
        assertEquals(CYLAnimatedItemBackgroundStyle.Flat, view.resolvedItemBackgroundStyle)
        assertTrue("flat: no glass layer", view.itemLiquidGlassView == null)

        view.itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        view.itemBackgroundColor = 0x66FF8800
        view.layout(0, 0, 200, 80)
        assertEquals(CYLAnimatedItemBackgroundStyle.LiquidGlass, view.resolvedItemBackgroundStyle)
        assertTrue("glass layer behind the content", view.itemLiquidGlassView != null)

        CYLAnimatedItemView.liquidGlassActiveOverride = false
        view.itemBackgroundColor = 0x66FF8801
        assertEquals("ignored where the device draws none", CYLAnimatedItemBackgroundStyle.Flat, view.resolvedItemBackgroundStyle)
        assertTrue(view.itemLiquidGlassView == null)
    }

    private companion object {
        const val View_IMPORTANT_NO = android.view.View.IMPORTANT_FOR_ACCESSIBILITY_NO
    }
}
