//
//  CYLTabBarHostViewTests.m
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>

/// [EN] A small image for tabs and plus buttons. [CN] 用于 Tab 与 PlusButton 的小图片。
static UIImage *CYLHostTestsImage(void) {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(24, 24)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [UIColor.redColor setFill];
        [context fillRect:CGRectMake(0, 0, 24, 24)];
    }];
}

@interface CYLTabBarHostView (CYLTabBarHostViewTests)
+ (id)imageForValue:(id)value resolver:(UIImage * (^)(id))resolver;
@end

@interface CYLTabBarHostViewTests : XCTestCase
@property (nonatomic, strong) UIWindow *window;
@end

@implementation CYLTabBarHostViewTests

- (void)tearDown {
    self.window.hidden = YES;
    self.window = nil;
    [super tearDown];
}

#pragma mark - CYLTabBarControllerPlusButton

- (void)testPlusButtonKeyRegistersAPlusButtonForTheConfigurationContext {
    NSDictionary *configuration = @{
        CYLTabBarControllerContext : @"host-tests-plus",
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A" }, @{ CYLTabBarItemTitle : @"B" } ],
        CYLTabBarControllerPlusButton : @{ CYLTabBarItemTitle : @"Post", CYLTabBarItemImage : CYLHostTestsImage() },
    };
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:configuration];
    XCTAssertNotNil(tabBarController);
    CYLPlusButton *plusButton = [CYLPlusButton plusButtonForTabBarContext:@"host-tests-plus"];
    XCTAssertNotNil(plusButton);
    XCTAssertEqualObjects([plusButton titleForState:UIControlStateNormal], @"Post");
}

