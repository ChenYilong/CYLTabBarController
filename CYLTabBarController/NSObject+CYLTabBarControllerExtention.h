//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (CYLTabBarControllerExtention)

@property (nonatomic, assign, getter=cyl_isForceLandscape, setter=cyl_setIsForceLandscape:) BOOL cyl_isForceLandscape;

- (void)cyl_forceUpdateInterfaceOrientation:(UIInterfaceOrientation)orientation;

- (UIResponder<UIApplicationDelegate> *)cyl_sharedAppDelegate;
+ (UIViewController * __nullable)cyl_topmostViewController;

+ (UINavigationController * __nullable)cyl_currentNavigationController;

+ (void)cyl_dismissAll:(void (^ __nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
