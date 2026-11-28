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
 *      Whether a tab bar exists is asked at run time by class name (the badge never imports Core).
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
#if __has_include(<CYLUtilsKit/CYLUtils.h>)
#import <CYLUtilsKit/CYLUtils.h>
#else
#import "CYLUtils.h"
#endif

// [EN] D7 (docs/Animated-Item-Badge.md, step 4): CYLBadge sees only CYLUtils below it, so there is no `CYL_BADGE_CORE_AVAILABLE` and no import of
//      CYLTabBarController.h (that would be a module cycle). What needs the tab bar is decided at run time by class name
//      (`NSClassFromString(@"CYLTabBarController")`), as the badge's host lookups already do.
// [CN] D7（docs/Animated-Item-Badge.md，第 4 步）：CYLBadge 只看得到下面的 CYLUtils，因此没有 `CYL_BADGE_CORE_AVAILABLE`，也不导入
//      CYLTabBarController.h（那会形成模块循环）。需要 TabBar 的部分在运行时按类名判断（`NSClassFromString(@"CYLTabBarController")`），
//      与角标已有的宿主查找方式相同。

#import "CYLBadgeProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] `CYLBadgeAnimationForType()` is Swift since docs/Swift-Migration.md step 115 (phase ③, group A of docs/Swift-Migration-Phase3.md): Objective-C
 *      sees it through the generated Swift interface (`CYLSwiftInterface.h`), with the same names.
 * [CN] `CYLBadgeAnimationForType()` is 自第 115 步（第 ③ 阶段 A 组）起为 Swift：Objective-C 通过生成的 Swift 接口（`CYLSwiftInterface.h`）看到它，名称不变。
 */


NS_ASSUME_NONNULL_END

#endif /* CYLBadgeViewDefines_h */
