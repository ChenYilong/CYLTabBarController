/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2019 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (CYLNavigationControllerExtention)

@property (nonatomic, assign, getter=cyl_disablePopGestureRecognizer, setter=cyl_setDisablePopGestureRecognizer:) BOOL cyl_disablePopGestureRecognizer;
@property (nonatomic, assign, getter=cyl_hideNavigationBarSeparator, setter=cyl_setHideNavigationBarSeparator:) BOOL cyl_hideNavigationBarSeparator;
@property (nonatomic, assign, getter=cyl_navigationBarHidden, setter=cyl_setNavigationBarHidden:) BOOL cyl_navigationBarHidden;

/*!
 * 使用方法：用在viewWillDisappear/dealloc
 * 作用：在左滑动的过渡的时间段内禁用interactivePopGestureRecognizer
 */
- (void)cyl_disableInteractivePopGestureRecognizer;
/*!
 * use in viewDidDisappear
 * 作用：在左滑动的结束后启用interactivePopGestureRecognizer
 */
- (void)cyl_enableInteractivePopGestureRecognizer;
/*!
 * use in viewDidAppear
 * 当新的视图控制器加载完成后再启用
 */
- (void)cyl_resetInteractivePopGestureRecognizer;
/*!
 * use in viewWillAppear
 */
- (void)cyl_hideNavigationBarSeparatorIfNeeded;

- (BOOL)cyl_shouldNavigationBarVisible;
//use in viewWillDisappear
- (void)cyl_setNavigationBarVisibleIfNeeded:(BOOL)animated;
//use in viewWillAppear
- (void)cyl_setNavigationBarHiddenIfNeeded:(BOOL)animated;

- (void)cyl_viewWillAppearNavigationSetting:(BOOL)animated;
- (void)cyl_viewWillDisappearNavigationSetting:(BOOL)animated;
- (void)cyl_viewDidDisappearNavigationSetting:(BOOL)animated;
- (void)cyl_viewDidAppearNavigationSetting:(BOOL)animated;
- (void)cyl_deallocNavigationSetting;

@end

NS_ASSUME_NONNULL_END
