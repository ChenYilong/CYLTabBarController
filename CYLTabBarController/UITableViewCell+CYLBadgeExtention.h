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
 * [EN] `UIViewController (CYLNavigationBadge)` (`-cyl_showNavigationBadgeValue:animationType:backgroundColor:`) is Swift since docs/Swift-Migration.md step 115 (phase ③, group A of docs/Swift-Migration-Phase3.md): Objective-C
 *      sees it through the generated Swift interface (`CYLSwiftInterface.h`), with the same names.
 * [CN] `UIViewController (CYLNavigationBadge)` (`-cyl_showNavigationBadgeValue:animationType:backgroundColor:`) is 自第 115 步（第 ③ 阶段 A 组）起为 Swift：Objective-C 通过生成的 Swift 接口（`CYLSwiftInterface.h`）看到它，名称不变。
 */


NS_ASSUME_NONNULL_END

#import "CYLTabBarControllerSwiftInterface.h"
