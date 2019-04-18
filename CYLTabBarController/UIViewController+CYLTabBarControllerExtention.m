//
//  UIViewController+CYLTabBarControllerExtention.m
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 16/2/26.
//  Copyright © 2018年 https://github.com/ChenYilong .All rights reserved.
//

#import "UIViewController+CYLTabBarControllerExtention.h"
#import "CYLTabBarController.h"
#import <objc/runtime.h>
#define kActualView     [self cyl_getActualBadgeSuperView]

@implementation UIViewController (CYLTabBarControllerExtention)

#pragma mark -
#pragma mark - public Methods

- (UIViewController *)cyl_popSelectTabBarChildViewControllerAtIndex:(NSUInteger)index {
    return [self cyl_popSelectTabBarChildViewControllerAtIndex:index animated:NO];
}

- (UIViewController *)cyl_popSelectTabBarChildViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated {
    UIViewController *viewController = [self cyl_getViewControllerInsteadOfNavigationController];
    [viewController checkTabBarChildControllerValidityAtIndex:index];
    CYLTabBarController *tabBarController = [viewController cyl_tabBarController];
    tabBarController.selectedIndex = index;
    [viewController.navigationController popToRootViewControllerAnimated:animated];
    UIViewController *selectedTabBarChildViewController = tabBarController.selectedViewController;
    return [selectedTabBarChildViewController cyl_getViewControllerInsteadOfNavigationController];
}

- (void)cyl_popSelectTabBarChildViewControllerAtIndex:(NSUInteger)index
                                           completion:(CYLPopSelectTabBarChildViewControllerCompletion)completion {
    UIViewController *selectedTabBarChildViewController = [self cyl_popSelectTabBarChildViewControllerAtIndex:index];
    dispatch_async(dispatch_get_main_queue(), ^{
        !completion ?: completion(selectedTabBarChildViewController);
    });
}

- (UIViewController *)cyl_popSelectTabBarChildViewControllerForClassType:(Class)classType {
    CYLTabBarController *tabBarController = [[self cyl_getViewControllerInsteadOfNavigationController] cyl_tabBarController];
    NSArray *viewControllers = tabBarController.viewControllers;
    NSInteger atIndex = [self cyl_indexForClassType:classType inViewControllers:viewControllers];
    return [self cyl_popSelectTabBarChildViewControllerAtIndex:atIndex];
}

- (void)cyl_popSelectTabBarChildViewControllerForClassType:(Class)classType
                                                completion:(CYLPopSelectTabBarChildViewControllerCompletion)completion {
    UIViewController *selectedTabBarChildViewController = [self cyl_popSelectTabBarChildViewControllerForClassType:classType];
    dispatch_async(dispatch_get_main_queue(), ^{
        !completion ?: completion(selectedTabBarChildViewController);
    });
}

- (void)cyl_pushOrPopToViewController:(UIViewController *)viewController
                             animated:(BOOL)animated
                             callback:(CYLPushOrPopCallback)callback {
    if (!callback) {
        [self.navigationController pushViewController:viewController animated:animated];
        return;
    }
    
    void (^popSelectTabBarChildViewControllerCallback)(BOOL shouldPopSelectTabBarChildViewController, NSUInteger index) = ^(BOOL shouldPopSelectTabBarChildViewController, NSUInteger index) {
        if (shouldPopSelectTabBarChildViewController) {
            [self cyl_popSelectTabBarChildViewControllerAtIndex:index completion:^(__kindof UIViewController *selectedTabBarChildViewController) {
                [selectedTabBarChildViewController.navigationController pushViewController:viewController animated:animated];
            }];
        } else {
            [self.navigationController pushViewController:viewController animated:animated];
        }
    };
    NSArray<__kindof UIViewController *> *otherSameClassTypeViewControllersInCurrentNavigationControllerStack = [self cyl_getOtherSameClassTypeViewControllersInCurrentNavigationControllerStack:viewController];
    
    CYLPushOrPopCompletionHandler completionHandler = ^(BOOL shouldPop,
                                                        __kindof UIViewController *viewControllerPopTo,
                                                        BOOL shouldPopSelectTabBarChildViewController,
                                                        NSUInteger index
                                                        ) {
        if (!otherSameClassTypeViewControllersInCurrentNavigationControllerStack || otherSameClassTypeViewControllersInCurrentNavigationControllerStack.count == 0) {
            shouldPop = NO;
        }
        dispatch_async(dispatch_get_main_queue(),^{
            if (shouldPop) {
                [self.navigationController popToViewController:viewControllerPopTo animated:animated];
                return;
            }
            popSelectTabBarChildViewControllerCallback(shouldPopSelectTabBarChildViewController, index);
        });
    };
    callback(otherSameClassTypeViewControllersInCurrentNavigationControllerStack, completionHandler);
}

