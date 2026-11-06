//
//  UIViewController+CYLThemeSettings.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIViewController+CYLThemeSettings.h"
#import "CYLTabBarController.h"

NS_ASSUME_NONNULL_BEGIN

static NSString *const CYLThemeSettingsCellIdentifier = @"CYLThemeSettingsCell";
/// [EN] Where the demo keeps the chosen theme and the Dark Mode switch. [CN] 演示保存所选主题与深色模式开关的位置。
static NSString *const CYLDemoThemeIdentifierDefaultsKey = @"CYLDemoThemeIdentifier";
static NSString *const CYLDemoThemeFollowsSystemDefaultsKey = @"CYLDemoThemeFollowsSystem";

/// [EN] The identifiers of the demo themes. [CN] 演示主题的 identifier。
static NSString *const CYLDemoThemeIdentifierDefault = @"Default";
static NSString *const CYLDemoThemeIdentifierGrapefruit = @"Grapefruit";
static NSString *const CYLDemoThemeIdentifierGrass = @"Grass";
static NSString *const CYLDemoThemeIdentifierPinkRose = @"Pink Rose";
static NSString *const CYLDemoThemeIdentifierDark = @"Dark";
static NSString *const CYLDemoThemeIdentifierSpringFestival = @"Spring Festival";
static NSString *const CYLDemoThemeIdentifierChristmas = @"Christmas";
static NSString *const CYLDemoThemeIdentifierHalloween = @"Halloween";
static NSString *const CYLDemoThemeIdentifierValentine = @"Valentine's Day";
static NSString *const CYLDemoThemeIdentifierMidAutumn = @"Mid-Autumn";
static NSString *const CYLDemoThemeIdentifierEaster = @"Easter";
static NSString *const CYLDemoThemeIdentifierNewYear = @"New Year";
static NSString *const CYLDemoThemeIdentifierSummer = @"Summer";
static NSString *const CYLDemoThemeIdentifierBirthday = @"Birthday";
static NSString *const CYLDemoThemeIdentifierSpace = @"Space";
static NSString *const CYLDemoThemeIdentifierOcean = @"Ocean";
static NSString *const CYLDemoThemeIdentifierNetwork = @"Network";

static UIColor *CYLDemoRGB(CGFloat red, CGFloat green, CGFloat blue) {
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1];
}

/*!
 * [EN] A demo theme: its colors and, for a holiday skin, its icons. The icons are Fluent Emoji (MIT License, Microsoft;
 *      see `cyl_theme_icons_LICENSE.txt` in the resource bundle), named `cyl_theme_<name>` in the library's resource
 *      bundle. "Default" changes nothing, so the tab bar shows the app's own look again.
 * [CN] 演示主题：主题颜色；节日皮肤还带有自己的图标。图标为 Fluent Emoji（MIT 许可证，Microsoft；见资源包中的
 *      `cyl_theme_icons_LICENSE.txt`），在本库资源包中命名为 `cyl_theme_<名字>`。“默认”不做任何修改，TabBar 恢复 App 自己的外观。
 */
@interface CYLDemoTheme : NSObject <CYLTabBarTheme>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong, nullable) UIColor *tintColor;
@property (nonatomic, strong, nullable) UIColor *barColor;
@property (nonatomic, strong, nullable) UIColor *normalColor;
/// [EN] The icon names of a holiday skin, used in turn for the tabs; nil for a color theme. [CN] 节日皮肤的图标名，依次用于各 Tab；配色主题为 nil。
@property (nonatomic, copy, nullable) NSArray<NSString *> *iconNames;
/// [EN] The network skin: the URLs of each tab's icons (unselected, selected), used in turn; nil for the other themes.
/// [CN] 网络皮肤：每个 Tab 图标的 URL（未选中、选中），依次使用；其他主题为 nil。
@property (nonatomic, copy, nullable) NSArray<NSArray<NSString *> *> *iconURLs;
/// [EN] The network skin: the URLs of the plus button's images (normal, selected). [CN] 网络皮肤：PlusButton 图片的 URL（普通、选中）。
@property (nonatomic, copy, nullable) NSArray<NSString *> *plusButtonIconURLs;
/// [EN] The network skin: put before every tab title, e.g. "★". [CN] 网络皮肤：加在每个 Tab 标题前，例如“★”。
@property (nonatomic, copy, nullable) NSString *titlePrefix;
@end

@implementation CYLDemoTheme

+ (instancetype)themeWithIdentifier:(NSString *)identifier tintColor:(nullable UIColor *)tintColor barColor:(nullable UIColor *)barColor normalColor:(nullable UIColor *)normalColor {
    CYLDemoTheme *theme = [[self alloc] init];
    theme.identifier = identifier;
    theme.tintColor = tintColor;
    theme.barColor = barColor;
    theme.normalColor = normalColor;
    return theme;
}

/// [EN] The name shown in the picker, in the app's language. [CN] 选择器中显示的名字，使用 App 语言。
- (NSString *)localizedName {
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierGrapefruit]) {
        return CYLLocalizedString(@"西柚");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierGrass]) {
        return CYLLocalizedString(@"青草");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierPinkRose]) {
        return CYLLocalizedString(@"玫瑰粉");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierDark]) {
        return CYLLocalizedString(@"深色");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierSpringFestival]) {
        return CYLLocalizedString(@"春节");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierChristmas]) {
        return CYLLocalizedString(@"圣诞节");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierHalloween]) {
        return CYLLocalizedString(@"万圣节");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierValentine]) {
        return CYLLocalizedString(@"情人节");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierMidAutumn]) {
        return CYLLocalizedString(@"中秋节");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierEaster]) {
        return CYLLocalizedString(@"复活节");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierNewYear]) {
        return CYLLocalizedString(@"新年");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierSummer]) {
        return CYLLocalizedString(@"夏日");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierBirthday]) {
        return CYLLocalizedString(@"生日");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierSpace]) {
        return CYLLocalizedString(@"太空");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierOcean]) {
        return CYLLocalizedString(@"海洋");
    }
    if ([self.identifier isEqualToString:CYLDemoThemeIdentifierNetwork]) {
        return CYLLocalizedString(@"网络图标");
    }
    return CYLLocalizedString(@"默认");
}

#pragma mark - CYLTabBarTheme

/*!
 * [EN] The attributes of each real tab, in order, as `CYLTabBarTheme` expects them: one entry per tab, none for the plus
 *      button's page (some apps give it an entry in `tabBarItemsAttributes`) or a placeholder.
 * [CN] 每个真实 Tab 的 attributes，按顺序，符合 `CYLTabBarTheme` 的要求：每个 Tab 一项，PlusButton 的页面（有些 App 会在
 *      `tabBarItemsAttributes` 中为它提供一项）与占位控制器不占项。
 */
