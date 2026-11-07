// [EN] The method names are the iOS names on purpose (`cyl_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.content.Context
import android.content.res.Configuration
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.ImageView
import java.io.File
import java.io.InputStream
import java.lang.ref.WeakReference
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors

/*
 * [EN] The tab icon animation layer of the `CYLTabBarItemAnimation` subspec (issue #604), for every animation library:
 *      the registry of animators, the factory of animation views, the players, and the short path for libraries whose
 *      view plays itself. The tab bar talks only to these interfaces (dependency inversion). Lottie, PAG and Rive
 *      register themselves when their Android library (lottie-android, libpag, rive-android) is in the app, found by
 *      reflection, as iOS compiles each animator only with its library; without it their keys are ignored and the tab
 *      shows its image.
 * [CN] `CYLTabBarItemAnimation` 子库（issue #604）的 Tab 图标动画层，适用于所有动画库：animator 注册表、动画视图工厂、播放器，以及视图可以
 *      自己播放的动画库的简便路径。TabBar 只与这些接口交互（依赖反转）。Lottie、PAG 与 Rive 在其 Android 库（lottie-android、libpag、
 *      rive-android）存在时通过反射自动注册，就像 iOS 只在链接了动画库时才编译对应的 animator；没有动画库时忽略其 key，Tab 显示图片。
 */

/** [EN] `CYLTabBarAnimationOption`: an option name of `CYLTabBarAnimationURLWithOptions()`. [CN] `CYLTabBarAnimationURLWithOptions()` 的选项名。 */
typealias CYLTabBarAnimationOption = String

/** [EN] `CYLTabBarItemAnimatorPriority`: higher first; equal priorities keep their registration order. [CN] 优先级高的先查找；相同时保持注册顺序。 */
typealias CYLTabBarItemAnimatorPriority = Int

/** [EN] An animator that recognizes its own files (the default). [CN] 只识别自己文件类型的 animator（默认）。 */
const val CYLTabBarItemAnimatorPriorityDefault: CYLTabBarItemAnimatorPriority = 0
/** [EN] An animator that takes any file no other animator takes (Lottie). [CN] 接收其他 animator 都不处理的文件的 animator（Lottie）。 */
const val CYLTabBarItemAnimatorPriorityFallback: CYLTabBarItemAnimatorPriority = -1000

/**
 * [EN] `CYLTabBarAnimationURLWithOptions()`: `fileURL` with `options` in its fragment ("name=value&…", percent-encoded,
 *      sorted by name so the same options always give the same URL). null for a null or blank `fileURL`.
 * [CN] 把 `options` 写入 `fileURL` 的 fragment（"name=value&…"，百分号编码，按名称排序，相同选项总得到相同 URL）。`fileURL` 为 null 或空时返回 null。
 */
fun CYLTabBarAnimationURLWithOptions(fileURL: String?, options: Map<CYLTabBarAnimationOption, String>?): String? {
    if (fileURL.isNullOrBlank()) return null
    val base = fileURL.substringBefore('#')
    val items = options.orEmpty().filter { it.key.isNotEmpty() && it.value.isNotEmpty() }.toSortedMap()
        .map { (name, value) -> Uri.encode(name) + "=" + Uri.encode(value) }
    return if (items.isEmpty()) base else base + "#" + items.joinToString("&")
}

/** [EN] Splits a tab's animation URL into the file and its options (the reverse of `CYLTabBarAnimationURLWithOptions()`). [CN] 把 Tab 的动画 URL 拆成文件与选项。 */
internal fun CYLTabBarAnimationFileAndOptions(url: String): Pair<String, Map<String, String>> {
    val fragment = url.substringAfter('#', "")
    val options = fragment.split('&').filter { it.contains('=') }.associate { Uri.decode(it.substringBefore('=')) to Uri.decode(it.substringAfter('=')) }
    return url.substringBefore('#') to options
}

/** [EN] The lowercase extension of a URL or path, without options or query. [CN] URL 或路径的小写扩展名（不含选项与查询）。 */
internal fun CYLTabBarAnimationFileExtension(url: String): String =
    url.substringBefore('#').substringBefore('?').substringAfterLast('/').substringAfterLast('.', "").lowercase()

// MARK: - Players 播放器

/**
 * [EN] `CYLTabBarItemAnimationPlayer`: controls one tab icon animation view, whatever its library. The optional members
 *      have defaults that do nothing.
 * [CN] 控制一个 Tab 图标动画视图，无论其动画库。可选成员的默认实现不做任何事。
 */
interface CYLTabBarItemAnimationPlayer {
    /** [EN] The view it controls (held weakly). [CN] 它所控制的视图（弱引用）。 */
    val animationView: View?
    /** [EN] Plays once, from the first frame. [CN] 从第一帧开始播放一次。 */
    fun play()
    /** [EN] Shows the last frame without playing (the tab selected at launch, #389). [CN] 不播放，直接显示最后一帧（#389）。 */
    fun showLastFrame()
    /** [EN] Stops, back to the first frame. [CN] 停止并回到第一帧。 */
    fun stop()
    /** [EN] The playback position, 0…1. [CN] 播放位置，0…1。 */
    var progress: Float
        get() = 0f
        set(@Suppress("UNUSED_PARAMETER") value) { /* [EN] Optional. [CN] 可选。 */ }
    /** [EN] The playback speed (#428); libraries without one ignore it. [CN] 播放速度（#428）；没有播放速度的动画库忽略它。 */
    var animationSpeed: Float
        get() = 1f
        set(@Suppress("UNUSED_PARAMETER") value) { /* [EN] Optional. [CN] 可选。 */ }
    /** [EN] Applies `darkColors` (keypath → color, #442) where `configuration` is dark, removes them otherwise. [CN] 深色模式下应用 `darkColors`，否则移除。 */
    fun applyDarkColors(darkColors: Map<String, Int>, configuration: Configuration) { /* [EN] Optional. [CN] 可选。 */ }
    /**
     * [EN] Applies `colors` (keypath → color, resolved for `configuration`: `CYLTabBarAnimationColors` plus the dark colors
     *      in Dark Mode); null or empty removes every override (#216). By default it forwards to `applyDarkColors`.
     * [CN] 应用 `colors`（已按 `configuration` 解析：`CYLTabBarAnimationColors` 加深色模式下的深色颜色）；null 或空移除所有覆盖（#216）。
     *      默认转发给 `applyDarkColors`。
     */
    fun applyColors(colors: Map<String, Int>?, configuration: Configuration) = applyDarkColors(colors.orEmpty(), configuration)
}

