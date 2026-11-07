package com.cyl.tabbar.example.pag

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.LayoutInflater
import android.view.Menu
import android.view.MenuInflater
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.TextView
import androidx.annotation.ColorInt
import androidx.annotation.StringRes
import androidx.core.os.bundleOf
import androidx.core.view.MenuProvider
import androidx.fragment.app.Fragment
import androidx.lifecycle.Lifecycle
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.demo.DemoAssets
import com.cyl.tabbar.cyl_addBadgeHelperTable
import com.cyl.tabbar.cyl_pushViewController
import com.cyl.tabbar.cyl_showNavigationBadgeValue
import kotlin.random.Random

/**
 * [EN] A page of a tab's navigation controller (iOS `ViewController` in a `RootNavigationController`): its title shows in the
 *      action bar while it is on screen; a pushed page hides the tab bar (`hidesBottomBarWhenPushed`) and shows a back button.
 * [CN] Tab 导航控制器中的页面（iOS `RootNavigationController` 中的 `ViewController`）：显示时其标题出现在 ActionBar 中；push 的页面隐藏 TabBar
 *      （`hidesBottomBarWhenPushed`）并显示返回按钮。
 */
abstract class NavigationPage(@StringRes private val navigationTitle: Int, private val pushed: Boolean = false) : Fragment() {
    override fun onResume() { super.onResume(); if (!isHidden) appear() }
    override fun onPause() { if (pushed) disappear(); super.onPause() }
    override fun onHiddenChanged(hidden: Boolean) { super.onHiddenChanged(hidden); if (!hidden) appear() }

    private fun appear() {
        val activity = activity as? MainActivity ?: return
        activity.setNavigationTitle(if (navigationTitle != 0) getString(navigationTitle) else "")
        activity.supportActionBar?.setDisplayHomeAsUpEnabled(pushed)
        if (pushed) activity.tabBarController?.setTabBarHidden(true, true)
    }

    private fun disappear() {
        val activity = activity as? MainActivity ?: return
        activity.supportActionBar?.setDisplayHomeAsUpEnabled(false)
        activity.tabBarController?.setTabBarHidden(false, true)
    }
}

/** [EN] A page with a title and a color (iOS `HealthyVC`, `FriendsVC`, `WisdomVC`). [CN] 带标题与颜色的页面（iOS `HealthyVC`、`FriendsVC`、`WisdomVC`）。 */
class ColorPage : NavigationPage(0) {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View =
        View(inflater.context).apply {
            setBackgroundColor(requireArguments().getInt(COLOR))
            isClickable = true
        }

    override fun onResume() {
        super.onResume()
        if (!isHidden) (activity as? MainActivity)?.setNavigationTitle(getString(requireArguments().getInt(TITLE)))
    }

    override fun onHiddenChanged(hidden: Boolean) {
        super.onHiddenChanged(hidden)
        if (!hidden) (activity as? MainActivity)?.setNavigationTitle(getString(requireArguments().getInt(TITLE)))
    }

    companion object {
        private const val TITLE = "title"
        private const val COLOR = "color"
        fun newInstance(@StringRes title: Int, @ColorInt color: Int) = ColorPage().apply { arguments = bundleOf(TITLE to title, COLOR to color) }
    }
}

/**
 * [EN] iOS `HomeVC`: a red page with the badge helper table (`cyl_addBadgeHelperTable`), a "Full screen" action item with
 *      a shaking dot badge of a random color (`cyl_showNavigationBadgeValue`) that pushes `ChildPage`.
 * [CN] iOS `HomeVC`：带角标帮助列表（`cyl_addBadgeHelperTable`）的红色页面，"全屏" 菜单项上有随机颜色、抖动的红点角标
 *      （`cyl_showNavigationBadgeValue`），点击 push `ChildPage`。
 */
class HomePage : NavigationPage(R.string.tab_home) {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View =
        FrameLayout(inflater.context).apply { setBackgroundColor(Color.RED) }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        cyl_addBadgeHelperTable()
        requireActivity().addMenuProvider(object : MenuProvider {
            override fun onCreateMenu(menu: Menu, menuInflater: MenuInflater) {
                menu.add(Menu.NONE, R.id.full_screen, Menu.NONE, R.string.full_screen).setIcon(DemoAssets.drawable(requireContext(), "屏幕全屏")).setShowAsAction(MenuItem.SHOW_AS_ACTION_IF_ROOM)
                view.post { cyl_showNavigationBadgeValue("", CYLEnums.CYLBadgeAnimationType.Shake, Color.rgb(Random.nextInt(256), Random.nextInt(256), Random.nextInt(256))) }
            }

            override fun onMenuItemSelected(menuItem: MenuItem): Boolean {
                if (menuItem.itemId != R.id.full_screen) return false
                cyl_pushViewController(ChildPage())
                return true
            }
        }, viewLifecycleOwner, Lifecycle.State.RESUMED)
    }
}

