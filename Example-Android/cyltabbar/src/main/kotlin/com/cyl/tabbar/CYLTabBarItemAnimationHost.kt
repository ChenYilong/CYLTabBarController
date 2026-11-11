// [EN] The method names are the iOS names on purpose (`cyl_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.content.res.Configuration
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import java.util.WeakHashMap

/*
 * [EN] The tab side of the animation layer: `UIControl (CYLTabBarItemAnimation)` and its Lottie-named twins as View
 *      extensions (the tab buttons and the plus button), the Dark Mode / color registry (#442, #216), and the lookup of a
 *      tab's animation file in its attributes.
 * [CN] 动画层的 Tab 一侧：以 View 扩展实现的 `UIControl (CYLTabBarItemAnimation)` 及其 Lottie 命名的方法（Tab 按钮与 PlusButton）、
 *      深色模式 / 颜色注册表（#442、#216），以及在 Tab 属性中查找动画文件。
 */

/**
 * [EN] The Dark Mode versions and colors of the animations, by the light animation's URL (the iOS style source): a dark
 *      file (`…DarkURL` / `…DarkFilePath`), dark colors (`…DarkColors`) and the colors of every appearance (`…Colors`).
 * [CN] 动画的深色版本与颜色，按浅色动画 URL 登记（对应 iOS 的 style source）：深色文件、深色颜色与所有外观下的颜色。
 */
object CYLTabBarItemAnimationStyleSource {
    private val darkURLs = java.util.concurrent.ConcurrentHashMap<String, String>()
    private val darkColors = java.util.concurrent.ConcurrentHashMap<String, Map<String, Int>>()
    private val colors = java.util.concurrent.ConcurrentHashMap<String, Map<String, Int>>()

    fun registerDarkURL(darkURL: String, url: String) { darkURLs[url] = darkURL }
    fun registerDarkColors(colors: Map<String, Int>, url: String) { darkColors[url] = colors }
    fun registerColors(colors: Map<String, Int>?, url: String) { if (colors.isNullOrEmpty()) this.colors.remove(url) else this.colors[url] = colors }
    fun darkColorsForURL(url: String): Map<String, Int>? = darkColors[url]
    fun hasDarkURLs(): Boolean = darkURLs.isNotEmpty() || darkColors.isNotEmpty()
    fun hasDarkStyleForURL(url: String): Boolean = darkURLs.containsKey(url) || darkColors.containsKey(url)

