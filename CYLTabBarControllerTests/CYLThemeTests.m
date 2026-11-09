//
//  CYLThemeTests.m
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CYLTabBarController/CYLTabBarController.h>
// [EN] Internal to the framework: not in its public headers. [CN] 框架内部的头文件，不属于其公开头文件。
#import "../CYLTabBarController/CYLTabBarItemAnimation/GIF/CYLGIFTabBarItemAnimator.h"
#import "../CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimatorRegistry.h"
#import "../CYLTabBarController/CYLTabBarItemAnimation/CYLTabBarItemAnimationPlayableView.h"
#import <ImageIO/ImageIO.h>

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

/// [EN] A tab bar theme with a title and an icon for each tab (below). [CN] 每个 Tab 都有标题与图标的 TabBar 主题（见下方）。
@interface CYLTestItemsTabBarTheme : NSObject <CYLTabBarTheme>
@end

@interface CYLTestKeysTabBarTheme : NSObject <CYLTabBarTheme>
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, id> *> *attributes;
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

#pragma mark - Theme images, effects, layer colors

/// [EN] A square image of `side` points. [CN] 边长为 `side` 点的正方形图片。
static UIImage *CYLTestImage(CGFloat side, UIColor *color) {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [color setFill];
        UIRectFill(CGRectMake(0, 0, side, side));
    }];
}

/// [EN] A manager with a small image theme "A" (10 pt) and a large one "B" (20 pt), on "A". [CN] 有小图主题“A”（10 pt）与大图主题“B”（20 pt）的管理器，当前为“A”。
- (CYLThemeManager *)newImageManager {
    CYLThemeManager *manager = [self newManager];
    [manager addThemeIdentifier:@"A" theme:CYLTestImage(10, UIColor.redColor)];
    [manager addThemeIdentifier:@"B" theme:CYLTestImage(20, UIColor.blueColor)];
    manager.currentThemeIdentifier = @"A";
    return manager;
}

- (UIImage *)themeImageOfManager:(CYLThemeManager *)manager {
    return [UIImage cyl_imageWithThemeManagerName:manager.name provider:^UIImage *(CYLThemeManager *themeManager, id identifier, UIImage *theme) {
        return theme;
    }];
}

- (void)testViewOfAViewControllerNotInAWindowGetsTheNewTheme {
    CYLThemeManager *manager = [self newImageManager];
    UIViewController *viewController = [[UIViewController alloc] init];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[self themeImageOfManager:manager]];
    [viewController.view addSubview:imageView];
    XCTAssertNil(viewController.view.window);

    manager.currentThemeIdentifier = @"B";
    [viewController cyl_themeDidChangeByManager:manager identifier:manager.currentThemeIdentifier theme:manager.currentTheme];
    XCTAssertEqual(imageView.image.size.width, 20.0, @"the walk reaches a view controller's view that is not in a window");
}

/// [EN] A tab bar theme with an icon and a title for each tab. [CN] 每个 Tab 都有图标与标题的 TabBar 主题。
- (void)testTabBarThemeIconsDoNotTouchTabBarItemImagesAndTitlesStillChange {
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ [UIViewController new], [UIViewController new] ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"A" }, @{ CYLTabBarItemTitle : @"B" } ]];
    [tabBarController loadViewIfNeeded];
    UIViewController *first = tabBarController.viewControllers.firstObject;
    // [EN] A tab without an image of its own gets a placeholder image from the library. [CN] 没有图片的 Tab 会得到本库设置的占位图。
    UIImage *imageBefore = first.tabBarItem.image;
    CYLTestItemsTabBarTheme *theme = [CYLTestItemsTabBarTheme new];
    [tabBarController cyl_applyTabBarTheme:theme];
    XCTAssertEqualObjects(first.tabBarItem.title, @"★ A");
    XCTAssertEqual(first.tabBarItem.image, imageBefore, @"theme icons are views in place of the icon; the item keeps the app's image");
    XCTAssertNil(tabBarController.tabBarItemsAttributes.firstObject[CYLTabBarItemImage]);

    [tabBarController cyl_applyTabBarTheme:nil];
    XCTAssertEqualObjects(first.tabBarItem.title, @"A", @"nil gives back the app's own titles");
}

/// [EN] A skin and its restore: following navigation titles change with the tabs, every changed tab posts
///      `CYLTabBarItemDidChangeNotification`, and the tab bar posts `CYLTabBarControllerThemeDidApplyNotification` once.
/// [CN] 换肤与恢复：跟随的导航栏标题随 Tab 变化，每个变化的 Tab 发送 `CYLTabBarItemDidChangeNotification`，TabBar 发送一次
///      `CYLTabBarControllerThemeDidApplyNotification`。
- (void)testSkinUpdatesFollowingNavigationTitlesAndPostsNotifications {
    UIViewController *page = [UIViewController new];
    CYL_NAVIGATION_TITLE_FOLLOWS_TAB_BAR_ITEM(page);
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:page];
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ navigation, [UIViewController new] ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"A", CYLTabBarItemIdentifier : @"a" },
                                                                                                    @{ CYLTabBarItemTitle : @"B", CYLTabBarItemIdentifier : @"b" } ]];
    [tabBarController loadViewIfNeeded];
    XCTAssertEqualObjects(page.navigationItem.title, @"A");
    NSMutableArray<NSNotification *> *itemNotes = [NSMutableArray array];
    NSMutableArray<NSNotification *> *skinNotes = [NSMutableArray array];
    NSMutableArray<NSNotification *> *iconNotes = [NSMutableArray array];
    id iconObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemIconDidChangeNotification object:page queue:nil usingBlock:^(NSNotification *note) {
        [iconNotes addObject:note];
    }];
    id itemObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarItemDidChangeNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
        [itemNotes addObject:note];
    }];
    id skinObserver = [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarControllerThemeDidApplyNotification object:tabBarController queue:nil usingBlock:^(NSNotification *note) {
        [skinNotes addObject:note];
    }];
    CYLTestItemsTabBarTheme *theme = [CYLTestItemsTabBarTheme new];
    [tabBarController cyl_applyTabBarTheme:theme];
    XCTAssertEqualObjects(page.navigationItem.title, @"★ A", @"a skin's title reaches the following navigation bar");
    NSNotification *pageNote = nil;
    for (NSNotification *note in itemNotes) {
        if (note.object == page) { pageNote = note; }
    }
    XCTAssertNotNil(pageNote);
    XCTAssertEqualObjects(pageNote.userInfo[CYLTabBarItemChangedAttributesKey][CYLTabBarItemTitle], @"★ A");
    XCTAssertEqualObjects(pageNote.userInfo[CYLTabBarItemIndexKey], @0);
    XCTAssertEqual(skinNotes.count, 1u);
    XCTAssertEqual(skinNotes.firstObject.userInfo[CYLTabBarThemeKey], theme);
    XCTAssertEqualObjects(skinNotes.firstObject.userInfo[CYLTabBarItemIndexesKey], [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)],
                          @"a skin changes every tab by default");
    XCTAssertEqualObjects(skinNotes.firstObject.userInfo[CYLTabBarItemIdentifiersKey], (@[ @"a", @"b" ]));
    XCTAssertEqualObjects(pageNote.userInfo[CYLTabBarItemIdentifier], @"a");
    XCTAssertGreaterThan(iconNotes.count, 0u, @"the skin's icon (a view in place of the icon) posts the icon notification");
    XCTAssertEqualObjects(iconNotes.firstObject.userInfo[CYLTabBarItemIndexKey], @0);

    [tabBarController cyl_applyTabBarTheme:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:itemObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:skinObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:iconObserver];
    XCTAssertEqualObjects(page.navigationItem.title, @"A", @"restoring gives the navigation bar the app's title back");
    XCTAssertEqual(skinNotes.count, 2u);
    XCTAssertNil(skinNotes.lastObject.userInfo[CYLTabBarThemeKey], @"no theme when restoring");
}

