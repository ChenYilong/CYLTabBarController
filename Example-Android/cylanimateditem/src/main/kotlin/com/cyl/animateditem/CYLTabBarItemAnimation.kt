// [EN] The method names are the iOS names on purpose (`cyl_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.animateditem

import androidx.annotation.RestrictTo
import android.content.Context
import android.content.res.Configuration
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
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

/**
 * [EN] `CYLTabBarAnimationOption`: an option name of `CYLTabBarAnimationURLWithOptions()`. [CN] `CYLTabBarAnimationURLWithOptions()` 的选项名。
 */
typealias CYLTabBarAnimationOption = String

/**
 * [EN] `CYLTabBarItemAnimatorPriority`: higher first; equal priorities keep their registration order. [CN] 优先级高的先查找；相同时保持注册顺序。
 */
typealias CYLTabBarItemAnimatorPriority = Int

/**
 * [EN] An animator that recognizes its own files (the default). [CN] 只识别自己文件类型的 animator（默认）。
 */
const val CYLTabBarItemAnimatorPriorityDefault: CYLTabBarItemAnimatorPriority = 0
/**
 * [EN] An animator that takes any file no other animator takes (Lottie). [CN] 接收其他 animator 都不处理的文件的 animator（Lottie）。
 */
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

/**
 * [EN] Splits a tab's animation URL into the file and its options (the reverse of `CYLTabBarAnimationURLWithOptions()`). [CN] 把 Tab 的动画 URL 拆成文件与选项。
 */
@RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
fun CYLTabBarAnimationFileAndOptions(url: String): Pair<String, Map<String, String>> {
    val fragment = url.substringAfter('#', "")
    val options = fragment.split('&').filter { it.contains('=') }.associate { Uri.decode(it.substringBefore('=')) to Uri.decode(it.substringAfter('=')) }
    return url.substringBefore('#') to options
}

/**
 * [EN] The lowercase extension of a URL or path, without options or query. [CN] URL 或路径的小写扩展名（不含选项与查询）。
 */
@RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
fun CYLTabBarAnimationFileExtension(url: String): String =
    url.substringBefore('#').substringBefore('?').substringAfterLast('/').substringAfterLast('.', "").lowercase()

// MARK: - Players 播放器

/**
 * [EN] `CYLTabBarItemAnimationPlayer`: controls one tab icon animation view, whatever its library. The optional members
 *      have defaults that do nothing.
 * [CN] 控制一个 Tab 图标动画视图，无论其动画库。可选成员的默认实现不做任何事。
 */
interface CYLTabBarItemAnimationPlayer {
    /**
     * [EN] The view it controls (held weakly). [CN] 它所控制的视图（弱引用）。
     */
    val animationView: View?
    /**
     * [EN] Plays once, from the first frame. [CN] 从第一帧开始播放一次。
     */
    fun play()
    /**
     * [EN] Shows the last frame without playing (the tab selected at launch, #389). [CN] 不播放，直接显示最后一帧（#389）。
     */
    fun showLastFrame()
    /**
     * [EN] Stops, back to the first frame. [CN] 停止并回到第一帧。
     */
    fun stop()
    /**
     * [EN] Pauses on the current frame (the user is scrolling). Optional: an engine without a pause keeps playing. [CN] 暂停在当前帧（用户正在滚动）。可选：没有暂停能力的引擎会继续播放。
     */
    fun pause() { /* [EN] Optional. [CN] 可选。 */ }
    /**
     * [EN] Continues from the paused frame. Optional. [CN] 从暂停的帧继续。可选。
     */
    fun resume() { /* [EN] Optional. [CN] 可选。 */ }
    /**
     * [EN] The playback position, 0…1. [CN] 播放位置，0…1。
     */
    var progress: Float
        get() = 0f
        set(@Suppress("UNUSED_PARAMETER") value) { /* [EN] Optional. [CN] 可选。 */ }
    /**
     * [EN] The playback speed (#428); libraries without one ignore it. [CN] 播放速度（#428）；没有播放速度的动画库忽略它。
     */
    var animationSpeed: Float
        get() = 1f
        set(@Suppress("UNUSED_PARAMETER") value) { /* [EN] Optional. [CN] 可选。 */ }
    /**
     * [EN] Whether the animation repeats until this is turned off (iOS `loops`); false: it plays once. Applies to the
     *      animation already playing. Libraries without a loop ignore it.
     * [CN] 动画是否重复播放直到关闭（iOS 的 `loops`）；false 时只播放一次。对正在播放的动画同样生效。没有循环的动画库忽略它。
     */
    var loops: Boolean
        get() = false
        set(@Suppress("UNUSED_PARAMETER") value) { /* [EN] Optional. [CN] 可选。 */ }
    /**
     * [EN] Applies `darkColors` (keypath → color, #442) where `configuration` is dark, removes them otherwise. [CN] 深色模式下应用 `darkColors`，否则移除。
     */
    fun applyDarkColors(darkColors: Map<String, Int>, configuration: Configuration) { /* [EN] Optional. [CN] 可选。 */ }
    /**
     * [EN] Applies `colors` (keypath → color, resolved for `configuration`: `CYLTabBarAnimationColors` plus the dark colors
     *      in Dark Mode); null or empty removes every override (#216). By default it forwards to `applyDarkColors`.
     * [CN] 应用 `colors`（已按 `configuration` 解析：`CYLTabBarAnimationColors` 加深色模式下的深色颜色）；null 或空移除所有覆盖（#216）。
     *      默认转发给 `applyDarkColors`。
     */
    fun applyColors(colors: Map<String, Int>?, configuration: Configuration) = applyDarkColors(colors.orEmpty(), configuration)
    /**
     * [EN] The tab's current tint (its title color, normal or selected), set by the tab bar on every state change; an
     *      animation whose `CYLTabBarAnimationOptionTint` option is "title" draws in it. Libraries without a tint ignore it.
     * [CN] Tab 当前的着色（其标题颜色，普通或选中），TabBar 在每次状态变化时设置；`CYLTabBarAnimationOptionTint` 选项为 "title" 的动画用它绘制。
     *      没有着色的动画库忽略它。
     */
    var tintColor: Int?
        get() = null
        set(@Suppress("UNUSED_PARAMETER") value) { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] The tab's tint with its state (iOS `-cyl_applyAnimationViewTintColor:selected:`): a fixed `tint` colors only the
     *      unselected tab, the selected one takes `color` (the title's selected color), as "title" does. The default sets
     *      `tintColor`, so a caller without the state keeps the fixed tint in both states.
     * [CN] 带状态的 Tab 着色（iOS `-cyl_applyAnimationViewTintColor:selected:`）：固定 `tint` 只为未选中的 Tab 着色，选中的 Tab 使用
     *      `color`（标题的选中颜色），与 "title" 相同。默认实现设置 `tintColor`，因此不带状态的调用方在两种状态下都保留固定着色。
     */
    fun setTintColor(color: Int?, selected: Boolean) { tintColor = color }

    /**
     * [EN] Whether a pass is playing now: true or false, or null when the library cannot tell (the default).
     *      `CYLAnimatedItemView` reads it to find the end of a play-once animation (`showsImageWhenAnimationEnds`,
     *      `animationEndListener`); with null it falls back to `progress` reaching 1.
     * [CN] 当前是否正在播放：true 或 false；动画库无法判断时为 null（默认）。`CYLAnimatedItemView` 读取它来发现只播放一次的动画何时结束
     *      （`showsImageWhenAnimationEnds`、`animationEndListener`）；为 null 时改为判断 `progress` 是否到达 1。
     */
    val isPlaying: Boolean? get() = null
}

/**
 * [EN] `CYLTabBarItemAnimationBasePlayer`: a convenient superclass that keeps the view weakly. [CN] 便捷父类，弱引用视图。
 */
abstract class CYLTabBarItemAnimationBasePlayer(animationView: View) : CYLTabBarItemAnimationPlayer {
    private val viewReference = WeakReference(animationView)
    override val animationView: View? get() = viewReference.get()
}

// MARK: - Animators 动画库

/**
 * [EN] `CYLTabBarItemAnimationFileMatching`: which files a library plays, and how it is looked up. [CN] 动画库播放哪些文件、如何被查找。
 */
interface CYLTabBarItemAnimationFileMatching {
    /**
     * [EN] A unique name, e.g. "Lottie"; registering the same name again replaces the animator. [CN] 唯一名称；重复注册同名时替换。
     */
    val identifier: String
    /**
     * [EN] true for an animation file this library plays. [CN] 本动画库能播放的文件返回 true。
     */
    fun canAnimateFileAtURL(url: String): Boolean
    /**
     * [EN] The lookup order (default `CYLTabBarItemAnimatorPriorityDefault`). [CN] 查找顺序。
     */
    val priority: CYLTabBarItemAnimatorPriority get() = CYLTabBarItemAnimatorPriorityDefault
    /**
     * [EN] The file extensions it plays, e.g. ["pag"], to find "<name>.<ext>" for a bare name. [CN] 它播放的文件扩展名。
     */
    val fileExtensions: List<String> get() = emptyList()
    /**
     * [EN] Its own attribute keys by the generic key they stand for, e.g. { CYLTabBarAnimationURL: CYLTabBarPAGURL }. [CN] 自有 key 与通用 key 的对应。
     */
    val attributeKeys: Map<String, String> get() = emptyMap()
}

/**
 * [EN] `CYLTabBarItemAnimationViewFactory`: the views a library makes, and a player for each. [CN] 动画库创建的视图及其播放器。
 */
interface CYLTabBarItemAnimationViewFactory {
    /**
     * [EN] A view showing the first frame of the animation at `url`; null when the file cannot be loaded. [CN] 显示 `url` 动画第一帧的视图；无法加载时为 null。
     */
    fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View?
    /**
     * [EN] A player for `view` when it is one of this library's views, else null. [CN] `view` 属于本动画库时返回其播放器，否则 null。
     */
    fun playerForAnimationView(view: View): CYLTabBarItemAnimationPlayer?
}

/**
 * [EN] `CYLTabBarItemAnimator`: an animation library for tab icons. [CN] Tab 图标动画库。
 */
interface CYLTabBarItemAnimator : CYLTabBarItemAnimationFileMatching, CYLTabBarItemAnimationViewFactory

/**
 * [EN] `CYLTabBarItemAnimatorRegistering`: what the engine and the factory need from a registry. [CN] 引擎与工厂需要的注册表能力。
 */
interface CYLTabBarItemAnimatorRegistering {
    fun registerAnimator(animator: CYLTabBarItemAnimator)
    fun unregisterAnimatorWithIdentifier(identifier: String)
    /**
     * [EN] By priority, then registration order. [CN] 按优先级、再按注册顺序。
     */
    fun animators(): List<CYLTabBarItemAnimator>
    fun animatorWithIdentifier(identifier: String): CYLTabBarItemAnimator?
    /**
     * [EN] The animator bound to `url`, else the first that can play its file. [CN] 绑定到 `url` 的 animator，否则第一个能播放的。
     */
    fun animatorForURL(url: String?): CYLTabBarItemAnimator?
    /**
     * [EN] The first animator whose own keys have a value in `attributes`. [CN] 第一个在 `attributes` 中有值的自有 key 所属的 animator。
     */
    fun animatorForAttributes(attributes: Map<String, Any?>?): CYLTabBarItemAnimator?
    fun attributeKeyForGenericKey(genericKey: String, attributes: Map<String, Any?>?): String?
    /**
     * [EN] Binds `url` to `animator` (null removes the binding). [CN] 把 `url` 绑定到 `animator`（null 移除绑定）。
     */
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