    fun isDark(configuration: Configuration) = (configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

    /**
     * [EN] The file to show for `url` in `configuration`: its dark version in Dark Mode. [CN] `configuration` 下 `url` 应显示的文件：深色模式下为其深色版本。
     */
    fun urlForStyle(url: String, configuration: Configuration): String = if (isDark(configuration)) darkURLs[url] ?: url else url

    /**
     * [EN] The colors for `url` in `configuration`: its colors, plus the dark colors in Dark Mode. [CN] `configuration` 下 `url` 的颜色：其颜色，深色模式下加上深色颜色。
     */
    fun colorsForStyle(url: String, configuration: Configuration): Map<String, Int>? {
        val all = HashMap(colors[url].orEmpty())
        if (isDark(configuration)) darkColors[url]?.let { all.putAll(it) }
        return all.takeIf { it.isNotEmpty() }
    }
}

private class CYLTabAnimationState(
    var url: String,
    var size: CYLSize?,
    var contentMode: ImageView.ScaleType,
    var speed: Float,
    var view: View?,
    var loadedURL: String?,
    var playing: Boolean = false,
)

private val animationStates = WeakHashMap<View, CYLTabAnimationState>()

private fun View.cyl_iconSizePx(size: CYLSize?): Pair<Int, Int> {
    val density = resources.displayMetrics.density
    val width = size?.width?.takeIf { it > 0 } ?: CYLConstants.CYLTabBarItemImagePlaceholderWidth
    val height = size?.height?.takeIf { it > 0 } ?: CYLConstants.CYLTabBarItemImagePlaceholderHeight
    return (width * density).toInt() to (height * density).toInt()
}

private fun View.cyl_insertAnimationView(state: CYLTabAnimationState) {
    val host = this as? ViewGroup ?: return
    val url = CYLTabBarItemAnimationStyleSource.urlForStyle(state.url, resources.configuration)
    val view = CYLTabBarItemAnimationFactory.animationViewWithURL(context, url, state.size ?: CYLSize.zero, state.contentMode) ?: return
    state.view?.let { host.removeView(it) }
    val (width, height) = cyl_iconSizePx(state.size)
    view.setTag(R.id.cyl_tab_bar_item_animation_view, true)
    host.addView(view, FrameLayout.LayoutParams(width, height, Gravity.CENTER))
    state.view = view
    state.loadedURL = url
    val player = CYLTabBarItemAnimationFactory.playerForView(view)
    if (state.speed > 0 && state.speed.isFinite()) player?.animationSpeed = state.speed
    player?.applyColors(CYLTabBarItemAnimationStyleSource.colorsForStyle(state.url, resources.configuration), resources.configuration)
    // [EN] The animation replaces the icon. [CN] 动画取代图标。
    when (this) {
        is CYLTabBarItemButton -> iconView.visibility = View.INVISIBLE
        is CYLPlusButton -> imageView.visibility = View.INVISIBLE
    }
    requestLayout()
}

/**
 * [EN] `-cyl_tabBarItemAnimationView`: the animation view of this tab button, or null. [CN] 本 Tab 按钮的动画视图，没有时为 null。
 */
val View.cyl_tabBarItemAnimationView: View? get() = animationStates[this]?.view

/**
 * [EN] `-cyl_isTabBarItemAnimationReady`: the animation view was added. [CN] 已添加动画视图。
 */
fun View.cyl_isTabBarItemAnimationReady(): Boolean = cyl_tabBarItemAnimationView != null

/**
 * [EN] `cyl_tabBarItemAnimationPlayer`: the player of this tab button's animation, null without one. [CN] 本 Tab 按钮动画的播放器，没有时为 null。
 */
val View.cyl_tabBarItemAnimationPlayer: CYLTabBarItemAnimationPlayer? get() = CYLTabBarItemAnimationFactory.playerForView(cyl_tabBarItemAnimationView)

/**
 * [EN] `-cyl_addTabBarItemAnimationWithURL:size:contentMode:(animationSpeed:)`: adds the animation of `url` in place of the
 *      icon, once; `speed` > 0 sets its playback speed. No library for the file: nothing is added and the icon stays.
 * [CN] 用 `url` 的动画取代图标，只添加一次；`speed` > 0 时设置播放速度。没有能播放该文件的动画库时不添加，保留图标。
 */
@JvmOverloads
fun View.cyl_addTabBarItemAnimationWithURL(url: String?, size: CYLSize?, contentMode: ImageView.ScaleType = ImageView.ScaleType.FIT_CENTER, speed: Float = 0f) {
    if (url.isNullOrBlank() || animationStates[this]?.view != null) return
    val state = CYLTabAnimationState(url, size, contentMode, speed, null, null)
    animationStates[this] = state
    cyl_insertAnimationView(state)
}

/**
 * [EN] `-cyl_setTabBarItemAnimationSpeed:`: 0, negative or not finite: the default. [CN] 0、负数或非有限值表示默认值。
 */
fun View.cyl_setTabBarItemAnimationSpeed(speed: Float) {
    val state = animationStates[this] ?: return
    state.speed = speed
    cyl_tabBarItemAnimationPlayer?.animationSpeed = if (speed > 0 && speed.isFinite()) speed else 1f
}

/**
 * [EN] `-cyl_reloadTabBarItemAnimationViewForCurrentStyle`: swaps to the file and colors of the current style (#442). [CN] 切换为当前风格的文件与颜色（#442）。
 */
fun View.cyl_reloadTabBarItemAnimationViewForCurrentStyle() {
    val state = animationStates[this] ?: return
    val url = CYLTabBarItemAnimationStyleSource.urlForStyle(state.url, resources.configuration)
    if (url != state.loadedURL) {
        cyl_insertAnimationView(state)
        if (state.playing) cyl_tabBarItemAnimationPlayer?.showLastFrame()
    } else {
        cyl_refreshTabBarItemAnimationColors()
    }
}

/**
 * [EN] `-cyl_replaceTabBarItemAnimationWithURL:size:contentMode:`: replaces the animation (e.g. a theme's). [CN] 替换动画（例如主题的动画）。
 */
fun View.cyl_replaceTabBarItemAnimationWithURL(url: String?, size: CYLSize?, contentMode: ImageView.ScaleType = ImageView.ScaleType.FIT_CENTER) {
    val previous = animationStates[this]
    if (url.isNullOrBlank()) {
        previous?.view?.let { (this as? ViewGroup)?.removeView(it) }
        animationStates.remove(this)
        when (this) {
            is CYLTabBarItemButton -> iconView.visibility = View.VISIBLE
            is CYLPlusButton -> imageView.visibility = View.VISIBLE
        }
        return
    }
    val state = CYLTabAnimationState(url, size, contentMode, previous?.speed ?: 0f, previous?.view, null, previous?.playing ?: false)
    animationStates[this] = state
    cyl_insertAnimationView(state)
    if (state.playing) cyl_tabBarItemAnimationPlayer?.showLastFrame()
}

/**
 * [EN] `-cyl_refreshTabBarItemAnimationColors`: applies the colors of the current style again (#216). [CN] 重新应用当前风格的颜色（#216）。
 */
fun View.cyl_refreshTabBarItemAnimationColors() {
    val state = animationStates[this] ?: return
    cyl_tabBarItemAnimationPlayer?.applyColors(CYLTabBarItemAnimationStyleSource.colorsForStyle(state.url, resources.configuration), resources.configuration)
}

/**
 * [EN] `-cyl_playTabBarItemAnimationWithURL:size:defaultSelected:contentMode:`: adds the animation when needed, then plays
 *      it, or shows its last frame when `defaultSelected` (the tab selected at launch, #389).
 * [CN] 需要时添加动画，然后播放；`defaultSelected` 时显示最后一帧（启动时选中的 Tab，#389）。
 */
@JvmOverloads
fun View.cyl_playTabBarItemAnimationWithURL(url: String?, size: CYLSize?, defaultSelected: Boolean, contentMode: ImageView.ScaleType = ImageView.ScaleType.FIT_CENTER) {
    cyl_addTabBarItemAnimationWithURL(url, size, contentMode)
    val state = animationStates[this] ?: return
    val player = cyl_tabBarItemAnimationPlayer ?: return
    state.playing = true
    if (defaultSelected) player.showLastFrame() else player.play()
}

/**
 * [EN] `-cyl_stopTabBarItemAnimation`: stops, back to the first frame. [CN] 停止并回到第一帧。
 */
fun View.cyl_stopTabBarItemAnimation() {
    val state = animationStates[this] ?: return
    state.playing = false
    cyl_tabBarItemAnimationPlayer?.stop()
}

// MARK: - The Lottie-named methods (deprecated on iOS) Lottie 命名的方法（iOS 上已废弃）

/**
 * [EN] `-cyl_lottieAnimationView`. [CN] 动画视图。
 */
val View.cyl_lottieAnimationView: View? get() = cyl_tabBarItemAnimationView
/**
 * [EN] `-cyl_isLottieReady`: use `cyl_isTabBarItemAnimationReady`. [CN] 请使用 `cyl_isTabBarItemAnimationReady`。
 */
fun View.cyl_isLottieReady(): Boolean = cyl_isTabBarItemAnimationReady()
/**
 * [EN] `-cyl_addLottieImageWithLottieURL:size:contentMode:(animationSpeed:)`. [CN] 添加 Lottie 动画。
 */
@JvmOverloads
fun View.cyl_addLottieImageWithLottieURL(lottieURL: String?, size: CYLSize?, contentMode: ImageView.ScaleType = ImageView.ScaleType.FIT_CENTER, animationSpeed: Float = 0f) =
    cyl_addTabBarItemAnimationWithURL(lottieURL, size, contentMode, animationSpeed)
/**
 * [EN] `-cyl_addLottieImageWithLottieFilePath:size:contentMode:`: a path or an asset name. [CN] 路径或 asset 名称。
 */
@JvmOverloads
fun View.cyl_addLottieImageWithLottieFilePath(lottieFilePath: String, size: CYLSize?, contentMode: ImageView.ScaleType = ImageView.ScaleType.FIT_CENTER) =
    cyl_addTabBarItemAnimationWithURL(lottieFilePath, size, contentMode)
fun View.cyl_setLottieAnimationSpeed(animationSpeed: Float) = cyl_setTabBarItemAnimationSpeed(animationSpeed)
fun View.cyl_reloadLottieAnimationViewForCurrentStyle() = cyl_reloadTabBarItemAnimationViewForCurrentStyle()
@JvmOverloads
fun View.cyl_animationLottieImageWithLottieURL(lottieURL: String?, size: CYLSize?, defaultSelected: Boolean, contentMode: ImageView.ScaleType = ImageView.ScaleType.FIT_CENTER) =
    cyl_playTabBarItemAnimationWithURL(lottieURL, size, defaultSelected, contentMode)
fun View.cyl_stopAnimationOfLottieView() = cyl_stopTabBarItemAnimation()
/**
 * [EN] `-[UIView cyl_isLottieAnimationView]`: a Lottie view (lottie-android). [CN] 是否为 Lottie 视图（lottie-android）。
 */
fun View.cyl_isLottieAnimationView(): Boolean = CYLLottieTabBarItemAnimator.isAvailable && CYLLottieTabBarItemAnimator.playerForAnimationView(this) != null

// MARK: - CYLTabBar (CYLTabBarControllerExtention)

/**
 * [EN] `-cyl_animationLottieImageWithSelectedControl:…`: plays the selected button's animation and stops the others. [CN] 播放选中按钮的动画，停止其他按钮的动画。
 */
@JvmOverloads
fun CYLTabBar.cyl_animationLottieImageWithSelectedControl(selectedControl: View?, lottieURL: String?, size: CYLSize?, defaultSelected: Boolean, contentMode: ImageView.ScaleType = ImageView.ScaleType.FIT_CENTER) {
    for (button in tabBarButtonArray) if (button !== selectedControl) button.cyl_stopTabBarItemAnimation()
    plusButton?.takeIf { it !== selectedControl }?.cyl_stopTabBarItemAnimation()
    selectedControl?.cyl_playTabBarItemAnimationWithURL(lottieURL, size, defaultSelected, contentMode)
}

/**
 * [EN] `-cyl_stopAnimationOfAllLottieView`. [CN] 停止所有动画。
 */
fun CYLTabBar.cyl_stopAnimationOfAllLottieView() {
    for (button in tabBarButtonArray) button.cyl_stopTabBarItemAnimation()
    plusButton?.cyl_stopTabBarItemAnimation()
}

// MARK: - Attributes 属性

/**
 * [EN] The value of `genericKey` in a tab's attributes: the generic key, else the key of the library the attributes choose, else any library's key. [CN] Tab 属性中 `genericKey` 的值：通用 key，否则属性选择的动画库的 key，否则任一动画库的 key。
 */
internal fun CYLTabBarItemAttributesAnimationValue(attributes: Map<String, Any?>, genericKey: String): Any? {
    attributes[genericKey]?.let { return it }
    CYLTabBarItemAnimatorRegistry.attributeKeyForGenericKey(genericKey, attributes)?.let { key -> attributes[key]?.let { return it } }
    val known = mapOf(
        CYLConstants.CYLTabBarAnimationURL to listOf(CYLConstants.CYLTabBarLottieURL, CYLConstants.CYLTabBarPAGURL, CYLConstants.CYLTabBarRiveURL, CYLConstants.CYLTabBarGIFURL),
        CYLConstants.CYLTabBarAnimationFilePath to listOf(CYLConstants.CYLTabBarLottieFilePath, CYLConstants.CYLTabBarPAGFilePath, CYLConstants.CYLTabBarRiveFilePath, CYLConstants.CYLTabBarGIFFilePath),
        CYLConstants.CYLTabBarAnimationSize to listOf(CYLConstants.CYLTabBarLottieSize, CYLConstants.CYLTabBarPAGSize, CYLConstants.CYLTabBarRiveSize, CYLConstants.CYLTabBarGIFSize),
        CYLConstants.CYLTabBarAnimationDarkURL to listOf(CYLConstants.CYLTabBarLottieDarkURL, CYLConstants.CYLTabBarPAGDarkURL, CYLConstants.CYLTabBarRiveDarkURL, CYLConstants.CYLTabBarGIFDarkURL),
        CYLConstants.CYLTabBarAnimationDarkFilePath to listOf(CYLConstants.CYLTabBarLottieDarkFilePath, CYLConstants.CYLTabBarPAGDarkFilePath, CYLConstants.CYLTabBarRiveDarkFilePath, CYLConstants.CYLTabBarGIFDarkFilePath),
        CYLConstants.CYLTabBarAnimationDarkColors to listOf(CYLConstants.CYLTabBarLottieDarkColors, CYLConstants.CYLTabBarRiveDarkColors),
    )
    return known[genericKey]?.firstNotNullOfOrNull { attributes[it] }
}

/**
 * [EN] A color map from a configuration value (keypath → "#RRGGBB" or Int). [CN] 由配置值得到的颜色表。
 */
@Suppress("UNCHECKED_CAST")
internal fun CYLAnimationColorsValue(value: Any?): Map<String, Int>? =
    (value as? Map<String, Any?>)?.mapNotNull { (key, color) -> CYLTabBarConfiguration.colorValue(color)?.let { key to it } }?.toMap()?.takeIf { it.isNotEmpty() }

/**
 * [EN] The animation file of a tab (`…URL`, else `…FilePath`, with `CYLTabBarAnimationOptions` in its fragment), bound to the
 *      library its keys choose, with its Dark Mode version and colors registered (#442, #216). null without one.
 * [CN] Tab 的动画文件（`…URL`，否则 `…FilePath`，`CYLTabBarAnimationOptions` 写入 fragment），绑定到其 key 选择的动画库，并登记深色版本与颜色。没有时为 null。
 */
internal fun CYLTabBarItemAnimationURLOfAttributes(attributes: Map<String, Any?>): String? {
    val file = (CYLTabBarItemAttributesAnimationValue(attributes, CYLConstants.CYLTabBarAnimationURL) as? String)?.takeIf { it.isNotBlank() }
        ?: (CYLTabBarItemAttributesAnimationValue(attributes, CYLConstants.CYLTabBarAnimationFilePath) as? String)?.takeIf { it.isNotBlank() }
        ?: return null
    @Suppress("UNCHECKED_CAST")
    val options = (attributes[CYLConstants.CYLTabBarAnimationOptions] as? Map<String, Any?>)?.mapNotNull { (key, value) -> (value as? String)?.let { key to it } }?.toMap()
    val url = (if (options.isNullOrEmpty()) file else CYLTabBarAnimationURLWithOptions(file, options + CYLTabBarAnimationFileAndOptions(file).second)) ?: return null
    CYLTabBarItemAnimatorRegistry.animatorForAttributes(attributes)?.let { CYLTabBarItemAnimatorRegistry.bindURL(url, it) }
    val darkURL = (CYLTabBarItemAttributesAnimationValue(attributes, CYLConstants.CYLTabBarAnimationDarkURL) as? String)?.takeIf { it.isNotBlank() }
        ?: (CYLTabBarItemAttributesAnimationValue(attributes, CYLConstants.CYLTabBarAnimationDarkFilePath) as? String)?.takeIf { it.isNotBlank() }
    if (darkURL != null) {
        CYLTabBarItemAnimationStyleSource.registerDarkURL(darkURL, url)
        CYLTabBarItemAnimatorRegistry.animatorForAttributes(attributes)?.let { CYLTabBarItemAnimatorRegistry.bindURL(darkURL, it) }
    }
    CYLAnimationColorsValue(CYLTabBarItemAttributesAnimationValue(attributes, CYLConstants.CYLTabBarAnimationDarkColors))?.let { CYLTabBarItemAnimationStyleSource.registerDarkColors(it, url) }
    CYLTabBarItemAnimationStyleSource.registerColors(CYLAnimationColorsValue(attributes[CYLConstants.CYLTabBarAnimationColors]), url)
    return url
}

/**
 * [EN] Whether a tab's attributes name an animation file. [CN] Tab 属性是否指定了动画文件。
 */
internal fun CYLTabBarItemAttributesHaveAnimationFile(attributes: Map<String, Any?>): Boolean =
    listOf(CYLConstants.CYLTabBarAnimationURL, CYLConstants.CYLTabBarAnimationFilePath).any { (CYLTabBarItemAttributesAnimationValue(attributes, it) as? String)?.isNotBlank() == true }

// MARK: - Attribute helpers 属性辅助函数

/**
 * [EN] Adds "<name>.<fileType>" from the app's assets (`assetDirectory`, null: the root) to each tab by position, with
 *      "<name>_dark.<fileType>" as the dark version when it exists. A tab without a name or a file is left as it is.
 * [CN] 按位置为每个 Tab 添加 App assets（`assetDirectory`，null 为根目录）中的 "<name>.<fileType>"，存在 "<name>_dark.<fileType>" 时作为深色版本。
 *      没有名称或文件的 Tab 保持不变。
 */
private fun CYLTabBarItemsAttributesAddingFilesOfType(context: android.content.Context, attributes: List<Map<String, Any?>>, names: List<Any?>, assetDirectory: String?, fileType: String, filePathKey: String, darkFilePathKey: String): List<Map<String, Any?>> {
    val prefix = assetDirectory?.trim('/')?.takeIf { it.isNotEmpty() }?.let { "$it/" } ?: ""
    val files = (context.assets.list(prefix.trimEnd('/')) ?: emptyArray()).toSet()
    return attributes.mapIndexed { index, item ->
        val name = names.getOrNull(index) as? String
        if (name.isNullOrEmpty() || "$name.$fileType" !in files) return@mapIndexed item
        val animated = LinkedHashMap(item)
        animated[filePathKey] = "$prefix$name.$fileType"
        if ("${name}_dark.$fileType" in files) animated[darkFilePathKey] = "$prefix${name}_dark.$fileType"
        animated
    }
}

/**
 * [EN] `CYLTabBarItemsAttributesAddingLottieFiles()`: "<name>.json" assets as `CYLTabBarLottieFilePath`. [CN] 以 "<name>.json" asset 作为 `CYLTabBarLottieFilePath`。
 */
@JvmOverloads
fun CYLTabBarItemsAttributesAddingLottieFiles(context: android.content.Context, attributes: List<Map<String, Any?>>, lottieFileNames: List<String>, assetDirectory: String? = null): List<Map<String, Any?>> =
    CYLTabBarItemsAttributesAddingFilesOfType(context, attributes, lottieFileNames, assetDirectory, "json", CYLConstants.CYLTabBarLottieFilePath, CYLConstants.CYLTabBarLottieDarkFilePath)

/**
 * [EN] `CYLTabBarItemsAttributesAddingPAGFiles()`: "<name>.pag" assets as `CYLTabBarPAGFilePath`. [CN] 以 "<name>.pag" asset 作为 `CYLTabBarPAGFilePath`。
 */
@JvmOverloads
fun CYLTabBarItemsAttributesAddingPAGFiles(context: android.content.Context, attributes: List<Map<String, Any?>>, pagFileNames: List<String>, assetDirectory: String? = null): List<Map<String, Any?>> =
    CYLTabBarItemsAttributesAddingFilesOfType(context, attributes, pagFileNames, assetDirectory, "pag", CYLConstants.CYLTabBarPAGFilePath, CYLConstants.CYLTabBarPAGDarkFilePath)

/**
 * [EN] `CYLTabBarItemAttributesAddingAnimationFile()`: one tab's attributes with an animation (#477): "name.ext" for that
 *      file, or "name" for the first extension of the libraries in the app whose asset exists.
 * [CN] 为一个 Tab 添加动画（#477）："name.ext" 为该文件，"name" 为 App 中动画库扩展名里第一个存在的 asset。
 */
@JvmOverloads
fun CYLTabBarItemAttributesAddingAnimationFile(context: android.content.Context, attributes: Map<String, Any?>, fileName: String, assetDirectory: String? = null): Map<String, Any?> {
    if (fileName.isEmpty()) return attributes
    val extensions = CYLTabBarItemAnimatorRegistry.fileExtensions().ifEmpty { listOf("json", "pag", "riv") }
    val extension = CYLTabBarAnimationFileExtension(fileName)
    val prefix = assetDirectory?.trim('/')?.takeIf { it.isNotEmpty() }?.let { "$it/" } ?: ""
    val files = (context.assets.list(prefix.trimEnd('/')) ?: emptyArray()).toSet()
    val (name, fileType) = if (extension.isNotEmpty() && extension in extensions) fileName.substringBeforeLast('.') to extension
                           else fileName to (extensions.firstOrNull { "$fileName.$it" in files } ?: return attributes)
    return CYLTabBarItemsAttributesAddingFilesOfType(context, listOf(attributes), listOf(name), assetDirectory, fileType, CYLConstants.CYLTabBarAnimationFilePath, CYLConstants.CYLTabBarAnimationDarkFilePath).first()
}

/**
 * [EN] `CYLTabBarItemsAttributesAddingAnimationFiles()`: the same for every tab by position; a null or empty name leaves the tab static. [CN] 按位置对每个 Tab 执行；名称为 null 或空时保持静态。
 */
@JvmOverloads
fun CYLTabBarItemsAttributesAddingAnimationFiles(context: android.content.Context, attributes: List<Map<String, Any?>>, fileNames: List<String?>, assetDirectory: String? = null): List<Map<String, Any?>> =
    attributes.mapIndexed { index, item -> fileNames.getOrNull(index)?.let { CYLTabBarItemAttributesAddingAnimationFile(context, item, it, assetDirectory) } ?: item }
