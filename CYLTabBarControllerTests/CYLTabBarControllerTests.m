//
//  CYLTabBarControllerTests.m
//  CYLTabBarControllerTests
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 15/10/25.
// [CN] Copyright (c) 2026年 https://github.com/ChenYilong .All rights reserved.
// [EN] Copyright (c) 2026 https://github.com/ChenYilong .All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>

@interface CYLTabBarControllerTests : XCTestCase

@end

@implementation CYLTabBarControllerTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

/// [EN] `reportsTapsToDelegate` replaces the deprecated `cyl_userInteractionDisabled` for the plus button's reports: YES by
///      default, the deprecated flag still opts out while the property is not set, and a value set on it wins.
/// [CN] `reportsTapsToDelegate` 取代已废弃的 `cyl_userInteractionDisabled` 控制 PlusButton 的上报：默认 YES；未设置时废弃标记仍可关闭上报；
///      设置后以它为准。
- (void)testPlusButtonReportsTapsToDelegate {
    CYLPlusButton *plusButton = [[CYLPlusButton alloc] init];
    XCTAssertTrue(plusButton.reportsTapsToDelegate, @"reported by default");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    plusButton.cyl_userInteractionDisabled = YES;
    XCTAssertFalse(plusButton.reportsTapsToDelegate, @"the deprecated flag still opts out while the property is not set");
    plusButton.reportsTapsToDelegate = YES;
    XCTAssertTrue(plusButton.reportsTapsToDelegate, @"a value set on the property wins over the deprecated flag");
    XCTAssertTrue(plusButton.cyl_userInteractionDisabled, @"the deprecated flag itself is unchanged");
#pragma clang diagnostic pop
    plusButton.reportsTapsToDelegate = NO;
    XCTAssertFalse(plusButton.reportsTapsToDelegate);
}

/// [EN] `CYLTabBarControllerLocalization`: a configuration file and its tables in the same folder; the texts follow the
///      library's language, a key without a translation stays, and nothing changes without the key.
/// [CN] `CYLTabBarControllerLocalization`：配置文件与字符串表在同一目录；文本跟随本库语言，没有译文的键保持原样，没有该键时不做任何改变。
- (void)testConfigurationFileLocalization {
    NSString *folder = [NSTemporaryDirectory() stringByAppendingPathComponent:NSUUID.UUID.UUIDString];
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSDictionary<NSString *, NSString *> *tables = @{
        @"en" : @"\"tab.home\" = \"Home\";\n\"tab.me\" = \"Me\";\n\"tab.home.selected\" = \"Refresh\";\n\"tab.post\" = \"Post\";\n",
        @"zh-Hans" : @"/* 简体中文 */\n\"tab.home\" = \"首页\";\n\"tab.me\" = \"我的\";\n\"tab.home.selected\" = \"刷新\";\n\"tab.post\" = \"发布\";\n",
    };
    for (NSString *language in tables) {
        NSString *lproj = [folder stringByAppendingPathComponent:[NSString stringWithFormat:@"Texts/%@.lproj", language]];
        XCTAssertTrue([fileManager createDirectoryAtPath:lproj withIntermediateDirectories:YES attributes:nil error:NULL]);
        XCTAssertTrue([tables[language] writeToFile:[lproj stringByAppendingPathComponent:@"Tabs.strings"] atomically:YES encoding:NSUTF8StringEncoding error:NULL]);
    }
    NSString *json = @"{\"CYLTabBarControllerLocalization\": {\"CYLTabBarLocalizationTableName\": \"Tabs\", \"CYLTabBarLocalizationPath\": \"Texts\"},"
                     @" \"CYLTabBarControllerTabBarItemsAttributes\": ["
                     @"{\"CYLTabBarItemIdentifier\": \"home\", \"CYLTabBarItemTitle\": \"tab.home\", \"CYLTabBarItemSelectedTitle\": \"tab.home.selected\", \"CYLTabBarItemAccessibilityHint\": \"tab.missing\"},"
                     @"{\"CYLTabBarItemIdentifier\": \"me\", \"CYLTabBarItemTitle\": \"tab.me\"}],"
                     @" \"CYLTabBarControllerPlusButton\": {\"CYLTabBarItemTitle\": \"tab.post\"}}";
    NSString *file = [folder stringByAppendingPathComponent:@"tabs.json"];
    XCTAssertTrue([json writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:NULL]);
    UIViewController * (^resolver)(NSString *, NSDictionary *) = ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
        return [[UIViewController alloc] init];
    };
    NSArray<NSDictionary *> * (^titlesForLanguage)(NSString *) = ^NSArray<NSDictionary *> *(NSString *language) {
        CYLSetLocalizationLanguage(language);
        NSError *error = nil;
        NSMutableDictionary *configuration = [[CYLTabBarController configurationWithContentsOfFile:file error:&error] mutableCopy];
        XCTAssertNil(error);
        configuration[CYLTabBarControllerPageResolver] = resolver;
        return [CYLTabBarController tabBarControllerWithConfiguration:configuration].tabBarItemsAttributes;
    };
    NSArray<NSDictionary *> *english = titlesForLanguage(@"en");
    XCTAssertEqualObjects(english[0][CYLTabBarItemTitle], @"Home");
    XCTAssertEqualObjects(english[0][CYLTabBarItemSelectedTitle], @"Refresh");
    XCTAssertEqualObjects(english[0][CYLTabBarItemAccessibilityHint], @"tab.missing", @"a key without a translation stays");
    XCTAssertEqualObjects(english[1][CYLTabBarItemTitle], @"Me");
    NSArray<NSDictionary *> *chinese = titlesForLanguage(@"zh-Hans");
    XCTAssertEqualObjects(chinese[0][CYLTabBarItemTitle], @"首页");
    XCTAssertEqualObjects(chinese[1][CYLTabBarItemTitle], @"我的");
    NSDictionary *plusButton = [CYLTabBarController configurationWithContentsOfFile:file error:NULL][CYLTabBarControllerPlusButton];
    XCTAssertEqualObjects(plusButton[CYLTabBarItemTitle], @"tab.post", @"the file is read as is; the texts are translated when the controller is made");
    CYLSetLocalizationLanguage(nil);
    // [EN] Without the key, nothing changes. [CN] 没有该键时不做任何改变。
    NSDictionary *plain = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemIdentifier : @"home", CYLTabBarItemTitle : @"tab.home" } ],
        CYLTabBarControllerPageResolver : resolver,
    }].tabBarItemsAttributes.firstObject;
    XCTAssertEqualObjects(plain[CYLTabBarItemTitle], @"tab.home");
    // [EN] Tables downloaded into the sandbox: "sandbox:Caches/…", from a configuration made in code. [CN] 下载到沙盒中的字符串表：
    //      "sandbox:Caches/…"，配置在代码中创建。
    NSString *caches = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    NSString *downloaded = [NSString stringWithFormat:@"cyl-localization-test-%@", NSUUID.UUID.UUIDString];
    NSString *downloadedLproj = [caches stringByAppendingPathComponent:[downloaded stringByAppendingPathComponent:@"en.lproj"]];
    XCTAssertTrue([fileManager createDirectoryAtPath:downloadedLproj withIntermediateDirectories:YES attributes:nil error:NULL]);
    XCTAssertTrue([@"\"tab.home\" = \"Downloaded home\";" writeToFile:[downloadedLproj stringByAppendingPathComponent:@"Localizable.strings"] atomically:YES encoding:NSUTF8StringEncoding error:NULL]);
    CYLSetLocalizationLanguage(@"en");
    NSDictionary *fromSandbox = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerLocalization : @{ CYLTabBarLocalizationPath : [@"sandbox:Caches/" stringByAppendingString:downloaded] },
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemIdentifier : @"home", CYLTabBarItemTitle : @"tab.home" } ],
        CYLTabBarControllerPageResolver : resolver,
    }].tabBarItemsAttributes.firstObject;
    CYLSetLocalizationLanguage(nil);
    XCTAssertEqualObjects(fromSandbox[CYLTabBarItemTitle], @"Downloaded home");
    [fileManager removeItemAtPath:[caches stringByAppendingPathComponent:downloaded] error:NULL];
    [fileManager removeItemAtPath:folder error:NULL];
}

