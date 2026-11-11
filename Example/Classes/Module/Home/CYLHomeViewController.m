//
//  CYLHomeViewController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLHomeViewController.h"
#import "CYLFlatDesignTableViewController.h"
#import <CYLTabBarController/UITableViewCell+CYLBadgeExtention.h>
#import <CYLTabBarController/UIViewController+CYLSettingsSection.h>
//#import "CYLTabBarControllerConfig.h"
#import "CYLPlusButtonSubclass.h"
#import "MainTabBarController.h"
#import "CYLMainRootViewController.h"
#import "CYLGalleryViewController.h"
#import <MJRefresh/MJRefresh.h>
#import "CYLDemoLocalization.h"

@interface CYLHomeViewController ()
@property (nonatomic, strong) id<UIInteraction> bottomEdgeInteraction;
@end

@implementation CYLHomeViewController 

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    // [EN] `-CYLDemoGalleryScene 8.1`: opens the gallery once at launch, which then opens that scene (screenshots).
    // [CN] `-CYLDemoGalleryScene 8.1`：启动时打开一次图库，再由图库打开该场景（用于截图）。
    static BOOL opened = NO;
    if (!opened && [CYLGalleryViewController cyl_launchSceneNumber] && self.navigationController) {
        opened = YES;
        [self.navigationController pushViewController:[[CYLGalleryViewController alloc] init] animated:NO];
    }
}


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
    self.view.backgroundColor = UIColor.systemGroupedBackgroundColor; // [EN] The grouped background, so the rounded sections stand out. [CN] 分组背景色，使圆角分组清晰可见。
//    [self.navigationController.tabBarItem setBadgeValue:@"3"];
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshTabBar:)];
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
    
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:CYLDemoLocalizedString(@"FlatDesign") style:UIBarButtonItemStylePlain target:self action:@selector(flatDesignTabBar:)];
// [CN] leftBarButtonItem.tintColor = UIColor.redColor; // 确保使用原图色
// [EN] leftBarButtonItem.tintColor = UIColor.redColor; // Make sure the original image color is used
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;


    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:CYLDemoLocalizedString(@"LiquidGlass") style:UIBarButtonItemStylePlain target:self action:@selector(refreshTabBar:)];
    // [EN] Issue #216: the skin button opens the theme picker; the tab bar restyles in place in every style.
    // [CN] Issue #216：换肤按钮打开主题选择器，TabBar 在所有样式中原地更换外观。
    UIBarButtonItem *themeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:CYLDemoLocalizedString(@"换肤") style:UIBarButtonItemStylePlain target:self action:@selector(showThemePicker:)];
    self.navigationItem.rightBarButtonItems = @[ self.navigationItem.rightBarButtonItem, themeBarButtonItem ];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"CYLTabBar" style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];

