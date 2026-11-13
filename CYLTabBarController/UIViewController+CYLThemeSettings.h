//
//  UIViewController+CYLThemeSettings.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 * FIX: issue #216
 * [EN] `UIViewController (CYLThemeSettings)` (the demo's theme picker cell, action sheet, menu and theme list section) is
 *      implemented in Swift (`Swift/UIViewController+CYLThemeSettings.swift`, every selector kept) and declared by the
 *      generated Swift interface (`CYLSwiftInterface.h`), imported below (docs/Swift-Migration.md, step 30).
 * [CN] `UIViewController (CYLThemeSettings)`（演示的主题选择 cell、action sheet、菜单与主题列表分组）在 Swift 中实现
 *      （`Swift/UIViewController+CYLThemeSettings.swift`，所有 selector 不变），由下面导入的 Swift 生成接口（`CYLSwiftInterface.h`）声明
 *      （docs/Swift-Migration.md，第 30 步）。
 */
#import "CYLSwiftInterface.h"
