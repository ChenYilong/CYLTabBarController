//
//  CYLTabBarItemAnimationService.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * [EN] The C entry points of the animation service (`CYLTabBarItemAnimationDefaultStyleSource()` …) are `@_cdecl` Swift
 *      functions, declared for Objective-C by the generated Swift interface since docs/Swift-Migration.md step 118;
 *      `CYLTabBarItemAnimationIsAvailable()` is a macro over `CYLTabBarItemAnimationGetService()`.
 * [CN] 动画服务的 C 入口（`CYLTabBarItemAnimationDefaultStyleSource()` 等）是 `@_cdecl` 的 Swift 函数，自第 118 步起由生成的 Swift 接口为
 *      Objective-C 声明；`CYLTabBarItemAnimationIsAvailable()` 是基于 `CYLTabBarItemAnimationGetService()` 的宏。
 */
#import <UIKit/UIKit.h>
#import "CYLTabBarControllerSwiftInterface.h"

/*!
 * `noexcept` in C++: the declarations of CYLTabBarController-Swift.h (functions implemented in Swift with @_cdecl) carry
 * it, and Objective-C++ files that import both headers fail to compile when the two declarations differ.
 */
#ifndef CYL_NOEXCEPT
#if defined(__cplusplus)
#define CYL_NOEXCEPT noexcept
#else
#define CYL_NOEXCEPT
#endif
#endif

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] The protocols `CYLTabBarItemAnimationStyleSource`, `CYLTabBarItemAnimationHost` and `CYLTabBarItemAnimationService`
 *      are implemented in Swift (`Swift/CYLTabBarItemAnimationService.swift`, every selector kept) and declared by the
 *      generated Swift interface (`CYLSwiftInterface.h`). The functions below are declared here for
 *      Objective-C callers and defined in Swift with `@_cdecl` (`Swift/UIControl+CYLTabBarItemAnimation.swift`,
 *      `Swift/CYLTabBarItemAnimationStyleRegistry.swift`) (docs/Swift-Migration.md).
 * [CN] `CYLTabBarItemAnimationStyleSource`、`CYLTabBarItemAnimationHost` 与 `CYLTabBarItemAnimationService` 协议在 Swift 中实现
 *      （`Swift/CYLTabBarItemAnimationService.swift`，所有 selector 不变），由 Swift 生成接口（`CYLSwiftInterface.h`）声明。下面的函数
 *      在这里为 Objective-C 调用方声明，并以 `@_cdecl` 在 Swift 中定义（`Swift/UIControl+CYLTabBarItemAnimation.swift`、
 *      `Swift/CYLTabBarItemAnimationStyleRegistry.swift`）（docs/Swift-Migration.md）。
 */

/*!
 * [EN] Called by the `CYLTabBarItemAnimation` subspec when it loads. [CN] 由 `CYLTabBarItemAnimation` 子库在加载时调用。
 * [EN] Core's style source, over the registrations of the `…DarkURL` / `…DarkFilePath` / `…DarkColors` keys.
 * [CN] Core 的风格来源，基于 `…DarkURL` / `…DarkFilePath` / `…DarkColors` 等 key 的注册信息。
 */

/*!
 * [EN] Core's host. [CN] Core 提供的宿主实现。
 */


/*!
 * [EN] The service, or nil without an animation library. [CN] 动画服务；没有动画库时为 nil。
 */

/*!
 * [EN] YES when an animation library is in the build. [CN] 构建中包含动画库时返回 YES。
 */
#define CYLTabBarItemAnimationIsAvailable() (CYLTabBarItemAnimationGetService() != nil)

/*!
 * [EN] The value of a generic animation key (`CYLTabBarAnimationURL`…) in a tab's attributes: the generic key first, then
 *      the key of the one library the tab's keys choose (e.g. `CYLTabBarRiveURL`), never another library's. Core reads tab
 *      attributes only through this, so a new library needs no change in Core.
 * [CN] Tab 属性中某个通用动画 key（`CYLTabBarAnimationURL`…）的值：先取通用 key，再取 Tab 的 key 所选择的那一个动画库的 key（例如
 *      `CYLTabBarRiveURL`），不会取其他动画库的 key。Core 只通过它读取 Tab 属性，因此新增动画库时无需修改 Core。
 */

NS_ASSUME_NONNULL_END
