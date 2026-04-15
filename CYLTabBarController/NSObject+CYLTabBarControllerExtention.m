//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "NSObject+CYLTabBarControllerExtention.h"
#import <objc/runtime.h>
#import "CYLConstants.h"

@implementation NSString (CYLTabBarControllerExtention)

- (NSString *)cyl_trim {
    NSMutableCharacterSet * characterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [characterSet addCharactersInString:@"\0"];
    return [self stringByTrimmingCharactersInSet:characterSet];
}

@end

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

static UIInterfaceOrientationMask CYLMaskFromOrientation(UIInterfaceOrientation orientation) {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return UIInterfaceOrientationMaskPortrait;
        case UIInterfaceOrientationPortraitUpsideDown:
            return UIInterfaceOrientationMaskPortraitUpsideDown;
        case UIInterfaceOrientationLandscapeLeft:
            return UIInterfaceOrientationMaskLandscapeLeft;
        case UIInterfaceOrientationLandscapeRight:
            return UIInterfaceOrientationMaskLandscapeRight;
        default:
            return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)cyl_forceUpdateInterfaceOrientation:(UIInterfaceOrientation)orientation {
    UIResponder<UIApplicationDelegate> *appDelegate = [self cyl_sharedAppDelegate];
    BOOL isForceLandscape = (UIInterfaceOrientationLandscapeLeft == orientation) || (UIInterfaceOrientationLandscapeRight == orientation);
    appDelegate.cyl_isForceLandscape = isForceLandscape;
    if ([appDelegate respondsToSelector:@selector(application:supportedInterfaceOrientationsForWindow:)]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         [appDelegate application:[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:CYLGetRootWindow()];
         
         );
    }
    
    if (@available(iOS 16.0, *)) {
        
        UIWindowScene *windowScene = CYLGetWindowScene();
        if (windowScene) {
            
            UIViewController *rootVC = windowScene.keyWindow.rootViewController;
            UIViewController *topVC = rootVC;
            while (topVC.presentedViewController) {
                topVC = topVC.presentedViewController;
            }
            
            if (!topVC) { return; }
            
            // ✅ 将 (UIInterfaceOrientation)orientation 转换为 Mask
            
            
            UIInterfaceOrientationMask targetMask = CYLMaskFromOrientation(orientation);
            
            UIInterfaceOrientationMask supportedMask =
            [topVC supportedInterfaceOrientations];
            
            //如果不支持则强制 fallback
            if (!(supportedMask & targetMask)) {
                targetMask = supportedMask;
            }
            
            [topVC setNeedsUpdateOfSupportedInterfaceOrientations];
            
            UIWindowSceneGeometryPreferencesIOS *preferences =
            [[UIWindowSceneGeometryPreferencesIOS alloc]
             initWithInterfaceOrientations:targetMask];
            
            [windowScene requestGeometryUpdateWithPreferences:preferences
                                                 errorHandler:^(NSError * _Nonnull error) {
            }];
        }
    } else if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        NSNumber *num = [[NSNumber alloc] initWithInt:UIInterfaceOrientationPortrait];
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         [[UIDevice currentDevice] performSelector:@selector(setOrientation:) withObject:(id)num];
         );
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

+ (UIViewController * __nullable)cyl_topmostViewController {
    UIViewController *topViewController = [CYLGetRootWindow() rootViewController];
    
    if (topViewController == nil) {
        return nil;
    }
    
    while (true) {
        if (topViewController.presentedViewController != nil) {
            topViewController = topViewController.presentedViewController;
        } else if ([topViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navi = (UINavigationController *)topViewController;
            topViewController = navi.topViewController;
        } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *)topViewController;
            topViewController = tab.selectedViewController;
        } else {
            break;
        }
    }
    
    return topViewController;
}

+ (UINavigationController * __nullable)cyl_currentNavigationController {
    return [[UIViewController cyl_topmostViewController] navigationController];
}

