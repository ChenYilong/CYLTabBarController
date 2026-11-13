//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [CN] FIX: issue #535 — shared with CYLBadgeView through CYLUtils. 通过 CYLUtils 与 CYLBadgeView 共用。
// [EN] FIX: issue #535 — shared with CYLBadgeView through CYLUtils.
#if __has_include("CYLUtils/UIView+CYLUtils.h")
#import "CYLUtils/UIView+CYLUtils.h"
#else
#import "UIView+CYLUtils.h"
#endif
#import <Foundation/Foundation.h>
#import "CYLConstants.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] `UIView (CYLTabBarControllerExtention)`, `(CYLTabBarControllerExtentionDeprecated)` and `(CYLTabBarMetrics)` are implemented
 *      in Swift (`Swift/UIView+CYLTabBarControllerExtention.swift`, docs/Swift-Migration.md, step 25) and declared by the generated
 *      Swift interface imported at the end of this header. Every selector and Swift name is kept.
 * [CN] `UIView (CYLTabBarControllerExtention)`、`(CYLTabBarControllerExtentionDeprecated)` 与 `(CYLTabBarMetrics)` 在 Swift 中实现
 *      （`Swift/UIView+CYLTabBarControllerExtention.swift`，docs/Swift-Migration.md，第 25 步），由本头文件末尾导入的 Swift 生成接口声明。
 *      保留所有 selector 与 Swift 名称。
 */

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
