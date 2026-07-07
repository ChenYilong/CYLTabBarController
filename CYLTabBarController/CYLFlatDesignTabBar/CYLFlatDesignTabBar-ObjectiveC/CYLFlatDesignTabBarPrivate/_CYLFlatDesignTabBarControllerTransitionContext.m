//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "_CYLFlatDesignTabBarControllerTransitionContext.h"

@interface _CYLFlatDesignUITabBarControllerTransitionContext ()

@property (nullable, nonatomic, weak) __kindof UIViewController *sourceViewController;
@property (nullable, nonatomic, weak) __kindof UIViewController *destinationViewController;

@property (nonatomic, assign) CGAffineTransform targetTransform;

@end

@implementation _CYLFlatDesignUITabBarControllerTransitionContext {
    __weak __kindof UIView *_containerView;
}

- (instancetype)initWithSourceViewController:(UIViewController *)sourceViewController
                   destinationViewController:(__kindof UIViewController *)destinationViewController
                               containerView:(__kindof UIView *)containerView {
    if (self = [super init]) {
        self.sourceViewController = sourceViewController;
        self.destinationViewController = destinationViewController;
        self.targetTransform = CGAffineTransformIdentity;
        _containerView = containerView;
    }
    return self;
}

#pragma mark - UIViewControllerContextTransitioning

- (UIView *)containerView {
    return _containerView;
}

- (BOOL)transitionWasCancelled {
    return NO;
}

- (UIModalPresentationStyle)presentationStyle {
    return UIModalPresentationCustom;
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    
}

- (void)finishInteractiveTransition {
    
}

- (void)cancelInteractiveTransition {
    
}

- (void)pauseInteractiveTransition {
    
}

- (void)completeTransition:(BOOL)didComplete {
    if (self.completionBlock) {
        self.completionBlock(didComplete);
    }
}

- (__kindof UIViewController *)viewControllerForKey:(UITransitionContextViewControllerKey)key {
    if ([key isEqualToString:UITransitionContextFromViewControllerKey]) {
        return self.sourceViewController;
    } else if ([key isEqualToString:UITransitionContextToViewControllerKey]) {
        return self.destinationViewController;
    }
    return nil;
}

- (__kindof UIView *)viewForKey:(UITransitionContextViewKey)key {
    if ([key isEqualToString:UITransitionContextFromViewKey]) {
        return self.sourceViewController.view;
    } else if ([key isEqualToString:UITransitionContextToViewKey]) {
        return self.destinationViewController.view;
    }
    return nil;
}

- (CGRect)initialFrameForViewController:(UIViewController *)vc {
    return self.containerView.bounds;
}

- (CGRect)finalFrameForViewController:(UIViewController *)vc {
    return self.containerView.bounds;
}

@end
