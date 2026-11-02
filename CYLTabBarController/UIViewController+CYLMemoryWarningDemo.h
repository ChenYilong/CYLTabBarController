//
//  UIViewController+CYLMemoryWarningDemo.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Section of the memory warning demo row: a demo table puts it first and shifts its own rows to section 1.
 * [CN] 内存警告演示行所在的 section：示例列表把它放在最前面，自己的行移到 section 1。
 */
FOUNDATION_EXTERN const NSInteger CYLMemoryWarningDemoSection;

/*!
 * [EN] Memory warning demo shared by all the example apps (issue #426, `unloadsUnselectedViewsOnMemoryWarning`), in every
 *      tab bar style. A table adds one section with one row:
 *          numberOfSections            → 2
 *          numberOfRows (demo section) → 1
 *          cellForRow   (demo section) → -cyl_memoryWarningDemoCellForTableView:
 *          didSelectRow (demo section) → -cyl_showMemoryWarningDemo
 * [CN] 所有示例工程共用的内存警告演示（issue #426，`unloadsUnselectedViewsOnMemoryWarning`），适用于所有 TabBar 样式。
 *      列表增加一个只有一行的 section，调用方式见上。
 */
@interface UIViewController (CYLMemoryWarningDemo)

/*!
 * [EN] Cell of the demo row.
 * [CN] 演示行的 cell。
 */
- (UITableViewCell *)cyl_memoryWarningDemoCellForTableView:(UITableView *)tableView;

/*!
 * [EN] Simulates a memory warning for this view controller's tab bar controller
 *      (`+[CYLTabBarController cyl_simulateMemoryWarningForTabBarController:]`), then shows an alert that lists, for each
 *      tab, whether its view was unloaded and why not. Select an unloaded tab afterwards: its `-viewDidLoad` runs again.
 * [CN] 对当前 TabBarController 模拟内存警告（`+[CYLTabBarController cyl_simulateMemoryWarningForTabBarController:]`），
 *      然后弹窗列出每个 Tab 的视图是否被卸载及未卸载的原因。之后切换到已卸载的 Tab，会重新执行 `-viewDidLoad`。
 */
- (void)cyl_showMemoryWarningDemo;

@end

NS_ASSUME_NONNULL_END
