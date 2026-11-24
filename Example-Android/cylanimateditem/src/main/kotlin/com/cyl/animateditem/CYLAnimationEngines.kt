package com.cyl.animateditem

import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.Handler
import android.os.Looper
import android.util.Log

/**
 * [EN] The animation types the component knows, whether or not their library is in the app: each type's own keys, file
 *      extensions and Gradle dependency. A tab or an item that names a type whose library is missing still finds its file
 *      (and shows its static image, or the placeholder), and debug builds log which dependency to add. The iOS
 *      counterpart is `CYLAnimationKeys` of the CYLAnimatedItem pod (`CYLAnimationAttributesValue`,
 *      `CYLAnimationTypeOfFile`, `CYLAnimationTypeIsAvailable`, `CYLAnimationWarnMissingEngine`).
 * [CN] 组件认识的动画类型（与其动画库是否在 App 中无关）：每种类型自己的 key、文件扩展名与 Gradle 依赖。指定了动画库缺失的类型的 Tab
 *      或条目仍能找到文件（并显示静态图片，没有时显示占位图），debug 构建会在日志中提示需要加入的依赖。iOS 对应 CYLAnimatedItem pod 的
 *      `CYLAnimationKeys`。
 */
object CYLAnimationEngines {

    /**
     * [EN] Called on the main thread when an animation file cannot be shown, with the file name or path as configured and
     *      a short reason (`CYLResourceMissingReason`): once per resource per view. The same signal as
     *      `CYLAnimatedItemView.onResourceMissing`, for a host with no view reference (CYLPlaceholder's status bar).
     *      Nothing else changes: the item still shows its static image or the placeholder. iOS:
     *      `CYLAnimationEngines.resourceMissingListener`.
     * [CN] 动画文件无法显示时在主线程调用，参数为按配置给出的文件名或路径与一个简短原因（`CYLResourceMissingReason`）：每个视图每个资源一次。
     *      与 `CYLAnimatedItemView.onResourceMissing` 是同一信号，供没有视图引用的宿主使用（CYLPlaceholder 状态栏）。其他行为不变：条目仍显示
     *      静态图片或占位图。
     */
    @JvmStatic
    @Volatile
    var resourceMissingListener: ((resource: String, reason: String) -> Unit)? = null

    private val mainHandler by lazy { Handler(Looper.getMainLooper()) }

    /**
     * [EN] Delivers a missing resource on the main thread: logs a warning in a debuggable app, calls `viewCallback`, then
     *      `resourceMissingListener`. A throwing callback does not stop the other.
     * [CN] 在主线程上报缺失的资源：可调试的 App 中输出警告日志，先调用 `viewCallback`，再调用 `resourceMissingListener`。某个回调抛出异常不影响另一个。
     */
    internal fun dispatchResourceMissing(context: Context, resource: String, reason: String, viewCallback: ((String, String) -> Unit)?) {
        val deliver = Runnable {
            if (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0) {
                Log.w("CYLAnimatedItem", "Animation resource \"$resource\" is missing: $reason. Shown in debuggable builds only.")
            }
            runCatching { viewCallback?.invoke(resource, reason) }
            runCatching { resourceMissingListener?.invoke(resource, reason) }
        }
        if (Looper.myLooper() == Looper.getMainLooper()) deliver.run() else mainHandler.post(deliver)
    }

    private class Type(val name: String, val extensions: List<String>, val keys: Map<String, String>, val dependency: String, val isAvailable: () -> Boolean)

    private val types = listOf(
        Type("Lottie", listOf("json", "lottie"), keys(CYLTabBarItemAnimationKeys.CYLTabBarLottieURL, CYLTabBarItemAnimationKeys.CYLTabBarLottieFilePath, CYLTabBarItemAnimationKeys.CYLTabBarLottieSize,
            CYLTabBarItemAnimationKeys.CYLTabBarLottieDarkURL, CYLTabBarItemAnimationKeys.CYLTabBarLottieDarkFilePath, CYLTabBarItemAnimationKeys.CYLTabBarLottieDarkColors),
            "com.airbnb.android:lottie") { CYLLottieTabBarItemAnimator.isAvailable },
        Type("PAG", listOf("pag"), keys(CYLTabBarItemAnimationKeys.CYLTabBarPAGURL, CYLTabBarItemAnimationKeys.CYLTabBarPAGFilePath, CYLTabBarItemAnimationKeys.CYLTabBarPAGSize,
            CYLTabBarItemAnimationKeys.CYLTabBarPAGDarkURL, CYLTabBarItemAnimationKeys.CYLTabBarPAGDarkFilePath, null),
            "com.tencent.tav:libpag") { CYLPAGTabBarItemAnimator.isAvailable },
        Type("Rive", listOf("riv"), keys(CYLTabBarItemAnimationKeys.CYLTabBarRiveURL, CYLTabBarItemAnimationKeys.CYLTabBarRiveFilePath, CYLTabBarItemAnimationKeys.CYLTabBarRiveSize,
            CYLTabBarItemAnimationKeys.CYLTabBarRiveDarkURL, CYLTabBarItemAnimationKeys.CYLTabBarRiveDarkFilePath, CYLTabBarItemAnimationKeys.CYLTabBarRiveDarkColors),
            "app.rive:rive-android") { CYLRiveTabBarItemAnimator.isAvailable },
        Type("SVGA", listOf("svga"), keys(CYLTabBarItemAnimationKeys.CYLTabBarSVGAURL, CYLTabBarItemAnimationKeys.CYLTabBarSVGAFilePath, CYLTabBarItemAnimationKeys.CYLTabBarSVGASize,
            CYLTabBarItemAnimationKeys.CYLTabBarSVGADarkURL, CYLTabBarItemAnimationKeys.CYLTabBarSVGADarkFilePath, null),
            "com.github.yyued:SVGAPlayer-Android") { CYLSVGATabBarItemAnimator.isAvailable },
        // [EN] GIF is decoded by the platform: always there. [CN] GIF 由系统解码：总是可用。
        Type("GIF", listOf("gif"), keys(CYLTabBarItemAnimationKeys.CYLTabBarGIFURL, CYLTabBarItemAnimationKeys.CYLTabBarGIFFilePath, CYLTabBarItemAnimationKeys.CYLTabBarGIFSize,
            CYLTabBarItemAnimationKeys.CYLTabBarGIFDarkURL, CYLTabBarItemAnimationKeys.CYLTabBarGIFDarkFilePath, null),
            "") { true },
    )

