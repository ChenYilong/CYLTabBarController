package com.cyl.animateditem

import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.util.Base64
import android.view.ContextThemeWrapper
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File

/**
 * The UNSET colours of an unselected item in dark mode adapt by themselves: a theme colour counts in night only when it is night-aware (differs
 * from its light value), else the dark fallback; the built-in normal title and icon tint also go through the dark-glass contrast rule.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34], qualifiers = "night")
class CYLAnimatedItemNightDefaultColorTest {
    private val app: Context = ApplicationProvider.getApplicationContext()
    private val factory = CYLTabBarItemAnimationFactory(CYLTabBarItemAnimatorRegistry().apply { registerAnimator(CYLGIFTabBarItemAnimator.animator) })
    private val gif: String by lazy {
        File.createTempFile("cyl-night-default", ".gif").apply { writeBytes(Base64.decode(CYLGIFDecoderTestData.THREE_FRAMES, Base64.DEFAULT)); deleteOnExit() }.absolutePath
    }

    @After
    fun reset() {
        CYLAnimatedItemView.liquidGlassActiveOverride = null
    }

    private fun themed(style: Int): Context = ContextThemeWrapper(app, style)

    private fun configuration(night: Boolean) = Configuration(app.resources.configuration).apply {
        uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or (if (night) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO)
    }

    private fun luminance(color: Int) = CYLAnimatedItemContrast.relativeLuminance(Color.red(color) / 255.0, Color.green(color) / 255.0, Color.blue(color) / 255.0)

    private fun contrast(color: Int) = CYLAnimatedItemContrast.contrastRatio(luminance(color), CYLAnimatedItemContrast.glassReferenceLuminance(null, null))

    private fun makeItem(context: Context, glass: Boolean): CYLAnimatedItemView {
        CYLAnimatedItemView.liquidGlassActiveOverride = glass
        return CYLAnimatedItemView(context).apply {
            title = "Title"
            animationSource = factory
            animationTint = "title"
            animationURL = gif
            if (glass) itemBackgroundStyle = CYLAnimatedItemBackgroundStyle.LiquidGlass
            layout(0, 0, 200, 80)
        }
    }

    @Test
    fun aLightOnlyThemeIsNotNightAwareSoNightTakesTheDarkFallback() {
        val context = themed(android.R.style.Theme_Material_Light)
        val night = configuration(night = true)
        assertEquals(CYLAnimatedItemBuiltInColors.NORMAL_DARK, CYLAnimatedItemBuiltInColors.normal(context, night))
        assertEquals(CYLAnimatedItemBuiltInColors.DIVIDER_DARK, CYLAnimatedItemBuiltInColors.divider(context, night))
        assertEquals(CYLAnimatedItemBuiltInColors.withAlpha(CYLAnimatedItemBuiltInColors.NORMAL_DARK, CYLAnimatedItemBuiltInColors.DISABLED_ALPHA), CYLAnimatedItemBuiltInColors.disabled(context, night))
        assertEquals("light mode unchanged: the theme colour", CYLAnimatedItemBuiltInColors.themeColor(context, android.R.attr.textColorPrimary), CYLAnimatedItemBuiltInColors.normal(context, configuration(night = false)))
    }

    @Test
    fun aNightAwareThemeKeepsItsOwnNightColour() {
        val context = themed(android.R.style.Theme_DeviceDefault_DayNight)
        val night = configuration(night = true)
        val nightValue = CYLAnimatedItemBuiltInColors.themeColor(ContextThemeWrapper(context, 0).also { it.applyOverrideConfiguration(night) }, android.R.attr.textColorPrimary)
        val lightValue = CYLAnimatedItemBuiltInColors.themeColor(ContextThemeWrapper(context, 0).also { it.applyOverrideConfiguration(configuration(night = false)) }, android.R.attr.textColorPrimary)
        assumeTrue("the theme resolves a different colour per mode", nightValue != null && nightValue != lightValue)
        assertEquals(nightValue, CYLAnimatedItemBuiltInColors.normal(context, night))
        assertEquals(lightValue, CYLAnimatedItemBuiltInColors.normal(context, configuration(night = false)))
    }

    @Test
    fun anUnsetTitleAndIconTintOnDarkGlassWithALightOnlyThemeAreReadable() {
        val item = makeItem(themed(android.R.style.Theme_Material_Light), glass = true)
        assertNotNull("glass drawn", item.itemLiquidGlassView)
        assertTrue("title " + contrast(item.titleView.currentTextColor), contrast(item.titleView.currentTextColor) >= CYLAnimatedItemContrast.TITLE_MINIMUM_CONTRAST)
        val tint = CYLTabBarItemAnimationTint.appliedColor(item.animationView)
        assertNotNull(tint)
        assertTrue("icon " + contrast(tint!!), contrast(tint) >= CYLAnimatedItemContrast.ICON_MINIMUM_CONTRAST)
        assertEquals("the properties hold the app's (unset) value", null, item.titleColor)
    }

    @Test
    fun aFlatItemIsNotAdaptedBeyondTheNightAwareRule() {
        val context = themed(android.R.style.Theme_Material_Light)
        val item = makeItem(context, glass = false)
        assertEquals(CYLAnimatedItemBuiltInColors.normal(context, configuration(night = true)), item.titleView.currentTextColor)
        assertEquals(CYLAnimatedItemBuiltInColors.NORMAL_DARK, item.titleView.currentTextColor)
    }

    @Test
    @Config(sdk = [34], qualifiers = "notnight")
    fun lightModeIsUnchanged() {
        val context = themed(android.R.style.Theme_Material_Light)
        val item = makeItem(context, glass = true)
        assertEquals(CYLAnimatedItemBuiltInColors.normal(context, configuration(night = false)), item.titleView.currentTextColor)
        assertEquals(CYLAnimatedItemBuiltInColors.themeColor(context, android.R.attr.textColorPrimary), item.titleView.currentTextColor)
    }

    @Test
    fun selectedAndDisabledKeepTheirBuiltInColoursOnDarkGlass() {
        val context = themed(android.R.style.Theme_Material_Light)
        val night = configuration(night = true)
        val item = makeItem(context, glass = true)
        item.isSelected = true
        assertEquals(CYLAnimatedItemBuiltInColors.selected(context, night), item.titleView.currentTextColor)
        assertEquals(CYLAnimatedItemBuiltInColors.selected(context, night), CYLTabBarItemAnimationTint.appliedColor(item.animationView))
        item.isSelected = false
        item.disabledAlpha = 1f
        item.isEnabled = false
        assertEquals(CYLAnimatedItemBuiltInColors.disabled(context, night), item.titleView.currentTextColor)
    }
}
