//
//  UITableViewCell+CYLBadgeExtention.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UITableViewCell+CYLBadgeExtention.h"
#import "UIView+CYLBadgeExtention.h"
#import "CAAnimation+CYLBadgeExtention.h"
#import "CYLTabBarController.h"

const CGFloat CYLBadgeRowHeight = 60;
static const CGFloat CYLBadgeIconSide = 30;
/// Key of the animations added here with the `CAAnimation+CYLBadgeExtention` factories (not by an animation type).
static NSString *const CYLBadgeHelperAnimationKey = @"cyl.badge.helper";

// Item keys.
static NSString *const CYLBadgeItemTitle = @"title";
/// The core API behind the sample, shown after its title, e.g. "Number (cyl_showBadgeValue:)".
static NSString *const CYLBadgeItemAPI = @"api";
static NSString *const CYLBadgeItemValue = @"value";
static NSString *const CYLBadgeItemAnimationType = @"animationType";
/// One of the names handled by `CYLBadgeHelperAnimation()`: an animation built with a `CAAnimation` factory.
static NSString *const CYLBadgeItemFactoryAnimation = @"factoryAnimation";
static NSString *const CYLBadgeItemMaximum = @"maximum";
static NSString *const CYLBadgeItemColors = @"colors";
static NSString *const CYLBadgeItemFont = @"font";
static NSString *const CYLBadgeItemBorder = @"border";
static NSString *const CYLBadgeItemDynamicBorder = @"dynamicBorder";
static NSString *const CYLBadgeItemRadius = @"radius";
static NSString *const CYLBadgeItemMargin = @"margin";
static NSString *const CYLBadgeItemCornerRadius = @"cornerRadius";
static NSString *const CYLBadgeItemReduceMotion = @"reduceMotion";
static NSString *const CYLBadgeItemPosition = @"position";

// Factory animations.
static NSString *const CYLBadgeRotationForever = @"rotationForever";
static NSString *const CYLBadgeSpringForever = @"springForever";
static NSString *const CYLBadgeShakeThreeTimes = @"shakeThreeTimes";
static NSString *const CYLBadgeBounceThreeTimes = @"bounceThreeTimes";
static NSString *const CYLBadgeScaleThreeTimes = @"scaleThreeTimes";
static NSString *const CYLBadgeBlinkThreeTimes = @"blinkThreeTimes";
static NSString *const CYLBadgeFlipTwice = @"flipTwice";
static NSString *const CYLBadgeSpringOnce = @"springOnce";

// Positions other than the default top-right corner.
static NSString *const CYLBadgeTopLeft = @"topLeft";
static NSString *const CYLBadgeBottomLeft = @"bottomLeft";
static NSString *const CYLBadgeBottomRight = @"bottomRight";

/// The animation called `name`, sized for `badge`; nil for an unknown name.
static CAAnimation *CYLBadgeHelperAnimation(NSString *name, UIView *badge) {
    CGSize size = badge.bounds.size;
    if ([name isEqualToString:CYLBadgeRotationForever]) {
        return [CAAnimation cyl_rotationAnimationWithDuration:2 degree:2 * M_PI direction:CYLAxisZ repeatCount:HUGE_VALF];
    }
    if ([name isEqualToString:CYLBadgeSpringForever]) {
        CAAnimation *animation = [CAAnimation cyl_springAnimationForDuration:1];
        animation.repeatCount = HUGE_VALF;
        return animation;
    }
    if ([name isEqualToString:CYLBadgeShakeThreeTimes]) {
        return [CAAnimation cyl_shakeAnimationRepeatTimes:3 duration:1 offset:size.width / 4];
    }
    if ([name isEqualToString:CYLBadgeBounceThreeTimes]) {
        return [CAAnimation cyl_bounceAnimationRepeatTimes:3 duration:1 offset:size.height / 4];
    }
    if ([name isEqualToString:CYLBadgeScaleThreeTimes]) {
        return [CAAnimation cyl_scaleAnimationFromScale:1.4 toScale:0.6 duration:1 repeatTimes:3];
    }
    if ([name isEqualToString:CYLBadgeBlinkThreeTimes]) {
        return [CAAnimation cyl_opacityTimesAnimationRepeatTimes:3 duration:0.8];
    }
    if ([name isEqualToString:CYLBadgeFlipTwice]) {
        return [CAAnimation cyl_rotationAnimationWithDuration:1 degree:M_PI direction:CYLAxisY repeatCount:2];
    }
    if ([name isEqualToString:CYLBadgeSpringOnce]) {
        return [CAAnimation cyl_springAnimationForDuration:0.6];
    }
    return nil;
}