    /**
     * [EN] The identifiers of the registered animators, in lookup order: the engines in this app.
     * [CN] 已注册 animator 的名称，按查找顺序：即 App 中的引擎。
     */
    fun registeredIdentifiers(): List<String> = animators().map { it.identifier }

    /**
     * [EN] Whether an animator with `identifier` (e.g. "Rive") is registered. [CN] 名称为 `identifier` 的 animator 是否已注册。
     */
    fun isAnimatorRegisteredWithIdentifier(identifier: String): Boolean = animatorWithIdentifier(identifier) != null

    /**
     * [EN] The known engines (`CYLAnimationEngines.knownTypes()`) that are not registered.
     * [CN] 已知（`CYLAnimationEngines.knownTypes()`）但未注册的引擎。
     */
    fun missingKnownIdentifiers(): List<String> = registeredIdentifiers().let { registered -> CYLAnimationEngines.knownTypes().filter { it !in registered } }

    /**
     * [EN] Two animators of the same priority that claim the same file extension, one sentence each (the one registered
     *      first plays those files). [CN] 相同优先级且声明了相同文件扩展名的两个 animator，每条一句（先注册的播放这些文件）。
     */
    fun conflictDescriptions(): List<String> {
        val list = animators()
        val conflicts = mutableListOf<String>()
        for (i in list.indices) for (j in i + 1 until list.size) {
            val first = list[i]
            val second = list[j]
            if (first.priority != second.priority) continue
            val shared = first.fileExtensions.map { it.lowercase() }.toSet() intersect second.fileExtensions.map { it.lowercase() }.toSet()
            if (shared.isEmpty()) continue
            conflicts += "${first.identifier} and ${second.identifier} both claim .${shared.sorted().joinToString(", .")} at priority ${first.priority}: " +
                "${first.identifier} plays these files (registered first). Give one of them another priority."
        }
        return conflicts
    }

    /**
     * [EN] A readable report: each registered engine, each known engine that is missing with its dependency, and the
     *      conflicts. iOS: `+[CYLTabBarItemAnimatorRegistry registrationReport]`.
     * [CN] 可读的报告：每个已注册引擎、每个缺少的已知引擎及其依赖，以及冲突。iOS：`+[CYLTabBarItemAnimatorRegistry registrationReport]`。
     */
    fun registrationReport(): String = buildList {
        val list = animators()
        add("[CYLAnimatedItem] Animation engines: ${list.size} registered, in lookup order.")
        list.forEach { animator ->
            val files = animator.fileExtensions.map { it.lowercase() }.distinct().sorted().joinToString(" ") { ".$it" }.ifEmpty { "(none)" }
            add("  ✅ ${animator.identifier}: ${animator.javaClass.simpleName}, priority ${animator.priority}, files $files")
        }
        missingKnownIdentifiers().forEach { add("  ➖ $it: not in this app. To add it: implementation(\"${CYLAnimationEngines.dependencyOf(it)}:<version>\").") }
        conflictDescriptions().forEach { add("  ⚠️ $it") }
    }.joinToString("\n")

    companion object {
        /**
         * [EN] The instance the animators register into. [CN] animator 注册到的共享实例。
         */
        @JvmStatic
        val sharedRegistry: CYLTabBarItemAnimatorRegistry by lazy {
            CYLTabBarItemAnimatorRegistry().apply {
                CYLLottieTabBarItemAnimator.takeIf { it.isAvailable }?.let { registerAnimator(it) }
                CYLPAGTabBarItemAnimator.takeIf { it.isAvailable }?.let { registerAnimator(it) }
                if (CYLRiveTabBarItemAnimator.isAvailable) registerAnimator(CYLRiveTabBarItemAnimator.animator)
                CYLSVGATabBarItemAnimator.takeIf { it.isAvailable }?.let { registerAnimator(it) }
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
        fun registeredIdentifiers() = sharedRegistry.registeredIdentifiers()
        fun isAnimatorRegisteredWithIdentifier(identifier: String) = sharedRegistry.isAnimatorRegisteredWithIdentifier(identifier)
        fun missingKnownIdentifiers() = sharedRegistry.missingKnownIdentifiers()
        fun conflictDescriptions() = sharedRegistry.conflictDescriptions()
        fun registrationReport() = sharedRegistry.registrationReport()

        /**
         * [EN] Logs `registrationReport()` (tag "CYLAnimatedItem"). [CN] 打印 `registrationReport()`（tag 为 "CYLAnimatedItem"）。
         */
        fun logRegistrationReport() {
            android.util.Log.i("CYLAnimatedItem", registrationReport())
        }
    }
}

// MARK: - Factory 工厂

/**
 * [EN] `CYLTabBarItemAnimationViewMaking`: makes animation views and finds their players. [CN] 创建动画视图并查找其播放器。
 */
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
        val options = CYLTabBarAnimationFileAndOptions(url).second
        view.cyl_setTag(OPTIONS_TAG, options)
        view.cyl_setTag(PLAYER_TAG, animator.playerForAnimationView(view)?.let { tinting(it, view, options) })
        return view
    }

    override fun playerForView(view: View?): CYLTabBarItemAnimationPlayer? {
        view ?: return null
        (view.cyl_getTag(PLAYER_TAG) as? CYLTabBarItemAnimationPlayer)?.let { return it }
        @Suppress("UNCHECKED_CAST")
        val options = view.cyl_getTag(OPTIONS_TAG) as? Map<String, String> ?: emptyMap()
        return registry.animators().firstNotNullOfOrNull { it.playerForAnimationView(view) }?.let { tinting(it, view, options) }?.also { view.cyl_setTag(PLAYER_TAG, it) }
    }

    /**
     * [EN] The `tint` / `darkTint` options for every engine (`CYLTabBarItemAnimationTint`): the player draws them, and a
     *      fixed tint is drawn at once. A view that draws its tint itself (Rive) keeps its own player.
     * [CN] 所有引擎的 `tint` / `darkTint` 选项（`CYLTabBarItemAnimationTint`）：由播放器绘制，固定着色立即绘制。自己绘制着色的视图（Rive）保留自己的播放器。
     */
    private fun tinting(player: CYLTabBarItemAnimationPlayer, view: View, options: Map<String, String>): CYLTabBarItemAnimationPlayer {
        if (!CYLTabBarItemAnimationTint.hasTint(options)) return player
        if ((view as? CYLTabBarItemAnimationPlayableView)?.cyl_drawsAnimationViewTint == true) return player
        CYLTabBarItemAnimationTint.fixedTintColor(options, view.resources.configuration)?.let { CYLTabBarItemAnimationTint.apply(view, it) }
        return CYLTabBarItemAnimationTintingPlayer(player, options)
    }

    override fun isAnimationView(view: View?): Boolean = playerForView(view) != null

    companion object {
        private const val PLAYER_TAG = "cyl_tab_bar_item_animation_player"
        private const val OPTIONS_TAG = "cyl_tab_bar_item_animation_options"
        @JvmStatic
        val sharedFactory: CYLTabBarItemAnimationFactory by lazy { CYLTabBarItemAnimationFactory() }
        fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType) = sharedFactory.animationViewWithURL(context, url, size, contentMode)
        fun playerForView(view: View?) = sharedFactory.playerForView(view)
        fun isAnimationView(view: View?) = sharedFactory.isAnimationView(view)
    }
}

// MARK: - The short path: views that play themselves 简便路径：自己播放的视图

/**
 * [EN] `CYLTabBarItemAnimationPlayableView`: a view that plays, stops and shows its last frame. [CN] 能播放、停止并显示最后一帧的视图。
 */
interface CYLTabBarItemAnimationPlayableView {
    fun cyl_playAnimationView()
    fun cyl_showAnimationViewLastFrame()
    fun cyl_stopAnimationView()
    /**
     * [EN] Pauses a playing animation where it is (`cyl.animation.didPause` follows from the item); optional, default: keeps playing.
     * [CN] 在当前位置暂停正在播放的动画（item 随后发出 `cyl.animation.didPause`）；可选，默认继续播放。
     */
    fun cyl_pauseAnimationView() { /* [EN] Optional. [CN] 可选。 */ }
    /** [EN] Continues what [cyl_pauseAnimationView] paused. [CN] 继续被 [cyl_pauseAnimationView] 暂停的动画。 */
    fun cyl_resumeAnimationView() { /* [EN] Optional. [CN] 可选。 */ }
    /**
     * [EN] Colors for Dark Mode, already resolved; null restores the light colors. [CN] 深色模式颜色（已解析）；null 恢复浅色。
     */
    fun cyl_applyAnimationViewColors(colors: Map<String, Int>?) { /* [EN] Optional. [CN] 可选。 */ }
    /**
     * [EN] The tab's tint (see `CYLTabBarItemAnimationPlayer.tintColor`). [CN] Tab 的着色（见 `CYLTabBarItemAnimationPlayer.tintColor`）。
     */
    fun cyl_applyAnimationViewTintColor(color: Int?) { /* [EN] Optional. [CN] 可选。 */ }
    /**
     * [EN] The tab's tint with its state (see `CYLTabBarItemAnimationPlayer.setTintColor`). [CN] 带状态的 Tab 着色（见 `CYLTabBarItemAnimationPlayer.setTintColor`）。
     */
    fun cyl_applyAnimationViewTintColor(color: Int?, selected: Boolean) = cyl_applyAnimationViewTintColor(color)
    /**
     * [EN] Whether the view draws the `tint` / `darkTint` options itself; false (the default): the factory draws them on
     *      the view's layer (`CYLTabBarItemAnimationTint`), as for every engine without a tint of its own.
     * [CN] 视图是否自己绘制 `tint` / `darkTint` 选项；false（默认）：由工厂在视图图层上绘制（`CYLTabBarItemAnimationTint`），与所有没有自身着色的引擎相同。
     */
    val cyl_drawsAnimationViewTint: Boolean get() = false
    /**
     * [EN] Whether the view plays again after each pass until this is turned off (the player's `loops`). For views with no
     *      progress to restart, such as Rive state machines (docs/Animated-Item.md, the Rive loop).
     * [CN] 视图是否在每次播放后再次播放，直到关闭（播放器的 `loops`）。用于没有进度可重新开始的视图，例如 Rive 状态机（docs/Animated-Item.md，Rive 循环）。
     */
    fun cyl_setAnimationViewLoops(loops: Boolean) { /* [EN] Optional. [CN] 可选。 */ }
    /**
     * [EN] Whether a pass is playing now (the player's `isPlaying`); null (the default) when the view cannot tell.
     * [CN] 当前是否正在播放（播放器的 `isPlaying`）；视图无法判断时为 null（默认）。
     */
    fun cyl_isAnimationViewPlaying(): Boolean? = null
    /**
     * [EN] The playback speed (the player's `animationSpeed`, 1 = the file's own), applied to a pass already playing.
     * [CN] 播放速度（播放器的 `animationSpeed`，1 = 文件自身速度），对正在播放的动画同样生效。
     */
    fun cyl_setAnimationViewSpeed(speed: Float) { /* [EN] Optional. [CN] 可选。 */ }
    /**
     * [EN] Shows the time at `progress` (0…1, the player's `progress`; 0 before `restartAnimation()` plays again).
     * [CN] 显示 `progress`（0…1，播放器的 `progress`；`restartAnimation()` 重新播放前为 0）处的时刻。
     */
    fun cyl_setAnimationViewProgress(progress: Float) { /* [EN] Optional. [CN] 可选。 */ }
}

