//
//  CYLTabBarControllerSwiftInterface.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * [EN] The Objective-C interface of Core's Swift code (docs/Swift-Migration.md): the header Swift generates for the
 *      `CYLTabBarController` module. Split from `CYLSwiftInterface.h` (D7, docs/Animated-Item-Badge.md): CYLUtils and CYLBadge
 *      are modules of their own and have their own interface headers, which this one imports first.
 *      Built on macOS, 2026-11-29.
 * [CN] Core 的 Swift 代码的 Objective-C 接口（docs/Swift-Migration.md）：Swift 为 `CYLTabBarController` 模块生成的头文件。从 `CYLSwiftInterface.h`
 *      拆出（D7，docs/Animated-Item-Badge.md）：CYLUtils 与 CYLBadge 是独立的模块，各有自己的接口头文件，本文件先导入它们。 已于 2026-11-29 在 macOS 上构建。
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
 * [EN] Objective-C declarations the generated interface uses and that stay Objective-C for now: they must come first, as the
 *      first header that imports this file may not have seen them (step 21: `UIView (CYLBadgeExtention)` adopts
 *      `CYLBadgeProtocol` and uses `CYLBadgeAnimationType`). Only headers that import nothing of this module go here.
 * [CN] 生成的接口所用、目前仍为 Objective-C 的声明：必须先导入，因为第一个导入本文件的头文件可能还没有看到它们（第 21 步：
 *      `UIView (CYLBadgeExtention)` 遵守 `CYLBadgeProtocol` 并使用 `CYLBadgeAnimationType`）。这里只放不导入本模块其他头文件的头文件。
 */
/*!
 * [EN] `Ivar` (a parameter of the `cyl_is<Type>Ivar()` functions) comes from the Objective-C runtime header, which a build
 *      without modules (React Native's) does not import by itself before the generated interface.
 * [CN] `Ivar`（`cyl_is<Type>Ivar()` 函数的参数）来自 Objective-C 运行时头文件；不使用 modules 的构建（React Native）不会在生成的接口之前自动导入它。
 */
#import <objc/runtime.h>
#import "CYLBadgeSwiftInterface.h"
#if __has_include(<CYLTabBarController/CYLTabBarControllerTypedefs.h>)
#import <CYLTabBarController/CYLTabBarControllerTypedefs.h>
#elif __has_include("CYLTabBarControllerTypedefs.h")
#import "CYLTabBarControllerTypedefs.h"
#endif
/*!
 * [EN] The animation subspec's protocols (`CYLTabBarItemAnimationPlayableView`, `CYLTabBarItemAnimationViewProviding`), which
 *      Swift classes of the Lottie, Rive and PAG subspecs adopt: without them the generated interface fails in a framework build.
 * [CN] Lottie、Rive、PAG 子库的 Swift 类遵守的动画协议：缺少它们时，framework 编译中生成的接口会失败。
 */
#if __has_feature(modules) && __has_include(<CYLAnimatedItem/CYLAnimatedItem-umbrella.h>)
#pragma clang module import CYLAnimatedItem
#else
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationPlayableView.h>) || __has_include(<CYLTabBarController/CYLTabBarItemAnimationPlayableView.h>)
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationPlayableView.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationPlayableView.h>
#else
#import <CYLTabBarController/CYLTabBarItemAnimationPlayableView.h>
#endif
#elif __has_include("CYLTabBarItemAnimationPlayableView.h")
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationPlayableView.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationPlayableView.h>
#else
#import "CYLTabBarItemAnimationPlayableView.h"
#endif
#endif
#endif
// [EN] The Swift header declares `CYLFlatDesignTabBarButton : CYLAnimatedItemView`; in a framework that compiles the
//      component into the same module (CYLTabBarController.xcodeproj, Carthage) the superclass must be declared first.
// [CN] Swift 头文件声明了 `CYLFlatDesignTabBarButton : CYLAnimatedItemView`；在把组件编译进同一模块的 framework 中（CYLTabBarController.xcodeproj、
//      Carthage），必须先声明父类。
#if __has_feature(modules) && __has_include(<CYLAnimatedItem/CYLAnimatedItem-umbrella.h>)
#pragma clang module import CYLAnimatedItem
#else
#if __has_include(<CYLAnimatedItem/CYLAnimatedItemView.h>)
#import <CYLAnimatedItem/CYLAnimatedItemView.h>
#elif __has_include(<CYLTabBarController/CYLAnimatedItemView.h>)
#import <CYLTabBarController/CYLAnimatedItemView.h>
#elif __has_include("CYLAnimatedItemView.h")
#import "CYLAnimatedItemView.h"
#endif
#endif
#if defined(SWIFT_PACKAGE)
#pragma clang module import CYLTabBarController
#elif __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
#import <CYLTabBarController/CYLTabBarController-Swift.h>
#elif __has_include("CYLTabBarController-Swift.h")
#import "CYLTabBarController-Swift.h"
#endif
#endif
