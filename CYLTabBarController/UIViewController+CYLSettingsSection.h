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
 *      row 8 lists the scroll hiding simulations in an action sheet (`-cyl_presentScrollHideSimulationMenu`, issue #13),
 *      then the in-place tab item updates (`-cyl_tabBarItemUpdateCellForTableView:row:`): title, icon, network icon,
 *      all network icons, all local icons, GIF icon, all titles, replace neighboring tabs.
 * [CN] 列表顶部设置分组的 section：第 0 行为语言设置（`-cyl_languageCellForTableView:`），第 1 行为内存警告检查
 *      （`-cyl_memoryWarningCellForTableView:`），第 2 行切换所有 Tab 的标题偏移（`CYLTabBarController.titlePositionAdjustment`，
 *      issue #475），第 3 行切换 `tabBar.standardAppearance` 主题（液态玻璃与扁平样式共用），
 *      第 4 行切换缓存的登录状态（`cyl_loggedIn`），并列出需要登录的 Tab（issue #19），
 *      第 5 行显示 PlusButton 的可点击区域，并用滑块按倍数扩大（issue #91），
 *      第 6 行按不含 PlusButton 的下标选中下一个 Tab（`cyl_selectedIndexIgnoringPlusButton`，issue #515），
 *      第 7 行切换滚动时 TabBar 缩小或隐藏的方式（`cyl_tabBarMinimizeBehavior`，issue #13），
 *      第 8 行用操作表列出滚动隐藏的模拟（`-cyl_presentScrollHideSimulationMenu`，issue #13），之后是原地更新 Tab 的若干行
 *      （`-cyl_tabBarItemUpdateCellForTableView:row:`）：标题、图标、网络图标、所有网络图标、所有本地图标、GIF 图标、所有标题、替换相邻 Tab 的页面。
 */
FOUNDATION_EXTERN const NSInteger CYLSettingsSection;

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
 *      appearance theme, the login state or the tab item update.
 * [CN] 取消选中并执行该行：语言选择、内存警告检查、切换到下一个标题偏移、下一个 appearance 主题、登录状态或更新 Tab。
 */
- (void)cyl_didSelectSettingsRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView;

@end

/*!
 * [EN] Scroll hiding (issue #13): simulations of the interruptions the tab bar must come back from (alerts, modals,
 *      push / pop, tab switch, app lifecycle, memory warning, overlay window, keyboard, share sheet, scrolling in code,
 *      the app hiding the bar, accessibility and power state changes, rotation). Demo helpers: each turns scroll hiding
 *      on and fires after 1.5 s. A grouped list shows them as a section; the settings section has one row that lists
 *      them all in an action sheet (`CYLSettingsSection`, every demo).
 * [CN] 滚动隐藏（issue #13）：模拟 TabBar 必须从中恢复显示的各种意外情况（弹框、模态页面、push / pop、切换 Tab、App 生命周期、内存警告、
 *      浮层窗口、键盘、分享面板、代码滚动、App 自己隐藏 TabBar、辅助功能与电源状态变化、旋转）。演示辅助方法：每项先开启滚动隐藏，
 *      1.5 秒后触发。分组列表以一个 section 显示；设置分组中有一行，用操作表列出全部模拟（`CYLSettingsSection`，所有 Demo）。
 */
@interface UIViewController (CYLScrollHideSimulation)
/// [EN] Number of simulations. [CN] 模拟的数量。
- (NSInteger)cyl_scrollHideSimulationRowCount;
/// [EN] The cell of simulation `row`. [CN] 第 `row` 个模拟的 cell。
- (UITableViewCell *)cyl_scrollHideSimulationCellForTableView:(UITableView *)tableView row:(NSInteger)row;
/// [EN] Runs simulation `row` after 1.5 s. [CN] 1.5 秒后执行第 `row` 个模拟。
- (void)cyl_didSelectScrollHideSimulationRow:(NSInteger)row;
/// [EN] Lists every simulation in an action sheet. [CN] 用操作表列出全部模拟。
- (void)cyl_presentScrollHideSimulationMenu;
@end

NS_ASSUME_NONNULL_END
