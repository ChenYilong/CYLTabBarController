/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (CYLNavigationControllerExtention)

@property (nonatomic, assign, getter=cyl_disablePopGestureRecognizer, setter=cyl_setDisablePopGestureRecognizer:) BOOL cyl_disablePopGestureRecognizer;
@property (nonatomic, assign, getter=cyl_hideNavigationBarSeparator, setter=cyl_setHideNavigationBarSeparator:) BOOL cyl_hideNavigationBarSeparator;
@property (nonatomic, assign, getter=cyl_navigationBarHidden, setter=cyl_setNavigationBarHidden:) BOOL cyl_navigationBarHidden;
@property (nonatomic, assign, getter=cyl_hidesBottomBarWhenPushed, setter=cyl_setHidesBottomBarWhenPushed:) BOOL cyl_hidesBottomBarWhenPushed;

/*!
 * 使用方法：用在viewWillDisappear/dealloc
 * 作用：在左滑动的过渡的时间段内禁用interactivePopGestureRecognizer
 * [EN] Disables the interactive pop gesture during the swipe-back transition. Call in `viewWillDisappear` / `dealloc`.
 * [CN] 在左滑返回的过渡期间禁用 interactivePopGestureRecognizer，请在 viewWillDisappear / dealloc 中调用。
 */
- (void)cyl_disableInteractivePopGestureRecognizer;
/*!
 * use in viewDidDisappear
 * 作用：在左滑动的结束后启用interactivePopGestureRecognizer
 * [EN] Re-enables the interactive pop gesture after the swipe-back ends. Call in `viewDidDisappear`.
 * [CN] 左滑返回结束后重新启用 interactivePopGestureRecognizer，请在 viewDidDisappear 中调用。
 */
- (void)cyl_enableInteractivePopGestureRecognizer;
/*!
 * use in viewDidAppear
 * 当新的视图控制器加载完成后再启用
 * [EN] Enables or disables the pop gesture: disabled when `cyl_disablePopGestureRecognizer` is YES or this is the root controller. Call in `viewDidAppear`.
 * [CN] 重新设置返回手势：cyl_disablePopGestureRecognizer 为 YES 或当前为栈底控制器时禁用，否则启用。请在 viewDidAppear 中调用。
 */
- (void)cyl_resetInteractivePopGestureRecognizer;
/*!
 * use in viewWillAppear
 * [EN] Hides the navigation bar's bottom separator when `cyl_hideNavigationBarSeparator` is YES. Call in `viewWillAppear`.
 * [CN] 当 cyl_hideNavigationBarSeparator 为 YES 时隐藏导航栏底部分割线，请在 viewWillAppear 中调用。
 */
- (void)cyl_hideNavigationBarSeparatorIfNeeded;

/*!
 * [EN] Returns YES if the navigation bar should be shown again when this controller disappears (e.g. on pop). Call in `viewWillDisappear`.
 * [CN] 判断当前控制器消失时（如 Pop）是否应恢复显示导航栏，请在 viewWillDisappear 中使用。
 */
- (BOOL)cyl_shouldNavigationBarVisible;
//use in viewWillDisappear

/*!
 * [EN] Shows the navigation bar again if this controller hid it and it should become visible. Call in `viewWillDisappear`.
 * [CN] 若当前控制器隐藏了导航栏且需要恢复，则重新显示导航栏，请在 viewWillDisappear 中调用。
 */
- (void)cyl_setNavigationBarVisibleIfNeeded:(BOOL)animated;
//use in viewWillAppear

/*!
 * [EN] Hides the navigation bar when `cyl_navigationBarHidden` is YES. Call in `viewWillAppear`.
 * [CN] 当 cyl_navigationBarHidden 为 YES 时隐藏导航栏，请在 viewWillAppear 中调用。
 */
- (void)cyl_setNavigationBarHiddenIfNeeded:(BOOL)animated;

/*!
 * [EN] All-in-one setup for `viewWillAppear`: hides the separator and the navigation bar if needed.
 * [CN] viewWillAppear 中的一站式设置：按需隐藏导航栏分割线与导航栏。
 */
- (void)cyl_viewWillAppearNavigationSetting:(BOOL)animated;

/*!
 * [EN] All-in-one setup for `viewWillDisappear`: disables the pop gesture and restores the navigation bar if needed.
 * [CN] viewWillDisappear 中的一站式设置：禁用返回手势，并按需恢复导航栏。
 */
- (void)cyl_viewWillDisappearNavigationSetting:(BOOL)animated;

/*!
 * [EN] All-in-one setup for `viewDidDisappear`: re-enables the pop gesture.
 * [CN] viewDidDisappear 中的一站式设置：重新启用返回手势。
 */
- (void)cyl_viewDidDisappearNavigationSetting:(BOOL)animated;

/*!
 * [EN] All-in-one setup for `viewDidAppear`: resets the pop gesture state.
 * [CN] viewDidAppear 中的一站式设置：重置返回手势状态。
 */
- (void)cyl_viewDidAppearNavigationSetting:(BOOL)animated;

/*!
 * [EN] All-in-one setup for `dealloc`: disables the pop gesture.
 * [CN] dealloc 中的一站式设置：禁用返回手势。
 */
- (void)cyl_deallocNavigationSetting;

@end

NS_ASSUME_NONNULL_END
