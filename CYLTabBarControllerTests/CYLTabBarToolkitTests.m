//
//  CYLTabBarToolkitTests.m
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>
#import <CYLTabBarController/CYLTabBar.h>


/// [EN] A delegate that refuses the Liquid Glass lens. [CN] 拒绝液态玻璃放大镜的代理。
@interface CYLLensRefusingDelegate : NSObject <CYLTabBarControllerDelegate>
@end

@implementation CYLLensRefusingDelegate
- (BOOL)tabBarController:(CYLTabBarController *)tabBarController shouldShowPlatterLiquidLensViewForControl:(UIControl *)control {
    return NO;
}
@end

/// [EN] A subclass that overrides the delegate method and calls super, as the examples do. [CN] 与示例一样重写代理方法并调用 super 的子类。
@interface CYLSuperCallingTabBarController : CYLTabBarController
@property (nonatomic, assign) NSInteger shouldSelectCalls;
@end

@implementation CYLSuperCallingTabBarController
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    self.shouldSelectCalls += 1;
    return [super tabBarController:tabBarController shouldSelectViewController:viewController];
}
@end

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

#pragma mark - Selected tab badge (Swift since step 56)

/// [EN] The selected tab's badge value is stored while hidden and comes back when another tab is selected or the property is off.
/// [CN] 选中 Tab 的角标值在隐藏期间被暂存，选中其他 Tab 或关闭属性后恢复。
- (void)testHidesBadgeOfSelectedTab {
    CYLTabBarController *tabBarController = [self newTabBarController];
    UITabBarItem *firstItem = tabBarController.viewControllers[0].tabBarItem;
    UITabBarItem *secondItem = tabBarController.viewControllers[1].tabBarItem;
    firstItem.badgeValue = @"3";
    secondItem.badgeValue = @"5";
    tabBarController.selectedIndex = 0;
    XCTAssertFalse(tabBarController.cyl_hidesBadgeOfSelectedTab);
    tabBarController.cyl_hidesBadgeOfSelectedTab = YES;
    XCTAssertTrue(tabBarController.cyl_hidesBadgeOfSelectedTab);
    XCTAssertNil(firstItem.badgeValue, @"the selected tab's badge is hidden");
    XCTAssertEqualObjects(secondItem.badgeValue, @"5");
    tabBarController.selectedIndex = 1;
    SEL update = NSSelectorFromString(@"cyl_updateBadgesOfSelectedTab");
    XCTAssertTrue([tabBarController respondsToSelector:update]);
    ((void (*)(id, SEL))[tabBarController methodForSelector:update])(tabBarController, update);
    XCTAssertEqualObjects(firstItem.badgeValue, @"3", @"restored once another tab is selected");
    XCTAssertNil(secondItem.badgeValue);
    tabBarController.cyl_hidesBadgeOfSelectedTab = NO;
    XCTAssertEqualObjects(secondItem.badgeValue, @"5", @"everything hidden comes back when the property is off");
}

#pragma mark - Per-tab colors and title offset (Swift since step 57, issue #475)

/// [EN] A tab's own selected title color and the title offset go into its own appearance; the other tab keeps the bar's.
/// [CN] Tab 自己的选中标题颜色与标题偏移写入它自己的 appearance；另一个 Tab 使用 TabBar 的 appearance。
- (void)testPerTabColorAndOffsetReachTheItemAppearance {
    UINavigationController *first = [[UINavigationController alloc] initWithRootViewController:[UIViewController new]];
    UINavigationController *second = [[UINavigationController alloc] initWithRootViewController:[UIViewController new]];
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ first, second ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"First",
                                                                                                       CYLTabBarItemSelectedTitleColor : UIColor.redColor },
                                                                                                    @{ CYLTabBarItemTitle : @"Second" } ]];
    tabBarController.view.frame = CGRectMake(0, 0, 390, 844);
    [tabBarController.view layoutIfNeeded];
    XCTAssertEqual(tabBarController.tabBar.items.count, 2u, @"the color pass walks the tab bar's items");
    tabBarController.titlePositionAdjustment = UIOffsetMake(0, -3);
    SEL sync = NSSelectorFromString(@"cyl_syncTitlePositionAdjustmentAppearances");
    XCTAssertTrue([tabBarController respondsToSelector:sync]);
    ((void (*)(id, SEL))[tabBarController methodForSelector:sync])(tabBarController, sync);
    UITabBarAppearance *firstAppearance = first.tabBarItem.standardAppearance;
    XCTAssertNotNil(firstAppearance);
    UITabBarItemStateAppearance *selected = firstAppearance.stackedLayoutAppearance.selected;
    XCTAssertEqualObjects(selected.titleTextAttributes[NSForegroundColorAttributeName], UIColor.redColor);
    XCTAssertTrue(UIOffsetEqualToOffset(selected.titlePositionAdjustment, UIOffsetMake(0, -3)));
    // [EN] Without its own colors, the second tab still gets the offset. [CN] 第二个 Tab 没有自己的颜色，仍会得到偏移。
    UITabBarAppearance *secondAppearance = second.tabBarItem.standardAppearance;
    XCTAssertTrue(UIOffsetEqualToOffset(secondAppearance.stackedLayoutAppearance.normal.titlePositionAdjustment, UIOffsetMake(0, -3)));
    XCTAssertNil(secondAppearance.stackedLayoutAppearance.selected.titleTextAttributes[NSForegroundColorAttributeName]);
    // [EN] Reset: the copies go away. [CN] 重置：副本被移除。
    tabBarController.titlePositionAdjustment = UIOffsetZero;
    XCTAssertNil(second.tabBarItem.standardAppearance);
}

