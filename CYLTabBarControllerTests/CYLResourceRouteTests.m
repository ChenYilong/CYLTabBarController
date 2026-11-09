//
//  CYLResourceRouteTests.m
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CYLTabBarController.h"

/// [EN] `CYLResourceRoute` (docs/Resource-Routes.md) and the configuration initializers that take a route.
/// [CN] `CYLResourceRoute`（docs/Resource-Routes.md）以及接受路由的配置初始化方法。
@interface CYLResourceRouteTests : XCTestCase
@property (nonatomic, copy) NSString *folder;
@end

@implementation CYLResourceRouteTests

- (void)setUp {
    [super setUp];
    NSString *caches = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    self.folder = [caches stringByAppendingPathComponent:[@"cyl-route-test-" stringByAppendingString:NSUUID.UUID.UUIDString]];
    XCTAssertTrue([NSFileManager.defaultManager createDirectoryAtPath:self.folder withIntermediateDirectories:YES attributes:nil error:NULL]);
}

- (void)tearDown {
    [NSFileManager.defaultManager removeItemAtPath:self.folder error:NULL];
    [super tearDown];
}

- (void)write:(NSString *)text name:(NSString *)name {
    NSString *path = [self.folder stringByAppendingPathComponent:name];
    [NSFileManager.defaultManager createDirectoryAtPath:path.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:NULL];
    XCTAssertTrue([text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:NULL]);
}

/// [EN] Each prefix leads to its folder. [CN] 每种前缀对应各自的目录。
- (void)testPrefixes {
    NSString *resources = NSBundle.mainBundle.resourcePath;
    NSString *documents = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    NSString *caches = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    XCTAssertEqualObjects([CYLResourceRoute pathForRoute:@"bundle:Configurations" baseDirectory:@"/base"], [resources stringByAppendingPathComponent:@"Configurations"]);
    XCTAssertEqualObjects([CYLResourceRoute pathForRoute:@"bundle:/a/b" baseDirectory:nil], [resources stringByAppendingPathComponent:@"a/b"]);
    XCTAssertEqualObjects([CYLResourceRoute pathForRoute:@"sandbox:Documents/i18n" baseDirectory:nil], [documents stringByAppendingPathComponent:@"i18n"]);
    XCTAssertEqualObjects([CYLResourceRoute pathForRoute:@"sandbox:Caches/i18n" baseDirectory:nil], [caches stringByAppendingPathComponent:@"i18n"]);
    XCTAssertEqualObjects([CYLResourceRoute pathForRoute:@"sandbox:tmp/i18n" baseDirectory:nil], [NSTemporaryDirectory() stringByAppendingPathComponent:@"i18n"]);
    XCTAssertEqualObjects([CYLResourceRoute pathForRoute:@"sandbox:Library/i18n" baseDirectory:nil], [NSHomeDirectory() stringByAppendingPathComponent:@"Library/i18n"]);
    XCTAssertEqualObjects([CYLResourceRoute pathForRoute:@"file:///var/tmp/a%20b.json" baseDirectory:nil], @"/var/tmp/a b.json");
    XCTAssertEqualObjects([CYLResourceRoute pathForRoute:@"/var/tmp/x" baseDirectory:@"/base"], @"/var/tmp/x");
    XCTAssertEqualObjects([CYLResourceRoute pathForRoute:@"~/x" baseDirectory:nil], [NSHomeDirectory() stringByAppendingPathComponent:@"x"]);
    XCTAssertEqualObjects([CYLResourceRoute pathForRoute:@"Texts" baseDirectory:@"/base"], @"/base/Texts");
    XCTAssertEqualObjects([CYLResourceRoute pathForRoute:@" Texts \n" baseDirectory:nil], [resources stringByAppendingPathComponent:@"Texts"]);
    XCTAssertNil([CYLResourceRoute pathForRoute:@"" baseDirectory:nil]);
    XCTAssertNil([CYLResourceRoute pathForRoute:(NSString *)(id)@42 baseDirectory:nil], @"not a string");
}