/// [EN] `cyl_navigationTitleFollowsTabBarItemTitle`: the navigation bar title is the tab title when the tab is set up and
///      after an in-place update, which also posts `CYLTabBarItemTitleDidChangeNotification`; a page that does not follow
///      keeps its own title.
/// [CN] `cyl_navigationTitleFollowsTabBarItemTitle`：Tab 设置时与原地更新后，导航栏标题都是 Tab 标题，更新还会发送
///      `CYLTabBarItemTitleDidChangeNotification`；不跟随的页面保留自己的标题。
- (void)testNavigationTitleFollowsTabBarItemTitle {
    UIViewController *home = [[UIViewController alloc] init];
    UIViewController *me = [[UIViewController alloc] init];
    CYL_NAVIGATION_TITLE_FOLLOWS_TAB_BAR_ITEM(home);
    me.navigationItem.title = @"Mine";
    UINavigationController *homeNavigation = [[UINavigationController alloc] initWithRootViewController:home];
    UINavigationController *meNavigation = [[UINavigationController alloc] initWithRootViewController:me];
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ homeNavigation, meNavigation ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"Home", CYLTabBarItemIdentifier : @"home" },
                                                                                                    @{ CYLTabBarItemTitle : @"Me", CYLTabBarItemIdentifier : @"me" } ]];
    XCTAssertEqualObjects(home.navigationItem.title, @"Home", @"set when the tab is set up");
    XCTAssertEqualObjects(CYL_TAB_BAR_ITEM_TITLE(home), @"Home");
    XCTAssertEqualObjects(CYL_TAB_BAR_ITEM_TITLE(me), @"Me");
    __block NSNotification *titleNote = nil;
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemTitleDidChangeNotification object:home queue:nil usingBlock:^(NSNotification *note) {
        titleNote = note;
    }];
    [tabBarController updateTabBarItemsWithAttributes:@[ @{ CYLTabBarItemTitle : @"★ Home" }, @{ CYLTabBarItemTitle : @"★ Me" } ]];
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    XCTAssertEqualObjects(home.navigationItem.title, @"★ Home", @"follows the in-place update");
    XCTAssertEqualObjects(CYL_TAB_BAR_ITEM_TITLE(home), @"★ Home");
    // [EN] The notification names exactly what changed. [CN] 通知精确指出变化的对象。
    XCTAssertEqual(titleNote.object, home);
    XCTAssertEqualObjects(titleNote.userInfo[CYLTabBarItemTitle], @"★ Home");
    XCTAssertEqualObjects(titleNote.userInfo[CYLTabBarItemOldTitleKey], @"Home");
    XCTAssertEqualObjects(titleNote.userInfo[CYLTabBarItemIdentifier], @"home");
    XCTAssertEqualObjects(titleNote.userInfo[CYLTabBarItemIndexKey], @0);
    XCTAssertEqual(titleNote.userInfo[CYLTabBarControllerKey], tabBarController);
    XCTAssertEqual(titleNote.userInfo[CYLTabBarItemViewControllerKey], homeNavigation);
    XCTAssertEqual(titleNote.userInfo[CYLTabBarItemKey], homeNavigation.tabBarItem);
    XCTAssertEqualObjects(me.navigationItem.title, @"Mine", @"a page that does not follow keeps its own title");

    // [EN] An image key posts the icon notification with that key; a title alone does not. [CN] 图片 key 发送带该 key 的图标通知；仅标题不发送。
    NSMutableArray<NSNotification *> *iconNotes = [NSMutableArray array];
    id iconObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemIconDidChangeNotification object:me queue:nil usingBlock:^(NSNotification *note) {
        [iconNotes addObject:note];
    }];
    [tabBarController updateTabBarItemAtIndex:1 attributes:@{ CYLTabBarItemTitle : @"Me again" }];
    XCTAssertEqual(iconNotes.count, 0u);
    UIImage *image = [UIImage systemImageNamed:@"star"];
    [tabBarController updateTabBarItemAtIndex:1 attributes:@{ CYLTabBarItemImage : image }];
    [[NSNotificationCenter defaultCenter] removeObserver:iconObserver];
    XCTAssertEqual(iconNotes.count, 1u);
    XCTAssertEqualObjects(iconNotes.firstObject.userInfo[CYLTabBarItemIndexKey], @1);
    XCTAssertEqualObjects(iconNotes.firstObject.userInfo[CYLTabBarItemIdentifier], @"me");
    XCTAssertEqual(iconNotes.firstObject.userInfo[CYLTabBarItemChangedAttributesKey][CYLTabBarItemImage], image);
}

