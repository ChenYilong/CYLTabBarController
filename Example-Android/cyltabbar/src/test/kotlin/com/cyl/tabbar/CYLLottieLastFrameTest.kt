package com.cyl.tabbar

import android.app.Activity
import android.os.Looper
import android.widget.ImageView
import com.cyl.animateditem.CYLSize
import com.cyl.animateditem.CYLTabBarItemAnimationFactory
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.File

/**
 * [EN] The real lottie-android: a progress set before the composition is loaded (a selected tag resting on its last frame) is still
 *      the progress once the composition has loaded, not frame 0.
 * [CN] 真实的 lottie-android：在动画数据加载完成之前设置的进度（停在最后一帧的选中 Tab），加载完成后仍然是该进度，而不是第 0 帧。
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CYLLottieLastFrameTest {

    private fun lottieFile() = File.createTempFile("tab", ".json").apply {
        writeText("""{"v":"5.7.4","fr":30,"ip":0,"op":30,"w":30,"h":30,"layers":[{"ty":4,"nm":"Shape","ip":0,"op":30,"st":0,"ks":{},"shapes":[{"ty":"fl","nm":"Fill 1","c":{"a":0,"k":[1,0,0,1]},"o":{"a":0,"k":100}}]}]}""")
    }

    private fun waitForComposition(view: android.view.View) {
        val deadline = System.currentTimeMillis() + 10_000
        while (System.currentTimeMillis() < deadline) {
            shadowOf(Looper.getMainLooper()).idle()
            if (view.javaClass.getMethod("getComposition").invoke(view) != null) break
            Thread.sleep(20)
        }
        shadowOf(Looper.getMainLooper()).idle()
        assertNotNull("the composition loaded", view.javaClass.getMethod("getComposition").invoke(view))
    }

    @Test
    fun lastFrameSetBeforeTheCompositionLoadsSurvivesTheLoad() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val view = CYLTabBarItemAnimationFactory.animationViewWithURL(activity, lottieFile().absolutePath, CYLSize(30f, 30f), ImageView.ScaleType.FIT_CENTER)!!
        val player = CYLTabBarItemAnimationFactory.playerForView(view)!!
        player.progress = 0f
        player.showLastFrame()
        waitForComposition(view)
        assertEquals("the last frame, not frame 0", 1f, player.progress, 0.01f)
    }

    @Test
    fun theLastProgressAskedForBeforeTheLoadWins() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val view = CYLTabBarItemAnimationFactory.animationViewWithURL(activity, lottieFile().absolutePath, CYLSize(30f, 30f), ImageView.ScaleType.FIT_CENTER)!!
        val player = CYLTabBarItemAnimationFactory.playerForView(view)!!
        player.showLastFrame()
        player.stop()
        waitForComposition(view)
        assertEquals("stop() came last", 0f, player.progress, 0.01f)
    }
}
