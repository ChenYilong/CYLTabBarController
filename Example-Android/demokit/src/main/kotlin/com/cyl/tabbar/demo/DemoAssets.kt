package com.cyl.tabbar.demo

import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import androidx.annotation.ColorInt
import com.cyl.tabbar.CYLTabBarConfiguration
import org.json.JSONObject
import java.io.File

/**
 * [EN] The demo apps take their images, colors and fonts from the iOS examples themselves, not from copies: an app's
 *      Gradle file adds the iOS example's `Assets.xcassets` (and its fonts, its animation files, the library's resource
 *      bundle) to its assets, and this reads them the way Xcode does:
 *      - `drawable(name)`: `<name>.imageset`, the @2x / @3x file closest to the screen density (decoded at its scale), the
 *        dark appearance in night mode, a PDF rendered with `PdfRenderer`; also `<name>@3x.png` files of a bundle.
 *      - `color(name)`: `<name>.colorset`, with its dark appearance.
 *      - `font(file)`: a font file of the assets.
 *      `install()` makes tab attributes that name images (`CYLTabBarItemImage: "Home"`) find them here first.
 * [CN] 演示 App 直接从 iOS 示例获取图片、颜色与字体，而不是副本：App 的 Gradle 文件把 iOS 示例的 `Assets.xcassets`（以及字体、动画文件、库的
 *      资源 bundle）加入 assets，这里按 Xcode 的方式读取：
 *      - `drawable(name)`：`<name>.imageset`，选择最接近屏幕密度的 @2x / @3x 文件（按其倍数解码），夜间模式使用深色外观，PDF 用 `PdfRenderer`
 *        渲染；也支持 bundle 中的 `<name>@3x.png` 文件。
 *      - `color(name)`：`<name>.colorset`，含深色外观。
 *      - `font(file)`：assets 中的字体文件。
 *      `install()` 让按名称引用图片的 Tab 属性（`CYLTabBarItemImage: "Home"`）先在这里查找。
 */
object DemoAssets {
    private var index: Map<String, String>? = null
    private val fonts = HashMap<String, Typeface>()

    /** [EN] Image set and color set names → their asset folders, and `name@Nx.png` files → their paths. [CN] 图片集与颜色集名称 → 其 assets 目录，`name@Nx.png` 文件 → 其路径。 */
    @Synchronized
    private fun index(context: Context): Map<String, String> = index ?: HashMap<String, String>().also { map ->
        fun walk(path: String, depth: Int) {
            if (depth > 6) return
            for (name in context.assets.list(path).orEmpty()) {
                val child = if (path.isEmpty()) name else "$path/$name"
                when {
                    name.endsWith(".imageset") || name.endsWith(".colorset") -> map.getOrPut(name) { child }
                    name.matches(Regex(".+@[23]x\\.png")) -> map.getOrPut(name.substringBefore('@') + "@png") { child }
                    !name.contains('.') -> walk(child, depth + 1)
                }
            }
        }
        walk("", 0)
        index = map
    }

    private fun isDark(context: Context) = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    private fun contents(context: Context, folder: String): JSONObject? =
        runCatching { context.assets.open("$folder/Contents.json").use { JSONObject(it.reader().readText()) } }.getOrNull()

    private fun isDarkEntry(entry: JSONObject): Boolean {
        val appearances = entry.optJSONArray("appearances") ?: return false
        return (0 until appearances.length()).any { appearances.getJSONObject(it).optString("value") == "dark" }
    }

    /** [EN] Decoded images, shared by every drawable made from them (one bitmap per name, density and appearance). [CN] 已解码的图片，由其生成的所有 drawable 共用（每个名称、密度与外观一个位图）。 */
    private val images = HashMap<String, Drawable.ConstantState>()
    private val missing = HashSet<String>()

    /** [EN] The image `name` of the iOS assets (a new drawable over a shared bitmap), or null. [CN] iOS 资源中名为 `name` 的图片（共用位图的新 drawable），或 null。 */
    fun drawable(context: Context, name: String): Drawable? {
        val key = "$name@${context.resources.displayMetrics.densityDpi}@${isDark(context)}"
        synchronized(images) { images[key] }?.let { return it.newDrawable(context.resources) }
        val drawable = decode(context, name) ?: run {
            // [EN] Logged once per name: an image the iOS examples do not have (or this app does not package). [CN] 每个名称只记录一次：iOS 示例中没有（或本 App 未打包）的图片。
            if (synchronized(missing) { missing.add(name) }) android.util.Log.w("CYLDemoAssets", "missing image: $name")
            return null
        }
        drawable.constantState?.let { state -> synchronized(images) { images[key] = state } }
        return drawable
    }

    private fun decode(context: Context, name: String): Drawable? {
        val index = index(context)
        index["$name.imageset"]?.let { folder -> return imageSet(context, folder) }
        // [EN] A bundle file such as cyl_theme_rocket@3x.png. [CN] bundle 中的文件，例如 cyl_theme_rocket@3x.png。
        return index["$name@png"]?.let { path -> bitmap(context, path, path.substringAfterLast('@').first().digitToInt().toFloat()) }
    }

