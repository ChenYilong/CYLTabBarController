/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "UIView+CYLBadgeExtention.h"
#import "CYLBadgeProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] `UIBarButtonItem (CYLBadgeExtention)` is implemented in Swift (`CYLBadgeView/Swift/UIBarButtonItem+CYLBadgeExtention.swift`,
 *      docs/Swift-Migration.md, step 24): the badge goes on the image or title inside the item's button, and on iOS 26+ with
 *      Liquid Glass it is the system badge. The conformance is declared here; the protocol's members are internal in Swift,
 *      so the generated header does not import the umbrella header. For the same reason
 *      `-cyl_showBadgeValue:animationType:backgroundColor:` (it takes `CYLBadgeAnimationType`) is declared below.
 * [CN] `UIBarButtonItem (CYLBadgeExtention)` 在 Swift 中实现（`CYLBadgeView/Swift/UIBarButtonItem+CYLBadgeExtention.swift`，
 *      docs/Swift-Migration.md，第 24 步）：角标放在 item 按钮内的图片或标题上，iOS 26+ 液态玻璃下使用系统角标。遵守关系声明在这里；
 *      协议成员在 Swift 中为 internal，生成的头文件因此不会导入伞头文件。`-cyl_showBadgeValue:animationType:backgroundColor:`（参数为 `CYLBadgeAnimationType`）也因此在下方声明。
 */
@interface UIBarButtonItem (CYLBadgeExtention)<CYLBadgeProtocol>

/*!
 * [EN] Same as `-cyl_showBadgeValue:animationType:`, with the badge's background color set first (nil keeps the
 *      current one). Safe in `-viewDidLoad`, before the bar button is laid out:
 *
 *          [self.navigationItem.rightBarButtonItem cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeShake
 *                                                    backgroundColor:UIColor.cyl_randomColor];
 *          // Swift
 *          navigationItem.rightBarButtonItem?.cyl_showBadgeValue("", animationType: .shake, backgroundColor: .cyl_randomColor)
 *
 * [CN] 同 `-cyl_showBadgeValue:animationType:`，并先设置角标背景色（传 nil 保持当前颜色）。可在 `-viewDidLoad` 中、bar button
 *      完成布局之前调用（示例见上）。
 */
- (void)cyl_showBadgeValue:(NSString *)value
             animationType:(CYLBadgeAnimationType)animationType
           backgroundColor:(nullable UIColor *)backgroundColor;

@end

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
