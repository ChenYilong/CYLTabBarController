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
#import "CYLBaseViewController.h"
#import "CYLBaseTableViewController.h"

/// [EN] FIX: issue #535 — see `cyl_automaticNavigationSettingEnabled`. [CN] 见 `cyl_automaticNavigationSettingEnabled`。
static BOOL CYLAutomaticNavigationSettingEnabled = NO;

/// [EN] The page shown inside `viewController`: the top of a navigation stack, the selected tab, recursively.
/// [CN] `viewController` 中正在显示的页面：逐层取导航栈顶与选中的 Tab。
static UIViewController *CYLVisibleLeafViewController(UIViewController *viewController) {
    UIViewController *current = viewController;
    while (YES) {
        UIViewController *next = nil;
        if ([current isKindOfClass:[UINavigationController class]]) {
            next = ((UINavigationController *)current).topViewController;
        } else if ([current isKindOfClass:[UITabBarController class]]) {
            next = ((UITabBarController *)current).selectedViewController;
        }
        if (!next || next == current) {
            return current;
        }
        current = next;
    }
}

@implementation UIViewController (CYLNavigationControllerExtention)

#pragma mark - FIX: issue #535 — navigation settings without a base class

+ (BOOL)cyl_automaticNavigationSettingEnabled {
    return CYLAutomaticNavigationSettingEnabled;
}

+ (void)cyl_setAutomaticNavigationSettingEnabled:(BOOL)automaticNavigationSettingEnabled {
    CYLAutomaticNavigationSettingEnabled = automaticNavigationSettingEnabled;
    if (!automaticNavigationSettingEnabled) {
        return;
    }
    // [EN] Installed the first time it is turned on; turning it off only skips the calls.
    // [CN] 第一次开启时安装；关闭后只是不再调用。
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class viewControllerClass = [UIViewController class];
        SEL selectors[][2] = {
            { @selector(viewWillAppear:), @selector(cyl_automaticNavigationViewWillAppear:) },
            { @selector(viewDidAppear:), @selector(cyl_automaticNavigationViewDidAppear:) },
            { @selector(viewWillDisappear:), @selector(cyl_automaticNavigationViewWillDisappear:) },
            { @selector(viewDidDisappear:), @selector(cyl_automaticNavigationViewDidDisappear:) },
        };
        for (NSUInteger i = 0; i < sizeof(selectors) / sizeof(selectors[0]); i++) {
            Method originalMethod = class_getInstanceMethod(viewControllerClass, selectors[i][0]);
            Method swizzledMethod = class_getInstanceMethod(viewControllerClass, selectors[i][1]);
            if (originalMethod && swizzledMethod) {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        }
    });
}

/*!
 * [EN] YES when the automatic calls apply to this view controller: turned on, not one of the base classes (they call
 *      the methods themselves), one of the properties set, and inside a navigation controller.
 * [CN] 自动调用作用于本控制器时为 YES：已开启、不是基类（基类自己调用）、设置了其中任一属性，且位于导航控制器中。
 */
- (BOOL)cyl_needsAutomaticNavigationSetting {
    if (!CYLAutomaticNavigationSettingEnabled) {
        return NO;
    }
    if ([self isKindOfClass:[CYLBaseViewController class]] || [self isKindOfClass:[CYLBaseTableViewController class]]) {
        return NO;
    }
    if (!self.cyl_navigationBarHidden && !self.cyl_hideNavigationBarSeparator && !self.cyl_disablePopGestureRecognizer && !self.cyl_hidesAncestorNavigationBars) {
        return NO;
    }
    // [EN] As in the base classes: any view controller in a navigation controller, also a tab directly in a tab bar
    //      controller that is itself pushed (issue #535).
    // [CN] 与基类相同：任何位于导航控制器中的控制器，包括直接作为 Tab、而 TabBarController 本身被 push 的情况（issue #535）。
    return self.navigationController != nil;
}

/// [EN] After the exchange these run as the UIViewController methods; the same selector calls the original.
/// [CN] 交换后它们作为 UIViewController 的方法执行；调用同名选择子即调用原实现。
- (void)cyl_automaticNavigationViewWillAppear:(BOOL)animated {
    [self cyl_automaticNavigationViewWillAppear:animated];
    if ([self cyl_needsAutomaticNavigationSetting]) {
        [self cyl_viewWillAppearNavigationSetting:animated];
    }
}

