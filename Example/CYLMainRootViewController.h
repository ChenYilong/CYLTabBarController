//
//  CYLMainRootViewController.h
//  CYLTabBarController
//
//  Created by chenyilong on 7/3/2019.
//  Copyright © 2019 微博@iOS程序犭袁. All rights reserved.
//
#import <UIKit/UIKit.h>

#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface CYLMainRootViewController : UINavigationController

- (CYLTabBarController *)createNewTabBarWithContext:(NSString *)context;

@end

NS_ASSUME_NONNULL_END
