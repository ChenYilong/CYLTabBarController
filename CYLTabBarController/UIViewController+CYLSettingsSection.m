//
//  UIViewController+CYLSettingsSection.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIViewController+CYLSettingsSection.h"
#import "CYLLocalization.h"
#import "UIViewController+CYLMemoryWarning.h"
#import "UIViewController+CYLTabBarItemUpdate.h"
#import "UIViewController+CYLThemeSettings.h"
#import "UITableViewCell+CYLBadgeExtention.h"
#import "CYLTabBarController.h"
#import "CYLPlusButton.h"
#import "UIView+CYLUtils.h"
#import "NSObject+CYLUtils.h"
#import <objc/runtime.h>

const NSInteger CYLSettingsSection = 0;

/// [EN] Rows of the settings section; the tab item update rows follow (`UIViewController+CYLTabBarItemUpdate.h`).
/// [CN] 设置分组的行；其后是更新 Tab 的若干行（`UIViewController+CYLTabBarItemUpdate.h`）。
typedef NS_ENUM(NSInteger, CYLSettingsRow) {
    CYLSettingsRowLanguage,
    CYLSettingsRowMemoryWarning,
    CYLSettingsRowTitlePositionAdjustment,
    CYLSettingsRowStandardAppearance,
    CYLSettingsRowLoginState,
    CYLSettingsRowPlusButtonTouchableArea,
    CYLSettingsRowSelectedIndexIgnoringPlusButton, // FIX: issue #515
    CYLSettingsRowTabBarMinimizeBehavior, // issue #13
    CYLSettingsRowTabButtonTapAnimation,     // FIX: issue #535
    CYLSettingsRowTabButtonLongPress,        // FIX: issue #535
    CYLSettingsRowSwipeToSwitchTab,          // FIX: issue #535
    CYLSettingsRowOutsideSuperviewBounds,    // FIX: issue #535
    CYLSettingsRowBundleImage,               // FIX: issue #535
    CYLSettingsRowNavigationWithoutBaseClass, // FIX: issue #535
    CYLSettingsRowSlideTransition,           // FIX: issue #535
    CYLSettingsRowTapFeedback,               // FIX: issue #535
    CYLSettingsRowGestureTiming,             // FIX: issue #535 / #152
    CYLSettingsRowSwitchAdjacentTab,         // FIX: issue #535
    CYLSettingsRowUtilsHelpers,              // FIX: issue #535
    CYLSettingsRowTheme,                // issue #216, see UIViewController+CYLThemeSettings.h
    CYLSettingsRowScrollHideSimulation,   // issue #13: simulated interruptions, in an action sheet
    CYLSettingsRowTabBarItemUpdate,     // then one row per tab item update, see UIViewController+CYLTabBarItemUpdate.h
};

static NSString *const CYLTitlePositionAdjustmentCellIdentifier = @"CYLTitlePositionAdjustmentCell";

/*!
 * FIX: issue #475
 * [EN] The vertical title offsets the demo row cycles through.
 * [CN] 演示行依次切换的标题垂直偏移。
 */
static const CGFloat CYLDemoTitleVerticalOffsets[] = { 0, -4, 4 };
static const NSUInteger CYLDemoTitleVerticalOffsetsCount = sizeof(CYLDemoTitleVerticalOffsets) / sizeof(CYLDemoTitleVerticalOffsets[0]);

static CYLTabBarController *_Nullable CYLSettingsTabBarController(UIViewController *viewController) {
    return [viewController cyl_owningTabBarController] ?: [viewController cyl_tabBarController];
}

static UITableViewCell *CYLTitlePositionAdjustmentCell(UITableView *tableView, CYLTabBarController *_Nullable tabBarController) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLTitlePositionAdjustmentCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLTitlePositionAdjustmentCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"arrow.up.arrow.down"];
        }
    }
    UIOffset offset = tabBarController ? tabBarController.titlePositionAdjustment : UIOffsetZero;
    NSString *offsetText = [NSString stringWithFormat:@"(%g, %g)", offset.horizontal, offset.vertical];
    cell.textLabel.text = CYLLocalizedString(@"标题偏移（titlePositionAdjustment）");
    cell.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"点击切换所有 Tab 标题的垂直偏移，当前：%@"), offsetText];
    return cell;
}

/*!
 * [EN] Moves every tab title to the next offset of `CYLDemoTitleVerticalOffsets` with the public setter
 *      `-[CYLTabBarController setTitlePositionAdjustment:]`, which re-applies it at runtime on all tab bar styles.
 * [CN] 通过公开的 setter `-[CYLTabBarController setTitlePositionAdjustment:]` 将所有 Tab 标题切换到
 *      `CYLDemoTitleVerticalOffsets` 中的下一个偏移，运行时对所有 TabBar 样式生效。
 */
static void CYLSwitchTitlePositionAdjustment(CYLTabBarController *_Nullable tabBarController) {
    if (!tabBarController) {
        return;
    }
    CGFloat current = tabBarController.titlePositionAdjustment.vertical;
    NSUInteger next = 0;
    for (NSUInteger idx = 0; idx < CYLDemoTitleVerticalOffsetsCount; idx++) {
        if (fabs(CYLDemoTitleVerticalOffsets[idx] - current) < 0.5) {
            next = (idx + 1) % CYLDemoTitleVerticalOffsetsCount;
            break;
        }
    }
    tabBarController.titlePositionAdjustment = UIOffsetMake(0, CYLDemoTitleVerticalOffsets[next]);
}

#pragma mark - standardAppearance themes

static NSString *const CYLStandardAppearanceCellIdentifier = @"CYLStandardAppearanceCell";

/*!
 * [EN] Demo themes for `tabBar.standardAppearance`. The same appearance object styles the system tab bar (Liquid Glass
 *      and the classic style) and the FlatDesign tab bar, see `-[CYLFlatDesignTabBar standardAppearance]`.
 * [CN] `tabBar.standardAppearance` 的演示主题。同一个 appearance 对象同时作用于系统 TabBar（液态玻璃与经典样式）与扁平样式 TabBar，
 *      见 `-[CYLFlatDesignTabBar standardAppearance]`。
 */
typedef NS_ENUM(NSInteger, CYLDemoAppearanceTheme) {
    CYLDemoAppearanceThemeOriginal,
    CYLDemoAppearanceThemeDark,
    CYLDemoAppearanceThemeCenteredCapsule,
    CYLDemoAppearanceThemeGreenLine,
    CYLDemoAppearanceThemeCount,
};

static char CYLDemoAppearanceThemeKey;
static char CYLDemoOriginalStandardAppearanceKey;
static char CYLDemoOriginalScrollEdgeAppearanceKey;

static NSString *CYLDemoAppearanceThemeName(CYLDemoAppearanceTheme theme) {
    switch (theme) {
        case CYLDemoAppearanceThemeDark:
            return CYLLocalizedString(@"深色");
        case CYLDemoAppearanceThemeCenteredCapsule:
            return CYLLocalizedString(@"居中胶囊");
        case CYLDemoAppearanceThemeGreenLine:
            return CYLLocalizedString(@"绿色描边");
        default:
            return CYLLocalizedString(@"原始");
    }
}

/// A capsule for `selectionIndicatorImage`: resizable and template, so `selectionIndicatorTintColor` colors it.
/// 用作 `selectionIndicatorImage` 的胶囊：可拉伸的模板图片，由 `selectionIndicatorTintColor` 着色。
static UIImage *CYLDemoCapsuleImage(void) API_AVAILABLE(ios(13.0)) {
    CGSize size = CGSizeMake(32, 32);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [[UIColor blackColor] setFill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectInset(CGRectMake(0, 0, size.width, size.height), 2, 4) cornerRadius:12] fill];
    }];
    image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(15, 15, 15, 15)];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

static void CYLDemoSetItemColors(UITabBarAppearance *appearance, UIColor *normalColor, UIColor *selectedColor) API_AVAILABLE(ios(13.0)) {
    for (UITabBarItemAppearance *itemAppearance in @[ appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance ]) {
        itemAppearance.normal.iconColor = normalColor;
        itemAppearance.normal.titleTextAttributes = @{ NSForegroundColorAttributeName : normalColor };
        itemAppearance.selected.iconColor = selectedColor;
        itemAppearance.selected.titleTextAttributes = @{ NSForegroundColorAttributeName : selectedColor };
    }
}

static UITabBarAppearance *CYLDemoAppearanceForTheme(CYLDemoAppearanceTheme theme) API_AVAILABLE(ios(13.0)) {
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    switch (theme) {
        case CYLDemoAppearanceThemeDark: {
            [appearance configureWithOpaqueBackground];
            appearance.backgroundColor = [UIColor colorWithWhite:0.08 alpha:1];
            appearance.shadowColor = [UIColor clearColor];
            CYLDemoSetItemColors(appearance, [UIColor lightGrayColor], [UIColor whiteColor]);
            appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = [UIColor systemOrangeColor];
            break;
        }
        case CYLDemoAppearanceThemeCenteredCapsule: {
            appearance.stackedItemPositioning = UITabBarItemPositioningCentered;
            appearance.stackedItemWidth = 64;
            appearance.stackedItemSpacing = 8;
            appearance.selectionIndicatorImage = CYLDemoCapsuleImage();
            appearance.selectionIndicatorTintColor = [[UIColor systemPinkColor] colorWithAlphaComponent:0.2];
            CYLDemoSetItemColors(appearance, [UIColor systemGrayColor], [UIColor systemPinkColor]);
            appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = [UIColor systemPurpleColor];
            break;
        }
        case CYLDemoAppearanceThemeGreenLine: {
            [appearance configureWithOpaqueBackground];
            appearance.backgroundColor = [UIColor systemBackgroundColor];
            appearance.shadowColor = [UIColor systemGreenColor];
            CYLDemoSetItemColors(appearance, [UIColor secondaryLabelColor], [UIColor systemGreenColor]);
            appearance.stackedLayoutAppearance.normal.badgePositionAdjustment = UIOffsetMake(2, -2);
            break;
        }
        default:
            break;
    }
    return appearance;
}

static UITableViewCell *CYLStandardAppearanceCell(UITableView *tableView, CYLTabBarController *_Nullable tabBarController) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLStandardAppearanceCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLStandardAppearanceCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"paintpalette"];
        }
    }
    CYLTabBarController *controller = tabBarController;
    CYLDemoAppearanceTheme theme = controller ? [objc_getAssociatedObject(controller, &CYLDemoAppearanceThemeKey) integerValue] : CYLDemoAppearanceThemeOriginal;
    cell.textLabel.text = CYLLocalizedString(@"standardAppearance 主题（液态玻璃与扁平样式共用）");
    cell.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"点击切换 tabBar.standardAppearance，当前：%@"), CYLDemoAppearanceThemeName(theme)];
    return cell;
}

/*!
 * [EN] Assigns the next theme to `tabBar.standardAppearance` (and `scrollEdgeAppearance`). Nothing else is needed: the
 *      FlatDesign tab bar follows the system tab bar's appearance. "Original" puts back what the app had set.
 * [CN] 将下一个主题赋给 `tabBar.standardAppearance`（以及 `scrollEdgeAppearance`）。无需其他代码：扁平样式 TabBar 跟随系统 TabBar
 *      的 appearance。“原始”恢复 App 原先的设置。
 */
static void CYLSwitchStandardAppearance(CYLTabBarController *_Nullable owningTabBarController) {
    CYLTabBarController *tabBarController = owningTabBarController;
    if (!tabBarController) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        UITabBar *tabBar = tabBarController.tabBar;
        if (!objc_getAssociatedObject(tabBarController, &CYLDemoOriginalStandardAppearanceKey)) {
            objc_setAssociatedObject(tabBarController, &CYLDemoOriginalStandardAppearanceKey, tabBar.standardAppearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (@available(iOS 15.0, *)) {
                objc_setAssociatedObject(tabBarController, &CYLDemoOriginalScrollEdgeAppearanceKey, tabBar.scrollEdgeAppearance ?: [NSNull null], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
        CYLDemoAppearanceTheme current = [objc_getAssociatedObject(tabBarController, &CYLDemoAppearanceThemeKey) integerValue];
        CYLDemoAppearanceTheme next = (current + 1) % CYLDemoAppearanceThemeCount;
        objc_setAssociatedObject(tabBarController, &CYLDemoAppearanceThemeKey, @(next), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        UITabBarAppearance *standardAppearance = objc_getAssociatedObject(tabBarController, &CYLDemoOriginalStandardAppearanceKey);
        id scrollEdgeAppearance = objc_getAssociatedObject(tabBarController, &CYLDemoOriginalScrollEdgeAppearanceKey);
        if (next != CYLDemoAppearanceThemeOriginal) {
            standardAppearance = CYLDemoAppearanceForTheme(next);
            scrollEdgeAppearance = standardAppearance;
        }
        tabBar.standardAppearance = standardAppearance;
        if (@available(iOS 15.0, *)) {
            tabBar.scrollEdgeAppearance = [scrollEdgeAppearance isKindOfClass:[UITabBarAppearance class]] ? scrollEdgeAppearance : nil;
        }
    }
}

#pragma mark - Login state (issue #19)

static NSString *const CYLLoginStateCellIdentifier = @"CYLLoginStateCell";

/// The titles of the tabs that need login, joined for display. 需要登录的 Tab 的标题，拼接后用于显示。
static NSString *CYLLoginRequiredTabTitles(CYLTabBarController *_Nullable owningTabBarController) {
    CYLTabBarController *tabBarController = owningTabBarController;
    if (!tabBarController) {
        return @"";
    }
    NSMutableArray<NSString *> *titles = [NSMutableArray array];
    for (UIViewController *viewController in tabBarController.viewControllers) {
        if (![tabBarController cyl_isLoginRequiredForViewController:viewController]) {
            continue;
        }
        NSString *title = viewController.tabBarItem.title ?: [viewController cyl_getViewControllerInsteadOfNavigationController].title;
        if (title.length > 0) {
            [titles addObject:title];
        }
    }
    return [titles componentsJoinedByString:CYLLocalizedString(@"、")];
}

/// Fills the login state cell: icon, state, and which tabs need login. 填充登录状态 cell：图标、状态，以及需要登录的 Tab。
static void CYLConfigureLoginStateCell(UITableViewCell *cell, CYLTabBarController *_Nullable owningTabBarController) {
    BOOL loggedIn = owningTabBarController.cyl_loggedIn;
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:loggedIn ? @"person.crop.circle.badge.checkmark" : @"person.crop.circle.badge.xmark"];
    }
    cell.textLabel.text = loggedIn ? CYLLocalizedString(@"登录状态：已登录") : CYLLocalizedString(@"登录状态：未登录");
    NSString *titles = CYLLoginRequiredTabTitles(owningTabBarController);
    if (titles.length > 0) {
        cell.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"打开开关表示已登录，关闭表示未登录（已缓存到本地）。未登录时点击「%@」会先弹出登录页，登录后自动切换到该 Tab；已登录时直接切换。"), titles];
    } else {
        cell.detailTextLabel.text = CYLLocalizedString(@"打开开关表示已登录，关闭表示未登录（已缓存到本地）。当前没有需要登录的 Tab。");
    }
}

