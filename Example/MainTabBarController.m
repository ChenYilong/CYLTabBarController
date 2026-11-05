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
/// [EN] The covers of the first tab, kept: the decoration block runs again after a theme switch or a tab reload, and
///      covering with the same views moves them instead of adding more.
/// [CN] 第一个 Tab 的封面，保留下来：换肤或重新加载 Tab 后装饰 block 会再次执行，用同样的视图覆盖只会移动它们，不会再添加新的。
@property (nonatomic, strong) UIButton *contentCover;
@property (nonatomic, strong) UIButton *selectedContentCover;

@property (nonatomic, assign) CGRect tabBarBounds;

@end

@implementation MainTabBarController

- (instancetype)initWithContext:(NSString *)context {
    /**
     * [CN] 以下两行代码目的在于手动设置让TabBarItem只显示图标，不显示文字，并让图标垂直居中。
     * 等 效于在 `-tabBarItemsAttributesForController` 方法中不传 `CYLTabBarItemTitle` 字段。
     * 更推荐后一种做法。
     * [EN] The two lines below manually make the TabBarItem show only its icon, without a title, and center the icon vertically.
     *      This is equivalent to not passing the `CYLTabBarItemTitle` key in the `-tabBarItemsAttributesForController` method.
     *      The latter approach is recommended.
     */
    UIEdgeInsets imageInsets = UIEdgeInsetsZero;//UIEdgeInsetsMake(4.5, 0, -4.5, 0);
    UIOffset titlePositionAdjustment = UIOffsetMake(0, -3.5);
    CYLTabBarStyleType tabBarStyleType;
    //    tabBarStyleType = CYLTabBarStyleTypeFlatDesign;
    // [CN] 设置 TabBar 样式：液态玻璃效果（覆盖上一行）
    // [EN] Set the TabBar style: Liquid Glass effect (overrides the previous line).
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
        [self setUpLoginRequiredTabs];
        [self setUpTabBarItemGestures];
    }
    return self;
}

/*!
 * [EN] #152: gestures on the tab buttons and the plus button, with the block API. CYLFlatDesignMainTabBarController and
 *      Example-Swift show the delegate method; all of them use -cyl_demo_handleTabBarItemGesture:control:viewController:.
 * [CN] #152：Tab 按钮与 PlusButton 上的手势，使用 block 方式。CYLFlatDesignMainTabBarController 与 Example-Swift 演示代理方法；
 *      都使用 -cyl_demo_handleTabBarItemGesture:control:viewController:。
 */
- (void)setUpTabBarItemGestures {
    __weak __typeof(self) weakSelf = self;
    self.cyl_tabBarItemGestureHandler = ^(CYLTabBarController *tabBarController, CYLTabBarItemGesture gesture,
                                          UIControl *control, UIViewController *viewController) {
        [weakSelf cyl_demo_handleTabBarItemGesture:gesture control:control viewController:viewController];
    };
}

/*!
 * #19: "Messages" and "Me" need login (block API). While logged out, tapping them shows the login alert; after logging in
 * the tapped tab is selected. Toggle the state with the "Login state" row of the settings section.
 * #19：「消息」「我的」需要登录（block 方式）。未登录时点击会弹出登录弹窗，登录后选中所点击的 Tab。通过设置分组中的「登录状态」行切换。
 */
- (void)setUpLoginRequiredTabs {
    // "message" is set in -tabBarItemsAttributesForTabBar; "Me" has no identifier, so it uses its class name (#408).
    // "message" 在 -tabBarItemsAttributesForTabBar 中设置；「我的」没有设置标识，使用类名（#408）。
    self.cyl_loginRequiredTabBarItemIdentifiers = @[ @"message", NSStringFromClass([CYLMineViewController class]) ];
    self.cyl_loginHandler = ^(CYLTabBarController *tabBarController, UIViewController *viewController, CYLTabBarLoginCompletion completion) {
        [tabBarController cyl_demo_presentLoginForViewController:viewController completion:completion];
    };
}

