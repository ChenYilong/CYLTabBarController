//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignTableViewController.h"
#import <objc/runtime.h>
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


@end

@implementation CYLFlatDesignTableViewController


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
    self.navigationItem.title = self.title; //✅sets navigation bar title.The right way to set the title of the navigation
    //    self.tabBarItem.title = @"首页";   //❌sets tab bar title. Even the `tabBarItem.title` changed, this will be ignored in tabbar.
    //self.title = @"首页1";                //❌sets both of these. Do not do this‼️‼️This may cause something strange  .
    //    [self.navigationController.tabBarItem setBadgeValue:@"3"];
    //    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshTabBar:)];
    //    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
    
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:CYLLocalizedString(@"FlatDesign") style:UIBarButtonItemStylePlain target:self action:@selector(flatDesignTabBar:)];
    // [CN] leftBarButtonItem.tintColor = UIColor.redColor; // 确保使用原图色
    // [EN] leftBarButtonItem.tintColor = UIColor.redColor; // Make sure the original image color is used
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

// [EN] The grouped demo sections (shared with the Liquid Glass pages), then the badge rows.
// [CN] 分组的演示 section（与液态玻璃页面共用），然后是角标行。
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self cyl_demoSectionCount] + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < [self cyl_demoSectionCount]) {
        return [self cyl_demoRowCountInSection:section];
    }
    return 50;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section < [self cyl_demoSectionCount] ? [self cyl_demoTitleForSection:section] : CYLLocalizedString(@"角标");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < [self cyl_demoSectionCount]) {
        return [self cyl_demoCellForTableView:tableView indexPath:indexPath];
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    // [EN] The badge sample is the title, the page the subtitle, as in the other demos.
    // [CN] 与其他演示一致，以角标样例为主标题、页面为副标题。
    cell.textLabel.text = [UITableViewCell cyl_badgeTitleForRow:indexPath.row];
    cell.detailTextLabel.text = [NSString localizedStringWithFormat:CYLLocalizedString(@"%@ CYLTabBarController on iOS %@"), self.title, @([[[UIDevice currentDevice] systemVersion] floatValue])];
    [cell cyl_wrapsTextLabels];
    [cell cyl_showBadgeForRow:indexPath.row];
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < [self cyl_demoSectionCount]) {
        [self cyl_demoDidSelectRowAtIndexPath:indexPath inTableView:tableView];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UIViewController *vc = [[UIViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    vc.cyl_hidesBottomBarWhenPushed = YES;
    vc.view.backgroundColor = UIColor.systemBackgroundColor;
    [self.navigationController pushViewController:vc animated:YES];
}

@end

#pragma mark - CYLTabBarDemoSection

typedef NS_ENUM(NSInteger, CYLTabBarDemoRow) {
    CYLTabBarDemoRowShowHideTabBar,
    CYLTabBarDemoRowItemNotCentered,
    CYLTabBarDemoRowItemCentered,
    CYLTabBarDemoRowItemBackgroundColor,
    CYLTabBarDemoRowTabBarHeight,
    CYLTabBarDemoRowCompareSystemTabBar,
    CYLTabBarDemoRowPushSystemStyle,
    CYLTabBarDemoRowPushFlatDesign,
    CYLTabBarDemoRowPopPushDemo,
    CYLTabBarDemoRowCount,
};

static char CYLTabBarDemoItemTitleKey;

@implementation UIViewController (CYLTabBarDemoSection)

- (NSInteger)cyl_tabBarDemoRowCount {
    return CYLTabBarDemoRowCount;
}

/// [EN] The tab bar controller of this page. [CN] 当前页面所在的 TabBarController。
- (CYLTabBarController *)cyl_tabBarDemoTabBarController {
    return [self cyl_owningTabBarController] ?: [self cyl_tabBarController];
}

/*!
 * [EN] Whether the current tab bar supports `row`: the item layout and background rows need FlatDesign tab items
 *      (`CYLFlatDesignTabBarItem`); with Liquid Glass or the classic style the system draws the tab items.
 * [CN] 当前 TabBar 是否支持 `row`：item 布局与背景行需要扁平样式的 item（`CYLFlatDesignTabBarItem`）；液态玻璃与经典样式的 item 由
 *      系统绘制。
 */
- (BOOL)cyl_isTabBarDemoRowSupported:(NSInteger)row {
    // [EN] Liquid Glass sizes its tab bar itself: `tabBarHeight` applies to FlatDesign and the classic style.
    // [CN] 液态玻璃的 TabBar 高度由系统决定：`tabBarHeight` 适用于扁平样式与经典样式。
    if (row == CYLTabBarDemoRowTabBarHeight) {
        return [self cyl_tabBarDemoTabBarController].tabBarStyleType == CYLTabBarStyleTypeFlatDesign || ![CYLConstants isLiquidGlassActive];
    }
    BOOL needsFlatDesign = (row == CYLTabBarDemoRowItemNotCentered || row == CYLTabBarDemoRowItemCentered ||
                            row == CYLTabBarDemoRowItemBackgroundColor);
    if (!needsFlatDesign) {
        return YES;
    }
#if CYL_FLATDESIGN_AVAILABLE
    CYLTabBarController *tabBarController = [self cyl_tabBarDemoTabBarController];
    return tabBarController.tabBarStyleType == CYLTabBarStyleTypeFlatDesign &&
           ![self.cylflatdesign_tabBarController isKindOfClass:[CYLFlatDesignSystemTabBarController class]];
#else
    return NO;
#endif
}

- (UITableViewCell *)cyl_tabBarDemoCellForTableView:(UITableView *)tableView row:(NSInteger)row {
    static NSString *const identifier = @"CYLTabBarDemoCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
    }
    NSString *title = nil;
    NSString *symbolName = nil;
    BOOL pushes = NO;
    switch (row) {
        case CYLTabBarDemoRowShowHideTabBar:
            title = CYLLocalizedString(@"Show / hide CYLFlatDesignTabBar");
            symbolName = @"eye";
            break;
        case CYLTabBarDemoRowItemNotCentered:
            title = CYLLocalizedString(@"Change CYLFlatDesignTabBarItem 不居中显示（系统效果）");
            symbolName = @"text.alignleft";
            break;
        case CYLTabBarDemoRowItemCentered:
            title = CYLLocalizedString(@"Change CYLFlatDesignTabBarItem 居中显示");
            symbolName = @"text.aligncenter";
            break;
        case CYLTabBarDemoRowItemBackgroundColor:
            title = CYLLocalizedString(@"设置 CYLFlatDesignTabBarItem 背景色");
            symbolName = @"paintbrush";
            break;
        case CYLTabBarDemoRowTabBarHeight:
            title = CYLLocalizedString(@"改变 CYLFlatDesignTabBar 高度");
            symbolName = @"arrow.up.and.down";
            break;
        case CYLTabBarDemoRowCompareSystemTabBar:
            title = CYLLocalizedString(@"和系统 UITabBar 比较");
            symbolName = @"rectangle.split.2x1";
            pushes = YES;
            break;
        case CYLTabBarDemoRowPushSystemStyle:
            title = CYLLocalizedString(@"Push To 系统 UITabBarController（另一个 PlusButton）");
            symbolName = @"square.stack";
            pushes = YES;
            break;
        case CYLTabBarDemoRowPushFlatDesign:
            title = CYLLocalizedString(@"Push To 另一个 CYLFlatDesignTabBarController（另一个 PlusButton）");
            symbolName = @"square.stack.3d.up";
            pushes = YES;
            break;
        default:
            title = CYLLocalizedString(@"cyl_pop / cyl_push 系列方法演示");
            symbolName = @"arrow.uturn.left";
            pushes = YES;
            break;
    }
    BOOL supported = [self cyl_isTabBarDemoRowSupported:row];
    cell.textLabel.text = title;
    cell.detailTextLabel.text = supported ? nil : (row == CYLTabBarDemoRowTabBarHeight ?
        CYLLocalizedString(@"液态玻璃不支持：TabBar 高度由系统决定（扁平样式与经典样式支持）") :
        CYLLocalizedString(@"当前 TabBar 样式不支持：仅扁平样式（CYLFlatDesignTabBar）支持"));
    cell.imageView.image = [UIImage systemImageNamed:symbolName];
    cell.accessoryType = pushes ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    [cell cyl_wrapsTextLabels];
    cell.textLabel.textColor = supported ? UIColor.labelColor : UIColor.secondaryLabelColor;
    return cell;
}

- (void)cyl_didSelectTabBarDemoRow:(NSInteger)row inTableView:(UITableView *)tableView {
    if (![self cyl_isTabBarDemoRowSupported:row]) {
        NSString *message = (row == CYLTabBarDemoRowTabBarHeight) ?
            CYLLocalizedString(@"液态玻璃不支持：TabBar 高度由系统决定（扁平样式与经典样式支持）") :
            CYLLocalizedString(@"该功能需要扁平样式的 TabBarItem（CYLFlatDesignTabBarItem）。液态玻璃与经典样式的 TabBarItem 由系统绘制，不支持修改布局与背景色。");
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:CYLLocalizedString(@"当前 TabBar 样式不支持")
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"OK") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    CYLTabBarController *tabBarController = [self cyl_tabBarDemoTabBarController];
    switch (row) {
        case CYLTabBarDemoRowShowHideTabBar: {
            [tabBarController setTabBarHidden:!tabBarController.isTabBarHidden animated:YES];
            break;
        }
#if CYL_FLATDESIGN_AVAILABLE
        case CYLTabBarDemoRowItemNotCentered:
        case CYLTabBarDemoRowItemCentered: {
            CYLFlatDesignTabBarItem *item = self.navigationController.cyl_tabBarItem;
            item.layoutCentered = (row == CYLTabBarDemoRowItemCentered);
            if (item.title) {
                objc_setAssociatedObject(self, &CYLTabBarDemoItemTitleKey, item.title, OBJC_ASSOCIATION_COPY_NONATOMIC);
                item.title = nil;
            } else {
                item.title = objc_getAssociatedObject(self, &CYLTabBarDemoItemTitleKey);
            }
            break;
        }
        case CYLTabBarDemoRowItemBackgroundColor:
            for (UIViewController *viewController in tabBarController.viewControllers) {
                BOOL isOn = (viewController.cyl_tabBarItem.backgroundColor != nil);
                viewController.cyl_tabBarItem.backgroundColor = isOn ? nil : [UIColor colorWithRed:0.18 green:0.18 blue:0.18 alpha:1.0];
                viewController.cyl_tabBarItem.selectedBackgroundColor = isOn ? nil : UIColor.blackColor;
            }
            break;
#endif
        case CYLTabBarDemoRowTabBarHeight:
            tabBarController.tabBarHeight += 10;
            if (tabBarController.tabBarHeight >= 100) {
                tabBarController.tabBarHeight = 49;
            }
            break;
        case CYLTabBarDemoRowCompareSystemTabBar:
            [self.navigationController pushViewController:[[CYLFlatDesignTabBarDemoViewController alloc] init] animated:YES];
            break;
        case CYLTabBarDemoRowPushSystemStyle: {
            // [EN] Same logic as the plus button's "Switch Style" menu: a tab bar controller with the OTHER plus button.
            // [CN] 与 PlusButton“切换样式”菜单相同：push 一个使用 **另一个** PlusButton 的 TabBarController。
            Class plusButtonClass = [CYLPlusButtonSubclass alternatePlusButtonClassForOwner:self];
            MainTabBarController *liquidGlassTabBarController = [CYLMainRootViewController newLiquidGlassTabBarControllerWithPlusButtonClass:plusButtonClass];
            liquidGlassTabBarController.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:liquidGlassTabBarController animated:YES];
            break;
        }
        case CYLTabBarDemoRowPushFlatDesign: {
            Class plusButtonClass = [CYLPlusButtonSubclass alternatePlusButtonClassForOwner:self];
            CYLFlatDesignMainTabBarController *flatDesignTabBarController = [CYLMainRootViewController newFlatDesignTabBarControllerWithPlusButtonClass:plusButtonClass];
            flatDesignTabBarController.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:flatDesignTabBarController animated:YES];
            break;
        }
        default: {
            // [EN] Every `cyl_pop…` / `cyl_push…` method, from a page pushed onto this tab's navigation stack.
            // [CN] 从 push 到当前 Tab 导航栈中的页面调用每一个 `cyl_pop…` / `cyl_push…` 方法。
            CYLPopPushDemoViewController *viewController = [[CYLPopPushDemoViewController alloc] init];
            viewController.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
    }
}

