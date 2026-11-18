// [EN] The method names are the iOS names on purpose (`cyl_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.animateditem

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.drawable.Drawable
import android.os.SystemClock
import android.view.View
import android.widget.ImageView

/**
 * [EN] `CYLGIFTabBarItemAnimator` (issue #605): GIF tab icons that play once when the tab is selected, through the short
 *      path: a `CYLTabBarItemViewAnimator` for ".gif" files whose views (`CYLGIFTabBarItemAnimationView`) play themselves.
 *      The platform decodes GIFs (as ImageIO does on iOS), so it is always registered. A GIF given as
 *      `CYLTabBarItemImage` is an image, not an animation.
 * [CN] `CYLGIFTabBarItemAnimator`（issue #605）：选中 Tab 时播放一次的 GIF 图标，走简便路径：".gif" 文件的 `CYLTabBarItemViewAnimator`，其视图
 *      （`CYLGIFTabBarItemAnimationView`）自己播放。GIF 由系统解码（如同 iOS 的 ImageIO），因此总会注册。作为 `CYLTabBarItemImage` 传入的 GIF 是图片，不是动画。
 */
object CYLGIFTabBarItemAnimator {
    /**
     * [EN] The registered animator, e.g. to inject another view provider. [CN] 已注册的 animator，例如用于注入其他视图 provider。
     */
    @JvmStatic
    val animator: CYLTabBarItemViewAnimator by lazy {
        CYLTabBarItemViewAnimator("GIF", listOf("gif"), mapOf(
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationURL to CYLTabBarItemAnimationKeys.CYLTabBarGIFURL,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationFilePath to CYLTabBarItemAnimationKeys.CYLTabBarGIFFilePath,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationSize to CYLTabBarItemAnimationKeys.CYLTabBarGIFSize,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkURL to CYLTabBarItemAnimationKeys.CYLTabBarGIFDarkURL,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkFilePath to CYLTabBarItemAnimationKeys.CYLTabBarGIFDarkFilePath,
        ), CYLGIFTabBarItemAnimationView.Provider)
    }
}

/**
 * [EN] The GIF view of a tab: shows the first frame, plays once when the tab is selected and stays on the last frame;
 *      the tab selected at launch shows the last frame without playing (#389). The frames come from `CYLGIFDecoder`, so
 *      any time of the GIF can be shown on every Android version (`android.graphics.Movie`, used before, draws one frame
 *      on API 37 whatever time it is given, B24). It obeys the player's `loops` (plays again after
 *      each pass), `animationSpeed` (scales the GIF's time) and `progress` (`CYLAnimatedItemView.restartAnimation()`
 *      starts from frame 0), as the Lottie, PAG and Rive players do.
 * [CN] Tab 的 GIF 视图：显示第一帧，选中 Tab 时播放一次并停在最后一帧；启动时选中的 Tab 直接显示最后一帧（#389）。帧来自 `CYLGIFDecoder`，
 *      因此在所有 Android 版本上都能显示 GIF 的任意时刻（之前使用的 `android.graphics.Movie` 在 API 37 上无论给定什么时刻都只绘制一帧，B24）。
 */
