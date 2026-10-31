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
#import "AppDelegate.h"

@interface CYLMainRootViewController ()

@end

@implementation CYLMainRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    [self createLiquidGlassTabBar];
//    [self createFlatDesignTabBar];
    [self allowLandscapeOnFoldableDevice];

}

/*!
 * FIX: issue #680
 * [EN] On a foldable device (iPhone Duo) let the demo rotate with the device, so the unfolded inner screen is
 *      filled in landscape. `UIHingeInteraction` only reports a hinge on foldable devices.
 * [CN] 可折叠设备（iPhone Duo）上允许 Demo 跟随设备旋转，展开内屏横屏时铺满屏幕。只有可折叠设备才会通过
 *      `UIHingeInteraction` 返回铰链。
 */
- (void)allowLandscapeOnFoldableDevice {
#if defined(__IPHONE_27_1) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_27_1
    if (@available(iOS 27.1, *)) {
        __weak __typeof(self) weakSelf = self;
        UIHingeInteraction *hingeInteraction = [[UIHingeInteraction alloc] initWithUpdateHandler:^(UIHingeInteraction *interaction, UIHingeInteractionUpdate *update) {
            AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
            if (!update.hinge || ![appDelegate isKindOfClass:[AppDelegate class]] || appDelegate.supportsLandscapeOnFoldableDevice) { return; }
            appDelegate.supportsLandscapeOnFoldableDevice = YES;
            [weakSelf setNeedsUpdateOfSupportedInterfaceOrientations];
        }];
        [self.view addInteraction:hingeInteraction];
    }
#endif
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
        
        nav.cyl_getViewControllerInsteadOfNavigationController.title  = [NSString stringWithFormat:@"%@%@", firstTabBarItemsAttributes[CYLTabBarItemTitle],@"（扁平）"];

        
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
        //            // 设置badgeSize不为CGSizeZero、badgeValue为nil，就变成一个点了
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

