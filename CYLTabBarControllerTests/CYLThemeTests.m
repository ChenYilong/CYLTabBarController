//
//  CYLThemeTests.m
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>

/// [EN] A tab bar theme with a background color only. [CN] 只有背景色的 TabBar 主题。
@interface CYLTestTabBarTheme : NSObject <CYLTabBarTheme>
@property (nonatomic, strong) UIColor *barColor;
@end

@implementation CYLTestTabBarTheme

- (UITabBarAppearance *)cyl_tabBarAppearanceForTabBarController:(CYLTabBarController *)tabBarController {
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = self.barColor;
    return appearance;
}

@end

@interface CYLThemeTests : XCTestCase
@end

@implementation CYLThemeTests

/// [EN] A manager of its own for each test, so tests do not share state. [CN] 每个测试使用自己的管理器，互不影响。
- (CYLThemeManager *)newManager {
    return [CYLThemeManagerCenter themeManagerWithName:[NSUUID UUID].UUIDString];
}

- (void)testFirstThemeIsNotAChangeAndSwitchingPostsOnce {
    CYLThemeManager *manager = [self newManager];
    [manager addThemeIdentifier:@"Light" theme:@"light theme"];
    [manager addThemeIdentifier:@"Dark" theme:@"dark theme"];
    __block NSInteger posts = 0;
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:CYLThemeDidChangeNotification object:manager queue:nil usingBlock:^(NSNotification *note) {
        posts++;
    }];
    manager.currentThemeIdentifier = @"Light";
    XCTAssertEqual(posts, 0, @"the first theme is not a change");
    XCTAssertEqualObjects(manager.currentTheme, @"light theme");

    manager.currentThemeIdentifier = @"Dark";
    XCTAssertEqual(posts, 1);
    XCTAssertEqualObjects(manager.currentTheme, @"dark theme");

    manager.currentThemeIdentifier = @"Dark";
    XCTAssertEqual(posts, 1, @"the same theme again is not a change");
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
}

- (void)testSettingCurrentThemeSetsItsIdentifier {
    CYLThemeManager *manager = [self newManager];
    [manager addThemeIdentifier:@"A" theme:@"theme A"];
    [manager addThemeIdentifier:@"B" theme:@"theme B"];
    manager.currentTheme = @"theme B";
    XCTAssertEqualObjects(manager.currentThemeIdentifier, @"B");
}

- (void)testUnregisteredIdentifierIsIgnoredWithoutGenerator {
    CYLThemeManager *manager = [self newManager];
    [manager addThemeIdentifier:@"A" theme:@"theme A"];
    manager.currentThemeIdentifier = @"A";
    manager.currentThemeIdentifier = @"Missing";
    XCTAssertEqualObjects(manager.currentThemeIdentifier, @"A");
}

- (void)testGeneratorCreatesAndRegistersTheme {
    CYLThemeManager *manager = [self newManager];
    manager.themeGenerator = ^__kindof NSObject *(__kindof NSObject<NSCopying> *identifier) {
        return [NSString stringWithFormat:@"generated %@", identifier];
    };
    manager.currentThemeIdentifier = @"X";
    XCTAssertEqualObjects(manager.currentTheme, @"generated X");
    XCTAssertEqualObjects(manager.themeIdentifiers, @[ @"X" ]);
}

- (void)testDuplicatesAreIgnoredAndRemovingRemovesThePair {
    CYLThemeManager *manager = [self newManager];
    [manager addThemeIdentifier:@"A" theme:@"theme A"];
    [manager addThemeIdentifier:@"A" theme:@"another theme"];
    [manager addThemeIdentifier:@"B" theme:@"theme B"];
    XCTAssertEqual(manager.themes.count, 2u);

    [manager removeThemeIdentifier:@"A"];
    XCTAssertEqualObjects(manager.themeIdentifiers, @[ @"B" ]);
    XCTAssertEqualObjects(manager.themes, @[ @"theme B" ]);
    XCTAssertEqualObjects([manager identifierForTheme:@"theme B"], @"B");

    [manager removeTheme:@"theme B"];
    XCTAssertNil(manager.themeIdentifiers);
    XCTAssertNil(manager.themes);
}

- (void)testThemeColorFollowsTheTheme {
    CYLThemeManager *manager = [self newManager];
    [manager addThemeIdentifier:@"Red" theme:UIColor.redColor];
    [manager addThemeIdentifier:@"Blue" theme:UIColor.blueColor];
    manager.currentThemeIdentifier = @"Red";
    UIColor *color = [UIColor cyl_colorWithName:@"accent" themeManagerName:manager.name provider:^UIColor *(CYLThemeManager *themeManager, id identifier, UIColor *theme) {
        return theme;
    }];
    XCTAssertTrue(color.cyl_isThemeColor);
    XCTAssertEqualObjects(color.cyl_themeColorName, @"accent");
    XCTAssertEqualObjects(color.cyl_rawColor, UIColor.redColor);

    manager.currentThemeIdentifier = @"Blue";
    XCTAssertEqualObjects(color.cyl_rawColor, UIColor.blueColor);
    XCTAssertFalse(UIColor.redColor.cyl_isThemeColor);
    XCTAssertEqualObjects(UIColor.redColor.cyl_rawColor, UIColor.redColor);
}

- (void)testRegisteredViewPropertyGetsTheNewThemeColor {
    CYLThemeManager *manager = [self newManager];
    [manager addThemeIdentifier:@"Red" theme:UIColor.redColor];
    [manager addThemeIdentifier:@"Blue" theme:UIColor.blueColor];
    manager.currentThemeIdentifier = @"Red";
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    view.backgroundColor = [UIColor cyl_colorWithThemeManagerName:manager.name provider:^UIColor *(CYLThemeManager *themeManager, id identifier, UIColor *theme) {
        return theme;
    }];
    [view cyl_registerThemeColorProperties:@[ @"backgroundColor" ]];
    __block BOOL blockRan = NO;
    view.cyl_themeDidChangeBlock = ^{
        blockRan = YES;
    };

    manager.currentThemeIdentifier = @"Blue";
    // [EN] The view is in no window: tell it as the manager tells the views of a window.
    // [CN] 该视图不在 window 上：像管理器通知 window 中的视图那样通知它。
    [view cyl_themeDidChangeByManager:manager identifier:manager.currentThemeIdentifier theme:manager.currentTheme];
    XCTAssertTrue(blockRan);
    XCTAssertEqualObjects(view.backgroundColor.cyl_rawColor, UIColor.blueColor);
}

- (void)testTabBarThemeAppliesAndRestoresTheAppearance {
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ [UIViewController new], [UIViewController new] ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"A" }, @{ CYLTabBarItemTitle : @"B" } ]];
    [tabBarController loadViewIfNeeded];
    UIColor *originalColor = tabBarController.tabBar.standardAppearance.backgroundColor;

    CYLTestTabBarTheme *theme = [CYLTestTabBarTheme new];
    theme.barColor = UIColor.systemPinkColor;
    [tabBarController cyl_applyTabBarTheme:theme];
    XCTAssertEqualObjects(tabBarController.tabBar.standardAppearance.backgroundColor, UIColor.systemPinkColor);

    [tabBarController cyl_applyTabBarTheme:nil];
    XCTAssertEqualObjects(tabBarController.tabBar.standardAppearance.backgroundColor, originalColor, @"nil gives back the app's own look");
}

@end