- (void)testPlusButtonWithoutAnImageIsNotRegistered {
    [CYLPlusButton cyl_registerPlusButtonWithAttributes:@{ CYLTabBarItemTitle : @"No image" } action:nil context:@"host-tests-no-image"];
    XCTAssertNil([CYLPlusButton plusButtonForTabBarContext:@"host-tests-no-image"]);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
/// [EN] A reported tap: what `-cyl_sendDidSelectControl:` runs for a configuration plus button. [CN] 一次上报的点击：`-cyl_sendDidSelectControl:` 对配置 PlusButton 执行的内容。
static void CYLHostTestsTap(CYLPlusButton *plusButton) {
    [plusButton performSelector:NSSelectorFromString(@"cyl_configurationPlusButtonTapped")];
}
#pragma clang diagnostic pop

- (void)testEachContextKeepsItsOwnPlusButtonAction {
    __block NSInteger tapsA = 0;
    __block NSInteger tapsB = 0;
    [CYLPlusButton cyl_registerPlusButtonWithAttributes:@{ CYLTabBarItemTitle : @"A", CYLTabBarItemImage : CYLHostTestsImage() }
                                                 action:^(CYLPlusButton *plusButton) { tapsA++; }
                                                context:@"host-tests-context-a"];
    [CYLPlusButton cyl_registerPlusButtonWithAttributes:@{ CYLTabBarItemImage : CYLHostTestsImage() }
                                                 action:^(CYLPlusButton *plusButton) { tapsB++; }
                                                context:@"host-tests-context-b"];
    CYLPlusButton *plusButtonA = [CYLPlusButton plusButtonForTabBarContext:@"host-tests-context-a"];
    CYLPlusButton *plusButtonB = [CYLPlusButton plusButtonForTabBarContext:@"host-tests-context-b"];
    XCTAssertNotNil(plusButtonA);
    XCTAssertNotNil(plusButtonB);
    XCTAssertNotEqual(plusButtonA, plusButtonB);
    CYLHostTestsTap(plusButtonA);
    XCTAssertEqual(tapsA, 1);
    XCTAssertEqual(tapsB, 0);
    CYLHostTestsTap(plusButtonB);
    XCTAssertEqual(tapsA, 1);
    XCTAssertEqual(tapsB, 1);
    XCTAssertEqualObjects([plusButtonA titleForState:UIControlStateNormal], @"A");
}

- (void)testPlusButtonKeyInAConfigurationFile {
    // [EN] Binary Protobuf: field 12 (CYLTabBarControllerPlusButton) holding a CYLTabBarItem with field 1 (title) "Post" and
    //      field 2 (image) "post". [CN] 二进制 Protobuf：字段 12（CYLTabBarControllerPlusButton）包含一个 CYLTabBarItem，字段 1（标题）为
    //      "Post"，字段 2（图片）为 "post"。
    const uint8_t bytes[] = { 0x62, 0x0C, 0x0A, 0x04, 'P', 'o', 's', 't', 0x12, 0x04, 'p', 'o', 's', 't' };
    NSError *error;
    NSDictionary *binary = [CYLTabBarConfigurationParser dictionaryWithData:[NSData dataWithBytes:bytes length:sizeof(bytes)]
                                                                     format:CYLTabBarConfigurationFormatProtobuf
                                                                      error:&error];
    XCTAssertNil(error);
    NSDictionary *expected = @{ CYLTabBarItemTitle : @"Post", CYLTabBarItemImage : @"post" };
    XCTAssertEqualObjects(binary[CYLTabBarControllerPlusButton], expected);
    NSData *json = [@"{\"CYLTabBarControllerPlusButton\": {\"CYLTabBarItemTitle\": \"Post\", \"CYLTabBarItemImage\": \"post\"}}" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects([CYLTabBarConfigurationParser dictionaryWithData:json format:CYLTabBarConfigurationFormatJSON error:NULL][CYLTabBarControllerPlusButton], expected);
    NSData *text = [@"CYLTabBarControllerPlusButton { CYLTabBarItemTitle: \"Post\" CYLTabBarItemImage: \"post\" }" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects([CYLTabBarConfigurationParser dictionaryWithData:text format:CYLTabBarConfigurationFormatProtobufText error:NULL][CYLTabBarControllerPlusButton], expected);
}

- (void)testPlusButtonLayoutKeys {
    NSDictionary *configuration = @{
        CYLTabBarControllerContext : @"host-tests-layout",
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A" }, @{ CYLTabBarItemTitle : @"B" } ],
        CYLTabBarControllerPlusButton : @{
            CYLTabBarItemTitle : @"Menu",
            CYLPlusButtonBackgroundImage : CYLHostTestsImage(),
            CYLTabBarItemTitleColor : @"#FFFFFF",
            CYLTabBarItemTitleFont : @15,
            CYLPlusButtonIndexInTabBar : @1,
            CYLPlusButtonCenterYMultiplier : @0.3,
            CYLPlusButtonCenterYOffset : @"-10",
            CYLPlusButtonKeepsTitleVisible : @YES,
            CYLTabBarItemIdentifier : @"plus",
        },
    };
    XCTAssertNotNil([CYLTabBarController tabBarControllerWithConfiguration:configuration]);
    CYLPlusButton *plusButton = [CYLPlusButton plusButtonForTabBarContext:@"host-tests-layout"];
    XCTAssertNotNil(plusButton);
    Class<CYLPlusButtonSubclassing> plusButtonClass = (Class<CYLPlusButtonSubclassing>)[plusButton class];
    XCTAssertEqual([plusButtonClass indexOfPlusButtonInTabBar], 1u);
    XCTAssertEqualWithAccuracy([plusButtonClass multiplierOfTabBarHeight:49], 0.3, 0.0001);
    XCTAssertEqualWithAccuracy([plusButtonClass constantOfPlusButtonCenterYOffsetForTabBarHeight:49], -10, 0.0001);
    XCTAssertEqualObjects([plusButtonClass tabBarItemIdentifier], @"plus");
    // [EN] A title on a background image does not line up with the tab titles. [CN] 画在背景图上的标题不与 Tab 标题对齐。
    XCTAssertFalse([plusButtonClass alignsTitleWithTabBarItemTitles]);
    XCTAssertNotNil([plusButton backgroundImageForState:UIControlStateNormal]);
    CGFloat red = 0, green = 0, blue = 0, alpha = 0;
    XCTAssertTrue([[plusButton titleColorForState:UIControlStateNormal] getRed:&red green:&green blue:&blue alpha:&alpha]);
    XCTAssertEqualWithAccuracy(red + green + blue + alpha, 4, 0.01);
    XCTAssertEqualWithAccuracy(plusButton.titleLabel.font.pointSize, 15, 0.01);
    XCTAssertTrue(plusButton.cyl_keepShowingPlusButtonLabel);
    XCTAssertFalse([(id)plusButtonClass respondsToSelector:@selector(plusChildViewController)]);
}

- (void)testPlusButtonImageSizeDrawsItsImagesAspectFit {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(80, 40)];
    UIImage *wide = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [UIColor.blueColor setFill];
        [context fillRect:CGRectMake(0, 0, 80, 40)];
    }];
    [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : @"host-tests-image-size",
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemIdentifier : @"a" },
                                                      @{ CYLTabBarItemTitle : @"B", CYLTabBarItemIdentifier : @"b" } ],
        CYLTabBarControllerPlusButton : @{ CYLTabBarItemTitle : @"Post", CYLTabBarItemImage : wide,
                                           CYLTabBarItemSelectedImage : wide, CYLPlusButtonImageSize : @"{20, 20}" },
    }];
    UIButton *plusButton = [CYLPlusButton plusButtonForTabBarContext:@"host-tests-image-size"];
    UIImage *image = [plusButton imageForState:UIControlStateNormal];
    if (@available(iOS 15.0, *)) {
        image = image ?: plusButton.configuration.image;
    }
    XCTAssertEqualWithAccuracy(image.size.width, 20, 0.5, @"aspect fit in 20 × 20");
    XCTAssertEqualWithAccuracy(image.size.height, 10, 0.5);
    XCTAssertEqualWithAccuracy([plusButton imageForState:UIControlStateSelected].size.width, 20, 0.5);
}

- (void)testPlusButtonWithoutLayoutKeysKeepsTheDefaults {
    [CYLPlusButton cyl_registerPlusButtonWithAttributes:@{ CYLTabBarItemTitle : @"Post", CYLTabBarItemImage : CYLHostTestsImage() }
                                                 action:nil context:@"host-tests-defaults"];
    Class plusButtonClass = [[CYLPlusButton plusButtonForTabBarContext:@"host-tests-defaults"] class];
    XCTAssertFalse([plusButtonClass respondsToSelector:@selector(indexOfPlusButtonInTabBar)]);
    XCTAssertFalse([plusButtonClass respondsToSelector:@selector(multiplierOfTabBarHeight:)]);
    XCTAssertTrue([(Class<CYLPlusButtonSubclassing>)plusButtonClass alignsTitleWithTabBarItemTitles]);
}

