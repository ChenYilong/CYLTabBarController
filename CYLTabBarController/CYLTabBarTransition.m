//
//  CYLTabBarTransition.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarTransition.h"

#pragma mark - CYLTabBarSlideTransitionAnimator

@implementation CYLTabBarSlideTransitionAnimator

- (instancetype)initWithTargetEdge:(UIRectEdge)targetEdge {
    if (self = [super init]) {
        _targetEdge = targetEdge;
        _duration = 0.35;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return self.duration;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey] ?: fromViewController.view;
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey] ?: toViewController.view;
    CGRect fromFrame = [transitionContext initialFrameForViewController:fromViewController];
    CGRect toFrame = [transitionContext finalFrameForViewController:toViewController];
    // [EN] -1: the old tab leaves to the left (the new one comes from the right); 1: the other way.
    // [CN] -1：旧 Tab 向左滑出（新 Tab 从右侧滑入）；1：反之。
    CGFloat offset = (self.targetEdge == UIRectEdgeRight) ? 1.0 : -1.0;

    fromView.frame = fromFrame;
    toView.frame = CGRectOffset(toFrame, -CGRectGetWidth(toFrame) * offset, 0);
    [transitionContext.containerView addSubview:toView];
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        fromView.frame = CGRectOffset(fromFrame, CGRectGetWidth(fromFrame) * offset, 0);
        toView.frame = toFrame;
    } completion:^(BOOL finished) {
        BOOL cancelled = [transitionContext transitionWasCancelled];
        if (cancelled) {
            fromView.frame = fromFrame;
        }
        [transitionContext completeTransition:!cancelled];
    }];
}

@end

#pragma mark - CYLTabBarInteractiveTransition

@interface CYLTabBarInteractiveTransition ()
@property (nonatomic, weak) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, assign) CGPoint initialTranslation;
@end

@implementation CYLTabBarInteractiveTransition

- (instancetype)initWithGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer {
    if (self = [super init]) {
        _gestureRecognizer = gestureRecognizer;
        [gestureRecognizer addTarget:self action:@selector(cyl_gestureRecognizerDidUpdate:)];
    }
    return self;
}

- (void)dealloc {
    [_gestureRecognizer removeTarget:self action:@selector(cyl_gestureRecognizerDidUpdate:)];
}

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    self.transitionContext = transitionContext;
    self.initialTranslation = [self.gestureRecognizer translationInView:transitionContext.containerView];
    [super startInteractiveTransition:transitionContext];
}

/// [EN] The progress, or -1 when the finger went back past the start. [CN] 进度；手指反向越过起点时为 -1。
- (CGFloat)cyl_percentForGestureRecognizer:(UIPanGestureRecognizer *)gestureRecognizer {
    UIView *containerView = self.transitionContext.containerView;
    CGFloat width = CGRectGetWidth(containerView.bounds);
    if (width <= 0) {
        return 0;
    }
    CGPoint translation = [gestureRecognizer translationInView:containerView];
    if ((translation.x > 0.0 && self.initialTranslation.x < 0.0) || (translation.x < 0.0 && self.initialTranslation.x > 0.0)) {
        return -1.0;
    }
    return fabs(translation.x) / width;
}

- (void)cyl_gestureRecognizerDidUpdate:(UIPanGestureRecognizer *)gestureRecognizer {
    CGFloat percent = [self cyl_percentForGestureRecognizer:gestureRecognizer];
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            break;
        case UIGestureRecognizerStateChanged:
            if (percent < 0.0) {
                [self cancelInteractiveTransition];
                [gestureRecognizer removeTarget:self action:@selector(cyl_gestureRecognizerDidUpdate:)];
            } else {
                [self updateInteractiveTransition:percent];
            }
            break;
        case UIGestureRecognizerStateEnded:
            if (percent >= 0.4) {
                [self finishInteractiveTransition];
            } else {
                [self cancelInteractiveTransition];
            }
            break;
        default:
            [self cancelInteractiveTransition];
            break;
    }
}

@end
