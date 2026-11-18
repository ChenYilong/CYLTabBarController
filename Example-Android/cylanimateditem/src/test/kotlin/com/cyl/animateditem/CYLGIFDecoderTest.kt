package com.cyl.animateditem

import android.util.Base64
import android.widget.ImageView
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner

/**
 * [EN] `CYLGIFDecoder` (B24: `android.graphics.Movie` draws one frame on API 37 whatever time it is given). The GIFs were
 *      made with Pillow: three 4 x 4 frames (red, green, blue; 100, 200, 300 ms), and a 40 x 30 interlaced image of random
 *      indices (palette entry k = (3k, 3k + 1, 3k + 2)), which makes the LZW codes grow to 9 bits and more.
 * [CN] `CYLGIFDecoder`（B24：`android.graphics.Movie` 在 API 37 上无论给定什么时刻都只绘制一帧）。GIF 由 Pillow 生成：三个 4 x 4 帧
 *      （红、绿、蓝；100、200、300 毫秒），以及一个 40 x 30 的隔行随机索引图像（调色板第 k 项 = (3k, 3k + 1, 3k + 2)），使 LZW 码长增长到 9 位以上。
 */
@RunWith(RobolectricTestRunner::class)
class CYLGIFDecoderTest {
    private val threeFrames = Base64.decode(CYLGIFDecoderTestData.THREE_FRAMES, Base64.DEFAULT)

    @Test
    fun framesDelaysAndColors() {
        val frames = CYLGIFDecoder.decode(threeFrames)!!
        assertEquals(4, frames.width)
        assertEquals(4, frames.height)
        assertEquals(3, frames.frameCount)
        assertArrayEquals(intArrayOf(100, 200, 300), frames.delays)
        assertEquals(600, frames.duration)
        assertEquals(0xFFFF0000.toInt(), frames.pixels[0][0])
        assertEquals(0xFF00FF00.toInt(), frames.pixels[1][15])
        assertEquals(0xFF0000FF.toInt(), frames.pixels[2][5])
    }

    @Test
    fun theFrameAtATime() {
        val frames = CYLGIFDecoder.decode(threeFrames)!!
        assertEquals(0, frames.frameAt(0))
        assertEquals(0, frames.frameAt(99))
        assertEquals(1, frames.frameAt(100))
        assertEquals(1, frames.frameAt(299))
        assertEquals(2, frames.frameAt(300))
        assertEquals("clamped to the pass", 2, frames.frameAt(5000))
    }

    @Test
    fun interlacedImageWithGrowingCodes() {
        val frames = CYLGIFDecoder.decode(Base64.decode(CYLGIFDecoderTestData.NOISE, Base64.DEFAULT))!!
        assertEquals(40, frames.width)
        assertEquals(30, frames.height)
        val pixels = frames.pixels[0]
        assertEquals(0xFF666768.toInt(), pixels[0])
        assertEquals(0xFFB3B4B5.toInt(), pixels[1])
        assertEquals(0xFF444546.toInt(), pixels[39])
        assertEquals(0xFF2B2C2D.toInt(), pixels[40])
        assertEquals(0xFFF3F4F5.toInt(), pixels[517])
        assertEquals(0xFF212223.toInt(), pixels[1199])
    }

    @Test
    fun notAGIF() {
        assertNull(CYLGIFDecoder.decode("not a gif at all".toByteArray()))
        assertNull(CYLGIFDecoder.decode(threeFrames.copyOf(20)))
    }

    @Test
    fun theViewShowsTheFrameOfItsTime() {
        val view = CYLGIFTabBarItemAnimationView(ApplicationProvider.getApplicationContext(), ImageView.ScaleType.FIT_CENTER)
        view.setData(threeFrames)
        val player = CYLGIFTabBarItemAnimator.animator.playerForAnimationView(view)!!
        assertEquals(600, view.duration)
        player.progress = 0f
        assertEquals(0, view.shownFrame)
        player.progress = 0.5f
        assertEquals(1, view.shownFrame)
        player.showLastFrame()
        assertEquals(2, view.shownFrame)
        player.stop()
        assertEquals("stop shows the first frame", 0, view.shownFrame)
        assertNotNull(CYLGIFDrawable.fromBytes(threeFrames))
    }
}

/** [EN] The test GIFs (see CYLGIFDecoderTest). [CN] 测试用 GIF（见 CYLGIFDecoderTest）。 */
internal object CYLGIFDecoderTestData {
    const val THREE_FRAMES = "R0lGODlhBAAEAIEAAP8AAAAAAAAAAAAAACH/C05FVFNDQVBFMi4wAwEAAAAh+QQECgAAACwAAAAABAAEAAAICQABCBxIsCCAgAAh+QQFFAABACwAAAAABAAEAIEA/wAAAAAAAAAAAAAICQABCBxIsCCAgAAh+QQFHgABACwAAAAABAAEAIEAAP8AAAAAAAAAAAAICQABCBxIsCCAgAA7"
    const val NOISE = "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"
}