- (void)viewDidLoad {
    // [CN] * @attention 请在父类的 ViewDidLoad 调用之前设置CYLTabBarStyleType。最佳位置是initWithViewControllers方法内部， 最晚在在 `-[super viewDidLoad];` 之前调用。因为 需要在 tabBar 的KVC操作之前确定自定义样式，否则， 就会执行默认逻辑， 可能会导致你的自定义样式失效。
    // [EN] @attention Set CYLTabBarStyleType before the superclass's ViewDidLoad is called. The best place is inside the
    //      initWithViewControllers method, and at the latest before `-[super viewDidLoad];`. The custom style must be decided
    //      before the tabBar KVC operation; otherwise the default logic runs and your custom style may not take effect.
    //    self.tabBarStyleType = CYLTabBarStyleTypeFlatDesign;
    [[UIApplication sharedApplication] setApplicationSupportsShakeToEdit:YES];
    [self becomeFirstResponder];
    [self customizeInterface];
    // Issue #426: on a memory warning, unload the views of the tabs that are not selected; they load again when selected.
    // Issue #426：收到内存警告时卸载未选中 Tab 的视图，切换到该 Tab 时重新加载。
    self.unloadsUnselectedViewsOnMemoryWarning = YES;
    [super viewDidLoad];
    [self observeLottieAnimationViewDidAdd];
    // FIX: issue #22
    // [EN] `self.tabBar.items` is still empty here: customize the items once they exist.
    // [CN] 此时 `self.tabBar.items` 仍为空：在 item 创建后再自定义。
    [self performWhenTabBarItemsReady:^(CYLTabBarController *tabBarController) {
        for (UITabBarItem *item in tabBarController.tabBar.items) {
            item.accessibilityHint = item.title;
        }
    }];
}

/*!
 * [EN] Issue #428: called once for each Lottie view, after `-lottieAnimationSpeed` was applied. Set a different speed for
 *      one tab here with `-[UIControl cyl_setLottieAnimationSpeed:]`.
 * [CN] Issue #428：每个 Lottie 视图添加后回调一次，此时已设置 `-lottieAnimationSpeed`。可在这里用
 *      `-[UIControl cyl_setLottieAnimationSpeed:]` 为某一个 Tab 单独设置速度。
 */
- (void)observeLottieAnimationViewDidAdd {
    __weak __typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemAnimationViewDidAddNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        UIControl *tabButton = note.object;
        if (tabButton.cyl_tabBarController != weakSelf) {
            return;
        }
        NSLog(@"🟢 Lottie view added: tab %@, animationSpeed %@", @(tabButton.cyl_tabBarChildViewControllerIndex),
              [(id)tabButton.cyl_tabBarItemAnimationView valueForKey:@"animationSpeed"]);
    }];
}

/*!
 * [EN] Issue #428: plays the Lottie icons 1.5 times as fast. No need to wait for the Lottie views to be added.
 * [CN] Issue #428：Lottie 图标以 1.5 倍速播放，无需等待 Lottie 视图添加完成。
 */