/// Center offset that moves the badge from the icon's top-right corner, where it is centered at (width + 2, 0), to `position`.
static CGPoint CYLBadgeHelperCenterOffset(NSString *position) {
    CGFloat toLeft = -(CYLBadgeIconSide + 4);
    if ([position isEqualToString:CYLBadgeTopLeft]) {
        return CGPointMake(toLeft, 0);
    }
    if ([position isEqualToString:CYLBadgeBottomLeft]) {
        return CGPointMake(toLeft, CYLBadgeIconSide);
    }
    if ([position isEqualToString:CYLBadgeBottomRight]) {
        return CGPointMake(0, CYLBadgeIconSide);
    }
    return CGPointZero;
}

/// Border color that follows Dark Mode: black in light mode, white in dark mode.
static UIColor *CYLBadgeHelperDynamicBorderColor(void) {
    if (@available(iOS 13.0, *)) {
        return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            BOOL isDark = traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
            return isDark ? [UIColor whiteColor] : [UIColor blackColor];
        }];
    }
    return [UIColor blackColor];
}

@implementation UITableViewCell (CYLBadgeExtention)

/*!
 * Every badge style and animation, in display order:
 * 1. top-right corner, animated: animations that repeat forever, then ones that repeat a few times, then ones that play once;
 * 2. top-right corner, not animated: styles and appearance options;
 * 3. the other corners: top-left, bottom-left, bottom-right.
 */
