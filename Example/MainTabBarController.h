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
