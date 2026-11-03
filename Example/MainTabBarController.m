//
//  MainTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
#import "MainTabBarController.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/UIImage+CYLTabBarControllerExtention.h>
#else
#import "UIImage+CYLTabBarControllerExtention.h"
#endif
static CGFloat const CYLTabBarControllerHeight = 40.f;

//View Controllers
#import "CYLHomeViewController.h"
#import "CYLMessageViewController.h"
#import "CYLMineViewController.h"
#import "CYLSameCityViewController.h"


@interface MainTabBarController ()<CYLTabBarControllerDelegate, CYLFlatDesignUITabBarControllerDelegate>

@property (nonatomic, weak) UIButton *selectedCover;

@property (nonatomic, assign) CGRect tabBarBounds;

@end

@implementation MainTabBarController

- (instancetype)initWithContext:(NSString *)context {
    /**
     * 以下两行代码目的在于手动设置让TabBarItem只显示图标，不显示文字，并让图标垂直居中。
     * 等 效于在 `-tabBarItemsAttributesForController` 方法中不传 `CYLTabBarItemTitle` 字段。
     * 更推荐后一种做法。
     */
    UIEdgeInsets imageInsets = UIEdgeInsetsZero;//UIEdgeInsetsMake(4.5, 0, -4.5, 0);
    UIOffset titlePositionAdjustment = UIOffsetMake(0, -3.5);
    CYLTabBarStyleType tabBarStyleType;
    //    tabBarStyleType = CYLTabBarStyleTypeFlatDesign;
    // 设置 TabBar 样式：液态玻璃效果（覆盖上一行）
    //    tabBarStyleType = CYLTabBarStyleTypeLiquidGlass;
    tabBarStyleType = CYLTabBarStyleTypeDefault;
    
    if (self = [super initWithViewControllers:[self viewControllersForTabBar]
                        tabBarItemsAttributes:[self tabBarItemsAttributesForTabBar]
                                  imageInsets:imageInsets
                      titlePositionAdjustment:titlePositionAdjustment
                                    styleType:tabBarStyleType
                                      context:context]) {
        //        self.adjustTabBarItemImageViewSizeDependOnSuperView = NO;
        
        [self customizeTabBarAppearanceWithTitlePositionAdjustment:titlePositionAdjustment];
        self.delegate = self;
        self.navigationController.navigationBar.hidden = YES;
    }
    return self;
}

- (void)viewDidLoad {
    // * @attention 请在父类的 ViewDidLoad 调用之前设置CYLTabBarStyleType。最佳位置是initWithViewControllers方法内部， 最晚在在 `-[super viewDidLoad];` 之前调用。因为 需要在 tabBar 的KVC操作之前确定自定义样式，否则， 就会执行默认逻辑， 可能会导致你的自定义样式失效。
    //    self.tabBarStyleType = CYLTabBarStyleTypeFlatDesign;
    [[UIApplication sharedApplication] setApplicationSupportsShakeToEdit:YES];
    [self becomeFirstResponder];
    [self customizeInterface];
    // Issue #426: on a memory warning, unload the views of the tabs that are not selected; they load again when selected.
    // Issue #426：收到内存警告时卸载未选中 Tab 的视图，切换到该 Tab 时重新加载。
    self.unloadsUnselectedViewsOnMemoryWarning = YES;
    [super viewDidLoad];
    [self observeLottieAnimationViewDidAdd];
}

/*!
 * [EN] Issue #428: called once for each Lottie view, after `-lottieAnimationSpeed` was applied. Set a different speed for
 *      one tab here with `-[UIControl cyl_setLottieAnimationSpeed:]`.
 * [CN] Issue #428：每个 Lottie 视图添加后回调一次，此时已设置 `-lottieAnimationSpeed`。可在这里用
 *      `-[UIControl cyl_setLottieAnimationSpeed:]` 为某一个 Tab 单独设置速度。
 */
- (void)observeLottieAnimationViewDidAdd {
    __weak __typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemLottieAnimationViewDidAddNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        UIControl *tabButton = note.object;
        if (tabButton.cyl_tabBarController != weakSelf) {
            return;
        }
        NSLog(@"🟢 Lottie view added: tab %@, animationSpeed %@", @(tabButton.cyl_tabBarChildViewControllerIndex),
              [(id)tabButton.cyl_lottieAnimationView valueForKey:@"animationSpeed"]);
    }];
}

/*!
 * [EN] Issue #428: plays the Lottie icons 1.5 times as fast. No need to wait for the Lottie views to be added.
 * [CN] Issue #428：Lottie 图标以 1.5 倍速播放，无需等待 Lottie 视图添加完成。
 */
- (CGFloat)lottieAnimationSpeed {
    return 1.5;
}

