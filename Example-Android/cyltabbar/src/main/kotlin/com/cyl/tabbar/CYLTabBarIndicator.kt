/*
 * [EN] Adapted from QMUI_Android's QMUITabIndicator and the indicator layout of QMUIBasicTabSegment
 *      (https://github.com/Tencent/QMUI_Android), under the MIT License:
 * [CN] 改编自 QMUI_Android 的 QMUITabIndicator 与 QMUIBasicTabSegment 的指示器布局（https://github.com/Tencent/QMUI_Android），
 *      遵循 MIT 许可证：
 *
 * Tencent is pleased to support the open source community by making QMUI_Android available.
 * Copyright (C) 2017-2018 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.drawable.Drawable
import androidx.annotation.ColorInt

/**
 * [EN] Android only (no iOS counterpart): how the tab bar lays its tabs out. `Fixed` (default) gives every tab the same
 *      width, as on iOS; `Scrollable` sizes each tab to its content plus `cyl_itemSpaceInScrollMode`, and the bar scrolls
 *      horizontally when the tabs are wider than it (QMUI `MODE_SCROLLABLE`).
 * [CN] 仅 Android（iOS 无对应 API）：TabBar 的排布方式。`Fixed`（默认）每个 Tab 等宽，与 iOS 一致；`Scrollable` 按内容加
 *      `cyl_itemSpaceInScrollMode` 决定每个 Tab 的宽度，Tab 总宽超过 TabBar 时可横向滚动（QMUI 的 `MODE_SCROLLABLE`）。
 */
enum class CYLTabBarScrollMode { Fixed, Scrollable }

/**
 * [EN] Android only (no iOS counterpart): a bar drawn under (or over, `top`) the selected tab, set with
 *      `CYLTabBar.cyl_indicator`. It moves to the new tab when the selection changes, and follows the finger while the pages
 *      are swiped (`CYLTabBarController.cyl_swipesBetweenPages`, or `CYLTabBar.cyl_updateIndicatorPosition` from a pager of
 *      the app).
 *      - `height`: in dp (ignored with a `drawable`, which uses its intrinsic height when it has one).
 *      - `widthFollowsContent`: true (default) spans the title (or the icon of a tab without a title); false spans the tab.
 *      - `color`: a fixed color; null (default) takes the selected title color of the tab, blended while moving.
 *      - `cornerRadius`: in dp, for the default bar.
 * [CN] 仅 Android（iOS 无对应 API）：绘制在选中 Tab 下方（`top` 时为上方）的指示条，通过 `CYLTabBar.cyl_indicator` 设置。选中变化时移动到新
 *      Tab，滑动翻页时跟随手指（`CYLTabBarController.cyl_swipesBetweenPages`，或在 App 自己的翻页控件中调用 `CYLTabBar.cyl_updateIndicatorPosition`）。
 *      - `height`：dp（使用 `drawable` 时忽略；drawable 有固有高度时使用该高度）。
 *      - `widthFollowsContent`：true（默认）跨越标题（没有标题的 Tab 为图标）；false 跨越整个 Tab。
 *      - `color`：固定颜色；null（默认）使用该 Tab 的选中标题颜色，移动过程中渐变。
 *      - `cornerRadius`：dp，用于默认指示条。
 */
class CYLTabBarIndicator @JvmOverloads constructor(
    val height: Float = 2f,
    val top: Boolean = false,
    val widthFollowsContent: Boolean = true,
    @ColorInt val color: Int? = null,
    val drawable: Drawable? = null,
    val cornerRadius: Float = 0f,
) {
    private val rect = Rect()
    private val rectF = RectF()
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.FILL }
    private var placed = false

    /** [EN] `updateInfo`: the indicator's left and width in the bar's content, and its color. [CN] 指示条在 TabBar 内容中的左边与宽度，以及颜色。 */
    internal fun update(left: Int, width: Int, @ColorInt tabColor: Int) {
        rect.left = left
        rect.right = left + width
        placed = true
        val resolved = color ?: tabColor
        if (drawable != null) drawable.setTint(resolved) else paint.color = resolved
    }

    internal fun hide() { placed = false }

    /** [EN] Where the indicator is, in the bar's content, or null when hidden. [CN] 指示条在 TabBar 内容中的位置，隐藏时为 null。 */
    internal val cyl_bounds: Rect? get() = if (placed) Rect(rect) else null

    /** [EN] Draws at the top or the bottom of `[viewTop, viewBottom]`. [CN] 绘制在 `[viewTop, viewBottom]` 的顶部或底部。 */
    internal fun draw(canvas: Canvas, viewTop: Int, viewBottom: Int, density: Float) {
        if (!placed || rect.width() <= 0) return
        val barHeight = drawable?.intrinsicHeight?.takeIf { it > 0 } ?: maxOf(1, (height * density).toInt())
        if (top) { rect.top = viewTop; rect.bottom = viewTop + barHeight } else { rect.bottom = viewBottom; rect.top = viewBottom - barHeight }
        if (drawable != null) {
            drawable.bounds = rect
            drawable.draw(canvas)
        } else {
            rectF.set(rect)
            val radius = cornerRadius * density
            if (radius > 0) canvas.drawRoundRect(rectF, radius, radius, paint) else canvas.drawRect(rect, paint)
        }
    }

    internal companion object {
        /** [EN] `QMUIColorHelper.computeColor`: `from` blended towards `to` by `fraction`. [CN] 按 `fraction` 从 `from` 向 `to` 渐变的颜色。 */
        @ColorInt
        fun blend(@ColorInt from: Int, @ColorInt to: Int, fraction: Float): Int {
            val f = fraction.coerceIn(0f, 1f)
            fun channel(a: Int, b: Int) = (a + (b - a) * f).toInt()
            return Color.argb(channel(Color.alpha(from), Color.alpha(to)), channel(Color.red(from), Color.red(to)),
                channel(Color.green(from), Color.green(to)), channel(Color.blue(from), Color.blue(to)))
        }
    }
}