/*!
 * [EN] The switch of the login state row: on means logged in. Flipping it sets `cyl_loggedIn`; it also follows
 *      `CYLTabBarLoginStateDidChangeNotification`, so it stays right after logging in from the login alert or in
 *      another list.
 * [CN] 登录状态行的开关：打开表示已登录。拨动开关会设置 `cyl_loggedIn`；同时监听 `CYLTabBarLoginStateDidChangeNotification`，
 *      通过登录弹窗登录或在其他列表中切换后也保持正确。
 */
@interface CYLLoginStateSwitch : UISwitch
@property (nonatomic, weak, nullable) CYLTabBarController *tabBarController;
@property (nonatomic, weak, nullable) UITableViewCell *cell;
@end

@implementation CYLLoginStateSwitch

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addTarget:self action:@selector(cyl_valueDidChange) forControlEvents:UIControlEventValueChanged];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cyl_loginStateDidChange) name:CYLTabBarLoginStateDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)cyl_valueDidChange {
    self.tabBarController.cyl_loggedIn = self.isOn;
}

- (void)cyl_loginStateDidChange {
    CYLTabBarController *tabBarController = self.tabBarController;
    BOOL loggedIn = tabBarController.cyl_loggedIn;
    if (self.isOn != loggedIn) {
        [self setOn:loggedIn animated:YES];
    }
    UITableViewCell *cell = self.cell;
    if (cell) {
        CYLConfigureLoginStateCell(cell, tabBarController);
    }
}

@end

static UITableViewCell *CYLLoginStateCell(UITableView *tableView, CYLTabBarController *_Nullable owningTabBarController) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLLoginStateCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLLoginStateCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        cell.accessoryView = [[CYLLoginStateSwitch alloc] initWithFrame:CGRectZero];
    }
    CYLLoginStateSwitch *loginSwitch = (CYLLoginStateSwitch *)cell.accessoryView;
    if ([loginSwitch isKindOfClass:[CYLLoginStateSwitch class]]) {
        loginSwitch.tabBarController = owningTabBarController;
        loginSwitch.cell = cell;
        loginSwitch.on = owningTabBarController.cyl_loggedIn;
    }
    CYLConfigureLoginStateCell(cell, owningTabBarController);
    return cell;
}

/// A tap on the row flips the switch too. 点击该行同样会拨动开关。
static void CYLToggleLoginState(CYLTabBarController *_Nullable owningTabBarController) {
    CYLTabBarController *tabBarController = owningTabBarController;
    tabBarController.cyl_loggedIn = !tabBarController.cyl_loggedIn;
}

#pragma mark - PlusButton touchable area (issue #91)

static NSString *const CYLTouchableAreaCellIdentifier = @"CYLTouchableAreaCell";

/*!
 * [EN] Issue #91 demo row: a switch shows the plus button's touchable area as a translucent overlay (off restores the
 *      normal look), and a slider multiplies the area from 1x to 3x (`touchableAreaScale`). Works in every style; only
 *      when the tab bar controller has a plus button.
 * [CN] Issue #91 演示行：开关以半透明覆盖层显示 PlusButton 的可点击区域（关闭即恢复正常外观），滑块按 1 至 3 倍扩大可点击区域
 *      （`touchableAreaScale`）。适用于所有样式；仅在 TabBarController 有 PlusButton 时可用。
 */
@interface CYLTouchableAreaCell : UITableViewCell
@property (nonatomic, weak, nullable) CYLTabBarController *tabBarController;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UISlider *scaleSlider;
@property (nonatomic, strong) UISwitch *overlaySwitch;
@end

@implementation CYLTouchableAreaCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        _titleLabel.numberOfLines = 0;
        _summaryLabel = [[UILabel alloc] init];
        _summaryLabel.font = [UIFont systemFontOfSize:14];
        if (@available(iOS 13.0, *)) {
            // [EN] As the other rows' subtitles: a brighter gray in Dark Mode. [CN] 与其他行的副标题一致：深色模式下为更亮的灰色。
            _summaryLabel.textColor = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
                return traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark ? [UIColor colorWithWhite:0.80 alpha:1] : UIColor.secondaryLabelColor;
            }];
        } else {
            _summaryLabel.textColor = [UIColor grayColor];
        }
        _summaryLabel.numberOfLines = 0;
        _scaleSlider = [[UISlider alloc] init];
        _scaleSlider.minimumValue = 1.0;
        _scaleSlider.maximumValue = 3.0;
        [_scaleSlider addTarget:self action:@selector(cyl_scaleDidChange) forControlEvents:UIControlEventValueChanged];
        _overlaySwitch = [[UISwitch alloc] init];
        [_overlaySwitch addTarget:self action:@selector(cyl_overlayDidChange) forControlEvents:UIControlEventValueChanged];
        self.accessoryView = _overlaySwitch;

        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[ _titleLabel, _summaryLabel, _scaleSlider ]];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.spacing = 6;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:stackView];
        UILayoutGuide *margins = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [stackView.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
            [stackView.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
            [stackView.topAnchor constraintEqualToAnchor:margins.topAnchor],
            [stackView.bottomAnchor constraintEqualToAnchor:margins.bottomAnchor],
        ]];
    }
    return self;
}

/// [EN] The plus button of this tab bar controller, guarded by `-hasPlusButton`.
/// [CN] 本 TabBarController 的 PlusButton，先判断 `-hasPlusButton`。
- (nullable CYLPlusButton *)cyl_touchableAreaPlusButton {
    CYLTabBarController *tabBarController = self.tabBarController;
    if (!tabBarController || ![tabBarController hasPlusButton]) {
        return nil;
    }
    return [CYLPlusButton plusButtonForOwner:tabBarController];
}

- (void)cyl_reloadTouchableArea {
    CYLPlusButton *plusButton = [self cyl_touchableAreaPlusButton];
    self.titleLabel.text = CYLLocalizedString(@"PlusButton 点击范围（issue #91）");
    self.scaleSlider.enabled = (plusButton != nil);
    self.overlaySwitch.enabled = (plusButton != nil);
    if (!plusButton) {
        self.summaryLabel.text = CYLLocalizedString(@"当前 TabBar 没有 PlusButton");
        self.scaleSlider.value = 1.0;
        self.overlaySwitch.on = NO;
        return;
    }
    self.scaleSlider.value = plusButton.touchableAreaScale;
    self.overlaySwitch.on = plusButton.showsTouchableArea;
    NSString *scaleText = [NSString stringWithFormat:@"%.1f", plusButton.touchableAreaScale];
    self.summaryLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"打开开关以半透明红色显示可点击区域，关闭恢复正常；拖动滑块按倍数扩大点击范围，当前：%@ 倍"), scaleText];
}

- (void)cyl_scaleDidChange {
    // [EN] Steps of 0.1.
    // [CN] 以 0.1 为步长。
    CGFloat scale = round(self.scaleSlider.value * 10.0) / 10.0;
    [self cyl_touchableAreaPlusButton].touchableAreaScale = scale;
    [self cyl_reloadTouchableArea];
}

- (void)cyl_overlayDidChange {
    [self cyl_touchableAreaPlusButton].showsTouchableArea = self.overlaySwitch.isOn;
    [self cyl_reloadTouchableArea];
}

@end

static UITableViewCell *CYLTouchableAreaCellForTableView(UITableView *tableView, CYLTabBarController *_Nullable tabBarController) {
    CYLTouchableAreaCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLTouchableAreaCellIdentifier];
    if (![cell isKindOfClass:[CYLTouchableAreaCell class]]) {
        cell = [[CYLTouchableAreaCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CYLTouchableAreaCellIdentifier];
    }
    cell.tabBarController = tabBarController;
    [cell cyl_reloadTouchableArea];
    return cell;
}

#pragma mark - selectedIndex and the plus button (issue #515)

static NSString *const CYLSelectedIndexCellIdentifier = @"CYLSelectedIndexCell";

/*!
 * [EN] Issue #515 demo row: a tap selects the next tab with `cyl_selectedIndexIgnoringPlusButton`; the text shows that
 *      index next to `selectedIndex`, which also counts the plus button's child view controller or placeholder.
 * [CN] Issue #515 演示行：点击通过 `cyl_selectedIndexIgnoringPlusButton` 选中下一个 Tab；文字同时显示该下标与 `selectedIndex`
 *      （后者还会计入 PlusButton 的子控制器或占位控制器）。
 */
static UITableViewCell *CYLSelectedIndexCell(UITableView *tableView, CYLTabBarController *_Nullable tabBarController) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLSelectedIndexCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLSelectedIndexCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"arrow.right.square"];
        }
    }
    NSUInteger indexIgnoringPlusButton = tabBarController ? tabBarController.cyl_selectedIndexIgnoringPlusButton : NSNotFound;
    NSUInteger selectedIndex = tabBarController ? tabBarController.selectedIndex : NSNotFound;
    UIViewController *selectedViewController = [tabBarController.selectedViewController cyl_getViewControllerInsteadOfNavigationController];
    NSString *title = selectedViewController.tabBarItem.title ?: tabBarController.selectedViewController.tabBarItem.title ?: @"-";
    NSString *indexText = (indexIgnoringPlusButton == NSNotFound) ? @"-" : [NSString stringWithFormat:@"%@", @(indexIgnoringPlusButton)];
    NSString *selectedIndexText = (selectedIndex == NSNotFound) ? @"-" : [NSString stringWithFormat:@"%@", @(selectedIndex)];
    cell.textLabel.text = CYLLocalizedString(@"selectedIndex 与 PlusButton（issue #515）");
    cell.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"点击切换到下一个 Tab。不含 PlusButton 的下标：%1$@，selectedIndex：%2$@，当前：%3$@"), indexText, selectedIndexText, title];
    return cell;
}

/// [EN] Selects the next tab, by its index without the plus button. [CN] 按不含 PlusButton 的下标选中下一个 Tab。
static void CYLSelectNextTabIgnoringPlusButton(CYLTabBarController *_Nullable tabBarController) {
    NSUInteger count = tabBarController.cyl_viewControllersIgnoringPlusButton.count;
    if (!tabBarController || count == 0) {
        return;
    }
    NSUInteger current = tabBarController.cyl_selectedIndexIgnoringPlusButton;
    NSUInteger next = (current == NSNotFound) ? 0 : (current + 1) % count;
    tabBarController.cyl_selectedIndexIgnoringPlusButton = next;
}

#pragma mark - Tap animation, long press, swipe (issue #535)

static NSString *const CYLTabButtonTapAnimationCellIdentifier = @"CYLTabButtonTapAnimationCell";
static NSString *const CYLInteractionSwitchCellIdentifier = @"CYLInteractionSwitchCell";

/// [EN] The demo's name of each tap animation type. [CN] 每种点击动画在演示中的名称。
static NSString *CYLTabButtonTapAnimationTypeName(CYLTabButtonTapAnimationType type) {
    switch (type) {
        case CYLTabButtonTapAnimationTypeScale: return CYLLocalizedString(@"放大再缩小");
        case CYLTabButtonTapAnimationTypeZoomIn: return CYLLocalizedString(@"从小放大");
        case CYLTabButtonTapAnimationTypeBounce: return CYLLocalizedString(@"弹性");
        case CYLTabButtonTapAnimationTypeBounceWithFireworks: return CYLLocalizedString(@"弹性 + 烟花");
        case CYLTabButtonTapAnimationTypeRotation: return CYLLocalizedString(@"旋转");
        case CYLTabButtonTapAnimationTypeFlip: return CYLLocalizedString(@"翻转");
        case CYLTabButtonTapAnimationTypeFume: return CYLLocalizedString(@"飘散");
        case CYLTabButtonTapAnimationTypeNone:
        default: return CYLLocalizedString(@"无");
    }
}

/*!
 * [EN] The demo cycles through every built-in type, then the two other ways to set an animation: one tab only
 *      (`viewController.cyl_tabButtonAnimation`) and an object for every tab (`cyl_defaultTabButtonAnimation`).
 * [CN] 演示依次切换所有内置类型，以及另外两种设置方式：只设置一个 Tab（`viewController.cyl_tabButtonAnimation`），
 *      以及所有 Tab 共用一个对象（`cyl_defaultTabButtonAnimation`）。
 */
typedef NS_ENUM(NSInteger, CYLDemoTapAnimationStep) {
    CYLDemoTapAnimationStepOneTabRotation = CYLTabButtonTapAnimationTypeFume + 1,
    CYLDemoTapAnimationStepDefaultFrameAnimation,
    // [EN] The classes with their properties set. [CN] 设置了属性的动画类。
    CYLDemoTapAnimationStepSlowScale,
    CYLDemoTapAnimationStepSlowZoomIn,
    CYLDemoTapAnimationStepStarFireworks,
    CYLDemoTapAnimationStepCurlUp,
    CYLDemoTapAnimationStepCount,
};

static char CYLDemoTapAnimationStepKey;

static NSInteger CYLCurrentDemoTapAnimationStep(CYLTabBarController *_Nullable tabBarController) {
    NSNumber *step = tabBarController ? objc_getAssociatedObject(tabBarController, &CYLDemoTapAnimationStepKey) : nil;
    return step ? step.integerValue : tabBarController.cyl_tabButtonTapAnimationType;
}

/// [EN] Frames for `CYLTabButtonFrameAnimation`: dots that grow. [CN] `CYLTabButtonFrameAnimation` 的帧：逐渐变大的圆点。
static NSArray<UIImage *> *CYLDemoFrameImages(void) {
    NSMutableArray<UIImage *> *images = [NSMutableArray array];
    for (NSInteger idx = 1; idx <= 6; idx++) {
        UIImage *image = [UIImage cyl_imageWithColor:[UIColor systemOrangeColor] size:CGSizeMake(6.0 * idx, 6.0 * idx) cornerRadius:3.0 * idx];
        if (image) {
            [images addObject:image];
        }
    }
    return images;
}

/// [EN] The animation classes with their properties set. [CN] 设置了属性的动画类。
static id<CYLTabButtonAnimation> _Nullable CYLDemoConfiguredTapAnimation(NSInteger step) {
    switch (step) {
        case CYLDemoTapAnimationStepSlowScale: {
            CYLTabButtonScaleAnimation *animation = [[CYLTabButtonScaleAnimation alloc] init];
            animation.duration = 1.2;
            return animation;
        }
        case CYLDemoTapAnimationStepSlowZoomIn: {
            CYLTabButtonZoomInAnimation *animation = [[CYLTabButtonZoomInAnimation alloc] init];
            animation.duration = 1.2;
            return animation;
        }
        case CYLDemoTapAnimationStepStarFireworks: {
            CYLTabButtonBounceAnimation *animation = [[CYLTabButtonBounceAnimation alloc] init];
            animation.playsFireworks = YES;
            if (@available(iOS 13.0, *)) {
                UIImageSymbolConfiguration *configuration = [UIImageSymbolConfiguration configurationWithPointSize:8];
                animation.fireworksImage = [[UIImage systemImageNamed:@"star.fill" withConfiguration:configuration] imageWithTintColor:[UIColor systemYellowColor] renderingMode:UIImageRenderingModeAlwaysOriginal];
            }
            return animation;
        }
        case CYLDemoTapAnimationStepCurlUp: {
            CYLTabButtonFlipAnimation *animation = [[CYLTabButtonFlipAnimation alloc] init];
            animation.direction = 5;
            animation.disablesDeselectAnimation = YES;
            return animation;
        }
        default:
            return nil;
    }
}

