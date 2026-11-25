package com.cyl.animateditem

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.ConcurrentHashMap

/**
 * [EN] The animation rendering mode (`animationRenderingMode`, URL option `renderingMode=`), the same names on every platform.
 *      It only applies while no `animationTint` is set (an explicit tint always wins). `Automatic` (default): tint with the effective
 *      icon color only if the file is detected as ONE-COLOR (`CYLAnimationColorCount`); undetectable or multi-color files keep their
 *      own colors. `AlwaysTemplate`: tint with the effective icon color regardless. `AlwaysOriginal`: never tint.
 * [CN] 动画渲染模式（`animationRenderingMode`，URL 选项 `renderingMode=`），各平台同名。仅在没有设置 `animationTint` 时生效（显式着色始终优先）。
 *      `Automatic`（默认）：仅当文件被检测为单色（`CYLAnimationColorCount`）时才用有效图标颜色着色；无法检测或多色的文件保持自身颜色。
 *      `AlwaysTemplate`：无论如何都用有效图标颜色着色。`AlwaysOriginal`：从不着色。
 */
enum class CYLAnimationRenderingMode(val optionValue: String) {
    Automatic("automatic"),
    AlwaysTemplate("alwaysTemplate"),
    AlwaysOriginal("alwaysOriginal");

    companion object {
        /**
         * [EN] The URL option name. [CN] URL 选项名称。
         */
        const val OPTION_NAME = "renderingMode"

        /**
         * [EN] The mode of an option value (case-insensitive, trimmed); null for a missing or unknown text. [CN] 选项值对应的模式（不区分大小写、去除空白）；缺失或未知文本为 null。
         */
        @JvmStatic
        fun parse(text: String?): CYLAnimationRenderingMode? {
            val value = text?.trim()?.takeIf { it.isNotEmpty() } ?: return null
            return values().firstOrNull { it.optionValue.equals(value, ignoreCase = true) }
        }
    }
}

/**
 * [EN] ONE-COLOR DETECTION: a PURE function over the file data (same algorithm and fixtures on every platform), cached per file URL.
 *      - Lottie JSON: the distinct RGB of every fill (`fl`) and stroke (`st`) color, static value and every keyframe value (`s`, `e`),
 *        in file order (root layers, then assets). Alpha is ignored; a color whose 4th component (alpha) is 0, and a fill / stroke
 *        whose static opacity `o` is 0, are fully transparent and skipped. Two colors within +-2/255 per channel are the same
 *        (compared with the representatives found so far). Gradients (`gf` / `gs`), image layers (`ty` 2) and image assets
 *        (an asset with `p` and no `layers`) are multi-color. Exactly one distinct color: one-color; more: multi-color; none, or
 *        a text that is not a JSON object: undetectable.
 *      - GIF: the FIRST frame (un-premultiplied ARGB); pixels with alpha < 0.1 are ignored; the rest is quantized to 4 bits per
 *        channel; one bucket holding >= 98% of them: one-color, else multi-color; no pixel left: undetectable.
 *      - PAG, SVGA, Rive and anything else: undetectable (original colors unless an explicit tint / `AlwaysTemplate`).
 * [CN] 单色检测：对文件数据的纯函数（各平台算法与测试夹具相同），按文件 URL 缓存。
 *      - Lottie JSON：每个填充（`fl`）与描边（`st`）颜色（静态值与每个关键帧值 `s`、`e`）的不同 RGB，按文件顺序（根图层，然后 assets）。忽略 alpha；
 *        第 4 分量（alpha）为 0 的颜色、静态不透明度 `o` 为 0 的填充 / 描边视为完全透明并跳过。每通道相差 +-2/255 以内视为同一颜色（与已找到的代表色比较）。
 *        渐变（`gf` / `gs`）、图片图层（`ty` 为 2）与图片 asset（有 `p` 且没有 `layers`）为多色。恰好一种颜色：单色；更多：多色；没有，
 *        或文本不是 JSON 对象：无法检测。
 *      - GIF：第一帧（非预乘 ARGB）；alpha < 0.1 的像素忽略；其余量化为每通道 4 位；某一桶占 >= 98%：单色，否则多色；没有剩余像素：无法检测。
 *      - PAG、SVGA、Rive 及其他：无法检测（保持原色，除非显式着色 / `AlwaysTemplate`）。
 */