#pragma mark - The restore model, applying the current theme, persistence

- (CYLTabBarController *)newTabBarControllerWithTitles {
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ [UIViewController new], [UIViewController new] ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"A" }, @{ CYLTabBarItemTitle : @"B" } ]];
    [tabBarController loadViewIfNeeded];
    return tabBarController;
}

- (void)testRestoreRemovesAKeyTheAppDidNotHave {
    CYLTabBarController *tabBarController = [self newTabBarControllerWithTitles];
    CYLTestKeysTabBarTheme *theme = [CYLTestKeysTabBarTheme new];
    theme.attributes = @[ @{ CYLTabBarItemTitle : @"T", CYLTabBarItemTitleColor : UIColor.systemPinkColor }, @{} ];
    [tabBarController cyl_applyTabBarTheme:theme];
    XCTAssertEqualObjects([tabBarController tabBarItemAttributesAtIndex:0][CYLTabBarItemTitleColor], UIColor.systemPinkColor);

    [tabBarController cyl_applyTabBarTheme:nil];
    NSDictionary *attributes = [tabBarController tabBarItemAttributesAtIndex:0];
    XCTAssertEqualObjects(attributes[CYLTabBarItemTitle], @"A");
    XCTAssertNil(attributes[CYLTabBarItemTitleColor], @"a key the theme added and the app did not have is removed");
}

- (void)testRestoreKeepsATitleTheAppChangedMeanwhile {
    CYLTabBarController *tabBarController = [self newTabBarControllerWithTitles];
    CYLTestKeysTabBarTheme *theme = [CYLTestKeysTabBarTheme new];
    theme.attributes = @[ @{ CYLTabBarItemTitle : @"T" }, @{ CYLTabBarItemTitle : @"U" } ];
    [tabBarController cyl_applyTabBarTheme:theme];
    [tabBarController updateTabBarItemAtIndex:0 attributes:@{ CYLTabBarItemTitle : @"Mine" }];

    [tabBarController cyl_applyTabBarTheme:nil];
    XCTAssertEqualObjects([tabBarController tabBarItemAttributesAtIndex:0][CYLTabBarItemTitle], @"Mine", @"the app's change is kept");
    XCTAssertEqualObjects([tabBarController tabBarItemAttributesAtIndex:1][CYLTabBarItemTitle], @"B", @"the untouched tab gets its own title back");
}

- (void)testOneTimeLayoutBlockRunsAgainAfterATheme {
    CYLTabBarController *tabBarController = [self newTabBarControllerWithTitles];
    __block NSInteger runs = 0;
    [tabBarController setViewDidLayoutSubViewsBlockInvokeOnce:YES block:^(CYLTabBarController *controller) {
        runs++;
    }];
    [tabBarController viewDidLayoutSubviews];
    [tabBarController viewDidLayoutSubviews];
    XCTAssertEqual(runs, 1, @"once per setup");

    CYLTestKeysTabBarTheme *theme = [CYLTestKeysTabBarTheme new];
    theme.attributes = @[ @{ CYLTabBarItemTitle : @"T" }, @{} ];
    [tabBarController cyl_applyTabBarTheme:theme];
    [tabBarController viewDidLayoutSubviews];
    [tabBarController viewDidLayoutSubviews];
    XCTAssertEqual(runs, 2, @"a theme lets it run once more (covers and badges are added again)");

    [tabBarController reloadTabBarItemsWithAttributes:@[ @{ CYLTabBarItemTitle : @"A" }, @{ CYLTabBarItemTitle : @"B" } ]];
    [tabBarController viewDidLayoutSubviews];
    XCTAssertEqual(runs, 3, @"reloading the tabs too");
}

- (void)testSymbolThemeImagesAreMarkedNewObjects {
    CYLThemeManager *manager = [self newManager];
    UIImage *symbol = [UIImage systemImageNamed:@"star.fill"];
    [manager addThemeIdentifier:@"S" theme:symbol];
    manager.currentThemeIdentifier = @"S";
    UIImage *first = [self themeImageOfManager:manager];
    UIImage *second = [self themeImageOfManager:manager];
    XCTAssertTrue(first.cyl_isThemeImage);
    XCTAssertTrue(second.cyl_isThemeImage);
    XCTAssertNotEqual(first, second);
    XCTAssertFalse(symbol.cyl_isThemeImage, @"the provider's symbol is not marked");
    NSLog(@"[CYLThemeTests] a symbol theme image is a symbol: %d", first.isSymbolImage);
}

