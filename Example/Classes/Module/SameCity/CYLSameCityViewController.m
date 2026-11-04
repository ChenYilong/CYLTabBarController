//
//  CYLSameCityViewController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLSameCityViewController.h"
#import "CYLFlatDesignTableViewController.h"
#import <CYLTabBarController/UITableViewCell+CYLBadgeExtention.h>
#import <CYLTabBarController/UIViewController+CYLSettingsSection.h>
#import "CYLDetailsViewController.h"
#import <MJRefresh/MJRefresh.h>

@implementation CYLSameCityViewController


- (instancetype)init {
    // [EN] Inset grouped sections with rounded corners, as in the Settings app.
    // [CN] 与系统“设置”App 相同的圆角分组（Inset Grouped）样式。
    return [super initWithStyle:UITableViewStyleInsetGrouped];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [UITableViewCell cyl_setUpAutomaticRowHeightForTableView:self.tableView];
    NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), self);

    self.view.backgroundColor = UIColor.systemBackgroundColor; // [EN] Dark Mode. [CN] 适配深色模式。
//    self.navigationItem.title = @"同城";    //✅sets navigation bar title.The right way to set the title of the navigation
//    self.tabBarItem.title = @"同城";   //❌sets tab bar title. Even the `tabBarItem.title` changed, this will be ignored in tabbar.
    //self.title = @"同城1";                //❌sets both of these. Do not do this‼️‼️ This may cause something strange
    
    __weak __typeof(self) weakSelf = self;
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
        //Call this Block When enter the refresh status automatically
        NSTimeInterval delaySeconds = 1;
        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
        dispatch_after(when, dispatch_get_main_queue(), ^{
            [weakSelf.tableView.mj_header endRefreshing];
        });
    }];
//    [self.view layoutIfNeeded];

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
    cell.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"%@ CYLTabBarController on iOS %@"), self.title, @([[[UIDevice currentDevice] systemVersion] floatValue])];
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
    return section < [self cyl_demoSectionCount] ? [self cyl_demoTitleForSection:section] : CYLLocalizedString(@"角标");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < [self cyl_demoSectionCount]) {
        return [self cyl_demoRowCountInSection:section];
    }
    return MAX(15, [UITableViewCell cyl_badgeStyleCount]); // every badge style has a row
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < [self cyl_demoSectionCount]) {
        [self cyl_demoDidSelectRowAtIndexPath:indexPath inTableView:tableView];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController *viewController = [[CYLDetailsViewController alloc] init];
//    viewController.hidesBottomBarWhenPushed = YES;  // This property needs to be set before pushing viewController to the navigationController's stack. Meanwhile as it is all base on CYLBaseNavigationController, there is no need to do this.
    [viewController cyl_setNavigationBarHidden:YES];
    [viewController cyl_setDisablePopGestureRecognizer:YES];

    [self.navigationController pushViewController:viewController animated:YES];
}

@end