/** [EN] `CYLTabBarItemAnimationBasePlayer`: a convenient superclass that keeps the view weakly. [CN] 便捷父类，弱引用视图。 */
abstract class CYLTabBarItemAnimationBasePlayer(animationView: View) : CYLTabBarItemAnimationPlayer {
    private val viewReference = WeakReference(animationView)
    override val animationView: View? get() = viewReference.get()
}

// MARK: - Animators 动画库

/** [EN] `CYLTabBarItemAnimationFileMatching`: which files a library plays, and how it is looked up. [CN] 动画库播放哪些文件、如何被查找。 */
interface CYLTabBarItemAnimationFileMatching {
    /** [EN] A unique name, e.g. "Lottie"; registering the same name again replaces the animator. [CN] 唯一名称；重复注册同名时替换。 */
    val identifier: String
    /** [EN] true for an animation file this library plays. [CN] 本动画库能播放的文件返回 true。 */
    fun canAnimateFileAtURL(url: String): Boolean
    /** [EN] The lookup order (default `CYLTabBarItemAnimatorPriorityDefault`). [CN] 查找顺序。 */
    val priority: CYLTabBarItemAnimatorPriority get() = CYLTabBarItemAnimatorPriorityDefault
    /** [EN] The file extensions it plays, e.g. ["pag"], to find "<name>.<ext>" for a bare name. [CN] 它播放的文件扩展名。 */
    val fileExtensions: List<String> get() = emptyList()
    /** [EN] Its own attribute keys by the generic key they stand for, e.g. { CYLTabBarAnimationURL: CYLTabBarPAGURL }. [CN] 自有 key 与通用 key 的对应。 */
    val attributeKeys: Map<String, String> get() = emptyMap()
}

/** [EN] `CYLTabBarItemAnimationViewFactory`: the views a library makes, and a player for each. [CN] 动画库创建的视图及其播放器。 */
interface CYLTabBarItemAnimationViewFactory {
    /** [EN] A view showing the first frame of the animation at `url`; null when the file cannot be loaded. [CN] 显示 `url` 动画第一帧的视图；无法加载时为 null。 */
    fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View?
    /** [EN] A player for `view` when it is one of this library's views, else null. [CN] `view` 属于本动画库时返回其播放器，否则 null。 */
    fun playerForAnimationView(view: View): CYLTabBarItemAnimationPlayer?
}

/** [EN] `CYLTabBarItemAnimator`: an animation library for tab icons. [CN] Tab 图标动画库。 */
interface CYLTabBarItemAnimator : CYLTabBarItemAnimationFileMatching, CYLTabBarItemAnimationViewFactory

/** [EN] `CYLTabBarItemAnimatorRegistering`: what the engine and the factory need from a registry. [CN] 引擎与工厂需要的注册表能力。 */
interface CYLTabBarItemAnimatorRegistering {
    fun registerAnimator(animator: CYLTabBarItemAnimator)
    fun unregisterAnimatorWithIdentifier(identifier: String)
    /** [EN] By priority, then registration order. [CN] 按优先级、再按注册顺序。 */
    fun animators(): List<CYLTabBarItemAnimator>
    fun animatorWithIdentifier(identifier: String): CYLTabBarItemAnimator?
    /** [EN] The animator bound to `url`, else the first that can play its file. [CN] 绑定到 `url` 的 animator，否则第一个能播放的。 */
    fun animatorForURL(url: String?): CYLTabBarItemAnimator?
    /** [EN] The first animator whose own keys have a value in `attributes`. [CN] 第一个在 `attributes` 中有值的自有 key 所属的 animator。 */
    fun animatorForAttributes(attributes: Map<String, Any?>?): CYLTabBarItemAnimator?
    fun attributeKeyForGenericKey(genericKey: String, attributes: Map<String, Any?>?): String?
    /** [EN] Binds `url` to `animator` (null removes the binding). [CN] 把 `url` 绑定到 `animator`（null 移除绑定）。 */
    fun bindURL(url: String, animator: CYLTabBarItemAnimator?)
    fun attributeKeysForGenericKey(genericKey: String): List<String>
    fun fileExtensions(): List<String>
}

/**
 * [EN] `CYLTabBarItemAnimatorRegistry`: the animation libraries in the app, thread-safe. The shared instance registers
 *      Lottie, PAG and Rive when their libraries are present; the companion functions forward to it.
 * [CN] App 中的动画库，线程安全。共享实例在 Lottie、PAG 与 Rive 存在时注册它们；伴生对象的函数转发给共享实例。
 */