- (CGFloat)tabBarItemAnimationSpeed {
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
        // [CN] // 设置badgeSize不为CGSizeZero、badgeValue为nil，就变成一个点了
        // [EN] If badgeSize is not CGSizeZero and badgeValue is nil, the badge becomes a dot.
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
        // [EN] #433: like JD, the selected Home tab reads "Refresh"; a re-tap replays its Lottie animation and is
        //      reported to `cyl_tabBarItemGestureHandler` (-setUpTabBarItemGestures).
        // [CN] #433：与京东一样，选中的「首页」显示「刷新」；再次点击重播 Lottie 动画，并回调 `cyl_tabBarItemGestureHandler`
        //      （-setUpTabBarItemGestures）。
        CYLTabBarItemSelectedTitle : CYLLocalizedString(@"刷新"),
        CYLTabBarItemIdentifier : @"home",  // #408: stays right when tabs are added or removed. Tab 增减后依然准确。
        // A name also loads "<name>_dark" when that image exists: here home_normal_dark (UIImage.cyl_darkImageNameSuffix).
        // 图片名会同时加载存在的「<name>_dark」：这里是 home_normal_dark（UIImage.cyl_darkImageNameSuffix）。
        CYLTabBarItemImage : @"home_normal",  /* NSString and UIImage are supported*/
        CYLTabBarItemSelectedImage : @"home_highlight",  /* NSString and UIImage are supported*/
        //                                                 CYLTabBarItemTitlePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(firstXOffset, -3.5)],
        //                                                 CYLTabBarItemImagePositionAdjustment: [NSValue valueWithUIOffset:UIOffsetMake(firstXOffset, -3.5)],
        // [CN] 第一位 右大，下大
        // [EN] First item: larger to the right, larger downward.
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
        // [EN] #216: the unselected icon's color follows the skin (the tab's file stays the same): gray, or red with the Christmas skin.
        // [CN] #216：未选中图标的颜色跟随皮肤（Tab 的文件不变）：灰色，圣诞皮肤时为红色。
        CYLTabBarAnimationColors : @{ @"Icon_Discovery_Normal.**.Color" : [UIColor cyl_colorWithThemeProvider:^UIColor *(CYLThemeManager *manager, NSObject<NSCopying> *identifier, NSObject *theme) {
            return [identifier isEqual:@"Christmas"] ? UIColor.systemRedColor : [UIColor colorWithWhite:0.498 alpha:1];
        }] },
        //                                                  CYLTabBarLottieSize: [NSValue valueWithCGSize:CGSizeMake(22, 22)]
    };
    
    NSDictionary *thirdTabBarItemsAttributes = @{
        CYLTabBarItemTitle : CYLLocalizedString(@"消息"),
        CYLTabBarItemIdentifier : @"message",
        // A dark image under any name. Names are the prepared form (rendered as original, #465); a UIImage object for
        // the same is `[UIImage cyl_imageWithImageInfo:@"message_normal" darkImageInfo:@"message_normal_night"]`.
        // [CN] 任意名称的深色图片。图片名是库预先处理好的形式（按原图渲染，#465）；同样效果的 UIImage 对象为
        // [EN] A dark image under any name. The image name is in the form the library has already prepared (rendered as
        //      original, #465); a UIImage object with the same effect is
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
 * [CN] 更多TabBar自定义设置：比如：tabBarItem 的选中和不选中文字和背景图片属性、tabbar 背景图片属性等等
 * [EN] More TabBar customization: e.g. selected and unselected title and background image attributes of tabBarItem,
 *      the tabbar background image, and so on.
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
    // [CN] FIX: #581 iOS15以上，iOS26以下，可以设置。
    //iOS26 不推荐设置 `UITabBar.appearance().backgroundColor`。因为玻璃效果下，不仅无法设置背景，同时会干扰 TabBar 里的 Label 未选中颜色，因为 iOS26 里的未选中时的 Label 颜色为系统内部逻辑， 无法自定义。所以如果背景颜色， 与Label颜色一致，白底白字， 用户将无法辨认。暗黑模式下， 也会有类似问题。
    // [EN] FIX: #581 Can be set on iOS15 and later, below iOS26.
    //      Setting `UITabBar.appearance().backgroundColor` is not recommended on iOS26. With the glass effect the background
    //      cannot be set, and it also interferes with the unselected color of the Labels in the TabBar, because on iOS26 the
    //      unselected Label color is decided by internal system logic and cannot be customized. So if the background color
    //      matches the Label color (white text on white), users cannot read it. Dark Mode has similar problems.
    if (!CYL_IS_IOS_26) {
        //            standardAppearance.backgroundColor = [UIColor cyl_systemBackgroundColor];
    }
    // [CN] shadowColor和shadowImage均可以自定义颜色, shadowColor默认高度为1, shadowImage可以自定义高度.
    // [EN] Both shadowColor and shadowImage can use a custom color; shadowColor has a default height of 1, while
    //      shadowImage can have a custom height.
    standardAppearance.shadowColor = [UIColor cyl_systemGreenColor];
    // standardAppearance.shadowImage = [[self class] imageWithColor:[UIColor cyl_systemGreenColor] size:CGSizeMake(self.cyl_tabBarController.visiableTabBarSize.width, 1)];
    return standardAppearance;
}