/// [EN] A badge keeps its font when every title changes in place ("Change all titles" in the ObjC example).
/// [CN] 原地修改所有标题后，角标字体保持不变（ObjC 示例的「批量更换标题」）。
- (void)testABadgeKeepsItsFontWhenTheTitlesChangeInPlace {
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ [UIViewController new], [UIViewController new], [UIViewController new] ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"Home", CYLTabBarItemImage : [UIImage systemImageNamed:@"house"] },
                                                                                                    @{ CYLTabBarItemTitle : @"Nearby", CYLTabBarItemImage : [UIImage systemImageNamed:@"map"] },
                                                                                                    @{ CYLTabBarItemTitle : @"Me", CYLTabBarItemImage : [UIImage systemImageNamed:@"person"] } ]];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 402, 874)];
    window.rootViewController = tabBarController;
    window.hidden = NO;
    void (^layOut)(void) = ^{
        for (NSUInteger pass = 0; pass < 4; pass++) {
            [tabBarController.tabBar setNeedsLayout];
            [tabBarController.view layoutIfNeeded];
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
        }
    };
    layOut();
    [tabBarController.viewControllers[1].tabBarItem cyl_showBadgeValue:@"8" animationType:CYLBadgeAnimationTypeNone];
    layOut();
    NSArray<UILabel *> * (^badgeLabels)(void) = ^NSArray<UILabel *> * {
        NSMutableArray<UILabel *> *labels = [NSMutableArray array];
        NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:tabBarController.tabBar];
        while (queue.count) {
            UIView *view = queue.firstObject;
            [queue removeObjectAtIndex:0];
            if ([view isKindOfClass:[UILabel class]] && [((UILabel *)view).text isEqualToString:@"8"]) {
                [labels addObject:(UILabel *)view];
            }
            [queue addObjectsFromArray:view.subviews];
        }
        return labels;
    };
    NSArray<UILabel *> *before = badgeLabels();
    XCTAssertGreaterThan(before.count, 0u, @"the badge is shown");
    NSMutableArray<UIFont *> *fontsBefore = [NSMutableArray array];
    for (UILabel *label in before) {
        [fontsBefore addObject:label.font];
    }
    [tabBarController updateTabBarItemsWithAttributes:@[ @{ CYLTabBarItemTitle : @"★ Home" }, @{ CYLTabBarItemTitle : @"★ Nearby" }, @{ CYLTabBarItemTitle : @"★ Me" } ]];
    layOut();
    NSArray<UILabel *> *after = badgeLabels();
    XCTAssertEqual(after.count, before.count);
    for (NSUInteger index = 0; index < MIN(after.count, fontsBefore.count); index++) {
        XCTAssertEqualObjects(after[index].font, fontsBefore[index], @"badge %@ keeps its font", @(index));
        XCTAssertTrue(CGAffineTransformIsIdentity(after[index].transform), @"badge %@ is not scaled", @(index));
    }
    // [EN] The ObjC example's "8" pulses forever (`CYLBadgeAnimationTypeScale`): after the change it still pulses and keeps
    //      its font, rather than stopping at a small size. [CN] ObjC 示例中的「8」一直缩放（`CYLBadgeAnimationTypeScale`）：修改后
    //      仍在缩放、字体不变，而不是停在较小的尺寸。
    [tabBarController.viewControllers[2].tabBarItem cyl_showBadgeValue:@"8" animationType:CYLBadgeAnimationTypeScale];
    layOut();
    NSArray<UILabel *> *pulsing = [badgeLabels() filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UILabel *label, NSDictionary *bindings) {
        for (CALayer *layer = label.layer; layer; layer = layer.superlayer) {
            if (layer.animationKeys.count > 0) {
                return YES;
            }
        }
        return NO;
    }]];
    XCTAssertGreaterThan(pulsing.count, 0u, @"the scale badge animates");
    UIFont *pulsingFont = pulsing.firstObject.font;
    [tabBarController updateTabBarItemsWithAttributes:@[ @{ CYLTabBarItemTitle : @"Home" }, @{ CYLTabBarItemTitle : @"Nearby" }, @{ CYLTabBarItemTitle : @"Me" } ]];
    layOut();
    NSUInteger stillPulsing = 0;
    for (UILabel *label in badgeLabels()) {
        for (CALayer *layer = label.layer; layer; layer = layer.superlayer) {
            if (layer.animationKeys.count > 0) {
                stillPulsing++;
                XCTAssertEqualObjects(label.font, pulsingFont, @"the pulsing badge keeps its font");
                break;
            }
        }
    }
    XCTAssertGreaterThan(stillPulsing, 0u, @"the scale badge still animates after the titles changed");
}

/// [EN] VoiceOver reads a tab's new title after an in-place change, and a label the app set on the tab item is kept.
/// [CN] 原地修改标题后 VoiceOver 读出新标题，App 自己给 TabBarItem 设置的 label 保持不变。
- (void)testTabAccessibilityLabelsFollowTitlesAndKeepTheAppsLabels {
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ [UIViewController new], [UIViewController new] ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"A" },
                                                                                                    @{ CYLTabBarItemTitle : @"B" } ]];
    [tabBarController loadViewIfNeeded];
    UITabBarItem *appLabeledItem = tabBarController.viewControllers[1].tabBarItem;
    appLabeledItem.accessibilityLabel = @"Custom";
    [tabBarController updateTabBarItemAtIndex:0 attributes:@{ CYLTabBarItemTitle : @"★ A" }];
    [tabBarController updateTabBarItemAtIndex:1 attributes:@{ CYLTabBarItemTitle : @"★ B" }];
    [tabBarController.view setNeedsLayout];
    [tabBarController.view layoutIfNeeded];
    // [EN] The library writes the default label on Liquid Glass only: the classic tab buttons read the title themselves,
    //      and the item's label stays nil there (iOS 17.5 simulator).
    // [CN] 库只在液态玻璃下写入默认 label：经典样式的 Tab 按钮自己读取标题，item 的 label 保持为 nil（iOS 17.5 模拟器）。
    BOOL writesDefaultLabels = [CYLConstants isLiquidGlassActive];
    NSString * (^expected)(NSString *) = ^NSString *(NSString *title) {
        return writesDefaultLabels ? title : nil;
    };
    XCTAssertEqualObjects(tabBarController.viewControllers[0].tabBarItem.accessibilityLabel, expected(@"★ A"));
    XCTAssertEqualObjects(appLabeledItem.accessibilityLabel, @"Custom", @"the app's own label is kept");
    [tabBarController updateTabBarItemAtIndex:0 attributes:@{ CYLTabBarItemTitle : @"A" }];
    [tabBarController.view setNeedsLayout];
    [tabBarController.view layoutIfNeeded];
    XCTAssertEqualObjects(tabBarController.viewControllers[0].tabBarItem.accessibilityLabel, expected(@"A"), @"follows the title back");
}