/**
 * [EN] `CYLTabBarItemAnimationViewProviding`: makes playable views for `CYLTabBarItemViewAnimator`. [CN] 为 `CYLTabBarItemViewAnimator` 创建可播放视图。
 */
// [EN] kotlin:S6517: a plain interface on purpose; its implementations are named objects (`CYLGIFTabBarItemAnimationView.Provider`...) that are public API. [CN] kotlin:S6517：刻意使用普通接口；其实现是作为公开 API 的具名对象（`CYLGIFTabBarItemAnimationView.Provider` 等）。
@Suppress("kotlin:S6517")
interface CYLTabBarItemAnimationViewProviding {
    /**
     * [EN] A view for `fileURL` with the `options` of the tab's URL; null when it cannot be made. [CN] `fileURL` 的视图（带 Tab URL 中的选项）；无法创建时为 null。
     */
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
    /**
     * [EN] Where the views come from; null goes back to the provider given at initialization. [CN] 视图来源；设为 null 恢复初始化时的 provider。
     */
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
        val owner = view.cyl_getTag("cyl_tab_bar_item_view_animator") as? String
        if (owner != null && owner != identifier) return null
        view.cyl_setTag("cyl_tab_bar_item_view_animator", identifier)
        return object : CYLTabBarItemAnimationBasePlayer(view) {
            private var appliedColors: Map<String, Int>? = null
            override fun play() = playable.cyl_playAnimationView()
            override fun showLastFrame() = playable.cyl_showAnimationViewLastFrame()
            override fun stop() = playable.cyl_stopAnimationView()
            override fun pause() = playable.cyl_pauseAnimationView()
            override fun resume() = playable.cyl_resumeAnimationView()
            override val isPlaying: Boolean? get() = playable.cyl_isAnimationViewPlaying()
            override var loops: Boolean = false
                set(value) { field = value; playable.cyl_setAnimationViewLoops(value) }
            override var animationSpeed: Float = 1f
                set(value) { field = value; playable.cyl_setAnimationViewSpeed(value) }
            override var progress: Float = 0f
                set(value) { field = value; playable.cyl_setAnimationViewProgress(value) }
            override var tintColor: Int? = null
                set(value) { if (field != value) { field = value; playable.cyl_applyAnimationViewTintColor(value) } }
            private var tintSelected: Boolean? = null
            override fun setTintColor(color: Int?, selected: Boolean) {
                if (tintColor == color && tintSelected == selected) return
                tintColor = color
                tintSelected = selected
                playable.cyl_applyAnimationViewTintColor(color, selected)
            }
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
/**
 * [EN] The URL prefix of a file in the app's assets. [CN] App assets 中文件的 URL 前缀。
 */
private const val ANDROID_ASSET_PREFIX = "file:///android_asset/"

object CYLTabBarItemAnimationFiles {
    private val executor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    fun isRemote(url: String) = url.startsWith("http://") || url.startsWith("https://")

    /**
     * [EN] The asset name of `url`, or null when it is not an asset. [CN] `url` 对应的 asset 名称；不是 asset 时为 null。
     */
    fun assetName(url: String): String? = when {
        url.startsWith(ANDROID_ASSET_PREFIX) -> url.removePrefix(ANDROID_ASSET_PREFIX)
        url.startsWith("asset:///") -> url.removePrefix("asset:///")
        url.startsWith("asset:") -> url.removePrefix("asset:")
        url.contains(':') || url.startsWith("/") -> null
        else -> url
    }

    /**
     * [EN] A stream of a local `url`, or null. [CN] 本地 `url` 的流，或 null。
     */
    fun openLocal(context: Context, url: String): InputStream? = try {
        when {
            isRemote(url) -> null
            assetName(url) != null -> context.assets.open(assetName(url)!!)
            url.startsWith("file:") -> Uri.parse(url).path?.let { File(it).inputStream() }
            File(url).isAbsolute -> File(url).inputStream()
            else -> context.contentResolver.openInputStream(Uri.parse(url))
        }
    } catch (error: java.io.IOException) { null } catch (error: SecurityException) { null }

    /**
     * [EN] A local file of `url` (copied to the cache when it is an asset, a stream or remote), delivered on the main thread. [CN] `url` 的本地文件（asset、流或远程文件会复制到缓存），在主线程回调。
     */
    fun localFile(context: Context, url: String, completion: (File?) -> Unit) {
        // [EN] An absolute path ("/..." on Android; a drive path in JVM tests on Windows). [CN] 绝对路径（Android 上为 "/..."；Windows 上的 JVM 测试中为盘符路径）。
        if (File(url).isAbsolute && File(url).exists()) return completion(File(url))
        if (url.startsWith("file:") && !url.startsWith(ANDROID_ASSET_PREFIX)) return completion(Uri.parse(url).path?.let { File(it) }?.takeIf { it.exists() })
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

/**
 * [EN] Calls a method by name with arguments adapted to its parameters; null when it cannot. [CN] 按名称调用方法并适配参数；无法调用时返回 null。
 */
@RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
object CYLReflection {
    fun type(name: String): Class<*>? = try { Class.forName(name) } catch (error: ClassNotFoundException) { null } catch (error: LinkageError) { null }

    /**
     * [EN] Public methods by class, name and parameter count, looked up once (theme changes call setters often). [CN] 按类、名称与参数个数缓存的公开方法，只查找一次（主题变化会频繁调用 setter）。
     */
    private val methodCache = java.util.concurrent.ConcurrentHashMap<String, List<java.lang.reflect.Method>>()

    private fun methods(type: Class<*>, name: String, count: Int): List<java.lang.reflect.Method> =
        methodCache.getOrPut(type.name + "#" + name + "/" + count) { type.methods.filter { it.name == name && it.parameterTypes.size == count } }

    fun call(target: Any, name: String, vararg args: Any?): Any? {
        val methods = methods(target.javaClass, name, args.size)
        for (method in methods) {
            val adapted = adapt(method.parameterTypes, args) ?: continue
            return try { method.invoke(target, *adapted) ?: Unit } catch (error: ReflectiveOperationException) { null } catch (error: RuntimeException) { null }
        }
        return null
    }

    /**
     * [EN] Calls the overload of `name` with the fewest parameters, filling the missing ones with defaults. [CN] 调用参数最少的 `name` 重载，用默认值补齐缺少的参数。
     */
    fun callWithDefaults(target: Any, name: String, provided: Map<Class<*>, Any?> = emptyMap()): Any? {
        val method = target.javaClass.methods.filter { it.name == name }.minByOrNull { it.parameterTypes.size } ?: return null
        val args = method.parameterTypes.map { type -> provided.entries.firstOrNull { type.isAssignableFrom(it.key) }?.value ?: defaultValue(type) }
        return try { method.invoke(target, *args.toTypedArray()) ?: Unit } catch (error: ReflectiveOperationException) { null } catch (error: RuntimeException) { null }
    }

    /**
     * [EN] A placeholder for a parameter left to its Kotlin default (`callKotlin`). [CN] 使用 Kotlin 默认值的参数占位（`callKotlin`）。
     */
    val DEFAULT = Any()

    /**
     * [EN] Calls a Kotlin method with default parameters through its synthetic `name$default` method, so the parameters given
     *      as `DEFAULT` take the library's own defaults (e.g. rive-android's `Fit.CONTAIN`, `Loop.AUTO`), not a guess. The
     *      overload is the one whose parameter count is `args.size` and whose given arguments fit. Null when none fits.
     * [CN] 通过 Kotlin 生成的 `name$default` 方法调用带默认参数的方法，传入 `DEFAULT` 的参数使用库自己的默认值（如 rive-android 的
     *      `Fit.CONTAIN`、`Loop.AUTO`），而不是猜测的值。选择参数个数为 `args.size` 且给定参数类型匹配的重载。没有匹配时为 null。
     */
    fun callKotlin(target: Any, name: String, vararg args: Any?): Any? {
        val candidates = target.javaClass.methods.filter { method ->
            method.name == name + "\$default" && java.lang.reflect.Modifier.isStatic(method.modifiers) && method.parameterTypes.size == args.size + 3
        }
        for (method in candidates) {
            val values = kotlinDefaultArguments(method.parameterTypes, target, args) ?: continue
            return try { method.invoke(null, *values) ?: Unit } catch (error: ReflectiveOperationException) { null } catch (error: RuntimeException) { null }
        }
        return null
    }

    /**
     * [EN] The arguments of a `name$default` method: the target, the given arguments (adapted) or placeholders, the mask of
     *      the defaulted parameters, and the unused marker; null when a given argument does not fit.
     * [CN] `name$default` 方法的参数：目标、给定参数（已适配）或占位值、使用默认值的参数掩码，以及未使用的标记；给定参数类型不匹配时为 null。
     */
    private fun kotlinDefaultArguments(types: Array<Class<*>>, target: Any, args: Array<out Any?>): Array<Any?>? {
        if (!types[0].isInstance(target)) return null
        var mask = 0
        val values = arrayOfNulls<Any?>(types.size)
        values[0] = target
        for ((index, arg) in args.withIndex()) {
            val type = types[index + 1]
            if (arg === DEFAULT) {
                mask = mask or (1 shl index)
                values[index + 1] = defaultValue(type).takeIf { type.isPrimitive }
            } else {
                val adapted = adapt(arrayOf(type), arrayOf(arg)) ?: return null
                values[index + 1] = adapted[0]
            }
        }
        values[types.size - 2] = mask
        return values
    }

    /**
     * [EN] The constant `name` of the enum `className`, or null. [CN] 枚举 `className` 中名为 `name` 的常量，或 null。
     */
    fun enumConstant(className: String, name: String): Any? = type(className)?.enumConstants?.firstOrNull { (it as? Enum<*>)?.name == name }

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
/**
 * [EN] The images of a Lottie file (its "assets" with a "p" file name): lottie-android throws when it draws an image layer
 *      without an images folder or a delegate ("You must set an images folder"), while lottie-ios loads them by name. The
 *      delegate loads each image from the app's drawable of the same name (lower case, "-" as "_"), else from the app's
 *      assets next to the file ("<file's folder>/<u><p>", then "<u><p>"), else gives none. Embedded ("data:") images are
 *      decoded by lottie-android itself. An app that set its own delegate keeps it (set after the view is made, it
 *      replaces this one). By reflection: the component does not depend on lottie-android. Moved from
 *      CollectionViewClassifyMenu's `CYLTagLottieImages` (its tags' Lottie files with images).
 * [CN] Lottie 文件的图片（"assets" 中带 "p" 文件名的条目）：没有图片目录或代理时，lottie-android 绘制图片图层会抛出异常，而 lottie-ios 按名称
 *      加载。该代理先从 App 同名 drawable（小写，"-" 换成 "_"）加载，再从 App assets 中文件旁（"<文件目录>/<u><p>"，然后 "<u><p>"）加载，否则不提供。
 *      内嵌（"data:"）图片由 lottie-android 自己解码。App 之后设置的代理会替换本代理。通过反射实现：组件不依赖 lottie-android。从
 *      CollectionViewClassifyMenu 的 `CYLTagLottieImages` 迁移而来。
 */
internal object CYLLottieImageAssets {
    fun prepare(context: Context, view: View, file: String) {
        val delegateType = CYLReflection.type("com.airbnb.lottie.ImageAssetDelegate") ?: return
        val folder = if (file.contains('/')) file.substringBeforeLast('/') + "/" else ""
        val appContext = context.applicationContext ?: context
        try {
            val delegate = java.lang.reflect.Proxy.newProxyInstance(delegateType.classLoader, arrayOf(delegateType)) { proxy, method, args ->
                when (method.name) {
                    "fetchBitmap" -> args?.firstOrNull()?.let { bitmap(appContext, it, folder) }
                    "hashCode" -> System.identityHashCode(proxy)
                    "equals" -> proxy === args?.firstOrNull()
                    "toString" -> "CYLLottieImageAssets"
                    else -> null
                }
            }
            view.javaClass.getMethod("setImageAssetDelegate", delegateType).invoke(view, delegate)
        } catch (error: Throwable) {
            // [EN] An older lottie-android without the delegate: the failure listener shows the static image.
            // [CN] 没有该代理的旧版 lottie-android：失败监听显示静态图片。
        }
    }

    private fun bitmap(context: Context, asset: Any, folder: String): android.graphics.Bitmap? {
        val fileName = asset.javaClass.getMethod("getFileName").invoke(asset) as? String ?: return null
        val dirName = (try { asset.javaClass.getMethod("getDirName").invoke(asset) as? String } catch (e: Throwable) { null }) ?: ""
        val name = fileName.substringAfterLast('/').substringBeforeLast('.').replace('-', '_').lowercase()
        val id = context.resources.getIdentifier(name, "drawable", context.packageName)
        if (id != 0) {
            return android.graphics.BitmapFactory.decodeResource(context.resources, id)
        }
        for (path in listOf(folder + dirName + fileName, dirName + fileName, fileName)) {
            try {
                context.assets.open(path).use { return android.graphics.BitmapFactory.decodeStream(it) }
            } catch (error: Throwable) {
                // [EN] Try the next location. [CN] 尝试下一个位置。
            }
        }
        return null
    }
}

object CYLLottieTabBarItemAnimator : CYLTabBarItemAnimator {
    private const val VIEW_CLASS = "com.airbnb.lottie.LottieAnimationView"
    val isAvailable: Boolean get() = CYLReflection.type(VIEW_CLASS) != null
    override val identifier: String = "Lottie"
    override val priority: CYLTabBarItemAnimatorPriority = CYLTabBarItemAnimatorPriorityFallback
    override val fileExtensions: List<String> = listOf("json", "lottie", "zip")
    override val attributeKeys: Map<String, String> = mapOf(
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationURL to CYLTabBarItemAnimationKeys.CYLTabBarLottieURL,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationFilePath to CYLTabBarItemAnimationKeys.CYLTabBarLottieFilePath,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationSize to CYLTabBarItemAnimationKeys.CYLTabBarLottieSize,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkURL to CYLTabBarItemAnimationKeys.CYLTabBarLottieDarkURL,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkFilePath to CYLTabBarItemAnimationKeys.CYLTabBarLottieDarkFilePath,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkColors to CYLTabBarItemAnimationKeys.CYLTabBarLottieDarkColors,
    )

    override fun canAnimateFileAtURL(url: String): Boolean = url.isNotEmpty()

    override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View? {
        val view = CYLReflection.newInstance(VIEW_CLASS, context) as? View ?: return null
        // [EN] Merge paths (common in After Effects exports): lottie-android leaves them off and then draws such a file
        //      wrongly or not at all, while lottie-ios draws them. On, as on iOS.
        // [CN] 合并路径（After Effects 导出的文件中很常见）：lottie-android 默认关闭，此时这类文件会画错或完全不画，
        //      而 lottie-ios 会绘制它们。与 iOS 一致，打开。
        CYLReflection.call(view, "enableMergePathsForKitKatAndAbove", true)
        // [EN] Image layers at the size the file declares for each image (its "w" / "h"), as lottie-ios draws them.
        //      lottie-android otherwise sizes an image by its bitmap's pixels times the screen density, so a bitmap a
        //      delegate decodes from a drawable folder (scaled to the screen) or a @2x / @3x file draws 2-3 times too
        //      large and spills out of the icon.
        // [CN] 图片图层使用文件为每张图片声明的尺寸（"w" / "h"），与 lottie-ios 一致。否则 lottie-android 按位图像素乘以屏幕密度确定图片尺寸，
        //      代理从 drawable 目录解码（已按屏幕缩放）的位图或 @2x / @3x 文件会大 2-3 倍并溢出图标。
        CYLReflection.call(view, "setMaintainOriginalImageBounds", true)
        val file = url.substringBefore('#')
        CYLLottieImageAssets.prepare(context, view, file)
        setFailureListener(view, file)
        if (CYLTabBarItemAnimationFiles.isRemote(file)) {
            // [EN] A download: the host shows its static image or placeholder until the composition is loaded.
            // [CN] 下载中：在动画加载完成之前，宿主显示其静态图片或占位图。
            CYLTabBarItemAnimationFailure.markLoading(view)
            setLoadedListener(view)
        }
        val loaded = when {
            CYLTabBarItemAnimationFiles.isRemote(file) -> CYLReflection.call(view, "setAnimationFromUrl", file)
            CYLTabBarItemAnimationFiles.assetName(file) != null -> CYLReflection.call(view, "setAnimation", CYLTabBarItemAnimationFiles.assetName(file))
            else -> CYLTabBarItemAnimationFiles.openLocal(context, file)?.let { CYLReflection.call(view, "setAnimation", it, file) }
        }
        loaded ?: return null
        (view as? ImageView)?.scaleType = contentMode
        return view
    }

    /**
     * [EN] Lottie throws on the main thread when a file cannot be loaded or parsed, unless a failure listener is set: the
     *      listener drops the animation view, so the tab shows its image, as on iOS.
     * [CN] 文件无法加载或解析时，Lottie 会在主线程抛出异常，除非设置了失败监听：监听移除动画视图，Tab 显示其图片，与 iOS 一致。
     */
    /**
     * [EN] Tells the host when Lottie has the composition of a remote file. [CN] Lottie 拿到远程文件的动画数据时通知宿主。
     */
    private fun setLoadedListener(view: View) {
        val listenerType = CYLReflection.type("com.airbnb.lottie.LottieOnCompositionLoadedListener") ?: return
        val listener = java.lang.reflect.Proxy.newProxyInstance(listenerType.classLoader, arrayOf(listenerType)) { proxy, method, args ->
            when (method.name) {
                "onCompositionLoaded" -> { CYLTabBarItemAnimationFailure.reportLoaded(view); null }
                "hashCode" -> System.identityHashCode(proxy)
                "equals" -> proxy === args?.firstOrNull()
                "toString" -> "CYLLottieLoadedListener"
                else -> null
            }
        }
        CYLReflection.call(view, "addLottieOnCompositionLoadedListener", listener)
    }

    private fun setFailureListener(view: View, file: String) {
        val listenerType = CYLReflection.type("com.airbnb.lottie.LottieListener") ?: return
        val listener = java.lang.reflect.Proxy.newProxyInstance(listenerType.classLoader, arrayOf(listenerType)) { proxy, method, args ->
            when (method.name) {
                "onResult" -> {
                    Log.w("CYLTabBarController", "Lottie could not load $file: ${(args?.firstOrNull() as? Throwable)?.message}")
                    view.post { CYLTabBarItemAnimationFailure.report(view) }
                    null
                }
                "hashCode" -> System.identityHashCode(proxy)
                "equals" -> proxy === args?.firstOrNull()
                "toString" -> "CYLLottieFailureListener"
                else -> null
            }
        }
        CYLReflection.call(view, "setFailureListener", listener)
    }

    override fun playerForAnimationView(view: View): CYLTabBarItemAnimationPlayer? =
        if (view.javaClass.name == VIEW_CLASS || CYLReflection.type(VIEW_CLASS)?.isInstance(view) == true) LottiePlayer(view) else null

    private class LottiePlayer(view: View) : CYLTabBarItemAnimationBasePlayer(view) {
        private val appliedKeyPaths = HashSet<String>()

        override fun play() { animationView?.let { CYLReflection.call(it, "setProgress", 0f); CYLReflection.call(it, "playAnimation") } }
        override fun showLastFrame() { animationView?.let { CYLReflection.call(it, "cancelAnimation"); CYLReflection.call(it, "setProgress", 1f) } }
        override fun stop() { animationView?.let { CYLReflection.call(it, "cancelAnimation"); CYLReflection.call(it, "setProgress", 0f) } }
        override fun pause() { animationView?.let { CYLReflection.call(it, "pauseAnimation") } }
        override fun resume() { animationView?.let { CYLReflection.call(it, "resumeAnimation") } }
        override val isPlaying: Boolean? get() = animationView?.let { CYLReflection.call(it, "isAnimating") as? Boolean }
        override var progress: Float
            get() = animationView?.let { CYLReflection.call(it, "getProgress") as? Float } ?: 0f
            set(value) { animationView?.let { CYLReflection.call(it, "setProgress", value) } }
        override var animationSpeed: Float
            get() = animationView?.let { CYLReflection.call(it, "getSpeed") as? Float } ?: 1f
            set(value) { animationView?.let { CYLReflection.call(it, "setSpeed", value) } }
        // [EN] LottieDrawable.INFINITE is -1; 0 plays once. [CN] LottieDrawable.INFINITE 为 -1；0 表示播放一次。
        override var loops: Boolean
            get() = animationView?.let { CYLReflection.call(it, "getRepeatCount") as? Int } == -1
            set(value) { animationView?.let { CYLReflection.call(it, "setRepeatCount", if (value) -1 else 0) } }

        /**
         * [EN] Colors by keypath ("Layer.Group.Fill 1.Color" or with "**"), through `addValueCallback(KeyPath, LottieProperty.COLOR, …)`. [CN] 按 keypath 设置颜色，通过 `addValueCallback`。
         */
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
 * [EN] `CYLPAGTabBarItemAnimator`: PAG tab icons with libpag, registered when libpag is in the app. ".pag" files; PAG
 *      has no playback speed. The view is `org.libpag.PAGImageView` (libpag 4.0+), else `org.libpag.PAGView`.
 *      `PAGImageView` is a plain View that draws each frame as a bitmap, the view libpag recommends for many small
 *      icons. `PAGView` is a TextureView with its own GL surface per icon. In a list of icons, on an emulator's
 *      translated GL (libEGL "called unimplemented OpenGL ES API"), it drew the first frame and then stopped updating,
 *      so the icons never played.
 * [CN] 使用 libpag 的 PAG Tab 图标，App 中有 libpag 时注册。".pag" 文件；PAG 没有播放速度。视图为 `org.libpag.PAGImageView`
 *      （libpag 4.0+），没有时为 `org.libpag.PAGView`。`PAGImageView` 是普通 View，将每帧绘制为位图，是 libpag 为大量小图标推荐的视图；
 *      `PAGView` 是 TextureView，每个图标一个 GL 表面：在图标列表中、模拟器转译的 GL 上（libEGL "called unimplemented OpenGL ES API"）
 *      它只画出第一帧便不再更新，图标从不播放。
 */
object CYLPAGTabBarItemAnimator : CYLTabBarItemAnimator {
    private const val IMAGE_VIEW_CLASS = "org.libpag.PAGImageView"
    private const val VIEW_CLASS = "org.libpag.PAGView"
    val isAvailable: Boolean get() = CYLReflection.type(IMAGE_VIEW_CLASS) != null || CYLReflection.type(VIEW_CLASS) != null
    override val identifier: String = "PAG"
    override val fileExtensions: List<String> = listOf("pag")
    override val attributeKeys: Map<String, String> = mapOf(
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationURL to CYLTabBarItemAnimationKeys.CYLTabBarPAGURL,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationFilePath to CYLTabBarItemAnimationKeys.CYLTabBarPAGFilePath,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationSize to CYLTabBarItemAnimationKeys.CYLTabBarPAGSize,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkURL to CYLTabBarItemAnimationKeys.CYLTabBarPAGDarkURL,
        CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkFilePath to CYLTabBarItemAnimationKeys.CYLTabBarPAGDarkFilePath,
    )

    override fun canAnimateFileAtURL(url: String): Boolean = CYLTabBarAnimationFileExtension(url) == "pag"

    override fun animationViewWithURL(context: Context, url: String, size: CYLSize, contentMode: ImageView.ScaleType): View? {
        val view = (CYLReflection.newInstance(IMAGE_VIEW_CLASS, context) ?: CYLReflection.newInstance(VIEW_CLASS, context)) as? View ?: return null
        // [EN] PAGScaleMode: 1 stretch, 2 letterbox (fit), 3 zoom (fill). [CN] PAGScaleMode：1 拉伸，2 适应，3 填充。
        CYLReflection.call(view, "setScaleMode", when (contentMode) { ImageView.ScaleType.FIT_XY -> 1; ImageView.ScaleType.CENTER_CROP -> 3; else -> 2 })
        CYLTabBarItemAnimationFailure.markLoading(view)
        CYLTabBarItemAnimationFiles.localFile(context, url.substringBefore('#')) { file ->
            // [EN] PAGImageView.setPath returns false for a file it cannot read. [CN] PAGImageView.setPath 无法读取文件时返回 false。
            if (file != null && CYLReflection.call(view, "setPath", file.absolutePath) != false) {
                CYLReflection.call(view, "flush")
                CYLTabBarItemAnimationFailure.reportLoaded(view)
            } else {
                CYLTabBarItemAnimationFailure.reportLater(view)
            }
        }
        return view
    }

    override fun playerForAnimationView(view: View): CYLTabBarItemAnimationPlayer? = when {
        CYLReflection.type(IMAGE_VIEW_CLASS)?.isInstance(view) == true -> PAGImagePlayer(view)
        CYLReflection.type(VIEW_CLASS)?.isInstance(view) == true -> PAGPlayer(view)
        else -> null
    }

    /**
     * [EN] `PAGImageView`: progress is a frame (`setCurrentFrame` / `currentFrame` of `numFrames`).
     * [CN] `PAGImageView`：进度为帧（`numFrames` 中的 `setCurrentFrame` / `currentFrame`）。
     */
    private class PAGImagePlayer(view: View) : CYLTabBarItemAnimationBasePlayer(view) {
        // [EN] setRepeatCount: 0 repeats without end, 1 plays once. [CN] setRepeatCount：0 为无限重复，1 为播放一次。
        override var loops: Boolean = false
            set(value) { field = value; animationView?.let { CYLReflection.call(it, "setRepeatCount", if (value) 0 else 1) } }

        private fun frames(view: View) = (CYLReflection.call(view, "numFrames") as? Int)?.takeIf { it > 0 } ?: 1

        private fun show(view: View, frame: Int) {
            CYLReflection.call(view, "setCurrentFrame", frame)
            CYLReflection.call(view, "flush")
        }

        override fun play() {
            animationView?.let {
                CYLReflection.call(it, "pause")
                CYLReflection.call(it, "setRepeatCount", if (loops) 0 else 1)
                show(it, 0)
                CYLReflection.call(it, "play")
            }
        }

        override fun showLastFrame() { animationView?.let { CYLReflection.call(it, "pause"); show(it, frames(it) - 1) } }
        override fun stop() { animationView?.let { CYLReflection.call(it, "pause"); show(it, 0) } }
        override val isPlaying: Boolean? get() = animationView?.let { CYLReflection.call(it, "isPlaying") as? Boolean }
        override var progress: Float
            get() = animationView?.let { view -> ((CYLReflection.call(view, "currentFrame") as? Int) ?: 0).toFloat() / maxOf(1, frames(view) - 1) } ?: 0f
            set(value) { animationView?.let { show(it, Math.round(value.coerceIn(0f, 1f) * (frames(it) - 1))) } }
    }

    private class PAGPlayer(view: View) : CYLTabBarItemAnimationBasePlayer(view) {
        // [EN] PAGView.setRepeatCount: 0 repeats without end, 1 plays once. [CN] PAGView.setRepeatCount：0 为无限重复，1 为播放一次。
        override var loops: Boolean = false
            set(value) { field = value; animationView?.let { CYLReflection.call(it, "setRepeatCount", if (value) 0 else 1) } }
        override fun play() { animationView?.let { CYLReflection.call(it, "setRepeatCount", if (loops) 0 else 1); CYLReflection.call(it, "setProgress", 0.0); CYLReflection.call(it, "play") } }
        override fun showLastFrame() { animationView?.let { CYLReflection.call(it, "stop"); CYLReflection.call(it, "setProgress", 1.0); CYLReflection.call(it, "flush") } }
        override fun stop() { animationView?.let { CYLReflection.call(it, "stop"); CYLReflection.call(it, "setProgress", 0.0); CYLReflection.call(it, "flush") } }
        override fun pause() { animationView?.let { CYLReflection.call(it, "pause") } }
        override fun resume() { animationView?.let { CYLReflection.call(it, "play") } }
        override val isPlaying: Boolean? get() = animationView?.let { CYLReflection.call(it, "isPlaying") as? Boolean }
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

    /**
     * [EN] The registered animator, e.g. to inject another view provider. [CN] 已注册的 animator，例如用于注入其他视图 provider。
     */
    @JvmStatic
    val animator: CYLTabBarItemViewAnimator by lazy {
        CYLTabBarItemViewAnimator("Rive", listOf("riv"), mapOf(
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationURL to CYLTabBarItemAnimationKeys.CYLTabBarRiveURL,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationFilePath to CYLTabBarItemAnimationKeys.CYLTabBarRiveFilePath,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationSize to CYLTabBarItemAnimationKeys.CYLTabBarRiveSize,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkURL to CYLTabBarItemAnimationKeys.CYLTabBarRiveDarkURL,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkFilePath to CYLTabBarItemAnimationKeys.CYLTabBarRiveDarkFilePath,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkColors to CYLTabBarItemAnimationKeys.CYLTabBarRiveDarkColors,
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
class CYLRiveTabBarItemAnimationView internal constructor(context: Context, private val rive: View, private val options: Map<String, String>) :
    android.widget.FrameLayout(context), CYLTabBarItemAnimationPlayableView {

    private val handler = Handler(Looper.getMainLooper())
    private val stateMachine get() = options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveStateMachine]
    private val booleanInput get() = options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveInput] ?: options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveActiveProperty] ?: "active"
    private val activeDuration get() = options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveActiveDuration]?.toDoubleOrNull() ?: 1.0
    /**
     * [EN] Plays again after each pass (`cyl_setAnimationViewLoops`). [CN] 每次播放后再次播放（`cyl_setAnimationViewLoops`）。
     */
    private var loops = false
    private val numberInput get() = options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveNumberInput]
    private val numberValues get() = CYLRiveInputs.numberValues(options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveNumberValues])
    private var lastNumber: Float? = null
    /**
     * [EN] Paused on its first frame after load, not played yet (docs/Animated-Item.md): the next play resumes it first.
     * [CN] 加载后暂停在第一帧、尚未播放：下一次播放先恢复它。
     */
    private var restingAfterLoad = false
    private var hasPlayed = false

    /**
     * [EN] Rests on the first frame until the first play: a file whose state machine moves by itself (shapes.riv, truck.riv)
     *      no longer runs from load. The machine is created (autoplay) so its inputs can be read. Called right after the load
     *      (rive-android builds the scene synchronously in `setRiveFile`), it advances the machine in fixed steps of
     *      `SETTLE_STEP_SECONDS` until it settles (rive-android then pauses it by itself), at most `SETTLE_STEPS` steps; a
     *      machine still moving after that (shapes.riv, truck.riv) is paused. The steps do not depend on the device's speed,
     *      so every launch rests on the same frame, as on iOS. A machine paused before it settled answered its inputs the
     *      wrong way round (menu_button.riv went back to the hamburger when opened and showed its X when closed, 319ba8a4);
     *      a pause 100 ms after load, at 396d3fca, rested on a frame that depended on the device (menu_button.riv on its X).
     * [CN] 在第一次播放之前停在第一帧：状态机会自行运动的文件（shapes.riv、truck.riv）不再从加载起就运动。状态机先创建（autoplay）以便读取其输入。
     *      在加载之后调用（rive-android 在 `setRiveFile` 中同步构建场景），以固定步长 `SETTLE_STEP_SECONDS` 推进状态机直到稳定（rive-android
     *      随即自行暂停它），最多 `SETTLE_STEPS` 步；之后仍在运动的状态机（shapes.riv、truck.riv）被暂停。步数与设备速度无关，因此每次启动都停在
     *      同一帧，与 iOS 一致。稳定之前就被暂停的状态机会反向响应输入（319ba8a4 时 menu_button.riv 打开时回到汉堡图标、关闭时显示 X）；
     *      396d3fca 时加载 100 ms 后暂停，停在哪一帧取决于设备（menu_button.riv 停在 X 上）。
     */
    internal fun cyl_restUntilPlayed() {
        if (hasPlayed) return
        val controller = CYLReflection.call(rive, "getController")
        if (controller == null) {
            // [EN] The fake view of the tests has no controller. [CN] 测试中的伪造视图没有控制器。
            CYLReflection.call(rive, "pause")
            restingAfterLoad = true
            return
        }
        val isMoving = { (CYLReflection.call(controller, "getPlayingStateMachines") as? Collection<*>)?.isNotEmpty() == true }
        var steps = 0
        while (isMoving() && steps < SETTLE_STEPS) {
            CYLReflection.call(controller, "advance", SETTLE_STEP_SECONDS)
            steps++
        }
        // [EN] The file controller only: `RiveAnimationView.pause()` also stops the view's renderer, after which the state
        //      machine no longer runs continuously (menu_button.riv crept one frame per input and never reached its X on
        //      Android, dcbfdec6 and ad3dca0e).
        // [CN] 只暂停文件控制器：`RiveAnimationView.pause()` 还会停止视图的渲染器，之后状态机不再连续运行（Android 上
        //      menu_button.riv 每次输入只前进一帧，始终到不了 X）。
        if (isMoving()) CYLReflection.call(controller, "pause")
        restingAfterLoad = true
    }
    /**
     * [EN] A resting icon shows the values of a newly bound theme instance (night mode switch), as on iOS (isPaused = false): its
     *      controller is paused, so it drew the old frame until the next play (data_bind_test_impl.riv, 2026-11-19). The file
     *      resumes as a first play resumes it, draws for two frames, and its controller is paused again; it keeps resting.
     * [CN] 静止的图标显示新绑定主题实例的值（深色模式切换），与 iOS 一致（isPaused = false）：其控制器已暂停，所以在下次播放之前一直绘制旧帧。
     *      文件按第一次播放的方式恢复，绘制两帧后控制器再次暂停；图标仍保持静止。
     */
    private fun redrawRestingFrame() {
        if (!restingAfterLoad || hasPlayed) return
        val controller = CYLReflection.call(rive, "getController") ?: return
        val machine = stateMachine
        if (machine != null) {
            CYLReflection.callKotlin(rive, "play", machine, CYLReflection.DEFAULT, CYLReflection.DEFAULT, true, false)
        } else if (options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveAnimation] == null) {
            CYLReflection.callKotlin(rive, "play", CYLReflection.DEFAULT, CYLReflection.DEFAULT, false)
        }
        handler.postDelayed({ if (restingAfterLoad && !hasPlayed) CYLReflection.call(controller, "pause") }, NEXT_FRAME_MS * 2)
    }

    // [EN] A loop pass leaves a file that is still moving on its own alone (shapes.riv, truck.riv); only a play restarts it.
    // [CN] 一次循环不打断仍在自行运动的文件（shapes.riv、truck.riv）；只有播放才会重新开始它。
    private val loopRunnable: Runnable = Runnable {
        if (!loops) return@Runnable
        if (restartsOnPlay() && CYLReflection.call(rive, "isPlaying") == true) {
            handler.postDelayed(loopRunnable, (LOOP_SECONDS * 1000).toLong())
        } else {
            cyl_playAnimationView()
        }
    }

    init {
        addView(rive, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
        // [EN] A tab icon is not a control: TalkBack reads the tab button. [CN] Tab 图标不是控件：TalkBack 读取 Tab 按钮。
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS
        // [EN] A fixed tint ("#RRGGBB" / "#AARRGGBB"), with its night-mode color (`darkTint`). [CN] 固定着色，及其夜间模式颜色（`darkTint`）。
        fixedTintColor(resources.configuration)?.let { applyTint(it) }
    }

    private val tintOption get() = CYLTabBarItemAnimationTint.tintOption(options)

    /**
     * [EN] The fixed tint for `configuration`: `darkTint` in night mode when it is set, else `tint`; null for "title" or none.
     * [CN] `configuration` 下的固定着色：夜间模式且设置了 `darkTint` 时使用它，否则使用 `tint`；"title" 或未设置时为 null。
     */
    internal fun fixedTintColor(configuration: Configuration): Int? = CYLTabBarItemAnimationTint.fixedTintColor(options, configuration)

    private fun isNight(configuration: Configuration) =
        (configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    /**
     * [EN] Night mode changed: the fixed tint takes its color for the new mode, and the theme instance is bound again.
     * [CN] 夜间模式变化：固定着色使用新模式的颜色，并重新绑定主题实例。
     */
    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        if (fixedTintColor(newConfig) != null) applyTint(CYLTabBarItemAnimationTint.resolvedTintColor(options, tintTitleColor, newConfig, tintSelected))
        cyl_bindThemeInstance(newConfig)
    }

    private val lightInstanceName get() = options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveViewModelInstance]?.takeIf { it.isNotEmpty() }
    private val darkInstanceName get() = options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveDarkViewModelInstance]?.takeIf { it.isNotEmpty() }
    private var lightInstance: Any? = null
    private var darkInstance: Any? = null
    /**
     * [EN] The instance bound last, by `cyl_bindThemeInstance`. [CN] `cyl_bindThemeInstance` 最近绑定的实例。
     */
    internal var boundThemeInstance: Any? = null
        private set
    /**
     * [EN] The selected state, carried over to the other instance. [CN] 选中状态，切换实例时带过去。
     */
    private var isActive = false

    /**
     * [EN] Rive's theme pattern (the iOS options of the same name): binds the named instance of the artboard's default view
     *      model for `configuration`'s mode (`viewModelInstance` by day, `darkViewModelInstance` at night) to every state
     *      machine, keeping the selected state. rive-android by reflection: `getController().getFile()`,
     *      `defaultViewModelForArtboard(getActiveArtboard())`, `createInstanceFromName`, `StateMachineInstance.setViewModelInstance`.
     *      Called after the file loads and when night mode changes; nothing without the options.
     * [CN] Rive 的主题方式（与 iOS 同名的选项）：按 `configuration` 的模式（日间为 `viewModelInstance`，夜间为 `darkViewModelInstance`）把画板默认
     *      view model 的具名实例绑定到每个状态机，并保持选中状态。通过反射使用 rive-android：`getController().getFile()`、
     *      `defaultViewModelForArtboard(getActiveArtboard())`、`createInstanceFromName`、`StateMachineInstance.setViewModelInstance`。
     *      文件加载后及夜间模式变化时调用；没有这些选项时不做任何事。
     */
    internal fun cyl_bindThemeInstance(configuration: Configuration = resources.configuration) {
        val darkName = darkInstanceName ?: return
        val controller = CYLReflection.call(rive, "getController") ?: return
        val file = CYLReflection.call(controller, "getFile") ?: return
        val artboard = CYLReflection.call(controller, "getActiveArtboard") ?: return
        val viewModel = CYLReflection.call(file, "defaultViewModelForArtboard", artboard) ?: return
        if (lightInstance == null) {
            lightInstance = lightInstanceName?.let { CYLReflection.call(viewModel, "createInstanceFromName", it) }
                ?: CYLReflection.call(viewModel, "createDefaultInstance")
        }
        if (darkInstance == null) {
            darkInstance = CYLReflection.call(viewModel, "createInstanceFromName", darkName)
            if (darkInstance == null) Log.w(TAG, "The Rive file has no view model instance named $darkName")
        }
        val instance = (if (isNight(configuration)) darkInstance else lightInstance) ?: return
        if (instance === boundThemeInstance) return
        // [EN] The selected state goes with the theme. [CN] 选中状态随主题一起切换。
        CYLReflection.call(instance, "getBooleanProperty", booleanInput)?.let { CYLReflection.call(it, "setValue", isActive) }
        val machines = CYLReflection.call(controller, "getStateMachines") as? List<*>
        machines?.filterNotNull()?.forEach { CYLReflection.call(it, "setViewModelInstance", instance) }
        if (machines.isNullOrEmpty()) CYLReflection.call(artboard, "setViewModelInstance", instance)
        boundThemeInstance = instance
        redrawRestingFrame()
    }

    /**
     * [EN] The tint currently drawn, or null. [CN] 当前绘制的着色，没有时为 null。
     */
    var appliedTintColor: Int? = null
        private set

    /**
     * [EN] Bug B12: icons.riv draws light strokes that vanish on a light tab bar, and a Rive file has no tint of its own.
     *      A one-color icon is tinted like a template image: its layer is drawn through a SRC_IN color filter (a
     *      TextureView, as rive-android's view, takes it as its layer paint). null removes it.
     * [CN] 问题 B12：icons.riv 绘制浅色描边，在浅色 TabBar 上几乎不可见，而 Rive 文件本身没有着色。单色图标像模板图片一样着色：通过 SRC_IN
     *      颜色滤镜绘制其图层（rive-android 的视图是 TextureView，作为其 layer paint）。null 移除着色。
     */
    private fun applyTint(color: Int?) {
        appliedTintColor = color
        val paint = color?.let { android.graphics.Paint().apply { colorFilter = android.graphics.PorterDuffColorFilter(it, android.graphics.PorterDuff.Mode.SRC_IN) } }
        if (rive is android.view.TextureView) {
            rive.setLayerPaint(paint)
        } else {
            rive.setLayerType(if (paint != null) View.LAYER_TYPE_HARDWARE else View.LAYER_TYPE_NONE, paint)
        }
    }

    /**
     * [EN] The tab's title color, drawn when the `tint` option is "title". [CN] Tab 的标题颜色，`tint` 选项为 "title" 时绘制。
     */
    override fun cyl_applyAnimationViewTintColor(color: Int?) {
        if (tintOption == TINT_TITLE) applyTint(color)
    }

    /**
     * [EN] The title color and state given last, for a night-mode change. [CN] 最近给出的标题颜色与状态，供夜间模式变化使用。
     */
    private var tintTitleColor: Int? = null
    private var tintSelected: Boolean? = null

    /**
     * [EN] A fixed tint only on the unselected tab; the selected tab takes the title color (iOS 9a64feea).
     * [CN] 固定着色只用于未选中的 Tab；选中的 Tab 使用标题颜色（iOS 9a64feea）。
     */
    override fun cyl_applyAnimationViewTintColor(color: Int?, selected: Boolean) {
        tintTitleColor = color
        tintSelected = selected
        if (tintOption != null) applyTint(CYLTabBarItemAnimationTint.resolvedTintColor(options, color, resources.configuration, selected))
    }

    /**
     * [EN] The Rive view draws its tint on rive-android's view, not on this container. [CN] Rive 视图在 rive-android 的视图上绘制着色，而不是在本容器上。
     */
    override val cyl_drawsAnimationViewTint: Boolean get() = true

    /**
     * [EN] Leaves every touch to the tab button: rive-android's `RiveAnimationView` consumes touches for its state
     *      machines' pointer events, so a tap on a Rive icon never selected its tab (the tab bar of Example-Rive on
     *      Android ignored taps on the icons). iOS tab icons do not take touches either.
     * [CN] 把所有触摸交给 Tab 按钮：rive-android 的 `RiveAnimationView` 为状态机的指针事件消费触摸，导致点按 Rive 图标不会选中 Tab
     *      （Android 上 Example-Rive 的 TabBar 点按图标无反应）。iOS 的 Tab 图标同样不接收触摸。
     */
    override fun dispatchTouchEvent(event: android.view.MotionEvent?): Boolean = false

    private fun setActive(active: Boolean) {
        isActive = active
        val machine = stateMachine ?: return
        if (!hasInput(machine, booleanInput)) return
        cyl_resumeStateMachineIfSettled(machine)
        CYLReflection.call(rive, "setBooleanState", machine, booleanInput, active)
    }

    /**
     * [EN] Plays the state machine again when the controller has none playing, before an input is set. A machine that settled
     *      (after `cyl_restUntilPlayed`, or after any transition) is paused by rive-android; a new input is meant to restart
     *      it, but on a slow x86_64 emulator (API 37) it did not: menu_button.riv stayed on its close icon while "isOpen"
     *      flipped on every loop pass (3bd20b3c, logged by the CollectionViewClassifyMenu session). The fake view of the tests
     *      has no controller.
     * [CN] 设置输入之前，如果控制器中没有正在播放的状态机，则重新播放该状态机。已稳定的状态机（`cyl_restUntilPlayed` 之后，或任意一次切换之后）会被
     *      rive-android 暂停；新的输入本应让它重新运行，但在较慢的 x86_64 模拟器（API 37）上没有：每次循环 "isOpen" 都在切换，menu_button.riv
     *      却一直停在关闭图标上（3bd20b3c，CollectionViewClassifyMenu 会话记录）。测试中的伪造视图没有控制器。
     */
    private fun cyl_resumeStateMachineIfSettled(machine: String) {
        val controller = CYLReflection.call(rive, "getController") ?: return
        val playing = CYLReflection.call(controller, "getPlayingStateMachines") as? Collection<*> ?: return
        if (playing.isNotEmpty()) return
        CYLReflection.callKotlin(rive, "play", machine, CYLReflection.DEFAULT, CYLReflection.DEFAULT, true, false)
    }

    /**
     * [EN] Whether the state machine has the input: rive-android throws `StateMachineInputException` on its render
     *      thread for a missing one (the default boolean input "active" of a file without it), which crashes the app;
     *      on iOS, RiveRuntime's `setInput` only logs. Unknown (an older rive-android without `getInputNames`): true.
     * [CN] 状态机是否有该输入：rive-android 对不存在的输入（没有默认布尔输入 "active" 的文件）会在渲染线程抛出 `StateMachineInputException`，
     *      导致应用崩溃；iOS 上 RiveRuntime 的 `setInput` 只打印日志。无法判断时（没有 `getInputNames` 的旧版 rive-android）返回 true。
     */
    internal fun hasInput(machine: String, input: String): Boolean = CYLRiveInputs.hasInput(rive, machine, input)

    /**
     * [EN] Plays from the start (docs/Animated-Item.md, the Rive loop): a trigger restarts the state machine, then fires a frame
     *      later (check.riv stayed on its finished check); a boolean input the state machine has goes false, then true a
     *      frame later, so every play is a transition (a held input used to play once), and false after the duration; a
     *      state machine without that input restarts (house.riv); a linear animation restarts. With looping on, it plays
     *      again after each pass.
     * [CN] 从头播放（docs/Animated-Item.md，Rive 循环）：trigger 先重新开始状态机，一帧之后再触发（check.riv 停在完成的对勾上）；状态机中存在的布尔输入先设为
     *      false，一帧之后设为 true，每次播放都是一次状态切换（保持的输入以前只播放一次），经过时长后设为 false；没有该输入的状态机重新开始（house.riv）；
     *      线性动画重新开始。开启循环时，每次播放后再次播放。
     */
    override fun cyl_playAnimationView() {
        handler.removeCallbacksAndMessages(null)
        hasPlayed = true
        if (restingAfterLoad) {
            // [EN] Resumed where it rests (no settling), then played as usual. Only the state machine: an unnamed `play()` also
            //      starts every linear animation of the artboard, which then overrides the machine (menu_button.riv stuck after
            //      one play on Android, dcbfdec6).
            // [CN] 从静止处恢复（不重新定位），然后照常播放。只恢复状态机：不带名字的 `play()` 还会启动画板的所有线性动画，它们会覆盖状态机
            //      （Android 上 menu_button.riv 播放一次后卡住，dcbfdec6）。
            restingAfterLoad = false
            val machineName = stateMachine
            if (machineName != null) {
                CYLReflection.callKotlin(rive, "play", machineName, CYLReflection.DEFAULT, CYLReflection.DEFAULT, true, false)
            } else if (options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveAnimation] == null) {
                CYLReflection.callKotlin(rive, "play", CYLReflection.DEFAULT, CYLReflection.DEFAULT, false)
            }
        }
        val machine = stateMachine
        val trigger = options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveTriggerInput] ?: options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveTriggerProperty]
        val animation = options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveAnimation]
        val default = CYLReflection.DEFAULT
        val restart = {
            // [EN] `reset()`, then `play(loop, direction, settleInitialState)` with its defaults. [CN] `reset()` 后以默认值调用 `play(loop, direction, settleInitialState)`。
            CYLReflection.call(rive, "reset")
            CYLReflection.callKotlin(rive, "play", default, default, default)
        }
        val number = numberInput
        when {
            machine != null && trigger == null && number != null && hasInput(machine, number) -> {
                // [EN] The next value: house.riv moves only when Rooms changes. [CN] 下一个值：house.riv 只在 Rooms 变化时运动。
                val next = CYLRiveInputs.nextNumber(numberValues, CYLRiveInputs.numberValue(rive, machine, number) ?: lastNumber)
                lastNumber = next
                cyl_resumeStateMachineIfSettled(machine)
                CYLReflection.call(rive, "setNumberState", machine, number, next)
            }
            machine != null && trigger != null && hasInput(machine, trigger) -> {
                restart()
                handler.postDelayed({ CYLReflection.call(rive, "fireState", machine, trigger) }, NEXT_FRAME_MS)
            }
            machine != null && trigger == null && numberInput == null && hasInput(machine, booleanInput) -> {
                setActive(false)
                handler.postDelayed({
                    setActive(true)
                    if (activeDuration > 0) handler.postDelayed({ setActive(false) }, (activeDuration * 1000).toLong())
                }, inputOffMilliseconds())
            }
            // [EN] rive-android `play(animationName, loop, direction, isStateMachine, settleInitialState)`, from the start.
            // [CN] rive-android 的 `play(animationName, loop, direction, isStateMachine, settleInitialState)`，从头开始。
            animation != null -> { CYLReflection.call(rive, "reset"); CYLReflection.callKotlin(rive, "play", animation, default, default, false, default) }
            else -> restart()
        }
        if (loops) handler.postDelayed(loopRunnable, (loopSeconds(machine, trigger) * 1000).toLong())
    }

