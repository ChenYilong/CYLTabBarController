/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "UIView+CYLBadgeExtention.h"
#import "CYLBadgeProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIControl (CYLBadgeExtention)<CYLBadgeProtocol>

/*!
 * [EN] Returns YES if a badge is currently shown on this control.
 * [CN] 判断当前控件上是否正在显示角标。
 */
- (BOOL)cyl_isShowBadge;
/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 * [EN] Shows a red-dot badge on this control with no animation.
 * [CN] 在当前控件上显示红点角标，无动画。
 */
- (void)cyl_showBadge;

/**
 *
 *  @param value String value, default is `nil`. if value equal @"" means red dot style.
 *  @param animationType animationType
 *  @attention
                - 调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
                - 不支持 CYLPlusChildViewController 对应的 TabBarItem 角标设置，调用会被忽略。
 * [EN] Shows a badge with `value` (@"" for a red dot) and the given animation on this control.
 * [CN] 在当前控件上显示值为 value 的角标（传 @"" 为红点），并使用指定动画。
 */
- (void)cyl_showBadgeValue:(NSString *)value
             animationType:(CYLBadgeAnimationType)animationType;

/**
 *  clear badge(hide badge)
 * [EN] Hides the badge on this control.
 * [CN] 隐藏当前控件上的角标。
 */
- (void)cyl_clearBadge;

/**
 *  make bage(if existing) not hiden
 * [EN] Shows the badge again if one exists and was hidden.
 * [CN] 若角标存在且被隐藏，则重新显示。
 */
- (void)cyl_resumeBadge;

/*!
 * [EN] Returns YES if the badge is paused (hidden but kept).
 * [CN] 判断角标是否处于暂停（隐藏但保留）状态。
 */
- (BOOL)cyl_isPauseBadge;

@end

NS_ASSUME_NONNULL_END

