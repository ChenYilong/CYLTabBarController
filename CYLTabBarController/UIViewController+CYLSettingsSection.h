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
 *      row 6 selects the next tab by its index without the plus button (`cyl_selectedIndexIgnoringPlusButton`, issue #515).
 * [CN] 列表顶部设置分组的 section：第 0 行为语言设置（`-cyl_languageCellForTableView:`），第 1 行为内存警告检查
 *      （`-cyl_memoryWarningCellForTableView:`），第 2 行切换所有 Tab 的标题偏移（`CYLTabBarController.titlePositionAdjustment`，
 *      issue #475），第 3 行切换 `tabBar.standardAppearance` 主题（液态玻璃与扁平样式共用），
 *      第 4 行切换缓存的登录状态（`cyl_loggedIn`），并列出需要登录的 Tab（issue #19），
 *      第 5 行显示 PlusButton 的可点击区域，并用滑块按倍数扩大（issue #91），
 *      第 6 行按不含 PlusButton 的下标选中下一个 Tab（`cyl_selectedIndexIgnoringPlusButton`，issue #515）。
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
 * [EN] Deselects the row and runs it: the language picker, the memory warning check, the next title offset, the next appearance theme or the login state.
 * [CN] 取消选中并执行该行：语言选择、内存警告检查、切换到下一个标题偏移、下一个 appearance 主题或登录状态。
 */
- (void)cyl_didSelectSettingsRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView;

@end

NS_ASSUME_NONNULL_END
