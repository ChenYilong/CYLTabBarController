//
//  CYLMainRootViewController.h
//  CYLTabBarController
//
//  Created by chenyilong on 7/3/2026.
//  Copyright © 2026 微博@iOS程序犭袁. All rights reserved.
//
#import <UIKit/UIKit.h>

#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif
@class CYLFlatDesignMainTabBarController;

NS_ASSUME_NONNULL_BEGIN

@interface CYLMainRootViewController : UINavigationController

- (CYLTabBarController *)createLiquidGlassTabBar;
- (CYLTabBarController *)createNewTabBarWithContext:(NSString *)context;
- (CYLFlatDesignMainTabBarController *)createFlatDesignTabBar;

@end

NS_ASSUME_NONNULL_END
