//
//  CYLTabBarToolkitTests.m
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>
#import <CYLTabBarController/CYLTabBar.h>

@interface CYLTabBarToolkitTests : XCTestCase
@end

@implementation CYLTabBarToolkitTests

/// [EN] Two tabs in navigation controllers, laid out. [CN] 两个放在导航控制器中的 Tab，已布局。
- (CYLTabBarController *)newTabBarController {
    UINavigationController *first = [[UINavigationController alloc] initWithRootViewController:[UIViewController new]];
    UINavigationController *second = [[UINavigationController alloc] initWithRootViewController:[UIViewController new]];
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ first, second ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"First" },
                                                                                                    @{ CYLTabBarItemTitle : @"Second" } ]];
    tabBarController.view.frame = CGRectMake(0, 0, 390, 844);
    [tabBarController.view layoutIfNeeded];
    return tabBarController;
}

#pragma mark - Type safety

/// [EN] A tab bar controller whose tab bar is a plain UITabBar: only CYLTabBar has the plus button label check.
/// [CN] TabBar 是系统 UITabBar 的控制器：只有 CYLTabBar 才有 PlusButton 标题的判断方法。
- (void)testSelectionUpdateAcceptsASystemTabBar {
    CYLTabBarController *tabBarController = [self newTabBarController];
    UITabBarController *systemTabBarController = [[UITabBarController alloc] init];
    UIViewController *first = [[UIViewController alloc] init];
    UIViewController *second = [[UIViewController alloc] init];
    systemTabBarController.viewControllers = @[ first, second ];
    XCTAssertFalse([systemTabBarController.tabBar isKindOfClass:[CYLTabBar class]]);
    XCTAssertNoThrow([tabBarController updateSelectionStatusIfNeededForTabBarController:systemTabBarController
                                                             shouldSelectViewController:second]);
}

#pragma mark - Double tap

/// [EN] The per-tab block; the taps themselves are recognized by the tab bar item gestures (docs/TabBarItem-Gestures.md).
/// [CN] 单个 Tab 的 block；点击本身由 TabBarItem 手势识别（docs/TabBarItem-Gestures.md）。
- (void)testDoubleTapBlockIsKeptOnTheItem {
    CYLTabBarController *tabBarController = [self newTabBarController];
    UITabBarItem *item = tabBarController.viewControllers[0].tabBarItem;
    XCTAssertNil(item.cyl_doubleTapBlock);
    item.cyl_doubleTapBlock = ^(UITabBarItem *tabBarItem, NSInteger index) {};
    XCTAssertNotNil(item.cyl_doubleTapBlock);
    item.cyl_doubleTapBlock = nil;
    XCTAssertNil(item.cyl_doubleTapBlock);
}

#pragma mark - Item appearance

- (void)testApplyItemAppearanceReachesEveryLayout {
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance cyl_applyItemAppearanceWithBlock:^(UITabBarItemAppearance *itemAppearance) {
        itemAppearance.selected.iconColor = UIColor.systemRedColor;
    }];
    XCTAssertEqualObjects(appearance.stackedLayoutAppearance.selected.iconColor, UIColor.systemRedColor);
    XCTAssertEqualObjects(appearance.inlineLayoutAppearance.selected.iconColor, UIColor.systemRedColor);
    XCTAssertEqualObjects(appearance.compactInlineLayoutAppearance.selected.iconColor, UIColor.systemRedColor);
}

#pragma mark - Classic styles and UITabBarAppearance

