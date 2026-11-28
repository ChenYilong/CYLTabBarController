/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "CYLTabBar.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] `UITabBar (CYLTabBarControllerExtention)` is public Swift since docs/Swift-Migration.md step 119
 *      (`Swift/CYLTabBar+CYLTabBarControllerExtention.swift`, same selectors and Swift names; `-cyl_contentView` is the one of
 *      `UIView`); Objective-C reads it from the generated Swift interface.
 * [CN] 自第 119 步起 `UITabBar (CYLTabBarControllerExtention)` 为公开的 Swift（selector 与 Swift 名称不变；`-cyl_contentView` 为 `UIView` 的方法）；
 *      Objective-C 通过生成的 Swift 接口读取。
 */

/*!
 * [EN] The `CYLTabBar (CYLTabBarControllerExtention)` members (`cyl_selectedControl`, `-cyl_selectedIndex`, `-cyl_visibleControls`,
 *      `-cyl_subTabBarButtons`, `-cyl_tabBarButtonWithTabIndex:` and the others) are implemented in Swift
 *      (`Swift/CYLTabBar+CYLTabBarControllerExtention.swift`); since `CYLTabBar` itself is Swift (step 100), Objective-C callers get
 *      them from the generated Swift interface (imported by `CYLTabBar.h`), as a category of a Swift class cannot be declared here.
 * [CN] `CYLTabBar (CYLTabBarControllerExtention)` 的成员在 Swift 中实现（`Swift/CYLTabBar+CYLTabBarControllerExtention.swift`）；由于 `CYLTabBar`
 *      本身已是 Swift（第 100 步），Objective-C 调用方从生成的 Swift 接口（由 `CYLTabBar.h` 导入）获得它们，因为这里不能为 Swift 类声明类别。
 */

NS_ASSUME_NONNULL_END

#import "CYLTabBarControllerSwiftInterface.h"
