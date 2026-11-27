package com.cyl.animateditem

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PorterDuff
import android.graphics.PorterDuffColorFilter
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.ColorDrawable
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertSame
import kotlin.test.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * Static images follow the rendering mode as animations do (2026-11-28; a ClassifyMenu tag, also a CYLAnimatedItemView, kept a dark one-colour
 * glyph on night glass): `Automatic` tints a one-colour image with the resolved icon colour through the contrast rule, keeps a multi-colour one,
 * `AlwaysTemplate` / `AlwaysOriginal` force it, an explicit colour still wins, a host's own filter is never replaced.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], qualifiers = "night")
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class CYLAnimatedItemStaticImageTintTest {

    private val app: Context = ApplicationProvider.getApplicationContext()
    private val grey = 0xFF3C3C43.toInt()
    private val darkFill = 0xFF1C1C1E.toInt()

    private class Tag(context: Context) : CYLAnimatedItemView(context) {
        fun builtInIcon(color: Int?) = applyIconTintColor(color)
    }

    private class TabLike(context: Context) : CYLAnimatedItemView(context) {
        override val tintsStaticImageAutomatically: Boolean get() = false
    }

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    private fun image(vararg colors: Int): BitmapDrawable {
        val bitmap = Bitmap.createBitmap(colors.size * 8, 8, Bitmap.Config.ARGB_8888)
        colors.forEachIndexed { index, color -> for (x in index * 8 until index * 8 + 8) for (y in 0 until 8) bitmap.setPixel(x, y, color) }
        return BitmapDrawable(app.resources, bitmap)
    }

    private fun filterColor(view: CYLAnimatedItemView): Int? = view.staticImageRenderingColor()

    @Test
    fun theDrawableKindCountsPixelsLikeAGifFrame() {
        assertEquals(CYLAnimationColorCount.Kind.OneColor, CYLAnimationColorCount.drawableKind(image(grey)))
        assertEquals(CYLAnimationColorCount.Kind.MultiColor, CYLAnimationColorCount.drawableKind(image(Color.RED, Color.GREEN, Color.BLUE)))
        assertEquals(CYLAnimationColorCount.Kind.Undetectable, CYLAnimationColorCount.drawableKind(ColorDrawable(grey)), "no intrinsic size")
    }

    @Test
    fun aOneColourImageTakesTheBuiltInIconColourLiftedOnTheDarkFill() {
        val tag = Tag(app)
        tag.itemBackgroundColor = darkFill
        tag.builtInIcon(grey)
        tag.image = image(grey)
        val color = filterColor(tag)
        assertNotNull(color)
        val reference = CYLAnimatedItemContrast.flatReferenceLuminance(darkFill)
        val luminance = CYLAnimatedItemContrast.relativeLuminance(Color.red(color!!) / 255.0, Color.green(color) / 255.0, Color.blue(color) / 255.0)
        assertTrue(CYLAnimatedItemContrast.contrastRatio(luminance, reference) >= 3 - 0.01, "icon 3:1 on the dark fill, as the animation")
        assertNotNull(tag.iconView.colorFilter, "the static image is tinted")
    }

    @Test
    fun aMultiColourImageKeepsItsColoursUnderAutomatic() {
        val tag = Tag(app)
        tag.builtInIcon(grey)
        tag.image = image(Color.RED, Color.GREEN, Color.BLUE)
        assertNull(filterColor(tag))
        assertNull(tag.iconView.colorFilter)
    }

    @Test
    fun theRenderingModeForcesOrForbidsTheTint() {
        val tag = Tag(app)
        tag.builtInIcon(grey)
        tag.image = image(Color.RED, Color.GREEN, Color.BLUE)
        tag.animationRenderingMode = CYLAnimationRenderingMode.AlwaysTemplate
        assertNotNull(filterColor(tag), "alwaysTemplate tints a multi-colour image")
        tag.animationRenderingMode = CYLAnimationRenderingMode.AlwaysOriginal
        tag.image = image(grey)
        assertNull(filterColor(tag), "alwaysOriginal never tints")
    }

    @Test
    fun anExplicitColourStillWinsAndAHostFilterIsKept() {
        val tag = Tag(app)
        tag.image = image(Color.RED, Color.GREEN, Color.BLUE)
        tag.iconColor = Color.WHITE
        assertNotNull(tag.iconView.colorFilter, "explicit tints any image whole")
        tag.iconColor = null
        assertNull(tag.iconView.colorFilter)
        val own = PorterDuffColorFilter(Color.MAGENTA, PorterDuff.Mode.SRC_IN)
        tag.iconView.colorFilter = own
        tag.builtInIcon(grey)
        tag.image = image(grey)
        assertSame(own, tag.iconView.colorFilter, "the host's own filter is not replaced")
    }

    @Test
    fun aSubclassThatTintsItsOwnIconOptsOut() {
        val tab = TabLike(app)
        tab.image = image(grey)
        assertNull(filterColor(tab))
        assertNull(tab.iconView.colorFilter)
    }
}
