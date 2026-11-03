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

#endif /* CYLBadgeViewDefines_h */
