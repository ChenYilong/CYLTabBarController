package com.cyl.tabbar.demo

import android.app.AlertDialog
import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.AbsListView
import android.widget.BaseAdapter
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ListView
import android.widget.TextView
import androidx.core.os.bundleOf
import androidx.fragment.app.Fragment
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.cyl_setUpAutomaticRowHeightForTableView
import com.cyl.tabbar.cyl_showBadgeForRow
import com.cyl.tabbar.cyl_tabBarController
import com.cyl.tabbar.cyl_wrapsTextLabels
import com.cyl.tabbar.cyl_pushViewController

/**
 * [EN] One demo row, as a `UITableViewCell` of the iOS Example: a title, an optional subtitle (read each time the list
 *      reloads, so it can show the current state), an optional badge sample on its icon, and what a tap does.
 * [CN] 一个演示行，对应 iOS Example 的 `UITableViewCell`：标题、可选的副标题（每次刷新列表时读取，因此能显示当前状态）、可选的图标角标示例，
 *      以及点击时做什么。
 */
class DemoRow(
    val title: String,
    val subtitle: (DemoListFragment.() -> String?)? = null,
    val badgeRow: Int = -1,
    val action: DemoListFragment.() -> Unit,
)

/** [EN] A section of rows with its header, as a table view section. [CN] 一组行及其标题，对应列表的 section。 */
class DemoSection(val title: String, val rows: List<DemoRow>)

/**
 * [EN] The demo pages of the four tabs (Home, Message, Discover, Me), ported from the iOS Example's table view controllers
 *      (`CYLHomeViewController`, `CYLMessageViewController`, `CYLSameCityViewController`, `CYLMineViewController`):
 *      a list of sections from `DemoCatalog`, and a container that pages are pushed onto (`cyl_pushViewController`).
 * [CN] 四个 Tab（首页、消息、发现、我的）的演示页面，移植自 iOS Example 的列表页面：由 `DemoCatalog` 给出的 section 列表，以及可 push 页面的容器
 *      （`cyl_pushViewController`）。
 */
class DemoListFragment : Fragment() {

    /** [EN] Which tab: one of `DemoCatalog.HOME`, `MESSAGE`, `DISCOVER`, `ME`. [CN] 哪个 Tab：`DemoCatalog.HOME`、`MESSAGE`、`DISCOVER`、`ME` 之一。 */
    val page: String get() = requireArguments().getString(PAGE) ?: DemoCatalog.HOME
    /** [EN] `CYLTabBarItemPageParameters.url` of the tab, when its page ID is "web". [CN] 页面 ID 为 "web" 时 Tab 的 `CYLTabBarItemPageParameters.url`。 */
    val url: String? get() = requireArguments().getString(URL)
    private var sections: List<DemoSection> = emptyList()
    private val adapter = Adapter()
    /** [EN] The list, also the scrolling view of scroll hiding (issue #13). [CN] 列表，也是滚动隐藏的滚动视图（issue #13）。 */
    var listView: ListView? = null
        private set