//    [self.navigationItem.leftBarButtonItem setTintColor:UIColor.blackColor];
//    [self.navigationItem.rightBarButtonItem setTintColor:UIColor.blackColor];

    // #425: red background, text color and the (-5, 3) offset come from CYLBadgeAppearance (SceneDelegate.m
    // -setUpBadgeAppearance); a red dot has no text, so its text color never showed.
    // #425：红色背景和 (-5, 3) 偏移来自 CYLBadgeAppearance（SceneDelegate.m -setUpBadgeAppearance），无需逐个设置；
    // 红点没有文字，原先设置的文字颜色不会显示。
    //                [viewController0 cyl_setBadgeRadius:11/2];
    
    // Animated navigation item badges in a random color. 导航栏按钮的动画角标，使用随机颜色。
    [self.navigationItem.rightBarButtonItem cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeShake backgroundColor:UIColor.cyl_randomColor];
    [self.navigationItem.leftBarButtonItem cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeBreathe backgroundColor:UIColor.cyl_randomColor];

    if (CYL_IS_IOS_26) {
        if (@available(iOS 26.0, *)) {
            UIScrollEdgeElementContainerInteraction *interaction = [UIScrollEdgeElementContainerInteraction new];
            
            interaction.scrollView = self.tableView;
            interaction.edge = UIRectEdgeBottom;
            [self.cyl_tabBarController.tabBar addInteraction:interaction];
            self.bottomEdgeInteraction = interaction;
        } else {
            // Fallback on earlier versions
        }
        }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (@available(iOS 26.0, *)) {
        // FIX: issue #653 — on iOS 27.1 the folded iPhone Duo can show the tab bar as a vertical bar
        // (`allowsVerticalBar = YES`). The tab bar is then a full-height column on the trailing edge, so a
        // bottom-edge effect tied to it would blur the whole list. Only use it while the tab bar is horizontal.
        // iPhone Duo 折叠且 TabBar 为竖向栏时，TabBar 是整列高度，底部边缘效果会把整个列表模糊掉，因此只在横向时启用。
        UIScrollEdgeElementContainerInteraction *interaction = (UIScrollEdgeElementContainerInteraction *)self.bottomEdgeInteraction;
        CGSize tabBarSize = self.cyl_tabBarController.tabBar.bounds.size;
        BOOL isVerticalTabBar = tabBarSize.height > tabBarSize.width;
        UIScrollView *scrollView = isVerticalTabBar ? nil : self.tableView;
        if (interaction && interaction.scrollView != scrollView) {
            interaction.scrollView = scrollView;
        }
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

/// [EN] Issue #216: the skin (theme) picker. [CN] Issue #216：换肤（主题）选择器。
- (void)showThemePicker:(id)sender {
    __weak __typeof(self) weakSelf = self;
    [self cyl_presentThemePickerFromView:nil completion:^{
        [weakSelf.tableView reloadData];
    }];
}

- (void)refreshTabBar:(id)sender {
    [self createNewTabBardynamically];
}

- (void)flatDesignTabBar:(id)sender {
    CYLMainRootViewController *rootController = [CYLMainRootViewController currentRootViewController];
    [rootController createFlatDesignTabBar];
}

- (void)createNewTabBardynamically {
    // [EN] As the FlatDesign page's "Liquid Glass" button: the plus button is registered and the new tab bar uses its
    //      context. With this page's class as the context no plus button matched, so the new tab bar had none.
    // [CN] 与扁平样式页面的“Liquid Glass”按钮相同：注册 PlusButton，新 TabBar 使用其 context。以前使用本页面的类名作为 context，
    //      没有与之匹配的 PlusButton，因此新 TabBar 没有 PlusButton。
    [CYLPlusButtonSubclass registerPlusButton];
    CYLMainRootViewController *rootController = [CYLMainRootViewController currentRootViewController];
    [rootController createNewTabBarWithContext:NSStringFromClass([CYLTabBarController class])];
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
    if ([self isGallerySection:indexPath.section]) {
        UITableViewCell *galleryCell = [tableView dequeueReusableCellWithIdentifier:@"GalleryCell"] ?:
            [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"GalleryCell"];
        galleryCell.textLabel.text = CYLDemoLocalizedString(@"打开 TabBar 场景展示");
        galleryCell.detailTextLabel.text = CYLDemoLocalizedString(@"每个场景都是用公开 API 构建的 TabBar：样式、动画、提醒、Lottie 以及较新的 Tab API");
        [galleryCell cyl_wrapsTextLabels];
        galleryCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return galleryCell;
    }
    static NSString * CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
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
// Section 0: settings (language, memory warning). 第 0 组：设置（语言、内存警告）。
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // [EN] The grouped demo sections (shared with the FlatDesign page), then this page's rows.
    // [CN] 分组的演示 section（与扁平样式页面共用），然后是本页面的行。
    return [self cyl_demoSectionCount] + 2;
}

/// [EN] The section right after the shared demo sections opens the tab bar gallery (docs/Tab-Bar-Gallery.md).
/// [CN] 共用演示 section 之后的一组用于打开 TabBar 图库（docs/Tab-Bar-Gallery.md）。
- (BOOL)isGallerySection:(NSInteger)section {
    return section == [self cyl_demoSectionCount];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self isGallerySection:section]) {
        return @"Tab Bar Gallery";
    }
    return section < [self cyl_demoSectionCount] ? [self cyl_demoTitleForSection:section] : CYLDemoLocalizedString(@"角标");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < [self cyl_demoSectionCount]) {
        return [self cyl_demoRowCountInSection:section];
    }
    if ([self isGallerySection:section]) {
        return 1;
    }
    return MAX(30, [UITableViewCell cyl_badgeStyleCount]); // every badge style has a row
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < [self cyl_demoSectionCount]) {
        [self cyl_demoDidSelectRowAtIndexPath:indexPath inTableView:tableView];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self isGallerySection:indexPath.section]) {
        [self.navigationController pushViewController:[[CYLGalleryViewController alloc] init] animated:YES];
        return;
    }
    NSNumber *badgeNumber = @(indexPath.row);
    self.navigationItem.title = [NSString stringWithFormat:CYLDemoLocalizedString(@"首页(%@)"), badgeNumber]; //sets navigation bar title.
    
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