@SuppressLint("ViewConstructor") // [EN] Made by its provider, never inflated. [CN] 由 provider 创建，不从 XML 加载。
class CYLGIFTabBarItemAnimationView internal constructor(context: Context, private val contentMode: ImageView.ScaleType) :
    View(context), CYLTabBarItemAnimationPlayableView {

    private var frames: CYLGIFFrames? = null
    private val paint = Paint(Paint.FILTER_BITMAP_FLAG)
    private val matrix = android.graphics.Matrix()
    /**
     * [EN] The time shown, in ms. [CN] 显示的时刻（毫秒）。
     */
    private var time = 0
    /** [EN] A pass is playing. [CN] 正在播放。 */
    private var playing = false
    /** [EN] When the pass started (uptime ms) and the GIF time it started from. [CN] 本次播放开始的时刻（uptime 毫秒）及起始的 GIF 时刻。 */
    private var startUptime = 0L
    private var startTime = 0f
    /** [EN] The next frame of the pass playing. [CN] 当前播放的下一帧。 */
    private val tick = Runnable { advance() }
    /** [EN] Plays again after each pass (`loops`). [CN] 每次播放后再次播放（`loops`）。 */
    private var loops = false
    /** [EN] The speed, 1 = the GIF's own (`animationSpeed`). [CN] 速度，1 = GIF 自身速度（`animationSpeed`）。 */
    private var speed = 1f
    /** [EN] The time shown, in ms (tests). [CN] 显示的时刻（毫秒，测试用）。 */
    internal val shownTime: Int get() = time
    /** [EN] Whether a pass is playing (tests). [CN] 是否正在播放（测试用）。 */
    internal val isPlaying: Boolean get() = playing
    /**
     * [EN] The GIF's length in ms (1 s when the file gives none). [CN] GIF 的时长（毫秒，文件未给出时为 1 秒）。
     */
    val duration: Int get() = frames?.duration?.takeIf { it > 1 } ?: 1000
    /** [EN] The frame shown (tests). [CN] 显示的帧（测试用）。 */
    internal val shownFrame: Int get() = frames?.frameAt(time) ?: 0

    private fun isGIF(bytes: ByteArray): Boolean {
        if (bytes.size < 13) return false
        val signature = String(bytes, 0, 6, Charsets.US_ASCII)
        return signature == "GIF87a" || signature == "GIF89a"
    }

    internal fun setData(bytes: ByteArray) {
        // [EN] Bytes that are not a GIF (a corrupted file, an error page saved as .gif): reported, so the host shows its
        //      image or placeholder; so are GIF bytes with no frame that can be decoded.
        // [CN] 不是 GIF 的数据（文件损坏、保存为 .gif 的错误页面）：报告失败，宿主显示其图片或占位图；无法解码出任何帧的 GIF 数据同样处理。
        val decoded = if (isGIF(bytes)) CYLGIFDecoder.decode(bytes) else null
        if (decoded == null) {
            CYLTabBarItemAnimationFailure.reportLater(this)
            return
        }
        frames = decoded
        CYLTabBarItemAnimationFailure.reportLoaded(this)
        invalidate()
    }

    override fun cyl_playAnimationView() = playFrom(0f)

    /**
     * [EN] Plays the GIF from `fraction` (0…1) at `speed`, on the display's frame clock (`postOnAnimation`) with the GIF's
     *      own time, as Lottie does. Not a ValueAnimator: one ends at once wherever the process's animator duration scale is
     *      0, which an emulator showed with the setting unset (B24), while Lottie kept playing.
     * [CN] 以 `speed` 从 `fraction`（0…1）播放 GIF，基于显示帧时钟（`postOnAnimation`）与 GIF 自身的时间，与 Lottie 相同。不使用 ValueAnimator：
     *      进程的动画时长缩放为 0 时它会立即结束，模拟器在该设置未设置时就出现了这种情况（B24），而 Lottie 仍在播放。
     */
    private fun playFrom(fraction: Float) {
        cancelPass()
        startTime = fraction.coerceIn(0f, 1f) * (duration - 1)
        startUptime = android.os.SystemClock.uptimeMillis()
        time = startTime.toInt()
        playing = true
        invalidate()
        postOnAnimation(tick)
    }

    /**
     * [EN] One frame: the GIF time from the time passed and `speed`; with `loops` it wraps, otherwise it ends on the last frame.
     * [CN] 一帧：根据经过的时间与 `speed` 计算 GIF 时刻；`loops` 时循环，否则停在最后一帧。
     */
    private fun advance() {
        if (!playing) return
        val last = duration - 1
        val elapsed = startTime + (android.os.SystemClock.uptimeMillis() - startUptime) * speed
        if (loops) {
            time = (elapsed % duration).toInt()
        } else if (elapsed >= last) {
            time = last
            playing = false
        } else {
            time = elapsed.toInt()
        }
        invalidate()
        // [EN] At least 10 ms later, on the next display frame: still every frame at 60 Hz, and the clock always moves on
        //      between two ticks (a frame clock with no delay, as in tests, would otherwise repost forever at one instant).
        // [CN] 至少 10 毫秒后、在下一显示帧执行：60 Hz 下仍是每帧一次，且两次之间时钟总会前进（否则无延迟的帧时钟，如测试中，会在同一时刻无限重新提交）。
        if (playing) postOnAnimationDelayed(tick, FRAME_GAP_MS)
    }

    private fun cancelPass() {
        playing = false
        removeCallbacks(tick)
    }

    /** [EN] Where the playing pass is, 0…1. [CN] 当前播放位置，0…1。 */
    private val playingFraction: Float get() = time / (duration - 1).coerceAtLeast(1).toFloat()

    override fun cyl_setAnimationViewLoops(loops: Boolean) {
        if (this.loops == loops) return
        this.loops = loops
        // [EN] Turned off: the pass playing still ends on the last frame; turned on: it goes on and repeats.
        // [CN] 关闭时当前这次播放仍停在最后一帧；开启时继续播放并重复。
        if (isPlaying) playFrom(playingFraction)
    }

    override fun cyl_setAnimationViewSpeed(speed: Float) {
        val next = if (speed > 0f) speed else 1f
        if (this.speed == next) return
        this.speed = next
        // [EN] A pass already playing goes on from where it is at the new speed. [CN] 正在播放的动画从当前位置以新速度继续。
        if (isPlaying) playFrom(playingFraction)
    }

    override fun cyl_setAnimationViewProgress(progress: Float) {
        if (isPlaying) {
            playFrom(progress)
        } else {
            time = (progress.coerceIn(0f, 1f) * (duration - 1)).toInt()
            invalidate()
        }
    }

    override fun cyl_showAnimationViewLastFrame() {
        cancelPass()
        time = duration - 1
        invalidate()
    }

    override fun cyl_stopAnimationView() {
        cancelPass()
        time = 0
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        val frames = frames ?: return
        val movieWidth = frames.width.toFloat()
        val movieHeight = frames.height.toFloat()
        if (width == 0 || height == 0) return
        val scaleX = width / movieWidth
        val scaleY = height / movieHeight
        val (sx, sy) = when (contentMode) {
            ImageView.ScaleType.FIT_XY -> scaleX to scaleY
            ImageView.ScaleType.CENTER_CROP -> maxOf(scaleX, scaleY).let { it to it }
            else -> minOf(scaleX, scaleY).let { it to it }
        }
        matrix.setScale(sx, sy)
        matrix.postTranslate((width - movieWidth * sx) / 2, (height - movieHeight * sy) / 2)
        canvas.drawBitmap(frames.bitmap(frames.frameAt(time)), matrix, paint)
    }

    override fun onDetachedFromWindow() {
        cancelPass()
        super.onDetachedFromWindow()
    }

    private companion object {
        const val FRAME_GAP_MS = 10L
    }

    /**
     * [EN] Provides the views of `CYLGIFTabBarItemAnimator`. [CN] 为 `CYLGIFTabBarItemAnimator` 提供视图。
     */
    object Provider : CYLTabBarItemAnimationViewProviding {
        override fun cyl_animationViewWithFileURL(context: Context, fileURL: String, options: Map<String, String>, contentMode: ImageView.ScaleType): View {
            val view = CYLGIFTabBarItemAnimationView(context, contentMode)
            // [EN] Until the file is here (a download), the host shows its static image or placeholder. [CN] 文件到达之前（下载中），宿主显示其静态图片或占位图。
            CYLTabBarItemAnimationFailure.markLoading(view)
            CYLTabBarItemAnimationFiles.localFile(context, fileURL) { file ->
                // [EN] A missing file, a failed download or an unreadable one: the host shows its image or placeholder.
                // [CN] 文件不存在、下载失败或无法读取：宿主显示其图片或占位图。
                val bytes = try { file?.readBytes() } catch (error: java.io.IOException) { null }
                if (bytes == null || bytes.isEmpty()) CYLTabBarItemAnimationFailure.reportLater(view) else view.setData(bytes)
            }
            return view
        }
    }
}

