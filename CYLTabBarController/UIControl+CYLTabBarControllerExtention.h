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
@class LOTAnimationView;
@interface UIControl (CYLTabBarControllerExtention)

/*!
 * [EN] Returns the Lottie animation view inside this tab button (searching two levels deep); nil for the plus button.
 * [CN] 返回 Tab 按钮内的 Lottie 动画视图（向下查找两层）；PlusButton 返回 nil。
 */
- (UIView *)cyl_lottieAnimationView;

/*!
 * [EN] Returns YES if the control is the plus button that has a child view controller added to the tab bar.
 * [CN] 判断当前控件是否为已添加子控制器的 PlusButton。
 */
- (BOOL)cyl_isChildViewControllerPlusButton;

/*!
 * [EN] Returns YES if the control is selected and its tab is the tab bar controller's selected index.
 * [CN] 判断当前控件是否处于选中状态，且对应的 Tab 为 TabBarController 当前选中的索引。
 */
- (BOOL)cyl_isSelected;

/*!
 * [EN] Returns YES if the Lottie animation view has been added and laid out.
 * [CN] 判断 Lottie 动画视图是否已添加并完成布局。
 */
- (BOOL)cyl_isLottieReady;

/*!
 * [EN] Returns YES if the control is the plus button (the registered plus button class, or the plus child view controller's button).
 * [CN] 判断当前控件是否为 PlusButton（已注册的 PlusButton 类，或 PlusButton 子控制器对应的按钮）。
 */
- (BOOL)cyl_isPlusControl;

/*!
 * PlusButton without plusViewController equals NSNotFound
 */
@property (nonatomic, assign, getter=cyl_tabBarChildViewControllerIndex, setter=cyl_setTabBarChildViewControllerIndex:) NSInteger cyl_tabBarChildViewControllerIndex;

/*!
 * PlusButton has its own visible index,
 * in this case PlusButton is same as TabBarItem
 */
@property (nonatomic, assign, getter=cyl_tabBarItemVisibleIndex, setter=cyl_setTabBarItemVisibleIndex:) NSInteger cyl_tabBarItemVisibleIndex;
/*!
 *
 *对于- (void)tabBarController:(CYLTabBarController *)tabBarController didSelectControl:(UIControl *)control;
 *   // 即使 PlusButton 也添加了自定义点击事件，点击 PlusButton 后也会触发该代理方法。
    // 可在PlusButton初始化时使用 CYLExternPlusButton.cyl_shouldNotSelect = YES; 来禁止该协议方法触发plusButton回调
 */
@property (nonatomic, assign, getter=cyl_shouldNotSelect, setter=cyl_setShouldNotSelect:) BOOL cyl_shouldNotSelect;
/*!
 * same as cyl_userInteractionDisabled.
 *对于- (void)tabBarController:(CYLTabBarController *)tabBarController didSelectControl:(UIControl *)control;
 *   // 即使 PlusButton 也添加了自定义点击事件，点击 PlusButton 后也会触发该代理方法。
    // 可在PlusButton初始化时使用 CYLExternPlusButton.cyl_userInteractionDisabled = YES; 来禁止该协议方法触发plusButton回调
 */
@property (nonatomic, assign, getter=cyl_userInteractionDisabled, setter=cyl_setUserInteractionDisabled:) BOOL cyl_userInteractionDisabled;

/*!
 * [EN] Adds a Lottie animation view loaded from `lottieURL` in place of the tab image; does nothing if one already exists or for the plus button.
 * [CN] 用 lottieURL 加载 Lottie 动画视图并替换 Tab 图片；已存在动画视图或为 PlusButton 时不做处理。
 */
- (void)cyl_addLottieImageWithLottieURL:(NSURL *)lottieURL
                                   size:(CGSize)size
                            contentMode:(UIViewContentMode)contentMode;

/*!
 * [EN] Adds a Lottie animation view loaded from a local file path in place of the tab image; a zero `size` uses the default placeholder size.
 * [CN] 用本地文件路径加载 Lottie 动画视图并替换 Tab 图片；size 为 CGSizeZero 时使用默认占位尺寸。
 */
- (void)cyl_addLottieImageWithLottieFilePath:(NSString *)lottieFilePath
                                   size:(CGSize)size
                            contentMode:(UIViewContentMode)contentMode;

/*!
 * [EN] Plays the Lottie animation for this tab (adding the view if needed); shows the final frame instead when `defaultSelected` is YES.
 * [CN] 播放当前 Tab 的 Lottie 动画（必要时先添加视图）；defaultSelected 为 YES 时直接显示最后一帧。
 */
- (void)cyl_animationLottieImageWithLottieURL:(NSURL *)lottieURL
                                         size:(CGSize)size
                              defaultSelected:(BOOL)defaultSelected
                                  contentMode:(UIViewContentMode)contentMode;

/*!
 * [EN] Stops this tab's Lottie animation if it has started.
 * [CN] 若当前 Tab 的 Lottie 动画已开始播放，则停止。
 */
- (void)cyl_stopAnimationOfLottieView;

/*!
 * [EN] Replaces the tab image view with `newView`.
 * [CN] 用 newView 替换 Tab 按钮的图片视图。
 */
- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                                      show:(BOOL)show;

/*!
 * [EN] Replaces the tab image view with `newView` at `offset`, calling `completion` with the result.
 * [CN] 用 newView 替换 Tab 按钮的图片视图并应用 offset 偏移，完成后通过 completion 回调结果。
 */
- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)show
                                completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

/*!
 * [EN] Replaces the whole tab button with `newView` and hides the original image view.
 * [CN] 用 newView 替换整个 Tab 按钮，并隐藏原图片视图。
 */
- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                   show:(BOOL)show;


/*!
 * [EN] Replaces the whole tab button with `newView` at `offset`, calling `completion` with the result.
 * [CN] 用 newView 替换整个 Tab 按钮并应用 offset 偏移，完成后通过 completion 回调结果。
 */
- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                 offset:(UIOffset)offset
                                   show:(BOOL)theShow
                             completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

/*!
 * [EN] Returns YES if the control is a Liquid Glass platter selected-state control.
 * [CN] 判断当前控件是否为液态玻璃 Platter 中的选中态控件。
 */
- (BOOL)cyl_isPlatterSelectedControl;

/*!
 * [EN] Returns the platter selected-state control matching this control, or self if none.
 * [CN] 返回与当前控件对应的 Platter 选中态控件，没有则返回自身。
 */
- (UIControl *)cyl_platterSelectedControl;

/*!
 * [EN] Returns YES if the control lives in the platter content view (normal state).
 * [CN] 判断当前控件是否位于 Platter 内容视图中（常态控件）。
 */
- (BOOL)cyl_isPlatterNormalControl;

/*!
 * [EN] Returns the platter normal-state control matching this control, or self if none.
 * [CN] 返回与当前控件对应的 Platter 常态控件，没有则返回自身。
 */
- (UIControl *)cyl_platterNormalControl;

/*!
 * [EN] Covers the tab image view (or the whole button) with `newView` without hiding the original; waits `delay` seconds if the button is not ready yet (e.g. Lottie still loading).
 * [CN] 用 newView 覆盖 Tab 图片视图（或整个按钮），不隐藏原视图；按钮未就绪（如 Lottie 未初始化完成）时延迟 delay 秒执行。
 */
- (void)cyl_coverTabImageViewOrTabButton:(BOOL)isTabButton
                                 newView:(UIView *)newView
                                  offset:(UIOffset)offset
                                    show:(BOOL)theShow
                 delayIfNeededForSeconds:(CGFloat)delay
                              completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

/*!
 * [EN] Same as `-cyl_coverTabImageViewOrTabButton:...`, applied to the platter selected-state control (or self).
 * [CN] 同 -cyl_coverTabImageViewOrTabButton:...，但作用于 Platter 选中态控件（没有则作用于自身）。
 */
- (void)cyl_coverSeclectContentTabImageViewOrTabButton:(BOOL)isTabButton
                               newView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                           delayIfNeededForSeconds:(CGFloat)delay
                                            completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

/*!
 * [EN] Covers the visible tab image view (or button) with `newView`; forwards to the selected-content variant.
 * [CN] 用 newView 覆盖当前可见的 Tab 图片视图（或按钮），内部转调选中态内容的覆盖方法。
 */
- (void)cyl_coverVisiableTabImageViewOrTabButton:(BOOL)isTabButton
                                         newView:(UIView *)newView
                                          offset:(UIOffset)offset
                                            show:(BOOL)theShow
                         delayIfNeededForSeconds:(CGFloat)delay
                                      completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

/*!
 * [EN] Covers the normal-state content with `contentNewView` and the selected-state content with `seclectContentNewView`.
 * [CN] 分别用 contentNewView 覆盖常态内容、用 seclectContentNewView 覆盖选中态内容。
 */
- (void)cyl_coverVisiableTabImageViewOrTabButton:(BOOL)isTabButton
                                  contentNewView:(UIView *)contentNewView
                           seclectContentNewView:(UIView *)seclectContentNewView
                                          offset:(UIOffset)offset
                                            show:(BOOL)theShow
                         delayIfNeededForSeconds:(CGFloat)delay
                                      completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

/*!
 * [EN] Hides the control and its selected-state counterpart, including labels and images, and disables their interaction.
 * [CN] 隐藏当前控件及其选中态对应控件（包括标题与图片），并禁用交互。
 */
- (void)cyl_hideControl;

@end

@interface UIControl (CYLTabBarControllerExtentionDeprecated)

@property (nonatomic, strong, setter=cyl_setTabBadgePointView:, getter=cyl_tabBadgePointView) UIView *cyl_tabBadgePointView CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
@property (nonatomic, assign, setter=cyl_setTabBadgePointViewOffset:, getter=cyl_tabBadgePointViewOffset) UIOffset cyl_tabBadgePointViewOffset CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
/*!
 * *  调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 * @attention 已经废弃，请改用`-[UIViewController cyl_showBadgeValue:animationType:]`
 * [EN] Deprecated. Shows the red-dot badge. Use `-[UIViewController cyl_showBadgeValue:animationType:]` instead.
 * [CN] 已废弃。显示红点角标，请改用 -[UIViewController cyl_showBadgeValue:animationType:]。
 */
- (void)cyl_showTabBadgePoint CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
/*!
 * *  调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 * @attention 已经废弃，请改用`-[UIViewController cyl_showBadgeValue:animationType:]`
 * [EN] Deprecated. Removes the red-dot badge. Use `-[UIViewController cyl_clearBadge]` instead.
 * [CN] 已废弃。移除红点角标，请改用 -[UIViewController cyl_clearBadge]。
 */
- (void)cyl_removeTabBadgePoint CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
/*!
 * *  调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 * @attention 已经废弃，请改用`-[UIViewController cyl_showBadgeValue:animationType:]`
 * [EN] Deprecated. Returns YES if the red-dot badge is shown. Use `-[UIViewController cyl_isShowBadge]` instead.
 * [CN] 已废弃。判断红点角标是否显示，请改用 -[UIViewController cyl_isShowBadge]。
 */
- (BOOL)cyl_isShowTabBadgePoint CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");

@end

NS_ASSUME_NONNULL_END