- (NSArray *)viewControllersForTabBar {
    CYLHomeViewController *firstViewController = [[CYLHomeViewController alloc] init];
    UIViewController *firstNavigationController = [[CYLBaseNavigationController alloc]
                                                   initWithRootViewController:firstViewController];
    [firstViewController cyl_setHideNavigationBarSeparator:YES];
    // [firstViewController cyl_setNavigationBarHidden:YES];
    CYLSameCityViewController *secondViewController = [[CYLSameCityViewController alloc] init];
    UIViewController *secondNavigationController = [[CYLBaseNavigationController alloc]
                                                    initWithRootViewController:secondViewController];
    [secondViewController cyl_setHideNavigationBarSeparator:YES];
    // [secondViewController cyl_setNavigationBarHidden:YES];
    
    CYLMessageViewController *thirdViewController = [[CYLMessageViewController alloc] init];
    UIViewController *thirdNavigationController = [[CYLBaseNavigationController alloc]
                                                   initWithRootViewController:thirdViewController];
    [thirdViewController cyl_setHideNavigationBarSeparator:YES];
    CYLMineViewController *fourthViewController = [[CYLMineViewController alloc] init];
    UIViewController *fourthNavigationController = [[CYLBaseNavigationController alloc]
                                                    initWithRootViewController:fourthViewController];
    [fourthNavigationController cyl_setHideNavigationBarSeparator:YES];
    NSArray *viewControllers = @[
        firstNavigationController,
        secondNavigationController,
        thirdNavigationController,
        fourthNavigationController
    ];
    for (NSInteger i = 0; i < self.tabBarItemsAttributesForTabBar.count; i++) {
        UIViewController *vc = viewControllers[i];
        NSDictionary *firstTabBarItemsAttributes = self.tabBarItemsAttributesForTabBar[i];
        //        vc.title = firstTabBarItemsAttributes[CYLTabBarItemTitle];
        NSString *title = firstTabBarItemsAttributes[CYLTabBarItemTitle];
        if ([CYLConstants isLiquidGlassActive]) {
            title = [NSString stringWithFormat:@"%@%@", firstTabBarItemsAttributes[CYLTabBarItemTitle],CYLLocalizedString(@"（液态）")];
        }
        vc.cyl_getViewControllerInsteadOfNavigationController.title  = title;
        
        //        [self setupChildViewController:nav
        //                                 title:titles[i]
        //                             imageName:images[i]
        //                     selectedImageName:selectedImages[i]
        //                        lottieFilePath:lottieFilePaths[i]];
        
        
        
        //        if (i == 0) {
        //            nav.cyl_tabBarItem.badgeValue = @"1";
        //        } else if (i == 1) {
        //            nav.cyl_tabBarItem.badgeValue = @"11";
        //            nav.cyl_tabBarItem.badgeColor = UIColor.systemBlueColor;
        //        } else if (i == 2) {
        //            nav.cyl_tabBarItem.imagePositionAdjustment = UIOffsetMake(0, -12);
        //        } else if (i == 3) {
        //            nav.cyl_tabBarItem.badgeValue = @"新消息";
        //            [nav.cyl_tabBarItem setBadgeTextAttributes:@{NSForegroundColorAttributeName:UIColor.greenColor} forState:UIControlStateNormal];
        //        } else if (i == 4) {
        //            // 设置badgeSize不为CGSizeZero、badgeValue为nil，就变成一个点了
        //            nav.cyl_tabBarItem.badgeValue = nil;
        //            nav.cyl_tabBarItem.badgeSize = CGSizeMake(10, 10);
        //            nav.cyl_tabBarItem.badgeColor = UIColor.systemRedColor;
        //        }
        
    }
    return viewControllers;
}

