/*
 * [EN] The indicator and title blending while swiping follow QMUI_Android's QMUIBasicTabSegment.updateIndicatorPosition
 *      (https://github.com/Tencent/QMUI_Android), under the MIT License; the drag rules follow ViewPager:
 * [CN] 滑动时指示条与标题的渐变参照 QMUI_Android 的 QMUIBasicTabSegment.updateIndicatorPosition（https://github.com/Tencent/QMUI_Android），
 *      遵循 MIT 许可证；拖动规则参照 ViewPager：
 *
 * Tencent is pleased to support the open source community by making QMUI_Android available.
 * Copyright (C) 2017-2018 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */
package com.cyl.tabbar

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ValueAnimator
import android.content.Context
import android.view.MotionEvent
import android.view.VelocityTracker
import android.view.View
import android.view.ViewConfiguration
import android.view.ViewGroup
import android.widget.FrameLayout
import kotlin.math.abs

/**
 * [EN] The pages container of `CYLTabBarController` (`pagesContainer`): a `FrameLayout` that, with
 *      `cyl_swipesBetweenPages`, lets a horizontal drag move to the neighbor tab.
 * [CN] `CYLTabBarController` 的页面容器（`pagesContainer`）：一个 `FrameLayout`，开启 `cyl_swipesBetweenPages` 后横向拖动可切换到相邻 Tab。
 */
@android.annotation.SuppressLint("ViewConstructor") // [EN] Made by the controller, never inflated. [CN] 由控制器创建，不从 XML 加载。
class CYLTabBarPagesContainer internal constructor(context: Context, controller: CYLTabBarController) : FrameLayout(context) {
    private val swipe = CYLTabBarPageSwipe(controller, this)

    override fun onInterceptTouchEvent(event: MotionEvent): Boolean = swipe.onInterceptTouchEvent(event) || super.onInterceptTouchEvent(event)

    @android.annotation.SuppressLint("ClickableViewAccessibility") // [EN] Only drags that move the pages land here. [CN] 只有移动页面的拖动会到这里。
    override fun onTouchEvent(event: MotionEvent): Boolean = swipe.onTouchEvent(event) || super.onTouchEvent(event)
}

/**
 * [EN] Swiping between the pages, like a `ViewPager`: the selected page and its neighbor follow the finger, the tab bar's
 *      indicator and titles blend between the two tabs, and the neighbor is selected past 40 % of the width or after a
 *      fling. A child that can still scroll in that direction (a horizontal list, a map) keeps the drag. A tab that would
 *      not be selected by a tap (`shouldSelect` false, a custom action, a login) does not move.
 * [CN] 像 `ViewPager` 一样在页面间滑动：选中页面与相邻页面跟随手指，TabBar 的指示条与标题在两个 Tab 之间渐变，超过宽度的 40% 或快速滑动后选中相邻
 *      Tab。仍可沿该方向滚动的子视图（横向列表、地图）保留拖动。点击时不会被选中的 Tab（`shouldSelect` 为 false、自定义动作、需要登录）不会移动。
 */
internal class CYLTabBarPageSwipe(private val controller: CYLTabBarController, private val container: ViewGroup) {
    private val configuration = ViewConfiguration.get(container.context)
    private val touchSlop = configuration.scaledTouchSlop
    private val minimumFlingVelocity = configuration.scaledMinimumFlingVelocity * 4
    private var startX = 0f
    private var startY = 0f
    private var dragging = false
    private var step = 0
    private var target = -1
    private var fromView: View? = null
    private var targetView: View? = null
    private var targetShownByTransaction = false
    private var velocityTracker: VelocityTracker? = null
    private var settling: ValueAnimator? = null

    fun onInterceptTouchEvent(event: MotionEvent): Boolean {
        if (!controller.cyl_swipesBetweenPages || settling != null) return false
        detect(event)
        return dragging
    }

    /**
     * [EN] Starts a drag once the finger moved mostly sideways past the touch slop. [CN] 手指主要横向移动并超过 touch slop 时开始拖动。
     */
    private fun detect(event: MotionEvent) {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> { startX = event.x; startY = event.y; dragging = false; track(event, reset = true) }
            MotionEvent.ACTION_MOVE -> {
                track(event)
                val dx = event.x - startX
                val dy = event.y - startY
                if (!dragging && abs(dx) > touchSlop && abs(dx) > abs(dy) * 1.5f) {
                    val direction = if (dx < 0) 1 else -1
                    if (!canScroll(container, direction, startX.toInt(), startY.toInt()) && begin(direction)) {
                        dragging = true
                        startX = event.x
                        container.parent?.requestDisallowInterceptTouchEvent(true)
                    }
                }
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> recycleTracker()
        }
    }

