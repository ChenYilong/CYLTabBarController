package com.cyl.liquidglass

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
 * The availability rule and the glass view's contract (the same names as iOS `CYLLiquidGlass` / `CYLLiquidGlassView`).
 */
@RunWith(RobolectricTestRunner::class)
class CYLLiquidGlassTest {

    @After
    fun reset() {
        CYLLiquidGlass.activeOverride = null
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

    private companion object {
        const val View_IMPORTANT_NO = android.view.View.IMPORTANT_FOR_ACCESSIBILITY_NO
    }
}
