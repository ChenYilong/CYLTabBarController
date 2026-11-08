package com.cyltabbar

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import com.cyl.tabbar.CYLSize
import com.cyl.tabbar.CYLTabBarItemAnimationFactory

/**
 * An animation played by CYLTabBarController's engine (`CYLTabBarItemAnimationFactory`), whatever its library (Rive,
 * Lottie, PAG, GIF) when the app has it. 由 CYLTabBarController 引擎播放的动画，App 引入对应库时可用（Rive、Lottie、PAG、GIF）。
 */
class CyltabbarAnimationView(context: Context) : FrameLayout(context) {
  private var source: String? = null
  private var playing = false
  private var animationView: View? = null

  fun applySource(value: String?) {
    if (value == source) return
    source = value
    rebuild()
  }

  fun applyPlaying(value: Boolean) {
    playing = value
    play()
  }

  override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
    super.onSizeChanged(w, h, oldw, oldh)
    if (animationView == null && w > 0) post { rebuild() }
  }

  private fun rebuild() {
    animationView?.let(::removeView)
    animationView = null
    val url = source?.takeIf { it.isNotBlank() } ?: return
    val density = resources.displayMetrics.density
    val size = if (width > 0) CYLSize(width / density, height / density) else CYLSize(44f, 44f)
    val view = CYLTabBarItemAnimationFactory.animationViewWithURL(context, url, size, ImageView.ScaleType.FIT_CENTER) ?: return
    addView(view, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
    animationView = view
    play()
  }

  private fun play() {
    val player = CYLTabBarItemAnimationFactory.playerForView(animationView) ?: return
    if (playing) player.play() else player.stop()
  }

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