    fun onTouchEvent(event: MotionEvent): Boolean {
        if (!controller.cyl_swipesBetweenPages || settling != null) return false
        if (!dragging) {
            // [EN] No page view took the touch: keep the stream (as ViewPager does) and watch for a drag. [CN] 没有页面视图接收触摸：保留事件流（与 ViewPager 一致）并检测拖动。
            detect(event)
            return event.actionMasked != MotionEvent.ACTION_UP && event.actionMasked != MotionEvent.ACTION_CANCEL
        }
        track(event)
        when (event.actionMasked) {
            MotionEvent.ACTION_MOVE -> update(event.x - startX)
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                val tracker = velocityTracker
                tracker?.computeCurrentVelocity(1000)
                val velocity = if (event.actionMasked == MotionEvent.ACTION_CANCEL) 0f else tracker?.xVelocity ?: 0f
                end(event.x - startX, velocity)
                recycleTracker()
            }
        }
        return true
    }

    private fun track(event: MotionEvent, reset: Boolean = false) {
        if (reset) recycleTracker()
        (velocityTracker ?: VelocityTracker.obtain().also { velocityTracker = it }).addMovement(event)
    }

    private fun recycleTracker() {
        velocityTracker?.recycle()
        velocityTracker = null
    }

    /**
     * [EN] `ViewPager.canScroll`: whether a view under the point can still scroll horizontally in `direction`. [CN] 触点下方的视图是否仍可沿 `direction` 横向滚动。
     */
    private fun canScroll(view: View, direction: Int, x: Int, y: Int): Boolean {
        if (view is ViewGroup) {
            for (index in view.childCount - 1 downTo 0) {
                val child = view.getChildAt(index)
                if (child.visibility != View.VISIBLE) continue
                val childX = x + view.scrollX - child.left
                val childY = y + view.scrollY - child.top
                if (childX >= 0 && childY >= 0 && childX < child.width && childY < child.height && canScroll(child, direction, childX, childY)) return true
            }
        }
        return view !== container && view.canScrollHorizontally(direction)
    }

    /**
     * [EN] Starts dragging towards `selectedIndex + direction`, when that tab may be selected. [CN] 开始向 `selectedIndex + direction` 拖动（该 Tab 可被选中时）。
     */
    private fun begin(direction: Int): Boolean {
        val index = controller.selectedIndex + direction
        val page = controller.cyl_swipeTargetPage(index) ?: return false
        val from = controller.selectedViewController?.view ?: return false
        val existing = page.view
        val view = if (existing != null) existing.also { it.visibility = View.VISIBLE } else controller.cyl_showPageForSwipe(page)
        view ?: return false
        targetShownByTransaction = existing == null
        step = direction
        target = index
        fromView = from
        targetView = view
        return true
    }

    private fun update(rawDx: Float) {
        val width = container.width.toFloat().takeIf { it > 0 } ?: return
        // [EN] Only towards the neighbor. [CN] 只朝相邻页面方向。
        val dx = if (step > 0) rawDx.coerceIn(-width, 0f) else rawDx.coerceIn(0f, width)
        fromView?.translationX = dx
        targetView?.translationX = dx + step * width
        controller.tabBar.cyl_updateIndicatorPosition(controller.selectedIndex, step * abs(dx) / width)
    }

    private fun end(rawDx: Float, velocity: Float) {
        val width = container.width.toFloat()
        val dx = if (step > 0) rawDx.coerceIn(-width, 0f) else rawDx.coerceIn(0f, width)
        val percent = if (width > 0) abs(dx) / width else 0f
        // [EN] A fling towards the neighbor (velocity opposite to `step`) or past 40 %. [CN] 朝相邻页面快速滑动（速度方向与 `step` 相反）或超过 40%。
        val finish = percent >= 0.4f || (-velocity * step > minimumFlingVelocity && percent > 0.05f)
        val endDx = if (finish) -step * width else 0f
        dragging = false
        settling = ValueAnimator.ofFloat(dx, endDx).apply {
            duration = (250 * abs(endDx - dx) / width.coerceAtLeast(1f)).toLong().coerceAtLeast(1)
            addUpdateListener { update(it.animatedValue as Float) }
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) = settle(finish)
            })
            start()
        }
    }

    private fun settle(finish: Boolean) {
        settling = null
        fromView?.translationX = 0f
        targetView?.translationX = 0f
        val page = controller.viewControllers.getOrNull(target)
        if (finish) {
            controller.cyl_selectIndexFromSwipe(target)
        } else {
            if (targetShownByTransaction) page?.let { controller.cyl_hidePageAfterSwipe(it) } else targetView?.visibility = View.GONE
            controller.tabBar.cyl_updateIndicatorPosition(controller.selectedIndex, 0f)
        }
        fromView = null
        targetView = null
        target = -1
    }
}
