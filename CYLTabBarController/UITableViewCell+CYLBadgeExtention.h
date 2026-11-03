//
//  UITableViewCell+CYLBadgeExtention.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

// CYLBadgeAnimationType. The badge headers are in CYLBadgeView/ (#535): this path works in the source tree (SPM clients,
// Xcode) and flattened (CocoaPods). 角标头文件位于 CYLBadgeView/（#535），该写法在源码目录与 CocoaPods 展平后都能找到。
#if __has_include("CYLBadgeView/CYLBadgeProtocol.h")
#import "CYLBadgeView/CYLBadgeProtocol.h"
#else
#import "CYLBadgeProtocol.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Row height that leaves room around the icon for its badge.
 * [CN] 行高：为图标四周的角标留出空间。
 */
FOUNDATION_EXTERN const CGFloat CYLBadgeRowHeight;

/*!
 * [EN] Badge samples shared by all the example apps: every badge style and animation, one per row.
 *      The icon is `cyl_badge_sample_icon` in the library's resource bundle (`CYLResourceBundle()`).
 * [CN] 所有示例工程共用的角标样例：每行一种角标样式或动画。图标为本库资源包（`CYLResourceBundle()`）中的 `cyl_badge_sample_icon`。
 */
@interface UITableViewCell (CYLBadgeExtention)

/*!
 * [EN] Shows the icon in the cell and a badge on it. Style and animation change with the row, so a table lists them all.
 * [CN] 在 cell 上显示图标及其角标，样式和动画随行号变化。
 */
- (void)cyl_showBadgeForRow:(NSInteger)row;

/*!
 * [EN] Title of the badge sample shown on `row`, followed by the core API that produces the effect, e.g.
 *      "20. Number (cyl_showBadgeValue:)" or "6. Rotation (forever) (cyl_rotationAnimationWithDuration:)".
 * [CN] 第 `row` 行角标样例的标题，后面附上实现该效果的核心 API，例如“20. 数字 (cyl_showBadgeValue:)”。
 */
+ (NSString *)cyl_badgeTitleForRow:(NSInteger)row;

/*!
 * [EN] Number of different badge samples.
 * [CN] 角标样例的种数。
 */
+ (NSInteger)cyl_badgeStyleCount;

@end

/*!
 * [EN] A badge on the navigation bar, adding the bar button when there is none.
 * [CN] 导航栏上的角标，没有按钮时先添加按钮。
 */
@interface UIViewController (CYLNavigationBadge)

/*!
 * [EN] Shows `value` (@"" for a red dot) with `animationType` and `backgroundColor` (nil: the default, see
 *      `CYLBadgeAppearance`) on `navigationItem.rightBarButtonItem`. When there is no right button, a bell button (a
 *      "Badge" text button before iOS 13) is added first, with no action: set `target` / `action` on the returned item
 *      to handle taps. Call it from `-viewDidLoad` or later; the badge appears once the bar button is laid out.
 *
 *          [self cyl_showNavigationBadgeValue:@"new" animationType:CYLBadgeAnimationTypeShake
 *                             backgroundColor:UIColor.cyl_randomColor];
 *          // Swift
 *          cyl_showNavigationBadge(value: "new", animationType: .shake, backgroundColor: .cyl_randomColor)
 *
 * [CN] 在 `navigationItem.rightBarButtonItem` 上显示角标：文字为 `value`（传 @"" 为红点），动画为 `animationType`，背景色为
 *      `backgroundColor`（传 nil 使用默认颜色，见 `CYLBadgeAppearance`）。没有右侧按钮时先添加一个铃铛按钮（iOS 13 以下为文字
 *      “Badge”），该按钮没有点击事件，可给返回的按钮设置 `target` / `action`。在 `-viewDidLoad` 或之后调用；按钮完成布局后显示角标。
 *      示例见上。
 *
 * @return [EN] The right bar button item that shows the badge. [CN] 显示角标的右侧按钮。
 */
- (UIBarButtonItem *)cyl_showNavigationBadgeValue:(NSString *)value
                                    animationType:(CYLBadgeAnimationType)animationType
                                  backgroundColor:(nullable UIColor *)backgroundColor
    NS_SWIFT_NAME(cyl_showNavigationBadge(value:animationType:backgroundColor:));

@end

/*!
 * [EN] Table of every badge sample, one per row. Tap a row to clear its badge; the tap also simulates a memory warning
 *      (`+[CYLTabBarController cyl_simulateMemoryWarning]`) and logs the tab bar's state afterwards.
 * [CN] 列出全部角标样例的列表，点击一行清除该行角标；同时模拟内存警告（`+[CYLTabBarController cyl_simulateMemoryWarning]`），
 *      并输出之后的 TabBar 状态。
 */
@interface CYLBadgeHelperTableViewController : UITableViewController

/*!
 * [EN] Section 0 holds the settings rows (`CYLSettingsSection`: language, memory warning); the badge samples are in section 1.
 *      Called after a badge row is tapped (its badge cleared), e.g. to push a page; the row is `indexPath.row`.
 * [CN] 第 0 组只有一行，为语言设置（`-cyl_languageCellForTableView:`）；角标样例在第 1 组。点击角标行（并清除角标）后调用，
 *      例如用于 push 新页面；行号为 `indexPath.row`。
 */
@property (nonatomic, copy, nullable) void (^didSelectRowHandler)(NSIndexPath *indexPath);

@end

@interface UIViewController (CYLBadgeExtention)

/*!
 * [EN] Adds a `CYLBadgeHelperTableViewController` as a child that fills this view controller's view.
 * [CN] 添加一个铺满当前视图的 `CYLBadgeHelperTableViewController` 子控制器。
 */
- (void)cyl_addBadgeHelperTable;

@end

NS_ASSUME_NONNULL_END