static NSString *CYLDemoTapAnimationStepName(NSInteger step) {
    if (step == CYLDemoTapAnimationStepOneTabRotation) {
        return CYLLocalizedString(@"旋转（仅当前 Tab：viewController.cyl_tabButtonAnimation）");
    }
    if (step == CYLDemoTapAnimationStepDefaultFrameAnimation) {
        return CYLLocalizedString(@"逐帧 + 烟花（所有 Tab：cyl_defaultTabButtonAnimation）");
    }
    if (step == CYLDemoTapAnimationStepSlowScale) {
        return CYLLocalizedString(@"慢速放大再缩小（CYLTabButtonScaleAnimation.duration = 1.2）");
    }
    if (step == CYLDemoTapAnimationStepSlowZoomIn) {
        return CYLLocalizedString(@"慢速从小放大（CYLTabButtonZoomInAnimation.duration = 1.2）");
    }
    if (step == CYLDemoTapAnimationStepStarFireworks) {
        return CYLLocalizedString(@"弹性 + 星星烟花（CYLTabButtonBounceAnimation.fireworksImage）");
    }
    if (step == CYLDemoTapAnimationStepCurlUp) {
        return CYLLocalizedString(@"向上卷页，取消选中无动画（CYLTabButtonFlipAnimation.direction = 5）");
    }
    return CYLTabButtonTapAnimationTypeName((CYLTabButtonTapAnimationType)step);
}

static UITableViewCell *CYLTabButtonTapAnimationCell(UITableView *tableView, CYLTabBarController *_Nullable tabBarController) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLTabButtonTapAnimationCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLTabButtonTapAnimationCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"sparkles"];
        }
    }
    cell.textLabel.text = CYLLocalizedString(@"Tab 点击动画（issue #535）");
    cell.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"点击切换 Tab 与 PlusButton 的点击动画，当前：%@"), CYLDemoTapAnimationStepName(CYLCurrentDemoTapAnimationStep(tabBarController))];
    return cell;
}

/*!
 * [EN] Moves to the next built-in tap animation, and plays it on the selected tab so the change is visible at once.
 * [CN] 切换到下一个内置点击动画，并在当前选中的 Tab 上播放，立即看到效果。
 */
static void CYLSwitchTabButtonTapAnimation(CYLTabBarController *_Nullable tabBarController) {
    if (!tabBarController) {
        return;
    }
    NSInteger next = (CYLCurrentDemoTapAnimationStep(tabBarController) + 1) % CYLDemoTapAnimationStepCount;
    objc_setAssociatedObject(tabBarController, &CYLDemoTapAnimationStepKey, @(next), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // [EN] Reset the other two ways first, so only the current step applies.
    // [CN] 先清除另外两种设置，只保留当前步骤。
    tabBarController.cyl_defaultTabButtonAnimation = nil;
    for (UIViewController *viewController in tabBarController.viewControllers) {
        viewController.cyl_tabButtonAnimation = nil;
    }
    if (next == CYLDemoTapAnimationStepOneTabRotation) {
        tabBarController.cyl_tabButtonTapAnimationType = CYLTabButtonTapAnimationTypeNone;
        tabBarController.selectedViewController.cyl_tabButtonAnimation = [[CYLTabButtonRotationAnimation alloc] init];
    } else if (next == CYLDemoTapAnimationStepDefaultFrameAnimation) {
        tabBarController.cyl_tabButtonTapAnimationType = CYLTabButtonTapAnimationTypeNone;
        CYLTabButtonFrameAnimation *frameAnimation = [[CYLTabButtonFrameAnimation alloc] init];
        frameAnimation.images = CYLDemoFrameImages();
        frameAnimation.playsFireworks = YES;
        tabBarController.cyl_defaultTabButtonAnimation = frameAnimation;
    } else if (next >= CYLDemoTapAnimationStepSlowScale) {
        tabBarController.cyl_tabButtonTapAnimationType = CYLTabButtonTapAnimationTypeNone;
        tabBarController.cyl_defaultTabButtonAnimation = CYLDemoConfiguredTapAnimation(next);
    } else {
        tabBarController.cyl_tabButtonTapAnimationType = (CYLTabButtonTapAnimationType)next;
    }
    UIControl *selectedTabButton = tabBarController.selectedViewController.cyl_tabButton;
    if (selectedTabButton) {
        [tabBarController cyl_playTabButtonAnimationForControl:selectedTabButton];
    }
}

typedef NS_ENUM(NSInteger, CYLInteractionDemoSwitchKind) {
    CYLInteractionDemoSwitchKindLongPress,
    CYLInteractionDemoSwitchKindSwipe,
};

static BOOL CYLInteractionDemoSwitchIsOn(CYLTabBarController *_Nullable tabBarController, CYLInteractionDemoSwitchKind kind) {
    if (kind == CYLInteractionDemoSwitchKindSwipe) {
        return tabBarController.cyl_swipeToSwitchTabEnabled;
    }
    return tabBarController.cyl_didLongPressControlBlock != nil;
}

static void CYLInteractionDemoSwitchApply(CYLTabBarController *_Nullable tabBarController, CYLInteractionDemoSwitchKind kind, BOOL on) {
    if (!tabBarController) {
        return;
    }
    if (kind == CYLInteractionDemoSwitchKindSwipe) {
        tabBarController.cyl_swipeToSwitchTabEnabled = on;
        return;
    }
    if (!on) {
        tabBarController.cyl_didLongPressControlBlock = nil;
        return;
    }
    tabBarController.cyl_didLongPressControlBlock = ^(CYLTabBarController *pressedTabBarController, UIControl *control) {
        NSString *name = control.cyl_tabBarItemIdentifier ?: NSStringFromClass([control class]);
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:CYLLocalizedString(@"长按了「%@」"), name]
                                                                       message:nil
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"取消") style:UIAlertActionStyleCancel handler:nil]];
        [pressedTabBarController presentViewController:alert animated:YES completion:nil];
    };
}

/*!
 * [EN] The switch of the long press and swipe rows. Long press: the demo block shows the identifier of the pressed
 *      button. Swipe: `cyl_swipeToSwitchTabEnabled`.
 * [CN] 长按与滑动两行的开关。长按：演示 block 弹出被长按按钮的标识。滑动：`cyl_swipeToSwitchTabEnabled`。
 */
@interface CYLInteractionDemoSwitch : UISwitch
@property (nonatomic, weak, nullable) CYLTabBarController *tabBarController;
@property (nonatomic, assign) CYLInteractionDemoSwitchKind kind;
@end

@implementation CYLInteractionDemoSwitch

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addTarget:self action:@selector(cyl_valueDidChange) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)cyl_valueDidChange {
    CYLInteractionDemoSwitchApply(self.tabBarController, self.kind, self.isOn);
}

@end

static UITableViewCell *CYLInteractionSwitchCell(UITableView *tableView, CYLTabBarController *_Nullable tabBarController, CYLInteractionDemoSwitchKind kind) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLInteractionSwitchCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLInteractionSwitchCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        cell.accessoryView = [[CYLInteractionDemoSwitch alloc] initWithFrame:CGRectZero];
    }
    CYLInteractionDemoSwitch *demoSwitch = (CYLInteractionDemoSwitch *)cell.accessoryView;
    if ([demoSwitch isKindOfClass:[CYLInteractionDemoSwitch class]]) {
        demoSwitch.tabBarController = tabBarController;
        demoSwitch.kind = kind;
        demoSwitch.on = CYLInteractionDemoSwitchIsOn(tabBarController, kind);
    }
    BOOL isSwipe = (kind == CYLInteractionDemoSwitchKindSwipe);
    if (@available(iOS 13.0, *)) {
        cell.imageView.image = [UIImage systemImageNamed:isSwipe ? @"hand.draw" : @"hand.tap"];
    }
    cell.textLabel.text = isSwipe ? CYLLocalizedString(@"左右滑动切换 Tab（issue #535）") : CYLLocalizedString(@"长按 Tab（issue #535）");
    cell.detailTextLabel.text = isSwipe ? CYLLocalizedString(@"打开开关后在页面上左右滑动，切换到下一个或上一个 Tab。")
                                        : CYLLocalizedString(@"打开开关后长按任意 Tab 或 PlusButton，会弹出该按钮的标识。");
    return cell;
}

/// [EN] A tap on the row flips its switch. [CN] 点击该行同样会拨动开关。
static void CYLToggleInteractionSwitch(UITableView *tableView, NSIndexPath *indexPath, CYLTabBarController *_Nullable tabBarController, CYLInteractionDemoSwitchKind kind) {
    BOOL on = !CYLInteractionDemoSwitchIsOn(tabBarController, kind);
    CYLInteractionDemoSwitchApply(tabBarController, kind, on);
    UISwitch *demoSwitch = (UISwitch *)[tableView cellForRowAtIndexPath:indexPath].accessoryView;
    if ([demoSwitch isKindOfClass:[UISwitch class]]) {
        [demoSwitch setOn:on animated:YES];
    }
}

#pragma mark - Subviews outside their superview (issue #535)

static NSString *const CYLOutsideBoundsCellIdentifier = @"CYLOutsideBoundsCell";

/*!
 * [EN] Issue #535 demo row: a gray box with a button that sticks out of it to the right. With the switch off, only the
 *      part inside the box responds; on sets `cyl_respondsOutsideSuperviewBounds` and the whole button responds. Each
 *      tap plays `-cyl_addScaleBounceAnimationWithCompletion:` and counts.
 * [CN] Issue #535 演示行：灰色方框中有一个向右超出方框的按钮。开关关闭时只有方框内的部分响应；打开即设置
 *      `cyl_respondsOutsideSuperviewBounds`，整个按钮都能响应。每次点击播放 `-cyl_addScaleBounceAnimationWithCompletion:` 并计数。
 */
@interface CYLOutsideBoundsCell : UITableViewCell
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *summaryLabel;
@property (nonatomic, strong) UIView *boxView;
@property (nonatomic, strong) UIButton *outsideButton;
@property (nonatomic, strong) UISwitch *outsideSwitch;
@property (nonatomic, assign) NSInteger tapCount;
@end

@implementation CYLOutsideBoundsCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont boldSystemFontOfSize:15];
        _titleLabel.numberOfLines = 0;
        _summaryLabel = [[UILabel alloc] init];
        _summaryLabel.font = [UIFont systemFontOfSize:12];
        _summaryLabel.textColor = [UIColor grayColor];
        _summaryLabel.numberOfLines = 0;
        _boxView = [[UIView alloc] init];
        _boxView.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.25];
        _boxView.translatesAutoresizingMaskIntoConstraints = NO;
        _outsideButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _outsideButton.backgroundColor = [UIColor systemBlueColor];
        _outsideButton.layer.cornerRadius = 6;
        [_outsideButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_outsideButton setTitle:CYLLocalizedString(@"点我") forState:UIControlStateNormal];
        // [EN] Inside the box (left half) and outside it (right half). [CN] 左半部分在方框内，右半部分在方框外。
        _outsideButton.frame = CGRectMake(40, 8, 80, 28);
        [_outsideButton addTarget:self action:@selector(cyl_outsideButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [_boxView addSubview:_outsideButton];
        _outsideSwitch = [[UISwitch alloc] init];
        [_outsideSwitch addTarget:self action:@selector(cyl_switchDidChange) forControlEvents:UIControlEventValueChanged];
        self.accessoryView = _outsideSwitch;

        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[ _titleLabel, _summaryLabel, _boxView ]];
        stackView.axis = UILayoutConstraintAxisVertical;
        stackView.alignment = UIStackViewAlignmentLeading;
        stackView.spacing = 6;
        stackView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:stackView];
        UILayoutGuide *margins = self.contentView.layoutMarginsGuide;
        [NSLayoutConstraint activateConstraints:@[
            [stackView.leadingAnchor constraintEqualToAnchor:margins.leadingAnchor],
            [stackView.trailingAnchor constraintEqualToAnchor:margins.trailingAnchor],
            [stackView.topAnchor constraintEqualToAnchor:margins.topAnchor],
            [stackView.bottomAnchor constraintEqualToAnchor:margins.bottomAnchor],
            [_boxView.widthAnchor constraintEqualToConstant:80],
            [_boxView.heightAnchor constraintEqualToConstant:44],
        ]];
        [self cyl_reload];
    }
    return self;
}

- (void)cyl_reload {
    self.titleLabel.text = CYLLocalizedString(@"超出父视图响应点击（issue #535）");
    self.outsideSwitch.on = self.outsideButton.cyl_respondsOutsideSuperviewBounds;
    self.summaryLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"打开开关后，点击灰色方框外的按钮部分也能响应；点击会播放放大再缩小动画。已点击：%@ 次"), @(self.tapCount)];
}

- (void)cyl_switchDidChange {
    self.outsideButton.cyl_respondsOutsideSuperviewBounds = self.outsideSwitch.isOn;
    [self cyl_reload];
}

- (void)cyl_outsideButtonTapped {
    self.tapCount += 1;
    [self.outsideButton cyl_addScaleBounceAnimationWithCompletion:nil];
    [self cyl_reload];
}

@end

static UITableViewCell *CYLOutsideBoundsCellForTableView(UITableView *tableView) {
    CYLOutsideBoundsCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLOutsideBoundsCellIdentifier];
    if (![cell isKindOfClass:[CYLOutsideBoundsCell class]]) {
        cell = [[CYLOutsideBoundsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CYLOutsideBoundsCellIdentifier];
    }
    return cell;
}

#pragma mark - Images from a bundle (issue #535)

static NSString *const CYLBundleImageCellIdentifier = @"CYLBundleImageCell";

/*!
 * [EN] Issue #535 demo row: the icon is the library's sample image, read with `CYLImageInBundle` from its resource bundle
 *      (not cached). The text says whether `CYLBundleImage` also finds it in the main bundle (it does not with
 *      `use_frameworks!`, where the resource bundle is inside the framework).
 * [CN] Issue #535 演示行：图标是本库的示例图片，由 `CYLImageInBundle` 从资源包读取（不缓存）。文字说明 `CYLBundleImage` 能否在主 bundle 中
 *      找到它（使用 `use_frameworks!` 时资源包位于 framework 内，找不到）。
 */
