//
//  UIViewController+CYLMemoryWarning.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CYLTabBarController;

/*!
 * [EN] Simulates a memory warning for `tabBarController` (`+[CYLTabBarController cyl_simulateMemoryWarningForTabBarController:]`)
 *      and returns what happened to each tab, one line per tab ("Messages: unloaded", "Home: kept: selected"…), in the
 *      app's language: the message of `-cyl_simulateMemoryWarningAndShowResult`, for any UI (e.g. `CYLTabBarHostView`).
 * [CN] 对 `tabBarController` 模拟内存警告（`+[CYLTabBarController cyl_simulateMemoryWarningForTabBarController:]`），
 *      并返回每个 Tab 的结果，每个 Tab 一行（如「消息: 已卸载」「首页: 保留：当前选中」），使用 App 语言：即
 *      `-cyl_simulateMemoryWarningAndShowResult` 弹窗的内容，可用于任何界面（例如 `CYLTabBarHostView`）。
 */
FOUNDATION_EXTERN NSString *CYLSimulateMemoryWarningReport(CYLTabBarController *_Nullable tabBarController);

/*!
 * [EN] A memory warning check for `unloadsUnselectedViewsOnMemoryWarning` (issue #426), in every tab bar style: a table
 *      row, and the action that simulates the warning and shows what happened to each tab. Part of the settings section,
 *      see `UIViewController+CYLSettingsSection.h`.
 * [CN] `unloadsUnselectedViewsOnMemoryWarning`（issue #426）的内存警告检查，适用于所有 TabBar 样式：一行 cell，以及模拟内存警告
 *      并显示每个 Tab 结果的操作。属于设置分组，见 `UIViewController+CYLSettingsSection.h`。
 */
@interface UIViewController (CYLMemoryWarning)

/*!
 * [EN] Cell of the memory warning row, in the app's language.
 * [CN] 内存警告行的 cell，使用 App 语言。
 */
- (UITableViewCell *)cyl_memoryWarningCellForTableView:(UITableView *)tableView;

/*!
 * [EN] Simulates a memory warning for this view controller's tab bar controller
 *      (`+[CYLTabBarController cyl_simulateMemoryWarningForTabBarController:]`), then shows an alert that lists, for each
 *      tab, whether its view was unloaded and why not. Select an unloaded tab afterwards: its `-viewDidLoad` runs again.
 * [CN] 对当前 TabBarController 模拟内存警告（`+[CYLTabBarController cyl_simulateMemoryWarningForTabBarController:]`），
 *      然后弹窗列出每个 Tab 的视图是否被卸载及未卸载的原因。之后切换到已卸载的 Tab，会重新执行 `-viewDidLoad`。
 */
- (void)cyl_simulateMemoryWarningAndShowResult;

@end

NS_ASSUME_NONNULL_END
