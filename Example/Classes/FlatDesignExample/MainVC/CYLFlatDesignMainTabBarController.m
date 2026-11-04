//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignMainTabBarController.h"
#import "MainTabBarController.h"
#import "CYLFlatDesignTableViewController.h"
#import "CYLFlatDesignModalViewController.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "CAAnimation+CYLBadgeExtention.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

#if CYL_FLATDESIGN_AVAILABLE
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
     * [CN] 以下两行代码目的在于手动设置让TabBarItem只显示图标，不显示文字，并让图标垂直居中。
     * 等 效于在 `-tabBarItemsAttributesForController` 方法中不传 `CYLTabBarItemTitle` 字段。
     * 更推荐后一种做法。
     * [EN] The following two lines manually make the TabBarItem show only the icon, without text, and center the icon
     *      vertically.
     *      This is equivalent to not passing the `CYLTabBarItemTitle` field in `-tabBarItemsAttributesForController`.
     *      The latter approach is recommended.
     */
    UIEdgeInsets imageInsets = UIEdgeInsetsZero;//UIEdgeInsetsMake(4.5, 0, -4.5, 0);
    UIOffset titlePositionAdjustment = UIOffsetMake(0, -3.5);
    CYLTabBarStyleType tabBarStyleType;
    tabBarStyleType = CYLTabBarStyleTypeFlatDesign;
    // [CN] 设置 TabBar 样式：液态玻璃效果（覆盖上一行）
    // [EN] Set the TabBar style: Liquid Glass effect (overrides the previous line)
    //    tabBarStyleType = CYLTabBarStyleTypeLiquidGlass;
    
    if (self = [super initWithViewControllers:viewControllers
                        tabBarItemsAttributes:tabBarItemsAttributes
                                  imageInsets:imageInsets
                      titlePositionAdjustment:titlePositionAdjustment
                                    styleType:tabBarStyleType
                                      context:context]) {
        //        self.adjustTabBarItemImageViewSizeDependOnSuperView = NO;
        
        //        [self customizeTabBarAppearanceWithTitlePositionAdjustment:titlePositionAdjustment];
        // One UITabBarAppearance for every style: the same object MainTabBarController gives the Liquid Glass tab bar.
        // CYLTabBarController maps it onto the FlatDesign tab bar (background, shadow, title and icon colors, badges...),
        // see `-[CYLFlatDesignTabBar standardAppearance]`.
        // 所有样式共用一个 UITabBarAppearance：与 MainTabBarController 赋给液态玻璃 TabBar 的是同一个对象。CYLTabBarController 会将其
        // 映射到扁平样式 TabBar（背景、阴影、标题与图标颜色、角标等），见 `-[CYLFlatDesignTabBar standardAppearance]`。
#if CYL_FLATDESIGN_AVAILABLE
        if (@available(iOS 13.0, *)) {
            self.tabBar.standardAppearance = [MainTabBarController demoStandardAppearanceWithTitlePositionAdjustment:titlePositionAdjustment];
        }
#endif
        self.delegate = self;
        //        self.navigationController.navigationBar.hidden = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Issue #426: on a memory warning, unload the views of the tabs that are not selected; they load again when selected.
    // Issue #426：收到内存警告时卸载未选中 Tab 的视图，切换到该 Tab 时重新加载。
    self.unloadsUnselectedViewsOnMemoryWarning = YES;
    
#if CYL_FLATDESIGN_AVAILABLE
    
    // [CN] 设置代理
    // [EN] Set the delegate
    self.delegate = self;
    [self customizeInterface];
    
    // [CN] 可以通过KVC自定义CYLFlatDesignTabBar
    // [EN] CYLFlatDesignTabBar can be customized via KVC
    //    CYLFlatDesigMainTabBar *tabBar = [[CYLFlatDesigMainTabBar alloc] init];
    //    [self setValue:tabBar forKey:@"cyl_tabBar"];
    CYLFlatDesignTabBar *cyl_tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;
    
    // Used only while no `standardAppearance` is set: the appearance assigned in `-init…` takes precedence.
    // 仅在没有设置 `standardAppearance` 时使用：`-init…` 中赋值的 appearance 优先。
    cyl_tabBar.barTintColor = UIColor.systemBackgroundColor; // [EN] Dark Mode. [CN] 适配深色模式。
    cyl_tabBar.shadowImage = [UIImage cyl_imageWithColor:[UIColor.lightGrayColor colorWithAlphaComponent:0.5] size:CGSizeMake(1, 1)];
    
    //    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    //    NSMutableArray *titles = @[@"首页", @"同城", @"发布", @"消息", @"我的"].mutableCopy;
    //    NSMutableArray *images = @[@"home_normal", @"fishpond_normal", @"post_highlight", @"message_normal" ,@"account_normal"].mutableCopy;
    //    NSMutableArray *selectedImages = @[@"home_highlight", @"fishpond_highlight", @"post_highlight", @"message_highlight", @"account_highlight"].mutableCopy;
    //    NSMutableArray *lottieFilePaths = @[[[NSBundle mainBundle] pathForResource:@"green_lottie_tab_home" ofType:@"json"], [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_discover" ofType:@"json"], @"post_highlight", [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_news" ofType:@"json"], [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_mine" ofType:@"json"]].mutableCopy;
    //
    //
    // [CN] // 测试超过5个子控制器显示 moreNavigationController，继承自 CYLTabBarController 才会显示
    // [EN] Test showing moreNavigationController with more than 5 child controllers; it only appears when subclassing
    //      CYLTabBarController
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
    //// [CN] // 设置badgeSize不为CGSizeZero、badgeValue为nil，就变成一个点了
    //// [EN] With badgeSize not CGSizeZero and badgeValue nil, the badge becomes a dot
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

#if CYL_FLATDESIGN_AVAILABLE
- (void)setupChildViewController:(UIViewController *)childVC
                           title:(NSString *)title
                       imageName:(NSString *)imageName
               selectedImageName:(NSString *)selectedImageName
                  lottieFilePath:(NSString *)lottieFilePath {
    // [CN] cyl_setTabBarItem 方法内部需要获取到tabbarvc但是， cyl_setTabBarItem是在初始化完成前的配置， 所以需要手动指定tabbarvc，否则cyl_setTabBarItem会初始化失败。
    // [EN] cyl_setTabBarItem needs the tabbarvc internally, but cyl_setTabBarItem is configured before initialization
    //      finishes, so the tabbarvc must be set manually, otherwise cyl_setTabBarItem fails to initialize.
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
    // #19: this override does not call super, so ask for the login check itself (tabs that need login, see below).
    // #19：此重写没有调用 super，因此自行调用登录检查（需要登录的 Tab 见下方）。
    if ([self cyl_interceptLoginIfNeededForViewController:viewController]) {
        return NO;
    }
#if CYL_FLATDESIGN_AVAILABLE
    NSUInteger index = [tabBarController.viewControllers indexOfObject:viewController];
    if (index != NSNotFound) {
        
        CYLFlatDesignTabBar *tabBar;
        if ([self.cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
            tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;
        }
        
        [self springAnimationForView:tabBar.tabBarButtons[index].imageView];
    }
    //    if (0 == [tabBarController.viewControllers indexOfObject:viewController]) {
    //        [self setSelectedCoverShow:YES];
    //    } else {
    //        [self setSelectedCoverShow:NO];
    //    }
    // `index` only exists with FlatDesign: it was used after the guard, which did not build without it.
    // `index` 仅在有扁平样式时存在：以前在 guard 之后使用，没有扁平样式时无法编译。
    if (index == 2) {
        return NO;
    }
#endif
    return YES;
}

#pragma mark - #19 tabs that need login (delegate API)

/*!
 * #19, delegate API (MainTabBarController shows the block API): the last two tabs need login. The flat demo's tabs are
 * all the same class, so their default identifiers are equal; the delegate decides by position instead.
 * #19 代理方式（MainTabBarController 演示 block 方式）：最后两个 Tab 需要登录。扁平 Demo 的 Tab 都是同一个类，默认标识相同，
 * 因此由代理按位置判断。
 */
- (BOOL)tabBarController:(CYLTabBarController *)tabBarController requiresLoginToSelectViewController:(UIViewController *)viewController {
    NSUInteger index = [tabBarController.viewControllers indexOfObject:viewController];
    NSUInteger count = tabBarController.viewControllers.count;
    return index != NSNotFound && count >= 2 && index >= count - 2;
}

- (void)tabBarController:(CYLTabBarController *)tabBarController
presentLoginForViewController:(UIViewController *)viewController
              completion:(CYLTabBarLoginCompletion)completion {
    [tabBarController cyl_demo_presentLoginForViewController:viewController completion:completion];
}


- (void)customizeInterface {
    // [CN] 设置导航栏
    // [EN] Set up the navigation bar
    //    [self setUpNavigationBarAppearance];
    //     [self hideTabBarShadowImageView];
    //#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    //    if (@available(iOS 13.0, *)) {
    //        tabBarController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    //    }
    //#endif
    // [CN] 添加小红点
    //添加提示动画，引导用户点击
    // [EN] Add a red dot
    //      Add a hint animation to guide the user to tap
    __weak __typeof(self) weakSelf = self;
    [self setViewDidLayoutSubViewsBlockInvokeOnce:YES block:^(CYLTabBarController *tabBarController) {
        __strong typeof(self) self = weakSelf;
        if (!self) {
            return;
        }
        // [CN] 延迟是为了演示demo的时候， 方便看清楚badge动画。 非必须。可删除延迟。
        //@try是为了demo演示的时候， 随时调整减少 tabbar items 个数，而不导致崩溃， 非必须， 可删除。
        // [EN] The delay is only so the badge animation is easy to see in the demo. Not required; the delay can be removed.
        //      @try is only so the number of tabbar items can be reduced at any time in the demo without crashing. Not
        //      required; can be removed.
        NSTimeInterval delaySeconds = 1.5;
        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
        dispatch_after(when, dispatch_get_main_queue(), ^{
            @try {
                UIViewController *viewController0 = tabBarController.viewControllers[0];
                // UIControl *tab0 = viewController0.cyl_tabButton;
                // [tab0 cyl_showBadge];
                [viewController0 cyl_setBadgeBackgroundColor:UIColor.cyl_randomColor];
                [viewController0 cyl_setBadgeRadius:11/2];
                [viewController0 cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeBreathe];
                [self setSelectedCoverShow:YES];
                // [CN] 以上对Badge的参数设置，需要在 cyl_showBadgeValue 调用之前执行。
                // [EN] The Badge settings above must be applied before cyl_showBadgeValue is called.
                //                [viewController0 cyl_showBadge];
                
                //                                [tabBarController.viewControllers[1] cyl_setBadgeMargin:1.0];
                //                                [tabBarController.viewControllers[2] cyl_setBadgeMargin:1.0];
                //                                [tabBarController.viewControllers[3] cyl_setBadgeMargin:1.0];
                //                                [tabBarController.viewControllers[4] cyl_setBadgeMargin:1.0];
                [tabBarController.viewControllers[1] cyl_setBadgeBackgroundColor:UIColor.cyl_randomColor];
                [tabBarController.viewControllers[1] cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeScale];
                [tabBarController.viewControllers[2] cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeShake];
                
                NSString *testBadgeString = @"100";
                //                [tabBarController.viewControllers[3] cyl_setBadgeMargin:-5];
                //                CGSize size = [testBadgeString sizeWithAttributes:
                //                               @{NSFontAttributeName:
                //                                     tabBarController.viewControllers[3].cyl_badgeFont}];
                //                float labelHeight = ceilf(size.height);
                //                [tabBarController.viewControllers[3] cyl_setBadgeCornerRadius:(labelHeight+ tabBarController.viewControllers[3].cyl_badgeMargin)/2];
                [tabBarController.viewControllers[3] cyl_showBadgeValue:testBadgeString animationType:CYLBadgeAnimationTypeBounce];
                if (tabBarController.viewControllers.count > 4) {
                    // Differs from the global offset (SceneDelegate.m -setUpBadgeAppearance), so it is set here.
                    // 与全局偏移（SceneDelegate.m -setUpBadgeAppearance）不同，因此单独设置。
                    [tabBarController.viewControllers[4] cyl_setBadgeCenterOffset:CGPointMake(-1, 3)];
                    [tabBarController.viewControllers[4] cyl_showBadgeValue:@"NEW" animationType:CYLBadgeAnimationTypeBreathe];
                }
                // #535: the plus button gets a badge too, like the tabs; each tap adds 1 (see -didSelectControl:).
                // #535：PlusButton 也显示角标，与 Tab 一致；每次点击数字加 1（见 -didSelectControl:）。
                [tabBarController cyl_demo_showPlusButtonBadge];
            } @catch (NSException *exception) {
                NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
            }
            
            // [CN] 添加仿淘宝tabbar，第一个tab选中后有图标覆盖
            // [EN] Add a Taobao-style tabbar: when the first tab is selected, an icon covers it
            if (self.selectedIndex != 0) {
                return;
            }
            // tabBarController.selectedIndex = 1;
            
        });
    }];
}
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Disabled demo code, kept for reference. 已停用的演示代码，保留供参考。
#if 0
    CYLFlatDesignMainTabBarController *tabBarController = self;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{});
    // [CN] 延迟是为了演示demo的时候， 方便看清楚badge动画。 非必须。可删除延迟。
    //@try是为了demo演示的时候， 随时调整减少 tabbar items 个数，而不导致崩溃， 非必须， 可删除。
    // [EN] The delay is only so the badge animation is easy to see in the demo. Not required; the delay can be removed.
    //      @try is only so the number of tabbar items can be reduced at any time in the demo without crashing. Not
    //      required; can be removed.
    NSTimeInterval delaySeconds = 1.5;
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        /*return*/;
        @try {
            UIViewController *viewController0 = tabBarController.viewControllers[0];
            // UIControl *tab0 = viewController0.cyl_tabButton;
            // [tab0 cyl_showBadge];
            [viewController0 cyl_setBadgeBackgroundColor:UIColor.cyl_randomColor];
            [viewController0 cyl_setBadgeRadius:11/2];
            [viewController0 cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeBreathe];
            [self setSelectedCoverShow:YES];
            // [CN] 以上对Badge的参数设置，需要在 cyl_showBadgeValue 调用之前执行。
            // [EN] The Badge settings above must be applied before cyl_showBadgeValue is called.
            //                [viewController0 cyl_showBadge];
            
            //                                [tabBarController.viewControllers[1] cyl_setBadgeMargin:1.0];
            //                                [tabBarController.viewControllers[2] cyl_setBadgeMargin:1.0];
            //                                [tabBarController.viewControllers[3] cyl_setBadgeMargin:1.0];
            //                                [tabBarController.viewControllers[4] cyl_setBadgeMargin:1.0];
            [tabBarController.viewControllers[1] cyl_setBadgeBackgroundColor:UIColor.cyl_randomColor];
            [tabBarController.viewControllers[1] cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeScale];
            [tabBarController.viewControllers[2] cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeShake];
            
            NSString *testBadgeString = @"100";
            //                [tabBarController.viewControllers[3] cyl_setBadgeMargin:-5];
            //                CGSize size = [testBadgeString sizeWithAttributes:
            //                               @{NSFontAttributeName:
            //                                     tabBarController.viewControllers[3].cyl_badgeFont}];
            //                float labelHeight = ceilf(size.height);
            //                [tabBarController.viewControllers[3] cyl_setBadgeCornerRadius:(labelHeight+ tabBarController.viewControllers[3].cyl_badgeMargin)/2];
            [tabBarController.viewControllers[3] cyl_showBadgeValue:testBadgeString animationType:CYLBadgeAnimationTypeBounce];
            if (tabBarController.viewControllers.count > 4) {
                // Differs from the global offset (SceneDelegate.m -setUpBadgeAppearance), so it is set here.
                // 与全局偏移（SceneDelegate.m -setUpBadgeAppearance）不同，因此单独设置。
                [tabBarController.viewControllers[4] cyl_setBadgeCenterOffset:CGPointMake(-1, 3)];
                [tabBarController.viewControllers[4] cyl_showBadgeValue:@"NEW" animationType:CYLBadgeAnimationTypeBreathe];
            }
        } @catch (NSException *exception) {
            NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
        }
        
        
    });
    //    });
