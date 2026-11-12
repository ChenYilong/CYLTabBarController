/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CYLSwiftInterface.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Degrees to radians and back.
 * [CN] 角度与弧度互相转换。
 */
#define CYL_DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define CYL_RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

/*!
 * [EN] `CYLAxis` and `CAAnimation (CYLBadgeExtention)` are implemented in Swift (`CYLBadgeView/Swift/CAAnimation+CYLBadgeExtention.swift`). Objective-C callers get the declarations, with their
 *      documentation, from the generated Swift interface (`CYLSwiftInterface.h`); this header keeps only the macros
 *      (docs/Swift-Migration.md).
 * [CN] `CYLAxis` 与 `CAAnimation (CYLBadgeExtention)` 在 Swift 中实现（`CYLBadgeView/Swift/CAAnimation+CYLBadgeExtention.swift`）。Objective-C 调用方从 Swift 生成接口（`CYLSwiftInterface.h`）获得声明及其
 *      文档；本头文件只保留宏（docs/Swift-Migration.md）。
 */

NS_ASSUME_NONNULL_END

