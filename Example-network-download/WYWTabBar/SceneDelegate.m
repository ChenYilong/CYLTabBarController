//
//  SceneDelegate.m
//  WYWTabBar
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "SceneDelegate.h"
#import "CYLTabBarController.h"
#import "HomeViewController.h"
#import "WealthViewController.h"
#import "TradeViewController.h"
#import "InfoViewController.h"
#import "MineViewController.h"
#import "MainTabBarController.h"
#import "CYLDemoLocalization.h"

@interface SceneDelegate ()
@property (strong, nonatomic) MainTabBarController *tabBarController;
@end

@implementation SceneDelegate

// [EN] Creates the window for the scene: apps built with the iOS 27 SDK must adopt the UIScene life cycle.
// [CN] 为 scene 创建 window：使用 iOS 27 SDK 构建的 App 必须采用 UIScene 生命周期。
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.backgroundColor = [UIColor whiteColor];
    [self showTabBarControllerWithStyle:CYLTabBarStyleTypeLiquidGlass];
    [self.window makeKeyAndVisible];
}

- (void)showTabBarControllerWithStyle:(CYLTabBarStyleType)styleType {

    // [CN] 2. 创建 5 个页面 + 导航栏
    // [EN] 2. Create the 5 pages and their navigation bars.
    UIViewController *homeVC = [[HomeViewController alloc] init];
    UIViewController *wealthVC = [[WealthViewController alloc] init];
    UIViewController *tradeVC = [[TradeViewController alloc] init];
    UIViewController *infoVC = [[InfoViewController alloc] init];
    UIViewController *mineVC = [[MineViewController alloc] init];
    
    // [CN] 3. 包装导航控制器
    // [EN] 3. Wrap them in navigation controllers.
    UINavigationController *homeNav = [self wrapNavWithVC:homeVC title:CYLDemoLocalizedString(@"首页")];
    UINavigationController *wealthNav = [self wrapNavWithVC:wealthVC title:CYLDemoLocalizedString(@"理财")];
    UINavigationController *tradeNav = [self wrapNavWithVC:tradeVC title:CYLDemoLocalizedString(@"交易")];
    UINavigationController *infoNav = [self wrapNavWithVC:infoVC title:CYLDemoLocalizedString(@"资讯")];
    UINavigationController *mineNav = [self wrapNavWithVC:mineVC title:CYLDemoLocalizedString(@"我的")];
    
    // [CN] 1. 创建 TabBar 主控制器（图片使用 UIImage，非字符串）
    // [EN] 1. Create the tab bar controller (the images are UIImages, not names).
    // FIX: issue #601, #337
    // [EN] CYLTabBarItemImage is the default icon and the placeholder; CYLTabBarItemImageURL replaces it once downloaded
    //      (cached, drawn in its own colors, every style, also over a Lottie icon).
    // [CN] CYLTabBarItemImage 是默认图标及占位图；CYLTabBarItemImageURL 下载完成后覆盖它（带缓存，保持图片自身颜色，适用于所有样式，
    //      也能覆盖 Lottie 图标）。
    self.tabBarController = [[MainTabBarController alloc] initWithViewControllers:@[homeNav, wealthNav, tradeNav, infoNav, mineNav] tabBarItemsAttributes:@[
        // [CN] 首页
        // [EN] Home
        @{CYLTabBarItemTitle : CYLDemoLocalizedString(@"首页"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"house"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"house.fill"],
          CYLTabBarItemImageURL : @"https://cdn-icons-png.flaticon.com/512/3132/3132732.png",
          CYLTabBarItemSelectedImageURL : @"https://cdn-icons-png.flaticon.com/512/3132/3132779.png",
          CYLTabBarItemImageURLSize : [NSValue valueWithCGSize:CGSizeMake(24, 24)]},
        
        // [CN] 行情
        // [EN] Markets
        @{CYLTabBarItemTitle : CYLDemoLocalizedString(@"行情"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"chart.line.uptrend.xyaxis"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"chart.line.uptrend.xyaxis"],
          CYLTabBarItemImageURL : @"https://cdn-icons-png.flaticon.com/512/1828/1828884.png",
          CYLTabBarItemSelectedImageURL : @"https://cdn-icons-png.flaticon.com/512/1828/1828925.png",
          CYLTabBarItemImageURLSize : [NSValue valueWithCGSize:CGSizeMake(24, 24)]},
        
        // [CN] 交易
        // [EN] Trade
        @{CYLTabBarItemTitle : CYLDemoLocalizedString(@"交易"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"plus.circle"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"plus.circle.fill"],
          CYLTabBarItemImageURL : @"https://cdn-icons-png.flaticon.com/512/3132/3132732.png",
          CYLTabBarItemSelectedImageURL : @"https://cdn-icons-png.flaticon.com/512/3132/3132779.png",
          CYLTabBarItemImageURLSize : [NSValue valueWithCGSize:CGSizeMake(24, 24)]},
        
        // [CN] 资讯
        // [EN] News
        @{CYLTabBarItemTitle : CYLDemoLocalizedString(@"资讯"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"newspaper"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"newspaper.fill"],
          CYLTabBarItemImageURL : @"https://cdn-icons-png.flaticon.com/512/1828/1828884.png",
          CYLTabBarItemSelectedImageURL : @"https://cdn-icons-png.flaticon.com/512/1828/1828925.png",
          CYLTabBarItemImageURLSize : [NSValue valueWithCGSize:CGSizeMake(24, 24)]},
        
        // [CN] 我的
        // [EN] Me
        // FIX: issue #605
        // [EN] An animated GIF icon; any URL works, a file URL here.
        // [CN] GIF 动图图标；任何 URL 都可以，这里使用本地文件 URL。
        @{CYLTabBarItemTitle : CYLDemoLocalizedString(@"我的"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"person"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"person.fill"],
          CYLTabBarItemImageURL : [[NSBundle mainBundle] URLForResource:@"tab_animated" withExtension:@"gif"],
          CYLTabBarItemImageURLSize : [NSValue valueWithCGSize:CGSizeMake(24, 24)]}
    ] styleType:styleType context:nil];

    // [CN] 6. 设置 Window 根控制器
    // [EN] 6. Set the window's root view controller.
    self.window.rootViewController = self.tabBarController;
    [self updateTitleAfterPurchase];
}

// [CN] 包装导航栏
// [EN] Wraps a page in a navigation controller.
- (UINavigationController *)wrapNavWithVC:(UIViewController *)vc title:(NSString *)title {
    vc.title = title;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    return nav;
}

- (void)updateTitleAfterPurchase {
    // [EN] FIX: issue #601 — e.g. after a purchase: the title of a tab, in place.
    // [CN] 例如购买课程后：原地更新某个 Tab 的标题。
    [self.tabBarController updateTabBarItemAtIndex:1 attributes:@{CYLTabBarItemTitle : CYLDemoLocalizedString(@"已购课程")}];
}

@end