- (void)testPlusButtonPageAndAppearanceKeys {
    UIViewController *menu = [[UIViewController alloc] init];
    NSDictionary *configuration = @{
        CYLTabBarControllerContext : @"host-tests-page",
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemIdentifier : @"a" },
                                                      @{ CYLTabBarItemTitle : @"B", CYLTabBarItemIdentifier : @"b" } ],
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
            return [pageIdentifier isEqualToString:@"menu"] ? menu : [[UIViewController alloc] init];
        },
        CYLTabBarControllerPlusButton : @{ CYLTabBarItemTitle : @"Menu", CYLTabBarItemImage : CYLHostTestsImage(),
                                           CYLTabBarItemPageIdentifier : @"menu" },
        CYLTabBarControllerUserInterfaceStyle : @"dark",
        CYLTabBarControllerTabButtonTapAnimation : @"bounce",
        CYLTabBarControllerSwipeToSwitchTab : @YES,
    };
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:configuration];
    XCTAssertEqual([CYLPlusButton plusChildViewControllerForTabBarContext:@"host-tests-page"], menu);
    XCTAssertEqual([(Class<CYLPlusButtonSubclassing>)[[CYLPlusButton plusButtonForTabBarContext:@"host-tests-page"] class] indexOfPlusButtonInTabBar], 1u);
    XCTAssertEqual(tabBarController.overrideUserInterfaceStyle, UIUserInterfaceStyleDark);
    XCTAssertEqual(tabBarController.cyl_tabButtonTapAnimationType, CYLTabButtonTapAnimationTypeBounce);
    XCTAssertTrue(tabBarController.cyl_swipeToSwitchTabEnabled);
}

- (void)testInvalidAppearanceValuesAreIgnored {
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A" }, @{ CYLTabBarItemTitle : @"B" } ],
        CYLTabBarControllerUserInterfaceStyle : @"purple",
        CYLTabBarControllerTabButtonTapAnimation : @"wobble",
    }];
    XCTAssertEqual(tabBarController.overrideUserInterfaceStyle, UIUserInterfaceStyleUnspecified);
    XCTAssertEqual(tabBarController.cyl_tabButtonTapAnimationType, CYLTabButtonTapAnimationTypeNone);
}

#pragma mark - CYLTabBarHostView

- (CYLTabBarHostView *)hostViewInWindow {
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 390, 844)];
    UIViewController *root = [[UIViewController alloc] init];
    self.window.rootViewController = root;
    [self.window makeKeyAndVisible];
    CYLTabBarHostView *hostView = [[CYLTabBarHostView alloc] initWithFrame:CGRectMake(0, 744, 390, 100)];
    [root.view addSubview:hostView];
    return hostView;
}

- (void)waitForTabBarControllerOf:(CYLTabBarHostView *)hostView {
    NSPredicate *built = [NSPredicate predicateWithBlock:^BOOL(CYLTabBarHostView *view, NSDictionary *bindings) {
        [view layoutIfNeeded];
        return view.tabBarController != nil;
    }];
    [self waitForExpectations:@[ [self expectationForPredicate:built evaluatedWithObject:hostView handler:nil] ] timeout:5];
}

/// [EN] The key `cyl_loggedIn` is cached under. [CN] `cyl_loggedIn` 的缓存键。
static NSString *const CYLHostTestsLoggedInKey = @"CYLTabBarControllerLoggedIn";

- (NSDictionary *)loginConfiguration {
    return @{ CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemIdentifier : @"a" },
                                                            @{ CYLTabBarItemTitle : @"B", CYLTabBarItemIdentifier : @"b" } ],
              CYLTabBarControllerLoginRequiredTabBarItemIdentifiers : @[ @"b" ] };
}

- (void)testWithoutTheAppsLoginStateTheCachedOneIsUsedAndReported {
    BOOL saved = [NSUserDefaults.standardUserDefaults boolForKey:CYLHostTestsLoggedInKey];
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:CYLHostTestsLoggedInKey];
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    __block NSNumber *reported;
    hostView.loginStateDidChange = ^(BOOL loggedIn) {
        reported = @(loggedIn);
    };
    hostView.configuration = [self loginConfiguration];
    [self waitForTabBarControllerOf:hostView];
    XCTAssertEqualObjects(reported, @YES);
    XCTAssertTrue(hostView.loggedIn);
    XCTAssertTrue(hostView.tabBarController.cyl_loggedIn);
    [NSUserDefaults.standardUserDefaults setBool:saved forKey:CYLHostTestsLoggedInKey];
}

