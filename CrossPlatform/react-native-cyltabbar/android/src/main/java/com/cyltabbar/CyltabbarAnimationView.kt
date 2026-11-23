package com.cyltabbar

import android.content.Context
import android.widget.FrameLayout
import com.cyl.animateditem.CYLAnimatedItemAnimationEndListener
import com.cyl.animateditem.CYLAnimatedItemView
import com.cyl.animateditem.CYLSize

/**
 * An animation played by CYLTabBarController's engine through a `CYLAnimatedItemView` (the cross-platform engine API:
 * `docs/Animated-Item.md`, "Engine API across platforms"). Props `source`, `playing`, `selected`, `animationSpeed`,
 * `animationLoops`, `animationRestartToken`, `drivesAnimationPlayback` (default true), `iconSize`, `tintColor`; commands
 * `play`, `stopAtProgress`, `restart`; events `onAnimationLoaded`, `onAnimationFailed`, `onAnimationEnd`. No engine logic here.
 * 由 CYLTabBarController 引擎通过 `CYLAnimatedItemView` 播放的动画（跨端引擎 API，见 `docs/Animated-Item.md`）。
 */
class CyltabbarAnimationView(context: Context) : FrameLayout(context) {
  private val density = resources.displayMetrics.density
  private var iconSize: Float? = null

  /** Called with the event name ("loaded", "failed", "end"); the manager turns it into a React Native event. */
  var onEvent: ((String) -> Unit)? = null

  val item = CYLAnimatedItemView(context).apply {
    // Icon only: the view React Native lays out is the icon's frame. 只有图标：React Native 布局的视图就是图标的范围。
    drivesAnimationPlayback = true
    animationEndListener = CYLAnimatedItemAnimationEndListener { onEvent?.invoke("end") }
    onAnimationLoaded = { onEvent?.invoke("loaded") }
    onAnimationFailed = { onEvent?.invoke("failed") }
  }

  init {
    addView(item, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
  }

  override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
    super.onSizeChanged(w, h, oldw, oldh)
    fitIcon()
  }

  /** The icon fills the view, or is `iconSize` (dp) when given. 图标铺满视图，给了 `iconSize`（dp）时为该尺寸。 */
  private fun fitIcon() {
    val side = iconSize
    val size = when {
      side != null -> CYLSize(side, side)
      width > 0 -> CYLSize(width / density, height / density)
      else -> return
    }
    if (item.iconSizeDp != size) item.iconSizeDp = size
  }

  fun applySource(value: String?) { item.animationURL = value?.takeIf { it.isNotBlank() } }

  fun applyPlaying(value: Boolean) { if (value) item.playAnimation() else item.stopAnimation() }

  fun applySelected(value: Boolean) { item.isSelected = value }

  fun applyAnimationSpeed(value: Float) { item.animationSpeed = value }

  fun applyAnimationLoops(value: Boolean) { item.animationLoops = value }

  fun applyAnimationRestartToken(value: Int) { item.animationRestartToken = value }

  fun applyDrivesAnimationPlayback(value: Boolean) { item.drivesAnimationPlayback = value }

  fun applyShowsImageWhenAnimationEnds(value: Boolean) { item.showsImageWhenAnimationEnds = value }

  /** `iconSize` in dp; 0 or less fills the view. */
  fun applyIconSize(value: Float) { iconSize = value.takeIf { it > 0f }; fitIcon() }

  /** `tintColor` as an ARGB int; null clears it. */
  fun applyTintColor(value: Int?) { item.iconColor = value }

  fun play() = item.animatedItemPlayer.play()

  fun stopAtProgress(progress: Float) = item.animatedItemPlayer.stopAtProgress(progress)

  fun restart() = item.restartAnimation()

  // React Native does not lay out views it did not create. React Native 不布局它没有创建的视图。
  private val measureAndLayout = Runnable {
    measure(MeasureSpec.makeMeasureSpec(width, MeasureSpec.EXACTLY), MeasureSpec.makeMeasureSpec(height, MeasureSpec.EXACTLY))
    layout(left, top, right, bottom)
  }

  override fun requestLayout() {
    super.requestLayout()
    post(measureAndLayout)
  }
}
