//
//  CYLTabBarToolkitTests.m
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>
#import <CYLTabBarController/CYLTabBar.h>

@interface CYLTabBarToolkitTests : XCTestCase <CYLTabBarControllerDelegate>
@property (nonatomic, assign) NSInteger delegateDoubleTaps;
@property (nonatomic, assign) NSUInteger delegateDoubleTapIndex;
@end

@implementation CYLTabBarToolkitTests

- (void)setUp {
    [super setUp];
    self.delegateDoubleTaps = 0;
    self.delegateDoubleTapIndex = NSNotFound;
}

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

- (void)tabBarController:(CYLTabBarController *)tabBarController didDoubleTapViewController:(UIViewController *)viewController atIndex:(NSUInteger)index {
    self.delegateDoubleTaps++;
    self.delegateDoubleTapIndex = index;
}

#pragma mark - Double tap

- (void)testDoubleTapIntervalIsShort {
    XCTAssertEqualWithAccuracy(CYLTabBarItemDoubleTapInterval, 0.3, 0.001);
}

- (void)testTwoQuickTapsOnTheSelectedTabFireOnce {
    CYLTabBarController *tabBarController = [self newTabBarController];
    UITabBar *tabBar = tabBarController.tabBar;
    XCTAssertGreaterThanOrEqual(tabBar.items.count, 2u);
    tabBarController.selectedIndex = 0;
    tabBarController.delegate = self;
    __block NSInteger blockDoubleTaps = 0;
    __block NSInteger blockIndex = -1;
    tabBarController.viewControllers[0].tabBarItem.cyl_doubleTapBlock = ^(UITabBarItem *tabBarItem, NSInteger index) {
        blockDoubleTaps++;
        blockIndex = index;
    };

    [tabBarController tabBar:tabBar didSelectItem:tabBar.items[0]];
    XCTAssertEqual(blockDoubleTaps, 0, @"one tap is not a double tap");
    [tabBarController tabBar:tabBar didSelectItem:tabBar.items[0]];
    XCTAssertEqual(blockDoubleTaps, 1);
    XCTAssertEqual(blockIndex, 0);
    XCTAssertEqual(self.delegateDoubleTaps, 1);
    XCTAssertEqual(self.delegateDoubleTapIndex, 0u);
}

- (void)testTapsTooFarApartDoNotFire {
    CYLTabBarController *tabBarController = [self newTabBarController];
    UITabBar *tabBar = tabBarController.tabBar;
    XCTAssertGreaterThanOrEqual(tabBar.items.count, 2u);
    tabBarController.selectedIndex = 0;
    __block NSInteger doubleTaps = 0;
    tabBarController.viewControllers[0].tabBarItem.cyl_doubleTapBlock = ^(UITabBarItem *tabBarItem, NSInteger index) {
        doubleTaps++;
    };
    [tabBarController tabBar:tabBar didSelectItem:tabBar.items[0]];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:CYLTabBarItemDoubleTapInterval + 0.15]];
    [tabBarController tabBar:tabBar didSelectItem:tabBar.items[0]];
    XCTAssertEqual(doubleTaps, 0);
}

- (void)testATapOnAnotherTabDoesNotCount {
    CYLTabBarController *tabBarController = [self newTabBarController];
    UITabBar *tabBar = tabBarController.tabBar;
    XCTAssertGreaterThanOrEqual(tabBar.items.count, 2u);
    tabBarController.selectedIndex = 0;
    __block NSInteger doubleTaps = 0;
    tabBarController.viewControllers[1].tabBarItem.cyl_doubleTapBlock = ^(UITabBarItem *tabBarItem, NSInteger index) {
        doubleTaps++;
    };
    // [EN] The tab is not selected before this tap: it never counts. [CN] 点击前该 Tab 未选中：不计入。
    [tabBarController tabBar:tabBar didSelectItem:tabBar.items[1]];
    XCTAssertEqual(doubleTaps, 0);
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
    tabBarController.cyl_tabBarShadowColor = UIColor.clearColor;

    XCTAssertEqualObjects(tabBarController.cyl_tabBarItemSelectedTitleColor, UIColor.systemGreenColor, @"the getter returns the value set");
    UITabBarAppearance *appearance = tabBarController.tabBar.standardAppearance;
    for (UITabBarItemAppearance *itemAppearance in @[ appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance ]) {
        XCTAssertEqualObjects(itemAppearance.selected.titleTextAttributes[NSFontAttributeName], selectedFont);
        XCTAssertEqualObjects(itemAppearance.selected.titleTextAttributes[NSForegroundColorAttributeName], UIColor.systemGreenColor);
        XCTAssertEqualObjects(itemAppearance.normal.iconColor, UIColor.systemGrayColor);
    }
    XCTAssertEqualObjects(appearance.backgroundColor, UIColor.whiteColor);
    XCTAssertEqualObjects(appearance.shadowColor, UIColor.clearColor);
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

- (void)testItemLayoutBlockIsKept {
    UITabBarItem *item = [[UITabBarItem alloc] initWithTitle:@"A" image:nil tag:0];
    void (^block)(UITabBarItem *, UIView *) = ^(UITabBarItem *tabBarItem, UIView *view) {};
    item.cyl_viewDidLayoutSubviewsBlock = block;
    XCTAssertNotNil(item.cyl_viewDidLayoutSubviewsBlock);
    item.cyl_viewDidLayoutSubviewsBlock = nil;
    XCTAssertNil(item.cyl_viewDidLayoutSubviewsBlock);
}

@end