static NSArray<NSDictionary *> *CYLDemoRealTabsAttributes(CYLTabBarController *tabBarController) {
    // [EN] The tabs without the plus button's slot, as the library counts them (a plus child inside a navigation
    //      controller, a placeholder). [CN] 去掉 PlusButton slot 的 Tab，与本库的判断一致（包括被导航控制器包裹的 PlusButton 子控制器、占位控制器）。
    NSArray<UIViewController *> *viewControllers = tabBarController.viewControllers;
    NSMutableArray<NSDictionary *> *attributes = [NSMutableArray array];
    for (UIViewController *viewController in tabBarController.cyl_viewControllersIgnoringPlusButton) {
        NSUInteger index = [viewControllers indexOfObject:viewController];
        [attributes addObject:(index == NSNotFound ? nil : [tabBarController tabBarItemAttributesAtIndex:index]) ?: @{}];
    }
    return attributes;
}

/// [EN] A theme icon from the library's resource bundle, in its own colors. [CN] 本库资源包中的主题图标，保持原色。
- (nullable UIImage *)iconNamed:(NSString *)iconName {
    UIImage *image = [UIImage imageNamed:[@"cyl_theme_" stringByAppendingString:iconName] inBundle:CYLResourceBundle() compatibleWithTraitCollection:nil];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

/// [EN] The first icon, for the theme list. [CN] 第一个图标，用于主题列表。
- (nullable UIImage *)previewIcon {
    if (self.iconURLs.count > 0) {
        if (@available(iOS 13.0, *)) {
            return [[UIImage systemImageNamed:@"icloud.and.arrow.down"] imageWithTintColor:(self.tintColor ?: UIColor.systemBlueColor)
                                                                               renderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        return nil;
    }
    return self.iconNames.count > 0 ? [self iconNamed:self.iconNames[0]] : nil;
}

/// [EN] What the theme changes, for the theme list. [CN] 主题修改的内容，用于主题列表。
- (NSString *)localizedSummary {
    if (self.iconURLs.count > 0) {
        return CYLLocalizedString(@"网络图标、标题与配色");
    }
    return self.iconNames.count > 0 ? CYLLocalizedString(@"节日图标与配色") : CYLLocalizedString(@"仅配色");
}

/*!
 * [EN] `image` drawn at 45% opacity: the unselected look of a full color icon, which the item colors cannot tint.
 * [CN] 以 45% 不透明度绘制的 `image`：全彩图标的未选中样式（item 颜色无法为其着色）。
 */
static UIImage *CYLDemoFadedImage(UIImage *image) {
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = image.scale;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:image.size format:format];
    UIImage *faded = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [image drawAtPoint:CGPointZero blendMode:kCGBlendModeNormal alpha:0.45];
    }];
    return [faded imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

#pragma mark - CYLTabBarTheme

/*!
 * [EN] A holiday skin: its icons, in turn, on every tab (selected: full color; unselected: faded). A color theme, or
 *      icons that cannot be loaded, return nil: the app's own icons.
 * [CN] 节日皮肤：依次为每个 Tab 设置其图标（选中：全彩；未选中：半透明）。配色主题或图标无法加载时返回 nil：使用 App 自己的图标。
 */
- (nullable NSArray<NSDictionary<NSString *, id> *> *)cyl_tabBarItemsAttributesForTabBarController:(CYLTabBarController *)tabBarController {
    if (self.iconURLs.count > 0) {
        return [self networkItemsAttributesForTabBarController:tabBarController];
    }
    if (self.iconNames.count == 0) {
        return nil;
    }
    NSMutableArray<NSDictionary<NSString *, id> *> *itemsAttributes = [NSMutableArray array];
    NSUInteger count = CYLDemoRealTabsAttributes(tabBarController).count;
    for (NSUInteger index = 0; index < count; index++) {
        UIImage *selectedImage = [self iconNamed:self.iconNames[index % self.iconNames.count]];
        if (!selectedImage) {
            return nil;
        }
        [itemsAttributes addObject:@{ CYLTabBarItemImage : CYLDemoFadedImage(selectedImage), CYLTabBarItemSelectedImage : selectedImage }];
    }
    return itemsAttributes;
}

/*!
 * [EN] The network skin, as the "change tab title" and "change all network icons" demo rows: every tab's title with the
 *      prefix (`CYLTabBarItemTitle`), and its icons downloaded from the network (`CYLTabBarItemImageURL`,
 *      `CYLTabBarItemSelectedImageURL`, `CYLTabBarItemImageURLSize`), cached after the first time. Until the images are
 *      ready, the tab keeps the icon it shows.
 * [CN] 网络皮肤，与演示中“更换 Tab 标题”“批量下载网络图标”行相同：每个 Tab 的标题加上前缀（`CYLTabBarItemTitle`），图标从网络下载
 *      （`CYLTabBarItemImageURL`、`CYLTabBarItemSelectedImageURL`、`CYLTabBarItemImageURLSize`），第一次之后读取缓存。图片就绪前，
 *      Tab 保持当前显示的图标。
 */
- (NSArray<NSDictionary<NSString *, id> *> *)networkItemsAttributesForTabBarController:(CYLTabBarController *)tabBarController {
    NSMutableArray<NSDictionary<NSString *, id> *> *itemsAttributes = [NSMutableArray array];
    NSArray<NSDictionary *> *currentAttributes = CYLDemoRealTabsAttributes(tabBarController);
    NSString *prefix = [NSString stringWithFormat:@"%@ ", self.titlePrefix ?: @""];
    for (NSUInteger index = 0; index < currentAttributes.count; index++) {
        NSArray<NSString *> *URLs = self.iconURLs[index % self.iconURLs.count];
        NSMutableDictionary<NSString *, id> *attributes = [NSMutableDictionary dictionary];
        attributes[CYLTabBarItemImageURL] = URLs.firstObject;
        attributes[CYLTabBarItemSelectedImageURL] = URLs.lastObject;
        attributes[CYLTabBarItemImageURLSize] = [NSValue valueWithCGSize:CGSizeMake(24, 24)];
        // [EN] The title without a prefix added before (the tab bar remembers the titles a theme set).
        // [CN] 去掉之前加上的前缀（TabBar 会记录主题设置过的标题）。
        NSString *title = currentAttributes[index][CYLTabBarItemTitle];
        if ([title isKindOfClass:[NSString class]] && title.length > 0) {
            while (self.titlePrefix.length > 0 && [title hasPrefix:prefix]) {
                title = [title substringFromIndex:prefix.length];
            }
            attributes[CYLTabBarItemTitle] = [prefix stringByAppendingString:title];
        }
        [itemsAttributes addObject:[attributes copy]];
    }
    return itemsAttributes;
}

/*!
 * [EN] The plus button in this theme (`-updatePlusButtonWithAttributes:`): a holiday skin puts its last icon on it, the
 *      network skin downloads its images; a color theme leaves it alone.
 * [CN] 该主题下的 PlusButton（`-updatePlusButtonWithAttributes:`）：节日皮肤使用其最后一个图标，网络皮肤从网络下载图片；配色主题不修改。
 */
- (nullable NSDictionary<NSString *, id> *)cyl_plusButtonAttributesForTabBarController:(CYLTabBarController *)tabBarController {
    if (self.plusButtonIconURLs.count > 0) {
        return @{ CYLTabBarItemImageURL : self.plusButtonIconURLs.firstObject,
                  CYLTabBarItemSelectedImageURL : self.plusButtonIconURLs.lastObject };
    }
    UIImage *icon = self.iconNames.count > 0 ? [self iconNamed:self.iconNames.lastObject] : nil;
    if (!icon) {
        return nil;
    }
    return @{ CYLTabBarItemImage : icon, CYLTabBarItemSelectedImage : icon };
}

- (nullable UITabBarAppearance *)cyl_tabBarAppearanceForTabBarController:(CYLTabBarController *)tabBarController API_AVAILABLE(ios(13.0)) {
    if (!self.tintColor) {
        return nil;
    }
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    if (self.barColor) {
        appearance.backgroundColor = self.barColor;
    }
    UIColor *normalColor = self.normalColor ?: [UIColor systemGrayColor];
    for (UITabBarItemAppearance *itemAppearance in @[ appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance ]) {
        itemAppearance.normal.iconColor = normalColor;
        itemAppearance.normal.titleTextAttributes = @{ NSForegroundColorAttributeName : normalColor };
        itemAppearance.selected.iconColor = self.tintColor;
        itemAppearance.selected.titleTextAttributes = @{ NSForegroundColorAttributeName : self.tintColor };
        itemAppearance.normal.badgeBackgroundColor = self.tintColor;
    }
    return appearance;
}

/*!
 * [EN] The rest of the skin: the tint of every page (navigation bar buttons, switches...), nil for Default; before iOS 13,
 *      the tab bar colors themselves.
 * [CN] 皮肤的其余部分：所有页面的 tint（导航栏按钮、开关等），默认主题为 nil；iOS 13 以前直接设置 TabBar 颜色。
 */
- (void)cyl_customizeTabBarController:(CYLTabBarController *)tabBarController {
    // [EN] Default undoes only what a skin set, so the app's own colors stay at launch.
    // [CN] “默认”只撤销皮肤设置过的内容，因此启动时保留 App 自己的颜色。
    static BOOL skinColorsSet = NO;
    if (!self.tintColor && !skinColorsSet) {
        return;
    }
    skinColorsSet = (self.tintColor != nil);
    tabBarController.view.tintColor = self.tintColor;
    if (@available(iOS 13.0, *)) {
        return;
    }
    tabBarController.tabBar.tintColor = self.tintColor;
    tabBarController.tabBar.barTintColor = self.barColor;
    tabBarController.tabBar.unselectedItemTintColor = self.normalColor;
}

@end

#pragma mark - Settings

/// [EN] A holiday skin. [CN] 节日皮肤。
static CYLDemoTheme *CYLDemoHolidayTheme(NSString *identifier, UIColor *tintColor, UIColor *barColor, UIColor *normalColor, NSArray<NSString *> *iconNames) {
    CYLDemoTheme *theme = [CYLDemoTheme themeWithIdentifier:identifier tintColor:tintColor barColor:barColor normalColor:normalColor];
    theme.iconNames = iconNames;
    return theme;
}

/*!
 * [EN] The network skin: everything a theme can change at once. Each tab's title gets a "★" prefix, its icons and the
 *      plus button's come from the network (the URLs of the "download network icon" demo rows), and the colors change.
 * [CN] 网络皮肤：一次展示主题可以修改的所有内容。每个 Tab 的标题加上“★”前缀，Tab 图标与 PlusButton 图片来自网络（与演示中“下载网络图标”
 *      行相同的 URL），并修改配色。
 */
static CYLDemoTheme *CYLDemoNetworkTheme(void) {
    CYLDemoTheme *theme = [CYLDemoTheme themeWithIdentifier:CYLDemoThemeIdentifierNetwork tintColor:CYLDemoRGB(0, 122, 255)
                                                   barColor:CYLDemoRGB(242, 247, 255) normalColor:CYLDemoRGB(120, 134, 156)];
    theme.titlePrefix = @"★";
    theme.iconURLs = @[
        @[ @"https://cdn-icons-png.flaticon.com/512/1946/1946488.png", @"https://cdn-icons-png.flaticon.com/512/1946/1946436.png" ],
        @[ @"https://cdn-icons-png.flaticon.com/512/2099/2099085.png", @"https://cdn-icons-png.flaticon.com/512/2099/2099085.png" ],
        @[ @"https://cdn-icons-png.flaticon.com/512/2099/2099100.png", @"https://cdn-icons-png.flaticon.com/512/2099/2099100.png" ],
        @[ @"https://cdn-icons-png.flaticon.com/512/1077/1077063.png", @"https://cdn-icons-png.flaticon.com/512/1077/1077114.png" ],
    ];
    theme.plusButtonIconURLs = @[ @"https://cdn-icons-png.flaticon.com/512/992/992651.png", @"https://cdn-icons-png.flaticon.com/512/1828/1828817.png" ];
    return theme;
}

/// [EN] The demo themes, in the picker's order: five color themes, eleven holiday skins, then the network skin. [CN] 演示主题，按选择器中的顺序：五个配色主题、十一个节日皮肤，然后是网络皮肤。
static NSArray<CYLDemoTheme *> *CYLDemoThemes(void) {
    static NSArray<CYLDemoTheme *> *themes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        themes = @[
            [CYLDemoTheme themeWithIdentifier:CYLDemoThemeIdentifierDefault tintColor:nil barColor:nil normalColor:nil],
            [CYLDemoTheme themeWithIdentifier:CYLDemoThemeIdentifierGrapefruit tintColor:CYLDemoRGB(239, 83, 98) barColor:nil normalColor:nil],
            [CYLDemoTheme themeWithIdentifier:CYLDemoThemeIdentifierGrass tintColor:CYLDemoRGB(110, 180, 60) barColor:nil normalColor:nil],
            [CYLDemoTheme themeWithIdentifier:CYLDemoThemeIdentifierPinkRose tintColor:CYLDemoRGB(238, 133, 193) barColor:nil normalColor:nil],
            [CYLDemoTheme themeWithIdentifier:CYLDemoThemeIdentifierDark tintColor:CYLDemoRGB(39, 192, 243) barColor:CYLDemoRGB(18, 18, 20) normalColor:CYLDemoRGB(142, 142, 147)],
            CYLDemoHolidayTheme(CYLDemoThemeIdentifierSpringFestival, CYLDemoRGB(255, 213, 79), CYLDemoRGB(196, 30, 58), CYLDemoRGB(255, 205, 210),
                                @[ @"red_envelope", @"firecracker", @"red_paper_lantern", @"dragon", @"fireworks" ]),
            CYLDemoHolidayTheme(CYLDemoThemeIdentifierChristmas, CYLDemoRGB(255, 214, 102), CYLDemoRGB(22, 101, 52), CYLDemoRGB(200, 230, 201),
                                @[ @"christmas_tree", @"wrapped_gift", @"snowman", @"bell", @"star" ]),
            CYLDemoHolidayTheme(CYLDemoThemeIdentifierHalloween, CYLDemoRGB(255, 145, 0), CYLDemoRGB(38, 20, 58), CYLDemoRGB(179, 157, 219),
                                @[ @"jack_o_lantern", @"ghost", @"bat", @"spider", @"candy" ]),
            CYLDemoHolidayTheme(CYLDemoThemeIdentifierValentine, CYLDemoRGB(233, 30, 99), CYLDemoRGB(255, 235, 240), CYLDemoRGB(173, 120, 140),
                                @[ @"heart_with_ribbon", @"rose", @"love_letter", @"chocolate_bar", @"ring" ]),
            CYLDemoHolidayTheme(CYLDemoThemeIdentifierMidAutumn, CYLDemoRGB(255, 193, 7), CYLDemoRGB(26, 35, 76), CYLDemoRGB(159, 168, 218),
                                @[ @"moon_cake", @"full_moon", @"rabbit", @"teacup_without_handle", @"crescent_moon" ]),
            CYLDemoHolidayTheme(CYLDemoThemeIdentifierEaster, CYLDemoRGB(124, 179, 66), CYLDemoRGB(255, 250, 225), CYLDemoRGB(161, 136, 127),
                                @[ @"hatching_chick", @"egg", @"rabbit_face", @"tulip", @"basket" ]),
            CYLDemoHolidayTheme(CYLDemoThemeIdentifierNewYear, CYLDemoRGB(255, 215, 64), CYLDemoRGB(20, 20, 40), CYLDemoRGB(144, 164, 174),
                                @[ @"party_popper", @"confetti_ball", @"clinking_glasses", @"sparkler", @"alarm_clock" ]),
            CYLDemoHolidayTheme(CYLDemoThemeIdentifierSummer, CYLDemoRGB(0, 151, 167), CYLDemoRGB(255, 248, 225), CYLDemoRGB(141, 110, 99),
                                @[ @"beach_with_umbrella", @"watermelon", @"palm_tree", @"tropical_drink", @"sun" ]),
            CYLDemoHolidayTheme(CYLDemoThemeIdentifierBirthday, CYLDemoRGB(236, 64, 122), CYLDemoRGB(255, 243, 224), CYLDemoRGB(149, 117, 205),
                                @[ @"birthday_cake", @"balloon", @"candle", @"teddy_bear", @"wrapped_gift" ]),
            CYLDemoHolidayTheme(CYLDemoThemeIdentifierSpace, CYLDemoRGB(128, 222, 234), CYLDemoRGB(13, 17, 38), CYLDemoRGB(121, 134, 203),
                                @[ @"rocket", @"ringed_planet", @"flying_saucer", @"glowing_star", @"comet" ]),
            CYLDemoHolidayTheme(CYLDemoThemeIdentifierOcean, CYLDemoRGB(255, 255, 255), CYLDemoRGB(1, 87, 155), CYLDemoRGB(129, 212, 250),
                                @[ @"spouting_whale", @"tropical_fish", @"spiral_shell", @"crab", @"water_wave" ]),
            CYLDemoNetworkTheme(),
        ];
    });
    return themes;
}