open class CYLTabBarItemAnimatorRegistry : CYLTabBarItemAnimatorRegistering {
    private val registered = CopyOnWriteArrayList<CYLTabBarItemAnimator>()
    private val bindings = java.util.concurrent.ConcurrentHashMap<String, String>()

    override fun registerAnimator(animator: CYLTabBarItemAnimator) {
        synchronized(registered) {
            val index = registered.indexOfFirst { it.identifier == animator.identifier }
            if (index >= 0) registered[index] = animator else registered += animator
        }
    }

    override fun unregisterAnimatorWithIdentifier(identifier: String) {
        synchronized(registered) { registered.removeAll { it.identifier == identifier } }
        bindings.entries.removeAll { it.value == identifier }
    }

    override fun animators(): List<CYLTabBarItemAnimator> = registered.withIndex().sortedWith(compareByDescending<IndexedValue<CYLTabBarItemAnimator>> { it.value.priority }.thenBy { it.index }).map { it.value }

    override fun animatorWithIdentifier(identifier: String): CYLTabBarItemAnimator? = registered.firstOrNull { it.identifier == identifier }

    override fun animatorForURL(url: String?): CYLTabBarItemAnimator? {
        if (url.isNullOrEmpty()) return null
        bindings[url.substringBefore('#')]?.let { bound -> animatorWithIdentifier(bound)?.let { return it } }
        return animators().firstOrNull { it.canAnimateFileAtURL(url) }
    }

    override fun animatorForAttributes(attributes: Map<String, Any?>?): CYLTabBarItemAnimator? {
        attributes ?: return null
        return animators().firstOrNull { animator -> animator.attributeKeys.values.any { key -> attributes[key].let { it != null && it != "" } } }
    }

    override fun attributeKeyForGenericKey(genericKey: String, attributes: Map<String, Any?>?): String? =
        animatorForAttributes(attributes)?.attributeKeys?.get(genericKey)

    override fun bindURL(url: String, animator: CYLTabBarItemAnimator?) {
        val key = url.substringBefore('#')
        if (animator == null) bindings.remove(key) else bindings[key] = animator.identifier
    }

    override fun attributeKeysForGenericKey(genericKey: String): List<String> = animators().mapNotNull { it.attributeKeys[genericKey] }

    override fun fileExtensions(): List<String> = animators().flatMap { it.fileExtensions }.map { it.lowercase() }.distinct()

    companion object {
        /** [EN] The instance the animators register into. [CN] animator 注册到的共享实例。 */
        @JvmStatic
        val sharedRegistry: CYLTabBarItemAnimatorRegistry by lazy {
            CYLTabBarItemAnimatorRegistry().apply {
                CYLLottieTabBarItemAnimator.takeIf { it.isAvailable }?.let { registerAnimator(it) }
                CYLPAGTabBarItemAnimator.takeIf { it.isAvailable }?.let { registerAnimator(it) }
                if (CYLRiveTabBarItemAnimator.isAvailable) registerAnimator(CYLRiveTabBarItemAnimator.animator)
                // [EN] GIF needs no library: the platform decodes it, as ImageIO does on iOS. [CN] GIF 不需要额外的库：由系统解码，如同 iOS 的 ImageIO。
                registerAnimator(CYLGIFTabBarItemAnimator.animator)
            }
        }
        fun registerAnimator(animator: CYLTabBarItemAnimator) = sharedRegistry.registerAnimator(animator)
        fun unregisterAnimatorWithIdentifier(identifier: String) = sharedRegistry.unregisterAnimatorWithIdentifier(identifier)
        fun animators(): List<CYLTabBarItemAnimator> = sharedRegistry.animators()
        fun animatorWithIdentifier(identifier: String) = sharedRegistry.animatorWithIdentifier(identifier)
        fun animatorForURL(url: String?) = sharedRegistry.animatorForURL(url)
        fun animatorForAttributes(attributes: Map<String, Any?>?) = sharedRegistry.animatorForAttributes(attributes)
        fun attributeKeyForGenericKey(genericKey: String, attributes: Map<String, Any?>?) = sharedRegistry.attributeKeyForGenericKey(genericKey, attributes)
        fun bindURL(url: String, animator: CYLTabBarItemAnimator?) = sharedRegistry.bindURL(url, animator)
        fun attributeKeysForGenericKey(genericKey: String) = sharedRegistry.attributeKeysForGenericKey(genericKey)
        fun fileExtensions() = sharedRegistry.fileExtensions()
    }
}

// MARK: - Factory 工厂

/** [EN] `CYLTabBarItemAnimationViewMaking`: makes animation views and finds their players. [CN] 创建动画视图并查找其播放器。 */
interface CYLTabBarItemAnimationViewMaking {
    fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View?
    fun playerForView(view: View?): CYLTabBarItemAnimationPlayer?
    fun isAnimationView(view: View?): Boolean
}

/**
 * [EN] `CYLTabBarItemAnimationFactory`: picks the library of a file from the registry, asks it for the view, sets the
 *      view up for a tab button (no touches, the content mode) and attaches its player.
 * [CN] 从注册表选择文件的动画库，请它创建视图，为 Tab 按钮配置视图（不接收触摸、内容模式）并绑定播放器。
 */
open class CYLTabBarItemAnimationFactory(val registry: CYLTabBarItemAnimatorRegistering) : CYLTabBarItemAnimationViewMaking {
    constructor() : this(CYLTabBarItemAnimatorRegistry.sharedRegistry)