- (void)cyl_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    UIViewController *fromViewController = [self cyl_getViewControllerInsteadOfNavigationController];
    NSArray *childViewControllers = fromViewController.navigationController.childViewControllers;
    if (childViewControllers.count > 0) {
        if ([[childViewControllers lastObject] isKindOfClass:[viewController class]]) {
            return;
        }
    }
    [fromViewController.navigationController pushViewController:viewController animated:animated];
}

- (UIViewController *)cyl_getViewControllerInsteadOfNavigationController {
    BOOL isNavigationController = [[self class] isSubclassOfClass:[UINavigationController class]];
    if (isNavigationController && ((UINavigationController *)self).viewControllers.count > 0) {
        return ((UINavigationController *)self).viewControllers[0];
    }
    return self;
}

#pragma mark - public method

- (BOOL)cyl_isPlusChildViewController {
    if (!CYLPlusChildViewController) {
        return NO;
    }
    return (self == CYLPlusChildViewController);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (void)cyl_showTabBadgePoint {
    if (self.cyl_isPlusChildViewController) {
        return;
    }
    [self cyl_showBadge];
}

- (void)cyl_removeTabBadgePoint {
    if (self.cyl_isPlusChildViewController) {
        return;
    }
    [self cyl_clearBadge];
}

- (BOOL)cyl_isShowTabBadgePoint {
    if (self.cyl_isPlusChildViewController) {
        return NO;
    }
    return [self cyl_isShowBadge];;
}
#pragma clang diagnostic pop

- (void)cyl_setTabBadgePointView:(UIView *)tabBadgePointView {
    if (self.cyl_isPlusChildViewController) {
        return;
    }
    [self.cyl_tabButton cyl_setTabBadgePointView:tabBadgePointView];
}

- (UIView *)cyl_tabBadgePointView {
    if (self.cyl_isPlusChildViewController) {
        return nil;
    }
    return [self.cyl_tabButton cyl_tabBadgePointView];;
}

- (void)cyl_setTabBadgePointViewOffset:(UIOffset)tabBadgePointViewOffset {
    if (self.cyl_isPlusChildViewController) {
        return;
    }
    return [self.cyl_tabButton cyl_setTabBadgePointViewOffset:tabBadgePointViewOffset];
}

//offset如果都是整数，则往右下偏移
- (UIOffset)cyl_tabBadgePointViewOffset {
    if (self.cyl_isPlusChildViewController) {
        return UIOffsetZero;
    }
    return [self.cyl_tabButton cyl_tabBadgePointViewOffset];
}

- (BOOL)cyl_isEmbedInTabBarController {
    if (self.cyl_tabBarController == nil) {
        return NO;
    }
    if (self.cyl_isPlusChildViewController) {
        return NO;
    }
    BOOL isEmbedInTabBarController = NO;
    UIViewController *viewControllerInsteadIOfNavigationController = [self cyl_getViewControllerInsteadOfNavigationController];
    for (NSInteger i = 0; i < self.cyl_tabBarController.viewControllers.count; i++) {
        UIViewController * vc = self.cyl_tabBarController.viewControllers[i];
        if ([vc cyl_getViewControllerInsteadOfNavigationController] == viewControllerInsteadIOfNavigationController) {
            isEmbedInTabBarController = YES;
            [self cyl_setTabIndex:i];
            break;
        }
    }
    return isEmbedInTabBarController;
}

- (void)cyl_setTabIndex:(NSInteger)tabIndex {
    objc_setAssociatedObject(self, @selector(cyl_tabIndex), @(tabIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)cyl_tabIndex {
    if (!self.cyl_isEmbedInTabBarController) {
        return NSNotFound;
    }
    
    id tabIndexObject = objc_getAssociatedObject(self, @selector(cyl_tabIndex));
    NSInteger tabIndex = [tabIndexObject integerValue];
    return tabIndex;
}

- (UIControl *)cyl_tabButton {
    if (!self.cyl_isEmbedInTabBarController) {
        return nil;
    }
    UITabBarItem *tabBarItem;
    UIControl *control;
    @try {
        tabBarItem = self.cyl_tabBarController.tabBar.items[self.cyl_tabIndex];
        control = [tabBarItem cyl_tabButton];
    } @catch (NSException *exception) {}
    return control;
}

- (NSString *)cyl_context {
    return objc_getAssociatedObject(self, @selector(cyl_context));
}

- (void)cyl_setContext:(NSString *)cyl_context {
    objc_setAssociatedObject(self, @selector(cyl_context), cyl_context, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)cyl_plusViewControllerEverAdded {
    NSNumber *cyl_plusViewControllerEverAddedObject = objc_getAssociatedObject(self, @selector(cyl_plusViewControllerEverAdded));
    return [cyl_plusViewControllerEverAddedObject boolValue];
}

- (void)cyl_setPlusViewControllerEverAdded:(BOOL)cyl_plusViewControllerEverAdded {
    NSNumber *cyl_plusViewControllerEverAddedObject = [NSNumber numberWithBool:cyl_plusViewControllerEverAdded];
    objc_setAssociatedObject(self, @selector(cyl_plusViewControllerEverAdded), cyl_plusViewControllerEverAddedObject, OBJC_ASSOCIATION_ASSIGN);
}

#pragma mark -
#pragma mark - Private Methods

- (NSArray<__kindof UIViewController *> *)cyl_getOtherSameClassTypeViewControllersInCurrentNavigationControllerStack:(UIViewController *)viewController {
    NSArray *currentNavigationControllerStack = [self.navigationController childViewControllers];
    if (currentNavigationControllerStack.count < 2) {
        return nil;
    }
    NSMutableArray *mutableArray = [currentNavigationControllerStack mutableCopy];
    [mutableArray removeObject:self];
    currentNavigationControllerStack = [mutableArray copy];
    
    __block NSMutableArray *mutableOtherViewControllersInNavigationControllerStack = [NSMutableArray arrayWithCapacity:currentNavigationControllerStack.count];
    
    [currentNavigationControllerStack enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIViewController *otherViewController = obj;
        if ([otherViewController isKindOfClass:[viewController class]]) {
            [mutableOtherViewControllersInNavigationControllerStack addObject:otherViewController];
        }
    }];
    return [mutableOtherViewControllersInNavigationControllerStack copy];
}

- (void)checkTabBarChildControllerValidityAtIndex:(NSUInteger)index {
    CYLTabBarController *tabBarController = [[self cyl_getViewControllerInsteadOfNavigationController] cyl_tabBarController];
    @try {
        UIViewController *viewController;
        viewController = tabBarController.viewControllers[index];
        UIButton *plusButton = CYLExternPlusButton;
        BOOL shouldConfigureSelectionStatus = (CYLPlusChildViewController) && ((index != CYLPlusButtonIndex) && (viewController != CYLPlusChildViewController));
        if (shouldConfigureSelectionStatus) {
            plusButton.selected = NO;
        }
    } @catch (NSException *exception) {
        NSString *formatString = @"\n\n\
        ------ BEGIN NSException Log ---------------------------------------------------------------------\n \
        class name: %@                                                                                    \n \
        ------line: %@                                                                                    \n \
        ----reason: The Class Type or the index or its NavigationController you pass in method `-cyl_popSelectTabBarChildViewControllerAtIndex` or `-cyl_popSelectTabBarChildViewControllerForClassType` is not the item of CYLTabBarViewController \n \
        ------ END ---------------------------------------------------------------------------------------\n\n";
        NSString *reason = [NSString stringWithFormat:formatString,
                            @(__PRETTY_FUNCTION__),
                            @(__LINE__)];
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), reason);
    }
}

- (NSInteger)cyl_indexForClassType:(Class)classType inViewControllers:(NSArray *)viewControllers {
    __block NSInteger atIndex = NSNotFound;
    [viewControllers enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIViewController *obj_ = [obj cyl_getViewControllerInsteadOfNavigationController];
        if ([obj_ isKindOfClass:classType]) {
            atIndex = idx;
            *stop = YES;
            return;
        }
    }];
    return atIndex;
}

