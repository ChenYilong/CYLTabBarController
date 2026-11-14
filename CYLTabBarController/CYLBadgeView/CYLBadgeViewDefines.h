//
//  CYLBadgeViewDefines.h
//  CYLBadgeView
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * FIX: issue #535
 * [EN] Shared by the CYLBadgeView sources only; not part of the public API.
 *      Everything CYLBadgeView and Core both use (macros, `-cyl_setHidden:`, `-cyl_valueForKey:`, `-cyl_tabButton`,
 *      `CYLLocalizedString()`, `+[CYLUtils isLiquidGlassActive]`...) comes from CYLUtils, which both depend on.
 *      `CYL_BADGE_CORE_AVAILABLE` is only for what exists in Core alone, the tab bar: with Core, a tab button's badge
 *      goes on its icon or Lottie view and is mirrored to the Liquid Glass platter; on its own
 *      (`pod 'CYLTabBarController/CYLBadgeView'`) the badge goes on the control or the tab icon. Like the Lottie
 *      guards, it is set with `__has_include`.
 * [CN] 仅供 CYLBadgeView 源文件内部使用，不属于公开 API。
 *      CYLBadgeView 与 Core 共同使用的内容（宏、`-cyl_setHidden:`、`-cyl_valueForKey:`、`-cyl_tabButton`、`CYLLocalizedString()`、
 *      `+[CYLUtils isLiquidGlassActive]` 等）都来自二者共同依赖的 CYLUtils。
 *      `CYL_BADGE_CORE_AVAILABLE` 只用于 Core 独有的 TabBar 部分：有 Core 时，Tab 按钮的角标显示在图标或 Lottie 视图上，并同步到液态
 *      玻璃 platter；单独使用（`pod 'CYLTabBarController/CYLBadgeView'`）时，角标显示在控件或 Tab 图标上。与 Lottie 的隔离方式相同，
 *      通过 `__has_include` 判断。
 */

#ifndef CYLBadgeViewDefines_h
#define CYLBadgeViewDefines_h

#import <UIKit/UIKit.h>
#import "CYLUtils.h"

#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#define CYL_BADGE_CORE_AVAILABLE 1
#import <CYLTabBarController/CYLTabBarController.h>
#elif __has_include("CYLTabBarController.h")
#define CYL_BADGE_CORE_AVAILABLE 1
#import "CYLTabBarController.h"
#else
#define CYL_BADGE_CORE_AVAILABLE 0
#endif

#import "CYLBadgeProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] The animation a badge plays for `animationType`, sized for a badge of `badgeSize`; nil for
 *      `CYLBadgeAnimationTypeNone`. Add it with the key `CYLBadgeAnimationKeyForType(animationType)`. Shared by the
 *      library's badges (`-[UIView cyl_beginAnimation]`) and the system badge of a bar button item on iOS 26+; private to
 *      CYLBadgeView, not public API.
 * [CN] 角标在 `animationType` 下播放的动画，按 `badgeSize` 计算幅度；`CYLBadgeAnimationTypeNone` 时为 nil。使用
 *      `CYLBadgeAnimationKeyForType(animationType)` 作为 key 添加。由本库角标（`-[UIView cyl_beginAnimation]`）与 iOS 26+ 上
 *      bar button item 的系统角标共用；仅供 CYLBadgeView 内部使用，不是公开 API。
 */
/* [EN] Declared by the generated Swift header too (C++ sees that one: `noexcept`). [CN] 生成的 Swift 头文件也声明了它（C++ 使用那一份：`noexcept`）。 */
#if !defined(__cplusplus) || !__has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
FOUNDATION_EXTERN CAAnimation *_Nullable CYLBadgeAnimationForType(CYLBadgeAnimationType animationType, CGSize badgeSize);
#endif

NS_ASSUME_NONNULL_END

#endif /* CYLBadgeViewDefines_h */