    override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View? {
        val animator = registry.animatorForURL(url) ?: return null
        val view = try { animator.animationViewWithURL(context, url, size, contentMode) } catch (error: RuntimeException) { null } ?: return null
        view.isClickable = false
        view.isFocusable = false
        (view as? ImageView)?.scaleType = contentMode
        view.setTag(R.id.cyl_tab_bar_item_animation_player, animator.playerForAnimationView(view))
        return view
    }

    override fun playerForView(view: View?): CYLTabBarItemAnimationPlayer? {
        view ?: return null
        (view.getTag(R.id.cyl_tab_bar_item_animation_player) as? CYLTabBarItemAnimationPlayer)?.let { return it }
        return registry.animators().firstNotNullOfOrNull { it.playerForAnimationView(view) }?.also { view.setTag(R.id.cyl_tab_bar_item_animation_player, it) }
    }

    override fun isAnimationView(view: View?): Boolean = playerForView(view) != null

    companion object {
        @JvmStatic
        val sharedFactory: CYLTabBarItemAnimationFactory by lazy { CYLTabBarItemAnimationFactory() }
        fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType) = sharedFactory.animationViewWithURL(context, url, size, contentMode)
        fun playerForView(view: View?) = sharedFactory.playerForView(view)
        fun isAnimationView(view: View?) = sharedFactory.isAnimationView(view)
    }
}

// MARK: - The short path: views that play themselves 简便路径：自己播放的视图

/** [EN] `CYLTabBarItemAnimationPlayableView`: a view that plays, stops and shows its last frame. [CN] 能播放、停止并显示最后一帧的视图。 */
interface CYLTabBarItemAnimationPlayableView {
    fun cyl_playAnimationView()
    fun cyl_showAnimationViewLastFrame()
    fun cyl_stopAnimationView()
    /** [EN] Colors for Dark Mode, already resolved; null restores the light colors. [CN] 深色模式颜色（已解析）；null 恢复浅色。 */
    fun cyl_applyAnimationViewColors(colors: Map<String, Int>?) { /* [EN] Optional. [CN] 可选。 */ }
}

/** [EN] `CYLTabBarItemAnimationViewProviding`: makes playable views for `CYLTabBarItemViewAnimator`. [CN] 为 `CYLTabBarItemViewAnimator` 创建可播放视图。 */
interface CYLTabBarItemAnimationViewProviding {
    /** [EN] A view for `fileURL` with the `options` of the tab's URL; null when it cannot be made. [CN] `fileURL` 的视图（带 Tab URL 中的选项）；无法创建时为 null。 */
    fun cyl_animationViewWithFileURL(context: Context, fileURL: String, options: Map<String, String>, contentMode: ImageView.ScaleType): View?
}

/**
 * [EN] `CYLTabBarItemViewAnimator`: a ready-made animator for libraries whose view plays itself: it matches files by
 *      extension, splits the URL into the file and its options, asks `viewProvider` for the view, and plays it.
 * [CN] 为视图可以自己播放的动画库准备的 animator：按扩展名匹配文件，把 URL 拆成文件与选项，请 `viewProvider` 创建视图并播放。
 */
open class CYLTabBarItemViewAnimator(
    override val identifier: String,
    fileExtensions: List<String>,
    attributeKeys: Map<String, String>?,
    private val defaultViewProvider: CYLTabBarItemAnimationViewProviding?,
) : CYLTabBarItemAnimator {
    override val fileExtensions: List<String> = fileExtensions.map { it.lowercase() }
    override val attributeKeys: Map<String, String> = attributeKeys.orEmpty()
    /** [EN] Where the views come from; null goes back to the provider given at initialization. [CN] 视图来源；设为 null 恢复初始化时的 provider。 */
    var viewProvider: CYLTabBarItemAnimationViewProviding? = defaultViewProvider
        get() = field ?: defaultViewProvider
        set(value) { field = value ?: defaultViewProvider }

    override fun canAnimateFileAtURL(url: String): Boolean = CYLTabBarAnimationFileExtension(url) in fileExtensions

    override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View? {
        val (file, options) = CYLTabBarAnimationFileAndOptions(url)
        return viewProvider?.cyl_animationViewWithFileURL(context, file, options, contentMode)?.takeIf { it is CYLTabBarItemAnimationPlayableView }
    }

    override fun playerForAnimationView(view: View): CYLTabBarItemAnimationPlayer? {
        val playable = view as? CYLTabBarItemAnimationPlayableView ?: return null
        // [EN] A playable view made by another view animator is not this one's. [CN] 其他 view animator 创建的可播放视图不属于本 animator。
        val owner = view.getTag(R.id.cyl_tab_bar_item_view_animator) as? String
        if (owner != null && owner != identifier) return null
        view.setTag(R.id.cyl_tab_bar_item_view_animator, identifier)
        return object : CYLTabBarItemAnimationBasePlayer(view) {
            private var appliedColors: Map<String, Int>? = null
            override fun play() = playable.cyl_playAnimationView()
            override fun showLastFrame() = playable.cyl_showAnimationViewLastFrame()
            override fun stop() = playable.cyl_stopAnimationView()
            override fun applyColors(colors: Map<String, Int>?, configuration: Configuration) {
                // [EN] Only when the state changes, as on iOS. [CN] 与 iOS 一样，只在状态变化时应用。
                val next = colors?.takeIf { it.isNotEmpty() }
                if (next == appliedColors) return
                appliedColors = next
                playable.cyl_applyAnimationViewColors(next)
            }
        }
    }

}

// MARK: - Animation files 动画文件

