/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "UIViewController+CYLNavigationControllerExtention.h"
#import <objc/runtime.h>
#import "CYLConstants.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif
#import "UIView+CYLTabBarControllerExtention.h"

@implementation UIViewController (CYLNavigationControllerExtention)

- (BOOL)cyl_disablePopGestureRecognizer {
    NSNumber *disablePopGestureRecognizerObject = objc_getAssociatedObject(self, @selector(cyl_disablePopGestureRecognizer));
    return [disablePopGestureRecognizerObject boolValue];
}

- (void)cyl_setDisablePopGestureRecognizer:(BOOL)disablePopGestureRecognizer {
    NSNumber *disablePopGestureRecognizerObject = [NSNumber numberWithBool:disablePopGestureRecognizer];
    objc_setAssociatedObject(self, @selector(cyl_disablePopGestureRecognizer), disablePopGestureRecognizerObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cyl_hideNavigationBarSeparator {
    NSNumber *hideNavigationBarSeparatorObject = objc_getAssociatedObject(self, @selector(cyl_hideNavigationBarSeparator));
    return [hideNavigationBarSeparatorObject boolValue];
}

- (void)cyl_setHideNavigationBarSeparator:(BOOL)hideNavigationBarSeparator {
    NSNumber *hideNavigationBarSeparatorObject = [NSNumber numberWithBool:hideNavigationBarSeparator];
    objc_setAssociatedObject(self, @selector(cyl_hideNavigationBarSeparator), hideNavigationBarSeparatorObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cyl_navigationBarHidden {
    NSNumber *navigationBarHiddenObject = objc_getAssociatedObject(self, @selector(cyl_navigationBarHidden));
    return [navigationBarHiddenObject boolValue];
}

- (void)cyl_setNavigationBarHidden:(BOOL)navigationBarHidden {
    NSNumber *navigationBarHiddenObject = [NSNumber numberWithBool:navigationBarHidden];
    objc_setAssociatedObject(self, @selector(cyl_navigationBarHidden), navigationBarHiddenObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cyl_hidesBottomBarWhenPushed {
    NSNumber *hidesBottomBarWhenPushedObject = objc_getAssociatedObject(self, @selector(cyl_hidesBottomBarWhenPushed));
    return [hidesBottomBarWhenPushedObject boolValue];
}

- (void)cyl_setHidesBottomBarWhenPushed:(BOOL)hidesBottomBarWhenPushed {
    self.hidesBottomBarWhenPushed = hidesBottomBarWhenPushed;
    NSNumber *hidesBottomBarWhenPushedObject = @(hidesBottomBarWhenPushed);
    objc_setAssociatedObject(self, @selector(cyl_hidesBottomBarWhenPushed), hidesBottomBarWhenPushedObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//viewWillDisappear
//dealloc
// 在左滑动的过渡的时间段内禁用interactivePopGestureRecognizer
- (void)cyl_disableInteractivePopGestureRecognizer {
    if (![self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        return;
    }
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    
    if (!CYL_IS_IOS_26) {
        return;
    }
    if (![self.navigationController respondsToSelector:@selector(interactiveContentPopGestureRecognizer)]) {
        return;
    }
    if (@available(iOS 26.0, *)) {
        self.navigationController.interactiveContentPopGestureRecognizer.delegate = nil;
    }
    [self cyl_resetTabBarHidden];
}

//viewDidDisappear
// 在左滑动的结束后启用interactivePopGestureRecognizer
- (void)cyl_enableInteractivePopGestureRecognizer {
    if (![self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        return;
    }
    self.navigationController.interactivePopGestureRecognizer.delegate = (id <UIGestureRecognizerDelegate>)self;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    
    if (!CYL_IS_IOS_26) {
        return;
    }
    if (@available(iOS 26.0, *)) {
        if (![self.navigationController respondsToSelector:@selector(interactiveContentPopGestureRecognizer)]) {
            return;
        }
        self.navigationController.interactiveContentPopGestureRecognizer.delegate = (id <UIGestureRecognizerDelegate>)self;
        self.navigationController.interactiveContentPopGestureRecognizer.enabled = YES;
    }
}

//viewDidAppear
// 当新的视图控制器加载完成后再启用
- (void)cyl_resetInteractivePopGestureRecognizer {
    if (![self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        return;
    }
    BOOL isSingleViewControllerInNavigationController = ([self.navigationController.viewControllers count] == 1);
    BOOL needDisableInteractivePopGestureRecognizer = (self.cyl_disablePopGestureRecognizer) || isSingleViewControllerInNavigationController;
    if (needDisableInteractivePopGestureRecognizer) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        if (@available(iOS 26.0, *)) {
            self.navigationController.interactiveContentPopGestureRecognizer.enabled = NO;
        } else {
            // Fallback on earlier versions
        }
        
    } else {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        if (@available(iOS 26.0, *)) {
            self.navigationController.interactiveContentPopGestureRecognizer.enabled = YES;
        } else {
            // Fallback on earlier versions
        }
    }
    [self cyl_resetTabBarHidden];
}

static const NSTimeInterval kFullScreenAnimationTime = 0.3; // 根据你的项目定义


#pragma mark - TabBar Show / Hide

- (void)cyl_resetTabBarHidden {
    CYLTabBar *tabBar = self.cyl_tabBarController.tabBar;
    for (UIView *subview in tabBar.subviews) {
        [subview cyl_setHidden:self.cyl_hidesBottomBarWhenPushed];
    }
}

#pragma mark - private

- (void)cyl_changeTabbarStatusIfNeeded {
    if (![self cyl_isDirectChildOfRootTabBarController]) {
        return;
    }

    BOOL shouldTabBarHidden = [self cyl_shouldTabBarHidden];
    BOOL currentTabbarHidden = self.cyl_tabBarController.tabBar.cyl_isHidden;

    if (shouldTabBarHidden && !currentTabbarHidden) {
        [self  cyl_hideTabbar];
    } else if (!shouldTabBarHidden && currentTabbarHidden) {
        [self cyl_showTabbar];
    }
}

- (BOOL)cyl_shouldTabBarHidden {
    for (int i = 1; i < [self cyl_getViewControllerInsteadOfNavigationController].navigationController.viewControllers.count; i++ ) {
        if ([self cyl_getViewControllerInsteadOfNavigationController].navigationController.viewControllers[i].cyl_hidesBottomBarWhenPushed) {
            return YES;
        }
    }
    
    return NO;
}

- (void)cyl_hideTabbar {
    [self cyl_updateTabbarWithShouldHidden:YES];

    if (self.transitionCoordinator) {
        UIImageView *tabbarImageView = [self cyl_imageViewFromSnapshotOfView:self.cyl_tabBarController.tabBar];
        UIViewController *fromVC = [self.transitionCoordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
        [fromVC.view addSubview:tabbarImageView];

        [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {

        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [tabbarImageView removeFromSuperview];
            if (context.isCancelled) {
                [self cyl_updateTabbarWithShouldHidden:NO];
            }
        }];
    }
}

- (void)cyl_showTabbar {
    if (self.transitionCoordinator) {
        UIImageView *tabbarImageView = [self cyl_imageViewFromSnapshotOfView:self.cyl_tabBarController.tabBar];
        UIViewController *toVC = [self.transitionCoordinator viewControllerForKey:UITransitionContextToViewControllerKey];
        [toVC.view addSubview:tabbarImageView];

        [self.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {

        } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [tabbarImageView removeFromSuperview];
            if (context.isCancelled) {

            } else {
                [self cyl_updateTabbarWithShouldHidden:NO];
            }
        }];
    } else {
        [self cyl_updateTabbarWithShouldHidden:NO];
    }
}

#pragma mark - helper

- (BOOL)cyl_isDirectChildOfRootTabBarController {
    if (!self.cyl_tabBarController) {
        return NO;
    }
    return self.parentViewController == self.cyl_tabBarController;
}

- (UIImageView *)cyl_imageViewFromSnapshotOfView:(UIView *)view {
//    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithBounds:view.bounds];
//    UIImage *snapshot = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
//        [view.layer renderInContext:context.CGContext];
//    }];
//
   UIImage *snapshot = [view cyl_takeSnapshotWithoutViews:@[]];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:snapshot];
    imageView.frame = view.frame;
    return imageView;
}

- (void)cyl_updateTabbarWithShouldHidden:(BOOL)shouldHidden {
    CYLTabBar *tabBar = self.cyl_tabBarController.tabBar;
    [tabBar cyl_setHidden:shouldHidden];
    for (UIView *subview in tabBar.subviews) {
        [subview cyl_setHidden:shouldHidden];
    }
}

/// 显示或隐藏 TabBar（带屏幕外滑入/滑出动画）
/// @param visible YES=显示（从底部升上来），NO=隐藏（降到底部屏幕外）
/// @param animated 是否使用动画
/// @param completion 完成回调
- (void)cyl_setTabBarVisible:(BOOL)visible
                    animated:(BOOL)animated
                  completion:(void (^ _Nullable)(BOOL finished))completion {
    
    // 如果当前状态与目标状态相同，直接返回
    if (self.hidesBottomBarWhenPushed == !visible) {
        if (completion) {
            completion(YES);
        }
        return;
    }
    
    CYLTabBar *tabBar = self.cyl_tabBarController.tabBar;
    if (![tabBar isKindOfClass:[CYLTabBar class]]) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    
    CGSize screenSize = CYLScreenSize();
    CGFloat tabBarHeight = CYLGetTabBarFullH(CGRectGetHeight(tabBar.frame));
    
    // 计算关键位置
    CGRect visibleFrame = CGRectMake(0,
                                     screenSize.height - tabBarHeight,
                                     screenSize.width,
                                     tabBarHeight);
    
    CGRect hiddenFrame = CGRectMake(0,
                                    screenSize.height,  // 完全移到屏幕外
                                    screenSize.width,
                                    tabBarHeight);
    
    NSTimeInterval duration = animated ? kFullScreenAnimationTime : 0.0;
    
    // 设置动画的起始帧
    if (visible) {
        // 显示动画：起始位置在屏幕外（底部下方）
        tabBar.frame = hiddenFrame;
    } else {
        // 隐藏动画：起始位置在可见位置
        // 注意：如果当前 TabBar 已经在可见位置，无需设置
        // 如果不在，先设置到可见位置再开始隐藏动画
        if (!CGRectEqualToRect(tabBar.frame, visibleFrame)) {
            tabBar.frame = visibleFrame;
        }
    }
    
    // 目标帧
    CGRect targetFrame = visible ? visibleFrame : hiddenFrame;
    
    // 执行动画
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        tabBar.frame = targetFrame;
    } completion:^(BOOL finished) {
        if (completion) {
            completion(finished);
        }
    }];
}


#pragma mark - 判断 TabBar 是否可见

/// 判断 TabBar 是否可见（基于位置判断）
/// @return YES=可见，NO=不可见
- (BOOL)cyl_tabBarIsVisible {
    CYLTabBar *tabBar = self.cyl_tabBarController.tabBar;
    if (![tabBar isKindOfClass:[CYLTabBar class]]) {
        return NO;
    }
    
    CGRect tabBarFrame = tabBar.frame;
    CGSize screenSize = CYLScreenSize();
    
    // 判断逻辑：TabBar 的顶部是否在屏幕范围内
    // 如果 minY < 屏幕高度，说明至少有一部分可见
    return CGRectGetMinY(tabBarFrame) < screenSize.height;
}


#pragma mark - 便捷方法（可选）

/// 显示 TabBar（从底部升上来）
- (void)cyl_showTabBarAnimated:(BOOL)animated
                    completion:(void (^ _Nullable)(BOOL finished))completion {
    [self cyl_setTabBarVisible:YES animated:animated completion:completion];
}

/// 隐藏 TabBar（降到底部屏幕外）
- (void)cyl_hideTabBarAnimated:(BOOL)animated
                    completion:(void (^ _Nullable)(BOOL finished))completion {
    [self cyl_setTabBarVisible:NO animated:animated completion:completion];
}

/// 切换 TabBar 可见性
- (void)cyl_toggleTabBarAnimated:(BOOL)animated
                      completion:(void (^ _Nullable)(BOOL finished))completion {
    BOOL currentlyVisible = [self cyl_tabBarIsVisible];
    [self cyl_setTabBarVisible:!currentlyVisible animated:animated completion:completion];
}

#pragma mark - 判断 TabBar 是否可见

//viewWillAppear
- (void)cyl_hideNavigationBarSeparatorIfNeeded {
    if (self.cyl_hideNavigationBarSeparator) {
        self.navigationController.navigationBar.shadowImage = [UIImage new];
        self.navigationController.navigationBar.translucent = NO;
    }
}

//在viewwilldisappear使用
- (BOOL)cyl_shouldNavigationBarVisible {
    BOOL shouldSetNo = YES;
    
    BOOL isPop = YES;
    if (!self.navigationController) {
        return shouldSetNo;
    }
    //push的时候会先将vc添加到viewControllers，再调用viewWillDisappear
    //pop的时候会先将vc从viewControllers移除，再调用viewWillDisappear
    NSInteger selfIndex = -1;
    if (self.navigationController.viewControllers.count > 0) {
        NSArray *vcList = self.navigationController.viewControllers;
        for (NSInteger i = 0; i < vcList.count; i++) {
            UIViewController *vc = vcList[i];
            if (vc == self) {
                selfIndex = i;
                if (selfIndex == vcList.count - 1) {
                    //这种情况是navigationController push第一个vc或者present，不需要特殊处理，直接return
                    return YES;
                }
                isPop = NO;
                break;
            }
        }
        if (isPop) {
            UIViewController *preVc = (UIViewController *)self.navigationController.viewControllers.lastObject;
            if (self.cyl_navigationBarHidden == preVc.cyl_navigationBarHidden) {
                shouldSetNo = NO;
            }
        } else {
            if (selfIndex + 1 < self.navigationController.viewControllers.count) {
                UIViewController *nextVc = (UIViewController *)self.navigationController.viewControllers[selfIndex + 1];
                if (self.cyl_navigationBarHidden == nextVc.cyl_navigationBarHidden) {
                    shouldSetNo = NO;
                }
            }
        }
    }
    return shouldSetNo;
}

//viewWillDisappear
- (void)cyl_setNavigationBarVisibleIfNeeded:(BOOL)animated {
    if (self.cyl_navigationBarHidden && [self cyl_shouldNavigationBarVisible]) {
        [self.navigationController setNavigationBarHidden:!self.cyl_navigationBarHidden animated:animated];
    }
}

//viewWillAppear
- (void)cyl_setNavigationBarHiddenIfNeeded:(BOOL)animated {
    if (self.cyl_navigationBarHidden) {
        [self.navigationController setNavigationBarHidden:self.cyl_navigationBarHidden animated:animated];
    }
}

- (void)cyl_viewWillAppearNavigationSetting:(BOOL)animated {
    [self cyl_hideNavigationBarSeparatorIfNeeded];
    [self cyl_setNavigationBarHiddenIfNeeded:animated];
}

- (void)cyl_viewWillDisappearNavigationSetting:(BOOL)animated {
    [self cyl_disableInteractivePopGestureRecognizer];
    [self cyl_setNavigationBarVisibleIfNeeded:animated];
}

- (void)cyl_viewDidDisappearNavigationSetting:(BOOL)animated {
    [self cyl_enableInteractivePopGestureRecognizer];
}

- (void)cyl_viewDidAppearNavigationSetting:(BOOL)animated {
    [self cyl_resetInteractivePopGestureRecognizer];
}

- (void)cyl_deallocNavigationSetting {
    [self cyl_disableInteractivePopGestureRecognizer];
}

@end
