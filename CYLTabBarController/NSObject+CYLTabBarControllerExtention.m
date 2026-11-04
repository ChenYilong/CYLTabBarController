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
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

@implementation NSString (CYLTabBarControllerExtention)

- (NSString *)cyl_trim {
    NSMutableCharacterSet * characterSet = [NSMutableCharacterSet whitespaceAndNewlineCharacterSet];
    [characterSet addCharactersInString:@"\0"];
    return [self stringByTrimmingCharactersInSet:characterSet];
}

@end

@implementation NSObject (CYLTabBarControllerExtention)

- (NSString *)cyl_context {
    NSString *context = objc_getAssociatedObject(self, @selector(cyl_context));
    if (!context) {
        return NSStringFromClass([CYLTabBarController class]);
    }
    return context;
}

- (void)cyl_setContext:(NSString *)context {
    NSString *context_ = context;
    if (context && context.length > 0) {
        context_ = [context copy];
    } else {
        context_ = NSStringFromClass([CYLTabBarController class]);
    }
    objc_setAssociatedObject(self, @selector(cyl_context), context_, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

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
            
            // [CN] ✅ 将 (UIInterfaceOrientation)orientation 转换为 Mask
            // [EN] ✅ Convert (UIInterfaceOrientation)orientation to a Mask
            
            
            UIInterfaceOrientationMask targetMask = CYLMaskFromOrientation(orientation);
            
            UIInterfaceOrientationMask supportedMask =
            [topVC supportedInterfaceOrientations];
            
            // [CN] 如果不支持则强制 fallback
            // [EN] If not supported, force a fallback
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

/*!
 * [EN] The walk shared by `+cyl_topmostViewController` and `+cyl_currentNavigationController`: from `viewController`,
 *      follow presented controllers, the top of each navigation controller and the selected tab of each tab bar
 *      controller.
 *      FIX: issue #283 — with `forNavigation` YES (`+cyl_currentNavigationController`), an alert (`UIAlertController`)
 *      or a controller that is being dismissed does not count as presented: it has no navigation controller, so a push
 *      "from anywhere" (a notification, a network callback) found none while an alert was on screen. An empty
 *      navigation or tab bar controller is returned itself instead of nil. With NO, the walk is the one
 *      `+cyl_topmostViewController` always did.
 * [CN] `+cyl_topmostViewController` 与 `+cyl_currentNavigationController` 共用的查找：从 `viewController` 开始，沿 present 出来的
 *      控制器、导航控制器的栈顶、TabBarController 选中的 Tab 一路查找。
 *      FIX: issue #283 — `forNavigation` 为 YES 时（`+cyl_currentNavigationController`），弹窗（`UIAlertController`）或正在 dismiss
 *      的控制器不算作 present 出来的页面：它们没有导航控制器，屏幕上有弹窗时，“随时 push”（收到通知、网络回调）会找不到导航控制器。
 *      空的导航控制器或 TabBarController 返回其自身而不是 nil。为 NO 时与 `+cyl_topmostViewController` 原有的查找完全相同。
 */
static UIViewController *CYLTopmostViewController(UIViewController *viewController, BOOL forNavigation) {
    UIViewController *topViewController = viewController;
    while (topViewController) {
        UIViewController *presentedViewController = topViewController.presentedViewController;
        if (presentedViewController && !(forNavigation && ([presentedViewController isKindOfClass:[UIAlertController class]] ||
                                                           presentedViewController.isBeingDismissed))) {
            topViewController = presentedViewController;
            continue;
        }
        UIViewController *childViewController = nil;
        if ([topViewController isKindOfClass:[UINavigationController class]]) {
            childViewController = ((UINavigationController *)topViewController).topViewController;
        } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
            childViewController = ((UITabBarController *)topViewController).selectedViewController;
        } else {
            break;
        }
        if (!childViewController && forNavigation) {
            break;
        }
        topViewController = childViewController;
    }
    return topViewController;
}

+ (UIViewController * __nullable)cyl_topmostViewController {
    return CYLTopmostViewController([CYLGetRootWindow() rootViewController], NO);
}

+ (UINavigationController * __nullable)cyl_currentNavigationController {
    UIViewController *topViewController = CYLTopmostViewController([CYLGetRootWindow() rootViewController], YES);
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)topViewController;
    }
    return topViewController.navigationController;
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
        
        // [CN] 过滤掉空行或者 struct 结尾的"}"
        // [EN] Filter out empty lines and the closing "}" of structs
        if (line.cyl_trim.length <= 2) return;
        
        // [CN] 有些 struct 类型的变量，会把 struct 的成员也缩进打出来，所以用这种方式过滤掉
        // [EN] Some struct variables also print their members indented, so filter them out this way
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

- (BOOL)cyl_isPlusViewControllerAdded:(nullable NSArray *)viewControllers {
    if ([viewControllers containsObject:[CYLPlusButton plusChildViewControllerForOwner:self]]) {
        return YES;
    }
    __block BOOL isAdded = NO;
    [viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj cyl_isEqualToViewController:[CYLPlusButton plusChildViewControllerForOwner:self]]) {
            isAdded = YES;
            *stop = YES;
            return;
        }
    }];
    return isAdded;
}

- (void)cyl_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    @try {
        [self removeObserver:observer forKeyPath:keyPath];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
}

- (void)cyl_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context {
    @try {
        [self removeObserver:observer forKeyPath:keyPath context:context];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
}

@end

