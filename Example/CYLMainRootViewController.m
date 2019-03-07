//
//  CYLMainRootViewController.m
//  CYLTabBarController
//
//  Created by chenyilong on 7/3/2019.
//  Copyright © 2019 微博@iOS程序犭袁. All rights reserved.
//

#import "CYLMainRootViewController.h"
#import "MainTabBarController.h"
#import "CYLPlusButtonSubclass.h"

@interface CYLMainRootViewController ()<UITabBarControllerDelegate, CYLTabBarControllerDelegate>

@property (nonatomic, weak) UIButton *selectedCover;

@property (nonatomic, strong) MainTabBarController *tabBarController;

@end

@implementation CYLMainRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationBarHidden = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    //添加仿淘宝tabbar，第一个tab选中后有图标覆盖
    //    [tabBarController setViewDidLayoutSubViewsBlock:^(CYLTabBarController *tabBarController) {
    //        if ([self cyl_tabBarController].selectedIndex != 0) {
    //            return;
    //        }
    //        static dispatch_once_t onceToken;
    //        dispatch_once(&onceToken, ^{
    //            NSUInteger delaySeconds = 0.2;
    //            dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    //            dispatch_after(when, dispatch_get_main_queue(), ^{
    //                tabBarController.selectedIndex = 0;
    //            });
    //        });
    //    }];
    [self createNewTabBar];
    
    //这里演示如何动态替换TabBar
    NSUInteger delaySeconds = 3;
    __block dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        [self createNewTabBar];
        when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
        dispatch_after(when, dispatch_get_main_queue(), ^{
            [self createNewTabBar];
        });
    });
    // Do any additional setup after loading the view.
}

- (void)createNewTabBar {
    if (arc4random_uniform(10)%2 == 0) {
        CYLExternPlusButton = nil;
    } else {
        [CYLPlusButtonSubclass registerPlusButton];
    }
    MainTabBarController *tabBarController = [[MainTabBarController alloc] init];
    tabBarController.delegate = self;
    self.viewControllers = @[tabBarController];
    [self customizeInterfaceWithTabBarController:tabBarController];
}

- (void)setSelectedCoverShow:(BOOL)show {
    if (_selectedCover.superview && show) {
        [self addOnceScaleAnimationOnView:_selectedCover];
        return;
    }
    UIControl *selectedTabButton = [[self cyl_tabBarController].viewControllers[0].tabBarItem cyl_tabButton];
    if (show && !_selectedCover.superview) {
        UIButton *selectedCover = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [UIImage imageNamed:@"home_select_cover"];
        [selectedCover setImage:image forState:UIControlStateNormal];
        selectedCover.frame = CGRectMake(0, 0, image.size.width, image.size.height);
        if (selectedTabButton) {
            selectedCover.center = CGPointMake(selectedTabButton.cyl_tabImageView.center.x, selectedTabButton.center.y);
            [self addOnceScaleAnimationOnView:selectedCover];
            [selectedTabButton addSubview:(_selectedCover = selectedCover)];
            [selectedTabButton bringSubviewToFront:_selectedCover];
        }
    } else if (_selectedCover.superview){
        [_selectedCover removeFromSuperview];
        _selectedCover = nil;
    }
    if (selectedTabButton) {
        selectedTabButton.cyl_tabLabel.hidden =
        (show );
        selectedTabButton.cyl_tabImageView.hidden = (show);
    }
}

//缩放动画
- (void)addOnceScaleAnimationOnView:(UIView *)animationView {
    //需要实现的帧动画，这里根据需求自定义
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"transform.scale";
    animation.values = @[@0.5, @1.0];
    animation.duration = 0.1;
    //    animation.repeatCount = repeatCount;
    animation.calculationMode = kCAAnimationCubic;
    [animationView.layer addAnimation:animation forKey:nil];
}

