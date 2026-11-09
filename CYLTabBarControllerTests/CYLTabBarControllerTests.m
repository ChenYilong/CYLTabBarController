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
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"Home" }, @{ CYLTabBarItemTitle : @"Me" } ]];
    XCTAssertEqualObjects(home.navigationItem.title, @"Home", @"set when the tab is set up");
    XCTAssertEqualObjects(CYL_TAB_BAR_ITEM_TITLE(home), @"Home");
    XCTAssertEqualObjects(CYL_TAB_BAR_ITEM_TITLE(me), @"Me");
    __block NSString *notifiedTitle = nil;
    __block id notifiedPage = nil;
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemTitleDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        if (note.object == home) {
            notifiedPage = note.object;
            notifiedTitle = note.userInfo[CYLTabBarItemTitle];
        }
    }];
    [tabBarController updateTabBarItemsWithAttributes:@[ @{ CYLTabBarItemTitle : @"★ Home" }, @{ CYLTabBarItemTitle : @"★ Me" } ]];
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    XCTAssertEqualObjects(home.navigationItem.title, @"★ Home", @"follows the in-place update");
    XCTAssertEqualObjects(CYL_TAB_BAR_ITEM_TITLE(home), @"★ Home");
    XCTAssertEqual(notifiedPage, home);
    XCTAssertEqualObjects(notifiedTitle, @"★ Home");
    XCTAssertEqualObjects(me.navigationItem.title, @"Mine", @"a page that does not follow keeps its own title");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
