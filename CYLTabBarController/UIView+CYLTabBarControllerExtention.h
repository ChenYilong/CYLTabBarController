//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView (CYLTabBarControllerExtention)

- (BOOL)cyl_isPlusButton;
- (BOOL)cyl_isTabButton;
- (BOOL)cyl_isTabImageView;
- (BOOL)cyl_isTabLabel;
- (BOOL)cyl_isTabBadgeView;
- (BOOL)cyl_isTabBackgroundView;
- (UIView *)cyl_tabBadgeBackgroundView;
- (UIView *)cyl_tabBadgeBackgroundSeparator;

+ (UIView *)cyl_tabBadgePointViewWithClolor:(UIColor *)color radius:(CGFloat)radius;

@end
