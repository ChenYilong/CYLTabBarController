//
//  UIControl+CYLTabBarItemAnimation.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLTabBar.h"
#import "CYLTabBarItemAnimationService.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #604 — private header of Core, not part of the public API.
 * [EN] Library-neutral tab icon animation for Core's code. Core implements these categories by handing every call to
 *      the `CYLTabBarItemAnimationService` (`CYLTabBarItemAnimationService.h`) injected by the `CYLTabBarItemAnimation`
 *      subspec; without it they do nothing. The public Lottie-named methods (`-cyl_addLottieImageWithLottieURL:…`,
 *      `-cyl_lottieAnimationView`…) call them.
 * [CN] 供 Core 代码使用的、与动画库无关的 Tab 图标动画方法。Core 实现这些分类，把每个调用交给 `CYLTabBarItemAnimation` 子库注入的
 *      `CYLTabBarItemAnimationService`（`CYLTabBarItemAnimationService.h`）；没有注入时不做处理。公开的 Lottie 命名方法
 *      （`-cyl_addLottieImageWithLottieURL:…`、`-cyl_lottieAnimationView`…）调用它们。
 */
@interface UIControl (CYLTabBarItemAnimation)

/// [EN] The tab's animation view (searching two levels deep); nil for the plus button. [CN] Tab 的动画视图（向下查找两层）；PlusButton 返回 nil。
- (nullable UIView *)cyl_tabBarItemAnimationView;

/// [EN] YES once the animation view has been added and laid out. [CN] 动画视图已添加并完成布局时返回 YES。
- (BOOL)cyl_isTabBarItemAnimationReady;

/// [EN] Adds the animation at `URL` (a local file) in place of the tab's icon, once; a zero `size` uses the placeholder size.
/// [CN] 用 `URL`（本地文件）的动画替换 Tab 图标显示（只添加一次）；size 为 CGSizeZero 时使用占位尺寸。
- (void)cyl_addTabBarItemAnimationWithURL:(nullable NSURL *)URL
                                     size:(CGSize)size
                              contentMode:(UIViewContentMode)contentMode;

/// [EN] The same, and sets `animationSpeed` when this call adds the view (#428). [CN] 同上，本次调用新添加视图时设置 `animationSpeed`（#428）。
- (void)cyl_addTabBarItemAnimationWithURL:(nullable NSURL *)URL
                                     size:(CGSize)size
                              contentMode:(UIViewContentMode)contentMode
                           animationSpeed:(CGFloat)animationSpeed;

/// [EN] Sets the playback speed; nothing for a value of 0 or less, or a library without speed. [CN] 设置播放速度；小于等于 0 或动画库没有播放速度时不做处理。
- (void)cyl_setTabBarItemAnimationSpeed:(CGFloat)animationSpeed;

/// [EN] Swaps the view for the version of its animation matching the current style (#442). [CN] 将视图替换为与当前界面风格相符的动画版本（#442）。
- (void)cyl_reloadTabBarItemAnimationViewForCurrentStyle;

/// [EN] Adds the animation if needed and plays it (`defaultSelected`: shows its last frame). [CN] 必要时添加动画并播放（`defaultSelected`：显示最后一帧）。
- (void)cyl_playTabBarItemAnimationWithURL:(NSURL *)URL
                                      size:(CGSize)size
                           defaultSelected:(BOOL)defaultSelected
                               contentMode:(UIViewContentMode)contentMode;

/// [EN] Stops the tab's animation if it has started. [CN] 若 Tab 的动画已开始播放，则停止。
- (void)cyl_stopTabBarItemAnimation;

@end

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
