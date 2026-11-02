//
//  CYLMineViewController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLMineViewController.h"
#import <CYLTabBarController/UITableViewCell+CYLBadgeExtention.h>
#import "CYLDetailsViewController.h"
#import <MJRefresh/MJRefresh.h>

@implementation CYLMineViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = CYLBadgeRowHeight;
    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), self);

    self.view.backgroundColor = [UIColor whiteColor];

//    self.navigationItem.title = @"我的";
//    self.tabBarItem.title = @"我的";

    // ✅ 关键代码：设置 NavigationBar 为白色背景（非透明）
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];   // ⚠️ 非透明关键
//        appearance.backgroundColor = [UIColor whiteColor];
        appearance.backgroundColor = [UIColor cyl_systemBackgroundColor];

        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName : [UIColor cyl_labelColor]
        };

        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationController.navigationBar.compactAppearance = appearance;
    } else {
        // iOS 12 及以下
        self.navigationController.navigationBar.translucent = NO;
        self.navigationController.navigationBar.barTintColor = [UIColor cyl_systemBackgroundColor];

        self.navigationController.navigationBar.titleTextAttributes =
        @{ NSForegroundColorAttributeName : [UIColor cyl_labelColor] };
    }

    __weak __typeof(self) weakSelf = self;
    self.tableView.mj_header =
    [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [weakSelf.tableView.mj_header endRefreshing];
        });
    }];
    if (@available(iOS 13.0, *)) {
        //触发暗黑模式切换， 会引起 tabBar 的 重新布局 ，可以用来测试常见的 tabBar 布局bug
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
}


- (void)refresh {
    [self.tableView.mj_header beginRefreshing];
    NSTimeInterval delaySeconds = 1;
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        [self.tableView.mj_header endRefreshing];
    });
}
#pragma mark - Methods

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [cell cyl_showBadgeForRow:indexPath.row];
    cell.detailTextLabel.text = [UITableViewCell cyl_badgeTitleForRow:indexPath.row];
    [[cell textLabel] setText:[NSString stringWithFormat:CYLLocalizedString(@"%@ CYLTabBarController on iOS %@"), self.title, @([[[UIDevice currentDevice] systemVersion] floatValue])]];
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX(30, [UITableViewCell cyl_badgeStyleCount]); // every badge style has a row
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    展示红点
    [self cyl_setBadgeCenterOffset:CGPointZero];

    [self cyl_showBadgeValue:[NSString stringWithFormat:@"%@", @(indexPath.row)] animationType:CYLBadgeAnimationTypeNone];
    [CYLTabBarController cyl_simulateMemoryWarning]; // #426/#428: memory warning demo, see the log 内存警告演示，见日志
    [self testPush];
}

- (void)testPush {
    CYLBaseViewController *viewController = [[CYLBaseViewController alloc] init];
    viewController.view.backgroundColor = [UIColor redColor];
    [viewController cyl_setDisablePopGestureRecognizer:YES];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end

