// [EN] The method names are the iOS names on purpose, see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称，见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ValueAnimator
import android.view.MotionEvent
import android.view.View
import kotlin.math.abs

/** [EN] `UIRectEdge` for the slide transition: the edge the old tab leaves towards. [CN] 滑动转场的 `UIRectEdge`：旧 Tab 离开的方向。 */
enum class CYLRectEdge { Left, Right }

/**
 * [EN] `CYLTabBarSlideTransitionAnimator` (issue #535): the new tab slides in from the side opposite `targetEdge` while
 *      the old one slides out towards `targetEdge`. Return it from your delegate's
 *      `tabBarController_animationControllerForTransition`.
 * [CN] `CYLTabBarSlideTransitionAnimator`（issue #535）：新 Tab 从 `targetEdge` 的对侧滑入，旧 Tab 向 `targetEdge` 滑出。在代理的
 *      `tabBarController_animationControllerForTransition` 中返回它。
 */
open class CYLTabBarSlideTransitionAnimator(val targetEdge: CYLRectEdge) {
    /** [EN] Default 0.35 s. [CN] 默认 0.35 秒。 */
    var duration: Double = 0.35

    private var fromView: View? = null
    private var toView: View? = null
    private var completion: ((Boolean) -> Unit)? = null
    private var animator: ValueAnimator? = null

    /** [EN] -1: the old tab leaves to the left (the new one comes from the right); 1: the other way. [CN] -1：旧 Tab 向左离开；1：相反。 */
    private val offset: Float get() = if (targetEdge == CYLRectEdge.Right) 1f else -1f

    /** [EN] Places both pages for `percent` (0: the old page, 1: the new one). [CN] 按 `percent` 放置两个页面（0：旧页面，1：新页面）。 */
    internal fun applyProgress(percent: Float) {
        val width = (toView?.width ?: fromView?.width ?: 0).toFloat()
        fromView?.translationX = width * offset * percent
        toView?.translationX = -width * offset * (1f - percent)
    }

    /** [EN] `-animateTransition:`: slides `fromView` out and `toView` in, then calls `completion(finished)`. [CN] 滑出 `fromView`、滑入 `toView`，然后调用 `completion(finished)`。 */
    open fun animateTransition(fromView: View?, toView: View, completion: (Boolean) -> Unit) {
        prepare(fromView, toView, completion)
        animate(0f, 1f, finishing = true)
    }

    internal fun prepare(fromView: View?, toView: View, completion: (Boolean) -> Unit) {
        animator?.cancel()
        this.fromView = fromView
        this.toView = toView
        this.completion = completion
        fromView?.visibility = View.VISIBLE
        toView.visibility = View.VISIBLE
        applyProgress(0f)
    }

    internal fun animate(from: Float, to: Float, finishing: Boolean) {
        animator = ValueAnimator.ofFloat(from, to).apply {
            duration = (this@CYLTabBarSlideTransitionAnimator.duration * 1000 * abs(to - from)).toLong().coerceAtLeast(1)
            addUpdateListener { applyProgress(it.animatedValue as Float) }
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) = complete(finishing)
            })
            start()
        }
    }

    private fun complete(finished: Boolean) {
        fromView?.translationX = 0f
        toView?.translationX = 0f
        val done = completion
        fromView = null; toView = null; completion = null; animator = null
        done?.invoke(finished)
    }
}

/**
 * [EN] `UIPanGestureRecognizer` for `CYLTabBarInteractiveTransition`: feed it the touches of a view (`attachTo`, or call
 *      `onTouchEvent` from your own listener); it reports the horizontal translation and the state of the pan.
 * [CN] 用于 `CYLTabBarInteractiveTransition` 的 `UIPanGestureRecognizer`：把视图的触摸交给它（`attachTo`，或在自己的监听中调用
 *      `onTouchEvent`）；它报告水平位移与拖动状态。
 */
open class CYLPanGestureRecognizer {
    enum class State { Possible, Began, Changed, Ended, Cancelled }

    var state: State = State.Possible
        private set
    /** [EN] `translationInView:`: the horizontal distance (px) since the pan began. [CN] 拖动开始以来的水平距离（像素）。 */
    var translationX: Float = 0f
        private set
    private var startX = 0f
    private val targets = ArrayList<(CYLPanGestureRecognizer) -> Unit>()