/**
 * [EN] Opens a tab's animation file: an `http(s)` URL (downloaded once to the cache), a `file:` URL or absolute path,
 *      `file:///android_asset/…`, `asset:…`, `android.resource:` / `content:` URIs, or a bare name in the app's assets.
 *      The result is a local file for libraries that load paths (PAG) or a stream (Lottie, Rive).
 * [CN] 打开 Tab 的动画文件：`http(s)` URL（下载一次到缓存）、`file:` URL 或绝对路径、`file:///android_asset/…`、`asset:…`、
 *      `android.resource:` / `content:` URI，或 App assets 中的文件名。对加载路径的动画库（PAG）返回本地文件，对其他（Lottie、Rive）返回流。
 */
object CYLTabBarItemAnimationFiles {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun isRemote(url: String) = url.startsWith("http://") || url.startsWith("https://")

    /** [EN] The asset name of `url`, or null when it is not an asset. [CN] `url` 对应的 asset 名称；不是 asset 时为 null。 */
    fun assetName(url: String): String? = when {
        url.startsWith("file:///android_asset/") -> url.removePrefix("file:///android_asset/")
        url.startsWith("asset:///") -> url.removePrefix("asset:///")
        url.startsWith("asset:") -> url.removePrefix("asset:")
        url.contains(':') || url.startsWith("/") -> null
        else -> url
    }

    /** [EN] A stream of a local `url`, or null. [CN] 本地 `url` 的流，或 null。 */
    fun openLocal(context: Context, url: String): InputStream? = try {
        when {
            isRemote(url) -> null
            assetName(url) != null -> context.assets.open(assetName(url)!!)
            url.startsWith("file:") -> Uri.parse(url).path?.let { File(it).inputStream() }
            url.startsWith("/") -> File(url).inputStream()
            else -> context.contentResolver.openInputStream(Uri.parse(url))
        }
    } catch (error: java.io.IOException) { null } catch (error: SecurityException) { null }

    /** [EN] A local file of `url` (copied to the cache when it is an asset, a stream or remote), delivered on the main thread. [CN] `url` 的本地文件（asset、流或远程文件会复制到缓存），在主线程回调。 */
    fun localFile(context: Context, url: String, completion: (File?) -> Unit) {
        if (url.startsWith("/") && File(url).exists()) return completion(File(url))
        if (url.startsWith("file:") && !url.startsWith("file:///android_asset/")) return completion(Uri.parse(url).path?.let { File(it) }?.takeIf { it.exists() })
        val appContext = context.applicationContext
        executor.execute {
            val name = "cyl-animation-" + Integer.toHexString(url.hashCode()) + "." + CYLTabBarAnimationFileExtension(url).ifEmpty { "bin" }
            val target = File(appContext.cacheDir, name)
            val file = try {
                if (!target.exists() || target.length() == 0L) {
                    val input = if (isRemote(url)) java.net.URI(url).toURL().openStream() else openLocal(appContext, url)
                    input?.use { stream -> target.outputStream().use { stream.copyTo(it) } }
                }
                target.takeIf { it.exists() && it.length() > 0 }
            } catch (error: java.io.IOException) { null }
            mainHandler.post { completion(file) }
        }
    }
}

// MARK: - Reflection helpers 反射工具

/** [EN] Calls a method by name with arguments adapted to its parameters; null when it cannot. [CN] 按名称调用方法并适配参数；无法调用时返回 null。 */
internal object CYLReflection {
    fun type(name: String): Class<*>? = try { Class.forName(name) } catch (error: ClassNotFoundException) { null } catch (error: LinkageError) { null }

    fun call(target: Any, name: String, vararg args: Any?): Any? {
        val methods = target.javaClass.methods.filter { it.name == name && it.parameterTypes.size == args.size }
        for (method in methods) {
            val adapted = adapt(method.parameterTypes, args) ?: continue
            return try { method.invoke(target, *adapted) ?: Unit } catch (error: ReflectiveOperationException) { null } catch (error: RuntimeException) { null }
        }
        return null
    }

    /** [EN] Calls the overload of `name` with the fewest parameters, filling the missing ones with defaults. [CN] 调用参数最少的 `name` 重载，用默认值补齐缺少的参数。 */
    fun callWithDefaults(target: Any, name: String, provided: Map<Class<*>, Any?> = emptyMap()): Any? {
        val method = target.javaClass.methods.filter { it.name == name }.minByOrNull { it.parameterTypes.size } ?: return null
        val args = method.parameterTypes.map { type -> provided.entries.firstOrNull { type.isAssignableFrom(it.key) }?.value ?: defaultValue(type) }
        return try { method.invoke(target, *args.toTypedArray()) ?: Unit } catch (error: ReflectiveOperationException) { null } catch (error: RuntimeException) { null }
    }

    private fun defaultValue(type: Class<*>): Any? = when {
        type == java.lang.Boolean.TYPE -> false
        type == Integer.TYPE -> 0
        type == java.lang.Float.TYPE -> 0f
        type == java.lang.Double.TYPE -> 0.0
        type.isEnum -> type.enumConstants?.firstOrNull()
        else -> null
    }

    private fun adapt(types: Array<Class<*>>, args: Array<out Any?>): Array<Any?>? = Array(types.size) { index ->
        val type = types[index]
        val arg = args[index]
        when {
            arg == null -> if (type.isPrimitive) return null else null
            type == java.lang.Float.TYPE || type == java.lang.Float::class.java -> (arg as? Number)?.toFloat() ?: return null
            type == java.lang.Double.TYPE || type == java.lang.Double::class.java -> (arg as? Number)?.toDouble() ?: return null
            type == Integer.TYPE || type == Integer::class.java -> (arg as? Number)?.toInt() ?: return null
            type == java.lang.Boolean.TYPE || type == java.lang.Boolean::class.java -> arg as? Boolean ?: return null
            type.isInstance(arg) -> arg
            else -> return null
        }
    }

