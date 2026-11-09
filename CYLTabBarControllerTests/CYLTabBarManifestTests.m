//
//  CYLTabBarManifestTests.m
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CYLTabBarController.h"

/// [EN] A 1×1 PNG. [CN] 1×1 的 PNG。
static NSData *CYLTestPNG(void) {
    return [[NSData alloc] initWithBase64EncodedString:@"iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==" options:0];
}

/// [EN] The private hash helper of CYLTabBarManifest.m. [CN] CYLTabBarManifest.m 中的私有哈希方法。
@interface CYLTabBarManifest (CYLTests)
+ (NSString *)hashOfData:(NSData *)data;
@end

/// [EN] `CYLTabBarManifest` and `CYLTabBarManifestLoader` (docs/Configuration-Manifest.md, cases M1–M14).
/// [CN] `CYLTabBarManifest` 与 `CYLTabBarManifestLoader`（docs/Configuration-Manifest.md，情况 M1–M14）。
@interface CYLTabBarManifestTests : XCTestCase <CYLTabBarManifestLoaderDelegate>
@property (nonatomic, copy) NSString *folder;
@property (nonatomic, strong) NSMutableArray<NSString *> *events;
@end

@implementation CYLTabBarManifestTests

- (void)setUp {
    [super setUp];
    self.folder = [NSTemporaryDirectory() stringByAppendingPathComponent:[@"cyl-manifest-" stringByAppendingString:NSUUID.UUID.UUIDString]];
    [NSFileManager.defaultManager createDirectoryAtPath:self.folder withIntermediateDirectories:YES attributes:nil error:NULL];
    [NSFileManager.defaultManager removeItemAtPath:[CYLResourceRoute pathForRoute:@"sandbox:Caches/CYLTabBarManifest" baseDirectory:nil] error:NULL];
    self.events = [NSMutableArray array];
}

- (void)tearDown {
    [NSFileManager.defaultManager removeItemAtPath:self.folder error:NULL];
    [NSFileManager.defaultManager removeItemAtPath:[CYLResourceRoute pathForRoute:@"sandbox:Caches/CYLTabBarManifest" baseDirectory:nil] error:NULL];
    [super tearDown];
}

- (void)writeImage:(NSString *)path {
    NSString *full = [self.folder stringByAppendingPathComponent:path];
    [NSFileManager.defaultManager createDirectoryAtPath:full.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:NULL];
    XCTAssertTrue([CYLTestPNG() writeToFile:full atomically:YES]);
}

- (NSString *)hashOf:(NSString *)path {
    return [CYLTabBarManifest hashOfData:[NSData dataWithContentsOfFile:[self.folder stringByAppendingPathComponent:path]]];
}

