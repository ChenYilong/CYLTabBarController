package com.cyl.animateditem

import android.content.Context
import android.view.View
import android.widget.ImageView
import java.lang.reflect.Proxy

/**
 * [EN] `CYLSVGATabBarItemAnimator`: SVGA tab icons with SVGAPlayer-Android (`com.opensource.svgaplayer.SVGAImageView`,
 *      `com.github.yyued:SVGAPlayer-Android`), registered when that library is in the app, like PAG and Rive (iOS
 *      `CYLSVGATabBarItemAnimator`, issue #415). ".svga" files; selecting the tab plays once and keeps the last frame,
 *      deselecting shows the first frame. Parsing is asynchronous: play or stop asked before it ends runs afterwards.
 * [CN] 使用 SVGAPlayer-Android（`com.opensource.svgaplayer.SVGAImageView`，`com.github.yyued:SVGAPlayer-Android`）的 SVGA Tab 图标，
 *      App 中有该库时注册，与 PAG、Rive 相同（iOS `CYLSVGATabBarItemAnimator`，issue #415）。".svga" 文件；选中 Tab 时播放一次并停在最后一帧，
 *      取消选中时显示第一帧。解析是异步的：解析完成前的播放或停止请求在解析后执行。
 */
object CYLSVGATabBarItemAnimator : CYLTabBarItemAnimator {
    internal const val VIEW_CLASS = "com.opensource.svgaplayer.SVGAImageView"
    private const val PARSER_CLASS = "com.opensource.svgaplayer.SVGAParser"
    private const val COMPLETION_CLASS = "com.opensource.svgaplayer.SVGAParser\$ParseCompletion"
    private const val FILL_MODE_CLASS = "com.opensource.svgaplayer.SVGAImageView\$FillMode"

    /**
     * [EN] Whether SVGAPlayer-Android is in the app. [CN] App 中是否有 SVGAPlayer-Android。
     */
    val isAvailable: Boolean get() = CYLReflection.type(VIEW_CLASS) != null

    override val identifier: String = "SVGA"
    override val fileExtensions: List<String> = listOf("svga")
    override val attributeKeys: Map<String, String> = mapOf(
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationURL to CYLTabBarItemAnimationKeys.CYLTabBarSVGAURL,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationFilePath to CYLTabBarItemAnimationKeys.CYLTabBarSVGAFilePath,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationSize to CYLTabBarItemAnimationKeys.CYLTabBarSVGASize,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkURL to CYLTabBarItemAnimationKeys.CYLTabBarSVGADarkURL,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkFilePath to CYLTabBarItemAnimationKeys.CYLTabBarSVGADarkFilePath,
    )

    override fun canAnimateFileAtURL(url: String): Boolean = CYLTabBarAnimationFileExtension(url) == "svga"

    override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View? {
        val view = CYLReflection.newInstance(VIEW_CLASS, context) as? ImageView ?: return null
        view.scaleType = contentMode
        // [EN] Played once, kept on its last frame, never cleared. [CN] 播放一次、停在最后一帧、不清空。
        CYLReflection.call(view, "setLoops", 1)
        CYLReflection.call(view, "setClearsAfterStop", false)
        CYLReflection.call(view, "setClearsAfterDetached", false)
        CYLReflection.enumConstant(FILL_MODE_CLASS, "Forward")?.let { CYLReflection.call(view, "setFillMode", it) }
        val state = SVGAState()
        view.cyl_setTag("cyl_svga_state", state)
        val appContext = context.applicationContext
        // [EN] Until the file is parsed (a download), the host shows its static image or placeholder. [CN] 文件解析完成之前（下载中），宿主显示其静态图片或占位图。
        CYLTabBarItemAnimationFailure.markLoading(view)
        CYLTabBarItemAnimationFiles.localFile(context, url.substringBefore('#')) { file ->
            // [EN] A missing file or a failed download: reported, so the host falls back. [CN] 文件不存在或下载失败：报告失败，宿主回退显示。
            if (file != null) decode(appContext, file, view, state) else CYLTabBarItemAnimationFailure.reportLater(view, CYLResourceMissingReason.NOT_FOUND)
        }
        return view
    }

    override fun playerForAnimationView(view: View): CYLTabBarItemAnimationPlayer? =
        if (CYLReflection.type(VIEW_CLASS)?.isInstance(view) == true) SVGAPlayer(view) else null

