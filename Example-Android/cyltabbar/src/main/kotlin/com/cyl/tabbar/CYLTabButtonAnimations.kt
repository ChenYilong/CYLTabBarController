// [EN] The method names are the iOS names on purpose (`cyl_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.AnimatorSet
import android.animation.Keyframe
import android.animation.ObjectAnimator
import android.animation.PropertyValuesHolder
import android.animation.ValueAnimator
import android.graphics.Canvas
import android.graphics.ColorFilter
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.view.animation.OvershootInterpolator
import android.widget.ImageView
import android.widget.TextView
import kotlin.math.cos
import kotlin.math.sin

/*
 * [EN] The tap animation classes of CYLTabButtonAnimation.h (issue #535), with the iOS timings and keyframes, played with
 *      property animators. Ported, like on iOS, from the TLAnimationTabBar animations (Ramotion's animated-tab-bar, MIT).
 * [CN] CYLTabButtonAnimation.h 中的点击动画类（issue #535），沿用 iOS 的时长与关键帧，用属性动画播放。与 iOS 一样移植自 TLAnimationTabBar
 *      （Ramotion 的 animated-tab-bar，MIT）。
 */

/** [EN] The default duration of the animations (0.5 s on iOS). [CN] 动画默认时长（iOS 为 0.5 秒）。 */
internal const val CYLTabButtonAnimationDuration = 0.5

private fun View.dp(value: Float) = value * resources.displayMetrics.density

/** [EN] A keyframe animation of `property` with evenly spaced `values` or the given `times`. [CN] `property` 的关键帧动画。 */
private fun keyframes(target: View, property: String, values: FloatArray, times: FloatArray? = null, duration: Double = CYLTabButtonAnimationDuration): ObjectAnimator {
    val frames = values.mapIndexed { index, value -> Keyframe.ofFloat(times?.get(index) ?: (index.toFloat() / (values.size - 1)), value) }
    val holder = PropertyValuesHolder.ofKeyframe(property, *frames.toTypedArray())
    return ObjectAnimator.ofPropertyValuesHolder(target, holder).setDuration((duration * 1000).toLong())
}

private fun scaleKeyframes(target: View, values: FloatArray, times: FloatArray? = null, duration: Double = CYLTabButtonAnimationDuration): Animator =
    AnimatorSet().apply { playTogether(keyframes(target, "scaleX", values, times, duration), keyframes(target, "scaleY", values, times, duration)) }

/** [EN] Tagged animators of a view, so a reset can cancel them (the iOS animation keys). [CN] 视图上带标签的动画，便于重置时取消（对应 iOS 的动画 key）。 */
private val runningAnimators = java.util.WeakHashMap<View, MutableMap<String, Animator>>()

private fun View.cyl_start(key: String, animator: Animator) {
    val map = runningAnimators.getOrPut(this) { HashMap() }
    map.remove(key)?.cancel()
    map[key] = animator
    animator.start()
}

private fun View.cyl_cancel(key: String) {
    runningAnimators[this]?.remove(key)?.cancel()
}

// MARK: - Fireworks 烟花

/** [EN] A round particle in `color` (the iOS dot image). [CN] `color` 颜色的圆点粒子（iOS 的圆点图片）。 */
private class CYLDotDrawable(private val color: Int) : Drawable() {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = this@CYLDotDrawable.color }
    override fun draw(canvas: Canvas) {
        canvas.drawOval(bounds.left.toFloat(), bounds.top.toFloat(), bounds.right.toFloat(), bounds.bottom.toFloat(), paint)
    }
    override fun setAlpha(alpha: Int) { paint.alpha = alpha }
    override fun setColorFilter(colorFilter: ColorFilter?) { paint.colorFilter = colorFilter }
    @Deprecated("Deprecated in Java")
    override fun getOpacity(): Int = PixelFormat.TRANSLUCENT
}

/**
 * [EN] Fireworks around `view`: particles burst out of a 25 dp circle and fade (the iOS emitter layer), drawn in the
 *      overlay of the view's parent so they may leave the icon's bounds, then removed.
 * [CN] `view` 周围的烟花：粒子从 25 dp 的圆周向外散开并渐隐（对应 iOS 的发射层），绘制在父视图的 overlay 上以便超出图标范围，结束后移除。
 */
