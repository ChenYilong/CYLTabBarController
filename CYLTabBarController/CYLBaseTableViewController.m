/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2019 https://github.com/ChenYilong . All rights reserved.
 */


#import "CYLBaseTableViewController.h"
#import "CYLTabBarController.h"

@interface CYLBaseTableViewController ()

@end

@implementation CYLBaseTableViewController

#pragma mark -
#pragma mark - UIViewController Life

- (void)viewDidLoad {
    [super viewDidLoad];
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