- (void)testTheAppsLoginStateWinsAndATabThatNeedsLoginIsRequested {
    BOOL saved = [NSUserDefaults.standardUserDefaults boolForKey:CYLHostTestsLoggedInKey];
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:CYLHostTestsLoggedInKey];
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    __block NSNumber *reported;
    __block NSString *requested;
    hostView.loginStateDidChange = ^(BOOL loggedIn) {
        reported = @(loggedIn);
    };
    hostView.didRequestLogin = ^(NSInteger index, NSString *identifier, NSString *title) {
        requested = [NSString stringWithFormat:@"%@ %@ %@", @(index), identifier, title];
    };
    hostView.loggedIn = NO;
    hostView.configuration = [self loginConfiguration];
    [self waitForTabBarControllerOf:hostView];
    CYLTabBarController *tabBarController = hostView.tabBarController;
    XCTAssertEqualObjects(reported, @NO);
    XCTAssertFalse(tabBarController.cyl_loggedIn);
    // [EN] Logged out: the tab is not selected, the app is asked to log in. [CN] 未登录：不选中该 Tab，请求 App 登录。
    UIViewController *second = tabBarController.viewControllers[1];
    XCTAssertTrue([tabBarController cyl_interceptLoginIfNeededForViewController:second]);
    XCTAssertEqualObjects(requested, @"1 b B");
    hostView.selectedIndex = 1;
    XCTAssertEqual(tabBarController.selectedIndex, 0u);
    // [EN] Logging in applies the selection set before it; logging out there goes back to the first tab.
    // [CN] 登录后，之前设置的选中生效；在此退出登录回到第一个 Tab。
    hostView.loggedIn = YES;
    XCTAssertEqual(tabBarController.selectedIndex, 1u);
    __block NSInteger selectedIndex = -1;
    hostView.didSelectTab = ^(NSInteger index, NSString *identifier) {
        selectedIndex = index;
    };
    hostView.loggedIn = NO;
    XCTAssertEqual(tabBarController.selectedIndex, 0u);
    XCTAssertEqual(selectedIndex, 0);
    // [EN] After a reset the next tab bar uses the cached state again. [CN] 重置后，之后创建的 TabBar 重新使用缓存的状态。
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:CYLHostTestsLoggedInKey];
    [hostView resetLoggedIn];
    hostView.configuration = nil;
    hostView.configuration = [self loginConfiguration];
    [self waitForTabBarControllerOf:hostView];
    XCTAssertEqualObjects(reported, @YES);
    [NSUserDefaults.standardUserDefaults setBool:saved forKey:CYLHostTestsLoggedInKey];
}

- (void)testALanguageTranslatesTheLibraryAndLaysARightToLeftOneOutRightToLeft {
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    hostView.language = @"ar";
    hostView.configuration = [self loginConfiguration];
    [self waitForTabBarControllerOf:hostView];
    XCTAssertEqualObjects(CYLLocalizationLanguage(), @"ar");
    XCTAssertEqualObjects(CYLLocalizedString(@"加号按钮"), @"زر الإضافة");
    XCTAssertEqual(hostView.tabBarController.tabBar.semanticContentAttribute, UISemanticContentAttributeForceRightToLeft);
    // [EN] Another language builds the tab bar again, left to right. [CN] 切换语言会重新创建 TabBar，从左到右。
    CYLTabBarController *arabic = hostView.tabBarController;
    hostView.language = @"es";
    NSPredicate *rebuilt = [NSPredicate predicateWithBlock:^BOOL(CYLTabBarHostView *view, NSDictionary *bindings) {
        [view layoutIfNeeded];
        return view.tabBarController && view.tabBarController != arabic;
    }];
    [self waitForExpectations:@[ [self expectationForPredicate:rebuilt evaluatedWithObject:hostView handler:nil] ] timeout:5];
    XCTAssertEqualObjects(CYLLocalizedString(@"加号按钮"), @"Botón más");
    XCTAssertEqual(hostView.tabBarController.tabBar.semanticContentAttribute, UISemanticContentAttributeUnspecified);
    hostView.language = nil;
    XCTAssertNotEqualObjects(CYLLocalizationLanguage(), @"es");
}

- (void)testAHiddenTabBarTakesNoTouches {
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    hostView.configuration = [self loginConfiguration];
    [self waitForTabBarControllerOf:hostView];
    [hostView layoutIfNeeded];
    XCTAssertGreaterThan(hostView.touchableRects.count, 0u);
    hostView.tabBarHidden = YES;
    XCTAssertTrue(hostView.tabBarController.isTabBarHidden);
    XCTAssertEqual(hostView.touchableRects.count, 0u);
    hostView.tabBarHidden = NO;
    XCTAssertFalse(hostView.tabBarController.isTabBarHidden);
    XCTAssertGreaterThan(hostView.touchableRects.count, 0u);
}

- (void)testAMemoryWarningUnloadsTheUnselectedTabsButTheOnesKeptLoaded {
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    hostView.language = @"en";
    hostView.configuration = @{ CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemIdentifier : @"a" },
                                                                               @{ CYLTabBarItemTitle : @"B", CYLTabBarItemIdentifier : @"b" },
                                                                               @{ CYLTabBarItemTitle : @"C", CYLTabBarItemIdentifier : @"c" },
                                                                               @{ CYLTabBarItemTitle : @"D", CYLTabBarItemIdentifier : @"d" } ],
                                CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning : @"true",
                                CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers : @"a, b" };
    [self waitForTabBarControllerOf:hostView];
    CYLTabBarController *tabBarController = hostView.tabBarController;
    XCTAssertTrue(tabBarController.unloadsUnselectedViewsOnMemoryWarning);
    XCTAssertEqualObjects(tabBarController.cyl_keepsLoadedTabBarItemIdentifiers, (@[ @"a", @"b" ]));
    // [EN] Load every tab but D, then select C. [CN] 加载除 D 以外的所有 Tab，然后选中 C。
    for (NSInteger index = 0; index < 3; index++) {
        hostView.selectedIndex = index;
        [tabBarController.selectedViewController loadViewIfNeeded];
    }
    hostView.selectedIndex = 2;
    NSString *report = [hostView simulateMemoryWarning];
    // [EN] The host loads every (transparent) page when it builds the tab bar, as on Android: D, never selected, is unloaded.
    // [CN] 宿主在创建 TabBar 时加载所有（透明的）页面，与 Android 相同：从未选中的 D 被卸载。
    XCTAssertEqualObjects([report stringByReplacingOccurrencesOfString:@"\n" withString:@" | "],
                          @"A: kept: shouldUnload returned NO | B: kept: shouldUnload returned NO | C: kept: selected | D: unloaded");
    hostView.selectedIndex = 0;
    [hostView simulateMemoryWarning];
    XCTAssertFalse(tabBarController.viewControllers[2].isViewLoaded);
    hostView.language = nil;
}

