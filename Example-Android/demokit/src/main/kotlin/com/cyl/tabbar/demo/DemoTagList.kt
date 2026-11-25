package com.cyl.tabbar.demo

import android.content.Context
import com.cyl.classifymenu.CYLIndexPath
import com.cyl.classifymenu.CYLMenuDelegate
import com.cyl.classifymenu.CYLMenuFoldControlKeyContent
import com.cyl.classifymenu.CYLMenuFoldControlKeyPosition
import com.cyl.classifymenu.CYLMenuStyleBackgroundColor
import com.cyl.classifymenu.CYLMenuStyleBackgroundStyle
import com.cyl.classifymenu.CYLMenuStyleTitleMaxLines
import com.cyl.classifymenu.CYLTagItemIdentifier
import com.cyl.classifymenu.CYLTagItemSubtitle
import com.cyl.classifymenu.CYLTagItemTitle
import com.cyl.classifymenu.CYLTagListView
import com.cyl.classifymenu.CYLTagListViewDefaultVisibleRows
import com.cyl.classifymenu.CYLTagListViewFoldControl
import com.cyl.classifymenu.CYLTagListViewLongPressAction
import com.cyl.classifymenu.CYLTagListViewScrollEnabled
import com.cyl.classifymenu.CYLTagListViewSections
import com.cyl.classifymenu.CYLTagListViewSelectionMode
import com.cyl.classifymenu.CYLTagListViewStyle
import com.cyl.classifymenu.CYLTagSectionItems
import com.cyl.classifymenu.CYLTagSectionTitle
import com.cyl.classifymenu.applyConfiguration

/**
 * [EN] The demo's sectioned lists are CollectionViewClassifyMenu tag lists (docs/instructions/examples.md): one tag per row (its
 *      title; the subtitle is the long-press callout), a titled header per section, tags as wide as their title, titles that wrap
 *      up to 3 lines, a More / Less control after 3 rows of tags. A tap does what tapping the old row did. The badge sample rows
 *      stay rows of the list, because a badge is drawn over a row's icon and a tag has no place for it.
 * [CN] 演示中带分组的列表使用 CollectionViewClassifyMenu 的 TagList（docs/instructions/examples.md）：每行一个 Tag（标题；副标题为长按浮层），
 *      每个分组有标题，Tag 宽度随标题自适应，标题最多换行 3 行，超过 3 行 Tag 后出现 More / Less 控件。点击 Tag 与点击原行效果相同。
 *      角标样例行仍是列表的行，因为角标画在行图标上，Tag 没有对应位置。
 */
object DemoTagList {
    const val TITLE_MAX_LINES = 3
    const val VISIBLE_ROWS = 3

    private val BRACKETS = Regex("\\s*[（(]([^）)]*)[）)]")

    /**
     * [EN] A tag's title is short: what a row's title says in brackets, "(…)" or "（…）", moves behind the row's subtitle (shown on a long
     *      press). A title that is only brackets stays as it is. Returns the title and the subtitle ("" for none).
     * [CN] Tag 的标题要短：行标题中括号「(…)」或「（…）」里的内容追加到行的副标题之后（长按才显示）。只有括号的标题保持不变。
     */
    fun tagText(title: String, subtitle: String?): Pair<String, String> {
        val notes = BRACKETS.findAll(title).map { it.groupValues[1].trim() }.filter { it.isNotEmpty() }.toList()
        val stripped = title.replace(BRACKETS, "").replace(Regex("\\s+"), " ").trim()
        if (stripped.isEmpty()) return title to (subtitle ?: "")
        return stripped to (listOfNotNull(subtitle?.takeIf { it.isNotEmpty() }) + notes).joinToString(" · ")
    }

    /** [EN] A section whose rows carry badge samples stays a list section. [CN] 含角标样例行的分组仍是列表分组。 */
    fun isBadgeSection(section: DemoSection) = section.rows.any { it.badgeRow >= 0 }

    /** [EN] The tag list configuration of `sections` (the order of the sections and rows is kept). [CN] `sections` 的 TagList 配置（保持分组与行的顺序）。 */
    fun configuration(sections: List<DemoSection>, subtitleOf: (DemoRow) -> String?): Map<String, Any?> = mapOf(
        // [EN] `none`: a tap selects nothing but still reports the item, so the host runs the row's action. [CN] `none`：点击不选中，仍回调条目，由宿主执行该行的动作。
        CYLTagListViewSelectionMode to "none",
        CYLTagListViewScrollEnabled to false,
        CYLTagListViewLongPressAction to "callout",
        CYLTagListViewDefaultVisibleRows to VISIBLE_ROWS,
        CYLTagListViewFoldControl to mapOf(CYLMenuFoldControlKeyPosition to "tail", CYLMenuFoldControlKeyContent to "icon"),
        // [EN] Liquid Glass tags (docs/instructions/examples.md). [CN] 液态玻璃样式的 Tag（docs/instructions/examples.md）。
        // [EN] The list sits on the page's own background: its default white would hide the (dark mode) header texts. [CN] 列表位于页面自己的背景之上：默认的白色会遮住（深色模式下的）标题文字。
        CYLTagListViewStyle to mapOf(CYLMenuStyleTitleMaxLines to TITLE_MAX_LINES, CYLMenuStyleBackgroundStyle to "liquidGlass", CYLMenuStyleBackgroundColor to "#00000000"),
        CYLTagListViewSections to sections.mapIndexed { sectionIndex, section ->
            mapOf(
                CYLTagSectionTitle to section.title,
                CYLTagSectionItems to section.rows.mapIndexed { itemIndex, row ->
                    val (title, subtitle) = tagText(row.title, subtitleOf(row))
                    val item = mutableMapOf<String, Any?>(CYLTagItemIdentifier to "$sectionIndex-$itemIndex", CYLTagItemTitle to title)
                    subtitle.takeIf { it.isNotEmpty() }?.let { item[CYLTagItemSubtitle] = it }
                    item
                },
            )
        },
    )

    /**
     * [EN] The tag list of one page. `update` builds it again when a row's title or subtitle changes (e.g. the current skin after a
     *      tap), and the sections the user expanded stay expanded.
     * [CN] 一页的 TagList。行的标题或副标题变化（如点击后显示当前皮肤）时 `update` 重新配置，用户已展开的分组保持展开。
     */
    class Holder(context: Context, private val onTap: (DemoRow) -> Unit) {
        val view = CYLTagListView(context)
        private var signature: String? = null
        private var rows: List<List<DemoRow>> = emptyList()

        init {
            view.menuDelegate = object : CYLMenuDelegate {
                override fun menuDidSelectItemAtIndexPath(menu: Any, indexPath: CYLIndexPath) {
                    rows.getOrNull(indexPath.section)?.getOrNull(indexPath.item)?.let(onTap)
                }
            }
        }

        fun update(sections: List<DemoSection>, subtitleOf: (DemoRow) -> String?) {
            val newSignature = sections.joinToString("||") { section ->
                section.title + "|" + section.rows.joinToString("|") { it.title + "-" + (subtitleOf(it) ?: "") }
            }
            if (newSignature == signature) return
            val expanded = sections.indices.filter { signature != null && view.isSectionExpanded(it) }
            signature = newSignature
            rows = sections.map { it.rows }
            view.applyConfiguration(configuration(sections, subtitleOf))
            expanded.forEach { view.setExpanded(true, it, false) }
        }
    }
}