internal fun CYLTabButtonPlayFireworks(view: View, image: Drawable?) {
    val host = view.parent as? ViewGroup ?: return
    val tint = (view as? ImageView)?.imageTintList?.defaultColor ?: android.graphics.Color.rgb(0, 122, 255)
    val size = view.dp(8f).toInt()
    val centerX = view.left + view.width / 2f
    val centerY = view.top + view.height / 2f
    val particles = (0 until 12).map { index ->
        val drawable = image?.constantState?.newDrawable()?.mutate()?.apply { if (image is android.graphics.drawable.VectorDrawable || view !is ImageView) setTint(tint) } ?: CYLDotDrawable(tint)
        Triple(drawable, 2 * Math.PI * index / 12, 0.8f + (index % 3) * 0.2f)
    }
    particles.forEach { host.overlay.add(it.first) }
    ValueAnimator.ofFloat(0f, 1f).apply {
        duration = (CYLTabButtonAnimationDuration * 2 * 1000).toLong()
        addUpdateListener { animator ->
            val progress = animator.animatedValue as Float
            for ((drawable, angle, speed) in particles) {
                val radius = view.dp(12.5f) + view.dp(30f) * progress * speed
                val x = (centerX + cos(angle) * radius).toInt()
                val y = (centerY + sin(angle) * radius).toInt()
                val scaled = (size * (1f - 0.5f * progress)).toInt().coerceAtLeast(1)
                drawable.setBounds(x - scaled / 2, y - scaled / 2, x + scaled / 2, y + scaled / 2)
                drawable.alpha = (255 * (1f - progress)).toInt()
            }
            host.invalidate()
        }
        addListener(object : AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: Animator) { particles.forEach { host.overlay.remove(it.first) } }
        })
    }.start()
}

// MARK: - The animation classes 动画类

/** [EN] Scale up then down: 1.0 → 1.5 → 0.8 → 1.0. [CN] 先放大再缩小：1.0 → 1.5 → 0.8 → 1.0。 */
open class CYLTabButtonScaleAnimation : CYLTabButtonAnimation {
    /** [EN] Default 0.5 s. [CN] 默认 0.5 秒。 */
    var duration: Double = CYLTabButtonAnimationDuration

    override fun cyl_playSelectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) {
        iconView.cyl_start("scale", scaleKeyframes(iconView, floatArrayOf(1f, 1.5f, 0.8f, 1f), floatArrayOf(0f, 1f / 3, 2f / 3, 1f), duration))
    }
}

/** [EN] The icon grows from small to its size with a slight overshoot. [CN] 图标从小放大到原尺寸，略有回弹。 */
open class CYLTabButtonZoomInAnimation : CYLTabButtonAnimation {
    /** [EN] Default 0.5 s. [CN] 默认 0.5 秒。 */
    var duration: Double = CYLTabButtonAnimationDuration

    override fun cyl_playSelectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) {
        iconView.cyl_start("zoomIn", scaleKeyframes(iconView, floatArrayOf(0.1f, 1.2f, 0.9f, 1f), floatArrayOf(0f, 0.5f, 0.75f, 1f), duration))
    }
}

/** [EN] Elastic bounce of the icon, optionally with fireworks. [CN] 图标弹性跳动，可选烟花。 */
open class CYLTabButtonBounceAnimation : CYLTabButtonAnimation {
    /** [EN] Plays fireworks around the icon. Default false. [CN] 是否在图标周围播放烟花，默认 false。 */
    var playsFireworks: Boolean = false
    /** [EN] The firework particle; null: a small dot in the icon's tint. [CN] 烟花粒子；null 时为图标着色的小圆点。 */
    var fireworksImage: Drawable? = null

    override fun cyl_playSelectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) {
        iconView.cyl_start("bounce", scaleKeyframes(iconView, floatArrayOf(1f, 0.85f, 1.15f, 0.95f, 1.02f, 1f)))
        if (playsFireworks) CYLTabButtonPlayFireworks(iconView, fireworksImage)
    }
}