/// [EN] A manifest with light / dark themes, three tabs and a plus button; images under Skins/2.1.0.
/// [CN] 带浅色 / 深色主题、三个 Tab 与 PlusButton 的清单；图片位于 Skins/2.1.0。
- (NSMutableDictionary *)sampleManifest {
    for (NSString *path in @[ @"Skins/2.1.0/light/home@3x.png", @"Skins/2.1.0/light/home_selected@3x.png", @"Skins/2.1.0/dark/home@3x.png",
                              @"Skins/2.1.0/light/me@3x.png", @"Skins/2.1.0/light/plus@3x.png" ]) {
        [self writeImage:path];
    }
    NSArray *assets = @[
        @{ @"key" : @"home", @"theme" : @"light", @"state" : @"normal", @"path" : @"light/home@3x.png", @"hash" : [self hashOf:@"Skins/2.1.0/light/home@3x.png"] },
        @{ @"key" : @"home", @"theme" : @"light", @"state" : @"selected", @"path" : @"light/home_selected@3x.png" },
        @{ @"key" : @"home", @"theme" : @"dark", @"state" : @"normal", @"path" : @"dark/home@3x.png" },
        @{ @"key" : @"me", @"theme" : @"light", @"state" : @"normal", @"path" : @"light/me@3x.png" },
        @{ @"key" : @"plus", @"theme" : @"light", @"state" : @"normal", @"path" : @"light/plus@3x.png" },
    ];
    return [@{
        @"schemaVersion" : @1, @"id" : @"test-manifest", @"version" : @"2.1.0",
        @"runtime" : @{ @"platforms" : @[ @"ios", @"android" ], @"minAppVersion" : @"", @"startTime" : @"", @"endTime" : @"" },
        @"fallback" : @{ @"onError" : @"previous" },
        @"assets" : @{ @"baseRoute" : @"Skins/2.1.0", @"list" : assets },
        @"themes" : @{ @"default" : @"light", @"darkMode" : @"dark", @"list" : @{
            @"light" : @{ @"tabColor" : @"#8E8E93", @"tabSelectedColor" : @"#007AFF", @"tabBackgroundColor" : @"#FFFFFF" },
            @"dark" : @{ @"tabSelectedColor" : @"#0A84FF", @"tabBackgroundColor" : @"#1C1C1E" } } },
        @"tabBar" : @{ @"styleType" : @"liquidGlass", @"color" : @"@tabColor", @"selectedColor" : @"@tabSelectedColor", @"backgroundColor" : @"@tabBackgroundColor",
                       @"list" : @[
                           @{ @"key" : @"home", @"pagePath" : @"home", @"text" : @"tab.home", @"iconPath" : @"asset:home", @"selectedIconPath" : @"asset:home?state=selected" },
                           @{ @"key" : @"robot", @"pagePath" : @"robot", @"text" : @"Android only", @"iconPath" : @"asset:home", @"platforms" : @[ @"android" ] },
                           @{ @"key" : @"hidden", @"pagePath" : @"hidden", @"text" : @"Hidden", @"iconPath" : @"asset:home", @"visible" : @NO },
                           @{ @"key" : @"me", @"pagePath" : @"me", @"text" : @"tab.me", @"iconPath" : @"asset:me", @"minAppVersion" : @"2.0.0" } ],
                       @"midButton" : @{ @"key" : @"plus", @"index" : @1, @"text" : @"Post", @"width" : @55, @"height" : @80, @"iconPath" : @"asset:plus",
                                         @"action" : @"page", @"pagePath" : @"publish", @"platforms" : @[ @"all" ] } },
        @"localization" : @{ @"tableName" : @"Tabs", @"route" : @"Localization" },
    } mutableCopy];
}

- (CYLTabBarManifest *)manifestFrom:(NSDictionary *)dictionary {
    NSError *error = nil;
    CYLTabBarManifest *manifest = [CYLTabBarManifest manifestWithDictionary:dictionary baseDirectory:self.folder error:&error];
    XCTAssertNil(error);
    return manifest;
}

/// [EN] M1: not a manifest or an unknown schemaVersion. [CN] M1：不是清单，或未知的 schemaVersion。
- (void)testSchema {
    NSError *error = nil;
    XCTAssertNil([CYLTabBarManifest manifestWithDictionary:@{ @"schemaVersion" : @1 } baseDirectory:nil error:&error]);
    XCTAssertEqual(error.code, CYLTabBarConfigurationErrorUnsupportedManifest);
    NSMutableDictionary *future = [self sampleManifest];
    future[@"schemaVersion"] = @2;
    error = nil;
    XCTAssertNil([CYLTabBarManifest manifestWithDictionary:future baseDirectory:nil error:&error]);
    XCTAssertTrue([error.localizedDescription containsString:@"schemaVersion 2"]);
    XCTAssertEqualObjects([self manifestFrom:[self sampleManifest]].version, @"2.1.0");
}

/// [EN] M2–M4: platforms, app version and time window. [CN] M2–M4：平台、App 版本与时间段。
- (void)testEligibility {
    NSDate *now = [NSDate dateWithTimeIntervalSince1970:1780000000]; // [EN] 2026-05-28 [CN] 2026-05-28
    XCTAssertTrue([[self manifestFrom:[self sampleManifest]] isEligibleAtDate:now error:NULL]);
    NSMutableDictionary *dictionary = [self sampleManifest];
    NSError *error = nil;
    dictionary[@"runtime"] = @{ @"platforms" : @[ @"android" ] };
    XCTAssertFalse([[self manifestFrom:dictionary] isEligibleAtDate:now error:&error]);
    XCTAssertEqual(error.code, CYLTabBarConfigurationErrorNotEligible);
    dictionary[@"runtime"] = @{ @"platforms" : @"all", @"minAppVersion" : @"999.0" };
    XCTAssertFalse([[self manifestFrom:dictionary] isEligibleAtDate:now error:NULL]);
    dictionary[@"runtime"] = @{ @"platforms" : @[ @"all" ], @"startTime" : @"2027-01-01T00:00:00Z" };
    XCTAssertFalse([[self manifestFrom:dictionary] isEligibleAtDate:now error:&error]);
    XCTAssertTrue([error.localizedDescription containsString:@"starts"]);
    dictionary[@"runtime"] = @{ @"endTime" : @"2020-01-01T00:00:00Z" };
    XCTAssertFalse([[self manifestFrom:dictionary] isEligibleAtDate:now error:NULL]);
    dictionary[@"runtime"] = @{ @"startTime" : @"2020-01-01T00:00:00Z", @"endTime" : @"2030-01-01T00:00:00Z" };
    XCTAssertTrue([[self manifestFrom:dictionary] isEligibleAtDate:now error:NULL]);
}