+ (UIViewController * __nullable)cyl_topmostViewController {
    UIViewController *topViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    if (topViewController == nil) {
        return nil;
    }
    
    while (true) {
        if (topViewController.presentedViewController != nil) {
            topViewController = topViewController.presentedViewController;
        } else if ([topViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navi = (UINavigationController *)topViewController;
            topViewController = navi.topViewController;
        } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *)topViewController;
            topViewController = tab.selectedViewController;
        } else {
            break;
        }
    }
    
    return topViewController;
}

+ (UINavigationController * __nullable)cyl_currentNavigationController {
    return [[UIViewController cyl_topmostViewController] navigationController];
}

+ (void)cyl_dismissAll:(void (^ __nullable)(void))completion {
    UIViewController *topViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    if (topViewController == nil) {
        !completion ?: completion();
        return;
    }
    
    NSMutableArray *list = [NSMutableArray new];
    
    while (true) {
        if (topViewController.presentedViewController != nil) {
            topViewController = topViewController.presentedViewController;
            [list addObject:topViewController];
        } else if ([topViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navi = (UINavigationController *)topViewController;
            topViewController = navi.topViewController;
        } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *)topViewController;
            topViewController = tab.selectedViewController;
        } else {
            break;
        }
    }
    
    if (list.count == 0) {
        if (completion) {
            completion();
        }
        return;
    }
    
    for (NSInteger i = list.count - 1; i >=0 ; i--) {
        
        UIViewController *vc = list[i];
        if (i == 0) {
            if ([vc isKindOfClass:[UINavigationController class]]) {
                [(UINavigationController *)vc popToRootViewControllerAnimated:NO];
            }
            [vc dismissViewControllerAnimated:NO completion:completion];
        } else {
            if ([vc isKindOfClass:[UINavigationController class]]) {
                [(UINavigationController *)vc popToRootViewControllerAnimated:NO];
            }
            [vc dismissViewControllerAnimated:NO completion:nil];
        }
    }
}

