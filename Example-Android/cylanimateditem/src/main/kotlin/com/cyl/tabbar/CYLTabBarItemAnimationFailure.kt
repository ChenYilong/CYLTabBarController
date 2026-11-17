package com.cyl.tabbar

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
    fun cyl_animationViewDidFail(animationView: View)
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
     * [EN] Reports that `animationView` could not load its file (missing, corrupted, a failed download, a parse error).
     * [CN] 报告 `animationView` 无法加载其文件（不存在、已损坏、下载失败、解析错误）。
     */
    @JvmStatic
    fun reportLater(animationView: View) {
        // [EN] After the view is in its host: a failure found while the view is being made (a missing local file) is not lost.
        // [CN] 在视图加入宿主之后再报告：创建视图期间发现的失败（例如本地文件不存在）不会丢失。
        animationView.post { report(animationView) }
    }

    /**
     * [EN] Reports now. Prefer `reportLater` from an animator, whose view may not have a parent yet. [CN] 立即报告。animator 中优先使用 `reportLater`，因为其视图可能还没有父视图。
     */
    @JvmStatic
    fun report(animationView: View) {
        val host = animationView.parent as? View ?: return
        if (host is CYLTabBarItemAnimationFailureHandling) host.cyl_animationViewDidFail(animationView) else fallbackHandler?.invoke(host)
    }
}