object CYLAnimationColorCount {
    enum class Kind { OneColor, MultiColor, Undetectable }

    /** [EN] Share of the visible GIF pixels one bucket must hold. [CN] 一个桶必须占有的可见 GIF 像素比例。 */
    const val GIF_ONE_COLOR_SHARE = 0.98

    /** [EN] Per-channel tolerance (out of 255) of two Lottie colors that count as the same. [CN] 两个 Lottie 颜色视为相同的每通道容差（满值 255）。 */
    const val LOTTIE_TOLERANCE = 2

    // MARK: - Lottie

    /**
     * [EN] The kind of Lottie JSON `text`. [CN] Lottie JSON `text` 的类型。
     */
    @JvmStatic
    fun lottieKind(text: String): Kind {
        val root = try { JSONObject(text) } catch (error: Exception) { return Kind.Undetectable }
        return try { LottieScan().scan(root) } catch (error: Exception) { Kind.Undetectable }
    }

    private class LottieScan {
        private val colors = ArrayList<IntArray>()
        private var multi = false

        fun scan(root: JSONObject): Kind {
            layers(root.optJSONArray("layers"))
            val assets = root.optJSONArray("assets")
            if (assets != null) for (index in 0 until assets.length()) {
                val asset = assets.optJSONObject(index) ?: continue
                if (asset.has("p") && !asset.has("layers")) multi = true
                layers(asset.optJSONArray("layers"))
            }
            return when {
                multi || colors.size > 1 -> Kind.MultiColor
                colors.size == 1 -> Kind.OneColor
                else -> Kind.Undetectable
            }
        }

        private fun layers(array: JSONArray?) {
            array ?: return
            for (index in 0 until array.length()) {
                val layer = array.optJSONObject(index) ?: continue
                when (layer.optInt("ty", -1)) {
                    2 -> multi = true
                    4 -> shapes(layer.optJSONArray("shapes"))
                }
            }
        }

        private fun shapes(array: JSONArray?) {
            array ?: return
            for (index in 0 until array.length()) {
                val shape = array.optJSONObject(index) ?: continue
                when (shape.optString("ty")) {
                    "gf", "gs" -> multi = true
                    "fl", "st" -> if (!transparentOpacity(shape.optJSONObject("o"))) property(shape.optJSONObject("c"))
                    "gr" -> shapes(shape.optJSONArray("it"))
                }
            }
        }

        private fun transparentOpacity(opacity: JSONObject?): Boolean {
            opacity ?: return false
            if (opacity.optInt("a", 0) != 0) return false
            val value = opacity.opt("k")
            return value is Number && value.toDouble() == 0.0
        }

        private fun property(color: JSONObject?) {
            val keys = color?.optJSONArray("k") ?: return
            if (keys.length() == 0) return
            if (keys.opt(0) is Number) { add(keys); return }
            for (index in 0 until keys.length()) {
                val keyframe = keys.optJSONObject(index) ?: continue
                add(keyframe.optJSONArray("s"))
                add(keyframe.optJSONArray("e"))
            }
        }

        private fun add(values: JSONArray?) {
            values ?: return
            if (values.length() < 3) return
            val rgb = IntArray(3)
            for (channel in 0 until 3) {
                val value = values.opt(channel) as? Number ?: return
                rgb[channel] = Math.round(value.toDouble() * 255.0).toInt().coerceIn(0, 255)
            }
            val alpha = values.opt(3) as? Number
            if (alpha != null && alpha.toDouble() == 0.0) return
            if (colors.any { known -> (0 until 3).all { Math.abs(known[it] - rgb[it]) <= LOTTIE_TOLERANCE } }) return
            colors.add(rgb)
        }
    }

