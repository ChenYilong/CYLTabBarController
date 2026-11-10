//
//  CYLMainRootViewController.m
//  CYLTabBarController
//
//  Created by chenyilong on 7/3/2026.
//  Copyright © 2026 微博@iOS程序犭袁. All rights reserved.
//

#import "CYLMainRootViewController.h"
#import "MainTabBarController.h"
#import "CYLPlusButtonSubclass.h"
#import "CYLFlatDesignMainTabBarController.h"
#import "CYLFlatDesignTableViewController.h"
#import "CYLHomeViewController.h"
#import "CYLSameCityViewController.h"
#import "CYLMessageViewController.h"
#import "CYLMineViewController.h"
#import "CYLPlusDemoChildViewController.h"

@interface CYLMainRootViewController ()

@end

@implementation CYLMainRootViewController

+ (instancetype)currentRootViewController {
    UIViewController *rootViewController = CYLGetRootWindow().rootViewController;
    return [rootViewController isKindOfClass:self] ? (CYLMainRootViewController *)rootViewController : nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBarHidden = YES;
    self.view.backgroundColor = UIColor.systemBackgroundColor; // [EN] Dark Mode. [CN] 适配深色模式。
    // [EN] Scroll hiding self-test (issue #13, scripts/scroll-hide-self-test.sh): `-CYLScrollHideSelfTestFlatDesign YES`
    //      starts on the FlatDesign tab bar, which code can hide on every system (Liquid Glass is minimized by the system).
    // [CN] 滚动隐藏自测（issue #13，scripts/scroll-hide-self-test.sh）：`-CYLScrollHideSelfTestFlatDesign YES` 以扁平样式 TabBar 启动，
    //      在所有系统上都可以用代码隐藏（液态玻璃由系统缩小）。
    // [EN] `-CYLDemoManifestTheme light|dark|christmas`: the tab bar comes from the configuration manifest built into the app
    //      (docs/Configuration-Manifest.md) instead of code.
    // [CN] `-CYLDemoManifestTheme light|dark|christmas`：TabBar 来自 App 内置的配置清单（docs/Configuration-Manifest.md），而不是代码。
    NSString *manifestTheme = [[NSUserDefaults standardUserDefaults] stringForKey:@"CYLDemoManifestTheme"];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"CYLScrollHideSelfTestFlatDesign"]) {
        [self createFlatDesignTabBar];
    } else if (manifestTheme.length > 0 && [self createManifestTabBarWithTheme:manifestTheme]) {
        // [EN] Built from the manifest. [CN] 已由清单创建。
    } else {
        [self createLiquidGlassTabBar];
    }
//    [self createFlatDesignTabBar];

}

/// No restriction in code: the orientations set in Xcode (Info.plist) apply. A navigation controller allows all but
/// upside down by default on iPhone, which would leave one of them out.
/// 代码中不做限制，以 Xcode 中的设置（Info.plist）为准。导航控制器在 iPhone 上默认不允许倒置竖屏，会漏掉这个方向。
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

#pragma mark -
#pragma mark - createLiquidGlassTabBar
// MARK: createLiquidGlassTabBar

- (CYLTabBarController *)createLiquidGlassTabBar {
    return [self createLiquidGlassTabBarWithPlusButtonClass:[CYLPlusButtonSubclass class]];
}

- (CYLTabBarController *)createLiquidGlassTabBarWithPlusButtonClass:(Class)plusButtonClass {
    MainTabBarController *tabBarController = [[self class] newLiquidGlassTabBarControllerWithPlusButtonClass:plusButtonClass];
    self.viewControllers = @[tabBarController];
    return tabBarController;
}

+ (MainTabBarController *)newLiquidGlassTabBarControllerWithPlusButtonClass:(Class)plusButtonClass {
    // Registers for the plus button class's own context; the plus button of the other class stays registered.
    // 按该 PlusButton 类自己的 context 注册；另一个类的 PlusButton 保持注册。
    [plusButtonClass registerPlusButton];
    NSString *context = [plusButtonClass matchedTabBarContext];
    MainTabBarController *tabBarController = [[MainTabBarController alloc] initWithContext:context];
    tabBarController.allowsVerticalBar = YES;
    return tabBarController;
}

