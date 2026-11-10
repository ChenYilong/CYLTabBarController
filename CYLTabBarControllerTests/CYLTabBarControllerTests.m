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
    XCTAssertEqualObjects(tabBarController.viewControllers[0].tabBarItem.accessibilityLabel, @"★ A");
    XCTAssertEqualObjects(appLabeledItem.accessibilityLabel, @"Custom", @"the app's own label is kept");
    [tabBarController updateTabBarItemAtIndex:0 attributes:@{ CYLTabBarItemTitle : @"A" }];
    [tabBarController.view setNeedsLayout];
    [tabBarController.view layoutIfNeeded];
    XCTAssertEqualObjects(tabBarController.viewControllers[0].tabBarItem.accessibilityLabel, @"A", @"follows the title back");
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

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
