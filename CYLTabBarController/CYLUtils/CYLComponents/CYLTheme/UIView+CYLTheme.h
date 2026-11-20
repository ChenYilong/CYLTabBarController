//
//  UIView+CYLTheme.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/04/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Implemented in Swift (`CYLUtils/Swift/UIView+CYLTheme.swift`); declared here for Objective-C callers only and hidden from
 *      Swift (`__swift__`), which uses the Swift declarations (docs/Swift-Migration.md).
 * [CN] 在 Swift 中实现（`CYLUtils/Swift/UIView+CYLTheme.swift`）；这里只为 Objective-C 调用方声明，并对 Swift 隐藏（`__swift__`），Swift 直接使用
 *      Swift 声明（docs/Swift-Migration.md）。
 */
#ifndef __swift__


/*!
 * FIX: issue #216
 * [EN] How a view follows the theme. When the theme of a `CYLThemeManager` changes, every view of the visible windows
 *      (hidden ones included, so they are right when shown) gets `-cyl_themeDidChangeByManager:identifier:theme:`. No
 *      UIKit method is swizzled: a view added to a window later reads its theme colors when it is drawn, as any
 *      dynamic color. Also done for every view, without registering anything:
 *      - labels and text views redraw (their text colors follow);
 *      - `UITabBar`, `UINavigationBar` and `UIToolbar` assign their appearances again, so the theme colors in them
 *        follow (for a tab bar of `CYLTabBarController`, prefer the `CYLTabBarTheme` protocol, see
 *        `CYLTabBarController.h`).
 * [CN] 视图如何跟随主题。`CYLThemeManager` 的主题切换时，可见 window 上的所有视图（包括隐藏的视图，显示时即为正确样式）都会收到
 *      `-cyl_themeDidChangeByManager:identifier:theme:`。不会 hook 任何 UIKit 方法：之后才加入 window 的视图在绘制时读取主题颜色，
 *      与其他动态颜色相同。无需注册，所有视图都会：
 *      - UILabel 与 UITextView 重新绘制（文字颜色随之更新）；
 *      - `UITabBar`、`UINavigationBar`、`UIToolbar` 重新设置各自的 appearance，使其中的主题颜色随之更新（`CYLTabBarController`
 *        的 TabBar 推荐使用 `CYLTabBarTheme` 协议，见 `CYLTabBarController.h`）。
 */


#endif

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