- (void)cyl_handleNavigationBackAction {
    [self cyl_handleNavigationBackActionWithAnimated:YES];
}

- (void)cyl_handleNavigationBackActionWithAnimated:(BOOL)animated {
    if (!self.presentationController) {
        [self.navigationController popViewControllerAnimated:animated];
        return;
    }
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:animated];
    } else {
        [self dismissViewControllerAnimated:animated completion:nil];
    }
}

#pragma mark -- public methods

/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 */
- (void)cyl_showBadge {
    [kActualView cyl_showBadge];
}

- (void)cyl_showBadgeValue:(NSString *)value
             animationType:(CYLBadgeAnimationType)animationType {
    [kActualView cyl_showBadgeValue:value animationType:animationType];
}

- (void)cyl_clearBadge {
    [kActualView cyl_clearBadge];
}

- (void)cyl_resumeBadge {
    [kActualView cyl_resumeBadge];
}

- (BOOL)cyl_isShowBadge {
    return [kActualView cyl_isShowBadge];
}

- (BOOL)cyl_isPauseBadge {
    return [kActualView cyl_isPauseBadge];
}

#pragma mark -- private method

/**
 *  Because UIBarButtonItem is kind of NSObject, it is not able to directly attach badge.
 This method is used to find actual view (non-nil) inside UIBarButtonItem instance.
 *
 *  @return view
 */
