//
//  UIViewController+CYLSettingsSection.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 * [EN] Section index of the settings rows at the top of a list: row 0 is the language setting
 *      (`-cyl_languageCellForTableView:`), row 1 the memory warning check (`-cyl_memoryWarningCellForTableView:`),
 *      row 2 switches the title offset of all tabs (`CYLTabBarController.titlePositionAdjustment`, issue #475),
 *      row 3 switches `tabBar.standardAppearance` themes, shared by Liquid Glass and FlatDesign,
 *      row 4 toggles the cached login state (`cyl_loggedIn`) and names the tabs that need login (issue #19),
 *      row 5 shows the plus button's touchable area and scales it with a slider (issue #91),
 *      row 6 selects the next tab by its index without the plus button (`cyl_selectedIndexIgnoringPlusButton`, issue #515),
 *      row 7 switches how the tab bar minimizes or hides on scroll (`cyl_tabBarMinimizeBehavior`, issue #13),
 *      row 8 switches the tap animation of the tabs, row 9 turns on the long press of the tabs, row 10 turns on swiping
 *      to switch tabs, row 11 shows a subview that responds outside its superview, row 12 loads an image from a bundle,
 *      row 13 hides the navigation bar without a base class, row 14 opens the slide transition demo, row 15 switches
 *      the tap sound and haptic, row 16 switches the long press duration and double tap interval, row 17 switches to
 *      the previous or next tab, row 18 runs the CYLUtils weak associated object and nearest control helpers (issue #535),
 *      row 19 pushes a tab bar controller whose plus button gets its image later (loaded, replaced, removed, or a
 *      background image),
 *      row 20 picks a skin (theme) of the tab bar (`CYLThemeManager`, `CYLTabBarTheme`, issue #216),
 *      row 21 lists the scroll hiding simulations in an action sheet (`-cyl_presentScrollHideSimulationMenu`, issue #13),
 *      row 22 creates a tab bar controller from a configuration file or URL (`UIViewController+CYLConfigurationDemo.h`),
 *      then the simulated failures of configurations, one row each (`-cyl_configurationEdgeCaseCellForTableView:row:`),
 *      then the in-place tab item updates (`-cyl_tabBarItemUpdateCellForTableView:row:`): title, icon, network icon,
 *      all network icons, all local icons, GIF icon, all titles, replace neighboring tabs.
 * [CN] 列表顶部设置分组的 section：第 0 行为语言设置（`-cyl_languageCellForTableView:`），第 1 行为内存警告检查
 *      （`-cyl_memoryWarningCellForTableView:`），第 2 行切换所有 Tab 的标题偏移（`CYLTabBarController.titlePositionAdjustment`，
 *      issue #475），第 3 行切换 `tabBar.standardAppearance` 主题（液态玻璃与扁平样式共用），
 *      第 4 行切换缓存的登录状态（`cyl_loggedIn`），并列出需要登录的 Tab（issue #19），
 *      第 5 行显示 PlusButton 的可点击区域，并用滑块按倍数扩大（issue #91），
 *      第 6 行按不含 PlusButton 的下标选中下一个 Tab（`cyl_selectedIndexIgnoringPlusButton`，issue #515），
 *      第 7 行切换滚动时 TabBar 缩小或隐藏的方式（`cyl_tabBarMinimizeBehavior`，issue #13），
 *      第 8 行切换 Tab 的点击动画，第 9 行开启 Tab 长按，第 10 行开启左右滑动切换 Tab，第 11 行演示超出父视图的子视图响应点击，
 *      第 12 行从 bundle 加载图片，第 13 行不继承基类隐藏导航栏，第 14 行打开滑动转场演示，第 15 行切换点击声音与触感反馈，
 *      第 16 行切换长按时长与双击间隔，第 17 行切换到上一个或下一个 Tab，第 18 行运行 CYLUtils 弱引用关联对象与查找按钮的工具方法（issue #535），
 *      第 19 行 push 一个 PlusButton 之后才加载图片的 TabBarController（加载、替换、移除图片或加载背景图片），
 *      第 20 行选择 TabBar 的皮肤（主题，`CYLThemeManager`、`CYLTabBarTheme`，issue #216），
 *      第 21 行用操作表列出滚动隐藏的模拟（`-cyl_presentScrollHideSimulationMenu`，issue #13），
 *      第 22 行由配置文件或 URL 创建 TabBarController（`UIViewController+CYLConfigurationDemo.h`），然后每个配置文件模拟意外情况一行
 *      （`-cyl_configurationEdgeCaseCellForTableView:row:`），之后是原地更新 Tab 的若干行
 *      （`-cyl_tabBarItemUpdateCellForTableView:row:`）：标题、图标、网络图标、所有网络图标、所有本地图标、GIF 图标、所有标题、替换相邻 Tab 的页面。
 */
#define CYLSettingsSection 0

/*!
 * [EN] `CYLSettingsGroup` and `UIViewController (CYLSettingsSection)` are implemented in Swift
 *      (`Swift/UIViewController+CYLSettingsSection.swift` and the `Swift/CYLSettingsDemoRows*.swift` rows, every name and
 *      selector kept) and declared by the generated Swift interface (`CYLSwiftInterface.h`), imported below. The scroll
 *      hiding simulations are in `Swift/UIViewController+CYLScrollHideSimulation.swift`. `CYLSettingsSection` is a macro (it
 *      was an extern constant), with the same name and value (docs/Swift-Migration.md, steps 32 and 33).
 * [CN] `CYLSettingsGroup` 与 `UIViewController (CYLSettingsSection)` 在 Swift 中实现（`Swift/UIViewController+CYLSettingsSection.swift`
 *      以及 `Swift/CYLSettingsDemoRows*.swift` 中的各行，所有名称与 selector 不变），由下面导入的 Swift 生成接口（`CYLSwiftInterface.h`）声明。
 *      滚动隐藏模拟位于 `Swift/UIViewController+CYLScrollHideSimulation.swift`。`CYLSettingsSection` 改为宏（原为 extern 常量），名称与值不变
 *      （docs/Swift-Migration.md，第 32、33 步）。
 */
#import "CYLSwiftInterface.h"
