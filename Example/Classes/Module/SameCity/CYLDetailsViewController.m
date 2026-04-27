//
//  CYLDetailsViewController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLDetailsViewController.h"
#import "CYLMineViewController.h"
#import "CYLSameCityViewController.h"
#import "CYLHomeViewController.h"
@interface CYLDetailsViewController ()

@end

@implementation CYLDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.title = @"详情页";
    self.view.backgroundColor = [UIColor orangeColor];
    
    UILabel *label = [[UILabel alloc] init];
    label.text = @"点击屏幕可跳转到“我的”，执行testPush";
    label.frame = CGRectMake(20, 150, CGRectGetWidth(self.view.frame) - 2 * 20, 20);
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.textAlignment = NSTextAlignmentCenter;
    [self.view addSubview:label];
//    [[self cyl_sharedAppDelegate] cyl_forceUpdateInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
//    self.navigationItem.backBarButtonItem;
    [self.navigationItem.backBarButtonItem cyl_setBadgeBackgroundColor:UIColor.redColor];
    [self.navigationItem.backBarButtonItem cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
    //                [viewController0 cyl_setBadgeRadius:11/2];
    //以上对Badge的参数设置，需要在 cyl_showBadgeValue 调用之前执行。
    [self.navigationItem.backBarButtonItem cyl_showBadge];
    [self.navigationItem.backBarButtonItem cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeScale];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[self cyl_sharedAppDelegate] cyl_forceUpdateInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[self cyl_sharedAppDelegate] cyl_forceUpdateInterfaceOrientation:UIInterfaceOrientationPortrait];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//     [self cyl_popSelectTabBarChildViewControllerAtIndex:4 completion:^(__kindof UIViewController *selectedTabBarChildViewController) {
    [self cyl_popSelectTabBarChildViewControllerForClassType:[CYLMineViewController class] completion:^(__kindof UIViewController *selectedTabBarChildViewController) {
        CYLMineViewController *mineViewController = selectedTabBarChildViewController;
        @try {
            [mineViewController testPush];
        } @catch (NSException *exception) {
            NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
        }
    }];
}

@end
