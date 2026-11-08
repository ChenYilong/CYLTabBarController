//
//  CYLTabBarPageRegistryTests.m
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <XCTest/XCTest.h>
#import <stdatomic.h>
#import <CYLTabBarController/CYLTabBarController.h>

/// [EN] A page registered automatically under "registry-tests-auto". [CN] 自动按 "registry-tests-auto" 注册的页面。
@interface CYLPageRegistryTestsAutoPage : UIViewController <CYLTabBarPage>
@end

@implementation CYLPageRegistryTestsAutoPage
+ (NSString *)cylTabBarPageIdentifier {
    return @"registry-tests-auto";
}
@end

/// [EN] An app object that provides pages without being a CYLTabBarPageRegistry. [CN] 不是 CYLTabBarPageRegistry 的页面提供对象。
@interface CYLPageRegistryTestsRouter : NSObject <CYLTabBarPageProviding>
@property (nonatomic, copy) NSDictionary<NSString *, CYLTabBarPageProvider> *routes;
@end

@implementation CYLPageRegistryTestsRouter
- (CYLTabBarPageProvider)pageProviderForPageIdentifier:(NSString *)pageIdentifier {
    return self.routes[pageIdentifier];
}
@end

@interface CYLTabBarPageRegistryTests : XCTestCase
@end

@implementation CYLTabBarPageRegistryTests

- (void)tearDown {
    [CYLTabBarPageRegistry.sharedRegistry unregisterPageIdentifier:@"registry-tests-shared"];
    [super tearDown];
}

static CYLTabBarPageProvider CYLTestPage(NSString *name) {
    return ^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
        UIViewController *page = [[UIViewController alloc] init];
        page.title = name;
        return page;
    };
}

static NSDictionary *CYLTestTab(NSString *title, NSString *pageIdentifier) {
    return @{ CYLTabBarItemTitle : title, CYLTabBarItemPageIdentifier : pageIdentifier };
}

#pragma mark - Registry

- (void)testRegistrationTrimsIdentifiersAndIgnoresBlankOnes {
    CYLTabBarPageRegistry *registry = [[CYLTabBarPageRegistry alloc] init];
    [registry registerPageProvider:CYLTestPage(@"a") forPageIdentifier:@"  a  "];
    [registry registerPageProvider:CYLTestPage(@"blank") forPageIdentifier:@"   "];
    [registry registerPageProvider:CYLTestPage(@"bc") forPageIdentifiers:@[ @"b", @"c" ]];
    XCTAssertEqualObjects(registry.registeredPageIdentifiers, (@[ @"a", @"b", @"c" ]));
    XCTAssertNotNil([registry pageProviderForPageIdentifier:@"a"]);
    XCTAssertNotNil([registry pageProviderForPageIdentifier:@" b "]);
    [registry unregisterPageIdentifier:@"a"];
    XCTAssertNil([registry pageProviderForPageIdentifier:@"a"]);
    [registry removeAllPageProviders];
    XCTAssertEqual(registry.registeredPageIdentifiers.count, 0u);
}

- (void)testFactoryReceivesATypedRequestWithoutPrivateKeys {
    CYLTabBarPageRegistry *registry = [[CYLTabBarPageRegistry alloc] init];
    __block CYLTabBarPageRequest *received = nil;
    [registry registerPageFactory:^UIViewController *(CYLTabBarPageRequest *request) {
        received = request;
        return [[UIViewController alloc] init];
    } forPageIdentifier:@"web"];
    NSDictionary *tab = @{ CYLTabBarItemTitle : @"Web", CYLTabBarItemIdentifier : @"discover", CYLTabBarItemPageIdentifier : @"web",
                           CYLTabBarItemPageParameters : @{ @"url" : @"https://example.com" }, @"_CYLPrivate" : @YES };
    NSArray *pages = [CYLTabBarPageRegistry pagesOfTabs:@[ tab ] registry:registry resolver:nil lookupOrder:nil keptTabs:nil skipped:nil];
    XCTAssertEqual(pages.count, 1u);
    XCTAssertEqualObjects(received.pageIdentifier, @"web");
    XCTAssertEqualObjects(received.tabIdentifier, @"discover");
    XCTAssertEqualObjects(received.title, @"Web");
    XCTAssertEqualObjects(received.parameters[@"url"], @"https://example.com");
    XCTAssertNil(received.attributes[@"_CYLPrivate"]);
}

