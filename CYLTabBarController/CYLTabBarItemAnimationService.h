//
//  CYLTabBarItemAnimationService.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLSwiftInterface.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] The protocols `CYLTabBarItemAnimationStyleSource`, `CYLTabBarItemAnimationHost` and `CYLTabBarItemAnimationService`
 *      are implemented in Swift (`Swift/CYLTabBarItemAnimationService.swift`, every selector kept) and declared by the
 *      generated Swift interface (`CYLSwiftInterface.h`). The functions below stay here: they are defined in Objective-C
 *      (`CYLConstants.m`, `UIControl+CYLTabBarItemAnimation.m`) (docs/Swift-Migration.md).
 * [CN] `CYLTabBarItemAnimationStyleSource`、`CYLTabBarItemAnimationHost` 与 `CYLTabBarItemAnimationService` 协议在 Swift 中实现
 *      （`Swift/CYLTabBarItemAnimationService.swift`，所有 selector 不变），由 Swift 生成接口（`CYLSwiftInterface.h`）声明。下面的函数
 *      保留在这里：它们在 Objective-C 中定义（`CYLConstants.m`、`UIControl+CYLTabBarItemAnimation.m`）（docs/Swift-Migration.md）。
 */

/*!
 * [EN] Called by the `CYLTabBarItemAnimation` subspec when it loads. [CN] 由 `CYLTabBarItemAnimation` 子库在加载时调用。
 * [EN] Core's style source, over the registrations of the `…DarkURL` / `…DarkFilePath` / `…DarkColors` keys.
 * [CN] Core 的风格来源，基于 `…DarkURL` / `…DarkFilePath` / `…DarkColors` 等 key 的注册信息。
 */
FOUNDATION_EXTERN id<CYLTabBarItemAnimationStyleSource> CYLTabBarItemAnimationDefaultStyleSource(void);

/*!
 * [EN] Core's host. [CN] Core 提供的宿主实现。
 */
/* [EN] Declared by the generated Swift header too (C++ sees that one: `noexcept`). [CN] 生成的 Swift 头文件也声明了它（C++ 使用那一份：`noexcept`）。 */
#if !defined(__cplusplus) || !__has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
FOUNDATION_EXTERN id<CYLTabBarItemAnimationHost> CYLTabBarItemAnimationDefaultHost(void);
#endif

/* [EN] Declared by the generated Swift header too (C++ sees that one: `noexcept`). [CN] 生成的 Swift 头文件也声明了它（C++ 使用那一份：`noexcept`）。 */
#if !defined(__cplusplus) || !__has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
FOUNDATION_EXTERN void CYLTabBarItemAnimationSetService(id<CYLTabBarItemAnimationService> _Nullable service);
#endif

/*!
 * [EN] The service, or nil without an animation library. [CN] 动画服务；没有动画库时为 nil。
 */
/* [EN] Declared by the generated Swift header too (C++ sees that one: `noexcept`). [CN] 生成的 Swift 头文件也声明了它（C++ 使用那一份：`noexcept`）。 */
#if !defined(__cplusplus) || !__has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
FOUNDATION_EXTERN id<CYLTabBarItemAnimationService> _Nullable CYLTabBarItemAnimationGetService(void);
#endif

/*!
 * [EN] YES when an animation library is in the build. [CN] 构建中包含动画库时返回 YES。
 */
static inline BOOL CYLTabBarItemAnimationIsAvailable(void) {
    return CYLTabBarItemAnimationGetService() != nil;
}

/*!
 * [EN] The value of a generic animation key (`CYLTabBarAnimationURL`…) in a tab's attributes: the generic key first, then
 *      the key of the one library the tab's keys choose (e.g. `CYLTabBarRiveURL`), never another library's. Core reads tab
 *      attributes only through this, so a new library needs no change in Core.
 * [CN] Tab 属性中某个通用动画 key（`CYLTabBarAnimationURL`…）的值：先取通用 key，再取 Tab 的 key 所选择的那一个动画库的 key（例如
 *      `CYLTabBarRiveURL`），不会取其他动画库的 key。Core 只通过它读取 Tab 属性，因此新增动画库时无需修改 Core。
 */
/* [EN] Declared by the generated Swift header too (C++ sees that one: `noexcept`). [CN] 生成的 Swift 头文件也声明了它（C++ 使用那一份：`noexcept`）。 */
#if !defined(__cplusplus) || !__has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
FOUNDATION_EXTERN id _Nullable CYLTabBarItemAttributesAnimationValue(NSDictionary * _Nullable attributes, NSString *genericKey);
#endif

NS_ASSUME_NONNULL_END
