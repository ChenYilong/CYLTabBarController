package com.cyl.animateditem

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
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
import org.robolectric.annotation.GraphicsMode

/** The options of the iOS item that the Android item mirrors; every one is off (null) by default. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class CYLAnimatedItemOptionsTest {
    private val app: Context = ApplicationProvider.getApplicationContext()
    private val source = CYLAnimatedItemAnimationEndTest.EndSource()

    @After
    fun reset() {
        CYLAnimatedItemView.reduceMotionOverride = null
        CYLAnimatedItemView.increaseContrastOverride = null
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    private fun animated() = CYLAnimatedItemView(app).apply {
        animationSource = source
        animationURL = "options.fake"
        drivesAnimationPlayback = true
        layout(0, 0, 200, 80)
    }

    private fun playerOf(item: CYLAnimatedItemView) = source.players.getValue(item.animationView!!)

    private fun render(item: CYLAnimatedItemView): Bitmap =
        Bitmap.createBitmap(item.width, item.height, Bitmap.Config.ARGB_8888).also { item.draw(Canvas(it)) }

    @Test
    fun theOptionsAreOffByDefault() {
        val item = CYLAnimatedItemView(app)
        assertNull(item.itemHighlightedBackgroundColor)
        assertNull(item.itemDisabledAnimationAlpha)
        assertFalse(item.showsLastFrameWhenSelected)
        assertFalse(item.showsOutlineWhenIncreaseContrast)
        assertFalse(item.respectsReduceMotion)
        assertFalse(item.disabledWinsImage)
    }

    @Test
    fun theHighlightedBackgroundShowsWhilePressedAndEnabledOnly() {
        val item = CYLAnimatedItemView(app).apply { itemHighlightedBackgroundColor = Color.RED; layout(0, 0, 100, 40) }
        assertEquals(Color.TRANSPARENT, render(item).getPixel(50, 20))
        item.isPressed = true
        assertEquals(Color.RED, render(item).getPixel(50, 20))
        item.isEnabled = false
        item.isPressed = true
        assertEquals("a disabled item shows no pressed look", Color.TRANSPARENT, render(item).getPixel(50, 20))
        item.isEnabled = true
        item.isPressed = false
        assertEquals(Color.TRANSPARENT, render(item).getPixel(50, 20))
    }

    @Test
    fun theDisabledAnimationAlphaAppliesWhileDisabled() {
        val item = animated()
        val view = item.animationView!!
        assertEquals(1f, view.alpha, 0f)
        item.itemDisabledAnimationAlpha = 0.3f
        assertEquals("enabled: untouched", 1f, view.alpha, 0f)
        item.isEnabled = false
        assertEquals(0.3f, view.alpha, 0f)
        item.isEnabled = true
        assertEquals(1f, view.alpha, 0f)
    }

    @Test
    fun disabledWinsImageShowsTheSelectedImageOnlyWhenSelectedAndEnabled() {
        val plain = ColorDrawable(Color.BLUE)
        val chosen = ColorDrawable(Color.GREEN)
        val item = CYLAnimatedItemView(app).apply { image = plain; selectedImage = chosen; isSelected = true }
        item.isEnabled = false
        assertTrue("default: selected wins", item.iconView.drawable === chosen)
        item.disabledWinsImage = true
        assertTrue(item.iconView.drawable === plain)
        item.isEnabled = true
        assertTrue(item.iconView.drawable === chosen)
    }

    @Test
    fun reduceMotionShowsTheStateFrameInsteadOfPlaying() {
        val item = animated().apply { respectsReduceMotion = true }
        val player = playerOf(item)
        CYLAnimatedItemView.reduceMotionOverride = true
        item.playAnimation()
        assertEquals("no run", 0, player.plays)
        item.isSelected = true
        item.playAnimation()
        assertEquals("selected: the last frame", 1f, player.progress, 0f)
        assertEquals(0, player.plays)
        CYLAnimatedItemView.reduceMotionOverride = false
        item.playAnimation()
        assertEquals(1, player.plays)
    }

    @Test
    fun withoutTheOptionReduceMotionDoesNotMatter() {
        val item = animated()
        CYLAnimatedItemView.reduceMotionOverride = true
        item.playAnimation()
        assertEquals(1, playerOf(item).plays)
    }

    @Test
    fun aSelectedItemShowsTheLastFrameWhenAsked() {
        val item = animated().apply { showsLastFrameWhenSelected = true }
        val player = playerOf(item)
        item.isSelected = true
        assertEquals(0, player.plays)
        assertEquals(1f, player.progress, 0f)
        item.isSelected = false
        item.showsLastFrameWhenSelected = false
        item.isSelected = true
        assertEquals(1, player.plays)
    }

    @Test
    fun theOutlineIsDrawnInTheTitleColourUnderIncreaseContrastOnly() {
        val item = CYLAnimatedItemView(app).apply { titleColor = Color.RED; showsOutlineWhenIncreaseContrast = true; layout(0, 0, 100, 40) }
        CYLAnimatedItemView.increaseContrastOverride = false
        assertEquals(Color.TRANSPARENT, render(item).getPixel(50, 0))
        CYLAnimatedItemView.increaseContrastOverride = true
        assertEquals(Color.RED, render(item).getPixel(50, 0))
        item.showsOutlineWhenIncreaseContrast = false
        assertNotEquals(Color.RED, render(item).getPixel(50, 0))
    }

    @Test
    fun increaseContrastNeedsApi34AndHasNoEffectBelow() {
        assertFalse("the standard contrast of the test device", CYLAnimatedItemView.isIncreaseContrastEnabled(app))
    }

    @Test
    @Config(sdk = [28])
    fun increaseContrastIsFalseBelowApi34() {
        assertFalse(CYLAnimatedItemView.isIncreaseContrastEnabled(app))
    }

    @Test
    fun theStaticForwardersMatchWhatExists() {
        assertEquals(CYLAnimatedItemBackgroundRenderer.resolvedContentInset(null, CYLAnimatedItemBackgroundStyle.Flat), CYLAnimatedItemView.resolvedContentHorizontalInset(null, CYLAnimatedItemBackgroundStyle.Flat), 0f)
        assertEquals(7f, CYLAnimatedItemView.resolvedContentHorizontalInset(7f, CYLAnimatedItemBackgroundStyle.LiquidGlass), 0f)
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        assertEquals(CYLAnimatedItemLiquidGlassContentInset, CYLAnimatedItemView.resolvedContentHorizontalInset(null, CYLAnimatedItemBackgroundStyle.LiquidGlass), 0f)
        assertEquals(listOf("Lottie", "PAG", "Rive", "SVGA").any { CYLAnimationEngines.isAvailable(it) }, CYLAnimatedItemView.isAnimationEngineAvailable)
    }
}