- (void)testRegisterPageClassUsesTheClassIdentifier {
    CYLTabBarPageRegistry *registry = [[CYLTabBarPageRegistry alloc] init];
    [registry registerPageClass:[CYLPageRegistryTestsAutoPage class]];
    [registry registerPageClass:[NSObject class]];
    XCTAssertEqualObjects(registry.registeredPageIdentifiers, @[ @"registry-tests-auto" ]);
    NSArray *pages = [CYLTabBarPageRegistry pagesOfTabs:@[ CYLTestTab(@"Auto", @"registry-tests-auto") ] registry:registry resolver:nil
                                            lookupOrder:@[ CYLTabBarPageSourceInstanceRegistry ] keptTabs:nil skipped:nil];
    XCTAssertTrue([pages.firstObject isKindOfClass:[CYLPageRegistryTestsAutoPage class]]);
}

#pragma mark - Lookup

- (void)testPageIdentifierFallsBackToTheTabIdentifier {
    XCTAssertEqualObjects([CYLTabBarPageRegistry pageIdentifierOfTab:@{ CYLTabBarItemIdentifier : @"home" }], @"home");
    // [EN] A dictionary literal has commas: parentheses keep it one macro argument. [CN] 字典字面量含逗号：用括号保证它是一个宏参数。
    XCTAssertEqualObjects(([CYLTabBarPageRegistry pageIdentifierOfTab:@{ CYLTabBarItemIdentifier : @"home", CYLTabBarItemPageIdentifier : @" " }]), @"home");
    XCTAssertEqualObjects(([CYLTabBarPageRegistry pageIdentifierOfTab:@{ CYLTabBarItemIdentifier : @"home", CYLTabBarItemPageIdentifier : @"web" }]), @"web");
    XCTAssertNil([CYLTabBarPageRegistry pageIdentifierOfTab:@{ CYLTabBarItemTitle : @"No ID" }]);
}

- (void)testDefaultLookupOrderIsInstanceResolverSharedAutomatic {
    CYLTabBarPageRegistry *instance = [[CYLTabBarPageRegistry alloc] init];
    [instance registerPageProvider:CYLTestPage(@"instance") forPageIdentifier:@"registry-tests-shared"];
    [CYLTabBarPageRegistry.sharedRegistry registerPageProvider:CYLTestPage(@"shared") forPageIdentifier:@"registry-tests-shared"];
    CYLTabBarPageProvider resolver = CYLTestPage(@"resolver");
    NSArray *tabs = @[ CYLTestTab(@"Shared", @"registry-tests-shared"), CYLTestTab(@"Auto", @"registry-tests-auto") ];

    NSArray<UIViewController *> *pages = [CYLTabBarPageRegistry pagesOfTabs:tabs registry:instance resolver:resolver lookupOrder:nil keptTabs:nil skipped:nil];
    XCTAssertEqualObjects([pages valueForKey:@"title"], (@[ @"instance", @"resolver" ]));

    pages = [CYLTabBarPageRegistry pagesOfTabs:tabs registry:nil resolver:nil lookupOrder:nil keptTabs:nil skipped:nil];
    XCTAssertEqualObjects(pages.firstObject.title, @"shared");
    XCTAssertTrue([pages.lastObject isKindOfClass:[CYLPageRegistryTestsAutoPage class]]);

    NSMutableArray<CYLTabBarSkippedTab *> *skipped = [NSMutableArray array];
    pages = [CYLTabBarPageRegistry pagesOfTabs:tabs registry:nil resolver:nil
                                   lookupOrder:@[ CYLTabBarPageSourceSharedRegistry ] keptTabs:nil skipped:skipped];
    XCTAssertEqual(pages.count, 1u);
    XCTAssertEqual(skipped.count, 1u);
    XCTAssertEqual(skipped.firstObject.reason, CYLTabBarPageSkipReasonUnregistered);
    XCTAssertEqualObjects(skipped.firstObject.pageIdentifier, @"registry-tests-auto");
}