    // MARK: - GIF

    /**
     * [EN] The kind of GIF `bytes` (the first frame). [CN] GIF `bytes` 的类型（第一帧）。
     */
    @JvmStatic
    fun gifKind(bytes: ByteArray): Kind {
        val pixels = CYLGIFDecoder.decode(bytes)?.pixels?.firstOrNull() ?: return Kind.Undetectable
        return gifKind(pixels)
    }

    /**
     * [EN] The kind of the ARGB (un-premultiplied) pixels of a first frame. [CN] 第一帧 ARGB（非预乘）像素的类型。
     */
    @JvmStatic
    fun gifKind(pixels: IntArray): Kind {
        val buckets = IntArray(4096)
        var visible = 0
        for (pixel in pixels) {
            val alpha = pixel ushr 24
            if (alpha / 255.0 < 0.1) continue
            val r = (pixel shr 16) and 0xFF
            val g = (pixel shr 8) and 0xFF
            val b = pixel and 0xFF
            buckets[((r shr 4) shl 8) or ((g shr 4) shl 4) or (b shr 4)]++
            visible++
        }
        if (visible == 0) return Kind.Undetectable
        var largest = 0
        for (count in buckets) if (count > largest) largest = count
        return if (largest >= GIF_ONE_COLOR_SHARE * visible) Kind.OneColor else Kind.MultiColor
    }

    // MARK: - Files 文件

    /**
     * [EN] The kind of the file `extension` ("json" / "gif", lowercase) with its data; other extensions are undetectable.
     * [CN] 扩展名为 `extension`（"json" / "gif"，小写）的文件数据的类型；其他扩展名无法检测。
     */
    @JvmStatic
    fun kind(extension: String, bytes: ByteArray): Kind = when (extension) {
        "json" -> lottieKind(String(bytes, Charsets.UTF_8))
        "gif" -> gifKind(bytes)
        else -> Kind.Undetectable
    }

    private val cache = ConcurrentHashMap<String, Kind>()

    /**
     * [EN] Forgets the cached kinds (tests). [CN] 清除缓存的类型（测试用）。
     */
    @JvmStatic
    fun clearCache() = cache.clear()

    /**
     * [EN] The kind of the animation source `url` (a file path / asset / `file:` / remote URL with options, or inline Lottie JSON),
     *      cached per file URL. A file that cannot be read yet (a download not finished, a missing file) is undetectable and not
     *      cached, so a later call sees the file. Reads local files and the download cache only; never the network.
     * [CN] 动画来源 `url`（带选项的文件路径 / asset / `file:` / 远程 URL，或内联 Lottie JSON）的类型，按文件 URL 缓存。暂时无法读取的文件
     *      （下载未完成、文件缺失）为无法检测且不缓存，之后再次调用会看到文件。只读本地文件与下载缓存，从不访问网络。
     */
    @JvmStatic
    fun kindOfSource(context: Context, url: String?): Kind {
        val text = url?.trim()?.takeIf { it.isNotEmpty() } ?: return Kind.Undetectable
        if (text.startsWith("{")) return lottieKind(text)
        // [EN] The same file text the animators open (the URL up to the first `#`). [CN] 与各 animator 打开的文件文本相同（第一个 `#` 之前的 URL）。
        val file = text.substringBefore('#')
        val extension = CYLTabBarAnimationFileExtension(file)
        if (extension != "json" && extension != "gif") return Kind.Undetectable
        cache[file]?.let { return it }
        val bytes = try { CYLTabBarItemAnimationFiles.readBytes(context, file) } catch (error: java.io.IOException) { null }
            ?: return Kind.Undetectable
        return kind(extension, bytes).also { cache[file] = it }
    }
}
