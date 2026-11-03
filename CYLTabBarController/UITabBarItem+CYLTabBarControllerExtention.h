//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
// FIX: issue #535 — shared with CYLBadgeView through CYLUtils. 通过 CYLUtils 与 CYLBadgeView 共用。
#if __has_include("CYLUtils/UIBarItem+CYLUtils.h")
#import "CYLUtils/UIBarItem+CYLUtils.h"
#else
#import "UIBarItem+CYLUtils.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface UITabBarItem (CYLTabBarControllerExtention)

@property (nonatomic, readonly, nullable) UIControl *cyl_selectedTabButton;
@property (nonatomic, readonly) UIControl *cyl_visiableTabButton;
@property (nonatomic, strong, getter=cyl_lottieURL, setter=cyl_setLottieURL:) NSURL *cyl_lottieURL;

@property (nonatomic, strong, getter=cyl_lottieSizeValue, setter=cyl_setLottieSizeValue:) NSValue *cyl_lottieSizeValue;
@property (nonatomic, assign, getter=cyl_imagePositionAdjustment, setter=cyl_setImagePositionAdjustment:) UIOffset cyl_imagePositionAdjustment;

/**
 * 获取一个UITabBarItem内显示图标的UIImageView，如果找不到则返回nil
 * [EN] Returns the image view that shows this item's icon, or nil.
 * [CN] 返回该 Item 用于显示图标的图片视图，找不到时返回 nil。
 */
- (nullable UIImageView *)cyl_imageView;

/*!
 * [EN] Same as `-cyl_imageView`.
 * [CN] 同 -cyl_imageView。
 */
- (nullable UIImageView *)cyl_imageViewInTabBarButton;

@end

NS_ASSUME_NONNULL_END
