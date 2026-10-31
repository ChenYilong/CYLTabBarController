//
//  CYLPopPushDemoViewController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPopPushDemoViewController.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

typedef void (^CYLPopPushDemoAction)(void);

@interface CYLPopPushDemoRow : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *detail;
@property (nonatomic, copy) CYLPopPushDemoAction action;
@end

@implementation CYLPopPushDemoRow
+ (instancetype)rowWithTitle:(NSString *)title detail:(NSString *)detail action:(CYLPopPushDemoAction)action {
    CYLPopPushDemoRow *row = [[self alloc] init];
    row.title = title;
    row.detail = detail;
    row.action = action;
    return row;
}
@end

/// Another class, to show that `-cyl_pushViewController:animated:` only skips a page of the same class as the top one.
/// 另一个类：用于演示 `-cyl_pushViewController:animated:` 只会忽略与栈顶同类型的页面。
@interface CYLPopPushDemoOtherViewController : UIViewController
@end

@implementation CYLPopPushDemoOtherViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemTealColor];
    self.navigationItem.title = @"另一个类型的页面";
}
@end

@interface CYLPopPushDemoViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSArray<CYLPopPushDemoRow *> *> *sections;
@property (nonatomic, copy) NSArray<NSString *> *sectionTitles;
@end

@implementation CYLPopPushDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // The tab bar controller, the tabs and the stack depth may have changed while this page was not visible.
    // 本页面不可见时，TabBarController、Tab 和栈深度都可能已经改变。
    NSUInteger level = [self.navigationController.viewControllers indexOfObject:self];
    self.navigationItem.title = [NSString stringWithFormat:@"cyl_pop / cyl_push（第 %@ 层）", @(level)];
    [self reloadRows];
}

#pragma mark - Rows

- (CYLTabBarController *)demoTabBarController {
    // Any style, flat design included. `-cyl_tabBarController` alone only finds the system styles.
    // 任意样式（包括扁平样式）。只用 `-cyl_tabBarController` 只能找到系统样式。
    return [self cyl_owningTabBarController] ?: [self cyl_tabBarController];
}

- (NSString *)titleOfTabAtIndex:(NSUInteger)index {
    NSArray<UIViewController *> *viewControllers = [self demoTabBarController].viewControllers;
    if (index >= viewControllers.count) {
        return @"不存在";
    }
    UIViewController *viewController = viewControllers[index];
    return viewController.tabBarItem.title ?: viewController.title ?: NSStringFromClass([viewController class]);
}

