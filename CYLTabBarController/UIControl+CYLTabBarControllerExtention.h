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

- (UIView *)cyl_lottieAnimationView;
- (BOOL)cyl_isChildViewControllerPlusButton;

- (BOOL)cyl_isSelected;

- (BOOL)cyl_isLottieReady;

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

- (void)cyl_addLottieImageWithLottieURL:(NSURL *)lottieURL
                                   size:(CGSize)size
                            contentMode:(UIViewContentMode)contentMode;
- (void)cyl_addLottieImageWithLottieFilePath:(NSString *)lottieFilePath
                                   size:(CGSize)size
                            contentMode:(UIViewContentMode)contentMode;

- (void)cyl_animationLottieImageWithLottieURL:(NSURL *)lottieURL
                                         size:(CGSize)size
                              defaultSelected:(BOOL)defaultSelected
                                  contentMode:(UIViewContentMode)contentMode;

- (void)cyl_stopAnimationOfLottieView;

- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                                      show:(BOOL)show;

- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)show
                                completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                   show:(BOOL)show;


- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                 offset:(UIOffset)offset
                                   show:(BOOL)theShow
                             completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

- (BOOL)cyl_isPlatterSelectedControl;
- (UIControl *)cyl_platterSelectedControl;
- (BOOL)cyl_isPlatterNormalControl;
- (UIControl *)cyl_platterNormalControl;

- (void)cyl_coverTabImageViewOrTabButton:(BOOL)isTabButton
                                 newView:(UIView *)newView
                                  offset:(UIOffset)offset
                                    show:(BOOL)theShow
                 delayIfNeededForSeconds:(CGFloat)delay
                              completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

- (void)cyl_coverSeclectContentTabImageViewOrTabButton:(BOOL)isTabButton
                               newView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                           delayIfNeededForSeconds:(CGFloat)delay
                                            completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

- (void)cyl_coverVisiableTabImageViewOrTabButton:(BOOL)isTabButton
                                         newView:(UIView *)newView
                                          offset:(UIOffset)offset
                                            show:(BOOL)theShow
                         delayIfNeededForSeconds:(CGFloat)delay
                                      completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

- (void)cyl_coverVisiableTabImageViewOrTabButton:(BOOL)isTabButton
                                  contentNewView:(UIView *)contentNewView
                           seclectContentNewView:(UIView *)seclectContentNewView
                                          offset:(UIOffset)offset
                                            show:(BOOL)theShow
                         delayIfNeededForSeconds:(CGFloat)delay
                                      completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;
- (void)cyl_hideControl;

@end

@interface UIControl (CYLTabBarControllerExtentionDeprecated)

@property (nonatomic, strong, setter=cyl_setTabBadgePointView:, getter=cyl_tabBadgePointView) UIView *cyl_tabBadgePointView CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
@property (nonatomic, assign, setter=cyl_setTabBadgePointViewOffset:, getter=cyl_tabBadgePointViewOffset) UIOffset cyl_tabBadgePointViewOffset CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
/*!
 * *  调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 * @attention 已经废弃，请改用`-[UIViewController cyl_showBadgeValue:animationType:]`
 */
- (void)cyl_showTabBadgePoint CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
/*!
 * *  调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 * @attention 已经废弃，请改用`-[UIViewController cyl_showBadgeValue:animationType:]`
 */
- (void)cyl_removeTabBadgePoint CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
/*!
 * *  调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 * @attention 已经废弃，请改用`-[UIViewController cyl_showBadgeValue:animationType:]`
 */
- (BOOL)cyl_isShowTabBadgePoint CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");

@end

NS_ASSUME_NONNULL_END