- (void)testTheTitleOffsetChangesAtRuntimeAndWinsOverTheConfiguration {
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    NSMutableDictionary *configuration = [[self loginConfiguration] mutableCopy];
    configuration[CYLTabBarControllerTitlePositionAdjustment] = @"{0, -3.5}";
    hostView.configuration = configuration;
    [self waitForTabBarControllerOf:hostView];
    CYLTabBarController *tabBarController = hostView.tabBarController;
    XCTAssertEqual(tabBarController.titlePositionAdjustment.vertical, -3.5);
    hostView.titlePositionAdjustment = [NSValue valueWithUIOffset:UIOffsetMake(0, 4)];
    // [EN] The same tab bar, its titles moved. [CN] 同一个 TabBar，标题已移动。
    XCTAssertEqual(hostView.tabBarController, tabBarController);
    XCTAssertEqual(tabBarController.titlePositionAdjustment.vertical, 4);
    // [EN] A tab bar built again keeps the offset set at runtime. [CN] 重新创建的 TabBar 保留运行时设置的偏移。
    hostView.configuration = nil;
    hostView.configuration = configuration;
    [self waitForTabBarControllerOf:hostView];
    XCTAssertEqual(hostView.tabBarController.titlePositionAdjustment.vertical, 4);
}

- (void)testInvalidJSONChangesNothing {
    CYLTabBarHostView *hostView = [[CYLTabBarHostView alloc] init];
    XCTAssertFalse([hostView setConfigurationJSON:@"[1, 2]"]);
    XCTAssertFalse([hostView setConfigurationJSON:@"not json"]);
    XCTAssertNil(hostView.configuration);
    XCTAssertTrue([hostView setConfigurationJSON:@"{\"CYLTabBarControllerTabBarItemsAttributes\": []}"]);
    XCTAssertNotNil(hostView.configuration);
}

- (void)testBuildsInAWindowWithEmptyPagesAndItsOwnContext {
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    hostView.configuration = @{ CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemIdentifier : @"a" },
                                                                               @{ CYLTabBarItemTitle : @"B", CYLTabBarItemIdentifier : @"b" } ] };
    [self waitForTabBarControllerOf:hostView];
    CYLTabBarController *tabBarController = hostView.tabBarController;
    XCTAssertEqual(tabBarController.viewControllers.count, 2u);
    XCTAssertTrue([tabBarController.context hasPrefix:@"CYLTabBarHostView-"]);
    XCTAssertEqualObjects(tabBarController.viewControllers.firstObject.view.backgroundColor, UIColor.clearColor);
    XCTAssertEqual(tabBarController.parentViewController, self.window.rootViewController);
}

- (void)testSelectedIndexAndTabCallbackCountTheConfigurationTabs {
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    __block NSInteger selectedIndex = -1;
    __block NSString *selectedIdentifier;
    hostView.didSelectTab = ^(NSInteger index, NSString *identifier) {
        selectedIndex = index;
        selectedIdentifier = identifier;
    };
    hostView.configuration = @{ CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemIdentifier : @"a" },
                                                                               @{ CYLTabBarItemTitle : @"B", CYLTabBarItemIdentifier : @"b" } ] };
    hostView.selectedIndex = 1;
    [self waitForTabBarControllerOf:hostView];
    CYLTabBarController *tabBarController = hostView.tabBarController;
    XCTAssertEqual(tabBarController.selectedIndex, 1u);
    UIViewController *first = tabBarController.viewControllers.firstObject;
    // [EN] Every tap is reported (`-tabBarController:didSelectControl:`), also again on the selected tab.
    // [CN] 每次点击都会上报（`-tabBarController:didSelectControl:`），再次点击已选中的 Tab 也会上报。
    tabBarController.selectedIndex = 0;
    [tabBarController.tabBar layoutIfNeeded];
    UIControl *button = first.cyl_tabButton;
    XCTAssertNotNil(button);
    id<CYLTabBarControllerDelegate> delegate = (id<CYLTabBarControllerDelegate>)hostView;
    [delegate tabBarController:tabBarController didSelectControl:button];
    XCTAssertEqual(selectedIndex, 0);
    XCTAssertEqualObjects(selectedIdentifier, @"a");
    selectedIndex = -1;
    [delegate tabBarController:tabBarController didSelectControl:button];
    XCTAssertEqual(selectedIndex, 0);
    // [EN] A page change alone reports nothing for a tab: the tap did. [CN] 仅页面变化不会为 Tab 上报：点击已上报。
    selectedIndex = -1;
    [(id<UITabBarControllerDelegate>)hostView tabBarController:tabBarController didSelectViewController:first];
    XCTAssertEqual(selectedIndex, -1);
}

