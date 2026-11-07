package com.cyl.tabbar.example.pag

import android.graphics.Color
import android.os.Bundle
import android.util.Log
import com.cyl.tabbar.CYLConstants
import com.cyl.tabbar.CYLEnums
import com.cyl.tabbar.CYLPlusButton
import com.cyl.tabbar.CYLTabBarController
import com.cyl.tabbar.CYLThemeManager
import com.cyl.tabbar.demo.DemoTabBarActivity

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

    private val animationFiles = listOf("tab_home.pag", "tab_health.pag", TAB_MOMENTS, TAB_ME)
    private val themeListener = CYLThemeManager.Listener { _, _, _ -> applySkinAnimations() }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // [EN] `RootNavigationController`: an opaque 3A57ED bar with white titles and buttons. [CN] `RootNavigationController`：不透明的 3A57ED 导航栏，白色标题与按钮。
        supportActionBar?.setBackgroundDrawable(android.graphics.drawable.ColorDrawable(NAVIGATION_BAR_COLOR))
        supportActionBar?.setHomeAsUpIndicator(androidx.core.content.ContextCompat.getDrawable(this, androidx.appcompat.R.drawable.abc_ic_ab_back_material)?.mutate()?.apply { setTint(Color.WHITE) })
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
        // [EN] The image names of `TabBarCommon.tabBarItemsAttributesForController()`, from Example-PAG's asset catalog. [CN] `TabBarCommon.tabBarItemsAttributesForController()` 中的图片名称，来自 Example-PAG 的资源目录。
        val images = listOf("Home", "Message", "lianxiren", "Me")
        val items = titles.indices.map { index ->
            mapOf(CYLConstants.CYLTabBarItemTitle to titles[index], CYLConstants.CYLTabBarItemImage to images[index],
                  CYLConstants.CYLTabBarItemSelectedImage to images[index] + "Selected") + animation(animationFiles[index])
        }.toMutableList()
        items[1] = items[1] + (CYLConstants.CYLTabBarItemDarkImage to "Message_night")
        val pages = listOf(
            HomePage(),
            ColorPage.newInstance(R.string.tab_health, Color.BLUE),
            ColorPage.newInstance(R.string.contacts, Color.rgb(128, 0, 128)),
            MePage(),
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

    /** [EN] The action bar title in white, as the iOS navigation bar. [CN] 白色的 ActionBar 标题，与 iOS 导航栏一致。 */
    fun setNavigationTitle(text: String) {
        title = android.text.SpannableString(text).apply { setSpan(android.text.style.ForegroundColorSpan(Color.WHITE), 0, length, 0) }
    }

    override fun onOptionsItemSelected(item: android.view.MenuItem): Boolean {
        if (item.itemId == android.R.id.home) {
            onBackPressedDispatcher.onBackPressed()
            return true
        }
        return super.onOptionsItemSelected(item)
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
        controller.updateTabBarItemAtIndex(2, animation(if (swaps) TAB_ME else TAB_MOMENTS))
        controller.updateTabBarItemAtIndex(3, animation(if (swaps) TAB_MOMENTS else TAB_ME))
    }

    companion object {
        /** [EN] The tab to select after the tab bar is created again (iOS `TabBarCommon.completionhandler`). [CN] 重新创建 TabBar 后选中的 Tab（iOS `TabBarCommon.completionhandler`）。 */
        const val SELECTED_INDEX = "selectedIndex"
        private const val TAB_MOMENTS = "tab_moments.pag"
        private const val TAB_ME = "tab_me.pag"
        val NAVIGATION_BAR_COLOR = Color.parseColor("#3A57ED")
    }
}