    fun staticField(className: String, field: String): Any? = try { type(className)?.getField(field)?.get(null) } catch (error: ReflectiveOperationException) { null }

    fun newInstance(className: String, context: Context): Any? {
        val type = type(className) ?: return null
        return try {
            type.getConstructor(Context::class.java).newInstance(context)
        } catch (error: ReflectiveOperationException) {
            try { type.getConstructor(Context::class.java, android.util.AttributeSet::class.java).newInstance(context, null) } catch (error: ReflectiveOperationException) { null }
        } catch (error: RuntimeException) { null } catch (error: LinkageError) { null }
    }
}

// MARK: - Lottie

/**
 * [EN] `CYLLottieTabBarItemAnimator`: Lottie tab icons with lottie-android (`com.airbnb.lottie.LottieAnimationView`),
 *      registered when that library is in the app. Looked up last: it plays every file no other animator plays.
 * [CN] 使用 lottie-android（`com.airbnb.lottie.LottieAnimationView`）的 Lottie Tab 图标，App 中有该库时注册。最后查找：播放其他 animator 都不播放的文件。
 */
object CYLLottieTabBarItemAnimator : CYLTabBarItemAnimator {
    private const val VIEW_CLASS = "com.airbnb.lottie.LottieAnimationView"
    val isAvailable: Boolean get() = CYLReflection.type(VIEW_CLASS) != null
    override val identifier: String = "Lottie"
    override val priority: CYLTabBarItemAnimatorPriority = CYLTabBarItemAnimatorPriorityFallback
    override val fileExtensions: List<String> = listOf("json", "lottie", "zip")
    override val attributeKeys: Map<String, String> = mapOf(
        CYLConstants.CYLTabBarAnimationURL to CYLConstants.CYLTabBarLottieURL,
        CYLConstants.CYLTabBarAnimationFilePath to CYLConstants.CYLTabBarLottieFilePath,
        CYLConstants.CYLTabBarAnimationSize to CYLConstants.CYLTabBarLottieSize,
        CYLConstants.CYLTabBarAnimationDarkURL to CYLConstants.CYLTabBarLottieDarkURL,
        CYLConstants.CYLTabBarAnimationDarkFilePath to CYLConstants.CYLTabBarLottieDarkFilePath,
        CYLConstants.CYLTabBarAnimationDarkColors to CYLConstants.CYLTabBarLottieDarkColors,
    )

    override fun canAnimateFileAtURL(url: String): Boolean = url.isNotEmpty()

    override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View? {
        val view = CYLReflection.newInstance(VIEW_CLASS, context) as? View ?: return null
        val file = url.substringBefore('#')
        val loaded = when {
            CYLTabBarItemAnimationFiles.isRemote(file) -> CYLReflection.call(view, "setAnimationFromUrl", file)
            CYLTabBarItemAnimationFiles.assetName(file) != null -> CYLReflection.call(view, "setAnimation", CYLTabBarItemAnimationFiles.assetName(file))
            else -> CYLTabBarItemAnimationFiles.openLocal(context, file)?.let { CYLReflection.call(view, "setAnimation", it, file) }
        }
        loaded ?: return null
        (view as? ImageView)?.scaleType = contentMode
        return view
    }

    override fun playerForAnimationView(view: View): CYLTabBarItemAnimationPlayer? =
        if (view.javaClass.name == VIEW_CLASS || CYLReflection.type(VIEW_CLASS)?.isInstance(view) == true) LottiePlayer(view) else null

    private class LottiePlayer(view: View) : CYLTabBarItemAnimationBasePlayer(view) {
        private val appliedKeyPaths = HashSet<String>()

        override fun play() { animationView?.let { CYLReflection.call(it, "setProgress", 0f); CYLReflection.call(it, "playAnimation") } }
        override fun showLastFrame() { animationView?.let { CYLReflection.call(it, "cancelAnimation"); CYLReflection.call(it, "setProgress", 1f) } }
        override fun stop() { animationView?.let { CYLReflection.call(it, "cancelAnimation"); CYLReflection.call(it, "setProgress", 0f) } }
        override var progress: Float
            get() = animationView?.let { CYLReflection.call(it, "getProgress") as? Float } ?: 0f
            set(value) { animationView?.let { CYLReflection.call(it, "setProgress", value) } }
        override var animationSpeed: Float
            get() = animationView?.let { CYLReflection.call(it, "getSpeed") as? Float } ?: 1f
            set(value) { animationView?.let { CYLReflection.call(it, "setSpeed", value) } }