    private fun keys(url: String, filePath: String, size: String, darkURL: String, darkFilePath: String, darkColors: String?): Map<String, String> =
        listOfNotNull(
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationURL to url,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationFilePath to filePath,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationSize to size,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkURL to darkURL,
            CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkFilePath to darkFilePath,
            darkColors?.let { CYLTabBarItemAnimationKeys.CYLTabBarAnimationDarkColors to it },
        ).toMap()

    private val warned = mutableSetOf<String>()

    /**
     * [EN] The value of `genericKey` under the generic key or any type's own key, whether or not that type's library is
     *      in the app. [CN] `genericKey` 的值：通用 key 或任一类型自己的 key，与该类型的动画库是否在 App 中无关。
     */
    @JvmStatic
    fun attributesValue(attributes: Map<String, Any?>?, genericKey: String): Any? {
        attributes ?: return null
        attributes[genericKey]?.let { return it }
        return types.firstNotNullOfOrNull { type -> type.keys[genericKey]?.let { attributes[it] } }
    }

    /**
     * [EN] "Lottie", "PAG", "Rive", "SVGA" or "GIF": from the type keys in `attributes`, else from the file's extension.
     * [CN] 类型名：先看 `attributes` 中的类型 key，否则看文件扩展名。
     */
    @JvmStatic
    fun typeOf(attributes: Map<String, Any?>?, file: String?): String? {
        attributes?.let { values -> types.firstOrNull { type -> type.keys.values.any { values[it] != null } }?.let { return it.name } }
        val extension = file?.substringBefore('#')?.substringBefore('?')?.substringAfterLast('.', "")?.lowercase().orEmpty()
        return types.firstOrNull { extension.isNotEmpty() && extension in it.extensions }?.name
    }

    /**
     * [EN] Whether the library of `type` is in the app. [CN] `type` 的动画库是否在 App 中。
     */
    @JvmStatic
    fun isAvailable(type: String?): Boolean = types.firstOrNull { it.name == type }?.isAvailable?.invoke() == true

    /**
     * [EN] The types this component knows, in a fixed order: "Lottie", "PAG", "Rive", "SVGA", "GIF"; each is also its
     *      animator's identifier in `CYLTabBarItemAnimatorRegistry`. iOS: `CYLAnimationKnownTypes()`.
     * [CN] 组件已知的类型，顺序固定；每个名称也是其 animator 在注册表中的名称。iOS：`CYLAnimationKnownTypes()`。
     */
    @JvmStatic
    fun knownTypes(): List<String> = types.map { it.name }

    /**
     * [EN] The Gradle dependency that brings the library of `type` (empty for GIF, decoded by the platform); null when
     *      unknown. iOS: `CYLAnimationSubspecOfType()`.
     * [CN] 提供 `type` 动画库的 Gradle 依赖（GIF 由系统解码，为空字符串）；未知类型为 null。iOS：`CYLAnimationSubspecOfType()`。
     */
    @JvmStatic
    fun dependencyOf(type: String?): String? = types.firstOrNull { it.name == type }?.dependency

    /**
     * [EN] In a debuggable app, logs once per type that a file cannot play because its library is missing, with the
     *      dependency to add; the item shows its static image, or the placeholder. Nothing in release builds, for an
     *      unknown type, or when the library is there.
     * [CN] 在可调试的 App 中，每种类型输出一次日志：文件因动画库缺失而无法播放，并给出需要加入的依赖；条目显示静态图片或占位图。release 构建、
     *      未知类型或动画库存在时不做任何事。
     */
    @JvmStatic
    fun warnMissingEngine(context: Context, attributes: Map<String, Any?>?, file: String?) {
        if (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) return
        val name = typeOf(attributes, file) ?: return
        if (isAvailable(name)) return
        val type = types.first { it.name == name }
        synchronized(warned) { if (!warned.add(name)) return }
        Log.w("CYLAnimatedItem", "$name animation (${file?.substringAfterLast('/') ?: "?"}) cannot play: the $name library is not in this app. " +
            "Showing the static image, or the placeholder without one. Add implementation(\"${type.dependency}:<version>\"). Shown in debuggable builds only.")
    }

    /**
     * [EN] For tests: forget the types already warned about. [CN] 供测试使用：清除已提示过的类型。
     */
    @androidx.annotation.VisibleForTesting
    internal fun resetWarnings() = synchronized(warned) { warned.clear() }
}

/**
 * [EN] The `reason` of a missing resource (`CYLAnimatedItemView.onResourceMissing`,
 *      `CYLAnimationEngines.resourceMissingListener`): the same four tokens on every platform.
 * [CN] 缺失资源的 `reason`：各平台使用同样的四个字符串。
 */
object CYLResourceMissingReason {
    const val NOT_FOUND = "not found"
    const val UNREADABLE = "unreadable"
    const val DECODE_FAILED = "decode failed"
    const val ENGINE_LIBRARY_MISSING = "engine library missing"
}