+ (NSArray<NSDictionary *> *)cyl_badgeItems {
    // Rebuilt when the language changes (`CYLSetLocalizationLanguage()`), so the titles follow it.
    static NSArray *items;
    static NSString *itemsLanguage;
    NSString *language = CYLLocalizationLanguage();
    if (!items || ![itemsLanguage isEqualToString:language]) {
        itemsLanguage = language;
        items = @[
            // 1.1 Animations that repeat forever: `CYLBadgeAnimationType`
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Scale (forever)"), CYLBadgeItemAPI: @"CYLBadgeAnimationTypeScale",   CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeScale)},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Shake (forever)"), CYLBadgeItemAPI: @"CYLBadgeAnimationTypeShake",   CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeShake)},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Bounce (forever)"), CYLBadgeItemAPI: @"CYLBadgeAnimationTypeBounce",  CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeBounce)},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Breathe (forever)"), CYLBadgeItemAPI: @"CYLBadgeAnimationTypeBreathe", CYLBadgeItemValue: @"",  CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeBreathe)},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Shake, stops with Reduce Motion"), CYLBadgeItemAPI: @"cyl_badgeRespectsReduceMotion", CYLBadgeItemValue: @"3",
              CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeShake), CYLBadgeItemReduceMotion: @YES},
            // 1.2 Animations that repeat forever: `CAAnimation+CYLBadgeExtention` factories
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Rotation (forever)"), CYLBadgeItemAPI: @"cyl_rotationAnimationWithDuration:", CYLBadgeItemValue: @"new", CYLBadgeItemFactoryAnimation: CYLBadgeRotationForever},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Spring (forever)"), CYLBadgeItemAPI: @"cyl_springAnimationForDuration:",   CYLBadgeItemValue: @"3",   CYLBadgeItemFactoryAnimation: CYLBadgeSpringForever},
            // 1.3 Animations that repeat a few times
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Shake ×3 (cyl_shakeAnimationRepeatTimes)"),   CYLBadgeItemValue: @"3", CYLBadgeItemFactoryAnimation: CYLBadgeShakeThreeTimes},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Bounce ×3 (cyl_bounceAnimationRepeatTimes)"), CYLBadgeItemValue: @"3", CYLBadgeItemFactoryAnimation: CYLBadgeBounceThreeTimes},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Scale ×3"), CYLBadgeItemAPI: @"cyl_scaleAnimationFromScale:",  CYLBadgeItemValue: @"3", CYLBadgeItemFactoryAnimation: CYLBadgeScaleThreeTimes},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Blink ×3"), CYLBadgeItemAPI: @"cyl_opacityTimesAnimationRepeatTimes:",  CYLBadgeItemValue: @"",  CYLBadgeItemFactoryAnimation: CYLBadgeBlinkThreeTimes},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Flip ×2"), CYLBadgeItemAPI: @"cyl_rotationAnimationWithDuration:",   CYLBadgeItemValue: @"3", CYLBadgeItemFactoryAnimation: CYLBadgeFlipTwice},
            // 1.4 Animations that play once
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Left to right once"), CYLBadgeItemAPI: @"CYLBadgeAnimationTypeLeftRightOnce", CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeLeftRightOnce)},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Right to left once"), CYLBadgeItemAPI: @"CYLBadgeAnimationTypeRightLeftOnce", CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeRightLeftOnce)},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Fade in once"), CYLBadgeItemAPI: @"CYLBadgeAnimationTypeFadeInOnce",       CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeFadeInOnce)},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Rolling once"), CYLBadgeItemAPI: @"CYLBadgeAnimationTypeRollingOnce",       CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeRollingOnce)},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Scale once"), CYLBadgeItemAPI: @"CYLBadgeAnimationTypeScaleOnce",         CYLBadgeItemValue: @"3", CYLBadgeItemAnimationType: @(CYLBadgeAnimationTypeScaleOnce)},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Spring once"), CYLBadgeItemAPI: @"cyl_springAnimationForDuration:",        CYLBadgeItemValue: @"3", CYLBadgeItemFactoryAnimation: CYLBadgeSpringOnce},
            // 2.1 Styles, no animation
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Red dot"), CYLBadgeItemAPI: @"cyl_showBadge",              CYLBadgeItemValue: @""},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Number"), CYLBadgeItemAPI: @"cyl_showBadgeValue:",               CYLBadgeItemValue: @"8"},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Number above maximum"), CYLBadgeItemAPI: @"cyl_badgeMaximumBadgeNumber", CYLBadgeItemValue: @"100"},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Custom maximum (9)"), CYLBadgeItemAPI: @"cyl_badgeMaximumBadgeNumber",   CYLBadgeItemValue: @"10", CYLBadgeItemMaximum: @9},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"New"), CYLBadgeItemAPI: @"cyl_showBadgeValue:@\"new\"",                  CYLBadgeItemValue: @"new"},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"NEW"), CYLBadgeItemAPI: @"cyl_showBadgeValue:@\"NEW\"",                  CYLBadgeItemValue: @"NEW"},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Other text"), CYLBadgeItemAPI: @"cyl_showBadgeValue:",           CYLBadgeItemValue: CYLLocalizedString(@"hot")},
            // 2.2 Appearance, no animation
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Custom colors"), CYLBadgeItemAPI: @"cyl_badgeBackgroundColor / cyl_badgeTextColor",        CYLBadgeItemValue: @"5",   CYLBadgeItemColors: @YES},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Custom font"), CYLBadgeItemAPI: @"cyl_badgeFont",          CYLBadgeItemValue: @"5",   CYLBadgeItemFont: @YES},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Border"), CYLBadgeItemAPI: @"cyl_badgeBorderColor / cyl_badgeBorderWidth",               CYLBadgeItemValue: @"5",   CYLBadgeItemBorder: @YES},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Border following Dark Mode"), CYLBadgeItemAPI: @"cyl_badgeBorderColor", CYLBadgeItemValue: @"5", CYLBadgeItemDynamicBorder: @YES},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Red dot radius"), CYLBadgeItemAPI: @"cyl_badgeRadius",       CYLBadgeItemValue: @"",    CYLBadgeItemRadius: @6},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Margin"), CYLBadgeItemAPI: @"cyl_badgeMargin",               CYLBadgeItemValue: @"5",   CYLBadgeItemMargin: @14},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Corner radius"), CYLBadgeItemAPI: @"cyl_badgeCornerRadius",        CYLBadgeItemValue: @"new", CYLBadgeItemCornerRadius: @3},
            // 3. Other corners
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Top left"), CYLBadgeItemAPI: @"cyl_badgeCenterOffset",     CYLBadgeItemValue: @"5", CYLBadgeItemPosition: CYLBadgeTopLeft},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Bottom left"), CYLBadgeItemAPI: @"cyl_badgeCenterOffset",  CYLBadgeItemValue: @"5", CYLBadgeItemPosition: CYLBadgeBottomLeft},
            @{CYLBadgeItemTitle: CYLLocalizedString(@"Bottom right"), CYLBadgeItemAPI: @"cyl_badgeCenterOffset", CYLBadgeItemValue: @"5", CYLBadgeItemPosition: CYLBadgeBottomRight},
        ];
    }
    return items;
}