- (void)testApplyCurrentThemeRefreshesAViewNothingWalked {
    CYLThemeManager *manager = [self newImageManager];
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[self themeImageOfManager:manager]];
    [container addSubview:imageView];
    manager.currentThemeIdentifier = @"B";
    XCTAssertEqual(imageView.image.size.width, 10.0, @"nothing walked the view yet");
    [container cyl_applyCurrentTheme];
    XCTAssertEqual(imageView.image.size.width, 20.0);
}

- (void)testPersistsCurrentThemeIdentifier {
    NSString *name = [NSUUID UUID].UUIDString;
    NSString *key = [NSString stringWithFormat:@"CYLThemeManager.%@.currentThemeIdentifier", name];
    [[NSUserDefaults standardUserDefaults] setObject:@"B" forKey:key];
    CYLThemeManager *manager = [CYLThemeManagerCenter themeManagerWithName:name];
    [manager addThemeIdentifier:@"A" theme:@"theme A"];
    [manager addThemeIdentifier:@"B" theme:@"theme B"];
    manager.persistsCurrentThemeIdentifier = YES;
    XCTAssertEqualObjects(manager.currentThemeIdentifier, @"B", @"the saved theme is current again");

    manager.currentThemeIdentifier = @"A";
    XCTAssertEqualObjects([[NSUserDefaults standardUserDefaults] objectForKey:key], @"A", @"every change is saved");
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
}

#pragma mark - Skins in a configuration file 配置文件中的皮肤

/// [EN] Two tabs from code, with skin names in their values. [CN] 两个代码传入的 Tab，值中带有皮肤名称。
- (NSDictionary *)skinnedConfigurationWithManagerName:(NSString *)name themes:(id)themes {
    return @{
        CYLTabBarControllerViewControllers : @[ [[UIViewController alloc] init], [[UIViewController alloc] init] ],
        CYLTabBarControllerThemeManagerName : name,
        CYLTabBarControllerThemes : themes,
        CYLTabBarControllerThemeIdentifier : @"light",
        CYLTabBarControllerTabBarItemsAttributes : @[
            @{ CYLTabBarItemTitle : @"@homeTitle", CYLTabBarItemIdentifier : @"home", CYLTabBarItemTitleColor : @"@accent" },
            @{ CYLTabBarItemTitle : @"@@me", CYLTabBarItemIdentifier : @"me" },
        ],
    };
}

- (NSDictionary *)itemWithIdentifier:(NSString *)identifier ofTabBarController:(CYLTabBarController *)tabBarController {
    for (NSDictionary *item in tabBarController.tabBarItemsAttributes) {
        if ([item[CYLTabBarItemIdentifier] isEqual:identifier]) {
            return item;
        }
    }
    return nil;
}

- (void)testSkinsOfAConfigurationResolveNamedValuesAndRegisterWithTheManager {
    NSString *name = [NSUUID UUID].UUIDString;
    NSDictionary *themes = @{
        @"light" : @{ @"homeTitle" : @"Home", @"accent" : @"#FF0000", CYLTabBarBackgroundColor : @"#FFFFFF" },
        @"dark" : @{ @"homeTitle" : @"Home (dark)", CYLTabBarBackgroundColor : @"#000000" },
    };
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithConfiguration:[self skinnedConfigurationWithManagerName:name themes:themes]];
    CYLThemeManager *manager = [CYLThemeManagerCenter themeManagerWithName:name];
    XCTAssertEqual(tabBarController.cyl_themeManager, manager);
    XCTAssertEqualObjects([manager.themeIdentifiers sortedArrayUsingSelector:@selector(compare:)], (@[ @"dark", @"light" ]));
    XCTAssertEqualObjects(manager.currentThemeIdentifier, @"light", @"the first skin");

    NSDictionary *home = [self itemWithIdentifier:@"home" ofTabBarController:tabBarController];
    XCTAssertEqualObjects(home[CYLTabBarItemTitle], @"Home");
    XCTAssertTrue([home[CYLTabBarItemTitleColor] isKindOfClass:[UIColor class]], @"a named value goes through the same conversion");
    XCTAssertEqualObjects([self itemWithIdentifier:@"me" ofTabBarController:tabBarController][CYLTabBarItemTitle], @"@me", @"\"@@\" is a literal \"@\"");

    CYLTabBarConfigurationTheme *dark = [manager themeForIdentifier:@"dark"];
    XCTAssertTrue([dark isKindOfClass:[CYLTabBarConfigurationTheme class]]);
    XCTAssertEqualObjects([dark valueForName:@"accent"], @"#FF0000", @"a name the skin does not give comes from the base skin");
    NSArray<NSDictionary *> *darkItems = [dark cyl_tabBarItemsAttributesForTabBarController:tabBarController];
    XCTAssertEqual(darkItems.count, 2u);
    XCTAssertEqualObjects(darkItems.firstObject[CYLTabBarItemTitle], @"Home (dark)");
    XCTAssertEqualObjects(darkItems.lastObject, @{}, @"a tab without names stays as it is");
    UITabBarAppearance *appearance = [dark cyl_tabBarAppearanceForTabBarController:tabBarController];
    CGFloat red = 1, green = 1, blue = 1;
    XCTAssertTrue([appearance.backgroundColor getRed:&red green:&green blue:&blue alpha:NULL]);
    XCTAssertEqualWithAccuracy(red + green + blue, 0, 0.01, @"the dark skin's bar color");
    XCTAssertNotNil([CYLTabBarConfigurationTheme colorNamed:@"accent" themeManagerName:name]);
}

- (void)testSkinsAcceptTheListFormAndKeepASkinChosenBefore {
    NSString *name = [NSUUID UUID].UUIDString;
    CYLThemeManager *manager = [CYLThemeManagerCenter themeManagerWithName:name];
    [manager addThemeIdentifier:@"mine" theme:@"the app's own theme"];
    manager.currentThemeIdentifier = @"mine";
    // [EN] The Protobuf form: a list of skins, the values as map entries. [CN] Protobuf 形式：皮肤列表，值为 map 条目。
    NSArray *themes = @[ @{ CYLTabBarThemeIdentifier : @"light", CYLTabBarThemeValues : @[ @{ @"key" : @"homeTitle", @"value" : @"Home" } ] } ];
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithConfiguration:[self skinnedConfigurationWithManagerName:name themes:themes]];
    XCTAssertEqualObjects(manager.currentThemeIdentifier, @"mine", @"a skin chosen before stays");
    NSDictionary *home = [self itemWithIdentifier:@"home" ofTabBarController:tabBarController];
    XCTAssertEqualObjects(home[CYLTabBarItemTitle], @"Home");
    XCTAssertNil(home[CYLTabBarItemTitleColor], @"a name no skin gives leaves the key out");
    XCTAssertTrue([[manager themeForIdentifier:@"light"] isKindOfClass:[CYLTabBarConfigurationTheme class]]);
}

