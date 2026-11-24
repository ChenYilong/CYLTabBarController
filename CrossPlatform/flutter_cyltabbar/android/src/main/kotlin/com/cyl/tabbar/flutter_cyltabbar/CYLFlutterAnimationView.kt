package com.cyl.tabbar.flutter_cyltabbar

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import com.cyl.animateditem.CYLAnimatedItemAnimationEndListener
import com.cyl.animateditem.CYLAnimatedItemBackgroundStyle
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
 * `setDrivesAnimationPlayback`, `setShowsImageWhenAnimationEnds`, `setImage`, `setPlaying`, `setIconSize`, `setTintColor`, `setItemBackgroundStyle`, `setItemBackgroundColor`, `setItemCornerRadius`, `setItemBorderWidth`,
 * `setItemBorderColor` and the commands `play`, `stopAtProgress`,
 * `restart`; it calls back `onAnimationLoaded`, `onAnimationFailed`, `onAnimationEnd` and `onResourceMissing`. No engine logic here.
 * 由 CYLTabBarController 引擎通过 `CYLAnimatedItemView` 播放的动画（跨端引擎 API，见 `docs/Animated-Item.md`）。
 */
internal class CYLFlutterAnimationView(context: Context, viewId: Int, arguments: Map<*, *>, messenger: BinaryMessenger) :
  PlatformView, MethodChannel.MethodCallHandler {

  private val channel = MethodChannel(messenger, "flutter_cyltabbar/CYLAnimationView/$viewId")
  private val density = context.resources.displayMetrics.density
  private var iconSize: Float? = null
  private var imageRequest = 0

  private val item = CYLAnimatedItemView(context).apply {
    // Icon only; the view the host gives is the icon's frame. 只有图标；宿主给的视图就是图标的范围。
    drivesAnimationPlayback = true
    animationEndListener = CYLAnimatedItemAnimationEndListener { channel.invokeMethod("onAnimationEnd", null) }
    onAnimationLoaded = { channel.invokeMethod("onAnimationLoaded", null) }
    onAnimationFailed = { channel.invokeMethod("onAnimationFailed", null) }
    onResourceMissing = { resource, reason -> channel.invokeMethod("onResourceMissing", mapOf("resource" to resource, "reason" to reason)) }
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
    (arguments["image"] as? String)?.let { setImage(it) }
    (arguments["animationSpeed"] as? Number)?.let { item.animationSpeed = it.toFloat() }
    (arguments["animationLoops"] as? Boolean)?.let { item.animationLoops = it }
    (arguments["animationRestartToken"] as? Number)?.let { item.animationRestartToken = it.toInt() }
    (arguments["iconSize"] as? Number)?.let { iconSize = it.toFloat() }
    (arguments["tintColor"] as? Number)?.let { item.iconColor = it.toInt() }
    setItemBackgroundStyle(arguments["itemBackgroundStyle"])
    (arguments["itemBackgroundColor"] as? Number)?.let { item.itemBackgroundColor = it.toInt() }
    (arguments["itemCornerRadius"] as? Number)?.let { item.itemCornerRadius = it.toFloat() }
    (arguments["itemBorderWidth"] as? Number)?.let { item.itemBorderWidth = it.toFloat() }
    (arguments["itemBorderColor"] as? Number)?.let { item.itemBorderColor = it.toInt() }
    (arguments["selected"] as? Boolean)?.let { item.isSelected = it }
    fitIcon()
    (arguments["source"] as? String)?.let { item.animationURL = it }
    if (arguments["playing"] as? Boolean == true) item.playAnimation()
  }

  override fun getView(): View = container

  override fun dispose() = channel.setMethodCallHandler(null)

  /**
   * The still image `showsImageWhenAnimationEnds` shows, loaded like `source`; it is the item's own `image` (not the
   * placeholder), which `CYLAnimatedItemView` shows selected or not. null or blank clears it.
   */
  private fun setImage(value: String?) {
    val request = ++imageRequest
    val name = value?.takeIf { it.isNotBlank() } ?: run { item.image = null; return }
    CYLFlutterStillImage.loadAsync(item.context, name) { drawable -> if (request == imageRequest) item.image = drawable }
  }

  /** `itemBackgroundStyle`: "liquidGlass", or anything else (null, "flat") for flat. */
  private fun setItemBackgroundStyle(value: Any?) {
    item.itemBackgroundStyle = if (value == "liquidGlass") CYLAnimatedItemBackgroundStyle.LiquidGlass else CYLAnimatedItemBackgroundStyle.Flat
  }

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
      "setImage" -> setImage(argument as? String)
      "setPlaying" -> if (argument as? Boolean == true) item.playAnimation() else item.stopAnimation()
      "setIconSize" -> { iconSize = (argument as? Number)?.toFloat(); fitIcon() }
      "setTintColor" -> item.iconColor = (argument as? Number)?.toInt()
      "setItemBackgroundStyle" -> setItemBackgroundStyle(argument)
      "setItemBackgroundColor" -> item.itemBackgroundColor = (argument as? Number)?.toInt()
      "setItemCornerRadius" -> item.itemCornerRadius = (argument as? Number)?.toFloat()
      "setItemBorderWidth" -> item.itemBorderWidth = (argument as? Number)?.toFloat() ?: 0f
      "setItemBorderColor" -> item.itemBorderColor = (argument as? Number)?.toInt()
      "play" -> item.animatedItemPlayer.play()
      "stopAtProgress" -> item.animatedItemPlayer.stopAtProgress((argument as? Number)?.toFloat() ?: 0f)
      "restart" -> item.restartAnimation()
      else -> return result.notImplemented()
    }
    result.success(null)
  }
}
