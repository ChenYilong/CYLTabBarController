package com.cyl.tabbar.flutter_cyltabbar

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 * Registers the `flutter_cyltabbar/CYLTabBar` platform view: a CYLTabBarController made from a configuration, showing
 * only its tab bar. The tab bar controller needs a FragmentActivity: use FlutterFragmentActivity.
 */
class FlutterCyltabbarPlugin : FlutterPlugin, ActivityAware {
  private var activity: Activity? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    binding.platformViewRegistry.registerViewFactory(VIEW_TYPE, object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
      override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        CYLFlutterTabBarView(context, activity, viewId, args as? Map<*, *> ?: emptyMap<String, Any?>(), binding)
    })
    binding.platformViewRegistry.registerViewFactory("flutter_cyltabbar/CYLAnimationView", object : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
      override fun create(context: Context, viewId: Int, args: Any?): PlatformView =
        CYLFlutterAnimationView(context, viewId, args as? Map<*, *> ?: emptyMap<String, Any?>(), binding.binaryMessenger)
    })
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) = Unit

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  companion object {
    const val VIEW_TYPE = "flutter_cyltabbar/CYLTabBar"
  }
}
