//
//  CYLSameCityViewController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLSameCityViewController.h"
#import <CYLTabBarController/UITableViewCell+CYLBadgeExtention.h>
#import <CYLTabBarController/CYLLocalization.h>
#import "CYLDetailsViewController.h"
#import <MJRefresh/MJRefresh.h>

@implementation CYLSameCityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = CYLBadgeRowHeight;
    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), self);

    self.view.backgroundColor = [UIColor whiteColor];
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
    cell.detailTextLabel.text = [UITableViewCell cyl_badgeTitleForRow:indexPath.row];
    [[cell textLabel] setText:[NSString stringWithFormat:CYLLocalizedString(@"%@ CYLTabBarController on iOS %@"), self.title, @([[[UIDevice currentDevice] systemVersion] floatValue])]];
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == CYLLanguageSettingSection) {
        return [self cyl_languageCellForTableView:tableView];
    }
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

// Section 0: the language setting. 第 0 组：语言设置。
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == CYLLanguageSettingSection) {
        return 1;
    }
    return MAX(15, [UITableViewCell cyl_badgeStyleCount]); // every badge style has a row
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == CYLLanguageSettingSection) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self cyl_presentLanguagePicker];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [CYLTabBarController cyl_simulateMemoryWarning]; // #426/#428: memory warning demo, see the log 内存警告演示，见日志
    UIViewController *viewController = [[CYLDetailsViewController alloc] init];
//    viewController.hidesBottomBarWhenPushed = YES;  // This property needs to be set before pushing viewController to the navigationController's stack. Meanwhile as it is all base on CYLBaseNavigationController, there is no need to do this.
    [viewController cyl_setNavigationBarHidden:YES];
    [viewController cyl_setDisablePopGestureRecognizer:YES];

    [self.navigationController pushViewController:viewController animated:YES];
}

@end
