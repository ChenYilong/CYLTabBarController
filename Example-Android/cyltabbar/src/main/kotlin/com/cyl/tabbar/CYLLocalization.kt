package com.cyl.tabbar

import android.content.Context
import android.content.res.Configuration
import android.text.TextUtils
import android.view.View
import java.util.Locale

/**
 * [EN] The language of the library's own texts (badge and plus button accessibility texts), as iOS
 *      `CYLSetLocalizationLanguage()` / `CYLLocalizationLanguage()`: null follows the device language. The texts are
 *      resources generated from the iOS string tables (scripts/android-library-strings.py).
 * [CN] 库自身文字（角标与 PlusButton 的无障碍文字）使用的语言，对应 iOS 的 `CYLSetLocalizationLanguage()` /
 *      `CYLLocalizationLanguage()`：null 跟随设备语言。文字是由 iOS 字符串表生成的资源（scripts/android-library-strings.py）。
 */
object CYLLocalization {
    /** [EN] A BCP 47 tag such as "ar" or "zh-Hans", or null for the device language. [CN] BCP 47 语言标签，如 "ar"、"zh-Hans"；null 表示设备语言。 */
    @JvmStatic
    var language: String? = null

    /** [EN] `context` with [language] applied, or `context` itself when it follows the device. [CN] 应用 [language] 后的 `context`；跟随设备时为 `context` 本身。 */
    @JvmStatic
    fun localizedContext(context: Context): Context {
        val tag = language ?: return context
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(Locale.forLanguageTag(tag))
        return context.createConfigurationContext(configuration)
    }

    /** [EN] A library text in [language]. [CN] [language] 中的库文字。 */
    @JvmStatic
    fun string(context: Context, id: Int, vararg arguments: Any): String =
        localizedContext(context).resources.getString(id, *arguments)

    /** [EN] Whether `tag` (or the device language when null) is written right to left, e.g. Arabic. [CN] `tag`（null 时为设备语言）是否从右到左书写，如阿拉伯语。 */
    @JvmStatic
    fun isRightToLeft(tag: String?): Boolean {
        val locale = if (tag == null) Locale.getDefault() else Locale.forLanguageTag(tag)
        return TextUtils.getLayoutDirectionFromLocale(locale) == View.LAYOUT_DIRECTION_RTL
    }
}
