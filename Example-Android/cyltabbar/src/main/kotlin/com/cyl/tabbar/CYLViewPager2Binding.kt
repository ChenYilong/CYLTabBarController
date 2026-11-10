// [EN] The method names use the library's `cyl_` prefix, see docs/Android-API-Map.md. [CN] 方法名使用库的 `cyl_` 前缀，见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")
@file:JvmName("CYLViewPager2Binding")

package com.cyl.tabbar

import android.widget.FrameLayout
import androidx.fragment.app.Fragment
import androidx.viewpager2.adapter.FragmentStateAdapter
import androidx.viewpager2.widget.ViewPager2

/**
 * [EN] Android only, one line (like QMUI's `setupWithViewPager`): the controller's pages live in `viewPager`, an
 *      `androidx.viewpager2.widget.ViewPager2` of the app (add `androidx.viewpager2:viewpager2` to the app; the library
 *      only compiles against it). The pager gets an adapter over `viewControllers`, keeps every page alive (as the
 *      controller does), and is added to `pagesContainer` when it has no parent yet. Then:
 *      - a tap on a tab scrolls the pager to its page; swiping the pager selects the tab, telling the delegate as a tap does;
 *      - the indicator (`CYLTabBar.cyl_indicator`) and the title colors follow the pager's scrolling;
 *      - a page a tap could not select (`shouldSelect` false, a custom action, a login) bounces back;
 *      - `reloadTabBarItemsWithAttributes` and the other ways to change the pages update the pager.
 *      The built-in `cyl_swipesBetweenPages` is turned off (the pager swipes), and slide transitions of the delegate and
 *      unloading on memory warnings do not apply to a pager's pages.
 * [CN] 仅 Android，一行代码（类似 QMUI 的 `setupWithViewPager`）：控制器的页面放在 App 的 `viewPager`（`androidx.viewpager2.widget.ViewPager2`）中
 *      （App 需添加 `androidx.viewpager2:viewpager2`；库只在编译时依赖它）。翻页控件获得基于 `viewControllers` 的 adapter，所有页面保持存活（与控制器一致），
 *      没有父视图时加入 `pagesContainer`。之后：
 *      - 点击 Tab 让翻页控件滚动到对应页面；滑动翻页控件选中 Tab，并与点击一样通知代理；
 *      - 指示条（`CYLTabBar.cyl_indicator`）与标题颜色跟随翻页控件的滚动；
 *      - 点击时不能选中的页面（`shouldSelect` 为 false、自定义动作、需要登录）会弹回；
 *      - `reloadTabBarItemsWithAttributes` 等修改页面的方法会更新翻页控件。
 *      内置的 `cyl_swipesBetweenPages` 会关闭（由翻页控件滑动），代理的滑动转场与内存警告卸载不作用于翻页控件中的页面。
 */
fun CYLTabBarController.cyl_setupWithViewPager2(viewPager: ViewPager2) {
    cyl_swipesBetweenPages = false
    // [EN] Pages the controller already added leave its fragments: the pager adds them again. [CN] 控制器已添加的页面先移除：由翻页控件重新添加。
    if (!fragmentManager.isDestroyed && !fragmentManager.isStateSaved) {
        val added = viewControllers.filter { it.isAdded }
        if (added.isNotEmpty()) fragmentManager.beginTransaction().apply { added.forEach { remove(it) } }.commitNowAllowingStateLoss()
    }
    val binding = CYLViewPager2Host(this, viewPager)
    cyl_pagesHost = binding
    if (viewPager.parent == null) pagesContainer.addView(viewPager, FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
    binding.attach()
}

/** [EN] The pager behind `cyl_setupWithViewPager2`, or null. [CN] `cyl_setupWithViewPager2` 绑定的翻页控件，没有时为 null。 */
val CYLTabBarController.cyl_viewPager2: ViewPager2? get() = (cyl_pagesHost as? CYLViewPager2Host)?.viewPager

internal class CYLViewPager2Host(private val controller: CYLTabBarController, val viewPager: ViewPager2) : CYLTabBarController.CYLPagesHost {
    private var syncing = false

    /** [EN] Pages by identity, so a replaced page is a new item. [CN] 按对象标识区分页面，被替换的页面是新的项。 */
    private val adapter = object : FragmentStateAdapter(controller.activity) {
        override fun getItemCount(): Int = controller.viewControllers.size
        override fun createFragment(position: Int): Fragment = controller.viewControllers[position]
        override fun getItemId(position: Int): Long = System.identityHashCode(controller.viewControllers[position]).toLong()
        override fun containsItem(itemId: Long): Boolean = controller.viewControllers.any { System.identityHashCode(it).toLong() == itemId }
    }

    private val callback = object : ViewPager2.OnPageChangeCallback() {
        override fun onPageScrolled(position: Int, positionOffset: Float, positionOffsetPixels: Int) {
            if (positionOffset > 0f) controller.tabBar.cyl_updateIndicatorPosition(position, positionOffset)
        }

        override fun onPageSelected(position: Int) {
            if (syncing || position == controller.selectedIndex) return
            if (controller.cyl_gestureSelectablePage(position) == null) {
                showPage(controller.selectedIndex, smooth = true)
                return
            }
            controller.cyl_selectIndexFromSwipe(position)
        }

        override fun onPageScrollStateChanged(state: Int) {
            if (state == ViewPager2.SCROLL_STATE_IDLE) controller.tabBar.cyl_updateIndicatorPosition(controller.selectedIndex, 0f)
        }
    }

    fun attach() {
        viewPager.adapter = adapter
        keepEveryPage()
        viewPager.registerOnPageChangeCallback(callback)
        showPage(controller.selectedIndex, smooth = false)
    }

    /** [EN] Every page alive, as the controller keeps them (no state lost when leaving a tab). [CN] 所有页面保持存活，与控制器一致（离开 Tab 不丢失状态）。 */
    private fun keepEveryPage() {
        viewPager.offscreenPageLimit = maxOf(1, controller.viewControllers.size - 1)
    }

    private fun showPage(index: Int, smooth: Boolean) {
        if (index !in 0 until adapter.itemCount || viewPager.currentItem == index) return
        syncing = true
        try {
            viewPager.setCurrentItem(index, smooth)
        } finally {
            syncing = false
        }
    }

    override fun cyl_showPage(index: Int) = showPage(index, smooth = viewPager.isAttachedToWindow)

    override fun cyl_pagesDidChange() {
        keepEveryPage()
        @Suppress("NotifyDataSetChanged") // [EN] Any page may have changed. [CN] 任何页面都可能变化。
        adapter.notifyDataSetChanged()
    }
}
