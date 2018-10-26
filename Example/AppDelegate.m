//
//  AppDelegate.m
//  CYLTabBarController
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import "AppDelegate.h"
#import "CYLPlusButtonSubclass.h"
#import "HDLTabBarController.h"

@interface AppDelegate ()<UITabBarControllerDelegate, CYLTabBarControllerDelegate>
@property (nonatomic, strong) HDLTabBarController *tabBarController;
@property (nonatomic, weak) UIButton *selectedCover;

@end

@implementation AppDelegate
#define RANDOM_COLOR [UIColor colorWithHue: (arc4random() % 256 / 256.0) saturation:((arc4random()% 128 / 256.0 ) + 0.5) brightness:(( arc4random() % 128 / 256.0 ) + 0.5) alpha:1]

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [UIApplication sharedApplication].statusBarHidden = NO;

    // 设置主窗口,并设置根控制器
    self.window = [[UIWindow alloc]init];
    self.window.frame = [UIScreen mainScreen].bounds;
    [CYLPlusButtonSubclass registerPlusButton];
    HDLTabBarController *tabBarController = [[HDLTabBarController alloc] init];
    [tabBarController hideTabBadgeBackgroundSeparator];
    [tabBarController setViewDidLayoutSubViewsBlock:^(CYLTabBarController *tabBarController) {
        if ([self cyl_tabBarController].selectedIndex != 0) {
            return;
        }
        static dispatch_once_t onceToken;
        UITabBar *tabBar =  tabBarController.tabBar;
        for (UIControl *control in tabBar.subviews) {
            if ([control cyl_isTabButton]) {
                dispatch_once(&onceToken, ^{
                    NSUInteger delaySeconds = 0.2;
                    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
                    dispatch_after(when, dispatch_get_main_queue(), ^{
                        [self setSelectedCoverShow:YES];
                    });
                });
            }
        }
    }];
    tabBarController.delegate = self;
    self.tabBarController = tabBarController;
    [self.window setRootViewController:tabBarController];
    [self.window makeKeyAndVisible];
    [self customizeInterfaceWithTabBarController:tabBarController];
    return YES;
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
    [self setUpNavigationBarAppearance];
    
    [tabBarController hideTabBadgeBackgroundSeparator];
    //添加小红点
    UIViewController *viewController = tabBarController.viewControllers[0];
    UIView *tabBadgePointView0 = [UIView cyl_tabBadgePointViewWithClolor:RANDOM_COLOR radius:4.5];
    [viewController.tabBarItem.cyl_tabButton cyl_setTabBadgePointView:tabBadgePointView0];
    [viewController cyl_showTabBadgePoint];
    
    UIView *tabBadgePointView1 = [UIView cyl_tabBadgePointViewWithClolor:RANDOM_COLOR radius:4.5];
    @try {
        [tabBarController.viewControllers[1] cyl_setTabBadgePointView:tabBadgePointView1];
        [tabBarController.viewControllers[1] cyl_showTabBadgePoint];

        UIView *tabBadgePointView2 = [UIView cyl_tabBadgePointViewWithClolor:RANDOM_COLOR radius:4.5];
        [tabBarController.viewControllers[2] cyl_setTabBadgePointView:tabBadgePointView2];
        [tabBarController.viewControllers[2] cyl_showTabBadgePoint];

        [tabBarController.viewControllers[3] cyl_showTabBadgePoint];

        //添加提示动画，引导用户点击
        [self addScaleAnimationOnView:tabBarController.viewControllers[3].cyl_tabButton.cyl_tabImageView repeatCount:20];
    } @catch (NSException *exception) {}
    
}

/**
 *  设置navigationBar样式
 */
- (void)setUpNavigationBarAppearance {
    UINavigationBar *navigationBarAppearance = [UINavigationBar appearance];

    UIImage *backgroundImage = nil;
    NSDictionary *textAttributes = nil;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        backgroundImage = [UIImage imageNamed:@"navigationbar_background_tall"];

        textAttributes = @{
                           NSFontAttributeName : [UIFont boldSystemFontOfSize:18],
                           NSForegroundColorAttributeName : [UIColor blackColor],
                           };
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
        backgroundImage = [UIImage imageNamed:@"navigationbar_background"];
        textAttributes = @{
                           UITextAttributeFont : [UIFont boldSystemFontOfSize:18],
                           UITextAttributeTextColor : [UIColor blackColor],
                           UITextAttributeTextShadowColor : [UIColor clearColor],
                           UITextAttributeTextShadowOffset : [NSValue valueWithUIOffset:UIOffsetZero],
                           };
#endif
    }

    [navigationBarAppearance setBackgroundImage:backgroundImage
                                  forBarMetrics:UIBarMetricsDefault];
    [navigationBarAppearance setTitleTextAttributes:textAttributes];
    
}


#pragma mark - delegate

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    [[self cyl_tabBarController] updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController];
    if ([viewController.tabBarItem.cyl_tabButton cyl_isTabButton]|| [viewController.tabBarItem.cyl_tabButton cyl_isPlusButton]) {
        CGFloat index = [tabBarController.viewControllers indexOfObject:viewController];
        BOOL shouldSelectedCoverShow = (index == 0);
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@===%@", @(__PRETTY_FUNCTION__), @(__LINE__), tabBarController, @(tabBarController.selectedIndex));
        [self setSelectedCoverShow:shouldSelectedCoverShow];
    }
    
    return YES;
}


- (void)tabBarController:(UITabBarController *)tabBarController didSelectControl:(UIControl *)control {
    UIView *animationView;

    if ([control cyl_isTabButton]) {
        //更改红标状态
        if ([[self cyl_tabBarController].selectedViewController cyl_isShowTabBadgePoint]) {
            [[self cyl_tabBarController].selectedViewController cyl_removeTabBadgePoint];
        } else {
            [[self cyl_tabBarController].selectedViewController cyl_showTabBadgePoint];
        }

        animationView = [control cyl_tabImageView];
    }

    // 即使 PlusButton 也添加了点击事件，点击 PlusButton 后也会触发该代理方法。
    if ([control cyl_isPlusButton]) {
        UIButton *button = CYLExternPlusButton;
        animationView = button.imageView;
    }

    if ([self cyl_tabBarController].selectedIndex % 2 == 0) {
        [self addScaleAnimationOnView:animationView repeatCount:1];
    } else {
        [self addRotateAnimationOnView:animationView];
    }
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
