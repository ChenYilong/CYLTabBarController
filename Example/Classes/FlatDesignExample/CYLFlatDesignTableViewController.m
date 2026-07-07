//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignTableViewController.h"
#import "CYLFlatDesignTabBarDemoViewController.h"
#import "CYLFlatDesignMainTabBarController.h"
#import "CYLFlatDesignSystemTabBarController.h"
#import "MainTabBarController.h"
#import "CYLMainRootViewController.h"
#import "CYLPlusButtonSubclass.h"

@interface CYLFlatDesignDemoTabBar : UITabBar

@end

@implementation CYLFlatDesignDemoTabBar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.tintColor = UIColor.greenColor;
    }
    return self;
}

@end

@interface CYLFlatDesignTableViewController ()

@property (nonatomic, copy) NSString *itemTitle;

@end

@implementation CYLFlatDesignTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), self);
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = self.title; //✅sets navigation bar title.The right way to set the title of the navigation
    //    self.tabBarItem.title = @"首页";   //❌sets tab bar title. Even the `tabBarItem.title` changed, this will be ignored in tabbar.
    //self.title = @"首页1";                //❌sets both of these. Do not do this‼️‼️This may cause something strange  .
    //    [self.navigationController.tabBarItem setBadgeValue:@"3"];
    //    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshTabBar:)];
    //    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
    
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"FlatDesign" style:UIBarButtonItemStylePlain target:self action:@selector(flatDesignTabBar:)];
    //    leftBarButtonItem.tintColor = UIColor.redColor; // 确保使用原图色
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"LiquidGlass" style:UIBarButtonItemStylePlain target:self action:@selector(refreshTabBar:)];
    //    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"CYLTabBar" style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
    
#define RANDOM_COLOR [UIColor colorWithHue: (arc4random() % 256 / 256.0) saturation:((arc4random()% 128 / 256.0 ) + 0.5) brightness:(( arc4random() % 128 / 256.0 ) + 0.5) alpha:1]
    [self.navigationItem.leftBarButtonItem cyl_setBadgeBackgroundColor:UIColor.redColor];
    
    [self.navigationItem.rightBarButtonItem cyl_setBadgeBackgroundColor:UIColor.redColor];
    [self.navigationItem.leftBarButtonItem setTintColor:UIColor.redColor];
    [self.navigationItem.rightBarButtonItem setTintColor:UIColor.redColor];
    
    [self.navigationItem.leftBarButtonItem cyl_setBadgeTextColor:UIColor.redColor];
    [self.navigationItem.rightBarButtonItem cyl_setBadgeTextColor:UIColor.redColor];
    
    
    // ✅ iOS 26修复方案
    
    
    [self.navigationItem.rightBarButtonItem cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
    //                [viewController0 cyl_setBadgeRadius:11/2];
    
    //以上对Badge的参数设置，需要在 cyl_showBadgeValue 调用之前执行。
    [self.navigationItem.rightBarButtonItem cyl_showBadge];
    [self.navigationItem.rightBarButtonItem cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeShake];
    [self.navigationItem.leftBarButtonItem cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeScaleOnce];
    
    if (CYL_IS_IOS_26) {
        if (@available(iOS 26.0, *)) {
            UIScrollEdgeElementContainerInteraction *interaction = [UIScrollEdgeElementContainerInteraction new];
            
            interaction.scrollView = self.tableView;
            interaction.edge = UIRectEdgeBottom;
            [self.cyl_tabBarController.tabBar addInteraction:interaction];
        } else {
            // Fallback on earlier versions
        }
    }
}

- (void)refreshTabBar:(id)sender {
    [self createNewTabBardynamically];
}

- (void)flatDesignTabBar:(id)sender {
    CYLMainRootViewController *rootController = (CYLMainRootViewController *)CYLGetRootViewController();
    [rootController createFlatDesignTabBar];
}

