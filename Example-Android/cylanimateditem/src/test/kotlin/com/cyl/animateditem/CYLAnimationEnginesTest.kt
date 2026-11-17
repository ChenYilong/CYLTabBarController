package com.cyl.animateditem

import android.content.pm.ApplicationInfo
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLog

/**
 * [EN] A type's key without its library: the file is still found, the type is known, and a debuggable app logs once which
 *      dependency to add. This test classpath has no Lottie, libpag, Rive or SVGA library; GIF is decoded by the platform.
 * [CN] 没有动画库却传入该类型的 key：仍能找到文件、识别类型，可调试的 App 只输出一次需要加入的依赖。本测试 classpath 中没有 Lottie、libpag、
 *      Rive、SVGA；GIF 由系统解码。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimationEnginesTest {

    @After
    fun tearDown() = CYLAnimationEngines.resetWarnings()

    @Test
    fun typeKeysAreReadWithoutTheirLibrary() {
        val pag = mapOf<String, Any?>(CYLTabBarItemAnimationKeys.CYLTabBarPAGURL to "https://example.com/home.pag")
        assertEquals("https://example.com/home.pag", CYLAnimationEngines.attributesValue(pag, CYLTabBarItemAnimationKeys.CYLTabBarAnimationURL))
        val svga = mapOf<String, Any?>(CYLTabBarItemAnimationKeys.CYLTabBarSVGAFilePath to "/data/home.svga")
        assertEquals("/data/home.svga", CYLAnimationEngines.attributesValue(svga, CYLTabBarItemAnimationKeys.CYLTabBarAnimationFilePath))
        assertNull(CYLAnimationEngines.attributesValue(emptyMap(), CYLTabBarItemAnimationKeys.CYLTabBarAnimationURL))
        assertEquals("PAG", CYLAnimationEngines.typeOf(pag, null))
        assertEquals("SVGA", CYLAnimationEngines.typeOf(null, "file:///android_asset/a.svga#artboard=HOME"))
        assertEquals("Rive", CYLAnimationEngines.typeOf(null, "https://example.com/a.riv"))
        assertNull(CYLAnimationEngines.typeOf(null, "https://example.com/a.webp"))
        assertFalse(CYLAnimationEngines.isAvailable("PAG"))
        assertFalse(CYLAnimationEngines.isAvailable("SVGA"))
        assertTrue("GIF is decoded by the platform", CYLAnimationEngines.isAvailable("GIF"))
    }

    @Test
    fun aDebuggableAppIsToldOnceWhichDependencyToAdd() {
        val context = RuntimeEnvironment.getApplication()
        context.applicationInfo.flags = context.applicationInfo.flags or ApplicationInfo.FLAG_DEBUGGABLE
        ShadowLog.clear()
        val pag = mapOf<String, Any?>(CYLTabBarItemAnimationKeys.CYLTabBarPAGURL to "home.pag")
        CYLAnimationEngines.warnMissingEngine(context, pag, "home.pag")
        CYLAnimationEngines.warnMissingEngine(context, pag, "discover.pag")
        CYLAnimationEngines.warnMissingEngine(context, null, "tab.gif")
        val logs = ShadowLog.getLogsForTag("CYLAnimatedItem")
        assertEquals("once per type, never for an available one", 1, logs.size)
        assertTrue(logs[0].msg.contains("com.tencent.tav:libpag"))
    }

    @Test
    fun aReleaseAppLogsNothing() {
        val context = RuntimeEnvironment.getApplication()
        context.applicationInfo.flags = context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE.inv()
        ShadowLog.clear()
        CYLAnimationEngines.warnMissingEngine(context, null, "home.svga")
        assertTrue(ShadowLog.getLogsForTag("CYLAnimatedItem").isEmpty())
    }
}