static UITableViewCell *CYLBundleImageCell(UITableView *tableView) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLBundleImageCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLBundleImageCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    NSString *fileName = @"cyl_badge_sample_icon@3x.png";
    cell.imageView.image = CYLImageInBundle(CYLResourceBundle(), nil, fileName);
    UIImage *mainBundleImage = CYLBundleImage(nil, @"CYLTabBarController", nil, fileName);
    NSString *mainBundleResult = mainBundleImage ? CYLLocalizedString(@"已找到") : CYLLocalizedString(@"未找到（use_frameworks 时资源包位于 framework 中）");
    // [EN] Every other loader once, each with its result. [CN] 其他每个加载函数各调用一次，并显示结果。
    NSString *(^found)(id) = ^NSString *(id value) {
        return value ? @"✓" : @"✗";
    };
    NSString *pathInBundle = CYLImagePathInBundle(CYLResourceBundle(), nil, @"cyl_badge_sample_icon@3x");
    NSString *mainBundlePath = CYLBundleImagePath(nil, @"CYLTabBarController", nil, fileName);
    NSData *mainBundleData = CYLBundleImageData(nil, @"CYLTabBarController", nil, fileName);
    UIImage *imageFromData = CYLBundleImageFromData(nil, @"CYLTabBarController", nil, fileName);
    // [EN] `imageNamed:` also takes a path inside a bundle of the main bundle (cached by the system).
    // [CN] `imageNamed:` 也接受主 bundle 中某个 bundle 内的路径（由系统缓存）。
    UIImage *namedImage = CYLImageNamed(@"CYLTabBarController.bundle/cyl_badge_sample_icon");
    NSString *loaders = [NSString stringWithFormat:@"CYLImagePathInBundle %@ (%@) · CYLBundleImagePath %@ · CYLBundleImageData %@ · CYLBundleImageFromData %@ (@%@x) · CYLImageNamed %@",
                         found([[NSFileManager defaultManager] fileExistsAtPath:pathInBundle ?: @""] ? pathInBundle : nil),
                         pathInBundle.lastPathComponent ?: @"-",
                         found(mainBundlePath && [[NSFileManager defaultManager] fileExistsAtPath:mainBundlePath] ? mainBundlePath : nil),
                         mainBundleData ? [NSByteCountFormatter stringFromByteCount:(long long)mainBundleData.length countStyle:NSByteCountFormatterCountStyleFile] : found(nil),
                         found(imageFromData), imageFromData ? @(imageFromData.scale) : @"-",
                         found(namedImage)];
    cell.textLabel.text = CYLLocalizedString(@"从 bundle 加载图片（issue #535）");
    cell.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"左侧图片由 CYLImageInBundle 从资源包读取（不缓存）。主 bundle 中的 CYLBundleImage：%@"), mainBundleResult];
    cell.detailTextLabel.text = [cell.detailTextLabel.text stringByAppendingFormat:@"\n%@", loaders];
    return cell;
}

#pragma mark - Navigation bar without a base class (issue #535)

static NSString *const CYLNavigationSettingCellIdentifier = @"CYLNavigationSettingCell";

/*!
 * [EN] A plain UIViewController (no CYLBaseViewController) that hides the navigation bar, and the outer one when the tab
 *      bar controller is pushed. Its button goes back, since there is no bar.
 * [CN] 一个普通的 UIViewController（没有继承 CYLBaseViewController），隐藏导航栏；TabBarController 被 push 时外层导航栏也隐藏。
 *      由于没有导航栏，用页面上的按钮返回。
 */
@interface CYLNavigationSettingDemoViewController : UIViewController
@end

@implementation CYLNavigationSettingDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.cyl_navigationBarHidden = YES;
    self.cyl_hidesAncestorNavigationBars = YES;
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.text = CYLLocalizedString(@"这是一个普通的 UIViewController，没有继承 CYLBaseViewController。导航栏已隐藏。");
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [backButton setTitle:CYLLocalizedString(@"关闭") forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(cyl_back) forControlEvents:UIControlEventTouchUpInside];
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[ label, backButton ]];
    stackView.axis = UILayoutConstraintAxisVertical;
    stackView.spacing = 16;
    stackView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:stackView];
    [NSLayoutConstraint activateConstraints:@[
        [stackView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [stackView.leadingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.leadingAnchor],
        [stackView.trailingAnchor constraintEqualToAnchor:self.view.layoutMarginsGuide.trailingAnchor],
    ]];
}

- (void)cyl_back {
    [self.navigationController popViewControllerAnimated:YES];
}

@end

/*!
 * [EN] The switch turns `cyl_automaticNavigationSettingEnabled` on or off; a tap on the row pushes the plain page.
 * [CN] 开关打开或关闭 `cyl_automaticNavigationSettingEnabled`；点击该行 push 普通页面。
 */
@interface CYLNavigationSettingSwitch : UISwitch
@end

@implementation CYLNavigationSettingSwitch

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self addTarget:self action:@selector(cyl_valueDidChange) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (void)cyl_valueDidChange {
    UIViewController.cyl_automaticNavigationSettingEnabled = self.isOn;
}

@end

static UITableViewCell *CYLNavigationSettingCell(UITableView *tableView) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLNavigationSettingCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLNavigationSettingCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        cell.accessoryView = [[CYLNavigationSettingSwitch alloc] initWithFrame:CGRectZero];
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"menubar.rectangle"];
        }
    }
    ((UISwitch *)cell.accessoryView).on = UIViewController.cyl_automaticNavigationSettingEnabled;
    cell.textLabel.text = CYLLocalizedString(@"不继承基类隐藏导航栏（issue #535）");
    cell.detailTextLabel.text = CYLLocalizedString(@"打开开关即设置 cyl_automaticNavigationSettingEnabled；点击该行 push 一个普通 UIViewController，它设置了 cyl_navigationBarHidden 与 cyl_hidesAncestorNavigationBars。");
    return cell;
}

#pragma mark - Slide transition classes (issue #535)

static NSString *const CYLSlideTransitionCellIdentifier = @"CYLSlideTransitionCell";

/*!
 * [EN] A system UITabBarController whose delegate uses `CYLTabBarSlideTransitionAnimator`, driven by a pan through
 *      `CYLTabBarInteractiveTransition`: the way to use the two classes with a delegate of your own.
 * [CN] 一个系统 UITabBarController，其代理使用 `CYLTabBarSlideTransitionAnimator`，并由拖动手势通过 `CYLTabBarInteractiveTransition`
 *      驱动：演示在自己的代理中使用这两个类。
 */
@interface CYLSlideTransitionDemoTabBarController : UITabBarController <UITabBarControllerDelegate>
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@end

@implementation CYLSlideTransitionDemoTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    NSArray<UIColor *> *colors = @[ [UIColor systemRedColor], [UIColor systemGreenColor], [UIColor systemBlueColor] ];
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    for (NSUInteger idx = 0; idx < colors.count; idx++) {
        UIViewController *page = [[UIViewController alloc] init];
        page.view.backgroundColor = colors[idx];
        page.tabBarItem.title = [NSString stringWithFormat:CYLLocalizedString(@"页面 %@"), @(idx + 1)];
        UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [closeButton setTitle:CYLLocalizedString(@"关闭") forState:UIControlStateNormal];
        [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [closeButton addTarget:self action:@selector(cyl_close) forControlEvents:UIControlEventTouchUpInside];
        closeButton.translatesAutoresizingMaskIntoConstraints = NO;
        [page.view addSubview:closeButton];
        [NSLayoutConstraint activateConstraints:@[
            [closeButton.centerXAnchor constraintEqualToAnchor:page.view.centerXAnchor],
            [closeButton.centerYAnchor constraintEqualToAnchor:page.view.centerYAnchor],
        ]];
        [viewControllers addObject:page];
    }
    self.viewControllers = viewControllers;
    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(cyl_pan:)];
    [self.view addGestureRecognizer:self.panGestureRecognizer];
}

- (void)cyl_close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/// [EN] The pan only starts the switch; the interactive transition follows it. [CN] 拖动只负责开始切换，交互式转场跟随手势。
- (void)cyl_pan:(UIPanGestureRecognizer *)panGestureRecognizer {
    if (panGestureRecognizer.state != UIGestureRecognizerStateBegan || self.transitionCoordinator) {
        return;
    }
    CGFloat velocityX = [panGestureRecognizer velocityInView:self.view].x;
    if (velocityX < 0 && self.selectedIndex + 1 < self.viewControllers.count) {
        self.selectedIndex += 1;
    } else if (velocityX > 0 && self.selectedIndex > 0) {
        self.selectedIndex -= 1;
    }
}

- (id<UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController *)tabBarController
           animationControllerForTransitionFromViewController:(UIViewController *)fromVC
                                             toViewController:(UIViewController *)toVC {
    NSArray *viewControllers = tabBarController.viewControllers;
    BOOL forward = [viewControllers indexOfObject:toVC] > [viewControllers indexOfObject:fromVC];
    return [[CYLTabBarSlideTransitionAnimator alloc] initWithTargetEdge:forward ? UIRectEdgeLeft : UIRectEdgeRight];
}

- (id<UIViewControllerInteractiveTransitioning>)tabBarController:(UITabBarController *)tabBarController
                     interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController {
    UIGestureRecognizerState state = self.panGestureRecognizer.state;
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) {
        return [[CYLTabBarInteractiveTransition alloc] initWithGestureRecognizer:self.panGestureRecognizer];
    }
    return nil;
}

@end

static UITableViewCell *CYLSlideTransitionCell(UITableView *tableView) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLSlideTransitionCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLSlideTransitionCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"rectangle.split.3x1"];
        }
    }
    cell.textLabel.text = CYLLocalizedString(@"滑动转场（CYLTabBarSlideTransitionAnimator）");
    cell.detailTextLabel.text = CYLLocalizedString(@"点击打开一个系统 UITabBarController：点击 Tab 或在页面上左右拖动，页面跟随手指滑动切换。");
    return cell;
}

#pragma mark - Tap sound and haptic feedback (issue #535)

static NSString *const CYLTapFeedbackCellIdentifier = @"CYLTapFeedbackCell";

/*!
 * [EN] The steps the tap feedback row cycles through: off, the default click, a custom sound file, haptics of three
 *      strengths, then sound and haptic together.
 * [CN] 点击反馈行依次切换的步骤：关闭、默认点击声、自定义音频文件、三种强度的触感反馈、声音与触感同时开启。
 */
typedef NS_ENUM(NSInteger, CYLDemoTapFeedbackStep) {
    CYLDemoTapFeedbackStepOff,
    CYLDemoTapFeedbackStepDefaultSound,
    CYLDemoTapFeedbackStepCustomSound,
    CYLDemoTapFeedbackStepLightHaptic,
    CYLDemoTapFeedbackStepMediumHaptic,
    CYLDemoTapFeedbackStepHeavyHaptic,
    CYLDemoTapFeedbackStepSoundAndHaptic,
    CYLDemoTapFeedbackStepCount,
};

static char CYLDemoTapFeedbackStepKey;

/// [EN] A system sound file for the custom sound step, nil when the system does not have it. [CN] 自定义声音步骤使用的系统音频文件，系统中没有时为 nil。
static NSURL *_Nullable CYLDemoCustomTapSoundURL(void) {
    NSString *path = @"/System/Library/Audio/UISounds/Tock.caf";
    return [[NSFileManager defaultManager] fileExistsAtPath:path] ? [NSURL fileURLWithPath:path] : nil;
}

static NSString *CYLDemoTapFeedbackStepName(NSInteger step) {
    switch (step) {
        case CYLDemoTapFeedbackStepDefaultSound: return CYLLocalizedString(@"默认点击声");
        case CYLDemoTapFeedbackStepCustomSound: return CYLLocalizedString(@"自定义音频文件（cyl_tabButtonTapSoundURL）");
        case CYLDemoTapFeedbackStepLightHaptic: return CYLLocalizedString(@"轻触感反馈");
        case CYLDemoTapFeedbackStepMediumHaptic: return CYLLocalizedString(@"中等触感反馈");
        case CYLDemoTapFeedbackStepHeavyHaptic: return CYLLocalizedString(@"重触感反馈");
        case CYLDemoTapFeedbackStepSoundAndHaptic: return CYLLocalizedString(@"点击声 + 触感反馈");
        case CYLDemoTapFeedbackStepOff:
        default: return CYLLocalizedString(@"无");
    }
}

static UITableViewCell *CYLTapFeedbackCell(UITableView *tableView, CYLTabBarController *_Nullable tabBarController) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLTapFeedbackCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLTapFeedbackCellIdentifier];
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"speaker.wave.2"];
        }
    }
    NSInteger step = [objc_getAssociatedObject(tabBarController, &CYLDemoTapFeedbackStepKey) integerValue];
    cell.textLabel.text = CYLLocalizedString(@"Tab 点击声音与触感反馈（issue #535）");
    cell.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"点击切换，然后点击任意 Tab 或 PlusButton 试听。触感反馈只在真机上振动。当前：%@"), CYLDemoTapFeedbackStepName(step)];
    return cell;
}

/// [EN] Moves to the next step and plays it once at once. [CN] 切换到下一步，并立即播放一次。
static void CYLSwitchTapFeedback(CYLTabBarController *_Nullable tabBarController) {
    if (!tabBarController) {
        return;
    }
    NSInteger step = ([objc_getAssociatedObject(tabBarController, &CYLDemoTapFeedbackStepKey) integerValue] + 1) % CYLDemoTapFeedbackStepCount;
    objc_setAssociatedObject(tabBarController, &CYLDemoTapFeedbackStepKey, @(step), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    tabBarController.cyl_tabButtonTapSoundEnabled = (step == CYLDemoTapFeedbackStepDefaultSound ||
                                                     step == CYLDemoTapFeedbackStepCustomSound ||
                                                     step == CYLDemoTapFeedbackStepSoundAndHaptic);
    tabBarController.cyl_tabButtonTapSoundURL = (step == CYLDemoTapFeedbackStepCustomSound) ? CYLDemoCustomTapSoundURL() : nil;
    UIImpactFeedbackStyle style = UIImpactFeedbackStyleMedium;
    if (step == CYLDemoTapFeedbackStepLightHaptic) {
        style = UIImpactFeedbackStyleLight;
    } else if (step == CYLDemoTapFeedbackStepHeavyHaptic) {
        style = UIImpactFeedbackStyleHeavy;
    }
    tabBarController.cyl_tabButtonHapticFeedbackStyle = style;
    tabBarController.cyl_tabButtonHapticFeedbackEnabled = (step >= CYLDemoTapFeedbackStepLightHaptic);
    [tabBarController cyl_playTabButtonTapFeedback];
}

#pragma mark - Long press and double tap timing (issue #535 / #152)

static NSString *const CYLGestureTimingCellIdentifier = @"CYLGestureTimingCell";

/// [EN] The long press durations and double tap intervals the row cycles through, the default first.
/// [CN] 该行依次切换的长按时长与双击间隔，第一个为默认值。
static const NSTimeInterval CYLDemoLongPressDurations[] = { 0.5, 1.0, 0.25 };
static const NSTimeInterval CYLDemoDoubleTapIntervals[] = { 0.35, 0.6, 0.25 };
static const NSUInteger CYLDemoGestureTimingCount = sizeof(CYLDemoLongPressDurations) / sizeof(CYLDemoLongPressDurations[0]);

static UITableViewCell *CYLGestureTimingCell(UITableView *tableView, CYLTabBarController *_Nullable tabBarController) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLGestureTimingCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLGestureTimingCellIdentifier];
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"timer"];
        }
    }
    cell.textLabel.text = CYLLocalizedString(@"长按时长与双击间隔（issue #535 / #152）");
    // [EN] Both long press properties are read, to show they are one value. [CN] 读取两个长按属性，说明它们是同一个值。
    cell.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"点击切换。cyl_tabBarItemLongPressDuration：%@ 秒，cyl_tabButtonLongPressMinimumDuration：%@ 秒，cyl_tabBarItemDoubleTapInterval：%@ 秒"),
                                 @(tabBarController.cyl_tabBarItemLongPressDuration),
                                 @(tabBarController.cyl_tabButtonLongPressMinimumDuration),
                                 @(tabBarController.cyl_tabBarItemDoubleTapInterval)];
    return cell;
}