/// [EN] The plus button's page follows the plus button's title: `-updatePlusButtonWithAttributes:` sets its navigation bar
///      title and posts the title notification with the page as object and `CYLPlusButtonKey`.
/// [CN] PlusButton 的页面跟随 PlusButton 的标题：`-updatePlusButtonWithAttributes:` 设置其导航栏标题，并发送以页面为 object、带有
///      `CYLPlusButtonKey` 的标题通知。
- (void)testPlusButtonTitleUpdatesItsPageNavigationTitle {
    NSString *context = [NSUUID UUID].UUIDString;
    UIViewController *plusPage = [[UIViewController alloc] init];
    CYL_NAVIGATION_TITLE_FOLLOWS_TAB_BAR_ITEM(plusPage);
    UINavigationController *plusNavigation = [[UINavigationController alloc] initWithRootViewController:plusPage];
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : context,
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemIdentifier : @"a" },
                                                      @{ CYLTabBarItemTitle : @"B", CYLTabBarItemIdentifier : @"b" } ],
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
            return [pageIdentifier isEqualToString:@"post"] ? plusNavigation : [[UIViewController alloc] init];
        },
        CYLTabBarControllerPlusButton : @{ CYLTabBarItemTitle : @"Post", CYLTabBarItemImage : [UIImage systemImageNamed:@"plus.circle"],
                                           CYLTabBarItemPageIdentifier : @"post" },
    }];
    [tabBarController loadViewIfNeeded];
    XCTAssertTrue([tabBarController.viewControllers containsObject:plusNavigation]);
    XCTAssertEqualObjects(plusPage.navigationItem.title, @"Post", @"the plus button's title when its tab is set up");
    XCTAssertEqualObjects(CYL_TAB_BAR_ITEM_TITLE(plusPage), @"Post");
    __block NSNotification *titleNote = nil;
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemTitleDidChangeNotification object:plusPage queue:nil usingBlock:^(NSNotification *note) {
        titleNote = note;
    }];
    XCTAssertTrue([tabBarController updatePlusButtonWithAttributes:@{ CYLTabBarItemTitle : @"★ Post" }]);
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    XCTAssertEqualObjects(plusPage.navigationItem.title, @"★ Post", @"follows the plus button's new title");
    XCTAssertEqualObjects(CYL_TAB_BAR_ITEM_TITLE(plusPage), @"★ Post");
    XCTAssertEqualObjects(titleNote.userInfo[CYLTabBarItemTitle], @"★ Post");
    XCTAssertEqualObjects(titleNote.userInfo[CYLTabBarItemOldTitleKey], @"Post");
    XCTAssertNotNil(titleNote.userInfo[CYLPlusButtonKey]);
    XCTAssertEqual(titleNote.userInfo[CYLTabBarItemViewControllerKey], plusNavigation);
    // [EN] VoiceOver: the tab under the plus button reads as the plus button, with its new title.
    // [CN] VoiceOver：PlusButton 下方的 Tab 读作 PlusButton，使用其新标题。
    [tabBarController.view setNeedsLayout];
    [tabBarController.view layoutIfNeeded];
    XCTAssertEqualObjects(plusNavigation.tabBarItem.accessibilityLabel, @"★ Post", @"not the first title, \"Post\"");
}

/// [EN] FIX: issue #787. `CYLTabBarItemIconRenderingMode` and the tab bar's defaults (`CYLTabBarControllerIconRenderingMode`,
///      `CYLTabBarControllerIconColor`, `CYLTabBarControllerSelectedIconColor`): "template" tints one image in both states,
///      "original" keeps the image's colors, a tab's own value wins, an unknown value is dropped, and an in-place update
///      keeps the tab's mode.
/// [CN] FIX: issue #787。`CYLTabBarItemIconRenderingMode` 与 TabBar 的默认值：「template」让一张图片在两种状态下着色，「original」保持原色，
///      Tab 自己的值优先，未知值被丢弃，原地更新时保持 Tab 的渲染方式。
- (void)testIconRenderingMode {
    UIImage * (^drawn)(UIColor *) = ^UIImage *(UIColor *color) {
        return [[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(8, 8)] imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [color setFill];
            [context fillRect:CGRectMake(0, 0, 8, 8)];
        }];
    };
    UIImage *icon = drawn(UIColor.blueColor);
    XCTAssertEqual(icon.renderingMode, UIImageRenderingModeAutomatic);
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : [NSUUID UUID].UUIDString,
        CYLTabBarControllerIconRenderingMode : @"Template",
        CYLTabBarControllerIconColor : @"#FF0000",
        CYLTabBarControllerSelectedIconColor : @"#00FF00",
        CYLTabBarControllerTabBarItemsAttributes : @[
            @{ CYLTabBarItemIdentifier : @"a", CYLTabBarItemTitle : @"A", CYLTabBarItemImage : icon },
            @{ CYLTabBarItemIdentifier : @"b", CYLTabBarItemTitle : @"B", CYLTabBarItemImage : icon, CYLTabBarItemSelectedImage : drawn(UIColor.redColor),
               CYLTabBarItemIconRenderingMode : @"original", CYLTabBarItemIconColor : UIColor.purpleColor },
            @{ CYLTabBarItemIdentifier : @"c", CYLTabBarItemTitle : @"C", CYLTabBarItemImage : icon, CYLTabBarItemIconRenderingMode : @"bogus" },
        ],
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
            return [[UIViewController alloc] init];
        },
    }];
    NSArray<NSDictionary *> *attributes = tabBarController.tabBarItemsAttributes;
    XCTAssertEqual(attributes.count, 3u);
    XCTAssertEqualObjects(attributes[0][CYLTabBarItemIconRenderingMode], @"template", @"the tab bar's default, lowercased");
    XCTAssertTrue([attributes[0][CYLTabBarItemIconColor] isKindOfClass:[UIColor class]], @"the tab bar's icon color, parsed");
    XCTAssertTrue([attributes[0][CYLTabBarItemSelectedIconColor] isKindOfClass:[UIColor class]]);
    XCTAssertEqualObjects(attributes[1][CYLTabBarItemIconRenderingMode], @"original", @"a tab's own mode wins");
    XCTAssertEqualObjects(attributes[1][CYLTabBarItemIconColor], UIColor.purpleColor, @"a tab's own color wins");
    XCTAssertNil(attributes[2][CYLTabBarItemIconRenderingMode], @"an unknown mode is dropped");

    [tabBarController loadViewIfNeeded];
    UITabBarItem *a = tabBarController.viewControllers[0].tabBarItem;
    UITabBarItem *b = tabBarController.viewControllers[1].tabBarItem;
    UITabBarItem *c = tabBarController.viewControllers[2].tabBarItem;
    XCTAssertEqual(a.image.renderingMode, UIImageRenderingModeAlwaysTemplate);
    XCTAssertEqual(a.selectedImage.renderingMode, UIImageRenderingModeAlwaysTemplate, @"one image serves both states");
    XCTAssertEqual(b.image.renderingMode, UIImageRenderingModeAlwaysOriginal);
    XCTAssertEqual(b.selectedImage.renderingMode, UIImageRenderingModeAlwaysOriginal);
    XCTAssertNotEqual(c.image.renderingMode, UIImageRenderingModeAlwaysTemplate, @"no mode: the image as it is");

    // [EN] In place: a new image keeps the tab's mode; a new mode alone redraws both images.
    // [CN] 原地更新：新图片保持 Tab 的渲染方式；只更新渲染方式也会重新绘制两张图片。
    XCTAssertTrue([tabBarController updateTabBarItemAtIndex:0 attributes:@{ CYLTabBarItemImage : drawn(UIColor.greenColor) }]);
    XCTAssertEqual(a.image.renderingMode, UIImageRenderingModeAlwaysTemplate);
    XCTAssertTrue([tabBarController updateTabBarItemAtIndex:0 attributes:@{ CYLTabBarItemIconRenderingMode : @"original" }]);
    XCTAssertEqual(a.image.renderingMode, UIImageRenderingModeAlwaysOriginal);
}

