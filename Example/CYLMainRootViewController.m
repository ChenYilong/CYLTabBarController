//
//  CYLMainRootViewController.m
//  CYLTabBarController
//
//  Created by chenyilong on 7/3/2026.
//  Copyright © 2026 微博@iOS程序犭袁. All rights reserved.
//

#import "CYLMainRootViewController.h"
#import "MainTabBarController.h"
#import "CYLPlusButtonSubclass.h"

@interface CYLMainRootViewController ()

@end

@implementation CYLMainRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    [self createNewTabBar];
    [self.tabBarController setSelectedIndex:0];
    [self.tabBarController setSelectedIndex:1];

//    [self.tabBarController.tabBar setNeedsLayout];
//[self.tabBarController.tabBar layoutSubviews];
}

- (CYLTabBarController *)createNewTabBar {
    [CYLPlusButtonSubclass registerPlusButton];
    return [self createNewTabBarWithContext:@""];
}

- (CYLTabBarController *)createNewTabBarWithContext:(NSString *)context {
    MainTabBarController *tabBarController = [[MainTabBarController alloc] initWithContext:context];
//    [tabBarController.tabBar layoutIfNeeded];

    
    self.viewControllers = @[tabBarController];
    return tabBarController;
}

@end
