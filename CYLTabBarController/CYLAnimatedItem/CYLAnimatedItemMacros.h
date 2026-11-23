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


// CYL-SWIFT-MIGRATION: objc-required — [EN] C macros (the engine switches `CYL_*_AVAILABLE`, `@try` wrappers) and the prototype of the C function `CYLAnimatedItemResourceBundle()`, now defined in Swift (Swift/CYLAnimatedItemResources.swift): Swift cannot export macros or C prototypes. [CN] C 宏（引擎开关 `CYL_*_AVAILABLE`、`@try` 包装）与 C 函数 `CYLAnimatedItemResourceBundle()` 的原型（定义已改为 Swift）：Swift 无法导出宏或 C 原型。
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
 * [EN] One switch per animation type, all here in the component's core so that any file can ask (an undefined macro would
 *      silently count as 0 in `#if`). Each is 1 only when that type's engine subspec (`CYLAnimatedItem/GIF`, `PAG`,
 *      `PAGEnterprise`, `Rive`, `SVGA`) is in the build, which brings its animator header, and its library is there.
 *      The header is looked up through the header search paths only, never by a relative path, so a file on disk that
 *      the build does not compile does not count. `CYL_LOTTIE_AVAILABLE` (above) asks for the Lottie library only: the
 *      Lottie animator header is private, and the released Lottie keys depend on it.
 * [CN] 每种动画类型一个开关，统一放在组件核心中，任何文件都能检查（未定义的宏在 `#if` 中会被静默当作 0）。只有该类型的引擎子库
 *      （`CYLAnimatedItem/GIF`、`PAG`、`PAGEnterprise`、`Rive`、`SVGA`，会带入其 animator 头文件）参与构建且其动画库存在时才为 1。
 *      头文件只通过头文件搜索路径查找，不使用相对路径，因此磁盘上存在但未参与编译的文件不算。`CYL_LOTTIE_AVAILABLE`（见上）只检查
 *      Lottie 库：Lottie 的 animator 头文件是私有的，且已发布的 Lottie key 依赖它。
 */
#if (__has_include(<CYLAnimatedItem/CYLGIFTabBarItemAnimator.h>) || __has_include(<CYLTabBarController/CYLGIFTabBarItemAnimator.h>) || __has_include("CYLGIFTabBarItemAnimator.h")) && __has_include(<ImageIO/ImageIO.h>)
#define CYL_GIF_AVAILABLE 1
#else
#define CYL_GIF_AVAILABLE 0
#endif

#if (__has_include(<CYLAnimatedItem/CYLPAGTabBarItemAnimator.h>) || __has_include(<CYLTabBarController/CYLPAGTabBarItemAnimator.h>) || __has_include("CYLPAGTabBarItemAnimator.h")) && __has_include(<libpag/PAGView.h>)
#define CYL_PAG_AVAILABLE 1
#else
#define CYL_PAG_AVAILABLE 0
#endif

#if (__has_include(<CYLAnimatedItem/CYLRiveTabBarItemAnimator.h>) || __has_include(<CYLTabBarController/CYLRiveTabBarItemAnimator.h>) || __has_include("CYLRiveTabBarItemAnimator.h")) && __has_include(<RiveRuntime/RiveRuntime.h>)
#define CYL_RIVE_AVAILABLE 1
#else
#define CYL_RIVE_AVAILABLE 0
#endif

#if (__has_include(<CYLAnimatedItem/CYLSVGATabBarItemAnimator.h>) || __has_include(<CYLTabBarController/CYLSVGATabBarItemAnimator.h>) || __has_include("CYLSVGATabBarItemAnimator.h")) && (__has_include(<SVGAPlayerLite/SVGA.h>) || __has_include(<SVGAPlayer/SVGA.h>) || __has_include("SVGA.h"))
#define CYL_SVGA_AVAILABLE 1
#else
#define CYL_SVGA_AVAILABLE 0
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
 * [EN] Marks the keys of one animation type: nothing when that type's engine is in the build; otherwise a compile warning
 *      (the code still compiles and the item shows its static image, or the placeholder).
 * [CN] 标记某种动画类型的 key：该类型的引擎参与构建时无影响；否则给出编译警告（代码仍能编译，条目显示静态图片或占位图）。
 */
#if CYL_GIF_AVAILABLE
#define CYL_GIF_REQUIRED
#else
#define CYL_GIF_REQUIRED __attribute__((deprecated("GIF is not part of this build, so this key is ignored and the item shows its static image (or the placeholder). Add pod 'CYLAnimatedItem/GIF' (with CYLTabBarController: pod 'CYLTabBarController/GIF'), or wrap the code in #if CYL_GIF_AVAILABLE.")))
#endif
#if CYL_PAG_AVAILABLE
#define CYL_PAG_REQUIRED
#else
#define CYL_PAG_REQUIRED __attribute__((deprecated("PAG is not part of this build, so this key is ignored and the item shows its static image (or the placeholder). Add pod 'CYLAnimatedItem/PAG' (with CYLTabBarController: pod 'CYLTabBarController/PAG'), or wrap the code in #if CYL_PAG_AVAILABLE.")))
#endif
#if CYL_RIVE_AVAILABLE
#define CYL_RIVE_REQUIRED
#else
#define CYL_RIVE_REQUIRED __attribute__((deprecated("Rive is not part of this build, so this key is ignored and the item shows its static image (or the placeholder). Add pod 'CYLAnimatedItem/Rive' (with CYLTabBarController: pod 'CYLTabBarController/Rive'), or wrap the code in #if CYL_RIVE_AVAILABLE.")))
#endif
#if CYL_SVGA_AVAILABLE
#define CYL_SVGA_REQUIRED
#else
#define CYL_SVGA_REQUIRED __attribute__((deprecated("SVGA is not part of this build, so this key is ignored and the item shows its static image (or the placeholder). Add pod 'CYLAnimatedItem/SVGA' (with CYLTabBarController: pod 'CYLTabBarController/SVGA'), or wrap the code in #if CYL_SVGA_AVAILABLE.")))
#endif

/*!
 * [EN] Runs `Stuff` without the performSelector-leaks warning and logs an exception instead of crashing. CYLTabBarController
 *      uses this definition too (`CYLUtilsMacros.h` defines it only when the component is missing), so there is one
 *      definition and no "ambiguous expansion of macro" warning across the two modules.
 * [CN] 执行 `Stuff`，屏蔽 performSelector 泄漏警告，并在发生异常时记录日志而不是崩溃。CYLTabBarController 也使用这个定义
 *      （`CYLUtilsMacros.h` 只在缺少组件时定义），因此只有一个定义，两个 module 之间不会出现 "ambiguous expansion of macro" 警告。
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
// [EN] In Objective-C++ the declaration must say `noexcept` as the generated Swift header does, or a file that includes both fails
//      ("exception specification in declaration does not match previous declaration", React Native's `.mm` files).
// [CN] 在 Objective-C++ 中，声明必须与生成的 Swift 头文件一致地写 `noexcept`，否则同时包含两者的文件会编译失败（React Native 的 `.mm` 文件）。
#if defined(__cplusplus)
FOUNDATION_EXPORT NSBundle *_Nullable CYLAnimatedItemResourceBundle(void) noexcept;
#else
FOUNDATION_EXPORT NSBundle *_Nullable CYLAnimatedItemResourceBundle(void);
#endif

NS_ASSUME_NONNULL_END

#endif /* CYLAnimatedItemMacros_h */