/// [EN] M5–M6: one image per version, theme, tab and state, with the fallbacks; no path outside the folder.
/// [CN] M5–M6：每张图片由版本、主题、Tab 与状态确定，并有回退；不能使用目录之外的路径。
- (void)testAssetLookup {
    CYLTabBarManifest *manifest = [self manifestFrom:[self sampleManifest]];
    NSString *(^name)(NSString *) = ^NSString *(NSString *reference) {
        NSString *path = [manifest pathForAssetReference:reference];
        return path ? [path substringFromIndex:[path rangeOfString:@"2.1.0/"].location + 6] : nil;
    };
    XCTAssertEqualObjects(name(@"asset:home"), @"light/home@3x.png", @"no theme: the default theme");
    XCTAssertEqualObjects(name(@"asset:home?state=selected"), @"light/home_selected@3x.png");
    XCTAssertEqualObjects(name(@"asset:home?theme=dark"), @"dark/home@3x.png");
    XCTAssertEqualObjects(name(@"asset:home?theme=dark&state=selected"), @"dark/home@3x.png", @"the theme's normal image first");
    XCTAssertEqualObjects(name(@"asset:me?theme=dark"), @"light/me@3x.png", @"then the default theme's");
    XCTAssertNil(name(@"asset:nothing"));
    XCTAssertNil(name(@"home"), @"not an asset reference");
    NSMutableDictionary *hostile = [self sampleManifest];
    hostile[@"assets"] = @{ @"baseRoute" : @"Skins/2.1.0", @"list" : @[ @{ @"key" : @"x", @"path" : @"../../../etc/hosts" } ] };
    XCTAssertNil([[self manifestFrom:hostile] pathOfAssetWithKey:@"x" theme:nil state:nil], @"no path outside the assets folder");
}

/// [EN] M7: hashes. [CN] M7：哈希。
- (void)testAssetVerification {
    NSError *error = nil;
    CYLTabBarManifest *manifest = [self manifestFrom:[self sampleManifest]];
    XCTAssertTrue([manifest verifyAssetsWithError:&error]);
    XCTAssertNil(error);
    [@"changed" writeToFile:[self.folder stringByAppendingPathComponent:@"Skins/2.1.0/light/home@3x.png"] atomically:YES encoding:NSUTF8StringEncoding error:NULL];
    XCTAssertFalse([manifest verifyAssetsWithError:&error], @"a changed file");
    NSMutableDictionary *dictionary = [self sampleManifest];
    NSMutableDictionary *assets = [dictionary[@"assets"] mutableCopy];
    NSMutableArray *list = [assets[@"list"] mutableCopy];
    list[0] = @{ @"key" : @"home", @"theme" : @"light", @"path" : @"light/home@3x.png", @"hash" : @"sha256-AAAA" };
    [list addObject:@{ @"key" : @"gone", @"path" : @"light/gone@3x.png" }];
    assets[@"list"] = list;
    dictionary[@"assets"] = assets;
    error = nil;
    XCTAssertFalse([[self manifestFrom:dictionary] verifyAssetsWithError:&error]);
    XCTAssertEqual(error.code, CYLTabBarConfigurationErrorAssetInvalid);
    XCTAssertTrue([error.localizedDescription containsString:@"hash"]);
    [list removeObjectAtIndex:0];
    assets[@"list"] = list;
    dictionary[@"assets"] = assets;
    XCTAssertFalse([[self manifestFrom:dictionary] verifyAssetsWithError:&error]);
    XCTAssertTrue([error.localizedDescription containsString:@"missing"]);
}