#endif
}
- (UIButton *)selectedCover {
    //    if (_selectedCover) {
    //        return _selectedCover;
    //    }
    UIButton *selectedCover = [UIButton buttonWithType:UIButtonTypeCustom];
    // Decoration over the selected tab; VoiceOver reads the tab itself, not "home select cover".
    selectedCover.accessibilityElementsHidden = YES;
    
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
    
    // [CN] TODO:  如果是Lottie 动画icon需要添加延迟， 否则， 会在lottie动画未初始化完成前， 就替换， 位置错误。
    // [EN] TODO:  For a Lottie animation icon, a delay is needed; otherwise it is replaced before the lottie animation
    //      finishes initializing, and ends up in the wrong position.
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
            // [EN] The cover is kept on top by -cyl_coverVisiableTabImageViewOrTabButton:.
            // [CN] 封面由该方法保持在最上层。
            
            if (![CYLConstants isLiquidGlassActive]) {
                // [CN] LiquidGlass 已经自带缩放动画， 无需缩放
                // [EN] LiquidGlass already has its own scale animation, so no scaling is needed
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
    // [CN] 选择了 viewController
    // [EN] A viewController was selected
}

#pragma mark - CYLFlatDesignTabBarDelegate
#if CYL_FLATDESIGN_AVAILABLE
- (void)tabBar:(CYLFlatDesignTabBar *)tabBar didSelectItem:(nonnull CYLFlatDesignTabBarItem *)item {
    // [EN] Super keeps the library's tap handling (e.g. a double tap on the selected tab). The selector is shared with
    //      UITabBarDelegate, hence the casts.
    // [CN] 调用 super 以保留本库的点击处理（例如双击选中的 Tab）。该方法名与 UITabBarDelegate 相同，因此需要类型转换。
    [super tabBar:(UITabBar *)(id)tabBar didSelectItem:(UITabBarItem *)(id)item];
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
    NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), @"");
