//
//  UIControl+CYLTabBarItemAnimation.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLTabBar.h"
#import "CYLTabBarItemAnimationService.h"
#import "UIControl+CYLTabBarControllerExtention.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (CYLTabBarItemAnimation)

/// [EN] YES for a view made by a `CYLTabBarItemAnimator`. [CN] 由 `CYLTabBarItemAnimator` 创建的视图返回 YES。
- (BOOL)cyl_isTabBarItemAnimationView;

@end

@interface CYLTabBar (CYLTabBarItemAnimation)

/// [EN] Plays the animation on `selectedControl`. [CN] 在 `selectedControl` 上播放动画。
- (void)cyl_playTabBarItemAnimationWithSelectedControl:(nullable UIControl *)selectedControl
                                                   URL:(nullable NSURL *)URL
                                                  size:(CGSize)size
                                       defaultSelected:(BOOL)defaultSelected
                                           contentMode:(UIViewContentMode)contentMode;

/// [EN] Stops the animations of every tab, selected-state layer included. [CN] 停止所有 Tab 的动画，包括选中态图层。
- (void)cyl_stopAllTabBarItemAnimations;

@end

/*!
 * FIX: issue #442
 * [EN] Implemented by Core (CYLConstants.m): registers the dark version and the dark colors of the light animation `URL`
 *      in Core's style registry (`CYLTabBarItemAnimationDefaultStyleSource()`); nil clears them.
 * [CN] 由 Core 实现（CYLConstants.m）：在 Core 的风格注册表（`CYLTabBarItemAnimationDefaultStyleSource()`）中注册浅色动画 `URL`
 *      的深色版本与深色颜色；nil 表示清除。
 */
FOUNDATION_EXTERN void CYLTabBarItemAnimationRegisterDarkStyle(NSURL *URL, NSURL * _Nullable darkURL,
                                                                NSDictionary<NSString *, UIColor *> * _Nullable darkColors);

/*!
 * [EN] Implemented by Core, for CYLTabBarController.m: the animation file of a tab item (`…URL`, else `…FilePath`, with
 *      `filePath` set to the latter), bound to the library its keys choose, with its Dark Mode version registered (#442).
 * [CN] 由 Core 实现，供 CYLTabBarController.m 使用：Tab item 的动画文件（`…URL`，否则为 `…FilePath`，并把后者写入 `filePath`），
 *      绑定到其 key 选择的动画库，并注册其深色模式版本（#442）。
 */
FOUNDATION_EXTERN NSURL * _Nullable CYLTabBarItemAnimationURLFromAttributes(NSDictionary * _Nullable attributes,
                                                                            NSString * _Nullable __autoreleasing * _Nullable filePath);

/*!
 * [EN] Implemented by Core, for the subspec: moves the layout tracking of `view` (#653) to `newView`, e.g. a Lottie view
 *      swapped for its Dark Mode version (#442).
 * [CN] 由 Core 实现，供子库使用：把 `view` 的布局跟踪（#653）改为跟随 `newView`，例如 Lottie 视图替换为深色版本时（#442）。
 */
@interface UIView (CYLTabBarItemAnimationCoreSupport)

- (void)cyl_replaceTrackedSubview:(UIView *)view withView:(UIView *)newView;

@end

NS_ASSUME_NONNULL_END