    private fun imageSet(context: Context, folder: String): Drawable? {
        val images = contents(context, folder)?.optJSONArray("images") ?: return null
        val entries = (0 until images.length()).map { images.getJSONObject(it) }.filter { it.has("filename") }
        val dark = isDark(context)
        val candidates = entries.filter { isDarkEntry(it) == dark }.ifEmpty { entries.filter { !isDarkEntry(it) } }.ifEmpty { entries }
        val wanted = context.resources.displayMetrics.density
        val entry = candidates.minByOrNull { entry ->
            val scale = entry.optString("scale", "1x").removeSuffix("x").toFloatOrNull() ?: 1f
            // [EN] The closest scale, a larger one first (downscaling looks better). [CN] 最接近的倍数，优先更大的（缩小效果更好）。
            if (scale >= wanted) scale - wanted else (wanted - scale) * 2
        } ?: return null
        val file = "$folder/${entry.getString("filename")}"
        val scale = entry.optString("scale", "1x").removeSuffix("x").toFloatOrNull() ?: 1f
        return if (file.endsWith(".pdf", ignoreCase = true)) pdf(context, file) else bitmap(context, file, scale)
    }

    /** [EN] A bitmap of an @Nx file, decoded so that it keeps its size in points (dp). [CN] @Nx 文件的位图，解码后保持其点（dp）尺寸。 */
    private fun bitmap(context: Context, path: String, scale: Float): Drawable? = runCatching {
        val options = BitmapFactory.Options().apply {
            inDensity = (scale * 160).toInt()
            inTargetDensity = context.resources.displayMetrics.densityDpi
            inScaled = true
        }
        context.assets.open(path).use { BitmapFactory.decodeStream(it, null, options) }?.let { BitmapDrawable(context.resources, it) }
    }.getOrNull()

    /** [EN] A vector PDF of an image set (1 point = 1 dp), rendered at the screen density. [CN] 图片集中的矢量 PDF（1 点 = 1 dp），按屏幕密度渲染。 */
    private fun pdf(context: Context, path: String): Drawable? = runCatching {
        val file = File(context.cacheDir, "ios-assets/" + path.replace('/', '_')).apply {
            if (!exists()) { parentFile?.mkdirs(); context.assets.open(path).use { input -> outputStream().use { input.copyTo(it) } } }
        }
        ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
            PdfRenderer(descriptor).use { renderer ->
                renderer.openPage(0).use { page ->
                    val density = context.resources.displayMetrics.density
                    val bitmap = Bitmap.createBitmap((page.width * density).toInt().coerceAtLeast(1), (page.height * density).toInt().coerceAtLeast(1), Bitmap.Config.ARGB_8888)
                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                    BitmapDrawable(context.resources, bitmap)
                }
            }
        }
    }.getOrNull()

    /** [EN] The color `name` of the iOS assets (its dark appearance in night mode), or `fallback`. [CN] iOS 资源中名为 `name` 的颜色（夜间模式使用深色外观），或 `fallback`。 */
    @ColorInt
    fun color(context: Context, name: String, @ColorInt fallback: Int = Color.TRANSPARENT): Int {
        val folder = index(context)["$name.colorset"] ?: return fallback
        val colors = contents(context, folder)?.optJSONArray("colors") ?: return fallback
        val entries = (0 until colors.length()).map { colors.getJSONObject(it) }
        val entry = entries.firstOrNull { isDarkEntry(it) == isDark(context) } ?: entries.firstOrNull { !isDarkEntry(it) } ?: return fallback
        val components = entry.optJSONObject("color")?.optJSONObject("components") ?: return fallback
        fun component(key: String): Int {
            val value = components.optString(key, "0")
            return when {
                value.startsWith("0x", ignoreCase = true) -> value.substring(2).toInt(16)
                value.contains('.') -> (value.toFloat() * 255).toInt()
                else -> value.toIntOrNull() ?: 0
            }.coerceIn(0, 255)
        }
        val alpha = (components.optString("alpha", "1").toFloatOrNull() ?: 1f) * 255
        return Color.argb(alpha.toInt(), component("red"), component("green"), component("blue"))
    }

    /** [EN] A font file of the assets (e.g. the course's "Poppins-Bold.ttf"), or the default font. [CN] assets 中的字体文件（如课程的 "Poppins-Bold.ttf"），或默认字体。 */
    @Synchronized
    fun font(context: Context, file: String): Typeface = fonts.getOrPut(file) {
        runCatching { Typeface.createFromAsset(context.assets, file) }.getOrDefault(Typeface.DEFAULT)
    }

    /** [EN] Tab attributes that name images find them in the iOS assets first, then as before. [CN] 按名称引用图片的 Tab 属性先在 iOS 资源中查找，然后按原方式查找。 */
    @Synchronized
    fun install() {
        val previous = CYLTabBarConfiguration.imageResolver
        if (previous is IOSResolver) return
        CYLTabBarConfiguration.imageResolver = IOSResolver(previous)
    }

    private class IOSResolver(private val previous: CYLTabBarConfiguration.CYLTabBarImageResolver) : CYLTabBarConfiguration.CYLTabBarImageResolver {
        override fun drawable(context: Context, name: String): Drawable? =
            (if (name.startsWith("system:")) null else DemoAssets.drawable(context, name)) ?: previous.drawable(context, name)
    }
}