        /** [EN] Colors by keypath ("Layer.Group.Fill 1.Color" or with "**"), through `addValueCallback(KeyPath, LottieProperty.COLOR, …)`. [CN] 按 keypath 设置颜色，通过 `addValueCallback`。 */
        override fun applyColors(colors: Map<String, Int>?, configuration: Configuration) {
            val view = animationView ?: return
            val keyPathClass = CYLReflection.type("com.airbnb.lottie.model.KeyPath") ?: return
            val callbackClass = CYLReflection.type("com.airbnb.lottie.value.LottieValueCallback") ?: return
            val colorProperty = CYLReflection.staticField("com.airbnb.lottie.LottieProperty", "COLOR") ?: return
            val next = colors.orEmpty()
            val method = view.javaClass.methods.firstOrNull { it.name == "addValueCallback" && it.parameterTypes.size == 3 && it.parameterTypes[2] == callbackClass } ?: return
            fun keyPath(path: String): Any? = try {
                keyPathClass.getConstructor(Array<String>::class.java).newInstance(path.removeSuffix(".Color").removeSuffix(".color").split('.').toTypedArray() as Any)
            } catch (error: ReflectiveOperationException) { null }
            for (path in appliedKeyPaths - next.keys) {
                try { method.invoke(view, keyPath(path), colorProperty, null) } catch (error: ReflectiveOperationException) { /* [EN] Ignored. [CN] 忽略。 */ }
            }
            for ((path, color) in next) {
                try { method.invoke(view, keyPath(path), colorProperty, callbackClass.getConstructor(Any::class.java).newInstance(color)) } catch (error: ReflectiveOperationException) { /* [EN] Ignored. [CN] 忽略。 */ }
            }
            appliedKeyPaths.clear()
            appliedKeyPaths += next.keys
        }
    }
}

// MARK: - PAG

/**
 * [EN] `CYLPAGTabBarItemAnimator`: PAG tab icons with libpag (`org.libpag.PAGView`), registered when libpag is in the
 *      app. ".pag" files; PAG has no playback speed.
 * [CN] 使用 libpag（`org.libpag.PAGView`）的 PAG Tab 图标，App 中有 libpag 时注册。".pag" 文件；PAG 没有播放速度。
 */
object CYLPAGTabBarItemAnimator : CYLTabBarItemAnimator {
    private const val VIEW_CLASS = "org.libpag.PAGView"
    val isAvailable: Boolean get() = CYLReflection.type(VIEW_CLASS) != null
    override val identifier: String = "PAG"
    override val fileExtensions: List<String> = listOf("pag")
    override val attributeKeys: Map<String, String> = mapOf(
        CYLConstants.CYLTabBarAnimationURL to CYLConstants.CYLTabBarPAGURL,
        CYLConstants.CYLTabBarAnimationFilePath to CYLConstants.CYLTabBarPAGFilePath,
        CYLConstants.CYLTabBarAnimationSize to CYLConstants.CYLTabBarPAGSize,
        CYLConstants.CYLTabBarAnimationDarkURL to CYLConstants.CYLTabBarPAGDarkURL,
        CYLConstants.CYLTabBarAnimationDarkFilePath to CYLConstants.CYLTabBarPAGDarkFilePath,
    )

    override fun canAnimateFileAtURL(url: String): Boolean = CYLTabBarAnimationFileExtension(url) == "pag"

    override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View? {
        val view = CYLReflection.newInstance(VIEW_CLASS, context) as? View ?: return null
        // [EN] PAGScaleMode: 1 stretch, 2 letterbox (fit), 3 zoom (fill). [CN] PAGScaleMode：1 拉伸，2 适应，3 填充。
        CYLReflection.call(view, "setScaleMode", when (contentMode) { ImageView.ScaleType.FIT_XY -> 1; ImageView.ScaleType.CENTER_CROP -> 3; else -> 2 })
        CYLTabBarItemAnimationFiles.localFile(context, url.substringBefore('#')) { file ->
            if (file != null) { CYLReflection.call(view, "setPath", file.absolutePath); CYLReflection.call(view, "flush") }
        }
        return view
    }

    override fun playerForAnimationView(view: View): CYLTabBarItemAnimationPlayer? =
        if (CYLReflection.type(VIEW_CLASS)?.isInstance(view) == true) PAGPlayer(view) else null

    private class PAGPlayer(view: View) : CYLTabBarItemAnimationBasePlayer(view) {
        override fun play() { animationView?.let { CYLReflection.call(it, "setRepeatCount", 1); CYLReflection.call(it, "setProgress", 0.0); CYLReflection.call(it, "play") } }
        override fun showLastFrame() { animationView?.let { CYLReflection.call(it, "stop"); CYLReflection.call(it, "setProgress", 1.0); CYLReflection.call(it, "flush") } }
        override fun stop() { animationView?.let { CYLReflection.call(it, "stop"); CYLReflection.call(it, "setProgress", 0.0); CYLReflection.call(it, "flush") } }
        override var progress: Float
            get() = animationView?.let { (CYLReflection.call(it, "getProgress") as? Double)?.toFloat() } ?: 0f
            set(value) { animationView?.let { CYLReflection.call(it, "setProgress", value.toDouble()); CYLReflection.call(it, "flush") } }
    }
}

// MARK: - Rive

/**
 * [EN] `CYLRiveTabBarItemAnimator`: Rive tab icons with rive-android (`app.rive.runtime.kotlin.RiveAnimationView`), through
 *      the short path: a `CYLTabBarItemViewAnimator` for ".riv" files whose views (`CYLRiveTabBarItemAnimationView`) play
 *      themselves. Registered when rive-android is in the app.
 * [CN] 使用 rive-android（`app.rive.runtime.kotlin.RiveAnimationView`）的 Rive Tab 图标，走简便路径：".riv" 文件的
 *      `CYLTabBarItemViewAnimator`，其视图（`CYLRiveTabBarItemAnimationView`）自己播放。App 中有 rive-android 时注册。
 */
object CYLRiveTabBarItemAnimator {
    internal const val VIEW_CLASS = "app.rive.runtime.kotlin.RiveAnimationView"
    val isAvailable: Boolean get() = CYLReflection.type(VIEW_CLASS) != null