- (NSArray *)tabBarItemsAttributesForTabBar {
    return [[self class] tabBarItemsAttributesForTabBar];
}
+ (NSArray *)tabBarItemsAttributesForTabBar {
    
    // lottie动画的json文件来自于NorthSea, respect!
    // Dark Mode (#620), three ways, one per tab: "首页" by naming convention, "消息" a UIImage built from two images,
    // "我的" an asset catalog Dark appearance (recommended). The icons show when Lottie is off; with Lottie the
    // animations below replace them. See also the flat design demo page.
    // 深色模式（#620）三种方式，每个 Tab 一种：「首页」按命名规范，「消息」用两张图合成的 UIImage，「我的」用 Asset Catalog 的
    // Dark 外观（推荐）。关闭 Lottie 时显示这些图标；开启时由下方的 Lottie 动画代替。另见扁平样式的演示页。
    //    CGFloat firstXOffset = -12/2;
    NSDictionary *firstTabBarItemsAttributes = @{
        CYLTabBarItemTitle : CYLLocalizedString(@"首页"),
        CYLTabBarItemIdentifier : @"home",  // #408: stays right when tabs are added or removed. Tab 增减后依然准确。
        // A name also loads "<name>_dark" when that image exists: here home_normal_dark (UIImage.cyl_darkImageNameSuffix).
        // 图片名会同时加载存在的「<name>_dark」：这里是 home_normal_dark（UIImage.cyl_darkImageNameSuffix）。
        CYLTabBarItemImage : @"home_normal",  /* NSString and UIImage are supported*/
        CYLTabBarItemSelectedImage : @"home_highlight",  /* NSString and UIImage are supported*/
        //                                                 CYLTabBarItemTitlePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(firstXOffset, -3.5)],
        //                                                 CYLTabBarItemImagePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(firstXOffset, -3.5)],
        //第一位 右大，下大
                CYLTabBarLottieFilePath : [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_home" ofType:@"json"],
                // #442: the Dark Mode version of the animation; switches with the style. 深色模式下的动画，随风格自动切换。
                CYLTabBarLottieDarkFilePath : [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_home_dark" ofType:@"json"],
        //                                                 CYLTabBarLottieSize: [NSValue valueWithCGSize:CGSizeMake(22, 22)]
    };
    //    CGFloat secondXOffset = (-25+2)/2;
    NSDictionary *secondTabBarItemsAttributes = @{
        CYLTabBarItemTitle : CYLLocalizedString(@"同城"),
        CYLTabBarItemIdentifier : @"city",
        CYLTabBarItemImage :@"fishpond_normal",
        CYLTabBarItemSelectedImage : @"fishpond_highlight",
        //                                                  CYLTabBarItemTitlePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(secondXOffset, -3.5)],
        //                                                  CYLTabBarItemImagePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(firstXOffset, -3.5)],
        CYLTabBarLottieFilePath : [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_discover" ofType:@"json"],
        CYLTabBarLottieDarkFilePath : [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_discover_dark" ofType:@"json"],
        //                                                  CYLTabBarLottieSize: [NSValue valueWithCGSize:CGSizeMake(22, 22)]
    };
    
    NSDictionary *thirdTabBarItemsAttributes = @{
        CYLTabBarItemTitle : CYLLocalizedString(@"消息"),
        CYLTabBarItemIdentifier : @"message",
        // A dark image under any name. Names are the prepared form (rendered as original, #465); a UIImage object for
        // the same is `[UIImage cyl_imageWithImageInfo:@"message_normal" darkImageInfo:@"message_normal_night"]`.
        // 任意名称的深色图片。图片名是库预先处理好的形式（按原图渲染，#465）；同样效果的 UIImage 对象为
        // `[UIImage cyl_imageWithImageInfo:@"message_normal" darkImageInfo:@"message_normal_night"]`。
        CYLTabBarItemImage : @"message_normal",
        CYLTabBarItemDarkImage : @"message_normal_night",
        CYLTabBarItemSelectedImage : @"message_highlight",
        //                                                 CYLTabBarItemTitlePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(-secondXOffset, -3.5)],
        //                                                 CYLTabBarItemImagePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(firstXOffset, -3.5)],
        CYLTabBarLottieFilePath : [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_news" ofType:@"json"],
        CYLTabBarLottieDarkFilePath : [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_news_dark" ofType:@"json"],
        //                                                 CYLTabBarLottieSize: [NSValue valueWithCGSize:CGSizeMake(22, 22)]
    };
    NSDictionary *fourthTabBarItemsAttributes = @{
        CYLTabBarItemTitle : CYLLocalizedString(@"我的"),
        // No CYLTabBarItemIdentifier: the default is the class name, "CYLMineViewController" (#408).
        // 未设置 CYLTabBarItemIdentifier：默认值为类名 "CYLMineViewController"（#408）。
        // account_normal has its own Dark appearance in Images.xcassets; it wins over any "_dark" image.
        // account_normal 在 Images.xcassets 中自带 Dark 外观，优先于任何「_dark」图片。
        CYLTabBarItemImage : @"account_normal",
        CYLTabBarItemSelectedImage : @"account_highlight",
        //                                                  CYLTabBarItemTitlePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(-firstXOffset, -3.5)],
        //                                                  CYLTabBarItemImagePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(firstXOffset, -3.5)],
        CYLTabBarLottieFilePath : [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_mine" ofType:@"json"],
        CYLTabBarLottieDarkFilePath : [[NSBundle mainBundle] pathForResource:@"green_lottie_tab_mine_dark" ofType:@"json"],
        //                                                  CYLTabBarLottieSize: [NSValue valueWithCGSize:CGSizeMake(22, 22)]
    };
    NSArray *tabBarItemsAttributes = @[
        firstTabBarItemsAttributes,
        secondTabBarItemsAttributes,
        thirdTabBarItemsAttributes,
        fourthTabBarItemsAttributes
    ];
    return tabBarItemsAttributes;
}

/**
 *  更多TabBar自定义设置：比如：tabBarItem 的选中和不选中文字和背景图片属性、tabbar 背景图片属性等等
 */
+ (UITabBarAppearance *)demoStandardAppearanceWithTitlePositionAdjustment:(UIOffset)titlePositionAdjustment {
    // set the text color for unselected state
    // 普通状态下的文字属性
    NSDictionary *normalAttrs = @{
        NSForegroundColorAttributeName : [UIColor redColor],
        NSFontAttributeName : [UIFont systemFontOfSize:10],
    };
    // set the text color for selected state
    // 选中状态下的文字属性
    NSDictionary *selectedAttrs = @{
        NSForegroundColorAttributeName : [UIColor cyl_systemGreenColor],
        NSFontAttributeName : [UIFont systemFontOfSize:10],
    };
    UITabBarItemAppearance *stackedLayoutAppearance = [[UITabBarItemAppearance alloc] init];
    // fix https://github.com/ChenYilong/CYLTabBarController/issues/456
    stackedLayoutAppearance.normal.titlePositionAdjustment = titlePositionAdjustment;
    // set the text Attributes
    // 设置文字属性
    [stackedLayoutAppearance.normal setTitleTextAttributes:normalAttrs];
    [stackedLayoutAppearance.selected setTitleTextAttributes:selectedAttrs];
    // The icon colors follow the titles (template images); FlatDesign maps them too.
    // 图标颜色与标题一致（模板图片）；扁平样式同样映射。
    stackedLayoutAppearance.selected.iconColor = [UIColor cyl_systemGreenColor];

    UITabBarAppearance *standardAppearance = [[UITabBarAppearance alloc] init];
    standardAppearance.stackedLayoutAppearance = stackedLayoutAppearance;
    standardAppearance.inlineLayoutAppearance = stackedLayoutAppearance;
    standardAppearance.compactInlineLayoutAppearance = stackedLayoutAppearance;
    //FIX: #581 iOS15以上，iOS26以下，可以设置。
    //iOS26 不推荐设置 `UITabBar.appearance().backgroundColor`。因为玻璃效果下，不仅无法设置背景，同时会干扰 TabBar 里的 Label 未选中颜色，因为 iOS26 里的未选中时的 Label 颜色为系统内部逻辑， 无法自定义。所以如果背景颜色， 与Label颜色一致，白底白字， 用户将无法辨认。暗黑模式下， 也会有类似问题。
    if (!CYL_IS_IOS_26) {
        //            standardAppearance.backgroundColor = [UIColor cyl_systemBackgroundColor];
    }
    //shadowColor和shadowImage均可以自定义颜色, shadowColor默认高度为1, shadowImage可以自定义高度.
    standardAppearance.shadowColor = [UIColor cyl_systemGreenColor];
    // standardAppearance.shadowImage = [[self class] imageWithColor:[UIColor cyl_systemGreenColor] size:CGSizeMake(self.cyl_tabBarController.visiableTabBarSize.width, 1)];
    return standardAppearance;
}

- (void)customizeTabBarAppearanceWithTitlePositionAdjustment:(UIOffset)titlePositionAdjustment {
    //    if ([CYLConstants isLiquidGlassActive]) {
    //        return;
    //    }
    // Customize UITabBar height
    // 自定义 TabBar 高度
    //     [self cyl_tabBarController].tabBarHeight = CYL_IS_IPHONE_X ? 65 : 40;
    
    [self rootWindow].backgroundColor = [UIColor cyl_systemBackgroundColor];
    
    // set the text color for unselected state
    // 普通状态下的文字属性
    NSMutableDictionary *normalAttrs = [NSMutableDictionary dictionary];
    normalAttrs[NSForegroundColorAttributeName] = [UIColor redColor];
    normalAttrs[NSFontAttributeName] = [UIFont systemFontOfSize:10];
    
    // set the text color for selected state
    // 选中状态下的文字属性
    NSMutableDictionary *selectedAttrs = [NSMutableDictionary dictionary];
    selectedAttrs[NSForegroundColorAttributeName] = [UIColor cyl_systemGreenColor];
    selectedAttrs[NSFontAttributeName] = [UIFont systemFontOfSize:10];
    
    // Set the dark color to selected tab (the dimmed background)
    // TabBarItem选中后的背景颜色
    //     [self customizeTabBarSelectionIndicatorImage];
    
    // update TabBar when TabBarItem width did update
    // If your app need support UIDeviceOrientationLandscapeLeft or UIDeviceOrientationLandscapeRight，
    // remove the comment '//'
    // 如果你的App需要支持横竖屏，请使用该方法移除注释 '//'
    //     [self updateTabBarCustomizationWhenTabBarItemWidthDidUpdate];
    
    // 半透明， 需要注意：iOS26 液态玻璃下， 具有特殊效果， View 将延伸至TabBar以外区域。
    //如果想固定 TabBar 的背景色，就通过控制 translucent，否则默认一直都是透视的
    
    if (CYL_IS_IOS_26) {
        //        [UITabBar appearance].translucent = NO;
    }
    
    
    
    //     [[UITabBar appearance] setBackgroundImage:[[self class] imageWithColor:[UIColor whiteColor] size:CGSizeMake(self.cyl_tabBarController.visiableTabBarSize.width, tabBarController.tabBarHeight ?: (CYL_IS_IPHONE_X ? 65 : 40))]];
    //    [[UITabBar appearance] setUnselectedItemTintColor:[UIColor systemGrayColor]];
    
    //Three way to deal with shadow 三种阴影处理方式：
    // NO.3, without shadow : use -[[CYLTabBarController hideTabBarShadowImageView] in CYLMainRootViewController.m
    
    // NO.2，using layer to add shadow.
    //    CYLTabBarController *tabBarController = [self cyl_tabBarController];
    //    tabBarController.tabBar.layer.shadowColor = [UIColor blackColor].CGColor;
    //    tabBarController.tabBar.layer.shadowRadius = 15.0;
    //    tabBarController.tabBar.layer.shadowOpacity = 1;
    //    tabBarController.tabBar.layer.shadowOffset = CGSizeMake(0, 3);
    //    tabBarController.tabBar.layer.masksToBounds = NO;
    //    tabBarController.tabBar.clipsToBounds = NO;
    
    // NO.1，using Image note:recommended.推荐方式
    // set the bar shadow image
    // without shadow : use -[[CYLTabBarController hideTabBarShadowImageView] in CYLMainRootViewController.m
    if (@available(iOS 13.0, *)) {
        self.tabBar.unselectedItemTintColor = normalAttrs[NSForegroundColorAttributeName];
        
        // The same appearance also styles the FlatDesign tab bar, see CYLFlatDesignMainTabBarController.
        // 同一个 appearance 同样作用于扁平样式 TabBar，见 CYLFlatDesignMainTabBarController。
        UITabBarAppearance *standardAppearance = [[self class] demoStandardAppearanceWithTitlePositionAdjustment:titlePositionAdjustment];
        self.tabBar.standardAppearance = standardAppearance;
        self.tabBar.scrollEdgeAppearance = standardAppearance;
        
        self.tabBar.unselectedItemTintColor = normalAttrs[NSForegroundColorAttributeName];
        //        self.tabBar.barTintColor = [UIColor whiteColor];
        //        self.tabBar.shadowImage = [UIImage cyl_imageWithColor:[UIColor.lightGrayColor colorWithAlphaComponent:0.5] size:CGSizeMake(1, 1)];
        
        
    } else {
        // Override point for customization after application launch.
        // set the text Attributes
        // 设置文字属性
        UITabBarItem *tabBar = [UITabBarItem appearance];
        [tabBar setTitleTextAttributes:normalAttrs forState:UIControlStateNormal];
        [tabBar setTitleTextAttributes:selectedAttrs forState:UIControlStateSelected];
        
        // This shadow image attribute is ignored if the tab bar does not also have a custom background image.So at least set somthing.
        [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
        //FIX: #581
        // set background color
        // 设置 TabBar 背景
        [[UITabBar appearance] setBarTintColor:[UIColor cyl_systemBackgroundColor]];
        [[UITabBar appearance] setBackgroundColor:[UIColor cyl_systemBackgroundColor]];
        
        [[UITabBar appearance] setShadowImage:[UIImage cyl_imageWithColor:[UIColor cyl_systemGreenColor] size:CGSizeMake(self.cyl_tabBarController.visiableTabBarSize.width, 1)]];
        [self.tabBarItem setTitleTextAttributes:normalAttrs forState:UIControlStateNormal];
        [self.tabBarItem setTitleTextAttributes:selectedAttrs forState:UIControlStateSelected];
    }
    
    //    [[UITabBar appearance] setBackgroundColor:[UIColor clearColor]];
    
    if (!CYL_IS_IOS_26) {
        //iOS26 不推荐设置 `UITabBar.appearance().backgroundColor` 玻璃效果下，不仅无法设置背景，同时会干扰 TabBar 里的 Label 未选中颜色，因为 iOS26 里的未选中时的 Label 颜色为系统内部逻辑， 无法自定义。所以如果背景颜色， 与Label颜色一致，白底白字， 用户将无法辨认。暗黑模式下， 也会有类似问题。
        [UITabBar appearance].translucent = NO;
    }
    
}

- (void)updateTabBarCustomizationWhenTabBarItemWidthDidUpdate {
    void (^deviceOrientationDidChangeBlock)(NSNotification *) = ^(NSNotification *notification) {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        if ((orientation == UIDeviceOrientationLandscapeLeft) || (orientation == UIDeviceOrientationLandscapeRight)) {
            NSLog(@"Landscape Left or Right !");
        } else if (orientation == UIDeviceOrientationPortrait) {
            NSLog(@"Landscape portrait!");
        }
        [self customizeTabBarSelectionIndicatorImage];
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemWidthDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:deviceOrientationDidChangeBlock];
}

- (void)customizeTabBarSelectionIndicatorImage {
    if (CYL_IS_IOS_26) {
        return;
    }
    ///Get initialized TabBar Height if exists, otherwise get Default TabBar Height.
    CGFloat tabBarHeight = CYLTabBarControllerHeight;
    // This tab bar's own item width (the global `CYLTabBarItemWidth` is what was written last, by any tab bar).
    CGSize selectionIndicatorImageSize = CGSizeMake(self.cyl_tabBar.cyl_tabBarItemWidth, tabBarHeight);
    //Get initialized TabBar if exists.
    UITabBar *tabBar = self.tabBar ?: [UITabBar appearance];
    UIImage *image = [UIImage cyl_imageWithColor:[UIColor redColor]
                                            size:selectionIndicatorImageSize];
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(1, 0, 0, 0)];
    [tabBar setSelectionIndicatorImage:image];
}

+ (UIImage *)scaleImage:(UIImage *)image {
    CGFloat halfWidth = image.size.width/2;
    CGFloat halfHeight = image.size.height/2;
    UIImage *secondStrechImage = [image resizableImageWithCapInsets:UIEdgeInsetsMake(halfHeight, halfWidth, halfHeight, halfWidth) resizingMode:UIImageResizingModeStretch];
    return secondStrechImage;
}

- (void)dealloc {
    @try {
        //iOS9之后， 不再必须， 因此， 并非核心逻辑， 未来考虑删除。
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
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
    // selectedCover.userInteractionEnabled = false;
    //    _selectedCover = selectedCover;
    return selectedCover;
}

- (void)setSelectedCoverShow:(BOOL)show {
    UIControl *selectedTabButton = [self.viewControllers[0] cyl_tabButton];
    __weak __typeof(self) weakSelf = self;
    //TODO:  如果是Lottie 动画icon需要添加延迟， 否则， 会在lottie动画未初始化完成前， 就替换， 位置错误。
    [selectedTabButton cyl_coverVisiableTabImageViewOrTabButton:YES
                                                 contentNewView:self.selectedCover
                                          seclectContentNewView:self.selectedCover
                                                         offset:UIOffsetZero
                                                           show:show
                                        delayIfNeededForSeconds:0.1
                                                     completion:^(BOOL isReplaced, UIControl * _Nonnull tabBarButton, UIView * _Nonnull newView) {
        __strong typeof(self) self = weakSelf;
        if (!self) {
            return;
        }
        if (isReplaced && show && newView) {
            [self.viewControllers[0] cyl_clearBadge];
            //            [tabBarButton insertSubview:tabBarButton.cyl_lottieAnimationView belowSubview:selectedTabButton];
            //            [tabBarButton bringSubviewToFront:newView];
            // The cover is kept on top by -cyl_coverVisiableTabImageViewOrTabButton:. 封面由该方法保持在最上层。
            if (![CYLConstants isLiquidGlassActive]) {
                // LiquidGlass 已经自带缩放动画， 无需缩放
                [self addOnceScaleAnimationOnView:newView];
            }
        }
    }];
}

//缩放动画
- (void)addOnceScaleAnimationOnView:(UIView *)animationView {
    //需要实现的帧动画，这里根据需求自定义
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"transform.scale";
    animation.values = @[@1.5, @1.0];
    animation.duration = 0.1;
    //    animation.repeatCount = repeatCount;
    animation.calculationMode = kCAAnimationCubic;
    [animationView.layer addAnimation:animation forKey:nil];
}
//
- (void)traitCollectionDidChange:(nullable UITraitCollection *)previousTraitCollection  {
    [super traitCollectionDidChange:previousTraitCollection];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        // #620: compare this controller's own traits. The window scene's traits ignore `overrideUserInterfaceStyle` on
        // the window or a view controller, so they only ever report the system style.
        // #620：比较本控制器自身的 trait。window scene 的 trait 不认 window 或视图控制器上的 `overrideUserInterfaceStyle`，只反映系统风格。
        if (![self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            return;
        }
#else
#endif
        //TODO:
        [[UIViewController cyl_topmostViewController].navigationController.navigationBar setBarTintColor:[UIColor cyl_systemBackgroundColor]];
    }
#endif
    
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
        
        if (!CYL_IS_IOS_26) {
            [self customizeTabBarSelectionIndicatorImage];
            //           [self updateSelectionIndicatorColor:[UIColor greenColor]];
        }
        
        
        //延迟是为了演示demo的时候， 方便看清楚badge动画。 非必须。可删除延迟。
        //@try是为了demo演示的时候， 随时调整减少 tabbar items 个数，而不导致崩溃， 非必须， 可删除。
        NSTimeInterval delaySeconds = 1.5;
        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
        dispatch_after(when, dispatch_get_main_queue(), ^{
            @try {
                // #425: the shared badge style (offset, colors, font) is set once in SceneDelegate.m
                // -setUpBadgeAppearance; each tab below sets only what differs from it.
                // #425：共用的角标样式（偏移、颜色、字体）在 SceneDelegate.m -setUpBadgeAppearance 中统一设置一次，
                // 下面每个 Tab 只设置与之不同的部分。
                UIViewController *viewController0 = tabBarController.viewControllers[0];
                // UIControl *tab0 = viewController0.cyl_tabButton;
                // [tab0 cyl_showBadge];
                [viewController0 cyl_setBadgeBackgroundColor:UIColor.cyl_randomColor];
                [viewController0 cyl_setBadgeRadius:11/2];
                [viewController0 cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeBreathe];
                [self setSelectedCoverShow:YES];
                //以上对Badge的参数设置，需要在 cyl_showBadgeValue 调用之前执行。
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


#pragma mark - delegate

- (BOOL)tabBarController:(CYLTabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    UIControl *tabButton = viewController.tabBarItem.cyl_visiableTabButton;
    BOOL shouldSelectViewControllerFromSuper = [super tabBarController:tabBarController shouldSelectViewController:viewController];
    
#if defined(DEBUG) || defined(BETA)
    // test for issue #642
    //    self.selectedIndex = [self.viewControllers indexOfObject:viewController];
    
    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：index%@ title%@", @(__PRETTY_FUNCTION__), @(__LINE__), @([self.viewControllers indexOfObject:viewController]), viewController.title);
#endif
    if ([tabButton cyl_isPlusControl]) {
        //FIXME:  to delete 玻璃效果下， 不能调用 updateSelectionStatusIfNeededForTabBarController，selectedViewController， selectedIndex 否则无法实现plusButton的点击事件响应， 响应的仅仅是tabButton
        //         [self updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController];
        // tabBarController.selectedViewController = viewController;
        // tabBarController.selectedIndex = control.cyl_tabBarItemVisibleIndex;
        // [tabBarController cyl_popSelectTabBarChildViewControllerAtIndex:control.cyl_tabBarItemVisibleIndex];
        
        //        return shouldSelectViewControllerFromSuper;
    }
    //    if (0 == [tabBarController.viewControllers indexOfObject:viewController]) {
    //        [self setSelectedCoverShow:YES];
    //    } else {
    //        [self setSelectedCoverShow:NO];
    //    }
    BOOL should = YES;
    
    UIControl *selectedTabButton = [viewController.tabBarItem cyl_tabButton];
    if (selectedTabButton.selected && [[[self class] cyl_topmostViewController] respondsToSelector:@selector(refresh)]) {
        //双重点击， 触发刷新。
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS(
                                                [[[self class] cyl_topmostViewController] performSelector:@selector(refresh)];
                                                
                                                );
    }
    return should && shouldSelectViewControllerFromSuper;
}

- (BOOL)tabBarController:(CYLTabBarController *)tabBarController shouldShowPlatterLiquidLensViewForControl:(UIControl *)control {
    [super tabBarController:tabBarController shouldShowPlatterLiquidLensViewForControl:control];
    return YES;
}

#pragma mark - CYLFlatDesignTabBarDelegate


/*!
 * #408: tabs by identifier, not by index, so it stays right when tabs are added or removed. Called for every tab button
 * and for the plus button. Each tab bar controller (this context, the "CYLSecondPlusButtonContext" one, a pushed one)
 * answers for its own tabs and plus button.
 * #408：按标识而不是下标区分 Tab，增减 Tab 后依然准确。点击任意 Tab 按钮和 PlusButton 都会调用。每个 TabBarController
 * （当前 context、"CYLSecondPlusButtonContext"、push 出来的）只处理自己的 Tab 和 PlusButton。
 */
- (void)cyl_logTabBarItemIdentifiersForTabBarController:(CYLTabBarController *)tabBarController selectedControl:(UIControl *)control {
    // 1. Print: the tapped control and all of this tab bar controller's identifiers. 打印：点击的按钮及全部标识。
    NSString *identifier = control.cyl_tabBarItemIdentifier;
    NSLog(@"🟢 #408 [%@] tapped \"%@\" (selected \"%@\")", tabBarController.context, identifier, tabBarController.cyl_selectedTabBarItemIdentifier);
    for (NSString *eachIdentifier in tabBarController.cyl_tabBarItemIdentifiers) {
        UIControl *eachControl = [tabBarController cyl_controlWithTabBarItemIdentifier:eachIdentifier];
        NSLog(@"   \"%@\": index %@, %@", eachIdentifier, @([tabBarController cyl_indexOfTabBarItemIdentifier:eachIdentifier]),
              [eachControl cyl_isPlusButton] ? @"plus button" : @"tab button");
    }
    // 2. Use: handle each tab by identifier. 使用：按标识处理每个 Tab。
    if ([identifier isEqualToString:@"plus"] || [identifier isEqualToString:@"camera"]) {
        NSLog(@"   plus button of context %@", tabBarController.context);
    } else if ([identifier isEqualToString:@"message"]) {
        NSLog(@"   message tab, wherever it is now");
    } else if ([identifier isEqualToString:@"CYLMineViewController"]) {
        NSLog(@"   mine tab, by its default identifier (class name)");
    }
}

- (void)tabBarController:(CYLTabBarController *)tabBarController didSelectControl:(UIControl *)control {
    [self cyl_logTabBarItemIdentifiersForTabBarController:tabBarController selectedControl:control];
    UIView *animationView;
    
    // #535: the plus button's badge changes on every tap. Checked first: before iOS 26 `-cyl_isTabButton` is YES for the
    // plus button too. #535：每次点击 PlusButton，角标都会变化。需先判断：iOS 26 以前 `-cyl_isTabButton` 对 PlusButton 也返回 YES。
    // `-cyl_isPlusControl` also covers the system tab button of the plus child view controller (the layer under the
    // plus button). `-cyl_isPlusControl` 也包括 PlusButton 子控制器的系统 Tab 按钮（PlusButton 下方的图层）。
    // Guard: plus button code only when this tab bar controller has one. 仅在有 PlusButton 时处理 PlusButton。
    BOOL isPlusControl = [tabBarController hasPlusButton] && [control cyl_isPlusControl];
    if (isPlusControl) {
        [tabBarController cyl_demo_plusButtonDidTap];
    }
    if ([control cyl_isTabButton] && !isPlusControl) {
        //更改红标状态
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
        animationView = [control cyl_tabImageView];
    }
    
    // The plus button of this tab bar controller's context (`CYLExternPlusButton` is the one registered last).
    UIButton *button = [CYLPlusButton plusButtonForOwner:tabBarController];
    BOOL isPlusButton = [tabBarController hasPlusButton] && [control cyl_isPlusControl];
    // 即使 PlusButton 也添加了点击事件，点击 PlusButton 后也会触发该代理方法。
    // 可在PlusButton初始化时使用 CYLExternPlusButton.cyl_userInteractionDisabled = YES; 来禁止该协议方法触发plusButton回调
    if (isPlusButton) {
        animationView = button.imageView;
    }
    
    [self addScaleAnimationOnView:animationView repeatCount:1];
    // [self addRotateAnimationOnView:animationView];//暂时不推荐用旋转方式，badge也会旋转。
    
    //添加仿淘宝tabbar，第一个tab选中后有图标覆盖
    if ([control cyl_isTabButton] || [control cyl_isPlusButton]) {
        //        BOOL shouldSelectedCoverShow = (self.selectedIndex == 0);
        //        [self setSelectedCoverShow:shouldSelectedCoverShow];
    }
}
//缩放动画
- (void)addScaleAnimationOnView:(UIView *)animationView repeatCount:(float)repeatCount {
    if (CYL_IS_IOS_26) {
        //不建议在iOS26上给PlusButton添加动画， 因为在玻璃遮罩显示时， 玻璃遮罩本身就有缩放动画， 再添加动画， 会非常冗余。
        return;
    }
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
    if (CYL_IS_IOS_26) {
        //不建议在iOS26上给PlusButton添加动画， 因为在玻璃遮罩显示时， 玻璃遮罩本身就有缩放动画， 再添加动画， 会非常冗余。
        return;
    }
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
    CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.y"];
    
    // 设定动画选项
    rotateAnimation.duration = 1.2; // 持续时间
    rotateAnimation.repeatCount = 1; // 重复次数
    
    // 设定旋转角度
    rotateAnimation.fromValue = [NSNumber numberWithFloat:0.0]; // 起始角度
    rotateAnimation.toValue = [NSNumber numberWithFloat:2 * M_PI]; // 终止角度
    
    [animationView.layer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
}

//- (void)tabBar:(CYLFlatDesignTabBar *)tabBar didSelectItemAt:(NSInteger)index {
// //子类实现代理方法会， 覆盖父类的默认实现， 所以请先调用父类方法。
//    [super tabBar:tabBar didSelectItemAt:index];
//}

#pragma mark - Layout

//- (void)viewWillLayoutSubviews {
//    [super viewWillLayoutSubviews];
//
//    CGRect newBounds = self.tabBar.bounds;
//
//    // 等价于 Swift 的 didSet + guard
//    if (!CGRectEqualToRect(newBounds, _tabBarBounds)) {
//        _tabBarBounds = newBounds;
//        [self updateSelectionIndicatorColor:[UIColor greenColor]];
//    }
//}

#pragma mark - Update Selection Indicator

- (void)updateSelectionIndicatorColor:(UIColor *)tintColor {
    
    NSArray<UITabBarItem *> *tabBarItems = self.tabBar.items;
    if (tabBarItems.count == 0) return;
    
    CGFloat tabWidth = CGRectGetWidth(self.tabBar.bounds);
    CGFloat tabHeight = CGRectGetHeight(self.tabBar.bounds);
    
    CGSize tabSize = CGSizeMake(tabWidth / tabBarItems.count, tabHeight);
    
    UIImage *selectionImage = [UIImage cyl_imageWithColor:tintColor
                                                     size:tabSize];
    
    // 再次绘制，等价 Swift 逻辑
    UIGraphicsBeginImageContext(tabSize);
    [selectionImage drawInRect:CGRectMake(0, 0, tabSize.width, tabSize.height)];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.tabBar.selectionIndicatorImage = finalImage;
}

/*!
 * [EN] Issue #426: keeps the home tab loaded. `-[CYLHomeViewController viewDidLoad]` adds a scroll edge interaction for its
 *      table view to the tab bar, so running it again would add a second one.
 * [CN] Issue #426：保留首页 Tab 不卸载。`-[CYLHomeViewController viewDidLoad]` 会为其 tableView 向 TabBar 添加滚动边缘交互，
 *      重复执行会再添加一个。
 */
- (BOOL)shouldUnloadViewOfViewController:(UIViewController *)viewController {
    UIViewController *rootViewController = [viewController isKindOfClass:[UINavigationController class]] ?
        ((UINavigationController *)viewController).viewControllers.firstObject : viewController;
    return ![rootViewController isKindOfClass:[CYLHomeViewController class]];
}

- (UIViewContentMode)lottieAnimationViewContentMode {
    return UIViewContentModeScaleAspectFit;
}

@end

@implementation CYLTabBarController (CYLPlusButtonBadgeDemo)

- (NSInteger)cyl_demo_plusButtonBadgeCount {
    return [objc_getAssociatedObject(self, @selector(cyl_demo_plusButtonBadgeCount)) integerValue];
}

- (void)cyl_demo_setPlusButtonBadgeCount:(NSInteger)count {
    objc_setAssociatedObject(self, @selector(cyl_demo_plusButtonBadgeCount), @(count), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cyl_demo_showPlusButtonBadge {
    // The plus button of this tab bar controller's context. 当前 TabBarController 所在 context 的 PlusButton。
    // Guard: only with a plus button. 仅在有 PlusButton 时处理。
    if (![self hasPlusButton]) {
        return;
    }
    UIButton *plusButton = [CYLPlusButton plusButtonForOwner:self];
    if (!plusButton) {
        return;
    }
    NSInteger count = MAX([self cyl_demo_plusButtonBadgeCount], 1);
    [self cyl_demo_setPlusButtonBadgeCount:count];
    // Same API and look as the tabs' badges (shared style: SceneDelegate.m -setUpBadgeAppearance).
    // 与 Tab 角标相同的 API 和样式（共用样式见 SceneDelegate.m -setUpBadgeAppearance）。
    NSString *badgeValue = [NSString stringWithFormat:@"%@", @(count)];
    [plusButton cyl_showBadgeValue:badgeValue animationType:CYLBadgeAnimationTypeBounce];
    // With a plus child view controller there is a second layer: the system tab button of that view controller, under
    // the plus button. Update it too, the way the other tabs' badges are set (on the view controller), so both always
    // show the same value. 有 PlusButton 子控制器时还有第二个图层：PlusButton 下方该子控制器的系统 Tab 按钮。与其他 Tab 一样
    // （在控制器上设置）同时更新它，两者始终显示相同的值。
    // Guard: the second layer only exists with a plus child view controller. 仅在有 PlusButton 子控制器时存在第二个图层。
    if ([self hasPlusChildViewController]) {
        UIViewController *plusChildViewController = [CYLPlusButton plusChildViewControllerForOwner:self];
        [plusChildViewController cyl_showBadgeValue:badgeValue animationType:CYLBadgeAnimationTypeBounce];
    }
#if defined(DEBUG) || defined(BETA)
    NSLog(@"🟣 #535 plus button badge %@ (Liquid Glass: %@, from CYLUtils)", @(count), [CYLUtils isLiquidGlassActive] ? @"YES" : @"NO");
#endif
}

- (void)cyl_demo_plusButtonDidTap {
    [self cyl_demo_setPlusButtonBadgeCount:[self cyl_demo_plusButtonBadgeCount] + 1];
    [self cyl_demo_showPlusButtonBadge];
}

@end