/// [EN] FIX: issue #787. A tab with a dark image (`CYLTabBarItemDarkImage`) and "template" still switches to the dark image
///      in Dark Mode, and both variants stay templates.
/// [CN] FIX: issue #787。带深色图片（`CYLTabBarItemDarkImage`）且为 "template" 的 Tab，在深色模式下仍切换为深色图片，两种外观都保持模板。
- (void)testIconRenderingModeKeepsTheDarkImage {
    UIImage * (^drawn)(CGFloat) = ^UIImage *(CGFloat side) {
        return [[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side)] imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [UIColor.blueColor setFill];
            [context fillRect:CGRectMake(0, 0, side, side)];
        }];
    };
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : [NSUUID UUID].UUIDString,
        CYLTabBarControllerTabBarItemsAttributes : @[
            @{ CYLTabBarItemIdentifier : @"a", CYLTabBarItemTitle : @"A", CYLTabBarItemImage : drawn(8), CYLTabBarItemDarkImage : drawn(12),
               CYLTabBarItemIconRenderingMode : @"template" },
            @{ CYLTabBarItemIdentifier : @"b", CYLTabBarItemTitle : @"B", CYLTabBarItemImage : drawn(8) },
        ],
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
            return [[UIViewController alloc] init];
        },
    }];
    [tabBarController loadViewIfNeeded];
    UIImage *image = tabBarController.viewControllers[0].tabBarItem.image;
    XCTAssertEqual(image.renderingMode, UIImageRenderingModeAlwaysTemplate);
    UITraitCollection *dark = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark];
    UITraitCollection *light = [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight];
    UIImage *darkVariant = [image imageWithConfiguration:[UIImageConfiguration configurationWithTraitCollection:dark]];
    UIImage *lightVariant = [image imageWithConfiguration:[UIImageConfiguration configurationWithTraitCollection:light]];
    XCTAssertEqualWithAccuracy(darkVariant.size.width, 12, 0.01, @"the dark image in Dark Mode");
    XCTAssertEqualWithAccuracy(lightVariant.size.width, 8, 0.01, @"the light image otherwise");
    XCTAssertEqual(darkVariant.renderingMode, UIImageRenderingModeAlwaysTemplate, @"still a template in Dark Mode");
    XCTAssertEqual(tabBarController.viewControllers[0].tabBarItem.selectedImage.renderingMode, UIImageRenderingModeAlwaysTemplate);
}

/// [EN] FIX: issue #787. FlatDesign draws a "template" tab's image as a template (tinted by its image view) and an
///      "original" tab's image with its own colors.
/// [CN] FIX: issue #787。扁平样式把 "template" Tab 的图片作为模板绘制（由其图片视图着色），"original" Tab 的图片保持原色。
- (void)testIconRenderingModeInFlatDesign {
    Class buttonClass = NSClassFromString(@"CYLFlatDesignTabBarButton");
    if (!buttonClass) {
        XCTSkip(@"FlatDesign is not compiled into this target");
    }
    UIImage *icon = [[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(8, 8)] imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [UIColor.blueColor setFill];
        [context fillRect:CGRectMake(0, 0, 8, 8)];
    }];
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : [NSUUID UUID].UUIDString,
        CYLTabBarControllerStyleType : @"flatDesign",
        CYLTabBarControllerTabBarItemsAttributes : @[
            @{ CYLTabBarItemIdentifier : @"t", CYLTabBarItemTitle : @"Template", CYLTabBarItemImage : icon, CYLTabBarItemIconRenderingMode : @"template" },
            @{ CYLTabBarItemIdentifier : @"o", CYLTabBarItemTitle : @"Original", CYLTabBarItemImage : icon, CYLTabBarItemIconRenderingMode : @"original" },
        ],
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
            return [[UIViewController alloc] init];
        },
    }];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 390, 844)];
    window.rootViewController = tabBarController;
    window.hidden = NO;
    [tabBarController.view setNeedsLayout];
    [tabBarController.view layoutIfNeeded];
    NSMutableDictionary<NSString *, UIImage *> *images = [NSMutableDictionary dictionary];
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:tabBarController.view];
    while (queue.count > 0) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];
        if ([view isKindOfClass:buttonClass]) {
            UILabel *titleLabel = [view valueForKey:@"titleLabel"];
            UIImageView *imageView = [view valueForKey:@"imageView"];
            if (titleLabel.text && imageView.image) {
                images[titleLabel.text] = imageView.image;
            }
        }
        [queue addObjectsFromArray:view.subviews];
    }
    XCTAssertEqual(images[@"Template"].renderingMode, UIImageRenderingModeAlwaysTemplate, @"%@", images);
    XCTAssertEqual(images[@"Original"].renderingMode, UIImageRenderingModeAlwaysOriginal, @"%@", images);
    window.hidden = YES;
}

/// [EN] FIX: the FlatDesign "More" tab had no icon (the 1×1 transparent placeholder). With 8 tabs it now shows a real image
///      and the "More" title.
/// [CN] FIX：扁平样式的「More」Tab 没有图标（1×1 透明占位图）。8 个 Tab 时现在显示真实图片与「More」标题。
- (void)testFlatDesignMoreTabHasAnIcon {
    Class buttonClass = NSClassFromString(@"CYLFlatDesignTabBarButton");
    if (!buttonClass) {
        XCTSkip(@"FlatDesign is not compiled into this target");
    }
    NSMutableArray<NSDictionary *> *tabs = [NSMutableArray array];
    for (NSUInteger index = 0; index < 8; index++) {
        [tabs addObject:@{ CYLTabBarItemIdentifier : [NSString stringWithFormat:@"t%@", @(index)],
                           CYLTabBarItemTitle : [NSString stringWithFormat:@"T%@", @(index)],
                           CYLTabBarItemImage : [UIImage systemImageNamed:@"house"] }];
    }
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : [NSUUID UUID].UUIDString,
        CYLTabBarControllerStyleType : @"flatDesign",
        CYLTabBarControllerTabBarItemsAttributes : tabs,
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
            return [[UIViewController alloc] init];
        },
    }];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 390, 844)];
    window.rootViewController = tabBarController;
    window.hidden = NO;
    [tabBarController.view setNeedsLayout];
    [tabBarController.view layoutIfNeeded];
    NSMutableDictionary<NSString *, NSValue *> *sizes = [NSMutableDictionary dictionary];
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:tabBarController.view];
    while (queue.count > 0) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];
        if ([view isKindOfClass:buttonClass] && !view.hidden) {
            UILabel *titleLabel = [view valueForKey:@"titleLabel"];
            UIImageView *imageView = [view valueForKey:@"imageView"];
            sizes[titleLabel.text ?: @"(nil)"] = [NSValue valueWithCGSize:imageView.image.size];
        }
        [queue addObjectsFromArray:view.subviews];
    }
    window.hidden = YES;
    NSLog(@"FlatDesign buttons: %@", sizes);
    NSString *moreTitle = [sizes.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT (SELF BEGINSWITH 'T')"]].firstObject;
    XCTAssertNotNil(moreTitle, @"a More button: %@", sizes);
    XCTAssertGreaterThan(sizes[moreTitle].CGSizeValue.width, 1, @"More (%@) has a real icon, not the 1x1 placeholder: %@", moreTitle, sizes);
}

