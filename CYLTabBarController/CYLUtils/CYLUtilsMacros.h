//
//  CYLUtilsMacros.h
//  CYLUtils
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * FIX: issue #535
 * [EN] Feature checks and generic macros shared by Core and CYLBadgeView, moved here from `CYLConstants.h`, which
 *      imports this header, so existing code sees them as before.
 * [CN] Core 与 CYLBadgeView 共用的功能检测与通用宏，从 `CYLConstants.h` 移入。`CYLConstants.h` 会导入本头文件，原有代码不受影响。
 */

#ifndef CYLUtilsMacros_h
#define CYLUtilsMacros_h

#import <UIKit/UIKit.h>
#import "CYLLocalizedString.h"

/*!
 * [EN] 1 when the flat design subspec (CYLFlatDesignTabBar) is part of the build, 0 otherwise. The one place that asks
 *      `__has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)`; everywhere else guard flat design code with
 *      `#if CYL_FLATDESIGN_AVAILABLE`. Every file of the library imports this header first (`CYLConstants.h` and `CYLUtils.h` import it). Use the macro only after
 *      importing it: an undefined macro counts as 0 in `#if` and would silently leave the flat design code out.
 * [CN] 引入扁平样式子库（CYLFlatDesignTabBar）时为 1，否则为 0。这是唯一检查
 *      `__has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)` 的地方；其他地方统一用 `#if CYL_FLATDESIGN_AVAILABLE`
 *      为扁平样式代码做 guard。库中每个文件都会先引入本头文件（`CYLConstants.h`、`CYLUtils.h` 会导入它）。只能在引入之后使用该宏：未定义的宏在 `#if` 中按 0 处理，
 *      会悄悄去掉扁平样式代码。
 */
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
#define CYL_FLATDESIGN_AVAILABLE 1
#else
#define CYL_FLATDESIGN_AVAILABLE 0
#endif

/*!
 * [EN] Core and CYLUtils have no compile-time switch per animation library (PAG, Rive, …): whether a tab animates is
 *      decided at runtime by the animators registered with `CYLTabBarItemAnimatorRegistry` (the `CYLTabBarItemAnimation`
 *      subspec), so adding a library changes nothing here. The switches per type (`CYL_GIF_AVAILABLE`, `CYL_PAG_AVAILABLE`,
 *      `CYL_RIVE_AVAILABLE`, `CYL_SVGA_AVAILABLE`, `CYL_LOTTIE_AVAILABLE`) are in the component's core,
 *      `CYLAnimatedItemMacros.h`, imported at the end of this file; a library's keys exist only when the library does.
 * [CN] Core 与 CYLUtils 中没有各动画库（PAG、Rive……）的编译期开关：Tab 是否有动画在运行时由注册到 `CYLTabBarItemAnimatorRegistry`
 *      的 animator 决定（`CYLTabBarItemAnimation` 子库），因此新增动画库时这里无需修改。各类型的开关
 *      （`CYL_GIF_AVAILABLE`、`CYL_PAG_AVAILABLE`、`CYL_RIVE_AVAILABLE`、`CYL_SVGA_AVAILABLE`、`CYL_LOTTIE_AVAILABLE`）位于组件核心的
 *      `CYLAnimatedItemMacros.h`，在本文件末尾导入；动画库的 key 只在引入该动画库时存在。
 */

#define CYL_DEPRECATED(explain) __attribute__((deprecated(explain)))


#define CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_PUSH \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wdeprecated-implementations\"")

#define CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_POP \
_Pragma("clang diagnostic pop")

#define CYL_DEPRECATED_DECLARATIONS_PUSH \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"")

#define CYL_DEPRECATED_DECLARATIONS_POP \
_Pragma("clang diagnostic pop")


#define CYL_METHOD_SIGNATURES_PUSH \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wmethod-signatures\"")

#define CYL_METHOD_SIGNATURES_POP \
_Pragma("clang diagnostic pop")



#define CYL_IS_IOS_11  ([[[UIDevice currentDevice] systemVersion] floatValue] >= 11.f) && (@available(iOS 11.0, *))
#define CYL_IS_IOS_13  ([[[UIDevice currentDevice] systemVersion] floatValue] >= 13.f) && (@available(iOS 13.0, *))
#define CYL_IS_IOS_16  if (@available(iOS 16.0, *))

#define CYL_IS_IOS_26 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 26.f)
#define CYL_IS_IOS_27 ([[[UIDevice currentDevice] systemVersion] floatValue] >= 27.f)

#define CYL_SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define CYL_SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define CYL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define CYL_SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define CYL_SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

// [EN] CYL_ANIMATION_ENGINE_AVAILABLE, CYL_LOTTIE_AVAILABLE, CYL_LOTTIE_REQUIRED and CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS come
//      from the CYLAnimatedItem pod. Its CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS is the only one: with CocoaPods each pod is a
//      module, and a second, different definition here made every use an "ambiguous expansion of macro" warning. The
//      definition below is only a fallback for a build without the component.
// [CN] CYL_ANIMATION_ENGINE_AVAILABLE、CYL_LOTTIE_AVAILABLE、CYL_LOTTIE_REQUIRED 与 CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS 来自
//      CYLAnimatedItem pod。后者以组件的定义为唯一定义：使用 CocoaPods 时每个 pod 是一个 module，这里再定义一个不同的版本会让每处使用都产生
//      "ambiguous expansion of macro" 警告。下面的定义只是没有组件时的后备。
#if __has_include(<CYLAnimatedItem/CYLAnimatedItemMacros.h>)
#import <CYLAnimatedItem/CYLAnimatedItemMacros.h>
#elif __has_include("../CYLAnimatedItem/CYLAnimatedItemMacros.h")
#import "../CYLAnimatedItem/CYLAnimatedItemMacros.h"
#else
#import "CYLAnimatedItemMacros.h"
#endif

#ifndef CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
#define CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
@try { \
Stuff; \
} @catch (NSException *exception) { \
NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), \
@(__PRETTY_FUNCTION__), @(__LINE__), exception.reason); \
} \
_Pragma("clang diagnostic pop") \
} while (0);
#endif

#endif /* CYLUtilsMacros_h */