/// [EN] Saves every change of the default theme. [CN] 保存默认管理器的每次主题切换。
@interface CYLDemoThemeObserver : NSObject
@end

@implementation CYLDemoThemeObserver

- (void)themeDidChange:(NSNotification *)notification {
    CYLThemeManager *manager = notification.object;
    if (![manager.name isEqual:CYLThemeManagerNameDefault] || ![manager.currentThemeIdentifier isKindOfClass:[NSString class]]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] setObject:manager.currentThemeIdentifier forKey:CYLDemoThemeIdentifierDefaultsKey];
}

@end

/// [EN] Follows the system Dark Mode: Dark in dark, otherwise back to Default from Dark, or the theme already chosen.
/// [CN] 跟随系统深色模式：深色时为“深色”，浅色时从“深色”回到“默认”，否则保持已选主题。
static void CYLDemoSetFollowsSystem(BOOL followsSystem) {
    if (@available(iOS 13.0, *)) {
        CYLThemeManager *manager = CYLThemeManagerCenter.defaultThemeManager;
        manager.identifierForTrait = ^__kindof NSObject<NSCopying> *_Nullable (UITraitCollection *trait) {
            if (trait.userInterfaceStyle == UIUserInterfaceStyleDark) {
                return CYLDemoThemeIdentifierDark;
            }
            CYLThemeManager *defaultManager = CYLThemeManagerCenter.defaultThemeManager;
            if ([defaultManager.currentThemeIdentifier isEqual:CYLDemoThemeIdentifierDark]) {
                return CYLDemoThemeIdentifierDefault;
            }
            return defaultManager.currentThemeIdentifier;
        };
        manager.respondsSystemStyleAutomatically = followsSystem;
        [[NSUserDefaults standardUserDefaults] setBool:followsSystem forKey:CYLDemoThemeFollowsSystemDefaultsKey];
    }
}