- (void)testTheControllerKeepsItsOwnDelegateBehavior {
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    hostView.configuration = @{ CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A" }, @{ CYLTabBarItemTitle : @"B" } ] };
    [self waitForTabBarControllerOf:hostView];
    CYLTabBarController *tabBarController = hostView.tabBarController;
    XCTAssertEqual(tabBarController.delegate, (id)hostView);
    // [EN] The delegate methods the host does not handle go to the controller (e.g. the Liquid Glass lens decision).
    // [CN] 宿主未处理的 delegate 方法交给 controller（例如液态玻璃放大镜的判断）。
    SEL lens = @selector(tabBarController:shouldShowPlatterLiquidLensViewForControl:);
    XCTAssertEqual([hostView respondsToSelector:lens], [tabBarController respondsToSelector:lens]);
    XCTAssertFalse([hostView respondsToSelector:NSSelectorFromString(@"cyl_notADelegateMethod")]);
    // [EN] The controller's own `shouldSelect…`: the selected page is not selected again. [CN] controller 自己的 `shouldSelect…`：已选中的页面不会再次选中。
    XCTAssertFalse([(id<UITabBarControllerDelegate>)hostView tabBarController:tabBarController shouldSelectViewController:tabBarController.selectedViewController]);
}

- (void)testImageURLsAreLoadedBeforeTheTabBarIsBuilt {
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"cyl-host-tests-icon.png"];
    XCTAssertTrue([UIImagePNGRepresentation(CYLHostTestsImage()) writeToFile:path atomically:YES]);
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    hostView.configuration = @{ CYLTabBarControllerTabBarItemsAttributes : @[
        @{ CYLTabBarItemTitle : @"A", CYLTabBarItemImage : [NSURL fileURLWithPath:path].absoluteString },
        @{ CYLTabBarItemTitle : @"B", CYLTabBarItemImage : @"resolved-by-the-resolver" },
    ] };
    [self waitForTabBarControllerOf:hostView];
    XCTAssertNotNil(hostView.tabBarController.viewControllers.firstObject.tabBarItem.image);
}

- (void)testImageResolverHandlesOtherValues {
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    __block NSInteger calls = 0;
    hostView.imageResolver = ^UIImage *(id value) {
        calls++;
        return [value isEqual:@"custom:icon"] ? CYLHostTestsImage() : nil;
    };
    hostView.configuration = @{ CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemImage : @"custom:icon" },
                                                                               @{ CYLTabBarItemTitle : @"B" } ] };
    [self waitForTabBarControllerOf:hostView];
    XCTAssertEqual(calls, 1);
    XCTAssertNotNil(hostView.tabBarController.viewControllers.firstObject.tabBarItem.image);
}

- (void)testTabsWithoutAnIdentifierStillGetPages {
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    hostView.configuration = @{ CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A" }, @{ CYLTabBarItemTitle : @"B" } ] };
    [self waitForTabBarControllerOf:hostView];
    XCTAssertEqual(hostView.tabBarController.viewControllers.count, 2u);
}

/// [EN] A controller in a window with the plus button's page selected. [CN] 放入 window 并选中 PlusButton 页面的控制器。
- (CYLTabBarController *)controllerWithSelectedPlusPage:(UIViewController *)page context:(NSString *)context plusButton:(NSDictionary *)plusButton {
    NSMutableDictionary *attributes = [@{ CYLTabBarItemTitle : @"Post", CYLTabBarItemImage : CYLHostTestsImage(),
                                          CYLTabBarItemPageIdentifier : @"post" } mutableCopy];
    [attributes addEntriesFromDictionary:plusButton];
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : context,
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemIdentifier : @"a" },
                                                      @{ CYLTabBarItemTitle : @"B", CYLTabBarItemIdentifier : @"b" } ],
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *pageAttributes) {
            return [pageIdentifier isEqualToString:@"post"] ? page : [[UIViewController alloc] init];
        },
        CYLTabBarControllerPlusButton : attributes,
    }];
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 390, 844)];
    self.window.rootViewController = tabBarController;
    self.window.hidden = NO;
    [self.window layoutIfNeeded];
    tabBarController.selectedViewController = page;
    return tabBarController;
}

- (void)testAPlusPageWithoutATitleTakesThePlusButtonTitle {
    UIViewController *untitled = [[UIViewController alloc] init];
    [self controllerWithSelectedPlusPage:untitled context:@"host-tests-plus-title" plusButton:@{}];
    XCTAssertEqualObjects(untitled.title, @"Post", @"the system tab of the selected plus page shows it on Liquid Glass");
    UIViewController *titled = [[UIViewController alloc] init];
    titled.title = @"Compose";
    [self controllerWithSelectedPlusPage:titled context:@"host-tests-plus-own-title" plusButton:@{}];
    XCTAssertEqualObjects(titled.title, @"Compose", @"a page's own title is kept");
}

