//
//  UIView+CYLUtils.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * FIX: issue #535
 * [EN] View helpers used by both Core and CYLBadgeView. `-cyl_setHidden:` comes from `UIView+CYLTabBarControllerExtention.h`, `-cyl_isInvisiable` and `-cyl_canNotResponseEvent` from `UIView+CYLBadgeExtention.h`; both import this header.
 * [CN] Core 与 CYLBadgeView 共用的视图方法。`-cyl_setHidden:` 来自 `UIView+CYLTabBarControllerExtention.h`，`-cyl_isInvisiable`、`-cyl_canNotResponseEvent` 来自 `UIView+CYLBadgeExtention.h`，二者都会导入本头文件。
 */

#import <UIKit/UIKit.h>
#import "CYLSwiftInterface.h"
#import "NSObject+CYLUtils.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Implemented in Swift (`CYLUtils/Swift/UIView+CYLUtils.swift`). Objective-C callers get its declarations, with their
 *      documentation, from the generated Swift interface imported above (`CYLSwiftInterface.h`); nothing is declared twice
 *      (docs/Swift-Migration.md).
 * [CN] 在 Swift 中实现（`CYLUtils/Swift/UIView+CYLUtils.swift`）。Objective-C 调用方从上面导入的 Swift 生成接口（`CYLSwiftInterface.h`）获得
 *      声明及其文档；不重复声明（docs/Swift-Migration.md）。
 */

NS_ASSUME_NONNULL_END