- (void)customizeTabBarAppearanceWithTitlePositionAdjustment:(UIOffset)titlePositionAdjustment {
    //    if ([CYLConstants isLiquidGlassActive]) {
    //        return;
    //    }
    // Customize UITabBar height
    // [CN] 自定义 TabBar 高度
    // [EN] Custom TabBar height
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
    // [CN] 如果你的App需要支持横竖屏，请使用该方法移除注释 '//'
    // [EN] If your App needs to support both landscape and portrait, remove the '//' to use this method.
    //     [self updateTabBarCustomizationWhenTabBarItemWidthDidUpdate];
    
    // [CN] 半透明， 需要注意：iOS26 液态玻璃下， 具有特殊效果， View 将延伸至TabBar以外区域。
    //如果想固定 TabBar 的背景色，就通过控制 translucent，否则默认一直都是透视的
    // [EN] Translucent. Note: under iOS26 Liquid Glass this has a special effect: the View extends beyond the TabBar area.
    //      To fix the TabBar background color, control translucent; otherwise it is always see-through by default.
    
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
        // [CN] 设置 TabBar 背景
        // [EN] Set the TabBar background
        [[UITabBar appearance] setBarTintColor:[UIColor cyl_systemBackgroundColor]];
        [[UITabBar appearance] setBackgroundColor:[UIColor cyl_systemBackgroundColor]];
        
        [[UITabBar appearance] setShadowImage:[UIImage cyl_imageWithColor:[UIColor cyl_systemGreenColor] size:CGSizeMake(self.cyl_tabBarController.visiableTabBarSize.width, 1)]];
        [self.tabBarItem setTitleTextAttributes:normalAttrs forState:UIControlStateNormal];
        [self.tabBarItem setTitleTextAttributes:selectedAttrs forState:UIControlStateSelected];
    }
    
    //    [[UITabBar appearance] setBackgroundColor:[UIColor clearColor]];
    
    if (!CYL_IS_IOS_26) {
        // [CN] iOS26 不推荐设置 `UITabBar.appearance().backgroundColor` 玻璃效果下，不仅无法设置背景，同时会干扰 TabBar 里的 Label 未选中颜色，因为 iOS26 里的未选中时的 Label 颜色为系统内部逻辑， 无法自定义。所以如果背景颜色， 与Label颜色一致，白底白字， 用户将无法辨认。暗黑模式下， 也会有类似问题。
        // [EN] Setting `UITabBar.appearance().backgroundColor` is not recommended on iOS26. With the glass effect the background
        //      cannot be set, and it also interferes with the unselected color of the Labels in the TabBar, because on iOS26 the
        //      unselected Label color is decided by internal system logic and cannot be customized. So if the background color
        //      matches the Label color (white text on white), users cannot read it. Dark Mode has similar problems.
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
        // [CN] iOS9之后， 不再必须， 因此， 并非核心逻辑， 未来考虑删除。
        // [EN] No longer required since iOS9, so it is not core logic; consider removing it in the future.
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
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
    if (!self.contentCover) {
        self.contentCover = self.selectedCover;
        self.selectedContentCover = self.selectedCover;
    }
    // [CN] TODO:  如果是Lottie 动画icon需要添加延迟， 否则， 会在lottie动画未初始化完成前， 就替换， 位置错误。
    // [EN] TODO:  Lottie animation icons need a delay; otherwise the replacement happens before the lottie animation has
    //      finished initializing, and the position is wrong.
    [selectedTabButton cyl_coverVisiableTabImageViewOrTabButton:YES
                                                 contentNewView:self.contentCover
                                          seclectContentNewView:self.selectedContentCover
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
            // [EN] The cover is kept on top by -cyl_coverVisiableTabImageViewOrTabButton:.
            // [CN] 封面由该方法保持在最上层。
            if (![CYLConstants isLiquidGlassActive]) {
                // [CN] LiquidGlass 已经自带缩放动画， 无需缩放
                // [EN] LiquidGlass already has its own scale animation, so no scaling is needed.
                [self addOnceScaleAnimationOnView:newView];
            }
        }
    }];
}