/** [EN] One full turn of the icon. [CN] 图标旋转一圈。 */
open class CYLTabButtonRotationAnimation : CYLTabButtonAnimation {
    override fun cyl_playSelectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) {
        iconView.rotation = 0f
        iconView.cyl_start("rotation", ObjectAnimator.ofFloat(iconView, "rotation", 0f, -360f).setDuration((CYLTabButtonAnimationDuration * 1000).toLong()))
    }
}

/** [EN] The keys of the fume animation's running animators. [CN] 飘散动画正在运行的 animator 的键。 */
private const val FUME_ICON = "fume.icon"
private const val FUME_TITLE = "fume.title"

/** [EN] The icon moves down while the title floats up and fades out; deselecting brings them back. [CN] 图标下移、标题上浮并淡出；取消选中时恢复。 */
open class CYLTabButtonFumeAnimation : CYLTabButtonAnimation {
    override fun cyl_playSelectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) {
        iconView.cyl_start(FUME_ICON, ObjectAnimator.ofFloat(iconView, "translationY", 0f, iconView.dp(4f)).setDuration((CYLTabButtonAnimationDuration / 2 * 1000).toLong()))
        titleLabel ?: return
        val set = AnimatorSet().apply {
            playTogether(
                ObjectAnimator.ofFloat(titleLabel, "translationY", 0f, -titleLabel.dp(60f)),
                ObjectAnimator.ofFloat(titleLabel, "scaleX", 1f, 2f),
                ObjectAnimator.ofFloat(titleLabel, "scaleY", 1f, 2f),
                ObjectAnimator.ofFloat(titleLabel, "alpha", 1f, 0f),
            )
            duration = (CYLTabButtonAnimationDuration * 1000).toLong()
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    titleLabel.translationY = 0f; titleLabel.scaleX = 1f; titleLabel.scaleY = 1f
                }
            })
        }
        titleLabel.cyl_start(FUME_TITLE, set)
    }

    override fun cyl_playDeselectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) {
        iconView.cyl_cancel(FUME_ICON)
        iconView.translationY = 0f
        titleLabel ?: return
        val set = AnimatorSet().apply {
            playTogether(
                ObjectAnimator.ofFloat(titleLabel, "translationY", titleLabel.dp(15f), 0f),
                ObjectAnimator.ofFloat(titleLabel, "alpha", 0f, 1f),
            )
            duration = (CYLTabButtonAnimationDuration * 1000).toLong()
        }
        titleLabel.cyl_start(FUME_TITLE, set)
    }

    override fun cyl_resetTabButton(button: View, iconView: View, titleLabel: TextView?) {
        iconView.cyl_cancel(FUME_ICON)
        iconView.translationY = 0f
        titleLabel ?: return
        titleLabel.cyl_cancel(FUME_TITLE)
        titleLabel.translationY = 0f; titleLabel.scaleX = 1f; titleLabel.scaleY = 1f; titleLabel.alpha = 1f
    }
}

/** [EN] The icon shrinks while pressed and springs back when the finger lifts; no select animation. [CN] 按下时图标缩小，抬起时弹回；没有选中动画。 */
open class CYLTabButtonPressAnimation : CYLTabButtonAnimation {
    /** [EN] The icon's scale while pressed. Default 0.85. [CN] 按压时图标的缩放比例，默认 0.85。 */
    var pressedScale: Float = 0.85f

    override fun cyl_playSelectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) {
        // [EN] Press only, as on iOS. [CN] 与 iOS 一样只有按压效果。
    }

    override fun cyl_playHighlightAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) {
        iconView.animate().cancel()
        iconView.animate().scaleX(pressedScale).scaleY(pressedScale).setDuration(120).start()
    }

    override fun cyl_playDehighlightAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) {
        iconView.animate().cancel()
        // [EN] A spring with damping 0.5 on iOS. [CN] iOS 上为阻尼 0.5 的弹簧动画。
        iconView.animate().scaleX(1f).scaleY(1f).setDuration(350).setInterpolator(OvershootInterpolator(3f)).start()
    }
}

