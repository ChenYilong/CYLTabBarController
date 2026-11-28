//
//  CYLSwiftInterface.h
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * [EN] The Objective-C interface of CYLUtils' Swift code: the header Swift generates for the `CYLUtilsKit` module. CYLUtils is the bottom pod and sees nothing above it, so this file imports no CYLBadge, CYLAnimatedItem or CYLTabBarController header. Never imported while Swift itself compiles (`__swift__`). Built on macOS, 2026-11-29 (docs/Animated-Item-Badge.md, step 3).
 * [CN] CYLUtils 的 Swift 代码的 Objective-C 接口：Swift 为 `CYLUtilsKit` 模块生成的头文件。CYLUtils 是最底层的 pod，看不到上面的任何层，因此本文件不导入 CYLBadge、CYLAnimatedItem 或 CYLTabBarController 的头文件。Swift 自身编译时不导入（`__swift__`）。 已于 2026-11-29 在 macOS 上构建（docs/Animated-Item-Badge.md，第 3 步）。
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
/*!
 * [EN] `Ivar` (a parameter of the `cyl_is<Type>Ivar()` functions) comes from the Objective-C runtime header, which a build
 *      without modules (React Native's) does not import by itself before the generated interface.
 * [CN] `Ivar`（`cyl_is<Type>Ivar()` 函数的参数）来自 Objective-C 运行时头文件；不使用 modules 的构建（React Native）不会在生成的接口之前自己导入它。
 */
#import <objc/runtime.h>
#if defined(SWIFT_PACKAGE)
#pragma clang module import CYLUtilsKit
#elif __has_include(<CYLUtilsKit/CYLUtilsKit-Swift.h>)
#import <CYLUtilsKit/CYLUtilsKit-Swift.h>
#elif __has_include("CYLUtilsKit-Swift.h")
#import "CYLUtilsKit-Swift.h"
#elif __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
// [EN] The Xcode framework and Carthage build all three layers into one module (`CYLTabBarController.xcodeproj`, docs/Animated-Item-Badge.md, step 10 TODO). [CN] Xcode framework 与 Carthage 把三层编进同一个模块（`CYLTabBarController.xcodeproj`，docs/Animated-Item-Badge.md，第 10 步 TODO）。
#import <CYLTabBarController/CYLTabBarController-Swift.h>
#elif __has_include("CYLTabBarController-Swift.h")
#import "CYLTabBarController-Swift.h"
#endif
#endif