/// [EN] M8: conditions and overrides (Firebase expressions). [CN] M8：条件与覆盖项（Firebase 表达式）。
- (void)testConditions {
    NSMutableDictionary *dictionary = [self sampleManifest];
    dictionary[@"conditions"] = @[
        @{ @"name" : @"ios", @"expression" : @"device.os == 'ios' && percent between 0 and 99" },
        @{ @"name" : @"android", @"expression" : @"device.os == 'android'" },
        @{ @"name" : @"future", @"expression" : @"app.version >= '999.0.0'" },
        @{ @"name" : @"unknown", @"expression" : @"user.vip == true" },
    ];
    dictionary[@"overrides"] = @[
        @{ @"condition" : @"ios", @"tabBar" : @{ @"styleType" : @"flatDesign" } },
        @{ @"condition" : @"android", @"tabBar" : @{ @"midButton" : @{ @"height" : @64 } } },
        @{ @"condition" : @"future", @"version" : @"9.9.9" },
        @{ @"condition" : @"unknown", @"version" : @"8.8.8" },
    ];
    CYLTabBarManifest *manifest = [self manifestFrom:dictionary];
    XCTAssertEqualObjects(manifest.dictionary[@"tabBar"][@"styleType"], @"flatDesign");
    XCTAssertEqualObjects(manifest.dictionary[@"tabBar"][@"midButton"][@"height"], @80, @"merged key by key; the android override is not used");
    XCTAssertEqualObjects(manifest.dictionary[@"tabBar"][@"list"][0][@"key"], @"home", @"the rest of tabBar stays");
    XCTAssertEqualObjects(manifest.version, @"2.1.0");
}

/// [EN] M9–M11: the configuration: tabs, the plus button, themes with images, localization. [CN] M9–M11：配置：Tab、PlusButton、带图片的主题、本地化。
- (void)testConfiguration {
    NSDictionary *configuration = [[self manifestFrom:[self sampleManifest]] configuration];
    NSArray<NSDictionary *> *items = configuration[CYLTabBarControllerTabBarItemsAttributes];
    XCTAssertEqual(items.count, 2u, @"the Android-only and the hidden tabs are left out");
    XCTAssertEqualObjects(items[0][CYLTabBarItemIdentifier], @"home");
    XCTAssertEqualObjects(items[0][CYLTabBarItemPageIdentifier], @"home");
    XCTAssertEqualObjects(items[0][CYLTabBarItemImage], @"@cyl.asset.home.normal");
    XCTAssertEqualObjects(items[0][CYLTabBarItemSelectedImage], @"@cyl.asset.home.selected");
    XCTAssertEqualObjects(items[1][CYLTabBarItemMinimumAppVersion], @"2.0.0");
    XCTAssertEqualObjects(configuration[CYLTabBarControllerStyleType], @"liquidGlass");
    NSDictionary *themes = configuration[CYLTabBarControllerThemes];
    XCTAssertEqualObjects(themes[@"light"][CYLTabBarItemSelectedTitleColor], @"#007AFF");
    XCTAssertEqualObjects(themes[@"dark"][CYLTabBarBackgroundColor], @"#1C1C1E");
    XCTAssertEqualObjects(themes[@"dark"][CYLTabBarItemTitleColor], @"#8E8E93", @"a variable the dark theme does not give comes from the default theme");
    XCTAssertTrue([themes[@"dark"][@"cyl.asset.home.normal"] hasSuffix:@"dark/home@3x.png"]);
    XCTAssertTrue([themes[@"dark"][@"cyl.asset.home.selected"] hasSuffix:@"dark/home@3x.png"]);
    XCTAssertTrue([themes[@"light"][@"cyl.asset.home.selected"] hasSuffix:@"light/home_selected@3x.png"]);
    XCTAssertEqualObjects(configuration[CYLTabBarControllerThemeIdentifier], @"light");
    XCTAssertEqualObjects(configuration[CYLTabBarControllerDarkThemeIdentifier], @"dark");
    NSDictionary *plus = configuration[CYLTabBarControllerPlusButton];
    XCTAssertEqualObjects(plus[CYLPlusButtonIndexInTabBar], @1);
    XCTAssertEqualObjects(plus[CYLPlusButtonSize], @"{55, 80}");
    XCTAssertEqualObjects(plus[CYLTabBarItemPageIdentifier], @"publish");
    XCTAssertTrue([plus[CYLTabBarItemImage] hasSuffix:@"light/plus@3x.png"]);
    XCTAssertEqualObjects(configuration[CYLTabBarControllerContext], @"CYLTabBarManifest:test-manifest");
    XCTAssertEqualObjects(configuration[CYLTabBarControllerLocalization][CYLTabBarLocalizationTableName], @"Tabs");
    XCTAssertEqualObjects(configuration[CYLTabBarControllerLocalization][CYLTabBarLocalizationPath], [self.folder stringByAppendingPathComponent:@"Localization"]);
    NSMutableDictionary *callback = [self sampleManifest];
    NSMutableDictionary *tabBar = [callback[@"tabBar"] mutableCopy];
    NSMutableDictionary *mid = [tabBar[@"midButton"] mutableCopy];
    mid[@"action"] = @"callback";
    tabBar[@"midButton"] = mid;
    tabBar[@"list"] = @[ tabBar[@"list"][0] ];
    callback[@"tabBar"] = tabBar;
    [callback removeObjectForKey:@"themes"];
    NSDictionary *plain = [[self manifestFrom:callback] configuration];
    XCTAssertNil(plain[CYLTabBarControllerPlusButton][CYLTabBarItemPageIdentifier], @"a callback plus button opens no page");
    XCTAssertTrue([plain[CYLTabBarControllerTabBarItemsAttributes][0][CYLTabBarItemImage] hasSuffix:@"light/home@3x.png"], @"without themes, the default images directly");
}

