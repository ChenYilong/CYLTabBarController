//
//  UIViewController+CYLTabBarControllerExtention.m
//  CYLTabBarController
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 16/2/26.
//  Copyright © 2016年 https://github.com/ChenYilong .All rights reserved.
//

#import "UIViewController+CYLTabBarControllerExtention.h"
#import "CYLTabBarController.h"
#import <objc/runtime.h>

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

- (void)cyl_showTabBadgePoint {
    if (self.cyl_isPlusChildViewController) {
        return;
    }
    [self.cyl_tabButton cyl_showTabBadgePoint];
    [[[self cyl_getViewControllerInsteadOfNavigationController] cyl_tabBarController].tabBar layoutIfNeeded];
}

- (void)cyl_removeTabBadgePoint {
    if (self.cyl_isPlusChildViewController) {
        return;
    }
    [self.cyl_tabButton cyl_removeTabBadgePoint];
    [[[self cyl_getViewControllerInsteadOfNavigationController] cyl_tabBarController].tabBar layoutIfNeeded];
}

- (BOOL)cyl_isShowTabBadgePoint {
    if (self.cyl_isPlusChildViewController) {
        return NO;
    }
    return [self.cyl_tabButton cyl_isShowTabBadgePoint];
}

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
        @throw [NSException exceptionWithName:NSGenericException
                                       reason:reason
                                     userInfo:nil];
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

@end
