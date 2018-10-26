//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIControl (CYLTabBarControllerExtention)

- (UIView *)cyl_tabBadgeView;
- (UIImageView *)cyl_tabImageView;
- (UILabel *)cyl_tabLabel;

/*!
 * 调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 */
- (void)cyl_showTabBadgePoint;
- (void)cyl_removeTabBadgePoint;
- (BOOL)cyl_isShowTabBadgePoint;

@property (nonatomic, strong, setter=cyl_setTabBadgePointView:, getter=cyl_tabBadgePointView) UIView *cyl_tabBadgePointView;
@property (nonatomic, assign, setter=cyl_setTabBadgePointViewOffset:, getter=cyl_tabBadgePointViewOffset) UIOffset cyl_tabBadgePointViewOffset;

@end