- (void)testWithoutSkinsAnAtSignIsPlainText {
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithConfiguration:@{
        CYLTabBarControllerViewControllers : @[ [[UIViewController alloc] init] ],
        CYLTabBarControllerTabBarItemsAttributes : @[ @{ CYLTabBarItemTitle : @"@homeTitle", CYLTabBarItemIdentifier : @"home" } ],
    }];
    XCTAssertEqualObjects([self itemWithIdentifier:@"home" ofTabBarController:tabBarController][CYLTabBarItemTitle], @"@homeTitle");
}

@end

/// [EN] A tab bar theme with the given attributes. [CN] 使用给定 attributes 的 TabBar 主题。
@implementation CYLTestKeysTabBarTheme

- (NSArray<NSDictionary<NSString *, id> *> *)cyl_tabBarItemsAttributesForTabBarController:(CYLTabBarController *)tabBarController {
    return self.attributes;
}

@end

@implementation CYLTestItemsTabBarTheme

- (NSArray<NSDictionary<NSString *, id> *> *)cyl_tabBarItemsAttributesForTabBarController:(CYLTabBarController *)tabBarController {
    return @[ @{ CYLTabBarItemTitle : @"★ A", CYLTabBarItemImage : CYLTestImage(24, UIColor.orangeColor) },
              @{ CYLTabBarItemTitle : @"★ B", CYLTabBarItemImage : CYLTestImage(24, UIColor.purpleColor) } ];
}

@end

#pragma mark - Theme images, effects and layer colors (QMUI gap)

/// [EN] Two 1 × 1 images that tell themselves apart by their tint. [CN] 两张以 tint 区分的 1 × 1 图片。
static UIImage *CYLTestSolidImage(UIColor *color) {
    return [[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(1, 1)] imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [color setFill];
        UIRectFill(CGRectMake(0, 0, 1, 1));
    }];
}

@interface CYLThemeValueTests : XCTestCase
@property (nonatomic, strong) CYLThemeManager *manager;
@property (nonatomic, strong) UIImage *dayImage;
@property (nonatomic, strong) UIImage *nightImage;
@end

@implementation CYLThemeValueTests

- (void)setUp {
    [super setUp];
    self.manager = [CYLThemeManagerCenter themeManagerWithName:@"CYLThemeValueTests"];
    for (NSObject<NSCopying> *identifier in [self.manager.themeIdentifiers copy]) {
        [self.manager removeThemeIdentifier:identifier];
    }
    [self.manager addThemeIdentifier:@"day" theme:@"day"];
    [self.manager addThemeIdentifier:@"night" theme:@"night"];
    self.manager.currentThemeIdentifier = @"day";
    self.dayImage = CYLTestSolidImage(UIColor.whiteColor);
    self.nightImage = CYLTestSolidImage(UIColor.blackColor);
}

- (UIImage *)themeImage {
    __weak typeof(self) weakSelf = self;
    return [UIImage cyl_imageWithThemeManagerName:@"CYLThemeValueTests" provider:^UIImage *(CYLThemeManager *manager, NSObject<NSCopying> *identifier, NSObject *theme) {
        return [identifier isEqual:@"night"] ? weakSelf.nightImage : weakSelf.dayImage;
    }];
}

- (UIVisualEffect *)themeEffect {
    return [UIVisualEffect cyl_effectWithThemeManagerName:@"CYLThemeValueTests" provider:^UIVisualEffect *(CYLThemeManager *manager, NSObject<NSCopying> *identifier, NSObject *theme) {
        return [UIBlurEffect effectWithStyle:[identifier isEqual:@"night"] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight];
    }];
}

- (UIColor *)themeColor {
    return [UIColor cyl_colorWithThemeManagerName:@"CYLThemeValueTests" provider:^UIColor *(CYLThemeManager *manager, NSObject<NSCopying> *identifier, NSObject *theme) {
        return [identifier isEqual:@"night"] ? UIColor.blackColor : UIColor.whiteColor;
    }];
}

- (void)testThemeImageIsANewObjectThatKeepsTheProviderImageContent {
    UIImage *image = [self themeImage];
    XCTAssertTrue(image.cyl_isThemeImage);
    XCTAssertNotEqual(image, self.dayImage, @"the provider's (shared) image must not carry the theme info");
    XCTAssertFalse(self.dayImage.cyl_isThemeImage);
    XCTAssertEqual(image.cyl_rawImage, self.dayImage);
    XCTAssertTrue(CGSizeEqualToSize(image.size, self.dayImage.size));
    self.manager.currentThemeIdentifier = @"night";
    XCTAssertEqual(image.cyl_rawImage, self.nightImage, @"the raw image follows the current theme");
}

- (void)testImageViewAndButtonGetTheImageOfTheNewTheme {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = [self themeImage];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[self themeImage] forState:UIControlStateNormal];
    [button setBackgroundImage:[self themeImage] forState:UIControlStateSelected];
    UIImage *plainImage = CYLTestSolidImage(UIColor.redColor);
    [button setImage:plainImage forState:UIControlStateDisabled];
    UIView *container = [[UIView alloc] init];
    [container addSubview:imageView];
    [container addSubview:button];
    [container cyl_themeDidChangeByManager:self.manager identifier:@"day" theme:@"day"];
    self.manager.currentThemeIdentifier = @"night";
    // [EN] Not in a window: reached as a tracked view (found on the first change) or here by hand. [CN] 不在 window 中：作为记住的视图到达，或在此手动调用。
    [container cyl_themeDidChangeByManager:self.manager identifier:@"night" theme:@"night"];
    XCTAssertEqual(imageView.image.cyl_rawImage, self.nightImage);
    XCTAssertTrue(imageView.image.cyl_isThemeImage, @"still a theme image after the change");
    XCTAssertEqual([button imageForState:UIControlStateNormal].cyl_rawImage, self.nightImage);
    XCTAssertEqual([button backgroundImageForState:UIControlStateSelected].cyl_rawImage, self.nightImage);
    XCTAssertEqual([button imageForState:UIControlStateDisabled], plainImage, @"a plain image is left alone");
    XCTAssertEqual([button imageForState:UIControlStateHighlighted].cyl_rawImage, self.nightImage, @"a state without its own image follows normal");
}