- (UITabBarItem *)cyl_getActualBadgeSuperView {
    UIViewController *viewController = self.cyl_getViewControllerInsteadOfNavigationController;
    UITabBarItem *viewControllerItem = viewController.tabBarItem;
    UIControl *viewControllerControl = viewControllerItem.cyl_tabButton;
    UITabBarItem *navigationViewControllerItem = viewController.navigationController.tabBarItem;
    if (viewControllerControl) {
        return viewControllerItem;
    }
    return navigationViewControllerItem;
}

#pragma mark -- setter/getter
- (UILabel *)cyl_badge {
    return kActualView.cyl_badge;
}

- (void)cyl_setBadge:(UILabel *)label {
    [kActualView cyl_setBadge:label];
}

- (UIFont *)cyl_badgeFont {
    return kActualView.cyl_badgeFont;
}

- (void)cyl_setBadgeFont:(UIFont *)badgeFont {
    [kActualView cyl_setBadgeFont:badgeFont];
}

- (UIColor *)cyl_badgeBackgroundColor {
    return [kActualView cyl_badgeBackgroundColor];
}

- (void)cyl_setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor {
    [kActualView cyl_setBadgeBackgroundColor:badgeBackgroundColor];
}

- (UIColor *)cyl_badgeTextColor {
    return [kActualView cyl_badgeTextColor];
}

- (void)cyl_setBadgeTextColor:(UIColor *)badgeTextColor {
    [kActualView cyl_setBadgeTextColor:badgeTextColor];
}

- (CYLBadgeAnimationType)cyl_badgeAnimationType {
    return [kActualView cyl_badgeAnimationType];
}

- (void)cyl_setBadgeAnimationType:(CYLBadgeAnimationType)animationType {
    [kActualView cyl_setBadgeAnimationType:animationType];
}

- (CGRect)cyl_badgeFrame {
    return [kActualView cyl_badgeFrame];
}

- (void)cyl_setBadgeFrame:(CGRect)badgeFrame {
    [kActualView cyl_setBadgeFrame:badgeFrame];
}

- (CGPoint)cyl_badgeCenterOffset {
    return [kActualView cyl_badgeCenterOffset];
}

- (void)cyl_setBadgeCenterOffset:(CGPoint)badgeCenterOffset {
    [kActualView cyl_setBadgeCenterOffset:badgeCenterOffset];
}

- (NSInteger)cyl_badgeMaximumBadgeNumber {
    return [kActualView cyl_badgeMaximumBadgeNumber];
}

- (void)cyl_setBadgeMaximumBadgeNumber:(NSInteger)badgeMaximumBadgeNumber {
    [kActualView cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber];
}

- (CGFloat)cyl_badgeMargin {
    return [kActualView cyl_badgeMargin];
}

- (void)cyl_setBadgeMargin:(CGFloat)badgeMargin {
    [kActualView cyl_setBadgeMargin:badgeMargin];
}

- (CGFloat)cyl_badgeRadius {
    return [kActualView cyl_badgeRadius];
}

- (void)cyl_setBadgeRadius:(CGFloat)badgeRadius {
    [kActualView cyl_setBadgeRadius:badgeRadius];
}

@end