- (void)testAnyPageProvidingObjectWorksAsTheRegistry {
    CYLPageRegistryTestsRouter *router = [[CYLPageRegistryTestsRouter alloc] init];
    router.routes = @{ @"routed" : CYLTestPage(@"routed") };
    NSArray<UIViewController *> *pages = [CYLTabBarPageRegistry pagesOfTabs:@[ CYLTestTab(@"Routed", @"routed") ] registry:router resolver:nil
                                                                 lookupOrder:nil keptTabs:nil skipped:nil];
    XCTAssertEqualObjects(pages.firstObject.title, @"routed");
}

- (void)testSkippedTabsCarryTheReason {
    CYLTabBarPageRegistry *registry = [[CYLTabBarPageRegistry alloc] init];
    [registry registerPageProvider:^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
        [NSException raise:NSInternalInconsistencyException format:@"%@", @"boom"];
        return nil;
    } forPageIdentifier:@"raises"];
    [registry registerPageProvider:^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
        return (UIViewController *)(id)[[UITabBarController alloc] init];
    } forPageIdentifier:@"nested"];
    UIViewController *shared = [[UIViewController alloc] init];
    [registry registerPageProvider:^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
        return shared;
    } forPageIdentifiers:@[ @"first", @"second" ]];
    NSArray *tabs = @[ @"not a tab", @{ CYLTabBarItemTitle : @"No ID" }, CYLTestTab(@"Raises", @"raises"), CYLTestTab(@"Nested", @"nested"),
                       CYLTestTab(@"First", @"first"), CYLTestTab(@"Second", @"second"), CYLTestTab(@"Unknown", @"unknown") ];
    NSMutableArray<NSDictionary<NSString *, id> *> *kept = [NSMutableArray array];
    NSMutableArray<CYLTabBarSkippedTab *> *skipped = [NSMutableArray array];
    NSArray *pages = [CYLTabBarPageRegistry pagesOfTabs:tabs registry:registry resolver:nil
                                            lookupOrder:@[ CYLTabBarPageSourceInstanceRegistry ] keptTabs:kept skipped:skipped];
    XCTAssertEqual(pages.count, 1u);
    XCTAssertEqualObjects(kept, @[ tabs[4] ]);
    NSArray<NSNumber *> *reasons = [skipped valueForKey:@"reason"];
    XCTAssertEqualObjects(reasons, (@[ @(CYLTabBarPageSkipReasonInvalidTab), @(CYLTabBarPageSkipReasonMissingIdentifier),
                                       @(CYLTabBarPageSkipReasonProviderFailed), @(CYLTabBarPageSkipReasonProviderFailed),
                                       @(CYLTabBarPageSkipReasonProviderFailed), @(CYLTabBarPageSkipReasonUnregistered) ]));
    XCTAssertTrue([skipped[2].detail containsString:@"boom"]);
    XCTAssertEqualObjects(skipped[5].title, @"Unknown");
}

#pragma mark - Tab bar controller

- (void)testControllerKeepsItsSourcesAndSkippedTabs {
    CYLTabBarPageRegistry *registry = [[CYLTabBarPageRegistry alloc] init];
    [registry registerPageProvider:CYLTestPage(@"home") forPageIdentifier:@"home"];
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerPageRegistry : registry,
        CYLTabBarControllerAutomaticPageRegistration : @NO,
        CYLTabBarControllerPageLookupOrder : @"instance, shared",
        CYLTabBarControllerTabBarItemsAttributes : @[ CYLTestTab(@"Home", @"home"),
                                                      CYLTestTab(@"Auto", @"registry-tests-auto"),
                                                      @{ CYLTabBarItemTitle : @"Android", CYLTabBarItemPageIdentifier : @"home", CYLTabBarItemPlatforms : @"android" } ],
    }];
    XCTAssertTrue(tabBarController.cyl_pagesFromPageIdentifiers);
    XCTAssertEqual(tabBarController.cyl_pageRegistry, registry);
    XCTAssertNil(tabBarController.cyl_pageResolver);
    XCTAssertEqualObjects(tabBarController.cyl_pageLookupOrder, (@[ CYLTabBarPageSourceInstanceRegistry, CYLTabBarPageSourceSharedRegistry ]));
    XCTAssertEqual(tabBarController.viewControllers.count, 1u);
    XCTAssertEqual(tabBarController.cyl_skippedTabs.count, 2u);
    XCTAssertEqual(tabBarController.cyl_skippedTabs[0].reason, CYLTabBarPageSkipReasonExcluded);
    XCTAssertEqualObjects(tabBarController.cyl_skippedTabs[0].title, @"Android");
    XCTAssertEqual(tabBarController.cyl_skippedTabs[1].reason, CYLTabBarPageSkipReasonUnregistered);
}

