//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "_CYLFlatDesignTabBarControllerTransitionAnimator.h"

@implementation _CYLFlatDesignUITabBarControllerTransitionAnimator

#pragma mark - UIViewControllerAnimatedTransitioning

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *destinationViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    [transitionContext.containerView addSubview:destinationViewController.view];
    [transitionContext completeTransition:!transitionContext.transitionWasCancelled];
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.0;
}

@end
