package com.cyl.animateditem

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import com.cyl.tabbar.CYLSize
import com.cyl.tabbar.CYLTabBarItemAnimationFailure
import com.cyl.tabbar.CYLTabBarItemAnimationPlayer
import com.cyl.tabbar.CYLTabBarItemAnimationViewMaking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.File

/**
 * [EN] Animation files that fail: missing, empty, corrupted, or failing after the view was made (a parse error, a failed
 *      download). Each one falls back to the static image, or to the placeholder when there is none; nothing crashes.
 * [CN] 失败的动画文件：不存在、为空、已损坏，或视图创建后才失败（解析错误、下载失败）。都会回退到静态图片，没有静态图片时回退到占位图；不会崩溃。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemFailureTest {

    /**
     * [EN] Plays any file; counts how often it is asked. [CN] 能播放任何文件；记录被请求的次数。
     */
    class CountingSource : CYLTabBarItemAnimationViewMaking {
        var requests = 0
        val views = ArrayList<View>()
        private val players = HashMap<View, CYLTabBarItemAnimationPlayer>()
        override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View {
            requests++
            return View(context).also { view ->
                views += view
                players[view] = object : CYLTabBarItemAnimationPlayer {
                    override val animationView: View = view
                    override fun play() { /* [EN] Nothing to draw. [CN] 无需绘制。 */ }
                    override fun showLastFrame() { /* [EN] Nothing to draw. [CN] 无需绘制。 */ }
                    override fun stop() { /* [EN] Nothing to draw. [CN] 无需绘制。 */ }
                }
            }
        }
        override fun playerForView(view: View?) = players[view]
        override fun isAnimationView(view: View?) = players.containsKey(view)
    }

    private fun activity(): Activity = Robolectric.buildActivity(Activity::class.java).setup().get()

    private fun hosted(activity: Activity, item: CYLAnimatedItemView): CYLAnimatedItemView {
        val host = FrameLayout(activity)
        host.addView(item, FrameLayout.LayoutParams(400, 120))
        activity.setContentView(host)
        return item
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    private fun tempFile(activity: Activity, name: String, bytes: ByteArray): File =
        File(activity.cacheDir, name).apply { writeBytes(bytes) }

    @Test
    fun aMissingLocalFileShowsThePlaceholderWithoutAskingTheEngine() {
        val activity = activity()
        val source = CountingSource()
        val item = hosted(activity, CYLAnimatedItemView(activity).apply { animationSource = source; title = "Home" })
        item.animationURL = File(activity.cacheDir, "missing.json").absolutePath
        assertEquals(0, source.requests)
        assertNotNull(item.iconView.drawable)
        item.animationURL = "file://" + File(activity.cacheDir, "missing2.json").absolutePath
        item.animationURL = "file:///android_asset/missing.json"
        assertEquals(0, source.requests)
        assertFalse(item.isAnimationReady)
        assertNotNull("the placeholder", item.iconView.drawable)
    }

    @Test
    fun anEmptyFileIsMissingAndAFullOneIsAsked() {
        val activity = activity()
        val source = CountingSource()
        val item = hosted(activity, CYLAnimatedItemView(activity).apply { animationSource = source })
        item.animationURL = tempFile(activity, "empty.json", ByteArray(0)).absolutePath
        assertEquals(0, source.requests)
        assertNotNull(item.iconView.drawable)
        item.animationURL = tempFile(activity, "full.json", "{}".toByteArray()).absolutePath
        assertEquals(1, source.requests)
        assertTrue(item.isAnimationReady)
    }

    @Test
    fun aFailureReportedLaterShowsThePlaceholder() {
        val activity = activity()
        val source = CountingSource()
        val item = hosted(activity, CYLAnimatedItemView(activity).apply { animationSource = source; title = "Home"; animationURL = "https://example.com/home.json" })
        assertTrue(item.isAnimationReady)
        CYLTabBarItemAnimationFailure.reportLater(source.views.single())
        idle()
        assertFalse("a parse error or a failed download drops the animation", item.isAnimationReady)
        assertNotNull("the placeholder", item.iconView.drawable)
        assertEquals(View.VISIBLE, item.iconView.visibility)
    }

    @Test
    fun aFailureReportedLaterWithAnImageShowsTheImage() {
        val activity = activity()
        val source = CountingSource()
        val image = ColorDrawable(Color.BLUE)
        val item = hosted(activity, CYLAnimatedItemView(activity).apply { animationSource = source; this.image = image; animationURL = "https://example.com/home.json" })
        assertEquals(View.INVISIBLE, item.iconView.visibility)
        CYLTabBarItemAnimationFailure.reportLater(source.views.single())
        idle()
        assertSame(image, item.iconView.drawable)
        assertEquals(View.VISIBLE, item.iconView.visibility)
    }

    @Test
    fun aReportForAnOldViewIsIgnored() {
        val activity = activity()
        val source = CountingSource()
        val item = hosted(activity, CYLAnimatedItemView(activity).apply { animationSource = source; animationURL = "https://example.com/a.json" })
        val old = source.views.single()
        item.animationURL = "https://example.com/b.json"
        CYLTabBarItemAnimationFailure.reportLater(old)
        idle()
        assertTrue("the current animation stays", item.isAnimationReady)
    }

    @Test
    fun aCorruptedGIFFallsBackThroughTheRealEngine() {
        val activity = activity()
        val item = hosted(activity, CYLAnimatedItemView(activity).apply { title = "Home" })
        item.animationURL = tempFile(activity, "broken.gif", "not a gif at all".toByteArray()).absolutePath
        idle()
        assertFalse("a corrupted GIF does not stay as an empty animation", item.isAnimationReady)
        assertNull(item.animationView)
        assertNotNull("the placeholder", item.iconView.drawable)
        // [EN] A valid 1 x 1 GIF89a still plays. [CN] 有效的 1 x 1 GIF89a 仍可播放。
        val valid = android.util.Base64.decode("R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==", android.util.Base64.DEFAULT)
        item.animationURL = tempFile(activity, "valid.gif", valid).absolutePath
        idle()
        assertTrue(item.isAnimationReady)
    }
}