static BOOL CYLDemoFollowsSystem(void) {
    if (@available(iOS 13.0, *)) {
        return CYLThemeManagerCenter.defaultThemeManager.respondsSystemStyleAutomatically;
    }
    return NO;
}

static CYLDemoTheme *CYLDemoCurrentTheme(void) {
    id theme = CYLThemeManagerCenter.defaultThemeManager.currentTheme;
    return [theme isKindOfClass:[CYLDemoTheme class]] ? theme : CYLDemoThemes().firstObject;
}

static NSString *const CYLThemeListCellIdentifier = @"CYLThemeListCell";

/// [EN] A round swatch of a color theme's tint, for the theme list. [CN] 配色主题 tint 的圆形色块，用于主题列表。
static UIImage *CYLDemoColorSwatch(UIColor *color) {
    CGSize size = CGSizeMake(25, 25);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [color setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectInset(CGRectMake(0, 0, size.width, size.height), 2, 2)] fill];
    }];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

/// [EN] Applies `theme`; a theme picked by hand stops following the system. [CN] 应用 `theme`；手动选择主题后不再跟随系统。
/// [EN] YES for the same image object or the same pixels. [CN] 同一个图片对象或像素相同时为 YES。
/*!
 * [EN] A line of the plus child theme test: to the console, and appended at once to `tmp/plus-child-theme-test.log` in
 *      the app's data container, which scripts/plus-child-theme-test.sh reads (`xcrun simctl get_app_container … data`).
 *      The console stream of `simctl launch --console-pty` reached the script only when the app was closed, so it waited
 *      in vain and took every screenshot at the end.
 * [CN] PlusButton 子控制器换肤测试的一行输出：写到控制台，并立即追加到 App 数据容器中的 `tmp/plus-child-theme-test.log`，
 *      由 scripts/plus-child-theme-test.sh 读取（`xcrun simctl get_app_container … data`）。`simctl launch --console-pty` 的控制台输出
 *      直到 App 关闭才传到脚本，脚本因此一直等待，所有截图都在最后才截取。
 */
