//
//  CYLPlusButton.m
//  CYLCustomTabBarDemo
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2015 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPlusButton.h"
#import "CYLTabBarController.h"

CGFloat CYLPlusButtonWidth = 0.0f;
UIButton<CYLPlusButtonSubclassing> *CYLExternPlusButton = nil;
UIViewController *CYLPlusChildViewController = nil;

@implementation CYLPlusButton

#pragma mark -
#pragma mark - Private Methods

+ (void)registerSubclass {
    if ([self conformsToProtocol:@protocol(CYLPlusButtonSubclassing)]) {
        Class<CYLPlusButtonSubclassing> class = self;
        UIButton<CYLPlusButtonSubclassing> *plusButton = [class plusButton];
        CYLExternPlusButton = plusButton;
        CYLPlusButtonWidth = plusButton.frame.size.width;
        if ([[self class] respondsToSelector:@selector(plusChildViewController)]) {
            CYLPlusChildViewController = [class plusChildViewController];
            [[self class] addSelectViewControllerTarget:plusButton];
            if ([[self class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)]) {
                CYLPlusButtonIndex = [[self class] indexOfPlusButtonInTabBar];
            } else {
                [NSException raise:@"CYLTabBarController" format:@"If you want to add PlusChildViewController, you must realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】如果你想使用PlusChildViewController样式，你必须同时在你自定义的plusButton中实现 `+indexOfPlusButtonInTabBar`，来指定plusButton的位置"];
            }
        }
        
    }
}

+ (void)addSelectViewControllerTarget:(UIButton<CYLPlusButtonSubclassing> *)plusButton {
    id target = self;
    NSArray<NSString *> *selectorNamesArray = [plusButton actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
    if (selectorNamesArray.count == 0) {
        target = plusButton;
        selectorNamesArray = [plusButton actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
    }
    [selectorNamesArray enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SEL selector =  NSSelectorFromString(obj);
        [plusButton removeTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    }];
    [plusButton addTarget:plusButton action:@selector(plusChildViewControllerButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)plusChildViewControllerButtonClicked:(UIButton<CYLPlusButtonSubclassing> *)sender {
    sender.selected = YES;
    [self cyl_tabBarController].selectedIndex = CYLPlusButtonIndex;
}

@end
