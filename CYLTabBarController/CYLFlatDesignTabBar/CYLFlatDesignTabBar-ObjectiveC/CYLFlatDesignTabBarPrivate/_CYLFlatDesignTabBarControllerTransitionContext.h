//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface _CYLFlatDesignUITabBarControllerTransitionContext : NSObject<UIViewControllerContextTransitioning>

@property (nonatomic, copy) void(^completionBlock)(BOOL didComplete);

@property (nonatomic, assign, getter=isAnimated) BOOL animated;
@property (nonatomic, assign, getter=isInteractive) BOOL interactive;

- (instancetype)initWithSourceViewController:(nullable UIViewController *)sourceViewController
                   destinationViewController:(nullable __kindof UIViewController *)destinationViewController
                               containerView:(__kindof UIView *)containerView;

@end

NS_ASSUME_NONNULL_END
