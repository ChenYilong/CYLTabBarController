//
//  CYLPlusButton.m
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPlusButton.h"
#import "CYLTabBarController.h"
#import "UIViewController+CYLTabBarControllerExtention.h"

CGFloat CYLPlusButtonWidth = 0.0f;
UIButton<CYLPlusButtonSubclassing> *CYLExternPlusButton = nil;
UIViewController *CYLPlusChildViewController = nil;

@implementation CYLPlusButton

#pragma mark -
#pragma mark - public Methods

+ (void)registerPlusButton {
    if (![self conformsToProtocol:@protocol(CYLPlusButtonSubclassing)]) {
        return;
    }
    Class<CYLPlusButtonSubclassing> class = self;
    UIButton<CYLPlusButtonSubclassing> *plusButton = [class plusButton];
    CYLExternPlusButton = plusButton;
    CYLPlusButtonWidth = plusButton.frame.size.width;
    if ([[self class] respondsToSelector:@selector(plusChildViewController)]) {
        CYLPlusChildViewController = [class plusChildViewController];
        if ([[self class] respondsToSelector:@selector(tabBarContext)]) {
            NSString *tabBarContext = [class tabBarContext];
            if (tabBarContext && tabBarContext.length) {
                [CYLPlusChildViewController cyl_setContext:tabBarContext];
            }
        } else {
            [CYLPlusChildViewController cyl_setContext:NSStringFromClass([CYLTabBarController class])];
        }
        [[self class] addSelectViewControllerTarget:plusButton];
        if ([[self class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)]) {
            CYLPlusButtonIndex = [[self class] indexOfPlusButtonInTabBar];
        } else {
            [NSException raise:NSStringFromClass([CYLTabBarController class]) format:@"If you want to add PlusChildViewController, you must realizse `+indexOfPlusButtonInTabBar` in your custom plusButton class.【Chinese】如果你想使用PlusChildViewController样式，你必须同时在你自定义的plusButton中实现 `+indexOfPlusButtonInTabBar`，来指定plusButton的位置"];
        }
    }
}

+ (void)removePlusButton {
    CYLExternPlusButton = nil;
    [CYLPlusChildViewController cyl_setPlusViewControllerEverAdded:NO];
    CYLPlusChildViewController = nil;
}

+ (void)registerSubclass {
    [self registerPlusButton];
}

- (void)plusChildViewControllerButtonClicked:(UIButton<CYLPlusButtonSubclassing> *)sender {
    BOOL notNeedConfigureSelectionStatus = [[self class] respondsToSelector:@selector(shouldSelectPlusChildViewController)] && ![[self class] shouldSelectPlusChildViewController];
    if (notNeedConfigureSelectionStatus) {
        return;
    }
    CYLTabBarController *tabBarController = [sender cyl_tabBarController];
    NSInteger index = [tabBarController.viewControllers indexOfObject:CYLPlusChildViewController];
    if (NSNotFound != index && (index < tabBarController.viewControllers.count)) {
        [tabBarController setSelectedIndex:index];
    }
}

#pragma mark -
#pragma mark - Private Methods

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

/**
 *  按钮选中状态下点击先显示normal状态的颜色，松开时再回到selected状态下颜色。
 *  重写此方法即不会出现上述情况，与 UITabBarButton 相似
 */
- (void)setHighlighted:(BOOL)highlighted {}

@end
