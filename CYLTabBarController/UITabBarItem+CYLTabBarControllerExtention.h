//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITabBarItem (CYLTabBarControllerExtention)

@property (nonatomic, readonly) UIControl *cyl_tabButton;
@property (nonatomic, readonly) UIControl *cyl_selectedTabButton;
@property (nonatomic, readonly) UIControl *cyl_visiableTabButton;
@property (nonatomic, strong, getter=cyl_lottieURL, setter=cyl_setLottieURL:) NSURL *cyl_lottieURL;
//@property (nonatomic, assign, getter=cyl_lottieSize, setter=cyl_setLottieSize:) CGRect cyl_lottieSize;
@property (nonatomic, strong, getter=cyl_lottieSizeValue, setter=cyl_setLottieSizeValue:) NSValue *cyl_lottieSizeValue;

/**
 * 获取一个UITabBarItem内显示图标的UIImageView，如果找不到则返回nil
 */
- (nullable UIImageView *)cyl_imageView;
- (nullable UIImageView *)cyl_imageViewInTabBarButton;
- (BOOL)cyl_isReady;

@end

NS_ASSUME_NONNULL_END
