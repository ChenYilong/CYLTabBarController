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
}


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
    NSMutableArray *titles = @[@"首页", @"同城", @"发布", @"消息", @"我的"].mutableCopy;
    NSMutableArray *images = @[@"home_normal", @"fishpond_normal", @"post_highlight", @"message_normal" ,@"account_normal"].mutableCopy;
    NSMutableArray *selectedImages = @[@"home_highlight", @"fishpond_highlight", @"post_highlight", @"message_highlight", @"account_highlight"].mutableCopy;

    // 测试超过5个子控制器显示 moreNavigationController，继承自 CYLTabBarController 才会显示
    BOOL testMoreNav = NO;
    if (testMoreNav) {
        [titles addObject:@"测试"];
        [images addObject:@"account_normal"];
        [selectedImages addObject:@"account_highlight"];
    }

    // lottie动画的json文件来自于NorthSea, respect!
    CGFloat firstXOffset = -12/2;
    NSDictionary *firstTabBarItemsAttributes = @{
                                                 CYLTabBarItemTitle : @"首页",
                                                 CYLTabBarItemImage : @"home_normal",  /* NSString and UIImage are supported*/
                                                 CYLTabBarItemSelectedImage : @"home_highlight",  /* NSString and UIImage are supported*/
//                                                 CYLTabBarItemTitlePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(firstXOffset, -3.5)],
//                                                 CYLTabBarItemImagePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(firstXOffset, -3.5)],
                                                 //第一位 右大，下大
                                                 CYLTabBarLottieFilePath : [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_home" ofType:@"json"],
//                                                 CYLTabBarLottieSize: [NSValue valueWithCGSize:CGSizeMake(22, 22)]
                                                 };
    CGFloat secondXOffset = (-25+2)/2;
    NSDictionary *secondTabBarItemsAttributes = @{
                                                  CYLTabBarItemTitle : @"同城",
                                                  CYLTabBarItemImage :@"fishpond_normal",
                                                  CYLTabBarItemSelectedImage : @"fishpond_highlight",
//                                                  CYLTabBarItemTitlePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(secondXOffset, -3.5)],
//                                                  CYLTabBarItemImagePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(firstXOffset, -3.5)],
                                                  CYLTabBarLottieFilePath : [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_discover" ofType:@"json"],
//                                                  CYLTabBarLottieSize: [NSValue valueWithCGSize:CGSizeMake(22, 22)]
                                                  };
    
    NSDictionary *thirdTabBarItemsAttributes = @{
                                                 CYLTabBarItemTitle : @"消息",
                                                 CYLTabBarItemImage : @"message_normal",
                                                 CYLTabBarItemSelectedImage : @"message_highlight",
//                                                 CYLTabBarItemTitlePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(-secondXOffset, -3.5)],
//                                                 CYLTabBarItemImagePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(firstXOffset, -3.5)],
                                                 CYLTabBarLottieFilePath : [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_news" ofType:@"json"],
//                                                 CYLTabBarLottieSize: [NSValue valueWithCGSize:CGSizeMake(22, 22)]
                                                 };
    NSDictionary *fourthTabBarItemsAttributes = @{
                                                  CYLTabBarItemTitle : @"我的",
                                                  CYLTabBarItemImage : @"account_normal",
                                                  CYLTabBarItemSelectedImage : @"account_highlight",
//                                                  CYLTabBarItemTitlePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(-firstXOffset, -3.5)],
//                                                  CYLTabBarItemImagePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(firstXOffset, -3.5)],
                                                  CYLTabBarLottieFilePath : [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_mine" ofType:@"json"],
//                                                  CYLTabBarLottieSize: [NSValue valueWithCGSize:CGSizeMake(22, 22)]
                                                  };
    NSArray *tabBarItemsAttributes = @[
                                       firstTabBarItemsAttributes,
                                       secondTabBarItemsAttributes,
                                       thirdTabBarItemsAttributes,
                                       fourthTabBarItemsAttributes
                                       ];
    return tabBarItemsAttributes;
}

@end

