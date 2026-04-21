//
//  CYLHomeViewController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLHomeViewController.h"
//#import "CYLTabBarControllerConfig.h"
#import "CYLPlusButtonSubclass.h"
#import "MainTabBarController.h"
#import "CYLMainRootViewController.h"
#import <MJRefresh/MJRefresh.h>

@implementation CYLHomeViewController 

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), self);
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"首页(3)"; //✅sets navigation bar title.The right way to set the title of the navigation
    self.tabBarItem.title = @"首页";   //❌sets tab bar title. Even the `tabBarItem.title` changed, this will be ignored in tabbar.
    //self.title = @"首页1";                //❌sets both of these. Do not do this‼️‼️This may cause something strange  .
//    [self.navigationController.tabBarItem setBadgeValue:@"3"];
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshTabBar:)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"refresh TabBar" style:UIBarButtonItemStylePlain target:self action:@selector(refreshTabBar:)];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"CYLTabBar" style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];

#define RANDOM_COLOR [UIColor colorWithHue: (arc4random() % 256 / 256.0) saturation:((arc4random()% 128 / 256.0 ) + 0.5) brightness:(( arc4random() % 128 / 256.0 ) + 0.5) alpha:1]

    [self.navigationItem.rightBarButtonItem cyl_setBadgeBackgroundColor:UIColor.redColor];
    [self.navigationItem.rightBarButtonItem cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
    //                [viewController0 cyl_setBadgeRadius:11/2];
    
    //以上对Badge的参数设置，需要在 cyl_showBadgeValue 调用之前执行。
    [self.navigationItem.rightBarButtonItem cyl_showBadge];
    [self.navigationItem.rightBarButtonItem cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeScale];
    [self.navigationItem.leftBarButtonItem cyl_showBadge];
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

- (void)refresh {
    [self.tableView.mj_header beginRefreshing];
    NSUInteger delaySeconds = 1;
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        [self.tableView.mj_header endRefreshing];
    });
}

- (void)refreshTabBar:(id)sender {
    [self createNewTabBardynamically];
}

- (void)createNewTabBardynamically {
//    [CYLPlusButtonSubclass registerPlusButton];
    CYLMainRootViewController *rootController = (CYLMainRootViewController *)CYLGetRootViewController();
    [rootController createNewTabBarWithContext:NSStringFromClass([self class])];
}

#pragma mark - Methods

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [[cell textLabel] setText:[NSString stringWithFormat:@"%@ CYLTabBarController %@", self.tabBarItem.title, @(indexPath.row)]];
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animate {
    if ([navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        if ([navigationController.viewControllers count] == 1) {
            navigationController.interactivePopGestureRecognizer.enabled = NO;
        } else {
            navigationController.interactivePopGestureRecognizer.enabled = YES;
        }
    }
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 30;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSNumber *badgeNumber = @(indexPath.row);
    self.navigationItem.title = [NSString stringWithFormat:@"首页(%@)", badgeNumber]; //sets navigation bar title.
    
//    [self.navigationController.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%@", badgeNumber]];
    
//    CYLTabBarControllerConfig *tabBarControllerConfig = [[CYLTabBarControllerConfig alloc] init];
//    CYLTabBarController *tabBarController = tabBarControllerConfig.tabBarController;
//    tabBarController.delegate = self;
//
//    [self cyl_showBadgeValue:[NSString stringWithFormat:@"%@", @(indexPath.row)] animationType:CYLBadgeAnimationTypeScale];
    [self pushToNewViewController];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self pushToNewViewController];
}

- (void)pushToNewViewController {
    CYLBaseViewController *viewController = [CYLBaseViewController new];
    viewController.view.backgroundColor = [UIColor orangeColor];
    [viewController cyl_setNavigationBarHidden:YES];
    [viewController cyl_setDisablePopGestureRecognizer:NO];

    [self.navigationController  pushViewController:viewController animated:YES];
}

@end
