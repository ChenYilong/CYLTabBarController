//
//  UIBarItem+CYLUtils.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * FIX: issue #535
 * [EN] The view UIKit draws for a bar item. `-cyl_view` was implemented twice, for `UITabBarItem` (Core) and `UIBarButtonItem` (CYLBadgeView); it is now one method on their superclass. `cyl_tabButton` comes from `UITabBarItem+CYLTabBarControllerExtention.h`, which imports this header.
 * [CN] UIKit 为 bar item 绘制的视图。`-cyl_view` 原先在 `UITabBarItem`（Core）和 `UIBarButtonItem`（CYLBadgeView）各实现了一次，现在合并为父类上的一个方法。`cyl_tabButton` 来自 `UITabBarItem+CYLTabBarControllerExtention.h`，该头文件会导入本文件。
 */

#import <UIKit/UIKit.h>
#import "CYLSwiftInterface.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Implemented in Swift (`CYLUtils/Swift/UIBarItem+CYLUtils.swift`). Objective-C callers get its declarations, with their
 *      documentation, from the generated Swift interface imported above (`CYLSwiftInterface.h`); nothing is declared twice
 *      (docs/Swift-Migration.md).
 * [CN] 在 Swift 中实现（`CYLUtils/Swift/UIBarItem+CYLUtils.swift`）。Objective-C 调用方从上面导入的 Swift 生成接口（`CYLSwiftInterface.h`）获得
 *      声明及其文档；不重复声明（docs/Swift-Migration.md）。
 */

NS_ASSUME_NONNULL_END
