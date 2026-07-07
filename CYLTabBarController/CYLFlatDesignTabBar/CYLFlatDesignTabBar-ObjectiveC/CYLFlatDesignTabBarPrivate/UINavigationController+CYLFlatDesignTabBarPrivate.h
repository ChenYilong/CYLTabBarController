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
- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
   navigationBarDidChangeHeight:(CGFloat)height;

- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
         didBeginTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation;

- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
       didUpdateInteractiveFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                percentComplete:(CGFloat)percentComplete;

- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
       didUpdateInteractiveFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
           popGestureRecognizer:(UIGestureRecognizer *)popGestureRecognizer;

- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
          willEndTransitionFrom:(UIViewController *)fromVC
                             to:(UIViewController *)toVC
                      operation:(UINavigationControllerOperation)operation
                      cancelled:(BOOL)cancelled;

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

+ (void)cyl_navigationBarActionHook;

@end

NS_ASSUME_NONNULL_END
