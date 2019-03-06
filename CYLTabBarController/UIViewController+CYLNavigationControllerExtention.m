/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2019 https://github.com/ChenYilong . All rights reserved.
 */

#import "UIViewController+CYLNavigationControllerExtention.h"
#import <objc/runtime.h>

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

//viewWillDisappear
//dealloc
// 在左滑动的过渡的时间段内禁用interactivePopGestureRecognizer
- (void)cyl_disableInteractivePopGestureRecognizer {
    if (![self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        return;
    }
    self.navigationController.interactivePopGestureRecognizer.delegate = nil;
}

//viewDidDisappear
// 在左滑动的结束后启用interactivePopGestureRecognizer
- (void)cyl_enableInteractivePopGestureRecognizer {
    if (![self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        return;
    }
    self.navigationController.interactivePopGestureRecognizer.delegate = (id <UIGestureRecognizerDelegate>)self;
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
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
    } else {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

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
