//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2015 https://github.com/ChenYilong . All rights reserved.
//

#import "UITabBarItem+CYLTabBarControllerExtention.h"
#import <objc/runtime.h>
#import "UIControl+CYLTabBarControllerExtention.h"

@implementation UITabBarItem (CYLTabBarControllerExtention)

+ (void)load {
    [self cyl_swizzleSetBadgeValue];
}

+ (void)cyl_swizzleSetBadgeValue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cyl_ClassMethodSwizzle([self class], @selector(setBadgeValue:), @selector(cyl_setBadgeValue:));
    });
}

- (void)cyl_setBadgeValue:(NSString *)badgeValue {
    [self.cyl_tabButton cyl_removeTabBadgePoint];
    [self cyl_setBadgeValue:badgeValue];
}

- (UIControl *)cyl_tabButton {
    UIControl *control = [self valueForKey:@"view"];
    return control;
}

#pragma mark - private method

BOOL cyl_ClassMethodSwizzle(Class aClass, SEL originalSelector, SEL swizzleSelector) {
    Method originalMethod = class_getInstanceMethod(aClass, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(aClass, swizzleSelector);
    BOOL didAddMethod =
    class_addMethod(aClass,
                    originalSelector,
                    method_getImplementation(swizzleMethod),
                    method_getTypeEncoding(swizzleMethod));
    if (didAddMethod) {
        class_replaceMethod(aClass,
                            swizzleSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzleMethod);
    }
    return YES;
}

@end
