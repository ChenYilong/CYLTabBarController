//
//  CYLMainRootViewController.h
//  CYLTabBarController
//
//  Created by chenyilong on 7/3/2026.
//  Copyright © 2026 微博@iOS程序犭袁. All rights reserved.
//
#import <UIKit/UIKit.h>

#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif
@class CYLFlatDesignMainTabBarController;
@class MainTabBarController;

NS_ASSUME_NONNULL_BEGIN

@interface CYLMainRootViewController : UINavigationController

- (CYLTabBarController *)createLiquidGlassTabBar;
- (CYLTabBarController *)createNewTabBarWithContext:(NSString *)context;
- (CYLFlatDesignMainTabBarController *)createFlatDesignTabBar;

/*!
 * [EN] Replace the tab bar controller by one that shows the plus button of `plusButtonClass` (a `CYLPlusButtonSubclass`
 *      or `CYLSecondPlusButtonSubclass`): its context is that plus button's context. Used by the plus button's
 *      "Switch Style" menu, which switches to the OTHER plus button.
 * [CN] 将当前 TabBarController 替换为显示 `plusButtonClass`（`CYLPlusButtonSubclass` 或 `CYLSecondPlusButtonSubclass`）的 PlusButton 的
 *      TabBarController：它的 context 就是该 PlusButton 的 context。PlusButton 的“切换样式”菜单使用它，并切换到 **另一个** PlusButton。
 */
- (CYLTabBarController *)createLiquidGlassTabBarWithPlusButtonClass:(Class)plusButtonClass;
- (CYLFlatDesignMainTabBarController *)createFlatDesignTabBarWithPlusButtonClass:(Class)plusButtonClass;

/*!
 * [EN] The same, but only creates the tab bar controller, to be pushed from a page (for example a table cell). The
 *      plus button is registered for its own context, and stays registered next to the one of the tab bar
 *      controller you push from. A plus button class serves one tab bar controller at a time: pushing a third level
 *      with a plus button class that is still in use needs another plus button class (another context).
 * [CN] 同上，但只创建 TabBarController，用于从页面（例如 table cell）push。PlusButton 按它自己的 context 注册，并与当前 TabBarController
 *      的 PlusButton 同时保持注册。一个 PlusButton 类同一时间只服务于一个 TabBarController：push 到第三层且使用仍在使用中的 PlusButton 类时，需要另一个 PlusButton 类（另一个 context）。
 */
+ (MainTabBarController *)newLiquidGlassTabBarControllerWithPlusButtonClass:(Class)plusButtonClass;
+ (CYLFlatDesignMainTabBarController *)newFlatDesignTabBarControllerWithPlusButtonClass:(Class)plusButtonClass;

@end

NS_ASSUME_NONNULL_END
