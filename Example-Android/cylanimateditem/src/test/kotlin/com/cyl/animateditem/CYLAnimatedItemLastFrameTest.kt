package com.cyl.animateditem

import android.app.Activity
import android.content.Context
import android.content.res.Configuration
import android.view.View
import android.widget.ImageView
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/**
 * [EN] `showsLastFrameWhenSelected` for self-driven and host-driven items (a ClassifyMenu tag drives the player itself): a selected
 *      item ends on the last frame, also when it was selected before the animation view existed or loaded, and nothing plays after it.
 * [CN] 自行驱动与宿主驱动条目的 `showsLastFrameWhenSelected`（ClassifyMenu 的标签自己驱动播放器）：选中的条目最终停在最后一帧，
 *      即使在动画视图创建或加载之前就被选中，之后也不会播放。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemLastFrameTest {

    /** Records every progress-affecting call in order. */
    class RecordingPlayer(override val animationView: View, private val log: MutableList<String>) : CYLTabBarItemAnimationPlayer {
        override var progress = 0f
            set(value) { field = value; log += "progress=$value" }
        override var animationSpeed = 1f
        override var loops = false
        override fun play() { log += "play" }
        override fun showLastFrame() { log += "last" }
        override fun stop() { log += "stop" }
        override fun pause() { log += "pause" }
        override fun resume() { log += "resume" }
        override fun applyDarkColors(darkColors: Map<String, Int>, configuration: Configuration) { /* [EN] Not needed. [CN] 不需要。 */ }
    }

    class Source(private val log: MutableList<String>) : CYLTabBarItemAnimationViewMaking {
        val players = HashMap<View, RecordingPlayer>()
        override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View? =
            if (url.endsWith(".fake")) View(context).also { players[it] = RecordingPlayer(it, log) } else null
        override fun playerForView(view: View?): CYLTabBarItemAnimationPlayer? = players[view]
        override fun isAnimationView(view: View?) = players.containsKey(view)
    }

    private val log = ArrayList<String>()

    private fun item(drives: Boolean, option: Boolean): CYLAnimatedItemView {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        return CYLAnimatedItemView(activity).apply {
            animationSource = Source(log)
            drivesAnimationPlayback = drives
            showsLastFrameWhenSelected = option
        }
    }

    private fun CYLAnimatedItemView.load() {
        val view = animationView
        assertNotNull(view)
        cyl_animationViewDidLoad(view!!)
    }

    @Test
    fun hostDrivenItemSelectedBeforeTheViewExistsEndsOnTheLastFrameAfterTheLoad() {
        val item = item(drives = false, option = true)
        item.isSelected = true
        item.animationURL = "home.fake"
        item.load()
        val progress = log.filter { it == "last" || it == "play" || it.startsWith("progress") || it == "stop" }
        assertEquals("the last frame is the final call, nothing plays", "last", progress.last())
        assertEquals(false, log.contains("play"))
    }

    @Test
    fun hostDrivenItemSelectedAfterTheLoadShowsTheLastFrame() {
        val item = item(drives = false, option = true)
        item.animationURL = "home.fake"
        item.load()
        log.clear()
        item.isSelected = true
        assertEquals(listOf("last"), log)
    }

    @Test
    fun hostDrivenItemLoadingWhileSelectedShowsTheLastFrameAgain() {
        val item = item(drives = false, option = true)
        item.animationURL = "home.fake"
        item.isSelected = true
        log.clear()
        item.load()
        assertEquals(listOf("last"), log)
    }

    @Test
    fun turningTheOptionOnOfASelectedHostDrivenItemShowsTheLastFrame() {
        val item = item(drives = false, option = false)
        item.animationURL = "home.fake"
        item.isSelected = true
        log.clear()
        item.showsLastFrameWhenSelected = true
        assertEquals(listOf("last"), log)
    }

    @Test
    fun hostDrivenItemWithoutTheOptionGetsNothingAutomatic() {
        val item = item(drives = false, option = false)
        item.animationURL = "home.fake"
        log.clear()
        item.isSelected = true
        item.load()
        assertEquals(emptyList<String>(), log)
    }

    @Test
    fun selfDrivenItemWithTheOptionShowsTheLastFrameInsteadOfPlaying() {
        val item = item(drives = true, option = true)
        item.isSelected = true
        item.animationURL = "home.fake"
        item.load()
        assertEquals(false, log.contains("play"))
        assertEquals("last", log.last())
    }

    @Test
    fun selfDrivenItemWithoutTheOptionStillPlays() {
        val item = item(drives = true, option = false)
        item.animationURL = "home.fake"
        item.load()
        log.clear()
        item.isSelected = true
        assertEquals(true, log.contains("play"))
        assertEquals(false, log.contains("last"))
    }
}