/// [EN] FIX: issue #515. With a plus button that is not in the middle (4 tabs, plus button at index 1), every
///      `-setSelectedIndex:` selects one tab whose title and image belong together: the selected tab bar item is the
///      selected view controller's own.
/// [CN] FIX: issue #515。PlusButton 不在中间（4 个 Tab，PlusButton 位于下标 1）时，每次 `-setSelectedIndex:` 选中的 Tab 的标题与图片
///      属于同一个 Tab：选中的 tab bar item 就是选中控制器自己的。
- (void)testSelectedIndexWithAnOffCenterPlusButton {
    NSMutableArray<NSDictionary *> *tabs = [NSMutableArray array];
    for (NSString *name in @[ @"A", @"B", @"C", @"D" ]) {
        [tabs addObject:@{ CYLTabBarItemIdentifier : name.lowercaseString, CYLTabBarItemTitle : name, CYLTabBarItemImage : [UIImage systemImageNamed:@"house"] }];
    }
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : [NSUUID UUID].UUIDString,
        CYLTabBarControllerTabBarItemsAttributes : tabs,
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
            return [[UIViewController alloc] init];
        },
        CYLTabBarControllerPlusButton : @{ CYLTabBarItemTitle : @"Post", CYLTabBarItemImage : [UIImage systemImageNamed:@"plus.circle"],
                                           CYLPlusButtonIndexInTabBar : @1 },
    }];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 390, 844)];
    window.rootViewController = tabBarController;
    window.hidden = NO;
    [tabBarController.view layoutIfNeeded];
    for (NSUInteger index = 0; index < tabBarController.viewControllers.count; index++) {
        UIViewController *viewController = tabBarController.viewControllers[index];
        if (viewController.cyl_isPlaceholder) {
            continue;
        }
        tabBarController.selectedIndex = index;
        [tabBarController.view layoutIfNeeded];
        XCTAssertEqual(tabBarController.selectedViewController, viewController, @"index %@", @(index));
        XCTAssertEqual(tabBarController.tabBar.selectedItem, viewController.tabBarItem, @"index %@: the selected item is that tab's", @(index));
        XCTAssertEqualObjects(tabBarController.tabBar.selectedItem.title, viewController.tabBarItem.title);
    }
    window.hidden = YES;
}

/// [EN] FIX: long titles next to the plus button moved its slot off the middle. On Liquid Glass the plus button now follows
///      its slot (the tab button it covers) horizontally, and every title keeps its full text, also a new title set by
///      the app.
/// [CN] FIX：PlusButton 旁的长标题使其 slot 偏离中间。液态玻璃下 PlusButton 现在水平跟随它的 slot（它覆盖的 Tab 按钮），每个标题
///      都保持完整文字，App 之后设置的新标题也一样。
- (void)testLongTitlesNextToThePlusButtonKeepItOnItsSlot {
    NSString *longTitle = @"Scene one: review";
    NSString *secondTitle = @"Scene two: search";
    NSMutableArray<NSDictionary *> *tabs = [NSMutableArray array];
    for (NSString *name in @[ longTitle, secondTitle, @"C", @"D" ]) {
        [tabs addObject:@{ CYLTabBarItemIdentifier : [NSUUID UUID].UUIDString, CYLTabBarItemTitle : name, CYLTabBarItemImage : [UIImage systemImageNamed:@"house"] }];
    }
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : [NSUUID UUID].UUIDString,
        CYLTabBarControllerTabBarItemsAttributes : tabs,
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
            return [[UIViewController alloc] init];
        },
        CYLTabBarControllerPlusButton : @{ CYLTabBarItemTitle : @"Post", CYLTabBarItemImage : [UIImage systemImageNamed:@"plus.circle"] },
    }];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 402, 874)];
    window.rootViewController = tabBarController;
    window.hidden = NO;
    void (^layOut)(void) = ^{
        for (NSUInteger pass = 0; pass < 3; pass++) {
            [tabBarController.tabBar setNeedsLayout];
            [tabBarController.view layoutIfNeeded];
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
        }
    };
    CYLTabBar *tabBar = (CYLTabBar *)tabBarController.tabBar;
    void (^checkPlusButtonOnSlot)(NSString *) = ^(NSString *step) {
        if (![CYLConstants isLiquidGlassActive]) {
            return;
        }
        NSUInteger slotIndex = NSNotFound;
        for (NSUInteger index = 0; index < tabBarController.viewControllers.count; index++) {
            if (tabBarController.viewControllers[index].cyl_isPlaceholder) {
                slotIndex = index;
            }
        }
        NSArray<UIControl *> *tabButtons = [tabBar cyl_tabBarSubviews];
        XCTAssertLessThan(slotIndex, tabButtons.count, @"%@", step);
        if (slotIndex >= tabButtons.count) {
            return;
        }
        UIControl *slot = tabButtons[slotIndex];
        CGFloat slotCenterX = [slot.superview convertPoint:slot.center toView:tabBar].x;
        CGFloat plusCenterX = [tabBar.plusButton.superview convertPoint:tabBar.plusButton.center toView:tabBar].x;
        XCTAssertEqualWithAccuracy(plusCenterX, slotCenterX, 1, @"%@: the plus button is on its slot", step);
    };
    layOut();
    UITabBarItem *firstItem = tabBarController.viewControllers.firstObject.tabBarItem;
    XCTAssertEqualObjects(firstItem.title, longTitle, @"not cut");
    XCTAssertEqualObjects(tabBarController.viewControllers[1].tabBarItem.title, secondTitle, @"not cut");
    checkPlusButtonOnSlot(@"long titles");
    firstItem.title = @"A";
    layOut();
    XCTAssertEqualObjects(firstItem.title, @"A", @"the app's new title is used");
    checkPlusButtonOnSlot(@"after a title change");
    window.hidden = YES;
}

