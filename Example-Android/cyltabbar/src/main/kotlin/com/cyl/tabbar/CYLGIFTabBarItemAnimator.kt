// [EN] The method names are the iOS names on purpose (`cyl_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
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
    /** [EN] The registered animator, e.g. to inject another view provider. [CN] 已注册的 animator，例如用于注入其他视图 provider。 */
    @JvmStatic
    val animator: CYLTabBarItemViewAnimator by lazy {
        CYLTabBarItemViewAnimator("GIF", listOf("gif"), mapOf(
            CYLConstants.CYLTabBarAnimationURL to CYLConstants.CYLTabBarGIFURL,
            CYLConstants.CYLTabBarAnimationFilePath to CYLConstants.CYLTabBarGIFFilePath,
            CYLConstants.CYLTabBarAnimationSize to CYLConstants.CYLTabBarGIFSize,
            CYLConstants.CYLTabBarAnimationDarkURL to CYLConstants.CYLTabBarGIFDarkURL,
            CYLConstants.CYLTabBarAnimationDarkFilePath to CYLConstants.CYLTabBarGIFDarkFilePath,
        ), CYLGIFTabBarItemAnimationView.Provider)
    }
}

/**
 * [EN] The GIF view of a tab: shows the first frame, plays once when the tab is selected and stays on the last frame;
 *      the tab selected at launch shows the last frame without playing (#389). Drawn with `android.graphics.Movie`,
 *      which can show any time of the GIF on every Android version.
 * [CN] Tab 的 GIF 视图：显示第一帧，选中 Tab 时播放一次并停在最后一帧；启动时选中的 Tab 直接显示最后一帧（#389）。用 `android.graphics.Movie`
 *      绘制，它能在所有 Android 版本上显示 GIF 的任意时刻。
 */
@SuppressLint("ViewConstructor") // [EN] Made by its provider, never inflated. [CN] 由 provider 创建，不从 XML 加载。
@Suppress("DEPRECATION") // [EN] Movie is deprecated, but it is the only API that seeks a GIF on API 23+. [CN] Movie 已废弃，但它是 API 23+ 上唯一能定位 GIF 时刻的接口。
class CYLGIFTabBarItemAnimationView internal constructor(context: Context, private val contentMode: ImageView.ScaleType) :
    View(context), CYLTabBarItemAnimationPlayableView {

    private var movie: android.graphics.Movie? = null
    /** [EN] The time shown, in ms. [CN] 显示的时刻（毫秒）。 */
    private var time = 0
    private var animator: ValueAnimator? = null
    /** [EN] The GIF's length in ms (1 s when the file gives none). [CN] GIF 的时长（毫秒，文件未给出时为 1 秒）。 */
    val duration: Int get() = movie?.duration()?.takeIf { it > 0 } ?: 1000

    init {
        // [EN] Movie draws on a software canvas. [CN] Movie 在软件画布上绘制。
        setLayerType(LAYER_TYPE_SOFTWARE, null)
    }

    internal fun setData(bytes: ByteArray) {
        movie = android.graphics.Movie.decodeByteArray(bytes, 0, bytes.size)
        invalidate()
    }

    override fun cyl_playAnimationView() {
        animator?.cancel()
        animator = ValueAnimator.ofInt(0, duration - 1).apply {
            duration = this@CYLGIFTabBarItemAnimationView.duration.toLong()
            interpolator = android.view.animation.LinearInterpolator()
            addUpdateListener { time = it.animatedValue as Int; invalidate() }
            start()
        }
    }

    override fun cyl_showAnimationViewLastFrame() {
        animator?.cancel()
        time = duration - 1
        invalidate()
    }

    override fun cyl_stopAnimationView() {
        animator?.cancel()
        time = 0
        invalidate()
    }

    override fun onDraw(canvas: Canvas) {
        val movie = movie ?: return
        val movieWidth = movie.width().toFloat()
        val movieHeight = movie.height().toFloat()
        if (movieWidth <= 0 || movieHeight <= 0 || width == 0 || height == 0) return
        val scaleX = width / movieWidth
        val scaleY = height / movieHeight
        val (sx, sy) = when (contentMode) {
            ImageView.ScaleType.FIT_XY -> scaleX to scaleY
            ImageView.ScaleType.CENTER_CROP -> maxOf(scaleX, scaleY).let { it to it }
            else -> minOf(scaleX, scaleY).let { it to it }
        }
        canvas.save()
        canvas.translate((width - movieWidth * sx) / 2, (height - movieHeight * sy) / 2)
        canvas.scale(sx, sy)
        movie.setTime(time)
        movie.draw(canvas, 0f, 0f)
        canvas.restore()
    }

    override fun onDetachedFromWindow() {
        animator?.cancel()
        super.onDetachedFromWindow()
    }

    /** [EN] Provides the views of `CYLGIFTabBarItemAnimator`. [CN] 为 `CYLGIFTabBarItemAnimator` 提供视图。 */
    object Provider : CYLTabBarItemAnimationViewProviding {
        override fun cyl_animationViewWithFileURL(context: Context, fileURL: String, options: Map<String, String>, contentMode: ImageView.ScaleType): View {
            val view = CYLGIFTabBarItemAnimationView(context, contentMode)
            CYLTabBarItemAnimationFiles.localFile(context, fileURL) { file -> file?.readBytes()?.let { view.setData(it) } }
            return view
        }
    }
}