/** [EN] The block type of `CYLTabButtonBlockAnimation`: the arguments of the protocol methods. [CN] `CYLTabButtonBlockAnimation` 的回调类型。 */
typealias CYLTabButtonAnimationBlock = (button: View, iconView: View, titleLabel: TextView?) -> Unit
/** [EN] The block type of `badgeChangedAnimation`. [CN] `badgeChangedAnimation` 的回调类型。 */
typealias CYLTabButtonBadgeAnimationBlock = (button: View, iconView: View, badgeView: View?) -> Unit

/**
 * [EN] A `CYLTabButtonAnimation` made of blocks (lambdas): each block plays the matching method. A block left null behaves
 *      as if the method were not implemented, so the library's default applies.
 * [CN] 由 block（lambda）组成的 `CYLTabButtonAnimation`：每个 block 播放对应的方法。未设置的 block 等同于未实现该方法，使用库的默认行为。
 */
open class CYLTabButtonBlockAnimation : CYLTabButtonAnimation {
    var selectAnimation: CYLTabButtonAnimationBlock? = null
    var deselectAnimation: CYLTabButtonAnimationBlock? = null
    var reselectAnimation: CYLTabButtonAnimationBlock? = null
    var highlightAnimation: CYLTabButtonAnimationBlock? = null
    var dehighlightAnimation: CYLTabButtonAnimationBlock? = null
    var badgeChangedAnimation: CYLTabButtonBadgeAnimationBlock? = null

    override fun cyl_playSelectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) { selectAnimation?.invoke(button, iconView, titleLabel) }
    override fun cyl_playDeselectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) { deselectAnimation?.invoke(button, iconView, titleLabel) }
    override fun cyl_playReselectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) { reselectAnimation?.invoke(button, iconView, titleLabel) }
    override fun cyl_playHighlightAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) { highlightAnimation?.invoke(button, iconView, titleLabel) }
    override fun cyl_playDehighlightAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) { dehighlightAnimation?.invoke(button, iconView, titleLabel) }
    override fun cyl_playBadgeChangedAnimationWithTabButton(button: View, iconView: View, badgeView: View?) { badgeChangedAnimation?.invoke(button, iconView, badgeView) }

    /** [EN] A method counts as implemented only while its block is set. [CN] 只有设置了 block 的方法才算已实现。 */
    override fun cyl_respondsToSelector(selector: String): Boolean = when (selector) {
        "cyl_playSelectAnimationWithTabButton" -> selectAnimation != null
        "cyl_playDeselectAnimationWithTabButton" -> deselectAnimation != null
        "cyl_playReselectAnimationWithTabButton" -> reselectAnimation != null
        "cyl_playHighlightAnimationWithTabButton" -> highlightAnimation != null
        "cyl_playDehighlightAnimationWithTabButton" -> dehighlightAnimation != null
        "cyl_playBadgeChangedAnimationWithTabButton" -> badgeChangedAnimation != null
        else -> false
    }
}

/**
 * [EN] Flips or curls the icon. `direction` 1–6: flip from left, from right, from top, from bottom, curl up, curl down
 *      (default 1). A curl folds the icon around its top or bottom edge (Android has no page curl).
 * [CN] 翻转或卷曲图标。`direction` 1–6：从左、从右、从上、从下翻转，向上卷、向下卷（默认 1）。卷曲以图标的上边或下边为轴折叠（Android 没有翻页卷曲）。
 */
open class CYLTabButtonFlipAnimation : CYLTabButtonAnimation {
    var direction: Int = 1
    /** [EN] No animation when the button is deselected. Default false. [CN] 取消选中时不播放动画，默认 false。 */
    var disablesDeselectAnimation: Boolean = false

    private fun clampedDirection() = direction.coerceIn(1, 6)

    private fun flip(iconView: View, direction: Int) {
        val (property, from) = when (direction) {
            2 -> "rotationY" to -180f
            3 -> "rotationX" to -180f
            4 -> "rotationX" to 180f
            5, 6 -> "rotationX" to (if (direction == 5) 90f else -90f)
            else -> "rotationY" to 180f
        }
        if (direction >= 5) iconView.pivotY = if (direction == 5) 0f else iconView.height.toFloat() else iconView.pivotY = iconView.height / 2f
        iconView.cameraDistance = iconView.dp(800f)
        iconView.cyl_start("flip", ObjectAnimator.ofFloat(iconView, property, from, 0f).setDuration((CYLTabButtonAnimationDuration * 1000).toLong()))
    }

