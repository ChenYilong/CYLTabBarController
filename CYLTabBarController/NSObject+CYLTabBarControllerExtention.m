//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// CYL-SWIFT-MIGRATION: objc-required — [EN] Swift cannot catch Objective-C exceptions, and these two methods and `CYLCatchException()` exist to
//      catch one, e.g. the one `-removeObserver:forKeyPath:` raises for an observer that is not registered. Everything else of this
//      category is Swift (`Swift/NSObject+CYLTabBarControllerExtention.swift`, docs/Swift-Migration.md).
//      [CN] Swift 无法捕获 Objective-C 异常，而这两个方法正是为了捕获 `-removeObserver:forKeyPath:` 在观察者未注册时抛出的异常。
//      该类别的其他部分均为 Swift（`Swift/NSObject+CYLTabBarControllerExtention.swift`，docs/Swift-Migration.md）。
#import "NSObject+CYLTabBarControllerExtention.h"
#import "CYLConstants.h"

@implementation NSObject (CYLTabBarControllerExtentionKVOSafety)

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

NSException *_Nullable CYLCatchException(NS_NOESCAPE void (^block)(void)) {
    @try {
        block();
    } @catch (NSException *exception) {
        return exception;
    }
    return nil;
}