    /** [EN] The tab bar controller of this page. [CN] 本页面所在的 TabBarController。 */
    val tabBarController: CYLTabBarController? get() = cyl_tabBarController

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val list = ListView(context).apply {
            adapter = this@DemoListFragment.adapter
            setOnItemClickListener { _, _, position, _ -> (this@DemoListFragment.adapter.getItem(position) as? DemoRow)?.let(::run) }
            // [EN] A context menu on long press, as the iOS rows have (and the scroll hiding simulation "long press a row"). [CN] 长按弹出菜单，与 iOS 行一致（也用于滚动隐藏模拟 "长按某行"）。
            setOnItemLongClickListener { _, view, position, _ ->
                val row = this@DemoListFragment.adapter.getItem(position) as? DemoRow ?: return@setOnItemLongClickListener false
                android.widget.PopupMenu(context, view).apply {
                    menu.add(android.R.string.copy).setOnMenuItemClickListener {
                        context.getSystemService(android.content.ClipboardManager::class.java)?.setPrimaryClip(android.content.ClipData.newPlainText("row", row.title))
                        true
                    }
                }.show()
                true
            }
        }
        cyl_setUpAutomaticRowHeightForTableView(list)
        list.setOnScrollListener(ScrollBridge())
        listView = list
        reload()
        return FrameLayout(context).apply { addView(list) }
    }

    override fun onDestroyView() {
        listView = null
        super.onDestroyView()
    }

    private fun run(row: DemoRow) {
        row.action(this)
        reload()
    }

    /** [EN] Reads the sections again (rows show the current state). [CN] 重新读取各 section（行显示当前状态）。 */
    fun reload() {
        sections = DemoCatalog.sections(this)
        adapter.notifyDataSetChanged()
    }

    // MARK: - Helpers of the rows 行使用的工具方法

    /** [EN] Pushes a plain page with `text`, as the iOS rows push a `CYLBaseViewController`. [CN] push 一个显示 `text` 的页面，对应 iOS 行 push 的 `CYLBaseViewController`。 */
    fun pushText(text: String, background: Int = Color.rgb(255, 165, 0)) =
        cyl_pushViewController(TextPageFragment.newInstance(text, background = background))

    /** [EN] An alert with a message, as `UIAlertController (alert)`. [CN] 显示消息的弹窗，对应 `UIAlertController (alert)`。 */
    fun showMessage(title: String, message: String) {
        AlertDialog.Builder(requireContext()).setTitle(title).setMessage(message).setPositiveButton(android.R.string.ok, null).show()
    }

    /** [EN] A list to choose from, as the iOS action sheets; `checked` marks the current choice. [CN] 供选择的列表，对应 iOS 的操作表；`checked` 标记当前选项。 */
    fun choose(title: String, options: List<String>, checked: Int = -1, onPick: (Int) -> Unit) {
        AlertDialog.Builder(requireContext()).setTitle(title)
            .setSingleChoiceItems(options.toTypedArray(), checked) { dialog, which -> dialog.dismiss(); onPick(which); reload() }
            .setNegativeButton(android.R.string.cancel, null).show()
    }

    /**
     * [EN] A `ListView` scrolls its rows without changing `scrollY`, so the tab bar controller cannot see it: this passes
     *      the pixels scrolled to `cyl_scrollDidChange` (scroll hiding, issue #13). A `ScrollView` or `RecyclerView` needs
     *      no bridge.
     * [CN] `ListView` 滚动行时不改变 `scrollY`，TabBarController 无法感知：这里把滚动的像素交给 `cyl_scrollDidChange`（滚动隐藏，issue #13）。
     *      `ScrollView` 或 `RecyclerView` 无需此桥接。
     */
    private inner class ScrollBridge : AbsListView.OnScrollListener {
        private var lastPosition = -1
        private var lastTop = 0
        override fun onScrollStateChanged(view: AbsListView, scrollState: Int) { /* [EN] Only the offset matters. [CN] 只关心偏移。 */ }
        override fun onScroll(view: AbsListView, firstVisibleItem: Int, visibleItemCount: Int, totalItemCount: Int) {
            val top = view.getChildAt(0)?.top ?: return
            val height = view.getChildAt(0)?.height ?: return
            if (lastPosition >= 0) {
                val delta = if (firstVisibleItem == lastPosition) lastTop - top else (firstVisibleItem - lastPosition) * height + lastTop - top
                if (delta != 0) tabBarController?.cyl_scrollDidChange(delta)
            }
            lastPosition = firstVisibleItem
            lastTop = top
        }
    }

    private inner class Adapter : BaseAdapter() {
        private val items: List<Any> get() = sections.flatMap { listOf<Any>(it) + it.rows }
        override fun getCount() = items.size
        override fun getItem(position: Int): Any = items[position]
        override fun getItemId(position: Int) = position.toLong()
        override fun getViewTypeCount() = 2
        override fun getItemViewType(position: Int) = if (items[position] is DemoSection) 0 else 1
        override fun isEnabled(position: Int) = items[position] is DemoRow

        override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
            val context = parent.context
            return when (val item = items[position]) {
                is DemoSection -> ((convertView as? TextView) ?: header(context)).apply { text = item.title }
                is DemoRow -> ((convertView as? LinearLayout) ?: row(context)).also { view ->
                    val icon = view.getChildAt(0) as ImageView
                    icon.visibility = if (item.badgeRow >= 0) View.VISIBLE else View.GONE
                    if (item.badgeRow >= 0) icon.cyl_showBadgeForRow(item.badgeRow)
                    val texts = view.getChildAt(1) as LinearLayout
                    (texts.getChildAt(0) as TextView).text = item.title
                    val subtitle = item.subtitle?.invoke(this@DemoListFragment)
                    (texts.getChildAt(1) as TextView).apply { text = subtitle; visibility = if (subtitle.isNullOrEmpty()) View.GONE else View.VISIBLE }
                }
                else -> View(context)
            }
        }

        private fun header(context: Context) = TextView(context).apply {
            val density = resources.displayMetrics.density
            setPadding((16 * density).toInt(), (18 * density).toInt(), (16 * density).toInt(), (6 * density).toInt())
            setTextColor(Color.GRAY)
            textSize = 13f
            setTypeface(typeface, Typeface.BOLD)
        }

        private fun row(context: Context): LinearLayout {
            val density = context.resources.displayMetrics.density
            return LinearLayout(context).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                clipChildren = false
                setPadding((16 * density).toInt(), (10 * density).toInt(), (16 * density).toInt(), (10 * density).toInt())
                addView(ImageView(context), LinearLayout.LayoutParams((30 * density).toInt(), (30 * density).toInt()).apply { marginEnd = (16 * density).toInt() })
                addView(LinearLayout(context).apply {
                    orientation = LinearLayout.VERTICAL
                    addView(TextView(context).apply { textSize = 15f })
                    addView(TextView(context).apply { textSize = 12f; setTextColor(Color.GRAY) })
                }, LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f))
                cyl_wrapsTextLabels()
            }
        }
    }

    companion object {
        private const val PAGE = "page"
        private const val URL = "url"
        fun newInstance(page: String, url: String? = null) = DemoListFragment().apply { arguments = bundleOf(PAGE to page, URL to url) }
    }
}
