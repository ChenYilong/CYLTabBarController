//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import "NSObject+CYLTabBarControllerExtention.h"
#import <objc/runtime.h>

@implementation NSObject (CYLTabBarControllerExtention)

- (BOOL)cyl_isForceLandscape {
    NSNumber *isForceLandscapeObject = objc_getAssociatedObject(self, @selector(cyl_isForceLandscape));
    return [isForceLandscapeObject boolValue];
}

- (void)cyl_setIsForceLandscape:(BOOL)isForceLandscape {
    NSNumber *isForceLandscapeObject = @(isForceLandscape);
    objc_setAssociatedObject(self, @selector(cyl_isForceLandscape), isForceLandscapeObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIResponder<UIApplicationDelegate> *)cyl_sharedAppDelegate {
     id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
    return (UIResponder<UIApplicationDelegate> *)appDelegate;
}

- (void)cyl_forceUpdateInterfaceOrientation:(UIInterfaceOrientation)orientation {
    UIResponder<UIApplicationDelegate> *appDelegate = [self cyl_sharedAppDelegate];
    BOOL isForceLandscape = (UIInterfaceOrientationLandscapeLeft == orientation) || (UIInterfaceOrientationLandscapeRight == orientation);
    appDelegate.cyl_isForceLandscape = isForceLandscape;
    if ([appDelegate respondsToSelector:@selector(application:supportedInterfaceOrientationsForWindow:)]) {
        [appDelegate application:[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:UIApplication.sharedApplication.keyWindow];
    }
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        NSNumber *num = [[NSNumber alloc]initWithInt:UIInterfaceOrientationPortrait];
        [[UIDevice currentDevice] performSelector:@selector(setOrientation:)withObject:(id)num];
        [UIViewController attemptRotationToDeviceOrientation];
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val  = [@(orientation) intValue];
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

/*cyl_valueForKey 方法来源于QMUIKit的处理方式，感谢提供开源方案。*/
#define _CYLTypeEncodingDetectorGenerator(_TypeInFunctionName, _typeForEncode) \
CG_INLINE BOOL is##_TypeInFunctionName##TypeEncoding(const char *typeEncoding) {\
return strncmp(@encode(_typeForEncode), typeEncoding, strlen(@encode(_typeForEncode))) == 0;\
}\
CG_INLINE BOOL is##_TypeInFunctionName##Ivar(Ivar ivar) {\
return is##_TypeInFunctionName##TypeEncoding(ivar_getTypeEncoding(ivar));\
}
_CYLTypeEncodingDetectorGenerator(Object, id)

- (id)cyl_valueForKey:(NSString *)key {
    NSString * (^capString)(NSString *) = ^NSString *(NSString *string) {
        return [NSString stringWithFormat:@"%@%@", [string substringToIndex:1].uppercaseString, [string substringFromIndex:1]];
    };
    
    key = [key hasPrefix:@"_"] ? [key substringFromIndex:1] : key;
    Ivar ivar = class_getInstanceVariable(object_getClass(self), [NSString stringWithFormat:@"_%@", key].UTF8String);
    if (!ivar) ivar = class_getInstanceVariable(object_getClass(self), [NSString stringWithFormat:@"_is%@", capString(key)].UTF8String);
    if (!ivar) ivar = class_getInstanceVariable(object_getClass(self), key.UTF8String);
    if (!ivar) ivar = class_getInstanceVariable(object_getClass(self), [NSString stringWithFormat:@"is%@", capString(key)].UTF8String);
    
    if (ivar) {
        if (isObjectIvar(ivar)) {
            return object_getIvar(self, ivar);
        }
        ptrdiff_t ivarOffset = ivar_getOffset(ivar);
        unsigned char * bytes = (unsigned char *)(__bridge void *)self;
        NSValue *value = @(*(bytes + ivarOffset));
        return value;
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"get%@", capString(key)]);
        if ([self respondsToSelector:selector]) return [self performSelector:selector];
        selector = NSSelectorFromString(key);
        if ([self respondsToSelector:selector]) return [self performSelector:selector];
        selector = NSSelectorFromString([NSString stringWithFormat:@"is%@", capString(key)]);
        if ([self respondsToSelector:selector]) return [self performSelector:selector];
        selector = NSSelectorFromString([NSString stringWithFormat:@"_%@", key]);// 这一步是额外加的，系统的 valueForKey: 没有
        if ([self respondsToSelector:selector]) return [self performSelector:selector];
#pragma clang diagnostic pop
    }
    NSAssert(ivar, @"%@ 不存在名为 %@ 的 selector", NSStringFromClass(self.class), key);
    return nil;
}

@end
