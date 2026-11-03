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
#import "CYLTabBarController.h"
#import <objc/runtime.h>

const NSInteger CYLSettingsSection = 0;

/// Rows of the settings section; the tab item update rows follow (`UIViewController+CYLTabBarItemUpdate.h`).
/// 设置分组的行；其后是更新 Tab 的若干行（`UIViewController+CYLTabBarItemUpdate.h`）。
typedef NS_ENUM(NSInteger, CYLSettingsRow) {
    CYLSettingsRowLanguage,
    CYLSettingsRowMemoryWarning,
    CYLSettingsRowTitlePositionAdjustment,
    CYLSettingsRowStandardAppearance,
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

@implementation UIViewController (CYLSettingsSection)

- (NSInteger)cyl_settingsRowCount {
    return CYLSettingsRowTabBarItemUpdate + [self cyl_tabBarItemUpdateRowCount];
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
    } else if (indexPath.row >= CYLSettingsRowTabBarItemUpdate) {
        [self cyl_didSelectTabBarItemUpdateRow:indexPath.row - CYLSettingsRowTabBarItemUpdate];
        // The rows show which changes are on (a checkmark). 各行用勾号显示已应用的更改。
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
