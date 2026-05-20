//
//  _CYLFlatDesignTabBarControllerTransitionContext.h
//  CYLFlatDesignTabBarController
//
//  Created by apple on 2026/2/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface _CYLFlatDesignTabBarControllerTransitionContext : NSObject<UIViewControllerContextTransitioning>

@property (nonatomic, copy) void(^completionBlock)(BOOL didComplete);

@property (nonatomic, assign, getter=isAnimated) BOOL animated;
@property (nonatomic, assign, getter=isInteractive) BOOL interactive;

- (instancetype)initWithSourceViewController:(nullable UIViewController *)sourceViewController
                   destinationViewController:(nullable __kindof UIViewController *)destinationViewController
                               containerView:(__kindof UIView *)containerView;

@end

NS_ASSUME_NONNULL_END
