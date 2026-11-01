//
//  UITableViewCell+CYLBadgeExtention.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Row height that leaves room around the icon for its badge.
 * [CN] 行高：为图标四周的角标留出空间。
 */
FOUNDATION_EXTERN const CGFloat CYLBadgeRowHeight;

/*!
 * [EN] Badge samples shared by all the example apps: every badge style and animation, one per row.
 *      The icon is read from the app's asset catalog as `DemoIcon`.
 * [CN] 所有示例工程共用的角标样例：每行一种角标样式或动画。图标取 App 资源中的 `DemoIcon`。
 */
@interface UITableViewCell (CYLBadgeExtention)

/*!
 * [EN] Shows the icon in the cell and a badge on it. Style and animation change with the row, so a table lists them all.
 * [CN] 在 cell 上显示图标及其角标，样式和动画随行号变化。
 */
- (void)cyl_showBadgeForRow:(NSInteger)row;

/*!
 * [EN] Title of the badge sample shown on `row`.
 * [CN] 第 `row` 行角标样例的标题。
 */
+ (NSString *)cyl_badgeTitleForRow:(NSInteger)row;

/*!
 * [EN] Number of different badge samples.
 * [CN] 角标样例的种数。
 */
+ (NSInteger)cyl_badgeStyleCount;

@end

/*!
 * [EN] Table of every badge sample, one per row. Tap a row to clear its badge.
 * [CN] 列出全部角标样例的列表，点击一行清除该行角标。
 */
@interface CYLBadgeHelperTableViewController : UITableViewController

@end

@interface UIViewController (CYLBadgeExtention)

/*!
 * [EN] Adds a `CYLBadgeHelperTableViewController` as a child that fills this view controller's view.
 * [CN] 添加一个铺满当前视图的 `CYLBadgeHelperTableViewController` 子控制器。
 */
- (void)cyl_addBadgeHelperTable;

@end

NS_ASSUME_NONNULL_END
