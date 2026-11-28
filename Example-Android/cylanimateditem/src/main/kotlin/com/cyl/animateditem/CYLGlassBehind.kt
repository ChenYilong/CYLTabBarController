package com.cyl.animateditem

import android.view.View
import android.view.ViewGroup

/**
 * [EN] The glass views that are drawn BEHIND `view` and cover it, from the back one to the front one: for each ancestor N of `view` (starting at its
 *      host, which is never returned), the siblings of N that are drawn before N and are a [CYLAnimatedItemView] or [CYLAnimatedItemStackView]
 *      whose glass layer is attached and drawn, that are visible, attached, not transparent, not empty, and whose bounds contain the bounds of `view`
 *      (a tag lies inside its section card). "Drawn before" follows the drawing order of the parent: the custom child order when the parent enables
 *      one (detected by reflection, else the index order), then the z order (elevation + translationZ, a higher z is drawn later even at a lower
 *      index). Ancestors are never returned. Outer levels come first. Positions use `left`/`top`, the translation and the scroll of the parents. It only
 *      reads the view tree (no invalidate, no requestLayout), so it is safe on the draw path.
 *      Used by [CYLLiquidGlassView]: a glass tag samples these too, so it is lighter than its card (as on HarmonyOS); the board is drawn without its sheen and rim into the backdrop ([CYLLiquidGlassView.drawForBackdrop]: tint and fill only), so the tag does not light its edge twice.
 * [CN] 绘制在 `view` 后面并覆盖它的玻璃视图，由后到前：对 `view` 的每个祖先 N（从其宿主开始，宿主绝不返回），取先于 N 绘制、且是
 *      [CYLAnimatedItemView] 或 [CYLAnimatedItemStackView]、其玻璃层已附加并绘制、可见、已附加到窗口、不透明度大于 0、尺寸非零、
 *      边界包含 `view` 边界的同级（标签位于分区卡片之内）。「先绘制」遵循父视图的绘制顺序：父视图启用自定义子视图顺序时用它
 *      （通过反射检测，否则用索引顺序），再按 z 序（elevation + translationZ，z 更高的即使索引更小也更晚绘制）。祖先绝不返回。外层在前。
 *      位置使用 \`left\`/\`top\`、平移与父视图的滚动。它只读取视图树（不调用 invalidate、requestLayout），因此可用于绘制路径。
 *      由 [CYLLiquidGlassView] 使用：玻璃标签也采样这些视图，因此比所在的卡片更亮（与鸿蒙一致）；看板绘制到背景中时不含高光与细边（[CYLLiquidGlassView.drawForBackdrop]：只有着色与填充），标签不会把边照亮两次。
 */
internal fun glassViewsBehind(view: View): List<View> {
    val levels = ArrayList<List<View>>()
    var node: View = view.parent as? View ?: return emptyList()
    while (true) {
        val parent = node.parent as? ViewGroup ?: break
        val order = drawingOrder(parent)
        val nodePosition = order.indexOf(parent.indexOfChild(node))
        val found = ArrayList<View>()
        for (position in 0 until nodePosition) {
            val sibling = parent.getChildAt(order[position])
            if (qualifies(sibling) && covers(parent, sibling, view)) found += sibling
        }
        if (found.isNotEmpty()) levels += found
        node = parent
    }
    return levels.asReversed().flatten()
}

private fun qualifies(candidate: View): Boolean {
    val glass = when (candidate) {
        is CYLAnimatedItemView -> candidate.itemLiquidGlassView
        is CYLAnimatedItemStackView -> candidate.itemLiquidGlassView
        else -> null
    } as? CYLLiquidGlassView ?: return false
    return glass.isGlassDrawn && candidate.visibility == View.VISIBLE && candidate.alpha > 0f &&
        candidate.isAttachedToWindow && candidate.width > 0 && candidate.height > 0
}

/** The child indexes of `parent` in drawing order: the custom order if enabled, then a stable sort by z (as ViewGroup does). */
private fun drawingOrder(parent: ViewGroup): List<Int> {
    val count = parent.childCount
    var order = (0 until count).toList()
    try {
        val enabled = ViewGroup::class.java.getDeclaredMethod("isChildrenDrawingOrderEnabled").apply { isAccessible = true }
        if (enabled.invoke(parent) == true) {
            val child = ViewGroup::class.java.getDeclaredMethod("getChildDrawingOrder", Int::class.javaPrimitiveType, Int::class.javaPrimitiveType).apply { isAccessible = true }
            val custom = (0 until count).map { child.invoke(parent, count, it) as Int }
            if (custom.toSet().size == count && custom.all { it in 0 until count }) order = custom
        }
    } catch (e: Exception) {
        // [EN] Not detectable: the index order. [CN] 无法检测：按索引顺序。
    }
    return order.sortedBy { elevationOf(parent.getChildAt(it)) }
}

private fun elevationOf(child: View): Float = child.elevation + child.translationZ

/** Whether `outer` (a child of `parent`) contains `view` (a descendant of `parent`), both in the coordinates of `parent`. */
private fun covers(parent: ViewGroup, outer: View, view: View): Boolean {
    var x = 0f
    var y = 0f
    var v = view
    while (v.parent !== parent) {
        val up = v.parent as? View ?: return false
        x += v.left + v.translationX - up.scrollX
        y += v.top + v.translationY - up.scrollY
        v = up
    }
    x += v.left + v.translationX
    y += v.top + v.translationY
    val left = outer.left + outer.translationX
    val top = outer.top + outer.translationY
    val slop = 0.5f
    return x >= left - slop && y >= top - slop &&
        x + view.width <= left + outer.width + slop && y + view.height <= top + outer.height + slop
}