- (void)testClassicSettersSyncIntoTheAppearanceUnlessLiquidGlass {
    CYLTabBar *tabBar = [[CYLTabBar alloc] initWithFrame:CGRectMake(0, 0, 390, 83)];
    XCTAssertTrue(tabBar.syncsClassicStylesToAppearance, @"on by default");
    tabBar.tintColor = UIColor.systemOrangeColor;
    tabBar.unselectedItemTintColor = UIColor.systemGrayColor;
    tabBar.barTintColor = UIColor.systemYellowColor;
    UITabBarAppearance *appearance = tabBar.standardAppearance;
    if ([CYLUtils isLiquidGlassActive]) {
        // [EN] Liquid Glass: the system draws the bar, nothing is synced. [CN] 液态玻璃：由系统绘制 TabBar，不同步。
        XCTAssertNotEqualObjects(appearance.stackedLayoutAppearance.selected.iconColor, UIColor.systemOrangeColor);
        return;
    }
    XCTAssertEqualObjects(appearance.stackedLayoutAppearance.selected.iconColor, UIColor.systemOrangeColor);
    XCTAssertEqualObjects(appearance.inlineLayoutAppearance.selected.titleTextAttributes[NSForegroundColorAttributeName], UIColor.systemOrangeColor);
    XCTAssertEqualObjects(appearance.stackedLayoutAppearance.normal.iconColor, UIColor.systemGrayColor);
    XCTAssertEqualObjects(appearance.backgroundColor, UIColor.systemYellowColor);
}

- (void)testClassicSyncCanBeTurnedOff {
    CYLTabBar *tabBar = [[CYLTabBar alloc] initWithFrame:CGRectMake(0, 0, 390, 83)];
    tabBar.syncsClassicStylesToAppearance = NO;
    UIColor *before = tabBar.standardAppearance.backgroundColor;
    tabBar.barTintColor = UIColor.systemYellowColor;
    XCTAssertEqualObjects(tabBar.standardAppearance.backgroundColor, before);
}

- (void)testBackgroundEffectAndForegroundColorLiveInTheAppearance {
    UITabBar *tabBar = [[UITabBar alloc] initWithFrame:CGRectMake(0, 0, 390, 83)];
    UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemThinMaterialDark];
    tabBar.cyl_backgroundEffect = effect;
    tabBar.cyl_effectForegroundColor = UIColor.systemPinkColor;
    XCTAssertEqualObjects(tabBar.standardAppearance.backgroundEffect, effect);
    XCTAssertEqualObjects(tabBar.cyl_backgroundEffect, effect);
    XCTAssertEqualObjects(tabBar.standardAppearance.backgroundColor, UIColor.systemPinkColor);
    XCTAssertEqualObjects(tabBar.cyl_effectForegroundColor, UIColor.systemPinkColor);
}

#pragma mark - Styles in one place

- (void)testItemStylesReachEveryLayout {
    CYLTabBarController *tabBarController = [self newTabBarController];
    UIFont *selectedFont = [UIFont boldSystemFontOfSize:12];
    tabBarController.cyl_tabBarItemSelectedTitleFont = selectedFont;
    tabBarController.cyl_tabBarItemSelectedTitleColor = UIColor.systemGreenColor;
    tabBarController.cyl_tabBarItemImageColor = UIColor.systemGrayColor;
    tabBarController.cyl_tabBarBackgroundColor = UIColor.whiteColor;
    tabBarController.cyl_tabBarShadowColor = UIColor.systemRedColor;

    XCTAssertEqualObjects(tabBarController.cyl_tabBarItemSelectedTitleColor, UIColor.systemGreenColor, @"the getter returns the value set");
    UITabBarAppearance *appearance = tabBarController.tabBar.standardAppearance;
    for (UITabBarItemAppearance *itemAppearance in @[ appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance ]) {
        XCTAssertEqualObjects(itemAppearance.selected.titleTextAttributes[NSFontAttributeName], selectedFont);
        XCTAssertEqualObjects(itemAppearance.selected.titleTextAttributes[NSForegroundColorAttributeName], UIColor.systemGreenColor);
        XCTAssertEqualObjects(itemAppearance.normal.iconColor, UIColor.systemGrayColor);
    }
    XCTAssertEqualObjects(appearance.backgroundColor, UIColor.whiteColor);
    XCTAssertEqualObjects(appearance.shadowColor, UIColor.systemRedColor);

    // [EN] No shadow: the getter returns the color that was set, but UITabBarAppearance reads a clear shadow back as nil.
    // [CN] 没有阴影：getter 返回设置的颜色，但 UITabBarAppearance 把透明阴影读回为 nil。
    tabBarController.cyl_tabBarShadowColor = UIColor.clearColor;
    XCTAssertEqualObjects(tabBarController.cyl_tabBarShadowColor, UIColor.clearColor);
    XCTAssertNil(tabBarController.tabBar.standardAppearance.shadowColor);
}

