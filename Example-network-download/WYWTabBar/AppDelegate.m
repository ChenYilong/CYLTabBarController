//
//  AppDelegate.m
//  WYWTabBar
//
//  Created by weiyanwu on 2026/4/17.
//

#import "AppDelegate.h"
#import "CYLTabBarController.h"
#import "HomeViewController.h"
#import "WealthViewController.h"
#import "TradeViewController.h"
#import "InfoViewController.h"
#import "MineViewController.h"
#import "MainTabBarController.h"

@interface AppDelegate ()

@property (strong, nonatomic) MainTabBarController *tabBarController;


@end


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    [self showTabBarControllerWithStyle:CYLTabBarStyleTypeLiquidGlass];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)showTabBarControllerWithStyle:(CYLTabBarStyleType)styleType {

    // 2. 创建 5 个页面 + 导航栏
    UIViewController *homeVC = [[HomeViewController alloc] init];
    UIViewController *wealthVC = [[WealthViewController alloc] init];
    UIViewController *tradeVC = [[TradeViewController alloc] init];
    UIViewController *infoVC = [[InfoViewController alloc] init];
    UIViewController *mineVC = [[MineViewController alloc] init];
    
    // 3. 包装导航控制器
    UINavigationController *homeNav = [self wrapNavWithVC:homeVC title:CYLLocalizedString(@"首页")];
    UINavigationController *wealthNav = [self wrapNavWithVC:wealthVC title:CYLLocalizedString(@"理财")];
    UINavigationController *tradeNav = [self wrapNavWithVC:tradeVC title:CYLLocalizedString(@"交易")];
    UINavigationController *infoNav = [self wrapNavWithVC:infoVC title:CYLLocalizedString(@"资讯")];
    UINavigationController *mineNav = [self wrapNavWithVC:mineVC title:CYLLocalizedString(@"我的")];
    
    // 1. 创建 TabBar 主控制器（图片使用 UIImage，非字符串）
    self.tabBarController = [[MainTabBarController alloc] initWithViewControllers:@[homeNav, wealthNav, tradeNav, infoNav, mineNav] tabBarItemsAttributes:@[
        // 首页
        @{CYLTabBarItemTitle : CYLLocalizedString(@"首页"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"house"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"house.fill"]},
        
        // 行情
        @{CYLTabBarItemTitle : CYLLocalizedString(@"行情"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"chart.line.uptrend.xyaxis"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"chart.line.uptrend.xyaxis"]},
        
        // 交易
        @{CYLTabBarItemTitle : CYLLocalizedString(@"交易"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"plus.circle"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"plus.circle.fill"]},
        
        // 资讯
        @{CYLTabBarItemTitle : CYLLocalizedString(@"资讯"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"newspaper"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"newspaper.fill"]},
        
        // 我的
        @{CYLTabBarItemTitle : CYLLocalizedString(@"我的"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"person"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"person.fill"]}
    ] styleType:styleType context:nil];

    // 6. 设置 Window 根控制器
    self.window.rootViewController = self.tabBarController;
    [self loadTabBarIconsFromNetwork];
}

// 包装导航栏
- (UINavigationController *)wrapNavWithVC:(UIViewController *)vc title:(NSString *)title {
    vc.title = title;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    return nav;
}

- (void)loadTabBarIconsFromNetwork {
    // 示例图标URL数组（顺序与tabBarItem一致）
    NSArray *iconURLs = @[
        @"https://cdn-icons-png.flaticon.com/512/3132/3132732.png", // 购物车
        @"https://cdn-icons-png.flaticon.com/512/1828/1828884.png", // 消息
        @"https://cdn-icons-png.flaticon.com/512/3132/3132732.png", // 购物车
        @"https://cdn-icons-png.flaticon.com/512/1828/1828884.png", // 消息
        @"https://cdn-icons-png.flaticon.com/512/732/732240.png" // 地图
      ];
    // 示例选中状态图标URL数组（可选）
    NSArray *selectedIconURLs = @[
        @"https://cdn-icons-png.flaticon.com/512/3132/3132779.png", // 购物车（选中态，蓝色）
        @"https://cdn-icons-png.flaticon.com/512/1828/1828925.png", // 消息（选中态，蓝色）
        @"https://cdn-icons-png.flaticon.com/512/3132/3132779.png", // 购物车（选中态，蓝色）
        @"https://cdn-icons-png.flaticon.com/512/1828/1828925.png", // 消息（选中态，蓝色）
        @"https://cdn-icons-png.flaticon.com/512/732/732200.png" // 地图（选中态，蓝色）
      ];
    
    // FIX: issue #601, #337 — the icons come from the network through CYLTabBarController
    // (`-setTabBarItemIconWithURL:selectedURL:size:atIndex:`): downloaded and cached, drawn in their own colors, in every
    // tab bar style and also over a Lottie icon, without rebuilding the tab bar.
    // 图标通过 CYLTabBarController 从网络加载（`-setTabBarItemIconWithURL:selectedURL:size:atIndex:`）：下载并缓存，保持图片自身颜色，
    // 适用于所有样式，也能覆盖 Lottie 图标，无需重建 TabBar。
    for (NSInteger i = 0; i < iconURLs.count - 1; i++) {
        [self.tabBarController setTabBarItemIconWithURL:[NSURL URLWithString:iconURLs[i]]
                                            selectedURL:[NSURL URLWithString:selectedIconURLs[i]]
                                                   size:CGSizeMake(24, 24)
                                                atIndex:i];
    }

    // FIX: issue #605 — an animated GIF icon for the last tab; any URL works, a file URL here.
    // 最后一个 Tab 使用 GIF 动图图标；任何 URL 都可以，这里使用本地文件 URL。
    [self.tabBarController setTabBarItemIconWithURL:[[NSBundle mainBundle] URLForResource:@"tab_animated" withExtension:@"gif"]
                                        selectedURL:nil
                                               size:CGSizeMake(24, 24)
                                            atIndex:iconURLs.count - 1];

    // FIX: issue #601 — e.g. after a purchase: the title of a tab, in place. 例如购买课程后：原地更新某个 Tab 的标题。
    [self.tabBarController updateTabBarItemAtIndex:1 attributes:@{CYLTabBarItemTitle : CYLLocalizedString(@"已购课程")}];
}

@end
