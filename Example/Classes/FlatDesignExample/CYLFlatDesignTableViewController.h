//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CYLFlatDesignTableViewController : UITableViewController

@end

/*!
 * [EN] The tab bar demo rows, one table for every style: the Liquid Glass pages and the FlatDesign page show the same
 *      rows (show / hide the tab bar, item layout and background, tab bar height, comparisons and pushes, the
 *      `cyl_pop` / `cyl_push` demo). A row the current style does not support says so in its subtitle and, when tapped,
 *      in an alert.
 * [CN] TabBar 演示行，所有样式共用一个列表：液态玻璃页面与扁平样式页面显示相同的行（显示 / 隐藏 TabBar、item 布局与背景、TabBar 高度、
 *      对比与 push、`cyl_pop` / `cyl_push` 演示）。当前样式不支持的行会在副标题中注明，点击时弹窗说明。
 */
@interface UIViewController (CYLTabBarDemoSection)

/// [EN] Number of the tab bar demo rows. [CN] TabBar 演示行的行数。
- (NSInteger)cyl_tabBarDemoRowCount;
/// [EN] Cell of the tab bar demo row `row`. [CN] 第 `row` 个 TabBar 演示行的 cell。
- (UITableViewCell *)cyl_tabBarDemoCellForTableView:(UITableView *)tableView row:(NSInteger)row;
/// [EN] Runs the tab bar demo row `row`; `tableView` may be nil. [CN] 执行第 `row` 个 TabBar 演示行；`tableView` 可为 nil。
- (void)cyl_didSelectTabBarDemoRow:(NSInteger)row inTableView:(nullable UITableView *)tableView;

@end

/*!
 * [EN] The demo rows of every page, Liquid Glass and FlatDesign alike, grouped by function into sections with headers:
 *      general, tab bar appearance, updating tabs in place, tab pages / selection / login, the plus button, navigation.
 *      They gather the shared settings rows (`UIViewController+CYLSettingsSection.h`) and the tab bar demo rows above.
 *      A page shows these `-cyl_demoSectionCount` sections first, then its own rows (e.g. the badge samples).
 * [CN] 所有页面（液态玻璃与扁平样式相同）的演示行，按功能分组为带标题的 section：通用、TabBar 外观、原地更新 Tab、Tab 页面 / 选中 /
 *      登录、PlusButton、跳转与对比。包括共用的设置行（`UIViewController+CYLSettingsSection.h`）和上面的 TabBar 演示行。页面先显示这
 *      `-cyl_demoSectionCount` 个 section，然后是自己的行（如角标样例）。
 */
@interface UIViewController (CYLDemoSections)

- (NSInteger)cyl_demoSectionCount;
- (NSInteger)cyl_demoRowCountInSection:(NSInteger)section;
- (nullable NSString *)cyl_demoTitleForSection:(NSInteger)section;
- (UITableViewCell *)cyl_demoCellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath;
- (void)cyl_demoDidSelectRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView;

@end

NS_ASSUME_NONNULL_END
