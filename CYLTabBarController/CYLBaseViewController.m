/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

// CYL-SWIFT-MIGRATION: objc-shell — [EN] `CYLBaseViewController` stays an Objective-C class because Objective-C code subclasses it
//      (the demo's view controllers, apps); it holds no logic: each lifecycle method only calls the
//      `-cyl_…NavigationSetting` methods of `UIViewController (CYLTabBarControllerExtention)`, which move to Swift
//      with that category (docs/Swift-Migration.md).
//      [CN] `CYLBaseViewController` 保留为 Objective-C 类，因为 Objective-C 代码会继承它（示例中的控制器、App）；它不含逻辑：每个生命周期
//      方法只调用 `UIViewController (CYLTabBarControllerExtention)` 的 `-cyl_…NavigationSetting` 方法，这些方法随该类别迁移到
//      Swift（docs/Swift-Migration.md）。
#import "CYLBaseViewController.h"
#import "CYLTabBarController.h"

@interface CYLBaseViewController ()

@end

@implementation CYLBaseViewController

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view layoutIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self cyl_viewWillAppearNavigationSetting:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self cyl_viewDidAppearNavigationSetting:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self cyl_viewWillDisappearNavigationSetting:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self cyl_viewDidDisappearNavigationSetting:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [self cyl_deallocNavigationSetting];
}

@end

