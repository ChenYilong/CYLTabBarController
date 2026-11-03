//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignTableViewController.h"
#import <CYLTabBarController/UITableViewCell+CYLBadgeExtention.h>
#import <CYLTabBarController/UIViewController+CYLSettingsSection.h>
#import "CYLFlatDesignTabBarDemoViewController.h"
#import "CYLPopPushDemoViewController.h"
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
    [UITableViewCell cyl_setUpAutomaticRowHeightForTableView:self.tableView];
    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), self);
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = self.title; //✅sets navigation bar title.The right way to set the title of the navigation
    //    self.tabBarItem.title = @"首页";   //❌sets tab bar title. Even the `tabBarItem.title` changed, this will be ignored in tabbar.
    //self.title = @"首页1";                //❌sets both of these. Do not do this‼️‼️This may cause something strange  .
    //    [self.navigationController.tabBarItem setBadgeValue:@"3"];
    //    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshTabBar:)];
    //    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
    
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:CYLLocalizedString(@"FlatDesign") style:UIBarButtonItemStylePlain target:self action:@selector(flatDesignTabBar:)];
    //    leftBarButtonItem.tintColor = UIColor.redColor; // 确保使用原图色
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:CYLLocalizedString(@"LiquidGlass") style:UIBarButtonItemStylePlain target:self action:@selector(refreshTabBar:)];
    //    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"CYLTabBar" style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
    
    [self.navigationItem.leftBarButtonItem setTintColor:UIColor.redColor];
    [self.navigationItem.rightBarButtonItem setTintColor:UIColor.redColor];
    
    // ✅ iOS 26修复方案
    
    // #425: red background, text color and the (-5, 3) offset come from CYLBadgeAppearance (SceneDelegate.m
    // -setUpBadgeAppearance); a red dot has no text, so its text color never showed.
    // #425：红色背景和 (-5, 3) 偏移来自 CYLBadgeAppearance（SceneDelegate.m -setUpBadgeAppearance），无需逐个设置；
    // 红点没有文字，原先设置的文字颜色不会显示。
    //                [viewController0 cyl_setBadgeRadius:11/2];
    
    //以上对Badge的参数设置，需要在 cyl_showBadgeValue 调用之前执行。
    // Animated navigation item badges in a random color. 导航栏按钮的动画角标，使用随机颜色。
    [self.navigationItem.rightBarButtonItem cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeShake backgroundColor:UIColor.cyl_randomColor];
    [self.navigationItem.leftBarButtonItem cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeBreathe backgroundColor:UIColor.cyl_randomColor];
    
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

// Section 0: settings (language, memory warning). 第 0 组：设置（语言、内存警告）。
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == CYLSettingsSection) {
        return [self cyl_settingsRowCount];
    }
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == CYLSettingsSection) {
        return [self cyl_settingsCellForTableView:tableView atIndexPath:indexPath];
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.textLabel.font = [UIFont systemFontOfSize:12];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    NSString *title = [NSString localizedStringWithFormat:CYLLocalizedString(@"%@ CYLTabBarController on iOS %@"), self.title, @([[[UIDevice currentDevice] systemVersion] floatValue])];

    if (indexPath.row == 0) {
        title = CYLLocalizedString(@"Show / hide CYLFlatDesignTabBar");
    } else if (indexPath.row == 1) {
        title = CYLLocalizedString(@"Change CYLFlatDesignTabBarItem 不居中显示（系统效果）");
    } else if (indexPath.row == 2) {
        title = CYLLocalizedString(@"Change CYLFlatDesignTabBarItem 居中显示");
    } else if (indexPath.row == 3) {
        title = CYLLocalizedString(@"设置 CYLFlatDesignTabBarItem 背景色");
    } else if (indexPath.row == 4) {
        title = CYLLocalizedString(@"改变 CYLFlatDesignTabBar 高度");
    } else if (indexPath.row == 5) {
        title = CYLLocalizedString(@"和系统 UITabBar 比较");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 6) {
        title = CYLLocalizedString(@"Push To 系统 UITabBarController（另一个 PlusButton）");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 7) {
        title = CYLLocalizedString(@"Push To 另一个 CYLFlatDesignTabBarController（另一个 PlusButton）");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else if (indexPath.row == 8) {
        title = CYLLocalizedString(@"cyl_pop / cyl_push 系列方法演示");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    // The action is the title; the other rows show the badge sample as the title and the page as the subtitle, as in
    // the other demos. 操作行以操作为主标题；其余行与其他演示一致，以角标样例为主标题、页面为副标题。
    BOOL isActionRow = indexPath.row <= 8;
    cell.textLabel.text = isActionRow ? title : [UITableViewCell cyl_badgeTitleForRow:indexPath.row];
    cell.detailTextLabel.text = isActionRow ? [UITableViewCell cyl_badgeTitleForRow:indexPath.row] : title;
    [cell cyl_wrapsTextLabels];
    [cell cyl_showBadgeForRow:indexPath.row];

    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == CYLSettingsSection) {
        [self cyl_didSelectSettingsRowAtIndexPath:indexPath inTableView:tableView];
        return;
    }
#if CYL_FLATDESIGN_AVAILABLE

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
            UIColor *selectedBackgroundColor = nil;
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
        // Same logic as the plus button's "Switch Style" menu: a tab bar controller that shows the OTHER plus button
        // (another context); this flat design tab bar controller keeps its own.
        // 与 PlusButton“切换样式”菜单相同的逻辑：push 一个显示 **另一个** PlusButton（另一个 context）的 TabBarController，
        // 当前扁平样式的 TabBarController 保留自己的 PlusButton。
        Class plusButtonClass = [CYLPlusButtonSubclass alternatePlusButtonClassForOwner:self];
        MainTabBarController *tabBarController = [CYLMainRootViewController newLiquidGlassTabBarControllerWithPlusButtonClass:plusButtonClass];
        //                        tabBarController.hidesBottomBarWhenPushed = YES;
        tabBarController.hidesBottomBarWhenPushed = YES;

        [self.navigationController pushViewController:tabBarController animated:YES];
        
    } else if (indexPath.row == 7) {
        // A flat design tab bar controller inside the flat design one, also with the OTHER plus button.
        // 在扁平样式的 TabBarController 里 push 另一个扁平样式的 TabBarController，同样使用 **另一个** PlusButton。
        Class plusButtonClass = [CYLPlusButtonSubclass alternatePlusButtonClassForOwner:self];
        CYLFlatDesignMainTabBarController *flatDesignTabBarController = [CYLMainRootViewController newFlatDesignTabBarControllerWithPlusButtonClass:plusButtonClass];
        flatDesignTabBarController.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:flatDesignTabBarController animated:YES];
        
    } else if (indexPath.row == 8) {
        // Every `cyl_pop…` / `cyl_push…` method, called from a page pushed onto this tab's navigation stack.
        // 从 push 到当前 Tab 导航栈中的页面调用每一个 `cyl_pop…` / `cyl_push…` 方法。
        CYLPopPushDemoViewController *vc = [[CYLPopPushDemoViewController alloc] init];
        vc.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:vc animated:YES];
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
