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

static UIColor *CYLDemoRGB(CGFloat red, CGFloat green, CGFloat blue) {
    return [UIColor colorWithRed:red / 255.0 green:green / 255.0 blue:blue / 255.0 alpha:1];
}

/*!
 * [EN] A demo theme: its colors and, for the Spring Festival skin, holiday icons. "Default" changes nothing, so the tab
 *      bar shows the app's own look again.
 * [CN] 演示主题：主题颜色；春节皮肤还带有节日图标。“默认”不做任何修改，TabBar 恢复 App 自己的外观。
 */
@interface CYLDemoTheme : NSObject <CYLTabBarTheme>
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, strong, nullable) UIColor *tintColor;
@property (nonatomic, strong, nullable) UIColor *barColor;
@property (nonatomic, strong, nullable) UIColor *normalColor;
@property (nonatomic, assign) BOOL usesHolidayIcons;
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
    return CYLLocalizedString(@"默认");
}

#pragma mark - CYLTabBarTheme

/*!
 * [EN] The Spring Festival skin: one holiday symbol per tab (SF Symbols, iOS 13+), as `UIImage`s, so no image file is
 *      needed. Other themes return nil: the app's own icons.
 * [CN] 春节皮肤：每个 Tab 一个节日符号（SF Symbols，iOS 13+），以 `UIImage` 传入，无需图片文件。其他主题返回 nil：使用 App 自己的图标。
 */
- (nullable NSArray<NSDictionary<NSString *, id> *> *)cyl_tabBarItemsAttributesForTabBarController:(CYLTabBarController *)tabBarController {
    if (!self.usesHolidayIcons) {
        return nil;
    }
    if (@available(iOS 13.0, *)) {
        NSArray<NSArray<NSString *> *> *symbols = @[
            @[ @"gift", @"gift.fill" ],
            @[ @"star", @"star.fill" ],
            @[ @"moon.stars", @"moon.stars.fill" ],
            @[ @"heart", @"heart.fill" ],
            @[ @"bell", @"bell.fill" ],
            @[ @"flame", @"flame.fill" ],
        ];
        NSMutableArray<NSDictionary<NSString *, id> *> *itemsAttributes = [NSMutableArray array];
        NSUInteger count = tabBarController.tabBarItemsAttributes.count;
        for (NSUInteger index = 0; index < count; index++) {
            NSArray<NSString *> *pair = symbols[index % symbols.count];
            UIImage *image = [UIImage systemImageNamed:pair[0]];
            UIImage *selectedImage = [UIImage systemImageNamed:pair[1]];
            if (!image || !selectedImage) {
                return nil;
            }
            [itemsAttributes addObject:@{ CYLTabBarItemImage : image, CYLTabBarItemSelectedImage : selectedImage }];
        }
        return itemsAttributes;
    }
    return nil;
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

/// [EN] The demo themes, in the picker's order. [CN] 演示主题，按选择器中的顺序。
static NSArray<CYLDemoTheme *> *CYLDemoThemes(void) {
    static NSArray<CYLDemoTheme *> *themes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CYLDemoTheme *springFestival = [CYLDemoTheme themeWithIdentifier:CYLDemoThemeIdentifierSpringFestival
                                                               tintColor:CYLDemoRGB(255, 213, 79)
                                                                barColor:CYLDemoRGB(196, 30, 58)
                                                             normalColor:CYLDemoRGB(255, 205, 210)];
        springFestival.usesHolidayIcons = YES;
        themes = @[
            [CYLDemoTheme themeWithIdentifier:CYLDemoThemeIdentifierDefault tintColor:nil barColor:nil normalColor:nil],
            [CYLDemoTheme themeWithIdentifier:CYLDemoThemeIdentifierGrapefruit tintColor:CYLDemoRGB(239, 83, 98) barColor:nil normalColor:nil],
            [CYLDemoTheme themeWithIdentifier:CYLDemoThemeIdentifierGrass tintColor:CYLDemoRGB(110, 180, 60) barColor:nil normalColor:nil],
            [CYLDemoTheme themeWithIdentifier:CYLDemoThemeIdentifierPinkRose tintColor:CYLDemoRGB(238, 133, 193) barColor:nil normalColor:nil],
            [CYLDemoTheme themeWithIdentifier:CYLDemoThemeIdentifierDark tintColor:CYLDemoRGB(39, 192, 243) barColor:CYLDemoRGB(18, 18, 20) normalColor:CYLDemoRGB(142, 142, 147)],
            springFestival,
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

@implementation UIViewController (CYLThemeSettings)

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
            // [EN] A theme picked by hand stops following the system. [CN] 手动选择主题后不再跟随系统。
            if (CYLDemoFollowsSystem()) {
                CYLDemoSetFollowsSystem(NO);
            }
            CYLThemeManagerCenter.defaultThemeManager.currentThemeIdentifier = theme.identifier;
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

@end

NS_ASSUME_NONNULL_END
