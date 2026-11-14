//
//  UIViewController+CYLSettingsSection.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

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
FOUNDATION_EXTERN const NSInteger CYLSettingsSection;

/*!
 * [EN] The settings rows by function, for a list that shows them in groups (one table section per group, like Settings):
 *      the ObjC demo and the Swift demo (`Example-Shared/CYLSettingsDemoTableViewController.swift`) use the same groups.
 * [CN] 按功能划分的设置行，供分组显示的列表使用（每组一个 section，类似系统设置）：ObjC Demo 与 Swift Demo
 *      （`Example-Shared/CYLSettingsDemoTableViewController.swift`）使用相同的分组。
 */
typedef NS_ENUM(NSInteger, CYLSettingsGroup) {
    /*!
     * [EN] Language, memory warning, and rows a newer version adds. [CN] 语言、内存警告，以及新版本新增的行。
     */
    CYLSettingsGroupGeneral,
    /*!
     * [EN] Title offset, standardAppearance, scroll minimize. [CN] 标题偏移、standardAppearance、滚动缩小。
     */
    CYLSettingsGroupTabBarAppearance,
    /*!
     * [EN] In-place tab item updates (#601). [CN] 原地更新 Tab（#601）。
     */
    CYLSettingsGroupTabBarItemUpdate,
    /*!
     * [EN] Replace pages (#481), selectedIndex (#515), login (#19). [CN] 替换页面、selectedIndex、登录。
     */
    CYLSettingsGroupPagesSelectionLogin,
    /*!
     * [EN] The plus button's touchable area (#91), an image set later. [CN] PlusButton 可点击区域（#91）、之后才加载的图片。
     */
    CYLSettingsGroupPlusButton,
    /*!
     * [EN] Tap animation, sound, long press, swipe (#535, #118). [CN] 点击动画、声音、长按、滑动。
     */
    CYLSettingsGroupTabInteractions,
    /*!
     * [EN] No base class, CYLUtils helpers (#535). [CN] 无需继承基类、CYLUtils 工具方法。
     */
    CYLSettingsGroupHelpers,
    /*!
     * [EN] A tab bar controller from a configuration file, and the simulated failures. [CN] 由配置文件创建 TabBarController，以及模拟意外情况。
     */
    CYLSettingsGroupConfiguration,
};

/*!
 * [EN] The settings section in three calls, so a list adds it with one line in each data source and delegate method:
 *
 *          numberOfSections                  → your sections + 1
 *          numberOfRows      (CYLSettingsSection) → [self cyl_settingsRowCount]
 *          cellForRow        (CYLSettingsSection) → [self cyl_settingsCellForTableView:tableView atIndexPath:indexPath]
 *          didSelectRow      (CYLSettingsSection) → [self cyl_didSelectSettingsRowAtIndexPath:indexPath inTableView:tableView]
 * [CN] 用三个调用提供设置分组，列表在每个数据源 / 代理方法中各加一行即可（见上）。
 */
@interface UIViewController (CYLSettingsSection)

/*!
 * [EN] Number of rows in the settings section.
 * [CN] 设置分组的行数。
 */
- (NSInteger)cyl_settingsRowCount;

/*!
 * [EN] The cell for `indexPath.row` of the settings section.
 * [CN] 设置分组第 `indexPath.row` 行的 cell。
 */
- (UITableViewCell *)cyl_settingsCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath;

/*!
 * [EN] Deselects the row and runs it: the language picker, the memory warning check, the next title offset, the next
 *      appearance theme, the login state, the skin picker or the tab item update.
 * [CN] 取消选中并执行该行：语言选择、内存警告检查、切换到下一个标题偏移、下一个 appearance 主题、登录状态、换肤选择器或更新 Tab。
 */
- (void)cyl_didSelectSettingsRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView;

#pragma mark - Groups

/*!
 * [EN] The groups that have rows, in display order (`CYLSettingsGroup` values).
 * [CN] 有行的分组，按显示顺序排列（`CYLSettingsGroup` 的值）。
 */
- (NSArray<NSNumber *> *)cyl_settingsGroups NS_SWIFT_NAME(cyl_settingsGroups());

/*!
 * [EN] The localized title of `group`.
 * [CN] `group` 的本地化标题。
 */
- (NSString *)cyl_titleForSettingsGroup:(CYLSettingsGroup)group NS_SWIFT_NAME(cyl_title(for:));

/*!
 * [EN] The settings rows of `group`, in display order. Every settings row is in exactly one group; a row this version does
 *      not place goes to `CYLSettingsGroupGeneral`.
 * [CN] `group` 中的设置行，按显示顺序排列。每个设置行只属于一个分组；本版本未归类的行放入 `CYLSettingsGroupGeneral`。
 */
- (NSArray<NSNumber *> *)cyl_settingsRowsInGroup:(CYLSettingsGroup)group NS_SWIFT_NAME(cyl_settingsRows(in:));

/*!
 * [EN] The cell of settings row `row`, for any section of any table view (a grouped list).
 * [CN] 设置行 `row` 的 cell，可用于任意列表的任意 section（分组列表）。
 */
- (UITableViewCell *)cyl_settingsCellForTableView:(UITableView *)tableView row:(NSInteger)row NS_SWIFT_NAME(cyl_settingsCell(for:row:));

/*!
 * [EN] Runs settings row `row`, without touching a table view: a grouped list deselects and reloads its own rows after it
 *      (e.g. a checkmark or the current value changed).
 * [CN] 执行设置行 `row`，不操作列表：分组列表在其后自行取消选中并刷新（例如勾号或当前值已变化）。
 */
- (void)cyl_didSelectSettingsRow:(NSInteger)row NS_SWIFT_NAME(cyl_didSelectSettingsRow(_:));

@end

/*!
 * [EN] `UIViewController (CYLScrollHideSimulation)` (issue #13: the scroll hiding simulations and their self-test) is
 *      implemented in Swift (`Swift/UIViewController+CYLScrollHideSimulation.swift`, every selector kept) and declared by the
 *      generated Swift interface (`CYLSwiftInterface.h`), imported at the end of this header (docs/Swift-Migration.md, step 32).
 * [CN] `UIViewController (CYLScrollHideSimulation)`（issue #13：滚动隐藏模拟及其自测）在 Swift 中实现
 *      （`Swift/UIViewController+CYLScrollHideSimulation.swift`，所有 selector 不变），由本头文件末尾导入的 Swift 生成接口
 *      （`CYLSwiftInterface.h`）声明（docs/Swift-Migration.md，第 32 步）。
 */

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
