//
//  CYLAnimatedItemMacros.h
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
//  [EN] The CYLAnimatedItem pod's own macros. It depends on no other pod (not on CYLTabBarController), so it does not
//       import CYLUtils; CYLTabBarController's `CYLUtilsMacros.h` imports this file for the shared ones.
//  [CN] CYLAnimatedItem pod 自己的宏。它不依赖任何其他 pod（不依赖 CYLTabBarController），因此不导入 CYLUtils；CYLTabBarController 的
//       `CYLUtilsMacros.h` 导入本文件以获得共用的宏。
//

#ifndef CYLAnimatedItemMacros_h
#define CYLAnimatedItemMacros_h

#import <UIKit/UIKit.h>

/*!
 * [EN] 1 when the animation engine (the `CYLAnimatedItem/Engine` subspec, or a build that compiles it in) is part of the
 *      build, 0 otherwise: without it the component shows static images only.
 * [CN] 动画引擎（`CYLAnimatedItem/Engine` 子库，或把它编译进来的构建）参与构建时为 1，否则为 0：没有引擎时组件只显示静态图片。
 */
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationFactory.h>) || __has_include(<CYLTabBarController/CYLTabBarItemAnimationFactory.h>) || __has_include("CYLTabBarItemAnimationFactory.h")
#define CYL_ANIMATION_ENGINE_AVAILABLE 1
#else
#define CYL_ANIMATION_ENGINE_AVAILABLE 0
#endif

/*!
 * [EN] 1 when Lottie (lottie-ios 2.x or 4.x) is part of the build.
 * [CN] Lottie（lottie-ios 2.x 或 4.x）参与构建时为 1。
 */
#if __has_include(<Lottie/Lottie.h>) || __has_include(<Lottie/Lottie-Swift.h>)
#define CYL_LOTTIE_AVAILABLE 1
#else
#define CYL_LOTTIE_AVAILABLE 0
#endif

/*!
 * [EN] Marks the released Lottie keys: a compile warning when Lottie is not part of the build.
 * [CN] 标记已发布的 Lottie key：没有 Lottie 时给出编译警告。
 */
#if CYL_LOTTIE_AVAILABLE
#define CYL_LOTTIE_REQUIRED
#else
#define CYL_LOTTIE_REQUIRED __attribute__((deprecated("Lottie is not part of this build, so this is ignored and the tab shows its image. Add pod 'CYLTabBarController/Lottie' (or LottieSwift), or wrap the code in #if canImport(Lottie) / #if CYL_LOTTIE_AVAILABLE.")))
#endif

/*!
 * [EN] Runs `Stuff` without the performSelector-leaks warning and logs an exception instead of crashing. CYLTabBarController's
 *      `CYLUtilsMacros.h` defines the same macro with a localized message; the first definition wins.
 * [CN] 执行 `Stuff`，屏蔽 performSelector 泄漏警告，并在发生异常时记录日志而不是崩溃。CYLTabBarController 的 `CYLUtilsMacros.h`
 *      以本地化的日志定义同名宏；以先出现的定义为准。
 */
#ifndef CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
#define CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
@try { \
Stuff; \
} @catch (NSException *exception) { \
NSLog(@"🔴 %@ (line %@): %@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason); \
} \
_Pragma("clang diagnostic pop") \
} while (0);
#endif

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] The component's resource bundle, `CYLAnimatedItem.bundle` (the placeholder, its LICENSE and POLICY.md), or nil.
 * [CN] 组件的资源包 `CYLAnimatedItem.bundle`（占位图及其 LICENSE 与 POLICY.md），找不到时为 nil。
 */
FOUNDATION_EXPORT NSBundle *_Nullable CYLAnimatedItemResourceBundle(void);

NS_ASSUME_NONNULL_END

#endif /* CYLAnimatedItemMacros_h */