@end

#pragma mark - CYLDemoSections

/*!
 * [EN] One row of a demo section: a settings row of the library, or a tab bar demo row of this demo. Two kinds of row, each
 *      with its own index, instead of one number that encodes both.
 * [CN] 演示 section 中的一行：库的设置行，或本 Demo 的 TabBar 演示行。两种行各有自己的序号，而不是用一个数字同时表示两者。
 */
@interface CYLDemoRow : NSObject
@property (nonatomic, assign, readonly) BOOL isTabBarDemoRow;
@property (nonatomic, assign, readonly) NSInteger index;
+ (instancetype)settingsRow:(NSInteger)index;
+ (instancetype)tabBarDemoRow:(CYLTabBarDemoRow)index;
@end

@implementation CYLDemoRow

+ (instancetype)rowWithIndex:(NSInteger)index isTabBarDemoRow:(BOOL)isTabBarDemoRow {
    CYLDemoRow *row = [[self alloc] init];
    row->_index = index;
    row->_isTabBarDemoRow = isTabBarDemoRow;
    return row;
}

+ (instancetype)settingsRow:(NSInteger)index {
    return [self rowWithIndex:index isTabBarDemoRow:NO];
}

+ (instancetype)tabBarDemoRow:(CYLTabBarDemoRow)index {
    return [self rowWithIndex:index isTabBarDemoRow:YES];
}