/// The app icon drawn at 30 x 30 pt with rounded corners, which leaves 15 pt above and below it in a 60 pt row. The badge
/// sits on one of the icon's corners, so it needs that room to stay inside the row, animations included.
+ (UIImage *)cyl_badgeIcon {
    static UIImage *icon;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIImage *image = [UIImage imageNamed:@"cyl_badge_sample_icon" inBundle:CYLResourceBundle() compatibleWithTraitCollection:nil];
        CGRect rect = CGRectMake(0, 0, CYLBadgeIconSide, CYLBadgeIconSide);
        icon = [[[UIGraphicsImageRenderer alloc] initWithSize:rect.size] imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:6] addClip];
            [image drawInRect:rect];
        }];
    });
    return icon;
}

+ (NSDictionary *)cyl_badgeItemForRow:(NSInteger)row {
    NSArray<NSDictionary *> *items = [self cyl_badgeItems];
    return items[(NSUInteger)MAX(row, 0) % items.count];
}

/// [EN] Whether `color` is one of the fixed default text colors (black or gray), which do not adapt to Dark Mode.
/// [CN] `color` 是否为固定的默认文字颜色（黑色或灰色），这些颜色不会适配深色模式。
static BOOL CYLIsFixedDefaultTextColor(UIColor *color) {
    if (!color) {
        return YES;
    }
    for (UIColor *fixed in @[ UIColor.blackColor, UIColor.grayColor, UIColor.darkGrayColor, UIColor.lightGrayColor, UIColor.darkTextColor ]) {
        if ([color isEqual:fixed]) {
            return YES;
        }
    }
    return NO;
}

/// [EN] Subtitles: `secondaryLabelColor` in light mode; a brighter gray in Dark Mode, where `secondaryLabelColor` (60 %
///      white) is hard to read on black. [CN] 副标题：浅色模式为 `secondaryLabelColor`；深色模式为更亮的灰色，`secondaryLabelColor`
///      （60% 白色）在黑色背景上不易辨认。
static UIColor *CYLDemoSubtitleColor(void) API_AVAILABLE(ios(13.0)) {
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
        return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? [UIColor colorWithWhite:0.80 alpha:1] : UIColor.secondaryLabelColor;
    }];
}

