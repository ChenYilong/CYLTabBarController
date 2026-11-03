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
 *      (`-cyl_languageCellForTableView:`), row 1 the memory warning check (`-cyl_memoryWarningCellForTableView:`), then
 *      the in-place tab item updates (`-cyl_tabBarItemUpdateCellForTableView:row:`): title, icon, network icon, all network icons,
 *      GIF icon, all titles.
 * [CN] 列表顶部设置分组的 section：第 0 行为语言设置（`-cyl_languageCellForTableView:`），第 1 行为内存警告检查
 *      （`-cyl_memoryWarningCellForTableView:`），之后是原地更新 Tab 的若干行（`-cyl_tabBarItemUpdateCellForTableView:row:`）：标题、图标、网络图标、所有网络图标、GIF 图标、所有标题。
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
 * [EN] Deselects the row and runs it: the language picker, the memory warning check or the tab item update.
 * [CN] 取消选中并执行该行：语言选择、内存警告检查或更新 Tab。
 */
- (void)cyl_didSelectSettingsRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView;

@end

NS_ASSUME_NONNULL_END