/// [EN] The next pair of values. The two long press setters take turns, since they set one value.
/// [CN] 切换到下一组值。两个长按 setter 轮流使用，因为它们设置的是同一个值。
static void CYLSwitchGestureTiming(CYLTabBarController *_Nullable tabBarController) {
    if (!tabBarController) {
        return;
    }
    NSUInteger current = 0;
    for (NSUInteger idx = 0; idx < CYLDemoGestureTimingCount; idx++) {
        if (fabs(CYLDemoLongPressDurations[idx] - tabBarController.cyl_tabBarItemLongPressDuration) < 0.001) {
            current = idx;
            break;
        }
    }
    NSUInteger next = (current + 1) % CYLDemoGestureTimingCount;
    if (next % 2 == 0) {
        tabBarController.cyl_tabBarItemLongPressDuration = CYLDemoLongPressDurations[next];
    } else {
        tabBarController.cyl_tabButtonLongPressMinimumDuration = CYLDemoLongPressDurations[next];
    }
    tabBarController.cyl_tabBarItemDoubleTapInterval = CYLDemoDoubleTapIntervals[next];
}

#pragma mark - Switch to the adjacent tab (issue #535)

static NSString *const CYLSwitchAdjacentTabCellIdentifier = @"CYLSwitchAdjacentTabCell";

/*!
 * [EN] Two buttons that call `-cyl_switchToAdjacentTabWithStep:animated:` with -1 and 1; the list stays, so the result
 *      (YES or NO, e.g. at the last tab) is shown after the switch.
 * [CN] 两个按钮分别以 -1 与 1 调用 `-cyl_switchToAdjacentTabWithStep:animated:`；切换后在返回时显示结果（YES 或 NO，例如已是最后一个 Tab）。
 */
@interface CYLSwitchAdjacentTabCell : UITableViewCell
@property (nonatomic, weak, nullable) CYLTabBarController *tabBarController;
@end

static char CYLDemoSwitchAdjacentResultKey;

@implementation CYLSwitchAdjacentTabCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier]) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        if (@available(iOS 13.0, *)) {
            self.imageView.image = [UIImage systemImageNamed:@"arrow.left.arrow.right"];
        }
        UIButton *previousButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [previousButton setTitle:@"◀︎" forState:UIControlStateNormal];
        previousButton.accessibilityLabel = @"cyl_switchToAdjacentTab -1";
        previousButton.tag = -1;
        UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [nextButton setTitle:@"▶︎" forState:UIControlStateNormal];
        nextButton.accessibilityLabel = @"cyl_switchToAdjacentTab 1";
        nextButton.tag = 1;
        for (UIButton *button in @[ previousButton, nextButton ]) {
            button.titleLabel.font = [UIFont systemFontOfSize:22];
            [button addTarget:self action:@selector(cyl_switch:) forControlEvents:UIControlEventTouchUpInside];
        }
        UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[ previousButton, nextButton ]];
        stackView.spacing = 4;
        stackView.distribution = UIStackViewDistributionFillEqually;
        stackView.frame = CGRectMake(0, 0, 88, 44);
        self.accessoryView = stackView;
    }
    return self;
}

- (void)cyl_switch:(UIButton *)sender {
    CYLTabBarController *tabBarController = self.tabBarController;
    if (!tabBarController) {
        return;
    }
    BOOL switched = [tabBarController cyl_switchToAdjacentTabWithStep:sender.tag animated:YES];
    objc_setAssociatedObject(tabBarController, &CYLDemoSwitchAdjacentResultKey, @(switched), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_reload];
}

- (void)cyl_reload {
    NSNumber *result = self.tabBarController ? objc_getAssociatedObject(self.tabBarController, &CYLDemoSwitchAdjacentResultKey) : nil;
    self.textLabel.text = CYLLocalizedString(@"切换到上一个 / 下一个 Tab（issue #535）");
    NSString *resultText = result ? (result.boolValue ? @"YES" : @"NO") : @"-";
    self.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"点击右侧箭头调用 cyl_switchToAdjacentTabWithStep:-1 / 1，与滑动相同会跳过 PlusButton 并检查登录。上次返回：%@"), resultText];
}

@end

static UITableViewCell *CYLSwitchAdjacentTabCellForTableView(UITableView *tableView, CYLTabBarController *_Nullable tabBarController) {
    CYLSwitchAdjacentTabCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLSwitchAdjacentTabCellIdentifier];
    if (![cell isKindOfClass:[CYLSwitchAdjacentTabCell class]]) {
        cell = [[CYLSwitchAdjacentTabCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLSwitchAdjacentTabCellIdentifier];
    }
    cell.tabBarController = tabBarController;
    [cell cyl_reload];
    return cell;
}

#pragma mark - CYLUtils helpers (issue #535)

static NSString *const CYLUtilsHelpersCellIdentifier = @"CYLUtilsHelpersCell";
static char CYLDemoUtilsHelpersResultKey;
static char CYLDemoWeakObjectKey;

static UITableViewCell *CYLUtilsHelpersCell(UITableView *tableView, CYLTabBarController *_Nullable tabBarController) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLUtilsHelpersCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLUtilsHelpersCellIdentifier];
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"wrench.and.screwdriver"];
        }
    }
    NSString *result = tabBarController ? objc_getAssociatedObject(tabBarController, &CYLDemoUtilsHelpersResultKey) : nil;
    cell.textLabel.text = CYLLocalizedString(@"CYLUtils 弱引用关联对象与查找按钮（issue #535）");
    cell.detailTextLabel.text = result ?: CYLLocalizedString(@"点击运行：cyl_setWeakAssociatedObject:forKey: 在对象释放后返回 nil；cyl_nearestControlBelowView: 从选中 Tab 的图标找到它的按钮。");
    return cell;
}

/*!
 * [EN] Runs the two CYLUtils helpers and keeps their results for the row:
 *      1. a weak associated object is there while its object lives, and nil after it is released;
 *      2. from the image view inside the selected tab button, `-cyl_nearestControlBelowView:` finds that button.
 * [CN] 运行两个 CYLUtils 工具方法，并保存结果供该行显示：
 *      1. 弱引用关联对象在对象存活时存在，释放后为 nil；
 *      2. 从选中 Tab 按钮内的图片视图出发，`-cyl_nearestControlBelowView:` 找到该按钮。
 */
static void CYLRunUtilsHelpers(CYLTabBarController *_Nullable tabBarController) {
    if (!tabBarController) {
        return;
    }
    BOOL whileAlive = NO;
    @autoreleasepool {
        NSObject *object = [[NSObject alloc] init];
        [tabBarController cyl_setWeakAssociatedObject:object forKey:&CYLDemoWeakObjectKey];
        whileAlive = ([tabBarController cyl_weakAssociatedObjectForKey:&CYLDemoWeakObjectKey] == object);
    }
    BOOL afterRelease = ([tabBarController cyl_weakAssociatedObjectForKey:&CYLDemoWeakObjectKey] == nil);

    UIControl *tabButton = tabBarController.selectedViewController.cyl_tabButton;
    UIView *innerView = tabButton;
    // [EN] The deepest first subview, e.g. the icon's image view. [CN] 最深的第一个子视图，例如图标的图片视图。
    while (innerView.subviews.firstObject) {
        innerView = innerView.subviews.firstObject;
    }
    UIControl *foundControl = [innerView cyl_nearestControlBelowView:tabBarController.tabBar];
    NSString *found = !tabButton ? @"-" : ((foundControl == tabButton) ? @"YES" : (foundControl ? NSStringFromClass([foundControl class]) : @"nil"));
    NSString *result = [NSString stringWithFormat:CYLLocalizedString(@"弱引用：存活时取到 %@，释放后为 nil %@。从 %@ 找到选中的 Tab 按钮：%@"),
                        whileAlive ? @"YES" : @"NO", afterRelease ? @"YES" : @"NO",
                        innerView ? NSStringFromClass([innerView class]) : @"-", found];
    objc_setAssociatedObject(tabBarController, &CYLDemoUtilsHelpersResultKey, result, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - Minimize / hide the tab bar on scroll (issue #13)

static NSString *const CYLTabBarMinimizeCellIdentifier = @"CYLTabBarMinimizeCell";

/// [EN] The name of a CYLTabBarMinimizeBehavior, as in code. [CN] CYLTabBarMinimizeBehavior 的名称，与代码中一致。
static NSString *CYLTabBarMinimizeBehaviorName(CYLTabBarMinimizeBehavior behavior) {
    switch (behavior) {
        case CYLTabBarMinimizeBehaviorNever:
            return @"Never";
        case CYLTabBarMinimizeBehaviorOnScrollDown:
            return @"OnScrollDown";
        case CYLTabBarMinimizeBehaviorOnScrollUp:
            return @"OnScrollUp";
        case CYLTabBarMinimizeBehaviorAutomatic:
            break;
    }
    return @"Automatic";
}

/*!
 * [EN] Issue #13 demo row: a tap sets the next `cyl_tabBarMinimizeBehavior` (Automatic → OnScrollDown → OnScrollUp →
 *      Never) on the tab bar controller that shows this list; then scroll the list.
 * [CN] Issue #13 演示行：点击为显示本列表的 TabBarController 设置下一个 `cyl_tabBarMinimizeBehavior`（Automatic → OnScrollDown →
 *      OnScrollUp → Never），然后滚动列表即可看到效果。
 */
static UITableViewCell *CYLTabBarMinimizeCell(UITableView *tableView, CYLTabBarController *_Nullable tabBarController) {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLTabBarMinimizeCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLTabBarMinimizeCellIdentifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"arrow.up.and.down"];
        }
    }
    NSString *behaviorName = tabBarController ? CYLTabBarMinimizeBehaviorName(tabBarController.cyl_tabBarMinimizeBehavior) : @"-";
    cell.textLabel.text = CYLLocalizedString(@"滚动时缩小 / 隐藏 TabBar（issue #13）");
    cell.detailTextLabel.text = [NSString stringWithFormat:CYLLocalizedString(@"点击切换滚动行为。当前：%@。液态玻璃（iOS 26+）由系统缩小 TabBar；扁平样式与经典样式（iOS 25 及以前、iOS 26 UI 兼容模式）隐藏 TabBar。"), behaviorName];
    return cell;
}

/// [EN] Sets the next behavior: Automatic → OnScrollDown → OnScrollUp → Never → Automatic.
/// [CN] 切换到下一个行为：Automatic → OnScrollDown → OnScrollUp → Never → Automatic。
static void CYLSwitchTabBarMinimizeBehavior(CYLTabBarController *_Nullable tabBarController) {
    if (!tabBarController) {
        return;
    }
    CYLTabBarMinimizeBehavior next = CYLTabBarMinimizeBehaviorAutomatic;
    switch (tabBarController.cyl_tabBarMinimizeBehavior) {
        case CYLTabBarMinimizeBehaviorAutomatic:
            next = CYLTabBarMinimizeBehaviorOnScrollDown;
            break;
        case CYLTabBarMinimizeBehaviorOnScrollDown:
            next = CYLTabBarMinimizeBehaviorOnScrollUp;
            break;
        case CYLTabBarMinimizeBehaviorOnScrollUp:
            next = CYLTabBarMinimizeBehaviorNever;
            break;
        case CYLTabBarMinimizeBehaviorNever:
            next = CYLTabBarMinimizeBehaviorAutomatic;
            break;
    }
    tabBarController.cyl_tabBarMinimizeBehavior = next;
}

/// [EN] Issue #13: the settings row that lists the scroll hiding simulations. [CN] issue #13：列出滚动隐藏模拟的设置行。
static UITableViewCell *CYLScrollHideSimulationMenuCell(UITableView *tableView) {
    static NSString *const identifier = @"CYLScrollHideSimulationMenuCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.textLabel.font = [UIFont boldSystemFontOfSize:15];
        cell.detailTextLabel.textColor = [UIColor grayColor];
        cell.detailTextLabel.numberOfLines = 0;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"exclamationmark.triangle"];
        }
    }
    cell.textLabel.text = CYLLocalizedString(@"滚动隐藏：模拟意外情况（issue #13）");
    cell.detailTextLabel.text = CYLLocalizedString(@"选择一种意外情况，1.5 秒后触发。请先向下滚动隐藏 TabBar。");
    return cell;
}

@implementation UIViewController (CYLSettingsSection)

- (NSInteger)cyl_settingsRowCount {
    return CYLSettingsRowTabBarItemUpdate + [self cyl_tabBarItemUpdateRowCount];
}

- (UITableViewCell *)cyl_settingsCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self cyl_settingsRowCellForTableView:tableView atIndexPath:indexPath];
    // [EN] Every row shows its whole text, wrapped, never an ellipsis.
    // [CN] 每行完整显示文字（换行），不出现省略号。
    [cell cyl_wrapsTextLabels];
    return cell;
}

