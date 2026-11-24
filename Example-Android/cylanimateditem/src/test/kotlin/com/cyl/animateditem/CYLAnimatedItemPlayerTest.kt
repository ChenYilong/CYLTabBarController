package com.cyl.animateditem

import android.app.Activity
import android.view.View
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.shadows.ShadowLooper
import java.util.concurrent.TimeUnit

/**
 * [EN] `CYLAnimatedItemView.animatedItemPlayer` (the HarmonyOS `CYLAnimatedItemPlayer` contract), `animationRestartToken`
 *      and `drivesAnimationPlayback`, over a fake engine.
 * [CN] `CYLAnimatedItemView.animatedItemPlayer`（鸿蒙 `CYLAnimatedItemPlayer` 契约）、`animationRestartToken` 与
 *      `drivesAnimationPlayback`，使用模拟引擎。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemPlayerTest {

    /**
     * [EN] An engine player that remembers speed, loops and progress. [CN] 记住速度、循环与进度的引擎播放器。
     */
    class FakePlayer(override val animationView: View) : CYLTabBarItemAnimationPlayer {
        var running = false
        var plays = 0
        override var progress = 0f
        override var animationSpeed = 1f
        override var loops = false
        override val isPlaying: Boolean? get() = running
        override fun play() { plays++; running = true; progress = 0f }
        override fun showLastFrame() { running = false; progress = 1f }
        override fun stop() { running = false }
    }

    class FakeSource : CYLTabBarItemAnimationViewMaking {
        val players = HashMap<View, FakePlayer>()
        override fun animationViewWithURL(context: android.content.Context, url: String, size: CYLSize, contentMode: android.widget.ImageView.ScaleType): View =
            View(context).also { players[it] = FakePlayer(it) }
        override fun playerForView(view: View?): CYLTabBarItemAnimationPlayer? = players[view]
        override fun isAnimationView(view: View?) = players.containsKey(view)
    }

    private fun frames(ms: Long = 100) = ShadowLooper.idleMainLooper(ms, TimeUnit.MILLISECONDS)

    private fun make(url: String, drives: Boolean, selected: Boolean = false): Pair<CYLAnimatedItemView, FakeSource> {
        val source = FakeSource()
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val view = CYLAnimatedItemView(activity).apply {
            animationSource = source
            drivesAnimationPlayback = drives
            isSelected = selected
            animationURL = url
            activity.setContentView(this)
        }
        return view to source
    }

    private fun enginePlayer(view: CYLAnimatedItemView, source: FakeSource) = source.players.getValue(view.animationView!!)

    @Test
    fun theSupportFlagsFollowTheTypeOfTheFile() {
        val expected = mapOf(
            "a.json" to listOf(true, true, true, true), "a.pag" to listOf(true, true, true, false),
            "a.riv" to listOf(true, true, false, true), "a.svga" to listOf(true, true, true, false),
            "a.gif" to listOf(false, true, false, false),
        )
        for ((file, flags) in expected) {
            val player = make(file, false).first.animatedItemPlayer
            assertEquals(file, flags, listOf(player.supportsSpeed, player.supportsLoops, player.supportsProgress, player.supportsColors))
        }
        val unknown = make("a.fake", false).first.animatedItemPlayer
        assertFalse(unknown.supportsSpeed || unknown.supportsLoops || unknown.supportsProgress || unknown.supportsColors)
    }

    @Test
    fun playStopAtProgressSpeedAndLoopsGoThroughTheEngine() {
        val (view, source) = make("a.json", false)
        val engine = enginePlayer(view, source)
        val player = view.animatedItemPlayer
        player.speed = 2f
        player.loops = true
        assertEquals(2f, engine.animationSpeed, 0f)
        assertTrue(engine.loops)
        player.play()
        assertEquals(1, engine.plays)
        assertEquals(true, player.isPlaying)
        player.stopAtProgress(0.5f)
        assertEquals(false, player.isPlaying)
        assertEquals(0.5f, engine.progress, 0f)
        assertEquals(0.5f, player.progress, 0f)
    }

    @Test
    fun onEndedFiresWhenAPlayOncePassEndsAndNullRemovesIt() {
        val (view, source) = make("a.json", false)
        val engine = enginePlayer(view, source)
        var ended = 0
        view.animatedItemPlayer.onEnded = { ended++ }
        view.animatedItemPlayer.play()
        frames()
        engine.running = false
        frames()
        assertEquals(1, ended)
        view.animatedItemPlayer.onEnded = null
        view.animatedItemPlayer.play()
        frames()
        engine.running = false
        frames()
        assertEquals("removed", 1, ended)
    }

    @Test
    fun aGrownRestartTokenRestartsFromTheStartOnlyWhileTheItemDrives() {
        val (driving, drivingSource) = make("a.json", true)
        val engine = enginePlayer(driving, drivingSource)
        engine.progress = 0.7f
        assertEquals("the value at creation is not a restart", 0, engine.plays)
        driving.animationRestartToken = 1
        assertEquals(1, engine.plays)
        assertEquals(0f, engine.progress, 0f)
        driving.animationRestartToken = 1
        assertEquals("the same token again does nothing", 1, engine.plays)

        val (hosted, hostedSource) = make("a.json", false)
        hosted.animationRestartToken = 5
        assertEquals("a host-driven item ignores the token", 0, enginePlayer(hosted, hostedSource).plays)
    }

    @Test
    fun theDefaultRulesPlayOnSelectionAndRestOnDeselectionWhenTheItemDrives() {
        val (view, source) = make("a.json", true)
        val engine = enginePlayer(view, source)
        view.isSelected = true
        assertEquals("selected: plays once from the start", 1, engine.plays)
        assertFalse(view.animationLoops)
        view.isSelected = false
        assertEquals(false, engine.running)
        assertEquals("unselected: rests at the resting progress", 0f, engine.progress, 0f)

        val (selectedAtStart, startSource) = make("a.json", true, selected = true)
        assertEquals("a selected item plays when its animation is ready", 1, enginePlayer(selectedAtStart, startSource).plays)
    }

    @Test
    fun aHostDrivenItemTouchesNoEngineOnSelectionChanges() {
        val (view, source) = make("a.json", false)
        val engine = enginePlayer(view, source)
        view.isSelected = true
        view.isSelected = false
        assertEquals(0, engine.plays)
        view.animatedItemPlayer.play()
        assertEquals("the host plays through the player", 1, engine.plays)
    }

    @Test
    fun aNewViewAppliesTheDefaultPlaybackRulesLikeIOSAndHarmonyOS() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        assertTrue(CYLAnimatedItemView(activity).drivesAnimationPlayback)
    }

    @Test
    fun withoutAnimationViewThePlayerIsInert() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val player = CYLAnimatedItemView(activity).animatedItemPlayer
        player.play()
        assertNull(player.isPlaying)
        assertEquals(0f, player.progress, 0f)
        player.applyColors(mapOf("a" to 1))
        assertFalse(player.supportsSpeed)
    }
}
