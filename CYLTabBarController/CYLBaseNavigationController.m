/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "CYLBaseNavigationController.h"
#import "UIViewController+CYLTabBarControllerExtention.h"
#import "UIViewController+CYLNavigationControllerExtention.h"

@interface CYLBaseNavigationController ()

@end

@implementation CYLBaseNavigationController

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // 当前导航栏, 只有第一个viewController push的时候设置隐藏
    if (self.viewControllers.count == 1) {
        viewController.cyl_hidesBottomBarWhenPushed = YES;
    } else {
        viewController.cyl_hidesBottomBarWhenPushed = NO;
    }
    //FIXME:  闪动
    [viewController.view layoutIfNeeded];
    [super pushViewController:viewController animated:animated];

}

//fix https://github.com/ChenYilong/CYLTabBarController/issues/483
- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    [self toggleTabBarHidden];
    [super setViewControllers:viewControllers animated:animated];
}

- (void)toggleTabBarHidden {
    BOOL isHidden = (self.viewControllers.count > 1);
    UIViewController *viewController;
    @try {
        viewController = [self.viewControllers lastObject];
    } @catch (NSException *exception) {   
    }
    viewController.hidesBottomBarWhenPushed = isHidden;
}

- (BOOL)shouldAutorotate {
    return [self cyl_getViewControllerInsteadOfNavigationController].shouldAutorotate;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [self cyl_getViewControllerInsteadOfNavigationController].preferredInterfaceOrientationForPresentation;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self cyl_getViewControllerInsteadOfNavigationController].supportedInterfaceOrientations;
}

@end