- (UITableViewCell *)cyl_settingsRowCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == CYLSettingsRowMemoryWarning) {
        return [self cyl_memoryWarningCellForTableView:tableView];
    }
    if (indexPath.row == CYLSettingsRowTitlePositionAdjustment) {
        return CYLTitlePositionAdjustmentCell(tableView, CYLSettingsTabBarController(self));
    }
    if (indexPath.row == CYLSettingsRowStandardAppearance) {
        return CYLStandardAppearanceCell(tableView, CYLSettingsTabBarController(self));
    }
    if (indexPath.row == CYLSettingsRowLoginState) {
        return CYLLoginStateCell(tableView, CYLSettingsTabBarController(self));
    }
    if (indexPath.row == CYLSettingsRowPlusButtonTouchableArea) {
        return CYLTouchableAreaCellForTableView(tableView, CYLSettingsTabBarController(self));
    }
    if (indexPath.row == CYLSettingsRowSelectedIndexIgnoringPlusButton) {
        return CYLSelectedIndexCell(tableView, CYLSettingsTabBarController(self));
    }
    if (indexPath.row == CYLSettingsRowTabButtonTapAnimation) {
        return CYLTabButtonTapAnimationCell(tableView, CYLSettingsTabBarController(self));
    }
    if (indexPath.row == CYLSettingsRowTabButtonLongPress) {
        return CYLInteractionSwitchCell(tableView, CYLSettingsTabBarController(self), CYLInteractionDemoSwitchKindLongPress);
    }
    if (indexPath.row == CYLSettingsRowSwipeToSwitchTab) {
        return CYLInteractionSwitchCell(tableView, CYLSettingsTabBarController(self), CYLInteractionDemoSwitchKindSwipe);
    }
    if (indexPath.row == CYLSettingsRowOutsideSuperviewBounds) {
        return CYLOutsideBoundsCellForTableView(tableView);
    }
    if (indexPath.row == CYLSettingsRowBundleImage) {
        return CYLBundleImageCell(tableView);
    }
    if (indexPath.row == CYLSettingsRowNavigationWithoutBaseClass) {
        return CYLNavigationSettingCell(tableView);
    }
    if (indexPath.row == CYLSettingsRowSlideTransition) {
        return CYLSlideTransitionCell(tableView);
    }
    if (indexPath.row == CYLSettingsRowTapFeedback) {
        return CYLTapFeedbackCell(tableView, CYLSettingsTabBarController(self));
    }
    if (indexPath.row == CYLSettingsRowGestureTiming) {
        return CYLGestureTimingCell(tableView, CYLSettingsTabBarController(self));
    }
    if (indexPath.row == CYLSettingsRowSwitchAdjacentTab) {
        return CYLSwitchAdjacentTabCellForTableView(tableView, CYLSettingsTabBarController(self));
    }
    if (indexPath.row == CYLSettingsRowUtilsHelpers) {
        return CYLUtilsHelpersCell(tableView, CYLSettingsTabBarController(self));
    }
    if (indexPath.row == CYLSettingsRowTabBarMinimizeBehavior) {
        return CYLTabBarMinimizeCell(tableView, CYLSettingsTabBarController(self));
    }
    if (indexPath.row == CYLSettingsRowTheme) {
        return [self cyl_themeSettingsCellForTableView:tableView];
    }
    if (indexPath.row == CYLSettingsRowScrollHideSimulation) {
        return CYLScrollHideSimulationMenuCell(tableView);
    }
    if (indexPath.row >= CYLSettingsRowTabBarItemUpdate) {
        return [self cyl_tabBarItemUpdateCellForTableView:tableView row:indexPath.row - CYLSettingsRowTabBarItemUpdate];
    }
    return [self cyl_languageCellForTableView:tableView];
}

