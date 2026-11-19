package com.cyl.tabbar

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * [EN] `CYLTabBarConfiguration.drawable`: asset images of manifests are read at the density of their @2x / @3x suffix.
 * [CN] `CYLTabBarConfiguration.drawable`：清单的 asset 图片按 @2x / @3x 后缀的密度读取。
 */
class CYLTabBarConfigurationImageTest {
    @Test
    fun theDensityOfAnImageComesFromItsSuffix() {
        assertEquals(480, CYLTabBarConfiguration.densityOfImageName("Skins/2.1.0/light/home@3x.png"))
        assertEquals(320, CYLTabBarConfiguration.densityOfImageName("icons/me@2x.PNG"))
        assertEquals(160, CYLTabBarConfiguration.densityOfImageName("icons/me.png"))
        assertEquals(160, CYLTabBarConfiguration.densityOfImageName("icons/v@3x.backup/me.png"))
    }
}
