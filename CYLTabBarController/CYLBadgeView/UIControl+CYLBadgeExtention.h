/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "UIView+CYLBadgeExtention.h"
#import "CYLBadgeProtocol.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] `UIControl (CYLBadgeExtention)` is implemented in Swift, as part of Core (`CYLTabBarController/Swift/UIControl+CYLBadgeExtention.swift`,
 *      docs/Swift-Migration.md, step 22): a tab button's badge goes on its icon and is mirrored to the Liquid Glass platter.
 *      Without Core every control uses `UIView (CYLBadgeExtention)`. Its members are those of `CYLBadgeProtocol`, which
 *      `UIControl` adopts through `UIView` (declaring it again here made every Swift call ambiguous).
 * [CN] `UIControl (CYLBadgeExtention)` 在 Swift 中实现，属于 Core（`CYLTabBarController/Swift/UIControl+CYLBadgeExtention.swift`，
 *      docs/Swift-Migration.md，第 22 步）：Tab 按钮的角标放在图标上并同步到液态玻璃 platter。没有 Core 时所有控件使用
 *      `UIView (CYLBadgeExtention)`。其成员即 `CYLBadgeProtocol` 的成员，`UIControl` 通过 `UIView` 遵守该协议（在这里再次声明会让 Swift
 *      中的每个调用产生歧义）。
 */

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
