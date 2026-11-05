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