    /**
     * [EN] `SVGAParser(context).decodeFromInputStream(stream, cacheKey, completion, closeInputStream = true)`, the
     *      completion made with a dynamic proxy of `SVGAParser.ParseCompletion`; it calls back on the main thread.
     * [CN] `SVGAParser(context).decodeFromInputStream(stream, cacheKey, completion, closeInputStream = true)`，completion 由
     *      `SVGAParser.ParseCompletion` 的动态代理实现；在主线程回调。
     */
    private fun decode(context: Context, file: java.io.File, view: View, state: SVGAState) {
        val parserType = CYLReflection.type(PARSER_CLASS) ?: return
        val completionType = CYLReflection.type(COMPLETION_CLASS) ?: return
        val parser = try { parserType.getConstructor(Context::class.java).newInstance(context) } catch (error: ReflectiveOperationException) { return }
        val completion = Proxy.newProxyInstance(completionType.classLoader, arrayOf(completionType)) { proxy, method, args ->
            when (method.name) {
                "onComplete" -> { CYLReflection.call(view, "setVideoItem", args?.firstOrNull()); state.parsed(view); CYLTabBarItemAnimationFailure.reportLoaded(view) }
                // [EN] A file SVGAPlayer cannot read (corrupted): reported, so the host shows its image or placeholder; the log names it.
                // [CN] SVGAPlayer 无法读取的文件（已损坏）：报告失败，宿主显示其图片或占位图；日志中注明文件。
                "onError" -> { android.util.Log.w("CYLSVGA", "cannot parse " + file.name); CYLTabBarItemAnimationFailure.reportLater(view) }
                "hashCode" -> System.identityHashCode(proxy)
                "equals" -> proxy === args?.firstOrNull()
                "toString" -> "CYLSVGAParseCompletion"
                else -> null
            }
        }
        val stream = file.inputStream()
        val decoded = CYLReflection.callKotlin(parser, "decodeFromInputStream", stream, file.absolutePath, completion, true, CYLReflection.DEFAULT, CYLReflection.DEFAULT)
            ?: CYLReflection.call(parser, "decodeFromInputStream", stream, file.absolutePath, completion, true)
        if (decoded == null) stream.close()
    }

    /**
     * [EN] The request made before the file was parsed, run once it is. [CN] 文件解析完成前的请求，解析后执行。
     */
    private class SVGAState {
        var isParsed = false
        var pending: ((View) -> Unit)? = null
        fun parsed(view: View) { isParsed = true; pending?.invoke(view); pending = null }
        fun run(view: View, action: (View) -> Unit) { if (isParsed) action(view) else pending = action }
    }

    private class SVGAPlayer(view: View) : CYLTabBarItemAnimationBasePlayer(view) {
        private val state: SVGAState? get() = animationView?.cyl_getTag("cyl_svga_state") as? SVGAState

        // [EN] SVGAImageView.loops: 0 repeats without end, 1 plays once. [CN] SVGAImageView.loops：0 为无限重复，1 为播放一次。
        override var loops: Boolean = false
            set(value) { field = value; animationView?.let { CYLReflection.call(it, "setLoops", if (value) 0 else 1) } }

        override fun play() = perform { view ->
            CYLReflection.call(view, "setLoops", if (loops) 0 else 1)
            CYLReflection.call(view, "stepToFrame", 0, true)
        }

        override fun showLastFrame() = perform { view -> CYLReflection.call(view, "stepToPercentage", 1.0, false) }

        override fun stop() = perform { view -> CYLReflection.call(view, "stepToFrame", 0, false) }

        // [EN] SVGAImageView.pauseAnimation keeps the frame; resuming steps to the current frame and plays on.
        // [CN] SVGAImageView.pauseAnimation 保留当前帧；恢复时跳到当前帧并继续播放。
        override fun pause() = perform { view -> CYLReflection.call(view, "pauseAnimation") }

        override fun resume() = perform { view ->
            val frame = CYLReflection.call(view, "getCurrentFrame") as? Int ?: 0
            CYLReflection.call(view, "stepToFrame", frame, true)
        }

        // [EN] SVGAImageView.isAnimating; false before the file is parsed. [CN] SVGAImageView.isAnimating；文件解析前为 false。
        override val isPlaying: Boolean? get() = animationView?.let { CYLReflection.call(it, "isAnimating") as? Boolean }

        override var progress: Float
            get() = 0f
            set(value) { perform { view -> CYLReflection.call(view, "stepToPercentage", value.toDouble(), false) } }

        private fun perform(action: (View) -> Unit) {
            val view = animationView ?: return
            state?.run(view, action) ?: action(view)
        }
    }
}