- (void)testShowsSelectionKeepsTheLensUnderTheSelectedPlusButton {
    if (![CYLConstants isLiquidGlassActive]) {
        return;
    }
    CYLTabBarController *plain = [self controllerWithSelectedPlusPage:[[UIViewController alloc] init] context:@"host-tests-lens-default" plusButton:@{}];
    BOOL plainShows = [plain tabBarController:plain shouldShowPlatterLiquidLensViewForControl:[[UIControl alloc] init]];
    CYLTabBarController *shows = [self controllerWithSelectedPlusPage:[[UIViewController alloc] init] context:@"host-tests-lens-shows"
                                                           plusButton:@{ CYLPlusButtonShowsSelection : @YES }];
    XCTAssertTrue([shows tabBarController:shows shouldShowPlatterLiquidLensViewForControl:[[UIControl alloc] init]]);
    if (![plain.tabBar isPlusButtonLayoutCentered]) {
        XCTAssertFalse(plainShows, @"without the key: the library hides it while the plus page is selected");
    }
}

- (void)testThePlusButtonPageIsNotATabAndReportsMinusOne {
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    __block NSInteger selectedIndex = 99;
    __block NSString *selectedIdentifier;
    hostView.didSelectTab = ^(NSInteger index, NSString *identifier) {
        selectedIndex = index;
        selectedIdentifier = identifier;
    };
    hostView.configuration = @{
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemIdentifier : @"a" },
                                                      @{ CYLTabBarItemTitle : @"B", CYLTabBarItemIdentifier : @"b" } ],
        CYLTabBarControllerPlusButton : @{ CYLTabBarItemTitle : @"Menu", CYLTabBarItemImage : CYLHostTestsImage(),
                                           CYLTabBarItemIdentifier : @"plus", CYLTabBarItemPageIdentifier : @"menu" },
    };
    hostView.selectedIndex = 1;
    [self waitForTabBarControllerOf:hostView];
    CYLTabBarController *tabBarController = hostView.tabBarController;
    UIViewController *plusPage = [CYLPlusButton plusChildViewControllerForTabBarContext:tabBarController.context];
    XCTAssertNotNil(plusPage);
    XCTAssertEqual(tabBarController.selectedViewController.cyl_tabBarItemIdentifier, @"b");
    [(id<UITabBarControllerDelegate>)hostView tabBarController:tabBarController didSelectViewController:plusPage];
    XCTAssertEqual(selectedIndex, -1);
    XCTAssertEqualObjects(selectedIdentifier, @"plus");
}

