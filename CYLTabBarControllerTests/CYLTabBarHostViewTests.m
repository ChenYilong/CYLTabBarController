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
    [(id<UITabBarControllerDelegate>)hostView tabBarController:tabBarController didSelectViewController:first];
    XCTAssertEqual(selectedIndex, 0);
    XCTAssertEqualObjects(selectedIdentifier, @"a");
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

@end
