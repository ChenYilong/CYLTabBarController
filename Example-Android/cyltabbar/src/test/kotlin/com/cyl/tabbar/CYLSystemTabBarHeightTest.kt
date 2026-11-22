package com.cyl.tabbar

import android.app.Application
import android.view.ContextThemeWrapper
import android.view.View
import androidx.test.core.app.ApplicationProvider
import com.google.android.material.bottomnavigation.BottomNavigationView
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] The default tab bar height is the system tab bar's (docs/Cross-Platform-Components.md, "default tab bar height =
 *      the system tab bar's"): `CYLConstants.cyl_systemTabBarHeight` reads it from the theme, and a real
 *      BottomNavigationView in the same theme measures to that height.
 * [CN] 默认 TabBar 高度等于系统 TabBar 的高度：`CYLConstants.cyl_systemTabBarHeight` 从主题读取，同一主题中真实的 BottomNavigationView 测量结果相同。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLSystemTabBarHeightTest {

    private fun themed(style: Int) = ContextThemeWrapper(ApplicationProvider.getApplicationContext<Application>(), style)

    private fun measuredBottomNavigationDp(context: ContextThemeWrapper): Float {
        val bar = BottomNavigationView(context)
        for (index in 0 until 4) bar.menu.add(0, index, index, "Tab $index").setIcon(android.R.drawable.ic_menu_view)
        bar.measure(View.MeasureSpec.makeMeasureSpec(1080, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(4000, View.MeasureSpec.AT_MOST))
        return bar.measuredHeight / context.resources.displayMetrics.density
    }

    @Test
    fun material3ThemeGives80dpTheHeightOfItsBottomNavigationView() {
        val context = themed(com.google.android.material.R.style.Theme_Material3_DayNight)
        assertEquals(80f, CYLConstants.cyl_systemTabBarHeight(context), 0.5f)
        assertEquals(measuredBottomNavigationDp(context), CYLConstants.cyl_systemTabBarHeight(context), 1f)
    }

    @Test
    fun material2ThemeGives56dpTheHeightOfItsBottomNavigationView() {
        val context = themed(com.google.android.material.R.style.Theme_MaterialComponents_DayNight)
        assertEquals(56f, CYLConstants.cyl_systemTabBarHeight(context), 0.5f)
        assertEquals(measuredBottomNavigationDp(context), CYLConstants.cyl_systemTabBarHeight(context), 1f)
    }
}
