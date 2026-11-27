//
//  CYLBadgeSwiftInterface.h
//  CYLBadge
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * [EN] The Objective-C interface of CYLBadge's Swift code: the header Swift generates for the `CYLBadge` module, after CYLUtils' interface (the layer below). It sees nothing above CYLBadge. Written statically, not compiled yet (docs/Animated-Item-Badge.md, step 3).
 * [CN] CYLBadge 的 Swift 代码的 Objective-C 接口：Swift 为 `CYLBadge` 模块生成的头文件，在 CYLUtils（下面一层）的接口之后导入。它看不到 CYLBadge 之上的任何层。 静态编写，尚未编译（docs/Animated-Item-Badge.md，第 3 步）。
 */
// [EN] Not for the SwiftPM C target `CYLTabBarControllerObjC` (-DCYL_OBJC_BASE_TARGET): it sits below the Swift module, which imports it,
//      so it cannot import the Swift module back. [CN] SwiftPM 的 C 目标 `CYLTabBarControllerObjC`（-DCYL_OBJC_BASE_TARGET）不使用：它位于
//      Swift 模块之下，由 Swift 模块导入，不能反过来导入 Swift 模块。
#if defined(CYL_OBJC_BASE_TARGET)
#define CYL_SKIP_SWIFT_INTERFACE 1
#elif defined(__building_module)
#if __building_module(CYLTabBarControllerObjC)
#define CYL_SKIP_SWIFT_INTERFACE 1
#endif
#endif
#if !defined(__swift__) && !defined(CYL_SKIP_SWIFT_INTERFACE)
#if __has_include(<CYLUtilsKit/CYLSwiftInterface.h>)
#import <CYLUtilsKit/CYLSwiftInterface.h>
#else
#import "CYLSwiftInterface.h"
#endif
/*!
 * [EN] Objective-C declarations the generated interface uses and that stay Objective-C for now: first, as the first header that
 *      imports this file may not have seen them (`UIView (CYLBadgeExtention)` adopts `CYLBadgeProtocol` and uses
 *      `CYLBadgeAnimationType`).
 * [CN] 生成的接口所用、目前仍为 Objective-C 的声明：先导入，因为第一个导入本文件的头文件可能还没有看到它们（`UIView (CYLBadgeExtention)`
 *      遵守 `CYLBadgeProtocol` 并使用 `CYLBadgeAnimationType`）。
 */
#if __has_include(<CYLBadge/CYLBadgeProtocol.h>)
#import <CYLBadge/CYLBadgeProtocol.h>
#elif __has_include("CYLBadgeProtocol.h")
#import "CYLBadgeProtocol.h"
#endif
#if defined(SWIFT_PACKAGE)
// [EN] TODO (step 9): as in CYLUtils' interface, until `CYLBadge` is a SwiftPM target of its own. [CN] TODO（第 9 步）：与 CYLUtils 的接口相同，直到 `CYLBadge` 成为独立的 SwiftPM target。
#pragma clang module import CYLTabBarController
#elif __has_include(<CYLBadge/CYLBadge-Swift.h>)
#import <CYLBadge/CYLBadge-Swift.h>
#elif __has_include("CYLBadge-Swift.h")
#import "CYLBadge-Swift.h"
#elif __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
// [EN] The Xcode framework and Carthage build all three layers into one module (`CYLTabBarController.xcodeproj`, docs/Animated-Item-Badge.md, step 10 TODO). [CN] Xcode framework 与 Carthage 把三层编进同一个模块（`CYLTabBarController.xcodeproj`，docs/Animated-Item-Badge.md，第 10 步 TODO）。
#import <CYLTabBarController/CYLTabBarController-Swift.h>
#elif __has_include("CYLTabBarController-Swift.h")
#import "CYLTabBarController-Swift.h"
#endif
#endif
