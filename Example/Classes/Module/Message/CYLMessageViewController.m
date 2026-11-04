//
//  CYLMessageViewController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLMessageViewController.h"
#import <CYLTabBarController/UITableViewCell+CYLBadgeExtention.h>
#import <CYLTabBarController/UIViewController+CYLSettingsSection.h>
#import "CYLMainRootViewController.h"
#import "CYLPlusButtonSubclass.h"
#import "MainTabBarController.h"
#import <MJRefresh/MJRefresh.h>

@implementation CYLMessageViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [UITableViewCell cyl_setUpAutomaticRowHeightForTableView:self.tableView];
    NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), self);

    self.view.backgroundColor = [UIColor whiteColor];
//    self.navigationItem.title = @"消息";    //✅sets navigation bar title.The right way to set the title of the navigation
//    self.tabBarItem.title = @"消息";   //❌sets tab bar title. Even the `tabBarItem.title` changed, this will be ignored in tabbar.
    //self.title = @"消息1";                //❌sets both of these. Do not do this‼️‼️ This may cause something strange
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.navigationItem.leftBarButtonItem cyl_showBadge];
}

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [cell cyl_showBadgeForRow:indexPath.row];
    // [EN] An action row shows the action as its title; the other rows the badge sample, the page as the subtitle.
    //      Both wrap.
    // [CN] 操作行以操作为主标题；其余行以角标样例为主标题、页面为副标题。均可换行。
    [cell cyl_wrapsTextLabels];
    if (0 == indexPath.row) {
        // [EN] Pushes a tab bar controller of the SAME context, see `-tableView:didSelectRowAtIndexPath:`.
        // [CN] 推入同一个 context 的 TabBarController，见 `-tableView:didSelectRowAtIndexPath:`。
        cell.textLabel.text = CYLLocalizedString(@"Push 同一个 context 的 TabBarController（同一个 PlusButton 类）");
        cell.detailTextLabel.text = [UITableViewCell cyl_badgeTitleForRow:indexPath.row];
        return;
    }
    if (1 == indexPath.row) {
        // [EN] Issue #202: pushes a tab bar controller whose plus button has a tappable X subview.
        // [CN] 推入一个 TabBarController，其 PlusButton 带有可点击的 X 子按钮。
        [[cell textLabel] setText:CYLLocalizedString(@"Push 新 context 的 TabBarController（PlusButton 带可点击的 X 子按钮，issue #202）")];
        cell.detailTextLabel.text = CYLLocalizedString(@"点击 PlusButton 右上角的 X：X 随机改变颜色，PlusButton 不响应");
        return;
    }
    cell.textLabel.text = [UITableViewCell cyl_badgeTitleForRow:indexPath.row];
    cell.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"%@ CYLTabBarController on iOS %@"), self.title, @([[[UIDevice currentDevice] systemVersion] floatValue])];
}

#pragma mark - Table view

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == CYLSettingsSection) {
        return [self cyl_settingsCellForTableView:tableView atIndexPath:indexPath];
    }
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    [self configureCell:cell forIndexPath:indexPath];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == CYLSettingsSection) {
        [self cyl_didSelectSettingsRowAtIndexPath:indexPath inTableView:tableView];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    NSNumber *badgeNumber = @(indexPath.row);
//    self.navigationItem.title = [NSString stringWithFormat:@"首页(%@)", badgeNumber]; //sets navigation bar title.
    
    //    [self.navigationController.tabBarItem setBadgeValue:[NSString stringWithFormat:@"%@", badgeNumber]];
    
    //    CYLTabBarControllerConfig *tabBarControllerConfig = [[CYLTabBarControllerConfig alloc] init];
    //    CYLTabBarController *tabBarController = tabBarControllerConfig.tabBarController;
    //    tabBarController.delegate = self;
    //
    //    [self cyl_showBadgeValue:[NSString stringWithFormat:@"%@", @(indexPath.row)] animationType:CYLBadgeAnimationTypeScale];
    //    [self pushToNewViewController];

    // Same logic as the plus button's "Switch Style" menu: a tab bar controller that shows the OTHER plus button (another
    // context). The tab bar controller we push from keeps its own, both are registered at the same time.
    // 与 PlusButton“切换样式”菜单相同的逻辑：push 一个显示 **另一个** PlusButton（另一个 context）的 TabBarController。
    // 当前的 TabBarController 保留自己的 PlusButton，两个同时注册。
    MainTabBarController *tabBarController = nil;
    if (0 == indexPath.row) {
        // A tab bar controller with the SAME context as the one we push from, without registering again: it gets its
        // own instance of the same plus button class, and the one we push from keeps its plus button.
        // 与当前 TabBarController **相同** context 的 TabBarController，不重新注册：它得到同一个 PlusButton 类的另一个实例，
        // 当前的 TabBarController 保留自己的 PlusButton。
        tabBarController = [[MainTabBarController alloc] initWithContext:self.cyl_tabBarController.cyl_context];
        tabBarController.allowsVerticalBar = YES;
    } else if (1 == indexPath.row) {
        // [EN] Issue #202: a new context with `CYLCloseSubviewPlusButtonSubclass`; the other plus buttons stay registered.
        // [CN] Issue #202：新的 context，使用 `CYLCloseSubviewPlusButtonSubclass`；其他 PlusButton 保持注册。
        tabBarController = [CYLMainRootViewController newLiquidGlassTabBarControllerWithPlusButtonClass:[CYLCloseSubviewPlusButtonSubclass class]];
    } else {
        Class plusButtonClass = [CYLPlusButtonSubclass alternatePlusButtonClassForOwner:self];
        tabBarController = [CYLMainRootViewController newLiquidGlassTabBarControllerWithPlusButtonClass:plusButtonClass];
    }
    tabBarController.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:tabBarController animated:YES];
}

// Section 0: settings (language, memory warning). 第 0 组：设置（语言、内存警告）。
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == CYLSettingsSection) {
        return [self cyl_settingsRowCount];
    }
    return MAX(15, [UITableViewCell cyl_badgeStyleCount]); // every badge style has a row
}

@end