- (void)testThemeEffectFollowsTheThemeInAnEffectView {
    UIVisualEffect *effect = [self themeEffect];
    XCTAssertTrue(effect.cyl_isThemeEffect);
    XCTAssertTrue([effect isKindOfClass:[UIBlurEffect class]], @"a real blur effect, usable anywhere a UIBlurEffect is");
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    self.manager.currentThemeIdentifier = @"night";
    [effectView cyl_themeDidChangeByManager:self.manager identifier:@"night" theme:@"night"];
    XCTAssertNotEqual(effectView.effect, effect, @"a new effect object, so the view redraws");
    XCTAssertTrue(effectView.effect.cyl_isThemeEffect);
    UIBlurEffect *darkEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    XCTAssertEqualObjects([NSKeyedArchiver archivedDataWithRootObject:effectView.effect requiringSecureCoding:YES error:nil],
                          [NSKeyedArchiver archivedDataWithRootObject:darkEffect requiringSecureCoding:YES error:nil]);
}

- (void)testLayerColorFollowsTheThemeWithoutHooks {
    UIView *view = [[UIView alloc] init];
    [view.layer cyl_setThemeColor:[self themeColor] forKey:@"borderColor"];
    CAShapeLayer *shape = [CAShapeLayer layer];
    [view.layer addSublayer:shape];
    [shape cyl_setThemeColor:[self themeColor] forKey:@"fillColor"];
    XCTAssertTrue(CGColorEqualToColor(view.layer.borderColor, UIColor.whiteColor.CGColor));
    self.manager.currentThemeIdentifier = @"night";
    [view cyl_themeDidChangeByManager:self.manager identifier:@"night" theme:@"night"];
    XCTAssertTrue(CGColorEqualToColor(view.layer.borderColor, UIColor.blackColor.CGColor), @"the layer's CGColor is set again");
    XCTAssertTrue(CGColorEqualToColor(shape.fillColor, UIColor.blackColor.CGColor), @"and its own sublayers' too");
    [view.layer cyl_setThemeColor:nil forKey:@"borderColor"];
    XCTAssertNil([view.layer cyl_themeColorForKey:@"borderColor"]);
    XCTAssertEqual(view.layer.borderColor, NULL);
}

- (void)testAViewOutOfEveryWindowIsStillReachedByAThemeChange {
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.image = [self themeImage];
    [imageView cyl_registerThemeColorProperties:@[ @"tintColor" ]];
    imageView.tintColor = [self themeColor];
    // [EN] Registering tracked the view: the manager reaches it although it is in no window. [CN] 注册后视图被记住：虽不在 window 中，管理器仍能到达。
    self.manager.currentThemeIdentifier = @"night";
    XCTAssertEqual(imageView.image.cyl_rawImage, self.nightImage);
    XCTAssertEqualObjects(imageView.tintColor.cyl_rawColor, UIColor.blackColor);
}

- (void)testBarAppearanceImagesAndEffectsFollowTheTheme {
    UITabBar *tabBar = [[UITabBar alloc] init];
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    appearance.backgroundImage = [self themeImage];
    appearance.backgroundEffect = (UIBlurEffect *)[self themeEffect];
    tabBar.standardAppearance = appearance;
    self.manager.currentThemeIdentifier = @"night";
    [tabBar cyl_themeDidChangeByManager:self.manager identifier:@"night" theme:@"night"];
    XCTAssertEqual(tabBar.standardAppearance.backgroundImage.cyl_rawImage, self.nightImage);
    XCTAssertTrue(tabBar.standardAppearance.backgroundEffect.cyl_isThemeEffect);
    XCTAssertNotEqual(tabBar.standardAppearance.backgroundEffect, appearance.backgroundEffect);
}

@end

#pragma mark - Themes and the animation components (#216 + #604)

// [EN] Declared here: `UIControl+CYLTabBarItemAnimation.h` and `CYLTabBarItemAnimationService.h` are project headers of the
//      framework, not public ones; the C functions are exported and the methods are dispatched by selector.
// [CN] 在此声明：`UIControl+CYLTabBarItemAnimation.h` 与 `CYLTabBarItemAnimationService.h` 是 framework 的工程头文件，不是公开头文件；
//      C 函数已导出，方法按 selector 分发。
FOUNDATION_EXTERN NSURL *_Nullable CYLTabBarItemAnimationURLFromAttributes(NSDictionary *_Nullable attributes, NSString *_Nullable __autoreleasing *_Nullable filePath);
FOUNDATION_EXTERN id CYLTabBarItemAnimationDefaultStyleSource(void);
FOUNDATION_EXTERN void CYLTabBarItemAnimationRegisterColors(NSURL *URL, NSDictionary<NSString *, UIColor *> *_Nullable colors);

@protocol CYLThemeTestStyleSource <NSObject>
- (BOOL)hasStyleVariantForURL:(nullable NSURL *)URL;
- (nullable NSDictionary<NSString *, UIColor *> *)colorsForURL:(nullable NSURL *)URL;
@end

/// [EN] A plus button as an app makes it: its stand-in comes from `+plusButton`. [CN] App 的 PlusButton：其替身来自 `+plusButton`。
@interface CYLTestPlusButton : CYLPlusButton <CYLPlusButtonSubclassing>
@end

/// [EN] Implemented in `CYLPlusButton.m`. [CN] 在 `CYLPlusButton.m` 中实现。
@interface CYLPlusButton (CYLThemeTestsPrivate)
- (void)cyl_setBackgroundImageDidChangeHandler:(nullable void (^)(void))handler;
@end

@implementation CYLTestPlusButton
+ (id)plusButton {
    return [self new];
}
@end

/*!
 * FIX: issue #605
 * [EN] A GIF given by an animation key plays once when asked; given as an image, it stays an animated image that loops.
 * [CN] 通过动画 key 传入的 GIF 在要求时播放一次；作为图片传入时仍是循环播放的动图。
 */