#pragma mark - Layout helpers

- (void)testTabBarSpacingIsZeroOutsideATabBarController {
    UIViewController *viewController = [UIViewController new];
    XCTAssertEqual(viewController.cyl_tabBarSpacingInViewCoordinator, 0.0, @"no view loaded");
    [viewController loadViewIfNeeded];
    XCTAssertEqual(viewController.cyl_tabBarSpacingInViewCoordinator, 0.0, @"not in a window, no tab bar");
}

- (void)testOpaqueTabBarSafeAreaFixIsOnByDefault {
    CYLTabBarController *tabBarController = [self newTabBarController];
    XCTAssertTrue(tabBarController.cyl_fixesOpaqueTabBarSafeAreaInsets);
    tabBarController.cyl_fixesOpaqueTabBarSafeAreaInsets = NO;
    XCTAssertFalse(tabBarController.cyl_fixesOpaqueTabBarSafeAreaInsets);
}

#pragma mark - Reselect and custom tab actions (Swift since step 53)

- (void)testReselectBehaviorIsKept {
    CYLTabBarController *tabBarController = [self newTabBarController];
    XCTAssertEqual(tabBarController.cyl_reselectBehavior, CYLTabBarReselectBehaviorNone);
    tabBarController.cyl_reselectBehavior = CYLTabBarReselectBehaviorPopToRoot | CYLTabBarReselectBehaviorScrollToTop;
    XCTAssertEqual(tabBarController.cyl_reselectBehavior, CYLTabBarReselectBehaviorPopToRoot | CYLTabBarReselectBehaviorScrollToTop);
}

/// [EN] Pop to root first; the private selector is reached at run time. [CN] 先返回根页面；私有 selector 在运行时调用。
- (void)testReselectPopsToRoot {
    CYLTabBarController *tabBarController = [self newTabBarController];
    // [EN] In a window: a navigation controller outside one does not pop. [CN] 放入窗口：不在窗口中的导航控制器不会返回。
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 390, 844)];
    window.rootViewController = tabBarController;
    [window makeKeyAndVisible];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    UINavigationController *navigationController = (UINavigationController *)tabBarController.viewControllers.firstObject;
    [navigationController pushViewController:[UIViewController new] animated:NO];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    XCTAssertEqual(navigationController.viewControllers.count, 2u);
    SEL selector = NSSelectorFromString(@"cyl_performReselectBehaviorForViewController:");
    XCTAssertTrue([tabBarController respondsToSelector:selector]);
    tabBarController.cyl_reselectBehavior = CYLTabBarReselectBehaviorNone;
    ((void (*)(id, SEL, id))[tabBarController methodForSelector:selector])(tabBarController, selector, navigationController);
    XCTAssertEqual(navigationController.viewControllers.count, 2u, @"no behavior, nothing happens");
    tabBarController.cyl_reselectBehavior = CYLTabBarReselectBehaviorPopToRoot;
    ((void (*)(id, SEL, id))[tabBarController methodForSelector:selector])(tabBarController, selector, navigationController);
    // [EN] An animated pop ends on a later run loop turn. [CN] 带动画的返回在之后的 runloop 中完成。
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];
    XCTAssertEqual(navigationController.viewControllers.count, 1u);
}