- (void)cyl_automaticNavigationViewDidAppear:(BOOL)animated {
    [self cyl_automaticNavigationViewDidAppear:animated];
    if ([self cyl_needsAutomaticNavigationSetting]) {
        [self cyl_viewDidAppearNavigationSetting:animated];
    }
}

- (void)cyl_automaticNavigationViewWillDisappear:(BOOL)animated {
    [self cyl_automaticNavigationViewWillDisappear:animated];
    if ([self cyl_needsAutomaticNavigationSetting]) {
        [self cyl_viewWillDisappearNavigationSetting:animated];
    }
}

- (void)cyl_automaticNavigationViewDidDisappear:(BOOL)animated {
    [self cyl_automaticNavigationViewDidDisappear:animated];
    if ([self cyl_needsAutomaticNavigationSetting]) {
        [self cyl_viewDidDisappearNavigationSetting:animated];
    }
}

#pragma mark - FIX: issue #535 — navigation bars of the navigation controllers around this one

- (BOOL)cyl_hidesAncestorNavigationBars {
    return [objc_getAssociatedObject(self, @selector(cyl_hidesAncestorNavigationBars)) boolValue];
}

- (void)cyl_setHidesAncestorNavigationBars:(BOOL)hidesAncestorNavigationBars {
    objc_setAssociatedObject(self, @selector(cyl_hidesAncestorNavigationBars), @(hidesAncestorNavigationBars), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/// [EN] The navigation controllers that contain this one's, innermost first. [CN] 包含本控制器所在导航控制器的外层导航控制器，由内向外。
- (NSArray<UINavigationController *> *)cyl_ancestorNavigationControllers {
    NSMutableArray<UINavigationController *> *navigationControllers = [NSMutableArray array];
    UINavigationController *navigationController = self.navigationController.navigationController;
    while (navigationController && ![navigationControllers containsObject:navigationController]) {
        [navigationControllers addObject:navigationController];
        navigationController = navigationController.navigationController;
    }
    return navigationControllers;
}

- (void)cyl_hideAncestorNavigationBarsIfNeeded:(BOOL)animated {
    if (!self.cyl_hidesAncestorNavigationBars) {
        return;
    }
    for (UINavigationController *navigationController in [self cyl_ancestorNavigationControllers]) {
        if (!navigationController.navigationBarHidden) {
            // [EN] Remember that this bar was hidden here, so only it is shown again.
            // [CN] 记录该导航栏是在这里隐藏的，之后只恢复它。
            objc_setAssociatedObject(navigationController, @selector(cyl_hideAncestorNavigationBarsIfNeeded:), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [navigationController setNavigationBarHidden:YES animated:animated];
        }
    }
}

- (void)cyl_showAncestorNavigationBarsIfNeeded:(BOOL)animated {
    if (!self.cyl_hidesAncestorNavigationBars) {
        return;
    }
    for (UINavigationController *navigationController in [self cyl_ancestorNavigationControllers]) {
        if (![objc_getAssociatedObject(navigationController, @selector(cyl_hideAncestorNavigationBarsIfNeeded:)) boolValue]) {
            continue;
        }
        // [EN] Keep it hidden while the page now shown inside asks for it (e.g. after switching to another such tab).
        // [CN] 当前显示的内层页面仍要求隐藏时保持隐藏（例如切换到另一个同样设置的 Tab 后）。
        if (CYLVisibleLeafViewController(navigationController).cyl_hidesAncestorNavigationBars) {
            continue;
        }
        objc_setAssociatedObject(navigationController, @selector(cyl_hideAncestorNavigationBarsIfNeeded:), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [navigationController setNavigationBarHidden:NO animated:animated];
    }
}

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
// [CN] 在左滑动的过渡的时间段内禁用interactivePopGestureRecognizer
// [EN] Disable interactivePopGestureRecognizer during the swipe-back transition.
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
// [CN] 在左滑动的结束后启用interactivePopGestureRecognizer
// [EN] Enable interactivePopGestureRecognizer after the swipe-back ends.
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
// [CN] 当新的视图控制器加载完成后再启用
// [EN] Enable it again once the new view controller has finished loading.
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

static const NSTimeInterval kFullScreenAnimationTime = 0.3; // [CN] 根据你的项目定义
// [EN] Define according to your project.


#pragma mark - TabBar Show / Hide

- (void)cyl_resetTabBarHidden {
//    CYLTabBar *tabBar = self.cyl_tabBarController.tabBar;
//    for (UIView *subview in tabBar.subviews) {
        
//        [subview cyl_setHidden:self.cyl_hidesBottomBarWhenPushed];
//    }
}

#pragma mark - private

- (void)cyl_changeTabbarStatusIfNeeded {
    if (![self cyl_isDirectChildOfRootTabBarController]) {
        return;
    }

    BOOL shouldTabBarHidden = [self cyl_shouldTabBarHidden];
    BOOL currentTabbarHidden = self.cyl_tabBarController.tabBar.cyl_isInvisiable;//cyl_isHidden

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

        BOOL willComplete = [self.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [tabbarImageView removeFromSuperview];
            if (context.isCancelled) {
                [self cyl_updateTabbarWithShouldHidden:NO];
            }
        }];
        // NO: the transition cannot run the completion (e.g. it is not animated), so the snapshot would stay forever.
        // 返回 NO 表示转场不会执行 completion（例如没有动画），快照会一直留在页面上。
        if (!willComplete) {
            [tabbarImageView removeFromSuperview];
        }
    }
}

- (void)cyl_showTabbar {
    if (self.transitionCoordinator) {
        UIImageView *tabbarImageView = [self cyl_imageViewFromSnapshotOfView:self.cyl_tabBarController.tabBar];
        UIViewController *toVC = [self.transitionCoordinator viewControllerForKey:UITransitionContextToViewControllerKey];
        [toVC.view addSubview:tabbarImageView];

        BOOL willComplete = [self.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [tabbarImageView removeFromSuperview];
            if (!context.isCancelled) {
                [self cyl_updateTabbarWithShouldHidden:NO];
            }
        }];
        // NO: the completion never runs, and the tab bar would stay hidden. Show it now, as without a transition.
        // 返回 NO 表示 completion 不会执行，TabBar 会一直隐藏。与没有转场时一样，立即显示。
        if (!willComplete) {
            [tabbarImageView removeFromSuperview];
            [self cyl_updateTabbarWithShouldHidden:NO];
        }
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

/// [CN] 显示或隐藏 TabBar（带屏幕外滑入/滑出动画）
/// @param visible YES=显示（从底部升上来），NO=隐藏（降到底部屏幕外）
/// @param animated 是否使用动画
/// @param completion 完成回调
/// [EN] Show or hide the TabBar (with an off-screen slide-in/slide-out animation).
///      @param visible YES = show (rise from the bottom), NO = hide (drop off-screen at the bottom)
///      @param animated Whether to animate
///      @param completion Completion callback
- (void)cyl_setTabBarVisible:(BOOL)visible
                    animated:(BOOL)animated
                  completion:(void (^ _Nullable)(BOOL finished))completion {
    
    // [CN] 如果当前状态与目标状态相同，直接返回
    // [EN] If the current state equals the target state, return right away.
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
    
    // [CN] 计算关键位置
    // [EN] Compute the key positions
    CGRect visibleFrame = CGRectMake(0,
                                     screenSize.height - tabBarHeight,
                                     screenSize.width,
                                     tabBarHeight);
    
    CGRect hiddenFrame = CGRectMake(0,
                                    screenSize.height,  // [CN] 完全移到屏幕外
                                    // [EN] Move completely off-screen
                                    screenSize.width,
                                    tabBarHeight);
    
    NSTimeInterval duration = animated ? kFullScreenAnimationTime : 0.0;
    
    // [CN] 设置动画的起始帧
    // [EN] Set the animation's starting frame
    if (visible) {
        // [CN] 显示动画：起始位置在屏幕外（底部下方）
        // [EN] Show animation: starts off-screen (below the bottom)
        tabBar.frame = hiddenFrame;
    } else {
        // [CN] 隐藏动画：起始位置在可见位置
        // 注意：如果当前 TabBar 已经在可见位置，无需设置
        // 如果不在，先设置到可见位置再开始隐藏动画
        // [EN] Hide animation: starts at the visible position.
        //      Note: if the TabBar is already at the visible position, nothing needs to be set.
        //      If it is not, move it to the visible position first, then start the hide animation.
        if (!CGRectEqualToRect(tabBar.frame, visibleFrame)) {
            tabBar.frame = visibleFrame;
        }
    }
    
    // [CN] 目标帧
    // [EN] Target frame
    CGRect targetFrame = visible ? visibleFrame : hiddenFrame;
    
    // [CN] 执行动画
    // [EN] Run the animation
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

/// [CN] 判断 TabBar 是否可见（基于位置判断）
/// @return YES=可见，NO=不可见
/// [EN] Whether the TabBar is visible (based on its position).
///      @return YES = visible, NO = not visible
- (BOOL)cyl_tabBarIsVisible {
    CYLTabBar *tabBar = self.cyl_tabBarController.tabBar;
    if (![tabBar isKindOfClass:[CYLTabBar class]]) {
        return NO;
    }
    
    CGRect tabBarFrame = tabBar.frame;
    CGSize screenSize = CYLScreenSize();
    
    // [CN] 判断逻辑：TabBar 的顶部是否在屏幕范围内
    // 如果 minY < 屏幕高度，说明至少有一部分可见
    // [EN] Logic: whether the top of the TabBar is within the screen bounds.
    //      If minY < screen height, at least part of it is visible.
    return CGRectGetMinY(tabBarFrame) < screenSize.height;
}


#pragma mark - 便捷方法（可选）

/// [CN] 显示 TabBar（从底部升上来）
/// [EN] Show the TabBar (rise from the bottom)
- (void)cyl_showTabBarAnimated:(BOOL)animated
                    completion:(void (^ _Nullable)(BOOL finished))completion {
    [self cyl_setTabBarVisible:YES animated:animated completion:completion];
}

/// [CN] 隐藏 TabBar（降到底部屏幕外）
/// [EN] Hide the TabBar (drop off-screen at the bottom)
- (void)cyl_hideTabBarAnimated:(BOOL)animated
                    completion:(void (^ _Nullable)(BOOL finished))completion {
    [self cyl_setTabBarVisible:NO animated:animated completion:completion];
}

/// [CN] 切换 TabBar 可见性
/// [EN] Toggle TabBar visibility
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

// [CN] 在viewwilldisappear使用
// [EN] Use in viewwilldisappear
- (BOOL)cyl_shouldNavigationBarVisible {
    BOOL shouldSetNo = YES;
    
    BOOL isPop = YES;
    if (!self.navigationController) {
        return shouldSetNo;
    }
    // [CN] push的时候会先将vc添加到viewControllers，再调用viewWillDisappear
    //pop的时候会先将vc从viewControllers移除，再调用viewWillDisappear
    // [EN] On push, the vc is added to viewControllers first, then viewWillDisappear is called.
    //      On pop, the vc is removed from viewControllers first, then viewWillDisappear is called.
    NSInteger selfIndex = -1;
    if (self.navigationController.viewControllers.count > 0) {
        NSArray *vcList = self.navigationController.viewControllers;
        for (NSInteger i = 0; i < vcList.count; i++) {
            UIViewController *vc = vcList[i];
            if (vc == self) {
                selfIndex = i;
                if (selfIndex == vcList.count - 1) {
                    // [CN] 这种情况是navigationController push第一个vc或者present，不需要特殊处理，直接return
                    // [EN] This case is the navigationController pushing its first vc, or a present; no special handling is needed, just
                    //      return.
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
    // [EN] FIX: issue #535 — only with `cyl_hidesAncestorNavigationBars`. [CN] 仅在设置 `cyl_hidesAncestorNavigationBars` 时生效。
    [self cyl_hideAncestorNavigationBarsIfNeeded:animated];
}

- (void)cyl_viewWillDisappearNavigationSetting:(BOOL)animated {
    [self cyl_disableInteractivePopGestureRecognizer];
    [self cyl_setNavigationBarVisibleIfNeeded:animated];
}

- (void)cyl_viewDidDisappearNavigationSetting:(BOOL)animated {
    [self cyl_enableInteractivePopGestureRecognizer];
    // [EN] FIX: issue #535 — only with `cyl_hidesAncestorNavigationBars`. [CN] 仅在设置 `cyl_hidesAncestorNavigationBars` 时生效。
    [self cyl_showAncestorNavigationBarsIfNeeded:animated];
}

- (void)cyl_viewDidAppearNavigationSetting:(BOOL)animated {
    [self cyl_resetInteractivePopGestureRecognizer];
}

- (void)cyl_deallocNavigationSetting {
    [self cyl_disableInteractivePopGestureRecognizer];
}

@end