- (void)testReloadResolvesNewTabsAndReusesExistingPages {
    CYLTabBarPageRegistry *registry = [[CYLTabBarPageRegistry alloc] init];
    __block NSUInteger created = 0;
    [registry registerPageProvider:^UIViewController *(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes) {
        created++;
        UIViewController *page = [[UIViewController alloc] init];
        page.title = pageIdentifier;
        return page;
    } forPageIdentifiers:@[ @"home", @"me", @"web" ]];
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerPageRegistry : registry,
        CYLTabBarControllerTabBarItemsAttributes : @[ CYLTestTab(@"Home", @"home"), CYLTestTab(@"Me", @"me") ],
    }];
    XCTAssertEqual(created, 2u);
    UIViewController *home = tabBarController.viewControllers.firstObject;

    [tabBarController reloadTabBarItemsWithAttributes:@[ CYLTestTab(@"Web", @"web"), CYLTestTab(@"Home", @"home"), CYLTestTab(@"Missing", @"missing") ]];
    XCTAssertEqual(created, 3u, @"only the new page is created");
    XCTAssertEqualObjects([tabBarController.viewControllers valueForKey:@"title"], (@[ @"web", @"home" ]));
    XCTAssertEqual(tabBarController.viewControllers[1], home, @"the page of a kept tab is reused");
    XCTAssertEqual(tabBarController.cyl_skippedTabs.count, 1u);
    XCTAssertEqualObjects(tabBarController.cyl_skippedTabs.firstObject.pageIdentifier, @"missing");
    XCTAssertEqual(tabBarController.tabBarItemsAttributes.count, 2u);
}

#pragma mark - Asynchronous pages