    /**
     * [EN] Whether a play restarts the file (no usable trigger, number or boolean input, no named animation).
     * [CN] 一次播放是否重新开始文件（没有可用的 trigger、数字或布尔输入，也没有命名动画）。
     */
    /**
     * [EN] How long a held input stays off before it goes on again: half a loop pass while looping a held input (duration
     *      0), so the state machine spends real time closed on a slow device and every pass toggles (menu_button.riv stuck
     *      on an x86 emulator, the mini program's B20 fix 074285a6); otherwise INPUT_OFF_MS (150 ms): a slow device renders a
     *      frame in more than 50 ms, and the machine must advance at least once with the input off.
     * [CN] 保持的输入在重新打开前关闭多久：循环保持的输入（时长为 0）时为半个循环周期，使状态机在慢设备上也真正停留在关闭状态，每次循环都切换
     *      （x86 模拟器上 menu_button.riv 卡住，同小程序的 B20 修复 074285a6）；否则为 INPUT_OFF_MS（150 ms）：慢设备渲染一帧超过 50 ms，
     *      状态机必须在输入关闭时至少前进一次。
     */
    private fun inputOffMilliseconds(): Long =
        if (loops && activeDuration <= 0) (LOOP_SECONDS * 1000 / 2).toLong() else INPUT_OFF_MS

