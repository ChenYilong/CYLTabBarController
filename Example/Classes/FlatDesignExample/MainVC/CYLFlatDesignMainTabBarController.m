//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignMainTabBarController.h"
#import "CYLFlatDesignTableViewController.h"
#import "CYLFlatDesignModalViewController.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "CAAnimation+CYLBadgeExtention.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif
#define RANDOM_COLOR [UIColor colorWithHue: (arc4random() % 256 / 256.0) saturation:((arc4random()% 128 / 256.0 ) + 0.5) brightness:(( arc4random() % 128 / 256.0 ) + 0.5) alpha:1]

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
@interface CYLFlatDesignMainTabBarController ()<CYLFlatDesignUITabBarControllerDelegate>

#else
@interface CYLFlatDesignMainTabBarController ()

#endif
@end

@implementation CYLFlatDesignMainTabBarController



- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                context:(NSString *)context {
    /**
     * 以下两行代码目的在于手动设置让TabBarItem只显示图标，不显示文字，并让图标垂直居中。
     * 等 效于在 `-tabBarItemsAttributesForController` 方法中不传 `CYLTabBarItemTitle` 字段。
     * 更推荐后一种做法。
     */
    UIEdgeInsets imageInsets = UIEdgeInsetsZero;//UIEdgeInsetsMake(4.5, 0, -4.5, 0);
    UIOffset titlePositionAdjustment = UIOffsetMake(0, -3.5);
    CYLTabBarStyleType tabBarStyleType;
    tabBarStyleType = CYLTabBarStyleTypeFlatDesign;
    // 设置 TabBar 样式：液态玻璃效果（覆盖上一行）
    //    tabBarStyleType = CYLTabBarStyleTypeLiquidGlass;
    
    if (self = [super initWithViewControllers:viewControllers
                        tabBarItemsAttributes:tabBarItemsAttributes
                                  imageInsets:imageInsets
                      titlePositionAdjustment:titlePositionAdjustment
                                    styleType:tabBarStyleType
                                      context:context]) {
        //        self.adjustTabBarItemImageViewSizeDependOnSuperView = NO;
        
        //        [self customizeTabBarAppearanceWithTitlePositionAdjustment:titlePositionAdjustment];
        self.delegate = self;
        //        self.navigationController.navigationBar.hidden = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
    
    // 设置代理
    self.delegate = self;
    [self customizeInterface];
    
    // 可以通过KVC自定义CYLFlatDesignTabBar
    //    CYLFlatDesigMainTabBar *tabBar = [[CYLFlatDesigMainTabBar alloc] init];
    //    [self setValue:tabBar forKey:@"cyl_tabBar"];
    CYLFlatDesignTabBar *cyl_tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;
    
    cyl_tabBar.barTintColor = [UIColor whiteColor];
    cyl_tabBar.shadowImage = [UIImage cyl_imageWithColor:[UIColor.lightGrayColor colorWithAlphaComponent:0.5] size:CGSizeMake(1, 1)];
    
    //    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    //    NSMutableArray *titles = @[@"首页", @"同城", @"发布", @"消息", @"我的"].mutableCopy;
    //    NSMutableArray *images = @[@"home_normal", @"fishpond_normal", @"post_highlight", @"message_normal" ,@"account_normal"].mutableCopy;
    //    NSMutableArray *selectedImages = @[@"home_highlight", @"fishpond_highlight", @"post_highlight", @"message_highlight", @"account_highlight"].mutableCopy;
    //    NSMutableArray *lottieFilePaths = @[[[NSBundle mainBundle] pathForResource:@"green_lottie_tab_home" ofType:@"json"], [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_discover" ofType:@"json"], @"post_highlight", [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_news" ofType:@"json"], [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_mine" ofType:@"json"]].mutableCopy;
    //
    //
    //    // 测试超过5个子控制器显示 moreNavigationController，继承自 CYLTabBarController 才会显示
    //    BOOL testMoreNav = NO;
    //    if (testMoreNav) {
    //        [titles addObject:@"测试"];
    //        [images addObject:@"account_normal"];
    //        [selectedImages addObject:@"account_highlight"];
    //    }
    //
    //    for (NSInteger i = 0; i < titles.count; i++) {
    //        CYLFlatDesignTableViewController *vc = [[CYLFlatDesignTableViewController alloc] init];
    //        vc.title = titles[i];
    //        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    ////        [self setupChildViewController:nav
    ////                                 title:titles[i]
    ////                             imageName:images[i]
    ////                     selectedImageName:selectedImages[i]
    ////                        lottieFilePath:lottieFilePaths[i]];
    //
    //
    //
    ////        if (i == 0) {
    ////            nav.cyl_tabBarItem.badgeValue = @"1";
    ////        } else if (i == 1) {
    ////            nav.cyl_tabBarItem.badgeValue = @"11";
    ////            nav.cyl_tabBarItem.badgeColor = UIColor.systemBlueColor;
    ////        } else if (i == 2) {
    ////            nav.cyl_tabBarItem.imagePositionAdjustment = UIOffsetMake(0, -12);
    ////        } else if (i == 3) {
    ////            nav.cyl_tabBarItem.badgeValue = @"新消息";
    ////            [nav.cyl_tabBarItem setBadgeTextAttributes:@{NSForegroundColorAttributeName:UIColor.greenColor} forState:UIControlStateNormal];
    ////        } else if (i == 4) {
    ////            // 设置badgeSize不为CGSizeZero、badgeValue为nil，就变成一个点了
    ////            nav.cyl_tabBarItem.badgeValue = nil;
    ////            nav.cyl_tabBarItem.badgeSize = CGSizeMake(10, 10);
    ////            nav.cyl_tabBarItem.badgeColor = UIColor.systemRedColor;
    ////        }
    //        [viewControllers addObject:nav];
    //    }
    //    self.viewControllers = viewControllers;
#else
#endif
}

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
- (void)setupChildViewController:(UIViewController *)childVC
                           title:(NSString *)title
                       imageName:(NSString *)imageName
               selectedImageName:(NSString *)selectedImageName
                  lottieFilePath:(NSString *)lottieFilePath {
    //cyl_setTabBarItem 方法内部需要获取到tabbarvc但是， cyl_setTabBarItem是在初始化完成前的配置， 所以需要手动指定tabbarvc，否则cyl_setTabBarItem会初始化失败。
    //    [childVC cylflatdesign_setTabBarController:self];
    CYLFlatDesignTabBarItem *cyl_tabBarItem = [[CYLFlatDesignTabBarItem alloc] initWithTitle:title image:[UIImage imageNamed:imageName] selectedImage:[UIImage imageNamed:selectedImageName]];
    [cyl_tabBarItem cylflatdesign_setTabBarController:self];
    //    cyl_tabBarItem.title = title;
    cyl_tabBarItem.childViewController = childVC;
    //    cyl_tabBarItem.image = [UIImage imageNamed:imageName];
    //    cyl_tabBarItem.selectedImage = [UIImage imageNamed:selectedImageName];
    cyl_tabBarItem.lottieFilePath = lottieFilePath;
    [cyl_tabBarItem setTitleTextAttributes:
     @{
        NSForegroundColorAttributeName : UIColor.systemYellowColor
    }
                                  forState:UIControlStateSelected];
    
    [childVC cyl_setTabBarItem:cyl_tabBarItem];
}
#else
#endif

#pragma mark - CYLFlatDesignUITabBarControllerDelegate
- (BOOL)tabBarController:(CYLTabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
    NSInteger index = [tabBarController.viewControllers indexOfObject:viewController];
    if (index != NSNotFound) {
        
        CYLFlatDesignTabBar *tabBar;
        if ([self.cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
            tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;
        }
        
        [self springAnimationForView:tabBar.tabBarButtons[index].imageView];
    }
#else
#endif
    //    if (0 == [tabBarController.viewControllers indexOfObject:viewController]) {
    //        [self setSelectedCoverShow:YES];
    //    } else {
    //        [self setSelectedCoverShow:NO];
    //    }
    if (index == 2) {
        return NO;
    }
    return YES;
}


- (void)customizeInterface {
    //设置导航栏
    //    [self setUpNavigationBarAppearance];
    //     [self hideTabBarShadowImageView];
    //#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    //    if (@available(iOS 13.0, *)) {
    //        tabBarController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    //    }
    //#endif
    //添加小红点
    //添加提示动画，引导用户点击
    __weak __typeof(self) weakSelf = self;
    [self setViewDidLayoutSubViewsBlockInvokeOnce:YES block:^(CYLTabBarController *tabBarController) {
        __strong typeof(self) self = weakSelf;
        if (!self) {
            return;
        }
        //延迟是为了演示demo的时候， 方便看清楚badge动画。 非必须。可删除延迟。
        //@try是为了demo演示的时候， 随时调整减少 tabbar items 个数，而不导致崩溃， 非必须， 可删除。
        NSUInteger delaySeconds = 1.5;
        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
        dispatch_after(when, dispatch_get_main_queue(), ^{
            @try {
                UIViewController *viewController0 = tabBarController.viewControllers[0];
                // UIControl *tab0 = viewController0.cyl_tabButton;
                // [tab0 cyl_showBadge];
                [viewController0 cyl_setBadgeBackgroundColor:RANDOM_COLOR];
                [viewController0 cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
                [viewController0 cyl_setBadgeRadius:11/2];
                [viewController0 cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeBreathe];
                [self setSelectedCoverShow:YES];
                //以上对Badge的参数设置，需要在 cyl_showBadgeValue 调用之前执行。
                //                [viewController0 cyl_showBadge];
                
                //                                [tabBarController.viewControllers[1] cyl_setBadgeMargin:1.0];
                //                                [tabBarController.viewControllers[2] cyl_setBadgeMargin:1.0];
                //                                [tabBarController.viewControllers[3] cyl_setBadgeMargin:1.0];
                //                                [tabBarController.viewControllers[4] cyl_setBadgeMargin:1.0];
                [tabBarController.viewControllers[1] cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
                [tabBarController.viewControllers[1] cyl_setBadgeBackgroundColor:RANDOM_COLOR];
                [tabBarController.viewControllers[1] cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeScale];
                [tabBarController.viewControllers[2] cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
                
                [tabBarController.viewControllers[2] cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeShake];
                
                NSString *testBadgeString = @"100";
                //                [tabBarController.viewControllers[3] cyl_setBadgeMargin:-5];
                //                CGSize size = [testBadgeString sizeWithAttributes:
                //                               @{NSFontAttributeName:
                //                                     tabBarController.viewControllers[3].cyl_badgeFont}];
                //                float labelHeight = ceilf(size.height);
                //                [tabBarController.viewControllers[3] cyl_setBadgeCornerRadius:(labelHeight+ tabBarController.viewControllers[3].cyl_badgeMargin)/2];
                [tabBarController.viewControllers[3] cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
                [tabBarController.viewControllers[3] cyl_showBadgeValue:testBadgeString animationType:CYLBadgeAnimationTypeBounce];
                if (tabBarController.viewControllers.count > 4) {
                    [tabBarController.viewControllers[4] cyl_setBadgeCenterOffset:CGPointMake(-1, 3)];
                    [tabBarController.viewControllers[4] cyl_showBadgeValue:@"NEW" animationType:CYLBadgeAnimationTypeBreathe];
                }
            } @catch (NSException *exception) {
                NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
            }
            
            //添加仿淘宝tabbar，第一个tab选中后有图标覆盖
            if (self.selectedIndex != 0) {
                return;
            }
            // tabBarController.selectedIndex = 1;
            
        });
    }];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    return;
    CYLFlatDesignMainTabBarController *tabBarController = self;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{});
    //延迟是为了演示demo的时候， 方便看清楚badge动画。 非必须。可删除延迟。
    //@try是为了demo演示的时候， 随时调整减少 tabbar items 个数，而不导致崩溃， 非必须， 可删除。
    NSUInteger delaySeconds = 1.5;
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        /*return*/;
        @try {
            UIViewController *viewController0 = tabBarController.viewControllers[0];
            // UIControl *tab0 = viewController0.cyl_tabButton;
            // [tab0 cyl_showBadge];
            [viewController0 cyl_setBadgeBackgroundColor:RANDOM_COLOR];
            [viewController0 cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
            [viewController0 cyl_setBadgeRadius:11/2];
            [viewController0 cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeBreathe];
            [self setSelectedCoverShow:YES];
            //以上对Badge的参数设置，需要在 cyl_showBadgeValue 调用之前执行。
            //                [viewController0 cyl_showBadge];
            
            //                                [tabBarController.viewControllers[1] cyl_setBadgeMargin:1.0];
            //                                [tabBarController.viewControllers[2] cyl_setBadgeMargin:1.0];
            //                                [tabBarController.viewControllers[3] cyl_setBadgeMargin:1.0];
            //                                [tabBarController.viewControllers[4] cyl_setBadgeMargin:1.0];
            [tabBarController.viewControllers[1] cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
            [tabBarController.viewControllers[1] cyl_setBadgeBackgroundColor:RANDOM_COLOR];
            [tabBarController.viewControllers[1] cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeScale];
            [tabBarController.viewControllers[2] cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
            
            [tabBarController.viewControllers[2] cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeShake];
            
            NSString *testBadgeString = @"100";
            //                [tabBarController.viewControllers[3] cyl_setBadgeMargin:-5];
            //                CGSize size = [testBadgeString sizeWithAttributes:
            //                               @{NSFontAttributeName:
            //                                     tabBarController.viewControllers[3].cyl_badgeFont}];
            //                float labelHeight = ceilf(size.height);
            //                [tabBarController.viewControllers[3] cyl_setBadgeCornerRadius:(labelHeight+ tabBarController.viewControllers[3].cyl_badgeMargin)/2];
            [tabBarController.viewControllers[3] cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
            [tabBarController.viewControllers[3] cyl_showBadgeValue:testBadgeString animationType:CYLBadgeAnimationTypeBounce];
            if (tabBarController.viewControllers.count > 4) {
                [tabBarController.viewControllers[4] cyl_setBadgeCenterOffset:CGPointMake(-1, 3)];
                [tabBarController.viewControllers[4] cyl_showBadgeValue:@"NEW" animationType:CYLBadgeAnimationTypeBreathe];
            }
        } @catch (NSException *exception) {
            NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
        }
        
        
    });
    //    });
}
- (UIButton *)selectedCover {
    //    if (_selectedCover) {
    //        return _selectedCover;
    //    }
    UIButton *selectedCover = [UIButton buttonWithType:UIButtonTypeCustom];
    
    UIImage *image = [UIImage imageNamed:@"home_select_cover"];
    [selectedCover setImage:image forState:UIControlStateNormal];
    selectedCover.frame = ({
        CGRect frame = selectedCover.frame;
        frame.size = CGSizeMake(image.size.width, image.size.height);
        frame;
    });
    selectedCover.contentMode = UIViewContentModeCenter;
    selectedCover.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    selectedCover.translatesAutoresizingMaskIntoConstraints = NO;
    selectedCover.userInteractionEnabled = false;
    //    _selectedCover = selectedCover;
    [selectedCover cyl_setHidden:NO];
    
    return selectedCover;
}

- (void)setSelectedCoverShow:(BOOL)show {
    
    UIControl *selectedTabButton = [self.viewControllers[0] cyl_tabButton];
    //    selectedTabButton = self.viewControllers[0].cyl_tabBarItem.tabBarButton;
    __weak __typeof(self) weakSelf = self;
    
    //TODO:  如果是Lottie 动画icon需要添加延迟， 否则， 会在lottie动画未初始化完成前， 就替换， 位置错误。
    [selectedTabButton cyl_coverVisiableTabImageViewOrTabButton:YES
                                                 contentNewView:self.selectedCover
                                          seclectContentNewView:self.selectedCover
                                                         offset:UIOffsetZero
                                                           show:show
                                        delayIfNeededForSeconds:0.5
                                                     completion:^(BOOL isReplaced, UIControl * _Nonnull tabBarButton, UIView * _Nonnull newView) {
        __strong typeof(self) self = weakSelf;
        if (!self) {
            return;
        }
        
        if (isReplaced && show && newView) {
            [newView layoutIfNeeded];
            
            [self.viewControllers[0] cyl_clearBadge];
            //            [tabBarButton insertSubview:tabBarButton.cyl_lottieAnimationView belowSubview:selectedTabButton];
            //            [tabBarButton bringSubviewToFront:newView];
            [tabBarButton cyl_bringSubviewToTop:newView];
            
            if (![CYLConstants isLiquidGlassActive]) {
                // LiquidGlass 已经自带缩放动画， 无需缩放
                //                [self addOnceScaleAnimationOnView:newView];
                [newView.layer addAnimation:
                 [CAAnimation cyl_badge_once_scale_AnimationRepeatTimes:1
                                                               durTimes:0.5]
                                     forKey:@"animation"];
                
            }
        }
        
        //        if (!show) {
        //            [tabBarButton cyl_setHidden:NO];
        //            [newView cyl_setHidden:YES];
        //        }
    }];
}

- (void)tabBarController:(CYLTabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    // 选择了 viewController
}

#pragma mark - CYLFlatDesignTabBarDelegate
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
- (void)tabBar:(CYLFlatDesignTabBar *)tabBar didSelectItem:(nonnull CYLFlatDesignTabBarItem *)item {
    NSInteger index = [tabBar.items indexOfObject:item];
    if (index == 2) {
        CYLFlatDesignModalViewController *vc = [[CYLFlatDesignModalViewController alloc] init];
        [self presentViewController:vc animated:YES completion:nil];
        return;
    }
    BOOL isBlackTheme = (index == 4);
    NSDictionary *titleTextAttributes = isBlackTheme ? @{NSForegroundColorAttributeName:UIColor.whiteColor} : @{NSForegroundColorAttributeName:UIColor.grayColor};
    UIColor *barTintColor = isBlackTheme ? UIColor.blackColor : UIColor.whiteColor;
    tabBar.barTintColor = barTintColor;
    for (UIViewController *viewController in self.viewControllers) {
        [viewController.cyl_tabBarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    }
}


- (void)tabBarController:(CYLTabBarController *)tabBarController willShowTabBar:(CYLFlatDesignTabBar *)tabBar {
#if defined(DEBUG) || defined(BETA)
    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"");
#endif
}

- (void)tabBarController:(CYLTabBarController *)tabBarController didShowTabBar:(CYLFlatDesignTabBar *)tabBar {
#if defined(DEBUG) || defined(BETA)
    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"");
#endif
}

- (void)tabBarController:(CYLTabBarController *)tabBarController willHideTabBar:(CYLFlatDesignTabBar *)tabBar {
#if defined(DEBUG) || defined(BETA)
    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"");
#endif
}

- (void)tabBarController:(CYLTabBarController *)tabBarController didHideTabBar:(CYLFlatDesignTabBar *)tabBar {
#if defined(DEBUG) || defined(BETA)
    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), @"");
#endif
}

#else
#endif

- (void)tabBarController:(CYLTabBarController *)tabBarController didSelectControl:(UIControl *)control {
    
    UIView *animationView;
    
#if defined(DEBUG) || defined(BETA)
NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), control);
#endif
    if ([control cyl_isTabButton]) {
        //更改红标状态
        if ([control cyl_isShowBadge]) {
            if (CYLTabBarStyleTypeFlatDesign == tabBarController.tabBarStyleType) {
                [control cyl_clearBadge];
            } else {
                [tabBarController.selectedViewController cyl_clearBadge];
                
            }
        } else {
            if (CYLTabBarStyleTypeFlatDesign == tabBarController.tabBarStyleType) {
                [control cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
                [control  cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeScaleOnce];
            } else {
                [tabBarController.selectedViewController cyl_setBadgeCenterOffset:CGPointMake(-5, 3)];
                [tabBarController.selectedViewController cyl_showBadge];
            }
        }
        animationView = [control cyl_tabImageView];
    }
    
    UIButton *button = CYLExternPlusButton;
    BOOL isPlusButton = [control cyl_isPlusButton];
    // 即使 PlusButton 也添加了点击事件，点击 PlusButton 后也会触发该代理方法。
    // 可在PlusButton初始化时使用 CYLExternPlusButton.cyl_userInteractionDisabled = YES; 来禁止该协议方法触发plusButton回调
    if (isPlusButton) {
        animationView = button.imageView;
    }
    
    
    // [self addRotateAnimationOnView:animationView];//暂时不推荐用旋转方式，badge也会旋转。
    
    //添加仿淘宝tabbar，第一个tab选中后有图标覆盖
    if ([control cyl_isTabButton] || [control cyl_isPlusButton]) {
        BOOL shouldSelectedCoverShow = (self.selectedIndex == 0);
        //        [self setSelectedCoverShow:shouldSelectedCoverShow];
    }
}
#pragma mark - Spring Animation

static NSString *const CYLSpringAnimationKey = @"CYLSpringAnimationKey";

- (void)springAnimationForView:(UIView *)view {
    if (!view || ![view isKindOfClass:[UIView class]]) { return; }
    [self removeSpringAnimationForView:view];
    CAKeyframeAnimation *springAnimation = [CAKeyframeAnimation cyl_springAnimationForDuration:0.6];
    [view.layer addAnimation:springAnimation forKey:CYLSpringAnimationKey];
}

- (void)removeSpringAnimationForView:(UIView *)view {
    if (!view || ![view isKindOfClass:[UIView class]]) { return; }
    [view.layer removeAnimationForKey:CYLSpringAnimationKey];
}

@end