// [CN] 缩放动画
// [EN] Scale animation
- (void)addOnceScaleAnimationOnView:(UIView *)animationView {
    // [CN] 需要实现的帧动画，这里根据需求自定义
    // [EN] The keyframe animation to implement; customize it here as needed.
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
    // [EN] Add a red dot.
    //      Add a hint animation to guide the user to tap.
    __weak __typeof(self) weakSelf = self;
    [self setViewDidLayoutSubViewsBlockInvokeOnce:YES block:^(CYLTabBarController *tabBarController) {
        [weakSelf cyl_demo_decorateTabBarController:tabBarController];
    }];
}

/*!
 * [EN] The badges, the cover of the first tab and the selection indicator, once the tab buttons exist. Called again after
 *      the tab buttons are set up again, e.g. "Replace neighboring tabs" (issue #481).
 * [CN] Tab 按钮创建后添加角标、第一个 Tab 的封面与选中指示图。Tab 按钮重新创建后（如“替换相邻 Tab 的页面”，issue #481）会再次调用。
 */
- (void)cyl_demo_decorateTabBarController:(CYLTabBarController *)tabBarController {
    
    if (!CYL_IS_IOS_26) {
        [self customizeTabBarSelectionIndicatorImage];
        //           [self updateSelectionIndicatorColor:[UIColor greenColor]];
    }
    
    
    // [CN] 延迟是为了演示demo的时候， 方便看清楚badge动画。 非必须。可删除延迟。
    //@try是为了demo演示的时候， 随时调整减少 tabbar items 个数，而不导致崩溃， 非必须， 可删除。
    // [EN] The delay is only so the badge animation is easy to see in the demo. Not required; the delay can be removed.
    //      @try is only so the number of tabbar items can be reduced at any time in the demo without crashing. Not
    //      required; it can be removed.
    NSTimeInterval delaySeconds = 1.5;
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        @try {
            // [EN] #425: the shared badge style (offset, colors, font) is set once in SceneDelegate.m
            //      -setUpBadgeAppearance; each tab below sets only what differs from it.
            // [CN] #425：共用的角标样式（偏移、颜色、字体）在 SceneDelegate.m -setUpBadgeAppearance 中统一设置一次，
            //      下面每个 Tab 只设置与之不同的部分。
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
            // [EN] Issue #481: directly on the tab item; with Liquid Glass both layers get the badge and its color.
            // [CN] Issue #481：直接设置在 TabBarItem 上；液态玻璃下两个图层都会显示该角标及其颜色。
            [tabBarController.viewControllers[1].tabBarItem cyl_setBadgeBackgroundColor:UIColor.systemPurpleColor];
            [tabBarController.viewControllers[1].tabBarItem cyl_showBadgeValue:@"8" animationType:CYLBadgeAnimationTypeScale];
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
                // [EN] Differs from the global offset (SceneDelegate.m -setUpBadgeAppearance), so it is set here.
                // [CN] 与全局偏移（SceneDelegate.m -setUpBadgeAppearance）不同，因此单独设置。
                [tabBarController.viewControllers[4] cyl_setBadgeCenterOffset:CGPointMake(-1, 3)];
                [tabBarController.viewControllers[4] cyl_showBadgeValue:@"NEW" animationType:CYLBadgeAnimationTypeBreathe];
            }
            // [EN] #535: the plus button gets a badge too, like the tabs; each tap adds 1 (see -didSelectControl:).
            // [CN] #535：PlusButton 也显示角标，与 Tab 一致；每次点击数字加 1（见 -didSelectControl:）。
            [tabBarController cyl_demo_showPlusButtonBadge];
        } @catch (NSException *exception) {
            NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
        }
        
        // [CN] 添加仿淘宝tabbar，第一个tab选中后有图标覆盖
        // [EN] Add a Taobao-style tabbar: after the first tab is selected, an icon covers it.
        if (self.selectedIndex != 0) {
            return;
        }
        // tabBarController.selectedIndex = 1;
        
    });
}


