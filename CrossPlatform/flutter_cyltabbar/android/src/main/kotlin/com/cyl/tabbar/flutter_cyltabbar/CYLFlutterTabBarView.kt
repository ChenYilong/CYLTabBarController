package com.cyl.tabbar.flutter_cyltabbar

import android.app.Activity
import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.DisplayMetrics
import android.util.Log
import android.view.View
import androidx.fragment.app.FragmentActivity
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLTabBarHostView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

/**
 * The platform view of `flutter_cyltabbar` on Android: a [CYLTabBarHostView] (a CYLTabBarController made from a
 * configuration, showing only its tab bar) with a method channel. The activity must be a FlutterFragmentActivity.
 */
internal class CYLFlutterTabBarView(
  context: Context,
  activity: Activity?,
  viewId: Int,
  arguments: Map<*, *>,
  private val binding: FlutterPlugin.FlutterPluginBinding,
) : PlatformView, MethodChannel.MethodCallHandler {

  private val hostView = CYLTabBarHostView(context)
  private val channel = MethodChannel(binding.binaryMessenger, "${FlutterCyltabbarPlugin.VIEW_TYPE}/$viewId")

  init {
    if (activity !is FragmentActivity) {
      Log.e("flutter_cyltabbar", "CYLTabBar needs a FragmentActivity: make MainActivity extend FlutterFragmentActivity.")
    }
    channel.setMethodCallHandler(this)
    hostView.activityProvider = { activity as? FragmentActivity }
    // Flutter clips platform views: the widget also holds what rises above the bar. Flutter 会裁剪平台视图：组件高度包含高出 TabBar 的部分。
    hostView.heightIncludesOverflow = true
    hostView.imageResolver = { value -> (value as? String)?.takeIf { it.startsWith(ASSET_PREFIX) }?.let { assetImage(it.removePrefix(ASSET_PREFIX)) } }
    hostView.didSelectTab = { index, identifier -> channel.invokeMethod("onTabSelect", mapOf("index" to index, "identifier" to identifier)) }
    hostView.didTapPlusButton = { channel.invokeMethod("onPlusButtonPress", null) }
    hostView.preferredHeightDidChange = { height -> channel.invokeMethod("onTabBarLayout", height.toDouble()) }
    // [EN] Dart hit-tests the platform view: only these rects take touches. [CN] Dart 对平台视图做命中测试：只有这些矩形接收触摸。
    hostView.touchableRectsDidChange = { rects ->
      channel.invokeMethod("onTouchableRects", rects.map { listOf(it.left.toDouble(), it.top.toDouble(), it.width().toDouble(), it.height().toDouble()) })
    }
    hostView.didLongPressTab = { index, identifier, title ->
      channel.invokeMethod("onTabLongPress", mapOf("index" to index, "identifier" to identifier, "title" to title))
    }
    hostView.plusButtonBadgeValue = arguments["plusButtonBadgeValue"] as? String
    hostView.badgeAnimationType = badgeAnimation(arguments["badgeAnimation"])
    hostView.selectedIndex = (arguments["selectedIndex"] as? Number)?.toInt() ?: -1
    hostView.badgeValues = (arguments["badgeValues"] as? List<*>)?.map { it?.toString().orEmpty() } ?: emptyList()
    hostView.setConfigurationJSON(arguments["configuration"] as? String)
  }

  override fun getView(): View = hostView

  override fun dispose() {
    channel.setMethodCallHandler(null)
    hostView.configuration = null
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "setConfiguration" -> if (!hostView.setConfigurationJSON(call.arguments as? String)) hostView.configuration = null
      "setSelectedIndex" -> hostView.selectedIndex = (call.arguments as? Number)?.toInt() ?: -1
      "setBadgeValues" -> hostView.badgeValues = (call.arguments as? List<*>)?.map { it?.toString().orEmpty() } ?: emptyList()
      "setPlusButtonBadgeValue" -> hostView.plusButtonBadgeValue = call.arguments as? String
      "setBadgeAnimation" -> hostView.badgeAnimationType = badgeAnimation(call.arguments)
      else -> return result.notImplemented()
    }
    result.success(null)
  }

  /** A Flutter asset, its best resolution variant first (`2.0x/`, `3.0x/`...). Flutter asset，优先取最合适的分辨率版本。 */
  private fun assetImage(path: String): Drawable? {
    val directory = path.substringBeforeLast('/', "")
    val file = path.substringAfterLast('/')
    val screenScale = hostView.resources.displayMetrics.density
    val variants = listOf(4f, 3f, 2f, 1.5f)
    val scales = variants.filter { it >= screenScale }.sorted() + variants.filter { it < screenScale } + 1f
    for (scale in scales) {
      val variant = if (scale == 1f) path else listOf(directory, "${scale}x", file).filter { it.isNotEmpty() }.joinToString("/")
      val bytes = runCatching {
        hostView.context.assets.open(binding.flutterAssets.getAssetFilePathByName(variant)).use { it.readBytes() }
      }.getOrNull() ?: continue
      val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size) ?: continue
      // A `3.0x` image is three pixels per point. `3.0x` 的图片每点三个像素。
      bitmap.density = (DisplayMetrics.DENSITY_DEFAULT * scale).toInt()
      return BitmapDrawable(hostView.resources, bitmap)
    }
    return null
  }

  private fun badgeAnimation(value: Any?): CYLEnums.CYLBadgeAnimationType =
    CYLEnums.CYLBadgeAnimationType.values().firstOrNull { it.rawValue == (value as? Number)?.toInt() } ?: CYLEnums.CYLBadgeAnimationType.None

  private companion object {
    const val ASSET_PREFIX = "flutter-asset:"
  }
}
