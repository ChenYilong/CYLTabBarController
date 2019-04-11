/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2019 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "UIView+CYLBadgeExtention.h"
#import "CYLBadgeProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface UITabBarItem (CYLBadgeExtention)<CYLBadgeProtocol>

- (BOOL)cyl_isShowBadge;
/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 */
- (void)cyl_showBadge;

/**
 *
 *  @param value String value, default is `nil`. if value equal @"" means red dot style.
 *  @param animationType
 *  @attention
                - 调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
                - 不支持 CYLPlusChildViewController 对应的 TabBarItem 角标设置，调用会被忽略。
 */
- (void)cyl_showBadgeValue:(NSString *)value
             animationType:(CYLBadgeAnimationType)animationType;

/**
 *  clear badge(hide badge)
 */
- (void)cyl_clearBadge;

/**
 *  make bage(if existing) not hiden
 */
- (void)cyl_resumeBadge;

- (BOOL)cyl_isPauseBadge;

@end

NS_ASSUME_NONNULL_END