    private fun restartsOnPlay(): Boolean {
        val machine = stateMachine ?: return options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveAnimation] == null
        val trigger = options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveTriggerInput] ?: options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveTriggerProperty]
        if (trigger != null) return !hasInput(machine, trigger)
        numberInput?.let { return !hasInput(machine, it) }
        return !hasInput(machine, booleanInput)
    }

    /**
     * [EN] `cyl_setAnimationViewLoops`. [CN] `cyl_setAnimationViewLoops`。
     */
    override fun cyl_setAnimationViewLoops(loops: Boolean) {
        this.loops = loops
        if (!loops) handler.removeCallbacks(loopRunnable)
    }

    /**
     * [EN] A loop pass: after the input goes back to false (plus a pause), else LOOP_SECONDS. [CN] 一次循环：输入恢复为 false 之后（再停顿一下），否则 LOOP_SECONDS。
     */
    private fun loopSeconds(machine: String?, trigger: String?): Double =
        if (machine != null && trigger == null && activeDuration > 0) activeDuration + LOOP_PAUSE_SECONDS else LOOP_SECONDS

    override fun cyl_showAnimationViewLastFrame() {
        // [EN] The selection is recorded either way, so a theme instance bound later (night mode) keeps it.
        // [CN] 无论哪种情况都记录选中状态，之后绑定的主题实例（深色模式）会保留它。
        if (stateMachine != null) setActive(true) else { isActive = true; CYLReflection.call(rive, "pause") }
    }

    /**
     * [EN] rive-android's `isPlaying`: false once the animation ends or the state machine settles (rive-android pauses it).
     * [CN] rive-android 的 `isPlaying`：动画结束或状态机稳定（rive-android 会暂停它）后为 false。
     */
    override fun cyl_isAnimationViewPlaying(): Boolean? = CYLReflection.call(rive, "isPlaying") as? Boolean

    override fun cyl_stopAnimationView() {
        handler.removeCallbacksAndMessages(null)
        if (stateMachine != null) setActive(false) else { isActive = false; CYLReflection.call(rive, "stop"); CYLReflection.call(rive, "reset") }
    }

    /**
     * [EN] Provides the views of `CYLRiveTabBarItemAnimator`. [CN] 为 `CYLRiveTabBarItemAnimator` 提供视图。
     */
    companion object {
        /**
         * [EN] The `tint` option value that follows the tab's title color. [CN] 跟随 Tab 标题颜色的 `tint` 选项值。
         */
        const val TINT_TITLE = "title"
        private const val TAG = "CYLRiveTabBarItem"
        /**
         * [EN] Seconds of a loop pass when the file gives none. [CN] 文件未给出时一次循环的秒数。
         */
        const val LOOP_SECONDS = 1.5
        /**
         * [EN] The pause after an input goes back to false, before the next pass. [CN] 输入恢复为 false 后、下一次播放前的停顿。
         */
        const val LOOP_PAUSE_SECONDS = 0.4
        /**
         * [EN] A frame later: the state machine sees the reset or the false first. [CN] 一帧之后：状态机先看到重置或 false。
         */
        internal const val NEXT_FRAME_MS = 50L
        /**
         * [EN] A held input's off time before it goes on again (outside a loop). [CN] 保持的输入重新打开前的关闭时间（循环之外）。
         */
        internal const val INPUT_OFF_MS = 150L
        /**
         * [EN] One step of the state machine before it rests (a 60 Hz frame). [CN] 静止之前推进状态机的一步（60 Hz 的一帧）。
         */
        internal const val SETTLE_STEP_SECONDS = 1f / 60f
        /**
         * [EN] At most two seconds of steps; a machine still moving then moves by itself. [CN] 最多两秒的步数；之后仍在运动的状态机会自行运动。
         */
        internal const val SETTLE_STEPS = 120
    }

    object Provider : CYLTabBarItemAnimationViewProviding {
        @Volatile private var riveInitialized = false

        /**
         * [EN] rive-android needs `Rive.init(context)` before its first view (its androidx.startup initializer is not in every
         *      app, e.g. a React Native or Flutter app): called once here, by reflection, with the library's default renderer.
         * [CN] rive-android 在创建第一个视图之前需要 `Rive.init(context)`（并非每个 App 都有其 androidx.startup 初始化器，例如 React Native 或
         *      Flutter App）：这里通过反射调用一次，使用该库的默认渲染器。
         */
        private fun initializeRive(context: Context) {
            if (riveInitialized) return
            riveInitialized = true
            val rive = CYLReflection.type("app.rive.runtime.kotlin.core.Rive") ?: return
            val instance = runCatching { rive.getField("INSTANCE").get(null) }.getOrNull() ?: return
            runCatching { CYLReflection.callKotlin(instance, "init", context.applicationContext, CYLReflection.DEFAULT) }
        }

        override fun cyl_animationViewWithFileURL(context: Context, fileURL: String, options: Map<String, String>, contentMode: ImageView.ScaleType): View? {
            initializeRive(context)
            val rive = CYLReflection.newInstance(CYLRiveTabBarItemAnimator.VIEW_CLASS, context) as? View ?: return null
            val view = CYLRiveTabBarItemAnimationView(context, rive, options)
            // [EN] Until the file is here (a download), the host shows its static image or placeholder. [CN] 文件到达之前（下载中），宿主显示其静态图片或占位图。
            CYLTabBarItemAnimationFailure.markLoading(view)
            CYLTabBarItemAnimationFiles.localFile(context, fileURL) { file ->
                val bytes = try { file?.readBytes() } catch (error: java.io.IOException) { null }
                if (bytes == null || bytes.isEmpty()) {
                    CYLTabBarItemAnimationFailure.reportLater(view)
                    return@localFile
                }
                load(rive, bytes, options, contentMode)
                // [EN] The theme instance for the current mode (`viewModelInstance` / `darkViewModelInstance`). [CN] 当前模式的主题实例。
                view.cyl_bindThemeInstance()
                view.cyl_restUntilPlayed()
                CYLTabBarItemAnimationFailure.reportLoaded(view)
            }
            return view
        }

        /**
         * [EN] rive-android `setRiveBytes(bytes, artboardName, animationName, stateMachineName, autoplay, autoBind, fit,
         *      alignment, loop)`, as its sample's `setRiveResource(…, stateMachineName = …)`: the artboard and the state machine
         *      are given at load, a state machine runs (autoplay) so its inputs work, a linear animation waits to be played.
         *      The other parameters keep rive-android's defaults; the tab's content mode picks the fit.
         * [CN] rive-android 的 `setRiveBytes(bytes, artboardName, animationName, stateMachineName, autoplay, autoBind, fit, alignment, loop)`，
         *      与其示例的 `setRiveResource(…, stateMachineName = …)` 相同：加载时传入画板与状态机，状态机运行（autoplay）以便输入生效，线性动画等待播放。
         *      其他参数使用 rive-android 的默认值；Tab 的内容模式决定 fit。
         */
        private fun load(rive: View, bytes: ByteArray, options: Map<String, String>, contentMode: ImageView.ScaleType) {
            val default = CYLReflection.DEFAULT
            val stateMachine = options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveStateMachine]
            val fit = when (contentMode) {
                ImageView.ScaleType.FIT_XY -> "FILL"
                ImageView.ScaleType.CENTER_CROP -> "COVER"
                else -> "CONTAIN"
            }.let { CYLReflection.enumConstant("app.rive.runtime.kotlin.core.Fit", it) } ?: default
            val loaded = CYLReflection.callKotlin(rive, "setRiveBytes", bytes, options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveArtboard] ?: default,
                default, stateMachine ?: default, stateMachine != null, default, fit, default, default)
            // [EN] An older rive-android without these parameters: the bytes, then the artboard. [CN] 没有这些参数的旧版 rive-android：先设置数据，再设置画板。
            if (loaded == null) {
                CYLReflection.callWithDefaults(rive, "setRiveBytes", mapOf(ByteArray::class.java to bytes))
                options[CYLTabBarItemAnimationKeys.CYLTabBarAnimationOptionRiveArtboard]?.let { CYLReflection.call(rive, "setArtboardName", it) }
            }
        }
    }
}