/// [EN] M12: a tab bar controller, and no pages. [CN] M12：创建 TabBarController，以及没有页面时。
- (void)testTabBarController {
    CYLTabBarManifest *manifest = [self manifestFrom:[self sampleManifest]];
    NSError *error = nil;
    XCTAssertNil([manifest tabBarControllerWithError:&error]);
    XCTAssertEqual(error.code, CYLTabBarConfigurationErrorNoPages);
    NSMutableDictionary *configuration = [manifest.configuration mutableCopy];
    configuration[CYLTabBarControllerPageResolver] = ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
        return [[UIViewController alloc] init];
    };
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:configuration];
    XCTAssertGreaterThanOrEqual(tabBarController.viewControllers.count, 1u);
    XCTAssertNotNil(tabBarController.tabBarItemsAttributes.firstObject[CYLTabBarItemImage], @"the image of the current theme");
}

/// [EN] M15: `CYLTabBarControllerManifestRoute` in a dictionary (React Native, Flutter): the manifest, under the other keys.
/// [CN] M15：字典中的 `CYLTabBarControllerManifestRoute`（React Native、Flutter）：清单，再由其他键覆盖。
- (void)testManifestRouteKey {
    NSString *path = [self.folder stringByAppendingPathComponent:@"manifest.json"];
    [[NSJSONSerialization dataWithJSONObject:[self sampleManifest] options:0 error:NULL] writeToFile:path atomically:YES];
    UIViewController * (^resolver)(NSString *, NSDictionary *) = ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
        return [[UIViewController alloc] init];
    };
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerManifestRoute : path, CYLTabBarControllerPageResolver : resolver, CYLTabBarControllerStyleType : @"default",
    }];
    XCTAssertEqualObjects(tabBarController.tabBarItemsAttributes.firstObject[CYLTabBarItemIdentifier], @"home");
    XCTAssertEqual(tabBarController.tabBarStyleType, CYLTabBarStyleTypeDefault, @"the dictionary wins over the manifest's liquidGlass");
    CYLTabBarController *missing = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerManifestRoute : @"sandbox:Caches/no-such-manifest.json", CYLTabBarControllerPageResolver : resolver,
    }];
    XCTAssertEqual(missing.viewControllers.count, 0u, @"a missing manifest is ignored");
}

#pragma mark - Loader

- (BOOL)manifestLoader:(CYLTabBarManifestLoader *)loader shouldApplyManifest:(CYLTabBarManifest *)manifest source:(CYLTabBarManifestSource)source {
    [self.events addObject:[NSString stringWithFormat:@"should:%ld", (long)source]];
    return YES;
}

- (void)manifestLoader:(CYLTabBarManifestLoader *)loader didApplyManifest:(CYLTabBarManifest *)manifest source:(CYLTabBarManifestSource)source {
    [self.events addObject:[NSString stringWithFormat:@"apply:%ld", (long)source]];
}

- (void)manifestLoader:(CYLTabBarManifestLoader *)loader didFailWithError:(NSError *)error fallbackSource:(CYLTabBarManifestSource)fallbackSource {
    [self.events addObject:[NSString stringWithFormat:@"fail:%ld", (long)fallbackSource]];
}

- (NSURL *)publish:(NSDictionary *)dictionary name:(NSString *)name {
    NSString *path = [self.folder stringByAppendingPathComponent:name];
    [[NSJSONSerialization dataWithJSONObject:dictionary options:0 error:NULL] writeToFile:path atomically:YES];
    return [NSURL fileURLWithPath:path];
}

