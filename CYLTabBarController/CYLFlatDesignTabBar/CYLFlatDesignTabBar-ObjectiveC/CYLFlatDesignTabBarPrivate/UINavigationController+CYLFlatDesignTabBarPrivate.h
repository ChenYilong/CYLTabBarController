//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol UINavigationControllerExtensionDelegate <NSObject>

@required

/*!
 * [EN] Called when the navigation bar height changes; `height` includes the top safe area.
 * [CN] 导航栏高度变化时回调，height 包含顶部安全区。
 */
- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
   navigationBarDidChangeHeight:(CGFloat)height;

/*!
 * [EN] Called when a push/pop transition from `fromVC` to `toVC` begins.
 * [CN] 从 fromVC 到 toVC 的 Push/Pop 转场开始时回调。
 */
- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
         didBeginTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation;

/*!
 * [EN] Called as an interactive pop progresses, with its completion percentage.
 * [CN] 交互式返回进行中回调，携带完成百分比。
 */
- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
       didUpdateInteractiveFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                percentComplete:(CGFloat)percentComplete;

/*!
 * [EN] Called as an interactive pop progresses, with the driving gesture recognizer.
 * [CN] 交互式返回进行中回调，携带驱动转场的手势识别器。
 */
- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
       didUpdateInteractiveFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
           popGestureRecognizer:(UIGestureRecognizer *)popGestureRecognizer;

/*!
 * [EN] Called when a transition is about to end; `cancelled` tells whether it was cancelled.
 * [CN] 转场即将结束时回调，cancelled 表示是否被取消。
 */
- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
          willEndTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation
                      cancelled:(BOOL)cancelled;

/*!
 * [EN] Called after a transition ends; `cancelled` tells whether it was cancelled.
 * [CN] 转场结束后回调，cancelled 表示是否被取消。
 */
- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
           didEndTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation
                      cancelled:(BOOL)cancelled;

@end

@interface UINavigationController (CYLFlatDesignTabBarPrivate)

/**
 当有自定义全屏返回手势时，需要设置该值（比如一些第三方实现的全屏返回手势）
 用系统自带pop返回手势，则不用管
 */
@property (nonatomic, strong, nullable, getter=cylflatdesign_customPopGestureRecognizer, setter=cylflatdesign_setCustomPopGestureRecognizer:) UIGestureRecognizer *cylflatdesign_customPopGestureRecognizer;

/*!
 * [EN] Swizzles the navigation controller's pop methods (once) so the flat-design tab bar can follow push/pop transitions.
 * [CN] （只执行一次）Hook 导航控制器的 Pop 系列方法，使扁平化 TabBar 能跟随 Push/Pop 转场。
 */
+ (void)cyl_navigationBarActionHook;

@end

NS_ASSUME_NONNULL_END