- (CYLTabBarController *)createNewTabBarWithContext:(NSString *)context {
    MainTabBarController *tabBarController = [[MainTabBarController alloc] initWithContext:context];
//    CYLFlatDesignMainTabBarController *tabBarController = [[CYLFlatDesignMainTabBarController alloc] init];
    tabBarController.allowsVerticalBar = YES;
    self.viewControllers = @[tabBarController];
    return tabBarController;
}

#pragma mark -
#pragma mark - createManifestTabBar
// MARK: createManifestTabBar

/*!
 * [EN] A tab bar from a configuration manifest (docs/Configuration-Manifest.md): the manifest, its string tables and
 *      the images of every version and theme are in Example-Shared/Configurations, bundled as "Configurations"; its page
 *      IDs open this example's own pages, registered once. `theme` is one of `themes.list` (light, dark, christmas).
 * [CN] 由配置清单创建 TabBar（docs/Configuration-Manifest.md）：清单、字符串表与各版本、各主题的图片都在 Example-Shared/Configurations 中，
 *      以 "Configurations" 打包；清单中的页面 ID 打开本示例自己的页面，只注册一次。`theme` 为 `themes.list` 之一（light、dark、christmas）。
 */
- (BOOL)createManifestTabBarWithTheme:(NSString *)theme {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary<NSString *, Class> *pages = @{ @"home" : [CYLHomeViewController class], @"discover" : [CYLSameCityViewController class],
                                                   @"message" : [CYLMessageViewController class], @"me" : [CYLMineViewController class],
                                                   @"publish" : [CYLPlusDemoChildViewController class] };
        [CYLTabBarPageRegistry.sharedRegistry registerPageProvider:^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
            UIViewController *page = [[pages[pageIdentifier] alloc] init];
            return [[CYLBaseNavigationController alloc] initWithRootViewController:page];
        } forPageIdentifiers:pages.allKeys];
    });
    NSError *error = nil;
    CYLTabBarManifest *manifest = [CYLTabBarManifest manifestWithRoute:@"bundle:Configurations/Manifests/cyl_tabbar_manifest.json" error:&error];
    CYLTabBarController *tabBarController = [manifest tabBarControllerWithError:&error];
    if (!tabBarController) {
        NSLog(@"🔴 CYLDemoManifestTheme: %@", error.localizedDescription);
        return NO;
    }
    // [EN] After the manifest registered its themes. A skin other than the light / dark pair stops following the system
    //      appearance, which would choose light or dark again.
    // [CN] 在清单注册其主题之后。浅色 / 深色以外的皮肤停止跟随系统外观，否则系统会重新选择浅色或深色。
    NSDictionary *themes = manifest.dictionary[@"themes"];
    CYLThemeManager *manager = [CYLThemeManagerCenter themeManagerWithName:themes[@"managerName"] ?: @"CYLConfigurationDemo"];
    if (![theme isEqual:themes[@"default"]] && ![theme isEqual:themes[@"darkMode"]]) {
        if (@available(iOS 13.0, *)) {
            manager.respondsSystemStyleAutomatically = NO;
        }
        manager.identifierForTrait = nil;
    }
    manager.currentThemeIdentifier = theme;
    self.viewControllers = @[ tabBarController ];
    return YES;
}

#pragma mark -
#pragma mark - createFlatDesignTabBar
// MARK: createFlatDesignTabBar

- (CYLFlatDesignMainTabBarController *)createFlatDesignTabBar {
    return [self createFlatDesignTabBarWithPlusButtonClass:[CYLPlusButtonSubclass class]];
}

- (CYLFlatDesignMainTabBarController *)createFlatDesignTabBarWithPlusButtonClass:(Class)plusButtonClass {
    CYLFlatDesignMainTabBarController *tabBarController = [[self class] newFlatDesignTabBarControllerWithPlusButtonClass:plusButtonClass];
    self.viewControllers = @[tabBarController];
    return tabBarController;
}