- (void)customizeInterfaceWithTabBarController:(CYLTabBarController *)tabBarController {
    //设置导航栏
    //    [self setUpNavigationBarAppearance];
    [tabBarController hideTabBadgeBackgroundSeparator];
    //添加小红点
    //添加提示动画，引导用户点击
    [[self cyl_tabBarController] setViewDidLayoutSubViewsBlockInvokeOnce:YES block:^(CYLTabBarController *tabBarController) {
        NSUInteger delaySeconds = 0.2;
        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
        dispatch_after(when, dispatch_get_main_queue(), ^{
            @try {
                UIViewController *viewControler0 = tabBarController.viewControllers[0];
//                NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), viewControler0);
                [viewControler0 cyl_showBadge];
                [tabBarController.viewControllers[1] cyl_showBadgeValue:@"" animationType:CYLBadgeAnimTypeScale];
                [tabBarController.viewControllers[1] cyl_setBadgeBackgroundColor:[UIColor blueColor]];
                [tabBarController.viewControllers[2] cyl_showBadgeValue:@"test" animationType:CYLBadgeAnimTypeShake];
                [tabBarController.viewControllers[3] cyl_showBadgeValue:@"100" animationType:CYLBadgeAnimTypeBounce];
                [tabBarController.viewControllers[4] cyl_showBadgeValue:@"new" animationType:CYLBadgeAnimTypeBreathe];
            } @catch (NSException *exception) {}
        });
    }];
}

#pragma mark - delegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    BOOL should = YES;
    [[self cyl_tabBarController] updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController shouldSelect:should];
    return should;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectControl:(UIControl *)control {
    UIView *animationView;
    NSLog(@"🔴类名与方法名：%@（在第%@行），描述：tabBarChildViewControllerIndex: %@, tabBarItemVisibleIndex : %@", @(__PRETTY_FUNCTION__), @(__LINE__), @(control.cyl_tabBarChildViewControllerIndex), @(control.cyl_tabBarItemVisibleIndex));
    if ([control cyl_isTabButton]) {
        //更改红标状态
        if ([[self cyl_tabBarController].selectedViewController cyl_isShowBadge]) {
            [[self cyl_tabBarController].selectedViewController cyl_clearBadge];
        } else {
            [[self cyl_tabBarController].selectedViewController cyl_showBadge];
        }
        animationView = [control cyl_tabImageView];
    }
    
    UIButton *button = CYLExternPlusButton;
    BOOL isPlusButton = [control cyl_isPlusButton];
    // 即使 PlusButton 也添加了点击事件，点击 PlusButton 后也会触发该代理方法。
    if (isPlusButton) {
        animationView = button.imageView;
    }
    
    [self addScaleAnimationOnView:animationView repeatCount:1];
    // [self addRotateAnimationOnView:animationView];//暂时不推荐用旋转方式，badge也会旋转。
    
    //添加仿淘宝tabbar，第一个tab选中后有图标覆盖
    //    if ([control cyl_isTabButton]|| [control cyl_isPlusButton]) {
    //        BOOL shouldSelectedCoverShow = ([self cyl_tabBarController].selectedIndex == 0);
    //        [self setSelectedCoverShow:shouldSelectedCoverShow];
    //    }
}

//缩放动画
- (void)addScaleAnimationOnView:(UIView *)animationView repeatCount:(float)repeatCount {
    //需要实现的帧动画，这里根据需求自定义
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"transform.scale";
    animation.values = @[@1.0,@1.3,@0.9,@1.15,@0.95,@1.02,@1.0];
    animation.duration = 1;
    animation.repeatCount = repeatCount;
    animation.calculationMode = kCAAnimationCubic;
    [animationView.layer addAnimation:animation forKey:nil];
}

//旋转动画
- (void)addRotateAnimationOnView:(UIView *)animationView {
    // 针对旋转动画，需要将旋转轴向屏幕外侧平移，最大图片宽度的一半
    // 否则背景与按钮图片处于同一层次，当按钮图片旋转时，转轴就在背景图上，动画时会有一部分在背景图之下。
    // 动画结束后复位
    animationView.layer.zPosition = 65.f / 2;
    [UIView animateWithDuration:0.32 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        animationView.layer.transform = CATransform3DMakeRotation(M_PI, 0, 1, 0);
    } completion:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.70 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.2 options:UIViewAnimationOptionCurveEaseOut animations:^{
            animationView.layer.transform = CATransform3DMakeRotation(2 * M_PI, 0, 1, 0);
        } completion:nil];
    });
}

@end