- (void)cyl_wrapsTextLabels {
    for (UILabel *label in @[ self.textLabel ?: [UILabel new], self.detailTextLabel ?: [UILabel new] ]) {
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
    }
    // [EN] Dark Mode and contrast: fixed black or gray text becomes the semantic label colors (a custom color is kept),
    //      the title a semibold 16 pt and the subtitle 14 pt, both following Dynamic Type.
    // [CN] 深色模式与对比度：固定的黑色或灰色文字改为语义化的标签颜色（自定义颜色保留），标题为 16 pt 半粗体、副标题为 14 pt，
    //      均跟随动态字体。
    if (@available(iOS 13.0, *)) {
        if (CYLIsFixedDefaultTextColor(self.textLabel.textColor)) {
            self.textLabel.textColor = UIColor.labelColor;
        }
        if (CYLIsFixedDefaultTextColor(self.detailTextLabel.textColor) || [self.detailTextLabel.textColor isEqual:UIColor.secondaryLabelColor]) {
            self.detailTextLabel.textColor = CYLDemoSubtitleColor();
        }
    }
    UIFontMetrics *titleMetrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleSubheadline];
    UIFontMetrics *detailMetrics = [UIFontMetrics metricsForTextStyle:UIFontTextStyleFootnote];
    self.textLabel.font = [titleMetrics scaledFontForFont:[UIFont systemFontOfSize:16 weight:UIFontWeightSemibold]];
    self.detailTextLabel.font = [detailMetrics scaledFontForFont:[UIFont systemFontOfSize:14]];
    self.textLabel.adjustsFontForContentSizeCategory = YES;
    self.detailTextLabel.adjustsFontForContentSizeCategory = YES;
}

+ (void)cyl_setUpAutomaticRowHeightForTableView:(UITableView *)tableView {
    tableView.rowHeight = UITableViewAutomaticDimension;
    tableView.estimatedRowHeight = CYLBadgeRowHeight;
}

+ (NSString *)cyl_badgeTitleForRow:(NSInteger)row {
    NSDictionary *item = [self cyl_badgeItemForRow:row];
    NSString *title = item[CYLBadgeItemTitle];
    NSString *api = item[CYLBadgeItemAPI];
    // The core API in parentheses, like "Shake ×3 (cyl_shakeAnimationRepeatTimes)", whose title already names it.
    if (api.length > 0 && [title rangeOfString:api].location == NSNotFound) {
        title = [NSString stringWithFormat:@"%@ (%@)", title, api];
    }
    return [NSString stringWithFormat:@"%@. %@", @(row + 1), title];
}

+ (NSInteger)cyl_badgeStyleCount {
    return (NSInteger)[self cyl_badgeItems].count;
}

- (void)cyl_showBadgeForRow:(NSInteger)row {
    NSDictionary *item = [UITableViewCell cyl_badgeItemForRow:row];
    // The sample title (`+cyl_badgeTitleForRow:`, the subtitle in most lists) ends with its API name; a long one is cut
    // in the middle, so the name stays readable.
    self.detailTextLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    UIImageView *iconView = self.imageView;
    iconView.image = [UITableViewCell cyl_badgeIcon];
    iconView.clipsToBounds = NO;
    // Lay out the icon now, so the badge is created right away and a factory animation can be added to it.
    [self layoutIfNeeded];

    // Cells are reused: clear the badge, stop the previous row's animation (showing a badge without an animation type
    // does not remove it), and drop the previous row's options so they follow `CYLBadgeAppearance` again (#425).
    // Then set only what this row changes.
    [iconView.cyl_badge.layer removeAllAnimations];
    [iconView cyl_clearBadge];
    [iconView cyl_resetBadgeAppearance];
    if (item[CYLBadgeItemColors]) {
        iconView.cyl_badgeBackgroundColor = [UIColor purpleColor];
        iconView.cyl_badgeTextColor = [UIColor yellowColor];
    }
    if (item[CYLBadgeItemFont]) {
        iconView.cyl_badgeFont = [UIFont italicSystemFontOfSize:12];
    }
    if (item[CYLBadgeItemBorder] || item[CYLBadgeItemDynamicBorder]) {
        iconView.cyl_badgeBorderColor = item[CYLBadgeItemBorder] ? [UIColor whiteColor] : CYLBadgeHelperDynamicBorderColor();
        iconView.cyl_badgeBorderWidth = 2;
    }
    if (item[CYLBadgeItemPosition]) {
        iconView.cyl_badgeCenterOffset = CYLBadgeHelperCenterOffset(item[CYLBadgeItemPosition]);
    }
    if (item[CYLBadgeItemRadius]) {
        iconView.cyl_badgeRadius = [item[CYLBadgeItemRadius] floatValue];
    }
    if (item[CYLBadgeItemMargin]) {
        iconView.cyl_badgeMargin = [item[CYLBadgeItemMargin] floatValue];
    }
    if (item[CYLBadgeItemCornerRadius]) {
        iconView.cyl_badgeCornerRadius = [item[CYLBadgeItemCornerRadius] floatValue];
    }
    if (item[CYLBadgeItemMaximum]) {
        iconView.cyl_badgeMaximumBadgeNumber = [item[CYLBadgeItemMaximum] integerValue];
    }
    iconView.cyl_badgeRespectsReduceMotion = [item[CYLBadgeItemReduceMotion] boolValue];
    // Options must be set before showing the badge.
    CYLBadgeAnimationType animationType = (CYLBadgeAnimationType)[item[CYLBadgeItemAnimationType] unsignedIntegerValue];
    [iconView cyl_showBadgeValue:item[CYLBadgeItemValue] animationType:animationType];

    UIView *badge = iconView.cyl_badge;
    CAAnimation *animation = badge ? CYLBadgeHelperAnimation(item[CYLBadgeItemFactoryAnimation], badge) : nil;
    if (animation) {
        [badge.layer addAnimation:animation forKey:CYLBadgeHelperAnimationKey];
    }
}

