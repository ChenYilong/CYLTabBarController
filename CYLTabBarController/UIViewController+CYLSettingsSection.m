//
//  UIViewController+CYLSettingsSection.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIViewController+CYLSettingsSection.h"
#import "CYLLocalization.h"
#import "UIViewController+CYLMemoryWarning.h"
#import "CYLTabBarController.h"
#import "CYLPlusButton.h"
#import <objc/runtime.h>

const NSInteger CYLSettingsSection = 0;

/// Rows of the settings section.
typedef NS_ENUM(NSInteger, CYLSettingsRow) {
    CYLSettingsRowLanguage,
    CYLSettingsRowMemoryWarning,
    CYLSettingsRowTitlePositionAdjustment,
    CYLSettingsRowStandardAppearance,
    CYLSettingsRowLoginState,
    CYLSettingsRowPlusButtonTouchableArea,
    CYLSettingsRowCount,
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
        _titleLabel.font = [UIFont boldSystemFontOfSize:15];
        _titleLabel.numberOfLines = 0;
        _summaryLabel = [[UILabel alloc] init];
        _summaryLabel.font = [UIFont systemFontOfSize:12];
        _summaryLabel.textColor = [UIColor grayColor];
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

@implementation UIViewController (CYLSettingsSection)

- (NSInteger)cyl_settingsRowCount {
    return CYLSettingsRowCount;
}

- (UITableViewCell *)cyl_settingsCellForTableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath {
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
    } else {
        [self cyl_presentLanguagePicker];
    }
}

@end
