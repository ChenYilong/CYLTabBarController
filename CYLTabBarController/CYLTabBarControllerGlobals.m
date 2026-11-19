//
//  CYLTabBarControllerGlobals.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController.h"

/*!
 * [EN] The C globals of `CYLTabBarController.h` (declared `FOUNDATION_EXTERN` there, read by apps and by the library). They stay
 *      in Objective-C: Swift cannot export a data symbol (`@_cdecl` covers functions only), and changing them to functions
 *      would break the public API (docs/Swift-Migration.md, the class switch).
 * [CN] `CYLTabBarController.h` 中的 C 全局变量（在那里以 `FOUNDATION_EXTERN` 声明，App 与本库都会读取）。它们保留在 Objective-C 中：
 *      Swift 无法导出数据符号（`@_cdecl` 只适用于函数），改为函数会破坏公开 API（docs/Swift-Migration.md，类迁移）。
 */
NSUInteger CYLTabbarItemsCount = 0;
NSUInteger CYLPlusButtonIndex = 0;
CGFloat CYLTabBarItemWidth = 0.0f;
CGFloat CYLTabBarHeight = 49.0f;

NSString *const CYLTabBarItemLottieAnimationPlayingNotification = @"CYLTabBarItemLottieAnimationPlayingNotification";
NSString *const CYLTabBarItemLottieAnimationViewDidAddNotification = @"CYLTabBarItemLottieAnimationViewDidAddNotification";
NSString *const CYLTabBarStyleTypeDidChangeNotification = @"CYLTabBarStyleTypeDidChangeNotification";