- (void)load:(NSURL *)URL loader:(CYLTabBarManifestLoader *)loader check:(void (^)(CYLTabBarManifest *, CYLTabBarManifestSource, NSError *))check {
    XCTestExpectation *done = [self expectationWithDescription:URL.lastPathComponent];
    [loader loadManifestWithURL:URL completion:^(CYLTabBarManifest *manifest, CYLTabBarManifestSource source, NSError *error) {
        XCTAssertTrue(NSThread.isMainThread);
        check(manifest, source, error);
        [done fulfill];
    }];
    [self waitForExpectations:@[ done ] timeout:10];
}

/// [EN] M13–M14: download and cache, then a broken update falls back to the cache, then to the built-in manifest.
/// [CN] M13–M14：下载并缓存，之后损坏的更新回退到缓存，再回退到内置清单。
- (void)testLoaderFallbacks {
    CYLTabBarManifestLoader *loader = [[CYLTabBarManifestLoader alloc] init];
    loader.delegate = self;
    NSMutableDictionary *good = [self sampleManifest];
    // [EN] Remote assets sit next to the manifest: <folder>/<path>. [CN] 远程资源位于清单旁边：<目录>/<path>。
    for (NSString *path in @[ @"light/home@3x.png", @"light/home_selected@3x.png", @"dark/home@3x.png", @"light/me@3x.png", @"light/plus@3x.png" ]) {
        [self writeImage:path];
    }
    [self load:[self publish:good name:@"good.json"] loader:loader check:^(CYLTabBarManifest *manifest, CYLTabBarManifestSource source, NSError *error) {
        XCTAssertNil(error);
        XCTAssertEqual(source, CYLTabBarManifestSourceRemote);
        XCTAssertTrue([manifest.baseDirectory hasSuffix:@"CYLTabBarManifest/2.1.0"]);
        XCTAssertTrue([[manifest pathForAssetReference:@"asset:home"] hasPrefix:manifest.baseDirectory], @"assets read from the cache");
    }];
    XCTAssertEqualObjects(self.events, (@[ @"should:1", @"apply:1" ]));
    XCTAssertEqualObjects(loader.cachedManifest.version, @"2.1.0");

    NSMutableDictionary *broken = [self sampleManifest];
    broken[@"version"] = @"3.0.0";
    NSMutableDictionary *assets = [broken[@"assets"] mutableCopy];
    assets[@"list"] = @[ @{ @"key" : @"home", @"path" : @"light/home@3x.png", @"hash" : @"sha256-wrong" } ];
    broken[@"assets"] = assets;
    [self.events removeAllObjects];
    [self load:[self publish:broken name:@"broken.json"] loader:loader check:^(CYLTabBarManifest *manifest, CYLTabBarManifestSource source, NSError *error) {
        XCTAssertEqual(error.code, CYLTabBarConfigurationErrorAssetInvalid);
        XCTAssertEqual(source, CYLTabBarManifestSourceCache);
        XCTAssertEqualObjects(manifest.version, @"2.1.0", @"the last verified manifest");
    }];
    XCTAssertEqualObjects(self.events, (@[ @"should:2", @"fail:2", @"apply:2" ]));

    [NSFileManager.defaultManager removeItemAtPath:[CYLResourceRoute pathForRoute:@"sandbox:Caches/CYLTabBarManifest" baseDirectory:nil] error:NULL];
    NSURL *embedded = [self publish:[self sampleManifest] name:@"embedded.json"];
    loader.embeddedManifestRoute = embedded.absoluteString;
    [self load:[self publish:broken name:@"broken.json"] loader:loader check:^(CYLTabBarManifest *manifest, CYLTabBarManifestSource source, NSError *error) {
        XCTAssertEqual(source, CYLTabBarManifestSourceEmbedded);
        XCTAssertEqualObjects(manifest.identifier, @"test-manifest");
    }];
    NSMutableDictionary *notForIOS = [self sampleManifest];
    notForIOS[@"runtime"] = @{ @"platforms" : @[ @"android" ] };
    notForIOS[@"fallback"] = @{ @"onError" : @"none" };
    [self load:[self publish:notForIOS name:@"android.json"] loader:loader check:^(CYLTabBarManifest *manifest, CYLTabBarManifestSource source, NSError *error) {
        XCTAssertNil(manifest);
        XCTAssertEqual(source, CYLTabBarManifestSourceNone);
        XCTAssertEqual(error.code, CYLTabBarConfigurationErrorNotEligible);
    }];
}

@end