- (void)cyl_didSelectSettingsRowAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row == CYLSettingsRowMemoryWarning) {
        [self cyl_simulateMemoryWarningAndShowResult];
    } else if (indexPath.row == CYLSettingsRowTitlePositionAdjustment) {
        CYLSwitchTitlePositionAdjustment(CYLSettingsTabBarController(self));
        [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
    } else if (indexPath.row == CYLSettingsRowStandardAppearance) {
        CYLSwitchStandardAppearance(CYLSettingsTabBarController(self));
        [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
    } else if (indexPath.row == CYLSettingsRowLoginState) {
        // The switch and the text follow the notification, so the row is not reloaded (the switch animates).
        // 开关与文字随通知更新，因此不重新加载该行（开关会带动画切换）。
        CYLToggleLoginState(CYLSettingsTabBarController(self));
    } else if (indexPath.row == CYLSettingsRowPlusButtonTouchableArea) {
        // [EN] The switch and the slider act on their own; a tap on the row does nothing.
        // [CN] 开关与滑块各自生效，点击该行不做处理。
    } else if (indexPath.row == CYLSettingsRowSelectedIndexIgnoringPlusButton) {
        // [EN] The tab changes, so this list may disappear; reload the row only while it is still shown.
        // [CN] Tab 切换后本列表可能已不可见；仅在仍显示时刷新该行。
        CYLSelectNextTabIgnoringPlusButton(CYLSettingsTabBarController(self));
        if (tableView.window) {
            [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
        }
    } else if (indexPath.row == CYLSettingsRowTabBarMinimizeBehavior) {
        CYLSwitchTabBarMinimizeBehavior(CYLSettingsTabBarController(self));
        [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
    } else if (indexPath.row == CYLSettingsRowTabButtonTapAnimation) {
        CYLSwitchTabButtonTapAnimation(CYLSettingsTabBarController(self));
        [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
    } else if (indexPath.row == CYLSettingsRowTabButtonLongPress) {
        CYLToggleInteractionSwitch(tableView, indexPath, CYLSettingsTabBarController(self), CYLInteractionDemoSwitchKindLongPress);
    } else if (indexPath.row == CYLSettingsRowSwipeToSwitchTab) {
        CYLToggleInteractionSwitch(tableView, indexPath, CYLSettingsTabBarController(self), CYLInteractionDemoSwitchKindSwipe);
    } else if (indexPath.row == CYLSettingsRowOutsideSuperviewBounds || indexPath.row == CYLSettingsRowBundleImage) {
        // [EN] These rows act through their own controls; a tap on the row does nothing.
        // [CN] 这些行通过自身的控件生效，点击该行不做处理。
    } else if (indexPath.row == CYLSettingsRowNavigationWithoutBaseClass) {
        CYLNavigationSettingDemoViewController *page = [[CYLNavigationSettingDemoViewController alloc] init];
        page.hidesBottomBarWhenPushed = YES;
        if (self.navigationController) {
            [self.navigationController pushViewController:page animated:YES];
        } else {
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:page];
            [self presentViewController:navigationController animated:YES completion:nil];
        }
    } else if (indexPath.row == CYLSettingsRowSlideTransition) {
        CYLSlideTransitionDemoTabBarController *demo = [[CYLSlideTransitionDemoTabBarController alloc] init];
        demo.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:demo animated:YES completion:nil];
    } else if (indexPath.row == CYLSettingsRowTapFeedback) {
        CYLSwitchTapFeedback(CYLSettingsTabBarController(self));
        [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
    } else if (indexPath.row == CYLSettingsRowGestureTiming) {
        CYLSwitchGestureTiming(CYLSettingsTabBarController(self));
        [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
    } else if (indexPath.row == CYLSettingsRowSwitchAdjacentTab) {
        // [EN] The two arrows act on their own; a tap on the row does nothing. [CN] 两个箭头各自生效，点击该行不做处理。
    } else if (indexPath.row == CYLSettingsRowUtilsHelpers) {
        CYLRunUtilsHelpers(CYLSettingsTabBarController(self));
        [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
    } else if (indexPath.row == CYLSettingsRowTheme) {
        // [EN] The row shows the theme picked. [CN] 该行显示所选主题。
        __weak UITableView *weakTableView = tableView;
        [self cyl_presentThemePickerFromView:[tableView cellForRowAtIndexPath:indexPath] completion:^{
            UITableView *strongTableView = weakTableView;
            if (strongTableView.window && indexPath.row < [strongTableView numberOfRowsInSection:indexPath.section]) {
                [strongTableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
            }
        }];
    } else if (indexPath.row == CYLSettingsRowScrollHideSimulation) {
        [self cyl_presentScrollHideSimulationMenu];
    } else if (indexPath.row >= CYLSettingsRowTabBarItemUpdate) {
        [self cyl_didSelectTabBarItemUpdateRow:indexPath.row - CYLSettingsRowTabBarItemUpdate];
        // [EN] The rows show which changes are on (a checkmark).
        // [CN] 各行用勾号显示已应用的更改。
        NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
        for (NSInteger row = CYLSettingsRowTabBarItemUpdate; row < [self cyl_settingsRowCount]; row++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:indexPath.section]];
        }
        [tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    } else {
        [self cyl_presentLanguagePicker];
    }
}

@end

#pragma mark - CYLScrollHideSimulationSection (issue #13)

/*!
 * [EN] Scroll hiding (issue #13): rows that simulate the interruptions the tab bar must come back from. Each row turns
 *      scroll hiding on and fires its interruption after CYLScrollHideSimulationDelay, so there is time to scroll down
 *      and hide the bar first. Row titles name the API or event they trigger. System events that cannot be triggered
 *      from code (a real call, the low battery alert) are simulated by posting the notifications the system posts.
 * [CN] 滚动隐藏（issue #13）：模拟各种意外情况的演示行，TabBar 都必须从中恢复显示。每行先开启滚动隐藏，并在
 *      CYLScrollHideSimulationDelay 之后触发，留出时间先向下滚动隐藏 TabBar。行标题即触发的 API 或事件名称。无法用代码触发的系统事件
 *      （真实来电、低电量弹框）通过发送系统会发送的通知来模拟。
 */
typedef NS_ENUM(NSInteger, CYLScrollHideSimulationRow) {
    CYLScrollHideSimulationRowAlert,
    CYLScrollHideSimulationRowActionSheet,
    CYLScrollHideSimulationRowFullScreenModal,
    CYLScrollHideSimulationRowPageSheet,
    CYLScrollHideSimulationRowPushThenPop,
    CYLScrollHideSimulationRowPushHidesBottomBar,
    CYLScrollHideSimulationRowSwitchTab,
    CYLScrollHideSimulationRowResignActive,
    CYLScrollHideSimulationRowBackgroundForeground,
    CYLScrollHideSimulationRowNotificationTapPush,
    CYLScrollHideSimulationRowMemoryWarning,
    CYLScrollHideSimulationRowOverlayWindow,
    CYLScrollHideSimulationRowKeyboard,
    CYLScrollHideSimulationRowShareSheet,
    CYLScrollHideSimulationRowScrollToTopInCode,
    CYLScrollHideSimulationRowScrollDownInCode,
    CYLScrollHideSimulationRowAppHidesTabBar,
    CYLScrollHideSimulationRowTurnOffAndOn,
    CYLScrollHideSimulationRowVoiceOverStatus,
    CYLScrollHideSimulationRowKeyboardWhileScrolling,
    CYLScrollHideSimulationRowReduceMotionStatus,
    CYLScrollHideSimulationRowLowPowerMode,
    CYLScrollHideSimulationRowRotation,
    CYLScrollHideSimulationRowOverCurrentContext,
    CYLScrollHideSimulationRowPopover,
    CYLScrollHideSimulationRowDrawer,
    CYLScrollHideSimulationRowSafeAreaTop,
    CYLScrollHideSimulationRowSceneDeactivate,
    CYLScrollHideSimulationRowManualLongPress,
    CYLScrollHideSimulationRowManualTapOutside,
    CYLScrollHideSimulationRowManualKeepDragging,
    CYLScrollHideSimulationRowRealBackground,
    CYLScrollHideSimulationRowRealSystemAlert,
    CYLScrollHideSimulationRowOtherAppKeyboard,
    CYLScrollHideSimulationRowGuidedAccess,
    CYLScrollHideSimulationRowSameTabAgain,
    CYLScrollHideSimulationRowTurnOnAgain,
    CYLScrollHideSimulationRowAppShowsTabBar,
    CYLScrollHideSimulationRowSelfTest,
    CYLScrollHideSimulationRowCount,
};

/// [EN] What a simulation expects. [CN] 模拟的预期。
typedef NS_ENUM(NSInteger, CYLScrollHideSimulationKind) {
    /// [EN] The bar comes back. [CN] TabBar 恢复显示。
    CYLScrollHideSimulationKindRestore,
    /// [EN] The bar does not change. [CN] TabBar 不变。
    CYLScrollHideSimulationKindKeep,
    /// [EN] Done by hand, as the title says; the bar comes back. [CN] 按标题手动操作；TabBar 恢复显示。
    CYLScrollHideSimulationKindManual,
    /// [EN] Runs the automatic self-test. [CN] 运行自动自测。
    CYLScrollHideSimulationKindSelfTest,
};

/// [EN] Seconds between the tap and the interruption. [CN] 点击到触发之间的秒数。
static const NSTimeInterval CYLScrollHideSimulationDelay = 1.5;
/// [EN] Seconds a temporary page, window or keyboard stays. [CN] 临时页面、窗口或键盘停留的秒数。
static const NSTimeInterval CYLScrollHideSimulationHold = 1.5;

static void CYLScrollHideSimulationAfter(NSTimeInterval seconds, dispatch_block_t block) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

@implementation UIViewController (CYLScrollHideSimulation)

- (NSInteger)cyl_scrollHideSimulationRowCount {
    return CYLScrollHideSimulationRowCount;
}

/// [EN] The row's title (the API or event it triggers) and whether the bar is expected to come back.
/// [CN] 行标题（触发的 API 或事件）以及 TabBar 是否应当恢复显示。
- (NSString *)cyl_scrollHideSimulationTitleForRow:(NSInteger)row kind:(CYLScrollHideSimulationKind *)kind {
    *kind = CYLScrollHideSimulationKindRestore;
    switch ((CYLScrollHideSimulationRow)row) {
        case CYLScrollHideSimulationRowAlert: return @"UIAlertController (alert)";
        case CYLScrollHideSimulationRowActionSheet: return @"UIAlertController (actionSheet)";
        case CYLScrollHideSimulationRowFullScreenModal: return @"present (UIModalPresentationFullScreen)";
        case CYLScrollHideSimulationRowPageSheet: return @"present (UIModalPresentationPageSheet)";
        case CYLScrollHideSimulationRowPushThenPop: return @"push, then pop";
        case CYLScrollHideSimulationRowPushHidesBottomBar: return @"push (hidesBottomBarWhenPushed), then pop";
        case CYLScrollHideSimulationRowSwitchTab: return @"selectedIndex + 1, then back";
        case CYLScrollHideSimulationRowResignActive: return @"WillResignActive / DidBecomeActive (call, low battery, system alert)";
        case CYLScrollHideSimulationRowBackgroundForeground: return @"DidEnterBackground / WillEnterForeground";
        case CYLScrollHideSimulationRowNotificationTapPush: return @"Push notification tap: foreground, then push";
        case CYLScrollHideSimulationRowMemoryWarning: return @"UIApplicationDidReceiveMemoryWarningNotification";
        case CYLScrollHideSimulationRowOverlayWindow: return @"UIWindow (alert level) makeKeyAndVisible";
        case CYLScrollHideSimulationRowKeyboard: return @"UITextField becomeFirstResponder (keyboard)";
        case CYLScrollHideSimulationRowShareSheet: return @"UIActivityViewController";
        case CYLScrollHideSimulationRowScrollToTopInCode: return @"setContentOffset: top (status bar tap)";
        case CYLScrollHideSimulationRowScrollDownInCode:
            *kind = CYLScrollHideSimulationKindKeep;
            return @"setContentOffset: down, in code";
        case CYLScrollHideSimulationRowAppHidesTabBar:
            *kind = CYLScrollHideSimulationKindKeep;
            return @"App: setTabBarHidden:YES for 4 s";
        case CYLScrollHideSimulationRowTurnOffAndOn: return @"cyl_hidesTabBarOnScroll = NO, then YES";
        case CYLScrollHideSimulationRowVoiceOverStatus: return @"UIAccessibilityVoiceOverStatusDidChangeNotification";
        case CYLScrollHideSimulationRowKeyboardWhileScrolling:
            *kind = CYLScrollHideSimulationKindKeep;
            return @"Keyboard up for 4 s: scroll, the bar must not hide";
        case CYLScrollHideSimulationRowReduceMotionStatus: return @"UIAccessibilityReduceMotionStatusDidChangeNotification";
        case CYLScrollHideSimulationRowLowPowerMode: return @"NSProcessInfoPowerStateDidChangeNotification (Low Power Mode)";
        case CYLScrollHideSimulationRowRotation: return @"requestGeometryUpdate: landscape, then portrait (iOS 16+)";
        case CYLScrollHideSimulationRowOverCurrentContext: return @"present (OverCurrentContext) from a page that definesPresentationContext";
        case CYLScrollHideSimulationRowPopover: return @"present (UIModalPresentationPopover)";
        case CYLScrollHideSimulationRowDrawer: return @"tabBarController.view slides away and back (side menu / drawer)";
        case CYLScrollHideSimulationRowSafeAreaTop: return @"additionalSafeAreaInsets.top + 20 (in-call / hotspot status bar)";
        case CYLScrollHideSimulationRowSceneDeactivate: return @"UISceneWillDeactivateNotification (this scene)";
        case CYLScrollHideSimulationRowManualLongPress:
            *kind = CYLScrollHideSimulationKindManual;
            return @"Manual: long press a row (context menu, drag, text selection)";
        case CYLScrollHideSimulationRowManualTapOutside:
            *kind = CYLScrollHideSimulationKindManual;
            return @"Manual: tap a navigation bar button (UIMenu, action)";
        case CYLScrollHideSimulationRowManualKeepDragging:
            *kind = CYLScrollHideSimulationKindManual;
            return @"Manual: after a restore, fling on without lifting; only a new drag hides it";
        case CYLScrollHideSimulationRowRealBackground: return @"Real: open Settings (the app really goes to the background; come back)";
        case CYLScrollHideSimulationRowRealSystemAlert: return @"Real system alert: tel:// call prompt (iPhone; tap Cancel)";
        case CYLScrollHideSimulationRowOtherAppKeyboard:
            *kind = CYLScrollHideSimulationKindKeep;
            return @"UIKeyboardWillShow of another app (UIKeyboardIsLocalUserInfoKey = NO)";
        case CYLScrollHideSimulationRowGuidedAccess: return @"UIAccessibilityGuidedAccessStatusDidChangeNotification";
        case CYLScrollHideSimulationRowSameTabAgain:
            *kind = CYLScrollHideSimulationKindKeep;
            return @"selectedIndex = the same tab (no change)";
        case CYLScrollHideSimulationRowTurnOnAgain:
            *kind = CYLScrollHideSimulationKindKeep;
            return @"cyl_hidesTabBarOnScroll = YES again (no change)";
        case CYLScrollHideSimulationRowAppShowsTabBar: return @"App: setTabBarHidden:NO";
        case CYLScrollHideSimulationRowSelfTest:
            *kind = CYLScrollHideSimulationKindSelfTest;
            return @"Self-test: run every automatic simulation, report PASS / FAIL";
        case CYLScrollHideSimulationRowCount: break;
    }
    return @"-";
}

- (UITableViewCell *)cyl_scrollHideSimulationCellForTableView:(UITableView *)tableView row:(NSInteger)row {
    static NSString *const identifier = @"CYLScrollHideSimulationCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.detailTextLabel.numberOfLines = 0;
        if (@available(iOS 13.0, *)) {
            cell.imageView.image = [UIImage systemImageNamed:@"exclamationmark.triangle"];
        }
    }
    CYLScrollHideSimulationKind kind = CYLScrollHideSimulationKindRestore;
    cell.textLabel.text = [self cyl_scrollHideSimulationTitleForRow:row kind:&kind];
    switch (kind) {
        case CYLScrollHideSimulationKindRestore:
            cell.detailTextLabel.text = CYLLocalizedString(@"点击后 1.5 秒触发。请先向下滚动隐藏 TabBar。预期：TabBar 立即恢复显示，惯性滚动不会再次隐藏。");
            break;
        case CYLScrollHideSimulationKindKeep:
            cell.detailTextLabel.text = CYLLocalizedString(@"点击后 1.5 秒触发。预期：TabBar 的状态不因此改变（不会被隐藏，App 隐藏的也不会被显示）。");
            break;
        case CYLScrollHideSimulationKindManual:
            cell.detailTextLabel.text = CYLLocalizedString(@"手动操作：点击开启滚动隐藏，向下滚动隐藏 TabBar 后按标题操作。预期：TabBar 立即恢复显示。");
            break;
        case CYLScrollHideSimulationKindSelfTest:
            cell.detailTextLabel.text = CYLLocalizedString(@"自动依次运行所有可自动化的模拟并报告通过 / 失败（约 2 分钟），结果同时打印到控制台。也可以用启动参数 -CYLScrollHideSelfTest YES 运行。");
            break;
    }
    return cell;
}

/// [EN] The scroll view of this page. [CN] 当前页面的滚动视图。
- (UIScrollView *)cyl_scrollHideSimulationScrollView {
    if ([self isKindOfClass:[UITableViewController class]]) {
        return ((UITableViewController *)self).tableView;
    }
    return [self.view isKindOfClass:[UIScrollView class]] ? (UIScrollView *)self.view : nil;
}

/// [EN] A plain page that leaves by itself. [CN] 一个会自行离开的普通页面。
- (UIViewController *)cyl_scrollHideSimulationPage {
    UIViewController *page = [[UIViewController alloc] init];
    page.view.backgroundColor = [UIColor colorWithRed:0.35 green:0.78 blue:0.98 alpha:1.0];
    return page;
}

- (void)cyl_didSelectScrollHideSimulationRow:(NSInteger)row {
    CYLTabBarController *tabBarController = [self cyl_owningTabBarController] ?: [self cyl_tabBarController];
    tabBarController.cyl_hidesTabBarOnScroll = YES;
    CYLScrollHideSimulationKind kind = CYLScrollHideSimulationKindRestore;
    [self cyl_scrollHideSimulationTitleForRow:row kind:&kind];
    // [EN] A manual row only turns scroll hiding on; the user does the rest. [CN] 手动行只开启滚动隐藏，其余由用户操作。
    if (CYLScrollHideSimulationKindManual == kind) {
        return;
    }
    if (CYLScrollHideSimulationKindSelfTest == kind) {
        [self cyl_runScrollHideSelfTest];
        return;
    }
    __weak typeof(self) weakSelf = self;
    CYLScrollHideSimulationAfter(CYLScrollHideSimulationDelay, ^{
        [weakSelf cyl_runScrollHideSimulationRow:row tabBarController:tabBarController];
    });
}

- (void)cyl_runScrollHideSimulationRow:(NSInteger)row tabBarController:(CYLTabBarController *)tabBarController {
    __weak typeof(self) weakSelf = self;
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    switch ((CYLScrollHideSimulationRow)row) {
        case CYLScrollHideSimulationRowAlert:
        case CYLScrollHideSimulationRowActionSheet: {
            UIAlertControllerStyle style = (row == CYLScrollHideSimulationRowAlert) ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CYLTabBarController" message:@"#13" preferredStyle:style];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            alert.popoverPresentationController.sourceView = self.view;
            alert.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
            [self presentViewController:alert animated:YES completion:nil];
            break;
        }
        case CYLScrollHideSimulationRowFullScreenModal:
        case CYLScrollHideSimulationRowPageSheet: {
            UIViewController *page = [self cyl_scrollHideSimulationPage];
            page.modalPresentationStyle = (row == CYLScrollHideSimulationRowFullScreenModal) ? UIModalPresentationFullScreen : UIModalPresentationPageSheet;
            [self presentViewController:page animated:YES completion:^{
                CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                    [page dismissViewControllerAnimated:YES completion:nil];
                });
            }];
            break;
        }
        case CYLScrollHideSimulationRowPushThenPop:
        case CYLScrollHideSimulationRowPushHidesBottomBar:
        case CYLScrollHideSimulationRowNotificationTapPush: {
            if (row == CYLScrollHideSimulationRowNotificationTapPush) {
                [center postNotificationName:UIApplicationWillEnterForegroundNotification object:UIApplication.sharedApplication];
                [center postNotificationName:UIApplicationDidBecomeActiveNotification object:UIApplication.sharedApplication];
            }
            UIViewController *page = [self cyl_scrollHideSimulationPage];
            page.hidesBottomBarWhenPushed = (row == CYLScrollHideSimulationRowPushHidesBottomBar);
            [self.navigationController pushViewController:page animated:YES];
            CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                [weakSelf.navigationController popViewControllerAnimated:YES];
            });
            break;
        }
        case CYLScrollHideSimulationRowSwitchTab: {
            NSUInteger original = tabBarController.selectedIndex;
            NSUInteger count = tabBarController.viewControllers.count;
            if (count > 1) {
                tabBarController.selectedIndex = (original + 1) % count;
                CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                    tabBarController.selectedIndex = original;
                });
            }
            break;
        }
        case CYLScrollHideSimulationRowResignActive: {
            [center postNotificationName:UIApplicationWillResignActiveNotification object:UIApplication.sharedApplication];
            CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                [center postNotificationName:UIApplicationDidBecomeActiveNotification object:UIApplication.sharedApplication];
            });
            break;
        }
        case CYLScrollHideSimulationRowBackgroundForeground: {
            [center postNotificationName:UIApplicationDidEnterBackgroundNotification object:UIApplication.sharedApplication];
            CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                [center postNotificationName:UIApplicationWillEnterForegroundNotification object:UIApplication.sharedApplication];
                [center postNotificationName:UIApplicationDidBecomeActiveNotification object:UIApplication.sharedApplication];
            });
            break;
        }
        case CYLScrollHideSimulationRowMemoryWarning: {
            [center postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:UIApplication.sharedApplication];
            break;
        }
        case CYLScrollHideSimulationRowOverlayWindow: {
            UIWindow *mainWindow = self.view.window;
            UIWindow *overlay = nil;
            if (@available(iOS 13.0, *)) {
                overlay = mainWindow.windowScene ? [[UIWindow alloc] initWithWindowScene:mainWindow.windowScene] : nil;
            }
            if (!overlay) {
                overlay = [[UIWindow alloc] initWithFrame:mainWindow.bounds];
            }
            overlay.windowLevel = UIWindowLevelAlert;
            overlay.rootViewController = [self cyl_scrollHideSimulationPage];
            overlay.rootViewController.view.alpha = 0.6;
            [overlay makeKeyAndVisible];
            CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                overlay.hidden = YES;
                [mainWindow makeKeyWindow];
            });
            break;
        }
        case CYLScrollHideSimulationRowKeyboard: {
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, -100, 10, 10)];
            [self.view addSubview:textField];
            [textField becomeFirstResponder];
            CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                [textField resignFirstResponder];
                [textField removeFromSuperview];
            });
            break;
        }
        case CYLScrollHideSimulationRowShareSheet: {
            UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[ @"https://github.com/ChenYilong/CYLTabBarController/issues/13" ] applicationActivities:nil];
            share.popoverPresentationController.sourceView = self.view;
            share.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
            [self presentViewController:share animated:YES completion:nil];
            break;
        }
        case CYLScrollHideSimulationRowScrollToTopInCode: {
            UIScrollView *scrollView = [self cyl_scrollHideSimulationScrollView];
            [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, -scrollView.adjustedContentInset.top) animated:YES];
            break;
        }
        case CYLScrollHideSimulationRowScrollDownInCode: {
            UIScrollView *scrollView = [self cyl_scrollHideSimulationScrollView];
            CGFloat maxOffsetY = MAX(-scrollView.adjustedContentInset.top, scrollView.contentSize.height + scrollView.adjustedContentInset.bottom - CGRectGetHeight(scrollView.bounds));
            [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, MIN(maxOffsetY, scrollView.contentOffset.y + 600)) animated:YES];
            break;
        }
        case CYLScrollHideSimulationRowAppHidesTabBar: {
            [tabBarController setTabBarHidden:YES animated:YES];
            CYLScrollHideSimulationAfter(4, ^{
                [tabBarController setTabBarHidden:NO animated:YES];
            });
            break;
        }
        case CYLScrollHideSimulationRowTurnOffAndOn: {
            tabBarController.cyl_hidesTabBarOnScroll = NO;
            CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                tabBarController.cyl_hidesTabBarOnScroll = YES;
            });
            break;
        }
        case CYLScrollHideSimulationRowVoiceOverStatus: {
            [center postNotificationName:UIAccessibilityVoiceOverStatusDidChangeNotification object:nil];
            break;
        }
        case CYLScrollHideSimulationRowKeyboardWhileScrolling: {
            UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0, -100, 10, 10)];
            [self.view addSubview:textField];
            [textField becomeFirstResponder];
            CYLScrollHideSimulationAfter(4, ^{
                [textField resignFirstResponder];
                [textField removeFromSuperview];
            });
            break;
        }
        case CYLScrollHideSimulationRowReduceMotionStatus: {
            [center postNotificationName:UIAccessibilityReduceMotionStatusDidChangeNotification object:nil];
            break;
        }
        case CYLScrollHideSimulationRowLowPowerMode: {
            [center postNotificationName:NSProcessInfoPowerStateDidChangeNotification object:[NSProcessInfo processInfo]];
            break;
        }
        case CYLScrollHideSimulationRowRotation: {
#if defined(__IPHONE_16_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_16_0
            if (@available(iOS 16.0, *)) {
                UIWindowScene *windowScene = self.view.window.windowScene;
                UIWindowSceneGeometryPreferencesIOS *landscape = [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:UIInterfaceOrientationMaskLandscapeRight];
                [windowScene requestGeometryUpdateWithPreferences:landscape errorHandler:nil];
                CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                    UIWindowSceneGeometryPreferencesIOS *portrait = [[UIWindowSceneGeometryPreferencesIOS alloc] initWithInterfaceOrientations:UIInterfaceOrientationMaskPortrait];
                    [windowScene requestGeometryUpdateWithPreferences:portrait errorHandler:nil];
                });
            }
