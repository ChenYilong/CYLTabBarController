package com.cyl.animateditem

import android.app.Activity
import android.content.Context
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import com.cyl.tabbar.CYLSize
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
import org.robolectric.annotation.Config

/**
 * [EN] Image and animation edge cases: an animation file without an engine (or library) never crashes nor changes the
 *      layout; with both, the static image is the fallback and the animation wins only when it can play.
 *      This test classpath has no Lottie, libpag, Rive or SVGA library: the shared engine stands for "no engine".
 * [CN] 图片与动画的边界情况：没有引擎（或动画库）时传入动画文件不会崩溃，也不会改变布局；同时传入两者时，静态图片兜底，只有能播放时才优先展示动画。
 *      本测试的 classpath 中没有 Lottie、libpag、Rive、SVGA：共用引擎即代表「没有引擎」。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemEdgeCaseTest {

    private fun activity(): Activity = Robolectric.buildActivity(Activity::class.java).setup().get()

    private fun laidOut(activity: Activity, item: View, width: Int = 400, height: Int = 120): View {
        val host = FrameLayout(activity)
        host.addView(item, FrameLayout.LayoutParams(width, height))
        activity.setContentView(host)
        host.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))
        host.layout(0, 0, width, height)
        return item
    }

    private fun naturalSize(item: View): Pair<Int, Int> {
        item.measure(View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED), View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED))
        return item.measuredWidth to item.measuredHeight
    }

    private fun icon() = ColorDrawable(Color.BLUE).apply { setBounds(0, 0, 30, 30) }

    /**
     * [EN] A source that can play ".fake" files, standing for an engine with its library. [CN] 能播放 ".fake" 的来源，代表带动画库的引擎。
     */
    class PlayingSource : CYLTabBarItemAnimationViewMaking {
        private val players = HashMap<View, CYLTabBarItemAnimationPlayer>()
        override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View? =
            if (url.endsWith(".fake")) View(context).also { view ->
                players[view] = object : CYLTabBarItemAnimationPlayer {
                    override val animationView: View = view
                    override fun play() { /* [EN] Nothing to draw. [CN] 无需绘制。 */ }
                    override fun showLastFrame() { /* [EN] Nothing to draw. [CN] 无需绘制。 */ }
                    override fun stop() { /* [EN] Nothing to draw. [CN] 无需绘制。 */ }
                }
            } else null
        override fun playerForView(view: View?) = players[view]
        override fun isAnimationView(view: View?) = players.containsKey(view)
    }

    @Test
    fun onlyAnAnimationFileWithoutAnEngineShowsThePlaceholder() {
        val activity = activity()
        val item = CYLAnimatedItemView(activity).apply { title = "Home"; animationURL = "file:///android_asset/home.json" }
        assertFalse(item.isAnimationReady)
        assertNull(item.animationView)
        laidOut(activity, item)
        val placeholder = item.iconView.drawable
        assertNotNull("no static image, the file cannot play: the placeholder", placeholder)
        assertEquals(View.VISIBLE, item.iconView.visibility)
        val side = (24 * activity.resources.displayMetrics.density).toInt()
        assertEquals("a tab icon's size", side, item.iconView.width)
        assertEquals(side, placeholder!!.intrinsicWidth)
        assertTrue(item.titleView.left >= item.iconView.right)
        item.playAnimation()
        item.restartAnimation()
        item.stopAnimation()
        item.showAnimationLastFrame()
        assertEquals("the file is kept for later", "file:///android_asset/home.json", item.animationURL)
        item.animationSource = PlayingSource()
        item.animationURL = "home.fake"
        assertTrue(item.isAnimationReady)
        assertEquals("the animation wins once it can play", View.INVISIBLE, item.iconView.visibility)
    }

    @Test
    fun anEmptyPlaceholderKeepsTheTitleLayout() {
        val activity = activity()
        val titleOnly = CYLAnimatedItemView(activity).apply { title = "Home" }
        val item = CYLAnimatedItemView(activity).apply {
            title = "Home"; placeholderImage = android.graphics.drawable.ColorDrawable(Color.TRANSPARENT)
            animationURL = "file:///android_asset/home.json"
        }
        assertEquals(naturalSize(titleOnly), naturalSize(item))
        val custom = icon().apply { setBounds(0, 0, 10, 10) }
        val shaped = android.graphics.drawable.ShapeDrawable().apply { intrinsicWidth = 20; intrinsicHeight = 20 }
        item.placeholderImage = shaped
        assertSame("a custom placeholder", shaped, item.iconView.drawable)
        item.image = custom
        assertSame("a static image wins over the placeholder", custom, item.iconView.drawable)
    }

    @Test
    fun aSourceThatThrowsFallsBackToTheImage() {
        val activity = activity()
        val item = CYLAnimatedItemView(activity).apply {
            image = icon()
            animationSource = object : CYLTabBarItemAnimationViewMaking {
                override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View? = throw IllegalStateException("broken")
                override fun playerForView(view: View?): CYLTabBarItemAnimationPlayer? = null
                override fun isAnimationView(view: View?) = false
            }
            animationURL = "home.fake"
        }
        laidOut(activity, item)
        assertNull(item.animationView)
        assertEquals(View.VISIBLE, item.iconView.visibility)
    }

    @Test
    fun bothWithoutAnEngineShowTheStaticImage() {
        val activity = activity()
        val image = icon()
        val item = CYLAnimatedItemView(activity).apply { title = "Home"; this.image = image; animationURL = "file:///android_asset/home.json" }
        laidOut(activity, item)
        assertFalse(item.isAnimationReady)
        assertSame(image, item.iconView.drawable)
        assertEquals(View.VISIBLE, item.iconView.visibility)
        assertTrue(item.iconView.width > 0)
        val imageOnly = CYLAnimatedItemView(activity).apply { title = "Home"; this.image = icon() }
        assertEquals("the same layout as the image alone", naturalSize(imageOnly), naturalSize(item))
    }

    @Test
    fun bothWithAnEnginePreferTheAnimation() {
        val activity = activity()
        val item = CYLAnimatedItemView(activity).apply {
            title = "Home"; image = icon(); iconSizeDp = CYLSize(24f, 24f)
            animationSource = PlayingSource()
            animationURL = "home.fake"
        }
        laidOut(activity, item)
        assertTrue(item.isAnimationReady)
        val animation = assertNotNullView(item.animationView)
        assertEquals("the static image waits under the animation", View.INVISIBLE, item.iconView.visibility)
        assertEquals("the animation takes the icon's place", item.iconView.left, animation.left)
        assertEquals(item.iconView.width, animation.width)
        item.animationURL = "home.json"
        assertFalse("a file the engine cannot play falls back to the image", item.isAnimationReady)
        assertEquals(View.VISIBLE, item.iconView.visibility)
    }

    private fun assertNotNullView(view: View?): View {
        assertNotNull(view)
        return view!!
    }
}