/// [EN] FIX: titles too long for the platter overlapped. Only then are titles cut, the longest ones only: the short titles
///      keep their text, the tab buttons no longer overlap, the plus button stays on its slot, the full title is the
///      accessibility label, and a new title set by the app is used again.
/// [CN] FIX：超出 platter 的长标题互相重叠。只有这时才截断标题，并且只截断最长的：短标题保持文字，Tab 按钮不再重叠，PlusButton 仍在
///      它的 slot 上，完整标题作为无障碍标签，App 之后设置的新标题会重新生效。
- (void)testOnlyTitlesOverflowingThePlatterAreCut {
    if (![CYLConstants isLiquidGlassActive]) {
        return;
    }
    NSString *longTitle = @"Scene one: review filter and more";
    NSString *secondTitle = @"Scene two: search and sort";
    NSMutableArray<NSDictionary *> *tabs = [NSMutableArray array];
    for (NSString *name in @[ longTitle, secondTitle, @"C", @"D" ]) {
        [tabs addObject:@{ CYLTabBarItemIdentifier : [NSUUID UUID].UUIDString, CYLTabBarItemTitle : name, CYLTabBarItemImage : [UIImage systemImageNamed:@"house"] }];
    }
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : [NSUUID UUID].UUIDString,
        CYLTabBarControllerTabBarItemsAttributes : tabs,
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
            return [[UIViewController alloc] init];
        },
        CYLTabBarControllerPlusButton : @{ CYLTabBarItemTitle : @"Post", CYLTabBarItemImage : [UIImage systemImageNamed:@"plus.circle"] },
    }];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 402, 874)];
    window.rootViewController = tabBarController;
    window.hidden = NO;
    void (^layOut)(void) = ^{
        for (NSUInteger pass = 0; pass < 5; pass++) {
            [tabBarController.tabBar setNeedsLayout];
            [tabBarController.view layoutIfNeeded];
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
        }
    };
    CYLTabBar *tabBar = (CYLTabBar *)tabBarController.tabBar;
    void (^checkLayout)(NSString *) = ^(NSString *step) {
        // [EN] Every title whole in its label, and no two labels overlapping (the buttons themselves always overlap a little).
        // [CN] 每个标题在其标签中完整显示，且任意两个标签不重叠（按钮本身总会略微重叠）。
        NSMutableArray<NSValue *> *labelFrames = [NSMutableArray array];
        for (UIControl *tabButton in [tabBar cyl_tabBarSubviews]) {
            UILabel *label = tabButton.cyl_tabLabel;
            if (label.text.length == 0) {
                continue;
            }
            XCTAssertLessThanOrEqual([label sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)].width, CGRectGetWidth(label.bounds) + 0.5,
                                     @"%@: %@ is not squeezed", step, label.text);
            [labelFrames addObject:[NSValue valueWithCGRect:[label convertRect:label.bounds toView:tabBar]]];
        }
        [labelFrames sortUsingComparator:^NSComparisonResult(NSValue *first, NSValue *second) {
            return [@(CGRectGetMinX(first.CGRectValue)) compare:@(CGRectGetMinX(second.CGRectValue))];
        }];
        for (NSUInteger index = 1; index < labelFrames.count; index++) {
            XCTAssertLessThanOrEqual(CGRectGetMaxX(labelFrames[index - 1].CGRectValue), CGRectGetMinX(labelFrames[index].CGRectValue),
                                     @"%@: titles %@ and %@ do not overlap", step, @(index - 1), @(index));
        }
        NSUInteger slotIndex = NSNotFound;
        for (NSUInteger index = 0; index < tabBarController.viewControllers.count; index++) {
            if (tabBarController.viewControllers[index].cyl_isPlaceholder) {
                slotIndex = index;
            }
        }
        NSArray<UIControl *> *buttons = [tabBar cyl_tabBarSubviews];
        if (slotIndex < buttons.count) {
            UIControl *slot = buttons[slotIndex];
            CGFloat slotCenterX = [slot.superview convertPoint:slot.center toView:tabBar].x;
            CGFloat plusCenterX = [tabBar.plusButton.superview convertPoint:tabBar.plusButton.center toView:tabBar].x;
            XCTAssertEqualWithAccuracy(plusCenterX, slotCenterX, 1, @"%@: the plus button is on its slot", step);
        }
    };
    layOut();
    UITabBarItem *firstItem = tabBarController.viewControllers[0].tabBarItem;
    UITabBarItem *secondItem = tabBarController.viewControllers[1].tabBarItem;
    XCTAssertTrue([firstItem.title hasSuffix:@"…"], @"the longest title is cut: %@", firstItem.title);
    XCTAssertEqualObjects(firstItem.accessibilityLabel, longTitle);
    XCTAssertEqualObjects(tabBarController.viewControllers.lastObject.tabBarItem.title, @"D", @"a short title stays");
    XCTAssertGreaterThan(firstItem.title.length + secondItem.title.length, 20, @"only what overflows is cut: %@ / %@", firstItem.title, secondItem.title);
    checkLayout(@"overflowing titles");
    firstItem.title = @"A";
    layOut();
    XCTAssertEqualObjects(firstItem.title, @"A", @"the app's new title is used");
    XCTAssertEqualObjects(secondItem.title, secondTitle, @"fits again: the full title is back");
    checkLayout(@"after a title change");
    window.hidden = YES;
}

/// [EN] Without a plus button a long title is left as it is.
/// [CN] 没有 PlusButton 时长标题保持不变。
/*!
 * [EN] Liquid Glass: with the plus button's page selected, the real plus button (under the platter) is masked where its
 *      title meets the lens, so the lens does not show a blurred copy of the title under the stand-in's; the mask goes
 *      when another tab is selected.
 * [CN] 液态玻璃：PlusButton 的页面被选中时，真实 PlusButton（位于底板之下）在标题与放大镜重叠的区域被遮住，放大镜不再在替身标题下
 *      显示一层模糊的标题；选中其他 Tab 后遮罩移除。
 */
