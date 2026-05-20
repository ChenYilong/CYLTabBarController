//
//  UINavigationController+CYLFlatDesignTabBarPrivate.m
//  CYLFlatDesignTabBarController
//
//  Created by apple on 2026/2/10.
//

#import "UINavigationController+CYLFlatDesignTabBarPrivate.h"
#import "CYLFlatDesignTabBarController.h"
#import "CYLFlatDesignTabViewController.h"
#import <objc/runtime.h>

void _CYLFlatDesignTabBarSwizzleMethod(Class class, SEL originalSelector, SEL swizzledSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL const success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (success) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@interface UINavigationController ()

// UINavigationController扩展代理
@property (nonatomic, weak, getter=cylflatdesign_extensionDelegate, setter=cylflatdesign_setExtensionDelegate:) id<UINavigationControllerExtensionDelegate> cylflatdesign_extensionDelegate;

// 是否嵌套在CYLFlatDesignTabBarController中

@property (nonatomic, assign, getter=cylflatdesign_nestedInCYLFlatDesignTabBarController, setter=cylflatdesign_setNestedInCYLFlatDesignTabBarController:) BOOL cylflatdesign_nestedInCYLFlatDesignTabBarController;


// 标志导航控制器Pop手势是否注册
@property (nonatomic, assign, getter=cylflatdesign_interactivePopGestureRecognizerRegistered, setter=cylflatdesign_setInteractivePopGestureRecognizerRegistered:) BOOL cylflatdesign_interactivePopGestureRecognizerRegistered;

@end

@implementation UINavigationController (CYLFlatDesignTabBarPrivate)

#pragma mark Getters & Setters

- (id<UINavigationControllerExtensionDelegate>)cylflatdesign_extensionDelegate {
    id<UINavigationControllerExtensionDelegate> extensionDelegate = objc_getAssociatedObject(self, @selector(cylflatdesign_extensionDelegate));
    return extensionDelegate;
}

- (void)cylflatdesign_setExtensionDelegate:(id<UINavigationControllerExtensionDelegate>)extensionDelegate {
    id<UINavigationControllerExtensionDelegate> extensionDelegate_ = extensionDelegate;
    objc_setAssociatedObject(self, @selector(cylflatdesign_extensionDelegate), extensionDelegate_, OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)cylflatdesign_nestedInCYLFlatDesignTabBarController {
    NSNumber *nestedInCYLFlatDesignTabBarControllerObject = objc_getAssociatedObject(self, @selector(cylflatdesign_nestedInCYLFlatDesignTabBarController));
    return [nestedInCYLFlatDesignTabBarControllerObject boolValue];
}

- (void)cylflatdesign_setNestedInCYLFlatDesignTabBarController:(BOOL)nestedInCYLFlatDesignTabBarController {
    NSNumber *nestedInCYLFlatDesignTabBarControllerObject = @(nestedInCYLFlatDesignTabBarController);
    objc_setAssociatedObject(self, @selector(cylflatdesign_nestedInCYLFlatDesignTabBarController), nestedInCYLFlatDesignTabBarControllerObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cylflatdesign_interactivePopGestureRecognizerRegistered {
    NSNumber *interactivePopGestureRecognizerRegisteredObject = objc_getAssociatedObject(self, @selector(cylflatdesign_interactivePopGestureRecognizerRegistered));
    return [interactivePopGestureRecognizerRegisteredObject boolValue];
}

- (void)cylflatdesign_setInteractivePopGestureRecognizerRegistered:(BOOL)interactivePopGestureRecognizerRegistered {
    NSNumber *interactivePopGestureRecognizerRegisteredObject = @(interactivePopGestureRecognizerRegistered);
    objc_setAssociatedObject(self, @selector(cylflatdesign_interactivePopGestureRecognizerRegistered), interactivePopGestureRecognizerRegisteredObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIGestureRecognizer *)cylflatdesign_customPopGestureRecognizer {
    UIGestureRecognizer *customPopGestureRecognizer = objc_getAssociatedObject(self, @selector(cylflatdesign_customPopGestureRecognizer));
    return customPopGestureRecognizer;
}

- (void)cylflatdesign_setCustomPopGestureRecognizer:(UIGestureRecognizer *)customPopGestureRecognizer {
    UIGestureRecognizer *customPopGestureRecognizer_ = customPopGestureRecognizer;
    objc_setAssociatedObject(self, @selector(cylflatdesign_customPopGestureRecognizer), customPopGestureRecognizer_, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - 主流程
+ (void)load {
    return;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _CYLFlatDesignTabBarSwizzleMethod([self class],
                                          @selector(popViewControllerAnimated:),
                                          @selector(cylflatdesign_popViewControllerAnimated:));
        
        _CYLFlatDesignTabBarSwizzleMethod([self class],
                                          @selector(popToViewController:animated:),
                                          @selector(cylflatdesign_popToViewController:animated:));
        
        _CYLFlatDesignTabBarSwizzleMethod([self class],
                                          @selector(popToRootViewControllerAnimated:),
                                          @selector(cylflatdesign_popToRootViewControllerAnimated:));
        
        _CYLFlatDesignTabBarSwizzleMethod([self class],
                                          @selector(pushViewController:animated:),
                                          @selector(cylflatdesign_pushViewController:animated:));
        
        _CYLFlatDesignTabBarSwizzleMethod([self class],
                                          @selector(setViewControllers:animated:),
                                          @selector(cylflatdesign_setViewControllers:animated:));
        
        _CYLFlatDesignTabBarSwizzleMethod([self class],
                                          @selector(didMoveToParentViewController:),
                                          @selector(cylflatdesign_didMoveToParentViewController:));
        
        _CYLFlatDesignTabBarSwizzleMethod([self class],
                                          @selector(viewDidLayoutSubviews),
                                          @selector(cylflatdesign_viewDidLayoutSubviews));
    });
}

#pragma mark - Pop
- (UIViewController *)cylflatdesign_popViewControllerAnimated:(BOOL)animated {
    UIViewController *previousViewController = [self cylflatdesign_popViewControllerAnimated:animated];
    if (!self.cylflatdesign_nestedInCYLFlatDesignTabBarController) {
        return previousViewController;
    }
    
    [self _cylflatdesign_popViewController:previousViewController toViewController:self.topViewController animated:animated];
    return previousViewController;
}

- (NSArray<__kindof UIViewController *> *)cylflatdesign_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    UIViewController *previousViewController = self.topViewController;
    NSArray<__kindof UIViewController *> *viewControllers = [self cylflatdesign_popToViewController:viewController animated:animated];
    if (!self.cylflatdesign_nestedInCYLFlatDesignTabBarController) {
        return viewControllers;
    }
    [self _cylflatdesign_popViewController:previousViewController toViewController:viewController animated:animated];
    return viewControllers;
}

- (NSArray<__kindof UIViewController *> *)cylflatdesign_popToRootViewControllerAnimated:(BOOL)animated {
    UIViewController *previousViewController = self.topViewController;
    NSArray<__kindof UIViewController *> *viewControllers = [self cylflatdesign_popToRootViewControllerAnimated:animated];
    if (!self.cylflatdesign_nestedInCYLFlatDesignTabBarController) {
        return viewControllers;
    }
    if (viewControllers == nil || viewControllers.count == 0) {
        return viewControllers;
    }
    [self _cylflatdesign_popViewController:previousViewController toViewController:self.topViewController animated:animated];
    return viewControllers;
}

#pragma mark - Push
- (void)cylflatdesign_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (!self.cylflatdesign_nestedInCYLFlatDesignTabBarController) {
        [self cylflatdesign_pushViewController:viewController animated:animated];
        return;
    }
    
    UIViewController *previousViewController = self.topViewController;
    
    [self cylflatdesign_pushViewController:viewController animated:animated];
    
    [self _cylflatdesign_pushViewController:previousViewController toViewController:viewController animated:animated];
}

- (void)cylflatdesign_setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    if (!self.cylflatdesign_nestedInCYLFlatDesignTabBarController) {
        [self cylflatdesign_setViewControllers:viewControllers animated:animated];
        return;
    }
    
    UIViewController *previousViewController = self.topViewController;
    UIViewController *toViewController = viewControllers.lastObject;
    
    // TODO: 这里判断是Push还是Pop不知道准不准确
    BOOL isPush = NO;
    if (![self.viewControllers containsObject:toViewController]) {
        isPush = YES;
    }
    
    [self cylflatdesign_setViewControllers:viewControllers animated:animated];
    
    if (isPush) {
        [self _cylflatdesign_pushViewController:previousViewController toViewController:toViewController animated:animated];
    } else {
        [self _cylflatdesign_popViewController:previousViewController toViewController:toViewController animated:animated];
    }
}

- (void)cylflatdesign_didMoveToParentViewController:(nullable UIViewController *)parent {
    [self cylflatdesign_didMoveToParentViewController:parent];
    
    if (parent == nil && self.cylflatdesign_nestedInCYLFlatDesignTabBarController) {
        self.cylflatdesign_extensionDelegate = nil;
        self.cylflatdesign_nestedInCYLFlatDesignTabBarController = NO;
        [self _cylflatdesign_unregisterPopGestureRecognizer];
    } else if ([parent isKindOfClass:[CYLFlatDesignTabBarController class]] || [parent isKindOfClass:[CYLFlatDesignTabViewController class]]) {
        self.cylflatdesign_extensionDelegate = (id<UINavigationControllerExtensionDelegate>)parent;
        self.cylflatdesign_nestedInCYLFlatDesignTabBarController = YES;
        [self cylflatdesign_registerPopGestureRecognizer];
        [self cylflatdesign_updateNavigationBarHeight];
    }
}

- (void)cylflatdesign_viewDidLayoutSubviews {
    [self cylflatdesign_viewDidLayoutSubviews];
    if (self.cylflatdesign_nestedInCYLFlatDesignTabBarController) {
        [self cylflatdesign_updateNavigationBarHeight];
    }
}

#pragma mark - Gestures
- (UIGestureRecognizer *)cylflatdesign_responsePopGestureRecognizer {
    UIGestureRecognizer *popGestureRecognizer = self.cylflatdesign_customPopGestureRecognizer;
    if (!popGestureRecognizer) {
        if (@available(iOS 26.0, *)) {
            popGestureRecognizer = self.interactiveContentPopGestureRecognizer;
        } else {
            popGestureRecognizer = self.interactivePopGestureRecognizer;
        }
    }
    return popGestureRecognizer;
}

- (void)cylflatdesign_registerPopGestureRecognizer {
    if (self.cylflatdesign_interactivePopGestureRecognizerRegistered) return;
    UIGestureRecognizer *popGestureRecognizer = [self cylflatdesign_responsePopGestureRecognizer];
    if (popGestureRecognizer) {
        [popGestureRecognizer addTarget:self action:@selector(_cylflatdesign_popGestureRecognizerHandler:)];
        self.cylflatdesign_interactivePopGestureRecognizerRegistered = YES;
    }
}

- (void)_cylflatdesign_unregisterPopGestureRecognizer {
    if (!self.cylflatdesign_interactivePopGestureRecognizerRegistered) return;
    UIGestureRecognizer *popGestureRecognizer = [self cylflatdesign_responsePopGestureRecognizer];
    if (popGestureRecognizer) {
        [popGestureRecognizer removeTarget:self action:@selector(_cylflatdesign_popGestureRecognizerHandler:)];
        self.cylflatdesign_interactivePopGestureRecognizerRegistered = NO;
    }
}

- (void)_cylflatdesign_popGestureRecognizerHandler:(UIPanGestureRecognizer *)popGestureRecognizer {
    [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self
                                didUpdateInteractiveFrom:[self.transitionCoordinator viewControllerForKey:UITransitionContextFromViewControllerKey]
                                                      to:self.topViewController
                                    popGestureRecognizer:popGestureRecognizer];
    
    if (popGestureRecognizer.state == UIGestureRecognizerStateEnded) return;
    CGFloat const translation = [popGestureRecognizer translationInView:self.view].x;
    if (translation == 0.0) return;
    CGFloat const completed = MAX(0.0, MIN(1.0, translation / CGRectGetWidth(self.view.bounds)));
    [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self
                                didUpdateInteractiveFrom:[self.transitionCoordinator viewControllerForKey:UITransitionContextFromViewControllerKey]
                                                      to:self.topViewController
                                         percentComplete:completed];
}

#pragma mark - Helpers
- (void)_cylflatdesign_pushViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC animated:(BOOL)animated {
    
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.transitionCoordinator;
    
    [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self
                                  didBeginTransitionFrom:fromVC
                                                      to:toVC
                                               operation:UINavigationControllerOperationPush];
    if (transitionCoordinator) {
        __weak typeof(self) weakSelf = self;
        [transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            if (weakSelf == nil) return;
            typeof(self) strongSelf = weakSelf;
            [strongSelf.cylflatdesign_extensionDelegate cylflatdesign_navigationController:strongSelf
                                                 willEndTransitionFrom:fromVC
                                                                    to:toVC
                                                             operation:UINavigationControllerOperationPush
                                                             cancelled:context.isCancelled];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            if (weakSelf == nil) return;
            typeof(self) strongSelf = weakSelf;
            [strongSelf.cylflatdesign_extensionDelegate cylflatdesign_navigationController:strongSelf
                                                  didEndTransitionFrom:fromVC
                                                                    to:toVC
                                                             operation:UINavigationControllerOperationPush
                                                             cancelled:context.isCancelled];
        }];
    } else {
        if (animated) {
            [UIView animateWithDuration:0.35 delay:0.0 options:7 << 16 animations:^{
                [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self
                                               willEndTransitionFrom:fromVC
                                                                  to:toVC
                                                           operation:UINavigationControllerOperationPush
                                                           cancelled:NO];
            } completion:^(BOOL finished) {
                [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self
                                                didEndTransitionFrom:fromVC
                                                                  to:toVC
                                                           operation:UINavigationControllerOperationPush
                                                           cancelled:NO];
            }];
        } else {
            [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self
                                           willEndTransitionFrom:fromVC
                                                              to:toVC
                                                       operation:UINavigationControllerOperationPush
                                                       cancelled:NO];
            [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self
                                            didEndTransitionFrom:fromVC
                                                              to:toVC
                                                       operation:UINavigationControllerOperationPush
                                                       cancelled:NO];
        }
    }
}

- (void)_cylflatdesign_popViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC animated:(BOOL)animated {
    id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.transitionCoordinator;
    
    if (fromVC && fromVC == toVC) {
        NSLog(@"UINavigationController+CYLFlatDesignTabBarPrivate：是否连续 pop 操作？这可能会出问题!");
        // 解决连续 pop 操作，toVC不准确的问题
        NSInteger index = [self.viewControllers indexOfObject:toVC];
        NSInteger toIndex = index - 1;
        if (toIndex >= 0) {
            toVC = self.viewControllers[toIndex];
        }
    }
    
    [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self
                                  didBeginTransitionFrom:fromVC
                                                      to:toVC
                                               operation:UINavigationControllerOperationPop];
    if (transitionCoordinator) {
        __weak typeof(self) weakSelf = self;
        [transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            if (weakSelf == nil) return;
            typeof(self) strongSelf = weakSelf;
            [strongSelf.cylflatdesign_extensionDelegate cylflatdesign_navigationController:strongSelf
                                                 willEndTransitionFrom:fromVC
                                                                    to:toVC
                                                             operation:UINavigationControllerOperationPop
                                                             cancelled:context.isCancelled];
            
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            if (weakSelf == nil) return;
            typeof(self) strongSelf = weakSelf;
            [strongSelf.cylflatdesign_extensionDelegate cylflatdesign_navigationController:strongSelf
                                                  didEndTransitionFrom:fromVC
                                                                    to:toVC
                                                             operation:UINavigationControllerOperationPop
                                                             cancelled:context.isCancelled];
        }];
    } else {
        if (animated) {
            [UIView animateWithDuration:0.35 delay:0.0 usingSpringWithDamping:1.0 initialSpringVelocity:1.0 options:7 << 16 animations:^{
                [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self
                                               willEndTransitionFrom:fromVC
                                                                  to:toVC
                                                           operation:UINavigationControllerOperationPop
                                                           cancelled:NO];
            } completion:^(BOOL finished) {
                [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self
                                                didEndTransitionFrom:fromVC
                                                                  to:toVC
                                                           operation:UINavigationControllerOperationPop
                                                           cancelled:NO];
            }];
        } else {
            [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self
                                           willEndTransitionFrom:fromVC
                                                              to:toVC
                                                       operation:UINavigationControllerOperationPop
                                                       cancelled:NO];
            [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self
                                            didEndTransitionFrom:fromVC
                                                              to:toVC
                                                       operation:UINavigationControllerOperationPop
                                                       cancelled:NO];
        }
    }
}

- (void)cylflatdesign_updateNavigationBarHeight {
    CGFloat value = 0.0;
    for (UIView *subview in self.navigationBar.subviews) {
        if ([NSStringFromClass([subview class]) containsString:@"ContentView"]) {
            value = CGRectGetMaxY(subview.frame);
            break;
        }
    }
    [self.cylflatdesign_extensionDelegate cylflatdesign_navigationController:self navigationBarDidChangeHeight:value + self.view.safeAreaInsets.top];
}

@end
