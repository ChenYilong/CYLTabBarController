package com.cyl.animateditem

/**
 * [EN] Whether the device draws Liquid Glass, the one rule every CYLTabBarController component asks (the same names as
 *      iOS `CYLLiquidGlass.isActive()`): Android 12 and later (Android 13+ draws the full glass with refraction, Android 12 the
 *      blur only, as the tab bar does); false on older versions, where callers keep their flat background.
 * [CN] 设备是否绘制液态玻璃，CYLTabBarController 各组件共用的唯一规则（与 iOS `CYLLiquidGlass.isActive()` 同名）：Android 12 及以上
 *      （Android 13+ 绘制带折射的完整玻璃，Android 12 只有模糊，与 TabBar 相同）；更早的版本为 false，调用方保持扁平背景。
 */
internal object CYLLiquidGlass {

    /**
     * [EN] For tests: replaces the device check of `isActive()` (`null`, the default, asks the device).
     * [CN] 供测试使用：替代 `isActive()` 对设备的检查（默认 `null`，询问设备）。
     */
    @JvmField
    @Volatile
    var activeOverride: Boolean? = null

    /**
     * [EN] Whether Liquid Glass is in use (see the class comment). [CN] 是否使用液态玻璃（见类注释）。
     */
    @JvmStatic
    fun isActive(): Boolean = activeOverride ?: CYLLiquidGlassSupport.rendersBlur
}
