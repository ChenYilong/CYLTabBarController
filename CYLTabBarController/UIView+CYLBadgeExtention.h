/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2019 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "CYLBadgeProtocol.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -- badge apis

@interface UIView (CYLBadgeExtention)<CYLBadgeProtocol>

- (BOOL)cyl_isShowBadge;

/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 */
- (void)cyl_showBadge;

/**
 *  cyl_showBadge
 *
 *  @param value String value, default is `nil`. if value equal @"" means red dot style.
 *  @param animationType
 */
- (void)cyl_showBadgeValue:(NSString *)value
         animationType:(CYLBadgeAnimationType)animationType;
;

// wBadgeStyle default is CYLBadgeStyleNumber ;
// CYLBadgeAnimationType defualt is  CYLBadgeAnimationTypeNone
- (void)cyl_showBadgeValue:(NSString *)value;

/**
 *  clear badge(hide badge)
 */
- (void)cyl_clearBadge;

/**
 *  make bage(if existing) not hiden
 */
- (void)cyl_resumeBadge;

- (BOOL)cyl_isPauseBadge;

- (BOOL)cyl_isInvisiable;
- (BOOL)cyl_canNotResponseEvent;

@end

NS_ASSUME_NONNULL_END