#endif
            break;
        }
        case CYLScrollHideSimulationRowOverCurrentContext: {
            BOOL definedPresentationContext = self.definesPresentationContext;
            self.definesPresentationContext = YES;
            UIViewController *page = [self cyl_scrollHideSimulationPage];
            page.view.alpha = 0.7;
            page.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            [self presentViewController:page animated:YES completion:^{
                CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                    [page dismissViewControllerAnimated:YES completion:^{
                        weakSelf.definesPresentationContext = definedPresentationContext;
                    }];
                });
            }];
            break;
        }
        case CYLScrollHideSimulationRowPopover: {
            UIViewController *page = [self cyl_scrollHideSimulationPage];
            page.modalPresentationStyle = UIModalPresentationPopover;
            page.preferredContentSize = CGSizeMake(240, 160);
            page.popoverPresentationController.sourceView = self.view;
            page.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
            [self presentViewController:page animated:YES completion:^{
                CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                    [page dismissViewControllerAnimated:YES completion:nil];
                });
            }];
            break;
        }
        case CYLScrollHideSimulationRowDrawer: {
            UIView *controllerView = tabBarController.view;
            [UIView animateWithDuration:0.3 animations:^{
                controllerView.transform = CGAffineTransformMakeTranslation(CGRectGetWidth(controllerView.bounds) * 0.6, 0);
            } completion:^(BOOL __unused finished) {
                CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                    [UIView animateWithDuration:0.3 animations:^{
                        controllerView.transform = CGAffineTransformIdentity;
                    }];
                });
            }];
            break;
        }
        case CYLScrollHideSimulationRowSafeAreaTop: {
            UIEdgeInsets insets = tabBarController.additionalSafeAreaInsets;
            UIEdgeInsets taller = insets;
            taller.top += 20;
            tabBarController.additionalSafeAreaInsets = taller;
            CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                tabBarController.additionalSafeAreaInsets = insets;
            });
            break;
        }
        case CYLScrollHideSimulationRowSceneDeactivate: {
            if (@available(iOS 13.0, *)) {
                UIWindowScene *windowScene = self.view.window.windowScene;
                if (windowScene) {
                    [center postNotificationName:UISceneWillDeactivateNotification object:windowScene];
                    CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                        [center postNotificationName:UISceneDidActivateNotification object:windowScene];
                    });
                }
            }
            break;
        }
        case CYLScrollHideSimulationRowRealBackground: {
            // [EN] Not a simulation: the app really resigns active and goes to the background.
            // [CN] 不是模拟：App 真正失去活跃并进入后台。
            NSURL *settings = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            [UIApplication.sharedApplication openURL:settings options:@{} completionHandler:nil];
            break;
        }
        case CYLScrollHideSimulationRowRealSystemAlert: {
            // [EN] Not a simulation: iPhone shows a real system prompt and the app resigns active (no prompt in the
            //      simulator). [CN] 不是模拟：iPhone 显示真实的系统提示，App 失去活跃（模拟器中不显示）。
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:@"tel://10086"] options:@{} completionHandler:nil];
            break;
        }
        case CYLScrollHideSimulationRowOtherAppKeyboard: {
            [center postNotificationName:UIKeyboardWillShowNotification object:nil userInfo:@{ UIKeyboardIsLocalUserInfoKey : @NO }];
            CYLScrollHideSimulationAfter(CYLScrollHideSimulationHold, ^{
                [center postNotificationName:UIKeyboardWillHideNotification object:nil userInfo:@{ UIKeyboardIsLocalUserInfoKey : @NO }];
            });
            break;
        }
        case CYLScrollHideSimulationRowGuidedAccess: {
            [center postNotificationName:UIAccessibilityGuidedAccessStatusDidChangeNotification object:nil];
            break;
        }
        case CYLScrollHideSimulationRowSameTabAgain: {
            tabBarController.selectedIndex = tabBarController.selectedIndex;
            break;
        }
        case CYLScrollHideSimulationRowTurnOnAgain: {
            tabBarController.cyl_hidesTabBarOnScroll = YES;
            break;
        }
        case CYLScrollHideSimulationRowAppShowsTabBar: {
            [tabBarController setTabBarHidden:NO animated:YES];
            break;
        }
        case CYLScrollHideSimulationRowSelfTest:
        case CYLScrollHideSimulationRowManualLongPress:
        case CYLScrollHideSimulationRowManualTapOutside:
        case CYLScrollHideSimulationRowManualKeepDragging:
        case CYLScrollHideSimulationRowCount:
            break;
    }
}

#pragma mark Self-test

/// [EN] What the self-test expects after a simulation. [CN] 自测在模拟之后的预期。
typedef NS_ENUM(NSInteger, CYLScrollHideSelfTestExpectation) {
    /// [EN] Not automatic (manual, real, leaves the app). [CN] 不能自动执行（手动、真实触发、会离开 App）。
    CYLScrollHideSelfTestExpectationSkip,
    /// [EN] The bar is shown again. [CN] TabBar 重新显示。
    CYLScrollHideSelfTestExpectationRestored,
    /// [EN] The bar stays hidden by scroll hiding. [CN] TabBar 保持被滚动隐藏。
    CYLScrollHideSelfTestExpectationStillHidden,
    /// [EN] The app took the bar over: hidden, but not by scroll hiding. [CN] App 接管了 TabBar：已隐藏，但不是滚动隐藏。
    CYLScrollHideSelfTestExpectationAppHidden,
};

static CYLScrollHideSelfTestExpectation CYLScrollHideSelfTestExpectationForRow(NSInteger row) {
    switch ((CYLScrollHideSimulationRow)row) {
        case CYLScrollHideSimulationRowScrollDownInCode:
        case CYLScrollHideSimulationRowOtherAppKeyboard:
        case CYLScrollHideSimulationRowSameTabAgain:
        case CYLScrollHideSimulationRowTurnOnAgain:
            return CYLScrollHideSelfTestExpectationStillHidden;
        case CYLScrollHideSimulationRowAppShowsTabBar:
            return CYLScrollHideSelfTestExpectationRestored;
        case CYLScrollHideSimulationRowAppHidesTabBar:
            return CYLScrollHideSelfTestExpectationAppHidden;
        case CYLScrollHideSimulationRowKeyboardWhileScrolling:
        case CYLScrollHideSimulationRowRotation:
        case CYLScrollHideSimulationRowManualLongPress:
        case CYLScrollHideSimulationRowManualTapOutside:
        case CYLScrollHideSimulationRowManualKeepDragging:
        case CYLScrollHideSimulationRowRealBackground:
        case CYLScrollHideSimulationRowRealSystemAlert:
        case CYLScrollHideSimulationRowSelfTest:
        case CYLScrollHideSimulationRowCount:
            return CYLScrollHideSelfTestExpectationSkip;
        case CYLScrollHideSimulationRowAlert:
        case CYLScrollHideSimulationRowActionSheet:
        case CYLScrollHideSimulationRowFullScreenModal:
        case CYLScrollHideSimulationRowPageSheet:
        case CYLScrollHideSimulationRowPushThenPop:
        case CYLScrollHideSimulationRowPushHidesBottomBar:
        case CYLScrollHideSimulationRowSwitchTab:
        case CYLScrollHideSimulationRowResignActive:
        case CYLScrollHideSimulationRowBackgroundForeground:
        case CYLScrollHideSimulationRowNotificationTapPush:
        case CYLScrollHideSimulationRowMemoryWarning:
        case CYLScrollHideSimulationRowOverlayWindow:
        case CYLScrollHideSimulationRowKeyboard:
        case CYLScrollHideSimulationRowShareSheet:
        case CYLScrollHideSimulationRowScrollToTopInCode:
        case CYLScrollHideSimulationRowTurnOffAndOn:
        case CYLScrollHideSimulationRowVoiceOverStatus:
        case CYLScrollHideSimulationRowReduceMotionStatus:
        case CYLScrollHideSimulationRowLowPowerMode:
        case CYLScrollHideSimulationRowOverCurrentContext:
        case CYLScrollHideSimulationRowPopover:
        case CYLScrollHideSimulationRowDrawer:
        case CYLScrollHideSimulationRowSafeAreaTop:
        case CYLScrollHideSimulationRowSceneDeactivate:
        case CYLScrollHideSimulationRowGuidedAccess:
            return CYLScrollHideSelfTestExpectationRestored;
    }
    return CYLScrollHideSelfTestExpectationSkip;
}

/// [EN] When a simulation is checked, and when the next one starts. [CN] 检查模拟结果的时间，以及开始下一个模拟的时间。
static const NSTimeInterval CYLScrollHideSelfTestCheckDelay = 2.7;
static const NSTimeInterval CYLScrollHideSelfTestNextDelay = 1.5;

/*!
 * [EN] The automatic self-test: for every automatic simulation, scroll into the content, hide the bar as a downward
 *      scroll would (`-cyl_simulateHideOnScrollForTesting`), run the simulation, check the expected result after
 *      CYLScrollHideSelfTestCheckDelay, dismiss what it presented, and go on. Logs one line per simulation and shows a
 *      summary. Liquid Glass cannot be hidden from code (the system minimizes it), so every row is SKIP there.
 * [CN] 自动自测：对每个可自动化的模拟，先滚入内容，像向下滚动一样隐藏 TabBar（`-cyl_simulateHideOnScrollForTesting`），执行模拟，
 *      CYLScrollHideSelfTestCheckDelay 之后检查预期结果，关闭它 present 的页面后继续下一个。每个模拟打印一行日志，最后显示汇总。
 *      液态玻璃无法用代码隐藏（由系统缩小），因此其中每一行都为 SKIP。
 */
- (void)cyl_runScrollHideSelfTest {
    CYLTabBarController *tabBarController = [self cyl_owningTabBarController] ?: [self cyl_tabBarController];
    if (!tabBarController) {
        return;
    }
    tabBarController.cyl_hidesTabBarOnScroll = YES;
    NSLog(@"[CYLTabBarController] scroll hiding self-test: start (%@ simulations)", @(CYLScrollHideSimulationRowCount));
    [self cyl_runScrollHideSelfTestRow:0 tabBarController:tabBarController results:[NSMutableArray array]];
}

- (void)cyl_runScrollHideSelfTestRow:(NSInteger)row tabBarController:(CYLTabBarController *)tabBarController results:(NSMutableArray<NSString *> *)results {
    __weak typeof(self) weakSelf = self;
    if (row >= CYLScrollHideSimulationRowCount) {
        [self cyl_finishScrollHideSelfTestWithResults:results];
        return;
    }
    CYLScrollHideSimulationKind kind = CYLScrollHideSimulationKindRestore;
    NSString *title = [self cyl_scrollHideSimulationTitleForRow:row kind:&kind];
    CYLScrollHideSelfTestExpectation expectation = CYLScrollHideSelfTestExpectationForRow(row);
    void (^next)(void) = ^{
        [weakSelf cyl_runScrollHideSelfTestRow:row + 1 tabBarController:tabBarController results:results];
    };
    // [EN] Scroll into the content (in code: does not hide by itself), then hide as a downward scroll would.
    // [CN] 先滚入内容（代码滚动本身不会隐藏），再像向下滚动一样隐藏。
    UIScrollView *scrollView = [self cyl_scrollHideSimulationScrollView];
    CGFloat minOffsetY = -scrollView.adjustedContentInset.top;
    CGFloat maxOffsetY = MAX(minOffsetY, scrollView.contentSize.height + scrollView.adjustedContentInset.bottom - CGRectGetHeight(scrollView.bounds));
    [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, MIN(maxOffsetY, minOffsetY + 600)) animated:NO];
    if (CYLScrollHideSelfTestExpectationSkip == expectation || ![tabBarController cyl_simulateHideOnScrollForTesting]) {
        NSString *line = [NSString stringWithFormat:@"SKIP %@", title];
        [results addObject:line];
        NSLog(@"[CYLTabBarController] scroll hiding self-test: %@", line);
        next();
        return;
    }
    [self cyl_runScrollHideSimulationRow:row tabBarController:tabBarController];
    CYLScrollHideSimulationAfter(CYLScrollHideSelfTestCheckDelay, ^{
        BOOL hiddenByScroll = tabBarController.cyl_isTabBarHiddenByScroll;
        BOOL passed = NO;
        switch (expectation) {
            case CYLScrollHideSelfTestExpectationRestored:
                passed = !hiddenByScroll;
                break;
            case CYLScrollHideSelfTestExpectationStillHidden:
                passed = hiddenByScroll;
                break;
            case CYLScrollHideSelfTestExpectationAppHidden:
                passed = !hiddenByScroll && tabBarController.isTabBarHidden;
                break;
            case CYLScrollHideSelfTestExpectationSkip:
                break;
        }
        NSString *line = [NSString stringWithFormat:@"%@ %@", passed ? @"PASS" : @"FAIL", title];
        [results addObject:line];
        NSLog(@"[CYLTabBarController] scroll hiding self-test: %@", line);
        // [EN] Clean up: dismiss what is still presented (alerts, share sheet), show a bar left hidden.
        // [CN] 清理：关闭仍在显示的页面（弹框、分享面板），显示仍被隐藏的 TabBar。
        UIViewController *presented = weakSelf.presentedViewController;
        if (presented && !presented.isBeingDismissed) {
            [presented dismissViewControllerAnimated:NO completion:nil];
        }
        NSTimeInterval wait = CYLScrollHideSelfTestNextDelay;
        if (CYLScrollHideSelfTestExpectationAppHidden == expectation) {
            wait += 2.0;
        } else if (tabBarController.isTabBarHidden) {
            [tabBarController setTabBarHidden:NO animated:NO];
        }
        CYLScrollHideSimulationAfter(wait, next);
    });
}

- (void)cyl_finishScrollHideSelfTestWithResults:(NSArray<NSString *> *)results {
    NSUInteger passed = 0;
    NSUInteger failed = 0;
    NSUInteger skipped = 0;
    for (NSString *line in results) {
        if ([line hasPrefix:@"PASS"]) {
            passed++;
        } else if ([line hasPrefix:@"FAIL"]) {
            failed++;
        } else {
            skipped++;
        }
    }
    NSString *summary = [NSString stringWithFormat:@"%@ passed, %@ failed, %@ skipped", @(passed), @(failed), @(skipped)];
    NSLog(@"[CYLTabBarController] scroll hiding self-test: done: %@", summary);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Scroll hiding self-test (#13)"
                                                                   message:[NSString stringWithFormat:@"%@\n\n%@", summary, [results componentsJoinedByString:@"\n"]]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark Settings row: all simulations in an action sheet

/*!
 * [EN] The settings section's row for the same simulations (shown in every demo, Swift ones included): an action sheet
 *      lists them; the chosen one fires after CYLScrollHideSimulationDelay.
 * [CN] 设置分组中用于同样模拟的行（所有 Demo 都显示，包括 Swift Demo）：用操作表列出全部模拟，所选模拟在 CYLScrollHideSimulationDelay
 *      之后触发。
 */
- (void)cyl_presentScrollHideSimulationMenu {
    UIAlertController *menu = [UIAlertController alertControllerWithTitle:CYLLocalizedString(@"滚动隐藏：模拟意外情况（issue #13）")
                                                                  message:CYLLocalizedString(@"选择一种意外情况，1.5 秒后触发。请先向下滚动隐藏 TabBar。")
                                                           preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    for (NSInteger row = 0; row < CYLScrollHideSimulationRowCount; row++) {
        CYLScrollHideSimulationKind kind = CYLScrollHideSimulationKindRestore;
        NSString *title = [self cyl_scrollHideSimulationTitleForRow:row kind:&kind];
        [menu addAction:[UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction * __unused action) {
            [weakSelf cyl_didSelectScrollHideSimulationRow:row];
        }]];
    }
    [menu addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    menu.popoverPresentationController.sourceView = self.view;
    menu.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    [self presentViewController:menu animated:YES completion:nil];
}

@end
