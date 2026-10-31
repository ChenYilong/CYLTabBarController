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

@interface CYLHomeViewController ()
@property (nonatomic, strong) id<UIInteraction> bottomEdgeInteraction;
@end

@implementation CYLHomeViewController 

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), self);
    self.view.backgroundColor = [UIColor whiteColor];
//    self.navigationItem.title = @"首页"; //✅sets navigation bar title.The right way to set the title of the navigation
//    self.tabBarItem.title = @"首页";   //❌sets tab bar title. Even the `tabBarItem.title` changed, this will be ignored in tabbar.
    //self.title = @"首页1";                //❌sets both of these. Do not do this‼️‼️This may cause something strange  .
//    [self.navigationController.tabBarItem setBadgeValue:@"3"];
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(refreshTabBar:)];
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"home_normal"] style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
    
    UIBarButtonItem *leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"FlatDesign" style:UIBarButtonItemStylePlain target:self action:@selector(flatDesignTabBar:)];
//    leftBarButtonItem.tintColor = UIColor.redColor; // 确保使用原图色
    self.navigationItem.leftBarButtonItem = leftBarButtonItem;


    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"LiquidGlass" style:UIBarButtonItemStylePlain target:self action:@selector(refreshTabBar:)];
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"CYLTabBar" style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];

#define RANDOM_COLOR [UIColor colorWithHue: (arc4random() % 256 / 256.0) saturation:((arc4random()% 128 / 256.0 ) + 0.5) brightness:(( arc4random() % 128 / 256.0 ) + 0.5) alpha:1]
    [self.navigationItem.leftBarButtonItem cyl_setBadgeBackgroundColor:UIColor.redColor];

    [self.navigationItem.rightBarButtonItem cyl_setBadgeBackgroundColor:UIColor.redColor];
//    [self.navigationItem.leftBarButtonItem setTintColor:UIColor.blackColor];
//    [self.navigationItem.rightBarButtonItem setTintColor:UIColor.blackColor];

    [self.navigationItem.leftBarButtonItem cyl_setBadgeTextColor:UIColor.redColor];
    [self.navigationItem.rightBarButtonItem cyl_setBadgeTextColor:UIColor.redColor];

    

    

    [self.navigationItem.rightBarButtonItem cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
    //                [viewController0 cyl_setBadgeRadius:11/2];
    
    //以上对Badge的参数设置，需要在 cyl_showBadgeValue 调用之前执行。
    [self.navigationItem.rightBarButtonItem cyl_showBadge];
    [self.navigationItem.rightBarButtonItem cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeShake];
    [self.navigationItem.leftBarButtonItem cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeScaleOnce];

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

- (void)refreshTabBar:(id)sender {
    [self createNewTabBardynamically];
}

- (void)flatDesignTabBar:(id)sender {
    CYLMainRootViewController *rootController = (CYLMainRootViewController *)CYLGetRootViewController();
    [rootController createFlatDesignTabBar];
}

- (void)createNewTabBardynamically {
//    [CYLPlusButtonSubclass registerPlusButton];
    CYLMainRootViewController *rootController = (CYLMainRootViewController *)CYLGetRootViewController();
    [rootController createNewTabBarWithContext:NSStringFromClass([self class])];
}

#pragma mark - Methods

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    [[cell textLabel] setText:[NSString stringWithFormat:@"%@ CYLTabBarController on iOS %@", self.title, @([[[UIDevice currentDevice] systemVersion] floatValue])]];
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