- (void)testAsynchronousPageIsSwappedInAndAFailedOneRemovesTheTab {
    CYLTabBarPageRegistry *registry = [[CYLTabBarPageRegistry alloc] init];
    [registry registerPageProvider:CYLTestPage(@"home") forPageIdentifier:@"home"];
    // [EN] The pages arrive off the main thread, from the test's own queue: a busy CI runner may run the shared global
    //      queues late. `completions` tells a failure apart: no delivery at all, or a delivery that was not applied.
    // [CN] 页面从测试自己的队列、在非主线程送达：繁忙的 CI 机器可能延后执行共享的全局队列。`completions` 用于区分失败原因：完全没有送达，
    //      还是送达后未被应用。
    dispatch_queue_t deliveryQueue = dispatch_queue_create("CYLTabBarPageRegistryTests.delivery",
                                                           dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0));
    __block atomic_int completions = 0;
    [registry registerAsyncPageFactory:^UIViewController *(CYLTabBarPageRequest *request, CYLTabBarPageCompletion completion) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), deliveryQueue, ^{
            UIViewController *page = [request.pageIdentifier isEqualToString:@"later"] ? [[UIViewController alloc] init] : nil;
            page.title = request.title;
            completion(page);
            completion(page); // [EN] A second call is ignored. [CN] 第二次调用被忽略。
            atomic_fetch_add(&completions, 1);
        });
        return nil;
    } forPageIdentifiers:@[ @"later", @"never" ]];
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerPageRegistry : registry,
        CYLTabBarControllerTabBarItemsAttributes : @[ CYLTestTab(@"Later", @"later"), CYLTestTab(@"Home", @"home"), CYLTestTab(@"Never", @"never") ],
    }];
    XCTAssertEqual(tabBarController.viewControllers.count, 3u);
    XCTAssertEqual(tabBarController.cyl_pendingPages.count, 2u);
    XCTAssertTrue([tabBarController.viewControllers[0] isKindOfClass:[CYLTabBarPagePlaceholder class]]);
    XCTAssertTrue(tabBarController.viewControllers[0].cyl_isPendingPage);

    // [EN] Wait for the deliveries themselves, not a fixed delay: a busy CI runner may run the utility queue late.
    // [CN] 等待页面真正送达，而不是固定延时：繁忙的 CI 机器可能延后执行 utility 队列。
    NSPredicate *delivered = [NSPredicate predicateWithBlock:^BOOL(CYLTabBarController *controller, NSDictionary *bindings) {
        return controller.cyl_pendingPages.count == 0;
    }];
    [self waitForExpectations:@[ [[XCTNSPredicateExpectation alloc] initWithPredicate:delivered object:tabBarController] ] timeout:20];

    XCTAssertEqual(tabBarController.cyl_pendingPages.count, 0u, @"factory completions run: %d of 2", atomic_load(&completions));
    XCTAssertEqualObjects([tabBarController.viewControllers valueForKey:@"title"], (@[ @"Later", @"home" ]), @"\"later\" swapped in, \"never\" removed");
    XCTAssertFalse([tabBarController.viewControllers[0] isKindOfClass:[CYLTabBarPagePlaceholder class]]);
    XCTAssertEqual(tabBarController.tabBarItemsAttributes.count, 2u);
    XCTAssertEqual(tabBarController.cyl_skippedTabs.count, 1u);
    XCTAssertEqualObjects(tabBarController.cyl_skippedTabs.firstObject.pageIdentifier, @"never");
    XCTAssertEqual(tabBarController.cyl_skippedTabs.firstObject.reason, CYLTabBarPageSkipReasonProviderFailed);
}

- (void)testAsynchronousFactoryMayCompleteSynchronouslyAndUseItsOwnPlaceholder {
    CYLTabBarPageRegistry *registry = [[CYLTabBarPageRegistry alloc] init];
    UIViewController *placeholder = [[UIViewController alloc] init];
    placeholder.title = @"placeholder";
    [registry registerAsyncPageFactory:^UIViewController *(CYLTabBarPageRequest *request, CYLTabBarPageCompletion completion) {
        UIViewController *page = [[UIViewController alloc] init];
        page.title = @"now";
        completion(page);
        return placeholder;
    } forPageIdentifier:@"now"];
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerPageRegistry : registry,
        CYLTabBarControllerTabBarItemsAttributes : @[ CYLTestTab(@"Now", @"now") ],
    }];
    XCTAssertEqual(tabBarController.viewControllers.firstObject, placeholder, @"swapped on the next run loop turn, not inside init");
    XCTAssertNotNil(placeholder.cyl_loadedPage);
    XCTestExpectation *swapped = [self expectationWithDescription:@"swapped"];
    dispatch_async(dispatch_get_main_queue(), ^{
        [swapped fulfill];
    });
    [self waitForExpectationsWithTimeout:2 handler:nil];
    XCTAssertEqualObjects(tabBarController.viewControllers.firstObject.title, @"now");
    XCTAssertEqual(tabBarController.cyl_pendingPages.count, 0u);
}

- (void)testReloadWithViewControllersFromCodeIsUnchanged {
    UIViewController *first = [[UIViewController alloc] init];
    UIViewController *second = [[UIViewController alloc] init];
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ first, second ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"First" }, @{ CYLTabBarItemTitle : @"Second" } ]];
    XCTAssertFalse(tabBarController.cyl_pagesFromPageIdentifiers);
    [tabBarController reloadTabBarItemsWithAttributes:@[ @{ CYLTabBarItemTitle : @"1" }, @{ CYLTabBarItemTitle : @"2" } ]];
    XCTAssertEqualObjects(tabBarController.viewControllers, (@[ first, second ]));
}

@end