/**
 * [EN] iOS `ChilderVC`: an image from the network over a gray page; "Next" pushes `NextPage`, a tap creates the tab bar again
 *      (`TabBarCommon.enterApp`).
 * [CN] iOS `ChilderVC`：灰色页面上的网络图片；"下一页" push `NextPage`，点击页面重新创建 TabBar（`TabBarCommon.enterApp`）。
 */
class ChildPage : NavigationPage(0, pushed = true) {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val context = inflater.context
        val image = ImageView(context).apply { scaleType = ImageView.ScaleType.CENTER_CROP; setBackgroundColor(Color.LTGRAY) }
        Thread {
            val bitmap = runCatching { java.net.URI(BACKGROUND_IMAGE_URL).toURL().openStream().use { android.graphics.BitmapFactory.decodeStream(it) } }.getOrNull()
            image.post { if (bitmap != null) image.setImageBitmap(bitmap) }
        }.start()
        return FrameLayout(context).apply {
            setBackgroundColor(Color.WHITE)
            isClickable = true
            setOnClickListener { restart(-1) }
            addView(image, FrameLayout.LayoutParams(-1, -1))
            addView(TextView(context).apply { setText(R.string.child_hint); setTextColor(Color.WHITE); setShadowLayer(4f, 0f, 0f, Color.BLACK); gravity = Gravity.CENTER }, FrameLayout.LayoutParams(-1, -2, Gravity.CENTER))
        }
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        // [EN] `addRightBarButtonItemTitle("next")`: a white title item. [CN] `addRightBarButtonItemTitle("next")`：白色标题按钮。
        requireActivity().addMenuProvider(object : MenuProvider {
            override fun onCreateMenu(menu: Menu, menuInflater: MenuInflater) {
                menu.add(Menu.NONE, R.id.next_page, Menu.NONE, R.string.next).setShowAsAction(MenuItem.SHOW_AS_ACTION_IF_ROOM)
            }

            override fun onMenuItemSelected(menuItem: MenuItem): Boolean {
                if (menuItem.itemId != R.id.next_page) return false
                cyl_pushViewController(NextPage())
                return true
            }
        }, viewLifecycleOwner, Lifecycle.State.RESUMED)
    }

    companion object {
        /** [EN] The demo's background image (iOS `CYLDemoBackgroundImageURL` in Info.plist). [CN] 演示的背景图（iOS Info.plist 中的 `CYLDemoBackgroundImageURL`）。 */
        const val BACKGROUND_IMAGE_URL = "https://fc3tn.baidu.com/it/u=3025909226,1763324618&fm=202&src=bqdata"
    }
}

/** [EN] iOS `NextVC`: a tap creates the tab bar again with "Me" selected (`TabBarCommon.completionhandler(3)`). [CN] iOS `NextVC`：点击后重新创建 TabBar 并选中 "我的"（`TabBarCommon.completionhandler(3)`）。 */
class NextPage : NavigationPage(0, pushed = true) {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View =
        TextView(inflater.context).apply {
            setText(R.string.next_hint)
            gravity = Gravity.CENTER
            setBackgroundColor(Color.WHITE)
            isClickable = true
            setOnClickListener { restart(3) }
        }
}

/** [EN] Creates the tab bar again, selecting `index` (-1: the first tab). [CN] 重新创建 TabBar，选中 `index`（-1 为第一个 Tab）。 */
private fun Fragment.restart(index: Int) {
    val activity = requireActivity()
    activity.startActivity(Intent(activity, MainActivity::class.java).putExtra(MainActivity.SELECTED_INDEX, index).addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK))
    activity.finish()
}

/** [EN] iOS `MeVC`: "Me", the settings list (`CYLSettingsDemoTableViewController`) as a child. [CN] iOS `MeVC`："我的"，设置列表（`CYLSettingsDemoTableViewController`）作为子页面。 */
class MePage : NavigationPage(R.string.tab_me) {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        val list = FrameLayout(inflater.context).apply { id = View.generateViewId() }
        if (savedInstanceState == null) childFragmentManager.beginTransaction().add(list.id, com.cyl.tabbar.demo.DemoListFragment.newInstance(com.cyl.tabbar.demo.DemoCatalog.SETTINGS)).commit()
        return list
    }
}
