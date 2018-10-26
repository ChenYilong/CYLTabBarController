//
//  CYLHomeViewController.m
//  CYLTabBarController
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLHomeViewController.h"
//#import "CYLTabBarControllerConfig.h"
//#import "CYLPlusButtonSubclass.h"
@implementation CYLHomeViewController 

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"首页(3)"; //✅sets navigation bar title.The right way to set the title of the navigation
    self.tabBarItem.title = @"首页23333";   //❌sets tab bar title. Even the `tabBarItem.title` changed, this will be ignored in tabbar.
    //self.title = @"首页1";                //❌sets both of these. Do not do this‼️‼️This may cause something strange like this : http://i68.tinypic.com/282l3x4.jpg .
//    [self.navigationController.tabBarItem setBadgeValue:@"3"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - Methods

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [[cell textLabel] setText:[NSString stringWithFormat:@"%@ Controller Cell %@", self.tabBarItem.title, @(indexPath.row)]];
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

//- (void)viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//    
//    [self
//     .navigationController setNavigationBarHidden:YES animated:animated];
//    
//    // 当新的视图控制器加载完成后再启用
//    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
//        self.navigationController.interactivePopGestureRecognizer.delegate = self;
//    }
//    NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@====%@", @(__PRETTY_FUNCTION__), @(__LINE__), [NSValue valueWithUIEdgeInsets:self.view.safeAreaInsets]
//          ,[NSValue valueWithUIEdgeInsets:[UIApplication sharedApplication].keyWindow.safeAreaInsets]);
//}
//- (void)viewWillDisappear:(BOOL)animated {
//    [super viewWillDisappear:animated];
//    
//    
//    [self.navigationController setNavigationBarHidden:NO animated:animated];
//    // 在过渡的时候禁用interactivePopGestureRecognizer
//    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
//        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
//    }
//    NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@====%@", @(__PRETTY_FUNCTION__), @(__LINE__), [NSValue valueWithUIEdgeInsets:self.view.safeAreaInsets]
//          ,[NSValue valueWithUIEdgeInsets:[UIApplication sharedApplication].keyWindow.safeAreaInsets]);
//}
//
//-(void)viewDidDisappear:(BOOL)animated {
//    [super viewDidDisappear:animated];
//    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
//        self.navigationController.interactivePopGestureRecognizer.delegate = self;
//        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
//    }
//}
//- (void)viewDidAppear:(BOOL)animated {
//    [super viewDidAppear:animated];
//    
//    
////    if (self.disablePopGestureRecognizer) {
////        if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
////            self.navigationController.interactivePopGestureRecognizer.enabled = NO;
////        }
////    }
//    NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@====%@", @(__PRETTY_FUNCTION__), @(__LINE__), [NSValue valueWithUIEdgeInsets:self.view.safeAreaInsets]
//          ,[NSValue valueWithUIEdgeInsets:[UIApplication sharedApplication].keyWindow.safeAreaInsets]);
//}
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
    
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController  pushViewController:vc animated:YES];
}


//- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
////    UIViewController *viewController_ = [viewController  cyl_getViewControllerInsteadOfNavigationController];
////    [[viewController_ cyl_tabBarController] updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController];
//    return YES;
//}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UIViewController *vc = [UIViewController new];
    vc.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController  pushViewController:vc animated:YES];
}

@end
