//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import "UITabBarItem+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarControllerExtention.h"

@implementation UITabBarItem (CYLTabBarControllerExtention)

- (UIControl *)cyl_tabButton {
    UIControl *control = [self valueForKeyPath:@"_view"];
    return control;
}

@end
