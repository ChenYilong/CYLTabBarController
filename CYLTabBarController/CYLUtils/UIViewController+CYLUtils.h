//
//  UIViewController+CYLUtils.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * FIX: issue #535
 * [EN] Moved from `UIViewController+CYLTabBarControllerExtention.h` (Core), which imports this header.
 * [CN] 从 Core 的 `UIViewController+CYLTabBarControllerExtention.h` 移入，该头文件会导入本文件。
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Implemented in Swift (`Swift/UIViewController+CYLUtils.swift`); declared here for Objective-C callers only, and
 *      hidden from Swift (`__swift__`), which uses the Swift extension itself (docs/Swift-Migration.md).
 * [CN] 在 Swift 中实现（`Swift/UIViewController+CYLUtils.swift`）；这里只为 Objective-C 调用方声明，并对 Swift 隐藏（`__swift__`），
 *      Swift 直接使用该 Swift 扩展（docs/Swift-Migration.md）。
 */
#ifndef __swift__
@interface UIViewController (CYLUtils)

/*!
 * [EN] Returns the first view controller of a navigation controller, or the receiver itself if it is not one.
 * [CN] 若自身是导航控制器则返回其第一个子控制器，否则返回自身。
 */
- (UIViewController *)cyl_getViewControllerInsteadOfNavigationController;

@end
#endif

NS_ASSUME_NONNULL_END
