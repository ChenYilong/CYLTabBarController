//
//  NSObject+CYLUtils.m
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "NSObject+CYLUtils.h"
#import "CYLLocalizedString.h"
#import <objc/runtime.h>
#import "UIViewController+CYLUtils.h"

@implementation NSObject (CYLUtils)

- (id)cyl_valueForKey:(NSString *)key {
    id value;
    @try {
        value = [self valueForKey:key];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        if (![key isEqualToString:@"imageView"]) {
            NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, KVC failed：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
        }
#endif
    }
    return value;
}

- (void)cyl_setValue:(id)value forKey:(NSString *)key {
    @try {
        [self setValue:value forKey:key];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
}

- (BOOL)cyl_isPlaceholder {
    NSNumber *isPlaceholderObject = objc_getAssociatedObject(self, @selector(cyl_isPlaceholder));
    UIViewController *viewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        viewController = (UIViewController *)self;
    }
    if (viewController && [viewController cyl_getViewControllerInsteadOfNavigationController]) {
        viewController = [viewController cyl_getViewControllerInsteadOfNavigationController];
    }
    if (!viewController || ![self isKindOfClass:[UIViewController class]]) {
        return [isPlaceholderObject boolValue];
    }
    NSNumber *isPlaceholderObjectFromViewControllerInsteadOfNavigationController = objc_getAssociatedObject(viewController, @selector(cyl_isPlaceholder));

    return [isPlaceholderObject boolValue] || [isPlaceholderObjectFromViewControllerInsteadOfNavigationController boolValue];
}

- (void)cyl_setIsPlaceholder:(BOOL)isPlaceholder {
    NSNumber *isPlaceholderObject = @(isPlaceholder);
    objc_setAssociatedObject(self, @selector(cyl_isPlaceholder), isPlaceholderObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    UIViewController *viewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        viewController = (UIViewController *)self;
    }
    if (viewController && [viewController cyl_getViewControllerInsteadOfNavigationController]) {
        viewController = [viewController cyl_getViewControllerInsteadOfNavigationController];
    }
    if (!viewController || ![self isKindOfClass:[UIViewController class]]) {
        return;
    }
    objc_setAssociatedObject([viewController cyl_getViewControllerInsteadOfNavigationController], @selector(cyl_isPlaceholder), isPlaceholderObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
