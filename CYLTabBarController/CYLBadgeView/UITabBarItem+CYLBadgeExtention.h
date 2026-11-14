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
 * [EN] `UITabBarItem (CYLBadgeExtention)` is implemented in Swift (`CYLBadgeView/Swift/UITabBarItem+CYLBadgeExtention.swift`,
 *      docs/Swift-Migration.md, step 23): every badge call goes to the badge host of the item's tab button, in both Liquid
 *      Glass layers. The conformance is declared here; the protocol's members are internal in Swift, so the generated header
 *      does not import the umbrella header. `-cyl_moveBadgeToCurrentTabButtonIfNeeded` comes from the generated interface.
 * [CN] `UITabBarItem (CYLBadgeExtention)` 在 Swift 中实现（`CYLBadgeView/Swift/UITabBarItem+CYLBadgeExtention.swift`，
 *      docs/Swift-Migration.md，第 23 步）：每个角标调用都转给 item 的 Tab 按钮的角标宿主，并作用于液态玻璃的两个图层。遵守关系声明在
 *      这里；协议成员在 Swift 中为 internal，生成的头文件因此不会导入伞头文件。`-cyl_moveBadgeToCurrentTabButtonIfNeeded` 来自生成的接口。
 */
@interface UITabBarItem (CYLBadgeExtention)<CYLBadgeProtocol>
@end

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