/**
 * [EN] A GIF given as an image (`CYLTabBarItemImageURL`, `setTabBarItemIconWithURL`, a `CYLTabBarItemImage` Drawable): it
 *      loops, selected or not, as `+[UIImage cyl_animatedImageWithGIFData:]` does on iOS (#605). Only the GIF keys
 *      (`CYLTabBarGIFURL`...) play it once when the tab is selected.
 * [CN] 作为图片传入的 GIF（`CYLTabBarItemImageURL`、`setTabBarItemIconWithURL`、作为 `CYLTabBarItemImage` 的 Drawable）：无论是否选中都循环播放，
 *      与 iOS 的 `+[UIImage cyl_animatedImageWithGIFData:]` 一致（#605）。只有 GIF key（`CYLTabBarGIFURL` 等）才会在选中时播放一次。
 */
class CYLGIFDrawable private constructor(private val frames: CYLGIFFrames) : Drawable(), Runnable {
    private val paint = Paint(Paint.FILTER_BITMAP_FLAG)
    private val start = SystemClock.uptimeMillis()
    private val duration = frames.duration
    private val destination = android.graphics.Rect()

    override fun draw(canvas: Canvas) {
        val bounds = bounds
        if (bounds.isEmpty) return
        val frame = frames.frameAt(((SystemClock.uptimeMillis() - start) % duration).toInt())
        destination.set(bounds)
        canvas.drawBitmap(frames.bitmap(frame), null, destination, paint)
        // [EN] The next frame, about 60 fps, while the drawable is shown. [CN] 显示期间约每秒 60 帧绘制下一帧。
        scheduleSelf(this, SystemClock.uptimeMillis() + FRAME_MILLIS)
    }

    override fun run() = invalidateSelf()
    override fun setAlpha(alpha: Int) { paint.alpha = alpha }
    override fun setColorFilter(colorFilter: ColorFilter?) { paint.colorFilter = colorFilter }
    @Deprecated("Deprecated in Java")
    override fun getOpacity() = PixelFormat.TRANSLUCENT
    override fun getIntrinsicWidth() = frames.width
    override fun getIntrinsicHeight() = frames.height

    companion object {
        private const val FRAME_MILLIS = 16L

        /**
         * [EN] Whether `bytes` start with a GIF signature (GIF87a / GIF89a). [CN] `bytes` 是否以 GIF 签名（GIF87a / GIF89a）开头。
         */
        @JvmStatic
        fun isGIF(bytes: ByteArray): Boolean = bytes.size >= 6 && String(bytes, 0, 6, Charsets.US_ASCII).let { it == "GIF87a" || it == "GIF89a" }

        /**
         * [EN] A looping drawable for GIF `bytes`; null when they are not a GIF. [CN] GIF `bytes` 的循环 Drawable；不是 GIF 时为 null。
         */
        @JvmStatic
        fun fromBytes(bytes: ByteArray): CYLGIFDrawable? {
            if (!isGIF(bytes)) return null
            return CYLGIFDecoder.decode(bytes)?.let { CYLGIFDrawable(it) }
        }
    }
}
