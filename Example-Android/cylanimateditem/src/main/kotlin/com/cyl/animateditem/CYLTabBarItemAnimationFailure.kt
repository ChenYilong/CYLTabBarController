package com.cyl.animateditem

import android.view.View

/**
 * [EN] A view that holds an animation view and wants to know when its file cannot be loaded (`CYLAnimatedItemView`
 *      does: it drops the animation and shows its image again).
 * [CN] 持有动画视图、需要知道其文件无法加载的视图（`CYLAnimatedItemView` 实现了它：移除动画并重新显示图片）。
 */
interface CYLTabBarItemAnimationFailureHandling {
    /**
     * [EN] Called on the main thread with the animation view whose file failed. [CN] 在主线程调用，参数为文件加载失败的动画视图。
     */
    fun cyl_animationViewDidFail(animationView: View) // NOSONAR: shipped API name, the cyl_ prefix is the project's rule

    /**
     * [EN] Called on the main thread when an animation view that was loading (a download) has its file: the host can
     *      now hide its static image or placeholder. [CN] 正在加载（下载）的动画视图拿到文件时在主线程调用：宿主此时可以隐藏静态图片或占位图。
     */
    fun cyl_animationViewDidLoad(animationView: View) { /* [EN] Optional. [CN] 可选。 */ } // NOSONAR: shipped API name
}

/**
 * [EN] Where an animator reports a file that failed: the animation view's parent, when it implements
 *      `CYLTabBarItemAnimationFailureHandling`, otherwise `fallbackHandler` (the tab bar sets it for its tab buttons).
 * [CN] animator 报告文件加载失败的入口：动画视图的父视图实现了 `CYLTabBarItemAnimationFailureHandling` 时交给它，否则交给
 *      `fallbackHandler`（TabBar 为其 Tab 按钮设置）。
 */
object CYLTabBarItemAnimationFailure {
    /**
     * [EN] Called with the parent of the failed animation view when that parent does not handle it itself.
     * [CN] 失败动画视图的父视图自身不处理时，以该父视图调用。
     */
    @JvmStatic
    var fallbackHandler: ((host: View) -> Unit)? = null

    /**
     * [EN] Called with the parent of an animation view that finished loading, when that parent does not handle it itself.
     * [CN] 动画视图加载完成、其父视图自身不处理时，以该父视图调用。
     */
    @JvmStatic
    var loadedFallbackHandler: ((host: View) -> Unit)? = null

    /**
     * [EN] For animators: `animationView` waits for its file (a download, a copy to the cache). Until `reportLoaded` or
     *      `reportLater`, hosts keep showing the static image given to them, or the placeholder when there is none.
     * [CN] 供 animator 使用：`animationView` 正在等待其文件（下载、复制到缓存）。在 `reportLoaded` 或 `reportLater` 之前，宿主继续显示传入的静态图片，
     *      没有时显示占位图。
     */
    @JvmStatic
    fun markLoading(animationView: View) {
        animationView.cyl_setTag("cyl_tab_bar_item_animation_loading", true)
    }

    /**
     * [EN] Whether `animationView` still waits for its file. [CN] `animationView` 是否仍在等待其文件。
     */
    @JvmStatic
    fun isLoading(animationView: View?): Boolean =
        animationView?.cyl_getTag("cyl_tab_bar_item_animation_loading") == true

    /**
     * [EN] For animators: `animationView` has its file and shows the animation now. [CN] 供 animator 使用：`animationView` 已拿到文件，现在显示动画。
     */
    @JvmStatic
    fun reportLoaded(animationView: View) {
        if (!isLoading(animationView)) return
        animationView.cyl_setTag("cyl_tab_bar_item_animation_loading", null)
        animationView.post {
            val host = animationView.parent as? View ?: return@post
            if (host is CYLTabBarItemAnimationFailureHandling) host.cyl_animationViewDidLoad(animationView) else loadedFallbackHandler?.invoke(host)
        }
    }

    /**
     * [EN] Reports that `animationView` could not load its file (missing, corrupted, a failed download, a parse error).
     * [CN] 报告 `animationView` 无法加载其文件（不存在、已损坏、下载失败、解析错误）。
     */
    @JvmStatic
    @JvmOverloads
    fun reportLater(animationView: View, reason: String = CYLResourceMissingReason.DECODE_FAILED) {
        animationView.cyl_setTag(REASON_TAG, reason)
        // [EN] After the view is in its host: a failure found while the view is being made (a missing local file) is not lost.
        // [CN] 在视图加入宿主之后再报告：创建视图期间发现的失败（例如本地文件不存在）不会丢失。
        animationView.post { report(animationView) }
    }

    /**
     * [EN] Reports now. Prefer `reportLater` from an animator, whose view may not have a parent yet. [CN] 立即报告。animator 中优先使用 `reportLater`，因为其视图可能还没有父视图。
     */
    @JvmStatic
    @JvmOverloads
    fun report(animationView: View, reason: String? = null) {
        reason?.let { animationView.cyl_setTag(REASON_TAG, it) }
        animationView.cyl_setTag("cyl_tab_bar_item_animation_loading", null)
        val host = animationView.parent as? View ?: return
        if (host is CYLTabBarItemAnimationFailureHandling) host.cyl_animationViewDidFail(animationView) else {
            missingResource(animationView)?.let { (resource, why) -> CYLAnimationEngines.dispatchResourceMissing(animationView.context, resource, why, null) }
            fallbackHandler?.invoke(host)
        }
    }

    internal const val RESOURCE_TAG = "cyl_tab_bar_item_animation_resource"
    private const val REASON_TAG = "cyl_tab_bar_item_animation_failure_reason"
    private const val REPORTED_TAG = "cyl_tab_bar_item_animation_missing_reported"

    /**
     * [EN] The file name or path an animator was made for, and why it failed (a reason an animator gave, else "decode
     *      failed"); null when the view has no recorded file or was already reported. Marks the view as reported.
     * [CN] animator 创建视图时所用的文件名或路径，以及失败原因（animator 给出的原因，否则为 "decode failed"）；视图没有记录文件或已经报告过时为 null。
     *      同时标记该视图已报告。
     */
    internal fun missingResource(animationView: View): Pair<String, String>? {
        val resource = animationView.cyl_getTag(RESOURCE_TAG) as? String ?: return null
        if (animationView.cyl_getTag(REPORTED_TAG) == true) return null
        animationView.cyl_setTag(REPORTED_TAG, true)
        return resource to reasonOf(animationView)
    }

    /**
     * [EN] Why `animationView` failed: the reason its animator gave, else "decode failed". [CN] `animationView` 失败的原因：animator 给出的原因，否则为 "decode failed"。
     */
    internal fun reasonOf(animationView: View): String = animationView.cyl_getTag(REASON_TAG) as? String ?: CYLResourceMissingReason.DECODE_FAILED
}
