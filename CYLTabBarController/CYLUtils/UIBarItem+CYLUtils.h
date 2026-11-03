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

NS_ASSUME_NONNULL_BEGIN

@interface UIBarItem (CYLUtils)

/*!
 * [EN] The view UIKit draws for the item (`UIBarButtonItem` and `UITabBarItem` only; `UIBarItem` itself has none).
 *      Since iOS 11 it exists only once the item is on screen, so it can be nil before that.
 * [CN] UIKit 为该 item 绘制的视图（仅 `UIBarButtonItem`、`UITabBarItem` 有，`UIBarItem` 本身没有）。iOS 11 起，item 显示后才会创建，
 *      之前可能为 nil。
 */
- (nullable UIView *)cyl_view;

@end

@interface UITabBarItem (CYLUtils)

/*!
 * [EN] The button UIKit draws for the item in its tab bar (`UITabBarButton` / `_UITabButton`).
 * [CN] UIKit 在 TabBar 中为该 item 绘制的按钮（`UITabBarButton` / `_UITabButton`）。
 */
@property (nonatomic, readonly) UIControl *cyl_tabButton;

@end

NS_ASSUME_NONNULL_END