- (void)testTheSelectedPlusButtonTitleIsNotBlurredUnderTheLens {
    if (![CYLConstants isLiquidGlassActive]) {
        return;
    }
    UIViewController *menu = [[UIViewController alloc] init];
    NSString *context = [NSUUID UUID].UUIDString;
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : context,
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemImage : [UIImage systemImageNamed:@"house"] },
                                                      @{ CYLTabBarItemTitle : @"B", CYLTabBarItemImage : [UIImage systemImageNamed:@"star"] } ],
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
            return [pageIdentifier isEqualToString:@"menu"] ? menu : [[UIViewController alloc] init];
        },
        CYLTabBarControllerPlusButton : @{ CYLTabBarItemTitle : @"Menu", CYLTabBarItemImage : [UIImage systemImageNamed:@"plus.circle"],
                                           CYLTabBarItemPageIdentifier : @"menu" },
    }];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 402, 874)];
    window.rootViewController = tabBarController;
    // [EN] In the app's scene and key: the selected layer renders only in a visible window.
    // [CN] 放入 App 的 scene 并设为 key：选中图层只在可见的窗口中渲染。
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            window.windowScene = (UIWindowScene *)scene;
            break;
        }
    }
    [window makeKeyAndVisible];
    void (^layOut)(void) = ^{
        for (NSUInteger pass = 0; pass < 6; pass++) {
            [tabBarController.tabBar setNeedsLayout];
            [tabBarController.view layoutIfNeeded];
            [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
        }
    };
    layOut();
    CYLPlusButton *plusButton = [CYLPlusButton plusButtonForTabBarContext:context];
    XCTAssertNotNil(plusButton);
    XCTAssertNil(plusButton.layer.mask, @"no mask while another tab is selected");
    tabBarController.selectedViewController = [CYLPlusButton plusChildViewControllerForTabBarContext:context];
    layOut();
    UIButton *standIn = [plusButton valueForKey:@"selectedContentView"];
    if (!standIn.window || standIn == plusButton) {
        // [EN] Selected in code, the test host does not build the lens's stand-in; the masked title is checked on the
        //      simulator instead (docs/SwiftUI-Integration.md). [CN] 用代码选中时，测试宿主不会创建放大镜中的替身；遮住标题的效果
        //      改在模拟器上检查（docs/SwiftUI-Integration.md）。
        XCTSkip(@"the lens's stand-in is not built when the plus page is selected in code");
    }
    CAShapeLayer *mask = (CAShapeLayer *)plusButton.layer.mask;
    XCTAssertTrue([mask isKindOfClass:[CAShapeLayer class]], @"the selected plus button is masked under the lens");
    CGPoint titleCenter = [plusButton.titleLabel convertPoint:CGPointMake(CGRectGetMidX(plusButton.titleLabel.bounds),
                                                                          CGRectGetMidY(plusButton.titleLabel.bounds))
                                                       toView:plusButton];
    XCTAssertFalse(CGPathContainsPoint(mask.path, NULL, titleCenter, YES), @"the title is masked out");
    XCTAssertTrue(CGPathContainsPoint(mask.path, NULL, CGPointMake(CGRectGetMidX(plusButton.bounds), 1), YES),
                  @"the top of the icon, above the platter, stays");
    tabBarController.selectedIndex = 0;
    layOut();
    XCTAssertNil(plusButton.layer.mask, @"the mask goes once another tab is selected");
}

- (void)testLongTitlesWithoutAPlusButtonAreNotCut {
    NSString *longTitle = @"Scene one: review filter and more";
    NSMutableArray<NSDictionary *> *tabs = [NSMutableArray array];
    for (NSString *name in @[ longTitle, @"Scene two: search and sort", @"C", @"D" ]) {
        [tabs addObject:@{ CYLTabBarItemIdentifier : [NSUUID UUID].UUIDString, CYLTabBarItemTitle : name, CYLTabBarItemImage : [UIImage systemImageNamed:@"house"] }];
    }
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerContext : [NSUUID UUID].UUIDString,
        CYLTabBarControllerTabBarItemsAttributes : tabs,
        CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
            return [[UIViewController alloc] init];
        },
    }];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 390, 844)];
    window.rootViewController = tabBarController;
    window.hidden = NO;
    for (NSUInteger pass = 0; pass < 3; pass++) {
        [tabBarController.tabBar setNeedsLayout];
        [tabBarController.view layoutIfNeeded];
        [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];
    }
    XCTAssertFalse([tabBarController hasPlusButton]);
    XCTAssertEqualObjects(tabBarController.viewControllers.firstObject.tabBarItem.title, longTitle, @"not cut without a plus button");
    window.hidden = YES;
}

/// [EN] FIX: more than five tabs on the classic style / Liquid Glass showed the first five and no "More". With eight tabs
///      UIKit's "More" tab is there and a later tab can be selected; five tabs are unchanged; a plus button with eight
///      tabs does not crash.
/// [CN] FIX：经典样式 / 液态玻璃下超过 5 个 Tab 时只显示前 5 个且没有「More」。8 个 Tab 时有 UIKit 的「More」，之后的 Tab 也能选中；
///      5 个 Tab 不受影响；有 PlusButton 且 8 个 Tab 时不崩溃。
- (void)testMoreTabWithMoreThanFiveTabs {
    CYLTabBarController * (^make)(NSUInteger, NSDictionary *) = ^CYLTabBarController *(NSUInteger count, NSDictionary *plus) {
        NSMutableArray<NSDictionary *> *tabs = [NSMutableArray array];
        for (NSUInteger index = 0; index < count; index++) {
            [tabs addObject:@{ CYLTabBarItemIdentifier : [NSString stringWithFormat:@"t%@", @(index)],
                               CYLTabBarItemTitle : [NSString stringWithFormat:@"T%@", @(index)],
                               CYLTabBarItemImage : [UIImage systemImageNamed:@"house"] }];
        }
        NSMutableDictionary *configuration = [@{
            CYLTabBarControllerContext : [NSUUID UUID].UUIDString,
            CYLTabBarControllerTabBarItemsAttributes : tabs,
            CYLTabBarControllerPageResolver : ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
                return [[UIViewController alloc] init];
            },
        } mutableCopy];
        if (plus) {
            configuration[CYLTabBarControllerPlusButton] = plus;
        }
        return [CYLTabBarController tabBarControllerWithConfiguration:configuration];
    };
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 440, 956)];
    window.hidden = NO;

    CYLTabBarController *eight = make(8, nil);
    window.rootViewController = eight;
    [eight.view layoutIfNeeded];
    XCTAssertTrue([eight.tabBar.items containsObject:eight.moreNavigationController.tabBarItem], @"a More tab");
    eight.selectedIndex = 6;
    XCTAssertEqual(eight.selectedViewController, eight.viewControllers[6], @"the seventh tab can be selected");

    CYLTabBarController *five = make(5, nil);
    window.rootViewController = five;
    [five.view layoutIfNeeded];
    XCTAssertEqual(five.tabBar.items.count, 5u);
    XCTAssertFalse([five.tabBar.items containsObject:five.moreNavigationController.tabBarItem], @"five tabs: no More");

    CYLTabBarController *withPlus = make(8, @{ CYLTabBarItemTitle : @"Post", CYLTabBarItemImage : [UIImage systemImageNamed:@"plus.circle"] });
    window.rootViewController = withPlus;
    [withPlus.view layoutIfNeeded];
    XCTAssertGreaterThan(withPlus.tabBar.items.count, 0u);
    window.hidden = YES;
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
