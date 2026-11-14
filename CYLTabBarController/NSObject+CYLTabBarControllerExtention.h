//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
// [CN] FIX: issue #535 — shared with CYLBadgeView through CYLUtils. 通过 CYLUtils 与 CYLBadgeView 共用。
// [EN] FIX: issue #535 — shared with CYLBadgeView through CYLUtils.
#if __has_include("CYLUtils/NSObject+CYLUtils.h")
#import "CYLUtils/NSObject+CYLUtils.h"
#else
#import "NSObject+CYLUtils.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] The rest of `NSObject (CYLTabBarControllerExtention)` is implemented in Swift (`Swift/NSObject+CYLTabBarControllerExtention.swift`)
 *      and declared by the generated Swift interface imported at the end of this header. These two methods stay Objective-C:
 *      they catch an Objective-C exception, which Swift cannot (docs/Swift-Migration.md).
 * [CN] `NSObject (CYLTabBarControllerExtention)` 的其他部分在 Swift 中实现（`Swift/NSObject+CYLTabBarControllerExtention.swift`），由本头文件末尾
 *      导入的 Swift 生成接口声明。这两个方法保留为 Objective-C：它们需要捕获 Objective-C 异常，而 Swift 做不到（docs/Swift-Migration.md）。
 */
@interface NSObject (CYLTabBarControllerExtentionKVOSafety)

/*!
 * [EN] `-removeObserver:forKeyPath:` that logs (DEBUG) instead of raising when `observer` is not registered.
 * [CN] 观察者未注册时只打印日志（DEBUG）而不抛出异常的 `-removeObserver:forKeyPath:`。
 */
- (void)cyl_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

/*!
 * [EN] `-removeObserver:forKeyPath:context:` that logs (DEBUG) instead of raising when `observer` is not registered.
 * [CN] 观察者未注册时只打印日志（DEBUG）而不抛出异常的 `-removeObserver:forKeyPath:context:`。
 */
- (void)cyl_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context;

@end

/*!
 * [EN] Runs `block` and returns the Objective-C exception it raises, or nil. For the library's Swift code, which cannot
 *      catch Objective-C exceptions (e.g. around a page provider written by the app). Internal.
 * [CN] 执行 `block` 并返回它抛出的 Objective-C 异常，没有则为 nil。供本库的 Swift 代码使用（Swift 无法捕获 Objective-C 异常，例如调用
 *      App 编写的页面提供者时）。内部使用。
 */
FOUNDATION_EXTERN NSException *_Nullable CYLCatchException(NS_NOESCAPE void (^block)(void));

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
