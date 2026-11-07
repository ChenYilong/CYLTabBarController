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
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"CYLScrollHideSelfTestFlatDesign"]) {
        [self createFlatDesignTabBar];
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

