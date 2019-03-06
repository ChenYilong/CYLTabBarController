/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2019 https://github.com/ChenYilong . All rights reserved.
 */

#import "UITabBar+CYLTabBarControllerExtention.h"

@implementation UITabBar (CYLTabBarControllerExtention)

- (NSArray<UIControl *> *)cyl_subControls {
    NSMutableArray *subControls = [NSMutableArray arrayWithCapacity:self.subviews.count];
    for (UIControl *control in self.subviews) {
        if ([control isKindOfClass:[UIControl class]]) {
            [subControls addObject:control];
        }
    }
    return subControls;
}

@end
