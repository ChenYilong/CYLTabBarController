//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLConstants.h"

NS_ASSUME_NONNULL_BEGIN
/*!
 * [EN] `UIControl (CYLTabBarControllerExtention)` and `UIControl (CYLTabBarControllerExtentionDeprecated)` are implemented in
 *      Swift (`Swift/UIControl+CYLTabBarControllerExtention.swift`, every selector kept) and declared by the generated Swift
 *      interface (`CYLSwiftInterface.h`), imported at the end of this header (docs/Swift-Migration.md, step 26).
 * [CN] `UIControl (CYLTabBarControllerExtention)` 与 `UIControl (CYLTabBarControllerExtentionDeprecated)` 在 Swift 中实现
 *      （`Swift/UIControl+CYLTabBarControllerExtention.swift`，所有 selector 不变），由 Swift 生成接口（`CYLSwiftInterface.h`）声明，
 *      该接口在本头文件末尾导入（docs/Swift-Migration.md，第 26 步）。
 */

/*!
 * FIX: issue #604
 * [EN] Library-neutral tab icon animation (Lottie, PAG, Rive…). Every call goes to the animation service of the
 *      `CYLTabBarItemAnimation` subspec; without an animation subspec they do nothing. They replace the deprecated
 *      Lottie-named methods above (`-cyl_lottieAnimationView`, `-cyl_addLottieImageWithLottieURL:…`…).
 * [CN] 与动画库无关的 Tab 图标动画方法（Lottie、PAG、Rive…）。每个调用都交给 `CYLTabBarItemAnimation` 子库的动画服务；没有引入
 *      动画子库时不做处理。它们取代上面已废弃的 Lottie 命名方法（`-cyl_lottieAnimationView`、`-cyl_addLottieImageWithLottieURL:…`…）。
 */
@interface UIControl (CYLTabBarItemAnimation)

#ifndef __swift__ // [EN] Implemented in Swift (Swift/UIControl+CYLTabBarItemAnimation.swift). [CN] 在 Swift 中实现。
/*!
 * [EN] The tab's animation view (searching two levels deep); nil for the plus button. [CN] Tab 的动画视图（向下查找两层）；PlusButton 返回 nil。
 */
- (nullable UIView *)cyl_tabBarItemAnimationView;

/*!
 * [EN] YES once the animation view has been added and laid out. [CN] 动画视图已添加并完成布局时返回 YES。
 */
- (BOOL)cyl_isTabBarItemAnimationReady;

/*!
 * [EN] Adds the animation at `URL` (a local file) in place of the tab's icon, once; a zero `size` uses the placeholder size.
 * [CN] 用 `URL`（本地文件）的动画替换 Tab 图标显示（只添加一次）；size 为 CGSizeZero 时使用占位尺寸。
 */
- (void)cyl_addTabBarItemAnimationWithURL:(nullable NSURL *)URL
                                     size:(CGSize)size
                              contentMode:(UIViewContentMode)contentMode;

/*!
 * [EN] The same, and sets `animationSpeed` when this call adds the view (#428). [CN] 同上，本次调用新添加视图时设置 `animationSpeed`（#428）。
 */
- (void)cyl_addTabBarItemAnimationWithURL:(nullable NSURL *)URL
                                     size:(CGSize)size
                              contentMode:(UIViewContentMode)contentMode
                           animationSpeed:(CGFloat)animationSpeed;

/*!
 * [EN] Sets the playback speed; nothing for a value of 0 or less, or a library without speed. [CN] 设置播放速度；小于等于 0 或动画库没有播放速度时不做处理。
 */
- (void)cyl_setTabBarItemAnimationSpeed:(CGFloat)animationSpeed;

/*!
 * [EN] Swaps the view for the version of its animation matching the current style (#442). [CN] 将视图替换为与当前界面风格相符的动画版本（#442）。
 */
- (void)cyl_reloadTabBarItemAnimationViewForCurrentStyle;

/*!
 * FIX: issue #216
 * [EN] Replaces the animation of this tab button by the one at `URL`, keeping the playback state (a theme that gives the
 *      tab another file); adds it when the button has none. `-updateTabBarItemsWithAttributes:` calls it for an
 *      animation key, so a `CYLTabBarTheme` does not need to.
 * [CN] 把本 Tab 按钮的动画替换为 `URL` 的动画并保留播放状态（主题为该 Tab 指定了另一个文件）；按钮没有动画时添加。
 *      `-updateTabBarItemsWithAttributes:` 遇到动画 key 时会调用它，`CYLTabBarTheme` 无需自己调用。
 */
- (void)cyl_replaceTabBarItemAnimationWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode;

/*!
 * FIX: issue #216
 * [EN] Applies the colors registered for this tab button's animation again (`CYLTabBarAnimationColors`, resolved for the
 *      current theme, plus the dark colors in Dark Mode). Called for you on every theme change.
 * [CN] 重新应用为本 Tab 按钮动画注册的颜色（按当前主题解析的 `CYLTabBarAnimationColors`，深色模式下加上深色颜色）。每次主题切换时会自动调用。
 */
- (void)cyl_refreshTabBarItemAnimationColors;

/*!
 * [EN] Adds the animation if needed and plays it (`defaultSelected`: shows its last frame). [CN] 必要时添加动画并播放（`defaultSelected`：显示最后一帧）。
 */
- (void)cyl_playTabBarItemAnimationWithURL:(NSURL *)URL
                                      size:(CGSize)size
                           defaultSelected:(BOOL)defaultSelected
                               contentMode:(UIViewContentMode)contentMode;

/*!
 * [EN] Stops the tab's animation if it has started. [CN] 若 Tab 的动画已开始播放，则停止。
 */
- (void)cyl_stopTabBarItemAnimation;
#endif

@end

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