    /** [EN] The registered animator, e.g. to inject another view provider. [CN] 已注册的 animator，例如用于注入其他视图 provider。 */
    @JvmStatic
    val animator: CYLTabBarItemViewAnimator by lazy {
        CYLTabBarItemViewAnimator("Rive", listOf("riv"), mapOf(
            CYLConstants.CYLTabBarAnimationURL to CYLConstants.CYLTabBarRiveURL,
            CYLConstants.CYLTabBarAnimationFilePath to CYLConstants.CYLTabBarRiveFilePath,
            CYLConstants.CYLTabBarAnimationSize to CYLConstants.CYLTabBarRiveSize,
            CYLConstants.CYLTabBarAnimationDarkURL to CYLConstants.CYLTabBarRiveDarkURL,
            CYLConstants.CYLTabBarAnimationDarkFilePath to CYLConstants.CYLTabBarRiveDarkFilePath,
            CYLConstants.CYLTabBarAnimationDarkColors to CYLConstants.CYLTabBarRiveDarkColors,
        ), CYLRiveTabBarItemAnimationView.Provider)
    }
}

/**
 * [EN] The Rive view of a tab: a `RiveAnimationView` (created by reflection) driven by the Rive options of the tab's URL:
 *      artboard, state machine, a boolean input set while the tab plays (`CYLTabBarAnimationOptionRiveInput`, or the
 *      active property), a trigger, a linear animation, the active duration.
 * [CN] Tab 的 Rive 视图：通过反射创建的 `RiveAnimationView`，由 Tab URL 中的 Rive 选项驱动：画板、状态机、播放期间设置的布尔输入
 *      （`CYLTabBarAnimationOptionRiveInput` 或 active 属性）、触发器、线性动画、持续时间。
 */
@android.annotation.SuppressLint("ViewConstructor") // [EN] Made by its provider around a RiveAnimationView, never inflated. [CN] 由 provider 围绕 RiveAnimationView 创建，不从 XML 加载。
class CYLRiveTabBarItemAnimationView private constructor(context: Context, private val rive: View, private val options: Map<String, String>) :
    android.widget.FrameLayout(context), CYLTabBarItemAnimationPlayableView {

    private val handler = Handler(Looper.getMainLooper())
    private val stateMachine get() = options[CYLConstants.CYLTabBarAnimationOptionRiveStateMachine]
    private val booleanInput get() = options[CYLConstants.CYLTabBarAnimationOptionRiveInput] ?: options[CYLConstants.CYLTabBarAnimationOptionRiveActiveProperty] ?: "active"
    private val activeDuration get() = options[CYLConstants.CYLTabBarAnimationOptionRiveActiveDuration]?.toDoubleOrNull() ?: 1.0

    init {
        addView(rive, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
    }

    private fun setActive(active: Boolean) {
        val machine = stateMachine ?: return
        CYLReflection.call(rive, "setBooleanState", machine, booleanInput, active)
    }

    override fun cyl_playAnimationView() {
        handler.removeCallbacksAndMessages(null)
        val machine = stateMachine
        val trigger = options[CYLConstants.CYLTabBarAnimationOptionRiveTriggerInput] ?: options[CYLConstants.CYLTabBarAnimationOptionRiveTriggerProperty]
        val animation = options[CYLConstants.CYLTabBarAnimationOptionRiveAnimation]
        when {
            machine != null && trigger != null -> CYLReflection.call(rive, "fireState", machine, trigger)
            machine != null -> {
                setActive(true)
                if (activeDuration > 0) handler.postDelayed({ setActive(false) }, (activeDuration * 1000).toLong())
            }
            animation != null -> CYLReflection.callWithDefaults(rive, "play", mapOf(String::class.java to animation))
            else -> { CYLReflection.callWithDefaults(rive, "reset"); CYLReflection.callWithDefaults(rive, "play") }
        }
    }

    override fun cyl_showAnimationViewLastFrame() {
        if (stateMachine != null) setActive(true) else CYLReflection.callWithDefaults(rive, "pause")
    }

    override fun cyl_stopAnimationView() {
        handler.removeCallbacksAndMessages(null)
        if (stateMachine != null) setActive(false) else { CYLReflection.callWithDefaults(rive, "stop"); CYLReflection.callWithDefaults(rive, "reset") }
    }

    /** [EN] Provides the views of `CYLRiveTabBarItemAnimator`. [CN] 为 `CYLRiveTabBarItemAnimator` 提供视图。 */
    object Provider : CYLTabBarItemAnimationViewProviding {
        override fun cyl_animationViewWithFileURL(context: Context, fileURL: String, options: Map<String, String>, contentMode: ImageView.ScaleType): View? {
            val rive = CYLReflection.newInstance(CYLRiveTabBarItemAnimator.VIEW_CLASS, context) as? View ?: return null
            val view = CYLRiveTabBarItemAnimationView(context, rive, options)
            CYLTabBarItemAnimationFiles.localFile(context, fileURL) { file ->
                val bytes = file?.readBytes() ?: return@localFile
                CYLReflection.callWithDefaults(rive, "setRiveBytes", mapOf(ByteArray::class.java to bytes))
                options[CYLConstants.CYLTabBarAnimationOptionRiveArtboard]?.let { CYLReflection.call(rive, "setArtboardName", it) }
                options[CYLConstants.CYLTabBarAnimationOptionRiveStateMachine]?.let { CYLReflection.callWithDefaults(rive, "play", mapOf(String::class.java to it, java.lang.Boolean.TYPE to true)) }
            }
            return view
        }
    }
}