    override fun cyl_playSelectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) = flip(iconView, clampedDirection())

    override fun cyl_playDeselectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) {
        if (disablesDeselectAnimation) return
        val direction = clampedDirection()
        flip(iconView, if (direction % 2 == 0) direction - 1 else direction + 1)
    }
}

/**
 * [EN] Plays `images` as frames on the icon and keeps the last one while selected; when deselected, plays them in
 *      reverse, then shows the icon itself again.
 * [CN] 在图标上逐帧播放 `images`，选中期间停在最后一帧；取消选中时倒序播放，然后恢复图标本身。
 */
open class CYLTabButtonFrameAnimation : CYLTabButtonAnimation {
    var images: List<Drawable>? = null
    /** [EN] Plays fireworks around the icon. Default false. [CN] 是否在图标周围播放烟花，默认 false。 */
    var playsFireworks: Boolean = false
    var fireworksImage: Drawable? = null

    private val handler = Handler(Looper.getMainLooper())
    private val originals = java.util.WeakHashMap<ImageView, Drawable?>()

    private fun play(iconView: ImageView, reversed: Boolean) {
        val frames = images?.takeIf { it.isNotEmpty() } ?: return
        handler.removeCallbacksAndMessages(iconView)
        if (!originals.containsKey(iconView)) originals[iconView] = iconView.drawable
        val ordered = if (reversed) frames.reversed() else frames
        val step = (CYLTabButtonAnimationDuration * 1000 / ordered.size).toLong()
        ordered.forEachIndexed { index, frame ->
            handler.postAtTime({ iconView.setImageDrawable(frame) }, iconView, android.os.SystemClock.uptimeMillis() + step * index)
        }
        if (reversed) {
            // [EN] Back to the icon itself at the end, not to the first frame. [CN] 结束时恢复图标本身，而不是第一帧。
            handler.postAtTime({ restore(iconView) }, iconView, android.os.SystemClock.uptimeMillis() + step * ordered.size)
        }
    }

    private fun restore(iconView: ImageView) {
        handler.removeCallbacksAndMessages(iconView)
        if (originals.containsKey(iconView)) iconView.setImageDrawable(originals.remove(iconView))
    }

    override fun cyl_playSelectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) {
        val imageView = iconView as? ImageView ?: return
        if (images.isNullOrEmpty()) return
        play(imageView, false)
        if (playsFireworks) CYLTabButtonPlayFireworks(iconView, fireworksImage)
    }

    override fun cyl_playDeselectAnimationWithTabButton(button: View, iconView: View, titleLabel: TextView?) {
        (iconView as? ImageView)?.let { play(it, true) }
    }

    override fun cyl_resetTabButton(button: View, iconView: View, titleLabel: TextView?) {
        (iconView as? ImageView)?.let { restore(it) }
    }
}

/** [EN] The animation object of a `CYLTabButtonTapAnimationType` (iOS `CYLTabButtonAnimationForType`). [CN] 点击动画类型对应的动画对象。 */
internal fun CYLTabButtonAnimationForType(type: CYLEnums.CYLTabButtonTapAnimationType): CYLTabButtonAnimation? = when (type) {
    CYLEnums.CYLTabButtonTapAnimationType.Scale -> CYLTabButtonScaleAnimation()
    CYLEnums.CYLTabButtonTapAnimationType.ZoomIn -> CYLTabButtonZoomInAnimation()
    CYLEnums.CYLTabButtonTapAnimationType.Bounce -> CYLTabButtonBounceAnimation()
    CYLEnums.CYLTabButtonTapAnimationType.BounceWithFireworks -> CYLTabButtonBounceAnimation().apply { playsFireworks = true }
    CYLEnums.CYLTabButtonTapAnimationType.Rotation -> CYLTabButtonRotationAnimation()
    CYLEnums.CYLTabButtonTapAnimationType.Flip -> CYLTabButtonFlipAnimation()
    CYLEnums.CYLTabButtonTapAnimationType.Fume -> CYLTabButtonFumeAnimation()
    // [EN] As on iOS: no object for None, Frame (needs images) and Lottie (the animation file plays). [CN] 与 iOS 一致：None、Frame（需要图片）与 Lottie（播放动画文件）没有对象。
    else -> null
}

