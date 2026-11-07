package com.cyl.tabbar.example.pag

import android.graphics.Color
import android.os.Bundle
import android.util.Log
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLPlusButton
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.CYLThemeManager
import com.cyl.tabbar.demo.DemoCatalog
import com.cyl.tabbar.demo.DemoListFragment
import com.cyl.tabbar.demo.DemoTabBarActivity
import com.cyl.tabbar.demo.TextPageFragment

/**
 * [EN] The Android port of Example-PAG (issue #604): four PAG tab icons played by libpag (`CYLTabBarAnimationFilePath`, the
 *      ".pag" extension picks PAG; 33 dp, 1.5x speed), a plus button drawn as a title on a background image whose page is
 *      "Menu", a guide on first launch, and the Grapefruit skin swapping two tabs' animations in place (#216). Without
 *      the PAG files (downloaded by scripts/fetch-animation-resources.py) the tabs show their images.
 * [CN] Example-PAG 的 Android 版（issue #604）：由 libpag 播放的四个 PAG Tab 图标（`CYLTabBarAnimationFilePath`，".pag" 扩展名选择 PAG；
 *      33 dp，1.5 倍速），标题画在背景图上的 PlusButton（页面为 "菜单"），首次启动的引导页，以及西柚皮肤原地互换两个 Tab 的动画（#216）。
 *      没有 PAG 文件（由 scripts/fetch-animation-resources.py 下载）时 Tab 显示其图片。
 */
class MainActivity : DemoTabBarActivity() {

    private val animationFiles = listOf("tab_home.pag", "tab_health.pag", "tab_moments.pag", "tab_me.pag")
    private val themeListener = CYLThemeManager.Listener { _, _, _ -> applySkinAnimations() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        CYLThemeManager.defaultManager.addListener(themeListener)
        if (GuideActivity.isFirstLaunch(this)) GuideActivity.show(this)
    }

    override fun onDestroy() {
        CYLThemeManager.defaultManager.removeListener(themeListener)
        super.onDestroy()
    }

    override fun makeTabBarController(style: CYLEnums.CYLTabBarStyleType): CYLTabBarController {
        CYLPlusButton.registerPlusButton(MenuPlusButton)
        val titles = listOf(R.string.tab_home, R.string.tab_health, R.string.tab_moments, R.string.tab_me).map(::getString)
        val images = listOf("home", "message", "lianxiren", "me")
        val items = titles.indices.map { index ->
            mapOf(CYLConstants.CYLTabBarItemTitle to titles[index], CYLConstants.CYLTabBarItemImage to images[index],
                  CYLConstants.CYLTabBarItemSelectedImage to images[index] + "_selected") + animation(animationFiles[index])
        }
        val pages = listOf(
            HomePage(),
            TextPageFragment.newInstance(titles[1], background = Color.BLUE),
            TextPageFragment.newInstance(getString(R.string.contacts), background = Color.rgb(128, 0, 128)),
            DemoListFragment.newInstance(DemoCatalog.SETTINGS),
        )
        return CYLTabBarController(this, pages, items, style, MenuPlusButton.CONTEXT).apply {
            // [EN] Issue #428: tab icon animations at 1.5x. [CN] Issue #428：Tab 图标动画 1.5 倍速。
            tabBarItemAnimationSpeed = 1.5f
            cyl_tabBarItemImageColor = Color.LTGRAY
            setTintColor(Color.parseColor("#3A57ED"))
            cyl_tabBarBackgroundColor = Color.WHITE
            hideTabBarShadowImageView()
            intent.getIntExtra(SELECTED_INDEX, -1).takeIf { it >= 0 }?.let { index -> view.post { selectedIndex = index } }
        }
    }

    /** [EN] The animation keys of a file, when it was downloaded (as `CYLTabBarItemAttributesAddingAnimationFile`). [CN] 文件已下载时的动画 key（对应 `CYLTabBarItemAttributesAddingAnimationFile`）。 */
    private fun animation(file: String): Map<String, Any?> {
        val exists = assets.list("").orEmpty().contains(file)
        if (!exists) Log.w("CYLTabBarPAG", getString(R.string.missing_pag))
        return if (exists) mapOf(CYLConstants.CYLTabBarAnimationFilePath to file, CYLConstants.CYLTabBarAnimationSize to "{33, 33}") else emptyMap()
    }

    /** [EN] #216: the Grapefruit skin swaps the animations of "Moments" and "Me" in place. [CN] #216：西柚皮肤原地互换 "朋友圈" 与 "我的" 的动画。 */
    private fun applySkinAnimations() {
        val controller = tabBarController ?: return
        val swaps = CYLThemeManager.defaultManager.currentThemeIdentifier == "Grapefruit"
        controller.updateTabBarItemAtIndex(2, animation(if (swaps) "tab_me.pag" else "tab_moments.pag"))
        controller.updateTabBarItemAtIndex(3, animation(if (swaps) "tab_moments.pag" else "tab_me.pag"))
    }

    companion object {
        /** [EN] The tab to select after the tab bar is created again (iOS `TabBarCommon.completionhandler`). [CN] 重新创建 TabBar 后选中的 Tab（iOS `TabBarCommon.completionhandler`）。 */
        const val SELECTED_INDEX = "selectedIndex"
    }
}