+ (void)cyl_dismissAll:(void (^ __nullable)(void))completion {
    UIViewController *topViewController = CYLGetRootViewController();
    
    if (topViewController == nil) {
        !completion ?: completion();
        return;
    }
    
    NSMutableArray *list = [NSMutableArray new];
    
    while (true) {
        if (topViewController.presentedViewController != nil) {
            topViewController = topViewController.presentedViewController;
            [list addObject:topViewController];
        } else if ([topViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navi = (UINavigationController *)topViewController;
            topViewController = navi.topViewController;
        } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *)topViewController;
            topViewController = tab.selectedViewController;
        } else {
            break;
        }
    }
    
    if (list.count == 0) {
        if (completion) {
            completion();
        }
        return;
    }
    
    for (NSInteger i = list.count - 1; i >=0 ; i--) {
        
        UIViewController *vc = list[i];
        if (i == 0) {
            if ([vc isKindOfClass:[UINavigationController class]]) {
                [(UINavigationController *)vc popToRootViewControllerAnimated:NO];
            }
            [vc dismissViewControllerAnimated:NO completion:completion];
        } else {
            if ([vc isKindOfClass:[UINavigationController class]]) {
                [(UINavigationController *)vc popToRootViewControllerAnimated:NO];
            }
            [vc dismissViewControllerAnimated:NO completion:nil];
        }
    }
}

- (id)cyl_valueForKey:(NSString *)key {
    id value;
    @try {
        value = [self valueForKey:key];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
#endif
    }
    return value;
}

- (void)cyl_setValue:(id)value forKey:(NSString *)key {
    @try {
        [self setValue:value forKey:key];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
}

- (NSString *)cyl_methodList {
    NSString *methodList;
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     methodList = [self performSelector:NSSelectorFromString(@"_methodDescription")];
     
     );
    return methodList;
}

- (NSString *)cyl_shortMethodList {
    NSString *shortMethodList;
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     shortMethodList = [self performSelector:NSSelectorFromString(@"_shortMethodDescription")];
     );
    return shortMethodList;
}

- (NSString *)cyl_ivarList {
    NSString *systemResult;
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
                                            systemResult = [self performSelector:NSSelectorFromString(@"_ivarDescription")];
                                            
     );
    NSRegularExpression *regx = [NSRegularExpression regularExpressionWithPattern:@"^(\\s+)(\\S+)" options:NSRegularExpressionCaseInsensitive error:nil];
    NSMutableArray<NSString *> *lines = [systemResult componentsSeparatedByString:@"\n"].mutableCopy;
    [lines enumerateObjectsUsingBlock:^(NSString *line, NSUInteger idx, BOOL * _Nonnull stop) {
        
        // 过滤掉空行或者 struct 结尾的"}"
        if (line.cyl_trim.length <= 2) return;
        
        // 有些 struct 类型的变量，会把 struct 的成员也缩进打出来，所以用这种方式过滤掉
        if ([line hasPrefix:@"\t\t"]) return;
        
        NSTextCheckingResult *regxResult = [regx firstMatchInString:line options:NSMatchingReportCompletion range:NSMakeRange(0, line.length)];
        if (regxResult.numberOfRanges < 3) return;
        
        NSRange indentRange = [regxResult rangeAtIndex:1];
        NSRange offsetRange = NSMakeRange(NSMaxRange(indentRange), 0);
        NSRange ivarNameRange = [regxResult rangeAtIndex:2];
        NSString *ivarName = [line substringWithRange:ivarNameRange];
        Ivar ivar = class_getInstanceVariable(self.class, ivarName.UTF8String);
        ptrdiff_t ivarOffset = ivar_getOffset(ivar);
        NSString *lineWithOffset = [line stringByReplacingCharactersInRange:offsetRange withString:[NSString stringWithFormat:@"[%@|0x%@]", @(ivarOffset), [NSString stringWithFormat:@"%lx", (NSInteger)ivarOffset].uppercaseString]];
        [lines setObject:lineWithOffset atIndexedSubscript:idx];
    }];
    NSString *result = [lines componentsJoinedByString:@"\n"];
    return result;
}

- (NSString *)cyl_viewInfo {
    if ([self isKindOfClass:UIView.class]) {
        NSString *viewInfo;
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         viewInfo = [self performSelector:NSSelectorFromString(@"recursiveDescription")];
         
         );
        return viewInfo;
    }
    return @"Sorry, only support UIView";
}

- (BOOL)cyl_isContinuousGestureRecognizer {
    NSString *gestureRecognizerClassString = NSStringFromClass([self class]);
    if ([gestureRecognizerClassString hasPrefix:(@"_UIContinuous")] && [gestureRecognizerClassString hasSuffix:@"tionGestureRecognizer"]) {
        return YES;
    }
    return NO;
}

- (BOOL)cyl_isLongGestureRecognizer {
    NSString *gestureRecognizerClassString = NSStringFromClass([self class]);
    if ([gestureRecognizerClassString hasPrefix:(@"UILongPr")] && [gestureRecognizerClassString hasSuffix:@"essGestureRecognizer"]) {
        return YES;
    }
    return NO;
}

@end