- (void)reloadRows {
    __weak __typeof(self) weakSelf = self;
    NSUInteger lastIndex = MAX([self demoTabBarController].viewControllers.count, 1) - 1;
    NSString *lastTitle = [self titleOfTabAtIndex:lastIndex];
    NSString *secondTitle = [self titleOfTabAtIndex:1];
    // The class of the last tab's root view controller: `ForClassType` selects the FIRST tab of that class.
    // 最后一个 Tab 的根控制器类型：`ForClassType` 选中的是该类型的 **第一个** Tab。
    UIViewController *lastRoot = [[self demoTabBarController].viewControllers.lastObject cyl_getViewControllerInsteadOfNavigationController];
    Class classType = [lastRoot class] ?: [UIViewController class];
    NSUInteger classIndex = 0;
    for (UIViewController *viewController in [self demoTabBarController].viewControllers) {
        if ([[viewController cyl_getViewControllerInsteadOfNavigationController] isKindOfClass:classType]) { break; }
        classIndex++;
    }

    NSArray<CYLPopPushDemoRow *> *popSelectRows = @[
        [CYLPopPushDemoRow rowWithTitle:@"cyl_popSelectTabBarChildViewControllerAtIndex:"
                                 detail:[NSString stringWithFormat:@"Pop 当前导航栈到栈底，并选中「%@」（index %@），无动画", lastTitle, @(lastIndex)]
                                 action:^{ [weakSelf cyl_popSelectTabBarChildViewControllerAtIndex:lastIndex]; }],
        [CYLPopPushDemoRow rowWithTitle:@"…AtIndex:animated:"
                                 detail:[NSString stringWithFormat:@"同上，选中「%@」（index 1），带 pop 动画", secondTitle]
                                 action:^{ [weakSelf cyl_popSelectTabBarChildViewControllerAtIndex:1 animated:YES]; }],
        [CYLPopPushDemoRow rowWithTitle:@"…AtIndex:completion:"
                                 detail:[NSString stringWithFormat:@"选中「%@」，并在 completion 中向该 Tab push 一个新的演示页", lastTitle]
                                 action:^{
            [weakSelf cyl_popSelectTabBarChildViewControllerAtIndex:lastIndex completion:^(__kindof UIViewController *selectedTabBarChildViewController) {
                CYLPopPushDemoViewController *next = [[CYLPopPushDemoViewController alloc] init];
                next.hidesBottomBarWhenPushed = YES;
                [selectedTabBarChildViewController.navigationController pushViewController:next animated:YES];
            }];
        }],
        [CYLPopPushDemoRow rowWithTitle:@"…ForClassType:"
                                 detail:[NSString stringWithFormat:@"选中第一个类型为 %@ 的 Tab（「%@」，index %@）", NSStringFromClass(classType), [self titleOfTabAtIndex:classIndex], @(classIndex)]
                                 action:^{ [weakSelf cyl_popSelectTabBarChildViewControllerForClassType:classType]; }],
        [CYLPopPushDemoRow rowWithTitle:@"…ForClassType:completion:"
                                 detail:@"同上，并在 completion 中向该 Tab push 一个新的演示页"
                                 action:^{
            [weakSelf cyl_popSelectTabBarChildViewControllerForClassType:classType completion:^(__kindof UIViewController *selectedTabBarChildViewController) {
                CYLPopPushDemoViewController *next = [[CYLPopPushDemoViewController alloc] init];
                next.hidesBottomBarWhenPushed = YES;
                [selectedTabBarChildViewController.navigationController pushViewController:next animated:YES];
            }];
        }],
        [CYLPopPushDemoRow rowWithTitle:@"…AtIndex:99（无效 index）"
                                 detail:@"返回 nil：不 pop、不切换 Tab"
                                 action:^{
            UIViewController *selected = [weakSelf cyl_popSelectTabBarChildViewControllerAtIndex:99];
            [weakSelf showMessage:[NSString stringWithFormat:@"返回值：%@", selected ?: @"nil"]];
        }],
    ];

    NSArray<CYLPopPushDemoRow *> *pushRows = @[
        [CYLPopPushDemoRow rowWithTitle:@"pushViewController:animated:（普通 push）"
                                 detail:@"再 push 一层演示页，用来加深导航栈"
                                 action:^{
            CYLPopPushDemoViewController *next = [[CYLPopPushDemoViewController alloc] init];
            next.hidesBottomBarWhenPushed = YES;
            [weakSelf.navigationController pushViewController:next animated:YES];
        }],
        [CYLPopPushDemoRow rowWithTitle:@"cyl_pushViewController:（与栈顶同类型）"
                                 detail:@"栈顶已经是演示页，push 另一个演示页会被忽略，防止重复 push"
                                 action:^{
            NSUInteger count = weakSelf.navigationController.viewControllers.count;
            CYLPopPushDemoViewController *next = [[CYLPopPushDemoViewController alloc] init];
            next.hidesBottomBarWhenPushed = YES;
            [weakSelf cyl_pushViewController:next animated:YES];
            if (weakSelf.navigationController.viewControllers.count == count) {
                [weakSelf showMessage:@"已忽略：栈顶已是同类型页面"];
            }
        }],
        [CYLPopPushDemoRow rowWithTitle:@"cyl_pushViewController:（不同类型）"
                                 detail:@"push 一个不同类型的页面，正常 push"
                                 action:^{
            CYLPopPushDemoOtherViewController *other = [[CYLPopPushDemoOtherViewController alloc] init];
            other.hidesBottomBarWhenPushed = YES;
            [weakSelf cyl_pushViewController:other animated:YES];
        }],
        [CYLPopPushDemoRow rowWithTitle:@"cyl_pushOrPopToViewController:（栈中有同类型时 Pop）"
                                 detail:@"栈中已有演示页时，Pop 回最早的那个；否则 push 一个新的演示页"
                                 action:^{
            CYLPopPushDemoViewController *next = [[CYLPopPushDemoViewController alloc] init];
            next.hidesBottomBarWhenPushed = YES;
            [weakSelf cyl_pushOrPopToViewController:next animated:YES callback:^(NSArray<__kindof UIViewController *> *viewControllers, CYLPushOrPopCompletionHandler completionHandler) {
                completionHandler(viewControllers.count > 0, viewControllers.firstObject, NO, 0);
            }];
        }],
        [CYLPopPushDemoRow rowWithTitle:@"cyl_pushOrPopToViewController:（切换 Tab 后 Push）"
                                 detail:[NSString stringWithFormat:@"Pop 当前导航栈、选中「%@」，再向该 Tab push 一个新的演示页", lastTitle]
                                 action:^{
            CYLPopPushDemoViewController *next = [[CYLPopPushDemoViewController alloc] init];
            next.hidesBottomBarWhenPushed = YES;
            [weakSelf cyl_pushOrPopToViewController:next animated:YES callback:^(NSArray<__kindof UIViewController *> *viewControllers, CYLPushOrPopCompletionHandler completionHandler) {
                completionHandler(NO, nil, YES, lastIndex);
            }];
        }],
    ];

    self.sections = @[popSelectRows, pushRows];
    self.sectionTitles = @[@"Pop & Select（Pop 到栈底并切换 Tab）", @"Push（防重复 Push / Push 或 Pop）"];
    [self.tableView reloadData];
}

- (void)showMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.sections[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionTitles[section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"row"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"row"];
        cell.textLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        cell.textLabel.textColor = [UIColor systemBlueColor];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:12];
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
        cell.detailTextLabel.numberOfLines = 0;
    }
    CYLPopPushDemoRow *row = self.sections[indexPath.section][indexPath.row];
    cell.textLabel.text = row.title;
    cell.detailTextLabel.text = row.detail;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CYLPopPushDemoRow *row = self.sections[indexPath.section][indexPath.row];
    !row.action ?: row.action();
}

@end