#endif
}

- (void)tabBarController:(CYLTabBarController *)tabBarController didShowTabBar:(CYLFlatDesignTabBar *)tabBar {
#if defined(DEBUG) || defined(BETA)
    NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), @"");
#endif
}

- (void)tabBarController:(CYLTabBarController *)tabBarController willHideTabBar:(CYLFlatDesignTabBar *)tabBar {
#if defined(DEBUG) || defined(BETA)
    NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), @"");
#endif
}

- (void)tabBarController:(CYLTabBarController *)tabBarController didHideTabBar:(CYLFlatDesignTabBar *)tabBar {
#if defined(DEBUG) || defined(BETA)
    NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), @"");
#endif
}

#else
#endif

/*!
 * [EN] #152: the delegate method API of the tab bar item gestures (MainTabBarController shows the block API).
 * [CN] #152：TabBarItem 手势的代理方法方式（MainTabBarController 演示 block 方式）。
 */
- (void)tabBarController:(CYLTabBarController *)tabBarController
didRecognizeTabBarItemGesture:(CYLTabBarItemGesture)gesture
                 control:(UIControl *)control
          viewController:(UIViewController *)viewController {
    [tabBarController cyl_demo_handleTabBarItemGesture:gesture control:control viewController:viewController];
}

- (void)tabBarController:(CYLTabBarController *)tabBarController didSelectControl:(UIControl *)control {
    
#if defined(DEBUG) || defined(BETA)
NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), control);
    // #610 / #408: called for every tab button and for the plus button in the flat design style too; the identifier tells
    // which one was tapped. 扁平样式下点击每个 Tab 按钮和 PlusButton 也会调用；用标识区分是哪一个。
    NSLog(@"🟢 #610 flat design tapped \"%@\" (%@)", control.cyl_tabBarItemIdentifier, [control cyl_isPlusButton] ? @"plus button" : @"tab button");
