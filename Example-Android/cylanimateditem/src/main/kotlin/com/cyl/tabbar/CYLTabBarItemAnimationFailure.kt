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
     * [EN] Reports that `animationView` could not load its file. [CN] 报告 `animationView` 无法加载其文件。
     */
    @JvmStatic
    fun report(animationView: View) {
        val host = animationView.parent as? View ?: return
        if (host is CYLTabBarItemAnimationFailureHandling) host.cyl_animationViewDidFail(animationView) else fallbackHandler?.invoke(host)
    }
}