    /** [EN] `-addTarget:action:`. [CN] 添加回调。 */
    fun addTarget(target: (CYLPanGestureRecognizer) -> Unit) { targets += target }
    fun removeTarget(target: (CYLPanGestureRecognizer) -> Unit) { targets -= target }

    /** [EN] Routes the touches of `view` here. [CN] 把 `view` 的触摸交给它。 */
    fun attachTo(view: View) {
        view.setOnTouchListener { touched, event -> onTouchEvent(event).also { if (event.actionMasked == MotionEvent.ACTION_UP) touched.performClick() } }
    }

    fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> { startX = event.rawX; translationX = 0f; state = State.Possible }
            MotionEvent.ACTION_MOVE -> {
                translationX = event.rawX - startX
                state = if (state == State.Possible) State.Began else State.Changed
                notifyTargets()
                if (state == State.Began) { state = State.Changed; notifyTargets() }
            }
            MotionEvent.ACTION_UP -> { if (state != State.Possible) { state = State.Ended; notifyTargets() }; state = State.Possible }
            MotionEvent.ACTION_CANCEL -> { if (state != State.Possible) { state = State.Cancelled; notifyTargets() }; state = State.Possible }
        }
        return true
    }

    private fun notifyTargets() = targets.toList().forEach { it(this) }
}

/**
 * [EN] `CYLTabBarInteractiveTransition` (issue #535): drives `CYLTabBarSlideTransitionAnimator` with a pan, so the tabs
 *      follow the finger. Return it from your delegate's `tabBarController_interactionControllerForAnimationController`
 *      while your pan is active, and change `selectedIndex` when the pan begins. The transition finishes past 40 % of
 *      the width, otherwise it is cancelled and the previous tab stays selected.
 * [CN] `CYLTabBarInteractiveTransition`（issue #535）：用拖动驱动 `CYLTabBarSlideTransitionAnimator`，Tab 跟随手指。拖动进行时在代理的
 *      `tabBarController_interactionControllerForAnimationController` 中返回它，并在拖动开始时修改 `selectedIndex`。超过宽度的 40% 时
 *      完成转场，否则取消，之前的 Tab 保持选中。
 */
open class CYLTabBarInteractiveTransition(val gestureRecognizer: CYLPanGestureRecognizer) {
    private var animator: CYLTabBarSlideTransitionAnimator? = null
    private var width: Float = 0f
    private var initialTranslation: Float = 0f
    private val listener: (CYLPanGestureRecognizer) -> Unit = { gestureRecognizerDidUpdate(it) }

    init {
        gestureRecognizer.addTarget(listener)
    }

    /** [EN] `-startInteractiveTransition:`: the controller starts the transition with the animator and the container width. [CN] 控制器以动画对象与容器宽度开始转场。 */
    internal fun startInteractiveTransition(animator: CYLTabBarSlideTransitionAnimator, width: Int) {
        this.animator = animator
        this.width = width.toFloat()
        initialTranslation = gestureRecognizer.translationX
    }

    private fun percent(): Float {
        if (width <= 0) return 0f
        val translation = gestureRecognizer.translationX
        if ((translation > 0 && initialTranslation < 0) || (translation < 0 && initialTranslation > 0)) return -1f
        return (abs(translation) / width).coerceAtMost(1f)
    }

    private fun gestureRecognizerDidUpdate(recognizer: CYLPanGestureRecognizer) {
        val animator = animator ?: return
        val percent = percent()
        when (recognizer.state) {
            CYLPanGestureRecognizer.State.Changed -> if (percent < 0) {
                cancel(animator, 0f)
                recognizer.removeTarget(listener)
            } else {
                animator.applyProgress(percent)
            }
            CYLPanGestureRecognizer.State.Ended -> if (percent >= 0.4f) finish(animator, percent) else cancel(animator, percent.coerceAtLeast(0f))
            CYLPanGestureRecognizer.State.Cancelled -> cancel(animator, percent.coerceAtLeast(0f))
            else -> Unit
        }
    }

    private fun finish(animator: CYLTabBarSlideTransitionAnimator, from: Float) {
        this.animator = null
        animator.animate(from, 1f, finishing = true)
    }

    private fun cancel(animator: CYLTabBarSlideTransitionAnimator, from: Float) {
        this.animator = null
        animator.animate(from, 0f, finishing = false)
    }
}