#pragma mark - Reported control and the lens (Swift since step 59)

/// [EN] Without a plus button, a control reports itself; nil stays nil. [CN] 没有 PlusButton 时控件上报自身；nil 仍为 nil。
- (void)testReportedControlWithoutPlusButtonIsTheControl {
    CYLTabBarController *tabBarController = [self newTabBarController];
    SEL reported = NSSelectorFromString(@"cyl_reportedControlForControl:");
    XCTAssertTrue([tabBarController respondsToSelector:reported]);
    UIControl *control = [UIControl new];
    UIControl *(*call)(id, SEL, id) = (UIControl *(*)(id, SEL, id))[tabBarController methodForSelector:reported];
    XCTAssertEqual(call(tabBarController, reported, control), control);
    XCTAssertNil(call(tabBarController, reported, nil));
}

/// [EN] Liquid Glass: a delegate that refuses the lens turns its gestures off; without one they stay on.
/// [CN] 液态玻璃：拒绝放大镜的代理会关闭其手势；没有代理时手势保持开启。
- (void)testBeginShowLensFollowsTheDelegate {
    CYLTabBarController *tabBarController = [self newTabBarController];
    if (![CYLConstants isLiquidGlassActive] || ![tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    SEL begin = NSSelectorFromString(@"tabBarController:beginShowPlatterLiquidLensViewForControl:");
    XCTAssertTrue([tabBarController respondsToSelector:begin]);
    void (*call)(id, SEL, id, id) = (void (*)(id, SEL, id, id))[tabBarController methodForSelector:begin];
    CYLTabBar *tabBar = tabBarController.tabBar;
    UIControl *control = [UIControl new];
    CYLLensRefusingDelegate *delegate = [CYLLensRefusingDelegate new];
    tabBarController.delegate = delegate;
    call(tabBarController, begin, tabBarController, control);
    XCTAssertFalse(tabBar.liquidGlassContinuousGestureRecognizer.enabled);
    // [EN] The long press recognizer exists only once the tab bar is in a window. [CN] 长按手势只在 TabBar 进入窗口后存在。
    XCTAssertFalse(tabBar.liquidGlassLongGestureRecognizer.enabled);
    tabBarController.delegate = nil;
    call(tabBarController, begin, tabBarController, control);
    XCTAssertTrue(tabBar.liquidGlassContinuousGestureRecognizer.enabled);
    if (tabBar.liquidGlassLongGestureRecognizer) {
        XCTAssertTrue(tabBar.liquidGlassLongGestureRecognizer.enabled);
    }
}

#pragma mark - Selection (Swift since step 61)

/// [EN] super reaches the library's `-tabBarController:shouldSelectViewController:`: the selected tab is refused, another
///      one allowed, and a custom action tab refused.
/// [CN] super 能调用到库的 `-tabBarController:shouldSelectViewController:`：已选中的 Tab 被拒绝，其他 Tab 允许，自定义操作的 Tab 被拒绝。
- (void)testSubclassSuperReachesShouldSelect {
    UINavigationController *first = [[UINavigationController alloc] initWithRootViewController:[UIViewController new]];
    UINavigationController *second = [[UINavigationController alloc] initWithRootViewController:[UIViewController new]];
    CYLSuperCallingTabBarController *tabBarController = [[CYLSuperCallingTabBarController alloc] initWithViewControllers:@[ first, second ]
                                                                                                   tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"First" },
                                                                                                                            @{ CYLTabBarItemTitle : @"Second" } ]];
    tabBarController.view.frame = CGRectMake(0, 0, 390, 844);
    [tabBarController.view layoutIfNeeded];
    tabBarController.selectedIndex = 0;
    XCTAssertFalse([tabBarController tabBarController:tabBarController shouldSelectViewController:first], @"already selected");
    XCTAssertTrue([tabBarController tabBarController:tabBarController shouldSelectViewController:second]);
    tabBarController.cyl_customActionTabBarItemIdentifiers = @[ second.cyl_tabBarItemIdentifier ];
    tabBarController.cyl_customTabActionHandler = ^(CYLTabBarController *controller, UIViewController *viewController) {};
    XCTAssertFalse([tabBarController tabBarController:tabBarController shouldSelectViewController:second], @"a custom action tab");
    XCTAssertEqual(tabBarController.shouldSelectCalls, 3);
    XCTAssertNoThrow([tabBarController updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:second shouldSelect:NO]);
    XCTAssertNoThrow([tabBarController updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:second]);
}

@end