@interface CYLGIFAnimationTests : XCTestCase
@end

/// [EN] Private: what a new tab button from UIKit takes over from the old one (#605). [CN] 私有：UIKit 新建的 Tab 按钮从旧按钮接管的内容。
@interface CYLTabBarController (CYLReplacedTabButtonTesting)
- (void)cyl_adoptTabButton:(UIControl *)tabButton forTabBarItem:(nullable UITabBarItem *)item;
@end

@implementation CYLGIFAnimationTests

/// [EN] A GIF file of solid frames: red, green, blue, with these delays. [CN] 纯色帧组成的 GIF 文件：红、绿、蓝，时长如下。
- (NSURL *)gifFileURL {
    NSURL *URL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"cyl_gif_test.gif"]];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)URL, CFSTR("com.compuserve.gif"), 3, NULL);
    NSArray<UIColor *> *colors = @[ UIColor.redColor, UIColor.greenColor, UIColor.blueColor ];
    NSArray<NSNumber *> *delays = @[ @0.1, @0.2, @0.7 ];
    [colors enumerateObjectsUsingBlock:^(UIColor *color, NSUInteger index, BOOL *stop) {
        NSDictionary *properties = @{ (__bridge NSString *)kCGImagePropertyGIFDictionary : @{ (__bridge NSString *)kCGImagePropertyGIFDelayTime : delays[index] } };
        CGImageDestinationAddImage(destination, CYLTestImage(10, color).CGImage, (__bridge CFDictionaryRef)properties);
    }];
    XCTAssertTrue(CGImageDestinationFinalize(destination));
    CFRelease(destination);
    return URL;
}

- (void)testAGIFIsAnAnimationThatPlaysOnceAndEndsOnItsLastFrame {
    NSURL *URL = [self gifFileURL];
    id<CYLTabBarItemAnimator> animator = [CYLTabBarItemAnimatorRegistry animatorForURL:URL];
    XCTAssertEqualObjects(animator.identifier, @"GIF");
    UIImageView<CYLTabBarItemAnimationPlayableView> *view = (id)[animator animationViewWithURL:URL size:CGSizeMake(24, 24) contentMode:UIViewContentModeScaleAspectFit];
    XCTAssertTrue(CGSizeEqualToSize(view.bounds.size, CGSizeMake(24, 24)));
    UIImage *firstFrame = view.image;
    XCTAssertNotNil(firstFrame, @"a tab shows its first frame until it is selected");

    [view cyl_playAnimationView];
    CAKeyframeAnimation *animation = (CAKeyframeAnimation *)[view.layer animationForKey:view.layer.animationKeys.firstObject];
    XCTAssertEqual(animation.values.count, 3U);
    XCTAssertEqual(animation.repeatCount, 0.f, @"once, not a loop");
    XCTAssertEqualWithAccuracy(animation.duration, 1.0, 0.01);
    XCTAssertEqualWithAccuracy(animation.keyTimes[2].doubleValue, 0.3, 0.01, @"each frame keeps its own delay");
    XCTAssertNotEqual(view.image.CGImage, firstFrame.CGImage, @"the end state is the last frame");
    UIImage *lastFrame = view.image;

    [view cyl_stopAnimationView];
    XCTAssertNil(view.layer.animationKeys);
    XCTAssertEqual(view.image.CGImage, firstFrame.CGImage, @"stopping goes back to the first frame");

    [view cyl_showAnimationViewLastFrame];
    XCTAssertNil(view.layer.animationKeys, @"the tab selected at launch shows the last frame without playing");
    XCTAssertEqual(view.image.CGImage, lastFrame.CGImage);
}

- (void)testTheGIFKeysAreAliasesOfTheGenericKeys {
    NSURL *URL = [self gifFileURL];
    XCTAssertEqualObjects(CYLTabBarItemAnimationURLFromAttributes(@{ CYLTabBarGIFURL : URL }, NULL), URL);
    NSString *filePath = nil;
    XCTAssertEqualObjects(CYLTabBarItemAnimationURLFromAttributes(@{ CYLTabBarGIFFilePath : URL.path }, &filePath).path, URL.path);
    XCTAssertEqualObjects(filePath, URL.path);
}

- (void)testAGIFGivenAsAnImageStillLoops {
    UIImage *image = [UIImage cyl_animatedImageWithGIFData:[NSData dataWithContentsOfURL:[self gifFileURL]]];
    XCTAssertEqual(image.images.count, 3U);
    XCTAssertEqualWithAccuracy(image.duration, 1.0, 0.01);
}

/// FIX: issue #605 — the classic tab bar replaces a tab's button when its title changes (`self.title = …` in a page).
- (void)testANewTabButtonFromUIKitGetsItsTabsAnimationAgain {
    UIViewController *staticTab = [UIViewController new];
    UIViewController *animatedTab = [UIViewController new];
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ staticTab, animatedTab ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"A" },
                                                                                                    @{ CYLTabBarItemTitle : @"B", CYLTabBarGIFURL : [self gifFileURL] } ]];
    UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 390, 844)];
    window.rootViewController = tabBarController;
    window.hidden = NO;
    [window layoutIfNeeded];
    // [EN] Real tab buttons, standing in for the new ones from UIKit: an animation needs the button's own image view.
    // [CN] 用真实的 Tab 按钮代替 UIKit 新建的按钮：动画需要按钮自己的图片视图。
    UIControl *newButton = animatedTab.tabBarItem.cyl_tabButton;
    UIControl *newStaticButton = staticTab.tabBarItem.cyl_tabButton;
    if (!newButton || !newStaticButton) {
        window.hidden = YES;
        XCTSkip(@"no tab buttons in this tab bar style");
    }
    [newButton.cyl_tabBarItemAnimationView removeFromSuperview];
    [tabBarController setValue:@YES forKey:@"tabBarItemAnimationViewAdded"];

    [tabBarController cyl_adoptTabButton:newButton forTabBarItem:animatedTab.tabBarItem];
    UIView *animationView = newButton.cyl_tabBarItemAnimationView;
    XCTAssertNotNil(animationView, @"the new button shows the animation, not the static image");
    XCTAssertEqual(animatedTab.cyl_tabButton, newButton, @"the view controller's tab button is the new one");

    [tabBarController cyl_adoptTabButton:newButton forTabBarItem:animatedTab.tabBarItem];
    XCTAssertEqual(newButton.cyl_tabBarItemAnimationView, animationView, @"each layout pass adopts it again, without a second view");

    [tabBarController cyl_adoptTabButton:newStaticButton forTabBarItem:staticTab.tabBarItem];
    XCTAssertNil(newStaticButton.cyl_tabBarItemAnimationView, @"a tab without a file keeps its images");
    XCTAssertEqual(staticTab.cyl_tabButton, newStaticButton);
    window.hidden = YES;
}

