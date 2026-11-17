//
//  UIControl+CYLTabBarItemAnimationPlayer.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#if __has_include("../CYLUtils/CYLUtilsMacros.h")
#import "../CYLUtils/CYLUtilsMacros.h"
#else
#import "CYLUtilsMacros.h"
#endif

// [EN] Part of Core; declared only when an animation subspec brings the engine (`CYL_ANIMATION_ENGINE_AVAILABLE`).
// [CN] 属于 Core；只有动画子库带入引擎时才声明（`CYL_ANIMATION_ENGINE_AVAILABLE`）。
#if CYL_ANIMATION_ENGINE_AVAILABLE
#if __has_include(<CYLTabBarController/CYLTabBarItemAnimationPlayer.h>)
#import <CYLTabBarController/CYLTabBarItemAnimationPlayer.h>
#else
#import "CYLTabBarItemAnimationPlayer.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #604 — public API of the `CYLTabBarItemAnimation` subspec.
 * [EN] The player of a tab button's animation, whatever its library, so that an app controls it without casting
 *      `-cyl_lottieAnimationView` to `LOTAnimationView`, `PAGView`… (e.g. in `-tabBarController:didSelectControl:`).
 *
 *          id<CYLTabBarItemAnimationPlayer> player = control.cyl_tabBarItemAnimationPlayer;
 *          if ([player respondsToSelector:@selector(setAnimationSpeed:)]) { player.animationSpeed = 2; }
 *          [player play];
 * [CN] Tab 按钮动画的播放器，与动画库无关，App 无需把 `-cyl_lottieAnimationView` 强转为 `LOTAnimationView`、`PAGView` 等即可控制它（例如在
 *      `-tabBarController:didSelectControl:` 中）。示例见上。
 */
@interface UIControl (CYLTabBarItemAnimationPlayer)

/*!
 * [EN] The player of this tab button's animation, nil without one. [CN] 本 Tab 按钮动画的播放器；没有动画时为 nil。
 */
@property (nonatomic, readonly, nullable) id<CYLTabBarItemAnimationPlayer> cyl_tabBarItemAnimationPlayer;

@end

NS_ASSUME_NONNULL_END

#endif