@end

@implementation UIViewController (CYLDemoSections)

/*!
 * [EN] The sections: the library's settings groups (`-cyl_settingsGroups`), with this demo's tab bar rows added to the
 *      appearance group, and a last section for the navigation and comparison rows.
 * [CN] 各 section：使用库提供的设置分组（`-cyl_settingsGroups`），本 Demo 的 TabBar 演示行加入外观分组，最后一个 section 放跳转与对比的行。
 */
- (NSArray<NSDictionary *> *)cyl_demoSections {
    NSMutableArray<NSDictionary *> *sections = [NSMutableArray array];
    for (NSNumber *group in [self cyl_settingsGroups]) {
        CYLSettingsGroup settingsGroup = (CYLSettingsGroup)group.integerValue;
        NSMutableArray<CYLDemoRow *> *rows = [NSMutableArray array];
        for (NSNumber *row in [self cyl_settingsRowsInGroup:settingsGroup]) {
            [rows addObject:[CYLDemoRow settingsRow:row.integerValue]];
        }
        if (settingsGroup == CYLSettingsGroupTabBarAppearance) {
            // [EN] Show / hide, height, item layout and background color of the tab bar.
            // [CN] 显示 / 隐藏、高度、TabBarItem 布局与背景色。
            [rows addObjectsFromArray:@[ [CYLDemoRow tabBarDemoRow:CYLTabBarDemoRowShowHideTabBar],
                                         [CYLDemoRow tabBarDemoRow:CYLTabBarDemoRowTabBarHeight],
                                         [CYLDemoRow tabBarDemoRow:CYLTabBarDemoRowItemNotCentered],
                                         [CYLDemoRow tabBarDemoRow:CYLTabBarDemoRowItemCentered],
                                         [CYLDemoRow tabBarDemoRow:CYLTabBarDemoRowItemBackgroundColor] ]];
        }
        [sections addObject:@{ @"title" : [self cyl_titleForSettingsGroup:settingsGroup], @"rows" : rows }];
    }
    [sections addObject:@{ @"title" : CYLLocalizedString(@"跳转与对比"),
                           @"rows" : @[ [CYLDemoRow tabBarDemoRow:CYLTabBarDemoRowCompareSystemTabBar],
                                        [CYLDemoRow tabBarDemoRow:CYLTabBarDemoRowPushSystemStyle],
                                        [CYLDemoRow tabBarDemoRow:CYLTabBarDemoRowPushFlatDesign],
                                        [CYLDemoRow tabBarDemoRow:CYLTabBarDemoRowPopPushDemo] ] }];
    return sections;
}

