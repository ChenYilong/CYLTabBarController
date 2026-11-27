//
//  CYLFont.kt
//  cylutils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
//  [EN] Moved unchanged from CYLTabBarItem.kt into the bottom module (docs/Animated-Item-Badge-CrossPlatform.md, step A3): the badge needs them and sits
//       below the tab bar. The package stays `com.cyl.tabbar` (a package may span modules), so no import changes. Not compiled yet.
//  [CN] 从 CYLTabBarItem.kt 原样移到最底层模块（docs/Animated-Item-Badge-CrossPlatform.md，步骤 A3）：角标需要它们，而角标位于 TabBar 之下。
//       包名仍为 `com.cyl.tabbar`（一个包可以分布在多个模块），因此不需要改 import。尚未编译。
//

package com.cyl.tabbar

import android.graphics.Typeface

/**
 * [EN] UIEdgeInsets. [CN] 边距。
 */
data class CYLEdgeInsets(val top: Float, val left: Float, val bottom: Float, val right: Float) {
    companion object {
        @JvmField val zero = CYLEdgeInsets(0f, 0f, 0f, 0f)
    }
}

/**
 * [EN] UIFont: a size in sp and an optional typeface. [CN] 字体：字号（sp）与可选的 Typeface。
 */
data class CYLFont(val size: Float, val typeface: Typeface? = null, val bold: Boolean = false) {
    companion object {
        /**
         * [EN] "15", "bold:15" or "Family-Style:12" as in a configuration file. [CN] 配置文件中的写法。
         */
        @JvmStatic
        fun fromConfigurationValue(value: Any?): CYLFont? {
            val text = when (value) {
                is Number -> return CYLFont(value.toFloat()).takeIf { value.toFloat() > 0 }
                is String -> value.trim()
                else -> return null
            }
            val parts = text.split(':')
            val size = parts.last().toFloatOrNull() ?: return null
            if (size <= 0 || size > 200) return null
            if (parts.size == 1) return CYLFont(size)
            val name = parts[0].trim()
            val weights = listOf("ultralight", "thin", "light", "regular", "medium", "semibold", "bold", "heavy", "black")
            return if (name.lowercase() in weights) {
                CYLFont(size, bold = name.lowercase() in listOf("semibold", "bold", "heavy", "black"))
            } else {
                CYLFont(size, Typeface.create(name.substringBefore('-'), if (name.contains("Bold", true)) Typeface.BOLD else Typeface.NORMAL))
            }
        }
    }
}
