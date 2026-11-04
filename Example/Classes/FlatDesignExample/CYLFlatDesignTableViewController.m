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

/// [EN] A row of a demo section: a settings row (`CYLDemoRowSettings`) or a tab bar demo row (`CYLDemoRowTabBar`).
/// [CN] 演示 section 中的一行：设置行（`CYLDemoRowSettings`）或 TabBar 演示行（`CYLDemoRowTabBar`）。
static const NSInteger CYLDemoRowTabBar = 1000;
/// [EN] A row of the theme list section: `CYLDemoRowTheme` + the theme's index (issue #216).
/// [CN] 主题列表 section 中的一行：`CYLDemoRowTheme` + 主题序号（issue #216）。
static const NSInteger CYLDemoRowTheme = 2000;

@implementation UIViewController (CYLDemoSections)

/*!
 * [EN] The sections, by function: each row is a settings row index, or `CYLDemoRowTabBar` + a tab bar demo row. The
 *      settings rows follow `UIViewController+CYLSettingsSection.m`: 0 language, 1 memory warning, 2 title offset,
 *      3 standardAppearance, 4 login state, 5 plus button touchable area, 6 selectedIndex (#515), 7 minimize / hide the
 *      tab bar on scroll (#13, next to the show / hide row), 8–18 issue #535 (8 tap animation, 9 long press, 10 swipe,
 *      11 outside the superview, 12 bundle images, 13 navigation bar without a base class, 14 slide transition, 15 tap
 *      sound and haptic, 16 long press / double tap timing, 17 adjacent tab, 18 CYLUtils helpers), 19 skin (theme, #216), then the tab item
 *      updates (title, icon, network icon, all network icons, all local icons, GIF, all titles, replace neighbors).
 *      Settings rows not listed here (a newer library) go to the first section.
 * [CN] 按功能分组的 section：每行为设置行的序号，或 `CYLDemoRowTabBar` + TabBar 演示行序号。设置行顺序见
 *      `UIViewController+CYLSettingsSection.m`（见上方英文）。此处未列出的设置行（更新的库）放在第一个 section。
 */
- (NSArray<NSDictionary *> *)cyl_demoSections {
    NSInteger update = [self cyl_settingsRowCount] - [self cyl_tabBarItemUpdateRowCount];
    NSMutableArray<NSDictionary *> *sections = [@[
        @{ @"title" : CYLLocalizedString(@"通用"), @"rows" : @[ @0, @1 ] },
        @{ @"title" : CYLLocalizedString(@"TabBar 外观"),
           @"rows" : @[ @2, @3, @19, @(CYLDemoRowTabBar + 0), @7, @(CYLDemoRowTabBar + 4), @(CYLDemoRowTabBar + 1),
                        @(CYLDemoRowTabBar + 2), @(CYLDemoRowTabBar + 3) ] },
        @{ @"title" : CYLLocalizedString(@"原地更新 Tab"),
           @"rows" : @[ @(update + 0), @(update + 1), @(update + 2), @(update + 3), @(update + 4), @(update + 5), @(update + 6) ] },
        @{ @"title" : CYLLocalizedString(@"Tab 页面、选中与登录"), @"rows" : @[ @(update + 7), @6, @4 ] },
        @{ @"title" : @"PlusButton", @"rows" : @[ @5 ] },
        // [EN] Issue #216: every skin, one row each (color themes and holiday skins).
        // [CN] Issue #216：所有皮肤，每行一个（配色主题与节日皮肤）。
        @{ @"title" : [self cyl_themeListSectionTitle], @"rows" : ({
            NSMutableArray<NSNumber *> *themeRows = [NSMutableArray array];
            for (NSInteger themeRow = 0; themeRow < [self cyl_themeListRowCount]; themeRow++) {
                [themeRows addObject:@(CYLDemoRowTheme + themeRow)];
            }
            themeRows;
        }) },
        // FIX: issue #535 — tap animation, tap sound and haptic, long press, long press / double tap timing, swipe,
        // switch to the adjacent tab, slide transition. 点击动画、点击声音与触感、长按、长按与双击时长、滑动、切换相邻 Tab、滑动转场。
        @{ @"title" : CYLLocalizedString(@"Tab 交互"), @"rows" : @[ @8, @15, @9, @16, @10, @17, @14 ] },
        // FIX: issue #535 — navigation bar without a base class, outside the superview, bundle images, CYLUtils helpers.
        // 不继承基类隐藏导航栏、超出父视图响应、bundle 图片、CYLUtils 工具方法。
        @{ @"title" : CYLLocalizedString(@"无需继承基类与工具方法"), @"rows" : @[ @13, @11, @12, @18 ] },
        @{ @"title" : CYLLocalizedString(@"跳转与对比"),
           @"rows" : @[ @(CYLDemoRowTabBar + 5), @(CYLDemoRowTabBar + 6), @(CYLDemoRowTabBar + 7), @(CYLDemoRowTabBar + 8) ] },
    ] mutableCopy];
    NSMutableSet<NSNumber *> *listed = [NSMutableSet set];
    for (NSDictionary *section in sections) {
        [listed addObjectsFromArray:section[@"rows"]];
    }
    NSMutableArray<NSNumber *> *general = [sections[0][@"rows"] mutableCopy];
    for (NSInteger row = 0; row < [self cyl_settingsRowCount]; row++) {
        if (![listed containsObject:@(row)]) {
            [general addObject:@(row)];
        }
    }
    sections[0] = @{ @"title" : sections[0][@"title"], @"rows" : general };
    return sections;
}

- (NSInteger)cyl_demoRowAtIndexPath:(NSIndexPath *)indexPath {
    return [[self cyl_demoSections][indexPath.section][@"rows"][indexPath.row] integerValue];
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
    NSInteger row = [self cyl_demoRowAtIndexPath:indexPath];
    if (row >= CYLDemoRowTheme) {
        return [self cyl_themeListCellForTableView:tableView row:row - CYLDemoRowTheme];
    }
    if (row >= CYLDemoRowTabBar) {
        return [self cyl_tabBarDemoCellForTableView:tableView row:row - CYLDemoRowTabBar];
    }
    return [self cyl_settingsCellForTableView:tableView atIndexPath:[NSIndexPath indexPathForRow:row inSection:CYLSettingsSection]];
}

- (void)cyl_demoDidSelectRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSInteger row = [self cyl_demoRowAtIndexPath:indexPath];
    if (row >= CYLDemoRowTheme) {
        [self cyl_didSelectThemeListRow:row - CYLDemoRowTheme];
        // [EN] The checkmarks of the list and the skin row follow the new theme. [CN] 列表勾号与换肤行随新主题更新。
        if (tableView.window) {
            [tableView reloadData];
        }
        return;
    }
    if (row >= CYLDemoRowTabBar) {
        [self cyl_didSelectTabBarDemoRow:row - CYLDemoRowTabBar inTableView:nil];
        return;
    }
    // [EN] The settings rows reload their own index paths in the settings section, which this grouped table does not
    //      have: run the row without the table view, then reload the demo sections (e.g. the checkmarks).
    // [CN] 设置行会刷新其在设置分组中的 indexPath，而分组后的列表中没有该分组：不传列表执行该行，然后刷新演示 section（如勾号）。
    [self cyl_didSelectSettingsRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:CYLSettingsSection] inTableView:(UITableView *_Nonnull)nil];
    if (tableView.window) {
        [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, (NSUInteger)[self cyl_demoSectionCount])]
                 withRowAnimation:UITableViewRowAnimationNone];
    }
}

@end
