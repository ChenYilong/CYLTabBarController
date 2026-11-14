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
 * [EN] Row height that leaves room around the icon for its badge (a macro; it was an extern constant, same name and value).
 * [CN] 行高：为图标四周的角标留出空间（宏；原为 extern 常量，名称与值不变）。
 */
#ifndef __swift__
#define CYLBadgeRowHeight ((CGFloat)60)
#endif

/*!
 * [EN] `UITableViewCell (CYLBadgeExtention)`, `CYLBadgeHelperTableViewController` and `-[UIViewController cyl_addBadgeHelperTable]`
 *      are implemented in Swift (`Swift/UITableViewCell+CYLBadgeExtention.swift`, every name and selector kept) and declared by
 *      the generated Swift interface (`CYLSwiftInterface.h`), imported at the end of this header. The method below stays
 *      declared here: its signature has an Objective-C enum of this module (docs/Swift-Migration.md, step 34).
 * [CN] `UITableViewCell (CYLBadgeExtention)`、`CYLBadgeHelperTableViewController` 与 `-[UIViewController cyl_addBadgeHelperTable]` 在
 *      Swift 中实现（`Swift/UITableViewCell+CYLBadgeExtention.swift`，所有名称与 selector 不变），由本头文件末尾导入的 Swift 生成接口
 *      （`CYLSwiftInterface.h`）声明。下面的方法仍在此声明：其签名中含本模块的 Objective-C 枚举（docs/Swift-Migration.md，第 34 步）。
 */

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

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
