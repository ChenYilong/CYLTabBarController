package com.cyl.animateditem

import android.app.Activity
import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLog
import java.io.File

/**
 * [EN] `onResourceMissing` and `CYLAnimationEngines.resourceMissingListener`: which file, and why, once per resource per
 *      view, on the main thread; the item shows its image or the placeholder as before.
 * [CN] `onResourceMissing` 与 `CYLAnimationEngines.resourceMissingListener`：哪个文件、为什么；每个视图每个资源一次，在主线程；条目照常显示图片或占位图。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLResourceMissingTest {

    private val heard = ArrayList<Pair<String, String>>()
    private val global = ArrayList<Pair<String, String>>()

    @After
    fun tearDown() { CYLAnimationEngines.resourceMissingListener = null }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun hosted(activity: Activity, source: CYLTabBarItemAnimationViewMaking? = null): CYLAnimatedItemView {
        val item = CYLAnimatedItemView(activity).apply {
            title = "Home"
            source?.let { animationSource = it }
            onResourceMissing = { resource, reason -> heard += resource to reason }
        }
        CYLAnimationEngines.resourceMissingListener = { resource, reason -> global += resource to reason }
        val host = FrameLayout(activity)
        host.addView(item, FrameLayout.LayoutParams(400, 120))
        activity.setContentView(host)
        return item
    }

    private fun activity(): Activity = Robolectric.buildActivity(Activity::class.java).setup().get()

    @Test
    fun aMissingLocalFileIsReportedAsNotFoundToTheViewAndTheListener() {
        val activity = activity()
        val item = hosted(activity)
        val path = File(activity.cacheDir, "missing.pag").absolutePath
        item.animationURL = path
        assertEquals(listOf(path to CYLResourceMissingReason.NOT_FOUND), heard)
        assertEquals(heard, global)
        assertTrue("the placeholder still shows", item.iconView.drawable != null)
    }

    @Test
    fun aMissingAssetIsNotFoundAndAnEmptyFileIsUnreadable() {
        val activity = activity()
        val item = hosted(activity)
        item.animationURL = "file:///android_asset/missing.json"
        val empty = File(activity.cacheDir, "empty.json").apply { writeBytes(ByteArray(0)) }.absolutePath
        item.animationURL = empty
        assertEquals(listOf("file:///android_asset/missing.json" to "not found", empty to "unreadable"), heard)
    }

    @Test
    fun theSameResourceIsReportedOncePerView() {
        val activity = activity()
        val item = hosted(activity)
        val path = File(activity.cacheDir, "once.json").absolutePath
        item.animationURL = path
        item.reloadAnimation()
        item.animationURL = path
        assertEquals(1, heard.size)
        val other = hosted(activity)
        other.animationURL = path
        assertEquals("another view reports it again", 2, global.size)
    }

    @Test
    fun aTypeWithoutItsLibraryIsReportedAsEngineLibraryMissing() {
        val activity = activity()
        val item = hosted(activity, object : CYLTabBarItemAnimationViewMaking {
            override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View? = null
            override fun playerForView(view: View?): CYLTabBarItemAnimationPlayer? = null
            override fun isAnimationView(view: View?) = false
        })
        // [EN] This test classpath has no libpag. [CN] 本测试 classpath 中没有 libpag。
        val pag = File(activity.cacheDir, "home.pag").apply { writeBytes(byteArrayOf(1, 2, 3)) }.absolutePath
        item.animationURL = pag
        assertEquals(listOf(pag to CYLResourceMissingReason.ENGINE_LIBRARY_MISSING), heard)
    }

    @Test
    fun aFailureReportedLaterCarriesTheAnimatorsReason() {
        val activity = activity()
        val source = CYLAnimatedItemFailureTest.CountingSource()
        val item = hosted(activity, source)
        item.animationURL = "https://example.com/home.json"
        CYLTabBarItemAnimationFailure.reportLater(source.views.single(), CYLResourceMissingReason.UNREADABLE)
        idle()
        assertEquals(listOf("https://example.com/home.json" to "unreadable"), heard)
        assertEquals(heard, global)
        assertFalse(item.isAnimationReady)
    }

    @Test
    fun aCorruptedGIFIsDecodeFailed() {
        val activity = activity()
        val item = hosted(activity)
        val path = File(activity.cacheDir, "broken.gif").apply { writeBytes("not a gif".toByteArray()) }.absolutePath
        item.animationURL = path
        idle()
        assertEquals(listOf(path to CYLResourceMissingReason.DECODE_FAILED), heard)
    }

    @Test
    fun aBackgroundThreadReportReachesTheMainThread() {
        val activity = activity()
        var onMain: Boolean? = null
        CYLAnimationEngines.resourceMissingListener = { _, _ -> onMain = Looper.myLooper() == Looper.getMainLooper() }
        Thread { CYLAnimationEngines.dispatchResourceMissing(activity, "a.pag", "not found", null) }.also { it.start(); it.join() }
        idle()
        assertEquals(true, onMain)
    }

    @Test
    fun aDebuggableAppLogsAWarningAndAReleaseAppDoesNot() {
        val context = org.robolectric.RuntimeEnvironment.getApplication()
        context.applicationInfo.flags = context.applicationInfo.flags or ApplicationInfo.FLAG_DEBUGGABLE
        ShadowLog.clear()
        CYLAnimationEngines.dispatchResourceMissing(context, "a.pag", "not found", null)
        assertTrue(ShadowLog.getLogsForTag("CYLAnimatedItem").any { it.msg.contains("a.pag") && it.msg.contains("not found") })
        context.applicationInfo.flags = context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE.inv()
        ShadowLog.clear()
        CYLAnimationEngines.dispatchResourceMissing(context, "b.pag", "not found", null)
        assertTrue(ShadowLog.getLogsForTag("CYLAnimatedItem").isEmpty())
    }

    @Test
    fun aThrowingViewCallbackStillReachesTheListener() {
        val activity = activity()
        CYLAnimationEngines.resourceMissingListener = { resource, reason -> global += resource to reason }
        CYLAnimationEngines.dispatchResourceMissing(activity, "a.pag", "not found") { _, _ -> error("boom") }
        assertEquals(listOf("a.pag" to "not found"), global)
    }
}
