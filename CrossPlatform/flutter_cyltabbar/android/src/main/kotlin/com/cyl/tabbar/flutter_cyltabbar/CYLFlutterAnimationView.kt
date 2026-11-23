package com.cyl.tabbar.flutter_cyltabbar

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import com.cyl.animateditem.CYLAnimatedItemAnimationEndListener
import com.cyl.animateditem.CYLAnimatedItemView
import com.cyl.animateditem.CYLSize
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

/**
 * An animation played by CYLTabBarController's engine through a `CYLAnimatedItemView` (the cross-platform engine API:
 * `docs/Animated-Item.md`, "Engine API across platforms"). Channel `flutter_cyltabbar/CYLAnimationView/<id>`: the methods
 * `setSource`, `setSelected`, `setAnimationSpeed`, `setAnimationLoops`, `setAnimationRestartToken`,
 * `setDrivesAnimationPlayback`, `setPlaying`, `setIconSize`, `setTintColor` and the commands `play`, `stopAtProgress`,
 * `restart`; it calls back `onAnimationLoaded`, `onAnimationFailed` and `onAnimationEnd`. No engine logic here.
 * 由 CYLTabBarController 引擎通过 `CYLAnimatedItemView` 播放的动画（跨端引擎 API，见 `docs/Animated-Item.md`）。
 */
internal class CYLFlutterAnimationView(context: Context, viewId: Int, arguments: Map<*, *>, messenger: BinaryMessenger) :
  PlatformView, MethodChannel.MethodCallHandler {

  private val channel = MethodChannel(messenger, "flutter_cyltabbar/CYLAnimationView/$viewId")
  private val density = context.resources.displayMetrics.density
  private var iconSize: Float? = null

  private val item = CYLAnimatedItemView(context).apply {
    // Icon only; the view the host gives is the icon's frame. 只有图标；宿主给的视图就是图标的范围。
    drivesAnimationPlayback = true
    animationEndListener = CYLAnimatedItemAnimationEndListener { channel.invokeMethod("onAnimationEnd", null) }
    onAnimationLoaded = { channel.invokeMethod("onAnimationLoaded", null) }
    onAnimationFailed = { channel.invokeMethod("onAnimationFailed", null) }
  }

  private val container = object : FrameLayout(context) {
    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
      super.onSizeChanged(w, h, oldw, oldh)
      fitIcon()
    }
  }

  init {
    container.addView(item, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
    channel.setMethodCallHandler(this)
    (arguments["drivesAnimationPlayback"] as? Boolean)?.let { item.drivesAnimationPlayback = it }
    (arguments["showsImageWhenAnimationEnds"] as? Boolean)?.let { item.showsImageWhenAnimationEnds = it }
    (arguments["animationSpeed"] as? Number)?.let { item.animationSpeed = it.toFloat() }
    (arguments["animationLoops"] as? Boolean)?.let { item.animationLoops = it }
    (arguments["animationRestartToken"] as? Number)?.let { item.animationRestartToken = it.toInt() }
    (arguments["iconSize"] as? Number)?.let { iconSize = it.toFloat() }
    (arguments["tintColor"] as? Number)?.let { item.iconColor = it.toInt() }
    (arguments["selected"] as? Boolean)?.let { item.isSelected = it }
    fitIcon()
    (arguments["source"] as? String)?.let { item.animationURL = it }
    if (arguments["playing"] as? Boolean == true) item.playAnimation()
  }

  override fun getView(): View = container

  override fun dispose() = channel.setMethodCallHandler(null)

  /** The icon fills the view, or is `iconSize` (dp) when given. 图标铺满视图，给了 `iconSize`（dp）时为该尺寸。 */
  private fun fitIcon() {
    val side = iconSize
    val size = when {
      side != null -> CYLSize(side, side)
      container.width > 0 -> CYLSize(container.width / density, container.height / density)
      else -> return
    }
    if (item.iconSizeDp != size) item.iconSizeDp = size
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    val argument = call.arguments
    when (call.method) {
      "setSource" -> item.animationURL = argument as? String
      "setSelected" -> item.isSelected = argument as? Boolean ?: false
      "setAnimationSpeed" -> item.animationSpeed = (argument as? Number)?.toFloat() ?: 1f
      "setAnimationLoops" -> item.animationLoops = argument as? Boolean ?: false
      "setAnimationRestartToken" -> item.animationRestartToken = (argument as? Number)?.toInt() ?: 0
      "setDrivesAnimationPlayback" -> item.drivesAnimationPlayback = argument as? Boolean ?: true
      "setShowsImageWhenAnimationEnds" -> item.showsImageWhenAnimationEnds = argument as? Boolean ?: false
      "setPlaying" -> if (argument as? Boolean == true) item.playAnimation() else item.stopAnimation()
      "setIconSize" -> { iconSize = (argument as? Number)?.toFloat(); fitIcon() }
      "setTintColor" -> item.iconColor = (argument as? Number)?.toInt()
      "play" -> item.animatedItemPlayer.play()
      "stopAtProgress" -> item.animatedItemPlayer.stopAtProgress((argument as? Number)?.toFloat() ?: 0f)
      "restart" -> item.restartAnimation()
      else -> return result.notImplemented()
    }
    result.success(null)
  }
}