- (void)testPreferredHeightIncludesTheOverflowWhenAsked {
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    hostView.heightIncludesOverflow = YES;
    hostView.configuration = @{ CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A" }, @{ CYLTabBarItemTitle : @"B" } ] };
    [self waitForTabBarControllerOf:hostView];
    [hostView setNeedsLayout];
    [hostView layoutIfNeeded];
    CGFloat barHeight = CGRectGetHeight(hostView.tabBarController.tabBar.frame);
    XCTAssertGreaterThan(barHeight, 0);
    XCTAssertGreaterThanOrEqual(hostView.preferredHeight, ceil(barHeight + 8));
}

- (void)testTransparentStripPassesTouchesExceptOnThePlusButton {
    CYLTabBarHostView *hostView = [self hostViewInWindow];
    hostView.heightIncludesOverflow = YES;
    __block NSInteger changes = 0;
    hostView.touchableRectsDidChange = ^(NSArray<NSValue *> *rects) {
        changes++;
    };
    XCTAssertEqual(hostView.touchableRects.count, 0u);
    hostView.configuration = @{
        CYLTabBarControllerContext : @"host-tests-strip",
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A" }, @{ CYLTabBarItemTitle : @"B" } ],
        // [EN] A 90 pt background image, as in Example-PAG: it rises above the bar. [CN] 90 pt 的背景图，与 Example-PAG 相同：高出 TabBar。
        CYLTabBarControllerPlusButton : @{ CYLTabBarItemTitle : @"Menu",
                                           CYLPlusButtonBackgroundImage : [[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(90, 90)]
                                               imageWithActions:^(UIGraphicsImageRendererContext *context) {
                                                   [UIColor.blueColor setFill];
                                                   [context fillRect:CGRectMake(0, 0, 90, 90)];
                                               }] },
    };
    [self waitForTabBarControllerOf:hostView];
    [hostView setNeedsLayout];
    [hostView layoutIfNeeded];
    XCTAssertEqual(hostView.touchableRects.count, 2u);
    XCTAssertGreaterThan(changes, 0);
    CGRect bar = hostView.touchableRects[0].CGRectValue;
    CGRect plus = hostView.touchableRects[1].CGRectValue;
    XCTAssertTrue(CGRectEqualToRect(bar, [hostView.tabBarController.tabBar convertRect:hostView.tabBarController.tabBar.bounds toView:hostView]));
    XCTAssertGreaterThan(CGRectGetWidth(plus), 0);
    // [EN] Above the bar, away from the plus button: the views below get the touch. [CN] TabBar 上方、PlusButton 之外：触摸交给下方的视图。
    CGPoint strip = CGPointMake(2, CGRectGetMinY(bar) - 2);
    XCTAssertTrue(CGRectContainsPoint(hostView.bounds, strip));
    XCTAssertNil([hostView hitTest:strip withEvent:nil]);
    XCTAssertNotNil([hostView hitTest:CGPointMake(CGRectGetMidX(bar), CGRectGetMidY(bar)) withEvent:nil]);
    // [EN] The plus button's part above the bar, inside this view: the plus button. [CN] PlusButton 位于 TabBar 上方、本视图内的部分：命中 PlusButton。
    UIView *plusButton = [CYLPlusButton plusButtonForTabBarContext:@"host-tests-strip"];
    XCTAssertLessThan(CGRectGetMinY(plus), CGRectGetMinY(bar));
    UIView *hit = [hostView hitTest:CGPointMake(CGRectGetMidX(plus), (CGRectGetMinY(plus) + CGRectGetMinY(bar)) / 2) withEvent:nil];
    XCTAssertTrue([hit isDescendantOfView:plusButton], @"%@", hit);
    // [EN] A taller view (Flutter sets the preferred height) moves the bar down: the rects follow in the same layout pass.
    // [CN] 视图变高（Flutter 设置所需高度）会让 TabBar 下移：矩形在同一次布局中随之更新。
    CGRect frame = hostView.frame;
    frame.size.height += 40;
    hostView.frame = frame;
    [hostView layoutIfNeeded];
    XCTAssertEqualWithAccuracy(CGRectGetMinY(hostView.touchableRects[0].CGRectValue), CGRectGetMinY(bar) + 40, 0.5);
    XCTAssertEqualWithAccuracy(CGRectGetMinY(hostView.touchableRects[1].CGRectValue), CGRectGetMinY(plus) + 40, 0.5);
    // [EN] Without the overflow, the whole view takes touches, as before. [CN] 不含高出部分时，整个视图接收触摸，与以前相同。
    hostView.heightIncludesOverflow = NO;
    XCTAssertNotNil([hostView hitTest:strip withEvent:nil]);
}

#pragma mark - Skins, images and FlatDesign badges

- (void)testASkinOfAnEarlierConfigurationIsReplacedButTheAppsOwnSkinStays {
    NSString *managerName = @"host-tests-skins";
    NSDictionary * (^configuration)(NSString *) = ^NSDictionary *(NSString *skin) {
        return @{
            CYLTabBarControllerContext : [@"host-tests-skins-" stringByAppendingString:skin],
            CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemIdentifier : @"a" } ],
            CYLTabBarControllerThemes : @{ skin : @{ CYLTabBarItemSelectedTitleColor : @"#FF0000" } },
            CYLTabBarControllerThemeManagerName : managerName,
        };
    };
    CYLThemeManager *manager = [CYLThemeManagerCenter themeManagerWithName:managerName];
    [CYLTabBarController tabBarControllerWithConfiguration:configuration(@"Default")];
    XCTAssertEqualObjects(manager.currentThemeIdentifier, @"Default");
    [CYLTabBarController tabBarControllerWithConfiguration:configuration(@"Christmas")];
    XCTAssertEqualObjects(manager.currentThemeIdentifier, @"Christmas", @"a skin only an earlier configuration had is not kept");
    [manager addThemeIdentifier:@"App" theme:[[NSObject alloc] init]];
    manager.currentThemeIdentifier = @"App";
    [CYLTabBarController tabBarControllerWithConfiguration:configuration(@"Ocean")];
    XCTAssertEqualObjects(manager.currentThemeIdentifier, @"App", @"a skin the app chose stays");
}

- (void)testImagesLoadedFromValuesAreDrawnAsTheyAre {
    UIImage *image = CYLHostTestsImage();
    XCTAssertEqual(image.renderingMode, UIImageRenderingModeAutomatic);
    UIImage *loaded = [CYLTabBarHostView imageForValue:@"file:///icon.png" resolver:^UIImage *(id value) { return image; }];
    XCTAssertEqual(loaded.renderingMode, UIImageRenderingModeAlwaysOriginal, @"full color icons keep their colors, as image names");
    UIImage *template = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImage *kept = [CYLTabBarHostView imageForValue:@"file:///icon.png" resolver:^UIImage *(id value) { return template; }];
    XCTAssertEqual(kept.renderingMode, UIImageRenderingModeAlwaysTemplate, @"a rendering mode chosen by the resolver stays");
}

- (void)testFlatDesignBadgesOfPagesOutsideANavigationControllerGoOnTheFlatButtons {
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : @"host-tests-flat-badges",
        CYLTabBarControllerStyleType : @"flatDesign",
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
            return [[UIViewController alloc] init];
        },
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemIdentifier : @"a", CYLTabBarItemImage : CYLHostTestsImage() },
                                                      @{ CYLTabBarItemTitle : @"B", CYLTabBarItemIdentifier : @"b", CYLTabBarItemImage : CYLHostTestsImage() } ],
    }];
    if (tabBarController.tabBarStyleType != CYLTabBarStyleTypeFlatDesign) {
        return;
    }
    self.window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 390, 844)];
    self.window.rootViewController = tabBarController;
    self.window.hidden = NO;
    [self.window layoutIfNeeded];
    UIViewController *page = tabBarController.viewControllers[1];
    XCTAssertNil(page.navigationController);
    id host = [page cyl_getActualBadgeSuperView];
    XCTAssertTrue([host isKindOfClass:[UIView class]]);
    UIView *ancestor = host;
    while (ancestor && ![ancestor isKindOfClass:[CYLFlatDesignTabBar class]]) {
        ancestor = ancestor.superview;
    }
    XCTAssertNotNil(ancestor, @"the badge sits on a visible flat button, not on the hidden system tab button");
}

@end
