/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2019 https://github.com/ChenYilong . All rights reserved.
 */

#import "UITabBar+CYLTabBarControllerExtention.h"
#import "UIView+CYLTabBarControllerExtention.h"
#import "CYLTabBar.h"

@implementation UITabBar (CYLTabBarControllerExtention)

- (NSArray *)cyl_visibleControls {
        if (self.subviews.count == 0) {
            return self.subviews;
        }
        NSMutableArray *tabBarButtonArray = [NSMutableArray arrayWithCapacity:self.subviews.count];
        [self.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj cyl_isTabButton] || [obj cyl_isPlusButton] ) {
                [tabBarButtonArray addObject:obj];
            }
        }];
        
        NSArray *sortedSubviews = [[tabBarButtonArray copy] sortedArrayUsingComparator:^NSComparisonResult(UIView * formerView, UIView * latterView) {
            CGFloat formerViewX = formerView.frame.origin.x;
            CGFloat latterViewX = latterView.frame.origin.x;
            return  (formerViewX > latterViewX) ? NSOrderedDescending : NSOrderedAscending;
        }];
        return sortedSubviews;
}

- (NSArray<UIControl *> *)cyl_subTabBarButtons {
    NSMutableArray *subControls = [NSMutableArray arrayWithCapacity:self.subviews.count];
    for (UIControl *control in self.cyl_visibleControls) {
        if ([control cyl_isTabButton]) {
            [subControls addObject:control];
        }
    }
    return subControls;
}

@end