#endif
    // [EN] #535: the plus button's badge changes on every tap. Checked first: before iOS 26 `-cyl_isTabButton` is YES for the
    // plus button too.
    // [CN] #535：每次点击 PlusButton，角标都会变化。需先判断：iOS 26 以前 `-cyl_isTabButton` 对 PlusButton 也返回 YES。
    // [EN] `-cyl_isPlusControl` also covers the system tab button of the plus child view controller (the layer under the
    // plus button). Guard: plus button code only when this tab bar controller has one.
    // [CN] `-cyl_isPlusControl` 也包括 PlusButton 子控制器的系统 Tab 按钮（PlusButton 下方的图层）。仅在有 PlusButton 时处理 PlusButton。
    BOOL isPlusControl = [tabBarController hasPlusButton] && [control cyl_isPlusControl];
    if (isPlusControl) {
        [tabBarController cyl_demo_plusButtonDidTap];
    }
    if ([control cyl_isTabButton] && !isPlusControl) {
        // [CN] 更改红标状态
        // [EN] Update the red badge state
        if ([control cyl_isShowBadge]) {
            if (CYLTabBarStyleTypeFlatDesign == tabBarController.tabBarStyleType) {
                [control cyl_clearBadge];
            } else {
                [tabBarController.selectedViewController cyl_clearBadge];
                
            }
        } else {
            if (CYLTabBarStyleTypeFlatDesign == tabBarController.tabBarStyleType) {
                [control  cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeScaleOnce];
            } else {
                [tabBarController.selectedViewController cyl_showBadge];
            }
        }
    }
    
    // 即使 PlusButton 也添加了点击事件，点击 PlusButton 后也会触发该代理方法。
    // 可在PlusButton初始化时使用 CYLExternPlusButton.cyl_userInteractionDisabled = YES; 来禁止该协议方法触发plusButton回调
    // Rotating the tapped icon is disabled, the badge would rotate too. To enable it:
    // 暂时不推荐用旋转方式，badge也会旋转。如需启用：
    //    // The plus button of this tab bar controller's context (`CYLExternPlusButton` is the one registered last).
    //    UIView *animationView = [control cyl_isPlusButton] ? [CYLPlusButton plusButtonForOwner:tabBarController].imageView : [control cyl_tabImageView];
    //    [self addRotateAnimationOnView:animationView];
    
    // [CN] 添加仿淘宝tabbar，第一个tab选中后有图标覆盖
    // [EN] Add a Taobao-style tabbar: when the first tab is selected, an icon covers it
    if ([control cyl_isTabButton] || [control cyl_isPlusButton]) {
        //        BOOL shouldSelectedCoverShow = (self.selectedIndex == 0);
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

/*!
 * [EN] Issue #428: plays the Lottie icons 1.5 times as fast, the same as in the other styles.
 * [CN] Issue #428：Lottie 图标以 1.5 倍速播放，与其他样式一致。
 */
- (CGFloat)lottieAnimationSpeed {
    return 1.5;
}

@end
