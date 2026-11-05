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

#pragma mark - Theme images, effects and layer colors (QMUI gap)

/// [EN] Two 1 × 1 images that tell themselves apart by their tint. [CN] 两张以 tint 区分的 1 × 1 图片。
static UIImage *CYLTestImage(UIColor *color) {
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
    self.dayImage = CYLTestImage(UIColor.whiteColor);
    self.nightImage = CYLTestImage(UIColor.blackColor);
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
    UIImage *plainImage = CYLTestImage(UIColor.redColor);
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