#pragma mark - delegate

- (BOOL)tabBarController:(CYLTabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    UIControl *tabButton = viewController.tabBarItem.cyl_visiableTabButton;
    BOOL shouldSelectViewControllerFromSuper = [super tabBarController:tabBarController shouldSelectViewController:viewController];
    
#if defined(DEBUG) || defined(BETA)
    // test for issue #642
    //    self.selectedIndex = [self.viewControllers indexOfObject:viewController];
    
    NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：index%@ title%@"), @(__PRETTY_FUNCTION__), @(__LINE__), @([self.viewControllers indexOfObject:viewController]), viewController.title);
#endif
    if ([tabButton cyl_isPlusControl]) {
        // [CN] FIXME:  to delete 玻璃效果下， 不能调用 updateSelectionStatusIfNeededForTabBarController，selectedViewController， selectedIndex 否则无法实现plusButton的点击事件响应， 响应的仅仅是tabButton
        // [EN] FIXME:  to delete With the glass effect, updateSelectionStatusIfNeededForTabBarController, selectedViewController
        //      and selectedIndex must not be called; otherwise the plusButton tap event cannot be handled, and only the
        //      tabButton responds.
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
    // [EN] #152: re-tap, double tap and long press are handled by `cyl_tabBarItemGestureHandler`, see
    //      -setUpTabBarItemGestures.
    // [CN] #152：再次点击、双击与长按由 `cyl_tabBarItemGestureHandler` 处理，见 -setUpTabBarItemGestures。
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
        // [EN] Change the red badge state.
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
    // [CN] 即使 PlusButton 也添加了点击事件，点击 PlusButton 后也会触发该代理方法。
    // 可在PlusButton初始化时使用 CYLExternPlusButton.cyl_userInteractionDisabled = YES; 来禁止该协议方法触发plusButton回调
    // [EN] Even if the PlusButton has its own tap action, tapping the PlusButton still triggers this delegate method.
    //      Use CYLExternPlusButton.cyl_userInteractionDisabled = YES; when initializing the PlusButton to stop this
    //      protocol method from triggering the plusButton callback.
    if (isPlusButton) {
        animationView = button.imageView;
    }
    
    [self addScaleAnimationOnView:animationView repeatCount:1];
    // [CN] [self addRotateAnimationOnView:animationView];//暂时不推荐用旋转方式，badge也会旋转。
    // [EN] [self addRotateAnimationOnView:animationView];// The rotation approach is not recommended for now: the badge
    //      would rotate too.
    
    // [CN] 添加仿淘宝tabbar，第一个tab选中后有图标覆盖
    // [EN] Add a Taobao-style tabbar: after the first tab is selected, an icon covers it.
    if ([control cyl_isTabButton] || [control cyl_isPlusButton]) {
        //        BOOL shouldSelectedCoverShow = (self.selectedIndex == 0);
        //        [self setSelectedCoverShow:shouldSelectedCoverShow];
    }
}
// [CN] 缩放动画
// [EN] Scale animation
- (void)addScaleAnimationOnView:(UIView *)animationView repeatCount:(float)repeatCount {
    if (CYL_IS_IOS_26) {
        // [CN] 不建议在iOS26上给PlusButton添加动画， 因为在玻璃遮罩显示时， 玻璃遮罩本身就有缩放动画， 再添加动画， 会非常冗余。
        // [EN] Adding an animation to the PlusButton on iOS26 is not recommended: when the glass overlay is shown, the overlay
        //      already has its own scale animation, so another animation would be very redundant.
        return;
    }
    // [CN] 需要实现的帧动画，这里根据需求自定义
    // [EN] The keyframe animation to implement; customize it here as needed.
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
    animation.keyPath = @"transform.scale";
    animation.values = @[@1.0,@1.3,@0.9,@1.15,@0.95,@1.02,@1.0];
    animation.duration = 1;
    animation.repeatCount = repeatCount;
    animation.calculationMode = kCAAnimationCubic;
    [animationView.layer addAnimation:animation forKey:nil];
}

// [CN] 旋转动画
// [EN] Rotation animation
- (void)addRotateAnimationOnView:(UIView *)animationView {
    if (CYL_IS_IOS_26) {
        // [CN] 不建议在iOS26上给PlusButton添加动画， 因为在玻璃遮罩显示时， 玻璃遮罩本身就有缩放动画， 再添加动画， 会非常冗余。
        // [EN] Adding an animation to the PlusButton on iOS26 is not recommended: when the glass overlay is shown, the overlay
        //      already has its own scale animation, so another animation would be very redundant.
        return;
    }
    // [CN] 针对旋转动画，需要将旋转轴向屏幕外侧平移，最大图片宽度的一半
    // 否则背景与按钮图片处于同一层次，当按钮图片旋转时，转轴就在背景图上，动画时会有一部分在背景图之下。
    // 动画结束后复位
    // [EN] For the rotation animation, move the rotation axis outward from the screen by half the maximum image width.
    //      Otherwise the background and the button image are on the same layer; when the button image rotates, the axis
    //      lies on the background image and part of the animation ends up below the background.
    //      Reset after the animation ends.
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
    
    // [CN] 设定动画选项
    // [EN] Set the animation options
    rotateAnimation.duration = 1.2; // [CN] 持续时间
    // [EN] Duration
    rotateAnimation.repeatCount = 1; // [CN] 重复次数
    // [EN] Repeat count
    
    // [CN] 设定旋转角度
    // [EN] Set the rotation angle
    rotateAnimation.fromValue = [NSNumber numberWithFloat:0.0]; // [CN] 起始角度
    // [EN] Start angle
    rotateAnimation.toValue = [NSNumber numberWithFloat:2 * M_PI]; // [CN] 终止角度
    // [EN] End angle
    
    [animationView.layer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
}

//- (void)tabBar:(CYLFlatDesignTabBar *)tabBar didSelectItemAt:(NSInteger)index {
// [CN] //子类实现代理方法会， 覆盖父类的默认实现， 所以请先调用父类方法。
// [EN] A subclass implementing the delegate method overrides the superclass's default implementation, so call the
//      superclass method first.
//    [super tabBar:tabBar didSelectItemAt:index];
//}

#pragma mark - Layout

//- (void)viewWillLayoutSubviews {
//    [super viewWillLayoutSubviews];
//
//    CGRect newBounds = self.tabBar.bounds;
//
// [CN] // 等价于 Swift 的 didSet + guard
// [EN] Equivalent to Swift's didSet + guard
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
    
    // [CN] 再次绘制，等价 Swift 逻辑
    // [EN] Draw again, equivalent to the Swift logic
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

- (UIViewContentMode)tabBarItemAnimationViewContentMode {
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
    // [EN] The plus button of this tab bar controller's context.
    // [CN] 当前 TabBarController 所在 context 的 PlusButton。
    // [EN] Guard: only with a plus button.
    // [CN] 仅在有 PlusButton 时处理。
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
    // [EN] With a plus child view controller there is a second layer: the system tab button of that view controller, under
    // the plus button. Update it too, the way the other tabs' badges are set (on the view controller), so both always
    // show the same value.
    // [CN] 有 PlusButton 子控制器时还有第二个图层：PlusButton 下方该子控制器的系统 Tab 按钮。与其他 Tab 一样
    // （在控制器上设置）同时更新它，两者始终显示相同的值。
    // [EN] Guard: the second layer only exists with a plus child view controller.
    // [CN] 仅在有 PlusButton 子控制器时存在第二个图层。
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

@implementation CYLTabBarController (CYLLoginDemo)

- (void)cyl_demo_presentLoginForViewController:(UIViewController *)viewController completion:(CYLTabBarLoginCompletion)completion {
    NSString *title = viewController.tabBarItem.title ?: [viewController cyl_getViewControllerInsteadOfNavigationController].title ?: @"";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:CYLLocalizedString(@"需要登录")
                                                                   message:[NSString stringWithFormat:CYLLocalizedString(@"「%@」需要登录后才能查看"), title]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"取消") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        completion(NO);
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"登录") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // A real app logs in here first. 实际 App 在这里先完成登录。
        completion(YES);
    }]];
    UIViewController *presenter = self;
    while (presenter.presentedViewController) {
        presenter = presenter.presentedViewController;
    }
    [presenter presentViewController:alert animated:YES completion:nil];
}