- (void)testAFileThatIsNotAGIFMakesNoView {
    NSURL *URL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"cyl_missing.gif"]];
    [[NSFileManager defaultManager] removeItemAtURL:URL error:NULL];
    XCTAssertNil([[CYLTabBarItemAnimatorRegistry animatorForURL:URL] animationViewWithURL:URL size:CGSizeMake(24, 24) contentMode:UIViewContentModeScaleAspectFit]);
}

@end

@interface CYLThemeAnimationTests : XCTestCase
@end

@implementation CYLThemeAnimationTests

/// [EN] A file URL that needs no file on disk: the registries key by the URL only. [CN] 无需磁盘上存在的文件 URL：注册表只按 URL 作为 key。
- (NSURL *)animationURLNamed:(NSString *)name {
    return [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[name stringByAppendingPathExtension:@"json"]]];
}

- (void)testAnimationColorsOfTheAttributesAreRegisteredWithTheStyleSource {
    NSURL *URL = [self animationURLNamed:@"home"];
    UIColor *themeColor = [UIColor cyl_colorWithThemeProvider:^UIColor *(CYLThemeManager *manager, NSObject<NSCopying> *identifier, NSObject *theme) {
        return UIColor.systemRedColor;
    }];
    NSString *filePath = nil;
    NSURL *boundURL = CYLTabBarItemAnimationURLFromAttributes(@{ CYLTabBarAnimationURL : URL, CYLTabBarAnimationColors : @{ @"**.Fill 1.Color" : themeColor, @"" : UIColor.blackColor, @"bad" : @1 } }, &filePath);
    XCTAssertEqualObjects(boundURL, URL);
    id<CYLThemeTestStyleSource> styleSource = CYLTabBarItemAnimationDefaultStyleSource();
    XCTAssertTrue([styleSource respondsToSelector:@selector(colorsForURL:)]);
    NSDictionary<NSString *, UIColor *> *colors = [styleSource colorsForURL:URL];
    XCTAssertEqualObjects(colors.allKeys, @[ @"**.Fill 1.Color" ], @"only keypath -> UIColor pairs are kept");
    XCTAssertTrue(colors[@"**.Fill 1.Color"].cyl_isThemeColor, @"the theme color itself is kept, so a theme change can resolve it again");
    XCTAssertTrue([styleSource hasStyleVariantForURL:URL], @"colors count as a style variant, so the view remembers its source URL");
    CYLTabBarItemAnimationRegisterColors(URL, nil);
    XCTAssertNil([styleSource colorsForURL:URL]);
}

- (void)testAnInPlaceUpdateWithAnAnimationKeyGivesTheTabTheNewFile {
    XCTSkipIf(NSClassFromString(@"CYLLottieTabBarItemAnimator") == nil, @"needs an animation library (the Lottie subspec) in the test host");
    NSURL *oldURL = [self animationURLNamed:@"old"];
    NSURL *newURL = [self animationURLNamed:@"new"];
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ [UIViewController new], [UIViewController new] ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"A", CYLTabBarAnimationURL : oldURL, CYLTabBarAnimationSize : [NSValue valueWithCGSize:CGSizeMake(30, 30)] },
                                                                                                    @{ CYLTabBarItemTitle : @"B" } ]];
    [tabBarController loadViewIfNeeded];
    XCTAssertEqualObjects(tabBarController.viewControllers[0].tabBarItem.cyl_tabBarItemAnimationURL, oldURL);
    XCTAssertEqualObjects(tabBarController.tabBarItemAnimationURLs, @[ oldURL ]);

    // [EN] What a `CYLTabBarTheme` returns for a holiday skin with its own animation. [CN] 节日皮肤带自己动画时 `CYLTabBarTheme` 返回的内容。
    [tabBarController updateTabBarItemsWithAttributes:@[ @{ CYLTabBarAnimationURL : newURL }, @{} ]];
    XCTAssertEqualObjects(tabBarController.viewControllers[0].tabBarItem.cyl_tabBarItemAnimationURL, newURL, @"the tab item plays the new file from now on");
    XCTAssertEqualObjects(tabBarController.tabBarItemAnimationURLs, @[ newURL ], @"replaced in place, not appended");
    XCTAssertEqualObjects(tabBarController.tabBarItemsAttributes[0][CYLTabBarAnimationURL], newURL);
    XCTAssertNil(tabBarController.viewControllers[1].tabBarItem.cyl_tabBarItemAnimationURL, @"a tab without an animation key is left alone");
}

/*!
 * FIX: issue #216
 * [EN] With a plus button, Liquid Glass and FlatDesign keep a slot entry in `tabBarItemsAttributes`, and a theme saves that
 *      array to restore it later. The entry must not take a tab's place: "Moments" used to land on "Me".
 * [CN] 有 PlusButton 时，液态玻璃与扁平样式在 `tabBarItemsAttributes` 中保留一个 slot 项，而主题会保存该数组以便之后恢复。该项不能占用
 *      Tab 的位置：以前「Moments」会落到「Me」上。
 */
- (void)testASlotEntryInTheAttributesDoesNotShiftTheTabs {
    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ [UIViewController new], [UIViewController new] ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"A" }, @{ CYLTabBarItemTitle : @"B" } ]];
    [tabBarController loadViewIfNeeded];
    [tabBarController updateTabBarItemsWithAttributes:@[ @{ CYLTabBarItemTitle : @"Home" },
                                                         @{ @"CYLTabBarItemPlusSlotPlaceholder" : @YES },
                                                         @{ CYLTabBarItemTitle : @"Moments" } ]];
    XCTAssertEqualObjects(tabBarController.viewControllers[0].tabBarItem.title, @"Home");
    XCTAssertEqualObjects(tabBarController.viewControllers[1].tabBarItem.title, @"Moments", @"the slot entry takes no tab's place");
}