static void CYLDemoTestLog(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
static void CYLDemoTestLog(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
    NSString *line = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    NSLog(@"%@", line);
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"plus-child-theme-test.log"];
    NSFileHandle *file = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!file) {
        [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
        file = [NSFileHandle fileHandleForWritingAtPath:path];
    }
    [file seekToEndOfFile];
    [file writeData:[[line stringByAppendingString:@"\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
}

static BOOL CYLDemoSameImage(UIImage *image, UIImage *otherImage) {
    if (!image || !otherImage) {
        return NO;
    }
    if (image == otherImage || [image isEqual:otherImage]) {
        return YES;
    }
    NSData *data = UIImagePNGRepresentation(image);
    return data && [data isEqualToData:UIImagePNGRepresentation(otherImage)];
}

/*!
 * [EN] The plus child theme test (docs/Plus-Child-Theme-Switching-Test.md, scripts/plus-child-theme-test.sh): with the
 *      plus child view controller selected on Liquid Glass, the plus button's stand-in in the selected layer
 *      (`selectedContentView`) must show one of the plus button's own current images; an image the plus button no
 *      longer has is the stale stand-in that looked blurred. Logs "plus child theme test: PASS|FAIL|SKIP <phase> ...".
 *      Returns the plus button when its stand-in is shown (for the "stand-in only" step), else nil.
 * [CN] PlusButton 子控制器换肤测试（docs/Plus-Child-Theme-Switching-Test.md、scripts/plus-child-theme-test.sh）：在液态玻璃上选中
 *      PlusButton 子控制器时，选中图层中的 PlusButton 替身（`selectedContentView`）必须显示 PlusButton 自己当前的某张图片；显示 PlusButton
 *      已经没有的图片，就是看起来模糊的过期替身。输出 "plus child theme test: PASS|FAIL|SKIP <阶段> ..."。
 *      替身已显示时返回 PlusButton（用于“只看替身”步骤），否则返回 nil。
 */
static UIButton * _Nullable CYLDemoCheckPlusChildStandIn(NSString *phase) {
    CYLTabBarController *tabBarController = [CYLTabBarController cyl_activeTabBarController];
    CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = [CYLPlusButton plusButtonForOwner:tabBarController];
    NSString *theme = CYLThemeManagerCenter.defaultThemeManager.currentThemeIdentifier;
    if (!plusButton) {
        CYLDemoTestLog(@"plus child theme test: SKIP %@ theme=%@: no plus button", phase, theme);
        return nil;
    }
    // [EN] Liquid Glass active AND not the FlatDesign style, as in master: the FlatDesign tab bar has no selected layer,
    //      even on iOS 26 where `+isLiquidGlassActive` is YES.
    // [CN] 与 master 相同：液态玻璃处于活动状态且不是扁平样式。扁平样式 TabBar 没有选中图层，即使在 `+isLiquidGlassActive` 为 YES 的
    //      iOS 26 上也是如此。
    BOOL isLiquidGlassTabBar = (CYLTabBarStyleTypeFlatDesign != tabBarController.tabBarStyleType && [CYLConstants isLiquidGlassActive]);
    if (!isLiquidGlassTabBar) {
        CYLDemoTestLog(@"plus child theme test: SKIP %@ theme=%@: no stand-in outside the Liquid Glass tab bar", phase, theme);
        return nil;
    }
    UIButton *standIn = plusButton.selectedContentView;
    if (!standIn || standIn == plusButton || !standIn.window) {
        CYLDemoTestLog(@"plus child theme test: FAIL %@ theme=%@ selectedIndex=%@: the stand-in is not shown", phase, theme, @(tabBarController.selectedIndex));
        return nil;
    }
    UIImage *shown = standIn.currentImage;
    // [EN] One picture on Liquid Glass with a plus child, even when the theme gives a selected image too (the network skin):
    //      the stand-in shows the plus button's normal image, and so does the plus button in its current state.
    // [CN] 液态玻璃且有 PlusButton 子控制器时只有一张图片，即使主题同时提供了选中图片（网络皮肤）：替身显示 PlusButton 的普通状态图片，
    //      PlusButton 当前状态显示的也是它。
    UIImage *normalImage = [plusButton imageForState:UIControlStateNormal];
    BOOL matches = CYLDemoSameImage(shown, normalImage) && CYLDemoSameImage(plusButton.currentImage, normalImage);
    // [EN] The real plus button must not be drawn under the glass: blurred and magnified there, it showed around the
    //      stand-in's image wherever that image is transparent (a theme's star), and the icon looked soft.
    // [CN] 真实的 PlusButton 不能在玻璃下方绘制：它在那里被模糊并放大，会从替身图片的透明区域（如主题的星星）周围露出来，图标因此发虚。
    BOOL masked = [plusButton.layer.mask.name isEqualToString:@"CYLPlusButtonLiquidGlassMask"];
    CYLDemoTestLog(@"plus child theme test: %@ %@ theme=%@ selectedIndex=%@ standIn=%@ plusButton=%@ realButtonMaskedUnderGlass=%@",
          (matches && masked) ? @"PASS" : @"FAIL", phase, theme, @(tabBarController.selectedIndex), NSStringFromCGSize(shown.size),
          NSStringFromCGSize(plusButton.currentImage.size), @(masked));
    for (UIView *view = standIn.superview; view && view != tabBarController.tabBar.superview; view = view.superview) {
        if (view.layer.mask || view.clipsToBounds || view.layer.masksToBounds) {
            CYLDemoTestLog(@"plus child theme test: info %@ clip=%@ frame=%@ cornerRadius=%.1f layerMask=%@", phase, NSStringFromClass([view class]),
                  NSStringFromCGRect([view convertRect:view.bounds toView:nil]), view.layer.cornerRadius, @(view.layer.mask != nil));
            break;
        }
    }
    // [EN] The glass geometry: the selected-layer tab button that holds the stand-in, and the views of the tab bar whose
    //      class names say selection, lens, indicator or highlight. [CN] 玻璃的几何信息：容纳替身的选中图层 Tab 按钮，以及类名中
    //      含 selection、lens、indicator 或 highlight 的 TabBar 视图。
    CYLDemoTestLog(@"plus child theme test: info %@ selectedLayerTabButton=%@", phase, NSStringFromCGRect([standIn.superview convertRect:standIn.superview.bounds toView:nil]));
    NSMutableArray<UIView *> *pending = [NSMutableArray arrayWithObject:tabBarController.tabBar];
    NSUInteger logged = 0;
    while (pending.count > 0 && logged < 12) {
        UIView *view = pending.firstObject;
        [pending removeObjectAtIndex:0];
        [pending addObjectsFromArray:view.subviews];
        NSString *className = NSStringFromClass([view class]).lowercaseString;
        for (NSString *word in @[ @"selection", @"lens", @"indicator", @"highlight" ]) {
            if ([className containsString:word]) {
                CYLDemoTestLog(@"plus child theme test: info %@ view=%@ frame=%@ hidden=%@ alpha=%.2f", phase, NSStringFromClass([view class]),
                      NSStringFromCGRect([view convertRect:view.bounds toView:nil]), @(view.hidden), view.alpha);
                logged++;
                break;
            }
        }
    }
    // [EN] What is drawn: the image view's own image (a button with a `UIButtonConfiguration` may draw another image than
    //      `currentImage`), frames in the window, visibility up the superview chain, image scale.
    // [CN] 实际绘制的内容：图片视图自己的图片（使用 `UIButtonConfiguration` 的按钮绘制的图片可能与 `currentImage` 不同）、在 window 中的
    //      frame、父视图链上的可见性、图片 scale。
    BOOL standInVisible = YES;
    for (UIView *view = standIn; view; view = view.superview) {
        if (view.hidden || view.alpha < 0.01) {
            standInVisible = NO;
            break;
        }
    }
    UIImageView *imageView = standIn.imageView;
    CYLDemoTestLog(@"plus child theme test: info %@ standInFrame=%@ plusButtonFrame=%@ visible=%@ configuration=%@ highlighted=%@ "
          @"imageViewImageIsCurrent=%@ imageViewFrame=%@ imageViewHidden=%@ imageViewAlpha=%.2f imageScale=%.1f plusImageScale=%.1f "
          @"standInSuperview=%@",
          phase, NSStringFromCGRect([standIn convertRect:standIn.bounds toView:nil]),
          NSStringFromCGRect([plusButton convertRect:plusButton.bounds toView:nil]), @(standInVisible), @(standIn.configuration != nil),
          @(standIn.highlighted), @(CYLDemoSameImage(imageView.image, shown)), NSStringFromCGRect(imageView.frame), @(imageView.hidden),
          imageView.alpha, imageView.image.scale, plusButton.currentImage.scale, NSStringFromClass([standIn.superview class]));
    // [EN] The real plus button: whether anything hides it (itself or a superview), its mask, its image view.
    // [CN] 真实的 PlusButton：是否被隐藏（自身或父视图）、其 mask、其图片视图。
    NSString *hiddenBy = @"nothing";
    for (UIView *view = plusButton; view; view = view.superview) {
        if (view.hidden || view.alpha < 0.01) {
            hiddenBy = [NSString stringWithFormat:@"%@(hidden=%@ alpha=%.2f)", NSStringFromClass([view class]), @(view.hidden), view.alpha];
            break;
        }
    }
    CAShapeLayer *plusMask = [plusButton.layer.mask isKindOfClass:[CAShapeLayer class]] ? (CAShapeLayer *)plusButton.layer.mask : nil;
    CYLDemoTestLog(@"plus child theme test: info %@ plusButton hiddenBy=%@ window=%@ superview=%@ selected=%@ highlighted=%@ "
          @"maskFrame=%@ maskPathBox=%@ imageViewHidden=%@ imageViewAlpha=%.2f imageViewFrame=%@ layerOpacity=%.2f",
          phase, hiddenBy, @(plusButton.window != nil), NSStringFromClass([plusButton.superview class]), @(plusButton.selected),
          @(plusButton.highlighted), plusMask ? NSStringFromCGRect(plusMask.frame) : @"none",
          plusMask ? NSStringFromCGRect(CGPathGetPathBoundingBox(plusMask.path)) : @"none", @(plusButton.imageView.hidden),
          plusButton.imageView.alpha, NSStringFromCGRect(plusButton.imageView.frame), plusButton.layer.opacity);
    return plusButton;
}

static void CYLDemoApplyTheme(CYLDemoTheme *theme) {
    if (CYLDemoFollowsSystem()) {
        CYLDemoSetFollowsSystem(NO);
    }
    CYLThemeManagerCenter.defaultThemeManager.currentThemeIdentifier = theme.identifier;
}

@implementation UIViewController (CYLThemeSettings)

#pragma mark - Theme list section

- (NSString *)cyl_themeListSectionTitle {
    return [NSString stringWithFormat:CYLLocalizedString(@"换肤：节日与配色主题（%@ 种）"), @(CYLDemoThemes().count)];
}

- (NSInteger)cyl_themeListRowCount {
    return (NSInteger)CYLDemoThemes().count;
}

- (UITableViewCell *)cyl_themeListCellForTableView:(UITableView *)tableView row:(NSInteger)row {
    [UIViewController cyl_setUpThemeSettings];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLThemeListCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLThemeListCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    NSArray<CYLDemoTheme *> *themes = CYLDemoThemes();
    if (row < 0 || row >= (NSInteger)themes.count) {
        return cell;
    }
    CYLDemoTheme *theme = themes[(NSUInteger)row];
    cell.textLabel.text = [theme localizedName];
    cell.detailTextLabel.text = [theme localizedSummary];
    cell.imageView.image = [theme previewIcon] ?: CYLDemoColorSwatch(theme.tintColor ?: [UIColor lightGrayColor]);
    cell.accessoryType = [theme.identifier isEqualToString:CYLDemoCurrentTheme().identifier] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

- (void)cyl_didSelectThemeListRow:(NSInteger)row {
    [UIViewController cyl_setUpThemeSettings];
    NSArray<CYLDemoTheme *> *themes = CYLDemoThemes();
    if (row < 0 || row >= (NSInteger)themes.count) {
        return;
    }
    CYLDemoApplyTheme(themes[(NSUInteger)row]);
}

+ (void)cyl_setUpThemeSettings {
    static CYLDemoThemeObserver *observer;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CYLThemeManager *manager = CYLThemeManagerCenter.defaultThemeManager;
        for (CYLDemoTheme *theme in CYLDemoThemes()) {
            if (![manager themeForIdentifier:theme.identifier]) {
                [manager addThemeIdentifier:theme.identifier theme:theme];
            }
        }
        // [EN] The app may use the default manager with themes of its own: only pick one when none is current.
        // [CN] App 可能用默认管理器管理自己的主题：仅在没有当前主题时设置。
        if (!manager.currentThemeIdentifier) {
            NSString *savedIdentifier = [[NSUserDefaults standardUserDefaults] stringForKey:CYLDemoThemeIdentifierDefaultsKey];
            manager.currentThemeIdentifier = [manager themeForIdentifier:savedIdentifier ?: @""] ? savedIdentifier : CYLDemoThemeIdentifierDefault;
        }
        observer = [[CYLDemoThemeObserver alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(themeDidChange:) name:CYLThemeDidChangeNotification object:nil];
        if ([[NSUserDefaults standardUserDefaults] boolForKey:CYLDemoThemeFollowsSystemDefaultsKey]) {
            CYLDemoSetFollowsSystem(YES);
        }
        // [EN] `-CYLDemoThemeSwitchTo <identifier>` (scripts/theme-screenshots.sh): switch to that theme a few seconds
        //      after launch, as a tap on the skin button does, to check a theme change at runtime (e.g. a holiday skin,
        //      then a color skin, with a plus button and its child view controller).
        // [CN] `-CYLDemoThemeSwitchTo <identifier>`（scripts/theme-screenshots.sh）：启动几秒后切换到该主题，与点击换肤按钮相同，
        //      用于检查运行时切换主题（例如带 PlusButton 及其子控制器时，先节日皮肤、再配色主题）。
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        // [EN] `-CYLDemoSelectIndex <n>` selects tab n 2 s after launch, as a tap does (e.g. 2: the plus child view controller,
        //      to check that the plus button stays sharp in the Liquid Glass selected layer before and after a theme switch).
        //      `-CYLDemoThemeSwitchDelay <seconds>` delays the switch (default 4).
        // [CN] `-CYLDemoSelectIndex <n>` 在启动 2 秒后选中第 n 个 Tab，与点击相同（例如 2：PlusButton 子控制器，用于检查换肤前后液态玻璃
        //      选中图层中的 PlusButton 是否保持清晰）。`-CYLDemoThemeSwitchDelay <秒>` 推迟切换（默认 4）。
        NSString *switchIdentifier = [defaults stringForKey:@"CYLDemoThemeSwitchTo"];
        double switchDelay = [defaults objectForKey:@"CYLDemoThemeSwitchDelay"] ? [defaults doubleForKey:@"CYLDemoThemeSwitchDelay"] : 4;
        void (^switchTheme)(void) = ^{
            for (CYLDemoTheme *theme in CYLDemoThemes()) {
                if ([theme.identifier isEqualToString:switchIdentifier]) {
                    CYLDemoApplyTheme(theme);
                    break;
                }
            }
        };
        if ([defaults objectForKey:@"CYLDemoSelectIndex"]) {
            // [EN] The plus child theme test, as a chain with a handshake: after each state to photograph, the app waits
            //      until scripts/plus-child-theme-test.sh has saved its screenshot and created `tmp/ack-<step>` in the
            //      app's data container (at most 30 s), then goes on. On CI a screenshot took from 1 s to more than 10 s,
            //      so fixed delays let the app move on during the capture: the "before" screenshot showed the new theme,
            //      or the plus button hidden for the "stand-in only" step. Steps: select tab n (2 s after launch) →
            //      "before" check → ack → "stand-in only" (real plus button hidden) → ack → switch → "after" check (3 s
            //      later) → ack → "stand-in only" → ack → "done". `-CYLDemoThemeSwitchDelay` is not used here.
            // [CN] PlusButton 子控制器换肤测试，按链式执行并与脚本握手：每个需要截图的状态之后，App 等待 scripts/plus-child-theme-test.sh
            //      保存截图并在 App 数据容器中创建 `tmp/ack-<步骤>`（最多 30 秒），然后继续。CI 上一次截图需要 1 秒到 10 秒以上，固定延时会让
            //      App 在截图过程中继续执行：“before” 截图已经是新主题，或者截到为“只看替身”而隐藏的 PlusButton。步骤：选中第 n 个 Tab
            //      （启动 2 秒后）→ “before” 检查 → ack → “只看替身”（隐藏真实 PlusButton）→ ack → 切换 → “after” 检查（3 秒后）→ ack →
            //      “只看替身” → ack → “done”。这里不使用 `-CYLDemoThemeSwitchDelay`。
            NSInteger selectIndex = [defaults integerForKey:@"CYLDemoSelectIndex"];
            CYLDemoTestLog(@"plus child theme test: launch theme=%@", manager.currentThemeIdentifier);
            void (^after)(NSTimeInterval, dispatch_block_t) = ^(NSTimeInterval seconds, dispatch_block_t block) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
            };
            // [EN] Runs `block` once tmp/ack-<step> exists, or after 30 s. [CN] tmp/ack-<步骤> 出现后（或 30 秒后）执行 `block`。
            __block void (^waitForAck)(NSString *, NSUInteger, dispatch_block_t);
            void (^waitForAckBlock)(NSString *, NSUInteger, dispatch_block_t) = ^(NSString *step, NSUInteger tries, dispatch_block_t block) {
                NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[@"ack-" stringByAppendingString:step]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:path] || tries >= 120) {
                    if (tries >= 120) {
                        CYLDemoTestLog(@"plus child theme test: no ack for %@ after 30 s", step);
                    }
                    block();
                    return;
                }
                after(0.25, ^{
                    waitForAck(step, tries + 1, block);
                });
            };
            waitForAck = waitForAckBlock;
            // [EN] A check, its screenshot, then the stand-in alone and its screenshot. [CN] 检查并截图，然后只看替身并截图。
            void (^checkAndPhotograph)(NSString *, dispatch_block_t) = ^(NSString *phase, dispatch_block_t next) {
                UIButton * _Nullable plusButton = CYLDemoCheckPlusChildStandIn(phase);
                waitForAck(phase, 0, ^{
                    if (!plusButton) {
                        next();
                        return;
                    }
                    CGFloat alpha = plusButton.alpha;
                    plusButton.alpha = 0;
                    after(0.5, ^{
                        CYLDemoTestLog(@"plus child theme test: stand-in only %@", phase);
                        waitForAck([@"stand-in-only-" stringByAppendingString:phase], 0, ^{
                            plusButton.alpha = alpha;
                            after(1, next);
                        });
                    });
                });
            };
            after(2, ^{
                CYLTabBarController *tabBarController = [CYLTabBarController cyl_activeTabBarController];
                if (selectIndex >= 0 && (NSUInteger)selectIndex < tabBarController.viewControllers.count) {
                    tabBarController.selectedIndex = (NSUInteger)selectIndex;
                }
                after(3, ^{
                    checkAndPhotograph(@"before", ^{
                        if (switchIdentifier.length == 0) {
                            CYLDemoTestLog(@"plus child theme test: done");
                            waitForAck = nil;
                            return;
                        }
                        switchTheme();
                        after(3, ^{
                            checkAndPhotograph(@"after", ^{
                                CYLDemoTestLog(@"plus child theme test: done");
                                waitForAck = nil;
                            });
                        });
                    });
                });
            });
        } else if (switchIdentifier.length > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(switchDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), switchTheme);
        }
    });
}