@end

@implementation CYLTabBarController (CYLTabBarItemGestureDemo)

- (void)cyl_demo_handleTabBarItemGesture:(CYLTabBarItemGesture)gesture control:(UIControl *)control viewController:(UIViewController *)viewController {
    UIViewController *contentViewController = [viewController cyl_getViewControllerInsteadOfNavigationController];
    NSLog(@"🟣 #152 gesture %@ on \"%@\"", @(gesture), control.cyl_tabBarItemIdentifier);
    switch (gesture) {
        case CYLTabBarItemGestureReselect:
            [self cyl_demo_scrollToTop:contentViewController];
            break;
        case CYLTabBarItemGestureDoubleTap:
            if ([contentViewController respondsToSelector:@selector(refresh)]) {
                CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS(
                    [contentViewController performSelector:@selector(refresh)];
                );
            }
            break;
        case CYLTabBarItemGestureLongPress:
            [self cyl_demo_showActionsForControl:control];
            break;
    }
}

/// [EN] Scrolls the first scroll view of the page to its top. [CN] 将页面中的第一个滚动视图滚动到顶部。
- (void)cyl_demo_scrollToTop:(UIViewController *)viewController {
    UIView *view = viewController.isViewLoaded ? viewController.view : nil;
    NSMutableArray<UIView *> *views = view ? [NSMutableArray arrayWithObject:view] : [NSMutableArray array];
    while (views.count > 0) {
        UIView *each = views.firstObject;
        [views removeObjectAtIndex:0];
        if ([each isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *)each;
            [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, -scrollView.adjustedContentInset.top) animated:YES];
            return;
        }
        [views addObjectsFromArray:each.subviews];
    }
}

/// [EN] The long press menu: the tab's identifier and a way to select it. [CN] 长按菜单：显示 Tab 标识，并可选中它。
- (void)cyl_demo_showActionsForControl:(UIControl *)control {
    NSString *identifier = control.cyl_tabBarItemIdentifier;
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:identifier
                                                                    message:CYLLocalizedString(@"长按（#152）")
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    __weak __typeof(self) weakSelf = self;
    if (identifier.length > 0 && ![control cyl_isPlusButton]) {
        [sheet addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"选中") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [weakSelf cyl_selectTabBarItemWithIdentifier:identifier];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = control;
    sheet.popoverPresentationController.sourceRect = control.bounds;
    UIViewController *presenter = self.presentedViewController ? nil : self;
    [presenter presentViewController:sheet animated:YES completion:nil];
}

@end