/// [EN] The query picks one file by name, theme, version and format. [CN] 查询参数按名称、主题、版本与格式选出一个文件。
- (void)testQueryPicksOneFile {
    for (NSString *name in @[ @"tabbar.json", @"tabbar@1.0.json", @"tabbar@1.9.json", @"tabbar@1.10.yaml", @"tabbar-dark@2.0.yaml",
                              @"tabbar-dark@2.0.json", @"tabbar-dark.plist", @"tabbar.txt", @"tabbarx@3.0.json", @"._tabbar@9.0.json", @"other@5.0.json" ]) {
        [self write:@"{}" name:name];
    }
    NSString *route = [@"sandbox:Caches/" stringByAppendingString:self.folder.lastPathComponent];
    NSString * (^pick)(NSString *) = ^NSString *(NSString *query) {
        return [CYLResourceRoute pathForRoute:[NSString stringWithFormat:@"%@?%@", route, query] baseDirectory:nil].lastPathComponent;
    };
    XCTAssertEqualObjects(pick(@"name=tabbar"), @"tabbar@1.10.yaml", @"the highest version, compared as numbers");
    XCTAssertEqualObjects(pick(@"name=tabbar&version=1.9"), @"tabbar@1.9.json");
    XCTAssertEqualObjects(pick(@"name=tabbar&format=json"), @"tabbar@1.9.json");
    XCTAssertEqualObjects(pick(@"name=tabbar&theme=dark"), @"tabbar-dark@2.0.json", @"same version: JSON before YAML");
    XCTAssertEqualObjects(pick(@"name=tabbar&theme=dark&format=yml"), @"tabbar-dark@2.0.yaml", @"yml and yaml are one format");
    XCTAssertEqualObjects(pick(@"name=tabbar&theme=dark&format=plist"), @"tabbar-dark.plist");
    XCTAssertEqualObjects(pick(@"NAME=tabbar&Format=JSON&version=1.0"), @"tabbar@1.0.json", @"keys and formats ignore case");
    XCTAssertNil(pick(@"name=tabbar&version=7.0"));
    XCTAssertNil(pick(@"name=tabbar&theme=light"));
    XCTAssertNil(pick(@"name=missing"));
    XCTAssertNil(pick(@"theme=dark"), @"a query needs a name");
    XCTAssertNil([CYLResourceRoute pathForRoute:@"sandbox:Caches/no-such-folder?name=tabbar" baseDirectory:nil]);
    XCTAssertEqualObjects([CYLResourceRoute pathOfFileInDirectory:self.folder name:@"other" theme:nil version:nil format:nil].lastPathComponent, @"other@5.0.json");
}

/// [EN] A tab bar controller from a route into the sandbox; its tables, next to the file, translate the titles.
/// [CN] 根据指向沙盒的路由创建 TabBarController；文件旁边的字符串表翻译标题。
- (void)testTabBarControllerFromSandboxRouteWithLocalization {
    NSString *json = @"{\"CYLTabBarControllerLocalization\": {\"CYLTabBarLocalizationTableName\": \"Tabs\", \"CYLTabBarLocalizationPath\": \"Localization\"},"
                     @" \"CYLTabBarControllerTabBarItemsAttributes\": [{\"CYLTabBarItemIdentifier\": \"home\", \"CYLTabBarItemTitle\": \"%@\"}]}";
    [self write:[NSString stringWithFormat:json, @"Home"] name:@"tabbar@1.0.json"];
    [self write:[NSString stringWithFormat:json, @"Me"] name:@"tabbar@2.0.json"];
    [self write:@"\"Home\" = \"首页\";\n\"Me\" = \"我的\";\n" name:@"Localization/zh-Hans.lproj/Tabs.strings"];
    NSString *route = [NSString stringWithFormat:@"sandbox:Caches/%@?name=tabbar", self.folder.lastPathComponent];
    NSError *error = nil;
    NSDictionary *configuration = [CYLTabBarController configurationWithRoute:route error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects([configuration[CYLTabBarControllerTabBarItemsAttributes] firstObject][CYLTabBarItemTitle], @"Me", @"version 2.0 wins");
    CYLSetLocalizationLanguage(@"zh-Hans");
    NSMutableDictionary *withResolver = [configuration mutableCopy];
    withResolver[CYLTabBarControllerPageResolver] = ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
        return [[UIViewController alloc] init];
    };
    NSString *title = [CYLTabBarController tabBarControllerWithConfiguration:withResolver].tabBarItemsAttributes.firstObject[CYLTabBarItemTitle];
    CYLSetLocalizationLanguage(nil);
    XCTAssertEqualObjects(title, @"我的", @"the relative table path is resolved against the routed file's folder");
}

