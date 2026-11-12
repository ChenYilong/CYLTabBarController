//
//  CYLLocalization.h
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/02/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLSwiftInterface.h"

// FIX: issue #535 — CYLLocalizedString(), CYLResourceBundle(), CYLSetLocalizationLanguage() and the rest of the string
// table live in CYLUtils, shared with CYLBadgeView. 字符串表相关函数位于 CYLUtils，与 CYLBadgeView 共用。
#if __has_include("CYLUtils/CYLLocalizedString.h")
#import "CYLUtils/CYLLocalizedString.h"
#else
#import "CYLLocalizedString.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] `CYLLocalizedTabBarItemsAttributes()` and the `UIView` / `UIViewController` / `UIWindow (CYLLocalization)` categories are implemented in Swift (`Swift/CYLLocalization.swift`); Objective-C callers get the declarations, with their
 *      documentation, from the generated Swift interface (`CYLSwiftInterface.h`) (docs/Swift-Migration.md).
 * [CN] `CYLLocalizedTabBarItemsAttributes()` 与 `UIView` / `UIViewController` / `UIWindow (CYLLocalization)` 类别在 Swift 中实现（`Swift/CYLLocalization.swift`）；Objective-C 调用方从 Swift 生成接口
 *      （`CYLSwiftInterface.h`）获得声明及其文档（docs/Swift-Migration.md）。
 */

NS_ASSUME_NONNULL_END
