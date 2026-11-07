//
//  HomeViewController.m
//  WYWTabBar
//
//  Created by weiyanwu on 2026/4/17.
//

#import "HomeViewController.h"
#import "SceneDelegate.h"

@interface HomeViewController ()

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    // [EN] The network icons and the title update in both styles.
    // [CN] 网络图标与标题更新在两种样式下都可用。
    UISegmentedControl *styleControl = [[UISegmentedControl alloc] initWithItems:@[CYLLocalizedString(@"LiquidGlass"),
                                                                                   CYLLocalizedString(@"FlatDesign")]];
    styleControl.selectedSegmentIndex = (CYLTabBarStyleTypeFlatDesign == self.cyl_owningTabBarController.tabBarStyleType) ? 1 : 0;
    [styleControl addTarget:self action:@selector(styleChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = styleControl;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UISegmentedControl *styleControl = (UISegmentedControl *)self.navigationItem.titleView;
    styleControl.selectedSegmentIndex = (CYLTabBarStyleTypeFlatDesign == self.cyl_owningTabBarController.tabBarStyleType) ? 1 : 0;
}

- (void)styleChanged:(UISegmentedControl *)styleControl {
    CYLTabBarStyleType styleType = (styleControl.selectedSegmentIndex == 1) ? CYLTabBarStyleTypeFlatDesign : CYLTabBarStyleTypeLiquidGlass;
    [(SceneDelegate *)self.view.window.windowScene.delegate showTabBarControllerWithStyle:styleType];
}

@end