@end

static NSString *const CYLBadgeHelperCellIdentifier = @"CYLBadgeHelperCell";

@implementation UIViewController (CYLNavigationBadge)

- (UIBarButtonItem *)cyl_showNavigationBadgeValue:(NSString *)value
                                    animationType:(CYLBadgeAnimationType)animationType
                                  backgroundColor:(UIColor *)backgroundColor {
    UIBarButtonItem *item = self.navigationItem.rightBarButtonItem;
    if (!item) {
        if (@available(iOS 13.0, *)) {
            item = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"bell"] style:UIBarButtonItemStylePlain
                                                   target:nil action:NULL];
        } else {
            item = [[UIBarButtonItem alloc] initWithTitle:CYLLocalizedString(@"Badge") style:UIBarButtonItemStylePlain
                                                   target:nil action:NULL];
        }
        self.navigationItem.rightBarButtonItem = item;
    }
    [item cyl_showBadgeValue:value ?: @"" animationType:animationType backgroundColor:backgroundColor];
    return item;
}

@end

@implementation CYLBadgeHelperTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = CYLLocalizedString(@"Badge");
    [UITableViewCell cyl_setUpAutomaticRowHeightForTableView:self.tableView];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CYLBadgeHelperCellIdentifier];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == CYLSettingsSection ? [self cyl_settingsRowCount] : [UITableViewCell cyl_badgeStyleCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == CYLSettingsSection) {
        return [self cyl_settingsCellForTableView:tableView atIndexPath:indexPath];
    }
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLBadgeHelperCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [UITableViewCell cyl_badgeTitleForRow:indexPath.row];
    [cell cyl_wrapsTextLabels];
    [cell cyl_showBadgeForRow:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == CYLSettingsSection) {
        [self cyl_didSelectSettingsRowAtIndexPath:indexPath inTableView:tableView];
        return;
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [[tableView cellForRowAtIndexPath:indexPath].imageView cyl_clearBadge];
    !self.didSelectRowHandler ?: self.didSelectRowHandler(indexPath);
    // Issues #426, #428: a tap also simulates a memory warning and logs the tab bar's state afterwards, to check
    // that the tab Lottie icons keep their speed and the badges stay. 点击同时模拟内存警告并输出之后的 TabBar 状态。
    [CYLTabBarController cyl_simulateMemoryWarning];
}

@end

@implementation UIViewController (CYLBadgeExtention)

- (void)cyl_addBadgeHelperTable {
    CYLBadgeHelperTableViewController *badgeHelper = [[CYLBadgeHelperTableViewController alloc] initWithStyle:UITableViewStylePlain];
    [self addChildViewController:badgeHelper];
    badgeHelper.view.frame = self.view.bounds;
    badgeHelper.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:badgeHelper.view];
    [badgeHelper didMoveToParentViewController:self];
}

@end