/** [EN] The steps of a tap animation, with the names of their two spellings. [CN] 点击动画的步骤及其两种写法的方法名。 */
internal enum class CYLTabButtonAnimationStep(val camelCase: String, val underscore: String) {
    Select("cylPlaySelectAnimationWithTabButton", "cyl_playSelectAnimationWithTabButton"),
    Deselect("cylPlayDeselectAnimationWithTabButton", "cyl_playDeselectAnimationWithTabButton"),
    Reselect("cylPlayReselectAnimationWithTabButton", "cyl_playReselectAnimationWithTabButton"),
    Highlight("cylPlayHighlightAnimationWithTabButton", "cyl_playHighlightAnimationWithTabButton"),
    Dehighlight("cylPlayDehighlightAnimationWithTabButton", "cyl_playDehighlightAnimationWithTabButton"),
    BadgeChanged("cylPlayBadgeChangedAnimationWithTabButton", "cyl_playBadgeChangedAnimationWithTabButton"),
}

internal fun CYLTabButtonAnimation?.cyl_implements(step: CYLTabButtonAnimationStep): Boolean =
    this != null && (cyl_respondsToSelector(step.camelCase) || cyl_respondsToSelector(step.underscore))

/** [EN] Plays `step`: the `cylPlay…` method when implemented, otherwise the `cyl_play…` one. [CN] 播放 `step`：实现了 `cylPlay…` 时调用它，否则调用 `cyl_play…`。 */
internal fun CYLTabButtonAnimation.cyl_play(step: CYLTabButtonAnimationStep, button: View, iconView: View, titleLabel: TextView?, badgeView: View? = null) {
    val camelCase = cyl_respondsToSelector(step.camelCase)
    if (!camelCase && !cyl_respondsToSelector(step.underscore)) return
    when (step) {
        CYLTabButtonAnimationStep.Select -> if (camelCase) cylPlaySelectAnimationWithTabButton(button, iconView, titleLabel) else cyl_playSelectAnimationWithTabButton(button, iconView, titleLabel)
        CYLTabButtonAnimationStep.Deselect -> if (camelCase) cylPlayDeselectAnimationWithTabButton(button, iconView, titleLabel) else cyl_playDeselectAnimationWithTabButton(button, iconView, titleLabel)
        CYLTabButtonAnimationStep.Reselect -> if (camelCase) cylPlayReselectAnimationWithTabButton(button, iconView, titleLabel) else cyl_playReselectAnimationWithTabButton(button, iconView, titleLabel)
        CYLTabButtonAnimationStep.Highlight -> if (camelCase) cylPlayHighlightAnimationWithTabButton(button, iconView, titleLabel) else cyl_playHighlightAnimationWithTabButton(button, iconView, titleLabel)
        CYLTabButtonAnimationStep.Dehighlight -> if (camelCase) cylPlayDehighlightAnimationWithTabButton(button, iconView, titleLabel) else cyl_playDehighlightAnimationWithTabButton(button, iconView, titleLabel)
        CYLTabButtonAnimationStep.BadgeChanged -> if (camelCase) cylPlayBadgeChangedAnimationWithTabButton(button, iconView, badgeView) else cyl_playBadgeChangedAnimationWithTabButton(button, iconView, badgeView)
    }
}

// MARK: - UIViewController (CYLTabButtonAnimation)

private val pageTabButtonAnimations = java.util.WeakHashMap<androidx.fragment.app.Fragment, CYLTabButtonAnimation>()

/** [EN] `cyl_tabButtonAnimation`: the tap animation of this page's tab; takes precedence over the controller's. [CN] 本页面 Tab 的点击动画，优先于控制器的设置。 */
var androidx.fragment.app.Fragment.cyl_tabButtonAnimation: CYLTabButtonAnimation?
    get() = pageTabButtonAnimations[this]
    set(value) { if (value == null) pageTabButtonAnimations.remove(this) else pageTabButtonAnimations[this] = value }
