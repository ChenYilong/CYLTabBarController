//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "CYLConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (CYLTabBarControllerExtention)

- (BOOL)cyl_isPlusButton;
- (BOOL)cyl_isTabButton;
- (BOOL)cyl_isTabImageView;
- (BOOL)cyl_isTabLabel;
- (BOOL)cyl_isTabBadgeView;
- (BOOL)cyl_isTabBackgroundView;
- (UIView *)cyl_tabBadgeView;
- (UIImageView *)cyl_tabImageView;
- (UILabel *)cyl_tabLabel;
- (UIImageView *)cyl_tabShadowImageView;
- (UIVisualEffectView *)cyl_tabEffectView;
- (BOOL)cyl_isLottieAnimationView;
- (UIView *)cyl_tabBackgroundView;
+ (UIView *)cyl_tabBadgePointViewWithClolor:(UIColor *)color radius:(CGFloat)radius;
- (NSArray *)cyl_allSubviews;

@end

@interface UIView (CYLTabBarControllerExtentionDeprecated)
- (UIView *)cyl_tabBadgeBackgroundView CYL_DEPRECATED("Deprecated in 1.6.0. Use `+[CYLPlusButton cyl_tabBackgroundView]` instead.");
- (UIView *)cyl_tabBadgeBackgroundSeparator CYL_DEPRECATED("Deprecated in 1.6.0. Use `+[CYLPlusButton cyl_tabShadowImageView]` instead.");


@end

NS_ASSUME_NONNULL_END
