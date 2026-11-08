package com.cyl.tabbar.flutter_cyltabbar

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import com.cyl.tabbar.CYLSize
import com.cyl.tabbar.CYLTabBarItemAnimationFactory
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

/** An animation played by CYLTabBarController's engine. 由 CYLTabBarController 引擎播放的动画。 */
internal class CYLFlutterAnimationView(context: Context, viewId: Int, arguments: Map<*, *>, messenger: BinaryMessenger) :
  PlatformView, MethodChannel.MethodCallHandler {

  private val container = object : FrameLayout(context) {
    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
      super.onSizeChanged(w, h, oldw, oldh)
      if (animationView == null && w > 0) post { rebuild() }
    }
  }
  private val channel = MethodChannel(messenger, "flutter_cyltabbar/CYLAnimationView/$viewId")
  private var source = arguments["source"] as? String
  private var playing = arguments["playing"] as? Boolean ?: false
  private var animationView: View? = null

  init {
    channel.setMethodCallHandler(this)
  }

  override fun getView(): View = container

  override fun dispose() = channel.setMethodCallHandler(null)

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "setSource" -> { source = call.arguments as? String; rebuild() }
      "setPlaying" -> { playing = call.arguments as? Boolean ?: false; play() }
      else -> return result.notImplemented()
    }
    result.success(null)
  }

  private fun rebuild() {
    animationView?.let(container::removeView)
    animationView = null
    val url = source?.takeIf { it.isNotBlank() } ?: return
    if (container.width <= 0) return
    val density = container.resources.displayMetrics.density
    val view = CYLTabBarItemAnimationFactory.animationViewWithURL(container.context, url,
      CYLSize(container.width / density, container.height / density), ImageView.ScaleType.FIT_CENTER) ?: return
    container.addView(view, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
    animationView = view
    play()
  }

  private fun play() {
    val player = CYLTabBarItemAnimationFactory.playerForView(animationView) ?: return
    if (playing) player.play() else player.stop()
  }
}
