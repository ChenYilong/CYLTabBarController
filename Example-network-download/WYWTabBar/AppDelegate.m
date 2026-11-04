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
    // [EN] FIX: issue #601 — how long and how much the icons from the network stay cached (memory and sandbox), as
    //      SDWebImage's SDImageCacheConfig.
    // [CN] 网络图标在内存与沙盒中的缓存时长与大小，参考 SDWebImage 的 SDImageCacheConfig。
    CYLImageCache *imageCache = [CYLImageCache sharedImageCache];
    imageCache.maxDiskAge = 30 * 24 * 60 * 60;                 // 30 days
    imageCache.maxDiskSize = 20 * 1024 * 1024;                 // 20 MB
    imageCache.diskCacheExpireType = CYLImageCacheExpireTypeAccessDate;
    [self showTabBarControllerWithStyle:CYLTabBarStyleTypeLiquidGlass];
    [self.window makeKeyAndVisible];
    return YES;
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
    UINavigationController *homeNav = [self wrapNavWithVC:homeVC title:CYLLocalizedString(@"首页")];
    UINavigationController *wealthNav = [self wrapNavWithVC:wealthVC title:CYLLocalizedString(@"理财")];
    UINavigationController *tradeNav = [self wrapNavWithVC:tradeVC title:CYLLocalizedString(@"交易")];
    UINavigationController *infoNav = [self wrapNavWithVC:infoVC title:CYLLocalizedString(@"资讯")];
    UINavigationController *mineNav = [self wrapNavWithVC:mineVC title:CYLLocalizedString(@"我的")];
    
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
        @{CYLTabBarItemTitle : CYLLocalizedString(@"首页"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"house"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"house.fill"],
          CYLTabBarItemImageURL : @"https://cdn-icons-png.flaticon.com/512/3132/3132732.png",
          CYLTabBarItemSelectedImageURL : @"https://cdn-icons-png.flaticon.com/512/3132/3132779.png",
          CYLTabBarItemImageURLSize : [NSValue valueWithCGSize:CGSizeMake(24, 24)]},
        
        // [CN] 行情
        // [EN] Markets
        @{CYLTabBarItemTitle : CYLLocalizedString(@"行情"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"chart.line.uptrend.xyaxis"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"chart.line.uptrend.xyaxis"],
          CYLTabBarItemImageURL : @"https://cdn-icons-png.flaticon.com/512/1828/1828884.png",
          CYLTabBarItemSelectedImageURL : @"https://cdn-icons-png.flaticon.com/512/1828/1828925.png",
          CYLTabBarItemImageURLSize : [NSValue valueWithCGSize:CGSizeMake(24, 24)]},
        
        // [CN] 交易
        // [EN] Trade
        @{CYLTabBarItemTitle : CYLLocalizedString(@"交易"),
          CYLTabBarItemImage : [UIImage systemImageNamed:@"plus.circle"],
          CYLTabBarItemSelectedImage : [UIImage systemImageNamed:@"plus.circle.fill"],
          CYLTabBarItemImageURL : @"https://cdn-icons-png.flaticon.com/512/3132/3132732.png",
          CYLTabBarItemSelectedImageURL : @"https://cdn-icons-png.flaticon.com/512/3132/3132779.png",
          CYLTabBarItemImageURLSize : [NSValue valueWithCGSize:CGSizeMake(24, 24)]},
        
        // [CN] 资讯
        // [EN] News
        @{CYLTabBarItemTitle : CYLLocalizedString(@"资讯"),
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
        @{CYLTabBarItemTitle : CYLLocalizedString(@"我的"),
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
    [self.tabBarController updateTabBarItemAtIndex:1 attributes:@{CYLTabBarItemTitle : CYLLocalizedString(@"已购课程")}];
}

@end