/**
 * [EN] The inputs of a `RiveAnimationView`'s state machines, read by reflection (`getStateMachines()`, `getName()`,
 *      `getInputNames()` of rive-android): a missing input is skipped instead of crashing. Unknown answers are true.
 * [CN] 通过反射读取 `RiveAnimationView` 状态机的输入（rive-android 的 `getStateMachines()`、`getName()`、`getInputNames()`）：
 *      跳过不存在的输入，避免崩溃。无法判断时返回 true。
 */
internal object CYLRiveInputs {
    fun hasInput(rive: Any, machine: String, input: String): Boolean {
        val machines = try { rive.javaClass.getMethod("getStateMachines").invoke(rive) as? List<*> } catch (error: Exception) { null } ?: return true
        val instance = machines.firstOrNull { machineName(it) == machine } ?: return machines.isEmpty()
        val names = try { instance.javaClass.getMethod("getInputNames").invoke(instance) as? List<*> } catch (error: Exception) { null } ?: return true
        return names.contains(input)
    }

    /**
     * [EN] The `values` option ("3,4,5,6") as numbers. [CN] `values` 选项（"3,4,5,6"）转为数字。
     */
    fun numberValues(values: String?): List<Float> = values.orEmpty().split(',').mapNotNull { it.trim().toFloatOrNull() }

