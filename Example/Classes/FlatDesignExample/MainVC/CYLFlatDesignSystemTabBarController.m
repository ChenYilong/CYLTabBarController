//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignSystemTabBarController.h"
#import "CYLFlatDesignTableViewController.h"

@interface CYLFlatDesignSystemTabBarController ()

@end

@implementation CYLFlatDesignSystemTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    NSArray *titles = @[@"首页", @"同城", @"发布", @"消息", @"我的"];
    NSArray *images = @[@"home_normal", @"fishpond_normal", @"post_highlight", @"message_normal" ,@"account_normal"];
    NSArray *selectedImages = @[@"home_highlight", @"fishpond_highlight", @"post_highlight", @"message_highlight", @"account_highlight"];
    for (NSInteger i = 0; i < titles.count; i++) {
        CYLFlatDesignTableViewController *vc = [[CYLFlatDesignTableViewController alloc] init];
        vc.title = titles[i];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [self setupChildViewController:nav title:titles[i] imageName:images[i] selectedImageName:selectedImages[i]];
        if (i == 0) {
            nav.tabBarItem.badgeValue = @"1";
        } else if (i == 1) {
            nav.tabBarItem.badgeValue = @"11";
            nav.tabBarItem.badgeColor = UIColor.systemBlueColor;
        } else if (i == 2) {
//            nav.tabBarItem.imagePositionAdjustment = UIOffsetMake(0, -12);
        } else if (i == 3) {
            nav.tabBarItem.badgeValue = @"新消息";
            [nav.tabBarItem setBadgeTextAttributes:@{NSForegroundColorAttributeName:UIColor.greenColor} forState:UIControlStateNormal];
        } else if (i == 4) {
            nav.tabBarItem.badgeValue = @"11";
            nav.tabBarItem.badgeColor = UIColor.systemRedColor;
            // 让文字颜色和badgeColor一样，就变成一个点了
            [nav.tabBarItem setBadgeTextAttributes:@{NSForegroundColorAttributeName:UIColor.systemRedColor} forState:UIControlStateNormal];
        }
        
        [viewControllers addObject:nav];
    }
    
    self.viewControllers = viewControllers;
}

- (void)setupChildViewController:(UIViewController *)childVC title:(NSString *)title imageName:(NSString *)imageName selectedImageName:(NSString *)selectedImageName {
    childVC.tabBarItem.title = title;
    childVC.tabBarItem.image = [UIImage imageNamed:imageName];
    childVC.tabBarItem.selectedImage = [UIImage imageNamed:selectedImageName];
    [childVC.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName:UIColor.systemYellowColor} forState:UIControlStateSelected];
}

@end
