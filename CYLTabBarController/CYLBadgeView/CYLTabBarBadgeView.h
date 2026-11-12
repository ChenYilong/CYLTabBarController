//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
#import <UIKit/UIKit.h>
#import "CYLSwiftInterface.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] The default badge font (bold 9 pt), a macro for Objective-C callers.
 * [CN] 默认角标字体（9pt 粗体），供 Objective-C 调用方使用的宏。
 */
#define kCYLBadgeDefaultFont ([UIFont boldSystemFontOfSize:9])

/*!
 * [EN] `CYLTabBarBadgeView` and the `CYLBadgeTextDisplaying` protocol are implemented in Swift (`CYLBadgeView/Swift/CYLTabBarBadgeView.swift`). Objective-C callers get the declarations, with their
 *      documentation, from the generated Swift interface (`CYLSwiftInterface.h`), as a class cannot be declared twice
 *      (docs/Swift-Migration.md).
 * [CN] `CYLTabBarBadgeView` 与 `CYLBadgeTextDisplaying` 协议在 Swift 中实现（`CYLBadgeView/Swift/CYLTabBarBadgeView.swift`）。Objective-C 调用方从 Swift 生成接口（`CYLSwiftInterface.h`）获得声明及其
 *      文档，因为一个类不能声明两次（docs/Swift-Migration.md）。
 */

NS_ASSUME_NONNULL_END
