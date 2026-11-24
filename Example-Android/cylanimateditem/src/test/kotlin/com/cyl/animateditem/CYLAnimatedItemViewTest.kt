package com.cyl.animateditem

import android.app.Activity
import android.content.Context
import android.content.res.Configuration
import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.os.SystemClock
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
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
 * [EN] CYLAnimatedItemView on the JVM: content, layout on both axes, the accessory, the animation through any
 *      `CYLTabBarItemAnimationViewMaking`, gestures (tap, long press, drag), accessibility and subclassing.
 * [CN] JVM 上的 CYLAnimatedItemView：内容、两种方向的布局、附加图标、通过任意 `CYLTabBarItemAnimationViewMaking` 播放动画、手势（点击、长按、
 *      拖拽）、无障碍与继承。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLAnimatedItemViewTest {

    /**
     * [EN] A player that records calls. [CN] 记录调用的播放器。
     */
    class FakePlayer(override val animationView: View) : CYLTabBarItemAnimationPlayer {
        val calls = ArrayList<String>()
        override var progress = 0f
        override var animationSpeed = 1f
        override var loops = false
        override fun play() { calls += "play" }
        override fun showLastFrame() { calls += "last" }
        override fun stop() { calls += "stop" }
        override fun pause() { calls += "pause" }
        override fun resume() { calls += "resume" }
        override fun applyDarkColors(darkColors: Map<String, Int>, configuration: Configuration) { /* [EN] Not needed. [CN] 不需要。 */ }
    }

    /**
     * [EN] An animation source for files ending in ".fake": stands for any animator of the engine. [CN] 处理 ".fake" 文件的动画来源：代表引擎中的任意 animator。
     */
    class FakeSource : CYLTabBarItemAnimationViewMaking {
        val players = HashMap<View, FakePlayer>()
        override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View? =
            if (url.endsWith(".fake")) View(context).also { players[it] = FakePlayer(it) } else null
        override fun playerForView(view: View?): CYLTabBarItemAnimationPlayer? = players[view]
        override fun isAnimationView(view: View?) = players.containsKey(view)
    }

    /**
     * [EN] A tag as another repository would write it: a delete accessory, a badge in the accessibility text, colors per state.
     * [CN] 其他仓库会这样写的标签：删除附加图标、无障碍文本中的角标、各状态的颜色。
     */
    class TagItem(context: Context) : CYLAnimatedItemView(context) {
        var badge: String? = null
            set(value) { field = value; updateAccessibility() }
        var stateChanges = 0
        init {
            accessoryView = View(context).apply { contentDescription = "Delete" }
        }
        override fun accessibilityText(): CharSequence = CYLAnimatedItemAccessibilityText(title, badge?.let { "$it new" })
        override fun onItemStateChanged() { stateChanges++; titleView.setTextColor(if (isSelected) Color.RED else Color.BLACK) }
    }

    private fun activity(): Activity = Robolectric.buildActivity(Activity::class.java).setup().get()

    private fun host(activity: Activity, item: View, width: Int = 400, height: Int = 120): FrameLayout {
        val host = FrameLayout(activity)
        host.addView(item, FrameLayout.LayoutParams(width, height))
        activity.setContentView(host)
        host.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.EXACTLY))
        host.layout(0, 0, width, height)
        return host
    }

    private fun icon() = ColorDrawable(Color.BLUE).apply { setBounds(0, 0, 30, 30) }

    @Test
    fun showsTitleAndIconSideBySide() {
        val activity = activity()
        val item = CYLAnimatedItemView(activity).apply { title = "Home"; image = icon(); iconSizeDp = CYLSize(20f, 20f) }
        host(activity, item)
        assertEquals("Home", item.title)
        assertTrue(item.iconView.width > 0)
        assertTrue("the title follows the icon", item.titleView.left >= item.iconView.right)
        assertTrue("vertically centered", kotlin.math.abs(item.iconView.top + item.iconView.height / 2 - item.height / 2) <= 1)
        assertEquals("Home", item.contentDescription)
    }

    @Test
    fun verticalAxisPutsTheIconAboveTheTitle() {
        val activity = activity()
        val item = CYLAnimatedItemView(activity).apply { title = "Empty"; image = icon(); axis = CYLAnimatedItemAxis.Vertical; iconSizeDp = CYLSize(40f, 40f) }
        host(activity, item, 300, 300)
        assertTrue(item.titleView.top >= item.iconView.bottom)
        assertTrue("horizontally centered", kotlin.math.abs(item.iconView.left + item.iconView.width / 2 - item.width / 2) <= 1)
    }

    @Test
    fun selectedImageAndStateHook() {
        val activity = activity()
        val selected = icon()
        val item = TagItem(activity).apply { title = "Tag"; image = icon(); selectedImage = selected }
        host(activity, item)
        item.isSelected = true
        assertSame(selected, item.iconView.drawable)
        assertEquals(1, item.stateChanges)
        assertEquals(Color.RED, item.titleView.currentTextColor)
    }

    @Test
    fun playsAnyAnimationOfTheSource() {
        val activity = activity()
        val source = FakeSource()
        val item = CYLAnimatedItemView(activity).apply {
            animationSource = source
            image = icon()
            animationLoops = true
            animationSpeed = 2f
            animationURL = "home.fake"
        }
        host(activity, item)
        assertTrue(item.isAnimationReady)
        val player = source.players.values.single()
        assertTrue(player.loops)
        assertEquals(2f, player.animationSpeed, 0f)
        assertEquals("the static icon hides under the animation", View.INVISIBLE, item.iconView.visibility)
        assertEquals(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS, item.animationView!!.importantForAccessibility)
        player.progress = 0.7f
        item.restartAnimation()
        assertEquals("Play all restarts from 0", 0f, player.progress, 0f)
        item.animationRestingProgress = 1f
        item.stopAnimation()
        assertEquals(listOf("play", "stop"), player.calls)
        assertEquals(1f, player.progress, 0f)
        item.showAnimationLastFrame()
        assertEquals("last", player.calls.last())
    }

    @Test
    fun unknownFilesAndFailuresFallBackToTheImage() {
        val activity = activity()
        val source = FakeSource()
        val item = CYLAnimatedItemView(activity).apply { animationSource = source; image = icon(); animationURL = "home.unknown" }
        host(activity, item)
        assertFalse(item.isAnimationReady)
        assertEquals(View.VISIBLE, item.iconView.visibility)
        item.animationURL = "home.fake"
        val view = item.animationView!!
        CYLTabBarItemAnimationFailure.report(view)
        assertNull("a failed file shows the image again", item.animationView)
        assertEquals(View.VISIBLE, item.iconView.visibility)
    }

    @Test
    fun accessoryHasItsOwnTapAndIsPlaced() {
        val activity = activity()
        val item = TagItem(activity).apply { title = "Tag" }
        var itemTaps = 0
        var accessoryTaps = 0
        item.gestureListener = object : CYLAnimatedItemGestureListener {
            override fun onItemTapped(item: CYLAnimatedItemView) { itemTaps++ }
            override fun onAccessoryTapped(item: CYLAnimatedItemView) { accessoryTaps++ }
        }
        host(activity, item)
        val accessory = item.accessoryView!!
        assertEquals("trailing by default", item.width - item.paddingRight, accessory.right)
        assertTrue(accessory.performClick())
        assertEquals(1, accessoryTaps)
        assertEquals(0, itemTaps)
        item.performClick()
        assertEquals(1, itemTaps)
        item.accessoryPlacement = CYLAnimatedItemAccessoryPlacement.Leading
        host(activity.also { (item.parent as ViewGroup).removeView(item) }, item)
        assertEquals(0, accessory.left)
    }

    @Test
    fun accessibilityReadsTitleAndSubclassExtras() {
        val activity = activity()
        val item = TagItem(activity).apply { title = "Messages" }
        item.badge = "3"
        assertEquals("Messages, 3 new", item.contentDescription)
        assertEquals(View.IMPORTANT_FOR_ACCESSIBILITY_NO, item.titleView.importantForAccessibility)
        assertEquals("Delete", item.accessoryView!!.contentDescription)
        val info = android.view.accessibility.AccessibilityNodeInfo.obtain()
        item.isSelected = true
        item.onInitializeAccessibilityNodeInfo(info)
        assertTrue(info.isSelected)
        assertEquals(android.widget.Button::class.java.name, info.className)
    }

    private fun touch(view: View, action: Int, x: Float, y: Float, down: Long) =
        MotionEvent.obtain(down, SystemClock.uptimeMillis(), action, x, y, 0).also { it.setLocation(x, y); view.dispatchTouchEvent(it); it.recycle() }

    @Test
    fun dragsReportAndMoveTheView() {
        val activity = activity()
        val item = CYLAnimatedItemView(activity).apply { title = "Drag"; isDragEnabled = true; dragMovesView = true }
        val events = ArrayList<String>()
        item.gestureListener = object : CYLAnimatedItemGestureListener {
            override fun onItemTapped(item: CYLAnimatedItemView) { events += "tap" }
            override fun onDragBegan(item: CYLAnimatedItemView) { events += "began" }
            override fun onDragChanged(item: CYLAnimatedItemView, dx: Float, dy: Float) { events += "changed" }
            override fun onDragEnded(item: CYLAnimatedItemView, dx: Float, dy: Float, cancelled: Boolean) { events += "ended:${dx.toInt()}" }
        }
        host(activity, item)
        val down = SystemClock.uptimeMillis()
        touch(item, MotionEvent.ACTION_DOWN, 50f, 50f, down)
        touch(item, MotionEvent.ACTION_MOVE, 150f, 50f, down)
        assertEquals("follows the finger", 100f, item.translationX, 0.5f)
        touch(item, MotionEvent.ACTION_UP, 150f, 50f, down)
        assertEquals(listOf("began", "changed", "ended:100"), events)
    }

    @Test
    fun aRefusedDragIsATap() {
        val activity = activity()
        val item = CYLAnimatedItemView(activity).apply { title = "Tap"; isDragEnabled = true }
        val events = ArrayList<String>()
        item.gestureListener = object : CYLAnimatedItemGestureListener {
            override fun shouldBeginDrag(item: CYLAnimatedItemView) = false
            override fun onItemTapped(item: CYLAnimatedItemView) { events += "tap" }
            override fun onDragBegan(item: CYLAnimatedItemView) { events += "began" }
        }
        host(activity, item)
        val down = SystemClock.uptimeMillis()
        touch(item, MotionEvent.ACTION_DOWN, 50f, 50f, down)
        touch(item, MotionEvent.ACTION_UP, 51f, 50f, down)
        assertEquals(listOf("tap"), events)
    }

    @Test
    fun theSharedEngineIsTheDefaultSource() {
        val item = CYLAnimatedItemView(activity())
        assertNotNull(item.animationSource)
        assertSame(CYLAnimatedItemAnimationSource.shared, item.animationSource)
    }

    @Test
    fun postsTheAnimationMomentsAndPausesAndResumes() {
        val activity = activity()
        val source = FakeSource()
        val item = CYLAnimatedItemView(activity).apply { animationSource = source; image = icon(); animationLoops = true; animationURL = "home.fake" }
        host(activity, item)
        val player = source.players.values.single()
        val seen = ArrayList<String>()
        val registry = com.chenyilong.cyldeallocblockexecutor.LifecycleRegistry.of(item)
        for (name in listOf(com.chenyilong.cyldeallocblockexecutor.AnimationEvents.didStart, com.chenyilong.cyldeallocblockexecutor.AnimationEvents.didPause,
            com.chenyilong.cyldeallocblockexecutor.AnimationEvents.didResume, com.chenyilong.cyldeallocblockexecutor.AnimationEvents.didStop)) {
            registry.addCustomCallback<Any>(name) { _, _, info -> seen += "${info.customEvent}${info.userInfo?.get("finished")?.let { " finished=$it" } ?: ""}" }
        }
        item.pauseAnimation()
        assertEquals("nothing plays yet: nothing to pause", emptyList<String>(), seen)
        item.playAnimation()
        item.pauseAnimation()
        item.pauseAnimation()
        item.resumeAnimation()
        item.resumeAnimation()
        item.stopAnimation()
        assertEquals(listOf("cyl.animation.didStart", "cyl.animation.didPause", "cyl.animation.didResume", "cyl.animation.didStop finished=false"), seen)
        assertEquals(listOf("play", "pause", "resume", "stop"), player.calls)
    }

    @Test
    fun pausesPlayingItemsWhileTheUserScrollsAndResumesAfterwards() {
        val activity = activity()
        val source = FakeSource()
        val item = CYLAnimatedItemView(activity).apply { animationSource = source; image = icon(); animationLoops = true; animationURL = "home.fake" }
        host(activity, item)
        val player = source.players.values.single()
        item.playAnimation()
        CYLAnimatedItemView.pausesAnimationsWhileUserScrolls = true
        try {
            val scroller = com.chenyilong.cyldeallocblockexecutor.LifecycleRegistry.of(Any()).also { it.hookInstalled = true }
            scroller.fireAutomatic(com.chenyilong.cyldeallocblockexecutor.LifecycleEvent.scrollWillBeginDragging, com.chenyilong.cyldeallocblockexecutor.LifecycleTiming.afterSuper)
            assertEquals(listOf("play", "pause"), player.calls)
            scroller.fireAutomatic(com.chenyilong.cyldeallocblockexecutor.LifecycleEvent.scrollDidEndScrolling, com.chenyilong.cyldeallocblockexecutor.LifecycleTiming.afterSuper)
            assertEquals(listOf("play", "pause", "resume"), player.calls)
        } finally {
            CYLAnimatedItemView.pausesAnimationsWhileUserScrolls = false
            com.chenyilong.cyldeallocblockexecutor.LifecycleCenter.reset()
        }
        assertFalse(CYLAnimatedItemView.pausesAnimationsWhileUserScrolls)
    }
}
