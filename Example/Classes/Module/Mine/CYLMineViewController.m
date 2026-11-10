//
//  CYLMineViewController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLMineViewController.h"
#import "CYLFlatDesignTableViewController.h"
#import <CYLTabBarController/UITableViewCell+CYLBadgeExtention.h>
#import <CYLTabBarController/UIViewController+CYLSettingsSection.h>
#import "CYLDetailsViewController.h"
#import <MJRefresh/MJRefresh.h>
#import "CYLDemoLocalization.h"

@implementation CYLMineViewController


- (instancetype)init {
    // [EN] Inset grouped sections with rounded corners, as in the Settings app.
    // [CN] 与系统“设置”App 相同的圆角分组（Inset Grouped）样式。
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [UITableViewCell cyl_setUpAutomaticRowHeightForTableView:self.tableView];
    NSLog(CYLDemoLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), self);

    self.view.backgroundColor = UIColor.systemBackgroundColor; // [EN] Dark Mode. [CN] 适配深色模式。


    // [CN] ✅ 关键代码：设置 NavigationBar 为白色背景（非透明）
    // [EN] ✅ Key code: give the NavigationBar a white (non-transparent) background
    if (@available(iOS 13.0, *)) {
        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
        [appearance configureWithOpaqueBackground];   // [CN] ⚠️ 非透明关键
        // [EN] ⚠️ Key to being non-transparent
//        appearance.backgroundColor = [UIColor whiteColor];
        appearance.backgroundColor = [UIColor cyl_systemBackgroundColor];

        appearance.titleTextAttributes = @{
            NSForegroundColorAttributeName : [UIColor cyl_labelColor]
        };

        self.navigationController.navigationBar.standardAppearance = appearance;
        self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
        self.navigationController.navigationBar.compactAppearance = appearance;
    } else {
        // [CN] iOS 12 及以下
        // [EN] iOS 12 and below
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
        // [CN] 触发暗黑模式切换， 会引起 tabBar 的 重新布局 ，可以用来测试常见的 tabBar 布局bug
        // [EN] Triggers a dark mode switch, which relayouts the tabBar; useful for testing common tabBar layout bugs
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
    // [EN] The badge sample is the title, the page the subtitle; both wrap.
    // [CN] 角标样例为主标题，页面为副标题；均可换行。
    cell.textLabel.text = [UITableViewCell cyl_badgeTitleForRow:indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:CYLDemoLocalizedString(@"%@ CYLTabBarController on iOS %@"), self.title, @([[[UIDevice currentDevice] systemVersion] floatValue])];
    [cell cyl_wrapsTextLabels];
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < [self cyl_demoSectionCount]) {
        return [self cyl_demoCellForTableView:tableView indexPath:indexPath];
    }
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

// Section 0: settings (language, memory warning). 第 0 组：设置（语言、内存警告）。
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // [EN] The grouped demo sections (shared with the FlatDesign page), then this page's rows.
    // [CN] 分组的演示 section（与扁平样式页面共用），然后是本页面的行。
    return [self cyl_demoSectionCount] + 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section < [self cyl_demoSectionCount] ? [self cyl_demoTitleForSection:section] : CYLDemoLocalizedString(@"角标");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < [self cyl_demoSectionCount]) {
        return [self cyl_demoRowCountInSection:section];
    }
    return MAX(30, [UITableViewCell cyl_badgeStyleCount]); // every badge style has a row
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < [self cyl_demoSectionCount]) {
        [self cyl_demoDidSelectRowAtIndexPath:indexPath inTableView:tableView];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
// [CN] 展示红点
// [EN] Show the red dot
    [self cyl_setBadgeCenterOffset:CGPointZero];

    [self cyl_showBadgeValue:[NSString stringWithFormat:@"%@", @(indexPath.row)] animationType:CYLBadgeAnimationTypeNone];
    [self testPush];
}

- (void)testPush {
    CYLBaseViewController *viewController = [[CYLBaseViewController alloc] init];
    viewController.view.backgroundColor = [UIColor redColor];
    [viewController cyl_setDisablePopGestureRecognizer:YES];
    [self.navigationController pushViewController:viewController animated:YES];
}

@end

