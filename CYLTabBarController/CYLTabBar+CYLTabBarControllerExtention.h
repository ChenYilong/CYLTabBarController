/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2019 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "CYLTabBar.h"

NS_ASSUME_NONNULL_BEGIN

@interface CYLTabBar (CYLTabBarControllerExtention)

- (NSArray<UIControl *> *)cyl_visibleControls;
- (NSArray<UIControl *> *)cyl_subTabBarButtons;
- (NSArray<UIControl *> *)cyl_subTabBarButtonsWithoutPlusButton;
- (UIControl *)cyl_visibleControlWithIndex:(NSUInteger)index;
//- (UIControl *)cyl_subTabBarButtonWithIndex:(NSUInteger)index;
//- (void)cyl_animationLottieImageWithSelectedIndex:(NSUInteger)selectedIndex;
//- (void)cyl_animationLottieImageWithSelectedControl:(UIControl *)selectedControl;
- (void)cyl_animationLottieImageWithSelectedControl:(UIControl *)selectedControl
                                          lottieURL:(NSURL *)lottieURL
                                               size:(CGSize)size;
- (void)cyl_stopAnimationOfAllLottieView;
- (NSArray *)cyl_originalTabBarButtons;
//- (NSArray *)cyl_tabBarButtonFromTabBarSubviews:(NSArray *)tabBarSubviews;
//- (NSArray *)cyl_sortedSubviews;
- (BOOL)cyl_hasPlusChildViewController;

@end

NS_ASSUME_NONNULL_END
