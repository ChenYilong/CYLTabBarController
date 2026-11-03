//
//  MainTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 15/11/3.
//  Copyright © 2026年 https://github.com/ChenYilong .All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

@interface MainTabBarController : CYLTabBarController

- (instancetype)initWithContext:(NSString *)context;
+ (NSArray *)tabBarItemsAttributesForTabBar;

/*!
 * [EN] The demo's one `UITabBarAppearance`: assigned to `tabBar.standardAppearance` by MainTabBarController (Liquid Glass
 *      and the classic style) and by CYLFlatDesignMainTabBarController (FlatDesign), so a single appearance styles
 *      every tab bar style.
 * [CN] Demo 中唯一的 `UITabBarAppearance`：MainTabBarController（液态玻璃与经典样式）与 CYLFlatDesignMainTabBarController（扁平样式）
 *      都把它赋给 `tabBar.standardAppearance`，一个 appearance 即可设置所有 TabBar 样式。
 */
+ (UITabBarAppearance *)demoStandardAppearanceWithTitlePositionAdjustment:(UIOffset)titlePositionAdjustment API_AVAILABLE(ios(13.0));
@end

/*!
 * #535 demo: a badge on the plus button, like the tabs' badges: a number with a continuous animation. Each tap on the
 * plus button adds 1. Used by MainTabBarController and CYLFlatDesignMainTabBarController.
 * #535 演示：PlusButton 的角标，与其他 Tab 的角标效果一致：带持续动画的数字。每点击一次 PlusButton，数字加 1。
 * MainTabBarController 与 CYLFlatDesignMainTabBarController 共用。
 */
@interface CYLTabBarController (CYLPlusButtonBadgeDemo)

/// Shows the badge on this tab bar controller's plus button. 在当前 TabBarController 的 PlusButton 上显示角标。
- (void)cyl_demo_showPlusButtonBadge;

/// Call from `-tabBarController:didSelectControl:` for the plus button: adds 1 to its badge. 点击 PlusButton 时调用：角标数字加 1。
- (void)cyl_demo_plusButtonDidTap;

@end

/*!
 * #19 demo: tabs that need login. The login screen is an alert (Log in / Cancel) shared by MainTabBarController (block
 * API: `cyl_loginHandler`) and CYLFlatDesignMainTabBarController (delegate API). Toggle the cached login state with the
 * "Login state" row of the settings section.
 * #19 演示：需要登录的 Tab。登录页是一个弹窗（登录 / 取消），MainTabBarController（block 方式：`cyl_loginHandler`）与
 * CYLFlatDesignMainTabBarController（代理方式）共用。通过设置分组中的「登录状态」行切换缓存的登录状态。
 */
@interface CYLTabBarController (CYLLoginDemo)

/// Presents the demo login alert for `viewController`; calls `completion` with YES after "Log in", NO after "Cancel".
/// 为 `viewController` 展示演示登录弹窗；点击「登录」回调 YES，点击「取消」回调 NO。
- (void)cyl_demo_presentLoginForViewController:(UIViewController *)viewController completion:(CYLTabBarLoginCompletion)completion;

@end