- (void)createNewTabBardynamically {
    [CYLPlusButtonSubclass registerPlusButton];
    CYLMainRootViewController *rootController = (CYLMainRootViewController *)CYLGetRootViewController();
    [rootController createNewTabBarWithContext:NSStringFromClass([CYLTabBarController class])];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.textLabel.font = [UIFont systemFontOfSize:12];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    NSString *title = [NSString stringWithFormat:@"%@ CYLTabBarController on iOS %@", self.title, @([[[UIDevice currentDevice] systemVersion] floatValue])];

    if (indexPath.row == 0) {
        title = @"Show / hide CYLFlatDesignTabBar";
    } else if (indexPath.row == 1) {
        title = @"Change CYLFlatDesignTabBarItem 不居中显示（系统效果）";
    } else if (indexPath.row == 2) {
        title = @"Change CYLFlatDesignTabBarItem 居中显示";
    } else if (indexPath.row == 3) {
        title = @"设置 CYLFlatDesignTabBarItem 背景色";
    } else if (indexPath.row == 4) {
        title = @"改变 CYLFlatDesignTabBar 高度";
    } else if (indexPath.row == 5) {
        title = @"和系统 UITabBar 比较";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 6) {
        title = @"Push To 系统 UITabBarController";
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    cell.textLabel.text = title;

    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)

    [tableView deselectRowAtIndexPath:indexPath animated:true];
    
    
    if ([self.cylflatdesign_tabBarController isKindOfClass:[CYLFlatDesignSystemTabBarController class]]) {
        if (indexPath.row == 1 || indexPath.row == 2 || indexPath.row == 3 || indexPath.row == 4) {
            NSLog(@"系统TabBarController不支持");
            return;
        }
    }
    
    CYLTabBarController *tabBarController = (CYLTabBarController *)self.cylflatdesign_tabBarController;
    if (!tabBarController) {
        tabBarController = (CYLTabBarController *)self.cylflatdesign_tabBarController;
    }
    if (indexPath.row == 0) {
        if (tabBarController.isTabBarHidden) {
            [tabBarController setTabBarHidden:NO animated:YES];
        } else {
            [tabBarController setTabBarHidden:YES animated:YES];
        }
        
    } else if (indexPath.row == 1) {
        self.navigationController.cyl_tabBarItem.layoutCentered = NO;
        if (self.navigationController.cyl_tabBarItem.title) {
            _itemTitle = self.navigationController.cyl_tabBarItem.title;
            self.navigationController.cyl_tabBarItem.title = nil;
        } else {
            self.navigationController.cyl_tabBarItem.title = _itemTitle;
        }
    } else if (indexPath.row == 2) {
        self.navigationController.cyl_tabBarItem.layoutCentered = YES;
        if (self.navigationController.cyl_tabBarItem.title) {
            _itemTitle = self.navigationController.cyl_tabBarItem.title;
            self.navigationController.cyl_tabBarItem.title = nil;
        } else {
            self.navigationController.cyl_tabBarItem.title = _itemTitle;
        }
    } else if (indexPath.row == 3) {
        for (UIViewController *vc in tabBarController.viewControllers) {
            UIColor *backgroundColor = vc.cyl_tabBarItem.backgroundColor;
            UIColor *selectedBackgroundColor = vc.cyl_tabBarItem.selectedBackgroundColor;
            if (backgroundColor == nil) {
                backgroundColor = [UIColor colorWithRed:0.18 green:0.18 blue:0.18 alpha:1.0];
                selectedBackgroundColor = [UIColor blackColor];
            } else {
                backgroundColor = nil;
                selectedBackgroundColor = nil;
            }
            vc.cyl_tabBarItem.backgroundColor = backgroundColor;
            vc.cyl_tabBarItem.selectedBackgroundColor = selectedBackgroundColor;
        }
    } else if (indexPath.row == 4) {
        tabBarController.tabBarHeight += 10;
        if (tabBarController.tabBarHeight >= 100) {
            tabBarController.tabBarHeight = 49;
        }
    } else if (indexPath.row == 5) {
        CYLFlatDesignTabBarDemoViewController *vc = [[CYLFlatDesignTabBarDemoViewController alloc] init];
        //        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
    } else if (indexPath.row == 6) {
        //        CYLFlatDesignSystemTabBarController *vc = [[CYLFlatDesignSystemTabBarController alloc] init];
        //        vc.hidesBottomBarWhenPushed = YES;
        //        [self.navigationController pushViewController:vc animated:YES];
        
        //        CYLMainRootViewController *rootViewController = [[CYLMainRootViewController alloc] init];
        //                rootViewController.hidesBottomBarWhenPushed = YES;
        //        [CYLPlusButtonSubclass registerPlusButton];
        NSString *context = NSStringFromClass([self class]);
        MainTabBarController *tabBarController = [[MainTabBarController alloc] initWithContext:context];
        //                        tabBarController.hidesBottomBarWhenPushed = YES;
        tabBarController.hidesBottomBarWhenPushed = YES;

        [self.navigationController pushViewController:tabBarController animated:YES];
        
    } else {
        UIViewController *vc = [[UIViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        vc.cyl_hidesBottomBarWhenPushed = YES;

        vc.view.backgroundColor = UIColor.whiteColor;
        [self.navigationController pushViewController:vc animated:YES];
    }
#else
#endif
}

@end
