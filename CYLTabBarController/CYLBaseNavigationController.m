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

/**
 * TabBar内的ViewControllers会懒加载
 */
- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    // 当前导航栏, 只有第一个viewController push的时候设置隐藏
    if (self.viewControllers.count == 1) {
        viewController.cyl_hidesBottomBarWhenPushed = YES;
    } else {
        viewController.cyl_hidesBottomBarWhenPushed = NO;
    }
    //在ios26.1，如果rootVC是TabbarController，并且通过UINavigationControllert跳转，UINavigationControllery页面的布局会多出来一个动画，这个问题请问怎么处理？
    //FIXME: #632 如果你想避免闪动，可以通过提前加载 viewController 来解决。但是负作用是 viewController viewDidLoad 会提前加载， 所以不推荐该默认操作， 如果你可以接受 viewDidLoad 提前加载， 请pushViewController 后，自行调用该方法，解决闪动问题。
    // [viewController.view layoutIfNeeded];
    [super pushViewController:viewController animated:animated];
}

//fix https://github.com/ChenYilong/CYLTabBarController/issues/483
- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    [super setViewControllers:viewControllers animated:animated];
    [self toggleTabBarHidden];
}

- (NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated {
    NSArray<__kindof UIViewController *> *array = [super popToRootViewControllerAnimated:animated];
    [self toggleTabBarHidden];
    return array;
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    UIViewController *viewController = [super popViewControllerAnimated:animated];
    [self toggleTabBarHidden];
    return viewController;
}

- (NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray<__kindof UIViewController *> * array = [super popToViewController:viewController animated:animated];
    [self toggleTabBarHidden];
    return array;
}

- (void)toggleTabBarHidden {
    BOOL isHidden = (self.viewControllers.count > 1);
    UIViewController *viewController;
    @try {
        viewController = [self.viewControllers lastObject];
    } @catch (NSException *exception) {   
    }
    viewController.cyl_hidesBottomBarWhenPushed = isHidden;
}

@end
