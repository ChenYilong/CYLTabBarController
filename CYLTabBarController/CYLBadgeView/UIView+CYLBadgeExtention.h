/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>
// FIX: issue #535 — shared with Core through CYLUtils. 通过 CYLUtils 与 Core 共用。
#if __has_include(<CYLUtilsKit/UIView+CYLUtils.h>)
#import <CYLUtilsKit/UIView+CYLUtils.h>
#elif __has_include("../CYLUtils/UIView+CYLUtils.h")
#import "../CYLUtils/UIView+CYLUtils.h"
#else
#import "UIView+CYLUtils.h"
#endif
#import "CYLBadgeProtocol.h"
/*!
 * [EN] `UIView (CYLBadgeExtention)` (the `CYLBadgeProtocol` conformance) and `CYLBadgeAccessibilityDescription()` are Swift since docs/Swift-Migration.md step 115 (phase ③, group A of docs/Swift-Migration-Phase3.md): Objective-C
 *      sees it through the generated Swift interface (`CYLSwiftInterface.h`), with the same names.
 * [CN] `UIView (CYLBadgeExtention)` (the `CYLBadgeProtocol` conformance) and `CYLBadgeAccessibilityDescription()` are 自第 115 步（第 ③ 阶段 A 组）起为 Swift：Objective-C 通过生成的 Swift 接口（`CYLSwiftInterface.h`）看到它，名称不变。
 */




#import "CYLBadgeSwiftInterface.h"

/*!
 * `noexcept` in C++: the declarations of CYLTabBarController-Swift.h (functions implemented in Swift with @_cdecl) carry
 * it, and Objective-C++ files that import both headers fail to compile when the two declarations differ.
 */
#ifndef CYL_NOEXCEPT
#if defined(__cplusplus)
#define CYL_NOEXCEPT noexcept
#else
#define CYL_NOEXCEPT
#endif
#endif