- (UITableViewCell *)cyl_themeSettingsCellForTableView:(UITableView *)tableView {
    [UIViewController cyl_setUpThemeSettings];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLThemeSettingsCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLThemeSettingsCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"paintbrush"];
        }
    }
    NSString *themeName = [CYLDemoCurrentTheme() localizedName];
    if (CYLDemoFollowsSystem()) {
        themeName = [NSString stringWithFormat:@"%@ · %@", themeName, CYLLocalizedString(@"跟随系统深色模式")];
    }
    cell.textLabel.text = CYLLocalizedString(@"换肤（主题，issue #216）");
    cell.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"点击选择主题：TabBar 的背景、图标与文字颜色原地切换，所有 TabBar 样式均适用。当前：%@"), themeName];
    return cell;
}

- (void)cyl_presentThemePickerFromView:(nullable UIView *)sourceView completion:(nullable void (^)(void))completion {
    [UIViewController cyl_setUpThemeSettings];
    UIAlertController *picker = [UIAlertController alertControllerWithTitle:CYLLocalizedString(@"选择主题")
                                                                    message:nil
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    NSString *currentIdentifier = CYLDemoCurrentTheme().identifier;
    for (CYLDemoTheme *theme in CYLDemoThemes()) {
        BOOL isCurrent = [theme.identifier isEqualToString:currentIdentifier];
        NSString *title = isCurrent ? [NSString stringWithFormat:@"✓ %@", [theme localizedName]] : [theme localizedName];
        [picker addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            CYLDemoApplyTheme(theme);
            if (completion) {
                completion();
            }
        }]];
    }
    if (@available(iOS 13.0, *)) {
        BOOL followsSystem = CYLDemoFollowsSystem();
        NSString *title = CYLLocalizedString(@"跟随系统深色模式");
        if (followsSystem) {
            title = [NSString stringWithFormat:@"✓ %@", title];
        }
        [picker addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            CYLDemoSetFollowsSystem(!followsSystem);
            if (completion) {
                completion();
            }
        }]];
    }
    [picker addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    // [EN] iPad shows an action sheet as a popover. [CN] iPad 上 action sheet 以弹出框显示。
    UIPopoverPresentationController *popover = picker.popoverPresentationController;
    if (popover) {
        UIView *anchorView = sourceView ?: self.view;
        popover.sourceView = anchorView;
        popover.sourceRect = sourceView ? anchorView.bounds : CGRectMake(CGRectGetMidX(anchorView.bounds), CGRectGetMidY(anchorView.bounds), 1, 1);
    }
    [self presentViewController:picker animated:YES completion:nil];
}

