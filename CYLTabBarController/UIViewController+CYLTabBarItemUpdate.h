//
//  UIViewController+CYLTabBarItemUpdate.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Issue #601: rows that try the in-place tab item updates of `CYLTabBarController`, in every tab bar style, on the tab
 *      of this view controller (no new tab bar, no new view controllers). Each row switches one thing, and back on a second
 *      tap: the title, the icon (a view of ours), an icon downloaded from the network, an animated GIF icon, and the titles
 *      of every tab. Part of the settings section, see `UIViewController+CYLSettingsSection.h`.
 * [CN] Issue #601：试用 `CYLTabBarController` 原地更新 Tab 的若干行，适用于所有 TabBar 样式，作用于当前页面所在的 Tab（不新建 TabBar、
 *      不重新设置子控制器）。每行切换一项，再点一次恢复：标题、图标（我们自己的视图）、从网络下载的图标、GIF 动图图标、所有 Tab 的标题。
 *      属于设置分组，见 `UIViewController+CYLSettingsSection.h`。
 */
@interface UIViewController (CYLTabBarItemUpdate)

/*!
 * [EN] Number of the rows.
 * [CN] 行数。
 */
- (NSInteger)cyl_tabBarItemUpdateRowCount;

/*!
 * [EN] Cell of row `row`, in the app's language.
 * [CN] 第 `row` 行的 cell，使用 App 语言。
 */
- (UITableViewCell *)cyl_tabBarItemUpdateCellForTableView:(UITableView *)tableView row:(NSInteger)row;

/*!
 * [EN] Runs row `row`: switches its change on this view controller's tab, or back.
 * [CN] 执行第 `row` 行：对当前页面所在的 Tab 应用该项更改，或恢复。
 */
- (void)cyl_didSelectTabBarItemUpdateRow:(NSInteger)row;

@end

NS_ASSUME_NONNULL_END
