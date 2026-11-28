//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
// [CN] FIX: issue #535 — shared with CYLBadgeView through CYLUtils. 通过 CYLUtils 与 CYLBadgeView 共用。
// [EN] FIX: issue #535 — shared with CYLBadgeView through CYLUtils.
#if __has_include("CYLUtils/UIBarItem+CYLUtils.h")
#import "CYLUtils/UIBarItem+CYLUtils.h"
#else
#import "UIBarItem+CYLUtils.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] `UITabBarItem (CYLTabBarControllerExtention)` and `UITabBarAppearance (CYLTabBarControllerExtention)` are implemented in
 *      Swift (`Swift/UITabBarItem+CYLTabBarControllerExtention.swift`); Objective-C callers get the declarations, with their
 *      documentation, from the generated Swift interface imported at the end of this header (docs/Swift-Migration.md).
 * [CN] `UITabBarItem (CYLTabBarControllerExtention)` 与 `UITabBarAppearance (CYLTabBarControllerExtention)` 在 Swift 中实现
 *      （`Swift/UITabBarItem+CYLTabBarControllerExtention.swift`）；Objective-C 调用方从本头文件末尾导入的 Swift 生成接口获得声明及其文档
 *      （docs/Swift-Migration.md）。
 */

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
