package com.cyl.tabbar

import android.widget.AbsListView
import com.chenyilong.cyldeallocblockexecutor.LifecycleController
import java.util.WeakHashMap

/**
 * [EN] Reports the scrolling of a `ListView` / `GridView` (an `AbsListView`) to the lifecycle library, so the global observers
 *      (`LifecycleCenter.whileUserScrolls`, `CYLAnimatedItemView.pausesAnimationsWhileUserScrolls`) hear it. Call it from
 *      `AbsListView.OnScrollListener.onScrollStateChanged`: touch scroll begins, fling is the deceleration, idle ends. A `RecyclerView`
 *      or a plain `ScrollView` is reported by the library's `AndroidBinding.observeScrolling` instead.
 * [CN] 把 `ListView` / `GridView`（`AbsListView`）的滚动报告给生命周期库，使全局观察者
 *      （`LifecycleCenter.whileUserScrolls`、`CYLAnimatedItemView.pausesAnimationsWhileUserScrolls`）收到。在
 *      `AbsListView.OnScrollListener.onScrollStateChanged` 中调用：触摸滚动开始，甩动为减速，空闲结束。`RecyclerView` 或普通
 *      `ScrollView` 请使用库的 `AndroidBinding.observeScrolling`。
 */
object CYLScrollReporting {
    private class State(val controller: LifecycleController<Any>) {
        var dragging = false
        var flinging = false
    }

    private val states = WeakHashMap<Any, State>()

    @JvmStatic
    fun listViewScrollStateChanged(listView: AbsListView, scrollState: Int) {
        val state = synchronized(states) { states.getOrPut(listView) { State(LifecycleController<Any>(listView)) } }
        when (scrollState) {
            AbsListView.OnScrollListener.SCROLL_STATE_TOUCH_SCROLL -> {
                if (!state.dragging && !state.flinging) state.controller.scrollBegan(listView)
                state.dragging = true
                state.flinging = false
            }
            AbsListView.OnScrollListener.SCROLL_STATE_FLING -> {
                if (!state.dragging && !state.flinging) state.controller.scrollBegan(listView)
                if (state.dragging) {
                    state.dragging = false
                    state.controller.scrollEndedDragging(true, listView)
                }
                state.flinging = true
            }
            AbsListView.OnScrollListener.SCROLL_STATE_IDLE -> {
                when {
                    state.dragging -> state.controller.scrollEndedDragging(false, listView)
                    state.flinging -> state.controller.scrollEnded(listView)
                }
                state.dragging = false
                state.flinging = false
            }
        }
    }
}
