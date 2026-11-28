package com.cyl.tabbar.flutter_cyltabbar

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Handler
import android.os.Looper
import java.net.URI

/**
 * Loads the still image of `image` like `source`: an asset name (or `asset:` / `file:///android_asset/`), a path or
 * `file://`, or an http(s) URL (read off the main thread). 像 `source` 一样加载 `image`：asset 名称、路径或 URL（网络图片在后台线程读取）。
 */
internal object CYLFlutterStillImage {
  private const val ASSET_URI = "file:///android_asset/"

  /** The drawable for `value`, or null when it names nothing readable. Blocks for a URL: call it off the main thread. */
  fun load(context: Context, value: String): Drawable? {
    val bitmap: Bitmap? = try {
      when {
        value.startsWith("http://") || value.startsWith("https://") -> URI(value).toURL().openStream().use(BitmapFactory::decodeStream)
        value.startsWith(ASSET_URI) -> context.assets.open(value.removePrefix(ASSET_URI)).use(BitmapFactory::decodeStream)
        value.startsWith("file://") -> BitmapFactory.decodeFile(value.removePrefix("file://"))
        value.startsWith("/") -> BitmapFactory.decodeFile(value)
        else -> context.assets.open(value.removePrefix("asset:")).use(BitmapFactory::decodeStream)
      }
    } catch (error: java.io.IOException) { null } catch (error: java.net.URISyntaxException) { null }
    return bitmap?.let { BitmapDrawable(context.resources, it) }
  }

  /** Delivers [load]'s result on the main thread: at once for a local file, later for a URL. */
  fun loadAsync(context: Context, value: String, deliver: (Drawable?) -> Unit) {
    if (!value.startsWith("http://") && !value.startsWith("https://")) return deliver(load(context, value))
    Thread { val drawable = load(context, value); Handler(Looper.getMainLooper()).post { deliver(drawable) } }.start()
  }
}