/*!
 * FIX: issue #216
 * [EN] Outside Liquid Glass with a plus child, a plus button keeps its selected image: only there does the stand-in use
 *      one picture (checked on a simulator by scripts/plus-child-theme-test.sh).
 * [CN] 不是液态玻璃且有 PlusButton 子控制器的场景时，PlusButton 保留其选中图片：只有该场景的替身才只用一张图片（由
 *      scripts/plus-child-theme-test.sh 在模拟器上检查）。
 */
- (void)testABackgroundImageRunsTheHandlerUntilItIsRemoved {
    CYLTestPlusButton *plusButton = [CYLTestPlusButton new];
    __block NSInteger runs = 0;
    [plusButton cyl_setBackgroundImageDidChangeHandler:^{ runs += 1; }];
    [plusButton setBackgroundImage:CYLTestImage(10, UIColor.redColor) forState:UIControlStateNormal];
    XCTAssertEqual(runs, 1);
    [plusButton setBackgroundImage:CYLTestImage(10, UIColor.blueColor) forState:UIControlStateSelected];
    [plusButton setBackgroundImage:nil forState:UIControlStateNormal];
    XCTAssertEqual(runs, 1, @"only a new background image of the normal state");
    [plusButton cyl_setBackgroundImageDidChangeHandler:nil];
    [plusButton setBackgroundImage:CYLTestImage(10, UIColor.redColor) forState:UIControlStateNormal];
    XCTAssertEqual(runs, 1);
}

- (void)testAPlusButtonOutsideAGlassPlusChildKeepsItsSelectedImage {
    UIImage *normal = CYLTestImage(10, UIColor.redColor);
    UIImage *selected = CYLTestImage(10, UIColor.blueColor);
    CYLTestPlusButton *plusButton = [CYLTestPlusButton new];
    [plusButton setImage:normal forState:UIControlStateNormal];
    [plusButton setImage:selected forState:UIControlStateSelected];
    XCTAssertEqual([plusButton imageForState:UIControlStateNormal].CGImage, normal.CGImage);
    XCTAssertEqual([plusButton imageForState:UIControlStateSelected].CGImage, selected.CGImage);
    UIImage *themed = CYLTestImage(10, UIColor.greenColor);
    [plusButton cyl_updateTitle:nil image:themed selectedImage:selected];
    XCTAssertEqual([plusButton imageForState:UIControlStateNormal].CGImage, themed.CGImage);
    XCTAssertEqual([plusButton imageForState:UIControlStateSelected].CGImage, selected.CGImage);
}

/*!
 * FIX: issue #216
 * [EN] A plus button with no image of its own loses a theme's image when the theme goes, on its stand-in too.
 * [CN] 原本没有图片的 PlusButton 在主题结束时失去主题图片，替身也一样。
 */
- (void)testRemovingTheImageOfAPlusButtonClearsItAndItsStandIn {
    CYLTestPlusButton *plusButton = [CYLTestPlusButton new];
    UIButton *standIn = plusButton.selectedContentView;
    UIImage *themed = CYLTestImage(10, UIColor.greenColor);
    [plusButton cyl_updateTitle:nil image:themed selectedImage:themed];
    XCTAssertEqual([plusButton imageForState:UIControlStateNormal].CGImage, themed.CGImage);
    SEL removeImage = NSSelectorFromString(@"cyl_removeImage");
    XCTAssertTrue([plusButton respondsToSelector:removeImage]);
    ((void (*)(id, SEL))[plusButton methodForSelector:removeImage])(plusButton, removeImage);
    for (NSNumber *state in @[ @(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateSelected) ]) {
        XCTAssertNil([plusButton imageForState:state.unsignedIntegerValue], @"plus button, state %@", state);
        XCTAssertNil([standIn imageForState:state.unsignedIntegerValue], @"stand-in, state %@", state);
    }
}

- (void)testTheTabBarFollowsAnInjectedThemeManager {
    CYLThemeManager *manager = [CYLThemeManagerCenter themeManagerWithName:@"CYLThemeAnimationTests.tabBar"];
    for (NSObject<NSCopying> *identifier in [manager.themeIdentifiers copy]) {
        [manager removeThemeIdentifier:identifier];
    }
    CYLTestTabBarTheme *pink = [CYLTestTabBarTheme new];
    pink.barColor = UIColor.systemPinkColor;
    [manager addThemeIdentifier:@"plain" theme:@"plain"];
    [manager addThemeIdentifier:@"pink" theme:pink];
    manager.currentThemeIdentifier = @"plain";

    CYLTabBarController *tabBarController = [[CYLTabBarController alloc] initWithViewControllers:@[ [UIViewController new] ]
                                                                           tabBarItemsAttributes:@[ @{ CYLTabBarItemTitle : @"A" } ]];
    XCTAssertEqual(tabBarController.cyl_themeManager, CYLThemeManagerCenter.defaultThemeManager, @"the default manager unless set");
    tabBarController.cyl_themeManager = manager;
    [tabBarController loadViewIfNeeded];
    UIColor *originalColor = tabBarController.tabBar.standardAppearance.backgroundColor;

    [tabBarController cyl_themeDidChangeByManager:manager identifier:@"pink" theme:pink];
    XCTAssertEqualObjects(tabBarController.tabBar.standardAppearance.backgroundColor, UIColor.systemPinkColor);
    // [EN] A plain theme of the tab bar's own manager gives the app's look back; the default manager is not the tab bar's any more.
    // [CN] TabBar 自己管理器的普通主题恢复 App 外观；默认管理器不再是 TabBar 的管理器。
    [tabBarController cyl_themeDidChangeByManager:manager identifier:@"plain" theme:@"plain"];
    XCTAssertEqualObjects(tabBarController.tabBar.standardAppearance.backgroundColor, originalColor);
    [tabBarController cyl_themeDidChangeByManager:CYLThemeManagerCenter.defaultThemeManager identifier:@"x" theme:@"x"];
    XCTAssertEqualObjects(tabBarController.tabBar.standardAppearance.backgroundColor, originalColor, @"a plain theme of another manager changes nothing");
    tabBarController.cyl_themeManager = nil;
    XCTAssertEqual(tabBarController.cyl_themeManager, CYLThemeManagerCenter.defaultThemeManager, @"nil resets to the default");
}

@end
