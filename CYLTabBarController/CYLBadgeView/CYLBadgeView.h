//
//  CYLBadgeView.h
//  CYLBadgeView
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * FIX: issue #535
 * [EN] CYLBadgeView: the badge component of CYLTabBarController, usable on its own. Badges (red dot, number, text,
 *      image, custom view) with animations on any `UIView`, `UIControl`, `UIBarButtonItem` and `UITabBarItem`.
 *
 *      CocoaPods, badges only:
 *
 *          pod 'CYLTabBarController/CYLBadgeView'
 *
 *          #import <CYLTabBarController/CYLBadgeView.h>      // Objective-C
 *          import CYLTabBarController                         // Swift
 *
 *      CYLTabBarController's Core depends on it, so every other subspec, SPM and Carthage include it already, and
 *      `#import <CYLTabBarController/CYLTabBarController.h>` imports it too.
 *
 * [CN] CYLBadgeView：CYLTabBarController 的角标组件，可以单独使用。为任意 `UIView`、`UIControl`、`UIBarButtonItem`、
 *      `UITabBarItem` 添加带动画的角标（红点、数字、文字、图片、自定义视图）。
 *
 *      CocoaPods 只引入角标：
 *
 *          pod 'CYLTabBarController/CYLBadgeView'
 *
 *          #import <CYLTabBarController/CYLBadgeView.h>      // Objective-C
 *          import CYLTabBarController                         // Swift
 *
 *      CYLTabBarController 的 Core 依赖它，因此其他所有 subspec、SPM、Carthage 都已包含，
 *      `#import <CYLTabBarController/CYLTabBarController.h>` 也会一并导入。
 */

#import <UIKit/UIKit.h>
// FIX: issue #535 — shared with Core through CYLUtils. 通过 CYLUtils 与 Core 共用。
#if __has_include("../CYLUtils/CYLUtils.h")
#import "../CYLUtils/CYLUtils.h"
#else
#import "CYLUtils.h"
#endif
#import "CYLBadgeProtocol.h"
#import "CYLBadgeAppearance.h"
#import "CAAnimation+CYLBadgeExtention.h"
#import "CYLTabBarBadgeView.h"
#import "UIView+CYLBadgeExtention.h"
#import "UIControl+CYLBadgeExtention.h"
#import "UIBarButtonItem+CYLBadgeExtention.h"
#import "UITabBarItem+CYLBadgeExtention.h"