- (void)testCustomTabActionRunsOncePerRunLoopTurn {
    CYLTabBarController *tabBarController = [self newTabBarController];
    UIViewController *first = tabBarController.viewControllers.firstObject;
    UIViewController *second = tabBarController.viewControllers.lastObject;
    XCTAssertNotNil(first.cyl_tabBarItemIdentifier);
    tabBarController.cyl_customActionTabBarItemIdentifiers = @[ first.cyl_tabBarItemIdentifier ];
    XCTAssertEqualObjects(tabBarController.cyl_customActionTabBarItemIdentifiers, @[ first.cyl_tabBarItemIdentifier ]);
    __block NSInteger runs = 0;
    tabBarController.cyl_customTabActionHandler = ^(CYLTabBarController *controller, UIViewController *viewController) {
        XCTAssertEqual(viewController, first);
        runs += 1;
    };
    XCTAssertTrue([tabBarController cyl_isCustomActionTabViewController:first]);
    XCTAssertFalse([tabBarController cyl_isCustomActionTabViewController:second]);
    XCTAssertTrue([tabBarController cyl_performCustomTabActionIfNeededForViewController:first]);
    XCTAssertTrue([tabBarController cyl_performCustomTabActionIfNeededForViewController:first], @"the same tap: handled, not run again");
    XCTAssertFalse([tabBarController cyl_performCustomTabActionIfNeededForViewController:second]);
    XCTAssertEqual(runs, 1);
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertTrue([tabBarController cyl_performCustomTabActionIfNeededForViewController:first]);
    XCTAssertEqual(runs, 2, @"a later run loop turn runs it again");
}

- (void)testShouldPerformCustomTabActionHandlerWins {
    CYLTabBarController *tabBarController = [self newTabBarController];
    UIViewController *second = tabBarController.viewControllers.lastObject;
    tabBarController.cyl_customActionTabBarItemIdentifiers = @[];
    tabBarController.cyl_shouldPerformCustomTabActionHandler = ^BOOL(CYLTabBarController *controller, UIViewController *viewController) {
        return viewController == second;
    };
    XCTAssertTrue([tabBarController cyl_isCustomActionTabViewController:second]);
    XCTAssertFalse([tabBarController cyl_isCustomActionTabViewController:tabBarController.viewControllers.firstObject]);
    tabBarController.cyl_shouldPerformCustomTabActionHandler = nil;
    XCTAssertFalse([tabBarController cyl_isCustomActionTabViewController:second]);
}

/// [EN] The item styles are kept and read back. [CN] item 样式会被保存并可读回。
- (void)testItemStylesAreKept {
    CYLTabBarController *tabBarController = [self newTabBarController];
    UIFont *font = [UIFont systemFontOfSize:11];
    tabBarController.cyl_tabBarItemTitleFont = font;
    tabBarController.cyl_tabBarItemSelectedImageColor = UIColor.redColor;
    XCTAssertEqualObjects(tabBarController.cyl_tabBarItemTitleFont, font);
    XCTAssertEqualObjects(tabBarController.cyl_tabBarItemSelectedImageColor, UIColor.redColor);
    XCTAssertNil(tabBarController.cyl_tabBarShadowColor);
    tabBarController.cyl_tabBarItemTitleFont = nil;
    XCTAssertNil(tabBarController.cyl_tabBarItemTitleFont);
}

- (void)testItemLayoutBlockIsKept {
    UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:@"A" image:nil tag:0];
    void (^block)(UITabBarItem *, UIView *) = ^(UITabBarItem *tabBarItem, UIView *view) {};
    item.cyl_viewDidLayoutSubviewsBlock = block;
    XCTAssertNotNil(item.cyl_viewDidLayoutSubviewsBlock);
    item.cyl_viewDidLayoutSubviewsBlock = nil;
    XCTAssertNil(item.cyl_viewDidLayoutSubviewsBlock);
}

@end
