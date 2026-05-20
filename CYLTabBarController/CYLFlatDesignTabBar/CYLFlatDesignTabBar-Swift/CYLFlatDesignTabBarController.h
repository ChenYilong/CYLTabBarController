//
//  CYLFlatDesignTabBarController.h
//  CYLFlatDesignTabBarController
//
//  Created by apple on 2026/2/6.
//

#import <UIKit/UIKit.h>
#import "CYLFlatDesignTabBar.h"

NS_ASSUME_NONNULL_BEGIN

/**
 继承自 UITabBarController
 永久隐藏系统的 UITabBar，使用 CYLFlatDesignTabBar
 优点：支持系统 UITabBarController 大部分属性
 */

@class CYLFlatDesignTabBarController;

@protocol CYLFlatDesignTabBarControllerDelegate <UITabBarControllerDelegate>

@optional

// tabBar show/hide
- (void)tabBarController:(CYLFlatDesignTabBarController *)tabBarController willShowTabBar:(CYLFlatDesignTabBar *)tabBar;
- (void)tabBarController:(CYLFlatDesignTabBarController *)tabBarController didShowTabBar:(CYLFlatDesignTabBar *)tabBar;
- (void)tabBarController:(CYLFlatDesignTabBarController *)tabBarController willHideTabBar:(CYLFlatDesignTabBar *)tabBar;
- (void)tabBarController:(CYLFlatDesignTabBarController *)tabBarController didHideTabBar:(CYLFlatDesignTabBar *)tabBar;

@end

@interface CYLFlatDesignTabBarController : UITabBarController<CYLFlatDesignTabBarDelegate>

// 代理
@property (nonatomic, weak, nullable) id<CYLFlatDesignTabBarControllerDelegate> delegate;

/**
 设置CYLFlatDesignTabBar显示或隐藏
 如果设置了 hidesBottomBarWhenPushed，则 hidesBottomBarWhenPushed 优先级更高
 系统的 tabBarHidden 和 hidesBottomBarWhenPushed 也是乱七八糟，不知道什么原理
 */
@property (nonatomic, assign, getter=isTabBarHidden) BOOL tabBarHidden;
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated;

@property (nonatomic, readonly) CYLFlatDesignTabBar *cyl_tabBar;

// tabBar内容高度，默认49.0，真实高度会加上view.safeAreaInsets.bottom安全区域
@property (nonatomic, assign) CGFloat tabBarHeight;

@end

@interface UIViewController (CYLFlatDesignTabBarControllerItem)

// 如果未显式设置，则根据视图控制器的标题自动延迟创建
@property (null_resettable, nonatomic, strong, getter=cyl_tabBarItem, setter=cyl_setTabBarItem:) CYLFlatDesignTabBarItem *cyl_tabBarItem;

@end

NS_ASSUME_NONNULL_END
