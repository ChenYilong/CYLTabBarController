//
//  UIViewController+CYLTabBarControllerExtention.m
//  CYLTabBarController
//
//  v1.10.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 16/2/26.
//  Copyright © 2016年 https://github.com/ChenYilong .All rights reserved.
//

#import "UIViewController+CYLTabBarControllerExtention.h"
#import "CYLTabBarController.h"

@implementation UIViewController (CYLTabBarControllerExtention)

#pragma mark -
#pragma mark - public Methods

- (UIViewController *)cyl_popSelectTabBarChildViewControllerAtIndex:(NSUInteger)index {
    [self checkTabBarChildControllerValidityAtIndex:index];
    [self.navigationController popToRootViewControllerAnimated:NO];
    CYLTabBarController *tabBarController = [self cyl_tabBarController];
    tabBarController.selectedIndex = index;
    UIViewController *selectedTabBarChildViewController = tabBarController.selectedViewController;
    return [selectedTabBarChildViewController cyl_getViewControllerInsteadIOfNavigationController];
}

- (void)cyl_popSelectTabBarChildViewControllerAtIndex:(NSUInteger)index
                                           completion:(CYLPopSelectTabBarChildViewControllerCompletion)completion {
    UIViewController *selectedTabBarChildViewController = [self cyl_popSelectTabBarChildViewControllerAtIndex:index];
    dispatch_async(dispatch_get_main_queue(), ^{
        !completion ?: completion(selectedTabBarChildViewController);
    });
}

- (UIViewController *)cyl_popSelectTabBarChildViewControllerForClassType:(Class)classType {
    CYLTabBarController *tabBarController = [self cyl_tabBarController];
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
    UIViewController *fromViewController = [self cyl_getViewControllerInsteadIOfNavigationController];
    NSArray *childViewControllers = fromViewController.navigationController.childViewControllers;
    if (childViewControllers.count > 0) {
        if ([[childViewControllers lastObject] isKindOfClass:[viewController class]]) {
            return;
        }
    }
    [fromViewController.navigationController pushViewController:viewController animated:animated];
}

- (UIViewController *)cyl_getViewControllerInsteadIOfNavigationController {
    BOOL isNavigationController = [[self class] isSubclassOfClass:[UINavigationController class]];
    if (isNavigationController) {
        return ((UINavigationController *)self).viewControllers[0];
    }
    return self;
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
    CYLTabBarController *tabBarController = [self cyl_tabBarController];
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
        UIViewController *obj_ = [obj cyl_getViewControllerInsteadIOfNavigationController];
        if ([obj_ isKindOfClass:classType]) {
            atIndex = idx;
            *stop = YES;
            return;
        }
    }];
    return atIndex;
}

@end
