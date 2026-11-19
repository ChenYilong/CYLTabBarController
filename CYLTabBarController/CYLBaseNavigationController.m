/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

// CYL-SWIFT-MIGRATION: objc-shell — [EN] `CYLBaseNavigationController` stays an Objective-C class because Objective-C code
//      subclasses it (apps, the demos); it holds no logic: each override calls `super`, then a method of
//      `UINavigationController (CYLBaseNavigation)` in Swift (`Swift/UINavigationController+CYLBaseNavigation.swift`, step 102).
//      [CN] `CYLBaseNavigationController` 保留为 Objective-C 类，因为 Objective-C 代码会继承它（App、示例）；它不含逻辑：每个重写先调用
//      `super`，再调用 Swift 中 `UINavigationController (CYLBaseNavigation)` 的方法（`Swift/UINavigationController+CYLBaseNavigation.swift`，第 102 步）。
#import "CYLBaseNavigationController.h"
#import "CYLSwiftInterface.h"

@implementation CYLBaseNavigationController

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [self cyl_baseNavigationWillPushViewController:viewController];
    [super pushViewController:viewController animated:animated];
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated {
    [super setViewControllers:viewControllers animated:animated];
    [self cyl_baseNavigationToggleTabBarHidden];
}

- (NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated {
    NSArray<__kindof UIViewController *> *viewControllers = [super popToRootViewControllerAnimated:animated];
    [self cyl_baseNavigationToggleTabBarHidden];
    return viewControllers;
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    UIViewController *viewController = [super popViewControllerAnimated:animated];
    [self cyl_baseNavigationToggleTabBarHidden];
    return viewController;
}

- (NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray<__kindof UIViewController *> *viewControllers = [super popToViewController:viewController animated:animated];
    [self cyl_baseNavigationToggleTabBarHidden];
    return viewControllers;
}

@end
