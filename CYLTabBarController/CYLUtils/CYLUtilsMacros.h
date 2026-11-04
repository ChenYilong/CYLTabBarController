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
 * [EN] 1 when a Lottie library is part of the build, 0 otherwise: lottie-ios 2.x for Objective-C
 *      (`CYLTabBarController/LottieObjectiveC`, `<Lottie/Lottie.h>`) or lottie-ios 4.x for Swift
 *      (`CYLTabBarController/LottieSwift`, `CYLFlatDesignTabBar`, SPM; `<Lottie/Lottie-Swift.h>`). The Core subspec
 *      alone has no Lottie, and Lottie code there does nothing. Use it, like `CYL_FLATDESIGN_AVAILABLE`, only after
 *      importing this header.
 * [CN] 工程中引入了 Lottie 库时为 1，否则为 0：Objective-C 版 lottie-ios 2.x（`CYLTabBarController/LottieObjectiveC`，
 *      `<Lottie/Lottie.h>`），或 Swift 版 lottie-ios 4.x（`CYLTabBarController/LottieSwift`、`CYLFlatDesignTabBar`、SPM；
 *      `<Lottie/Lottie-Swift.h>`）。只引入 Core 子库时没有 Lottie，Lottie 相关代码不起作用。与 `CYL_FLATDESIGN_AVAILABLE`
 *      一样，只能在引入本头文件之后使用。
 */
#if __has_include(<Lottie/Lottie.h>) || __has_include(<Lottie/Lottie-Swift.h>)
#define CYL_LOTTIE_AVAILABLE 1
#else
#define CYL_LOTTIE_AVAILABLE 0
#endif

/*!
 * [EN] There is no compile-time switch per animation library (PAG, Rive, …): whether a tab animates is decided at runtime
 *      by the animators registered with `CYLTabBarItemAnimatorRegistry` (the `CYLTabBarItemAnimation` subspec), so adding
 *      a library changes nothing here.
 * [CN] 各动画库（PAG、Rive……）没有编译期开关：Tab 是否有动画在运行时由注册到 `CYLTabBarItemAnimatorRegistry` 的 animator 决定
 *      （`CYLTabBarItemAnimation` 子库），因此新增动画库时这里无需修改。
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

#endif /* CYLUtilsMacros_h */