    /**
     * [EN] The value after `current` in `values`, cycling (an unknown value starts the list); without values, `current + 1`.
     * [CN] `values` 中 `current` 之后的值，循环（未知值从列表开头开始）；没有值时为 `current + 1`。
     */
    fun nextNumber(values: List<Float>, current: Float?): Float {
        if (values.isEmpty()) return (current ?: 0f) + 1f
        val index = if (current == null) -1 else values.indexOf(current)
        return values[(index + 1) % values.size]
    }

    /**
     * [EN] A number input's value (`input(name).getValue()` of rive-android), null when unknown.
     * [CN] 数字输入的值（rive-android 的 `input(name).getValue()`），无法读取时为 null。
     */
    fun numberValue(rive: Any, machine: String, input: String): Float? {
        val machines = try { rive.javaClass.getMethod("getStateMachines").invoke(rive) as? List<*> } catch (error: Exception) { null } ?: return null
        val instance = machines.firstOrNull { machineName(it) == machine } ?: return null
        return try {
            val smi = instance.javaClass.getMethod("input", String::class.java).invoke(instance, input) ?: return null
            (smi.javaClass.getMethod("getValue").invoke(smi) as? Number)?.toFloat()
        } catch (error: Exception) { null }
    }

    private fun machineName(instance: Any?): String? = try { instance?.javaClass?.getMethod("getName")?.invoke(instance) as? String } catch (error: Exception) { null }
}