/// [EN] The actions of the theme menu, built when it opens. [CN] 主题菜单的各项，在菜单打开时生成。
static NSArray<UIMenuElement *> *CYLDemoThemeMenuElements(void (^_Nullable completion)(void)) API_AVAILABLE(ios(14.0));
static NSArray<UIMenuElement *> *CYLDemoThemeMenuElements(void (^_Nullable completion)(void)) {
    NSMutableArray<UIMenuElement *> *themeActions = [NSMutableArray array];
    NSString *currentIdentifier = CYLDemoCurrentTheme().identifier;
    for (CYLDemoTheme *theme in CYLDemoThemes()) {
        UIImage *image = [theme previewIcon] ?: CYLDemoColorSwatch(theme.tintColor ?: [UIColor lightGrayColor]);
        UIAction *action = [UIAction actionWithTitle:[theme localizedName] image:image identifier:nil handler:^(__kindof UIAction *menuAction) {
            CYLDemoApplyTheme(theme);
            if (completion) {
                completion();
            }
        }];
        action.state = [theme.identifier isEqualToString:currentIdentifier] ? UIMenuElementStateOn : UIMenuElementStateOff;
        [themeActions addObject:action];
    }
    BOOL followsSystem = CYLDemoFollowsSystem();
    UIAction *followAction = [UIAction actionWithTitle:CYLLocalizedString(@"跟随系统深色模式") image:[UIImage systemImageNamed:@"circle.lefthalf.filled"] identifier:nil handler:^(__kindof UIAction *menuAction) {
        CYLDemoSetFollowsSystem(!followsSystem);
        if (completion) {
            completion();
        }
    }];
    followAction.state = followsSystem ? UIMenuElementStateOn : UIMenuElementStateOff;
    return @[ [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:themeActions],
              [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[ followAction ]] ];
}

- (UIMenu *)cyl_themeMenuWithCompletion:(nullable void (^)(void))completion {
    [UIViewController cyl_setUpThemeSettings];
    NSArray<UIMenuElement *> *children = nil;
    if (@available(iOS 15.0, *)) {
        // [EN] Built again every time it opens, so the checkmark follows the current theme.
        // [CN] 每次打开时重新生成，勾号随当前主题变化。
        children = @[ [UIDeferredMenuElement elementWithUncachedProvider:^(void (^provide)(NSArray<UIMenuElement *> *)) {
            provide(CYLDemoThemeMenuElements(completion));
        }] ];
    } else {
        children = CYLDemoThemeMenuElements(completion);
    }
    return [UIMenu menuWithTitle:CYLLocalizedString(@"选择主题") children:children];
}

@end

NS_ASSUME_NONNULL_END