+ (CYLFlatDesignMainTabBarController *)newFlatDesignTabBarControllerWithPlusButtonClass:(Class)plusButtonClass {
    [plusButtonClass registerPlusButton];
    NSString *context = [plusButtonClass matchedTabBarContext];
    CYLFlatDesignMainTabBarController *tabBarController = [[CYLFlatDesignMainTabBarController alloc] initWithViewControllers:[self viewControllersForTabBar]
                                                           
                                                                                                       tabBarItemsAttributes:[self tabBarItemsAttributesForTabBar]
                                                                                                                     context:context];
    
    //    CYLTabBarStyleType type = CYLTabBarStyleTypeDefault;
    //        return [self initWithViewControllers:viewControllers
    //                       tabBarItemsAttributes:tabBarItemsAttributes
    //                                 imageInsets:UIEdgeInsetsZero
    //                     titlePositionAdjustment:UIOffsetZero
    //                                   styleType:type
    //                                     context:context];
    tabBarController.tabBarStyleType = CYLTabBarStyleTypeFlatDesign;
    return tabBarController;
}

#pragma mark -
#pragma mark - other
// MARK: other

+ (NSArray *)viewControllersForTabBar {
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    NSArray *tabBarItemsAttributesForTabBar = [self tabBarItemsAttributesForTabBar];
    for (NSInteger i = 0; i < tabBarItemsAttributesForTabBar.count; i++) {
        CYLFlatDesignTableViewController *vc = [[CYLFlatDesignTableViewController alloc] init];
        NSDictionary *firstTabBarItemsAttributes = tabBarItemsAttributesForTabBar[i];
//        vc.title = firstTabBarItemsAttributes[CYLTabBarItemTitle];
//        vc.title  = [NSString stringWithFormat:@"%@%@", firstTabBarItemsAttributes[CYLTabBarItemTitle],@"（扁平）"];

        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        //        [self setupChildViewController:nav
        //                                 title:titles[i]
        //                             imageName:images[i]
        //                     selectedImageName:selectedImages[i]
        //                        lottieFilePath:lottieFilePaths[i]];
        
        nav.cyl_getViewControllerInsteadOfNavigationController.title  = [NSString stringWithFormat:@"%@%@", firstTabBarItemsAttributes[CYLTabBarItemTitle],CYLLocalizedString(@"（扁平）")];

        
        //        if (i == 0) {
        //            nav.cyl_tabBarItem.badgeValue = @"1";
        //        } else if (i == 1) {
        //            nav.cyl_tabBarItem.badgeValue = @"11";
        //            nav.cyl_tabBarItem.badgeColor = UIColor.systemBlueColor;
        //        } else if (i == 2) {
        //            nav.cyl_tabBarItem.imagePositionAdjustment = UIOffsetMake(0, -12);
        //        } else if (i == 3) {
        //            nav.cyl_tabBarItem.badgeValue = @"新消息";
        //            [nav.cyl_tabBarItem setBadgeTextAttributes:@{NSForegroundColorAttributeName:UIColor.greenColor} forState:UIControlStateNormal];
        //        } else if (i == 4) {
        // [CN] // 设置badgeSize不为CGSizeZero、badgeValue为nil，就变成一个点了
        // [EN] If badgeSize is not CGSizeZero and badgeValue is nil, the badge becomes a dot.
        //            nav.cyl_tabBarItem.badgeValue = nil;
        //            nav.cyl_tabBarItem.badgeSize = CGSizeMake(10, 10);
        //            nav.cyl_tabBarItem.badgeColor = UIColor.systemRedColor;
        //        }
        [viewControllers addObject:nav];
    }
    return viewControllers;
}

+ (NSArray *)tabBarItemsAttributesForTabBar {
    return [MainTabBarController tabBarItemsAttributesForTabBar];
}

@end