/// [EN] `CYLTabBarControllerConfigurationRoute` in a dictionary: the file's keys, with the other keys over them (as React
///      Native and Flutter send it). [CN] 字典中的 `CYLTabBarControllerConfigurationRoute`：文件中的键，再由其他键覆盖（React Native 与
///      Flutter 就是这样发送的）。
- (void)testConfigurationRouteKey {
    [self write:@"{\"CYLTabBarControllerTitlePositionAdjustment\": \"{0, -5}\", \"CYLTabBarControllerTabBarItemsAttributes\": ["
                @"{\"CYLTabBarItemIdentifier\": \"home\", \"CYLTabBarItemTitle\": \"Home\"}, {\"CYLTabBarItemIdentifier\": \"me\", \"CYLTabBarItemTitle\": \"Me\"}]}"
           name:@"tabbar-dark.json"];
    NSString *route = [NSString stringWithFormat:@"sandbox:Caches/%@?name=tabbar&theme=dark", self.folder.lastPathComponent];
    UIViewController * (^resolver)(NSString *, NSDictionary *) = ^UIViewController *(NSString *pageIdentifier, NSDictionary *attributes) {
        return [[UIViewController alloc] init];
    };
    CYLTabBarController *fromFile = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerConfigurationRoute : route, CYLTabBarControllerPageResolver : resolver,
    }];
    XCTAssertEqual(fromFile.viewControllers.count, 2u);
    XCTAssertEqualObjects(fromFile.tabBarItemsAttributes[1][CYLTabBarItemTitle], @"Me");
    XCTAssertTrue(UIOffsetEqualToOffset(fromFile.titlePositionAdjustment, UIOffsetMake(0, -5)));
    CYLTabBarController *overridden = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerConfigurationRoute : route, CYLTabBarControllerPageResolver : resolver,
        CYLTabBarControllerTitlePositionAdjustment : @"{0, -1}",
    }];
    XCTAssertTrue(UIOffsetEqualToOffset(overridden.titlePositionAdjustment, UIOffsetMake(0, -1)), @"the dictionary wins over the file");
    XCTAssertEqual(overridden.viewControllers.count, 2u, @"keys it does not give come from the file");
    CYLTabBarController *missing = [CYLTabBarController tabBarControllerWithConfiguration:@{
        CYLTabBarControllerConfigurationRoute : @"sandbox:Caches/no-such-folder?name=tabbar", CYLTabBarControllerPageResolver : resolver,
    }];
    XCTAssertEqual(missing.viewControllers.count, 0u, @"a route without a file is ignored");
}

/// [EN] A route that matches nothing: nil and a file-not-found error, from every initializer. [CN] 没有匹配的路由：所有初始化方法都返回 nil 与“文件不存在”错误。
- (void)testRouteWithoutFile {
    NSString *route = [NSString stringWithFormat:@"sandbox:Caches/%@?name=nothing", self.folder.lastPathComponent];
    NSError *error = nil;
    XCTAssertNil([CYLTabBarController configurationWithRoute:route error:&error]);
    XCTAssertEqual(error.code, CYLTabBarConfigurationErrorFileNotFound);
    XCTAssertTrue([error.localizedDescription containsString:@"name=nothing"]);
    error = nil;
    XCTAssertNil([CYLTabBarController tabBarControllerWithConfigurationRoute:route error:&error]);
    XCTAssertEqualObjects(error.domain, CYLTabBarConfigurationErrorDomain);
    error = nil;
    XCTAssertNil([CYLTabBarController configurationWithRoute:@"" error:&error]);
    XCTAssertEqual(error.code, CYLTabBarConfigurationErrorFileNotFound);
    XCTAssertNil([CYLTabBarController configurationWithRoute:route error:NULL], @"a NULL error pointer is fine");
}

@end
