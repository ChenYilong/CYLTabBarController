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

    private class StatusAnimator(override val identifier: String, override val fileExtensions: List<String>, override val priority: CYLTabBarItemAnimatorPriority = CYLTabBarItemAnimatorPriorityDefault) : CYLTabBarItemAnimator {
        override fun canAnimateFileAtURL(url: String) = CYLTabBarAnimationFileExtension(url) in fileExtensions
        override fun animationViewWithURL(context: android.content.Context, url: String, size: CYLSize, contentMode: android.widget.ImageView.ScaleType): android.view.View? = null
        override fun playerForAnimationView(view: android.view.View): CYLTabBarItemAnimationPlayer? = null
    }

    /**
     * [EN] Several engines: which are in, which known ones are missing (with the dependency), and the conflicts.
     * [CN] 多个引擎：哪些已接入、哪些已知引擎缺少（及其依赖）以及冲突。
     */
    @Test
    fun theRegistryReportsEveryEngineTheMissingOnesAndTheConflicts() {
        val registry = CYLTabBarItemAnimatorRegistry()
        assertEquals(listOf("Lottie", "PAG", "Rive", "SVGA", "GIF"), registry.missingKnownIdentifiers())
        registry.registerAnimator(StatusAnimator("PAG", listOf("pag")))
        registry.registerAnimator(StatusAnimator("Lottie", listOf("json"), CYLTabBarItemAnimatorPriorityFallback))
        registry.registerAnimator(StatusAnimator("GIF", listOf("gif")))
        assertEquals(listOf("PAG", "GIF", "Lottie"), registry.registeredIdentifiers())
        assertTrue(registry.isAnimatorRegisteredWithIdentifier("GIF"))
        assertFalse(registry.isAnimatorRegisteredWithIdentifier("Rive"))
        assertEquals(listOf("Rive", "SVGA"), registry.missingKnownIdentifiers())
        assertTrue(registry.conflictDescriptions().isEmpty())
        val report = registry.registrationReport()
        assertTrue(report, report.contains("3 registered"))
        assertTrue(report, report.contains("✅ PAG"))
        assertTrue(report, report.contains("app.rive:rive-android"))

        registry.registerAnimator(StatusAnimator("MyGIF", listOf("GIF", "webp")))
        assertEquals(1, registry.conflictDescriptions().size)
        assertTrue(registry.conflictDescriptions().first().startsWith("GIF and MyGIF both claim .gif"))
        registry.registerAnimator(StatusAnimator("MyGIF", listOf("gif"), 10))
        assertTrue(registry.conflictDescriptions().isEmpty())
        assertEquals("MyGIF", registry.animatorForURL("/data/a.gif")?.identifier)
    }
}
