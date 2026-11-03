//
//  AppDelegate.h
//  WYWTabBar
//
//  Created by weiyanwu on 2026/4/17.
//

#import <UIKit/UIKit.h>

#import <CYLTabBarController/CYLTabBarController.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;

/// Shows the tabs with `styleType` (Liquid Glass or FlatDesign), then loads their icons from the network: the in-place
/// updates work in every style. 以 `styleType`（液态玻璃或扁平样式）显示 Tab，再从网络加载图标：原地更新适用于所有样式。
- (void)showTabBarControllerWithStyle:(CYLTabBarStyleType)styleType;
@end
