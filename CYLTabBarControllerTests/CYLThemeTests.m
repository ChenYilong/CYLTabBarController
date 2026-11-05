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

/// [EN] A tab bar theme with a title and an icon for each tab (below). [CN] 每个 Tab 都有标题与图标的 TabBar 主题（见下方）。
@interface CYLTestItemsTabBarTheme : NSObject <CYLTabBarTheme>
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

- (void)testThemeImageFollowsTheThemeAndNeverMarksTheProvidersImage {
    CYLThemeManager *manager = [self newImageManager];
    UIImage *image = [self themeImageOfManager:manager];
    XCTAssertTrue(image.cyl_isThemeImage);
    XCTAssertEqual(image.size.width, 10.0);
    XCTAssertFalse(((UIImage *)manager.currentTheme).cyl_isThemeImage, @"the provider's image (maybe shared) is not marked");
    XCTAssertNotEqual(image, manager.currentTheme);

    manager.currentThemeIdentifier = @"B";
    UIImage *current = [image cyl_imageForCurrentTheme];
    XCTAssertTrue(current.cyl_isThemeImage);
    XCTAssertEqual(current.size.width, 20.0);
    UIImage *plain = CYLTestImage(5, UIColor.greenColor);
    XCTAssertFalse(plain.cyl_isThemeImage);
    XCTAssertEqual([plain cyl_imageForCurrentTheme], plain);
}

- (void)testImageViewAndButtonGetTheNewThemeImage {
    CYLThemeManager *manager = [self newImageManager];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[self themeImageOfManager:manager]];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setImage:[self themeImageOfManager:manager] forState:UIControlStateNormal];
    [button setBackgroundImage:[self themeImageOfManager:manager] forState:UIControlStateSelected];
    UIImage *setImage = [self themeImageOfManager:manager];
    UIButton *probe = [UIButton buttonWithType:UIButtonTypeCustom];
    [probe setImage:setImage forState:UIControlStateNormal];
    UIImage *storedImage = [probe imageForState:UIControlStateNormal];
    NSLog(@"[CYLThemeTests] UIButton stores %@ (%p, theme image: %d) for %@ (%p, rendering mode %ld)",
          storedImage, storedImage, storedImage.cyl_isThemeImage, setImage, setImage, (long)setImage.renderingMode);
    XCTAssertTrue([button imageForState:UIControlStateNormal].cyl_isThemeImage, @"UIButton keeps the theme image object");

    manager.currentThemeIdentifier = @"B";
    [imageView cyl_themeDidChangeByManager:manager identifier:manager.currentThemeIdentifier theme:manager.currentTheme];
    [button cyl_themeDidChangeByManager:manager identifier:manager.currentThemeIdentifier theme:manager.currentTheme];
    XCTAssertEqual(imageView.image.size.width, 20.0);
    XCTAssertEqual([button imageForState:UIControlStateNormal].size.width, 20.0);
    XCTAssertEqual([button backgroundImageForState:UIControlStateSelected].size.width, 20.0);
    XCTAssertEqual([button imageForState:UIControlStateHighlighted], [button imageForState:UIControlStateNormal],
                   @"a state without an image of its own still falls back to the normal one");
}

- (void)testVisualEffectViewGetsTheNewThemeEffect {
    CYLThemeManager *manager = [self newManager];
    [manager addThemeIdentifier:@"Light" theme:@(UIBlurEffectStyleLight)];
    [manager addThemeIdentifier:@"Dark" theme:@(UIBlurEffectStyleDark)];
    manager.currentThemeIdentifier = @"Light";
    UIVisualEffect *effect = [UIVisualEffect cyl_effectWithThemeManagerName:manager.name provider:^UIVisualEffect *(CYLThemeManager *themeManager, id identifier, NSNumber *theme) {
        return [UIBlurEffect effectWithStyle:(UIBlurEffectStyle)theme.integerValue];
    }];
    XCTAssertTrue(effect.cyl_isThemeEffect);
    XCTAssertTrue([effect isKindOfClass:[UIBlurEffect class]]);
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    XCTAssertTrue(effectView.effect.cyl_isThemeEffect, @"the effect view keeps the theme effect");

    UIVisualEffect *before = effectView.effect;
    manager.currentThemeIdentifier = @"Dark";
    [effectView cyl_themeDidChangeByManager:manager identifier:manager.currentThemeIdentifier theme:manager.currentTheme];
    XCTAssertNotEqual(effectView.effect, before);
    XCTAssertTrue(effectView.effect.cyl_isThemeEffect);
}

- (void)testLayerThemeColorFollowsTheThemeWithSublayers {
    CYLThemeManager *manager = [self newManager];
    [manager addThemeIdentifier:@"Red" theme:UIColor.redColor];
    [manager addThemeIdentifier:@"Blue" theme:UIColor.blueColor];
    manager.currentThemeIdentifier = @"Red";
    UIColor *color = [UIColor cyl_colorWithThemeManagerName:manager.name provider:^UIColor *(CYLThemeManager *themeManager, id identifier, UIColor *theme) {
        return theme;
    }];
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
    view.layer.cyl_themeBorderColor = color;
    CAShapeLayer *sublayer = [CAShapeLayer layer];
    [view.layer addSublayer:sublayer];
    [sublayer cyl_setThemeColor:color forKeyPath:@"fillColor"];
    XCTAssertTrue(CGColorEqualToColor(view.layer.borderColor, UIColor.redColor.CGColor));
    XCTAssertTrue(CGColorEqualToColor(sublayer.fillColor, UIColor.redColor.CGColor));
    XCTAssertEqualObjects([sublayer cyl_themeColorForKeyPath:@"fillColor"], color);

    manager.currentThemeIdentifier = @"Blue";
    [view cyl_themeDidChangeByManager:manager identifier:manager.currentThemeIdentifier theme:manager.currentTheme];
    XCTAssertTrue(CGColorEqualToColor(view.layer.borderColor, UIColor.blueColor.CGColor));
    XCTAssertTrue(CGColorEqualToColor(sublayer.fillColor, UIColor.blueColor.CGColor), @"sublayers follow too");

    [sublayer cyl_setThemeColor:nil forKeyPath:@"fillColor"];
    XCTAssertNil([sublayer cyl_themeColorForKeyPath:@"fillColor"]);
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

@end

@implementation CYLTestItemsTabBarTheme

- (NSArray<NSDictionary<NSString *, id> *> *)cyl_tabBarItemsAttributesForTabBarController:(CYLTabBarController *)tabBarController {
    return @[ @{ CYLTabBarItemTitle : @"★ A", CYLTabBarItemImage : CYLTestImage(24, UIColor.orangeColor) },
              @{ CYLTabBarItemTitle : @"★ B", CYLTabBarItemImage : CYLTestImage(24, UIColor.purpleColor) } ];
}

@end
