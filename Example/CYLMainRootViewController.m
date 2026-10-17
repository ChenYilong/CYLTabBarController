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

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    [self createLiquidGlassTabBar];
//    [self createFlatDesignTabBar];

}

#pragma mark -
#pragma mark - createLiquidGlassTabBar
// MARK: createLiquidGlassTabBar

- (CYLTabBarController *)createLiquidGlassTabBar {
    [CYLPlusButtonSubclass registerPlusButton];
    NSString *context = nil; // NSStringFromClass([self class]);
    return [self createNewTabBarWithContext:context];
}

- (CYLTabBarController *)createNewTabBarWithContext:(NSString *)context {
    MainTabBarController *tabBarController = [[MainTabBarController alloc] initWithContext:context];
//    CYLFlatDesignMainTabBarController *tabBarController = [[CYLFlatDesignMainTabBarController alloc] init];
    self.viewControllers = @[tabBarController];
    return tabBarController;
}

#pragma mark -
#pragma mark - createFlatDesignTabBar
// MARK: createFlatDesignTabBar

- (CYLFlatDesignMainTabBarController *)createFlatDesignTabBar {
    [CYLPlusButtonSubclass registerPlusButton];
    CYLTabBarStyleType type = CYLTabBarStyleTypeDefault;
    NSString *context = nil;
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
    self.viewControllers = @[tabBarController];
    return tabBarController;
}

#pragma mark -
#pragma mark - other
// MARK: other

- (NSArray *)viewControllersForTabBar {
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

- (NSArray *)tabBarItemsAttributesForTabBar {
    return [MainTabBarController tabBarItemsAttributesForTabBar];
}

@end

