//
//  CYLMainRootViewController.h
//  CYLTabBarController
//
//  Created by chenyilong on 7/3/2019.
//  Copyright © 2019 微博@iOS程序犭袁. All rights reserved.
//
#import <UIKit/UIKit.h>

@class CYLTabBarController;

NS_ASSUME_NONNULL_BEGIN

@interface CYLMainRootViewController : UINavigationController

+ (void)customizeInterfaceWithTabBarController:(CYLTabBarController *)tabBarController;
- (void)createNewTabBar;

@end

NS_ASSUME_NONNULL_END