- (CYLDemoRow *)cyl_demoRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self cyl_demoSections][indexPath.section][@"rows"][indexPath.row];
}

- (NSInteger)cyl_demoSectionCount {
    return (NSInteger)[self cyl_demoSections].count;
}

- (NSInteger)cyl_demoRowCountInSection:(NSInteger)section {
    return (NSInteger)[[self cyl_demoSections][section][@"rows"] count];
}

- (NSString *)cyl_demoTitleForSection:(NSInteger)section {
    return [self cyl_demoSections][section][@"title"];
}

- (UITableViewCell *)cyl_demoCellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    CYLDemoRow *row = [self cyl_demoRowAtIndexPath:indexPath];
    if (row.isTabBarDemoRow) {
        return [self cyl_tabBarDemoCellForTableView:tableView row:row.index];
    }
    return [self cyl_settingsCellForTableView:tableView row:row.index];
}

- (void)cyl_demoDidSelectRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    CYLDemoRow *row = [self cyl_demoRowAtIndexPath:indexPath];
    if (row.isTabBarDemoRow) {
        [self cyl_didSelectTabBarDemoRow:row.index inTableView:nil];
        return;
    }
    // [EN] Run the row, then reload the demo sections (e.g. the checkmarks). [CN] 执行该行，然后刷新演示 section（如勾号）。
    [self cyl_didSelectSettingsRow:row.index];
    if (tableView.window) {
        [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, (NSUInteger)[self cyl_demoSectionCount])]
                 withRowAnimation:UITableViewRowAnimationNone];
    }
}

@end
