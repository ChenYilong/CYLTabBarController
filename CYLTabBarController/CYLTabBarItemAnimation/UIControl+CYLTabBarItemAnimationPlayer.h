//
//  UIControl+CYLTabBarItemAnimationPlayer.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLTabBarItemAnimationPlayer.h"

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
